part of 'config.dart';

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
