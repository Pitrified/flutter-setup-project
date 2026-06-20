# Plan 11/00 - Apple Integration: Zero to Live on macOS/iOS

## Status: draft

## Goal

High-level guide to go from a clean macOS machine to running and shipping
`fala` on Apple platforms: set up the toolchain, build the existing Android
app, adapt the app for macOS/iOS, and distribute to an iPhone (cable demo and
App Store).

This is an orientation document. Each section explains *what* to do, *why*,
and the *blockers* to expect. Detailed task plans (`01_*`, `02_*`, ...) come
later.

## Context

- App: `fala`, on-device Portuguese tutor. App ID `com.fala.app`.
- Engine: `flutter_gemma` (MediaPipe GenAI). The LLM model (~1.2GB) is
  downloaded at runtime, not bundled.
- Today the repo has only an `android/` platform folder. No `ios/` or
  `macos/` directories exist yet - they must be generated.
- Other native dependencies that need per-platform support: `hive` +
  `path_provider` (local storage), `flutter_secure_storage` (Keychain on
  Apple), `openai_dart` (network, no native code).

**Hard prerequisite:** building, signing, and shipping for iOS/macOS requires
a physical Mac with Xcode. There is no supported cloud-free way around this for
the signing/archive steps (CI services like Codemagic/GitHub Actions macOS
runners are the only alternative, out of scope here).

---

## Section 1 - Set up the macOS dev environment

**What:** Get git, VS Code, Flutter, Xcode, and Claude Code working on a fresh
Mac.

Steps:
1. **Xcode** from the App Store (large download, ~10GB+). Then run
   `sudo xcodebuild -runFirstLaunch` and accept the license. Install command
   line tools: `xcode-select --install`. Xcode is required even if you edit in
   VS Code - it provides the iOS/macOS SDKs, simulators, signing, and `xcodebuild`.
