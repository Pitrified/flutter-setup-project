---
status: draft
priority: 0
depends_on: [20_repo_split]
description: |
  Quality-of-life maintenance: 78 packages are behind their latest versions as of 2026-09-25, held
  back by constraints nobody has revisited. Take the upgrades that are free, and write down why each
  one that is not is pinned.
---

# Dependency upgrades

Draft spin-off, raised 2026-09-25 from a line in the `codegen` gate's output.

## Where this came from

Every `flutter pub get` prints it:

```
78 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
```

That line has been scrolling past for months. It is not urgent and it is not nothing: some of those 78
are transitive and will move on their own, some are held by a constraint that was right once, and at
least one is `flutter_gemma`, whose upgrades have broken this app before and whose native library
exclusions have to be re-verified each time (`docs/build-and-release.md`).

## Why it waits for the repo split

This folder carries `depends_on: [20_repo_split]`, and that is the point of the field
([`../22_plan_dependencies/00_start.md`](../22_plan_dependencies/00_start.md)): the split decides which
repo owns the `pubspec.yaml` being upgraded and whether the skeleton and the app keep one dependency set
or two. Doing the upgrades first means doing them twice, and the second time under a different set of
constraints.

## Shape

- `flutter pub outdated` as the starting list, split three ways: transitive and free, direct and
  free, and held by a constraint.
- Take the free ones in one commit per group, with the gates green between groups.
- For each one that stays behind, one line saying why, next to the constraint in `pubspec.yaml`. A pin
  with no reason is indistinguishable from neglect, which is how this list got to 78.
- `flutter_gemma` is its own step, because an upgrade means re-checking the `jniLibs.excludes` list and
  the APK size, and folder 16 may remove it entirely first.

## Out of scope

- Upgrading Flutter itself. The version is pinned in CI (`flutter-version: 3.44.5`) and moving it is a
  separate change with its own blast radius.
- Anything that changes app behaviour. This folder is maintenance; a behaviour change means a feature
  folder.

## Open questions

- Q1: does this wait for folder 16 as well, which may delete `flutter_gemma` and with it the largest
  upgrade risk here?
  Recommended: no, but sequence `flutter_gemma` last within this folder. If 16 lands first the step
  disappears, and if it does not, the upgrade is still worth having.
  NEW_ANS:
