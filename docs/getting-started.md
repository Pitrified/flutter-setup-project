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
4. Install Android 14 (API 34) platform from SDK Manager

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
flutter run
```

## Target versions

| Concern | Value |
|---------|-------|
| Development API level | Android 14 (API 34) |
| Minimum release API | Android 8.0 (API 26) |
| Flutter channel | stable |
