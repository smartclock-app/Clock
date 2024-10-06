import 'dart:async';

import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;
import 'package:flutter/material.dart';
import 'package:smartclock/alarm.dart';
import 'package:smartclock/timer.dart';
import 'package:provider/provider.dart';
import 'package:smartclock/util/config.dart';

enum NotificationType {
  timer,
  alarm,
}

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  Map<NotificationType, List<alexa.Notification>> notifications = {};
  StreamSubscription<void>? _subscription;

  void getNotifications() async {
    print("Refreshing notifications");
    final config = Provider.of<Config>(context, listen: false);
    final client = Provider.of<alexa.QueryClient>(context, listen: false);
    final ns = await client.getNotifications(config.alexa.userId);
    List<alexa.Notification> timers = [];
    List<alexa.Notification> alarms = [];

    for (var n in ns) {
      if (n.status != "ON") continue;
      if (!config.alexa.devices.contains(n.deviceName)) continue;

      switch (n.type) {
        case "Timer":
          timers.add(n);
          break;
        case "Alarm":
        case "MusicAlarm":
        case "Reminder":
          // If alarm is more than 12 hours away, skip
          if (DateTime.parse("${n.originalDate!}T${(n.snoozedToTime ?? n.originalTime!)}").difference(DateTime.now()).inHours > 12) {
            continue;
          }
          alarms.add(n);
          break;
      }
    }

    setState(() {
      notifications = {
        NotificationType.timer: timers,
        NotificationType.alarm: alarms,
      };
    });
  }

  @override
  void initState() {
    super.initState();
    getNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = Provider.of<StreamController<void>>(context).stream;
    _subscription?.cancel();
    _subscription = stream.listen((_) => getNotifications());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var timer in notifications[NotificationType.timer] ?? []) ...[
          TimerCard(timer: timer),
        ],
        for (var alarm in notifications[NotificationType.alarm] ?? []) ...[
          AlarmCard(alarm: alarm),
        ],
      ],
    );
  }
}
