# Getting Started

Set up a Flutter development environment on Linux (Ubuntu/Debian) from scratch.
After completing this guide you will have `flutter doctor` passing and an
Android emulator running.

## Prerequisites

- OS: Linux (Ubuntu 22.04+ or Debian 12+)
- Disk space: ~10 GB (Flutter SDK + Android SDK + emulator images)
- RAM: 8 GB minimum (16 GB recommended for emulator)
- Already installed: git, curl, unzip, ninja-build, VS Code

Install `ninja-build` if you don't have it - the Android build system requires it:

```bash
sudo apt install ninja-build
```

## Fresh cloud session

A claude.ai cloud session starts from a fresh clone on Ubuntu, as root, with no Flutter and no Android SDK.
Until the cloud environment runs a setup script, install Flutter by hand at the version CI pins, from the repo root:

```bash
version=$(sed -n 's/.*flutter-version: *//p' .github/workflows/checks.yml)
curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${version}-stable.tar.xz" \
  | tar -xJ -C "$HOME"
git config --global --add safe.directory '*'   # the SDK is a git checkout owned by another uid
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/flutter/bin:$PATH"
flutter --disable-analytics
scripts/check.sh
```

The SDK unpacks to about 2.3 GB and the first `pub get` adds about 700 MB, well inside the session's disk.
Claude's shell reads `~/.bashrc` for each command, so the `echo` line puts `flutter` on its `PATH` for the rest of the session; `scripts/check.sh` falls back to `$HOME/flutter/bin` either way.

What this does not give you:

- **The Android SDK.** No APK is built in a cloud session. Its command-line tools download from `dl.google.com`, which the default Trusted network access refuses.
- **Persistence.** The install lives in the session's container and is gone when the container is reclaimed. A new session repeats these steps.

## Install Flutter SDK

```bash
# Clone stable channel
git clone https://github.com/flutter/flutter.git -b stable ~/flutter

# Add to PATH (add this line to ~/.bashrc or ~/.zshrc)
export PATH="$HOME/flutter/bin:$PATH"

# Reload shell
source ~/.bashrc   # or source ~/.zshrc

# Verify
flutter --version

# Enable Android only
flutter config --no-enable-ios --no-enable-web --no-enable-linux-desktop
```

## Install Android toolchain

### Option A: Android Studio (recommended)

1. Download Android Studio from https://developer.android.com/studio
2. Extract and run the installer: `~/android-studio/bin/studio.sh`
3. During setup wizard, install: Android SDK, Android SDK Build-Tools, Android SDK Platform-Tools, **Android SDK Command-line Tools**
4. Install Android 16 (API 36) platform from SDK Manager

Android Studio installs the SDK to `~/Android/Sdk/` by default. Add to PATH:

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
```

### Option B: Command-line tools only

```bash
# Download command-line tools
mkdir -p ~/android-sdk/cmdline-tools
cd ~/android-sdk/cmdline-tools
curl -L -o tools.zip "https://dl.google.com/android/repository/commandlinetools-linux-latest.zip"
unzip tools.zip
mv cmdline-tools latest

# Add to PATH
export ANDROID_HOME="$HOME/android-sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

# Install required components
sdkmanager "platform-tools" "build-tools;34.0.0" "platforms;android-34"
```

### Accept licenses

```bash
flutter doctor --android-licenses
```

## Create Android emulator

```bash
# Install system image
sdkmanager "system-images;android-34;google_apis;x86_64"

# Create AVD
avdmanager create avd --name dev_phone --device pixel_7 \
  --package "system-images;android-34;google_apis;x86_64"

# Launch emulator
emulator -avd dev_phone &

# Verify Flutter sees it
flutter devices
```

## VS Code extensions

Install these extensions:

- **Dart** (`dart-code.dart-code`) - Dart language support
- **Flutter** (`dart-code.flutter`) - Flutter tooling

Optional but recommended:

- **Error Lens** (`usernamehw.errorlens`) - inline error display; add this to your VS Code settings to suppress noisy spelling warnings:
  ```json
  "errorLens.excludeByMessage": ["Unknown word."]
  ```
- **GitLens** - git history

## Validate setup

```bash
# Full diagnostic
flutter doctor -v
```

All checks should be green. If not, follow the doctor's suggestions.

### Quick smoke test

```bash
flutter create /tmp/test_app && cd /tmp/test_app && flutter run -v
```

Confirm the demo app launches on the emulator. Then delete it:

```bash
rm -rf /tmp/test_app
```

## Project-specific setup

After cloning this repo:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
scripts/install-hooks.sh   # runs the gates on every commit
flutter run
```

## Gates

`scripts/check.sh` is the one command that runs every check: markdown links resolve,
the plan folders agree with their convention, codegen, `dart format`, `flutter analyze`, `flutter test`.
CI runs the same script, and `scripts/install-hooks.sh` points git at `.githooks` so a
commit runs it too (bypass with `git commit --no-verify`).

```bash
scripts/check.sh                   # one line per gate
scripts/check.sh -v                # every gate's full output
python3 scripts/gates/links.py     # one gate on its own
```

