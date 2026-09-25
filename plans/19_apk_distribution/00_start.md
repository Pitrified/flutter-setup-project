---
status: draft
priority: 0
description: |
  Publish the release APK as a GitHub release asset, uploaded by hand, so a build
  reaches a phone without waiting on the Play Console. Gated on whether the APK
  carries a key, and on where the signing key lives.
---

# Getting the APK onto a phone without the Play Console

Status: draft spin-off, raised 2026-09-25. No phases derived.

## Where this came from

The ask: "a feature to upload the APK somewhere, can we just shove it in the GitHub
release/artifacts? Manually uploaded, no fancy CI/CD for now. Mid-priority, if the APK is small then
we can just [do that]."

## What exists today

- The Play Store private alpha is the current distribution path, and it is half finished: phase
  07/01 still has manual Console steps, and a review wait per upload.
- `docs/build-and-release.md` documents split-per-ABI builds. The arm64 release APK is 43 MB today,
  the fat APK 103 MB.
- No GitHub credentials on the dev box, so any upload runs from a g7 session.

## GitHub as the host: what is true, and what to check

To verify when picked up rather than trusting this note:

- **Releases take binary assets** and are the intended place for downloadable builds. The per-asset
  limit is large (gigabytes), far above any APK here.
- **Actions artifacts are the wrong tool**: they expire (90 days by default), they are zipped on
  download so a phone browser gets a `.zip` rather than an installable file, and they need a login to
  fetch on a private repo.
- **Repository visibility decides everything else.** On a public repo a release asset is a public URL
  with no auth, which is fine for an APK and very much not fine if that APK ever ships an API key
  inside it. That is the overlap with
  [`../13_key_distribution/00_start.md`](../13_key_distribution/00_start.md): a shipped-key build must
  not be published this way.
- The upload itself is one command from a machine with credentials:
  `gh release create v0.1.0-alpha build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.
- Android will refuse the install until "install unknown apps" is granted to whatever downloads it,
  and the APK must be signed with a real key (not the debug key this box uses) or upgrades over an
  earlier install fail with a signature mismatch.

Size matters to this ask, and [`../16_cloud_first_engine/00_start.md`](../16_cloud_first_engine/00_start.md)
is what changes it: with the on-device engine gone, most of the 43 MB goes with it. Worth measuring
after that lands rather than guessing now.

## Sketch

A short `docs/` section plus a checklist, not automation: build the split APK, sign it with the
release key, tag, `gh release create`, and paste the link. The interesting decisions are which ABIs to
publish, and what the release notes have to say about the key.

## Open questions

- Q1: public release assets, or private repo with authenticated downloads?
  Recommended: decide after key distribution. If the APK carries any key, it cannot be a public asset.
  NEW_ANS:
- Q2: which artifact goes up: the arm64 split APK, all splits, or the fat APK?
  Recommended: arm64 only, plus the fat APK on request. Every test device here is arm64, and x86_64
  exists for emulators, which are built locally anyway.
  NEW_ANS:
- Q3: does this replace the Play private alpha or sit beside it?
  Recommended: beside it. Sideloading is for fast iteration; the Play track is what non-technical
  testers can actually use.
  NEW_ANS:
- Q4: signing. Release builds on this box are debug-signed because there is no `key.properties` here.
  Where does the release key live, and does it stay off this box?
  Recommended: it stays off this box, with signed builds produced on g7, matching the rule that no
  pushable credentials live here.
  NEW_ANS:
