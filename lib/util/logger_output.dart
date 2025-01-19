import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

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

    // Write to stream
    if (shouldBroadcast) _streamController.add(event.lines);

    // Write to file
    _sink?.writeAll(event.lines, '\n');
    _sink?.writeln();
  }

  @override
  Future<void> destroy() async {
    // Cleanup file
    await _sink?.flush();
    await _sink?.close();
  }
}
