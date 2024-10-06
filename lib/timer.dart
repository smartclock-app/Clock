import 'dart:async';
import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;
import 'package:flutter/material.dart';

class TimerCard extends StatefulWidget {
  const TimerCard({super.key, required this.timer});

  final alexa.Notification timer;

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
    Duration remaining = DateTime.fromMillisecondsSinceEpoch(widget.timer.triggerTime!).difference(now);
    String remainingString = "${remaining.inHours}:${remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remaining.inSeconds.remainder(60).toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff8f8f8),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Timer", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text(remainingString, style: const TextStyle(fontSize: 28)),
        ],
      ),
    );
  }
}
