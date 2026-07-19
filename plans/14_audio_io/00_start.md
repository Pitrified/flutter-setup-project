---
status: draft
---

# Audio input and output - options brainstorm

Status: brain dump / start note. Nothing implemented yet, no phases derived.
Research dives, if needed, go in sibling files `01.1_<topic>.md`, `01.2_<topic>.md`, ...

Original idea: add audio input (user speaks in the target language) and audio output
(tutor replies are spoken).
Options to weigh: local vs cloud vs self-hosted, sync vs stream,
"just use Gboard voice typing" as the zero-effort input,
or a transcriber we control that can be biased toward the current topic.

App context that constrains the choice:

- Language tutoring: the user speaks a language they are *bad at*, with an accent,
  hesitations, and mixed-in native words. Generic dictation models are trained on fluent speakers,
  so recognition quality on learner speech is the core risk for every input option.
- Two inference engines already exist (on-device Gemma/Qwen via flutter_gemma, OpenAI cloud).
  Any cloud audio option inherits the key-distribution problem being worked in
  [`../13_key_distribution/00_start.md`](../13_key_distribution/00_start.md);
  the box proxy planned there could front audio APIs too.
- A self-hosted Linux box behind a Cloudflare tunnel is available for self-hosted options.
- The topic picker and CEFR level (phase 09) give us per-conversation context
  that a biasable transcriber could exploit.

---

## How to read the options

The choices are not one flat list of alternatives. They sit on separate axes,
and a full design picks one cell per axis:

| Axis | Values | Notes |
|------|--------|-------|
| A. Direction | input (STT) / output (TTS) | Independent decisions; can ship input first, output later, and mix tiers (e.g. cloud STT + local TTS). |
| B. Where it runs | on-device / cloud API / self-hosted box | Same trichotomy as the LLM engines. Cloud implies key distribution; self-hosted implies box uptime and latency; on-device implies model size and quality limits. |
| C. Delivery | sync (whole utterance / whole reply) / streaming (partials / chunked playback) | Sync is simpler and fine for a turn-based tutor; streaming matters only if we want live captions while speaking or speech that starts before the LLM finishes. |
| D. Integration depth (input only) | keyboard-level / app-level | Gboard voice typing is keyboard-level: zero code, zero control. Everything else is app-level: mic permission, recording, UI. |
| E. Topic biasing (input only) | none / language hint only / prompt or phrase biasing | Only some engines expose a biasing hook. This is a property of the chosen engine, not a separate option. |
| F. Transcript or direct audio | transcribe then feed text / feed audio straight to a multimodal LLM | Direct audio collapses STT into the LLM call. It is a different architecture, not just another STT engine. |

Alternatives within one axis exclude each other; axes combine freely
(with a few impossible cells, e.g. Gboard cannot be biased or streamed to the app).

Candidate bundles, cheapest first:

1. **Zero-code**: Gboard voice typing in (D=keyboard), system TTS out. Ship today, learn from usage.
2. **App-level local**: speech_to_text plugin in, flutter_tts out. Offline, free, no biasing.
3. **Biased cloud**: OpenAI transcription (topic-biased prompt) in, OpenAI TTS out, both through the box proxy from folder 13.
4. **Self-hosted**: faster-whisper + Piper on the box. Full control, no per-use cost, box becomes a dependency.
5. **Audio-native**: multimodal LLM hears and speaks directly (Realtime API, or Gemma 3n audio-in on-device). Furthest from current architecture.

---

## Input options (STT)

### I1. Gboard voice typing (keyboard-level)

The user taps the mic on their keyboard; text lands in our existing TextField.

