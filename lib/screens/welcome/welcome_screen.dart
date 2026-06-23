import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../config/model_config.dart';
import '../../providers/app_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/app/app_controller.dart';
import '../../services/inference/engine_kind.dart';

/// Welcome screen - app entry point.
///
/// Displays app name, status indicator, and start button.
/// Triggers app initialization on first build.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _triggerInit();
  }

  Future<void> _triggerInit() async {
    if (_initialized) return;
    _initialized = true;
    final appController = ref.read(appControllerProvider);
    await appController.initialize();
    if (mounted) {
      if (appController.state is AppNeedsModel) {
        context.go(AppRoutes.modelDownload);
      } else {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appController = ref.watch(appControllerProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: StreamBuilder<AppState>(
              stream: appController.stateStream,
              initialData: appController.state,
              builder: (context, snapshot) {
                final state = snapshot.data ?? const AppLoading();
                return Column(
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
                    if (state is AppLoading)
                      const CircularProgressIndicator(),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget(BuildContext context, AppState state) {
    return switch (state) {
      AppLoading() => const Text('Loading...'),
      AppReady() => Text(
          'Model: ${_modelLabel()}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      AppNeedsModel() => const Text('Model required'),
      AppError() => const SizedBox.shrink(),
    };
  }

  /// Label for the active engine's model, derived from the selected engine
  /// kind. Reading it here (rather than from `AppReady.modelInfo`) keeps it
  /// reactive to an OpenAI-model change, which does not re-init the controller.
  String _modelLabel() {
    final kind = ref.watch(selectedEngineKindProvider);
    return switch (kind) {
      EngineKind.openai => ref.watch(openaiModelProvider),
      EngineKind.gemma => ModelConfig.defaultModelFileName,
      EngineKind.fake => EngineKind.fake.displayName,
    };
  }
}
