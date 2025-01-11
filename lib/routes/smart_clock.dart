import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:logger/logger.dart';

import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:smartclock/config/config.dart' show ConfigModel, WeatherType;
import 'package:smartclock/routes/editor.dart';
import 'package:smartclock/routes/logs.dart';
import 'package:smartclock/util/logger_util.dart';
import 'package:smartclock/widgets/clock/clock.dart';
import 'package:smartclock/widgets/sidebar/sidebar.dart';
import 'package:smartclock/widgets/weather/weather.dart';
import 'package:smartclock/websocket/websocket_manager.dart';

class SmartClock extends StatefulWidget {
  const SmartClock({super.key});

  @override
  State<SmartClock> createState() => _SmartClockState();
}

class _SmartClockState extends State<SmartClock> {
  bool networkAvailable = false;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  WebSocketManager? _webSocketManager;
  Logger logger = LoggerUtil.logger;

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    final configModel = context.read<ConfigModel>();
    if (configModel.config.remoteConfig.enabled) {
      _webSocketManager = WebSocketManager(context);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _webSocketManager?.dispose();
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
    logger.t('Connection\'s Available: $result');
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigModel>().config;

    return MaterialApp(
      title: 'SmartClock',
      theme: ThemeData(scaffoldBackgroundColor: Colors.black, fontFamily: "Poppins"),
      debugShowCheckedModeBanner: false,
      routes: {
        '/editor': (context) => const Editor(),
        '/logs': (context) => const LogViewer(),
      },
      home: Scaffold(
        body: Consumer<ConfigModel>(
          builder: (context, value, child) => Container(
            key: value.clockKey,
            color: Colors.white,
            child: Center(
              child: SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final resolution = constraints.biggest;
                    final width = (resolution.width).toInt();
                    final height = (resolution.height).toInt();
                    logger.i("Safe Area Resolution: ${width}x$height");

                    return Stack(
                      children: [
                        const Clock(),
                        if (config.sidebar.enabled) Sidebar(networkAvailable: networkAvailable),
                        if (config.weather.enabled && config.weather.type == WeatherType.floating && config.networkEnabled && networkAvailable) const Weather(type: WeatherType.floating),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
