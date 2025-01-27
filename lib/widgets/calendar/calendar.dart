import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:smartclock/widgets/calendar/calendar_event_model.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:smartclock/util/event_utils.dart';
import 'package:smartclock/widgets/sidebar/info_widget.dart';
import 'package:smartclock/widgets/sidebar/error_info_widget.dart';
import 'package:smartclock/widgets/sidebar/sidebar_card.dart';
import 'package:smartclock/widgets/calendar/calendar_event.dart';
import 'package:smartclock/widgets/calendar/util/fetch_events.dart';
import 'package:smartclock/config/config.dart' show ConfigModel, Config;
import 'package:smartclock/util/data_sync_service.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  StreamSubscription<void>? _clockSubscription;
  late Config config;
  late sqlite3.Database database;
  late DataSyncService _syncService;
  final _client = http.Client();

  static const String _calendarEndpoint = 'calendar_events';

  @override
  void initState() {
    super.initState();
    config = context.read<ConfigModel>().config;
    database = context.read<sqlite3.Database>();
    _syncService = DataSyncService();

    // Initial fetch if this is the host
    if (_syncService.isHost) {
      _fetchAndUpdateEvents(updateWl: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final clockStream = context.read<StreamController<ClockEvent>>().stream;
    _clockSubscription?.cancel();
    _clockSubscription = clockStream.listen((event) {
      if (event.event == ClockEvents.refetch && _syncService.isHost) {
        _fetchAndUpdateEvents(
          updateWl: event.time.hour == 0 && event.time.minute == 0,
        );
      }
    });
  }

  Future<void> _fetchAndUpdateEvents({required bool updateWl}) async {
    try {
      await _syncService.refreshData(
        endpoint: _calendarEndpoint,
        fetcher: () => fetchEvents(
          config: config,
          httpClient: _client,
          database: database,
          updateWl: updateWl,
        ),
      );
    } catch (e, stack) {
      debugPrint('Error fetching calendar events: $e\n$stack');
    }
  }

  @override
  void dispose() {
    _clockSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, List<CalendarEventModel>>>(
      stream: _syncService.watchData(
        endpoint: _calendarEndpoint,
        fetcher: () => fetchEvents(
          config: config,
          httpClient: _client,
          database: database,
          updateWl: true,
        ),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const InfoWidget(title: "Calendar", message: "Loading Events...");
        }

        if (snapshot.hasError) {
          return ErrorInfoWidget(
            title: "Calendar",
            message: snapshot.error.toString(),
            stack: snapshot.stackTrace.toString(),
          );
        }

        final eventsByMonth = snapshot.data!;

        return Column(
          children: [
            for (var month in eventsByMonth.entries) ...[
              SidebarCard(
                margin: month.key != eventsByMonth.keys.last,
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        month.key,
                        style: TextStyle(
                          fontSize: config.sidebar.titleSize,
                          fontWeight: FontWeight.bold,
                        ),
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
