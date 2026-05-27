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

  /// Default model (Gemma 3 1B quantized).
  static const defaultModel = ModelConfig(
    downloadUrl:
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/model.task',
    fileName: 'gemma3-1b-it.task',
    fileSizeBytes: 1500000000,
  );
}
