import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:smartclock/widgets/sidebar/sidebar_card.dart';

import 'package:smartclock/widgets/weather/weather_icons.dart';
import 'package:smartclock/config/config.dart' show ConfigModel, Config;

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.weather});

  final Map<String, String> weather;

  @override
  Widget build(BuildContext context) {
    Config config = context.read<ConfigModel>().config;

    return SidebarCard(
      padding: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xfff8f8f8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                WeatherIcons.getIcon(weather["icon"] ?? "", size: config.weather.iconSize),
                const SizedBox(width: 16),
                Text(weather["temp"]!, style: TextStyle(fontSize: config.weather.fontSize, fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                WeatherIcons.getIcon("wind", size: config.weather.iconSize),
                const SizedBox(width: 16),
                Text(weather["windSpeed"]!, style: TextStyle(fontSize: config.weather.fontSize, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
