import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';
import '../../services/inference/engine_kind.dart';

/// Settings screen.
///
/// Engine selector is live. The OpenAI section is a greyed-out placeholder
/// until plan 03.2 lands - the dropdown shows the OpenAI option but does
/// not let the user pick it.
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
            'OpenAI',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const _OpenAiPlaceholder(),
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
      child: Row(
        children: [
          Text(kind.displayName),
          if (!kind.isImplemented) ...[
            const SizedBox(width: 8),
            const Tooltip(
              message: 'Coming soon',
              child: Text(
                '(coming soon)',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OpenAiPlaceholder extends StatelessWidget {
  const _OpenAiPlaceholder();

  @override
  Widget build(BuildContext context) {
    final disabledColor = Theme.of(context).disabledColor;
    return Opacity(
      opacity: 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API key and model selection arrive in the next release.',
            style: TextStyle(color: disabledColor),
          ),
          const SizedBox(height: 8),
          TextField(
            enabled: false,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'OpenAI API key',
              hintText: 'Coming soon',
              suffixIcon: Tooltip(
                message: 'Coming soon',
                child: Icon(Icons.lock_outline, color: disabledColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
