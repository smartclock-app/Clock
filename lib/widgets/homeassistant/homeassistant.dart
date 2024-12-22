import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:smartclock/config/config.dart' show ConfigModel, Config;
import 'package:smartclock/main.dart';

class HomeAssistant extends StatefulWidget {
  const HomeAssistant({super.key});

  @override
  State<HomeAssistant> createState() => _HomeAssistantState();
}

class _HomeAssistantState extends State<HomeAssistant> {
  late Config config;
  late WebSocketChannel _channel;
  StreamSubscription? _subscription;

  final OverlayPortalController _cameraOverlayController = OverlayPortalController();

  void connectToHomeAssistant() async {
    final dio = Dio(BaseOptions(baseUrl: config.homeAssistant.url, headers: {"Authorization": "Bearer ${config.homeAssistant.token}"}));

    Response alive = await dio.get("/api/");
    if (alive.statusCode != 200 || alive.data["message"] != "API running.") {
      logger.w("[Home Assistant] Connection failed");
      return;
    }

    final webSocketUri = Uri.parse("${config.homeAssistant.url.replaceFirst("http", "ws")}/api/websocket");
    _channel = WebSocketChannel.connect(webSocketUri);
    await _channel.ready;

    logger.t("[Home Assistant] Connected successfully");
    _subscription = _channel.stream.listen((message) {
      logger.t("[Home Assistant] $message");

      final data = jsonDecode(message);

      switch (data['type']) {
        case "auth_required":
          _channel.sink.add(jsonEncode({"type": "auth", "access_token": config.homeAssistant.token}));
          break;
        case "auth_invalid":
          _channel.sink.close();
          break;
        case "auth_ok":
          logger.i("[Home Assistant] Authenticated sucessfully");

          _channel.sink.add(jsonEncode({
            "id": 1,
            "type": "subscribe_trigger",
            "trigger": {
              "platform": "state",
              "entity_id": "input_boolean.smart_clock_overlay_test",
            },
          }));

          break;
        case 'event':
          final newValue = data['event']['variables']['trigger']['to_state']['state'];
          if (newValue == "on") {
            _cameraOverlayController.show();
          } else {
            _cameraOverlayController.hide();
          }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    config = context.read<ConfigModel>().config;
    connectToHomeAssistant();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _cameraOverlayController,
      overlayChildBuilder: (context) {
        return Container(
          color: Colors.white,
          child: const Center(child: Text("Test", style: TextStyle(fontSize: 100))),
        );
      },
    );
  }
}
