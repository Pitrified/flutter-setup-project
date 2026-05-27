import 'package:freezed_annotation/freezed_annotation.dart';

part 'tutor_response.freezed.dart';
part 'tutor_response.g.dart';

/// Full structured response from the tutor LLM.
///
/// Contains a correction block (with the corrected sentence + individual errors)
/// and a conversation block (the tutor's conversational reply).
@freezed
abstract class TutorResponse with _$TutorResponse {
  const factory TutorResponse({
    required CorrectionBlock correction,
    required ConversationBlock conversation,
  }) = _TutorResponse;

  factory TutorResponse.fromJson(Map<String, dynamic> json) =>
      _$TutorResponseFromJson(json);
}

/// Correction block: the full corrected sentence + individual errors.
///
/// If the user's message has no errors, [content] and [translation] are empty
/// strings and [errors] is an empty list.
@freezed
abstract class CorrectionBlock with _$CorrectionBlock {
  const factory CorrectionBlock({
    required String content,
    required String translation,
    required List<CorrectionError> errors,
  }) = _CorrectionBlock;

  factory CorrectionBlock.fromJson(Map<String, dynamic> json) =>
      _$CorrectionBlockFromJson(json);
}

/// A single error the tutor identified in the user's message.
@freezed
abstract class CorrectionError with _$CorrectionError {
  const factory CorrectionError({
    required String original,
    required String corrected,
    required String explanation,
  }) = _CorrectionError;

  factory CorrectionError.fromJson(Map<String, dynamic> json) =>
      _$CorrectionErrorFromJson(json);
}

/// Conversation block: the tutor's conversational reply.
@freezed
abstract class ConversationBlock with _$ConversationBlock {
  const factory ConversationBlock({
    required String content,
    required String translation,
  }) = _ConversationBlock;

  factory ConversationBlock.fromJson(Map<String, dynamic> json) =>
      _$ConversationBlockFromJson(json);
}
