class Config {
  final String resolution;
  final Alexa alexa;
  final Clock clock;
  final Calendar calendar;
  final Sidebar sidebar;
  final Weather weather;
  final Dimensions dimensions;

  Config({
    required this.resolution,
    required this.alexa,
    required this.clock,
    required this.calendar,
    required this.sidebar,
    required this.weather,
    required this.dimensions,
  });

  factory Config.fromJson(Map<String, dynamic> json) => Config(
        resolution: json["resolution"],
        alexa: Alexa.fromJson(json["alexa"]),
        clock: Clock.fromJson(json["clock"]),
        calendar: Calendar.fromJson(json["calendar"]),
        sidebar: Sidebar.fromJson(json["sidebar"]),
        weather: Weather.fromJson(json["weather"]),
        dimensions: Dimensions.fromJson(json["dimensions"]),
      );

  Map<String, dynamic> toJson() => {
        "resolution": resolution,
        "alexa": alexa.toJson(),
        "clock": clock.toJson(),
        "calendar": calendar.toJson(),
        "sidebar": sidebar.toJson(),
        "weather": weather.toJson(),
        "dimensions": dimensions.toJson(),
      };
}

class Alexa {
  final bool enabled;
  final String userId;
  final String token;
  final List<String> devices;

  Alexa({
    required this.enabled,
    required this.userId,
    required this.token,
    required this.devices,
  });

  factory Alexa.fromJson(Map<String, dynamic> json) => Alexa(
        enabled: json["enabled"],
        userId: json["userId"],
        token: json["token"],
        devices: List<String>.from(json["devices"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "enabled": enabled,
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

class Calendar {
  final bool enabled;
  final String clientId;
  final String clientSecret;
  String accessToken;
  String refreshToken;
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
        "monthTitleSize": monthTitleSize,
        "eventTitleSize": eventTitleSize,
        "eventTimeSize": eventTimeSize,
        "eventColorSize": eventColorSize,
      };
}

class Sidebar {
  final double padding;

  Sidebar({
    required this.padding,
  });

  factory Sidebar.fromJson(Map<String, dynamic> json) => Sidebar(
        padding: double.parse(json["padding"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "padding": padding,
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
