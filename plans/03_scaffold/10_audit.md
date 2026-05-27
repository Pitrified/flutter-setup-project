# Phase 03 Audit: Implementation vs Specifications

## Summary

Several discrepancies found between what was implemented and what the docs prescribe.
Most critical is the **structured output schema mismatch**.

---

## 1. CRITICAL: Structured Output Schema Mismatch

### Functional spec (docs/functional-specs.md Section 8):

```json
{
  "correction": {
    "content": "corrected sentence in target language",
    "translation": "English translation",
    "errors": [
      {
        "original": "what user wrote",
        "corrected": "fixed version",
        "explanation": "brief grammar/vocab note"
      }
    ]
  },
  "conversation": {
    "content": "tutor reply in target language",
    "translation": "English translation"
  }
}
```

### What was implemented (lib/models/tutor_response.dart):

```dart
class TutorResponse {
  String reply;
  List<CorrectionBlock> corrections;
}

class CorrectionBlock {
  String original;
  String corrected;
  String explanation;
  String? rule;
}
```

### Differences:

| Concern | Spec | Implementation | Impact |
|---------|------|----------------|--------|
| Top-level structure | `correction` + `conversation` objects | Flat `reply` + `corrections` list | **Schema mismatch** |
| Translation field | Both blocks have `translation` (English) | Missing entirely | Users won't see English translations |
| Correction content | `correction.content` (full corrected sentence) | Not present (only per-error corrections) | No overall corrected sentence shown |
| Conversation content | `conversation.content` | `reply` (renamed) | Minor rename, same purpose |
| Error object | `original`, `corrected`, `explanation` | Same + extra `rule` field | `rule` is extra (not in spec) |
| Empty correction | `correction.errors` is empty list | `corrections` is empty list | Equivalent behavior |

### Fix required:

Rewrite `TutorResponse` and `CorrectionBlock` to match the spec schema exactly.
This affects: models, fixtures, tests, Phase 04 plans (structured output parser, prompt).

### ANSWER: do it

---

## 2. MEDIUM: Riverpod Provider Style

### Coding standards (docs/coding-standards.md Section 3):

> Use `@riverpod` annotation (code generation)

### What was implemented:

Manual `Provider<GoRouter>((ref) {...})` and `StateProvider<bool>((ref) => false)`.

### Impact:

Not blocking (manual providers work), but inconsistent with stated conventions.
Should use `@riverpod` annotation for consistency once we have real providers.
The GoRouter provider is a special case (often manual in practice).

### Recommendation:

Accept manual providers for GoRouter (common pattern), but use `@riverpod` for all
future providers starting in Phase 04.

### ANSWER: ok, document rationale

---

## 3. LOW: ConversationMessage Missing Fields

### Functional spec (Section 9):

> conversations box: List of messages: role, content, timestamp, **correction data**

### What was implemented:

```dart
class ConversationMessage {
  String id;
  MessageRole role;
  String content;
  DateTime timestamp;
  TutorResponse? tutorResponse;  // This covers "correction data"
}
```

### Assessment:

This actually maps correctly. `tutorResponse` contains the correction data.
However, once TutorResponse is fixed (issue #1), the field remains valid.

**No change needed here.**

### ANSWER: ok, update specs to clarify that `tutorResponse` includes correction data.

---

## 4. LOW: Missing `settings` and `model_metadata` Persistence Models

### Functional spec (Section 9):

| Hive box | Contents |
|----------|----------|
| conversations | messages |
| settings | Selected language, CEFR level, prompt version |
| model_metadata | File path, version, download timestamp, compatibility |

### What was implemented:

Only the `Conversation` model exists. No `Settings` or `ModelMetadata` freezed models.

### Impact:

These are Phase 04/05 concerns. `ModelInfo` partially covers `model_metadata`.
`Settings` model still needs to be defined.

### Recommendation:

Add `Settings` model in Phase 04 or 05. `ModelInfo` is close enough to spec.

### ANSWER: no, check again.

what is the difference between the implemented `ModelInfo` and the spec's `ModelMetadata`?
Why are two of them existing?

---

## 5. INFORMATIONAL: Extra `rule` Field in CorrectionBlock

The implemented `CorrectionBlock` has an optional `rule` field not in the spec.
This is additive (not contradictory) and may be useful for categorizing errors.

### Recommendation:

Remove it to match spec exactly, or update the spec to include it.

### ANSWER: keep it, update spec

---

## Impact on Phase 04 Plans

The schema mismatch (issue #1) impacts these Phase 04 plans:

| Plan | Impact |
|------|--------|
| 03_structured_output.md | Parser references wrong model classes |
| 01_fake_inference_engine.md | Fixture JSON format wrong |
| 06_prompt_manager.md | Prompt template references wrong schema |

All three need their code examples updated once the models are fixed.

---

## Recommended Fix Order

1. Fix `TutorResponse` model to match spec schema
2. Update fixture JSON file
3. Update test
4. Update Phase 04 plan code examples
5. Run `build_runner` + `flutter analyze` + `flutter test`
