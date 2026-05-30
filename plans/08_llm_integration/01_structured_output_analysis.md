# Constrained decoding

_Research updated: 2026-05-30. Plugin version researched: 0.16.2 (project currently on 0.13.6)._

---

## Bottom line

**True FSM-based constrained decoding does not exist in flutter_gemma.**
The equivalent is the **function calling / tool API** with `ToolChoice.required`.
Qwen3 0.6B supports this fully, and it is already available in the current project
version (0.13.6).

---

## What "constrained decoding" usually means

In server-side runtimes (llama.cpp + Outlines, vLLM, Guidance), constrained decoding
compiles a JSON Schema into a finite state machine (FSM). At each generation step the
sampler masks every token that would leave the FSM in an invalid state. The result is
100% schema-compliant output regardless of model quality.

---

## What flutter_gemma offers instead

Neither MediaPipe (`.task`) nor LiteRT-LM (`.litertlm`) expose a grammar/constrained-
sampling hook. The plugin's structured-output story is entirely based on **tool calling**
(function calling):

- `Tool(name, description, parameters)` - define a tool whose `parameters` field is a
  JSON Schema map (OpenAI Chat Completions style).
- `createChat(tools: [...], toolChoice: ToolChoice.required)` - `ToolChoice.required`
  forces the model to always emit a tool call, never free text. This is the closest
  analogue to constrained decoding available in the plugin.
- The plugin returns `FunctionCallResponse(name, args)` where `args` is the parsed
  `Map<String, dynamic>`.

This is **not** token-level masking. It relies on the model's instruction-following
quality. Small models may still occasionally produce malformed JSON (which the plugin
then fails to parse and returns as a `TextResponse` instead).

---

## Qwen3 0.6B status in flutter_gemma

### Current version (0.13.6 - already in project)

| Feature | Status |
|---|---|
| `ModelType.qwen3` | Added in 0.13.6 - available now |
| Function calling | Supported via `<tool_call>` format (`qwen_function_call_format`) |
| `/no_think` suppression | Automatic when `isThinking: false` - faster TTFT, no `<think>` bleed into output |
| `ToolChoice.required` | Added in 0.12.8 - available now |
| `maxFunctionBufferLength` | Added in 0.13.6 - use for schemas with long field names |
| Model file needed | `.litertlm` from `litert-community/Qwen3-0.6B` on HuggingFace |

### Latest version (0.16.2 - published 2026-05-30)

Notable improvements over 0.13.6 that are relevant to this use case:

- **0.14.0**: Android `.litertlm` now uses Dart FFI instead of the Kotlin JVM path.
  Engine init dropped from ~10-15 s to ~2 s. `.task` models on Android still use
  MediaPipe.
- **0.14.1**: Gemma 4 gets native SDK function calling (not relevant for Qwen3, but
  the `SdkResponseParser` improvements clean up escape-token leakage in chat history
  which affects all models).
- **0.15.1**: `temperature`/`topK`/`topP` silently ignored on NPU backend (NPU uses
  greedy sampling only).
- **0.16.2**: Concurrent sessions (`openSession`), active backend reporting.

No version added true grammar/FSM constrained decoding.

---

## How to use tool calling for structured output (Qwen3 0.6B)

