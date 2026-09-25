# Structured Output System

> System spec for `lib/services/inference/structured_inference_engine.dart`,
> `structured_output_parser.dart`, and `json_extractor.dart`

## Purpose

Composes a raw `InferenceEngine` with a typed parser to provide a single API:
send a prompt, get back a domain object or an explicit failure mode. Callers
never deal with raw text parsing.

## Components

```
InferenceEngine (raw text) -> StructuredInferenceEngine<T> -> StructuredResult<T>
                                      |
                              StructuredOutputParser<T>
                                      |
                                JsonExtractor
```

## StructuredInferenceEngine\<T\>

### Constructor parameters

| Param | Type | Required | Description |
|-------|------|---------|-------------|
| `engine` | `InferenceEngine` | yes | Raw inference backend |
| `parser` | `StructuredOutputParser<T>` | yes | Converts raw text to T |
| `timeout` | `Duration` | no | Max wait for inference (default 30s) |

### Public API

| Method | Signature | Description |
|--------|-----------|-------------|
| `status` | `InferenceStatus` | Delegated from engine |
| `statusStream` | `Stream<InferenceStatus>` | Delegated from engine |
| `isReady` | `bool` | Delegated from engine |
| `generate(request)` | `Future<StructuredResult<T>>` | Generate + parse |
| `initialize()` | `Future<void>` | Delegates to engine |
| `dispose()` | `Future<void>` | Delegates to engine |

### Result type

`StructuredResult<T>` is a sealed class with three subtypes:

| Subtype | Fields | Meaning |
|---------|--------|---------|
| `StructuredSuccess<T>` | `value: T`, `rawText: String` | Parsed successfully |
| `StructuredInferenceFailure<T>` | `error: String` | Engine failed or timed out |
| `StructuredParseFailure<T>` | `rawText: String`, `error: String` | Text generated but parse failed |

### What a parse failure shows the learner

A `StructuredParseFailure` reads as a failed turn, not as the tutor speaking. The
conversation shows "Error generating response: the reply was not in the expected
format." and no correction card, and `rawText` goes to the log at warn level for
whoever is debugging it.

The reason is that the raw text is indistinguishable from an answer. A model that
breaks its schema usually writes fluent prose, so showing it puts English chatter
in the tutor's voice and the learner cannot tell that the correction they did not
get was lost rather than not needed. There is no retry: nothing in the app retries
a failed turn today, and one failure mode is not the place to invent one.

## StructuredOutputParser\<T\>

Generic parser that extracts JSON from LLM text and deserializes to T.

### Constructor parameters

| Param | Type | Required | Description |
|-------|------|---------|-------------|
| `fromJson` | `T Function(Map<String, dynamic>)` | yes | Factory (e.g. `TutorResponse.fromJson`) |
| `extractor` | `JsonExtractor` | no | Extraction strategy (default instance) |

### Parse flow

1. `extractor.extract(rawText)` - tries to find valid JSON string.
2. `jsonDecode(...)` - decode to Map.
3. `fromJson(map)` - construct typed domain object.

Returns `ParseResult<T>` (sealed: `ParseSuccess` / `ParseFailure`).

## JsonExtractor

Stateless utility that finds JSON in raw LLM output. Three strategies in order:

1. **Direct parse** - entire output is valid JSON.
2. **Markdown code block** - extract content from `` ```json ... ``` ``.
3. **JSON substring** - first `{` to last `}`.

## Dependencies

- `InferenceEngine` (interface)
- `AppLogger` (debug-only timing logs)
- `dart:convert` (JSON decode)

## Provider

`structuredInferenceEngineProvider` in `lib/providers/inference_provider.dart`:

```dart
final structuredInferenceEngineProvider =
    Provider<StructuredInferenceEngine<TutorResponse>?>((ref) {
  final engine = ref.watch(inferenceEngineProvider);
  if (engine == null) return null;
  return StructuredInferenceEngine(
    engine: engine,
    parser: const StructuredOutputParser(fromJson: TutorResponse.fromJson),
  );
});
```

Returns null until the raw engine is initialized.
