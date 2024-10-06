import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:smartclock/clock.dart';
import 'package:smartclock/Weather.dart';
import 'package:smartclock/util/config.dart' show Config;
import 'package:smartclock/sidebar.dart';
import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;
import 'package:json_schema/json_schema.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDir = await getApplicationSupportDirectory();

  final confFile = File("${appDir.path}/config.json");
  if (!confFile.existsSync()) confFile.writeAsStringSync(await rootBundle.loadString("assets/default_config.json"));
  print("Loaded Config File: ${confFile.path}");

  final cookieFile = File("${appDir.path}/cookies.json");
  if (!cookieFile.existsSync()) cookieFile.writeAsStringSync("{}");
  print("Loaded Cookie File: ${cookieFile.path}");

  const schemaUrl = "https://auth.smartclock.app/schema/v1";
  final configSchema = await JsonSchema.createFromUrl(schemaUrl);
  final results = configSchema.validate(confFile.readAsStringSync(), parseJson: true);
  if (!results.isValid) {
    print("Config file is invalid. Please check the schema at $schemaUrl");
    print("Warnings:" + results.warnings.join("\n"));
    print("Errors: " + results.errors.join("\n"));
    exit(1);
  }

  final config = Config.fromJson(json.decode(confFile.readAsStringSync()));
  final client = alexa.QueryClient(cookieFile);

  if (config.alexa.enabled) {
    if (!await client.checkStatus(config.alexa.userId)) {
      try {
        if (config.alexa.userId.isEmpty || config.alexa.token.isEmpty) {
          throw Exception("Alexa User ID and Token must be set in the config file.");
        }
        await client.login(config.alexa.userId, config.alexa.token);
      } catch (e) {
        print("Failed to login to Alexa: $e");
      }
    }
  }

  runApp(MultiProvider(
    providers: [
      Provider<Config>.value(value: config),
      Provider<alexa.QueryClient>.value(value: client),
      // Push events to this stream to tell widgets to update
      Provider<StreamController<void>>.value(value: StreamController<int?>.broadcast()),
    ],
    child: const SmartClock(),
  ));
}

class SmartClock extends StatelessWidget {
  const SmartClock({super.key});

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<Config>(context);
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
                const Sidebar(),
                if (config.weather.enabled) const Weather(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
