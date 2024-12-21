import 'dart:async';

import 'package:flutter/material.dart';

import 'package:intl/intl.dart' as intl; // Must be named as conflicted TextDirection
import 'package:provider/provider.dart';

import 'package:smartclock/main.dart' show logger;
import 'package:smartclock/config/config.dart';
import 'package:smartclock/util/data_utils.dart';
import 'package:smartclock/util/event_utils.dart';
import 'package:smartclock/widgets/clock/util/google_photos_scraper.dart';

class PhotoClock extends StatefulWidget {
  const PhotoClock({super.key, required this.now});

  final DateTime now;

  @override
  State<PhotoClock> createState() => _PhotoClockState();
}

class _PhotoClockState extends State<PhotoClock> {
  int photoIndex = 0;
  int thirtyCount = 0;
  late FutureOr<List<String>> _futureImages;
  StreamSubscription<void>? _subscription;

  String get _hour => widget.now.hour == 12 ? "12" : "${widget.now.hour % 12}".padLeft(2, "0");
  // ignore: non_constant_identifier_names
  String get _24Hour => "${widget.now.hour}".padLeft(2, "0");
  String get _minute => "${widget.now.minute}".padLeft(2, "0");
  String get _second => "${widget.now.second}".padLeft(2, "0");
  String get _period => widget.now.hour < 12 ? "AM" : "PM";

  Size _textSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  FutureOr<List<String>> getImages() async {
    final config = context.read<ConfigModel>().config;

    List<String> images;
    if (config.photos.useStaticLinks) {
      images = config.photos.images;
    } else {
      if (config.photos.scraperApiKey.isEmpty || config.photos.googlePhotoAlbumUrl.isEmpty) {
        logger.w("Cannot scrape Google Photos: API key or album URL is empty");
        return [];
      }

      images = await scrapeGooglePhotos(config.photos.scraperApiKey, config.photos.googlePhotoAlbumUrl);
    }

    images.shuffle();

    for (final image in images) {
      if (mounted) precacheImage(NetworkImage(image), context);
    }

    return images;
  }

  @override
  void initState() {
    super.initState();
    _futureImages = getImages();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final stream = context.read<StreamController<ClockEvent>>().stream;
    _subscription?.cancel();
    _subscription = stream.listen((event) {
      if (event.event == ClockEvents.skipPhoto) {
        setState(() {
          photoIndex++;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigModel>().config;
    final smallStyle = TextStyle(fontSize: config.clock.smallSize, height: 0.8, color: Colors.white);

    if (widget.now.second % 30 == 0) {
      setState(() {
        thirtyCount++;
      });

      if (thirtyCount >= config.photos.interval) {
        logger.i("Cycling clock image");
        setState(() {
          thirtyCount = 0;
          photoIndex++;
        });
      }
    }

    // Refetch images every 12 hours
    if (widget.now.hour % 12 == 0 && widget.now.minute == 0 && widget.now.second == 0) {
      setState(() {
        _futureImages = getImages();
      });
    }

    return FutureBuilder(
      future: Future.value(_futureImages),
      builder: (context, snapshot) {
        late final String? image;
        if (snapshot.hasData) {
          photoIndex %= snapshot.data!.length;
          image = snapshot.data![photoIndex];
        } else {
          image = null;
        }

        return Container(
          margin: EdgeInsets.all(config.clock.padding),
          decoration: BoxDecoration(
            color: config.sidebar.cardColor,
            borderRadius: BorderRadius.circular(config.sidebar.cardRadius),
            image: image != null
                ? DecorationImage(
                    image: NetworkImage(image),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  )
                : null,
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              const Expanded(flex: 1, child: SizedBox.expand()),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color.fromARGB(255, 0, 0, 0), Color.fromARGB(100, 0, 0, 0), Colors.transparent],
                    stops: [0, 0.9, 1],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Column(
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: config.clock.dateGap),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${config.clock.twentyFourHour ? _24Hour : _hour}:$_minute",
                          style: TextStyle(fontSize: config.clock.mainSize, height: 0.8, color: Colors.white),
                          softWrap: false,
                        ),
                        if (config.clock.showSeconds) ...[
                          // Ensure section is always the same width to prevent layout shifts
                          SizedBox(
                            width: _textSize(_period, smallStyle).width + config.clock.smallGap,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              verticalDirection: config.clock.twentyFourHour ? VerticalDirection.up : VerticalDirection.down,
                              children: [
                                Text(_second, style: smallStyle, softWrap: false),
                                SizedBox(height: config.clock.smallGap),
                                Text(!config.clock.twentyFourHour ? _period : "", style: smallStyle, softWrap: false),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: config.clock.dateGap),
                    Text(
                      intl.DateFormat("EEEE d'${getOrdinal(widget.now.day)}' MMMM yyyy").format(widget.now),
                      style: TextStyle(fontSize: config.clock.dateSize, height: 0.8, color: Colors.white),
                      textAlign: TextAlign.center,
                      softWrap: false,
                    ),
                    SizedBox(height: config.clock.dateGap),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
