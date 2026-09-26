# Cloud APK build - implementation tracking

A debug APK built in a cloud session, and the steps written down for the next one. Reasoning in [`00_start.md`](00_start.md).

## Key decisions

- **`dl.google.com` allowed** on the `Default` environment by the user.
- **Maven Central through Google's mirror**, via a machine-level Gradle init script, because Central rate-limits the environment.
- **The note, not a script**, until `24_cloud_sessions` writes the setup script.

## Phases

| #  | Phase                              | Plan                                                   | Status      |
| -- | ---------------------------------- | ------------------------------------------------------ | ----------- |
| 01 | Build the APK in this session      | [`01_this_session.md`](01_this_session.md)             | done        |
| 02 | Steps in the fresh-session note    | [`02_fresh_session_note.md`](02_fresh_session_note.md) | done        |
| 03 | Fold into the setup script         | [`03_setup_script.md`](03_setup_script.md)             | draft       |

Status values: draft / planned / in progress / done / superseded / discarded.

## Log

Append-only. Newest at the bottom.

- 2026-09-26 : spun off after the repo split merged. Phase 1 done in the same session: SDK installed, first Gradle build failed on HTTP 429 from Maven Central, mirror init script added, debug and release split APKs built for fala-language-tutor.
- 2026-09-26 : phase 2 - the note's code, run unchanged on a clean clone with an empty `HOME`, went from nothing to a built debug APK in 5 min 57 s. Phase 3 waits on `24_cloud_sessions`.
