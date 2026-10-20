#!/usr/bin/env bash
# Structural verification for the curriculum scaffold.
# Exit 0 = healthy. Any failure prints and sets exit 1.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

FAIL=0
pass() { printf '  \033[32mok\033[0m   %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=1; }
section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# Active curriculum: the 30-day AWS plan.
SLUGS=(
  week-1-foundations
  week-2-resilient
  week-3-modern-secure
  week-4-architect
)

# Parked: the networking curriculum. Kept, not required to grow.
PARKED=( phase-0-map )

section "Week directories"
for s in "${SLUGS[@]}"; do
  [ -d "docs/$s" ] && pass "docs/$s" || fail "docs/$s missing"
  [ -d "labs/$s" ] && pass "labs/$s" || fail "labs/$s missing"
done

section "Parked curriculum still intact"
for s in "${PARKED[@]}"; do
  [ -d "docs/$s" ] && pass "docs/$s preserved" || fail "docs/$s went missing"
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
  [ "$n" -eq 30 ] && pass "PROGRESS.md lists 30 days" \
                  || fail "PROGRESS.md lists $n days, expected 30"
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
done < <(find docs -mindepth 2 -maxdepth 2 -name '*.md' \( -path 'docs/phase-*' -o -path 'docs/week-*' \) 2>/dev/null)
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

section "Site shell"
for f in site/index.html site/assets/site.css site/assets/site.js tools/serve.sh; do
  [ -f "$f" ] && pass "$f" || fail "$f missing"
done

if [ -f site/index.html ]; then
  grep -q 'assets/curriculum.js' site/index.html \
    && pass "index.html loads curriculum.js" \
    || fail "index.html does not load assets/curriculum.js"
  # Strip comment lines first - the word "fetch()" appears in comments
  # explaining why it is not used, and that must not trip the check.
  if cat site/index.html site/assets/site.js \
       | grep -vE '^\s*(//|\*|/\*)' \
       | grep -qE '\bfetch\s*\('; then
    fail "site uses fetch() - blocked under file://"
  else
    pass "site avoids fetch()"
  fi
  grep -qiE 'src="https?://|href="https?://[^"]*\.css' site/index.html \
    && fail "site references a CDN - must work offline" \
    || pass "site has no external resources"
fi

section "Summary"
if [ "$FAIL" -eq 0 ]; then
  printf '\033[32mScaffold healthy.\033[0m\n'
else
  printf '\033[31mScaffold has failures (see above).\033[0m\n'
fi
exit "$FAIL"
