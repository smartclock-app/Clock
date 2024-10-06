import 'dart:async';
import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AlarmCard extends StatefulWidget {
  const AlarmCard({super.key, required this.alarm});

  final alexa.Notification alarm;

  @override
  State<AlarmCard> createState() => _AlarmCardState();
}

class _AlarmCardState extends State<AlarmCard> {
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
    String triggerTime = "${widget.alarm.originalDate!}T${(widget.alarm.snoozedToTime ?? widget.alarm.originalTime!)}";
    DateTime trigger = DateTime.parse(triggerTime);

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
          Text(widget.alarm.type == "Reminder" ? widget.alarm.reminderLabel! : "Alarm", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text(DateFormat.jm().format(trigger), style: const TextStyle(fontSize: 28)),
        ],
      ),
    );
  }
}
