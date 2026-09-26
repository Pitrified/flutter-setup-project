# fala

## Overview

Android language-tutoring app. The user chats in Portuguese and gets structured
corrections plus a conversational reply, streamed token by token.

Two inference engines sit behind one `InferenceEngine` interface, selected in Settings:

- **on-device**: Qwen3-0.6B (`.litertlm`, LiteRT-LM path of `flutter_gemma`), downloaded on
  first launch, offline afterwards.
- **cloud**: OpenAI via `openai_dart`, with the key stored in `flutter_secure_storage`.

`FakeInferenceEngine` is the third implementation and the one every test uses.

## Source of truth

- Architecture, scope, constraints: [docs/functional-specs.md](../docs/functional-specs.md)
- Folder layout and naming: [docs/project-structure.md](../docs/project-structure.md)
- Coding rules: [docs/coding-standards.md](../docs/coding-standards.md)
- AI collaboration: [docs/ai-development-playbook.md](../docs/ai-development-playbook.md)
- System specs: [docs/library/](../docs/library/)
- Build and release: [docs/build-and-release.md](../docs/build-and-release.md)

The docs lag the code in places, because the phases after 09 moved faster than the docs did.
Where a doc and the code disagree, the code is the fact and the doc is the bug: say so rather
than coding to the stale line. Where a doc and a *request* disagree, stop and ask.

## Progress

Each phase folder under [plans/](../plans/) owns its own `tracking.md` once it has phases, written in the shape the
`tracked-development` skill describes; a draft has only its `00_start.md`. Read the phase folder itself: the folders up to 09 predate the
convention and keep their own index, and none of them is the index for anything newer.

## Plans are a diary, docs are the as-is

`plans/` records how the project got here. `docs/` records what it is now. A reader who needs to know
why something is the way it is reads the docs, not a diary entry from four phases ago.

So nothing outside `plans/` points at a specific plan: no path to a plan folder or file, no `Qn`/`Dn`
id. When a comment, script or doc needs to lean on a decision, that decision goes in the docs file
whose topic it is, and the citation points there. Docs are grouped by topic, so a decision with no
obvious home means a missing doc rather than an exception.

These instructions and the other meta files (`docs/README.md`,
[ai-development-playbook.md](../docs/ai-development-playbook.md)) are the exception that proves the
rule: they may describe the *shape* of the plans tree, such as `plans/<folder>/tracking.md` or
`NN_feat_*.md`, because that is the convention rather than a decision. They still may not point at an
instance of it.

## Stack

Flutter (Dart) - Riverpod - GoRouter - Hive - flutter_gemma - openai_dart -
freezed + json_serializable - Android, min API 26, target 36

## Hard rules

- Follow the layer boundaries in [project-structure.md](../docs/project-structure.md)
- No business logic in widgets, go through providers
- No `print`/`debugPrint`, use the project logger
- A new dependency needs approval first, with the reason it beats what is already here
- Tests use `FakeInferenceEngine`, never a real engine or the network
- Trailing commas on multi-line argument lists
- Generated files (`*.freezed.dart`, `*.g.dart`) are gitignored, not committed
- No iOS, macOS, web or desktop code until phase 11 is actually being executed
- Touch the files the request is about and leave the rest alone

## Gates

`scripts/check.sh` runs every gate: markdown links resolve, the plan folders agree with their
convention (`scripts/plans.py check`), codegen, `dart format` over the tracked Dart files, `flutter analyze`, `flutter test`. CI runs the same
script. `scripts/install-hooks.sh` points git at `.githooks` so a commit runs them too.

It prints one line per gate and the full output of whichever one fails, so its output needs no
filtering; `scripts/check.sh -v` prints everything.

`scripts/plans.py` is a vendored copy of the one in the `tracked-development` skill in dotfiles.
Where that skill is installed, `check.sh` prints a note when the two differ and never fails on it.
The fix is always to copy the skill's file over this one, never the other way.

A gate has to name the file and the line when it fails, and be fast enough that nobody skips it.
Something that has never been seen failing is an assumption, not a gate.

So is something that has never been seen passing where it is claimed to pass. A green run here
proves the gates pass on a tree that already has generated files and a warm `.dart_tool`; a fresh
checkout has neither, which is exactly how the first CI run failed while local was green. Reproduce
the CI condition with a clean clone (`docs/getting-started.md`, "Reproducing CI locally") before
saying anything about it. Do not write that CI will pass, or that two environments agree, until
something has run in both: say what was checked, and say what was not.

