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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDir = await getApplicationDocumentsDirectory();

  final confFile = File("${appDir.path}/config.json");
  if (!confFile.existsSync()) {
    final confData = await rootBundle.loadString("assets/default_config.json");
    confFile.writeAsStringSync(confData);
  }
  final config = Config.fromJson(json.decode(confFile.readAsStringSync()));

  final cookieFile = File("${appDir.path}/cookies.json");
  if (!cookieFile.existsSync()) cookieFile.writeAsStringSync("{}");
  final client = alexa.QueryClient(cookieFile);
  if (!await client.checkStatus(config.alexa.userId)) {
    await client.login(config.alexa.userId, config.alexa.token);
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
          child: const Center(
            child: Stack(
              children: [
                Clock(),
                Sidebar(),
                Weather(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
