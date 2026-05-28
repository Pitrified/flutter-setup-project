import 'package:flutter/foundation.dart';

/// Debug-only memory and timing monitor.
///
/// Logs peak memory usage and inference timing at key checkpoints.
/// No-op in release builds.
class DebugMonitor {
  const DebugMonitor._();

  static const instance = DebugMonitor._();

  /// Log a timing measurement.
  void logTiming(String label, Duration duration) {
    if (kDebugMode) {
      debugPrint('[PERF] $label: ${duration.inMilliseconds}ms');
    }
  }

  /// Log a checkpoint (e.g., "engine initialized").
  void logCheckpoint(String label) {
    if (kDebugMode) {
      debugPrint('[PERF] checkpoint: $label');
    }
  }
}
