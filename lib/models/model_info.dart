import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_info.freezed.dart';
part 'model_info.g.dart';

/// Metadata for a downloaded LLM model file.
@freezed
abstract class ModelInfo with _$ModelInfo {
  const factory ModelInfo({
    required String name,
    required String filePath,
    required int fileSizeBytes,
    required DateTime downloadedAt,
    String? version,
    String? checksum,
  }) = _ModelInfo;

  factory ModelInfo.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoFromJson(json);
}
