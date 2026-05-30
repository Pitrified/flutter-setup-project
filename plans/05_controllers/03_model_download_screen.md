---
status: complete
depends_on: [05_controllers/01_app_controller.md, 04_core_systems/05_model_manager.md]
produces: [lib/screens/model_download/model_download_screen.dart]
---

# Plan: Model Download Screen

## Goal

Show download progress, handle errors with retry, and transition to welcome
screen once the model is available.

## Implementation

`lib/screens/model_download/model_download_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/model_config.dart';
import '../../providers/app_provider.dart';
import '../../providers/service_providers.dart';
import '../../services/model/model_manager.dart';

/// Model download screen - shown when model is not yet available.
///
/// Displays download progress, file size info, and handles errors with retry.
class ModelDownloadScreen extends ConsumerStatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  ConsumerState<ModelDownloadScreen> createState() =>
      _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends ConsumerState<ModelDownloadScreen> {
  DownloadStatus _status = const DownloadNotStarted();
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    final manager = ref.read(modelManagerProvider);
    manager.downloadStatusStream.listen((status) {
      if (mounted) setState(() => _status = status);
      if (status is DownloadComplete) {
        _onDownloadComplete();
      }
    });
  }

  Future<void> _startDownload() async {
    setState(() => _downloading = true);
    final manager = ref.read(modelManagerProvider);
    try {
      await manager.downloadModel(
        url: ModelConfig.defaultModel.downloadUrl,
        fileName: ModelConfig.defaultModel.fileName,
      );
    } on Exception {
      // Status stream handles UI update via DownloadFailed
    }
  }

  Future<void> _onDownloadComplete() async {
    final appController = ref.read(appControllerProvider);
    await appController.onModelDownloaded();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download Model')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download_rounded, size: 64),
            const SizedBox(height: 24),
            Text(
              'Language model required',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Download size: ~${(ModelConfig.defaultModel.fileSizeBytes ?? 0) ~/ 1000000} MB',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            _buildProgressWidget(),
            const SizedBox(height: 24),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressWidget() {
    return switch (_status) {
      DownloadNotStarted() => const SizedBox.shrink(),
      DownloadInProgress(:final progress, :final bytesReceived) => Column(
          children: [
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text('${(bytesReceived / 1000000).toStringAsFixed(1)} MB'),
          ],
        ),
      DownloadComplete() => const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Download complete'),
          ],
        ),
      DownloadFailed(:final error) => Text(
          'Download failed: $error',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
    };
  }

  Widget _buildActionButton() {
    if (_status is DownloadFailed || !_downloading) {
      return FilledButton(
        onPressed: _startDownload,
        child: Text(_status is DownloadFailed ? 'Retry' : 'Download'),
      );
    }
    if (_status is DownloadInProgress) {
      return const Text('Downloading...');
    }
    return const SizedBox.shrink();
  }
}
```

## Acceptance criteria

- [ ] Shows download size and start button
- [ ] Progress bar updates during download
- [ ] Error state shows retry button
- [ ] Navigates to welcome after successful download + engine init
- [ ] No direct service imports except through providers
- [ ] `flutter analyze` passes
