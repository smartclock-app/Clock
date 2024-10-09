import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:smartclock/calendar_event.dart';
import 'package:smartclock/util/fetch_events.dart';
import 'package:smartclock/util/config.dart' show Config;

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  StreamSubscription<void>? _subscription;
  late Config config;
  late Future<Map<String, List<CalendarItem>>> _futureEvents;
  final _client = http.Client();

  @override
  void initState() {
    super.initState();
    config = Provider.of<Config>(context, listen: false);
    _futureEvents = fetchEvents(config, _client);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = Provider.of<StreamController<void>>(context).stream;
    _subscription?.cancel();
    _subscription = stream.listen((_) {
      setState(() {
        _futureEvents = fetchEvents(config, _client);
      });
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
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xfff8f8f8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Calendar",
                    style: TextStyle(fontSize: config.calendar.monthTitleSize, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                Text(snapshot.error.toString()),
              ],
            ),
          );
        }

        if (!snapshot.hasData && snapshot.connectionState != ConnectionState.done) {
          return Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xfff8f8f8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Calendar",
                    style: TextStyle(fontSize: config.calendar.monthTitleSize, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Loading Events...",
                    style: TextStyle(fontSize: config.calendar.eventTitleSize),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            for (var month in snapshot.data!.entries) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xfff8f8f8),
                  borderRadius: BorderRadius.circular(10),
                ),
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
