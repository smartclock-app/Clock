import 'package:logger/logger.dart';

class LoggerUtil {
  static bool isInitialized = false;
  static late final Logger _logger;

  static init(Logger logger) {
    isInitialized = true;
    _logger = logger;
  }

  static Logger get logger {
    if (!isInitialized) {
      throw Exception("Logger is not initialized");
    }
    return _logger;
  }
}
