# Local LLM Integration Options for Mobile Apps

Here's a comprehensive breakdown of the main options for shipping an app that runs an LLM locally on the user's phone:

---

## On-Device LLM SDKs / APIs for Mobile Developers

### 1. **Google LiteRT-LM / MediaPipe LLM Inference API**
**Platforms:** Android (primary), iOS in progress

Google's LLM Inference API lets you run LLMs completely on-device for Android applications. The MediaPipe LLM Inference API is still available but Google now recommends migrating to LiteRT-LM. It has built-in support for Gemma 3n (the E2B ~2B and E4B ~4B variants).

Models come from **Google AI Edge / Hugging Face** in MediaPipe-compatible format. The API focuses on CPU and GPU to support multiple platforms, and on select premium Android phones, Android AICore can take advantage of hardware-specific neural accelerators.

**Best for:** Android-first apps, Gemma models, minimal integration friction.

---

### 2. **ExecuTorch (PyTorch / Meta)**
**Platforms:** iOS, Android

ExecuTorch is PyTorch's unified solution for deploying AI on-device — from smartphones to microcontrollers. It powers Meta's on-device AI across Instagram, WhatsApp, Quest 3, and Ray-Ban Meta Smart Glasses. It has a 50KB base runtime footprint and supports 12+ hardware backends including Apple, Qualcomm, ARM, and MediaTek. Supported models include Llama 3.x, Qwen 3, Phi-4-mini, and multimodal ones like LLaVA and Whisper.

The Unsloth team also documented a workflow to fine-tune a model and deploy it locally to Pixel 8 and iPhone 15 Pro at ~40 tokens/s using ExecuTorch + TorchAO.

Models come from **Meta / Hugging Face**, exported via PyTorch's own pipeline (no `.onnx` or `.tflite` conversion needed).

**Best for:** Production-grade apps on both platforms, fine-tuned model deployment, teams already in the PyTorch ecosystem.

---

### 3. **MLC-LLM**
**Platforms:** iOS, Android, Web, Desktop

MLC stands for Machine Learning Compilation. It doesn't just compile the model — it also compiles the runtime, which is crucial for mobile/edge devices where every bit of optimization counts. It targets any environment that can run C++.

MLC-LLM is a machine learning compiler and high-performance deployment engine for LLMs, built on top of TVM (Tensor Virtual Machine), supporting various platforms.

Models come from **Hugging Face** (or the MLC model hub), compiled into the MLC format. There's a React Native integration for cross-platform use.

**Best for:** Maximum portability, targeting both iOS and Android with one engine.

---

### 4. **ExecuTorch via React Native ExecuTorch**
**Platforms:** iOS + Android (React Native)

React Native ExecuTorch brings Meta's ExecuTorch AI framework into the React Native ecosystem, enabling developers to run AI models and LLMs locally on mobile devices. It provides a declarative API for on-device inference, allowing you to use local AI models without relying on cloud infrastructure.

**Best for:** RN/Expo shops that want on-device AI without diving into native code.

---

### 5. **Apple MLX** *(iOS/macOS only)*
Apple MLX is an array framework for machine learning research on Apple Silicon, brought to you by Apple ML Research. It's more of a research/prototyping framework than a shipping SDK, but it's the most native option for Apple-only apps.

Models come from **Hugging Face** in MLX format.

**Best for:** iOS-only apps targeting Apple Silicon devices.

---

## Where Do the Models Come From?

| Source | Notes |
|---|---|
| **Hugging Face** | Main hub for GGUF, ONNX, MLX, ExecuTorch-exported models |
| **Google AI Edge** | Gemma models in MediaPipe/LiteRT format |
| **MLC Model Hub** | Pre-compiled MLC models ready to deploy |
| **Meta** | Llama models (require license agreement) |

The typical pattern is: **model downloaded on first launch** (or via in-app prompt), cached locally in the app's storage directory. You manage this yourself in the app — there's no silent background download.

---

## Platform Caveat

Running a full local LLM API server (like Ollama) is an Android-exclusive capability — Apple's iOS sandboxing prevents the equivalent setup on iPhone. For iOS, you need to use embedded SDKs like ExecuTorch, MLC-LLM, or MediaPipe rather than a local server approach.

---

## Quick Recommendation

| Your stack | Best pick |
|---|---|
| React Native / Expo | `react-native-executorch` |
| Native Android | Google LiteRT-LM |
| Native iOS | ExecuTorch or MLX |
| Cross-platform native | MLC-LLM |
| Fine-tuned custom model | ExecuTorch + Unsloth pipeline |

