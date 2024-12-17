import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alexaquery_dart/alexaquery_dart.dart' as alexa;
import 'package:flutter/material.dart';

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
  final Clock clock;
  final Calendar calendar;
  final Energy energy;
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
    required this.clock,
    required this.calendar,
    required this.energy,
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
        orientation: Orientation.landscape,
        interactive: false,
        networkEnabled: true,
        remoteConfig: RemoteConfig.asDefault(),
        alexa: Alexa.asDefault(),
        clock: Clock.asDefault(),
        calendar: Calendar.asDefault(),
        energy: Energy.asDefault(),
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
        clock: Clock.fromJson(json["clock"]),
        calendar: Calendar.fromJson(json["calendar"]),
        energy: Energy.fromJson(json["energy"]),
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
        "clock": clock.toJson(),
        "calendar": calendar.toJson(),
        "energy": energy.toJson(),
        "sidebar": sidebar.toJson(),
        "watchlist": watchlist.toJson(),
        "weather": weather.toJson(),
        "dimensions": dimensions,
      };
}

class RemoteConfig {
  final bool enabled;
  final int port;
  final String password;
  final bool useBonjour;
  String? bonjourName;
  String? toggleDisplayPath;

  RemoteConfig({required this.enabled, required this.port, required this.password, required this.useBonjour, this.bonjourName, this.toggleDisplayPath});

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
        bonjourName: json["bonjourName"],
        toggleDisplayPath: json["toggleDisplayPath"],
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "port": port,
        "password": password,
        "useBonjour": useBonjour,
        if (bonjourName != null && bonjourName!.isNotEmpty) 'bonjourName': bonjourName,
        if (toggleDisplayPath != null && toggleDisplayPath!.isNotEmpty) 'toggleDisplayPath': toggleDisplayPath,
      };
}

class Alexa {
  final bool enabled;
  final ({bool nowplaying, bool alarms, bool timers, bool notes}) features;
  final String userId;
  final String token;
  final List<String> devices;
  List<String>? radioProviders;
  final double nowplayingImageSize;
  final double nowplayingFontSize;
  final double lyricsCurrentFontSize;
  final double lyricsNextFontSize;
  final int noteColumns;
  final double noteFontSize;

  Alexa({
    required this.enabled,
    required this.features,
    required this.userId,
    required this.token,
    required this.devices,
    this.radioProviders,
    required this.nowplayingImageSize,
    required this.nowplayingFontSize,
    required this.lyricsCurrentFontSize,
    required this.lyricsNextFontSize,
    required this.noteColumns,
    required this.noteFontSize,
  });

  factory Alexa.asDefault() => Alexa(
        enabled: false,
        features: (
          nowplaying: false,
          alarms: false,
          timers: false,
          notes: false,
        ),
        userId: "",
        token: "",
        devices: [],
        nowplayingImageSize: 146,
        nowplayingFontSize: 32,
        lyricsCurrentFontSize: 24,
        lyricsNextFontSize: 20,
        noteColumns: 3,
        noteFontSize: 24,
      );

