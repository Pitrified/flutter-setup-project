---
status: complete
depends_on: [04_core_systems/00_inference_interface.md]
produces: [lib/services/inference/fake_inference_engine.dart, assets/fixtures/tutor_responses.json]
---

# Plan: FakeInferenceEngine

## Goal

A deterministic mock inference engine that returns pre-loaded responses from a
JSON fixture file. This is a first-class citizen (not just for tests) that enables:
- Full UI/flow development without a real model
- Widget tests without loading 500MB of weights
- CI/CD pipelines
- Demo mode

## Implementation

`lib/services/inference/fake_inference_engine.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/inference_status.dart';
import '../../models/tutor_response.dart';
import 'inference_engine.dart';

/// Fake inference engine that returns pre-loaded responses in sequence.
///
/// Responses are loaded from a JSON fixture file in assets/fixtures/.
/// Each call to [generate] returns the next response in order, cycling back
/// to the start when all responses have been used.
class FakeInferenceEngine implements InferenceEngine {
  FakeInferenceEngine({
    this.fixtureAssetPath = 'assets/fixtures/tutor_responses.json',
    this.responseDelayMs = 500,
  });

  final String fixtureAssetPath;
  final int responseDelayMs;

  final _statusController = StreamController<InferenceStatus>.broadcast();
  InferenceStatus _status = const InferenceStatus.uninitialized();
  List<TutorResponse> _responses = [];
  int _nextIndex = 0;

  @override
  InferenceStatus get status => _status;

  @override
  Stream<InferenceStatus> get statusStream => _statusController.stream;

  @override
  bool get isReady => _status == const InferenceStatus.ready();

  @override
  Future<void> initialize() async {
    _setStatus(const InferenceStatus.loading());

    final jsonString = await rootBundle.loadString(fixtureAssetPath);
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    _responses = jsonList
        .map((e) => TutorResponse.fromJson(e as Map<String, dynamic>))
        .toList();

    _setStatus(const InferenceStatus.ready());
  }

  @override
  Future<InferenceResult> generate(InferenceRequest request) async {
    if (!isReady) {
      return const InferenceFailure(error: 'Engine not initialized');
    }

    _setStatus(const InferenceStatus.generating());

    // Simulate inference latency
    await Future.delayed(Duration(milliseconds: responseDelayMs));

    if (_responses.isEmpty) {
      _setStatus(const InferenceStatus.ready());
      return const InferenceSuccess(
        rawText: '{"correction": {"content": "", "translation": "", "errors": []}, "conversation": {"content": "No fixtures loaded", "translation": "No fixtures loaded"}}',
      );
    }

    final response = _responses[_nextIndex % _responses.length];
    _nextIndex++;

    _setStatus(const InferenceStatus.ready());
    return InferenceSuccess(
      rawText: jsonEncode(response.toJson()),
      tutorResponse: response,
    );
  }

  @override
  Future<void> dispose() async {
    _setStatus(const InferenceStatus.disposed());
    await _statusController.close();
  }

  void _setStatus(InferenceStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }
}
```

## Fixture file format

`assets/fixtures/tutor_responses.json`:

```json
[
  {
    "correction": {
      "content": "Eu gosto de cafe",
      "translation": "I like coffee",
      "errors": [
        {
          "original": "eu gosto de cafe",
          "corrected": "Eu gosto de cafe",
          "explanation": "Sentences should start with a capital letter."
        }
      ]
    },
    "conversation": {
      "content": "Muito bem! Voce esta aprendendo rapido.",
      "translation": "Very good! You are learning fast."
    }
  },
  {
    "correction": {
      "content": "",
      "translation": "",
      "errors": []
    },
    "conversation": {
      "content": "Otimo! Sua frase esta perfeita.",
      "translation": "Great! Your sentence is perfect."
    }
  },
  {
    "correction": {
      "content": "Eu estou cansado",
      "translation": "I am tired",
      "errors": [
        {
          "original": "Eu sou cansado",
          "corrected": "Eu estou cansado",
          "explanation": "Use 'estar' for temporary states, not 'ser'.",
        }
      ]
    },
    "conversation": {
      "content": "Boa tentativa! Veja a correcao acima.",
      "translation": "Good try! See the correction above."
    }
  }
]
```

## Provider override pattern

```dart
// In main.dart for dev mode:
ProviderScope(
  overrides: [
    inferenceEngineProvider.overrideWithValue(FakeInferenceEngine()),
  ],
  child: const FalaApp(),
)

// In tests:
final container = ProviderContainer(
  overrides: [
    inferenceEngineProvider.overrideWithValue(
      FakeInferenceEngine(responseDelayMs: 0),
    ),
  ],
);
```

## Tests

`test/services/fake_inference_engine_test.dart`:

- Starts as uninitialized, transitions to ready after initialize()
- Returns responses in sequence from fixture file
- Cycles back to first response after exhausting list
- Returns failure if generate() called before initialize()
- Simulates configurable delay
- Status stream emits correct transitions

## Acceptance criteria

- [ ] FakeInferenceEngine implements InferenceEngine fully
- [ ] Loads responses from JSON fixture file
- [ ] Returns responses sequentially with cycling
- [ ] Configurable delay simulates real inference latency
- [ ] Status transitions are correct and observable via stream
- [ ] Tests pass
- [ ] `flutter analyze` passes