------------------------------

Good questions — Flutter changes the picture a fair bit. Here's the full breakdown:

---

## Flutter Compatibility

### **flutter_gemma** — Best native Flutter option
A Flutter plugin that runs Gemma and other LLMs locally on Android, iOS, Web, and Desktop. Supports `.task` files (MediaPipe format) and `.litertlm` files (LiteRT-LM format, the newer Google standard). Supported models include Gemma 4, Gemma 3n, Qwen3 0.6B, Qwen 2.5, Phi-4 Mini, DeepSeek R1, and SmolLM 135M. This is the **easiest path for Flutter** — pure Dart API, no native glue code needed.

### **LiteRT / tflite_flutter** — Flutter-native, Google-backed
LiteRT (formerly TensorFlow Lite) is the recommended foundation for on-device AI in both Android-native and Flutter apps. The `tflite_flutter` package provides a high-level Dart API for running LiteRT models with GPU delegation for hardware acceleration. For Flutter apps targeting Android, LiteRT-LM specializes in GenAI and LLMs.

### **MLC-LLM** — Possible but manual
MLC exposes a C++ core and a REST-like local server. From Flutter you'd call it via platform channels or FFI. There's no official Flutter package — you'd be writing bridge code yourself.

### **ExecuTorch** — Not Flutter-friendly
ExecuTorch's public API is a C++ header (`text_llm_runner.h`), and the official wrapper is `react-native-executorch`. Flutter integration would require writing a native plugin from scratch — doable but significant work.

### **Apple MLX** — iOS/macOS only, no Flutter package
Same story: research framework, no Dart/Flutter bindings exist.

---

### Summary table

| SDK | Flutter support | Language required |
|---|---|---|
| **flutter_gemma** | ✅ First-class Dart package | Dart only |
| **LiteRT / tflite_flutter** | ✅ Official Flutter package | Dart only |
| **MLC-LLM** | ⚠️ Manual FFI/platform channels | C++ bridge |
| **ExecuTorch** | ❌ No Flutter support | C++ / Swift / Kotlin |
| **Apple MLX** | ❌ Apple only, no bindings | Swift / Python |

**Short answer: `flutter_gemma` is your go-to.** It's the only solution with a proper pub.dev package that actually wraps an on-device inference engine.

---

## What Phone Do You Need?

Here's where it gets interesting. The threshold depends heavily on model size.

**Bare minimum (it loads, even if slow):**
Standard iPhone 16 with 8 GB RAM handles 1B models only. On Android, 6 GB RAM lets you technically run 1–3B models, but it's not practically useful beyond autocomplete.

**Usable minimum (slow but functional chat):**
iPhone 16 Pro (A18 Pro) with 12 GB shared RAM runs Llama 3.2 3B at around 4 tokens/sec. On Android, 8 GB RAM + Snapdragon 8 Gen 2 (2022 flagship) is the useful tier for 3B–7B models.

**Smooth experience:**
Flagship devices achieve 15–30 tokens/sec, mid-range phones 5–15 tokens/sec. That feels like a real chat at 10+ tok/sec. Android devices with Snapdragon X Elite can run 7B models at ~5 tok/sec. iPad Pro M4 hits 15 tok/sec on 7B models.

### Rough phone generation guide

| Experience | Android | iPhone |
|---|---|---|
| Bare minimum | ~2021 mid-range, 6 GB RAM | iPhone 13 (1B only, very slow) |
| Usable (1–3B) | Snapdragon 8 Gen 1, 8 GB (2022) | iPhone 15 / A16 |
| Smooth chat (3B) | Snapdragon 8 Gen 2, 12 GB (2023) | iPhone 16 Pro / A18 Pro |
| Smooth chat (7B) | Snapdragon X Elite, 12 GB+ (2024–25) | iPad Pro M4 |

The key insight for your app: **design around a 1B–3B model** if you want a reasonable share of the installed base to run it. A 7B model today is really only comfortable on 2024–2025 flagships, and practical 7B-level chat on phones is more of a 2027 story.

------------------------------

Yes, there are good options — and the story here is actually more nuanced than just picking by size. The key insight is that **constrained decoding matters more than raw model intelligence** for your use case.

---

## The real trick: constrained decoding

When you send a JSON Schema with constrained decoding enabled, the schema gets compiled into a finite state machine (FSM). At each token generation step, only tokens that keep the output on a valid path through the FSM are allowed — giving you 100% schema compliance, not 99.9%.

