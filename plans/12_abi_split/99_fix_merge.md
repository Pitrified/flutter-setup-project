# merge histories

## draft

we messed up and pushed some changes on g7, and committed some changes on g4

some commit seem to be on both histories

the current machine is g4

```bash
pmn@pmn-G7:~/repos/flutter-setup-project (feat/abi-split)$ git log --pretty=fuller
commit 175612d0891c75dde9193ee201b51cdc7b7cf80c (HEAD -> feat/abi-split, origin/feat/abi-split)
Author:     Pitrified <pmn@gmail.com>
AuthorDate: Sat Jul 11 09:41:37 2026 +0200
Commit:     Pitrified <pmn@gmail.com>
CommitDate: Sat Jul 11 09:41:37 2026 +0200

    feat(android): drop armeabi-v7a and exclude unused flutter_gemma libs
    
    Phase 2 + 3 of plans/12_abi_split.
    
    - Exclude 8 native .so files (MediaPipe, image-generator, RAG) that this
      app never loads - it runs only the LiteRT-LM/qwen3 path - via
      packaging.jniLibs.excludes. Keep liblitertlm_jni.so and libsqlite3.so.
    - Drop 32-bit armeabi-v7a. ndk.abiFilters is overridden by the Flutter
      plugin and conflicts with --split-per-abi, so this is done at the build
      command with --target-platform android-arm64,android-x64 (documented).
    
    Verified on-device (Pixel 7 Pro): LiteRT-LM engine init + structured-output
    generation with no UnsatisfiedLinkError. Split arm64 APK 160 -> 43 MB,
    fat APK 273 -> 103 MB. Docs and plan tracking updated.
    
    Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>

commit 8cc54a2e52b6b1404bfda3e44a6b0de54d8456f0
Author:     Pitrified <pmn@gmail.com>
AuthorDate: Sat Jul 11 09:28:58 2026 +0200
Commit:     Pitrified <pmn@gmail.com>
CommitDate: Sat Jul 11 09:28:58 2026 +0200

    docs(abi-split): record g7 build, on-device test, Q3 resolution
    
    Split APKs rebuilt on g7 and arm64 verified on Pixel 7 Pro (download +
    structured streaming). Q3 resolved from source: app uses only the
    LiteRT-LM/qwen3 path, so the MediaPipe + RAG native libs are unused and
    are phase-3 exclusion candidates.
    
    Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>

commit 2904b04494f6a35c696fe37209b95715ce059979
Author:     Pitrified <pmn@gmail.com>
AuthorDate: Wed Jul 8 22:18:16 2026 +0200
Commit:     Pitrified <pmn@gmail.com>
CommitDate: Wed Jul 8 22:18:16 2026 +0200

    do test p1 for abi split

commit 6f1cf88b224749b9be158164713414ac6fa07896
Author:     Pitrified <pmn@gmail.com>
AuthorDate: Wed Jul 8 21:47:59 2026 +0200
Commit:     Pitrified <pmn@gmail.com>
CommitDate: Wed Jul 8 21:47:59 2026 +0200

    add plans for abi split

commit 6338f7407059c1153d28475604b609d21ce3a57d (origin/main, main)
Author:     Pitrified <pmn@gmail.com>
AuthorDate: Wed Jun 24 00:23:59 2026 +0200
Commit:     Pitrified <pmn@gmail.com>
CommitDate: Wed Jun 24 00:23:59 2026 +0200

    fix: update default engine kind to OpenAI and adjust related settings
```

