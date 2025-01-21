import 'package:smartclock/config/config.dart' show Config, Dimension;
import 'package:smartclock/util/logger_util.dart';

/// Automatically generates the values for the dimensions of the clock, sidebar, and weather widgets if none are provided.
void computeDefaultDimensions({required Config config, required double width, required double height}) {
  if (config.dimensions.isEmpty) {
    final logger = LoggerUtil.logger;
    logger.i("[Resolution] No dimensions set: Computing default dimensions");

    final weatherPadding = config.clock.padding * 4;

    final computedDimensions = {
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
    };

    config.dimensions.addAll(computedDimensions);
  }
}
