import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../providers/app_provider.dart';
import '../../services/app/app_controller.dart';

/// Welcome screen - app entry point.
///
/// Displays app name, status indicator, and start button.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appController = ref.watch(appControllerProvider);
    final state = appController.state;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'fala',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Learn Portuguese by speaking',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 48),
                _buildStatusWidget(context, state),
                const SizedBox(height: 32),
                if (state is AppReady)
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.conversation),
                    child: const Text('Start Conversation'),
                  ),
                if (state is AppLoading) const CircularProgressIndicator(),
                if (state is AppError)
                  Column(
                    children: [
                      Text(
                        state.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => appController.initialize(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget(BuildContext context, AppState state) {
    return switch (state) {
      AppLoading() => const Text('Loading...'),
      AppReady(:final modelInfo) => Text(
          'Model: ${modelInfo.name}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      AppNeedsModel() => const Text('Model required'),
      AppError() => const SizedBox.shrink(),
    };
  }
}