It is quiet by default: one line per gate, being that gate's own summary, and the
full output of any gate that fails. `-v` prints everything, which is worth it when
a gate passes and you still want to see what it did.

Gates run in this order: links, plans, codegen, format, analyze, test.
The format gate runs `dart format` over `git ls-files '*.dart'` and fails naming each file it would change; fix with `git ls-files -z '*.dart' | xargs -0 dart format`. Codegen is in the list
because `*.freezed.dart` and `*.g.dart` are gitignored, so a fresh checkout has
none and analyze fails on every freezed type. Warm it costs about 2s.

**Reproducing CI locally.** A pass on a working tree proves less than it looks:
your tree has generated files and a warm `.dart_tool` that a CI runner does not.
Clone the repo and run the gates in the clone, which is what CI checks out:

```bash
git clone --no-hardlinks . /tmp/fala-clean && cd /tmp/fala-clean
scripts/check.sh                   # ~2 min cold, mostly pub get and codegen
```

The workflow pins the same Flutter version this box runs, so the two are
comparable. Until that clone is green, CI is a guess.

## End-to-end on an emulator

`scripts/e2e.sh` is the slow check, kept out of `check.sh` because it takes minutes and needs an
emulator. It boots a headless AVD (`fala_api36`), starts the mock OpenAI server
(`tool/mock_openai.py`), and runs `integration_test/app_test.dart` against it, so a full conversation
is exercised with no API key and no network. Logs and the app's actual requests land in `build/e2e/`.

```bash
scripts/e2e.sh                     # reuse a running emulator, or boot one
scripts/e2e.sh --stop-emulator     # and shut it down afterwards
```

To drive the app by hand instead, `source tool/adb_ui.sh` gives `ui_tap`, `ui_text`, `ui_shot` and
friends, which find widgets in the view tree rather than guessing coordinates.

### How the app is pointed at the mock

`OPENAI_BASE_URL` is a compile-time define, read once in
`lib/services/inference/openai_inference_engine.dart` and empty by default, which
means the real API:

```bash
flutter run --dart-define=OPENAI_BASE_URL=http://10.0.2.2:8080/v1
```

- **It is a build-time define, not a Settings field.** A visible "API endpoint" box
  in a shipped app is a way to have someone's key sent elsewhere, and the value is a
  test fixture rather than a preference.
- **From an emulator the host is `10.0.2.2`**; `127.0.0.1` there is the emulator
  itself. `adb reverse tcp:8080 tcp:8080` makes `127.0.0.1` work too, on an emulator
  or a cabled phone.
- **Cleartext HTTP is debug-only**, granted by
  `android/app/src/debug/AndroidManifest.xml` and a network security config that
  permits `10.0.2.2`, `127.0.0.1` and `localhost`. Release builds stay strict.
- **The key goes in through the app's own Settings field.** The integration test
  types a dummy key and saves it, which exercises secure storage rather than adding
  a debug bypass to the one part of the app that handles a secret.

### What the mock does not prove

`tool/mock_openai.py` answers with scripted text whatever it is asked: it does not
validate the request against our JSON schema. So these runs prove the app handles a
well-formed OpenAI response, not that our `response_format` is one OpenAI accepts.
Only a real call with a real key proves that, and it stays a manual check.

The same reasoning keeps `scripts/e2e.sh` out of CI: a KVM-accelerated emulator in
GitHub Actions is slow and flaky, and `check.sh` has to stay fast enough that nobody
skips it.

## Target versions

| Concern | Value |
|---------|-------|
| Development API level | Android 16 (API 36) |
| Minimum release API | Android 8.0 (API 26) |
| Flutter channel | stable |

## Migrating from API 34 to API 36

If you previously set up your environment targeting API 34 (Android 14), follow these
steps to upgrade to API 36 (Android 16).

### 1. Install the new platform

**Android Studio:** Open SDK Manager (Tools > SDK Manager), check "Android 16 (API 36)"
under SDK Platforms, click Apply.

**CLI:**

```bash
sdkmanager "platforms;android-36" "build-tools;36.0.0"
```

### 2. Update the emulator

Create a new AVD with the API 36 system image:

```bash
sdkmanager "system-images;android-36;google_apis;x86_64"
avdmanager create avd --name dev_phone_36 --device pixel_7 \
  --package "system-images;android-36;google_apis;x86_64"
```

You can keep the old AVD for regression testing or delete it:

```bash
avdmanager delete avd --name dev_phone
```

### 3. Update the Flutter project (once scaffolded)

In `android/app/build.gradle`:

```groovy
android {
    compileSdk = 36

    defaultConfig {
        minSdk = 26
        targetSdk = 36
    }
}
```

### 4. Verify

```bash
flutter doctor    # should show Android SDK 36
flutter run       # should launch on the API 36 emulator
```

### Notes

- The old API 34 SDK can remain installed (it takes minimal disk space).
- Removing it: `sdkmanager --uninstall "platforms;android-34"`.
- If gradle sync fails after the bump, run `flutter clean && flutter pub get`.
