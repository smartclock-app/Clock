import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:path/path.dart' as path;
import 'package:bonsoir/bonsoir.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'package:smartclock/config/config.dart';
import 'package:smartclock/util/event_utils.dart';
import 'package:smartclock/util/logger_util.dart';
import 'package:smartclock/websocket/commands/get_logs.dart';
import 'package:smartclock/websocket/commands/toggle_display.dart';

part 'websocket_handler.dart';

class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;

  HttpServer? server;
  late ConfigModel configModel;
  BonsoirBroadcast? _broadcast;
  final WebSocketHandler commands = WebSocketHandler();
  Logger logger = LoggerUtil.logger;
  final List<WebSocket> clients = [];
  bool isInitalised = false;

  WebSocketManager._internal();

  void initialise(BuildContext context) {
    if (isInitalised) return;
    isInitalised = true;

    configModel = context.read<ConfigModel>();

    commands.addCommand('echo', (command) => command.data ?? "No data provided");
    commands.addCommand('get_commands', (command) => commands.commands.join('\n'));
    commands.addCommand('refresh', (command) {
      configModel.notifyListeners();
      return "Clock refreshed";
    });
    commands.addCommand('toggle_display', (command) {
      return toggleDisplay(
        script: configModel.config.remoteConfig.toggleDisplayPath,
        value: command.data != null ? bool.tryParse(command.data!) : null,
      );
    });
    commands.addCommand('get_display_status', (command) {
      return getDisplayStatus(
        script: configModel.config.remoteConfig.toggleDisplayPath,
      );
    });
    commands.addCommand('skip_photo', (command) {
      context.read<StreamController<ClockEvent>>().add((time: DateTime.now(), event: ClockEvents.skipPhoto));
      return "Photo skipped";
    });
    commands.addCommand('get_config', (command) => jsonEncode(configModel.config));
    commands.addCommand('set_config', (command) {
      final newConfig = Config.fromJsonValidated(configModel.config.file, jsonDecode(command.data!));
      configModel.setConfig(newConfig);
      return "Config updated";
    });
    commands.addCommand('get_logs', (command) {
      final file = File(path.join(configModel.appDir.path, "logs.txt"));
      return getLogPage(command.data, file);
    });

    _initServer();

    final config = configModel.config;
    if (config.remoteConfig.useBonjour) {
      _initBonjour(config).then((broadcast) => _broadcast = broadcast);
    }
  }

  Future<BonsoirBroadcast> _initBonjour(Config config) async {
    // LINUX BONJOUR DEPENDENCIES:
    // avahi-daemon avahi-discover avahi-utils libnss-mdns mdns-scan
    final bonjourName = config.remoteConfig.bonjourName;
    BonsoirService service = BonsoirService(
      name: bonjourName.isEmpty ? Platform.localHostname : bonjourName,
      type: '_smartclock._tcp',
      port: config.remoteConfig.port,
      attributes: {
        'platform': Platform.operatingSystem,
        'protected': config.remoteConfig.password.isNotEmpty.toString(),
      },
    );
    final broadcast = BonsoirBroadcast(service: service);
    await broadcast.ready;
    await broadcast.start();
    return broadcast;
  }

  void _initServer() async {
    server = await HttpServer.bind(InternetAddress.anyIPv4, configModel.config.remoteConfig.port);
    server?.transform(WebSocketTransformer()).listen(onWebSocketData);
    logger.i("[Remote Config] WebSocket server started on port ${configModel.config.remoteConfig.port}");
  }

  void onWebSocketData(WebSocket webSocket) {
    clients.add(webSocket);

    webSocket.listen(
        (event) async {
          final command = WebSocketCommand.fromEvent(event);
          logger.t("[Remote Config] Received ${command.command}");

          final config = configModel.config;
          if (config.remoteConfig.password.isNotEmpty && command.headers?['password'] != config.remoteConfig.password) {
            webSocket.add("Invalid password");
            return;
          }

          final response = await commands.handle(command);
          webSocket.add(response);
        },
        onError: (error) => logger.e("[Remote Config] WebSocket error: $error"),
        onDone: () {
          logger.i("[Remote Config] WebSocket connection closed");
          clients.remove(webSocket);
        });
  }

  void dispose() {
    server?.close(force: true);
    _broadcast?.stop();
  }
}
