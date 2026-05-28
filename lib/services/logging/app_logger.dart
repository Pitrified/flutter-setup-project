import 'package:flutter/foundation.dart';

/// Application logger.
///
/// Logs to console in debug mode, no-op in release.
/// All services should use this instead of print/debugPrint.
class AppLogger {
  const AppLogger._();

  static const instance = AppLogger._();

  /// Log an informational message.
  void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  /// Log a warning.
  void warn(String message) {
    if (kDebugMode) {
      debugPrint('[WARN] $message');
    }
  }

  /// Log an error with optional cause.
  void error(String message, {Object? cause}) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (cause != null) {
        debugPrint('[ERROR] Cause: $cause');
      }
    }
  }
}
