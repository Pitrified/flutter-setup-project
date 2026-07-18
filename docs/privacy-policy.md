# Privacy Policy - fala

**Last updated:** 2026-07-18

## Overview

fala is a language-learning app. It can generate tutor responses two ways, and
which one is active determines whether any data leaves your device:

- **On-device model** (Gemma / Qwen3): runs entirely offline after a one-time
  model download. Nothing you type is sent anywhere.
- **OpenAI (cloud)**: your messages are sent to OpenAI to generate a response.
  This is the **default** engine and can be changed in Settings.

## What fala itself collects

fala does **not** run analytics, advertising, or tracking, and does not create
an account or transmit data to servers operated by us. The only outbound network
traffic fala makes is:

1. The one-time download of the on-device model file (no personal data sent).
2. When the OpenAI engine is selected, requests to the OpenAI API (see below).

## OpenAI (cloud) engine

When the OpenAI engine is active:

- The text of your prompt - which includes your conversation content and the
  tutor instructions - is sent to OpenAI over an encrypted (HTTPS) connection so
  OpenAI can generate a reply.
- Processing of that data is governed by **OpenAI's** privacy policy and API data
  usage terms, not by fala. See <https://openai.com/policies/privacy-policy>.
- You supply your own OpenAI API key. It is stored **encrypted on your device**
  (Android Keystore via EncryptedSharedPreferences), never committed, never
  logged, and never sent anywhere except to OpenAI as the request credential.

To keep all data on-device, switch the engine to the on-device model in Settings.

## Local data

The app stores the following on your device only:

- **Conversation history**: your practice conversations, saved on-device for your
  reference.
- **Language model**: the downloaded on-device model file, in app-private storage.
- **OpenAI API key**: encrypted, as described above (only if you set one).
- **App preferences**: basic settings, including the selected engine.

## Data deletion

All local data can be deleted by:

- Clearing app data in Android Settings, or
- Uninstalling the app.

Deleting the API key (clear it in Settings, or clear app data) stops any further
requests to OpenAI. It does not delete data OpenAI may already hold from prior
requests - see OpenAI's policy for that.

## Children's privacy

fala does not knowingly collect data from children under 13. If you enable the
OpenAI engine, note that OpenAI's own age and usage terms apply to that data.

## Changes

We may update this policy. Changes will be noted in app updates and reflected in
the "Last updated" date above.

## Contact

For questions about this policy, contact: pitrified.git@gmail.com
