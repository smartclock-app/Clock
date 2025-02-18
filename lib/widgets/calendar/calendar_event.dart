import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartclock/util/color_from_hex.dart';

import 'package:smartclock/widgets/calendar/calendar_event_model.dart';
import 'package:smartclock/widgets/clock/util/get_ordinal.dart';
import 'package:smartclock/config/config.dart' show ConfigModel;

class CalendarEvent extends StatelessWidget {
  const CalendarEvent({super.key, required this.event});

  final CalendarEventModel event;

  DateTime get _start => event.start;
  DateTime get _end => event.end;

  /// Check if the event is an all-day event
  ///
  /// If [oneDay] is true (default), it will only return true if the event is exactly one day long
  ///
  /// If [oneDay] is false, it will return true if the event starts and ends at midnight
  bool isAllDay({bool oneDay = true}) {
    final bool isOneDay = _end.difference(_start).inDays == 1;
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
    final isSameMonth = _start.month == _end.month;

    if (isAllDay()) {
      dateString = startDay;
    } else if (isAllDay(oneDay: false)) {
      final format = "EEEE d'${getOrdinal(_end.day - 1)}'${!isSameMonth ? " MMM" : ""}";
      dateString = "$startDay — ${formatDate(_end.subtract(const Duration(days: 1)), format)}";
    } else if (!DateUtils.isSameDay(_start, _end)) {
      final format = "EEEE d'${getOrdinal(_end.day)}'${!isSameMonth ? " MMM" : ""}";
      dateString = "$startDay (${DateFormat("HH:mm").format(_start)}) - ${formatDate(_end, format)} (${DateFormat("HH:mm").format(_end)})";
    } else if (_start.isAtSameMomentAs(_end)) {
      dateString = "$startDay (${DateFormat("HH:mm").format(_start)})";
    } else {
      dateString = "$startDay (${DateFormat("HH:mm").format(_start)} - ${DateFormat("HH:mm").format(_end)})";
    }

    return Container(
      margin: EdgeInsets.only(top: config.clock.padding),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: config.calendar.eventColorWidth,
              decoration: BoxDecoration(
                color: event.color.toColor(),
                borderRadius: BorderRadius.circular(config.calendar.eventColorWidth / 2),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: config.calendar.eventColorWidth + 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: config.sidebar.headingSize,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(dateString, style: TextStyle(fontSize: config.sidebar.subheadingSize), textAlign: TextAlign.left),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
