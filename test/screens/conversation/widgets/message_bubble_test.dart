import 'package:fala/models/conversation_message.dart';
import 'package:fala/models/tutor_response.dart';
import 'package:fala/screens/conversation/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ConversationMessage _userMessage() => ConversationMessage(
      id: 'u1',
      role: MessageRole.user,
      content: 'eu vai na praia',
      timestamp: DateTime(2024),
    );

ConversationMessage _tutorMessage({required String translation}) =>
    ConversationMessage(
      id: 't1',
      role: MessageRole.tutor,
      content: 'Que bom! Voce gosta de praia?',
      timestamp: DateTime(2024),
      tutorResponse: TutorResponse(
        correction: const CorrectionBlock(
          content: 'Eu vou a praia.',
          translation: 'I go to the beach.',
          errors: [],
        ),
        conversation: ConversationBlock(
          content: 'Que bom! Voce gosta de praia?',
          translation: translation,
        ),
      ),
    );

Future<void> _pumpBubble(WidgetTester tester, ConversationMessage m) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MessageBubble(message: m),
      ),
    ),
  );
}

void main() {
  group('MessageBubble translation toggle', () {
    testWidgets('tutor message with translation: tap reveals, tap hides',
        (tester) async {
      const translation = 'Great! Do you like the beach?';
      await _pumpBubble(tester, _tutorMessage(translation: translation));

      expect(find.text(translation), findsNothing);

      await tester.tap(find.byType(MessageBubble));
      await tester.pumpAndSettle();
      expect(find.text(translation), findsOneWidget);

      await tester.tap(find.byType(MessageBubble));
      await tester.pumpAndSettle();
      expect(find.text(translation), findsNothing);
    });

    testWidgets('tutor message without translation: tap is inert',
        (tester) async {
      await _pumpBubble(tester, _tutorMessage(translation: ''));
      await tester.tap(find.byType(MessageBubble), warnIfMissed: false);
      await tester.pumpAndSettle();
      // No translation text exists, so just verify the message body is still
      // the only thing rendered.
      expect(find.text('Que bom! Voce gosta de praia?'), findsOneWidget);
    });

    testWidgets('user message: tap is inert and no translation shown',
        (tester) async {
      await _pumpBubble(tester, _userMessage());
      await tester.tap(find.byType(MessageBubble), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('eu vai na praia'), findsOneWidget);
    });
  });
}
