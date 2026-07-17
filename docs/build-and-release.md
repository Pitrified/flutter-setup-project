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
CPU architecture. We only ship arm64-v8a (phones) and x86_64 (emulators); 32-bit
armeabi-v7a is dropped as unrealistic for an on-device LLM (`plans/12_abi_split/`).
Restrict the ABI set with `--target-platform` and split per architecture so a device
gets only the code it runs:

```bash
flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64
```

Note: the ABI set is controlled here, not in `build.gradle.kts` - `ndk.abiFilters`
conflicts with `--split-per-abi` and is overridden by the Flutter plugin's target-platform
handling, so the flag is the reliable lever. Pass the same `--target-platform` to a plain
`flutter build apk` / `appbundle` to drop v7a from those outputs too.
As a guard, `build.gradle.kts` also excludes `lib/armeabi-v7a/**` via `packaging` jniLibs,
so a build that forgets the flag still ships no v7a libs; the flag remains needed for split
builds so Flutter does not emit an empty armeabi-v7a stub APK.

Outputs (install the arm64 one on any modern physical phone):

| File | Use |
|------|-----|
| `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` | 64-bit ARM - all phones since ~2016 |
| `build/app/outputs/flutter-apk/app-x86_64-release.apk` | emulators on a PC |

Flutter offsets each split's versionCode (adds 1000 / 2000 / ... per ABI). This is harmless for
direct install and for AAB uploads; it only matters if you upload split APKs directly to Play.
For the Play Store, upload the AAB instead (`flutter build appbundle`) - Google splits per ABI
server-side and each user downloads only their architecture.

The release build also excludes the flutter_gemma native libs this app never loads (MediaPipe,
image-generator and RAG `.so` files) via `packaging { jniLibs.excludes }` in
`android/app/build.gradle.kts`; the app runs only the LiteRT-LM / qwen3 path. See
`plans/12_abi_split/` and re-verify that exclude list on flutter_gemma upgrades.

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

`flutter_gemma` bundles native libs for engine paths this app never uses, so the old "<30MB APK"
target is not reachable, but the release build now drops armeabi-v7a and excludes the unused
MediaPipe / image-generator / RAG `.so` files (see `plans/12_abi_split/` and the split-per-ABI
section above). The LLM model downloads separately at runtime and is not counted below.
Measured on 2026-07-11 (Flutter 3.44.0, debug-signed release, on-device inference verified):

| Artifact | Size | Notes |
|----------|------|-------|
| Fat APK (`app-release.apk`, arm64 + x86_64) | 103 MB | both shipped ABIs; avoid for distribution |
| Split APK, arm64-v8a | 43 MB | on-disk; what a phone installs when sideloaded (was 160 MB) |
| Split APK, x86_64 | 48 MB | emulator (was 80 MB) |
| armeabi-v7a | dropped | 32-bit, unsupported (`--target-platform android-arm64,android-x64`) |

The remaining native weight is `liblitertlm_jni.so` (~20 MB, the LiteRT-LM engine this app runs)
plus `libflutter.so` and `libapp.so`. Build split APKs with
`flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64`; for
per-device Play download sizes run `bundletool get-size total --dimensions=ABI` on `app-release.aab`.
An earlier bundletool measurement (2026-07-09, before `libllm_inference_engine_jni.so` was also
excluded) gave a Play download of ~31 MB for arm64-v8a; the current build should come in below that.

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
