import 'package:freezed_annotation/freezed_annotation.dart';

part 'inference_status.freezed.dart';

/// Current status of the inference engine.
@freezed
sealed class InferenceStatus with _$InferenceStatus {
  const factory InferenceStatus.uninitialized() = InferenceStatusUninitialized;
  const factory InferenceStatus.loading() = InferenceStatusLoading;
  const factory InferenceStatus.ready() = InferenceStatusReady;
  const factory InferenceStatus.generating() = InferenceStatusGenerating;
  const factory InferenceStatus.error(String message) = InferenceStatusError;
  const factory InferenceStatus.disposed() = InferenceStatusDisposed;
}
