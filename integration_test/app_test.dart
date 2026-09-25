// End-to-end test: the real app on a device or emulator, against the mock
// OpenAI server in `tool/mock_openai.py`.
//
//   python3 tool/mock_openai.py --port 8080 &
//   flutter test integration_test/app_test.dart -d emulator-5554 \
//     --dart-define=OPENAI_BASE_URL=http://10.0.2.2:8080/v1
//
// Or `scripts/e2e.sh`, which does both.
//
// This covers what `flutter_test` cannot: a `testWidgets` body runs on a fake
// clock, so the Hive writes behind `startConversation` never complete inside it,
// which is why the language default and the chip's double write had no automated
// test until now. Here the app is real and so is the clock.
//
// It is ONE test with numbered stages rather than four tests. Each stage depends
// on the state the last one left, and calling `app.main()` again per test starts
// a second app over the first, whose controllers keep streaming into a tree the
// finders no longer see. One journey, in order, is what actually holds.

import 'dart:convert';
import 'dart:io';

import 'package:fala/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Pump until [finder] matches or [timeout] passes.
///
/// `pumpAndSettle` is not usable here: the conversation screen runs a typing
/// indicator while a reply streams, so the frame queue never empties and it
/// times out even when everything is fine.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('timed out waiting for: ${finder.describeMatch(Plurality.one)}');
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

/// Base URL the app was built against, so the test drives the same server the
/// app talks to rather than a second one it assumes exists.
const _baseUrl = String.fromEnvironment('OPENAI_BASE_URL');

/// Put the mock into a scenario for the turns that follow.
///
/// The test runs on the device, so it reaches the host exactly as the app does.
/// This is why the failure paths need no second harness and no restart.
Future<void> mockScenario(String scenario) async {
  final control = Uri.parse(_baseUrl.replaceFirst(RegExp(r'/v1/?$'), ''))
      .resolve('/_control');
  final client = HttpClient();
  try {
    final request = await client.postUrl(control);
    request.write(jsonEncode({'scenario': scenario}));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      fail('mock refused scenario "$scenario": ${response.statusCode} $body');
    }
  } finally {
    client.close();
  }
}

/// Type into the message field and press send.
Future<void> send(WidgetTester tester, String message) async {
  await tester.enterText(find.byType(TextField).first, message);
  await tester.pump(const Duration(milliseconds: 300));
  await tapAndSettle(tester, find.byIcon(Icons.send));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the whole journey: key, language, a turn, and a switch', (
    tester,
  ) async {
    app.main();

    // ---- 1. store a key through the app's own Settings field ----------------
    // Deliberately not a debug-only bypass: this exercises secure storage and
    // the real field (plans/17_emulator_e2e/00_start.md Q2).
    await waitFor(tester, find.text('fala'));
    await tapAndSettle(tester, find.byTooltip('Settings'));
    await waitFor(tester, find.text('OpenAI'));

    await tester.enterText(
      find.byType(TextField).first,
      'sk-mock-key-for-tests',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tapAndSettle(tester, find.text('Save'));
    await waitFor(tester, find.text('A key is currently stored.'));

    // ---- 2. pick a language, and check it reaches a new conversation --------
    await tapAndSettle(tester, find.text('Portuguese (Brazilian)').last);
    await waitFor(tester, find.text('Italian'));
    await tapAndSettle(tester, find.text('Italian').last);

    await tapAndSettle(tester, find.byTooltip('Back'));
    // The welcome tagline reads the stored default: provider wiring the widget
    // tests could not reach.
    await waitFor(tester, find.text('Learn Italian by speaking'));

    await waitFor(tester, find.text('Start Conversation'));
    await tapAndSettle(tester, find.text('Start Conversation'));
    // The call site that silently ignored the setting until a diff review.
    await waitFor(tester, find.text('Say something in Italian!'));
    expect(find.text('Type in Italian...'), findsOneWidget);
    expect(find.text('italiano'), findsOneWidget);

    // ---- 3. a full turn against the mock ------------------------------------
    await send(tester, 'Ciao come stai');
    await waitFor(tester, find.textContaining('Ciao! Come stai oggi?'));
    expect(find.text('Ciao come stai'), findsOneWidget);

    // ---- 4. the chip refuses an in-place switch, and writes both places -----
    await tapAndSettle(tester, find.text('italiano'));
    await waitFor(tester, find.text('French'));
    await tapAndSettle(tester, find.text('French'));

    await waitFor(tester, find.textContaining('Start over in French?'));
    await tapAndSettle(tester, find.text('Keep this one'));

    // Declining keeps the conversation and its history in Italian...
    await waitFor(tester, find.text('italiano'));
    expect(find.text('Ciao come stai'), findsOneWidget);

    // ...and still moves the app default, which is the other half of the write.
    await tapAndSettle(tester, find.byTooltip('Open navigation menu'));
    await waitFor(tester, find.text('Settings'));
    await tapAndSettle(tester, find.text('Settings'));
    await waitFor(tester, find.text('French'));
    // Back from Settings returns to the conversation we came from (the drawer
    // opened it), not to the welcome screen.
    await tapAndSettle(tester, find.byTooltip('Back'));
    await waitFor(tester, find.byType(TextField));

    // ---- 5. the failure paths, driven by switching the mock at runtime ------
    await mockScenario('unauthorized');
    await send(tester, 'Ancora');
    await waitFor(
      tester,
      find.textContaining('OpenAI key missing or rejected'),
    );

    // A 200 whose content is not JSON reads as a failed turn, not as the tutor
    // writing English prose (plans/09_ui_tweaks/10_malformed_reply_display.md).
    await mockScenario('malformed');
    await send(tester, 'E ancora');
    await waitFor(
      tester,
      find.textContaining('the reply was not in the expected format'),
    );
    expect(find.textContaining('the model forgot the JSON'), findsNothing);

    await mockScenario('ok');
  });
}
