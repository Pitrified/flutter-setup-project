# Tool Calling

## draft

in
flutter-setup-project/plans/08_llm_integration/01_structured_output_analysis.md
we analyzed `ToolChoice.required` approach

we want to plan the implementation

analyze the existing engine approaches
`flutter-setup-project/docs/library/structured-output-system.md`
`flutter-setup-project/docs/library/inference-engine.md`

is the existing InferenceEngine compatible with tool calling?
how would that be configured?
as inference engine for now knows nothing explitic about `<T>` so how do we pass the information to it?

and if we want to use the new InferenceToolEngine within
StructuredInferenceEngine
could that be done? how?

or do we need a new StructuredInferenceToolEngine?

brainstorm various composition/abstracion/whatever option to keep it clean

## Current architecture summary

```
ConversationController
  -> StructuredInferenceEngine<TutorResponse>
       -> InferenceEngine.generate(InferenceRequest) -> InferenceResult (raw text)
       -> StructuredOutputParser<T>.parse(rawText) -> ParseResult<T>
```

Key observations:

1. **InferenceEngine** is prompt-in, text-out. It knows nothing about `<T>`, tools,
   schemas, or chat sessions. It creates a fresh `createChat()` per `generate()` call.

2. **StructuredInferenceEngine<T>** composes `InferenceEngine` + `StructuredOutputParser<T>`.
   It calls `engine.generate()` (gets raw text), then `parser.parse()` (extracts JSON,
   deserializes to T). The schema knowledge lives only in the `fromJson` factory + the
   prompt text that asks the model to output JSON.

3. **FlutterGemmaEngine** already uses `createChat()` and `generateChatResponseAsync()`.
   It collects `TextResponse` tokens into a buffer. It does NOT use tools/ToolChoice.

4. **Tool calling with flutter_gemma** requires:
   - Defining a `Tool(name, description, parameters)` with a JSON Schema map.
   - Passing `tools: [...]` and `toolChoice: ToolChoice.required` to `createChat()`.
   - Handling `FunctionCallResponse` instead of (or alongside) `TextResponse`.
   - The response `args` is already a `Map<String, dynamic>` - no text parsing needed.

5. **The schema already exists** at `assets/prompts/tutor_response_schema.json` and
   matches the `TutorResponse.fromJson` shape (modulo `correction` vs `CorrectionBlock`).

---

## Core question

With tool calling, the model returns `FunctionCallResponse.args` (a pre-parsed Map).
The `StructuredOutputParser` + `JsonExtractor` pipeline becomes unnecessary - the
plugin already parsed the JSON. How do we wire this in cleanly?

---

## Option A: New engine implementation (ToolCallingEngine implements InferenceEngine)

Create `ToolCallingEngine implements InferenceEngine` that uses tool calling internally
but still returns `InferenceSuccess(rawText: jsonEncode(args))`.

```dart
class ToolCallingEngine implements InferenceEngine {
  ToolCallingEngine({required this.modelPath, required this.tool});

  final String modelPath;
  final Tool tool; // flutter_gemma Tool with schema

  @override
  Future<InferenceResult> generate(InferenceRequest request) async {
    final chat = await _model!.createChat(
      tools: [tool],
      toolChoice: ToolChoice.required,
      isThinking: false,
      modelType: ModelType.qwen3,
      maxFunctionBufferLength: 2048,
    );
    await chat.addQueryChunk(Message(text: request.prompt, isUser: true));
    await for (final response in chat.generateChatResponseAsync()) {
      if (response is FunctionCallResponse) {
        return InferenceSuccess(rawText: jsonEncode(response.args));
      }
      if (response is TextResponse) {
        // Model ignored tool - return raw text, parser will attempt extraction
        buffer.write(response.token);
      }
    }
    return InferenceSuccess(rawText: buffer.toString());
  }
}
```

**Composition**: Plug into existing StructuredInferenceEngine<TutorResponse> unchanged.

