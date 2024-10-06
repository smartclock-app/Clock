import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:smartclock/util/config.dart';
import 'package:smartclock/util/weather_icons.dart';

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
      print(e);
      return {};
    }
  }

  @override
  void initState() {
    super.initState();
    config = Provider.of<Config>(context, listen: false);
    _weather = _fetchWeather();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = Provider.of<StreamController<void>>(context).stream;
    _subscription?.cancel();
    _subscription = stream.listen((_) {
      setState(() {
        _weather = _fetchWeather();
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Config config = Provider.of<Config>(context);
    final dimensions = config.dimensions.weather.split(",").map((e) => double.parse(e)).toList();

    return FutureBuilder(
      future: _weather,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final weather = snapshot.data as Map<String, String>;

        return Positioned(
          left: dimensions[0],
          top: dimensions[1],
          width: dimensions[2],
          height: dimensions[3],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  WeatherIcons.getIcon(weather["icon"]!),
                  const SizedBox(width: 16),
                  Text(weather["temp"]!, style: const TextStyle(fontSize: 32)),
                ],
              ),
              Row(
                children: [
                  Text(weather["windSpeed"]!, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  const Icon(Icons.cloud_outlined, size: 50),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
