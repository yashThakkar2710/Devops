#!/usr/bin/env bash
# Structural verification for the curriculum scaffold.
# Exit 0 = healthy. Any failure prints and sets exit 1.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

FAIL=0
pass() { printf '  \033[32mok\033[0m   %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=1; }
section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

SLUGS=(
  phase-0-map
  phase-l1-linux-foundations
  phase-1-link-layer
  phase-2-network-layer
  phase-3-transport-layer
  phase-4-names-and-trust
  phase-5-application-layer
  phase-l2-linux-internals
  phase-6-linux-networking
  phase-7-container-kubernetes
  phase-8-cloud-internet
  phase-9-observability
)

section "Phase directories"
for s in "${SLUGS[@]}"; do
  [ -d "docs/$s" ] && pass "docs/$s" || fail "docs/$s missing"
  [ -d "labs/$s" ] && pass "labs/$s" || fail "labs/$s missing"
done

section "Top-level directories"
for d in tools reference reference/cheatsheets recall site site/assets; do
  [ -d "$d" ] && pass "$d" || fail "$d missing"
done

section "Curriculum artifacts"
for f in PROGRESS.md site/assets/curriculum.js tools/gen-curriculum.py; do
  [ -f "$f" ] && pass "$f" || fail "$f missing"
done

if [ -f tools/gen-curriculum.py ]; then
  if python tools/gen-curriculum.py --check >/dev/null 2>&1; then
    pass "PROGRESS.md and curriculum.js are in sync with the spec"
  else
    fail "generated artifacts are stale - run: python tools/gen-curriculum.py"
  fi
fi

if [ -f PROGRESS.md ]; then
  n=$(grep -cE '^- \[[ x]\] `' PROGRESS.md)
  [ "$n" -eq 83 ] && pass "PROGRESS.md lists 83 modules" \
                  || fail "PROGRESS.md lists $n modules, expected 83"
fi

section "Summary"
if [ "$FAIL" -eq 0 ]; then
  printf '\033[32mScaffold healthy.\033[0m\n'
else
  printf '\033[31mScaffold has failures (see above).\033[0m\n'
fi
exit "$FAIL"
