import 'dart:io';

import 'package:dio/dio.dart';
import 'package:install_plugin/install_plugin.dart';
import 'package:path_provider/path_provider.dart';

void installApk({required String url, required void Function(int, int) onDownloadProgress, required void Function(String) callback}) async {
  var appDocDir = await getTemporaryDirectory();

  final urlHash = url.hashCode.toRadixString(16);
  String savePath = "${appDocDir.path}/smartclock-$urlHash.apk";

  if (!File(savePath).existsSync()) {
    // Doesn't matter if the token is leaked, only has read access to a repo that will soon become public
    const githubToken = "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";
    await Dio().download(url, savePath, onReceiveProgress: onDownloadProgress, options: Options(headers: {"Authorization": "Bearer $githubToken", "Accept": "application/octet-stream"}));
  }

  final res = await InstallPlugin.install(savePath);
  callback("Update ${res['isSuccess'] == true ? 'Succeeded' : 'Failed: ${res['errorMessage'] ?? ''}'}");
}
