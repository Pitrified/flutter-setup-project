# Build and Release

## Prerequisites

- Flutter SDK (stable channel)
- Android SDK (API 26+)
- Java 17
- Release keystore (see below)

## Signing setup (first time)

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload
   ```

2. Copy `android/key.properties.example` to `android/key.properties`

3. Fill in the values:
   ```properties
   storePassword=your_password
   keyPassword=your_password
   keyAlias=upload
   storeFile=/absolute/path/to/upload-keystore.jks
   ```

## Build commands

### Debug APK
```bash
flutter build apk --debug
```

### Release APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Release App Bundle (for Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

## Size budget

Target: <30MB APK (model downloads separately at runtime).

## Install on device

```bash
flutter install --release
```

Or via adb:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Version management

Version is in `pubspec.yaml`:
```yaml
version: 0.1.0+1
```
- `0.1.0` = semantic version (shown to users)
- `+1` = versionCode (increment for each Play Store upload)
