import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:smartclock/util/event_utils.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:smartclock/widgets/sidebar/info_widget.dart';
import 'package:smartclock/widgets/sidebar/error_info_widget.dart';
import 'package:smartclock/widgets/sidebar/sidebar_card.dart';
import 'package:smartclock/widgets/calendar/calendar_event.dart';
import 'package:smartclock/widgets/calendar/util/fetch_events.dart';
import 'package:smartclock/config/config.dart' show ConfigModel, Config;

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  StreamSubscription<void>? _subscription;
  late Config config;
  late sqlite3.Database database;
  late Future<Map<String, List<CalendarItem>>> _futureEvents;
  final _client = http.Client();

  @override
  void initState() {
    super.initState();
    config = context.read<ConfigModel>().config;
    database = context.read<sqlite3.Database>();
    _futureEvents = fetchEvents(
      config: config,
      httpClient: _client,
      database: database,
      updateWl: true,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = context.read<StreamController<ClockEvent>>().stream;
    _subscription?.cancel();
    _subscription = stream.listen((event) {
      if (event.event == ClockEvents.refetch) {
        setState(() {
          _futureEvents = fetchEvents(
            config: config,
            httpClient: _client,
            database: database,
            updateWl: event.time.hour == 0 && event.time.minute == 0,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _futureEvents,
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState != ConnectionState.done) {
          return const InfoWidget(title: "Calendar", message: "Loading Events...");
        }

        return Column(
          children: [
            if (snapshot.hasError) ErrorInfoWidget(title: "Calendar", message: snapshot.error.toString(), stack: snapshot.stackTrace.toString()),
            if (snapshot.hasData)
              for (var month in snapshot.data!.entries) ...[
                SidebarCard(
                  margin: month.key != snapshot.data!.keys.last,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          month.key,
                          style: TextStyle(fontSize: config.calendar.monthTitleSize, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Divider(),
                      for (var event in month.value) ...[
                        CalendarEvent(event: event),
                      ],
                    ],
                  ),
                )
              ]
          ],
        );
      },
    );
  }
}
