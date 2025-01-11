import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;
import 'package:smartclock/widgets/sidebar/sidebar_card.dart';

class AlarmCard extends StatelessWidget {
  const AlarmCard({super.key, required this.alarm, required this.style});

  final alexa.Notification alarm;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final triggerTime = "${alarm.originalDate!}T${(alarm.snoozedToTime ?? alarm.originalTime!)}";
    final trigger = DateTime.parse(triggerTime);

    return SidebarCard(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(alarm.reminderLabel != null ? alarm.reminderLabel! : "Alarm", style: style),
          Text(DateFormat.jm().format(trigger), style: style),
        ],
      ),
    );
  }
}
