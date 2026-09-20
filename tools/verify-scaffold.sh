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

section "Documentation surfaces"
for f in README.md reference/glossary.md reference/rfc-index.md \
         reference/cheatsheets/README.md recall/README.md \
         labs/LAB-CONVENTIONS.md; do
  [ -f "$f" ] && pass "$f" || fail "$f missing"
done

# Spec section 9: module docs are named NN-MM-kebab-title.md.
# Vacuous today, but it catches a typo in month three.
bad=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  b=$(basename "$f")
  echo "$b" | grep -qE '^(L?[0-9]+)-[0-9]{2}-[a-z0-9-]+\.md$' || {
    fail "doc misnamed: $f (want NN-MM-kebab-title.md)"; bad=1; }
done < <(find docs -mindepth 2 -maxdepth 2 -name '*.md' -path 'docs/phase-*' 2>/dev/null)
[ "$bad" -eq 0 ] && pass "module docs follow the naming convention"

section "Lab contract"
[ -f tools/new-lab.sh ] && pass "tools/new-lab.sh" || fail "tools/new-lab.sh missing"

for f in README.md setup.sh verify.sh teardown.sh; do
  [ -f "labs/_template/$f" ] && pass "labs/_template/$f" \
                             || fail "labs/_template/$f missing"
done

# Every real lab (any dir with a setup.sh) must carry the full contract
while IFS= read -r d; do
  [ -z "$d" ] && continue
  for f in README.md setup.sh verify.sh teardown.sh; do
    [ -f "$d/$f" ] && pass "$(basename "$d")/$f" || fail "$d/$f missing"
  done
  for f in setup.sh verify.sh teardown.sh; do
    [ -f "$d/$f" ] || continue
    grep -q 'set -euo pipefail' "$d/$f" \
      && pass "$(basename "$d")/$f is strict" \
      || fail "$d/$f lacks 'set -euo pipefail'"
  done
done < <(find labs -mindepth 2 -maxdepth 3 -name setup.sh -not -path 'labs/_template/*' -printf '%h\n' 2>/dev/null)

section "Summary"
if [ "$FAIL" -eq 0 ]; then
  printf '\033[32mScaffold healthy.\033[0m\n'
else
  printf '\033[31mScaffold has failures (see above).\033[0m\n'
fi
exit "$FAIL"
