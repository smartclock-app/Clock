import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';

class LoggerOutput extends LogOutput {
  // Stream output dependencies
  late StreamController<List<String>> _controller;
  bool _shouldForward = false;

  // File output dependencies
  final File file;
  final bool overrideExisting;
  final Encoding encoding;
  IOSink? _sink;

  LoggerOutput({
    required this.file,
    this.overrideExisting = false,
    this.encoding = utf8,
  }) {
    // Init stream
    _controller = StreamController<List<String>>(
      onListen: () => _shouldForward = true,
      onPause: () => _shouldForward = false,
      onResume: () => _shouldForward = true,
      onCancel: () => _shouldForward = false,
    );
  }

  Stream<List<String>> get stream => _controller.stream;

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
    event.lines.forEach(print);

    // Add to stream
    if (_shouldForward) _controller.add(event.lines);

    // Write to file
    _sink?.writeAll(event.lines, '\n');
    _sink?.writeln();
  }

  @override
  Future<void> destroy() async {
    // Cleanup stream
    await _controller.close();

    // Cleanup file
    await _sink?.flush();
    await _sink?.close();
  }
}
