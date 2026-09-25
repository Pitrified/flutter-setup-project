---
status: done
---

# Phase 5 - Docs, store listing, naming

## Overview

The outward-facing text, rewritten once, now that TL6 fixes which languages the app supports.
Context: [`00_start.md`](00_start.md) Q6.

Q6 answered: keep the name `fala`, make the copy language-neutral. So this is a copy edit, and it no
longer waits on the discarded phase 4, since the shipped set is known from TL6.

## Goals

1. No user-facing or contributor-facing text claims the app is Portuguese-only.
2. The store listing states what the app supports, matching the shipped set.

## Plan

- [`pubspec.yaml:2`](../../pubspec.yaml) description.
- [`docs/functional-specs.md`](../../docs/functional-specs.md) lines 7, 11 and 75: the "Target
  language" row becomes the setting and its default, and the flow description stops naming Portuguese.
- [`docs/prompt-engineering.md`](../../docs/prompt-engineering.md) lines 137 to 147: the guidance is
  written in terms of Portuguese and should be written in terms of the target language, with
  Portuguese as the worked example.
- [`docs/google-play-private-alpha.md`](../../docs/google-play-private-alpha.md) lines 61 and 62:
  title and short description. Changing a live listing is a manual Play Console step, so this phase
  produces the text and hands the submission over.
- The app id and `android:label` stay as they are unless Q6 says otherwise. A rename would mean a new
  package name and a new listing, which is not a copy edit and would be its own effort.

## Out of scope

- The alpha submission itself, which is phase 07's manual step.
- Translating the docs.

## Done when

- `grep -rni portug docs pubspec.yaml` returns only deliberate mentions, such as the app-name gloss
  and the worked example.
- The store text is written down here, ready to paste.

## What the implementation found

Store text, ready to paste:

- Title: `fala - Language Tutor`
- Short description: `Practise a language by chatting with an AI tutor that corrects you`
- Full description: name the five languages (Portuguese (Brazilian), Spanish, French, Italian,
  German), and keep the existing engine and privacy wording.

`docs/prompt-engineering.md` needed more than a find-and-replace: it described "tutor_response v1" and
listed the prompt's instructions as Portuguese facts. It now documents the variables, the
throw-on-unsubstituted rule, and keeps Portuguese as a worked example, which is the shape the plan
asked for.

Deliberate remaining mentions of Portuguese, all outside the app code: the app-name gloss in
`functional-specs.md` ("fala" is a Portuguese word), the supported-language lists, and the worked
example above.

Not done here, and not ours to do: the live Play listing. Editing it is a manual Play Console step,
still open in phase 07.
