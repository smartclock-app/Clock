import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:smartclock/util/weather_icons.dart';
import 'package:smartclock/util/config.dart' show ConfigModel, Config;

class WeatherFloating extends StatelessWidget {
  const WeatherFloating({super.key, required this.weather});

  final Map<String, String> weather;

  @override
  Widget build(BuildContext context) {
    Config config = context.read<ConfigModel>().config;

    return Positioned(
      left: config.dimensions["weather"]!.x,
      top: config.dimensions["weather"]!.y,
      width: config.dimensions["weather"]!.width,
      height: config.dimensions["weather"]!.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              WeatherIcons.getIcon(weather["icon"] ?? "", size: config.weather.iconSize),
              const SizedBox(width: 16),
              Text(weather["temp"]!, style: TextStyle(fontSize: config.weather.fontSize, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              Text(weather["windSpeed"]!, style: TextStyle(fontSize: config.weather.fontSize, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              WeatherIcons.getIcon("wind", size: config.weather.iconSize),
            ],
          )
        ],
      ),
    );
  }
}
