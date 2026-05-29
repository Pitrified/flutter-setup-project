/// Configuration for the LLM model to download.
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

  /// Default file name for use as const default parameter values.
  static const defaultModelFileName = 'Qwen3-0.6B.litertlm';

  /// Default model (Qwen3 0.6B via LiteRT-LM, Apache 2.0, ungated).
  static const defaultModel = ModelConfig(
    downloadUrl:
        'https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/Qwen3-0.6B.litertlm',
    fileName: defaultModelFileName,
    fileSizeBytes: 614000000,
  );
}
