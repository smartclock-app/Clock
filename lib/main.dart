import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';
// ignore: unused_import --- Needed for sqlite3 on android
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;

import 'package:smartclock/config/config.dart' show ConfigModel, Config;
import 'package:smartclock/routes/smart_clock.dart';
import 'package:smartclock/util/logger_output.dart';
import 'package:smartclock/util/event_utils.dart';
import 'package:smartclock/util/file_utils.dart';

late Logger logger;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final Directory appDir = await getApplicationDirectory();

  final loggerOutput = LoggerOutput(file: File(path.join(appDir.path, "logs.txt")), overrideExisting: true);
  logger = Logger(
    level: Level.all,
    filter: ProductionFilter(),
    printer: SimplePrinter(printTime: true, colors: false),
    output: loggerOutput,
  );

  if (!appDir.existsSync()) appDir.createSync(recursive: true);
  logger.i("Application Directory: ${appDir.path}");

  final schemaFile = File(path.join(appDir.path, "schema.json"));
  final schema = await rootBundle.loadString("assets/schema.json");
  schemaFile.writeAsStringSync(schema);

  final confFile = File(path.join(appDir.path, "config.json"));
  if (!confFile.existsSync()) {
    Config.asDefault(confFile).save();
  }

  final cookieFile = File(path.join(appDir.path, "cookies.json"));
  if (!cookieFile.existsSync()) cookieFile.writeAsStringSync("{}");

  // Read config from disk, merge with default config to ensure all fields are present
  final configJson = jsonDecode(confFile.readAsStringSync());
  final exampleConfig = Config.asDefault(File("")).toJson();
  final mergedJson = Config.merge(configJson, exampleConfig);
  final config = Config.fromJson(confFile, mergedJson)..save();

  Database database = sqlite3.open(path.join(appDir.path, 'database.db'));
  database.execute(
      "CREATE TABLE IF NOT EXISTS lyrics (id TEXT PRIMARY KEY, lyrics TEXT); CREATE TABLE IF NOT EXISTS watchlist (id TEXT PRIMARY KEY UNIQUE, name TEXT, status TEXT, nextAirDate DATE)");

  final client = alexa.QueryClient(
    cookieFile,
    loginToken: config.alexa.token,
    logger: (log, level) {
      switch (level) {
        case "trace":
          logger.t("[AlexaQuery] $log");
          break;
        case "info":
          logger.i("[AlexaQuery] $log");
          break;
        case "warn":
          logger.w("[AlexaQuery] $log");
          break;
        case "error":
          logger.e("[AlexaQuery] $log");
          break;
        default:
          logger.i("[AlexaQuery] $log");
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
  final display = WidgetsBinding.instance.platformDispatcher.views.first;
  final width = display.physicalSize.width / display.devicePixelRatio;
  final height = display.physicalSize.height / display.devicePixelRatio;
  logger.i("Window Resolution: ${width.toInt()}x${height.toInt()}");

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => ConfigModel(config, client: client, appDir: appDir)),
      Provider<Database>.value(value: database),
      Provider<alexa.QueryClient>.value(value: client),
      // Push events to this stream to tell widgets to update
      Provider<StreamController<ClockEvent>>.value(value: StreamController<ClockEvent>.broadcast()),
    ],
    child: const SmartClock(),
  ));
}
