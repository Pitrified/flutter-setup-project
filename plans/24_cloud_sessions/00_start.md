---
status: draft
priority: 0
description: |
  Make a claude.ai cloud session match the workstation: the personal Claude config from dotfiles,
  the pinned Flutter SDK, and later the Android SDK for release builds, installed by one script
  the environment runs, so a new session starts ready to run scripts/check.sh.
---

# Cloud Claude Code sessions that match the workstation

Draft spin-off, raised 2026-09-25 from a cloud session on this repo. No phases derived.

## Where this came from

The ask, after Flutter had to be installed by hand in a cloud session and the dotfiles `CLAUDE.md` turned out not to be loaded:

> spin off a folder to describe this cloud claude code setup, final aim: being able to replicate the local settings + dev environment.
> dotfiles + skills + claude.md.
> flutter enabled - no apk for now; plan a section for when we will also generate the release build.
> search online for best practices about claude cloud sessions.
> ideally a single script we fire up to get all the container setup - maybe even a dockerfile? would that be compatible?

## What a cloud session has today

Checked from inside a session on 2026-09-25.

- Ubuntu 24.04 on x86_64, running as root. OpenJDK 21, Python, `uv`, Docker, `git`. No `/dev/kvm`, so no emulator.
- No Flutter. Installed by hand: the 3.44.5 stable tarball from `storage.googleapis.com` into `~/flutter`, the version CI pins. `~/flutter` is 2.3 GB and `~/.pub-cache` 671 MB after `flutter pub get`.
  On that fresh clone `scripts/check.sh` passed all five gates.
- No `~/dotfiles` and no `~/.claude/CLAUDE.md`.
  `~/.claude/` holds only harness files: `launcher-settings.json` (a Stop hook and one permission), `stop-hook-git-check.sh`, and `skills/synced/`, which is where skills enabled on claude.ai arrive.
- The instructions that did load were this repo's `CLAUDE.md` and the `.github/copilot-instructions.md` it imports.
  The `tracked-development` skill that file names lives only in dotfiles, so this session did not have it.
- Network, through the session's proxy: `storage.googleapis.com`, `pub.dev`, `maven.google.com`, `services.gradle.org` and `repo.maven.apache.org` answer.
  `dl.google.com` is refused with a 403, and that is where the Android command-line tools download from.
  The level is Trusted: see "Cloud environments" below.

## GitHub access: what a session can reach

Checked 2026-09-25, by the user on github.com and claude.ai, after an assistant claimed push access to 50 repos from the wrong signal.

- **The Claude GitHub App installation is the write list.** Settings, Installed GitHub Apps, Claude, Configure shows "Only select repositories": `Pitrified/dotfiles`, `Pitrified/flutter-setup-project`, `Pitrified/plans`.
  Pushes, pull requests and GitHub API calls from a session work on those three only.
- **The check is enforced.** Attaching `Pitrified/laife`, which is public and owned by the same account, is refused by claude.ai with "The Claude GitHub App on Pitrified doesn't include laife."
- **No other route.** `gh` has never been installed on the workstation, so `/web-setup` has never sent a token, and there is no token that bypasses the installation.
- **Reading is wider.** Any public repo can be cloned over plain git without credentials, since anyone can.
  Private repos are not in the installation, so no session reaches them.
- **The misleading signal.** `list_repos` marks every repo the account owns with `can_push: true`.
  That flag is the account's own permission, not the app's. Only the installation page, or an attach being refused or accepted, answers what a session can do.

For this folder that means: the personal layer clones dotfiles (public, and installed if a session ever needs to push to it), and a new repo needs adding to the installation before a session can push to it.

## Cloud environments

From `list_environments`, 2026-09-25: one environment, `Default`, kind `anthropic_cloud`, created 2026-07-14, described as "Default - trusted network access".
Onboarding created it. Its network level is Trusted, which matches `dl.google.com` being refused.
Its level, variables and setup script are in its settings: the environment menu in a session's title bar, then the gear on the environment, or Edit.

