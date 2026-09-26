# Repo split - implementation tracking

fala leaves for its own repo, `fala-language-tutor`, written fresh by a Claude session from a plan, with no local LLM.
This repo becomes the Flutter guide: setup from zero, a working app with the patterns other projects actually use, skills, scaffolding, and distribution approaches.
Brainstorm, decisions and open questions are in [`00_start.md`](00_start.md).

## Key decisions

- **Audit first.** It decides scope; the brainstorm is direction, not a list.
- **Order: fala-language-tutor before the clean-up.** The session writing it reads this repo while it still holds the working tutor.
- **No bootstrap script.** A session reads this repo and a plan, and writes the new one.
- **No history in the new repo** (Q2). It is written, not extracted.
- **The on-device engine stays in the guide** (Q5), as a gallery pattern; fala-language-tutor is cloud only.
- **The guide's app is a working gallery** (Q6): router, navigation, basic pages, components, storage.
- **LLM testing machinery duplicated** in both repos until a third copy, then assessed.
- **One cloud environment, set up by hand, for now.** Both repos carry a short fresh-session note until `24_cloud_sessions` replaces it with a setup script.

## Phases

| #  | Phase                                   | Plan                                                   | Status  |
| -- | --------------------------------------- | ------------------------------------------------------ | ------- |
| 01 | Fresh-session note in this repo         | [`01_fresh_session_note.md`](01_fresh_session_note.md) | planned |
| 02 | Audit                                   | [`02_audit.md`](02_audit.md)                           | planned |
| 03 | Write fala-language-tutor               | [`03_fala_repo.md`](03_fala_repo.md)                   | draft   |
| 04 | Clean this repo into the guide          | [`04_guide_cleanup.md`](04_guide_cleanup.md)           | draft   |

Status values: draft / planned / in progress / done / superseded / discarded.

## Log

Append-only. Newest at the bottom.

- 2026-09-25 : spun off as a draft while raising the wider roadmap.
- 2026-09-26 : brainstormed with the user; Q1 and Q2 answered by it, Q4 to Q6 raised. Four phases derived; 03 and 04 stay `draft` until the audit reports. Priority raised to 1; `16_cloud_first_engine` is also at 1 and may be superseded by this folder (Q5).
- 2026-09-26 : Q3 to Q6 answered. Plans split per folder by the audit; `fala-language-tutor` created and in the app installation; `16_cloud_first_engine` superseded, with the on-device engine removed in the new repo and kept here as a gallery pattern; the guide's app is a working gallery (router, navigation, pages, components, storage).