```bash
pmn@pmn-14G4:~/repos/flutter-setup-project (feat/abi-split)$ git log --pretty=fuller
commit 702d641bcdea7703930dbcd3e679ac1678cb2243 (HEAD -> feat/abi-split)
Author:     Pitrified <pmn@gmail.com>
AuthorDate: Thu Jul 9 19:02:03 2026 +0200
Commit:     Pitrified <pmn@gmail.com>
CommitDate: Thu Jul 9 19:02:03 2026 +0200

    feat(android): exclude unused image-gen and RAG native libs
    
    Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
    Claude-Session: https://claude.ai/code/session_01YJLtxwySVnWrasvzcTtJf5

commit 5395f418038366a6b7e57b30f4998a10fd5e5aed
Author:     Pitrified <pmn@gmail.com>
AuthorDate: Thu Jul 9 18:41:45 2026 +0200
Commit:     Pitrified <pmn@gmail.com>
CommitDate: Thu Jul 9 18:41:45 2026 +0200

    feat(android): drop armeabi-v7a from build outputs
    
    Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
    Claude-Session: https://claude.ai/code/session_01YJLtxwySVnWrasvzcTtJf5

commit 2904b04494f6a35c696fe37209b95715ce059979
Author:     Pitrified <pmn@gmail.com>
AuthorDate: Wed Jul 8 22:18:16 2026 +0200
Commit:     Pitrified <pmn@gmail.com>
CommitDate: Wed Jul 8 22:18:16 2026 +0200

    do test p1 for abi split

commit 6f1cf88b224749b9be158164713414ac6fa07896
Author:     Pitrified <pmn@gmail.com>
AuthorDate: Wed Jul 8 21:47:59 2026 +0200
Commit:     Pitrified <pmn@gmail.com>
CommitDate: Wed Jul 8 21:47:59 2026 +0200

    add plans for abi split

commit 6338f7407059c1153d28475604b609d21ce3a57d (origin/main, origin/HEAD, main)
Author:     Pitrified <pmn@gmail.com>
AuthorDate: Wed Jun 24 00:23:59 2026 +0200
Commit:     Pitrified <pmn@gmail.com>
CommitDate: Wed Jun 24 00:23:59 2026 +0200

    fix: update default engine kind to OpenAI and adjust related settings
```

## analysis

State after `git fetch` (local branch is ahead 2, behind 2):

```text
* 175612d feat(android): drop armeabi-v7a and exclude unused flutter_gemma libs   (origin/feat/abi-split, from g7)
* 8cc54a2 docs(abi-split): record g7 build, on-device test, Q3 resolution         (from g7)
| * 702d641 feat(android): exclude unused image-gen and RAG native libs           (HEAD, g4 local only)
| * 5395f41 feat(android): drop armeabi-v7a from build outputs                    (g4 local only)
|/
* 2904b04 do test p1 for abi split                                                (common ancestor)
```

No commit is literally on both histories;
the two pairs are two independent implementations of the same phases (2 + 3), diverging at 2904b04.
Both sides touch the same 5-6 files (`android/app/build.gradle.kts`, `docs/build-and-release.md`, the `plans/12_abi_split/` docs), so any rebase or merge conflicts in every file.

### What each side did

Same goal, different mechanics:

| Aspect | g4 (702d641, local) | g7 (175612d, origin) |
|---|---|---|
| v7a removal | `packaging { jniLibs.excludes += "lib/armeabi-v7a/**" }` | `--target-platform android-arm64,android-x64` at the build command |
| Lib excludes | 7 libs (image-gen + RAG) | 8 libs (same 7 **plus `libllm_inference_engine_jni.so`**, the MediaPipe LLM engine) |
| On-device verification | pending (commit says so) | done on Pixel 7 Pro, no UnsatisfiedLinkError |
| Sizes | arm64 split 71 MB, fat 147 MB | arm64 split 43 MB, fat 103 MB |
| Extras | bundletool Play-download numbers (arm64 ~31 MB) | Q3 resolved from source, plan docs updated with results |

The g7 version is a superset in substance: one more excluded lib (the biggest one, hence 71 -> 43 MB) and the runtime verification the g4 commit explicitly left pending.

### The one factual conflict

The two sides disagree on how v7a must be dropped:

