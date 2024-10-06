import 'package:flutter/material.dart';
import 'package:smartclock/calendar.dart';
import 'package:provider/provider.dart';
import 'package:smartclock/now_playing.dart';
import 'package:smartclock/notifications.dart';
import 'package:smartclock/util/config.dart' show Config;

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<Config>(context);
    final dimensions = config.dimensions.sidebar.split(",").map((e) => double.parse(e)).toList();

    return Positioned(
      left: dimensions[0],
      top: dimensions[1],
      width: dimensions[2],
      height: dimensions[3],
      child: Container(
        padding: EdgeInsets.all(config.sidebar.padding),
        child: const SingleChildScrollView(
          child: Column(
            children: [
              NowPlaying(),
              Notifications(),
              Calendar(),
            ],
          ),
        ),
      ),
    );
  }
}
