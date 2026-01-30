// WebSocket parsing/handler removed.
// Remote config now uses HTTP+JSON endpoints. This file is retained as a stub
// so any remaining references fail fast and remind maintainers to use the
// `CommandService` in `lib/remote/command_service.dart`.

part of 'websocket_manager.dart';

class WebSocketCommand {}

typedef WebSocketCommandHandler = void Function();

class WebSocketHandler {
  WebSocketHandler() {
    throw UnsupportedError('WebSocketHandler removed; use CommandService instead.');
  }
}
