import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;

import 'package:smartclock/config/config.dart' show ConfigModel, Config;
import 'package:smartclock/util/event_utils.dart';

import 'json_response.dart';
import 'commands/get_logs.dart' as logs_cmd;
import 'commands/toggle_display.dart' as display_cmd;

typedef CommandHandler = FutureOr<dynamic> Function(Map<String, dynamic>? data, Map<String, String>? headers);

/// A simple transport-agnostic command service.
///
/// Handlers return any JSON-serializable value or throw on error.
class CommandService {
  final Map<String, CommandHandler> _routes = {};

  void register(String name, CommandHandler handler) {
    _routes[name] = handler;
  }

  bool contains(String name) => _routes.containsKey(name);

  List<String> get commands => _routes.keys.toList()..sort();

  /// Handle a command by name. Returns a standardized JSON object map.
  Future<Map<String, dynamic>> handleCommand(String name, Map<String, dynamic>? data, Map<String, String>? headers) async {
    final handler = _routes[name];
    if (handler == null) return errorResponse('unknown command: $name');

    try {
      final result = await Future.value(handler(data, headers));
      return okResponse(result);
    } catch (e) {
      // Avoid leaking stack traces to clients in production; include message.
      return errorResponse(e.toString());
    }
  }

  /// Register a set of lightweight built-in handlers useful for migration.
  /// Additional handlers that call into app services should be registered
  /// by the caller (e.g., wiring existing command implementations).
  void registerDefaults() {
    register('echo', (data, headers) => data ?? '');

    register('get_commands', (data, headers) => commands.join('\n'));

    // get_config and set_config should be registered by the integrator
    // since they require access to the app's ConfigModel/IO.
  }

  /// Register application-specific handlers that depend on `ConfigModel` and `BuildContext`.
  void registerAppBindings(BuildContext context) {
    final configModel = context.read<ConfigModel>();

    register('refresh', (data, headers) {
      configModel.notifyListeners();
      return 'Clock refreshed';
    });

    register('toggle_display', (data, headers) {
      final value = data != null && data['value'] != null ? (data['value'] as bool?) : null;
      return display_cmd.toggleDisplay(script: configModel.config.remoteConfig.toggleDisplayPath, value: value);
    });

    register('get_display_status', (data, headers) => display_cmd.getDisplayStatus(script: configModel.config.remoteConfig.toggleDisplayPath));

    register('skip_photo', (data, headers) {
      context.read<StreamController<ClockEvent>>().add((time: DateTime.now(), event: ClockEvents.skipPhoto));
      return 'Photo skipped';
    });

    register('get_config', (data, headers) => jsonEncode(configModel.config));

    register('set_config', (data, headers) {
      final payload = data is Map<String, dynamic> ? data : <String, dynamic>{};
      final newConfig = Config.fromJsonValidated(configModel.config.file, payload);
      configModel.setConfig(newConfig);
      return 'Config updated';
    });

    register('get_logs', (data, headers) {
      final file = File(path.join(configModel.appDir.path, 'logs.txt'));
      final pageParam = data != null && data['page'] != null ? data['page'].toString() : null;
      return logs_cmd.getLogPage(pageParam, file);
    });
  }
}

final CommandService commandService = CommandService()..registerDefaults();