This is huge for small models. Even a mediocre 1B model becomes reliably structured when the runtime enforces the schema at the token level. So the question shifts from "can the model produce valid JSON?" to "does my inference engine support constrained decoding?"

- **MLC-LLM**: supports constrained generation
- **LiteRT-LM / flutter_gemma**: supports it for Gemma models via function calling mode
- **ExecuTorch**: grammar-based constrained output is on the roadmap but not fully there yet

---

## Best models for your use case

### 🥇 Qwen3 0.6B — surprising standout
Qwen3 0.6B scored 0.880 on a tool-calling/structured output benchmark — identical to Qwen3 4B, and better than Qwen3 1.7B (0.670). Parameter count is a weak predictor; architecture and training data matter more. It's already supported in `flutter_gemma` and available in 4-bit quantized form for mobile.

### 🥈 Gemma 3 1B / Gemma 3n E2B
Gemma 4 was explicitly designed for on-device agents, with built-in system-instruction support, tool-use capabilities, and native structured JSON output. The 1B and E2B variants are the smallest in the family and are the best-supported in the Flutter ecosystem via `flutter_gemma`.

Gemma 3 1B scored 0.600 on the tool-calling benchmark — functional, but noticeably weaker than Qwen3 0.6B on structured output tasks.

### 🥉 SmolLM2 1.7B
A HuggingFace model designed for edge deployment. Decent at following simple JSON schemas, but SmolLM3 (similar family) actually scored worse when a strict parser was applied — it was calling tools on prompts where it shouldn't. Fine for simple fixed schemas, less reliable with complex ones.

### FunctionGemma 270M — honorable mention
FunctionGemma is a 270M model fine-tuned specifically for function calling. It's the fastest (476ms) with perfect restraint behavior, but falls into keyword traps on harder prompts. If your schema is very simple and fixed, this is worth a look — it's tiny.

---

## Practical recommendation for your case

Since you just need consistent JSON for parsing (not deep reasoning), the winning combo is:

**Qwen3 0.6B + constrained decoding** — it punches way above its weight on structured output, runs on basically any modern-ish phone, and is available in flutter_gemma. Keep your JSON schema simple (flat or one level of nesting), write a tight system prompt describing exactly the expected fields, and let the FSM-based constrained decoding do the heavy lifting.

If you're locked into the Google/Flutter ecosystem and want the easiest integration, **Gemma 3n E2B** is the safer official pick with better tooling support, even if Qwen3 0.6B technically scores higher on structured output benchmarks.

------------------------------

Good framing. Let me break this down across two layers: what `flutter_gemma` gives you natively, and how to build the "pydantic/structured output" safety net on top of it.

---

## What flutter_gemma gives you natively

The plugin exposes a simple async generation API — you send a string prompt, get a string back. There's no built-in schema enforcement at the Dart level. The constrained decoding happens inside LiteRT-LM's C++ layer **only if** you use the function calling / JSON mode that the underlying engine supports for Gemma models.

So out of the box you'd be doing prompt engineering + hoping — which is exactly what you want to avoid.

---

## The safety stack you want to build

Think of it as three layers, from weakest to strongest:

### Layer 1 — Prompt discipline (necessary but not sufficient)
A tight system prompt that:
- States the exact JSON schema inline (field names, types, constraints)
- Shows a one-shot example of a valid output
- Explicitly says "respond with only valid JSON, no prose, no markdown fences"

This helps but doesn't guarantee anything on a 0.6B model.

### Layer 2 — Constrained decoding (the real guarantee)
This is your FSM-level enforcement. For flutter_gemma + Gemma/LiteRT models, you enable **function calling mode** when initializing the model. Under the hood this compiles your schema into a token-level constraint so invalid JSON is structurally impossible to generate.

```dart
final model = await GemmaLocalModel.init(
  modelPath: '...',
  maxTokens: 512,
  // This enables constrained/function-calling mode
  functionCallingConfig: FunctionCallingConfig(
    mode: FunctionCallingMode.any,
    functions: [yourJsonSchema],
  ),
);
```

This is your closest equivalent to OpenAI's `response_format: { type: "json_schema", strict: true }`. The guarantee is at the inference level, not post-hoc.

### Layer 3 — Dart-side validation (your final safety net)
Even with constrained decoding, you want a typed parsing layer in Dart — the equivalent of Pydantic. The standard pattern:

