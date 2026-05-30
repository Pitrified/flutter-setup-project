# Plan 07/00 - Build Configuration

## Status: complete

## Goal

Configure release signing, verify APK size budget, and establish
a repeatable release build process.

## Context

Current state:
- `android/app/build.gradle.kts` already has minify + shrink resources enabled
- Release signing currently uses debug keystore (placeholder)
- App ID: `com.fala.app`, min SDK 26, target SDK 36
- Model file (~1.2GB) is downloaded at runtime, not bundled in APK

APK size budget: <30MB (excluding model, which downloads separately).

## Tasks

### 1. Generate release keystore

Create a signing keystore for release builds. Store at
`~/cred/fala/upload-keystore.jks` (not in repo).

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

### 2. Configure signing in Gradle

File: `android/app/build.gradle.kts`

Add `signingConfigs.release` block reading from `key.properties`:
- `storeFile`
- `storePassword`
- `keyAlias`
- `keyPassword`

File: `android/key.properties` (gitignored)

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path>/upload-keystore.jks
```

### 3. Update .gitignore

Add:
```
android/key.properties
*.jks
```

### 4. Version management

Update `pubspec.yaml`:
```yaml
version: 0.1.0+1   # 0.1.0 = private alpha, +1 = versionCode
```

### 5. Build and measure APK

```bash
flutter build apk --release
# Check size:
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

Verify <30MB.

### 6. Document build process

File: `docs/build-and-release.md`

Steps to reproduce a release build from a clean checkout.

## Produces

- Signing configuration in Gradle
- `android/key.properties` template (`key.properties.example`)
- Updated `.gitignore`
- `docs/build-and-release.md`
- Verified APK size

## Tests

- `flutter build apk --release` succeeds without errors
- APK installs and runs on a physical device
