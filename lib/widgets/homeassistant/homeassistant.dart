import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/status.dart' as status;

import 'package:smartclock/config/config.dart' show ConfigModel, Config;
import 'package:smartclock/main.dart';

class HomeAssistant extends StatefulWidget {
  const HomeAssistant({super.key});

  @override
  State<HomeAssistant> createState() => _HomeAssistantState();
}

class _HomeAssistantState extends State<HomeAssistant> {
  late Config config;
  late WebSocketChannel channel;

  bool showOverlay = false;

  void connectToHomeAssistant() async {
    final dio = Dio(BaseOptions(baseUrl: config.homeAssistant.url, headers: {"Authorization": "Bearer ${config.homeAssistant.token}"}));

    Response alive = await dio.get("/api/");
    if (alive.statusCode != 200 || alive.data["message"] != "API running.") {
      logger.w("[Home Assistant] Connection failed");
      return;
    }

    final webSocketUri = Uri.parse("${config.homeAssistant.url.replaceFirst("http", "ws")}/api/websocket");
    channel = WebSocketChannel.connect(webSocketUri);
    await channel.ready;

    logger.t("[Home Assistant] Connected successfully");
    channel.stream.listen((message) {
      logger.t("[Home Assistant] $message");

      final data = jsonDecode(message);

      switch (data['type']) {
        case "auth_required":
          channel.sink.add(jsonEncode({"type": "auth", "access_token": config.homeAssistant.token}));
          break;
        case "auth_invalid":
          channel.sink.close();
          break;
        case "auth_ok":
          logger.i("Sucessfully authenticated with Home Assistant");

          // Subscribe to input_button.smartclock_overlay_test trigger
          channel.sink.add(jsonEncode({
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
          setState(() {
            showOverlay = newValue == "on";
          });
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
  Widget build(BuildContext context) {
    if (!showOverlay) {
      return const Positioned(top: 0, left: 0, width: 0, height: 0, child: SizedBox.shrink());
    }

    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.white,
        child: const Center(child: Text("Test", style: TextStyle(fontSize: 100))),
      ),
    );
  }
}
