import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Conversation screen - main chat interface.
///
/// Placeholder until Phase 05 wires up the full conversation loop.
class ConversationScreen extends ConsumerWidget {
  const ConversationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversation')),
      body: const Center(
        child: Text('Conversation screen (placeholder)'),
      ),
    );
  }
}
