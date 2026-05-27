---
status: not-started
depends_on: [docs/getting-started.md, docs/functional-specs.md]
produces: [fala/ (Flutter project root), fala/pubspec.yaml, fala/android/app/build.gradle]
---

# Plan: Create Flutter Project

## Goal

Run `flutter create` to scaffold the project, configure pubspec.yaml with all locked
dependencies, and set Android-specific build config (target/min SDK, package ID).
At the end the app compiles and runs on the emulator showing the default counter screen.

## Steps

### 1. Create the project

```bash
cd /home/pmn/repos/flutter-setup-project
flutter create --org com.fala --project-name fala --platforms android .
```

This creates the project in-place (since we already have the docs/ and plans/ folders).
The `--platforms android` flag prevents iOS/web/desktop scaffolding.

If `flutter create` complains about existing files, use:

```bash
flutter create --org com.fala --project-name fala --platforms android --overwrite .
```

**Verify:** the `lib/main.dart` and `android/` folders exist.

### 2. Configure pubspec.yaml

Replace the generated pubspec.yaml with:

```yaml
name: fala
description: On-device Portuguese language tutor
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: ^3.8.0

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  go_router: ^14.8.1
  hive: ^4.0.0
  hive_flutter: ^1.1.0
  flutter_gemma: ^0.4.1
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  logger: ^2.5.0
  path_provider: ^2.1.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.14
  freezed: ^2.5.8
  json_serializable: ^6.9.4
  riverpod_generator: ^2.6.3
  custom_lint: ^0.7.5
  riverpod_lint: ^2.6.3
  mockito: ^5.4.5
  build_verify: ^3.1.0

flutter:
  uses-material-design: true
  assets:
    - assets/prompts/
    - assets/fixtures/
```

**Notes:**
- Version numbers are approximate; use latest stable at time of execution.
- `flutter_gemma` version may need adjustment based on pub.dev availability.
- If `flutter_gemma` is not yet published, comment it out and add a TODO.

### 3. Configure Android build

Edit `android/app/build.gradle` to set:

```groovy
android {
    namespace = "com.fala.app"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.fala.app"
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.debug  // TODO: proper signing in Phase 07
            minifyEnabled = true
            shrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

Also update `android/build.gradle` (project-level) if needed to use AGP 8.x+.

### 4. Create asset directories

```bash
mkdir -p assets/prompts/tutor_response
mkdir -p assets/fixtures
echo "placeholder" > assets/prompts/tutor_response/.gitkeep
echo "[]" > assets/fixtures/tutor_responses.json
```

### 5. Validate

```bash
flutter pub get
flutter analyze    # should pass (default counter app)
flutter run        # launches on emulator
```

## Key decisions

- Package ID: `com.fala.app` (matches functional-specs.md)
- Project created in repo root (not a subfolder), since flutter-setup-project IS the app repo
- R8/ProGuard enabled in release mode from the start
- No Kotlin/Java source needed (pure Dart + Flutter plugins)

## Acceptance criteria

- [ ] `flutter pub get` succeeds with no dependency resolution errors
- [ ] `flutter analyze` reports no issues
- [ ] `flutter run` launches the app on the API 36 emulator
- [ ] `android/app/build.gradle` has minSdk 26, targetSdk 36, compileSdk 36
- [ ] Package ID is `com.fala.app`
