import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;

import 'package:smartclock/util/color_from_hex.dart';
import 'package:smartclock/util/logger.dart';

class ConfigModel extends ChangeNotifier {
  StreamSubscription<FileSystemEvent>? _fileWatcher;
  late alexa.QueryClient _client;
  Config config;

  ConfigModel(this.config, {required alexa.QueryClient client}) {
    _client = client;

    if (!Platform.isIOS) {
      _fileWatcher = config.file.watch().listen((event) {
        logger.i("Config file changed: ${event.path}");

        if (event.type == FileSystemEvent.modify) {
          final json = jsonDecode(config.file.readAsStringSync());

          final updatedConfig = Config.fromJson(config.file, json);

          if (config != updatedConfig) {
            config = Config.fromJson(config.file, json);
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
    notifyListeners();
  }

  @override
  void dispose() {
    _fileWatcher?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_client.loginToken != config.alexa.token) {
      _client.loginToken = config.alexa.token;
      logger.i("Updated Alexa loginToken: ${_client.loginToken}");
    }
    super.notifyListeners();
  }
}

class Config {
  File file;
  final ({double x, double y}) resolution;
  final bool networkEnabled;
  final RemoteConfig remoteConfig;
  final Alexa alexa;
  final Clock clock;
  final Calendar calendar;
  final Sidebar sidebar;
  final Watchlist watchlist;
  final Weather weather;
  final Dimensions dimensions;

  Config({
    required this.file,
    required this.resolution,
    required this.networkEnabled,
    required this.remoteConfig,
    required this.alexa,
    required this.clock,
    required this.calendar,
    required this.sidebar,
    required this.watchlist,
    required this.weather,
    required this.dimensions,
  });

  static Map<String, dynamic> merge(Map<String, dynamic> base, Map<String, dynamic> updates) {
    updates.forEach((key, value) {
      if (value is Map<String, dynamic> && base[key] is Map<String, dynamic>) {
        merge(base[key] ?? {}, value);
      } else if (!base.containsKey(key)) {
        base[key] = value;
      }
    });

    return base;
  }

  void save() {
    const encoder = JsonEncoder.withIndent("  ");
    file.writeAsStringSync(encoder.convert(this));
  }

  @override
  int get hashCode => toJson().toString().hashCode;

  @override
  bool operator ==(Object other) => other is Config && other.hashCode == hashCode;

  factory Config.asDefault(File file) => Config(
        file: file,
        resolution: (x: 1280, y: 800),
        networkEnabled: true,
        remoteConfig: RemoteConfig.asDefault(),
        alexa: Alexa.asDefault(),
        clock: Clock.asDefault(),
        calendar: Calendar.asDefault(),
        sidebar: Sidebar.asDefault(),
        watchlist: Watchlist.asDefault(),
        weather: Weather.asDefault(),
        dimensions: Dimensions.asDefault(),
      );

  factory Config.fromJson(File file, Map<String, dynamic> json) => Config(
        file: file,
        resolution: (
          x: double.parse(json["resolution"].split("x")[0]),
          y: double.parse(json["resolution"].split("x")[1]),
        ),
        networkEnabled: json["networkEnabled"],
        remoteConfig: RemoteConfig.fromJson(json["remoteConfig"]),
        alexa: Alexa.fromJson(json["alexa"]),
        clock: Clock.fromJson(json["clock"]),
        calendar: Calendar.fromJson(json["calendar"]),
        sidebar: Sidebar.fromJson(json["sidebar"]),
        watchlist: Watchlist.fromJson(json["watchlist"]),
        weather: Weather.fromJson(json["weather"]),
        dimensions: Dimensions.fromJson(json["dimensions"]),
      );

  Map<String, dynamic> toJson() => {
        "\$schema": "./schema.json",
        "resolution": "${resolution.x.toInt()}x${resolution.y.toInt()}",
        "networkEnabled": networkEnabled,
        "remoteConfig": remoteConfig.toJson(),
        "alexa": alexa.toJson(),
        "clock": clock.toJson(),
        "calendar": calendar.toJson(),
        "sidebar": sidebar.toJson(),
        "watchlist": watchlist.toJson(),
        "weather": weather.toJson(),
        "dimensions": dimensions.toJson(),
      };
}

class RemoteConfig {
  final bool enabled;
  final int port;
  final String password;
  final bool useBonjour;

  RemoteConfig({
    required this.enabled,
    required this.port,
    required this.password,
    required this.useBonjour,
  });

  factory RemoteConfig.asDefault() => RemoteConfig(
        enabled: true,
        port: 8080,
        password: "",
        useBonjour: true,
      );

  factory RemoteConfig.fromJson(Map<String, dynamic> json) => RemoteConfig(
        enabled: json["enabled"],
        port: json["port"],
        password: json["password"],
        useBonjour: json["useBonjour"],
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "port": port,
        "password": password,
        "useBonjour": useBonjour,
      };
}

class Alexa {
  final bool enabled;
  final ({bool nowplaying, bool alarms, bool timers}) features;
  final String userId;
  final String token;
  final List<String> devices;

  Alexa({
    required this.enabled,
    required this.features,
    required this.userId,
    required this.token,
    required this.devices,
  });

  factory Alexa.asDefault() => Alexa(
        enabled: false,
        features: (
          nowplaying: false,
          alarms: false,
          timers: false,
        ),
        userId: "",
        token: "",
        devices: [],
      );

  factory Alexa.fromJson(Map<String, dynamic> json) => Alexa(
        enabled: json["enabled"],
        features: (
          nowplaying: json["features"]["nowplaying"],
          alarms: json["features"]["alarms"],
          timers: json["features"]["timers"],
        ),
        userId: json["userId"],
        token: json["token"],
        devices: List<String>.from(json["devices"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "features": {
          "nowplaying": features.nowplaying,
          "alarms": features.alarms,
          "timers": features.timers,
        },
        "userId": userId,
        "token": token,
        "devices": List<dynamic>.from(devices.map((x) => x)),
      };
}

class Clock {
  final double mainSize;
  final double smallSize;
  final double smallGap;
  final double dateSize;
  final double dateGap;
  final double padding;

  Clock({
    required this.mainSize,
    required this.smallSize,
    required this.smallGap,
    required this.dateSize,
    required this.dateGap,
    required this.padding,
  });

  factory Clock.asDefault() => Clock(
        mainSize: 200,
        smallSize: 85,
        smallGap: 15,
        dateSize: 48,
        dateGap: 50,
        padding: 16,
      );

  factory Clock.fromJson(Map<String, dynamic> json) => Clock(
        mainSize: double.parse(json["mainSize"].toString()),
        smallSize: double.parse(json["smallSize"].toString()),
        smallGap: double.parse(json["smallGap"].toString()),
        dateSize: double.parse(json["dateSize"].toString()),
        dateGap: double.parse(json["dateGap"].toString()),
        padding: double.parse(json["padding"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "mainSize": mainSize,
        "smallSize": smallSize,
        "smallGap": smallGap,
        "dateSize": dateSize,
        "dateGap": dateGap,
        "padding": padding,
      };
}

class Dimension {
  final double x;
  final double y;
  final double width;
  final double height;

  Dimension({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory Dimension.parse(String json) {
    final csv = json.split(',');
    return Dimension(
      x: double.parse(csv[0]),
      y: double.parse(csv[1]),
      width: double.parse(csv[2]),
      height: double.parse(csv[3]),
    );
  }

  @override
  String toString() => "${x.toInt()},${y.toInt()},${width.toInt()},${height.toInt()}";
}

class Dimensions {
  final Dimension clock;
  final Dimension sidebar;
  final Dimension weather;

  Dimensions({
    required this.clock,
    required this.sidebar,
    required this.weather,
  });

  factory Dimensions.asDefault() => Dimensions(
        clock: Dimension.parse("0,0,800,800"),
        sidebar: Dimension.parse("800,0,480,800"),
        weather: Dimension.parse("64,64,672,100"),
      );

  factory Dimensions.fromJson(Map<String, dynamic> json) => Dimensions(
        clock: Dimension.parse(json["clock"]),
        sidebar: Dimension.parse(json["sidebar"]),
        weather: Dimension.parse(json["weather"]),
      );

  Map<String, dynamic> toJson() => {
        "clock": clock.toString(),
        "sidebar": sidebar.toString(),
        "weather": weather.toString(),
      };
}

class Calendar {
  final bool enabled;
  final String clientId;
  final String clientSecret;
  String accessToken;
  String refreshToken;
  DateTime tokenExpiry;
  final int maxEvents;
  final ({bool enabled, String odd, String even}) titles;
  final List<String> eventFilter;

  final double monthTitleSize;
  final double eventTitleSize;
  final double eventTimeSize;
  final double eventColorWidth;

  Calendar({
    required this.enabled,
    required this.clientId,
    required this.clientSecret,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenExpiry,
    required this.maxEvents,
    required this.titles,
    required this.eventFilter,
    required this.monthTitleSize,
    required this.eventTitleSize,
    required this.eventTimeSize,
    required this.eventColorWidth,
  });

  factory Calendar.asDefault() => Calendar(
        enabled: false,
        clientId: "",
        clientSecret: "",
        accessToken: "",
        refreshToken: "",
        tokenExpiry: DateTime.now(),
        maxEvents: 0,
        titles: (
          enabled: false,
          odd: "",
          even: "",
        ),
        eventFilter: [],
        monthTitleSize: 36,
        eventTitleSize: 34,
        eventTimeSize: 28,
        eventColorWidth: 8,
      );

  factory Calendar.fromJson(Map<String, dynamic> json) => Calendar(
        enabled: json["enabled"],
        clientId: json["clientId"],
        clientSecret: json["clientSecret"],
        accessToken: json["accessToken"],
        refreshToken: json["refreshToken"],
        tokenExpiry: DateTime.parse(json["tokenExpiry"]).toUtc(),
        maxEvents: json["maxEvents"],
        titles: (
          enabled: json["titles"]["enabled"],
          odd: json["titles"]["odd"],
          even: json["titles"]["even"],
        ),
        eventFilter: List<String>.from(json["eventFilter"].map((x) => x)),
        monthTitleSize: double.parse(json["monthTitleSize"].toString()),
        eventTitleSize: double.parse(json["eventTitleSize"].toString()),
        eventTimeSize: double.parse(json["eventTimeSize"].toString()),
        eventColorWidth: double.parse(json["eventColorWidth"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "clientId": clientId,
        "clientSecret": clientSecret,
        "accessToken": accessToken,
        "refreshToken": refreshToken,
        "tokenExpiry": tokenExpiry.toIso8601String(),
        "maxEvents": maxEvents,
        "titles": {
          "enabled": titles.enabled,
          "odd": titles.odd,
          "even": titles.even,
        },
        "eventFilter": List<dynamic>.from(eventFilter.map((x) => x)),
        "monthTitleSize": monthTitleSize,
        "eventTitleSize": eventTitleSize,
        "eventTimeSize": eventTimeSize,
        "eventColorWidth": eventColorWidth,
      };
}

class Sidebar {
  final bool enabled;
  final double cardRadius;
  final double cardSpacing;
  final Color cardColor;

  Sidebar({
    required this.enabled,
    required this.cardRadius,
    required this.cardSpacing,
    required this.cardColor,
  });

  factory Sidebar.asDefault() => Sidebar(
        enabled: true,
        cardRadius: 10,
        cardSpacing: 16,
        cardColor: "#f8f8f8".toColor(),
      );

  factory Sidebar.fromJson(Map<String, dynamic> json) => Sidebar(
        enabled: json["enabled"],
        cardRadius: double.parse(json["cardRadius"].toString()),
        cardSpacing: double.parse(json["cardSpacing"].toString()),
        cardColor: (json["cardColor"] as String).toColor(),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "cardRadius": cardRadius,
        "cardSpacing": cardSpacing,
        "cardColor": cardColor.toHex(),
      };
}

class Trakt {
  final String clientId;
  final String clientSecret;
  String accessToken;
  String refreshToken;
  final String redirectUri;
  final String listId;

  Trakt({
    required this.clientId,
    required this.clientSecret,
    required this.accessToken,
    required this.refreshToken,
    required this.redirectUri,
    required this.listId,
  });

  factory Trakt.asDefault() => Trakt(
        clientId: "",
        clientSecret: "",
        accessToken: "",
        refreshToken: "",
        redirectUri: "",
        listId: "",
      );

  factory Trakt.fromJson(Map<String, dynamic> json) => Trakt(
        clientId: json["clientId"],
        clientSecret: json["clientSecret"],
        accessToken: json["accessToken"],
        refreshToken: json["refreshToken"],
        redirectUri: json["redirectUri"],
        listId: json["listId"],
      );

  Map<String, dynamic> toJson() => {
        "clientId": clientId,
        "clientSecret": clientSecret,
        "accessToken": accessToken,
        "refreshToken": refreshToken,
        "redirectUri": redirectUri,
        "listId": listId,
      };
}

class Watchlist {
  final bool enabled;
  final Trakt trakt;
  final String tmdbApiKey;
  final String prefix;
  final Color color;
  final int maxItems;

  Watchlist({
    required this.enabled,
    required this.trakt,
    required this.tmdbApiKey,
    required this.prefix,
    required this.color,
    required this.maxItems,
  });

  factory Watchlist.asDefault() => Watchlist(
        enabled: false,
        trakt: Trakt.asDefault(),
        tmdbApiKey: "",
        prefix: "Watchlist: ",
        color: "#f5511d".toColor(),
        maxItems: 4,
      );

  factory Watchlist.fromJson(Map<String, dynamic> json) => Watchlist(
        enabled: json["enabled"],
        trakt: Trakt.fromJson(json["trakt"]),
        tmdbApiKey: json["tmdbApiKey"],
        prefix: json["prefix"],
        color: (json["color"] as String).toColor(),
        maxItems: json["maxItems"],
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "trakt": trakt.toJson(),
        "tmdbApiKey": tmdbApiKey,
        "prefix": prefix,
        "color": color.toHex(),
        "maxItems": maxItems,
      };
}

class Weather {
  final bool enabled;
  final String apiKey;
  final String postcode;
  final String country;
  final String units;
  final double fontSize;
  final double iconSize;

  Weather({
    required this.enabled,
    required this.apiKey,
    required this.postcode,
    required this.country,
    required this.units,
    required this.fontSize,
    required this.iconSize,
  });

  factory Weather.asDefault() => Weather(
        enabled: false,
        apiKey: "",
        postcode: "",
        country: "",
        units: "metric",
        fontSize: 32,
        iconSize: 50,
      );

  factory Weather.fromJson(Map<String, dynamic> json) => Weather(
        enabled: json["enabled"],
        apiKey: json["apiKey"],
        postcode: json["postcode"],
        country: json["country"],
        units: json["units"],
        fontSize: double.parse(json["fontSize"].toString()),
        iconSize: double.parse(json["iconSize"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "apiKey": apiKey,
        "postcode": postcode,
        "country": country,
        "units": units,
        "fontSize": fontSize,
        "iconSize": iconSize,
      };
}
