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

Target: <30MB APK (model downloads separately at runtime).

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