```
ConversationController
  -> StructuredInferenceEngine<TutorResponse>
       -> ToolCallingEngine.generate() -> InferenceSuccess(rawText = JSON from args)
       -> StructuredOutputParser<T>.parse() -> works as before (direct parse path)
```

**Pros**:
- Zero changes to StructuredInferenceEngine, parser, controller, providers.
- FakeInferenceEngine stays the same for tests.
- Existing prompt template still works (system instruction).
- Falls back gracefully: if model returns TextResponse, parser's JsonExtractor tries
  markdown/substring extraction.
- Single responsibility: ToolCallingEngine just changes how it talks to the plugin.

**Cons**:
- Redundant serialization: args is already a Map, we jsonEncode it, then the parser
  jsonDecode's it again. (Negligible performance cost for small payloads.)
- Does not expose the "pre-parsed" nature of tool calling to upper layers.
- Tool definition (schema) is baked into the engine. If we need different schemas for
  different request types, we'd need multiple engines or parameterization.
  NOTE: creating one engine per type is ok, it's what we do for `StructuredInferenceEngine<T>` anyway

---

## Option B: New InferenceEngine variant with typed result (InferenceToolEngine<T>)

Create a parallel interface that returns `Map<String, dynamic>` directly:

```dart
abstract class InferenceToolEngine<T> {
  Future<ToolInferenceResult<T>> generate(InferenceRequest request);
  // ... same status/init/dispose as InferenceEngine
}

sealed class ToolInferenceResult<T> {}
class ToolCallSuccess<T> extends ToolInferenceResult<T> {
  final T value; // pre-parsed via fromJson
}
class ToolCallFallback<T> extends ToolInferenceResult<T> {
  final String rawText; // model returned text instead of tool call
}
class ToolCallFailure<T> extends ToolInferenceResult<T> {
  final String error;
}
```

**Composition**: Would replace both InferenceEngine + StructuredInferenceEngine in one
layer. ConversationController would depend on `InferenceToolEngine<TutorResponse>`
directly.

**Pros**:
- No redundant JSON round-trip.
- Type safety end-to-end.
- Clean separation: the engine knows it's doing tool calling, returns domain objects.

**Cons**:
- New interface = new fake engine for tests.
- ConversationController now couples to the tool-calling concept directly.
- Cannot compose with the existing text-based parser fallback layer.
- Breaks the current clean separation where `InferenceEngine` knows nothing about T.
  NOTE: This would be ok, we are creating a new engine where info about T are sent in as a tool, it is fair that now the actual generation engine knows it
- More invasive change: touches providers, controller, tests.

### Notes

InferenceToolEngine could be renamed to InferenceMapEngine, since it returns a Map instead of String
the fact that internally the map is generated via tool calling is an implementation detail
(eg via the finite state machine constrained generation approach)

---

## Option C: Adapter inside StructuredInferenceEngine (strategy pattern)

Keep `InferenceEngine` text-based. Add an alternative "parsing strategy" to
`StructuredInferenceEngine` that receives pre-parsed args:

```dart
class StructuredInferenceEngine<T> {
  StructuredInferenceEngine({
    required this.engine,
    required this.parser,
    this.timeout,
  });
  // ... existing code ...
}
```

But this doesn't really work - the pre-parsing happens inside `InferenceEngine`, not
after it. The structured engine only sees InferenceResult (text). We'd need to smuggle
the Map through somehow (custom InferenceResult subtype).

**Variant C2**: Add a `InferenceMapSuccess` to InferenceResult:

```dart
sealed class InferenceResult {}
class InferenceSuccess extends InferenceResult { final String rawText; }
class InferenceMapSuccess extends InferenceResult { final Map<String, dynamic> args; }
class InferenceFailure extends InferenceResult { final String error; }
```

Then StructuredInferenceEngine handles both:

```dart
InferenceSuccess(:final rawText) => parser.parse(rawText),
InferenceMapSuccess(:final args) => ParseSuccess(value: fromJson(args)),
```

