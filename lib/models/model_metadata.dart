import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_metadata.freezed.dart';
part 'model_metadata.g.dart';

/// Metadata for a downloaded LLM model file.
@freezed
abstract class ModelMetadata with _$ModelMetadata {
  const factory ModelMetadata({
    required String name,
    required String filePath,
    required int fileSizeBytes,
    required DateTime downloadedAt,
    String? version,
    String? checksum,
  }) = _ModelMetadata;

  factory ModelMetadata.fromJson(Map<String, dynamic> json) =>
      _$ModelMetadataFromJson(json);
}
