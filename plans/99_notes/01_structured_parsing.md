# Structured Parsing - Current Data Flow

## AS-IS: How raw LLM text is handled today

### Layer 1: LLM produces raw text

The on-device model (Gemma 3 1B via LiteRT-LM) generates a string response.
If constrained decoding is active (FSM grammar enforcement at the C++ level),
this string is guaranteed to be valid JSON matching the schema. If not, it
could be anything - JSON, markdown-wrapped JSON, or broken text.

### Layer 2: InferenceEngine.generate() wraps it

```
InferenceRequest(prompt) --> [Engine] --> InferenceResult (sealed)
                                            |
                                            +-- InferenceSuccess(rawText, tutorResponse?)
                                            +-- InferenceFailure(error)
```

**FlutterGemmaEngine** (real, currently placeholder):
- Calls LiteRT-LM C++
- Returns `InferenceSuccess(rawText: response)` - tutorResponse is always null
- Does NOT parse the output at all

**FakeInferenceEngine** (test/dev):
- Loads pre-made TutorResponse fixtures from JSON asset
- Returns `InferenceSuccess(rawText: jsonEncode(fixture), tutorResponse: fixture)`
- BOTH fields populated because source is already structured

### Layer 3: StructuredOutputParser (standalone class)

```
rawText --> [StructuredOutputParser.parse()] --> ParseResult (sealed)
                                                    |
                                                    +-- ParseSuccess(response: TutorResponse)
                                                    +-- ParseFailure(rawText, error)
```

Extraction strategies (tried in order):
1. Direct JSON parse (pure JSON string)
2. Extract from markdown code block (```json ... ```)
3. Extract JSON substring (first `{` to last `}`)

Then validates by calling `TutorResponse.fromJson()` (freezed-generated).

### Layer 4: ConversationController (not yet implemented)

Currently planned to call engine.generate() and then decide how to get a
TutorResponse from the result. This is where the confusion lives.

### Diagram: current flow end-to-end

```
User message
    |
    v
PromptManager.buildPrompt() --> prompt string
    |
    v
InferenceEngine.generate(InferenceRequest(prompt))
    |
    v
InferenceResult
    |
    +-- InferenceFailure --> show error message to user
    |
    +-- InferenceSuccess
            |
            +-- .tutorResponse (nullable)
            |       |
            |       +-- non-null: ??? (who uses this? nothing currently)
            |       +-- null: ??? (what happens?)
            |
            +-- .rawText (always present)
                    |
                    v
            StructuredOutputParser.parse(rawText)
                    |
                    +-- ParseSuccess --> use .response (TutorResponse)
                    +-- ParseFailure --> show rawText to user as fallback
```

## Key observations

1. **Two parsing pathways exist but are never coordinated.** InferenceSuccess
   carries tutorResponse AND rawText. There is no clear contract on which one
   the consumer should use.

2. **FakeInferenceEngine returns redundant data.** It gives you the parsed
   TutorResponse AND the serialized JSON. If the controller re-parses rawText,
   the FakeInferenceEngine's tutorResponse field is dead weight. If the
   controller uses tutorResponse directly, it never exercises the parser.

3. **FlutterGemmaEngine skips parsing entirely.** It returns only rawText.
   The tutorResponse field is null. So the controller MUST use the parser
   for the real engine path.

4. **StructuredOutputParser is domain-specific.** It hardcodes TutorResponse
   as the output type. It lives in `services/inference/` alongside the
   engine - but it's not part of the engine interface. It's a standalone
   helper with no clear owner.

5. **InferenceSuccess.tutorResponse creates ambiguity.** It's unclear whether:
   - The engine is responsible for validation (constrained decoding succeeded)
   - The caller is responsible for validation (always parse rawText)
   - Or both (check tutorResponse first, fall back to parser)

6. **No retry logic exists.** The drafts mention a retry loop (re-prompt with
   error), but neither the engine nor the parser implements retry. If parsing
   fails, the user just sees raw text.

## Types involved

