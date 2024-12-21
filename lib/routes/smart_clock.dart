import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:smartclock/main.dart' show logger;
import 'package:smartclock/config/config.dart' show ConfigModel, WeatherType;
import 'package:smartclock/routes/editor.dart';
import 'package:smartclock/routes/logs.dart';
import 'package:smartclock/widgets/clock/clock.dart';
import 'package:smartclock/widgets/homeassistant/homeassistant.dart';
import 'package:smartclock/widgets/sidebar/sidebar.dart';
import 'package:smartclock/widgets/weather/weather.dart';
import 'package:smartclock/websocket/websocket_manager.dart';

class ScrollWithMouseBehavior extends MaterialScrollBehavior {
  const ScrollWithMouseBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.touch,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };
}

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
    logger.t('Connectivity changed: $result');
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigModel>().config;

    return MaterialApp(
      title: 'SmartClock',
      theme: ThemeData(scaffoldBackgroundColor: Colors.black, fontFamily: "Poppins"),
      debugShowCheckedModeBanner: false,
      scrollBehavior: const ScrollWithMouseBehavior(),
      routes: {
        '/editor': (context) => const Editor(),
        '/logs': (context) => const LogViewer(),
      },
      home: Scaffold(
        body: Container(
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
                      if (config.homeAssistant.enabled && config.networkEnabled && networkAvailable) const HomeAssistant(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
