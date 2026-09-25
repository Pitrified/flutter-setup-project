#!/usr/bin/env python3
"""A local stand-in for the OpenAI Chat Completions API.

Answers `POST /v1/chat/completions` the way `openai_dart` expects, in both
non-streaming and streaming (SSE) form, so the app can hold a full conversation
with no API key and no network. Point a debug build at it:

    python3 tool/mock_openai.py --port 8080
    flutter run --dart-define=OPENAI_BASE_URL=http://10.0.2.2:8080/v1

From an emulator the host is `10.0.2.2`; `127.0.0.1` there means the emulator
itself. `adb reverse tcp:8080 tcp:8080` makes `http://127.0.0.1:8080/v1` work
too, on an emulator or a cabled phone.

What it deliberately does NOT do (plans/17_emulator_e2e/00_start.md D5): validate
the request against our JSON schema. It replies with scripted text whatever it is
asked, so these runs prove the app handles a well-formed response, not that our
`response_format` is one the real API accepts.

Scenarios, chosen per request by the `X-Mock-Scenario` header, for the whole run
by `--scenario`, or at runtime by `POST /_control {"scenario": "..."}` (which is
how the integration test walks through the failure paths without restarting the
server):

    ok          a schema-shaped reply in the language the prompt asks for
    malformed   a 200 whose content is not JSON, for the parse-failure path
    unauthorized  HTTP 401 in OpenAI's error shape
    ratelimit   HTTP 429
    slow        like `ok`, but dripping, to watch the streaming UI

Every request is appended as one JSON line to --log-file (default
`mock_openai_requests.jsonl` beside the script), so a test can assert what the
app actually sent, including which language the prompt named.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

# The prompt's first line is "You are a language tutor for <language>." (see
# assets/prompts/tutor_response/v3.txt), which is how a reply can be written in
# the language the app asked for, and how a test can check the app asked at all.
TUTOR_LINE = re.compile(r"You are a language tutor for (.+?)\.")

# One scripted reply per language, in the shape of tutor_response_schema.
REPLIES: dict[str, dict] = {
    "Portuguese (Brazilian)": {
        "correction": {
            "content": "Olá, tudo bem?",
            "translation": "Hello, how are you?",
            "errors": [
                {
                    "original": "tudo bem",
                    "corrected": "tudo bem?",
                    "explanation": "A question needs a question mark.",
                }
            ],
        },
        "conversation": {
            "content": "Oi! Tudo ótimo. O que você fez hoje?",
            "translation": "Hi! All great. What did you do today?",
        },
    },
    "Spanish (European)": {
        "correction": {
            "content": "¡Hola, amigo!",
            "translation": "Hello, friend!",
            "errors": [
                {
                    "original": "Hola amigo",
                    "corrected": "¡Hola, amigo!",
                    "explanation": "Spanish opens an exclamation with ¡.",
                }
            ],
        },
        "conversation": {
            "content": "¡Hola! ¿Qué tal tu día?",
            "translation": "Hello! How is your day?",
        },
    },
    "French": {
        "correction": {"content": "", "translation": "", "errors": []},
        "conversation": {
            "content": "Bonjour ! Comment vas-tu ?",
            "translation": "Hello! How are you?",
        },
    },
    "Italian": {
        "correction": {"content": "", "translation": "", "errors": []},
        "conversation": {
            "content": "Ciao! Come stai oggi?",
            "translation": "Hi! How are you today?",
        },
    },
    "German": {
        "correction": {"content": "", "translation": "", "errors": []},
        "conversation": {
            "content": "Hallo! Wie geht es dir?",
            "translation": "Hello! How are you?",
        },
    },
}

FALLBACK_REPLY = {
    "correction": {"content": "", "translation": "", "errors": []},
    "conversation": {
        "content": "Hello! The mock did not recognise the language.",
        "translation": "Hello! The mock did not recognise the language.",
    },
}

SCENARIOS = ["ok", "malformed", "unauthorized", "ratelimit", "slow"]

ERRORS = {
    "unauthorized": (
        401,
        {
            "error": {
                "message": "Incorrect API key provided.",
                "type": "invalid_request_error",
                "code": "invalid_api_key",
            }
        },
    ),
    "ratelimit": (
        429,
        {
            "error": {
                "message": "Rate limit reached for requests.",
                "type": "requests",
                "code": "rate_limit_exceeded",
            }
        },
    ),
}


def language_of(body: dict) -> str:
    """The language the prompt names, or '' when the prompt does not say."""
    for message in body.get("messages", []):
        content = message.get("content")
        if isinstance(content, str):
            found = TUTOR_LINE.search(content)
            if found:
                return found.group(1)
    return ""


def reply_text(body: dict, scenario: str) -> str:
    if scenario == "malformed":
        # A 200 carrying something that is not JSON: the app's parse-failure path.
        return "Sure! Here is your correction: (the model forgot the JSON)"
    return json.dumps(REPLIES.get(language_of(body), FALLBACK_REPLY), ensure_ascii=False)


def chunks(text: str, size: int) -> list[str]:
    """Split mid-token on purpose, so the partial-JSON parser is exercised."""
    return [text[i : i + size] for i in range(0, len(text), size)] or [""]


class Handler(BaseHTTPRequestHandler):
    scenario_default = "ok"
    log_path: Path = Path("mock_openai_requests.jsonl")

    def log_message(self, fmt: str, *args) -> None:  # quieter default logging
        sys.stderr.write("mock: " + fmt % args + "\n")

    def _read_body(self) -> bytes:
        """Read the request body whether it is length-delimited or chunked.

        `openai_dart` sends Content-Length, but Dart's plain HttpClient (which
        the integration test uses to drive /_control) sends chunked with no
        length, and reading Content-Length alone silently yields an empty body.
        """
        if self.headers.get("Transfer-Encoding", "").lower() == "chunked":
            data = bytearray()
            while True:
                size_line = self.rfile.readline().strip()
                if not size_line:
                    break
                size = int(size_line.split(b";")[0], 16)
                if size == 0:
                    self.rfile.readline()  # trailing CRLF
                    break
                data += self.rfile.read(size)
                self.rfile.readline()  # CRLF after each chunk
            return bytes(data)
        return self.rfile.read(int(self.headers.get("Content-Length", "0")))

    def _send_json(self, status: int, payload: dict) -> None:
        raw = json.dumps(payload, ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self) -> None:  # noqa: N802 - name fixed by BaseHTTPRequestHandler
        # A liveness probe for the harness, and a way to eyeball the mock by hand.
        if self.path.rstrip("/") in ("/health", "/v1/health"):
            self._send_json(200, {"status": "ok", "scenario": self.scenario_default})
        else:
            self._send_json(404, {"error": {"message": f"no route {self.path}"}})

    def do_POST(self) -> None:  # noqa: N802
        if self.path.rstrip("/") == "/_control":
            self._control()
            return
        if not self.path.rstrip("/").endswith("/chat/completions"):
            self._send_json(404, {"error": {"message": f"no route {self.path}"}})
            return

        raw = self._read_body()
        try:
            body = json.loads(raw or b"{}")
        except json.JSONDecodeError:
            self._send_json(400, {"error": {"message": "body was not JSON"}})
            return

        scenario = self.headers.get("X-Mock-Scenario", self.scenario_default)
        self._record(body, scenario)

        if scenario in ERRORS:
            status, payload = ERRORS[scenario]
            self._send_json(status, payload)
            return

        text = reply_text(body, scenario)
        if body.get("stream"):
            self._stream(text, slow=scenario == "slow")
        else:
            self._send_json(
                200,
                {
                    "id": "chatcmpl-mock",
                    "object": "chat.completion",
                    "model": body.get("model", "mock"),
                    "choices": [
                        {
                            "index": 0,
                            "message": {"role": "assistant", "content": text},
                            "finish_reason": "stop",
                        }
                    ],
                },
            )

    def _control(self) -> None:
        """Switch the default scenario for subsequent requests.

        The integration test runs on the device and reaches the host the same way
        the app does, so it can drive the failure paths itself instead of the
        harness restarting this server between runs.
        """
        try:
            payload = json.loads(self._read_body() or b"{}")
        except json.JSONDecodeError:
            self._send_json(400, {"error": {"message": "body was not JSON"}})
            return
        wanted = payload.get("scenario")
        if wanted not in SCENARIOS:
            self._send_json(
                400,
                {"error": {"message": f"unknown scenario {wanted!r}; try {SCENARIOS}"}},
            )
            return
        Handler.scenario_default = wanted
        self._send_json(200, {"scenario": wanted})

    def _stream(self, text: str, *, slow: bool) -> None:
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        for piece in chunks(text, 12):
            event = {
                "id": "chatcmpl-mock",
                "object": "chat.completion.chunk",
                "choices": [{"index": 0, "delta": {"content": piece}}],
            }
            self.wfile.write(
                f"data: {json.dumps(event, ensure_ascii=False)}\n\n".encode()
            )
            self.wfile.flush()
            time.sleep(0.25 if slow else 0.02)
        self.wfile.write(b"data: [DONE]\n\n")
        self.wfile.flush()

    def _record(self, body: dict, scenario: str) -> None:
        entry = {
            "at": time.strftime("%Y-%m-%dT%H:%M:%S"),
            "scenario": scenario,
            "model": body.get("model"),
            "stream": bool(body.get("stream")),
            "language": language_of(body),
            "authorized": bool(self.headers.get("Authorization")),
            "prompt": "\n".join(
                m.get("content", "")
                for m in body.get("messages", [])
                if isinstance(m.get("content"), str)
            ),
        }
        with self.log_path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(entry, ensure_ascii=False) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument(
        "--scenario",
        default="ok",
        choices=SCENARIOS,
        help="default for requests without an X-Mock-Scenario header",
    )
    parser.add_argument(
        "--log-file",
        type=Path,
        default=Path(__file__).with_name("mock_openai_requests.jsonl"),
    )
    args = parser.parse_args()

    Handler.scenario_default = args.scenario
    Handler.log_path = args.log_file
    args.log_file.write_text("", encoding="utf-8")

    server = ThreadingHTTPServer(("0.0.0.0", args.port), Handler)
    print(f"mock OpenAI on http://0.0.0.0:{args.port}/v1  scenario={args.scenario}")
    print(f"  emulator: --dart-define=OPENAI_BASE_URL=http://10.0.2.2:{args.port}/v1")
    print(f"  or: adb reverse tcp:{args.port} tcp:{args.port}  (then 127.0.0.1)")
    print(f"  requests logged to {args.log_file}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nstopping")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
