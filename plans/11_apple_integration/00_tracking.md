# Phase 11 - Apple Integration: tracking

Take `fala` (currently Android-only, on-device `flutter_gemma`/MediaPipe tutor)
from a clean Mac to live on Apple platforms: set up the toolchain, rebuild the
Android APK to validate it, port to macOS, demo on iPhone over cable, and
publish via TestFlight + App Store. Orientation and analysis in
[`00_intro.md`](00_intro.md).

## Key decisions

- **iOS is the supported path; macOS is the risk.** `flutter_gemma`/MediaPipe
  runs on iOS; macOS desktop support is unconfirmed. Phase 3 must resolve the
  macOS engine story (native vs `openai_dart` cloud fallback vs preview-only)
  before any macOS UI work.
- **A physical Mac + Xcode is a hard requirement** for all iOS/macOS build,
  sign, and archive steps. No cloud-free workaround in scope.
- **Apple ID is enough for phases 1-4** (free provisioning, 7-day profiles); the
  paid **Apple Developer Program ($99/yr)** is required only for Phase 5.
- **Phase 2 (Android APK from CLI) is doable without Android SDK Studio** - SDK
  command-line tools + JDK only; it is a toolchain-validation step, not new
  product work.

## Phases

| #  | Phase                          | Plan                                                          | Status  |
| -- | ------------------------------ | ------------------------------------------------------------ | ------- |
| 1  | macOS toolchain setup          | [`01_feat_toolchain_setup.md`](01_feat_toolchain_setup.md)   | planned |
| 2  | Android APK from CLI           | [`02_feat_android_apk_cli.md`](02_feat_android_apk_cli.md)   | planned |
| 3  | macOS desktop port             | [`03_feat_macos_port.md`](03_feat_macos_port.md)             | draft   |
| 4  | iOS build + iPhone cable demo  | [`04_feat_ios_cable_demo.md`](04_feat_ios_cable_demo.md)     | draft   |
| 5  | TestFlight + App Store publish | [`05_feat_app_store_publish.md`](05_feat_app_store_publish.md) | draft |

Status values: draft / planned / in progress / done / superseded / discarded.

## Log

Append-only. Newest at the bottom.

- 2026-06-20 : bootstrapped phase 11 folder from `00_intro.md`; drafted phases
  1-5 as `NN_feat_*` sub-plans and this tracking file. Phases 1-2 set to
  `planned` (well-understood), phases 3-5 left `draft` pending the macOS engine
  decision and Apple Developer enrollment.
