import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:smartclock/clock.dart';
import 'package:smartclock/Weather.dart';
import 'package:smartclock/sidebar.dart';
import 'package:smartclock/util/logger.dart';
import 'package:smartclock/util/config.dart' show ConfigModel;

class SmartClock extends StatefulWidget {
  const SmartClock({super.key});

  @override
  State<SmartClock> createState() => _SmartClockState();
}

class _SmartClockState extends State<SmartClock> {
  bool networkAvailable = false;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    initConnectivity();

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      logger.w('Couldn\'t check connectivity status', error: e);
      return;
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    if (result.contains(ConnectivityResult.none)) {
      networkAvailable = false;
    } else {
      networkAvailable = true;
    }
    if (!mounted) return;
    setState(() {
      networkAvailable = networkAvailable;
    });
    logger.t('Connectivity changed: $result');
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigModel>().config;

    return MaterialApp(
      title: 'SmartClock',
      theme: ThemeData(scaffoldBackgroundColor: Colors.black, fontFamily: "Poppins"),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          width: config.resolution.x,
          height: config.resolution.y,
          color: Colors.white,
          child: Center(
            child: Stack(
              children: [
                const Clock(),
                if (config.sidebar.enabled && config.networkEnabled) Sidebar(networkAvailable: networkAvailable),
                if (config.weather.enabled && config.networkEnabled && networkAvailable) const Weather(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