- Effort: zero. Works today.
- Runs: on-device (Gboard's own models), free, offline.
- Biasing: none. No API surface at all; we never see audio.
- Delivery: streaming into the text field from the user's view, sync from ours.
- Limits: no control over language auto-detection, no confidence scores,
  no pronunciation signal, UX depends on the user's keyboard choice.
- Verdict candidate: the baseline. Costs nothing to "support" and tells us
  whether learner speech recognition is even acceptable before we invest.

### I2. Platform SpeechRecognizer via `speech_to_text` plugin (on-device)

Android's built-in recognizer (Google speech services) driven from the app.

- Effort: low. Mature plugin, mic permission + record button + partial results stream.
- Runs: on-device (downloads per-language packs), free, mostly offline.
- Biasing: language/locale selection only; no phrase or topic hints on Android.
- Delivery: streaming partials.
- Limits: same underlying models as Gboard, so recognition quality is similar;
  quality on learner speech unknown; per-language availability varies.
- Gain over I1: in-app UX (our own mic button), locale forced to the target language,
  partial results we can display.

### I3. On-device Whisper (whisper.cpp family)

Ship a small Whisper model in the app (e.g. via a whisper.cpp Flutter binding).

- Effort: medium-high. Native binding, model download (~75-500 MB), ABI concerns
  (we already fought armeabi-v7a exclusions for flutter_gemma).
- Runs: on-device, free, offline.
- Biasing: yes - Whisper's `initial_prompt` accepts free text;
  we can inject the current topic, expected vocabulary, and target language.
  This is the "hand rolled transcriber biased to the topic" option in local form.
- Delivery: sync per utterance (streaming exists but is hacky at this model size).
- Limits: tiny/base models are weak on accented non-English speech;
  small/medium may be too slow next to an LLM already occupying the device.
- Research dive candidate: which binding (whisper_flutter_new? sherpa-onnx? fonnx?),
  model size vs latency on our device tier. -> future `01.1`.

### I4. Cloud transcription API

OpenAI `whisper-1` / `gpt-4o-transcribe` (or Google, Deepgram, AssemblyAI).

- Effort: low-medium. Record to file, one HTTP call; we already have OpenAI plumbing.
- Runs: cloud. Costs per minute (order of $0.006/min for whisper-1). Needs network.
- Key distribution: inherits folder 13 wholesale; the box proxy should front this endpoint.
- Biasing: yes - `prompt` parameter (Whisper-style) or phrase hints depending on vendor.
  Best recognition quality of all options, including on accented speech.
- Delivery: sync per utterance; OpenAI Realtime or Deepgram give true streaming if wanted.
- Limits: privacy (audio leaves the device), cost, offline story gone for audio.

### I5. Self-hosted STT on the box

faster-whisper (or whisper.cpp server) behind the existing Cloudflare tunnel.

- Effort: medium. Server setup is easy; app-side is the same HTTP call as I4.
- Runs: self-hosted. No per-use cost, audio stays on our infrastructure.
- Biasing: yes, same `initial_prompt` mechanism, and we control decoding fully
  (temperature, beam size, vocabulary tricks).
- Delivery: sync; streaming possible with more server work.
- Limits: box CPU-only(?) latency for medium models, single point of failure,
  fine for private alpha but not a public-scale answer.
- Synergy: the same box proxy from folder 13 could route `/transcribe` locally
  and `/chat` to OpenAI - one auth story for both.

### I6. Direct audio into a multimodal LLM (skip transcription)

Send the user's audio straight to a model that hears.

- Cloud form: OpenAI Realtime / gpt-4o-audio - the model hears the learner directly,
  which could enable pronunciation feedback no transcript can carry.
- On-device form: Gemma 3n has audio input; flutter_gemma support status unknown -> research dive `01.2`.
- Effort: high. Different API shape, breaks the text-transcript conversation model,
  structured-output pipeline needs rethinking.
- Verdict candidate: not for the first iteration, but the only path to
  pronunciation-aware tutoring; keep on the map.

---

## Output options (TTS)

### O1. System TTS via `flutter_tts` (on-device)

- Effort: low. Mature plugin over Android TextToSpeech.
- Runs: on-device, free, offline. Per-language voices depend on the device's installed TTS engine.
- Delivery: sentence-level chunking is easy, so it pairs well with our streaming LLM UI
  (speak sentences as they complete).
- Limits: robotic-to-decent quality depending on device/language; pronunciation of the
  target language is usually correct, which is what a tutor needs most.

### O2. Cloud TTS

OpenAI `gpt-4o-mini-tts` / `tts-1`, Google, ElevenLabs.

- Effort: low-medium (HTTP call + audio playback via just_audio or similar).
- Runs: cloud, per-character/minute cost, needs network + folder 13 key story.
- Quality: natural voices, controllable pacing ("speak slowly and clearly" style instructions
  on gpt-4o-mini-tts fits a tutor well).
- Delivery: sync per reply, or chunked/streamed for lower latency.

### O3. Self-hosted TTS on the box

Piper (fast, many languages, light) or Kokoro (higher quality) behind the tunnel.

- Effort: medium. Same shape as I5; could live in the same service.
- Quality: Piper is between system TTS and cloud voices; per-language coverage to verify.

### O4. Audio-native LLM output

The Realtime-API end of I6: the model speaks directly. Same verdict - map it, defer it.

---

## Leanings (not decisions)

- Ship bundle 1 (Gboard + system TTS) immediately: document it, add a "speak replies" toggle
  using flutter_tts, and learn whether keyboard STT survives learner speech.
- The real fork is I2 vs I4/I5: is unbiased on-device recognition good enough for learners,
  or does topic biasing measurably help? That is testable cheaply
  (record sample learner audio once, run it through each engine offline, compare).
- Output is lower stakes: O1 first, O2/O3 as a quality upgrade later, independent of the input choice.
- Any cloud/self-hosted choice should wait for or co-design with folder 13's proxy
  rather than inventing a second auth path.

## Open questions

- Q1: Is "fully offline after model download" still a hard requirement, or has the OpenAI
  engine already relaxed it enough that cloud/self-hosted audio is acceptable?
  ANS: ...
- Q2: Which target languages must audio support first? (Determines voice/model availability
  for system TTS, Piper, and SpeechRecognizer language packs.)
  ANS: ...
- Q3: Is pronunciation feedback a goal (pushes toward I6/audio-native eventually),
  or is audio purely an input/output convenience over the existing text loop?
  ANS: ...
- Q4: Latency tolerance: is "speak, wait 2-4 s, see transcript" acceptable (sync),
  or do we want live partial captions while speaking (streaming, narrows the field to I2/I4-realtime)?
  ANS: ...
- Q5: For the biasing experiment, can we collect a small set of real learner utterances
  (you speaking the target language) to benchmark engines against, and roughly how many topics
  should the bias prompt cover?
  ANS: ...
- Q6: Should the box proxy (folder 13) be designed now to front audio endpoints too,
  or kept chat-only and extended later?
  ANS: ...
