import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_provider.dart';
import '../../providers/service_providers.dart';
import '../../services/model/model_manager.dart';

/// Model download screen - shown when model is not yet on device.
///
/// Displays download progress, completion state, and retry on failure.
class ModelDownloadScreen extends ConsumerStatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  ConsumerState<ModelDownloadScreen> createState() =>
      _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends ConsumerState<ModelDownloadScreen> {
  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    final modelManager = ref.read(modelManagerProvider);
    try {
      await modelManager.downloadModel(
        url: 'https://placeholder.example.com/gemma3-1b-it.task',
        fileName: 'gemma3-1b-it.task',
      );
      if (mounted) {
        final appController = ref.read(appControllerProvider);
        await appController.onModelDownloaded();
      }
    } on Exception {
      // Error state handled via stream
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelManager = ref.watch(modelManagerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: StreamBuilder<DownloadStatus>(
              stream: modelManager.downloadStatusStream,
              initialData: const DownloadNotStarted(),
              builder: (context, snapshot) {
                final status = snapshot.data ?? const DownloadNotStarted();
                return _buildContent(context, status);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DownloadStatus status) {
    return switch (status) {
      DownloadNotStarted() => const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparing download...'),
          ],
        ),
      DownloadInProgress(:final progress) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 16),
            Text('${(progress * 100).toStringAsFixed(0)}% downloaded'),
          ],
        ),
      DownloadComplete() => const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.green),
            SizedBox(height: 16),
            Text('Model ready!'),
          ],
        ),
      DownloadFailed(:final error) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(error),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _startDownload,
              child: const Text('Retry'),
            ),
          ],
        ),
    };
  }
}
