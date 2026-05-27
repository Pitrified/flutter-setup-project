---
status: not-started
depends_on: [03_scaffold/02_generated_models.md]
produces: [lib/app.dart, lib/main.dart, lib/providers/, lib/screens/welcome/, lib/screens/conversation/]
---

# Plan: Routing and Providers

## Goal

Wire GoRouter with initial routes, bootstrap Riverpod, and create placeholder screens.
After this step the app launches, shows the Welcome screen, and can navigate to
the Conversation screen. State flows through providers, not direct service access.

## Steps

### 1. Configure main.dart entry point

`lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: FalaApp(),
    ),
  );
}
```

### 2. Create app widget with GoRouter

`lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/welcome/welcome_screen.dart';
import 'screens/conversation/conversation_screen.dart';
import 'screens/model_download/model_download_screen.dart';

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
```

### 3. Create Welcome screen (placeholder)

`lib/screens/welcome/welcome_screen.dart`:

```dart
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
```

### 4. Create Conversation screen (placeholder)

`lib/screens/conversation/conversation_screen.dart`:

```dart
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
```

### 5. Create Model Download screen (placeholder)

`lib/screens/model_download/model_download_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model download screen - shown on first launch.
///
/// Placeholder until Phase 04 implements the model manager.
class ModelDownloadScreen extends ConsumerWidget {
  const ModelDownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download Model')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Downloading model... (placeholder)'),
          ],
        ),
      ),
    );
  }
}
```

### 6. Create initial providers

`lib/providers/app_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder for app-level providers.
///
/// Real providers (inference engine, conversation state, model manager)
/// will be added in Phase 04 and 05.

/// Whether the app has completed initialization.
final appInitializedProvider = StateProvider<bool>((ref) => false);
```

### 7. Validate

```bash
flutter analyze          # no lint errors
flutter run              # app launches, shows Welcome screen
# Tap "Start Conversation" -> navigates to Conversation screen
flutter test             # compiles (no test failures)
```

## Key decisions

- GoRouter uses declarative routes (not imperative Navigator.push)
- Route paths defined as constants in `AppRoutes` (prevents typos)
- All screens are `ConsumerWidget` (ready for Riverpod state access)
- No business logic in screens - just UI and provider reads
- MaterialApp.router used (not MaterialApp) for GoRouter integration
- Theme uses Material 3 with a teal seed color (can be refined later)

## Acceptance criteria

- [ ] App launches on emulator showing Welcome screen
- [ ] "Start Conversation" button navigates to Conversation screen
- [ ] Back navigation works (system back button)
- [ ] All screens use ConsumerWidget pattern
- [ ] No direct service imports in screen files
- [ ] `flutter analyze` passes
- [ ] Route constants are centralized in AppRoutes