2. **Homebrew** (https://brew.sh) - the package manager you will use for the rest.
3. **git** - ships with the command line tools; configure
   `git config --global user.name/user.email`. Add an SSH key to your Git host.
4. **Flutter** - `brew install --cask flutter` (or the manual tarball + PATH).
   Then `flutter doctor` and resolve every line. Run
   `flutter doctor --android-licenses` and `sudo gem install cocoapods`
   (CocoaPods is required for iOS/macOS plugin linking).
5. **VS Code** - `brew install --cask visual-studio-code`, then install the
   Flutter and Dart extensions.
6. **Claude Code** - install per current docs; authenticate.
7. Clone the repo, run `flutter pub get`, then `dart run build_runner build`
   (the project uses freezed/riverpod/json codegen).

**Blockers:**
- `flutter doctor` will flag missing CocoaPods, unaccepted Xcode license, or no
  simulators. Fix each before moving on.
- Apple Silicon vs Intel: some tools need Rosetta (`softwareupdate
  --install-rosetta`).
- An **Apple ID** is enough to start; a paid **Apple Developer Program**
  membership ($99/yr) is needed for on-device signing beyond 7-day free
  provisioning and for any store/TestFlight distribution.

## Section 2 - Build the existing Android app as an APK (without Android Studio)

**What:** Confirm the toolchain works by producing the Android APK you already
ship, from the command line only.

**Yes, doable without Android Studio.** You need the Android SDK + a JDK, not
the IDE.

Steps:
1. Install the SDK command-line tools: `brew install --cask android-commandlinetools`
   and a JDK (`brew install --cask temurin17`). Set `ANDROID_HOME` /
   `JAVA_HOME`.
2. Accept licenses and install platform/build-tools:
   `sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"`,
   then `flutter doctor --android-licenses`.
3. The release signing config reads from `android/key.properties` and a
   keystore at `~/cred/fala/upload-keystore.jks` (see `plans/07_release/00`).
   Recreate that file/keystore on the Mac, or build debug to skip signing.
4. Build:
   - Debug/sanity: `flutter build apk --debug`
   - Release: `flutter build apk --release` (or `appbundle` for Play).
5. Install to a connected Android device: `flutter install` or
   `adb install build/app/outputs/flutter-apk/app-release.apk`.

**Blockers:**
- Missing keystore -> release build fails; copy `key.properties` +
  `upload-keystore.jks` securely (never commit them).
- NDK/AGP version mismatches surface as Gradle errors - match the versions in
  `android/build.gradle.kts`.
- `flutter_gemma` pulls MediaPipe native libs; first build is slow and large.

## Section 3 - Adapt the app for macOS (the deltas)

**What:** Generate the macOS runner and make the app actually run as a desktop app.

Steps:
1. Enable + generate the platform folder:
   `flutter config --enable-macos-desktop`, then
   `flutter create --platforms=macos .` (adds `macos/` without touching Dart).
2. **Dependency reality check** - this is the main blocker. Audit each native
   plugin for macOS support:
   - `flutter_gemma` / MediaPipe: macOS desktop support is **not guaranteed**.
     If unsupported, options are (a) gate the on-device engine off on macOS and
     fall back to the `openai_dart` cloud path, or (b) keep macOS as a
     dev/preview target only. **Verify this first - it decides whether macOS is
     viable at all.**
   - `flutter_secure_storage`: uses macOS Keychain - works, but requires the
     **Keychain Sharing** entitlement.
   - `hive` + `path_provider`: fine on macOS.
3. **Entitlements & sandbox** - edit `macos/Runner/*.entitlements`:
   - `com.apple.security.network.client` (for `openai_dart` + model download).
   - Keychain access group for secure storage.
   - File read/write scope if the model is cached to disk.
4. **Min deployment target** - set in `macos/Podfile` and Xcode (e.g. macOS 11+),
   then `cd macos && pod install`.
5. Run: `flutter run -d macos`. Fix UI that assumes touch/phone sizing (window
   resizing, mouse, larger layouts).

**Blockers:**
- The on-device LLM engine is the make-or-break item. Decide the macOS engine
  story (native vs cloud fallback) before investing in UI polish.
- App Sandbox blocks network/file/keychain by default; missing entitlements
  cause silent runtime failures, not build errors.

## Section 4 - Adapt for iOS and run on an iPhone over cable (custom demo)

**What:** Generate the iOS runner and side-load a development build to a
physical iPhone for a private demo.

Steps:
1. `flutter create --platforms=ios .` to add `ios/`.
2. Open `ios/Runner.xcworkspace` in Xcode. Under **Signing & Capabilities**:
   - Select your Team (Apple ID works for free provisioning; paid for more).
   - Set the bundle identifier to match `com.fala.app` (must be unique on the
     App Store later).
   - Add capabilities: Keychain Sharing (secure storage), and confirm network
     is allowed (iOS allows outbound by default; App Transport Security may need
     config if any non-HTTPS endpoints).
3. **Plugin support** - `flutter_gemma`/MediaPipe **does** support iOS via
   MediaPipe GenAI, but check the min iOS version and device capability (the
   ~1.2GB model needs a capable device + storage). Set the iOS deployment
   target in the Podfile accordingly, then `cd ios && pod install`.
4. Plug in the iPhone, trust the computer, enable **Developer Mode** on the
   device (Settings > Privacy & Security). Then:
   `flutter run -d <device-id>` or Run from Xcode.
5. On the phone, trust the developer certificate
   (Settings > General > VPN & Device Management) the first time.

**Blockers:**
- Free provisioning profiles expire after **7 days** - the app stops launching
  and must be re-deployed. Paid membership gives 1-year profiles.
- "Untrusted Developer" until you trust the cert on-device.
- Model size: download-at-launch over cellular/limited storage can fail;
  consider Wi-Fi-only download UX.
- Bundle ID collisions if the chosen ID is already registered.

## Section 5 - Publish to the App Store (and TestFlight)

**What:** Move from cable side-loading to real distribution.

Steps:
1. **Apple Developer Program** membership ($99/yr) - required. Enroll and wait
   for approval (can take a day+).
2. In **App Store Connect**, register the app record with bundle ID
   `com.fala.app`, name, primary language, category (Education).
3. **Distribution signing** - create an App Store distribution certificate and
   provisioning profile (Xcode can manage automatically).
4. **Archive & upload:** in Xcode, set scheme to *Any iOS Device*, then
   *Product > Archive*, and upload via the Organizer (or
   `flutter build ipa` + `xcrun altool`/Transporter).
5. **TestFlight first** - the same upload appears in TestFlight for internal
   (up to 100 testers, fast) and external (needs a light review) testing. Use
   this for the iPhone demo at scale instead of cable side-loading.
6. **App Store review** - fill required metadata: privacy policy URL, App
   Privacy questionnaire (declare on-device processing + any network calls),
   screenshots for required device sizes, age rating, export-compliance answer
   (encryption usage). Submit for review.

**Blockers:**
- **App Review** is a human gate: rejections for missing privacy policy,
  incomplete metadata, crashes, or unclear AI/data handling are common. The
  on-device model + any cloud fallback must be described accurately in App
  Privacy.
- **Export compliance** - the app uses encryption (HTTPS/Keychain); answer the
  encryption questionnaire (usually exempt, but must be declared).
- Screenshots are required for specific device sizes - generate them from the
  simulator.
- The ~1.2GB runtime model: be ready to justify the download-on-first-run UX;
  Apple dislikes large/unclear post-install downloads.

---

## Summary of the critical path / blockers

| Step | Hard requirement | Top blocker |
| --- | --- | --- |
| Toolchain | Mac + Xcode | Disk space, `flutter doctor` issues |
| Android APK | Android SDK + JDK (no Studio) | Release keystore on new machine |
| macOS port | Generate `macos/`, entitlements | `flutter_gemma` macOS support uncertain |
| iPhone cable demo | Apple ID + Developer Mode | 7-day free-profile expiry |
| App Store | Developer Program ($99/yr) | App Review + privacy/export compliance |

**Decide first:** whether `flutter_gemma` runs on macOS desktop. That single
answer determines whether macOS is a real target or just iOS-via-Mac. iOS is
the well-supported path; macOS is the risk.

## Produces

- This orientation doc. Follow-on detailed plans (`01_*` onward) per section.
