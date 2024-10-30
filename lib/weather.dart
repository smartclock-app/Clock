import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import 'package:smartclock/util/logger.dart';
import 'package:smartclock/util/weather_icons.dart';
import 'package:smartclock/util/config.dart' show ConfigModel, Config;

class Weather extends StatefulWidget {
  const Weather({super.key});

  @override
  State<Weather> createState() => _WeatherState();
}

class _WeatherState extends State<Weather> {
  StreamSubscription<void>? _subscription;
  late Future<Map<String, String>> _weather;
  late Config config;

  Future<Map<String, String>> _fetchWeather() async {
    logger.t("Refetching weather");
    if (config.weather.apiKey.isEmpty || config.weather.postcode.isEmpty || config.weather.country.isEmpty || config.weather.units.isEmpty) {
      throw Exception("Weather API Key, Postcode, Country, and Units must be set in the config file.");
    }

    try {
      Response response = await Dio().get(
        "https://api.openweathermap.org/data/2.5/weather?zip=${config.weather.postcode},${config.weather.country}&appid=${config.weather.apiKey}&units=${config.weather.units}",
      );
      final icon = response.data["weather"][0]["icon"];
      final temp = response.data["main"]["temp"];
      final windSpeed = response.data["wind"]["speed"];
      return {
        "icon": icon,
        "temp": "${temp.round()}ºC",
        "windSpeed": "${windSpeed.round()} mph",
      };
    } catch (e) {
      logger.e(e);
      return {};
    }
  }

  @override
  void initState() {
    super.initState();
    config = context.read<ConfigModel>().config;
    _weather = _fetchWeather();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = Provider.of<StreamController<DateTime>>(context).stream;
    _subscription?.cancel();
    _subscription = stream.listen((_) {
      setState(() {
        _weather = _fetchWeather();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    Config config = context.read<ConfigModel>().config;

    return FutureBuilder(
      future: _weather,
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        final weather = snapshot.data as Map<String, String>;

        return Positioned(
          left: config.dimensions.weather.x,
          top: config.dimensions.weather.y,
          width: config.dimensions.weather.width,
          height: config.dimensions.weather.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  WeatherIcons.getIcon(weather["icon"] ?? "", size: config.weather.iconSize),
                  const SizedBox(width: 16),
                  Text(weather["temp"]!, style: TextStyle(fontSize: config.weather.fontSize)),
                ],
              ),
              Row(
                children: [
                  Text(weather["windSpeed"]!, style: TextStyle(fontSize: config.weather.fontSize)),
                  const SizedBox(width: 16),
                  Icon(Icons.cloud_outlined, size: config.weather.iconSize),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
