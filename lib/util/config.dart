class Config {
  static const String schema = "https://www.smartclock.app/schema/v3.json";
  final String resolution;
  final Alexa alexa;
  final Clock clock;
  final Calendar calendar;
  final Sidebar sidebar;
  final Watchlist watchlist;
  final Weather weather;
  final Dimensions dimensions;

  Config({
    required this.resolution,
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

  factory Config.fromJson(Map<String, dynamic> json) => Config(
        resolution: json["resolution"],
        alexa: Alexa.fromJson(json["alexa"]),
        clock: Clock.fromJson(json["clock"]),
        calendar: Calendar.fromJson(json["calendar"]),
        sidebar: Sidebar.fromJson(json["sidebar"]),
        watchlist: Watchlist.fromJson(json["watchlist"]),
        weather: Weather.fromJson(json["weather"]),
        dimensions: Dimensions.fromJson(json["dimensions"]),
      );

  Map<String, dynamic> toJson() => {
        "\$schema": schema,
        "resolution": resolution,
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

class Dimensions {
  final String clock;
  final String sidebar;
  final String weather;

  Dimensions({
    required this.clock,
    required this.sidebar,
    required this.weather,
  });

  factory Dimensions.fromJson(Map<String, dynamic> json) => Dimensions(
        clock: json["clock"],
        sidebar: json["sidebar"],
        weather: json["weather"],
      );

  Map<String, dynamic> toJson() => {
        "clock": clock,
        "sidebar": sidebar,
        "weather": weather,
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
    required this.monthTitleSize,
    required this.eventTitleSize,
    required this.eventTimeSize,
    required this.eventColorSize,
  });

  factory Calendar.fromJson(Map<String, dynamic> json) => Calendar(
        enabled: json["enabled"],
        clientId: json["clientId"],
        clientSecret: json["clientSecret"],
        accessToken: json["accessToken"],
        refreshToken: json["refreshToken"],
        maxEvents: json["maxEvents"],
        titles: Titles.fromJson(json["titles"]),
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

  factory Sidebar.fromJson(Map<String, dynamic> json) => Sidebar(
        enabled: json["enabled"],
        padding: double.parse(json["padding"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "padding": padding,
      };
}

class WatchlistItem {
  final String type;
  final String id;

  WatchlistItem({
    required this.type,
    required this.id,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) => WatchlistItem(
        type: json["type"],
        id: json["id"],
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "id": id,
      };
}

class Watchlist {
  final bool enabled;
  final String apiKey;
  final String prefix;
  final String color;
  final List<WatchlistItem> items;

  Watchlist({
    required this.enabled,
    required this.apiKey,
    required this.prefix,
    required this.color,
    required this.items,
  });

  factory Watchlist.fromJson(Map<String, dynamic> json) => Watchlist(
        enabled: json["enabled"],
        apiKey: json["apiKey"],
        prefix: json["prefix"],
        color: json["color"],
        items: List<WatchlistItem>.from(json["items"].map((x) => WatchlistItem.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
        "apiKey": apiKey,
        "prefix": prefix,
        "color": color,
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
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
