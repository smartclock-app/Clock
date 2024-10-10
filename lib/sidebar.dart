import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartclock/calendar.dart';
import 'package:smartclock/info_widget.dart';
import 'package:smartclock/now_playing.dart';
import 'package:smartclock/notifications.dart';
import 'package:smartclock/util/config.dart' show Config;

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.read<Config>();
    final dimensions = config.dimensions.sidebar.split(",").map((e) => double.parse(e)).toList();

    return Positioned(
      left: dimensions[0],
      top: dimensions[1],
      width: dimensions[2],
      height: dimensions[3],
      child: Container(
        padding: EdgeInsets.all(config.sidebar.padding),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (config.alexa.enabled) ...[
                const NowPlaying(),
                const Notifications(),
              ],
              if (config.calendar.enabled) const Calendar(),
              if (!config.alexa.enabled && !config.calendar.enabled) const InfoWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