- g4 commit claims neither `--target-platform` nor `ndk.abiFilters` removes flutter_gemma's AAR v7a libs, so a packaging exclude is required, and the flag is only needed to suppress the empty v7a stub APK in split builds.
- g7 commit claims `ndk.abiFilters` is overridden by the Flutter plugin and the `--target-platform` flag alone is the reliable lever.

g7's measured fat APK (103 MB, "arm64 + x86_64") suggests the flag did strip v7a, but the flag-only approach silently regresses on any `flutter build` invocation that forgets the flag (plain `flutter build apk` / `appbundle`).
The g4 packaging exclude is a belt-and-braces guard worth keeping regardless of which claim is right.

### Options

1. **Reset to origin, re-apply the g4 delta as one new commit (recommended).**
   g7's history is pushed, verified, and a superset; the g4 commits add ~2 salvageable items.
   Clean linear history, no conflict resolution theater, nothing force-pushed.
2. Merge `origin/feat/abi-split` into local: conflicts in all files, and the resolution work is identical to option 1 but leaves 4 near-duplicate commits plus a merge commit in history.
3. Rebase the 2 local commits onto origin: every hunk conflicts, and the rebased commits would mostly dissolve into no-ops. Worst of the three.

## plan

Option 1, on g4:

1. Safety branch for the local work:
   `git branch backup/g4-abi-split`
2. Adopt the pushed history:
   `git reset --hard origin/feat/abi-split`
3. Port the g4-only deltas from `backup/g4-abi-split` by hand (small, review each):
   - add `"lib/armeabi-v7a/**"` to the `jniLibs.excludes` list in `android/app/build.gradle.kts` as a guard for flag-less builds, with a comment noting the `--target-platform` interaction;
   - fold the useful g4 doc bits into `docs/build-and-release.md`: the "empty v7a stub APK" explanation for why the flag is still passed to split builds, and the bundletool Play-download measurements (marked as measured 2026-07-09, pre-`libllm_inference_engine_jni` exclusion, so re-measure or drop the stale numbers).
3b. Optional but cheap: rebuild once (`flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64`) to confirm sizes still match g7's numbers with the packaging exclude added, and run a plain `flutter build apk --release` to settle the factual conflict (does the fat APK contain `lib/armeabi-v7a/` without the flag?).
4. Commit as one `feat(android): ...` commit on `feat/abi-split`.
5. Push from a g7 session (this box has no GitHub credentials and cannot push); a plain `git push` works, no force needed since we only added on top of origin.
6. Delete `backup/g4-abi-split` once the push is confirmed.

Open question before executing: are the bundletool numbers worth keeping stale, re-measuring, or dropping? Default in step 3 is to keep the methodology sentence and re-measure only if a rebuild happens anyway.

## execution log (2026-07-17, g4)

- Step 1 done: `backup/g4-abi-split` created at 702d641.
- Step 2 done: `feat/abi-split` reset to origin (175612d).
- Step 3 done: `lib/armeabi-v7a/**` re-added to `jniLibs.excludes` with a comment; docs updated with the flag-less-build guard note, the empty-v7a-stub-APK rationale, and the 2026-07-09 bundletool number marked as pre-libllm-exclusion.
- Note: with the packaging exclude in place, the "does the flag alone strip AAR v7a libs" question is moot for this repo (the exclude always wins); the flag-only test from 3b was skipped for that reason.
- Note: this file was untracked and disappeared around the reset (cause unclear); recreated from session context.
- Step 3b done: split build re-run on g4 (Flutter 3.44.5) with the exclude in place.
  arm64-v8a 44.4 MB, x86_64 49.6 MB - matches g7's 43/48 MB (delta is the 3.44.0 -> 3.44.5 engine).
  arm64 APK contains only the 6 expected libs (libapp, libdartjni, libdatastore_shared_counter, libflutter, liblitertlm_jni, libsqlite3), zero armeabi entries.
- Step 4 done: committed as one commit on `feat/abi-split` (this file included).
- Remaining: step 5 (push from a g7 session, plain `git push`), then step 6 (delete `backup/g4-abi-split`).
