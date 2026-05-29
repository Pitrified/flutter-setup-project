import 'package:flutter/services.dart';
/// Manages versioned prompt templates from app assets.
///
/// Prompts are stored as plain text files in `assets/prompts/{name}/vN.txt`.
/// The manager loads the highest-numbered version and substitutes variables.
class PromptManager {
  PromptManager();

  final Map<String, String> _cache = {};

  /// Load a prompt template by name, using the specified version.
  ///
  /// If [version] is null, loads the highest available version.
  /// Templates use {{variable}} syntax for substitution.
  Future<String> loadTemplate({
    required String name,
    int? version,
  }) async {
    final key = '$name/v${version ?? "latest"}';
    if (_cache.containsKey(key)) return _cache[key]!;

    final assetPath = version != null
        ? 'assets/prompts/$name/v$version.txt'
        : await _findLatestVersion(name);

    final content = await rootBundle.loadString(assetPath);
    _cache[key] = content;
    return content;
  }

  /// Build a prompt by loading template and substituting variables.
  ///
  /// Variables in the template like {{user_message}} are replaced with
  /// the corresponding values from [variables].
  Future<String> buildPrompt({
    required String name,
    required Map<String, String> variables,
    int? version,
  }) async {
    var template = await loadTemplate(name: name, version: version);

    for (final entry in variables.entries) {
      template = template.replaceAll('{{${entry.key}}}', entry.value);
    }

    return template;
  }

  /// Find the highest version number for a prompt template.
  Future<String> _findLatestVersion(String name) async {
    // Try versions starting from a reasonable max
    for (var v = 10; v >= 1; v--) {
      final path = 'assets/prompts/$name/v$v.txt';
      try {
        await rootBundle.loadString(path);
        return path;
      } on Object {
        continue;
      }
    }

    throw StateError('No prompt template found for "$name"');
  }

  /// Clear the template cache.
  void clearCache() => _cache.clear();
}