```dart
import 'package:flutter_gemma/flutter_gemma.dart';

// 1. Define the output schema as a Tool.
//    The model MUST call this tool (ToolChoice.required), so args == your JSON.
const correctionTool = Tool(
  name: 'provide_correction',
  description: 'Structured language correction and conversational reply.',
  parameters: {
    'type': 'object',
    'properties': {
      'corrections': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'original': {'type': 'string'},
            'corrected': {'type': 'string'},
            'explanation': {'type': 'string'},
          },
          'required': ['original', 'corrected', 'explanation'],
        },
      },
      'reply': {'type': 'string'},
    },
    'required': ['corrections', 'reply'],
  },
);

// 2. Install the model (one time).
await FlutterGemma.installModel(modelType: ModelType.qwen3)
    .fromNetwork('https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/...')
    .install();

// 3. Create chat with tool and ToolChoice.required.
final model = await FlutterGemma.getActiveModel(maxTokens: 2048);
final chat = await model.createChat(
  systemInstruction: 'You are a Portuguese language tutor...',
  tools: [correctionTool],
  toolChoice: ToolChoice.required,
  isThinking: false,           // suppresses <think> block, faster response
  maxFunctionBufferLength: 2048, // increase if args are long
);

// 4. Send a message and parse the structured response.
await chat.addQueryChunk(Message.text(text: userInput, isUser: true));

await for (final response in chat.generateChatResponseAsync()) {
  if (response is FunctionCallResponse) {
    // response.name == 'provide_correction'
    // response.args == Map<String, dynamic> with 'corrections' and 'reply'
    final corrections = response.args['corrections'] as List;
    final reply = response.args['reply'] as String;
    // ...
  }
  // If response is TextResponse here, the model ignored the tool (parse failure).
  // Log it and retry or fall back to regex parsing.
}
```

---

## Reliability notes

- `ToolChoice.required` significantly improves consistency but does not guarantee
  it at the token level. Observed failure modes with Qwen3 0.6B:
  - Missing required fields (especially nested objects).
  - The `corrections` array returned as a JSON string instead of an array.
  - Rare: model outputs a `<think>` preamble despite `isThinking: false` on the first
    turn after a model load - add a thin retry wrapper.
- Keeping the schema **flat or one level of nesting** dramatically improves
  parse reliability on 0.6B models.
- A tight, explicit system prompt describing each field by name and type helps more
  than schema complexity.
- Qwen3 0.6B scored 0.880 on tool-calling benchmarks (identical to Qwen3 4B), which
  is notably better than Gemma 3 1B (0.600) for this specific task.

---

## Upgrade recommendation

Upgrading from 0.13.6 to 0.16.2 is worthwhile mainly for the **2 s Android engine
init** (was 10-15 s in 0.13.x on the JVM path). No structural API changes affect
the tool-calling flow described above. The `ModelType.qwen3` and `ToolChoice.required`
APIs are stable across versions.

---

## What was contradicting in the earlier draft

`plans/00_drafts/01_llm_local_integration.md` stated:

> "LiteRT-LM / flutter_gemma: supports it for Gemma models via function calling mode"

This conflated two things: (a) FSM constrained decoding (NOT supported) and (b) the
function calling API (supported, and usable for structured output). The word
"constrained decoding" in that draft was loosely used to mean "you can get structured
output somehow". The mechanism is tool calling, not grammar-guided sampling.

## LiteRT-LM's true constrained decoding (not in flutter_gemma)

_Source: https://github.com/google-ai-edge/LiteRT-LM/blob/main/docs/api/cpp/constrained-decoding.md_

LiteRT-LM's C++ API exposes genuine FSM-based constrained decoding. This is real
token-level masking - not instruction following. At each sampling step the engine
queries the constraint's `ComputeBitmap()` method which returns a boolean mask over
the entire vocabulary. Tokens outside the allowed set are zeroed before softmax, so
the model physically cannot produce non-compliant output.

### Which library powers it

The FSM engine is **LLGuidance** (`guidance-ai/llguidance`). LiteRT-LM packages it
as a native shared library: `libGemmaModelConstraintProvider` (`.dylib` on macOS,
`.so` on Android/Linux). This is the same binary that flutter_gemma already bundles -
it is visible in the macOS `Podfile` post-install block as:

```
for base in GemmaModelConstraintProvider LiteRtMetalAccelerator LiteRtTopKMetalSampler
```

So the capability sits right next to the inference engine inside every flutter_gemma
install. The hook to activate it is simply not wired through the Dart API.

### C++ API overview

Two mutually exclusive modes per `Conversation` instance:

