import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:smartclock/util/logger.dart';

class ConfigModel extends ChangeNotifier {
  late StreamSubscription<FileSystemEvent> _fileWatcher;
  Config config;

  ConfigModel(this.config) {
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

  @override
  void dispose() {
    _fileWatcher.cancel();
    super.dispose();
  }
}

class Config {
  final File file;
  final String resolution;
  final bool networkEnabled;
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
        merge(base[key], value);
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

  factory Config.empty(File file) => Config(
        file: file,
        resolution: "1280x800",
        networkEnabled: true,
        alexa: Alexa.empty(),
        clock: Clock.empty(),
        calendar: Calendar.empty(),
        sidebar: Sidebar.empty(),
        watchlist: Watchlist.empty(),
        weather: Weather.empty(),
        dimensions: Dimensions.empty(),
      );

  factory Config.fromJson(File file, Map<String, dynamic> json) => Config(
        file: file,
        resolution: json["resolution"],
        networkEnabled: json["networkEnabled"],
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
        "resolution": resolution,
        "networkEnabled": networkEnabled,
        "alexa": alexa.toJson(),
        "clock": clock.toJson(),
        "calendar": calendar.toJson(),
        "sidebar": sidebar.toJson(),
        "watchlist": watchlist.toJson(),
        "weather": weather.toJson(),
        "dimensions": dimensions.toJson(),
      };
}

enum AlexaFeatures {
  nowplaying,
  alarms,
  timers,
}

class Alexa {
  final bool enabled;
  final Map<AlexaFeatures, bool> features;
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

  factory Alexa.empty() => Alexa(
        enabled: false,
        features: {
          AlexaFeatures.nowplaying: false,
          AlexaFeatures.alarms: false,
          AlexaFeatures.timers: false,
        },
        userId: "",
        token: "",
        devices: [],
      );

