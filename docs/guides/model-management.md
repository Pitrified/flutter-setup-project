# Model management guide

How model files are downloaded, stored, verified, and used at runtime.

---

## Storage location

Models are stored under `getApplicationDocumentsDirectory()/models/`. The
directory is created on first access.

```
/data/data/com.fala.app/app_flutter/models/
  Qwen3-0.6B.litertlm
```

## Model configuration

`lib/config/model_config.dart` defines available models:

```dart
static const defaultModel = ModelConfig(
  downloadUrl: 'https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/Qwen3-0.6B.litertlm',
  fileName: 'Qwen3-0.6B.litertlm',
  fileSizeBytes: 614000000,
);
```

## Download flow

1. `AppController.initialize()` calls `modelChecker()` (delegates to `FlutterGemma.isModelInstalled`).
2. If model not found, state transitions to `AppNeedsModel` and download screen shown.
3. `ModelManager.downloadModel(url:, fileName:)` performs the HTTP download.
4. Progress reported via `downloadStatusStream` (0.0 to 1.0).
5. On success, `AppController.onModelDownloaded()` retries initialization.

## Checking availability

Two mechanisms exist depending on context:

| Context | Method |
|---------|--------|
| App startup | `FlutterGemma.isModelInstalled(fileName)` via `appControllerProvider` |
| Manual check | `ModelManager.getDownloadedModel(name)` returns `ModelMetadata?` |

## FlutterGemma install flow

`FlutterGemmaEngine.initialize()` uses the plugin's install API:

```dart
await FlutterGemma.installModel(
  modelType: ModelType.qwen3,
  fileType: ModelFileType.litertlm,
).fromNetwork(ModelConfig.defaultModel.downloadUrl).install();
```

This is idempotent - skips download if already installed.

## Error handling

- Download failure: partial file deleted, `DownloadFailed` status emitted, `ModelException` thrown.
- Init timeout: `AppController` enforces a 10-second timeout on `engine.initialize()`.
- HTTP errors: non-200 status codes throw `HttpException`.

## Cleanup

```dart
final manager = ref.read(modelManagerProvider);
await manager.deleteModel('Qwen3-0.6B.litertlm');
```

## Size considerations

- Model file: ~600 MB (quantized)
- APK: <30 MB (model downloaded separately)
- Minimum device storage recommended: 2 GB free
