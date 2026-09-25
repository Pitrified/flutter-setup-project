#!/usr/bin/env bash
# Every gate, one command. Add a gate by adding a line; keep each one fast
# enough that an agent will actually run it.
#
# The PATH fallback is for a machine whose shell config does not carry flutter;
# where it does, this is a no-op.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if ! command -v flutter >/dev/null 2>&1; then
  export PATH="$HOME/flutter/bin:$PATH"
fi

failed=()
run() {
  local name="$1"; shift
  echo "--- $name"
  if "$@"; then echo "    ok"; else failed+=("$name"); echo "    FAILED"; fi
}

run "links"    python3 scripts/gates/links.py
run "analyze"  flutter analyze
run "test"     flutter test --reporter=failures-only

echo
if [[ ${#failed[@]} -eq 0 ]]; then
  echo "all gates passed"
  exit 0
fi
echo "failed: ${failed[*]}"
exit 1
