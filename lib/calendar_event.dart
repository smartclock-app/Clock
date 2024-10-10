import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:smartclock/util/fetch_events.dart';
import 'package:smartclock/util/get_ordinal.dart';
import 'package:smartclock/util/config.dart' show Config;

class CalendarEvent extends StatelessWidget {
  const CalendarEvent({super.key, required this.event});

  final CalendarItem event;

  DateTime get _start => event.start;
  DateTime get _end => event.end;
  Duration get _duration => _end.difference(_start);

  Color hexToColor(String hex) => Color(int.parse(hex.replaceAll(RegExp(r'#'), '0xff')));

  bool isAllDay({bool oneDay = true}) {
    final bool isOneDay = _duration.inDays > 0 && _duration.inDays < 2;
    final bool startsMidnight = _start.hour == 0 && _start.minute == 0;
    final bool endsMidnight = _end.hour == 0 && _end.minute == 0;

    return (isOneDay || !oneDay) && startsMidnight && endsMidnight;
  }

  String formatDate(DateTime date, String format) {
    final DateTime now = DateTime.now();
    final Duration difference = date.difference(DateTime(now.year, now.month, now.day));

    if (difference.inDays < 1 && difference.inDays >= 0) return 'Today';
    if (difference.inDays < 2 && difference.inDays >= 1) return 'Tomorrow';

    return DateFormat(format).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<Config>();

    late final String dateString;
    final startDay = formatDate(_start, "EEEE d'${getOrdinal(_start.day)}'");

    // prettier-ignore
    if (isAllDay()) {
      dateString = startDay;
    } else if (isAllDay(oneDay: false)) {
      if (_start.month != _end.month) {
        dateString = "$startDay — ${DateFormat("EEEE d'${getOrdinal(_end.day - 1)}' MMM").format(_end.subtract(const Duration(days: 1)))}";
      } else {
        dateString = "$startDay - ${formatDate(_end.subtract(const Duration(days: 1)), "EEEE d'${getOrdinal(_end.day - 1)}'")}";
      }
    } else if (_duration.inDays > 1) {
      if (_start.month != _end.month) {
        dateString = "$startDay (HH:mm) - ${DateFormat("EEEE d'${getOrdinal(_end.day)}' MMM").format(_end)}";
      } else {
        dateString = "$startDay (HH:mm) - ${formatDate(_end, "EEEE d'${getOrdinal(_end.day)}'")}";
      }
    } else {
      dateString = startDay + DateFormat(" (HH:mm)").format(_start);
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border(
          left: BorderSide(color: hexToColor(event.color), width: 8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            event.title,
            style: TextStyle(
              fontSize: config.calendar.eventTitleSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(dateString, style: TextStyle(fontSize: config.calendar.eventTimeSize)),
        ],
      ),
    );
  }
}
