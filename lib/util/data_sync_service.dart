// util/data_sync_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/io.dart';
import 'package:smartclock/websocket/websocket_manager.dart';
import 'package:smartclock/util/logger_util.dart';

class DataSyncService {
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;

  final Map<String, dynamic> _data = {};
  final Map<String, StreamController> _controllers = {};
  Logger logger = LoggerUtil.logger;

  bool _isHost = false;
  bool get isHost => _isHost;

  IOWebSocketChannel? _hostConnection;
  final WebSocketManager _manager = WebSocketManager();

  DataSyncService._internal();

  Future<void> initialize({required bool isHost, required String hostUri}) async {
    _isHost = isHost;

    _manager.commands.addCommand('sync', (command) {
      final endpoint = command.headers?['endpoint'];

      // Handle initial data request from clients
      if (endpoint == 'get_initial_data') {
        return jsonEncode(_data);
      }

      // Handle regular sync updates
      if (endpoint != null && command.data != null) {
        _handleSyncData(endpoint, command.data!);
      }

      return 'Sync processed';
    });

    if (!isHost && hostUri.isNotEmpty) {
      await _connectToHost(hostUri);
    }
  }

  Future<void> _connectToHost(String hostUri) async {
    try {
      final ws = await WebSocket.connect(hostUri);
      _hostConnection = IOWebSocketChannel(ws);

      _hostConnection!.stream.listen(
        (event) {
          final command = WebSocketCommand.fromEvent(event);
          if (command.command != 'sync') return;

          final endpoint = command.headers?['endpoint'];
          if (endpoint == null || command.data == null) {
            logger.w('Invalid sync command received');
            return;
          }

          logger.i("[Data Sync] Received sync from host for $endpoint");
          _handleSyncData(endpoint, command.data!);
        },
        onDone: () {
          logger.i('Disconnected from host');
          _hostConnection = null;
        },
        onError: (error) {
          logger.e('Error in host connection: $error');
          _hostConnection = null;
        },
      );

      // Request initial data for all current endpoints
      _hostConnection!.sink.add(
        WebSocketCommand(
          command: 'sync',
          headers: {'endpoint': 'get_initial_data'},
        ).asResponse(),
      );

      logger.i('Connected to host');
    } catch (e) {
      logger.w('Failed to connect to host: $e');
      _hostConnection = null;
    }
  }

  Stream<T> watchData<T>({
    required String endpoint,
    required Future<T> Function() fetcher,
  }) {
    if (!_controllers.containsKey(endpoint)) {
      _controllers[endpoint] = StreamController<T>.broadcast(
        onListen: () {
          if (_data.containsKey(endpoint)) {
            _controllers[endpoint]!.add(_data[endpoint]);
          }
        },
      );

      // If we're the host or a client not connected to a host, and there's no data, fetch it
      if ((_isHost || _hostConnection == null) && !_data.containsKey(endpoint)) {
        fetcher().then((data) {
          _updateData(endpoint, data);
        });
      }
    }

    return _controllers[endpoint]!.stream as Stream<T>;
  }

  Future<void> refreshData<T>({
    required String endpoint,
    required Future<T> Function() fetcher,
  }) async {
    if (!_isHost) return; // Only host can refresh data

    final data = await fetcher();
    _updateData(endpoint, data);
  }

  void _updateData<T>(String endpoint, T data) {
    _data[endpoint] = data;

    if (_controllers.containsKey(endpoint)) {
      _controllers[endpoint]!.add(data);
    }

    // Broadcast to clients if we're the host
    if (_isHost) {
      final command = WebSocketCommand(
        command: 'sync',
        data: jsonEncode(data),
        headers: {'endpoint': endpoint},
      );

      for (final client in _manager.clients) {
        client.add(command.asResponse());
      }
    }
  }

  void _handleSyncData(String endpoint, String rawData) {
    try {
      final data = jsonDecode(rawData);

      _data[endpoint] = data;

      if (_controllers.containsKey(endpoint)) {
        _controllers[endpoint]!.add(data);
      }
    } catch (e) {
      logger.w('Failed to process sync data: $e');
    }
  }

  void dispose() {
    _hostConnection?.sink.close();

    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}
