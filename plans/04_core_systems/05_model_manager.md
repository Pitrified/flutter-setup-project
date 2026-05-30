---
status: complete
depends_on: [03_scaffold/00_create_project.md]
produces: [lib/services/model/model_manager.dart]
---

# Plan: Model Manager

## Goal

Handle model detection, download-on-first-launch, progress tracking, integrity
verification, and storage location management. The app needs internet only once
(first launch) to download the model, then works fully offline.

## Implementation

`lib/services/model/model_manager.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../models/model_metadata.dart';

/// Status of a model download operation.
sealed class DownloadStatus {
  const DownloadStatus();
}

class DownloadNotStarted extends DownloadStatus {
  const DownloadNotStarted();
}

class DownloadInProgress extends DownloadStatus {
  const DownloadInProgress({required this.progress, required this.bytesReceived});
  final double progress; // 0.0 to 1.0
  final int bytesReceived;
}

class DownloadComplete extends DownloadStatus {
  const DownloadComplete({required this.modelInfo});
  final ModelMetadata modelInfo;
}

class DownloadFailed extends DownloadStatus {
  const DownloadFailed({required this.error});
  final String error;
}

/// Manages model files on device storage.
///
/// Responsibilities:
/// - Check if a model is already downloaded
/// - Download model from a URL with progress reporting
/// - Verify model integrity (checksum)
/// - Provide the model file path to InferenceEngine
/// - Delete cached models
class ModelManager {
  ModelManager({this.modelDirName = 'models'});

  final String modelDirName;
  final _downloadStatusController = StreamController<DownloadStatus>.broadcast();

  Stream<DownloadStatus> get downloadStatusStream =>
      _downloadStatusController.stream;

  /// Get the directory where models are stored.
  Future<Directory> get modelDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$modelDirName');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Check if a model file exists and return its info.
  Future<ModelMetadata?> getDownloadedModel(String modelName) async {
    final dir = await modelDirectory;
    final file = File('${dir.path}/$modelName');
    if (!file.existsSync()) return null;

    final stat = await file.stat();
    return ModelMetadata(
      name: modelName,
      filePath: file.path,
      fileSizeBytes: stat.size,
      downloadedAt: stat.modified,
    );
  }

  /// Download a model file from the given URL.
  ///
  /// Reports progress via [downloadStatusStream].
  /// Returns the ModelMetadata on success, or throws on failure.
  Future<ModelMetadata> downloadModel({
    required String url,
    required String fileName,
    String? expectedChecksum,
  }) async {
    _downloadStatusController.add(const DownloadNotStarted());

    final dir = await modelDirectory;
    final targetFile = File('${dir.path}/$fileName');

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw HttpException(
          'Download failed with status ${response.statusCode}',
        );
      }

      final totalBytes = response.contentLength;
      var receivedBytes = 0;
      final sink = targetFile.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        final progress = totalBytes > 0 ? receivedBytes / totalBytes : 0.0;
        _downloadStatusController.add(DownloadInProgress(
          progress: progress,
          bytesReceived: receivedBytes,
        ));
      }

      await sink.close();
      client.close();

      // TODO: Verify checksum if provided

      final info = ModelMetadata(
        name: fileName,
        filePath: targetFile.path,
        fileSizeBytes: receivedBytes,
        downloadedAt: DateTime.now(),
        checksum: expectedChecksum,
      );

      _downloadStatusController.add(DownloadComplete(modelInfo: info));
      return info;
    } on Exception catch (e) {
      _downloadStatusController.add(DownloadFailed(error: e.toString()));
      // Clean up partial download
      if (targetFile.existsSync()) {
        await targetFile.delete();
      }
      rethrow;
    }
  }

  /// Delete a downloaded model file.
  Future<void> deleteModel(String modelName) async {
    final dir = await modelDirectory;
    final file = File('${dir.path}/$modelName');
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Dispose resources.
  Future<void> dispose() async {
    await _downloadStatusController.close();
  }
}
```

## Model source configuration

```dart
// lib/config/model_config.dart
class ModelConfig {
  const ModelConfig({
    required this.downloadUrl,
    required this.fileName,
    this.expectedChecksum,
    this.fileSizeBytes,
  });

  final String downloadUrl;
  final String fileName;
  final String? expectedChecksum;
  final int? fileSizeBytes;

  // Default model (Gemma 3 1B quantized)
  static const defaultModel = ModelConfig(
    downloadUrl: 'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/model.task',
    fileName: 'gemma3-1b-it.task',
    fileSizeBytes: 1500000000, // ~1.5 GB
  );
}
```

## Provider

```dart
// lib/providers/model_provider.dart
final modelManagerProvider = Provider<ModelManager>((ref) {
  return ModelManager();
});
```

## Tests

- `getDownloadedModel` returns null when no model exists
- `getDownloadedModel` returns ModelMetadata when file exists
- `deleteModel` removes the file
- Download progress is reported correctly (mock HTTP)
- Partial download cleanup on failure

## Acceptance criteria

- [ ] ModelManager detects existing model files
- [ ] Download with progress reporting works
- [ ] Partial downloads are cleaned up on failure
- [ ] Model directory is in app-specific storage (not accessible externally)
- [ ] DownloadStatus sealed class enables UI progress display
- [ ] `flutter analyze` passes
