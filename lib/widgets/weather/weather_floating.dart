import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:smartclock/widgets/weather/util/weather_icons.dart';
import 'package:smartclock/config/config.dart' show ConfigModel, Config;

class WeatherFloating extends StatelessWidget {
  const WeatherFloating({super.key, required this.weather});

  final Map<String, String> weather;

  @override
  Widget build(BuildContext context) {
    Config config = context.read<ConfigModel>().config;

    final fontColor = config.photos.enabled ? Colors.white : Colors.black;
    final shadow = Shadow(
      offset: const Offset(2.0, 2.0),
      blurRadius: 3.0,
      color: Colors.black.withAlpha(128),
    );

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
              WeatherIcons.getIcon(weather["icon"] ?? "", size: config.weather.iconSize, color: fontColor, shadow: shadow),
              const SizedBox(width: 16),
              Text(
                weather["temp"]!,
                style: TextStyle(
                  fontSize: config.weather.fontSize,
                  fontWeight: FontWeight.bold,
                  color: fontColor,
                  shadows: config.photos.enabled ? [shadow] : null,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                weather["windSpeed"]!,
                style: TextStyle(
                  fontSize: config.weather.fontSize,
                  fontWeight: FontWeight.bold,
                  color: fontColor,
                  shadows: config.photos.enabled ? [shadow] : null,
                ),
              ),
              const SizedBox(width: 16),
              WeatherIcons.getIcon("wind", size: config.weather.iconSize, color: fontColor, shadow: shadow),
            ],
          )
        ],
      ),
    );
  }
}
