import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;

import 'package:smartclock/config/config.dart' show ConfigModel;
import 'package:smartclock/util/event_utils.dart';
import 'package:smartclock/util/logger_util.dart';
import 'package:smartclock/widgets/alexa/alarm.dart';
import 'package:smartclock/widgets/alexa/timer.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  ({List<alexa.Notification> alarms, List<alexa.Notification> timers}) notifications = (alarms: [], timers: []);
  StreamSubscription<void>? _subscription;
  Logger logger = LoggerUtil.logger;

  void getNotifications() async {
    logger.t("Refetching notifications");
    final config = context.read<ConfigModel>().config;
    final client = context.read<alexa.QueryClient>();
    late List<alexa.Notification> ns;
    try {
      ns = await client.getNotifications(config.alexa.userId);
    } catch (e) {
      return logger.e("Failed to fetch notifications: $e");
    }

    final allDevices = await client.getDevices(config.alexa.userId);
    final devices = allDevices.where((d) => config.alexa.devices.contains(d.accountName));

    List<alexa.Notification> timers = [];
    List<alexa.Notification> alarms = [];

    for (var n in ns) {
      if (n.status != "ON") continue;
      if (devices.isNotEmpty && !devices.any((d) => d.serialNumber == n.deviceSerialNumber)) continue;

      switch (n.type) {
        case "Timer":
          if (config.alexa.features.timers) timers.add(n);
          break;
        case "Alarm":
        case "MusicAlarm":
        case "Reminder":
          // If alarm is more than 12 hours away, skip
          if (DateTime.parse("${n.originalDate!}T${(n.snoozedToTime ?? n.originalTime!)}").difference(DateTime.now()).inHours > 12) {
            continue;
          }
          if (config.alexa.features.alarms) alarms.add(n);
          break;
      }
    }

    if (!mounted) return;
    setState(() {
      notifications = (timers: timers, alarms: alarms);
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
    final stream = context.read<StreamController<ClockEvent>>().stream;
    _subscription?.cancel();
    _subscription = stream.listen((event) => event.event == ClockEvents.refetch ? getNotifications() : null);
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var timer in notifications.timers) ...[
          TimerCard(timer: timer),
        ],
        for (var alarm in notifications.alarms) ...[
          AlarmCard(alarm: alarm),
        ],
      ],
    );
  }
}
