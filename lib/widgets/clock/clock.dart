import 'dart:async';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl; // Must be named as conflicted TextDirection
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartclock/util/data_utils.dart';
import 'package:smartclock/main.dart' show logger;
import 'package:smartclock/util/event_utils.dart';
import 'package:smartclock/widgets/clock/photo_clock.dart';
import 'package:smartclock/config/config.dart' show ConfigModel, Config;

class Clock extends StatefulWidget {
  const Clock({super.key});

  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> {
  Timer? timer;
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newNow = DateTime.now();
      if (newNow.second % 30 == 0) {
        logger.t("Refetching Content...");
        // Notifies other widgets to refetch their content
        context.read<StreamController<ClockEvent>>().add((time: newNow, event: ClockEvents.refetch));
      }

      setState(() {
        now = newNow;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigModel>().config;

    return Positioned(
      left: config.dimensions["clock"]!.x,
      top: config.dimensions["clock"]!.y,
      width: config.dimensions["clock"]!.width,
      height: config.dimensions["clock"]!.height,
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Navigate to"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text("Logs"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed("/logs");
                      },
                    ),
                    ListTile(
                      title: const Text("Editor"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed("/editor");
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: config.photos.enabled ? PhotoClock(now: now) : BasicClock(now: now, config: config),
      ),
    );
  }
}

class BasicClock extends StatelessWidget {
  const BasicClock({super.key, required this.now, required this.config});

  final DateTime now;
  final Config config;

  String get _hour => now.hour == 12 ? "12" : "${now.hour % 12}".padLeft(2, "0");
  // ignore: non_constant_identifier_names
  String get _24Hour => "${now.hour}".padLeft(2, "0");
  String get _minute => "${now.minute}".padLeft(2, "0");
  String get _second => "${now.second}".padLeft(2, "0");
  String get _period => now.hour < 12 ? "AM" : "PM";

  Size _textSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  @override
  Widget build(BuildContext context) {
    final smallStyle = TextStyle(fontSize: config.clock.smallSize, height: 0.8, color: Colors.black);

    return Container(
      margin: EdgeInsets.all(config.clock.padding),
      decoration: BoxDecoration(
        color: config.sidebar.cardColor,
        borderRadius: BorderRadius.circular(config.sidebar.cardRadius),
      ),
      child: Center(
        child: Column(
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${config.clock.twentyFourHour ? _24Hour : _hour}:$_minute",
                  style: TextStyle(fontSize: config.clock.mainSize, height: 0.8, color: Colors.black),
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
              intl.DateFormat("EEEE d'${getOrdinal(now.day)}' MMMM yyyy").format(now),
              style: TextStyle(fontSize: config.clock.dateSize, height: 0.8, color: Colors.black),
              textAlign: TextAlign.center,
              softWrap: false,
            )
          ],
        ),
      ),
    );
  }
}
