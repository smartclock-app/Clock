import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final logger = Logger(
  level: kDebugMode ? Level.trace : Level.info,
  printer: PrettyPrinter(),
);
