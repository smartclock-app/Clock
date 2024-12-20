import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<Directory> getApplicationDirectory() async {
  if ((Platform.isMacOS || Platform.isLinux) && Platform.environment['HOME'] != null) {
    return Directory(path.join(Platform.environment['HOME']!, '.smartclock'));
  } else if (Platform.isWindows && Platform.environment['APPDATA'] != null) {
    return Directory(path.join(Platform.environment['APPDATA']!, 'SmartClock'));
  } else {
    final documentsDir = await getApplicationDocumentsDirectory();
    return Directory(path.join(documentsDir.path, 'SmartClock'));
  }
}
