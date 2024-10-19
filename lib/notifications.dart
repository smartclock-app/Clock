import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;
import 'package:smartclock/alarm.dart';
import 'package:smartclock/timer.dart';
import 'package:smartclock/util/logger.dart';
import 'package:smartclock/util/config.dart' show ConfigModel, AlexaFeatures;

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  Map<AlexaFeatures, List<alexa.Notification>> notifications = {};
  StreamSubscription<void>? _subscription;

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

    final allDevices = await client.getDeviceList(config.alexa.userId);
    final devices = allDevices.where((d) => config.alexa.devices.contains(d.accountName));

    List<alexa.Notification> timers = [];
    List<alexa.Notification> alarms = [];

    for (var n in ns) {
      if (n.status != "ON") continue;
      if (devices.isNotEmpty && !devices.any((d) => d.serialNumber == n.deviceSerialNumber)) continue;

      switch (n.type) {
        case "Timer":
          if (config.alexa.features[AlexaFeatures.timers]!) timers.add(n);
          break;
        case "Alarm":
        case "MusicAlarm":
        case "Reminder":
          // If alarm is more than 12 hours away, skip
          if (DateTime.parse("${n.originalDate!}T${(n.snoozedToTime ?? n.originalTime!)}").difference(DateTime.now()).inHours > 12) {
            continue;
          }
          if (config.alexa.features[AlexaFeatures.alarms]!) alarms.add(n);
          break;
      }
    }

    if (!mounted) return;
    setState(() {
      notifications = {
        AlexaFeatures.timers: timers,
        AlexaFeatures.alarms: alarms,
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
    final stream = Provider.of<StreamController<DateTime>>(context).stream;
    _subscription?.cancel();
    _subscription = stream.listen((_) => getNotifications());
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
        for (var timer in notifications[AlexaFeatures.timers] ?? []) ...[
          TimerCard(timer: timer),
        ],
        for (var alarm in notifications[AlexaFeatures.alarms] ?? []) ...[
          AlarmCard(alarm: alarm),
        ],
      ],
    );
  }
}