**Pros**:
- No redundant JSON round-trip.
- Minimal change to StructuredInferenceEngine (one extra case in switch).
- InferenceEngine interface gains one new result subtype; existing impls unaffected.
- FakeInferenceEngine can return either text or map as needed.

**Cons**:
- InferenceResult is a shared contract. Adding a tool-calling-specific subtype leaks
  the concept into a "generic" result type.
- Slightly less clean than Option A (which is invisible to everything above the engine).

---

## Option D: Composition with delegation (recommended hybrid)

Essentially Option A with one refinement: extract the Tool definition from the engine
constructor and pass it via the request, so one engine can serve multiple schemas.

```dart
/// Extended request that includes tool calling config.
class ToolCallingRequest extends InferenceRequest {
  const ToolCallingRequest({
    required super.prompt,
    required this.tool,
    super.maxTokens,
    super.temperature,
    super.topK,
    this.maxFunctionBufferLength = 2048,
  });

  final Tool tool;
  final int maxFunctionBufferLength;
}
```

NOTE: please rename `ToolCallingRequest` to `ToolCallingInferenceRequest` to make it clearer that it is an InferenceRequest subtype, and to avoid confusion with the flutter_gemma `Tool` type.

FlutterGemmaEngine (or a subclass) checks `request is ToolCallingRequest` and uses
tool calling path; otherwise falls back to text generation.

```dart
@override
Future<InferenceResult> generate(InferenceRequest request) async {
  if (request is ToolCallingRequest) {
    return _generateWithTool(request);
  }
  return _generateText(request);
}
```

**Composition**: Entirely transparent to StructuredInferenceEngine and above.

```
ConversationController
  -> StructuredInferenceEngine<TutorResponse>
       -> engine.generate(ToolCallingRequest(prompt, tool: tutorTool))
       -> InferenceSuccess(rawText: jsonEncode(args))
       -> parser.parse(rawText) -> TutorResponse
```

The only change needed outside the engine layer: the caller must pass
`ToolCallingRequest` instead of plain `InferenceRequest`. This means either:
- ConversationController constructs ToolCallingRequest directly (knows the Tool), or
- The provider layer wraps the tool config into requests automatically.

**Pros**:
- Single InferenceEngine implementation handles both text and tool calling.
- No new interfaces, no new result types, no new engine classes.
- StructuredInferenceEngine unchanged, parser unchanged.
- FakeInferenceEngine can ignore the ToolCallingRequest subtype and return text as before
  (polymorphism - it just reads `request.prompt`).
- Tool schema can live alongside the prompt template in assets.
- Future-proof: when a second tool/schema is needed, just pass a different Tool.

**Cons**:
- Subtype check (`is ToolCallingRequest`) in generate() is slightly unclean.
- The model still re-serializes -> re-parses JSON (same as Option A, negligible cost).

---

## Recommendation

**Option A** or **Option D** - both keep changes minimal and contained.

| Criterion | A | B | C2 | D |
|-----------|---|---|----|----|
| Files changed | 2-3 | 6+ | 4 | 2-3 |
| New interfaces | 0 | 1 | 0 | 0 |
| Test impact | none | new fakes | minor | none |
| JSON round-trip | yes | no | no | yes |
| Multiple schemas | hard | natural | medium | natural |
| Reversibility | high | low | medium | high |