```dart
// lib/services/inference/inference_engine.dart
class InferenceRequest { String prompt; int maxTokens; double temperature; int topK; }
sealed class InferenceResult {}
class InferenceSuccess extends InferenceResult { String rawText; TutorResponse? tutorResponse; }
class InferenceFailure extends InferenceResult { String error; }
abstract class InferenceEngine { Future<InferenceResult> generate(InferenceRequest); ... }

// lib/services/inference/structured_output_parser.dart
sealed class ParseResult {}
class ParseSuccess extends ParseResult { TutorResponse response; }
class ParseFailure extends ParseResult { String rawText; String error; }
class StructuredOutputParser { ParseResult parse(String rawText); }

// lib/models/tutor_response.dart (freezed)
class TutorResponse { CorrectionBlock correction; ConversationBlock conversation; }
class CorrectionBlock { String content; String translation; List<CorrectionError> errors; }
class CorrectionError { String original; String corrected; String explanation; }
class ConversationBlock { String content; String translation; }
```

## File locations

| File | Role |
|------|------|
| lib/services/inference/inference_engine.dart | Interface + InferenceRequest/Result types |
| lib/services/inference/fake_inference_engine.dart | Test/dev engine (returns both fields) |
| lib/services/inference/flutter_gemma_engine.dart | Real engine (returns rawText only, placeholder) |
| lib/services/inference/structured_output_parser.dart | JSON extraction + TutorResponse validation |
| lib/models/tutor_response.dart | Domain model (freezed) |
| lib/services/conversation/ | Empty - ConversationController not yet created |

## UPDATE

### de-coupling of InferenceSuccess and tutorResponse

the coupling of InferenceSuccess to a specific domain model (TutorResponse) is unacceptable

the inference engine should be completely agnostic to the content of the response - it should just return raw text

if we have some constrained decoding that guarantees valid output, that is excellent, but that output is still just raw text to the engine

then we want to make StructuredOutputParser generic and reusable across different domains - it should not be tied to TutorResponse

then we have a InferenceStructuredEngine that is also generic, and will combine the two - it will call the base engine to get raw text, then call the parser to get a structured result, and return either the structured result or a parsing error

## Proposals

### Option A: Generic class with factory function

The simplest Dart approach. Parser takes a `fromJson` factory at construction time.

```dart
// Engine stays pure text-in/text-out
class InferenceSuccess extends InferenceResult {
  const InferenceSuccess({required this.rawText});
  final String rawText;
  // no tutorResponse field
}

// Parser becomes generic
class StructuredOutputParser<T> {
  const StructuredOutputParser({required this.fromJson});
  final T Function(Map<String, dynamic> json) fromJson;

  ParseResult<T> parse(String rawText) { ... }
}

sealed class ParseResult<T> {}
class ParseSuccess<T> extends ParseResult<T> { final T value; }
class ParseFailure<T> extends ParseResult<T> { final String rawText; final String error; }

// Usage
final parser = StructuredOutputParser<TutorResponse>(
  fromJson: TutorResponse.fromJson,
);
```

Pros:
- Minimal abstraction, easy to understand
- Works with any freezed model (they all generate fromJson)
- No inheritance required on the domain model
- Single parser class covers all schemas

Cons:
- No schema JSON for constrained decoding (just parsing, not enforcement)
- Cannot carry metadata about the expected schema structure

---

### Option B: Codec pattern (like dart:convert)

A richer abstraction that pairs encoding/decoding with schema metadata.
Useful if the engine needs the JSON Schema for constrained decoding setup.

```dart
/// Describes how to encode/decode a structured response type.
abstract class ResponseCodec<T> {
  T decode(Map<String, dynamic> json);
  Map<String, dynamic> encode(T value);

  /// JSON Schema string for constrained decoding grammar compilation.
  String get jsonSchema;
}

class TutorResponseCodec implements ResponseCodec<TutorResponse> {
  @override
  TutorResponse decode(Map<String, dynamic> json) => TutorResponse.fromJson(json);

  @override
  Map<String, dynamic> encode(TutorResponse value) => value.toJson();

  @override
  String get jsonSchema => '...'; // the schema from assets/prompts/tutor_response_schema.json
}

// Parser uses the codec
class StructuredOutputParser<T> {
  const StructuredOutputParser({required this.codec});
  final ResponseCodec<T> codec;

  ParseResult<T> parse(String rawText) {
    // ... extraction strategies ...
    return ParseSuccess(value: codec.decode(jsonMap));
  }
}
```

