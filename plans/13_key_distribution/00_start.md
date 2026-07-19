# Key distribution - two-step rollout

Status: brain dump / start note. Nothing implemented yet.

Goal: users should not need their own OpenAI API key.
Two steps, increasing effort and safety:

1. **Step 1 - ship a key inside the app** (fastest, weakest).
2. **Step 2 - proxy service on the Linux box** (real key never leaves the box).

Prior art: [`../08_llm_integration/04_api_key_distribution_production.md`](../08_llm_integration/04_api_key_distribution_production.md)
already covers the full production architecture (backend proxy + Play Integrity).
This folder is about the pragmatic in-between: what we can ship now,
and a self-hosted version of the proxy on our own box instead of Render/Cloud Run.

---

## Step 1 - key shipped in the app

### The question: can we encrypt it so only OpenAI can read it?

Short answer: **no, that mechanism does not exist**.

- OpenAI authenticates with a bearer token in the `Authorization` header.
  There is no API surface that accepts an "encrypted key" that only OpenAI can decrypt;
  the plaintext key must exist in app memory at request time to build the header.
- TLS already gives us "only OpenAI can read it *in transit*".
  The problem is not transit, it is **at rest in the APK and at runtime in memory**.
  Anyone with the APK can extract the key (unzip + strings on `libapp.so`),
  and anyone with a rooted device or a proxy cert can read it from the request.
- Asymmetric encryption of the key at rest inside the app does not help:
  the app must be able to decrypt it to use it, so the decryption key ships too.
  This just moves the extraction one step, it does not prevent it.
- Partial exception worth knowing: OpenAI's **Realtime API ephemeral client secrets**
  (server mints a short-lived token, client uses it directly).
  That is the officially supported "client talks to OpenAI without the real key" path,
  but it *requires a server to mint the tokens* - i.e. it is Step 2 in disguise,
  and it only covers the Realtime API, not plain chat/responses calls.
  Verify current scope in the docs when we get there.

### So Step 1 is only viable as a damage-limited throwaway key

If we ship a key anyway (acceptable for a small alpha group, not for public release):

- Use a **dedicated project key**, not the org default:
  separate OpenAI project, only the models we use enabled.
- **Hard monthly budget cap** on that project in the OpenAI dashboard;
  when drained, the app degrades gracefully (`InferenceFailure` with readable reason).
- Light obfuscation only to deter casual extraction
  (`--dart-define` + `--obfuscate`, maybe XOR-split across constants);
  document clearly that this is a speed bump, not security.
- **Rotation plan**: key is revocable at any time; app should handle 401
  by telling the user to update the app. Consider fetching the key at first run
  from a URL we control instead of baking it in - same exposure,
  but rotation then does not require an app update.
- Accept and write down the ceiling: the key WILL be extractable;
  the budget cap is the actual security boundary.

### Open questions for step 1

- Which spend cap is acceptable as a total-loss write-off?
- Bake the key in the APK vs fetch-on-first-run from a static URL on the box?
- Do we gate it behind the existing alpha distribution (known testers) only?

---

## Step 2 - proxy service on the Linux box

The real key lives on the box; the app talks to our service;
we hand-roll the provenance verification of the caller.

### Fit with the box

- Box already runs a **Cloudflare tunnel** (`linux-box-cloudflare` repo),
  so the service gets a public HTTPS endpoint with no port forwarding
  and no TLS cert management on our side.
- OpenAI key stored root-only on the box (same pattern as the tunnel credential:
  root:600 file or env in a systemd unit), never in git.
- Service itself: small HTTP proxy, single endpoint mirroring `InferenceRequest`
  (see the reference architecture in the 08 note - `ProxyInferenceEngine` on the client,
  same `InferenceSuccess`/`InferenceFailure` shapes, one-line swap in the engine factory).
- Language/framework TBD: FastAPI is the obvious default;
  a single-file service kept in a repo under `~/repos`, deployed as a systemd unit.

### Hand-rolled provenance verification - options ladder

Weakest to strongest, composable:

1. **Static shared secret in the app** (HMAC over the request body + timestamp).
   Extractable like the Step 1 key, but the OpenAI key itself is no longer exposed;
   an attacker gets access to *our rate-limited endpoint*, not the raw key.
   This alone is already a big improvement over Step 1.
2. **Per-install registration**: first run generates a UUID, registers with the box,
   box issues a per-install token. Forgeable (anyone can register),
   but gives us per-install rate limiting and revocation.
3. **Nonce challenge**: client asks the box for a nonce, includes it signed in the request;
   kills replay of captured requests.
4. **Play Integrity verification on the box**: the app fetches an integrity token,
   the box verifies it against Google's API (this is still "hand-rolled" -
   just our own code calling Google's verification endpoint, no Firebase).
   This is the only rung that proves "genuine unmodified app on a genuine device".
5. **Allowlist for alpha**: while testers are a known group,
   a manually distributed per-tester token is simple and fully controlled.

Pragmatic pick for now: **1 + 2 + server-side rate limits**, with 4 as the upgrade
path before any public release (the 08 note's trigger list applies unchanged).

### Server-side controls (regardless of auth rung)

- Per-install and per-IP rate limits (token bucket; can start with in-memory,
  Redis only if we ever need multi-process).
- Hard daily budget counter on the box; over budget -> 503 with readable reason,
  stop forwarding to OpenAI.
- Log request counts per install token, never log prompts or the key.
- Key rotation is now trivial: rotate on the box, no app update needed.

### Open questions for step 2

- Which repo hosts the service - new `~/repos/<name>` or a subfolder of an existing one?
- Hostname/route under the existing Cloudflare tunnel config?
- Do we want Cloudflare Access / WAF rules in front as an extra layer for the alpha?
- Streaming: current engine does streaming UI (plan 10) - the proxy must support
  SSE/chunked passthrough, worth prototyping early since it constrains the framework choice.

---

## Sequencing

1. Decide Step 1 ceiling (budget cap + tester-only) and ship it to unblock alpha users.
2. Stand up the box proxy with rung 1+2 auth; swap the app to `ProxyInferenceEngine`.
3. Retire the shipped key (revoke it) once the proxy is stable.
4. Before public release: add Play Integrity verification (rung 4) per the 08 note.
