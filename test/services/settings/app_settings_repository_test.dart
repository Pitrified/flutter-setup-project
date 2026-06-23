import 'dart:io';

import 'package:fala/models/cefr_level.dart';
import 'package:fala/services/inference/engine_kind.dart';
import 'package:fala/services/settings/app_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late AppSettingsRepository repo;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_settings_test_');
    Hive.init(tempDir.path);
    repo = AppSettingsRepository(boxName: 'test_app_settings');
    await repo.initialize();
  });

  tearDown(() async {
    await repo.close();
    await tempDir.delete(recursive: true);
  });

  test('engineKind defaults to openai when nothing is stored', () {
    expect(repo.engineKind(), EngineKind.openai);
  });

  test('setEngineKind round-trips through the box', () async {
    await repo.setEngineKind(EngineKind.fake);
    expect(repo.engineKind(), EngineKind.fake);
    await repo.setEngineKind(EngineKind.openai);
    expect(repo.engineKind(), EngineKind.openai);
  });

  test('engineKind falls back to the default for an unknown stored value',
      () async {
    // Simulate a future rename / corrupted setting by writing through Hive.
    final box = await Hive.openBox<String>('test_app_settings');
    await box.put(AppSettingsRepository.keyEngineKind, 'not_a_kind');
    expect(repo.engineKind(), AppSettingsRepository.defaultEngineKind);
  });

  test('openaiModel defaults to gpt-4o-mini and round-trips', () async {
    expect(repo.openaiModel(), 'gpt-4o-mini');
    await repo.setOpenaiModel('gpt-4o');
    expect(repo.openaiModel(), 'gpt-4o');
  });

  test('defaultCefr defaults to a1 and round-trips', () async {
    expect(repo.defaultCefr(), CefrLevel.a1);
    await repo.setDefaultCefr(CefrLevel.b2);
    expect(repo.defaultCefr(), CefrLevel.b2);
  });

  test('defaultCefr falls back to default for an unknown stored value',
      () async {
    final box = await Hive.openBox<String>('test_app_settings');
    await box.put(AppSettingsRepository.keyDefaultCefr, 'z9');
    expect(repo.defaultCefr(), AppSettingsRepository.defaultCefrLevel);
  });

  test('defaultTopic defaults to empty and round-trips', () async {
    expect(repo.defaultTopicValue(), '');
    await repo.setDefaultTopic('Daily routine');
    expect(repo.defaultTopicValue(), 'Daily routine');
  });
}
