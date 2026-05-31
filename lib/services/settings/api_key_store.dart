import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage wrapper for the OpenAI API key.
///
/// Android-only; backed by `EncryptedSharedPreferences` on top of Android
/// Keystore. No plaintext on disk. The key is never logged.
///
/// Activated by plan 03.2 when the OpenAI engine ships; the wrapper exists in
/// 03.1 so the Settings screen and engine wiring already have a stable seam
/// to depend on.
class ApiKeyStore {
  ApiKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Storage key under which the OpenAI API key is stored.
  static const String openaiKeyName = 'openai_api_key';

  final FlutterSecureStorage _storage;

  /// Returns the stored OpenAI key, or `null` when none is set.
  Future<String?> read() => _storage.read(key: openaiKeyName);

  /// Persist [key] as the OpenAI API key. An empty string is treated as
  /// "clear" so the Settings UI can offer a single Save action.
  Future<void> write(String key) async {
    if (key.isEmpty) {
      await clear();
      return;
    }
    await _storage.write(key: openaiKeyName, value: key);
  }

  /// Remove the stored OpenAI key.
  Future<void> clear() => _storage.delete(key: openaiKeyName);

  /// Whether a non-empty key is currently stored.
  Future<bool> hasKey() async {
    final value = await read();
    return value != null && value.isNotEmpty;
  }
}
