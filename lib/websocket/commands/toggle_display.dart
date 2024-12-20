import 'dart:convert';
import 'dart:io';

Future<String> getDisplayStatus({String? script}) async {
  if (script == null) return "Script not found";

  final process = await Process.start(script, ["-q"]);

  if (!await process.stderr.isEmpty) {
    final error = await process.stderr.transform(utf8.decoder).join();
    return error;
  } else {
    final result = await process.stdout.transform(utf8.decoder).join();
    return result;
  }
}

Future<String> toggleDisplay({String? script, bool? value}) async {
  if (script == null) return "Script not found";

  final process = await Process.start(script, [
    if (value != null) ...["-p", value ? "on" : "off"]
  ]);

  if (!await process.stderr.isEmpty) {
    final error = await process.stderr.transform(utf8.decoder).join();
    return error;
  } else {
    final result = await process.stdout.transform(utf8.decoder).join();
    return result;
  }
}