```dart
// Define your schema as a Dart class
class LLMResponse {
  final String intent;
  final double confidence;
  final List<String> tags;

  LLMResponse({
    required this.intent,
    required this.confidence,
    required this.tags,
  });

  factory LLMResponse.fromJson(Map<String, dynamic> json) {
    // Validate types and required fields here
    return LLMResponse(
      intent: json['intent'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      tags: List<String>.from(json['tags']),
    );
  }
}

// Parse with fallback
LLMResponse? parseResponse(String raw) {
  try {
    final decoded = jsonDecode(raw);
    return LLMResponse.fromJson(decoded);
  } catch (e) {
    return null; // trigger retry or fallback
  }
}
```

You can use `json_serializable` + `freezed` to generate the boilerplate, which gets you very close to the Pydantic DX.

---

## The retry loop (what LangChain actually does under the hood)

LangChain's structured output with Pydantic is basically:
1. Call the model
2. Try to parse
3. If it fails, re-prompt with the error message appended
4. Retry up to N times

You can replicate this simply:

```dart
Future<LLMResponse?> generateStructured(String userPrompt, {int maxRetries = 3}) async {
  String? lastError;

  for (int i = 0; i < maxRetries; i++) {
    final prompt = buildPrompt(userPrompt, previousError: lastError);
    final raw = await gemmaModel.generate(prompt);

    final result = parseResponse(raw);
    if (result != null) return result;

    lastError = 'Previous output was invalid. Error: failed to parse field X.';
  }

  return null; // or throw, or return a default
}
```

On a small model with constrained decoding enabled, you should almost never hit retries. They're a backstop for edge cases.

---

## Summary of the full stack

| Layer | What it does | Dart equivalent |
|---|---|---|
| System prompt | Guides the model toward the schema | — |
| Constrained decoding (LiteRT) | Structurally enforces valid JSON | `strict: true` in OpenAI API |
| `freezed` + `json_serializable` | Typed parsing + validation | Pydantic model |
| Retry loop | Handles any remaining edge failures | LangChain's `.with_structured_output()` |

The honest caveat: **constrained decoding in flutter_gemma is only well-supported for Gemma models** (Google controls both ends). If you switch to Qwen3 0.6B, you'd be relying more on layers 1 and 3 unless you use MLC-LLM as your backend instead, which has more mature grammar-based constrained generation but requires more integration work. For your use case, **Gemma 3n E2B + flutter_gemma + freezed** is the most pragmatic path to a Pydantic-level safety guarantee.

------------------------------

## LiteRT-LM

Google's own inference runtime, built on top of TensorFlow Lite. It lives **inside the Android/iOS OS layer** — on Pixel phones and newer Android devices, it can delegate to the on-chip NPU transparently. You don't ship the runtime yourself; it's part of the platform (Android AICore) or bundled as an AAR.

The constrained decoding is implemented as a **grammar sampler** written in C++ that sits between the logits and the token selector. When you pass a JSON schema, it compiles it to an allowlist of valid next tokens at each step. You never touch this code — flutter_gemma wraps it entirely.

**Your app calls:** Dart → flutter_gemma plugin → LiteRT-LM C++ → GPU/NPU

---

## MLC-LLM

A compiler + runtime built on Apache TVM. The idea is that the model itself gets compiled — not just loaded — so the compute graph is fused and optimized for the specific chip. It's model-agnostic (Qwen, Llama, Gemma, etc.) and ships its own runtime that you bundle into the app yourself.

Constrained decoding here is called **XGrammar** — a standalone grammar engine that MLC integrates. It supports full JSON Schema, context-free grammars, and regex. More flexible than LiteRT-LM's sampler, and works with any model, not just Gemma.

**Your app calls:** Dart (via FFI/platform channel) → MLC runtime C++ + XGrammar → GPU

---

## The practical difference for you

| | LiteRT-LM | MLC-LLM |
|---|---|---|
| Flutter integration | `flutter_gemma` pub package | Manual FFI bridge (no pub package) |
| Model support | Gemma family primarily | Any model (Qwen3 0.6B, Llama, etc.) |
| Constrained decoding | Yes, for Gemma function calling | Yes, via XGrammar — more robust |
| You ship the runtime? | No, platform-provided | Yes, bundled in your app (~30MB) |
| Integration effort | Low | High |

If you go with Gemma and want the easy path → LiteRT-LM via flutter_gemma. If you want Qwen3 0.6B or need more robust schema enforcement → MLC-LLM, but you're writing native plugin glue code yourself.

------------------------------
