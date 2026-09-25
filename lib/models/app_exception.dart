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

/// A conversation's target language was changed after it already had messages.
///
/// The language is fixed when a conversation starts: its history is in the old
/// language, and switching in place would hand the model a bilingual transcript
/// to correct. Callers start a new conversation instead.
class LanguageLockedException extends AppException {
  const LanguageLockedException({required super.message, super.cause});
}

/// A prompt template was built with a placeholder left unsubstituted.
class PromptTemplateException extends AppException {
  const PromptTemplateException({required super.message, super.cause});
}