Adding a check to `check.sh` beats writing the rule down a second time: when a correction has to
be given twice, the fix is a mechanism, not more prose.

## Which machine

This box is headless: no device, no emulator, and `flutter devices` is empty. It builds, analyzes
and tests. Anything that needs the Pixel (install, on-device smoke test, timing) and every `git push`
happens from a `g7` session, so hand those back rather than working around them.

`flutter` and the Android SDK are on the PATH in every shell here, including non-interactive ones
(`~/.bashrc` sets them above its interactivity guard, 2026-09-24). `scripts/check.sh` still falls
back to `$HOME/flutter/bin` so it works on a machine without that edit.

## How to write

Technical prose: dry, concrete, and short without leaving anything out. The two failure modes are
padding that makes a page longer without making it say more, and cutting the detail that was the
reason to write the sentence. Aim between them.

Behind most of the habits below is one failure: reaching for the unusual word to show what the
writer is, rather than to show the reader what he means. Prose is a window onto the subject, and the
mannered kind has the writer's face reflected in it. An agent inherits the tic from its training
data, so the rule is the same for both of us: the word that carries the meaning.

- **No hype.** Adjectives and adverbs that carry tone but no information: seamless, robust,
  powerful, elegantly, simply, blazing. Cut them, or replace them with the concrete fact, subject
  to the next rule.
- **No volatile numbers.** A number that changes with the next run is a measurement with a date on
  it, and belongs in a plan log rather than in a doc. Numbers that hold still, such as APK sizes
  measured once, counts, API levels and versions, are facts and stay.
- **No padding.** One idea stated once. Do not restate a point in three framings, and do not open a
  paragraph by announcing what it is about to say.
- **No fake drama.** The "it is not X, it is Y" reveal. The countdown that rules out two things
  before naming the third. The one-sentence paragraph as a punchline. The "X is the Y of Z"
  metaphor. These are the most-cited tells of machine writing.
- **No thesaurus reach.** delve, leverage, unleash, realm, landscape, ever-evolving, meticulous,
  underscore, boast, harness, tapestry, testament, quietly, bites, load-bearing. A sample, not an
  exhaustive blacklist. Ordinary words instead.
- **Plain copulas.** "is" and "are", not "serves as a", "stands as", "represents".
- **No closing summary** repeating what the page just said, and no motivational sign-off.
- **No emoji**, and no decorative headers. Headers are plain labels.
- **No confident filler where a fact is missing.** If a value is unknown, say it is unknown and say
  who or what would know. A plausible invented number is the worst possible output.
- **Mechanical.** No em dashes (`--`, `---`, or Unicode). Use a hyphen or rewrite the sentence. Do
  not wrap markdown to a fixed column; break lines on logical boundaries instead, such as after a
  period or between clauses.

The list is the recurring failures, not the definition. The rule is technical, dry, complete prose.

## Planning

Plans keep the reasoning from being re-derived, not from being reopened. Anything in them can be
reopened: a decision, an answered question, a phase, the shape of the whole effort. Reopening on new
evidence is the plan working. Record what changed and leave the previous answer visible rather than
editing it away.

Write each point at the strength it actually has. "for now", "until the spike reports", "unless X
changes" are accurate about most choices and cost nothing. Reserve "never" and "hard requirement"
for the few things that are fixed, such as a cost ceiling or a device that has to go back intact. A
line written as an absolute gets read a month later as a deal breaker, and then something obvious
does not get tried.

Weight remarks by how they were made. An offhand comment is a signal, not an instruction. When one
would become a constraint, either mark it provisional or ask before promoting it.

`Qn` and `Dn` numbers are local to the file that raised them, so a bare `(Q4)` in a file that did
not raise it is a broken reference: name the file, as ``13_key_distribution/00_start.md` Q4`.

## Output style

- Small atomic diffs, one concern each.
- Public types and methods get `///` doc comments.
- Tests for non-trivial logic, and a failing test before its fix where that is possible.
- Verify against the real thing. `scripts/check.sh` green is the claim; "looks right" is not.
- Ask one clarifying question if the scope is ambiguous. Do not invent scope.
- End a task by asking the one follow-up question that would most change what happens next.

## Spellcheck

When the spellchecker flags a technical term or a British/American spelling, add it to
`.vscode/settings.json` under `cSpell.words` rather than rewording around it.
