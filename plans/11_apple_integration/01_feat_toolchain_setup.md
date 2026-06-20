---
status: planned
---

# Phase 1 - macOS Toolchain Setup

## Overview

Get a fresh Mac from zero to a working Flutter dev environment that can build
this repo. This is the foundation phase: nothing else in this initiative can
start until `flutter doctor` is clean and the repo's codegen runs.

Context: [`00_intro.md`](00_intro.md).

## Goals

1. Install and configure git, Homebrew, Xcode, Flutter, CocoaPods, VS Code, and
   Claude Code.
2. Clone the repo and produce a clean `flutter doctor`.
3. Run the project's code generation so the app analyzes without errors.

## Plan

### 1. Xcode + Apple toolchain
- Install **Xcode** from the App Store (~10GB+).
- `sudo xcodebuild -runFirstLaunch` and accept the license.
- `xcode-select --install` for command line tools.
- Apple Silicon: `softwareupdate --install-rosetta` if any tool needs it.

### 2. Package manager + git
- Install **Homebrew** (https://brew.sh).
- git ships with the CLT; set `git config --global user.name` / `user.email`.
- Generate an SSH key, add it to the Git host.

### 3. Flutter + CocoaPods
- `brew install --cask flutter` (or manual tarball + PATH).
- `sudo gem install cocoapods` (required for iOS/macOS plugin linking).
- `flutter doctor` and resolve every line.

### 4. Editor + agent
- `brew install --cask visual-studio-code`.
- Install the Flutter and Dart VS Code extensions.
- Install and authenticate **Claude Code**.

### 5. Repo bring-up
- Clone the repo.
- `flutter pub get`.
- `dart run build_runner build --delete-conflicting-outputs` (freezed /
  riverpod / json codegen).
- `flutter analyze` is clean.

## Blockers

- `flutter doctor` flags missing CocoaPods, unaccepted Xcode license, or no
  simulators - fix each before continuing.
- An **Apple ID** is enough for this phase; the paid **Apple Developer Program**
  ($99/yr) is only needed in phases 4-5.

## Out of scope

- Android SDK setup (Phase 2).
- Generating `ios/` or `macos/` folders (Phases 3-4).

## Done when

- `flutter doctor` shows no errors (Android section may still warn until
  Phase 2).
- `flutter analyze` passes on a clean clone after codegen.
- Claude Code runs in the repo.
