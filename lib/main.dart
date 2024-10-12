import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:json_schema/json_schema.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:sqflite/sqflite.dart';

import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;
import 'package:smartclock/clock.dart';
import 'package:smartclock/Weather.dart';
import 'package:smartclock/sidebar.dart';
import 'package:smartclock/util/logger.dart';
import 'package:smartclock/util/config.dart' show Config;

late void Function(Config config) saveConfig;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDir = await getApplicationSupportDirectory();
  logger.i("Config Directory: ${appDir.path}");

  final confFile = File(path.join(appDir.path, "config.json"));
  saveConfig = (Config config) {
    const encoder = JsonEncoder.withIndent("  ");
    confFile.writeAsStringSync(encoder.convert(config));
  };
  final exampleConfFile = File(path.join(appDir.path, "config.example.json"));
  final exampleConf = await rootBundle.loadString("assets/config.example.json");
  if (!confFile.existsSync()) confFile.writeAsStringSync(exampleConf);
  if (!exampleConfFile.existsSync()) exampleConfFile.writeAsStringSync(exampleConf);

  final cookieFile = File(path.join(appDir.path, "cookies.json"));
  if (!cookieFile.existsSync()) cookieFile.writeAsStringSync("{}");

  final configSchema = await JsonSchema.createFromUrl(Config.schema);
  final results = configSchema.validate(confFile.readAsStringSync(), parseJson: true);
  if (!results.isValid && !kDebugMode) {
    logger.w("Config file is invalid. Created missing keys.");
    logger.t(results.errors);

    Map<String, dynamic> config = json.decode(confFile.readAsStringSync());
    final exampleConfig = json.decode(exampleConf);
    config = Config.merge(config, exampleConfig);
    saveConfig(Config.fromJson(config));
  }

  Database database = await openDatabase(
    path.join(appDir.path, 'database.db'),
    onUpgrade: (db, _, __) async {
      final batch = db.batch();
      batch.execute("CREATE TABLE IF NOT EXISTS lyrics (id TEXT PRIMARY KEY, lyrics TEXT)");
      batch.execute("CREATE TABLE IF NOT EXISTS watchlist (id TEXT PRIMARY KEY UNIQUE, name TEXT, status TEXT, nextAirDate DATE)");
      await batch.commit();
      return;
    },
    version: 3,
  );

  final config = Config.fromJson(json.decode(confFile.readAsStringSync()));
  final client = alexa.QueryClient(
    cookieFile,
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

  if (config.alexa.enabled) {
    if (!await client.checkStatus(config.alexa.userId)) {
      try {
        if (config.alexa.userId.isEmpty || config.alexa.token.isEmpty) {
          throw Exception("Alexa User ID and Token must be set in the config file.");
        }
        await client.login(config.alexa.userId, config.alexa.token);
      } catch (e) {
        logger.w("Failed to login to Alexa: $e");
      }
    }
  }

  // LINUX BONJOUR DEPENDENCIES:
  // avahi-daemon avahi-discover avahi-utils libnss-mdns mdns-scan
  BonsoirService service = BonsoirService(
    name: "SC@${Platform.localHostname}",
    type: '_smartclock._tcp',
    port: 3030,
  );
  final broadcast = BonsoirBroadcast(service: service);
  await broadcast.ready;
  await broadcast.start();

  runApp(MultiProvider(
    providers: [
      Provider<Config>.value(value: config),
      Provider<Database>.value(value: database),
      Provider<alexa.QueryClient>.value(value: client),
      // Push events to this stream to tell widgets to update
      Provider<StreamController<DateTime>>.value(value: StreamController<DateTime>.broadcast()),
    ],
    child: const SmartClock(),
  ));
}

class SmartClock extends StatelessWidget {
  const SmartClock({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.read<Config>();
    final resolution = config.resolution.split("x").map((e) => int.parse(e));

    return MaterialApp(
      title: 'SmartClock',
      theme: ThemeData(scaffoldBackgroundColor: Colors.black, fontFamily: "Poppins"),
      home: Scaffold(
        body: Container(
          width: resolution.first.toDouble(),
          height: resolution.last.toDouble(),
          color: Colors.white,
          child: Center(
            child: Stack(
              children: [
                const Clock(),
                if (config.sidebar.enabled) const Sidebar(),
                if (config.weather.enabled) const Weather(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
