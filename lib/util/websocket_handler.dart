part of 'websocket_manager.dart';

class WebSocketCommand {
  final String command;
  final String? data;

  WebSocketCommand({required this.command, this.data});

  factory WebSocketCommand.fromEvent(String event) {
    final Map<String, String> parsed = {};
    final lines = event.split('\n');

    for (final line in lines) {
      final colonIndex = line.indexOf(':');
      if (colonIndex == -1) continue;

      final key = line.substring(0, colonIndex).trim();
      final value = line.substring(colonIndex + 1).trim();
      parsed[key] = value;
    }

    if (parsed['command'] == null) {
      return WebSocketCommand(command: "invalid_command");
    }

    return WebSocketCommand(command: parsed['command']!, data: parsed['data']);
  }
}

typedef WebSocketCommandHandler = FutureOr<String?> Function(WebSocketCommand command);

class WebSocketHandler {
  final Map<String, WebSocketCommandHandler> routes = {};

  void addCommand(String command, WebSocketCommandHandler handler) {
    routes[command] = handler;
  }

  List<String> get commands => routes.keys.toList();

  FutureOr<String?> handle(WebSocketCommand command) {
    return routes[command.command]?.call(command) ?? "Invalid command";
  }
}
