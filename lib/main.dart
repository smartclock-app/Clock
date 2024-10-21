import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:json_schema/json_schema.dart';

import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;

import 'package:smartclock/smart_clock.dart';
import 'package:smartclock/util/logger.dart';
import 'package:smartclock/util/config.dart' show ConfigModel, Config;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supportDir = await getApplicationSupportDirectory();
  final docsDir = await getApplicationDocumentsDirectory();
  final confDir = Directory(path.join(docsDir.path, 'SmartClock'));
  if (!confDir.existsSync()) confDir.createSync(recursive: true);
  logger.i("Support Directory: ${supportDir.path}");
  logger.i("Config Directory: ${confDir.path}");

  final schemaFile = File(path.join(confDir.path, "schema.json"));
  final schema = await rootBundle.loadString("assets/schema.json");
  schemaFile.writeAsStringSync(schema);

  final confFile = File(path.join(confDir.path, "config.json"));
  if (!confFile.existsSync()) Config.empty(confFile).save();

  final cookieFile = File(path.join(supportDir.path, "cookies.json"));
  if (!cookieFile.existsSync()) cookieFile.writeAsStringSync("{}");

  final configSchema = JsonSchema.create(schema);
  final results = configSchema.validate(confFile.readAsStringSync(), parseJson: true);
  if (!results.isValid) {
    logger.w("Config file is invalid. Created missing keys.");
    logger.t(results.errors);

    Map<String, dynamic> config = jsonDecode(confFile.readAsStringSync());
    final exampleConfig = Config.empty(File("")).toJson();
    config = Config.merge(config, exampleConfig);
    Config.fromJson(confFile, config).save();
  }

  Database database = await openDatabase(
    path.join(supportDir.path, 'database.db'),
    onUpgrade: (db, _, __) async {
      final batch = db.batch();
      batch.execute("CREATE TABLE IF NOT EXISTS lyrics (id TEXT PRIMARY KEY, lyrics TEXT)");
      batch.execute("CREATE TABLE IF NOT EXISTS watchlist (id TEXT PRIMARY KEY UNIQUE, name TEXT, status TEXT, nextAirDate DATE)");
      await batch.commit();
      return;
    },
    version: 3,
  );

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

  // // LINUX BONJOUR DEPENDENCIES:
  // // avahi-daemon avahi-discover avahi-utils libnss-mdns mdns-scan
  // BonsoirService service = BonsoirService(
  //   name: "SC@${Platform.localHostname}",
  //   type: '_smartclock._tcp',
  //   port: 3030,
  // );
  // final broadcast = BonsoirBroadcast(service: service);
  // await broadcast.ready;
  // await broadcast.start();

  runApp(MultiProvider(
    providers: [
      // Provider<Config>.value(value: config),
      ChangeNotifierProvider(create: (context) => ConfigModel(config)),
      Provider<Database>.value(value: database),
      Provider<alexa.QueryClient>.value(value: client),
      // Push events to this stream to tell widgets to update
      Provider<StreamController<DateTime>>.value(value: StreamController<DateTime>.broadcast()),
    ],
    child: Consumer<ConfigModel>(
      builder: (context, value, child) => SmartClock(key: UniqueKey()),
    ),
  ));
}
