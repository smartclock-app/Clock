import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:smartclock/sidebar_card.dart';
import 'package:smartclock/util/config.dart' show ConfigModel, Config;
import 'package:smartclock/main.dart' show logger;

typedef EnergyData = ({String? gas, String? electricity});

class Energy extends StatefulWidget {
  const Energy({super.key});

  @override
  State<Energy> createState() => _EnergyState();
}

class _EnergyState extends State<Energy> {
  StreamSubscription<void>? _subscription;
  late Future<EnergyData> _data;
  late Config config;

  Future<EnergyData> _fetchData() async {
    logger.t("Refetching weather");
    if (config.energy.token.isEmpty || config.energy.electricityId.isEmpty || config.energy.gasId.isEmpty) {
      throw Exception("Energy token and ids must be set in the config file.");
    }

    final midnightToday = "${DateTime.now().toUtc().toIso8601String().split("T")[0]}T00:00:00";
    final midnightTomorrow = "${DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String().split("T")[0]}T00:00:00";

    final options = Options(headers: {"Content-Type": "application/json", "applicationId": "b0f1b774-a586-4f72-9edd-27ead8aa7a8d", "token": config.energy.token});

    try {
      Response gasResponse = await Dio().get(
        "https://api.glowmarkt.com/api/v0-1/resource/${config.energy.gasId}/readings?from=$midnightToday&to=$midnightTomorrow&function=sum&period=P1D",
        options: options,
      );
      Response electricityResponse = await Dio().get(
        "https://api.glowmarkt.com/api/v0-1/resource/${config.energy.electricityId}/readings?from=$midnightToday&to=$midnightTomorrow&function=sum&period=P1D",
        options: options,
      );

      final gasCost = gasResponse.data["data"]?[0]?[1];
      final electricityCost = electricityResponse.data["data"]?[0]?[1];
      return (gas: "£${(gasCost / 100).toStringAsFixed(2)}", electricity: "£${(electricityCost / 100).toStringAsFixed(2)}");
    } catch (e, stack) {
      logger.e(e);
      logger.e(stack);
      return (gas: null, electricity: null);
    }
  }

  @override
  void initState() {
    super.initState();
    config = context.read<ConfigModel>().config;
    _data = _fetchData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = Provider.of<StreamController<DateTime>>(context).stream;
    _subscription?.cancel();
    _subscription = stream.listen((time) {
      // Refetch every half hour
      if ((time.minute == 0 || time.minute == 30) && time.second == 0) {
        setState(() {
          _data = _fetchData();
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
      future: _data,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

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
                    Icon(Icons.electric_meter_outlined, size: config.energy.iconSize),
                    const SizedBox(width: 16),
                    Text(snapshot.data?.electricity ?? "No Data", style: TextStyle(fontSize: config.energy.fontSize, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.gas_meter_outlined, size: config.energy.iconSize),
                    const SizedBox(width: 16),
                    Text(snapshot.data?.gas ?? "No Data", style: TextStyle(fontSize: config.energy.fontSize, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
