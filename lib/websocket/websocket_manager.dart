import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:bonsoir/bonsoir.dart';
import 'package:provider/provider.dart';

import 'package:smartclock/main.dart' show logger;
import 'package:smartclock/config/config.dart';
import 'package:smartclock/util/event_utils.dart';
import 'package:smartclock/websocket/commands/toggle_display.dart';

part 'websocket_handler.dart';

class WebSocketManager {
  HttpServer? server;
  late ConfigModel configModel;
  BonsoirBroadcast? _broadcast;
  late final WebSocketHandler commands;

  WebSocketManager(BuildContext context) {
    configModel = context.read<ConfigModel>();
    commands = WebSocketHandler();

    commands.addCommand('echo', (command) => command.data ?? "No data provided");
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
      final newConfig = Config.fromJson(configModel.config.file, jsonDecode(command.data!));
      configModel.setConfig(newConfig);
      return "Config updated";
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
    BonsoirService service = BonsoirService(
      name: config.remoteConfig.bonjourName ?? Platform.localHostname,
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
    logger.i("WebSocket server started on port ${configModel.config.remoteConfig.port}");
  }

  void onWebSocketData(WebSocket webSocket) {
    webSocket.listen(
      (event) async {
        final command = WebSocketCommand.fromEvent(event);
        logger.t("Received command: ${command.command}");

        final config = configModel.config;
        if (config.remoteConfig.password.isNotEmpty && command.headers?['password'] != config.remoteConfig.password) {
          webSocket.add("Invalid password");
          return;
        }

        final response = await commands.handle(command);
        webSocket.add(response);
      },
      onError: (error) => logger.e("WebSocket error: $error"),
      onDone: () => logger.i("WebSocket connection closed"),
    );
  }

  void dispose() {
    server?.close(force: true);
    _broadcast?.stop();
  }
}
