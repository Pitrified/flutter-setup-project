---
status: draft
depends_on: []
produces: [docs/getting-started.md]
---

# Plan: Dev Environment Setup

## Goal

A Flutter novice on Linux can go from zero to a working dev environment
with `flutter doctor` passing all checks and an Android emulator running.

## Target audience

Complete Flutter beginner. Assume only: Linux (Ubuntu/Debian-based), terminal familiarity,
VS Code installed. No prior Dart, Flutter, or Android SDK knowledge.

## Sections for docs/getting-started.md

### 1. Prerequisites

- OS: Linux (Ubuntu 22.04+ or Debian 12+)
- Disk space: ~10 GB (Flutter SDK + Android SDK + emulator images)
- RAM: 8 GB minimum (16 GB recommended for emulator)
- Tools already installed: git, curl, unzip, VS Code

### 2. Install Flutter SDK

- Download via `git clone` from the stable channel
- Add to PATH (shell rc file)
- Verify: `flutter --version`
- Enable only Android platform: `flutter config --no-enable-ios --no-enable-web --no-enable-linux-desktop`

### 3. Install Android toolchain

- Install Android Studio (for SDK manager and emulator)
- Or: install Android command-line tools only (lighter)
- Accept licenses: `flutter doctor --android-licenses`
- Required SDK components: Android SDK, Build-Tools, Platform-Tools, Android 16 (API 36) platform

### 4. Create Android emulator

- Install system image: `sdkmanager "system-images;android-36;google_apis;x86_64"`
- Create AVD: `avdmanager create avd --name dev_phone --device pixel_7 --package ...`
- Launch: `emulator -avd dev_phone`
- Verify Flutter sees it: `flutter devices`

### 5. VS Code extensions

- Dart (dart-code.dart-code)
- Flutter (dart-code.flutter)
- Optional: Error Lens, GitLens

### 6. Validate setup

- Run `flutter doctor -v` and confirm all green checks
- Create throwaway test app: `flutter create /tmp/test_app && cd /tmp/test_app && flutter run`
- Confirm it launches on emulator
- Delete throwaway app

### 7. Project-specific setup (post Phase 03)

- Clone this repo
- `flutter pub get`
- `dart run build_runner build`
- `flutter run`

(This section is a placeholder until Phase 03 scaffold exists.)

## Key decisions

- Android Studio is recommended over CLI-only because it provides the emulator GUI,
  but the doc should cover both paths.
- Target API level: Android 16 (API 36) for development, minimum SDK 26 (Android 8) for release.
- No iOS/Xcode/CocoaPods steps - Android only.

## References

- https://docs.flutter.dev/install/manual (pick Linux instructions)
- https://docs.flutter.dev/platform-integration/android/setup (pick Linux instructions)
- https://developer.android.com/studio/command-line/sdkmanager
