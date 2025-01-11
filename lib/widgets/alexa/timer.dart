import 'dart:async';
import 'package:flutter/material.dart';
import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;
import 'package:smartclock/widgets/sidebar/sidebar_card.dart';

class TimerCard extends StatefulWidget {
  const TimerCard({super.key, required this.timer, required this.style});

  final alexa.Notification timer;
  final TextStyle style;

  @override
  State<TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends State<TimerCard> {
  DateTime now = DateTime.now();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = DateTime.fromMillisecondsSinceEpoch(widget.timer.triggerTime!).difference(now);
    final hours = remaining.inHours > 0 ? "${remaining.inHours}:" : "";
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final remainingString = "$hours$minutes:$seconds";

    return SidebarCard(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Timer", style: widget.style),
          Text(remainingString, style: widget.style),
        ],
      ),
    );
  }
}
