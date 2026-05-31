import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/cefr_level.dart';
import '../../providers/settings_provider.dart';
import '../../services/inference/engine_kind.dart';

/// Settings screen.
///
/// Lets the user pick the active inference engine and (for OpenAI) supply an
/// API key and model id.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedKind = ref.watch(selectedEngineKindProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Inference engine',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _EngineDropdown(selected: selectedKind),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Default CEFR level',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Used for new conversations. Change the active conversation '
            'from its chip in the app bar.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          const _CefrDropdown(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'OpenAI',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const _OpenAiSection(),
        ],
      ),
    );
  }
}

class _EngineDropdown extends ConsumerWidget {
  const _EngineDropdown({required this.selected});

  final EngineKind selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButtonFormField<EngineKind>(
      initialValue: selected,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Active engine',
      ),
      items: EngineKind.values.map(_buildItem).toList(),
      onChanged: (kind) async {
        if (kind == null || !kind.isImplemented) return;
        final messenger = ScaffoldMessenger.of(context);
        await ref.read(selectedEngineKindProvider.notifier).select(kind);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Engine set to ${kind.displayName}.'),
          ),
        );
      },
    );
  }

  DropdownMenuItem<EngineKind> _buildItem(EngineKind kind) {
    return DropdownMenuItem<EngineKind>(
      value: kind,
      enabled: kind.isImplemented,
      child: Text(kind.displayName),
    );
  }
}

class _CefrDropdown extends ConsumerWidget {
  const _CefrDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(defaultCefrLevelProvider);
    return DropdownButtonFormField<CefrLevel>(
      initialValue: current,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Default level',
      ),
      items: [
        for (final level in CefrLevel.values)
          DropdownMenuItem<CefrLevel>(
            value: level,
            child: Text('${level.displayName} - ${level.description}'),
          ),
      ],
      onChanged: (level) async {
        if (level == null) return;
        await ref.read(defaultCefrLevelProvider.notifier).select(level);
      },
    );
  }
}

class _OpenAiSection extends ConsumerStatefulWidget {
  const _OpenAiSection();

  @override
  ConsumerState<_OpenAiSection> createState() => _OpenAiSectionState();
}

class _OpenAiSectionState extends ConsumerState<_OpenAiSection> {
  final _keyController = TextEditingController();
  final _modelController = TextEditingController();
  bool _hasStoredKey = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _modelController.text = ref.read(openaiModelProvider);
    _refreshKeyStatus();
  }

  Future<void> _refreshKeyStatus() async {
    final store = ref.read(apiKeyStoreProvider);
    final has = await store.hasKey();
    if (!mounted) return;
    setState(() {
      _hasStoredKey = has;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final store = ref.read(apiKeyStoreProvider);
    final keyInput = _keyController.text.trim();
    if (keyInput.isNotEmpty) {
      await store.write(keyInput);
      _keyController.clear();
    }
    await ref.read(openaiModelProvider.notifier).setModel(_modelController.text);
    await _refreshKeyStatus();
    messenger.showSnackBar(
      const SnackBar(content: Text('OpenAI settings saved.')),
    );
  }

  Future<void> _clearKey() async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(apiKeyStoreProvider).clear();
    _keyController.clear();
    await _refreshKeyStatus();
    messenger.showSnackBar(
      const SnackBar(content: Text('OpenAI key cleared.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _keyController,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'OpenAI API key',
            hintText: _loaded && _hasStoredKey
                ? 'Key stored. Enter to replace.'
                : 'sk-...',
            helperText: _loaded && _hasStoredKey
                ? 'A key is currently stored.'
                : 'No key stored yet.',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _modelController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Model',
            hintText: 'gpt-4o-mini',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _hasStoredKey ? _clearKey : null,
              child: const Text('Clear key'),
            ),
          ],
        ),
      ],
    );
  }
}
