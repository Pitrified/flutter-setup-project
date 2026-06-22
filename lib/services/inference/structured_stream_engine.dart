import 'dart:async';
import 'dart:convert';

import 'inference_engine.dart';
import 'partial_json_parser.dart';
import 'structured_output_parser.dart';

/// Which terminal failure a [StructuredDelta] carries.
enum StructuredFailureKind {
  /// The engine could not generate (mirrors `StructuredInferenceFailure`).
  inference,

  /// The engine produced text but the final strict parse to T failed
  /// (mirrors `StructuredParseFailure`).
  parse,
}

/// Terminal failure carried by a [StructuredDelta].
///
/// Mirrors the one-shot `StructuredResult<T>` failure split so the streaming
/// and one-shot vocabularies match.
class StructuredFailure {
  /// The engine could not generate a response.
  const StructuredFailure.inference(this.error)
      : kind = StructuredFailureKind.inference,
        rawText = null;

  /// The engine produced [rawText] but it could not be parsed to T.
  const StructuredFailure.parse({required this.rawText, required this.error})
      : kind = StructuredFailureKind.parse;

  final StructuredFailureKind kind;

  /// Human-readable description of the failure.
  final String error;

  /// The raw text that failed to parse, for [StructuredFailureKind.parse].
  final String? rawText;
}

/// One emission from [StructuredStreamEngine.generateStream] (G1 transport).
///
/// Carries a best-effort partial map at every tick plus the phase-1
/// closed-flags, and a fully-typed [value] only on the terminal success
/// emission. No per-schema partial class is minted: widgets read [partial] by
/// path while in-flight and switch to [value] once [isComplete].
class StructuredDelta<T> {
  const StructuredDelta({
    required this.partial,
    required this.closure,
    this.value,
    this.isComplete = false,
    this.failure,
  });

  /// Best-effort decoded object so far (any depth, nullable/partial leaves).
  final Map<String, dynamic> partial;

  /// Per-node closed-flags mirroring [partial] (see [JsonClosure]). Lets a
  /// consumer tell when an array stopped growing and when a leaf is final.
  final JsonClosure closure;

  /// The validated domain object. Non-null only on the terminal success
  /// emission, where [isComplete] is also true.
  final T? value;

  /// True on the terminal success emission (where [value] is materialized).
  final bool isComplete;

  /// Set on a terminal failure emission; null otherwise.
  final StructuredFailure? failure;

  /// Whether this is the stream's last emission (success or failure).
  bool get isTerminal => isComplete || failure != null;
}

/// Streaming, generic sibling of `StructuredInferenceEngine<T>`.
///
/// Maps an engine's cumulative raw-text stream (phase 2) through the tolerant
/// [PartialJsonParser] (phase 1) and yields `Stream<StructuredDelta<T>>`: a
/// best-effort partial map each tick, then a typed [T] materialized via
/// [fromJson] only at completion (G1). It references no domain type.
///
/// The one-shot `StructuredInferenceEngine<T>` stays the path for the persisted
/// final message; this is the parallel live path for the in-flight turn.
class StructuredStreamEngine<T> {
  StructuredStreamEngine({
    required this.engine,
    required this.fromJson,
    this.parser = const PartialJsonParser(),
    this.timeout = const Duration(seconds: 30),
  });

  /// The underlying raw-text streaming engine.
  final InferenceEngine engine;

  /// Factory used for the strict final parse - the same one the one-shot path
  /// uses, so the terminal [StructuredDelta.value] is equivalent to the
  /// one-shot result for the same input.
  final T Function(Map<String, dynamic>) fromJson;

  /// Tolerant partial parser applied to each cumulative buffer.
  final PartialJsonParser parser;

  /// Maximum time to wait between stream events before failing.
  final Duration timeout;

