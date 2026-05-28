import 'package:fala/models/tutor_response.dart';
import 'package:fala/screens/conversation/widgets/correction_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('displays corrections with original and corrected text',
      (tester) async {
    const corrections = [
      CorrectionError(
        original: 'eu sou',
        corrected: 'eu estou',
        explanation: 'Use estar for temporary states',
      ),
    ];

    await tester.pumpWidget(
      wrapWidget(const CorrectionCard(corrections: corrections)),
    );

    // RichText contains the correction spans
    expect(find.byType(RichText), findsWidgets);
    expect(find.text('Use estar for temporary states'), findsOneWidget);
  });

  testWidgets('displays multiple corrections', (tester) async {
    const corrections = [
      CorrectionError(
        original: 'a',
        corrected: 'b',
        explanation: 'fix 1',
      ),
      CorrectionError(
        original: 'c',
        corrected: 'd',
        explanation: 'fix 2',
      ),
    ];

    await tester.pumpWidget(
      wrapWidget(const CorrectionCard(corrections: corrections)),
    );

    expect(find.text('fix 1'), findsOneWidget);
    expect(find.text('fix 2'), findsOneWidget);
  });
}
