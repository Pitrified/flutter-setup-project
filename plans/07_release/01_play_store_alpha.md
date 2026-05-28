# Plan 07/01 - Play Store Alpha

## Status: not-started

## Goal

Publish the app to Google Play internal testing track for private alpha
distribution.

## Context

- App ID: `com.fala.app`
- Target: Internal testing track (up to 100 testers)
- Content rating: likely "Everyone" (educational, no user-generated content sharing)
- Privacy policy: required even for internal testing

## Tasks

### 1. Create Google Play developer account

- Register at https://play.google.com/console
- Pay one-time $25 fee
- Complete identity verification

### 2. Create app in Play Console

- App name: "fala"
- Default language: English (US)
- App type: App (not game)
- Category: Education
- Free

### 3. Store listing (minimal)

- Title: "fala - Portuguese Tutor"
- Short description: "Practice Portuguese with an on-device AI tutor"
- Full description: 2-3 paragraphs about offline learning
- Screenshots: 2 phone screenshots (welcome + conversation)
- Feature graphic: 1024x500 banner
- App icon: 512x512 (use Flutter's default or create minimal icon)

### 4. Content rating questionnaire

Complete the IARC questionnaire:
- No violence, sexual content, profanity, etc.
- No user-to-user communication
- No in-app purchases
- Expected rating: Everyone

### 5. Privacy policy

File: `docs/privacy-policy.md` (also host at a public URL)

Content:
- App runs entirely offline after model download
- No personal data collected or transmitted
- No analytics, no ads, no third-party services
- Conversation data stored locally only

### 6. Upload AAB and create release

```bash
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` to internal testing track.

### 7. Add testers

- Create email list for internal testers
- Share opt-in link

## Produces

- Play Console app listing
- `docs/privacy-policy.md`
- Store assets (screenshots, graphics)
- Published internal testing release

## Verification

- Install from Play Store internal link on physical device
- App launches, model downloads, conversation works
