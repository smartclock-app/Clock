import 'package:flutter/widgets.dart';
import 'package:smartclock/config/config.dart' show Config, Dimension;
import 'package:smartclock/util/logger_util.dart';

/// Automatically generates the values for the dimensions of the clock, sidebar, and weather widgets if none are provided.
void computeDefaultDimensions({required Config config, required double width, required double height}) {
  if (config.dimensions.isEmpty) {
    final logger = LoggerUtil.logger;
    logger.i("[Resolution] No dimensions set: Computing default dimensions");

    final weatherPadding = config.clock.padding * 4;
    final isLandscape = config.orientation == Orientation.landscape;

    final computedDimensions = isLandscape
        ? {
            'clock': Dimension(
              x: 0,
              y: 0,
              width: height,
              height: height,
            ),
            'sidebar': Dimension(
              x: height - config.clock.padding,
              y: 0,
              width: width - height + config.clock.padding,
              height: height,
            ),
            'weather': Dimension(
              x: weatherPadding,
              y: weatherPadding,
              width: height - (2 * weatherPadding),
              height: 0,
            ),
          }
        : {
            'clock': Dimension(
              x: 0,
              y: 0,
              width: width,
              height: width / 2,
            ),
            'sidebar': Dimension(
              x: 0,
              y: width - config.clock.padding,
              width: width,
              height: height - width + config.clock.padding,
            ),
            'weather': Dimension(
              x: weatherPadding,
              y: weatherPadding,
              width: width - (2 * weatherPadding),
              height: 0,
            ),
          };

    config.dimensions.addAll(computedDimensions);
  }
}
