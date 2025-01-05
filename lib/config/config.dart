import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;
import 'package:smartclock/main.dart' show logger;
import 'package:smartclock/util/color_from_hex.dart';

part 'remote_config.dart';
part 'alexa.dart';
part 'calendar.dart';
part 'clock.dart';
part 'dimension.dart';
part 'energy.dart';
part 'google.dart';
part 'homeassistant.dart';
part 'photos.dart';
part 'sidebar.dart';
part 'trakt.dart';
part 'watchlist.dart';
part 'weather.dart';

class ConfigModel extends ChangeNotifier {
  StreamSubscription<FileSystemEvent>? _fileWatcher;
  late alexa.QueryClient _client;
  Config config;
  Directory appDir;
  Key clockKey = UniqueKey();

  ConfigModel(this.config, {required alexa.QueryClient client, required this.appDir}) {
    _client = client;

    if (!Platform.isIOS) {
      _fileWatcher = config.file.watch().listen((event) {
        logger.i("Config file changed: ${event.path}");

        if (event.type == FileSystemEvent.modify) {
          final json = jsonDecode(config.file.readAsStringSync());

          final updatedConfig = Config.fromJsonValidated(config.file, json);

          if (config != updatedConfig) {
            config = updatedConfig;
            notifyListeners();
          } else {
            logger.i("Config hash unchanged");
          }
        }
      });
    }
  }

  void setConfig(Config config) {
    config.file = this.config.file;
    this.config = config;
    this.config.save();
    notifyListeners();
  }

  @override
  void dispose() {
    _fileWatcher?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    clockKey = UniqueKey();
    if (_client.loginToken != config.alexa.token) {
      _client.loginToken = config.alexa.token;
      logger.i("Updated Alexa loginToken: ${_client.loginToken}");
    }
    super.notifyListeners();
  }
}

class Config {
  File file;
  static const String version = "1.0.0";
  final Orientation orientation;
  final bool interactive;
  final bool networkEnabled;
  final RemoteConfig remoteConfig;
  final Alexa alexa;
  final Calendar calendar;
  final Clock clock;
  final Energy energy;
  final Google google;
  final HomeAssistant homeAssistant;
  final Photos photos;
  final Sidebar sidebar;
  final Watchlist watchlist;
  final Weather weather;
  final Map<String, Dimension> dimensions;

  Config({
    required this.file,
    required this.orientation,
    required this.interactive,
    required this.networkEnabled,
    required this.remoteConfig,
    required this.alexa,
    required this.calendar,
    required this.clock,
    required this.energy,
    required this.google,
    required this.homeAssistant,
    required this.photos,
    required this.sidebar,
    required this.watchlist,
    required this.weather,
    required this.dimensions,
  });

  factory Config.fromJsonValidated(File file, Map<String, dynamic> json) {
    Map<String, dynamic> merge(Map<String, dynamic> base, Map<String, dynamic> updates) {
      updates.forEach((key, value) {
        if (value is Map<String, dynamic> && base[key] is Map<String, dynamic>) {
          merge(base[key] ?? {}, value);
        } else if (!base.containsKey(key)) {
          base[key] = value;
        }
      });

      return base;
    }

    final merged = merge(json, Config.asDefault(null).toJson());
    return Config.fromJson(file, merged);
  }

  void save() {
    const encoder = JsonEncoder.withIndent("  ");
    file.writeAsStringSync(encoder.convert(this));
  }

  @override
  int get hashCode => toJson().toString().hashCode;

  @override
  bool operator ==(Object other) => other is Config && other.hashCode == hashCode;

  factory Config.asDefault(File? file) => Config(
        file: file ?? File(""),
        orientation: Orientation.landscape,
        interactive: false,
        networkEnabled: true,
        remoteConfig: RemoteConfig.asDefault(),
        alexa: Alexa.asDefault(),
        calendar: Calendar.asDefault(),
        clock: Clock.asDefault(),
        energy: Energy.asDefault(),
        google: Google.asDefault(),
        homeAssistant: HomeAssistant.asDefault(),
        photos: Photos.asDefault(),
        sidebar: Sidebar.asDefault(),
        watchlist: Watchlist.asDefault(),
        weather: Weather.asDefault(),
        dimensions: {
          "clock": Dimension.parse("0,0,800,800"),
          "sidebar": Dimension.parse("784,0,496,800"),
          "weather": Dimension.parse("64,64,672,100"),
        },
      );

  factory Config.fromJson(File file, Map<String, dynamic> json) => Config(
        file: file,
        orientation: json["orientation"] == "landscape" ? Orientation.landscape : Orientation.portrait,
        interactive: json["interactive"],
        networkEnabled: json["networkEnabled"],
        remoteConfig: RemoteConfig.fromJson(json["remoteConfig"]),
        alexa: Alexa.fromJson(json["alexa"]),
        calendar: Calendar.fromJson(json["calendar"]),
        clock: Clock.fromJson(json["clock"]),
        energy: Energy.fromJson(json["energy"]),
        google: Google.fromJson(json["google"]),
        homeAssistant: HomeAssistant.fromJson(json["homeAssistant"]),
        photos: Photos.fromJson(json["photos"]),
        sidebar: Sidebar.fromJson(json["sidebar"]),
        watchlist: Watchlist.fromJson(json["watchlist"]),
        weather: Weather.fromJson(json["weather"]),
        dimensions: (json["dimensions"] as Map<String, dynamic>).map((key, value) => MapEntry(key, Dimension.parse(value))),
      );

  Map<String, dynamic> toJson() => {
        "\$schema": "./schema.json",
        "version": version,
        "orientation": orientation == Orientation.landscape ? "landscape" : "portrait",
        "interactive": interactive,
        "networkEnabled": networkEnabled,
        "remoteConfig": remoteConfig.toJson(),
        "alexa": alexa.toJson(),
        "calendar": calendar.toJson(),
        "clock": clock.toJson(),
        "energy": energy.toJson(),
        "google": google.toJson(),
        "homeAssistant": homeAssistant.toJson(),
        "photos": photos.toJson(),
        "sidebar": sidebar.toJson(),
        "watchlist": watchlist.toJson(),
        "weather": weather.toJson(),
        "dimensions": dimensions,
      };
}