**Recommendation: Option D** - it is the same effort as A but supports multiple schemas
without needing separate engine instances. The subtype check is a minor inelegance that
can be refactored later if constrained decoding (issue #195) lands and changes the API.

---

## Implementation sketch for Option D

### Files to create/modify

1. **`lib/services/inference/inference_engine.dart`** - add `ToolCallingRequest` class.
2. **`lib/services/inference/flutter_gemma_engine.dart`** - add `_generateWithTool()`.
3. **`lib/services/inference/tool_definitions.dart`** (new) - define `tutorResponseTool`.
4. **`lib/services/conversation/conversation_controller.dart`** - pass `ToolCallingRequest`
   instead of plain `InferenceRequest`.
5. **`lib/services/inference/fake_inference_engine.dart`** - no change (ignores subtype).
6. **`test/`** - no structural changes; FakeInferenceEngine still returns text.

### Tool definition

```dart
// lib/services/inference/tool_definitions.dart
import 'package:flutter_gemma/flutter_gemma.dart';

/// Tool definition for structured tutor responses.
///
/// When used with ToolChoice.required, forces the model to return a
/// FunctionCallResponse with args matching the TutorResponse schema.
const tutorResponseTool = Tool(
  name: 'tutor_response',
  description: 'Provide a structured language correction and conversational reply.',
  parameters: {
    'type': 'object',
    'required': ['correction', 'conversation'],
    'properties': {
      'correction': {
        'type': 'object',
        'required': ['content', 'translation', 'errors'],
        'properties': {
          'content': {'type': 'string'},
          'translation': {'type': 'string'},
          'errors': {
            'type': 'array',
            'items': {
              'type': 'object',
              'required': ['original', 'corrected', 'explanation'],
              'properties': {
                'original': {'type': 'string'},
                'corrected': {'type': 'string'},
                'explanation': {'type': 'string'},
              },
            },
          },
        },
      },
      'conversation': {
        'type': 'object',
        'required': ['content', 'translation'],
        'properties': {
          'content': {'type': 'string'},
          'translation': {'type': 'string'},
        },
      },
    },
  },
);
```

### Prompt template change

With tool calling, the prompt no longer needs to say "Output ONLY the JSON object".
The system instruction focuses on behavior; the schema is expressed in the Tool
definition. A `tutor_response/v2.txt` would remove the JSON format block.

### Fallback behavior

If the model returns `TextResponse` instead of `FunctionCallResponse` (parse failure
inside flutter_gemma), the engine returns the raw text. The existing
`StructuredOutputParser` + `JsonExtractor` pipeline attempts extraction. This gives
graceful degradation identical to the current text-only flow.

---

## Open questions

1. Should `ToolCallingRequest.tool` carry the flutter_gemma `Tool` type directly, or
   should we define our own schema representation to avoid leaking the plugin type?
   ANSWER: we can use the gemma tool, if in the future we want to support multiple plugins we can create an abstraction layer then or remap from gemma to the other plugin format, not important to solve upfront
2. Should the system instruction (prompt template v2) still include the schema as
   documentation for the model, or rely entirely on the tool definition?
   ANSWER: needs experimentation, see if the model can follow the tool schema without it being in the prompt
3. Do we upgrade flutter_gemma to 0.14+ (for 2s init) as part of this work, or keep
   0.13.6 and upgrade separately?
   ANSWER: we can upgrade as initial part of this work, to be sure we are on the latest version
4. How do we handle the `maxFunctionBufferLength` - hardcode 2048 or make configurable?
   ANSWER: configurable. explain how and where
5. Should we load the tool schema from asset JSON (reusing `tutor_response_schema.json`)
   or keep it as a Dart const?
   ANSWER: whichever is cleaner. is there a way to derive json schema from the class definition?

## additional options

### opt 1: generate_with_schema()

we can change in `StructuredInferenceEngine`

```dart
    final result = await structuredEngine.generate(
      InferenceRequest(prompt: prompt),
    );
```

```dart
    final result = await structuredEngine.generate(
      prompt = prompt,
    );
    final result = await structuredEngine.generate_with_schema(
      prompt = prompt,
      schema = tutor_response_schema.json
    );
```

and let the structured engine build the `InferenceRequest` or `ToolCallingRequest` 

but then how can we be sure that the `final InferenceEngine engine;` in the structured engine will be able to handle a `ToolCallingRequest`?

analyze this approach and explore pros and cons,
create a new option section if it's different than the others,
expand one existing section with an additional sub-section of the closer one

### opt 2: separate engine

the core point is that InferenceToolEngine lives closer to the conceptual level of StructuredInferenceEngine
it gives back a generic Map instead of the `<T>` but it is still more structured than the text-based InferenceEngine
which i guess is option B
