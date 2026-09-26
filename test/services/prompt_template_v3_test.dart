import 'package:fala/models/target_language.dart';
import 'package:fala/services/conversation/conversation_controller.dart';
import 'package:fala/services/prompt/prompt_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks the real shipped template against the real variable set, rather than
/// a fixture that could drift from either. The variables are the ones
/// `ConversationController.sendMessage` passes; if that list and the template
/// stop agreeing, `buildPrompt` throws and this test says which variable.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, String> variablesFor(TargetLanguage language) => {
    'target_language': language.promptName,
    'explanation_language': ConversationController.explanationLanguage,
    'cefr_level': 'A1',
    'topic': '',
    'user_message': 'Oi',
    'conversation_history': '',
  };

  test(
    'the latest template resolves with the controller variable set',
    () async {
      final prompt = await PromptManager().buildPrompt(
        name: 'tutor_response',
        variables: variablesFor(TargetLanguage.ptBr),
      );

      expect(prompt, contains('language tutor for Portuguese (Brazilian)'));
      expect(prompt, contains('English translation'));
      expect(prompt, isNot(contains('{{')));
    },
  );

  test('the same template names any other language', () async {
    final prompt = await PromptManager().buildPrompt(
      name: 'tutor_response',
      variables: variablesFor(TargetLanguage.deDe),
    );

    expect(prompt, contains('language tutor for German'));
    expect(prompt, contains('Always reply in German.'));
    expect(prompt, isNot(contains('Portuguese')));
  });
}
