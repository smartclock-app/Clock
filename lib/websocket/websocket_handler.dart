part of 'websocket_manager.dart';

class WebSocketCommand {
  final String command;
  final String? data;
  final Map<String, String>? headers;

  WebSocketCommand({required this.command, this.data, this.headers});

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

    final headers = Map<String, String>.from(parsed)..removeWhere((key, _) => key == 'command' || key == 'data');

    return WebSocketCommand(
      command: parsed['command']!,
      data: parsed['data'],
      headers: headers.isNotEmpty ? headers : null,
    );
  }

  String asResponse() {
    final lines = <String>[];
    lines.add("command: $command");
    if (data != null) lines.add("data: $data");
    if (headers != null) {
      for (final entry in headers!.entries) {
        lines.add("${entry.key}: ${entry.value}");
      }
    }
    return lines.join("\n");
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
