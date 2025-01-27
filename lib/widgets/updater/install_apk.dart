import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

void installApk({required String url, required void Function(int, int) onDownloadProgress, required void Function(String) callback}) async {
  var appDocDir = await getTemporaryDirectory();

  final urlHash = url.hashCode.toRadixString(16);
  String savePath = "${appDocDir.path}/smartclock-$urlHash.apk";

  if (!File(savePath).existsSync()) {
    await Dio().download(url, savePath, onReceiveProgress: onDownloadProgress, options: Options(headers: {"Accept": "application/octet-stream"}));
  }

  try {
    final result = await OpenFilex.open(savePath);
    if (result.type != ResultType.done) {
      callback("Error opening APK: ${result.message}");
    } else {
      callback("APK opened successfully");
    }
  } catch (e) {
    callback("Error opening APK: $e");
  }
}
