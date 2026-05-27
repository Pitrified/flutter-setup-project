import 'package:fala/services/prompt/prompt_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const templateContent = '''You are a tutor at {{cefr_level}} level.
User says: {{user_message}}''';

  late PromptManager manager;

  setUp(() {
    manager = PromptManager();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = String.fromCharCodes(message!.buffer.asUint8List());
      if (key == 'assets/prompts/tutor_response/v1.txt') {
        return ByteData.sublistView(
          Uint8List.fromList(templateContent.codeUnits),
        );
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  test('loads template by explicit version', () async {
    final content = await manager.loadTemplate(
      name: 'tutor_response',
      version: 1,
    );
    expect(content, contains('{{cefr_level}}'));
  });

  test('substitutes variables correctly', () async {
    final prompt = await manager.buildPrompt(
      name: 'tutor_response',
      version: 1,
      variables: {
        'cefr_level': 'A1',
        'user_message': 'Ola mundo',
      },
    );
    expect(prompt, contains('A1'));
    expect(prompt, contains('Ola mundo'));
    expect(prompt, isNot(contains('{{cefr_level}}')));
  });

  test('unknown variables are left as-is', () async {
    final prompt = await manager.buildPrompt(
      name: 'tutor_response',
      version: 1,
      variables: {'cefr_level': 'B1'},
    );
    expect(prompt, contains('{{user_message}}'));
  });

  test('caches templates on second load', () async {
    await manager.loadTemplate(name: 'tutor_response', version: 1);
    // Remove mock - second call should use cache
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    final content = await manager.loadTemplate(
      name: 'tutor_response',
      version: 1,
    );
    expect(content, contains('{{cefr_level}}'));
  });
}
