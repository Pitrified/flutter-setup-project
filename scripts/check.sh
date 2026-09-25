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
# The plan folders against their own convention: frontmatter, the status enum,
# and a tracking table that agrees with the files. Not --citations yet; that set
# is not empty until plans/21_plans_query_skill/04_stop_citing_the_diary.md lands.
run "plans"    python3 scripts/plans.py check
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
