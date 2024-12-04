import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<File?> getScript(String platform) async {
  try {
    final script = rootBundle.loadString("assets/display/$platform.sh");
    final tempDir = await getTemporaryDirectory();
    final file = File("${tempDir.path}/toggle_display_$platform.sh");
    if (!file.existsSync()) file.writeAsStringSync(await script);
    return file;
  } catch (e) {
    return null;
  }
}

// Placeholder function to toggle the display
Future<String> toggleDisplay(String platform) async {
  final script = await getScript(platform);
  if (script == null) return "Script not found";

  final process = await Process.start("sh", [script.path]);

  if (!await process.stderr.isEmpty) {
    final error = await process.stderr.transform(utf8.decoder).join();
    return error;
  } else {
    final result = await process.stdout.transform(utf8.decoder).join();
    return result;
  }
}
