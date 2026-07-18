# Google Play Private Alpha Setup

Manual, one-time-plus-per-release steps to get fala onto testers' phones through
the Play Store without making it public.
Building and signing the AAB is covered separately in
[build-and-release.md](build-and-release.md); this doc is everything you do in the
**Play Console** after you have an AAB.

## 1. Goal

Distribute the app to a small whitelist of testers via the Play Store **without
making it public**. Use **Internal Testing** for fastest turnaround.

---

## 2. Prerequisites

- Google Play Console developer account (one-time $25 fee).
- Identity verification completed (personal ID or D-U-N-S for an org; can take
  days - start early).
- A signed AAB built per [build-and-release.md](build-and-release.md#production-signing-required-for-play-store):
  ```bash
  flutter build appbundle --release
  ```
  Output: `build/app/outputs/bundle/release/app-release.aab`.
- A privacy policy URL hosted somewhere stable (GitHub Pages is acceptable).
  Source lives in [privacy-policy.md](privacy-policy.md).

---

## 3. Track choice

| Track          | Max testers  | Approval delay | Use when                  |
| -------------- | ------------ | -------------- | ------------------------- |
| **Internal**   | 100          | Minutes        | **Default for alpha**     |
| Closed (Alpha) | Larger lists | ~hours         | When > 100 testers needed |
| Open           | Public       | Hours/days     | Not for alpha             |

---

## 4. App creation (one-time)

Play Console → **Create app**:

- App name: `fala`
- Default language: English (US)
- App or Game → **App**
- Free / Paid → **Free**
- Category: **Education**
- Declarations: ads (No), Play content guidelines, US export laws

Package name is fixed by the build: `com.fala.app` (set as `applicationId` in
`android/app/build.gradle.kts`). It cannot be changed after the first upload.

---

## 5. Store listing (minimal, still required)

Even an internal release needs a main store listing filled in:

- Title: `fala - Portuguese Tutor`
- Short description: `Practice Portuguese with an on-device AI tutor`
- Full description: 2-3 paragraphs about AI-assisted language practice (cloud
  via OpenAI by default, or a fully on-device model - see privacy policy)
- App icon: 512x512 PNG
- Feature graphic: 1024x500 banner
- Phone screenshots: at least 2 (e.g. welcome + conversation)

---

## 6. Required pre-launch forms (even for internal track)

These block AAB upload or rollout if missing:

- [ ] **App access** - describe demo flow if any login (none for alpha →
      "All functionality available without restrictions")
- [ ] **Ads** - declare No
- [ ] **Content rating** - fill the IARC questionnaire (no violence, no user-to-user
      communication, no purchases → expected rating **Everyone**)
- [ ] **Target audience** - pick age group
- [ ] **News app** - No
- [ ] **COVID-19 contact tracing** - No
- [ ] **Data safety** - declare what's collected (see note below)
- [ ] **Government app** - No
- [ ] **Financial features** - No
- [ ] **Health** - No
- [ ] **Privacy policy URL**

Data Safety for fala depends on the active engine (see
[privacy-policy.md](privacy-policy.md)):

- fala runs **no** analytics, ads, or tracking of its own.
- The **default OpenAI (cloud) engine** sends the user's messages to OpenAI to
  generate replies. That is a third-party data transfer and must be declared:
  under Data Safety, mark **Messages / other user content** as *collected and
  shared with a third party* for **App functionality**, over an encrypted
  connection. Do **not** declare "No data shared" while OpenAI is the default.
- Only if you ship with the on-device engine forced and the OpenAI path removed
  could you honestly declare *No data collected, no data shared*.

Keep this honest and re-check it whenever the default engine or any network path
changes.

---

## 7. Tester whitelisting (Internal track)

1. **Testing → Internal testing → Testers tab**.
2. Create an email list (or use a Google Group).
3. Add tester emails (must be Gmail / Google-account-linked addresses).
4. Save. Share the **opt-in URL** shown on the page with testers.

Testers must:

1. Click the opt-in URL while signed in to the device's Google account.
2. Wait a few minutes for propagation.
3. Install via Play Store (search by package name `com.fala.app` or use the test link).

---

## 8. Build upload

1. **Internal testing → Create new release**.
2. Upload `build/app/outputs/bundle/release/app-release.aab`.
3. Release name: matches the version name (e.g. `0.1.0-alpha1`).
4. Release notes: 1-3 lines, plain English, what changed.
5. **Save → Review release → Start rollout to Internal testing**.

First upload only:

- If you let Google manage app signing (recommended), you upload with your
  **upload key** (the keystore from build-and-release.md) and Google re-signs
  with the app signing key it holds.
- Play scans the AAB and surfaces warnings (target SDK, deprecated APIs,
  permissions). Resolve **all** errors; warnings are a judgment call - document
  any waivers.

---

## 9. Iteration loop

```
edit → build release AAB → bump versionCode → upload new release → testers update from Play Store
```

Testers normally get the update within minutes. Force-refresh: open Play Store →
app page → pull to refresh.

---

## 10. Versioning conventions

Single source of truth: the `version:` line in `pubspec.yaml`
(`version: <name>+<versionCode>`, e.g. `0.1.0+1`). The part after `+` is the
Android `versionCode`.

```
0.1.0-alpha1   version: 0.1.0+1     (versionCode 1)
0.1.0-alpha2   version: 0.1.0+2     (versionCode 2)
0.1.0-beta1    version: 0.1.0+20    (versionCode 20)
0.1.0          version: 0.1.0+100   (versionCode 100)
```

Always strictly increasing `versionCode`. Once uploaded, a versionCode cannot be
reused.

Note: `--split-per-abi` APKs get a per-ABI versionCode offset from Flutter (see
[build-and-release.md](build-and-release.md#smaller-apks-split-per-abi)). This
does **not** apply to the AAB - upload the single AAB and let Google split per ABI
server-side, so each user downloads only their architecture.

---

## 11. What testers see

- Listed as **(Unreleased)** on their Play Store page - fine.
- Can leave private feedback via the opt-in page.
- If they uninstall and reinstall, conversation history and downloaded model are
  **gone** (local-only persistence; the model re-downloads on first launch).

---

## 12. Pulling a release

If a build is broken:

1. **Internal testing → Releases overview → Halt rollout** (instant).
2. Upload a new build with a higher versionCode.
3. Do **not** delete the previous AAB; it's needed for diffing.

---

## 13. Common rejection reasons

| Reason                          | Fix                                                            |
| ------------------------------- | ------------------------------------------------------------- |
| Target SDK too low              | Bump `targetSdk` in `android/app/build.gradle.kts` (currently 36) |
| 32-bit-only AAB                 | Ship arm64-v8a; armeabi-v7a is already dropped (see build-and-release.md) |
| Missing Data Safety form        | Fill in §6                                                    |
| Privacy policy URL 404          | Host a stable page                                            |
| Permissions declared but unused | Trim from `AndroidManifest.xml` or justify in console         |

---

## 14. Verification

- Install from the Play Store internal link on a physical device.
- App launches, model downloads on first run, a conversation works end to end.

---

## 15. Future improvements

- Automate AAB upload via the [Google Play Developer Publishing API](https://developers.google.com/android-publisher) from CI.
- Promote to the Closed track once tester count > 50.
- Generate release notes from the git log.
