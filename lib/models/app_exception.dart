/// Application-level exception hierarchy.
///
/// All domain exceptions extend [AppException]. Use specific subtypes
/// to classify failures for error handling and user-facing messages.
sealed class AppException implements Exception {
  const AppException({required this.message, this.cause});

  /// Human-readable description of what went wrong.
  final String message;

  /// Optional underlying error that caused this exception.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Inference engine failed to generate or initialize.
class InferenceException extends AppException {
  const InferenceException({required super.message, super.cause});
}

/// Model file operations failed (download, verification, deletion).
class ModelException extends AppException {
  const ModelException({required super.message, super.cause});
}

/// Local storage operations failed (Hive, file I/O).
class StorageException extends AppException {
  const StorageException({required super.message, super.cause});
}

/// Network operations failed (HTTP, connectivity).
class NetworkException extends AppException {
  const NetworkException({required super.message, super.cause});
}
