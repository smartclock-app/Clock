import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:logger/logger.dart';

import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:smartclock/config/config.dart' show Config, ConfigModel, WeatherType;
import 'package:smartclock/routes/editor.dart';
import 'package:smartclock/routes/logs.dart';
import 'package:smartclock/util/auto_dimensions.dart';
import 'package:smartclock/util/logger_util.dart';
import 'package:smartclock/widgets/clock/clock.dart';
import 'package:smartclock/widgets/sidebar/sidebar.dart';
import 'package:smartclock/widgets/weather/weather.dart';
import 'package:smartclock/remote/http_server.dart';
import 'package:smartclock/remote/command_service.dart';

class SmartClock extends StatefulWidget {
  const SmartClock({super.key});

  @override
  State<SmartClock> createState() => _SmartClockState();
}

class _SmartClockState extends State<SmartClock> {
  bool networkAvailable = true;
  late final Config config;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Logger logger = LoggerUtil.logger;

  @override
  void initState() {
    super.initState();

    config = context.read<ConfigModel>().config;

    if (config.checkNetwork) {
      initConnectivity();
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    }

    final configModel = context.read<ConfigModel>();
    if (configModel.config.remoteConfig.enabled) {
      // Start the HTTP-based remoteConfig server (JSON + Basic Auth)
      remoteConfigHttpServer.start(context);
      // Wire app-specific command handlers into the transport-agnostic CommandService
      // so existing commands remain available over HTTP.
      commandService.registerAppBindings(context);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    // Ensure the remote config HTTP server is stopped when the widget is disposed.
    remoteConfigHttpServer.stop();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      logger.w('[Network] Couldn\'t check connectivity status', error: e);
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
    logger.t('[Network] Connection\'s Available: $result');
  }

  @override
  Widget build(BuildContext context) {
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
                    final width = resolution.width;
                    final height = resolution.height;
                    logger.i("[Resolution] Safe Area: ${width.toInt()}x${height.toInt()}");

                    computeDefaultDimensions(config: config, width: width, height: height);

                    return Stack(
                      children: [
                        Clock(networkAvailable: networkAvailable),
                        if (config.sidebar.enabled) Sidebar(networkAvailable: networkAvailable),
                        if (config.weather.enabled && config.weather.type == WeatherType.floating && networkAvailable) const Weather(type: WeatherType.floating),
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
