import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/app_provider.dart';
import 'screens/conversation/conversation_screen.dart';
import 'screens/model_download/model_download_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'services/app/app_controller.dart';

/// Route path constants.
abstract final class AppRoutes {
  static const welcome = '/';
  static const conversation = '/conversation';
  static const modelDownload = '/model-download';
}

/// App-level GoRouter configuration.
///
/// Uses manual Provider (not @riverpod) because GoRouter setup is declarative
/// configuration, not async/stateful logic. This is a common Flutter pattern.
final routerProvider = Provider<GoRouter>((ref) {
  final appController = ref.watch(appControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.welcome,
    redirect: (context, state) {
      final appState = appController.state;
      final location = state.matchedLocation;

      // Redirect to model download if model is needed
      if (appState is AppNeedsModel && location != AppRoutes.modelDownload) {
        return AppRoutes.modelDownload;
      }

      // Prevent accessing conversation if not ready
      if (location == AppRoutes.conversation && appState is! AppReady) {
        return AppRoutes.welcome;
      }

      // Redirect away from model download if model is available
      if (location == AppRoutes.modelDownload && appState is AppReady) {
        return AppRoutes.welcome;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.conversation,
        builder: (context, state) => const ConversationScreen(),
      ),
      GoRoute(
        path: AppRoutes.modelDownload,
        builder: (context, state) => const ModelDownloadScreen(),
      ),
    ],
  );
});

/// Root application widget.
class FalaApp extends ConsumerWidget {
  const FalaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'fala',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
