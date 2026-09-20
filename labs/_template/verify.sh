#!/usr/bin/env bash
# {{LAB_NAME}} - prove the lab worked. Binary: exit 0 or 1.
set -euo pipefail
cd "$(dirname "$0")"

FAIL=0
check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf '  ok   %s\n' "$label"
  else
    printf '  FAIL %s\n' "$label"
    FAIL=1
  fi
}

echo "TODO: add checks with: check \"description\" <command>"

if [ "$FAIL" -eq 0 ]; then
  echo "PASS"
else
  echo "FAIL - see above"
fi
exit "$FAIL"
