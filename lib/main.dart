import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';
import 'package:json_schema/json_schema.dart';
import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;

import 'package:smartclock/smart_clock.dart';
import 'package:smartclock/util/logger.dart';
import 'package:smartclock/util/config.dart' show ConfigModel, Config;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  late final Directory appDir;
  if ((Platform.isMacOS || Platform.isLinux) && Platform.environment['HOME'] != null) {
    appDir = Directory(path.join(Platform.environment['HOME']!, '.smartclock'));
  } else if (Platform.isWindows && Platform.environment['APPDATA'] != null) {
    appDir = Directory(path.join(Platform.environment['APPDATA']!, 'SmartClock'));
  } else {
    final documentsDir = await getApplicationDocumentsDirectory();
    appDir = Directory(path.join(documentsDir.path, 'SmartClock'));
  }

  if (!appDir.existsSync()) appDir.createSync(recursive: true);
  logger.i("Application Directory: ${appDir.path}");

  final schemaFile = File(path.join(appDir.path, "schema.json"));
  final schema = await rootBundle.loadString("assets/schema.json");
  schemaFile.writeAsStringSync(schema);

  final confFile = File(path.join(appDir.path, "config.json"));
  // TODO: Remove this when remoteConfig is finished.
  if (Platform.isIOS) {
    // Writes pre-filled config file to device.
    final confJson = await rootBundle.loadString("assets/iphone13.json");
    confFile.writeAsStringSync(confJson);
  } else if (!confFile.existsSync()) {
    Config.asDefault(confFile).save();
  }

  final cookieFile = File(path.join(appDir.path, "cookies.json"));
  if (!cookieFile.existsSync()) cookieFile.writeAsStringSync("{}");

  final configJson = jsonDecode(confFile.readAsStringSync());
  final configSchema = JsonSchema.create(schema);
  final results = configSchema.validate(configJson);

  if (!results.isValid) {
    logger.w("Config file is invalid. Created missing keys.");
    logger.t(results.errors);

    final exampleConfig = Config.asDefault(File("")).toJson();
    final mergedJson = Config.merge(configJson, exampleConfig);
    Config.fromJson(confFile, mergedJson).save();
  }

  Database database = sqlite3.open(path.join(appDir.path, 'database.db'));
  database.execute(
      "CREATE TABLE IF NOT EXISTS lyrics (id TEXT PRIMARY KEY, lyrics TEXT); CREATE TABLE IF NOT EXISTS watchlist (id TEXT PRIMARY KEY UNIQUE, name TEXT, status TEXT, nextAirDate DATE)");

  final config = Config.fromJson(confFile, jsonDecode(confFile.readAsStringSync()));
  final client = alexa.QueryClient(
    cookieFile,
    loginToken: config.alexa.token,
    logger: (log, level) {
      switch (level) {
        case "trace":
          logger.t(log);
          break;
        case "info":
          logger.i(log);
          break;
        case "warn":
          logger.w(log);
          break;
        case "error":
          logger.e(log);
          break;
        default:
          logger.i(log);
      }
    },
  );

  if (config.orientation == Orientation.landscape) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  } else {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Get display resolution and pixel ratio
  late final double xSize, ySize;
  final display = WidgetsBinding.instance.platformDispatcher.views.first;
  final width = display.physicalSize.width / display.devicePixelRatio;
  final height = display.physicalSize.height / display.devicePixelRatio;
  final widerThanTall = width >= height;
  logger.i("Window Resolution: ${width.toInt()}x${height.toInt()}");

  // Set the resolution based on the orientation
  // If device starts with orientation opposite of config, swap the values
  if ((widerThanTall && config.orientation == Orientation.landscape) || (!widerThanTall && config.orientation == Orientation.portrait)) {
    xSize = width;
    ySize = height;
  } else {
    xSize = height;
    ySize = width;
  }

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => ConfigModel(config, client: client)),
      Provider<Database>.value(value: database),
      Provider<alexa.QueryClient>.value(value: client),
      // Push events to this stream to tell widgets to update
      Provider<StreamController<DateTime>>.value(value: StreamController<DateTime>.broadcast()),
    ],
    child: Consumer<ConfigModel>(
      builder: (context, value, child) => SmartClock(
        key: UniqueKey(),
        resolution: (x: xSize, y: ySize),
      ),
    ),
  ));
}
