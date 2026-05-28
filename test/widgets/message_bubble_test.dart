import 'package:fala/models/conversation_message.dart';
import 'package:fala/screens/conversation/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('user message aligns right', (tester) async {
    final message = ConversationMessage(
      id: '1',
      role: MessageRole.user,
      content: 'Ola mundo',
      timestamp: DateTime(2024),
    );

    await tester.pumpWidget(wrapWidget(MessageBubble(message: message)));

    final align = tester.widget<Align>(find.byType(Align));
    expect(align.alignment, Alignment.centerRight);
    expect(find.text('Ola mundo'), findsOneWidget);
  });

  testWidgets('tutor message aligns left', (tester) async {
    final message = ConversationMessage(
      id: '2',
      role: MessageRole.tutor,
      content: 'Muito bem!',
      timestamp: DateTime(2024),
    );

    await tester.pumpWidget(wrapWidget(MessageBubble(message: message)));

    final align = tester.widget<Align>(find.byType(Align));
    expect(align.alignment, Alignment.centerLeft);
    expect(find.text('Muito bem!'), findsOneWidget);
  });
}
