import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../config/model_config.dart';
import '../../providers/app_provider.dart';

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
  int _progress = 0;
  String? _error;
  bool _complete = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    setState(() {
      _progress = 0;
      _error = null;
      _complete = false;
    });
    try {
      await FlutterGemma.installModel(
        modelType: ModelType.qwen3,
        fileType: ModelFileType.litertlm,
      )
          .fromNetwork(ModelConfig.defaultModel.downloadUrl)
          .withProgress((progress) {
        if (mounted) setState(() => _progress = progress);
      }).install();
      if (mounted) {
        setState(() => _complete = true);
        final appController = ref.read(appControllerProvider);
        await appController.onModelDownloaded();
        if (mounted) {
          context.go(AppRoutes.welcome);
        }
      }
    } on Exception catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(_error!),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _startDownload,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (_complete) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 48, color: Colors.green),
          SizedBox(height: 16),
          Text('Model ready!'),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LinearProgressIndicator(value: _progress / 100),
        const SizedBox(height: 16),
        Text('$_progress% downloaded'),
      ],
    );
  }
}
