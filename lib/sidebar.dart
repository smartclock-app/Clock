import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartclock/calendar.dart';
import 'package:smartclock/info_widget.dart';
import 'package:smartclock/now_playing.dart';
import 'package:smartclock/notifications.dart';
import 'package:smartclock/util/config.dart' show Config, AlexaFeatures;

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.read<Config>();

    return Positioned(
      left: config.dimensions.sidebar.x,
      top: config.dimensions.sidebar.y,
      width: config.dimensions.sidebar.width,
      height: config.dimensions.sidebar.height,
      child: Container(
        padding: EdgeInsets.all(config.sidebar.padding),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (config.alexa.enabled) ...[
                if (config.alexa.features[AlexaFeatures.nowplaying]!)
                  if (config.alexa.devices.isNotEmpty)
                    const NowPlaying()
                  else
                    const InfoWidget(
                      title: "Now Playing",
                      message: "You have enabled Now Playing, but not entered any devices.\n\nTo hide this message, enter at least one device, or disable Now Playing.",
                    ),
                const Notifications(),
              ],
              if (config.calendar.enabled) const Calendar(),
              if (!config.alexa.enabled && !config.calendar.enabled)
                const InfoWidget(
                  title: "Widgets",
                  message: "No widgets enabled.\n\nYou can enable widgets in the conf file.\n\nTo hide this message, enable at least one widget, or disable the sidebar.",
                ),
            ],
          ),
        ),
      ),
    );
  }
}
