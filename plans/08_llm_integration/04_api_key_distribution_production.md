# API key distribution - production hardening (deferred)

Status: **plan only, not in scope for the current phase**. The current internal-alpha
build uses user-supplied keys held in Android Keystore - see
[`03_openai_integration.md` - API key distribution / Internal alpha](03_openai_integration.md).

This document captures what a public-distribution build would need so we do not have
to rediscover it later.

---

## Why the alpha approach does not generalise

The alpha model puts the operational cost and abuse risk on the tester, who supplies
their own OpenAI key. In a public Play Store release:

- We cannot expect every user to own and paste an OpenAI key.
- If we ship our own key in the APK in any form (`--dart-define`, asset file,
  obfuscated string, native constant), it is recoverable. A Flutter release APK is a
  ZIP, and `libapp.so` is parseable enough that string constants and Dart-compiled
  literals leak out. Obfuscation slows down extraction, it does not prevent it.
- Even rate-limited per-key, an exposed key can be drained quickly.

So a production deployment needs a **server-side key + an attested client**.

---

## Reference architecture: backend proxy + Play Integrity

```
Flutter app
  |
  | 1. fetch attestation token (Play Integrity API)
  v
Play Integrity service
  |
  | 2. signed token returned to app
  v
Flutter app
  |
  | 3. POST /v1/infer  (Authorization: Bearer <attestation token>,
  |                     X-User-Session: <opaque session id>)
  v
Our backend (e.g. FastAPI on Render/Cloud Run)
  |
  | 4. verify token with Google Play Integrity API server-side
  | 5. apply per-session quota / rate limit
  | 6. forward to OpenAI with the server-held key
  v
OpenAI API
```

### Component responsibilities

**Client (Flutter app)**
- Requests a Play Integrity token per call (or per session, cached briefly).
- Talks only to our backend; never embeds an OpenAI key.
- Surfaces failures as `InferenceFailure` with user-readable reasons
  (quota exceeded, attestation failed, network down, etc.).
- Implements exponential backoff for 429 and 5xx responses.

**Backend proxy**
- Single endpoint `POST /v1/infer` mirroring the
  [`InferenceRequest`](../../lib/services/inference/inference_engine.dart) shape.
- Verifies the Play Integrity token on every request:
  - `appRecognitionVerdict == PLAY_RECOGNIZED`
  - `deviceRecognitionVerdict` includes `MEETS_DEVICE_INTEGRITY`
  - Nonce matches a server-issued challenge to prevent replay.
- Holds the OpenAI key in a secret store (Render env var / Cloud Run secret /
  AWS Secrets Manager). Never logs it. Rotates on a schedule.
- Enforces per-install and per-IP rate limits (e.g. Redis token bucket).
- Optionally caches identical prompts to reduce cost.
- Returns the same `InferenceSuccess`/`InferenceFailure` JSON the client
  already expects, so `OpenAiInferenceEngine` can be swapped for a thin
  `ProxyInferenceEngine` without touching higher layers.

**OpenAI**
- Sees one server identity, one key. Easy to revoke and rotate.
- Subject to whatever org-level quotas we configure.

---

## Authentication tiers (weakest to strongest)

Reference table from
[`00.2_llm_integration_report.md`](00.2_llm_integration_report.md#option-b--your-own-backend-proxy-recommended-for-consumer-app),
refined for our context:

| Method | Description | Verdict for our prod build |
|---|---|---|
| Shared secret hardcoded in app | Not safe; extractable. | No. |
| Per-install random token issued on first run | App generates UUID, registers with backend. Easy to forge by anyone with the endpoint. | No on its own. Acceptable only combined with attestation. |
| Firebase App Check | Wraps Play Integrity + reCAPTCHA. Easiest if we already use Firebase. | Yes, if we adopt Firebase. |
| Play Integrity API direct | Same guarantees as App Check, no Firebase dependency. | Yes, default choice given current stack. |
| User accounts (OAuth / email link) | Per-user JWT, server-side rate limit per user. Adds onboarding friction. | Yes if we ever add accounts; until then attestation alone is enough. |

We pick **Play Integrity API + per-install session id** as the default, because:

- It does not force a Firebase dependency.
- It does not require user accounts.
- It gives us "request comes from a genuine, unmodified install of our app on a
  genuine Android device" - which is exactly the property we need to keep abuse low.

---

## Cost and rate-limit controls

Even with attestation, a determined abuser can repeatedly install/uninstall to
get fresh attestation tokens. Defenses:

- Per-attestation-token quota (e.g. N requests / hour / token).
- Per-IP secondary cap.
- Per-account cap if/when accounts exist.
- Hard daily budget enforced server-side; once exceeded, return 503 with a
  user-readable reason and stop forwarding to OpenAI.
- Optional model fallback: if budget tight, downgrade `gpt-4o-mini` to a
  smaller/cheaper model before refusing.

Monitor:

- Cost per active install per day.
- Distribution of requests per attestation token (long tail = abuse).
- 4xx/5xx rate from OpenAI, alert on spikes.

---

## Secret management

- Never check the OpenAI key into git, even encrypted.
- Store in the hosting provider's secret manager.
- Rotate at least every 90 days.
- Set an org-level monthly spend cap in the OpenAI dashboard as a hard ceiling.
- Have a documented incident-response procedure: rotate key, invalidate
  attestations issued before T, push a forced-update flag to the app.

---

## What changes on the client side

The client engine stays trivial. We add one new implementation alongside
`OpenAiInferenceEngine`:

```dart
class ProxyInferenceEngine implements InferenceEngine {
  ProxyInferenceEngine({required this.endpoint, required this.attestor});

  final Uri endpoint;
  final IntegrityAttestor attestor; // wraps Play Integrity client

  @override
  Future<InferenceResult> generate(InferenceRequest request) async {
    final token = await attestor.fetchToken(nonce: _newNonce());
    final response = await http.post(
      endpoint.resolve('/v1/infer'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );
    // map status codes to InferenceSuccess / InferenceFailure
  }
}
```

Switching from "direct OpenAI" to "proxy" is a one-line change in the engine
factory. `StructuredInferenceEngine<T>` is unchanged.

---

## When to actually do this

Triggers that mean "stop deferring, build this":

- We are about to publish on the public Play Store (closed or open testing
  beyond a known group counts).
- We want the app usable without the user owning an OpenAI account.
- Monthly OpenAI spend from real testers exceeds a budget threshold we want
  to control centrally.

Until any of those is true, the alpha approach in
[`03_openai_integration.md`](03_openai_integration.md) is sufficient.