  factory Alexa.fromJson(Map<String, dynamic> json) => Alexa(
        enabled: json["enabled"],
        features: {
          AlexaFeatures.nowplaying: json["features"]["nowplaying"],
          AlexaFeatures.alarms: json["features"]["alarms"],
          AlexaFeatures.timers: json["features"]["timers"],
        },
        userId: json["userId"],
        token: json["token"],
        devices: List<String>.from(json["devices"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "features": {
          "nowplaying": features[AlexaFeatures.nowplaying],
          "alarms": features[AlexaFeatures.alarms],
          "timers": features[AlexaFeatures.timers],
        },
        "userId": userId,
        "token": token,
        "devices": List<dynamic>.from(devices.map((x) => x)),
      };
}

class Clock {
  final double mainSize;
  final double smallSize;
  final double dateSize;

  Clock({
    required this.mainSize,
    required this.smallSize,
    required this.dateSize,
  });

  factory Clock.empty() => Clock(
        mainSize: 200,
        smallSize: 85,
        dateSize: 48,
      );

  factory Clock.fromJson(Map<String, dynamic> json) => Clock(
        mainSize: double.parse(json["mainSize"].toString()),
        smallSize: double.parse(json["smallSize"].toString()),
        dateSize: double.parse(json["dateSize"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "mainSize": mainSize,
        "smallSize": smallSize,
        "dateSize": dateSize,
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

  factory Dimensions.empty() => Dimensions(
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

class Titles {
  final bool enabled;
  final String odd;
  final String even;

  Titles({
    required this.enabled,
    required this.odd,
    required this.even,
  });

  factory Titles.empty() => Titles(
        enabled: false,
        odd: "",
        even: "",
      );

  factory Titles.fromJson(Map<String, dynamic> json) => Titles(
        enabled: json["enabled"],
        odd: json["odd"],
        even: json["even"],
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "odd": odd,
        "even": even,
      };
}

class Calendar {
  final bool enabled;
  final String clientId;
  final String clientSecret;
  String accessToken;
  String refreshToken;
  final int maxEvents;
  final Titles titles;
  final List<String> eventFilter;

  final double monthTitleSize;
  final double eventTitleSize;
  final double eventTimeSize;
  final double eventColorSize;

  Calendar({
    required this.enabled,
    required this.clientId,
    required this.clientSecret,
    required this.accessToken,
    required this.refreshToken,
    required this.maxEvents,
    required this.titles,
    required this.eventFilter,
    required this.monthTitleSize,
    required this.eventTitleSize,
    required this.eventTimeSize,
    required this.eventColorSize,
  });

  factory Calendar.empty() => Calendar(
        enabled: false,
        clientId: "",
        clientSecret: "",
        accessToken: "",
        refreshToken: "",
        maxEvents: 0,
        titles: Titles.empty(),
        eventFilter: [],
        monthTitleSize: 36,
        eventTitleSize: 34,
        eventTimeSize: 28,
        eventColorSize: 8,
      );

  factory Calendar.fromJson(Map<String, dynamic> json) => Calendar(
        enabled: json["enabled"],
        clientId: json["clientId"],
        clientSecret: json["clientSecret"],
        accessToken: json["accessToken"],
        refreshToken: json["refreshToken"],
        maxEvents: json["maxEvents"],
        titles: Titles.fromJson(json["titles"]),
        eventFilter: List<String>.from(json["eventFilter"].map((x) => x)),
        monthTitleSize: double.parse(json["monthTitleSize"].toString()),
        eventTitleSize: double.parse(json["eventTitleSize"].toString()),
        eventTimeSize: double.parse(json["eventTimeSize"].toString()),
        eventColorSize: double.parse(json["eventColorSize"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "clientId": clientId,
        "clientSecret": clientSecret,
        "accessToken": accessToken,
        "refreshToken": refreshToken,
        "maxEvents": maxEvents,
        "titles": titles.toJson(),
        "eventFilter": List<dynamic>.from(eventFilter.map((x) => x)),
        "monthTitleSize": monthTitleSize,
        "eventTitleSize": eventTitleSize,
        "eventTimeSize": eventTimeSize,
        "eventColorSize": eventColorSize,
      };
}

class Sidebar {
  final bool enabled;
  final double padding;

  Sidebar({
    required this.enabled,
    required this.padding,
  });

  factory Sidebar.empty() => Sidebar(
        enabled: true,
        padding: 16,
      );

  factory Sidebar.fromJson(Map<String, dynamic> json) => Sidebar(
        enabled: json["enabled"],
        padding: double.parse(json["padding"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "padding": padding,
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

  factory Trakt.empty() => Trakt(
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
  final String color;
  final int maxItems;

  Watchlist({
    required this.enabled,
    required this.trakt,
    required this.tmdbApiKey,
    required this.prefix,
    required this.color,
    required this.maxItems,
  });

  factory Watchlist.empty() => Watchlist(
        enabled: false,
        trakt: Trakt.empty(),
        tmdbApiKey: "",
        prefix: "Watchlist: ",
        color: "#f5511d",
        maxItems: 4,
      );

  factory Watchlist.fromJson(Map<String, dynamic> json) => Watchlist(
        enabled: json["enabled"],
        trakt: Trakt.fromJson(json["trakt"]),
        tmdbApiKey: json["tmdbApiKey"],
        prefix: json["prefix"],
        color: json["color"],
        maxItems: json["maxItems"],
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "trakt": trakt.toJson(),
        "tmdbApiKey": tmdbApiKey,
        "prefix": prefix,
        "color": color,
        "maxItems": maxItems,
      };
}

class Weather {
  final bool enabled;
  final String apiKey;
  final String postcode;
  final String country;
  final String units;

  Weather({
    required this.enabled,
    required this.apiKey,
    required this.postcode,
    required this.country,
    required this.units,
  });

  factory Weather.empty() => Weather(
        enabled: false,
        apiKey: "",
        postcode: "",
        country: "",
        units: "metric",
      );

  factory Weather.fromJson(Map<String, dynamic> json) => Weather(
        enabled: json["enabled"],
        apiKey: json["apiKey"],
        postcode: json["postcode"],
        country: json["country"],
        units: json["units"],
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "apiKey": apiKey,
        "postcode": postcode,
        "country": country,
        "units": units,
      };
}
