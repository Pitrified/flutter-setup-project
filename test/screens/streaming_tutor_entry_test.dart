import 'package:fala/models/conversation_message.dart';
import 'package:fala/models/tutor_response.dart';
import 'package:fala/screens/conversation/widgets/streaming_reply_view.dart';
import 'package:fala/screens/conversation/widgets/streaming_tutor_entry.dart';
import 'package:fala/services/inference/partial_json_parser.dart';
import 'package:fala/services/inference/structured_stream_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Build a delta from a truncated buffer via the real tolerant parser, so the
/// partial map + closed-flags are realistic.
StructuredDelta<TutorResponse> _delta(String buffer, {bool complete = false}) {
  final result = const PartialJsonParser().parse(buffer);
  return StructuredDelta<TutorResponse>(
    partial: result.value,
    closure: result.closure,
    isComplete: complete,
    value: complete ? TutorResponse.fromJson(result.value) : null,
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('StreamingTutorEntry', () {
    testWidgets('reply text grows as the buffer fills', (tester) async {
      await tester.pumpWidget(
        _wrap(StreamingTutorEntry(
          delta: _delta('{"conversation":{"content":"Ol'),
        )),
      );
      expect(find.text('Ol'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(StreamingTutorEntry(
          delta: _delta('{"conversation":{"content":"Ola!"'),
        )),
      );
      expect(find.text('Ola!'), findsOneWidget);
      expect(find.text('Ol'), findsNothing);
    });

    testWidgets('a correction row appears partial then completes',
        (tester) async {
      // A RichText whose rendered plain text contains [s].
      Finder richTextWith(String s) => find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains(s),
          );

      // original present, corrected not yet -> no strike->replace, no
      // explanation.
      await tester.pumpWidget(
        _wrap(StreamingTutorEntry(
          delta: _delta('{"correction":{"errors":[{"original":"eu gosto"'),
        )),
      );
      expect(find.text('eu gosto'), findsOneWidget);
      expect(richTextWith('Eu gosto'), findsNothing);
      expect(find.text('Capitalize.'), findsNothing);

      // Both present and closed -> full strike->replace + explanation.
      await tester.pumpWidget(
        _wrap(StreamingTutorEntry(
          delta: _delta(
            '{"correction":{"errors":[{"original":"eu gosto",'
            '"corrected":"Eu gosto","explanation":"Capitalize."}]}}',
          ),
        )),
      );
      expect(richTextWith('Eu gosto'), findsOneWidget);
      expect(find.text('Capitalize.'), findsOneWidget);
    });

    testWidgets('does not throw on null/absent leaves', (tester) async {
      await tester.pumpWidget(
        _wrap(StreamingTutorEntry(delta: _delta('{"correction":{"errors":[{'))),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(StreamingTutorEntry), findsOneWidget);
    });
  });

  group('showStreamingOverlay', () {
    ConversationMessage msg(MessageRole role) => ConversationMessage(
          id: role.name,
          role: role,
          content: 'x',
          timestamp: DateTime(2026),
        );

    test('hidden when not sending', () {
      expect(
        showStreamingOverlay(isSending: false, messages: [msg(MessageRole.user)]),
        isFalse,
      );
    });

    test('shown while sending and awaiting the tutor reply', () {
      expect(
        showStreamingOverlay(isSending: true, messages: [msg(MessageRole.user)]),
        isTrue,
      );
    });

    test('hidden once the tutor message is committed (handoff)', () {
      expect(
        showStreamingOverlay(
          isSending: true,
          messages: [msg(MessageRole.user), msg(MessageRole.tutor)],
        ),
        isFalse,
      );
    });

    test('hidden when there are no messages', () {
      expect(showStreamingOverlay(isSending: true, messages: const []), isFalse);
    });
  });
}