  /// Stream typed partial deltas for [request].
  ///
  /// Emits non-terminal deltas (growing [StructuredDelta.partial], `value ==
  /// null`) as the buffer fills, coalescing ticks whose partial map and
  /// closed-flags are structurally unchanged. The final emission is either a
  /// success delta (typed [StructuredDelta.value], `isComplete`) or a failure
  /// delta. Failures (inference error, malformed final JSON, or a stall longer
  /// than [timeout] between events) surface as a terminal
  /// [StructuredDelta.failure].
  Stream<StructuredDelta<T>> generateStream(InferenceRequest request) {
    final finalParser = StructuredOutputParser<T>(fromJson: fromJson);
    final controller = StreamController<StructuredDelta<T>>();

    var lastPartial = const <String, dynamic>{};
    var lastClosure = const JsonClosure.open();
    var lastBuffer = '';
    String? lastSignature;

    StreamSubscription<String>? sub;
    Timer? timer;

    void emitFailure(StructuredFailure failure) {
      if (controller.isClosed) return;
      controller
        ..add(
          StructuredDelta<T>(
            partial: lastPartial,
            closure: lastClosure,
            failure: failure,
          ),
        )
        ..close();
    }

    // Inactivity timeout: a stall longer than [timeout] between events. A
    // manual timer is used because Stream.timeout pauses its timer while an
    // async* source is suspended, so it would not detect a real stall. Closing
    // the controller triggers onCancel, which cancels the upstream
    // subscription.
    void resetTimer() {
      timer?.cancel();
      timer = Timer(timeout, () {
        emitFailure(const StructuredFailure.inference('Response timed out'));
      });
    }

    controller.onListen = () {
      resetTimer();
      sub = engine.generateStream(request).listen(
        (buffer) {
          // Already terminated (e.g. a timeout closed us): drop late buffered
          // events before re-arming the timer, so no dangling timer outlives
          // the stream.
          if (controller.isClosed) return;
          resetTimer();
          lastBuffer = buffer;
          final result = parser.parse(buffer);
          lastPartial = result.value;
          lastClosure = result.closure;

          // Coalesce: skip ticks whose map *and* closed-flags are unchanged
          // (e.g. trailing whitespace), to limit downstream rebuilds.
          final signature = _signature(result);
          if (signature == lastSignature) return;
          lastSignature = signature;

          if (!controller.isClosed) {
            controller.add(
              StructuredDelta<T>(partial: lastPartial, closure: lastClosure),
            );
          }
        },
        onError: (Object error) {
          timer?.cancel();
          final message =
              error is InferenceStreamException ? error.message : '$error';
          emitFailure(StructuredFailure.inference(message));
        },
        onDone: () {
          timer?.cancel();
          if (controller.isClosed) return;
          // Strict final parse on the full buffer, matching the one-shot path.
          switch (finalParser.parse(lastBuffer)) {
            case ParseSuccess(:final value):
              controller
                ..add(
                  StructuredDelta<T>(
                    partial: lastPartial,
                    closure: lastClosure,
                    value: value,
                    isComplete: true,
                  ),
                )
                ..close();
            case ParseFailure(:final rawText, :final error):
              emitFailure(
                StructuredFailure.parse(rawText: rawText, error: error),
              );
          }
        },
      );
    };

    controller.onCancel = () {
      timer?.cancel();
      // Fire-and-forget: cancelling an engine stream that is stalled on an
      // await returns a future that may never complete, which would block the
      // controller's done event. We do not need to wait for the cleanup.
      //
      // Consequence: the engine's own `finally { status = ready }` only runs
      // when that abandoned async* actually unwinds, so on a stall the engine
      // status can read `generating` a while after this stream already failed.
      // That cosmetic lag is intentional - awaiting the cancel here to fix it
      // would reintroduce the hang above.
      final cancelled = sub?.cancel();
      if (cancelled != null) unawaited(cancelled);
    };

    return controller.stream;
  }

  /// Delegates initialization to the underlying engine.
  Future<void> initialize() => engine.initialize();

  /// Delegates disposal to the underlying engine.
  Future<void> dispose() => engine.dispose();

  /// Whether the underlying engine is ready to accept requests.
  bool get isReady => engine.isReady;

  /// Structural signature of a parse result (value shape + closed-flags), used
  /// for cheap coalescing of no-op ticks.
  String _signature(PartialJsonResult result) =>
      jsonEncode([result.value, _closureToJson(result.closure)]);

  static Object _closureToJson(JsonClosure c) => <String, Object>{
        'c': c.closed,
        if (c.fields.isNotEmpty)
          'f': c.fields.map((k, v) => MapEntry(k, _closureToJson(v))),
        if (c.elements.isNotEmpty)
          'e': c.elements.map(_closureToJson).toList(),
      };
}
