import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smartclock/util/color_from_hex.dart';
import 'package:smartclock/util/logger_util.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:smartclock/widgets/watchlist/update_watchlist.dart';
import 'package:smartclock/widgets/watchlist/trakt_manager.dart';
import 'package:smartclock/config/config.dart' show Config;

class CalendarItem {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final Color color;

  const CalendarItem({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
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

Future<Map<String, List<CalendarItem>>> fetchEvents({required Config config, required http.Client httpClient, required Database database, bool updateWl = false}) async {
  final logger = LoggerUtil.logger;
  logger.t("Refetching calendar");

  if (config.google.accessToken.isEmpty || config.google.refreshToken.isEmpty || config.google.clientId.isEmpty || config.google.clientSecret.isEmpty) {
    throw Exception("Calendar API credentials must be set in the config file.");
  }

  // Create Google auth client with credentials from config
  final client = auth.autoRefreshingClient(
    auth.ClientId(config.google.clientId, config.google.clientSecret),
    auth.AccessCredentials(
      auth.AccessToken("Bearer", config.google.accessToken, config.google.tokenExpiry),
      config.google.refreshToken,
      [calendar.CalendarApi.calendarReadonlyScope],
    ),
    httpClient,
  );

  bool credentialsUpdated = false;
  client.credentialUpdates.listen((credentials) {
    if (credentials.accessToken.data != config.google.accessToken) {
      logger.t("Updating calendar access token");
      config.google.accessToken = credentials.accessToken.data;
      credentialsUpdated = true;
    }

    if (credentials.refreshToken != config.google.refreshToken) {
      logger.t("Updating calendar refresh token");
      config.google.refreshToken = credentials.refreshToken!;
      credentialsUpdated = true;
    }

    if (credentials.accessToken.expiry != config.google.tokenExpiry) {
      logger.t("Updating calendar token expiry");
      config.google.tokenExpiry = credentials.accessToken.expiry;
      credentialsUpdated = true;
    }
  });

  final calendarApi = calendar.CalendarApi(client);

  final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  List<CalendarItem> allEvents = [];

  // Fetch all calendar lists
  final calendarList = await calendarApi.calendarList.list();

  // For each calendar list, fetch all events
  for (final calendarListEntry in calendarList.items!) {
    final Set<String> recurringEvents = HashSet();
    final color = calendarListEntry.backgroundColor ?? "#1a1a1a";
    final events = await calendarApi.events.list(
      calendarListEntry.id!,
      timeMin: DateTime.now().toUtc(),
      singleEvents: true,
      orderBy: "startTime",
      maxResults: config.calendar.maxEvents,
    );

    // For each event, create a CalendarItem
    for (final event in events.items!) {
      late final DateTime startDate;
      late final DateTime endDate;
      event.summary ??= "No title";

      // If the event is an all-day event, use the date field, otherwise use the dateTime field
      if (event.start!.date != null) {
        startDate = event.start!.date!;
        endDate = event.end!.date!;
      } else {
        startDate = event.start!.dateTime!.toLocal();
        endDate = event.end!.dateTime!.toLocal();
      }

      // Skip event if it's summary matches a filter
      if (config.calendar.eventFilter.any((filter) => event.summary != null ? RegExp(filter).hasMatch(event.summary!) : false)) {
        continue;
      }

      // Skip event if event in this calendar already has same name
      // Doesn't skip if event in another calendar has same name
      if (recurringEvents.contains(event.summary)) {
        continue;
      } else {
        recurringEvents.add(event.summary!);
      }

      final calendarItem = CalendarItem(
        id: event.id!,
        title: event.summary!,
        start: startDate,
        end: endDate,
        color: (eventColor(event.colorId) ?? color).toColor(),
      );

      allEvents.add(calendarItem);
    }
  }

  // Get watchlist
  (String, String)? newTraktTokens;
  if (config.watchlist.enabled) {
    if (config.watchlist.trakt.accessToken.isEmpty ||
        config.watchlist.trakt.refreshToken.isEmpty ||
        config.watchlist.trakt.clientId.isEmpty ||
        config.watchlist.trakt.clientSecret.isEmpty ||
        config.watchlist.trakt.redirectUri.isEmpty ||
        config.watchlist.tmdbApiKey.isEmpty) {
      throw Exception("Trakt & TMDb API credentials must be set in the config file.");
    }

    final trakt = TraktManager(
      clientId: config.watchlist.trakt.clientId,
      clientSecret: config.watchlist.trakt.clientSecret,
      redirectURI: config.watchlist.trakt.redirectUri,
      accessToken: config.watchlist.trakt.accessToken,
      refreshToken: config.watchlist.trakt.refreshToken,
    );

    final currentWatchlist = database.select("SELECT * FROM watchlist");
    final (watchlistChanged, itemIds, tokens) = await trakt.getClockList(config: config, watchlist: currentWatchlist);
    if (watchlistChanged || updateWl) await updateWatchlist(config: config, items: itemIds, database: database);
    if (tokens != null) newTraktTokens = (tokens.accessToken, tokens.refreshToken);

    int count = 0;
    final watchlist = database.select("SELECT * FROM watchlist WHERE nextAirDate IS NOT NULL ORDER BY nextAirDate");
    Map<DateTime, List<String>> watchlistEvents = {};
    for (final item in watchlist) {
      if ((item["nextAirDate"] as String?) == null) continue;

      final DateTime start = DateTime.parse(item["nextAirDate"] as String);
      if (start.isBefore(DateUtils.dateOnly(DateTime.now()))) continue;

      if (!watchlistEvents.containsKey(start)) {
        if (++count > config.watchlist.maxItems) break;
        watchlistEvents[start] = [];
      }
      watchlistEvents[start]!.add(item["name"] as String);
    }

    for (final item in watchlistEvents.entries) {
      final DateTime start = item.key;
      final DateTime end = start.add(const Duration(days: 1));

      item.value.sort();

      final event = CalendarItem(
        id: UniqueKey().toString(),
        title: config.watchlist.prefix.isNotEmpty ? "${config.watchlist.prefix}\n${item.value.join("\n")}" : item.value.join("\n"),
        start: start,
        end: end,
        color: config.watchlist.color,
      );
      allEvents.add(event);
    }
  }

  // Sort events by start date
  allEvents.sort((a, b) => a.start.compareTo(b.start));

  // Sort events by month
  final Map<String, List<CalendarItem>> sortedEvents = {};
  final currentTime = DateTime.now();
  final currentWeek = weekNumber(currentTime);
  final weekReference = DateTime(2024, 1, 1); // Must be a Monday for isEven calculation below
  for (final event in allEvents.take(config.calendar.maxEvents)) {
    final eventMonth = months[event.start.month - 1];
    final eventYear = event.start.year;
    final eventWeek = weekNumber(event.start);

    String key;
    bool isEven = (weekReference.difference(event.start).inDays ~/ 7).isEven;
    final title = isEven ? config.calendar.titles.even : config.calendar.titles.odd;
    if (eventWeek == currentWeek || event.start.isBefore(currentTime)) {
      key = title.isNotEmpty ? "This Week - $title" : "This Week";
    } else if (eventWeek == currentWeek + 1) {
      key = title.isNotEmpty ? "Next Week - $title" : "Next Week";
    } else {
      key = "$eventMonth $eventYear";
    }

    if (!sortedEvents.containsKey(key)) sortedEvents[key] = [];
    sortedEvents[key]!.add(event);
  }

  // Update credentials in config if they have changed
  if (newTraktTokens != null) {
    if (newTraktTokens.$1 != config.watchlist.trakt.accessToken) {
      logger.t("Updating Trakt access token");
      config.watchlist.trakt.accessToken = newTraktTokens.$1;
      credentialsUpdated = true;
    }

    if (newTraktTokens.$2 != config.watchlist.trakt.refreshToken) {
      logger.t("Updating Trakt refresh token");
      config.watchlist.trakt.refreshToken = newTraktTokens.$2;
      credentialsUpdated = true;
    }
  }

  if (credentialsUpdated) {
    config.save();
  }

  return sortedEvents;
}
