import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:smartclock/util/fetch_events.dart';
import 'package:smartclock/util/get_ordinal.dart';
import 'package:smartclock/util/config.dart' show ConfigModel;

class CalendarEvent extends StatelessWidget {
  const CalendarEvent({super.key, required this.event});

  final CalendarItem event;

  DateTime get _start => event.start;
  DateTime get _end => event.end;
  Duration get _duration => _end.difference(_start);

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
    final config = context.read<ConfigModel>().config;

    late final String dateString;
    final startDay = formatDate(_start, "EEEE d'${getOrdinal(_start.day)}'");

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
        dateString = "$startDay (${DateFormat("HH:mm").format(_start)}) - ${DateFormat("EEEE d'${getOrdinal(_end.day)}' MMM").format(_end)}";
      } else {
        dateString = "$startDay (${DateFormat("HH:mm").format(_start)}) - ${formatDate(_end, "EEEE d'${getOrdinal(_end.day)}'")}";
      }
    } else if (_start.isAtSameMomentAs(_end)) {
      dateString = "$startDay (${DateFormat("HH:mm").format(_start)})";
    } else {
      dateString = "$startDay (${DateFormat("HH:mm").format(_start)} - ${DateFormat("HH:mm").format(_end)})";
    }

    return Container(
      margin: EdgeInsets.only(top: config.sidebar.cardSpacing),
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(config.calendar.eventColorWidth * (4 / 5)),
        border: Border(
          left: BorderSide(color: event.color, width: config.calendar.eventColorWidth),
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
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(dateString, style: TextStyle(fontSize: config.calendar.eventTimeSize)),
        ],
      ),
    );
  }
}
