import '../models/app_exception.dart';

/// Maps [AppException] subtypes to user-friendly messages.
///
/// Centralized for future localization support.
class ErrorMessages {
  const ErrorMessages._();

  /// Get a user-facing message for the given exception.
  static String forException(AppException exception) {
    return switch (exception) {
      InferenceException() => 'The AI could not generate a response. '
          'Please try again.',
      ModelException() => 'There was a problem with the language model. '
          'Please restart the app.',
      StorageException() => 'Could not save or load data. '
          'Please check available storage.',
      NetworkException() => 'Network error. '
          'Please check your connection and try again.',
    };
  }
}
