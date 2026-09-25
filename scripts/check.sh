#!/usr/bin/env bash
# Every gate, one command. Add a gate by adding a line; keep each one fast
# enough that an agent will actually run it.
#
#   scripts/check.sh      one line per gate, and the full output of any that fails
#   scripts/check.sh -v   everything, as each gate prints it
#
# Quiet by default because the interesting part is which gate failed, and the
# noise (pub resolution, build_runner progress, every passing test) buried it:
# every caller was piping this through the same grep. A failing gate still prints
# all of its output, which is the only time it is wanted.
#
# The PATH fallback is for a machine whose shell config does not carry flutter;
# where it does, this is a no-op.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

verbose=0
case "${1:-}" in
  -v|--verbose) verbose=1 ;;
  "") ;;
  *) echo "usage: scripts/check.sh [-v]" >&2; exit 2 ;;
esac

if ! command -v flutter >/dev/null 2>&1; then
  export PATH="$HOME/flutter/bin:$PATH"
fi

failed=()
run() {
  local name="$1"; shift
  echo "--- $name"
  if (( verbose )); then
    if "$@"; then echo "    ok"; else failed+=("$name"); echo "    FAILED"; fi
    return
  fi
  local log
  log=$(mktemp)
  if "$@" >"$log" 2>&1; then
    # The last non-empty line is each gate's own summary: "157 file(s) checked",
    # "No issues found!", "All tests passed!".
    local summary
    summary=$(grep -v '^[[:space:]]*$' "$log" | tail -1)
    [[ -n "$summary" ]] && echo "    ${summary:0:110}"
    echo "    ok"
  else
    sed 's/^/    /' "$log"
    failed+=("$name")
    echo "    FAILED"
  fi
  rm -f "$log"
}

run "links"    python3 scripts/gates/links.py
# The plan folders against their own convention: frontmatter, the status enum,
# and a tracking table that agrees with the files.
run "plans"    python3 scripts/plans.py check --citations
# Codegen first, and not only in CI: *.freezed.dart and *.g.dart are gitignored,
# so a fresh checkout has none and everything after this step fails with
# undefined getters. Warm it is ~2s; cold (a clean clone) about a minute.
run "codegen"  dart run build_runner build --delete-conflicting-outputs
run "analyze"  flutter analyze
run "test"     flutter test --reporter=failures-only

echo
if [[ ${#failed[@]} -eq 0 ]]; then
  echo "all gates passed"
  exit 0
fi
echo "failed: ${failed[*]}"
exit 1
