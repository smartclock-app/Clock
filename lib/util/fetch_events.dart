import 'dart:collection';

import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:smartclock/main.dart';
import 'package:smartclock/util/config.dart' show Config;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smartclock/util/logger.dart';

class CalendarItem {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String? recurringEventId;
  final String color;

  const CalendarItem({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.recurringEventId,
    required this.color,
  });
}

/// Calculates number of weeks for a given year as per https://en.wikipedia.org/wiki/ISO_week_date#Weeks_per_year
int numOfWeeks(int year) {
  DateTime dec28 = DateTime(year, 12, 28);
  int dayOfDec28 = int.parse(DateFormat("D").format(dec28));
  return ((dayOfDec28 - dec28.weekday + 10) / 7).floor();
}

/// Calculates week number from a date as per https://en.wikipedia.org/wiki/ISO_week_date#Calculation
int weekNumber(DateTime date) {
  int dayOfYear = int.parse(DateFormat("D").format(date));
  int woy = ((dayOfYear - date.weekday + 10) / 7).floor();
  if (woy < 1) {
    woy = numOfWeeks(date.year - 1);
  } else if (woy > numOfWeeks(date.year)) {
    woy = 1;
  }
  return woy;
}

String? eventColor(String? colorId) {
  if (colorId == null) return null;
  int id = int.parse(colorId);

  const colours = [
    "#7986cb",
    "#33b679",
    "#8e24aa",
    "#e67c73",
    "#f6c026",
    "#f5511d",
    "#039be5",
    "#616161",
    "#3f51b5",
    "#0b8043",
    "#d60000",
  ];

  if (id < 1 || id > 11) return colours[0];
  return colours[id - 1];
}

Future<Map<String, List<CalendarItem>>> fetchEvents(Config config, http.Client httpClient) async {
  logger.t("Refetching calendar");

  if (config.calendar.accessToken.isEmpty || config.calendar.refreshToken.isEmpty || config.calendar.clientId.isEmpty || config.calendar.clientSecret.isEmpty) {
    throw Exception("Calendar API credentials must be set in the config file.");
  }

  // Create Google auth client with credentials from config
  final client = auth.autoRefreshingClient(
    auth.ClientId(config.calendar.clientId, config.calendar.clientSecret),
    auth.AccessCredentials(
      auth.AccessToken("Bearer", config.calendar.accessToken, DateTime.now().toUtc()),
      config.calendar.refreshToken,
      [calendar.CalendarApi.calendarReadonlyScope],
    ),
    httpClient,
  );

  final calendarApi = calendar.CalendarApi(client);

  final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  List<CalendarItem> allEvents = [];
  Set<String> recurringEvents = HashSet();

  // Fetch all calendar lists
  final calendarList = await calendarApi.calendarList.list();

  // For each calendar list, fetch all events
  for (final calendarListEntry in calendarList.items!) {
    final color = calendarListEntry.backgroundColor ?? "#1a1a1a";
    final events = await calendarApi.events.list(
      calendarListEntry.id!,
      timeMin: DateTime.now().toUtc(),
      singleEvents: true,
      orderBy: "startTime",
    );

    // For each event, create a CalendarItem
    for (final event in events.items!) {
      late final DateTime startDate;
      late final DateTime endDate;

      // If the event is an all-day event, use the date field, otherwise use the dateTime field
      if (event.start!.date != null) {
        startDate = event.start!.date!;
        endDate = event.end!.date!;
      } else {
        startDate = event.start!.dateTime!.toLocal();
        endDate = event.end!.dateTime!.toLocal();
      }

      // If the event is a recurring event, skip it if we've already added it
      if (event.recurringEventId != null) {
        if (recurringEvents.contains(event.recurringEventId!)) {
          continue;
        }
        recurringEvents.add(event.recurringEventId!);
      }

      final calendarItem = CalendarItem(
        id: event.id!,
        title: event.summary!,
        start: startDate,
        end: endDate,
        recurringEventId: event.recurringEventId,
        color: eventColor(event.colorId) ?? color,
      );

      allEvents.add(calendarItem);
    }
  }

  // Sort events by start date
  allEvents.sort((a, b) => a.start.compareTo(b.start));

  // Sort events by month
  final Map<String, List<CalendarItem>> sortedEvents = {};
  final currentWeek = weekNumber(DateTime.now());
  for (final event in allEvents.getRange(0, config.calendar.maxEvents)) {
    final eventMonth = months[event.start.month - 1];
    final eventYear = event.start.year;
    final eventWeek = weekNumber(event.start);

    String key;
    if (eventWeek <= currentWeek) {
      key = "This Week";
    } else if (eventWeek == currentWeek + 1) {
      key = "Next Week";
    } else {
      key = "$eventMonth $eventYear";
    }

    if (!sortedEvents.containsKey(key)) sortedEvents[key] = [];
    sortedEvents[key]!.add(event);
  }

  // Update credentials in config if they have changed
  if (client.credentials.accessToken.data != config.calendar.accessToken || client.credentials.refreshToken != config.calendar.refreshToken) {
    logger.t("Updating calendar credentials");

    config.calendar.accessToken = client.credentials.accessToken.data;
    config.calendar.refreshToken = client.credentials.refreshToken!;
    saveConfig(config);
  }

  return sortedEvents;
}
