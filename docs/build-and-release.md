# Build and Release

## Prerequisites

- Flutter SDK (stable channel)
- Android SDK (API 26+)
- Java 17

## Quick start (testable APK, no signing setup needed)

The release build falls back to debug signing when `key.properties` is absent.
This is sufficient for testing on your own device:

```bash
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

Or simply:
```bash
flutter run --release
```

### Smaller APKs (split per ABI)

The default `flutter build apk` produces one fat APK carrying native libraries for every
CPU architecture (arm64-v8a, armeabi-v7a, x86_64). For direct install it is faster to build
one APK per architecture and hand a device only the one it runs:

```bash
flutter build apk --release --split-per-abi
```

Outputs (install the arm64 one on any modern physical phone):

| File | Use |
|------|-----|
| `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` | 64-bit ARM - all phones since ~2016 |
| `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` | 32-bit ARM - legacy devices |
| `build/app/outputs/flutter-apk/app-x86_64-release.apk` | emulators on a PC |

Flutter offsets each split's versionCode (adds 1000 / 2000 / ... per ABI). This is harmless for
direct install and for AAB uploads; it only matters if you upload split APKs directly to Play.
For the Play Store, upload the AAB instead (`flutter build appbundle`) - Google splits per ABI
server-side and each user downloads only their architecture.

### Debugging a live app on device

If the app crashes or misbehaves on device:

```bash
# Run in debug mode (hot reload, full error messages)
flutter run

# Run in profile mode (release performance, some debug info)
flutter run --profile

# View real-time logs from a release APK already installed
adb logcat | grep -i "flutter\|fala\|Fatal\|AndroidRuntime"

# Filter to just your app's process
adb logcat --pid=$(adb shell pidof com.fala.app)

# Clear old logs first
adb logcat -c && adb logcat | grep -i "flutter\|Fatal"
```

Key things to look for in logcat:
- `FATAL EXCEPTION` - unhandled crash
- `FlutterError` - Dart-side exception
- `E/flutter` - Flutter engine errors

## Production signing (required for Play Store)

### 1. Generate a keystore

```bash
keytool -genkey -v -keystore ~/cred/fala/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

You will be prompted to set a **store password** and **key password**.
These are passwords you choose - remember them for the next step.

### 2. Create key.properties

Copy the template:
```bash
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties` with the values you set during keytool:
```properties
storePassword=the_password_you_chose
keyPassword=the_password_you_chose
keyAlias=upload
storeFile=/home/you/cred/fala/upload-keystore.jks
```

This file is gitignored and never committed.

### 3. Build signed APK or AAB

```bash
# APK (for direct install)
flutter build apk --release

# App Bundle (for Play Store upload)
flutter build appbundle --release
```

## Build outputs

| Command | Output path |
|---------|-------------|
| APK | `build/app/outputs/flutter-apk/app-release.apk` |
| AAB | `build/app/outputs/bundle/release/app-release.aab` |

## Size budget

The app bundles `flutter_gemma`'s MediaPipe native libraries, so the old "<30MB APK" target is
not reachable while those ship in the binary. The LLM model itself still downloads separately at
runtime and is not counted below. Measured on 2026-07-09 (Flutter 3.44.5, debug-signed release):

| Artifact | Size | Notes |
|----------|------|-------|
| Fat APK (`app-release.apk`) | 273 MB | all three ABIs; avoid for distribution |
| Split APK, arm64-v8a | 160 MB | on-disk; what a phone installs when sideloaded |
| Split APK, x86_64 | 80 MB | emulator |
| Split APK, armeabi-v7a | 40 MB | legacy 32-bit |
| **Play Store download, arm64-v8a** | **64 MB** | compressed delivery from the AAB - the real user number |
| Play Store download, x86_64 | 33 MB | |
| Play Store download, armeabi-v7a | 21 MB | |

Play Store numbers come from `bundletool get-size total --dimensions=ABI` on `app-release.aab`.
arm64 is heaviest because it alone bundles the Gemma/Gecko embedding and MediaPipe vision libs;
trimming unused ones is tracked in `plans/12_abi_split/`.

## Install on device

```bash
# Via flutter
flutter install --release

# Via adb
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Run on emulator

### List available emulators

```bash
flutter emulators
```

### Launch an emulator

```bash
flutter emulators --launch <emulator_name>
```

Or if you already have one running:
```bash
flutter run
```

### Create an emulator (if none exists)

```bash
# Install system image
sdkmanager "system-images;android-34;google_apis;x86_64"

# Create AVD
avdmanager create avd -n fala_test \
  -k "system-images;android-34;google_apis;x86_64" \
  --device "pixel_6"

# Launch
emulator -avd fala_test
```

### Run in release mode on emulator

```bash
flutter run --release
```

Note: The model download URL is a placeholder. On first run, the app will
show the "needs model" screen (expected behavior until a real model server
is configured).

## Version management

Version is in `pubspec.yaml`:
```yaml
version: 0.1.0+1
```
- `0.1.0` = semantic version (shown to users)
- `+1` = versionCode (increment for each Play Store upload)