Pros:
- Schema travels with the type - engine can use it for constrained decoding
- Clean separation: codec knows the shape, parser knows extraction strategies
- Could feed `codec.jsonSchema` to LiteRT-LM's FunctionCallingConfig

Cons:
- More boilerplate (one codec class per domain model)
- Overkill if you only ever have one schema (TutorResponse)

---

### Option C: Composition layer - StructuredInferenceEngine

A wrapper that composes a raw engine + a parser into a single "structured"
engine. The raw engine stays generic; the structured layer adds type safety.

```dart
// Raw engine - pure text-in/text-out
abstract class InferenceEngine {
  Future<InferenceResult> generate(InferenceRequest request);
}

class InferenceSuccess extends InferenceResult {
  const InferenceSuccess({required this.rawText});
  final String rawText;
}

// Structured engine - wraps raw engine + parser
class StructuredInferenceEngine<T> {
  StructuredInferenceEngine({
    required this.engine,
    required this.parser,
  });

  final InferenceEngine engine;
  final StructuredOutputParser<T> parser;

  Future<StructuredResult<T>> generate(InferenceRequest request) async {
    final result = await engine.generate(request);
    if (result is InferenceFailure) {
      return StructuredFailure(error: result.error);
    }
    final raw = (result as InferenceSuccess).rawText;
    final parsed = parser.parse(raw);
    return switch (parsed) {
      ParseSuccess(:final value) => StructuredSuccess(value: value, rawText: raw),
      ParseFailure(:final error) => StructuredParseFailure(rawText: raw, error: error),
    };
  }
}

sealed class StructuredResult<T> {}
class StructuredSuccess<T> extends StructuredResult<T> {
  final T value;
  final String rawText;
}
class StructuredFailure<T> extends StructuredResult<T> { final String error; }
class StructuredParseFailure<T> extends StructuredResult<T> {
  final String rawText;
  final String error;
}
```

Pros:
- Clean separation of concerns: engine knows nothing about parsing
- ConversationController depends on StructuredInferenceEngine<TutorResponse>
- Easy to test: mock the raw engine, test parsing separately
- Three-state result: inference failure vs parse failure vs success
- Composable: same engine, different parsers for different use cases

Cons:
- Extra wrapper layer
- Provider setup slightly more complex

---

### Option D: OutputParser as an abstract interface (strategy pattern)

Keep the parser as a swappable strategy. Different output shapes get different
parser implementations. No generics needed at the engine level.

```dart
abstract class OutputParser<T> {
  ParseResult<T> parse(String rawText);
}

class TutorResponseParser implements OutputParser<TutorResponse> {
  @override
  ParseResult<TutorResponse> parse(String rawText) {
    // ... extraction strategies specific to TutorResponse ...
  }
}

// ConversationController takes the parser as a dependency
class ConversationController {
  ConversationController({
    required this.engine,
    required this.parser, // OutputParser<TutorResponse>
    ...
  });
  final InferenceEngine engine;
  final OutputParser<TutorResponse> parser;
}
```

Pros:
- Each domain model gets a tailored parser (different extraction heuristics)
- No generic type parameter pollution on the engine
- Testable: swap in a FakeParser for controller tests

Cons:
- Multiple parser classes if you add schemas (but we only have one)
- No compile-time guarantee that engine + parser are paired correctly

---

### Option E: Combine B + C (codec feeds constrained decoding + structured engine)

The most complete approach. The codec provides the schema to configure
constrained decoding at the engine level, and also handles parsing.

```dart
abstract class ResponseCodec<T> {
  T decode(Map<String, dynamic> json);
  String get jsonSchema;
}

class StructuredInferenceEngine<T> {
  StructuredInferenceEngine({
    required this.engine,
    required this.codec,
  });

  final InferenceEngine engine;
  final ResponseCodec<T> codec;

  Future<StructuredResult<T>> generate(InferenceRequest request) async {
    // Could configure constrained decoding using codec.jsonSchema
    final result = await engine.generate(
      request.copyWith(responseSchema: codec.jsonSchema),
    );
    // Then parse and validate
    ...
  }
}
```

