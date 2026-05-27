import 'package:fala/models/conversation_message.dart';
import 'package:fala/models/inference_status.dart';
import 'package:fala/models/tutor_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConversationMessage', () {
    test('creates from factory', () {
      final msg = ConversationMessage(
        id: '1',
        role: MessageRole.user,
        content: 'Eu gosto de cafe',
        timestamp: DateTime(2025),
      );

      expect(msg.role, MessageRole.user);
      expect(msg.content, 'Eu gosto de cafe');
      expect(msg.tutorResponse, isNull);
    });

    test('roundtrips through JSON', () {
      final msg = ConversationMessage(
        id: '1',
        role: MessageRole.tutor,
        content: 'Quase perfeito!',
        timestamp: DateTime(2025),
        tutorResponse: const TutorResponse(
          correction: CorrectionBlock(
            content: 'Eu gosto de cafe',
            translation: 'I like coffee',
            errors: [
              CorrectionError(
                original: 'cafe',
                corrected: 'cafe',
                explanation: 'Missing accent on e',
              ),
            ],
          ),
          conversation: ConversationBlock(
            content: 'Quase perfeito!',
            translation: 'Almost perfect!',
          ),
        ),
      );

      final json = msg.toJson();
      final restored = ConversationMessage.fromJson(json);
      expect(restored, msg);
    });
  });

  group('InferenceStatus', () {
    test('sealed union exhaustive matching', () {
      const status = InferenceStatus.ready();
      final label = switch (status) {
        InferenceStatusUninitialized() => 'uninitialized',
        InferenceStatusLoading() => 'loading',
        InferenceStatusReady() => 'ready',
        InferenceStatusGenerating() => 'generating',
        InferenceStatusError() => 'error',
        InferenceStatusDisposed() => 'disposed',
      };
      expect(label, 'ready');
    });
  });
}
