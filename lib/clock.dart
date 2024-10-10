import 'dart:async';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartclock/util/config.dart' show Config;
import 'package:smartclock/util/get_ordinal.dart';
import 'package:smartclock/util/logger.dart';

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
        Provider.of<StreamController<void>>(context, listen: false).add(null);
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
    final config = context.read<Config>();
    // x,y,width,height
    final dimensions = config.dimensions.clock.split(",").map((e) => double.parse(e)).toList();
    final clockConf = config.clock;

    return Positioned(
      left: dimensions[0],
      top: dimensions[1],
      width: dimensions[2],
      height: dimensions[3],
      child: Container(
        margin: const EdgeInsets.only(top: 16, left: 16, bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xfff8f8f8),
          borderRadius: BorderRadius.circular(10),
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
                    style: TextStyle(fontSize: clockConf.mainSize, height: 0.8, color: Colors.black),
                    softWrap: false,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _second,
                        style: TextStyle(fontSize: clockConf.smallSize, height: 0.8, color: Colors.black),
                        softWrap: false,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        _period,
                        style: TextStyle(fontSize: clockConf.smallSize, height: 0.8, color: Colors.black),
                        softWrap: false,
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 50),
              Text(
                DateFormat("EEEE d'${getOrdinal(now.day)}' MMMM yyyy").format(now),
                style: TextStyle(fontSize: clockConf.dateSize, height: 0.8, color: Colors.black),
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