  factory Alexa.fromJson(Map<String, dynamic> json) => Alexa(
        enabled: json["enabled"],
        features: (
          nowplaying: json["features"]["nowplaying"],
          alarms: json["features"]["alarms"],
          timers: json["features"]["timers"],
          notes: json["features"]["notes"],
        ),
        userId: json["userId"],
        token: json["token"],
        devices: List<String>.from(json["devices"].map((x) => x)),
        radioProviders: json["radioProviders"] != null ? List<String>.from(json["radioProviders"].map((x) => x)) : null,
        nowplayingImageSize: double.parse(json["nowplayingImageSize"].toString()),
        nowplayingFontSize: double.parse(json["nowplayingFontSize"].toString()),
        lyricsCurrentFontSize: double.parse(json["lyricsCurrentFontSize"].toString()),
        lyricsNextFontSize: double.parse(json["lyricsNextFontSize"].toString()),
        noteColumns: json["noteColumns"],
        noteFontSize: double.parse(json["noteFontSize"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "features": {
          "nowplaying": features.nowplaying,
          "alarms": features.alarms,
          "timers": features.timers,
          "notes": features.notes,
        },
        "userId": userId,
        "token": token,
        "devices": List<dynamic>.from(devices.map((x) => x)),
        if (radioProviders != null) 'radioProviders': List<dynamic>.from(radioProviders!.map((x) => x)),
        "nowplayingImageSize": nowplayingImageSize,
        "nowplayingFontSize": nowplayingFontSize,
        "lyricsCurrentFontSize": lyricsCurrentFontSize,
        "lyricsNextFontSize": lyricsNextFontSize,
        "noteColumns": noteColumns,
        "noteFontSize": noteFontSize,
      };
}

class Clock {
  final bool twentyFourHour;
  final bool showSeconds;
  final double mainSize;
  final double smallSize;
  final double smallGap;
  final double dateSize;
  final double dateGap;
  final double padding;

  Clock({
    required this.twentyFourHour,
    required this.showSeconds,
    required this.mainSize,
    required this.smallSize,
    required this.smallGap,
    required this.dateSize,
    required this.dateGap,
    required this.padding,
  });

  factory Clock.asDefault() => Clock(
        twentyFourHour: false,
        showSeconds: true,
        mainSize: 200,
        smallSize: 85,
        smallGap: 15,
        dateSize: 48,
        dateGap: 50,
        padding: 16,
      );

  factory Clock.fromJson(Map<String, dynamic> json) => Clock(
        twentyFourHour: json["twentyFourHour"],
        showSeconds: json["showSeconds"],
        mainSize: double.parse(json["mainSize"].toString()),
        smallSize: double.parse(json["smallSize"].toString()),
        smallGap: double.parse(json["smallGap"].toString()),
        dateSize: double.parse(json["dateSize"].toString()),
        dateGap: double.parse(json["dateGap"].toString()),
        padding: double.parse(json["padding"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "twentyFourHour": twentyFourHour,
        "showSeconds": showSeconds,
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

  factory Dimension.parse(String csv) {
    final parsed = csv.split(',');
    return Dimension(
      x: double.parse(parsed[0]),
      y: double.parse(parsed[1]),
      width: double.parse(parsed[2]),
      height: double.parse(parsed[3]),
    );
  }

  @override
  String toString() => "${x.toInt()},${y.toInt()},${width.toInt()},${height.toInt()}";
  String toJson() => toString();
}

class Energy {
  final bool enabled;
  final String token;
  final String gasId;
  final String electricityId;
  final double fontSize;
  final double iconSize;

  Energy({
    required this.enabled,
    required this.token,
    required this.gasId,
    required this.electricityId,
    required this.fontSize,
    required this.iconSize,
  });

  factory Energy.asDefault() => Energy(
        enabled: false,
        token: "",
        gasId: "",
        electricityId: "",
        fontSize: 32,
        iconSize: 50,
      );

  factory Energy.fromJson(Map<String, dynamic> json) => Energy(
        enabled: false, // TODO: Disable until better implementation, current api not useful.
        token: json["token"],
        gasId: json["gasId"],
        electricityId: json["electricityId"],
        fontSize: double.parse(json["fontSize"].toString()),
        iconSize: double.parse(json["iconSize"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "token": token,
        "gasId": gasId,
        "electricityId": electricityId,
        "fontSize": fontSize,
        "iconSize": iconSize,
      };
}

class Google {
  final String clientId;
  final String clientSecret;
  String accessToken;
  String refreshToken;
  DateTime tokenExpiry;

  Google({
    required this.clientId,
    required this.clientSecret,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenExpiry,
  });

  factory Google.asDefault() => Google(
        clientId: "",
        clientSecret: "",
        accessToken: "",
        refreshToken: "",
        tokenExpiry: DateTime.now(),
      );

  factory Google.fromJson(Map<String, dynamic> json) => Google(
        clientId: json["clientId"],
        clientSecret: json["clientSecret"],
        accessToken: json["accessToken"],
        refreshToken: json["refreshToken"],
        tokenExpiry: DateTime.parse(json["tokenExpiry"]).toUtc(),
      );

  Map<String, dynamic> toJson() => {
        "clientId": clientId,
        "clientSecret": clientSecret,
        "accessToken": accessToken,
        "refreshToken": refreshToken,
        "tokenExpiry": tokenExpiry.toIso8601String(),
      };
}

class Calendar {
  final bool enabled;
  final Google google;
  final int maxEvents;
  final ({String odd, String even}) titles;
  final List<String> eventFilter;

  final double monthTitleSize;
  final double eventTitleSize;
  final double eventTimeSize;
  final double eventColorWidth;

  Calendar({
    required this.enabled,
    required this.google,
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
        google: Google.asDefault(),
        maxEvents: 10,
        titles: (
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
        google: Google.fromJson(json["google"]),
        maxEvents: json["maxEvents"],
        titles: (
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
        "google": google.toJson(),
        "maxEvents": maxEvents,
        "titles": {
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
  final Color cardColor;

  Sidebar({
    required this.enabled,
    required this.cardRadius,
    required this.cardColor,
  });

  factory Sidebar.asDefault() => Sidebar(
        enabled: true,
        cardRadius: 10,
        cardColor: "#f8f8f8".toColor(),
      );

  factory Sidebar.fromJson(Map<String, dynamic> json) => Sidebar(
        enabled: json["enabled"],
        cardRadius: double.parse(json["cardRadius"].toString()),
        cardColor: (json["cardColor"] as String).toColor(),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "cardRadius": cardRadius,
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
  final bool? includeEpisodesAsShow;

  Trakt({
    required this.clientId,
    required this.clientSecret,
    required this.accessToken,
    required this.refreshToken,
    required this.redirectUri,
    required this.listId,
    this.includeEpisodesAsShow,
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
        includeEpisodesAsShow: json["includeEpisodesAsShow"],
      );

  Map<String, dynamic> toJson() => {
        "clientId": clientId,
        "clientSecret": clientSecret,
        "accessToken": accessToken,
        "refreshToken": refreshToken,
        "redirectUri": redirectUri,
        "listId": listId,
        if (includeEpisodesAsShow != null) 'includeEpisodesAsShow': includeEpisodesAsShow,
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

enum WeatherType { floating, card }

class Weather {
  final bool enabled;
  final WeatherType type;
  final String apiKey;
  final String postcode;
  final String country;
  final String units;
  final double fontSize;
  final double iconSize;

  Weather({
    required this.enabled,
    required this.type,
    required this.apiKey,
    required this.postcode,
    required this.country,
    required this.units,
    required this.fontSize,
    required this.iconSize,
  });

  factory Weather.asDefault() => Weather(
        enabled: false,
        type: WeatherType.floating,
        apiKey: "",
        postcode: "",
        country: "",
        units: "metric",
        fontSize: 32,
        iconSize: 50,
      );

  factory Weather.fromJson(Map<String, dynamic> json) => Weather(
        enabled: json["enabled"],
        type: json["type"] == "card" ? WeatherType.card : WeatherType.floating,
        apiKey: json["apiKey"],
        postcode: json["postcode"],
        country: json["country"],
        units: json["units"],
        fontSize: double.parse(json["fontSize"].toString()),
        iconSize: double.parse(json["iconSize"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "type": type == WeatherType.card ? "card" : "floating",
        "apiKey": apiKey,
        "postcode": postcode,
        "country": country,
        "units": units,
        "fontSize": fontSize,
        "iconSize": iconSize,
      };
}
