import 'package:fala/services/settings/api_key_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('read returns null when nothing is stored', () async {
    final store = ApiKeyStore();
    expect(await store.read(), isNull);
    expect(await store.hasKey(), isFalse);
  });

  test('write persists the key, read returns it', () async {
    final store = ApiKeyStore();
    await store.write('sk-test');
    expect(await store.read(), 'sk-test');
    expect(await store.hasKey(), isTrue);
  });

  test('write with empty string clears the key', () async {
    final store = ApiKeyStore();
    await store.write('sk-test');
    await store.write('');
    expect(await store.read(), isNull);
    expect(await store.hasKey(), isFalse);
  });

  test('clear removes the key', () async {
    final store = ApiKeyStore();
    await store.write('sk-test');
    await store.clear();
    expect(await store.read(), isNull);
  });
}
