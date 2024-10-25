part of 'websocket_manager.dart';

class WebSocketCommand {
  final String command;
  final String? data;

  WebSocketCommand(this.command, this.data);

  factory WebSocketCommand.fromEvent(String event) {
    late List<String> csv;

    try {
      csv = event.split("~~");
    } on FormatException catch (_) {
      return WebSocketCommand("invalid_csv", null);
    }

    return WebSocketCommand(csv[0], csv.length > 1 ? csv[1] : null);
  }
}

typedef WebSocketCommandHandler = String? Function(WebSocketCommand command);

class WebSocketHandler {
  final Map<String, WebSocketCommandHandler> routes = {};

  void addCommand(String command, WebSocketCommandHandler handler) {
    routes[command] = handler;
  }

  String handle(WebSocketCommand command) {
    return routes[command.command]?.call(command) ?? "Invalid command";
  }
}
