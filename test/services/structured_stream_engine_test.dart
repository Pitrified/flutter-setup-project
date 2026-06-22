import 'dart:async';
import 'dart:convert';

import 'package:fala/models/inference_status.dart';
import 'package:fala/models/tutor_response.dart';
import 'package:fala/services/inference/inference_engine.dart';
import 'package:fala/services/inference/partial_json_parser.dart';
import 'package:fala/services/inference/structured_output_parser.dart';
import 'package:fala/services/inference/structured_stream_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Engine that emits a scripted list of cumulative buffers, then optionally
/// stalls (to trigger the inactivity timeout) or throws.
class _ScriptedEngine implements InferenceEngine {
  _ScriptedEngine(this.buffers, {this.throwMessage, this.stall = false});

  final List<String> buffers;
  final String? throwMessage;
  final bool stall;

  @override
  InferenceStatus get status => const InferenceStatus.ready();
  @override
  bool get isReady => true;
  @override
  Stream<InferenceStatus> get statusStream => const Stream.empty();
  @override
  Future<void> initialize() async {}
  @override
  Future<InferenceResult> generate(InferenceRequest request) async =>
      const InferenceFailure(error: 'not used');

  @override
  Stream<String> generateStream(InferenceRequest request) async* {
    for (final buffer in buffers) {
      yield buffer;
    }
    if (stall) {
      await Completer<void>().future; // never completes
    }
    if (throwMessage != null) {
      throw InferenceStreamException(throwMessage!);
    }
  }

  @override
  Future<void> dispose() async {}
}

/// A complete, schema-conforming TutorResponse document, long enough that
/// small chunks land inside the nested errors array.
const _completeJson =
    '{"correction":{"content":"Eu gosto de cafe","translation":"I like '
    'coffee","errors":[{"original":"eu gosto","corrected":"Eu gosto",'
    '"explanation":"Capitalize the first word."}]},"conversation":'
    '{"content":"Muito bem!","translation":"Very good!"}}';

/// Cumulative buffers-so-far for [full], revealing [step] chars at a time.
List<String> _cumulative(String full, {int step = 8}) {
  final out = <String>[];
  for (var end = step; end < full.length; end += step) {
    out.add(full.substring(0, end));
  }
  out.add(full);
  return out;
}

/// Total number of closed nodes in a closure tree (monotonically grows as the
/// buffer fills, since a closed node stays closed in any larger buffer).
int _closedCount(JsonClosure c) {
  var n = c.closed ? 1 : 0;
  for (final f in c.fields.values) {
    n += _closedCount(f);
  }
  for (final e in c.elements) {
    n += _closedCount(e);
  }
  return n;
}

StructuredStreamEngine<TutorResponse> _engineFor(_ScriptedEngine engine) =>
    StructuredStreamEngine<TutorResponse>(
      engine: engine,
      fromJson: TutorResponse.fromJson,
      timeout: const Duration(milliseconds: 100),
    );

void main() {
  const request = InferenceRequest(prompt: 'x');

  test('intermediate deltas grow, with null value and not complete', () async {
    final sse = _engineFor(_ScriptedEngine(_cumulative(_completeJson)));

    final deltas = await sse.generateStream(request).toList();
    final intermediates = deltas.where((d) => !d.isTerminal).toList();

    expect(intermediates, isNotEmpty);
    for (final d in intermediates) {
      expect(d.value, isNull);
      expect(d.isComplete, isFalse);
      expect(d.failure, isNull);
    }

    // Closed-node count never decreases across emissions.
    for (var i = 1; i < intermediates.length; i++) {
      expect(
        _closedCount(intermediates[i].closure),
        greaterThanOrEqualTo(_closedCount(intermediates[i - 1].closure)),
      );
    }
    // The last intermediate has filled in the correction block.
    expect(intermediates.last.partial['correction'], isA<Map<String, dynamic>>());
  });

  test('a nested array element is visible while still open (arrive-as-you-go)',
      () async {
    final sse = _engineFor(_ScriptedEngine(_cumulative(_completeJson)));

    final deltas = await sse.generateStream(request).toList();

    bool firstErrorOpen(StructuredDelta<TutorResponse> d) {
      final e0 = d.closure.field('correction')?.field('errors')?.element(0);
      return e0 != null && !e0.closed;
    }

    // At least one delta exposes errors[0] before its closing brace arrives...
    expect(deltas.any(firstErrorOpen), isTrue);
    // ...and by the end that element is closed.
    final finalE0 =
        deltas.last.closure.field('correction')!.field('errors')!.element(0)!;
    expect(finalE0.closed, isTrue);
  });

  test('terminal value equals the one-shot parse of the same buffer', () async {
    final sse = _engineFor(_ScriptedEngine(_cumulative(_completeJson)));

    final deltas = await sse.generateStream(request).toList();
    final terminal = deltas.last;

    const oneShot = StructuredOutputParser<TutorResponse>(
      fromJson: TutorResponse.fromJson,
    );
    final expected = oneShot.parse(_completeJson) as ParseSuccess<TutorResponse>;

    expect(terminal.isComplete, isTrue);
    expect(terminal.failure, isNull);
    expect(terminal.value, isNotNull);
    expect(terminal.value, expected.value);
  });

  test('inference failure yields a terminal inference-failure delta', () async {
    final sse = _engineFor(
      _ScriptedEngine(const ['{"correction":'], throwMessage: 'boom'),
    );

    final deltas = await sse.generateStream(request).toList();
    final terminal = deltas.last;

    expect(terminal.value, isNull);
    expect(terminal.isComplete, isFalse);
    expect(terminal.failure, isNotNull);
    expect(terminal.failure!.kind, StructuredFailureKind.inference);
    expect(terminal.failure!.error, 'boom');
  });

  test('malformed final JSON yields a terminal parse-failure delta', () async {
    // Valid JSON, but not a TutorResponse: the final strict parse fails.
    final sse = _engineFor(_ScriptedEngine(_cumulative('{"foo":"bar"}')));

    final deltas = await sse.generateStream(request).toList();
    final terminal = deltas.last;

    expect(terminal.value, isNull);
    expect(terminal.failure, isNotNull);
    expect(terminal.failure!.kind, StructuredFailureKind.parse);
    expect(terminal.failure!.rawText, isNotNull);
  });

  test('a stalled stream times out to a terminal inference failure', () async {
    final sse = _engineFor(
      _ScriptedEngine(const ['{"correction":{'], stall: true),
    );

    final deltas = await sse.generateStream(request).toList();
    final terminal = deltas.last;

    expect(terminal.failure, isNotNull);
    expect(terminal.failure!.kind, StructuredFailureKind.inference);
    expect(terminal.failure!.error, 'Response timed out');
  });

  test('coalescing suppresses ticks with an unchanged map and closed-flags',
      () async {
    // Three buffers that all parse to the same closed {"a":1}.
    final sse = _engineFor(
      _ScriptedEngine(const ['{"a":1}', '{"a":1} ', '{"a":1}  ']),
    );

    final deltas = await sse.generateStream(request).toList();
    final intermediates = deltas.where((d) => !d.isTerminal).toList();

    expect(intermediates, hasLength(1));
    expect(jsonEncode(intermediates.single.partial), '{"a":1}');
  });
}
