# Phase 03 Audit: Implementation vs Specifications

## Summary

Several discrepancies found and resolved. See RESOLUTION tags below.

---

## 1. CRITICAL: Structured Output Schema Mismatch

### ANSWER: do it
### RESOLUTION: Fixed. TutorResponse rewritten to match spec exactly.

Models now: `TutorResponse` -> `CorrectionBlock` (content, translation, errors[]) + `ConversationBlock` (content, translation).
`CorrectionError` has `original`, `corrected`, `explanation`, `rule?`.
Fixture JSON updated. Tests pass.

---

## 2. MEDIUM: Riverpod Provider Style

### ANSWER: ok, document rationale
### RESOLUTION: Done. GoRouter provider has doc comment explaining why manual Provider
is acceptable (declarative config, common Flutter pattern). Future providers will use @riverpod.

---

## 3. LOW: ConversationMessage Missing Fields

### ANSWER: ok, update specs to clarify that `tutorResponse` includes correction data.
### RESOLUTION: Done. Functional spec Section 9 now maps Hive boxes to Dart models explicitly.

---

## 4. LOW: Missing `settings` and `model_metadata` Persistence Models

### ANSWER: no, check again. What is the difference between ModelInfo and model_metadata?

### RESOLUTION: There is no duplication. `ModelInfo` IS the Dart model stored in the
`model_metadata` Hive box. The spec said "model_metadata" (box name) and we implemented
`ModelInfo` (Dart class). Same thing, different naming levels. Spec updated to show the
mapping: `model_metadata` box -> `ModelInfo` model.

`Settings` model still needs to be created (Phase 04/05 scope).

---

## 5. INFORMATIONAL: Extra `rule` Field in CorrectionBlock

### ANSWER: keep it, update spec
### RESOLUTION: Done. Spec Section 8 now includes `rule` as optional field with description.

---

## All issues resolved. Tests pass, analysis clean.
