import 'package:logger/logger.dart';

/// Project-wide logger instance.
///
/// Use this instead of print/debugPrint throughout the app.
/// Log levels: trace, debug, info, warning, error, fatal.
final log = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
