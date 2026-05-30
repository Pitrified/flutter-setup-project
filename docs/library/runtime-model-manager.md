# RuntimeModelManager

> System spec for `lib/services/model/model_manager.dart`

## Purpose

Manages LLM model files on device storage. Handles checking for existing
downloads, downloading with progress reporting, cleanup of partial downloads,
and deletion of cached models.

## Constructor parameters

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `modelDirName` | `String` | no | Subdirectory name in app documents (default `'models'`) |

## Public API

| Method | Signature | Description |
|--------|-----------|-------------|
| `downloadStatusStream` | `Stream<DownloadStatus>` | Broadcast stream of download progress |
| `modelDirectory` | `Future<Directory>` | Get/create the models directory |
| `getDownloadedModel(name)` | `Future<ModelMetadata?>` | Check if model exists, return metadata |
| `downloadModel(...)` | `Future<ModelMetadata>` | Download from URL with progress |
| `deleteModel(name)` | `Future<void>` | Remove a cached model file |
| `dispose()` | `Future<void>` | Close stream controller |

## Download status

`DownloadStatus` is a sealed class:

| Subtype | Fields | Meaning |
|---------|--------|---------|
| `DownloadNotStarted` | - | Initial state |
| `DownloadInProgress` | `progress: double`, `bytesReceived: int` | Actively downloading |
| `DownloadComplete` | `modelInfo: ModelMetadata` | File saved successfully |
| `DownloadFailed` | `error: String` | Download failed (partial file cleaned up) |

## downloadModel parameters

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `url` | `String` | yes | Remote URL to download from |
| `fileName` | `String` | yes | Local file name to save as |
| `expectedChecksum` | `String?` | no | SHA-256 for verification (not yet implemented) |

## Behavior details

- Uses `dart:io` `HttpClient` for downloads.
- Reports progress as `bytesReceived / contentLength` (0.0 to 1.0).
- On failure, deletes any partial file before throwing `ModelException`.
- Model directory is created recursively under `getApplicationDocumentsDirectory()`.
- Checksum verification is planned but not yet implemented.

## Dependencies

- `path_provider` package (app documents directory)
- `dart:io` (`HttpClient`, `File`, `Directory`)
- `ModelMetadata` model
- `AppException` (`ModelException` subclass)

## Provider

`modelManagerProvider` in `lib/providers/service_providers.dart`:

```dart
final modelManagerProvider = Provider<ModelManager>((ref) {
  return ModelManager();
});
```