Pros:
- Schema drives both constrained decoding AND validation
- Single source of truth for what the model should output
- Future-proof for when FlutterGemmaEngine supports function calling mode

Cons:
- Most complex, heaviest abstraction
- InferenceRequest would need a schema field (or separate config step)
- Premature if constrained decoding is not yet wired up

---

## Summary

| Option | Complexity | Decouples engine? | Generic? | Schema for constrained decoding? | Retry support? |
|--------|-----------|-------------------|----------|----------------------------------|----------------|
| A: Factory function | Low | Yes | Yes | No | No |
| B: Codec pattern | Medium | Yes | Yes | Yes | No |
| C: StructuredInferenceEngine | Medium | Yes | Yes | No | Easy to add |
| D: Strategy pattern | Low | Yes | Yes (per-class) | No | No |
| E: Codec + Structured | High | Yes | Yes | Yes | Easy to add |
| F: Typedef + extension types | Low | Yes | Yes | No | No |
| G: Mixin-based composition | Medium | Yes | Yes | Optional | Yes |

All options agree on one thing: **remove `tutorResponse` from `InferenceSuccess`**.
The engine returns raw text. Parsing happens outside.

---

### Option F: Dart typedef + extension types (lightweight)

Dart 3.3 extension types give you zero-cost type wrapping. Combined with
typedef for the factory function, this is the most Dart-idiomatic lightweight
approach. No class hierarchy needed.

```dart
// Type alias for any JSON-deserializable factory
typedef FromJsonFactory<T> = T Function(Map<String, dynamic>);

// Extension type wraps the parse result with zero runtime cost
extension type ParsedOutput<T>._(({T value, String rawText})? _result) {
  bool get isSuccess => _result != null;
  T get value => _result!.value;
  String get rawText => _result!.rawText;
}

// Generic parse function - no class needed
ParseResult<T> parseStructuredOutput<T>(
  String rawText,
  FromJsonFactory<T> fromJson,
) {
  // ... extraction strategies ...
}

// Usage is a one-liner wherever you need it
final result = parseStructuredOutput(rawText, TutorResponse.fromJson);
```

Pros:
- No class hierarchy, no inheritance, no boilerplate
- Dart-native: extension types are zero-cost abstractions
- Maximum flexibility - just a function, compose however you want
- Easy to inline in tests

Cons:
- Less discoverable (no class to navigate to)
- No state (no caching, no retry counter)
- Extraction strategies not customizable per-type

---

### Option G: Mixin-based composition with retry

Dart mixins let you compose capabilities without deep inheritance. The
structured engine gets retry behavior mixed in rather than baked in.

```dart
// Raw engine - pure text
abstract class InferenceEngine {
  Future<InferenceResult> generate(InferenceRequest request);
}

// Retry logic as a mixin (reusable across different wrappers)
mixin RetryMixin {
  int get maxRetries => 3;

  Future<T> withRetry<T>(
    Future<T> Function(String? previousError) attempt,
  ) async {
    String? lastError;
    for (var i = 0; i < maxRetries; i++) {
      try {
        return await attempt(lastError);
      } on ParseException catch (e) {
        lastError = e.message;
      }
    }
    throw MaxRetriesExceeded(lastError);
  }
}

// Structured engine with retry mixed in
class StructuredInferenceEngine<T> with RetryMixin {
  StructuredInferenceEngine({
    required this.engine,
    required this.fromJson,
    this.maxRetries = 3,
  });

  final InferenceEngine engine;
  final T Function(Map<String, dynamic>) fromJson;
  @override
  final int maxRetries;

  Future<StructuredResult<T>> generate(
    InferenceRequest request, {
    String Function(String error)? buildRetryPrompt,
  }) async {
    return withRetry((previousError) async {
      final modifiedRequest = previousError != null && buildRetryPrompt != null
          ? request.copyWith(prompt: buildRetryPrompt(previousError))
          : request;
      final result = await engine.generate(modifiedRequest);
      if (result is InferenceFailure) throw InferenceException(result.error);
      // parse or throw ParseException to trigger retry
      ...
    });
  }
}
```