The Edit dialog, as the user read it on 2026-09-25: Name `Default`, Network access Trusted (`trusted_only`), and four fields.
Environment variables in `.env` format, with the warning that they are visible to anyone using the environment.
API credentials, empty, whose values cannot be read back after saving.
Setup script, a bash field. Changes apply to new sessions only.
The variables box showed `NODE_ENV=production` and `GIT_AUTHOR_NAME=Your Name`, and the script box `npm install`. These are most likely the dialog's grey placeholder text rather than saved values: this repo has no `package.json`, and the session started with no `node_modules` or lock file in the checkout. To confirm in the dialog.

`Default` stays as it is, as a temporary environment (Q2). The Flutter stack gets a new environment, which is where the setup script is verified.

How long each piece lasts, per the docs:

- **An environment** lasts until it is archived. It holds the network level, the variables and the setup script, and every session started in it uses them.
  More can be added from the same menu (Add cloud environment). The docs give no limit on how many.
- **The setup-script snapshot** is rebuilt when the script or the allowed hosts change, and after about seven days.
- **A session's container** is reclaimed after a period of inactivity. Reopening the session provisions a fresh one from the snapshot, with the conversation restored.
  Anything installed by hand mid-session, and background processes, are gone. The Flutter install in the session this folder came from is that kind.
- **Git** is the only thing that outlives all of the above. Work not pushed is lost with the container.

## What the documentation says

