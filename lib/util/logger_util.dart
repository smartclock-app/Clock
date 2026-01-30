import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class LoggerUtil {
  static bool isInitialized = false;
  static late final Logger _logger;

  static init(Logger logger) {
    isInitialized = true;
    _logger = logger;
  }

  static Logger get logger {
    if (!isInitialized) {
      throw Exception("Logger is not initialized");
    }
    return _logger;
  }
}

class LoggerOutput extends LogOutput {
  final File file;
  final bool overrideExisting;
  final Encoding encoding;
  IOSink? _sink;

  static bool shouldBroadcast = false;
  static final StreamController<List<String>> _streamController = StreamController<List<String>>.broadcast(
    onListen: () => shouldBroadcast = true,
    onCancel: () => shouldBroadcast = false,
  );
  static Stream<List<String>> get stream => _streamController.stream;

  LoggerOutput({
    required this.file,
    this.overrideExisting = false,
    this.encoding = utf8,
  });

  @override
  Future<void> init() async {
    // Init file
    _sink = file.openWrite(
      mode: overrideExisting ? FileMode.writeOnly : FileMode.writeOnlyAppend,
      encoding: encoding,
    );
  }

  @override
  void output(OutputEvent event) {
    // Write to console
    event.lines.forEach(debugPrint);

    // Write to stream (in-memory broadcast). Guard to avoid exceptions
    try {
      if (shouldBroadcast) {
        // Dispatch asynchronously to avoid re-entrancy that can cause
        // downstream consumers (for example SSE handlers) to write to
        // HTTP responses while the logger is still in the middle of
        // handling an event. Scheduling on the microtask queue decouples
        // the emission and prevents "StreamSink is bound to a stream"
        // style errors caused by synchronous re-entry.
        scheduleMicrotask(() {
          try {
            _streamController.add(event.lines);
          } catch (e) {
            debugPrint('LoggerOutput: failed to broadcast to stream async: $e');
          }
        });
      }
    } catch (e) {
      // Swallow stream errors to avoid crashing the app; print to console for diagnostics.
      debugPrint('LoggerOutput: failed to schedule broadcast: $e');
    }

    // Write to file. Wrap in try/catch because underlying IOSink may throw
    // (for example if bound to a stream via addStream elsewhere).
    try {
      _sink?.writeAll(event.lines, '\n');
      _sink?.writeln();
    } catch (e, st) {
      debugPrint('LoggerOutput: failed to write to file sink: $e\n$st');
    }
  }

  @override
  Future<void> destroy() async {
    // Cleanup file
    await _sink?.flush();
    await _sink?.close();
  }
}
