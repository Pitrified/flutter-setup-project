import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';

/// Welcome screen shown at app launch.
///
/// Displays runtime status and a button to start a conversation.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('fala')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to fala',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16),
            const Text('Your Portuguese tutor'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.conversation),
              child: const Text('Start Conversation'),
            ),
          ],
        ),
      ),
    );
  }
}
