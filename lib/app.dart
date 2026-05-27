import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/conversation/conversation_screen.dart';
import 'screens/model_download/model_download_screen.dart';
import 'screens/welcome/welcome_screen.dart';

/// Route path constants.
abstract final class AppRoutes {
  static const welcome = '/';
  static const conversation = '/conversation';
  static const modelDownload = '/model-download';
}

/// App-level GoRouter configuration.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.welcome,
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
