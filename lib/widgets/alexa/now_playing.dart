import 'dart:async';
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:smartclock/util/event_utils.dart';
import 'package:smartclock/util/logger_util.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;
import 'package:smartclock/widgets/alexa/now_playing_lyrics.dart';
import 'package:smartclock/widgets/sidebar/sidebar_card.dart';
import 'package:smartclock/widgets/alexa/util/fetch_lyrics.dart';
import 'package:smartclock/widgets/alexa/util/lrc.dart';
import 'package:smartclock/config/config.dart' show ConfigModel;

const radioProviders = ["Unknown Provider", "PLANET_RADIO", "TuneIn", "Global Player"];

class NowPlaying extends StatefulWidget {
  const NowPlaying({super.key});

  @override
  State<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> {
  StreamSubscription<void>? _subscription;
  int progress = 0;
  Lrc? lyrics;
  ConfigModel? configModel;
  Logger logger = LoggerUtil.logger;

  alexa.Queue? queue;

  bool isRadio() {
    bool isRadio = false;
    if (configModel!.config.alexa.radioProviders != null && queue?.provider?.providerName != null) {
      isRadio = configModel!.config.alexa.radioProviders!.contains(queue?.provider?.providerName);
    }
    return isRadio || radioProviders.contains(queue?.provider?.providerName ?? "Unknown Provider");
  }

  void getQueue() async {
    if (queue?.playerState == "REFRESHING") return;

    logger.t("Refetching queue");
    final config = configModel!.config;
    final database = context.read<sqlite3.Database>();
    final client = context.read<alexa.QueryClient>();
    alexa.Queue q = alexa.Queue(playerState: "STOPPED");
    try {
      for (final device in config.alexa.devices) {
        final queue = await client.getQueue(config.alexa.userId, device);
        if (queue.playerState == "PLAYING") {
          q = queue;
          break;
        }
      }
    } catch (e) {
      return logger.e("Failed to fetch queue: $e");
    }

    if (radioProviders.contains(q.provider?.providerName ?? "Unknown Provider")) {
      if (!mounted) return;
      return setState(() {
        lyrics = null;
        progress = 0;
        queue = q;
      });
    }

    Lrc? lyricResult;
    if (q.infoText?.title != null && q.infoText?.subText1 != null) {
      lyricResult = await fetchLyrics(database, q.infoText!.title!, q.infoText!.subText1!);
    }

    if (!mounted) return;
    setState(() {
      lyrics = lyricResult;
      queue = q;
      progress = q.progress?.mediaProgress ?? 0;
    });
  }

  Timer? timer;

  @override
  void initState() {
    super.initState();
    configModel = context.read<ConfigModel>();
    getQueue();
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (queue == null || queue!.progress == null) {
        progress = 0;
        return;
      }

      if (queue!.playerState != "PLAYING") {
        return;
      }

      if (!isRadio()) {
        if (progress >= queue!.progress!.mediaLength!) {
          getQueue();
          queue!.playerState = "REFRESHING";
        }

        setState(() {
          progress = min(progress + 100, queue!.progress!.mediaLength!);
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = context.read<StreamController<ClockEvent>>().stream;
    _subscription?.cancel();
    _subscription = stream.listen((event) => event.event == ClockEvents.refetch ? getQueue() : null);
  }

  @override
  void dispose() {
    timer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  String formatMediaTime(int time, {bool remaining = false}) {
    final minutes = time ~/ 60000;
    final seconds = (time ~/ 1000) % 60;
    return "${remaining ? "-" : ""}$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (queue == null || queue?.playerState == null || !(queue!.playerState == "PLAYING" || queue!.playerState == "REFRESHING")) return const SizedBox.shrink();

    final config = context.read<ConfigModel>().config;
    final isRadioBool = isRadio();

    return SidebarCard(
      padding: false,
      child: Column(
        children: [
          Column(
            children: [
              Row(
                children: [
                  ColorFiltered(
                    colorFilter: const ColorFilter.mode(Color(0xfff8f8f8), BlendMode.darken),
                    child: Image.network(queue?.mainArt?.fullUrl ?? "", height: config.alexa.nowplayingImageSize),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              queue?.infoText?.title ?? "",
                              style: TextStyle(fontSize: config.alexa.nowplayingFontSize, height: 1, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              queue?.infoText?.subText1 ?? "",
                              style: TextStyle(fontSize: config.alexa.nowplayingFontSize, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isRadioBool) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(formatMediaTime(progress)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: progress / queue!.progress!.mediaLength!,
                                    color: const Color(0xff1a1a1a),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(formatMediaTime(queue!.progress!.mediaLength! - progress, remaining: true)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (!isRadioBool && (lyrics?.lyrics.isNotEmpty ?? false)) NowPlayingLyrics(progress: progress, lyrics: lyrics!, config: config),
            ],
          ),
        ],
      ),
    );
  }
}
