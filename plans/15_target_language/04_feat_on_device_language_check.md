---
status: discarded
---

# Phase 4 - On-device language check

**Discarded 2026-09-24, before any of it ran.** Q5 was answered "local models are soon to be
dismissed, too shaky and slow, we target cloud main for now", which removes the thing this phase
existed to decide: there is no shipped-set gate, because the set is what the cloud engine handles.
The file stays as the record of a measurement that was planned and then made pointless by a product
decision. The wider question it raises is
[`../16_cloud_first_engine/00_start.md`](../16_cloud_first_engine/00_start.md).

The plan as it stood:

## Overview

Measure whether Qwen3-0.6B is usable as a tutor in each candidate language, and let the answer decide
the shipped set. Needs the Pixel 7 Pro, so it runs from a g7 session, not from the box.
Context: [`00_start.md`](00_start.md) Q5. Depends on phase 3 only for convenience: the language can
be switched from the UI by then.

Draft until Q2 and Q5 are answered, since they define what is being measured and how many languages.

## Goals

1. A recorded verdict per candidate language for the on-device engine.
2. A shipped set that excludes languages the small model gets wrong.

## Plan

- Fixed script of learner turns per language: a sentence with an obvious agreement error, one with a
  wrong preposition, one correct sentence (the model must not invent a correction), and one
  open-ended reply, so the same input is compared across languages.
- Run each through the on-device engine on the device, and through the OpenAI engine as the reference
  for what a correct answer looks like.
- Record per language: does it reply in the right language, does it correct the planted error, does it
  hallucinate an error in the correct sentence, and does the JSON parse. Counts, not impressions.
- Decide per language: ship, ship with a warning on the picker, or leave out of the enum.

## Out of scope

- Improving the model or the prompt for a weak language. If a language fails, it does not ship in
  this effort; a prompt-tuning pass is separate work.
- Cloud engine quality, which is assumed adequate for the major European languages.

## Done when

- Every candidate language from Q2 has a recorded verdict in this file, with the date and the device.
- The enum matches those verdicts.
