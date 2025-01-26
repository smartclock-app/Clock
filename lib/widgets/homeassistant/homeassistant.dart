import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:smartclock/config/config.dart' show ConfigModel, Config, Camera;
import 'package:smartclock/util/event_utils.dart';
import 'package:smartclock/util/logger_util.dart';
import 'package:smartclock/widgets/homeassistant/camera.dart';

class HomeAssistant extends StatefulWidget {
  const HomeAssistant({super.key});

  bool get platformIsSupported => Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  @override
  State<HomeAssistant> createState() => _HomeAssistantState();
}

class _HomeAssistantState extends State<HomeAssistant> {
  late Config config;
  Logger logger = LoggerUtil.logger;
  late WebSocketChannel _channel;
  StreamSubscription? _eventSubscription;
  StreamSubscription? _webSocketSubscription;
  final List<(Uri, Camera)> cameras = [];
  final Map<int, Camera> _messageIds = {};
  bool isConnected = false;
  int messageId = 1;
  (DateTime?, int) _reconnectAttempt = (null, 0);

  final OverlayPortalController _cameraOverlayController = OverlayPortalController();

  bool get shouldAttemptReconnect {
    if (_reconnectAttempt.$1 == null) return true;
    final diff = DateTime.now().difference(_reconnectAttempt.$1!);
    return diff.inSeconds >= min(30 * _reconnectAttempt.$2, 300);
  }

  void connectToHomeAssistant() async {
    final dio = Dio(BaseOptions(
      baseUrl: config.homeAssistant.url,
      headers: {"Authorization": "Bearer ${config.homeAssistant.token}"},
    ));

    try {
      Response alive = await dio.get("/api/");
      if (alive.statusCode != 200 || alive.data["message"] != "API running.") {
        logger.w("[Home Assistant] Connection failed");
        return;
      }
    } on DioException catch (e) {
      logger.w("[Home Assistant] Connection failed: ${e.response?.statusCode} ${e.response?.statusMessage}");
      _reconnectAttempt = (DateTime.now(), _reconnectAttempt.$2 + 1);
      logger.w("[Home Assistant] Waiting ${30 * _reconnectAttempt.$2} seconds before reconnecting");
      return;
    }

    final webSocketUri = Uri.parse("${config.homeAssistant.url.replaceFirst("http", "ws")}/api/websocket");
    _channel = WebSocketChannel.connect(webSocketUri);
    await _channel.ready;

    logger.t("[Home Assistant] Connected successfully");
    isConnected = true;
    _webSocketSubscription = _channel.stream.listen(
      handleMessage,
      onDone: () {
        logger.t("[Home Assistant] Connection closed");
        isConnected = false;
      },
    );
  }

  void handleMessage(dynamic message) async {
    logger.t("[Home Assistant] $message");

    final data = jsonDecode(message);

    switch (data['type']) {
      // Called on first connection
      case "auth_required":
        _channel.sink.add(jsonEncode({"type": "auth", "access_token": config.homeAssistant.token}));
        break;

      // Called if authentication fails
      case "auth_invalid":
        _channel.sink.close();
        break;

      // Called if authentication succeeds
      case "auth_ok":
        for (final camera in config.homeAssistant.cameras) {
          _channel.sink.add(jsonEncode({
            "id": messageId++,
            "type": "subscribe_trigger",
            "trigger": {
              "platform": "state",
              "entity_id": camera.trigger,
            },
          }));
        }

        break;

      // Called when trigger state changes
      case 'event':
        messageId += 1;
        final trigger = data?['event']?['variables']?['trigger'];
        final entityId = trigger?['entity_id'];
        final state = trigger?['to_state']?['state'];
        if (state == "on") {
          final camera = config.homeAssistant.cameras.firstWhere((camera) => camera.trigger == entityId);

          if (camera.streamUri != null) {
            final streamUri = Uri.parse(camera.streamUri!);
            cameras.add((streamUri, camera));
            _cameraOverlayController.show();
          } else {
            _messageIds[messageId] = camera; // Store camera with message id for use with result
            _channel.sink.add(jsonEncode({"id": messageId, "type": "camera/stream", "entity_id": camera.id}));
          }
        } else {
          final waitTime = config.homeAssistant.cameraWaitTime;
          await Future.delayed(Duration(seconds: waitTime));
          if (!mounted) return;
          setState(() {
            cameras.removeWhere((camera) => camera.$2.trigger == entityId);
          });
          if (cameras.isEmpty) _cameraOverlayController.hide();
        }
        break;

      // Called with camera stream result
      case 'result':
        final id = data?['id'];
        final url = data?['result']?['url'];
        if (url != null) {
          final streamUri = Uri.parse('${config.homeAssistant.url}$url');
          final camera = _messageIds[id]!;
          cameras.add((streamUri, camera));
          _cameraOverlayController.show();
          _messageIds.remove(id); // Clear message id after use
        }
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    if (!widget.platformIsSupported) return;
    config = context.read<ConfigModel>().config;
    connectToHomeAssistant();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = context.read<StreamController<ClockEvent>>().stream;
    _eventSubscription?.cancel();
    _eventSubscription = stream.listen((event) {
      if (event.event == ClockEvents.refetch && !isConnected && shouldAttemptReconnect) {
        connectToHomeAssistant();
      }
    });
  }

  @override
  void dispose() {
    _webSocketSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.platformIsSupported) {
      return const SizedBox.shrink();
    }

    return OverlayPortal(
      controller: _cameraOverlayController,
      overlayChildBuilder: (context) {
        return Row(
          children: [
            for (final camera in cameras) ...[
              Expanded(child: HomeAssistantCamera(streamUri: camera.$1, aspectRatio: camera.$2.aspectRatio)),
            ]
          ],
        );
      },
    );
  }
}
