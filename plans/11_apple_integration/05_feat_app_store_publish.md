---
status: draft
---

# Phase 5 - TestFlight + App Store Publish

## Overview

Move from cable side-loading to real distribution: TestFlight for scaled
testing, then App Store review for public release. This phase is gated on a paid
Apple Developer Program membership and on passing Apple's human review.

Context: [`00_intro.md`](00_intro.md), depends on
[`04_feat_ios_cable_demo.md`](04_feat_ios_cable_demo.md).

## Goals

1. Enroll in the Apple Developer Program and register the app record.
2. Archive, sign for distribution, and upload a build.
3. Distribute via TestFlight, then submit for App Store review.

## Plan

### 1. Program + app record
- Enroll in the **Apple Developer Program** ($99/yr); approval can take a day+.
- In **App Store Connect**, register the app with bundle ID `com.fala.app`,
  name, primary language, category (Education).

### 2. Distribution signing
- Create an App Store distribution certificate + provisioning profile (Xcode can
  manage automatically).

### 3. Archive + upload
- Scheme to *Any iOS Device*, *Product > Archive*, upload via Organizer; or
  `flutter build ipa` + Transporter / `xcrun altool`.

### 4. TestFlight
- Internal testing (up to 100 testers, fast) for the scaled demo.
- External testing needs a light review.

### 5. App Store submission
- Required metadata: privacy policy URL, App Privacy questionnaire (declare
  on-device processing + any network calls), screenshots for required device
  sizes, age rating, export-compliance answer (encryption).
- Submit for review.

## Blockers

- **App Review** is a human gate: common rejections for missing privacy policy,
  incomplete metadata, crashes, or unclear AI/data handling. Describe the
  on-device model + any cloud fallback accurately.
- **Export compliance**: the app uses encryption (HTTPS/Keychain) - answer the
  questionnaire (usually exempt, but must be declared).
- Screenshots required for specific device sizes - generate from the simulator.
- The ~1.2GB runtime model: be ready to justify the download-on-first-run UX;
  Apple scrutinizes large/unclear post-install downloads.

## Out of scope

- macOS App Store / notarized distribution (separate effort if Phase 3 ships).
- Marketing, ASO, paid acquisition.

## Done when

- A build is live on TestFlight and installable by an invited tester.
- The App Store submission is accepted (or the review feedback is logged for the
  next iteration).
