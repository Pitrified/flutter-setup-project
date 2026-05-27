import 'package:freezed_annotation/freezed_annotation.dart';

part 'tutor_response.freezed.dart';
part 'tutor_response.g.dart';

/// Structured response from the tutor LLM.
@freezed
abstract class TutorResponse with _$TutorResponse {
  const factory TutorResponse({
    required String reply,
    required List<CorrectionBlock> corrections,
  }) = _TutorResponse;

  factory TutorResponse.fromJson(Map<String, dynamic> json) =>
      _$TutorResponseFromJson(json);
}

/// A single correction the tutor identified in the user's message.
@freezed
abstract class CorrectionBlock with _$CorrectionBlock {
  const factory CorrectionBlock({
    required String original,
    required String corrected,
    required String explanation,
    String? rule,
  }) = _CorrectionBlock;

  factory CorrectionBlock.fromJson(Map<String, dynamic> json) =>
      _$CorrectionBlockFromJson(json);
}
