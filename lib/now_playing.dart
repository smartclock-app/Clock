import 'dart:async';
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;
import 'package:smartclock/util/fetch_lyrics.dart';
import 'package:smartclock/util/logger.dart';
import 'package:smartclock/util/lrc.dart';
import 'package:smartclock/now_playing_lyrics.dart';
import 'package:smartclock/util/config.dart' show ConfigModel;

const radioProviders = ["Unknown Provider", "TuneIn Live Radio", "Global Player"];

class NowPlaying extends StatefulWidget {
  const NowPlaying({super.key});

  @override
  State<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> {
  StreamSubscription<void>? _subscription;
  double progress = 0;
  bool get isRadio => radioProviders.contains(queue?.provider?.providerDisplayName ?? "Unknown Provider");
  Lrc? lyrics;

  alexa.Queue? queue;

  void getQueue() async {
    if (queue?.state == "REFRESHING") return;

    logger.t("Refetching queue");
    final config = context.read<ConfigModel>().config;
    final database = context.read<Database>();
    final client = context.read<alexa.QueryClient>();
    alexa.Queue q = alexa.Queue(state: "STOPPED");
    try {
      for (final device in config.alexa.devices) {
        final queue = await client.getQueue(config.alexa.userId, device);
        if (queue.state == "PLAYING") {
          q = queue;
          break;
        }
      }
    } catch (e) {
      return logger.e("Failed to fetch queue: $e");
    }

    if (radioProviders.contains(q.provider?.providerDisplayName ?? "Unknown Provider")) {
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
    final difference = DateTime.now().toUtc().difference(q.timestamp!).inMilliseconds;
    if (!mounted) return;
    setState(() {
      lyrics = lyricResult;
      queue = q;
      progress = (q.progress?.mediaProgress ?? 0).toDouble() + difference / 900;
    });
  }

  Timer? timer;

  @override
  void initState() {
    super.initState();
    getQueue();
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (queue == null || queue!.progress == null) {
        progress = 0;
        return;
      }

      if (queue!.state != "PLAYING") {
        return;
      }

      if (!isRadio) {
        if (progress >= queue!.progress!.mediaLength!) {
          getQueue();
          queue!.state = "REFRESHING";
        }

        setState(() {
          progress = min(progress + 0.1, queue!.progress!.mediaLength!.toDouble());
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = Provider.of<StreamController<DateTime>>(context).stream;
    _subscription?.cancel();
    _subscription = stream.listen((_) => getQueue());
  }

  @override
  void dispose() {
    timer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  String formatMediaTime(int time, {bool remaining = false}) {
    final minutes = time ~/ 60;
    final seconds = time % 60;
    return "${remaining ? "-" : ""}$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (queue == null || queue?.state == null || !(queue!.state == "PLAYING" || queue!.state == "REFRESHING")) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xfff8f8f8),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Column(
            children: [
              Row(
                children: [
                  ColorFiltered(
                    colorFilter: const ColorFilter.mode(Color(0xfff8f8f8), BlendMode.darken),
                    child: Image.network(queue?.mainArt?.url ?? "", height: 146),
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
                              style: const TextStyle(fontSize: 32, height: 1, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              queue!.infoText!.subText1!,
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isRadio) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(formatMediaTime(progress.toInt())),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: progress / queue!.progress!.mediaLength!,
                                    color: const Color(0xff1a1a1a),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(formatMediaTime(queue!.progress!.mediaLength! - progress.toInt(), remaining: true)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (!isRadio && (lyrics?.lyrics.isNotEmpty ?? false)) NowPlayingLyrics(progress: progress, lyrics: lyrics!),
            ],
          ),
        ],
      ),
    );
  }
}