Pros:
- Retry is composable (mix it in or leave it out)
- Matches the LangChain "parse, fail, re-prompt with error" pattern from drafts
- Engine stays pure; retry is a wrapper concern
- Can customize retry prompt building per-use-case

Cons:
- More moving parts
- Retry on small on-device models may not help (same model, same mistake)
- Mixin state management can be tricky if not careful

---

### Option H: Keep it minimal - just separate the parser

The user's UPDATE specifically says:
1. Engine returns raw text (decouple)
2. Parser becomes generic (not tied to TutorResponse)
3. StructuredInferenceEngine combines them

This is essentially Option C but expressed at the minimal viable level.
The key question is how much flexibility to build into the generic parser.

**Variant H1: Parser is just the extraction strategies (shared) + a factory**

```dart
/// Extracts JSON from messy LLM text (markdown blocks, embedded JSON, etc.)
class JsonExtractor {
  const JsonExtractor();
  String? extract(String rawText); // returns clean JSON string or null
}

/// Generic structured parser: extract JSON then deserialize
class StructuredOutputParser<T> {
  const StructuredOutputParser({
    required this.fromJson,
    this.extractor = const JsonExtractor(),
  });

  final T Function(Map<String, dynamic>) fromJson;
  final JsonExtractor extractor;

  ParseResult<T> parse(String rawText) {
    final json = extractor.extract(rawText);
    if (json == null) return ParseFailure(rawText: rawText, error: 'No JSON found');
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return ParseSuccess(value: fromJson(map));
    } on Object catch (e) {
      return ParseFailure(rawText: rawText, error: e.toString());
    }
  }
}
```

This separates the "find JSON in text" concern (JsonExtractor) from the
"deserialize into type T" concern (fromJson). Both are independently testable
and swappable.

**Variant H2: StructuredInferenceEngine is the consumer-facing API**

```dart
class StructuredInferenceEngine<T> {
  StructuredInferenceEngine({
    required this.engine,
    required this.parser,
  });

  final InferenceEngine engine;
  final StructuredOutputParser<T> parser;

  Future<StructuredResult<T>> generate(InferenceRequest request) async {
    final result = await engine.generate(request);
    return switch (result) {
      InferenceFailure(:final error) => StructuredFailure(error: error),
      InferenceSuccess(:final rawText) => switch (parser.parse(rawText)) {
        ParseSuccess(:final value) => StructuredSuccess(value: value, rawText: rawText),
        ParseFailure(:final error) => StructuredParseFailure(rawText: rawText, error: error),
      },
    };
  }
}
```

The ConversationController would depend on
`StructuredInferenceEngine<TutorResponse>` (not on InferenceEngine directly).
This gives a clean typed API where the caller gets `TutorResponse` or an
explicit failure mode.

---

## The key decision axes

1. **Do you need JSON Schema at the engine level now?**
   - Yes -> Options B, E (codec pattern carries schema)
   - No, defer -> A, C, D, F, G, H

2. **Do you want a composed object (engine + parser) or manual wiring?**
   - Composed -> C, E, G, H2 (StructuredInferenceEngine wraps both)
   - Manual (controller wires engine + parser itself) -> A, D, F, H1

3. **Should retry logic be part of this layer?**
   - Yes -> G (mixin), or add to C/E/H2
   - No, handle elsewhere (or not at all for 1B models) -> everything else

4. **How much type safety / boilerplate tradeoff?**
   - Minimal boilerplate -> A, F (one-liner usage)
   - Medium boilerplate, strong contracts -> C, H
   - Heavy boilerplate, maximum guarantees -> B, E
  - No, controller wires them manually -> A or D

## Comments

* output parser and codec are overkill, decoding is always 'valid json -> some object'
* factory function approach is enough
* structured inference engine is not the one to handle constrained generation
* InferenceEngine should be abstracted more: add one or more options to make the `generate` method more flexible. it will not do the parsing, but it can take additional parameters that allow it to configure constrained decoding at the lower level. actual implementations of the engine will write their own `generate` method that uses these params to set up the decoding strategy. similar, the `StructuredInferenceEngine` can be more flexible and and not necessarily receive a json schema.
