import 'package:flutter/widgets.dart';

class WeatherIcons {
  static const Map<String, String> icons = {
    "01d": "\uea02",
    "01n": "\uea01",
    "02d": "\uea03",
    "02n": "\uea04",
    "03d": "\uea05",
    "03n": "\uea06",
    "04d": "\uea07",
    "04n": "\uea08",
    "09d": "\uea09",
    "09n": "\uea0a",
    "10d": "\uea0b",
    "10n": "\uea0c",
    "11d": "\uea0d",
    "11n": "\uea0e",
    "1232n": "\uea0f",
    "13d": "\uea10",
    "13n": "\uea11",
    "50d": "\uea12",
    "50n": "\uea13",
  };

  static Widget getIcon(String icon) {
    return Text(
      icons[icon] ?? "",
      style: const TextStyle(
        fontFamily: "WeatherIcons",
        fontSize: 50,
        height: 1,
      ),
    );
  }
}
