import 'dart:async';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartclock/util/get_ordinal.dart';
import 'package:smartclock/util/logger.dart';
import 'package:smartclock/util/config.dart' show ConfigModel;

class Clock extends StatefulWidget {
  const Clock({super.key});

  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> {
  Timer? timer;
  DateTime now = DateTime.now();

  String get _hour => now.hour == 12 ? "12" : "${now.hour % 12}".padLeft(2, "0");
  String get _minute => "${now.minute}".padLeft(2, "0");
  String get _second => "${now.second}".padLeft(2, "0");
  String get _period => now.hour < 12 ? "AM" : "PM";

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newNow = DateTime.now();
      if (newNow.second % 30 == 0) {
        logger.t("Refetching Content...");
        Provider.of<StreamController<DateTime>>(context, listen: false).add(now);
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
      left: config.dimensions.clock.x,
      top: config.dimensions.clock.y,
      width: config.dimensions.clock.width,
      height: config.dimensions.clock.height,
      child: Container(
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
                    "$_hour:$_minute",
                    style: TextStyle(fontSize: config.clock.mainSize, height: 0.8, color: Colors.black),
                    softWrap: false,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _second,
                        style: TextStyle(fontSize: config.clock.smallSize, height: 0.8, color: Colors.black),
                        softWrap: false,
                      ),
                      SizedBox(height: config.clock.smallGap),
                      Text(
                        _period,
                        style: TextStyle(fontSize: config.clock.smallSize, height: 0.8, color: Colors.black),
                        softWrap: false,
                      ),
                    ],
                  )
                ],
              ),
              SizedBox(height: config.clock.dateGap),
              Text(
                DateFormat("EEEE d'${getOrdinal(now.day)}' MMMM yyyy").format(now),
                style: TextStyle(fontSize: config.clock.dateSize, height: 0.8, color: Colors.black),
                textAlign: TextAlign.center,
                softWrap: false,
              )
            ],
          ),
        ),
      ),
    );
  }
}
