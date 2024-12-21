import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import 'package:smartclock/main.dart' show logger;
import 'package:smartclock/config/config.dart' show ConfigModel, Config, WeatherType;
import 'package:smartclock/util/event_utils.dart';
import 'package:smartclock/widgets/weather/weather_card.dart';
import 'package:smartclock/widgets/weather/weather_floating.dart';

class Weather extends StatefulWidget {
  const Weather({super.key, required this.type});

  final WeatherType type;

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
    final stream = context.read<StreamController<ClockEvent>>().stream;
    _subscription?.cancel();
    _subscription = stream.listen((event) {
      if (event.event == ClockEvents.refetch) {
        setState(() {
          _weather = _fetchWeather();
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _weather,
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        final weather = snapshot.data;
        if (weather == null) {
          return const SizedBox.shrink();
        }

        if (widget.type == WeatherType.floating) {
          return WeatherFloating(weather: weather);
        } else if (widget.type == WeatherType.card) {
          return WeatherCard(weather: weather);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
