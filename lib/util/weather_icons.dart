import 'package:flutter/material.dart';

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
    "wind": "\uea14",
  };

  static Widget getIcon(String icon, {required double size, Color color = Colors.black, Shadow? shadow}) {
    return SizedBox(
      width: size,
      child: Text(
        icons[icon] ?? "",
        style: TextStyle(
          color: color,
          fontFamily: "WeatherIcons",
          fontSize: size,
          height: 1,
          shadows: shadow != null ? [shadow] : null,
        ),
      ),
    );
  }
}