**Mode 1 - Tool calling constraint** (easiest):

```cpp
#include "runtime/conversation/conversation.h"

ConversationConfig::Builder builder;
builder.SetEnableConstrainedDecoding(true);
auto config = builder.Build(*engine).value();
```

The engine reads the tool declarations and constrains output to valid tool-call syntax.
This is the C++ equivalent of what flutter_gemma's `ToolChoice.required` attempts to
do at the instruction-following level - except this one enforces it in the sampler.

**Mode 2 - Custom constraint via LLGuidance** (JSON Schema / Regex / Lark grammar):

```cpp
#include "runtime/conversation/conversation.h"
#include "runtime/components/constrained_decoding/llg_constraint_config.h"

ConversationConfig::Builder builder;
builder.SetConstraintProviderConfig(LlGuidanceConfig());
auto config = builder.Build(*engine).value();
auto conversation = Conversation::Create(*engine, config).value();

// Per-request: constrain to a JSON Schema
LlGuidanceConstraintArg constraint_arg;
constraint_arg.constraint_type = LlgConstraintType::kJsonSchema;
constraint_arg.constraint_string = R"({
  "type": "object",
  "properties": {
    "corrections": {"type": "array", "items": {"type": "object", ...}},
    "reply": {"type": "string"}
  },
  "required": ["corrections", "reply"]
})";

auto response = conversation->SendMessage(
    user_message,
    {.decoding_constraint = constraint_arg}
);
```

LLGuidance supports three constraint types:
- `kJsonSchema` - JSON object matching a JSON Schema draft 7+ schema
- `kRegex` - output must match a regular expression
- `kLark` - output must follow a Lark context-free grammar

### Which models support it

Constrained decoding is an **inference engine feature**, not a model property. It
applies to any `.litertlm` model:

| Model | Format | Constrained decoding usable? |
|---|---|---|
| Qwen3 0.6B | `.litertlm` | Yes |
| Gemma 3 1B | `.litertlm` | Yes |
| Gemma 4 E2B/E4B | `.litertlm` | Yes |
| Gemma3n E2B/E4B | `.litertlm` | Yes |
| DeepSeek R1 | `.litertlm` | Yes |
| Any `.task` / `.bin` model | MediaPipe / raw | No - MediaPipe has no constraint hook |

The constraint masks the sampler output regardless of whether the underlying model
was fine-tuned for structured output. A model with no tool-call training can still
produce 100%-valid JSON when constrained by `kJsonSchema`.

### Why it is not reachable from flutter_gemma today

flutter_gemma's Dart FFI layer wraps the **LiteRT-LM C API** (a thin C wrapper around
the C++ internals). As of 0.16.2 the C API does not include `SetConstraintProviderConfig`
or `SetEnableConstrainedDecoding`. These are C++ only.

There is an open feature request: flutter_gemma issue #195 (opened 2026-03-11,
still open, no assignee, no linked PR).

### What it would take to use it from Dart today

Option 1 - Wait: Track issue #195. If merged, flutter_gemma would expose a
`constraintSchema` parameter on `createChat()` or similar.

Option 2 - Custom Flutter plugin: Write a new plugin (Kotlin/C JNI on Android,
Swift/Obj-C on iOS, C++ on desktop) that directly calls the LiteRT-LM C++ API
with `SetConstraintProviderConfig`. Requires distributing `libGemmaModelConstraintProvider`
separately and maintaining JNI glue. This is a multi-week engineering task, outside
the locked dependency policy of `fala`.

Option 3 - Dart FFI directly: Not practical. The C API does not expose constraints.
The C++ API cannot be called directly from Dart FFI (no `extern "C"` wrappers for
the constraint types).

### Decision for fala

Stick with `ToolChoice.required` (see "How to use tool calling" section above).
It covers the use case with acceptable reliability at 0.6B scale. Track issue #195;
if it ships, upgrading to true FSM guarantees would be a low-effort swap.


