import 'package:fala/models/target_language.dart';
import 'package:fala/screens/conversation/widgets/language_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('languageSwitchAction', () {
    test('a dismissed sheet does nothing', () {
      expect(
        languageSwitchAction(
          picked: null,
          current: TargetLanguage.ptBr,
          hasMessages: true,
        ),
        LanguageSwitchAction.none,
      );
    });

    test('picking the language already in use does nothing', () {
      expect(
        languageSwitchAction(
          picked: TargetLanguage.ptBr,
          current: TargetLanguage.ptBr,
          hasMessages: false,
        ),
        LanguageSwitchAction.none,
      );
    });

    test('an empty conversation switches in place', () {
      expect(
        languageSwitchAction(
          picked: TargetLanguage.esEs,
          current: TargetLanguage.ptBr,
          hasMessages: false,
        ),
        LanguageSwitchAction.switchInPlace,
      );
    });

    test('a conversation with messages asks before restarting', () {
      expect(
        languageSwitchAction(
          picked: TargetLanguage.esEs,
          current: TargetLanguage.ptBr,
          hasMessages: true,
        ),
        LanguageSwitchAction.confirmRestart,
      );
    });
  });

  testWidgets('the confirm dialog names the language and both choices', (
    tester,
  ) async {
    bool? answer;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              answer = await showLanguageSwitchDialog(
                context,
                language: TargetLanguage.frFr,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Start over in French?'), findsOneWidget);
    expect(find.text('Keep this one'), findsOneWidget);

    await tester.tap(find.text('Keep this one'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(answer, isFalse);
  });

  testWidgets('the picker lists every language and returns the tapped one', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    TargetLanguage? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              picked = await showLanguagePickerSheet(
                context,
                current: TargetLanguage.ptBr,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 400));

    for (final language in TargetLanguage.values) {
      expect(
        find.text(language.endonym),
        findsOneWidget,
        reason: language.name,
      );
    }

    // The sheet is height-capped, so the last entry starts below the fold and a
    // tap at its offset would miss.
    await tester.ensureVisible(find.text('German'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('German'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(picked, TargetLanguage.deDe);
  });
}