From [Configure cloud environments](https://code.claude.com/docs/en/cloud-environments) and [Use Claude Code in the cloud](https://code.claude.com/docs/en/claude-code-on-the-web), read 2026-09-25.
These pages change often, so re-read them when a phase is picked up rather than trusting this summary.

- **What carries over.** A session starts from a fresh clone. The repo's `CLAUDE.md`, `.claude/rules/`, `.claude/skills/`, `.claude/agents/` and `.claude/commands/` load.
  The user's `~/.claude/CLAUDE.md`, `~/.claude/skills/`, user-scoped plugins and user-scoped MCP servers do not, "because they live on your machine".
  Skills enabled on claude.ai load automatically.
- **Setup script.** A bash script in the environment's settings. It runs as root before Claude Code starts, must exit 0 or the session fails to start, and should finish in about five minutes.
  After it finishes, the filesystem is snapshotted and reused by later sessions, which skip the script.
  The snapshot is rebuilt when the script or the allowed hosts change, and after about seven days. Resuming a session never re-runs it.
  Only files are kept; processes the script started are not.
- **SessionStart hook.** Lives in the repo's `.claude/settings.json` and runs on every start and resume, locally and in the cloud.
  It is not loaded in a session with several repos. A cloud-only hook checks `CLAUDE_CODE_REMOTE=true`.
  The docs' split: the setup script provisions the machine, and the hook does project setup such as installing dependencies.
- **Base image.** "Replacing the base image entirely isn't supported yet."
  The options are a setup script on top of the provided image, or your own image run as a container next to Claude with `docker compose`.
  Self-hosted environments run on a runner image the organization supplies, which is a different product.
- **Environment variables** are visible to anyone who uses the environment, so no secrets go there.
- **Limits.** Roughly 4 vCPUs, 16 GB RAM and 30 GB disk.
- **Network levels.** None, Trusted (a default allowlist of registries, GitHub and cloud SDK hosts), Full, and Custom (your own list, optionally with the defaults).

Community examples of setup scripts, not yet read in detail:
[ArloL/claude-code-web-environment-setup](https://github.com/ArloL/claude-code-web-environment-setup),
[justanotherspy/claude-code-web-environment-scripts](https://github.com/justanotherspy/claude-code-web-environment-scripts).

## Three layers, three owners

1. **Personal: CLAUDE.md, rules, skills, settings.** Owned by `Pitrified/dotfiles`.
   Its `install/install.py` already maps `claude/claude__X.symlink` to `~/.claude/X` one file or folder at a time, so the harness files in `~/.claude/` are left alone.
2. **Toolchain: Flutter now, the Android SDK later.** Owned by this repo, because the pinned version is here, in `.github/workflows/checks.yml`.
   Reading the version from that file keeps it at one pin.
3. **Project warm-up: `flutter pub get`, maybe codegen.** A SessionStart hook in this repo's `.claude/settings.json`, gated on `CLAUDE_CODE_REMOTE`.
   The first `build_runner` run in the session above took about a minute, so it may be better left to `scripts/check.sh`.

## Personal layer: what to watch

- `install.py` runs under `uv` with Python pinned to 3.14. `uv` is in the base image; whether it can fetch 3.14 through the proxy is unverified.
- The dotfiles `settings.json` is the risky file, and is not linked in the cloud (Q3).
  Its PreToolUse hooks call `rtk`, which is not installed here, on every Bash call.
  It also sets `model` and `effortLevel`, which may override what the session picker chose.
  So the installer needs a way to link `CLAUDE.md`, rules and skills without `settings.json`; `install.py` links every `*.symlink` today.
- Unverified, and the first thing to check: whether Claude Code in a cloud session reads a `~/.claude/CLAUDE.md` that a setup script wrote.
  The docs say the file does not carry over because it is on the workstation, which suggests a copy in the VM would be read, but nothing has shown it yet.
- Skills come from dotfiles (Q4), not from claude.ai, so there is one copy.
  That makes this layer the carrier for `managing-plan-folders` once it moves to dotfiles.
  The move is its own folder, `25_skill_to_dotfiles`, on branch `feat/25_skill_to_dotfiles`; not linked here because that folder is not on this branch.

## Toolchain layer: Flutter

What the session above did by hand, as a script:

```sh
version=3.44.5   # read from .github/workflows/checks.yml
curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${version}-stable.tar.xz" | tar -xJ -C "$HOME"
git config --global --add safe.directory '*'   # the SDK is a git checkout owned by another uid
"$HOME/flutter/bin/flutter" --disable-analytics
```

Points to settle when it is built:

- **PATH.** `scripts/check.sh` already falls back to `$HOME/flutter/bin`, but a bare `flutter` in Claude's shell needs `PATH` set in a file that shell reads.
  Which file that is (`~/.bashrc`, `/etc/profile.d/`, the environment's variables) has to be checked.
- **Idempotent.** The script runs again whenever the snapshot is rebuilt. It should skip the download when `~/flutter` already has the pinned version.
- **The repo may not be there yet.** The docs do not say whether the clone happens before the setup script.
  Until that is checked, the environment's setup script fetches the repo script from `raw.githubusercontent.com` rather than running it from the checkout.

## Release build: a later phase

Update 2026-09-26: a debug build now works in the `Default` environment, set up by hand, in [`../26_cloud_android_build/00_start.md`](../26_cloud_android_build/00_start.md). Its findings (the Maven Central rate limit, the mirror script, the time and disk a first build takes) feed the setup script here.

Out of scope now. What it needs, so the phase does not start cold:

- **Network.** The Android command-line tools come from `dl.google.com`, which is refused today.
  It needs Custom access with `dl.google.com` added to the defaults. `maven.google.com`, which Gradle uses, already answers.
  Settled by Q7: the Flutter environment is created with that access from the start, so this phase needs no network change.
- **SDK packages.** `platform-tools`, `platforms;android-36`, a matching `build-tools`, and the NDK version Flutter selects (`ndkVersion = flutter.ndkVersion` in `android/app/build.gradle.kts`).
  Their sizes and download times are unknown until measured. The NDK is the one that may not fit in the five-minute budget.
  The docs' answers are parallel downloads with `&` and `wait`, or a download started in the background from a SessionStart hook.
- **Java.** The base image ships OpenJDK 21, and `docs/build-and-release.md` lists Java 17. Whether this build accepts 21 is unknown: one of them is wrong, and a build will say which.
- **Signing.** Environment variables are visible to anyone using the environment, so `key.properties` values cannot go there.
  [`../19_apk_distribution/00_start.md`](../19_apk_distribution/00_start.md) Q4 already recommends that the release key stay off the dev box.
  The same answer here means cloud builds are debug-signed, which is what the release build does anyway when `key.properties` is absent.
- **Getting the APK out.** The container is discarded after the session, so a built APK has to leave by a GitHub release or a push.
  That is folder 19's question, so it waits for that folder's answer.
- **No emulator.** There is no `/dev/kvm`, so the headless-emulator end-to-end test does not run here.

## One script, and the Dockerfile question

A Dockerfile cannot be the session's environment: the base image cannot be replaced.
It could still be:

- **a local test harness for the script.** `FROM ubuntu:24.04` plus the setup script.
  Testing a change to the script otherwise means changing the environment and starting a session, which rebuilds the snapshot each time.
  The harness is only an approximation, because Anthropic's image carries tools a plain Ubuntu image does not.
- **a self-hosted runner image.** That is an organization-level setup, far outside this repo.
- **a sidecar via `docker compose`.** No use for Flutter: Claude's shell runs on the VM, not in the sidecar.

So the single source is one idempotent bash script, and the environment's setup script is a few lines that fetch and run it.
A Dockerfile is optional, and only earns its place if changing the script by trial sessions gets slow.

## Docs this will make stale

- `.github/copilot-instructions.md`, "Which machine", knows two machines: a headless dev box, and g7 for devices and every `git push`.
  A cloud session is a third, and it can push. That section needs the cloud session as a third entry.
- `docs/getting-started.md` needs a section for starting in a cloud session.
- `docs/build-and-release.md` and the Java version, once a build has settled it.

## Candidate phases

Not derived yet; a sketch for when this is picked up.

1. Personal layer: create the Flutter environment (Q2, Q7), with a setup script that clones dotfiles and runs the installer. Check that `CLAUDE.md` and the skills load in a new session there.
2. Toolchain: the Flutter script, `PATH`, and the SessionStart hook for `pub get`. Done when a new session runs `scripts/check.sh` green with no manual step.
3. Docs: the "Which machine" entry and the getting-started section.
4. Release build: the Android SDK and network access, gated on folder 19.

## Open questions

- Q1: where does the setup script live?
  a. all of it in this repo, `scripts/`.
  b. all of it in dotfiles.
  c. the personal layer in dotfiles, the Flutter layer here, and the environment's setup script calls both.
  Recommended: c, because the Flutter pin belongs with the repo that CI builds, and the dotfiles layer is the same for every repo.
  ANS: c.
- Q2: one cloud environment for every repo, or one per stack?
  The setup script and network level belong to the environment, not the repo, so a Flutter environment carries 3 GB that a Python repo does not need.
  a. one environment with dotfiles and every toolchain.
  b. one environment per stack, each running the dotfiles layer first.
  Recommended: b, because the snapshot is per environment, and a per-stack script stays inside the five-minute budget.
  ANS: b. `Default` stays as a temporary environment; a new one is created for the Flutter stack, and the setup script is verified there.
- Q3: the dotfiles `settings.json` in the cloud?
  a. link it unchanged and install `rtk` in the setup script.
  b. leave it out of the cloud and link only `CLAUDE.md`, rules and skills.
  c. a cloud variant of it in dotfiles.
  Recommended: b for the first phase, since its hooks and model settings are what could break a session, then revisit.
  ANS: b, not linked.
- Q4: skills from dotfiles through the setup script, or enabled on claude.ai?
  Recommended: dotfiles, so there is one copy. Keep claude.ai for skills that are not in dotfiles.
  ANS: dotfiles.
- Q5: which network access level is the environment set to now, and is moving to Custom acceptable when the release phase starts?
  Only the environment settings show the level; `dl.google.com` being refused suggests Trusted.
  ANS: asked where to check. Answered under "Cloud environments": the one environment, `Default`, is Trusted, and the level is shown in its settings.
  The second half is still open, as Q7.
- Q6: a Dockerfile as a local test harness for the script?
  Recommended: not yet. Write the script first, and add the harness only if testing it through new sessions is slow.
  ANS: deferred.

### Second batch (2026-09-25)

- Q7: when the release phase starts, move `Default` to Custom access, or add a second environment for Android builds?
  a. `Default` to Custom: the Trusted defaults plus `dl.google.com`.
  b. a second environment, Custom with `dl.google.com`, used only for release work.
  c. Full access.
  Recommended: follows Q2. With one environment per stack it is a, applied to the Flutter environment; c opens every host to fetch one.
  ANS: a, on the new Flutter environment rather than `Default`, and from its creation rather than when the release phase starts.
