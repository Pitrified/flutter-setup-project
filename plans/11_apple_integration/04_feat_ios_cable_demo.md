---
status: draft
---

# Phase 4 - iOS Build + iPhone Cable Demo

## Overview

Generate the `ios/` runner and side-load a development build onto a physical
iPhone over cable for a private demo. iOS is the well-supported Apple path:
`flutter_gemma`/MediaPipe GenAI runs on iOS, so the main work is signing and
on-device provisioning rather than engine viability.

Context: [`00_intro.md`](00_intro.md), depends on
[`01_feat_toolchain_setup.md`](01_feat_toolchain_setup.md).

## Goals

1. Generate the iOS platform folder and link CocoaPods.
2. Sign with a development profile and deploy to a connected iPhone.
3. Run a core flow on-device, including the on-device model.

## Plan

### 1. Generate platform
- `flutter create --platforms=ios .` (adds `ios/`).

### 2. Signing in Xcode
- Open `ios/Runner.xcworkspace`.
- Signing & Capabilities: select Team (Apple ID = free provisioning; paid for
  more), set bundle ID to `com.fala.app` (must be unique for the store later).
- Add capabilities: Keychain Sharing (secure storage); confirm network/ATS is
  fine for the `openai_dart` endpoints.

### 3. Plugin support
- Confirm `flutter_gemma`/MediaPipe min iOS version and device capability (the
  ~1.2GB model needs a capable device + free storage).
- Set the iOS deployment target in the Podfile; `cd ios && pod install`.

### 4. On-device deploy
- Plug in iPhone, trust the computer, enable **Developer Mode**
  (Settings > Privacy & Security).
- `flutter run -d <device-id>` (or Run from Xcode).
- On first launch, trust the developer cert
  (Settings > General > VPN & Device Management).

## Blockers

- **Free provisioning profiles expire after 7 days** - the app stops launching
  and must be redeployed. Paid membership gives 1-year profiles.
- "Untrusted Developer" until the cert is trusted on-device.
- Model size: download-at-launch over cellular / low storage can fail; consider
  Wi-Fi-only download UX.
- Bundle ID collision if `com.fala.app` is already registered elsewhere.

## Out of scope

- TestFlight / App Store distribution (Phase 5).
- macOS desktop (Phase 3).

## Done when

- A development build launches on a physical iPhone over cable.
- A core conversation flow runs on-device, including model download + inference.
