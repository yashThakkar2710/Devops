# Networking Curriculum Scaffold — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the durable scaffolding for a 4-month, 83-module networking and Linux curriculum, so that teaching module `00-01` can begin in the next session without further setup.

**Architecture:** The spec at `docs/superpowers/specs/2026-09-20-networking-curriculum-design.md` is the single source of truth for the curriculum. A generator script parses it and emits both `PROGRESS.md` (human checklist) and `site/assets/curriculum.js` (site data), so the two can never drift. A structural verification script enforces every invariant the scaffold depends on and is the test harness for this plan. Content modules are authored one per session afterwards; this plan builds only the container they land in.

**Tech Stack:** Bash (Git Bash on Windows, and WSL2 Ubuntu for labs), Python 3.13 (generator + local static server), plain HTML/CSS/JS with no framework, no CDN and no build step.

**Spec:** `docs/superpowers/specs/2026-09-20-networking-curriculum-design.md`

## Global Constraints

Copied verbatim from the spec; every task inherits these.

- **Markdown is the source of truth; HTML is a companion, not a rendering of it.** Never render doc prose into the site.
- The site must work opened directly from disk via `file://`. **No `fetch()` of local files** — `file://` blocks it. Inline all data. Shared CSS/JS via relative `<link>`/`<script>` is fine.
- **No framework, no CDN, no build step, no account.**
- Every lab has `setup.sh`, `verify.sh`, `teardown.sh`.
- `verify.sh` proves the lab worked; the learner never guesses.
- `teardown.sh` always fully cleans up. No lab leaves the system modified.
- Labs run inside WSL2 or Docker, **never against the host network**.
- Module docs are named `NN-MM-kebab-title.md` matching their phase folder.
- Numbered prefixes throughout so directory listings sort in study order.
- Numbers, RFC references and protocol details are stated precisely or not at all.
- Study order is `0 → L1 → 1 → 2 → 3 → 4 → 5 → L2 → 6 → 7 → 8 → 9`.
- Totals to preserve: **83 modules, ~247 hours, 12 phases.**

**Phase slugs** (fixed; used for directory names everywhere):

| Phase | Slug |
|---|---|
| 0 | `phase-0-map` |
| L1 | `phase-l1-linux-foundations` |
| 1 | `phase-1-link-layer` |
| 2 | `phase-2-network-layer` |
| 3 | `phase-3-transport-layer` |
| 4 | `phase-4-names-and-trust` |
| 5 | `phase-5-application-layer` |
| L2 | `phase-l2-linux-internals` |
| 6 | `phase-6-linux-networking` |
| 7 | `phase-7-container-kubernetes` |
| 8 | `phase-8-cloud-internet` |
| 9 | `phase-9-observability` |

**Shell note:** all commands in this plan run in **Git Bash** from `C:\Devops` unless a step says "in WSL". Scripts are invoked as `bash tools/foo.sh` rather than relying on the executable bit, which Windows does not preserve reliably.

---

## File Structure

| File | Responsibility |
|---|---|
| `tools/verify-scaffold.sh` | The test harness. Asserts every structural invariant. Exit 0 = scaffold healthy. |
| `tools/gen-curriculum.py` | Parses the spec; emits `PROGRESS.md` and `site/assets/curriculum.js`. Preserves existing tick marks. |
| `tools/new-lab.sh` | Scaffolds a new lab folder from the template. |
| `tools/serve.sh` | Serves `site/` on localhost. |
| `PROGRESS.md` | Generated. The learner's checklist of all 83 modules. |
| `README.md` | How to use the whole system. Hand-written. |
| `labs/LAB-CONVENTIONS.md` | The contract every lab obeys. Hand-written. |
| `labs/_template/` | Canonical lab skeleton copied by `new-lab.sh`. |
| `site/index.html` | Dashboard shell: phase cards, progress, search. |
| `site/assets/site.css` | All styling. Dark theme, light-mode fallback. |
| `site/assets/site.js` | Renders curriculum, persists progress to `localStorage`. |
| `site/assets/curriculum.js` | Generated. `window.CURRICULUM` data. |
| `reference/glossary.md` | Term → one line → owning module. Grows as we go. |
| `reference/rfc-index.md` | Which RFCs are worth reading, and which sections. |
| `reference/cheatsheets/README.md` | Rule: only commands that appeared in a lab. |
| `recall/README.md` | How to use the recall banks. |
| `labs/phase-0-map/00-01-first-capture/` | The first real lab. Proves the conventions work end to end. |

---

### Task 1: Verification harness and directory skeleton

The test harness comes first, so every later task has something to fail against.

**Files:**
- Create: `tools/verify-scaffold.sh`
- Create: `docs/phase-*/` and `labs/phase-*/` directories (24 total) each containing `.gitkeep`
- Create: `reference/cheatsheets/`, `recall/`, `site/assets/`

**Interfaces:**
- Consumes: nothing.
- Produces: `bash tools/verify-scaffold.sh` — exits 0 when all invariants hold, non-zero with a printed list of failures otherwise. Every subsequent task extends this script with new checks and re-runs it.

- [ ] **Step 1: Write the failing test**

Create `tools/verify-scaffold.sh`:

```bash
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

section "Summary"
if [ "$FAIL" -eq 0 ]; then
  printf '\033[32mScaffold healthy.\033[0m\n'
else
  printf '\033[31mScaffold has failures (see above).\033[0m\n'
fi
exit "$FAIL"
```

- [ ] **Step 2: Run it to verify it fails**

```bash
bash tools/verify-scaffold.sh
```

Expected: exits **1**, printing `FAIL docs/phase-0-map missing` and 23 further missing-directory lines, ending with `Scaffold has failures`.

- [ ] **Step 3: Create the directories**

```bash
for s in phase-0-map phase-l1-linux-foundations phase-1-link-layer \
         phase-2-network-layer phase-3-transport-layer phase-4-names-and-trust \
         phase-5-application-layer phase-l2-linux-internals \
         phase-6-linux-networking phase-7-container-kubernetes \
         phase-8-cloud-internet phase-9-observability; do
  mkdir -p "docs/$s" "labs/$s"
  touch "docs/$s/.gitkeep" "labs/$s/.gitkeep"
done
mkdir -p tools reference/cheatsheets recall site/assets
```

- [ ] **Step 4: Run it to verify it passes**

```bash
bash tools/verify-scaffold.sh
```

Expected: exits **0**, every line `ok`, ending with `Scaffold healthy.`

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "Add scaffold verification harness and phase directories

verify-scaffold.sh is the test harness for the whole scaffold: it
asserts structural invariants and is extended by each later task.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 2: Curriculum generator, PROGRESS.md and site data

The spec is the single source of truth. Hand-maintaining the module list in two places would drift, so both artifacts are generated from it and the verifier asserts they are in sync.

**Files:**
- Create: `tools/gen-curriculum.py`
- Create (generated): `PROGRESS.md`, `site/assets/curriculum.js`
- Modify: `tools/verify-scaffold.sh` (append the sync check)

**Interfaces:**
- Consumes: `tools/verify-scaffold.sh` from Task 1.
- Produces:
  - `python tools/gen-curriculum.py` — regenerates both artifacts, preserving ticked boxes. Prints `83 modules across 12 phases`.
  - `python tools/gen-curriculum.py --check` — exits 1 if either artifact is stale.
  - `window.CURRICULUM` — a JS array of `{id, slug, title, hours, modules: [{id, title}]}`, consumed by `site/assets/site.js` in Task 5.

- [ ] **Step 1: Write the failing test**

Append to `tools/verify-scaffold.sh`, immediately **before** the `section "Summary"` block:

```bash
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
```

- [ ] **Step 2: Run it to verify it fails**

```bash
bash tools/verify-scaffold.sh
```

Expected: exits **1** with `FAIL PROGRESS.md missing`, `FAIL site/assets/curriculum.js missing`, `FAIL tools/gen-curriculum.py missing`.

- [ ] **Step 3: Write the generator**

Create `tools/gen-curriculum.py`:

```python
#!/usr/bin/env python3
"""Generate PROGRESS.md and site/assets/curriculum.js from the design spec.

The spec is the single source of truth for the curriculum. Both artifacts
are derived from it so they cannot drift. Existing tick marks in
PROGRESS.md are preserved across regeneration.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SPEC = ROOT / "docs/superpowers/specs/2026-09-20-networking-curriculum-design.md"
PROGRESS = ROOT / "PROGRESS.md"
CURRICULUM_JS = ROOT / "site/assets/curriculum.js"

SLUGS = {
    "0": "phase-0-map",
    "L1": "phase-l1-linux-foundations",
    "1": "phase-1-link-layer",
    "2": "phase-2-network-layer",
    "3": "phase-3-transport-layer",
    "4": "phase-4-names-and-trust",
    "5": "phase-5-application-layer",
    "L2": "phase-l2-linux-internals",
    "6": "phase-6-linux-networking",
    "7": "phase-7-container-kubernetes",
    "8": "phase-8-cloud-internet",
    "9": "phase-9-observability",
}

# "### Phase L1 - Linux Working Knowledge (5 modules, ~13h)"
PHASE_RE = re.compile(
    r"^### Phase (?P<id>L?\d+) [\u2014-] (?P<title>.+?) "
    r"\((?P<count>\d+) modules?, ~(?P<hours>\d+)h\)\s*$"
)
# "- `L1-03` Processes, signals, and **file descriptors** - ..."
MODULE_RE = re.compile(r"^- `(?P<id>L?\d+-\d+)`\s+(?P<title>.+?)\s*$")


def strip_md(text: str) -> str:
    """Remove inline markdown emphasis and code markers from a title."""
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)
    text = re.sub(r"\*(.+?)\*", r"\1", text)
    return text.replace("`", "")


def parse_spec() -> list[dict]:
    if not SPEC.exists():
        sys.exit(f"spec not found: {SPEC}")

    phases: list[dict] = []
    current: dict | None = None
    in_fence = False

    for line in SPEC.read_text(encoding="utf-8").splitlines():
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue

        if line.startswith("#"):
            # Any heading ends the previous phase section. Checked before
            # the module regex so stray bullets under a later section can
            # never be attributed to the last phase.
            current = None

        m = PHASE_RE.match(line)
        if m:
            pid = m.group("id")
            if pid not in SLUGS:
                sys.exit(f"unknown phase id {pid!r}; add it to SLUGS")
            current = {
                "id": pid,
                "slug": SLUGS[pid],
                "title": strip_md(m.group("title")),
                "hours": int(m.group("hours")),
                "declared": int(m.group("count")),
                "modules": [],
            }
            phases.append(current)
            continue

        m = MODULE_RE.match(line)
        if m and current is not None:
            current["modules"].append(
                {"id": m.group("id"), "title": strip_md(m.group("title"))}
            )

    if not phases:
        sys.exit("parsed zero phases; the spec format changed")

    for p in phases:
        actual = len(p["modules"])
        if actual != p["declared"]:
            sys.exit(
                f"Phase {p['id']}: heading declares {p['declared']} modules "
                f"but {actual} are listed"
            )
        del p["declared"]

    return phases


def read_done() -> set[str]:
    """Module ids already ticked, so regeneration never loses progress."""
    if not PROGRESS.exists():
        return set()
    return set(
        re.findall(r"^- \[x\] `([^`]+)`", PROGRESS.read_text(encoding="utf-8"), re.M)
    )


def render_progress(phases: list[dict], done: set[str]) -> str:
    total = sum(len(p["modules"]) for p in phases)
    hours = sum(p["hours"] for p in phases)
    complete = sum(1 for p in phases for mod in p["modules"] if mod["id"] in done)

    out = [
        "# Progress",
        "",
        "<!-- GENERATED by tools/gen-curriculum.py from the design spec.",
        "     Tick boxes by hand; they survive regeneration.",
        "     Do not edit anything else here - it will be overwritten. -->",
        "",
        f"**{complete} / {total} modules complete** · ~{hours} hours total · "
        "study order is top to bottom.",
        "",
        "Spec: [design spec]"
        "(docs/superpowers/specs/2026-09-20-networking-curriculum-design.md)",
        "",
    ]
    for p in phases:
        pdone = sum(1 for mod in p["modules"] if mod["id"] in done)
        out.append(
            f"## Phase {p['id']} — {p['title']} "
            f"({pdone}/{len(p['modules'])}, ~{p['hours']}h)"
        )
        out.append("")
        out.append(f"`docs/{p['slug']}/`")
        out.append("")
        for mod in p["modules"]:
            box = "x" if mod["id"] in done else " "
            out.append(f"- [{box}] `{mod['id']}` {mod['title']}")
        out.append("")
    return "\n".join(out)


def render_js(phases: list[dict]) -> str:
    payload = json.dumps(phases, indent=2, ensure_ascii=False)
    return (
        "// GENERATED by tools/gen-curriculum.py from the design spec.\n"
        "// Do not edit by hand. Inlined as a script because file:// blocks fetch().\n"
        f"window.CURRICULUM = {payload};\n"
    )


def main() -> None:
    check = "--check" in sys.argv
    phases = parse_spec()
    done = read_done()

    want = {PROGRESS: render_progress(phases, done), CURRICULUM_JS: render_js(phases)}

    if check:
        for path, content in want.items():
            have = path.read_text(encoding="utf-8") if path.exists() else None
            if have != content:
                print(f"stale: {path.relative_to(ROOT)}")
                sys.exit(1)
        sys.exit(0)

    for path, content in want.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")

    total = sum(len(p["modules"]) for p in phases)
    print(f"{total} modules across {len(phases)} phases")


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Generate the artifacts**

```bash
python tools/gen-curriculum.py
```

Expected output, exactly: `83 modules across 12 phases`

If it instead exits with `Phase N: heading declares X modules but Y are listed`, the spec and its own headings disagree — fix the **spec**, not the generator.

- [ ] **Step 5: Verify idempotency and tick preservation**

```bash
python tools/gen-curriculum.py --check && echo "IN SYNC"
sed -i '0,/^- \[ \] `00-01`/s//- [x] `00-01`/' PROGRESS.md
python tools/gen-curriculum.py
grep -c '^- \[x\] `00-01`' PROGRESS.md
sed -i '0,/^- \[x\] `00-01`/s//- [ ] `00-01`/' PROGRESS.md
python tools/gen-curriculum.py
```

Expected: `IN SYNC`, then `1` (the tick survived regeneration), then a clean regenerate back to unticked.

- [ ] **Step 6: Run the harness to verify it passes**

```bash
bash tools/verify-scaffold.sh
```

Expected: exits **0**, including `ok   PROGRESS.md lists 83 modules` and `ok   PROGRESS.md and curriculum.js are in sync with the spec`.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "Generate PROGRESS.md and site data from the spec

The spec is the single source of truth for the curriculum. Both the
human checklist and the site data are derived from it, and the verifier
fails if either goes stale. Tick marks survive regeneration.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: README and reference scaffolding

The entry point a returning learner reads first, plus the reference surfaces that accumulate over four months.

**Files:**
- Create: `README.md`, `reference/glossary.md`, `reference/rfc-index.md`, `reference/cheatsheets/README.md`, `recall/README.md`
- Modify: `tools/verify-scaffold.sh`

**Interfaces:**
- Consumes: `tools/verify-scaffold.sh`, `PROGRESS.md`.
- Produces: no programmatic interface. `README.md` is the documented entry point referenced by Task 5's site footer.

- [ ] **Step 1: Write the failing test**

Append to `tools/verify-scaffold.sh` before `section "Summary"`:

```bash
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
```

- [ ] **Step 2: Run it to verify it fails**

```bash
bash tools/verify-scaffold.sh
```

Expected: exits **1** with six `FAIL ... missing` lines. (`labs/LAB-CONVENTIONS.md` is created in Task 4 and stays failing until then — that is intended.)

- [ ] **Step 3: Write README.md**

```markdown
# Networking and Linux, from first principles

A four-month, 83-module curriculum taking networking and Linux from nothing
to production DevOps depth. Built to be learned once.

**Goal: conceptual clarity, not coverage.** The test of a finished module is
whether you can explain the mechanism to someone else without notes,
including why it was designed that way and how it fails.

## Start here

1. Read [PROGRESS.md](PROGRESS.md) — every module, in study order.
2. Open `site/index.html` in a browser, or run `bash tools/serve.sh`.
3. Begin with `docs/phase-0-map/`.

## How a session works

1. Say "next module", or name one.
2. The module doc is written to `docs/<phase-slug>/`, and taught in
   conversation with concrete examples. Interrupt with "go deeper" whenever
   you want to dig.
3. Run the lab in WSL. Breaking it is part of the lab.
4. Recall questions are added to `recall/`; `PROGRESS.md` is ticked.
5. Roughly once a phase, that phase's interactive page gets built.

## Layout

| Path | What it holds |
|---|---|
| `docs/` | Module notes. **Source of truth.** Read these in your editor. |
| `labs/` | Runnable labs. Each has `setup.sh`, `verify.sh`, `teardown.sh`. |
| `site/` | Interactive diagrams. A companion to the docs, not a copy of them. |
| `reference/` | Glossary, cheatsheets, curated RFC list. |
| `recall/` | Active-recall questions per phase. |
| `tools/` | Generator, verifier, lab scaffolder, local server. |

## Every module has the same five parts

1. **The problem** — what breaks without this. Motivation before mechanism.
2. **The mechanism** — how it works, to byte level where that matters.
3. **The lab** — build it, then deliberately break it.
4. **Why is it like this** — the trade-off or historical accident behind it.
5. **Failure modes and recall questions.**

## Labs

Labs run in **WSL2 Ubuntu** or Docker, never against the Windows host network.

```bash
cd labs/<phase-slug>/<lab-name>
bash setup.sh      # build it
bash verify.sh     # prove it worked - never guess
bash teardown.sh   # always clean up
```

`teardown.sh` is not optional. A lab that leaves your system modified is a
lab that will confuse the next one.

## Tools

```bash
bash tools/verify-scaffold.sh   # check the repo is structurally healthy
python tools/gen-curriculum.py  # rebuild PROGRESS.md + site data from the spec
bash tools/new-lab.sh <phase-slug> <lab-name>
bash tools/serve.sh             # serve site/ at http://localhost:8080
```

## Design decisions worth remembering

- **Order:** trace one request end to end first (Phase 0), then rigorous
  bottom-up, then re-trace the same request at the end explaining every byte.
- **Linux is split in two.** L1 before Phase 1 (terminal competence, file
  descriptors). L2 before Phase 6 (kernel depth, cgroups, namespaces) so it
  is applied within days, not months.
- **No Cisco, no CCNA.** Concepts are vendor-neutral, practised on Linux and
  FRR. Vendor syntax is a lookup, not a competency. Deliberate choice.
- **Markdown is the source of truth.** The site shows mechanisms moving; it
  never duplicates prose.

Full reasoning: [design spec](docs/superpowers/specs/2026-09-20-networking-curriculum-design.md)

## Scope

This is project 1 of an expected 3. It covers networking and Linux in depth,
plus the networking slice of containers, Kubernetes and cloud. It does not
cover Terraform, CI/CD, Kubernetes operations, observability stacks, or AWS
breadth such as IAM. Those come later, and are faster to learn from this
foundation.
```

- [ ] **Step 4: Write the reference stubs**

`reference/glossary.md`:

```markdown
# Glossary

One line per term, and the module that owns it. Added to as modules are
written — a term appears here only once something has actually taught it.

Format: **Term** — one-sentence definition. `module-id`

## A

_(empty — the first entries arrive with module `00-01`)_
```

`reference/rfc-index.md`:

```markdown
# RFC reading list

Curated. Most RFCs are not worth reading end to end; these are the ones
that repay the effort, with the sections that matter.

Entries are added as their module is written, so nothing here is untethered
from something you have already studied.

Format: **RFC number — title.** Why it is worth reading, and which sections.
`module-id`

_(empty — the first entries arrive with Phase 1)_
```

`reference/cheatsheets/README.md`:

```markdown
# Cheatsheets

**Rule: a command appears here only after it has appeared in a lab.**

A cheatsheet of commands you have never run is a list of strings to forget.
These exist to reload context fast on something you already understand — not
to substitute for understanding it.

One file per tool: `tcpdump.md`, `iproute2.md`, `ss.md`, `iptables.md`,
`dig.md`, `tc.md`, and so on. Created on first use.
```

`recall/README.md`:

```markdown
# Active recall

Re-reading produces recognition. Recall produces retention. These banks are
the difference between "I studied this" and "I know this".

One file per phase: `phase-<id>-questions.md`, written as that phase is
taught.

## How to use them

- Answer out loud or in writing **before** looking anything up.
- A question you can only answer by reading the doc again is a question you
  have not learned yet. Mark it and return tomorrow.
- Revisit a phase's bank when you finish the next phase, and again a month
  later.

## What makes a good question here

Questions test **derivation**, not recognition.

- Weak: "What is TIME_WAIT?"
- Strong: "Why would removing TIME_WAIT be unsafe, and what specifically
  could go wrong?"

The second cannot be answered from a memorised definition. That is the point.
```

- [ ] **Step 5: Run the harness**

```bash
bash tools/verify-scaffold.sh
```

Expected: exits **1** with exactly **one** remaining failure, `FAIL labs/LAB-CONVENTIONS.md missing`. All five files from this task report `ok`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Add README and reference scaffolding

Entry point plus the glossary, RFC list, cheatsheet and recall surfaces
that accumulate over the curriculum. Each carries the rule that governs
it, so they stay useful rather than becoming dumping grounds.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 4: Lab conventions, template and scaffolder

Every lab obeys one contract so that four months of labs stay predictable and none of them leave the machine dirty.

**Files:**
- Create: `labs/LAB-CONVENTIONS.md`
- Create: `labs/_template/{README.md,setup.sh,verify.sh,teardown.sh}`
- Create: `tools/new-lab.sh`
- Modify: `tools/verify-scaffold.sh`

**Interfaces:**
- Consumes: `tools/verify-scaffold.sh`; phase slugs from Global Constraints.
- Produces: `bash tools/new-lab.sh <phase-slug> <lab-name>` — creates `labs/<phase-slug>/<lab-name>/` from `_template`, substituting `{{LAB_NAME}}` and `{{PHASE_SLUG}}`. Used by Task 6 and every future lab.

- [ ] **Step 1: Write the failing test**

Append to `tools/verify-scaffold.sh` before `section "Summary"`:

```bash
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
```

- [ ] **Step 2: Run it to verify it fails**

```bash
bash tools/verify-scaffold.sh
```

Expected: exits **1** with `FAIL tools/new-lab.sh missing` and four `FAIL labs/_template/... missing` lines. The `find` loop matches nothing yet, which is correct — no labs exist.

- [ ] **Step 3: Write LAB-CONVENTIONS.md**

```markdown
# Lab conventions

Every lab in this repo obeys this contract. Four months of labs stay
predictable only if none of them is a special case.

## The four files

| File | Contract |
|---|---|
| `README.md` | Objective, prerequisites, steps, **what to observe**, and the question the lab answers. |
| `setup.sh` | Builds the environment. Idempotent — safe to re-run. |
| `verify.sh` | Proves the lab worked. Exits 0 or 1. **Never asks you to eyeball output.** |
| `teardown.sh` | Removes everything `setup.sh` created. Safe to run twice, and safe to run after a failed setup. |

## Rules

1. **`set -euo pipefail` at the top of every script.** A lab that fails
   silently teaches the wrong lesson.
2. **Labs run in WSL2 or Docker, never against the Windows host network.**
   Creating interfaces or firewall rules on the host is out of bounds.
3. **`teardown.sh` is not optional.** Run it even when the lab worked.
   Leftover namespaces and bridges will confuse the next lab, and you will
   spend an hour debugging a mess you made yesterday.
4. **`verify.sh` is binary.** It answers "did this work", not "here is some
   output, you decide". You should never have to guess.
5. **Artifacts go in `out/`**, which is gitignored. Captures can be large.
6. **Breaking the lab is part of the lab.** Most READMEs end with a
   "now break it" section. Do that part — it is where the understanding is.

## Naming

`labs/<phase-slug>/<module-id>-<kebab-name>/`

For example: `labs/phase-1-link-layer/01-04-build-a-switch/`

## Creating one

```bash
bash tools/new-lab.sh phase-1-link-layer 01-04-build-a-switch
```

## Running one

```bash
cd labs/<phase-slug>/<lab-name>
bash setup.sh
bash verify.sh
bash teardown.sh
```

## If a lab leaves a mess

Network namespaces are the usual culprit. To see and remove strays, **in WSL**:

```bash
ip netns list
sudo ip netns delete <name>
ip -br link show | grep -E 'veth|br-'
```

Docker strays:

```bash
docker ps -a
docker network ls
```
```

- [ ] **Step 4: Write the template files**

`labs/_template/README.md`:

```markdown
# {{LAB_NAME}}

**Phase:** {{PHASE_SLUG}}
**Time:** ~NN minutes

## The question this answers

_One sentence. What will you be able to explain after this that you could
not before?_

## Prerequisites

- Runs in WSL2 Ubuntu.
- Packages: _list them_

## Steps

```bash
bash setup.sh
bash verify.sh
```

## What to observe

_The specific thing to look at, and what it means. Not "observe the output"._

## Now break it

_A deliberate change that makes it fail, and the symptom that appears. This
section is the point of the lab, not an extra._

## Clean up

```bash
bash teardown.sh
```
```

`labs/_template/setup.sh`:

```bash
#!/usr/bin/env bash
# {{LAB_NAME}} - build the environment. Idempotent.
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p out

echo "TODO: build the lab environment"

echo "setup complete"
```

`labs/_template/verify.sh`:

```bash
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
```

`labs/_template/teardown.sh`:

```bash
#!/usr/bin/env bash
# {{LAB_NAME}} - remove everything setup.sh created.
# Safe to run twice, and safe after a failed setup.
set -euo pipefail
cd "$(dirname "$0")"

rm -rf out

echo "teardown complete"
```

- [ ] **Step 5: Write the scaffolder**

Create `tools/new-lab.sh`:

```bash
#!/usr/bin/env bash
# Scaffold a new lab from labs/_template.
# Usage: bash tools/new-lab.sh <phase-slug> <lab-name>
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "$#" -ne 2 ]; then
  echo "usage: bash tools/new-lab.sh <phase-slug> <lab-name>" >&2
  echo "example: bash tools/new-lab.sh phase-1-link-layer 01-04-build-a-switch" >&2
  exit 2
fi

PHASE_SLUG="$1"
LAB_NAME="$2"
DEST="labs/$PHASE_SLUG/$LAB_NAME"

if [ ! -d "labs/$PHASE_SLUG" ]; then
  echo "no such phase: labs/$PHASE_SLUG" >&2
  echo "phases:" >&2
  find labs -mindepth 1 -maxdepth 1 -type d -name 'phase-*' -printf '  %f\n' >&2
  exit 1
fi

if [ -e "$DEST" ]; then
  echo "already exists: $DEST" >&2
  exit 1
fi

cp -r labs/_template "$DEST"
for f in "$DEST"/*; do
  sed -i "s|{{LAB_NAME}}|$LAB_NAME|g; s|{{PHASE_SLUG}}|$PHASE_SLUG|g" "$f"
done

echo "created $DEST"
ls -1 "$DEST" | sed 's/^/  /'
```

- [ ] **Step 6: Test the scaffolder end to end**

```bash
bash tools/new-lab.sh phase-9-observability 99-99-throwaway
grep -c '99-99-throwaway' labs/phase-9-observability/99-99-throwaway/README.md
bash tools/new-lab.sh phase-9-observability 99-99-throwaway; echo "exit=$?"
bash tools/new-lab.sh no-such-phase foo; echo "exit=$?"
```

Expected: `created labs/phase-9-observability/99-99-throwaway` with four files listed; then `1` (placeholder substituted); then `already exists: ...` and `exit=1`; then `no such phase: labs/no-such-phase` and `exit=1`.

- [ ] **Step 7: Confirm the verifier catches an incomplete lab, then clean up**

```bash
rm labs/phase-9-observability/99-99-throwaway/verify.sh
bash tools/verify-scaffold.sh | grep -E 'FAIL.*verify\.sh' ; echo "caught=$?"
rm -rf labs/phase-9-observability/99-99-throwaway
```

Expected: a line `FAIL labs/phase-9-observability/99-99-throwaway/verify.sh missing` and `caught=0` — proving the contract check has teeth, not just that it passes when nothing is there.

- [ ] **Step 8: Run the harness to verify it passes**

```bash
bash tools/verify-scaffold.sh
```

Expected: exits **0**, `Scaffold healthy.` The `labs/LAB-CONVENTIONS.md` failure from Task 3 is now resolved.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "Add lab contract, template and scaffolder

Every lab carries setup/verify/teardown plus a README. The verifier
enforces the contract on all labs, including 'set -euo pipefail', so a
lab that fails silently cannot ship.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 5: Site shell

The dashboard. Phase cards, module checkboxes with persisted progress, and search. Per-phase visualization pages are built later, one when each phase begins; this task builds the frame they hang on and links to them as they appear.

**Note for the executor:** this is real UI. Consider the `frontend-design` skill before writing the CSS. The look should read as a technical instrument — dense, precise, calm — not a marketing page.

**Files:**
- Create: `site/index.html`, `site/assets/site.css`, `site/assets/site.js`, `tools/serve.sh`
- Modify: `tools/verify-scaffold.sh`

**Interfaces:**
- Consumes: `window.CURRICULUM` from `site/assets/curriculum.js` (Task 2) — array of `{id, slug, title, hours, modules: [{id, title}]}`.
- Produces: `bash tools/serve.sh` serves `site/` at `http://localhost:8080`. Progress is stored in `localStorage` under the single key `netcurriculum.progress` as a JSON array of completed module ids.

- [ ] **Step 1: Write the failing test**

Append to `tools/verify-scaffold.sh` before `section "Summary"`:

```bash
section "Site shell"
for f in site/index.html site/assets/site.css site/assets/site.js tools/serve.sh; do
  [ -f "$f" ] && pass "$f" || fail "$f missing"
done

if [ -f site/index.html ]; then
  grep -q 'assets/curriculum.js' site/index.html \
    && pass "index.html loads curriculum.js" \
    || fail "index.html does not load assets/curriculum.js"
  grep -qE '\bfetch\s*\(' site/index.html site/assets/site.js \
    && fail "site uses fetch() - blocked under file://" \
    || pass "site avoids fetch()"
  grep -qiE 'src="https?://|href="https?://[^"]*\.css' site/index.html \
    && fail "site references a CDN - must work offline" \
    || pass "site has no external resources"
fi
```

- [ ] **Step 2: Run it to verify it fails**

```bash
bash tools/verify-scaffold.sh
```

Expected: exits **1** with four `FAIL ... missing` lines for the site files and `tools/serve.sh`.

- [ ] **Step 3: Write index.html**

```html
<!doctype html>
<html lang="en" data-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Networking Curriculum</title>
<link rel="stylesheet" href="assets/site.css">
</head>
<body>
<header class="topbar">
  <div class="wrap topbar-inner">
    <div class="brand">
      <span class="brand-mark">//</span>
      <span>Networking &amp; Linux</span>
    </div>
    <div class="topbar-tools">
      <input id="search" type="search" placeholder="Filter modules…" autocomplete="off" spellcheck="false">
      <button id="theme" type="button" title="Toggle theme">◐</button>
    </div>
  </div>
</header>

<main class="wrap">
  <section class="summary">
    <div class="summary-head">
      <h1>Progress</h1>
      <p id="overall-text" class="muted">—</p>
    </div>
    <div class="bar bar-lg"><div id="overall-bar" class="bar-fill"></div></div>
    <p class="note">
      Docs are the source of truth — read them in your editor under
      <code>docs/</code>. These pages show mechanisms moving; they do not
      repeat the prose.
    </p>
  </section>

  <section id="phases" class="phases"></section>

  <p id="empty" class="empty" hidden>No modules match that filter.</p>
</main>

<footer class="wrap foot">
  <span>83 modules · ~247 hours · study order top to bottom</span>
  <span class="muted">Progress is stored in this browser only.</span>
</footer>

<script src="assets/curriculum.js"></script>
<script src="assets/site.js"></script>
</body>
</html>
```

- [ ] **Step 4: Write site.css**

```css
:root {
  --bg: #0d1117; --panel: #151b23; --panel-2: #1b222c;
  --line: #262d38; --line-soft: #1e242e;
  --ink: #e6edf3; --ink-dim: #8b949e; --ink-faint: #6e7681;
  --accent: #4493f8; --done: #3fb950;
  --radius: 10px;
  --mono: ui-monospace, "Cascadia Code", "JetBrains Mono", Consolas, monospace;
  --sans: ui-sans-serif, system-ui, "Segoe UI", sans-serif;
}
:root[data-theme="light"] {
  --bg: #ffffff; --panel: #f6f8fa; --panel-2: #eef1f4;
  --line: #d0d7de; --line-soft: #e4e8ec;
  --ink: #1f2328; --ink-dim: #59636e; --ink-faint: #818b98;
  --accent: #0969da; --done: #1a7f37;
}
* { box-sizing: border-box; }
body {
  margin: 0; background: var(--bg); color: var(--ink);
  font-family: var(--sans); font-size: 15px; line-height: 1.55;
  -webkit-font-smoothing: antialiased;
}
.wrap { max-width: 1100px; margin: 0 auto; padding: 0 16px; }
.muted { color: var(--ink-dim); }
code { font-family: var(--mono); font-size: .88em; }

.topbar {
  position: sticky; top: 0; z-index: 10;
  background: color-mix(in srgb, var(--bg) 88%, transparent);
  backdrop-filter: blur(8px);
  border-bottom: 1px solid var(--line);
}
.topbar-inner {
  display: flex; align-items: center; justify-content: space-between;
  gap: 16px; height: 56px;
}
.brand { display: flex; align-items: center; gap: 10px; font-weight: 600; letter-spacing: -.01em; }
.brand-mark { font-family: var(--mono); color: var(--accent); }
.topbar-tools { display: flex; gap: 8px; align-items: center; }
#search {
  width: min(280px, 44vw); padding: 7px 11px;
  background: var(--panel); color: var(--ink);
  border: 1px solid var(--line); border-radius: 7px;
  font: inherit; font-size: 14px;
}
#search:focus { outline: 2px solid var(--accent); outline-offset: -1px; border-color: transparent; }
#theme {
  width: 34px; height: 34px; cursor: pointer;
  background: var(--panel); color: var(--ink-dim);
  border: 1px solid var(--line); border-radius: 7px; font-size: 15px;
}
#theme:hover { color: var(--ink); }

.summary { padding: 32px 0 20px; }
.summary-head { display: flex; align-items: baseline; justify-content: space-between; gap: 16px; flex-wrap: wrap; }
.summary h1 { margin: 0; font-size: 20px; letter-spacing: -.01em; }
#overall-text { margin: 0; font-family: var(--mono); font-size: 13px; }
.note { margin: 14px 0 0; font-size: 13px; color: var(--ink-faint); max-width: 62ch; }

.bar { height: 5px; background: var(--panel-2); border-radius: 99px; overflow: hidden; }
.bar-lg { height: 7px; margin-top: 12px; }
.bar-fill { height: 100%; width: 0; background: var(--done); border-radius: 99px; transition: width .25s ease; }

.phases { display: grid; gap: 14px; padding-bottom: 40px; }
.phase {
  background: var(--panel); border: 1px solid var(--line);
  border-radius: var(--radius); overflow: hidden;
}
.phase[data-complete="true"] { border-color: color-mix(in srgb, var(--done) 40%, var(--line)); }
.phase-head {
  display: flex; align-items: center; gap: 12px;
  padding: 13px 16px; cursor: pointer; user-select: none;
}
.phase-head:hover { background: var(--panel-2); }
.chev { color: var(--ink-faint); font-size: 11px; width: 10px; transition: transform .15s ease; }
.phase[open] .chev { transform: rotate(90deg); }
.phase-id {
  font-family: var(--mono); font-size: 12px; font-weight: 600;
  color: var(--accent); background: color-mix(in srgb, var(--accent) 12%, transparent);
  padding: 2px 7px; border-radius: 5px; min-width: 34px; text-align: center;
}
.phase-title { font-weight: 600; letter-spacing: -.01em; }
.phase-meta { margin-left: auto; display: flex; align-items: center; gap: 12px; }
.phase-count { font-family: var(--mono); font-size: 12px; color: var(--ink-dim); white-space: nowrap; }
.phase-meta .bar { width: 76px; }
.viz-link {
  font-size: 12px; color: var(--accent); text-decoration: none;
  border: 1px solid color-mix(in srgb, var(--accent) 35%, transparent);
  padding: 2px 8px; border-radius: 5px;
}
.viz-link:hover { background: color-mix(in srgb, var(--accent) 12%, transparent); }
.viz-soon { font-size: 12px; color: var(--ink-faint); }

.modules { border-top: 1px solid var(--line-soft); padding: 6px 0; }
.mod { display: flex; align-items: flex-start; gap: 11px; padding: 6px 16px 6px 38px; }
.mod:hover { background: var(--panel-2); }
.mod input { margin: 4px 0 0; accent-color: var(--done); cursor: pointer; flex: none; }
.mod label { cursor: pointer; display: flex; gap: 10px; align-items: baseline; flex-wrap: wrap; }
.mod-id { font-family: var(--mono); font-size: 12px; color: var(--ink-faint); flex: none; }
.mod-title { font-size: 14px; }
.mod input:checked ~ label .mod-title { color: var(--ink-dim); text-decoration: line-through; }
.mod input:checked ~ label .mod-id { color: var(--done); }

.empty { text-align: center; color: var(--ink-faint); padding: 40px 0; }
.foot {
  display: flex; justify-content: space-between; gap: 16px; flex-wrap: wrap;
  border-top: 1px solid var(--line); padding-top: 16px; padding-bottom: 32px;
  font-size: 12px; color: var(--ink-faint);
}

@media (max-width: 620px) {
  .phase-meta .bar { display: none; }
  .mod { padding-left: 16px; }
}
```

- [ ] **Step 5: Write site.js**

```javascript
/* Dashboard for the networking curriculum.
   Data comes from window.CURRICULUM (assets/curriculum.js), inlined as a
   script because file:// blocks fetch(). Progress lives in localStorage. */
(function () {
  "use strict";

  var STORE = "netcurriculum.progress";
  var THEME = "netcurriculum.theme";
  var phasesEl = document.getElementById("phases");
  var searchEl = document.getElementById("search");
  var emptyEl = document.getElementById("empty");
  var data = window.CURRICULUM || [];

  function loadDone() {
    try {
      var raw = localStorage.getItem(STORE);
      return new Set(raw ? JSON.parse(raw) : []);
    } catch (e) {
      return new Set();
    }
  }
  function saveDone(set) {
    try {
      localStorage.setItem(STORE, JSON.stringify(Array.from(set)));
    } catch (e) {
      /* private mode or blocked storage - the page still works */
    }
  }

  var done = loadDone();

  function el(tag, cls, text) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text != null) n.textContent = text;
    return n;
  }

  function build() {
    data.forEach(function (phase) {
      var det = el("details", "phase");
      det.dataset.phase = phase.id;
      det.open = true;

      var head = el("summary", "phase-head");
      head.appendChild(el("span", "chev", "▶"));
      head.appendChild(el("span", "phase-id", phase.id));
      head.appendChild(el("span", "phase-title", phase.title));

      var meta = el("div", "phase-meta");
      var count = el("span", "phase-count", "");
      var bar = el("div", "bar");
      var fill = el("div", "bar-fill");
      bar.appendChild(fill);

      /* Per-phase visualization pages are built as each phase begins.
         Link to one only if it exists; otherwise say so plainly. */
      var vizName = "phase-" + phase.id.toLowerCase() + ".html";
      var viz = el("span", "viz-soon", "viz: not built yet");
      viz.dataset.href = vizName;

      meta.appendChild(viz);
      meta.appendChild(count);
      meta.appendChild(bar);
      head.appendChild(meta);
      det.appendChild(head);

      var list = el("div", "modules");
      phase.modules.forEach(function (mod) {
        var row = el("div", "mod");
        row.dataset.search = (mod.id + " " + mod.title).toLowerCase();

        var box = el("input");
        box.type = "checkbox";
        box.id = "m-" + mod.id;
        box.checked = done.has(mod.id);
        box.addEventListener("change", function () {
          if (box.checked) done.add(mod.id);
          else done.delete(mod.id);
          saveDone(done);
          refresh();
        });

        var label = el("label");
        label.htmlFor = box.id;
        label.appendChild(el("span", "mod-id", mod.id));
        label.appendChild(el("span", "mod-title", mod.title));

        row.appendChild(box);
        row.appendChild(label);
        list.appendChild(row);
      });

      det.appendChild(list);
      det._count = count;
      det._fill = fill;
      phasesEl.appendChild(det);
    });
  }

  function refresh() {
    var total = 0;
    var complete = 0;

    data.forEach(function (phase, i) {
      var det = phasesEl.children[i];
      var n = phase.modules.length;
      var c = phase.modules.filter(function (m) { return done.has(m.id); }).length;
      total += n;
      complete += c;
      det._count.textContent = c + "/" + n + " · ~" + phase.hours + "h";
      det._fill.style.width = (n ? (c / n) * 100 : 0) + "%";
      det.dataset.complete = c === n ? "true" : "false";
    });

    var pct = total ? Math.round((complete / total) * 100) : 0;
    document.getElementById("overall-text").textContent =
      complete + " / " + total + " modules · " + pct + "%";
    document.getElementById("overall-bar").style.width = pct + "%";
  }

  function filter(q) {
    q = q.trim().toLowerCase();
    var anyVisible = false;

    Array.prototype.forEach.call(phasesEl.children, function (det) {
      var shown = 0;
      Array.prototype.forEach.call(det.querySelectorAll(".mod"), function (row) {
        var hit = !q || row.dataset.search.indexOf(q) !== -1;
        row.hidden = !hit;
        if (hit) shown++;
      });
      det.hidden = shown === 0;
      if (shown) anyVisible = true;
      if (q) det.open = true;
    });

    emptyEl.hidden = anyVisible;
  }

  searchEl.addEventListener("input", function () { filter(searchEl.value); });
  searchEl.addEventListener("keydown", function (e) {
    if (e.key === "Escape") { searchEl.value = ""; filter(""); }
  });

  var themeBtn = document.getElementById("theme");
  try {
    var saved = localStorage.getItem(THEME);
    if (saved) document.documentElement.dataset.theme = saved;
  } catch (e) { /* ignore */ }
  themeBtn.addEventListener("click", function () {
    var next = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
    document.documentElement.dataset.theme = next;
    try { localStorage.setItem(THEME, next); } catch (e) { /* ignore */ }
  });

  if (!data.length) {
    phasesEl.appendChild(
      el("p", "empty", "curriculum.js is empty - run: python tools/gen-curriculum.py")
    );
    return;
  }

  build();
  refresh();
})();
```

- [ ] **Step 6: Write the server script**

Create `tools/serve.sh`:

```bash
#!/usr/bin/env bash
# Serve site/ locally. Optional - index.html also works opened directly.
set -euo pipefail
cd "$(dirname "$0")/../site"

PORT="${1:-8080}"
echo "serving site/ at http://localhost:$PORT  (ctrl-c to stop)"
python -m http.server "$PORT" --bind 127.0.0.1
```

- [ ] **Step 7: Run the harness to verify it passes**

```bash
bash tools/verify-scaffold.sh
```

Expected: exits **0**, including `ok   site avoids fetch()` and `ok   site has no external resources`.

- [ ] **Step 8: Confirm it renders, both ways**

```bash
start "" "C:\Devops\site\index.html"
```

Expected in the browser: 12 phase cards in study order (`0, L1, 1, 2, 3, 4, 5, L2, 6, 7, 8, 9`), `0 / 83 modules · 0%` at the top. Tick any box — the bars move. Reload — the tick survives. Type `tcp` in the filter — only TCP-related modules remain. Click `◐` — the theme flips and survives reload.

Then confirm the served path works too:

```bash
bash tools/serve.sh
```

Visit `http://localhost:8080`, confirm identical rendering, then ctrl-c.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "Add site shell: phase dashboard with persisted progress

Renders the 12 phases from generated curriculum data. No framework, no
CDN, no build step, and no fetch() so it works opened straight from disk.
The verifier enforces those three constraints.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 6: Phase 0 lab — first capture

The first real lab, and the proof that the conventions work end to end. It produces the packet capture that module `00-01` is taught from, so the next session can start immediately.

**Files:**
- Create: `labs/phase-0-map/00-01-first-capture/{README.md,setup.sh,capture.sh,verify.sh,teardown.sh}`
- Modify: `.gitignore` (ignore `out/` under labs — already present as `labs/**/out/`; confirm only)

**Interfaces:**
- Consumes: `bash tools/new-lab.sh` from Task 4; the lab contract from `labs/LAB-CONVENTIONS.md`.
- Produces: `labs/phase-0-map/00-01-first-capture/out/capture.pcap` — a capture containing DNS, a TCP handshake and a TLS handshake, which module `00-01` is taught against.

**Runs in WSL**, not Git Bash. Every command in this task's steps 3–7 is run from a WSL shell.

- [ ] **Step 1: Write the failing test — scaffold the lab, then run its verifier**

```bash
bash tools/new-lab.sh phase-0-map 00-01-first-capture
cd labs/phase-0-map/00-01-first-capture && bash verify.sh; echo "exit=$?"; cd -
```

Expected: the lab is created from the template, and its verifier prints `TODO: add checks...` then `PASS` with `exit=0` — a verifier that passes while proving nothing. That is the failure this task fixes.

- [ ] **Step 2: Write the real verify.sh**

Replace `labs/phase-0-map/00-01-first-capture/verify.sh`:

```bash
#!/usr/bin/env bash
# 00-01-first-capture - prove the capture contains a full request.
set -euo pipefail
cd "$(dirname "$0")"

PCAP="out/capture.pcap"
FAIL=0
check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then printf '  ok   %s\n' "$label"
  else printf '  FAIL %s\n' "$label"; FAIL=1; fi
}
count() { tcpdump -r "$PCAP" -nn "$1" 2>/dev/null | wc -l; }
atleast() { [ "$(count "$1")" -ge "$2" ]; }

if [ ! -s "$PCAP" ]; then
  echo "  FAIL $PCAP missing or empty - run: bash setup.sh"
  echo "FAIL"
  exit 1
fi

check "capture is readable"            tcpdump -r "$PCAP" -nn -c 1
check "contains DNS traffic"           atleast "port 53" 1
check "contains a TCP SYN"             atleast "tcp[tcpflags] & tcp-syn != 0" 1
check "contains a TCP SYN-ACK"         atleast "tcp[tcpflags] & (tcp-syn|tcp-ack) == (tcp-syn|tcp-ack)" 1
check "contains HTTPS traffic on 443"  atleast "tcp port 443" 1
check "contains a connection teardown" atleast "tcp[tcpflags] & (tcp-fin|tcp-rst) != 0" 1

echo
if [ "$FAIL" -eq 0 ]; then
  echo "PASS - capture contains DNS, a TCP handshake, TLS and a teardown."
  echo "Packets captured: $(count '')"
else
  echo "FAIL - see above. Re-run: bash teardown.sh && bash setup.sh"
fi
exit "$FAIL"
```

- [ ] **Step 3: Run the verifier to confirm it now fails honestly**

In WSL, from the lab directory:

```bash
bash verify.sh; echo "exit=$?"
```

Expected: `FAIL out/capture.pcap missing or empty - run: bash setup.sh`, `exit=1`.

- [ ] **Step 4: Write setup.sh and capture.sh**

`setup.sh`:

```bash
#!/usr/bin/env bash
# 00-01-first-capture - check tooling, then capture one HTTPS request.
# Idempotent: re-running replaces the capture.
set -euo pipefail
cd "$(dirname "$0")"

if ! grep -qi microsoft /proc/version 2>/dev/null; then
  echo "This lab must run inside WSL2, not Git Bash." >&2
  echo "Open a WSL shell and run it from there." >&2
  exit 1
fi

MISSING=()
for t in tcpdump curl dig ip ss; do
  command -v "$t" >/dev/null 2>&1 || MISSING+=("$t")
done

if [ "${#MISSING[@]}" -gt 0 ]; then
  echo "missing tools: ${MISSING[*]}"
  echo "installing..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq tcpdump curl dnsutils iproute2
fi

mkdir -p out
bash capture.sh
echo "setup complete - now run: bash verify.sh"
```

`capture.sh`:

```bash
#!/usr/bin/env bash
# Capture one full HTTPS request: DNS lookup, TCP handshake, TLS, teardown.
set -euo pipefail
cd "$(dirname "$0")"

TARGET="${1:-example.com}"
PCAP="out/capture.pcap"

echo "capturing traffic for https://$TARGET"

# 'any' catches loopback too, in case the resolver is local.
sudo tcpdump -i any -nn -s 0 -w "$PCAP" \
  "port 53 or port 443" >/dev/null 2>&1 &
TCPDUMP_PID=$!

cleanup() { sudo kill "$TCPDUMP_PID" 2>/dev/null || true; wait "$TCPDUMP_PID" 2>/dev/null || true; }
trap cleanup EXIT

sleep 1  # let tcpdump attach before traffic starts

# Query an external resolver directly so DNS is always on the wire and
# never served from a local cache. Caching is discussed in the module.
dig +short "$TARGET" @1.1.1.1 >/dev/null || true

curl -s -o /dev/null "https://$TARGET" || true

sleep 1  # let the teardown packets land

cleanup
trap - EXIT
sudo chown "$(id -u):$(id -g)" "$PCAP"

echo "wrote $PCAP ($(du -h "$PCAP" | cut -f1))"
```

- [ ] **Step 5: Write teardown.sh**

```bash
#!/usr/bin/env bash
# 00-01-first-capture - remove the capture. Safe to run twice.
set -euo pipefail
cd "$(dirname "$0")"

rm -rf out
echo "teardown complete"
```

- [ ] **Step 6: Run the lab end to end in WSL**

```bash
cd /mnt/c/Devops/labs/phase-0-map/00-01-first-capture
bash setup.sh
bash verify.sh; echo "exit=$?"
```

Expected: six `ok` lines, then `PASS - capture contains DNS, a TCP handshake, TLS and a teardown.`, a packet count above zero, and `exit=0`.

If `contains DNS traffic` fails, the `dig` query did not reach the wire — check that `1.1.1.1` is reachable from WSL with `dig +short example.com @1.1.1.1`.

- [ ] **Step 7: Confirm teardown is clean and repeatable**

```bash
bash teardown.sh
bash teardown.sh
ls out 2>&1 | head -1
bash verify.sh; echo "exit=$?"
```

Expected: `teardown complete` twice with no error the second time; `ls: cannot access 'out': No such file or directory`; and the verifier failing with `exit=1`. A teardown that leaves the verifier passing has not torn anything down.

- [ ] **Step 8: Write the lab README**

Replace `labs/phase-0-map/00-01-first-capture/README.md`:

```markdown
# 00-01 · First capture

**Phase:** phase-0-map
**Time:** ~30 minutes
**Runs in:** WSL2 Ubuntu (not Git Bash)

## The question this answers

What actually crosses the wire when you fetch one HTTPS page — and how much
of it can you not yet explain?

This lab does not teach you the answers. It produces the evidence, and an
honest list of what you do not know. That list is the map the next four
months fill in.

## Prerequisites

- WSL2 Ubuntu.
- `tcpdump`, `curl`, `dig`, `ip`, `ss` — `setup.sh` installs any that are
  missing.
- `sudo` is needed: capturing packets is a privileged operation, for
  reasons that will make sense after Phase L1.

## Steps

```bash
cd /mnt/c/Devops/labs/phase-0-map/00-01-first-capture
bash setup.sh
bash verify.sh
```

`setup.sh` starts `tcpdump`, resolves `example.com` against `1.1.1.1`,
fetches the page over HTTPS, and stops capturing. Everything lands in
`out/capture.pcap`.

## What to observe

Read the capture:

```bash
tcpdump -r out/capture.pcap -nn | head -40
```

Find these five things, in this order. Write down the line number of each:

1. **A DNS query and its response** (port 53). A name goes out, an address
   comes back.
2. **Three packets in a row** between your machine and that address: `SYN`,
   `SYN-ACK`, `ACK`. Nothing useful has been sent yet — this is setup.
3. **A burst of encrypted-looking traffic on port 443** immediately after.
   That is the TLS handshake. Note how many round trips it takes.
4. **The actual request and response**, indistinguishable from the
   handshake because it is encrypted.
5. **`FIN` or `RST`** at the end. The connection closing.

Now count: **how many round trips happened before a single byte of the web
page moved?** That number is why the rest of this curriculum exists.

## Build your map of ignorance

This is the real deliverable. For each item below, write one honest line:
*what you think it does*, and *what you cannot explain*.

- Why did DNS use UDP, and what happens if the response is too big?
- Why does TCP need three packets to start, rather than two?
- What is a sequence number, and why is the first one not zero?
- What does the `win` value in the tcpdump output mean?
- Why is TLS a separate handshake instead of part of TCP?
- What decided which network interface this traffic left from?
- What did your packet look like *before* the kernel put it on the wire?
- Why does the connection need closing at all?

Save it as `docs/phase-0-map/00-01-map-of-ignorance.md`. You will re-read it
at the capstone, and the difference will be the measure of what you learned.

## Now break it

Capture again, but block the DNS response:

```bash
bash teardown.sh
sudo iptables -I INPUT -p udp --sport 53 -j DROP
bash setup.sh          # this will hang, then fail
sudo iptables -D INPUT -p udp --sport 53 -j DROP
```

Observe: `curl` does not say "DNS is broken". It hangs, then reports it
could not resolve the host — and the capture shows the query going out
repeatedly with no answer. **Retry behaviour is the symptom; the cause is
silence.** That pattern recurs constantly in production, and recognising it
is most of what diagnosis is.

## Clean up

```bash
bash teardown.sh
```
```

- [ ] **Step 9: Run the full harness**

Back in Git Bash from `C:\Devops`:

```bash
bash tools/verify-scaffold.sh
```

Expected: exits **0**. The new lab satisfies the contract: four files present, all three scripts strict.

- [ ] **Step 10: Confirm the capture is not committed**

```bash
cd labs/phase-0-map/00-01-first-capture && bash setup.sh 2>/dev/null || true; cd -
git status --short
```

Expected: `out/capture.pcap` does **not** appear — `.gitignore` already carries `*.pcap` and `labs/**/out/`. If it does appear, fix `.gitignore` before committing.

- [ ] **Step 11: Commit**

```bash
git add -A
git commit -m "Add Phase 0 lab: first capture

The first real lab and an end-to-end proof of the lab contract. Produces
the packet capture that module 00-01 is taught from, and asks the learner
to write their map of ignorance - the deliverable the capstone is measured
against.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Done criteria

The scaffold is complete when all of the following hold:

```bash
bash tools/verify-scaffold.sh            # exits 0
python tools/gen-curriculum.py --check   # exits 0
git status --short                       # empty
```

and:

- `site/index.html` opens from disk and shows 12 phases and 83 modules.
- Ticking a module persists across a reload.
- `labs/phase-0-map/00-01-first-capture/` runs, verifies and tears down cleanly in WSL.

## What this plan deliberately does not build

- **Module docs.** All 83 are authored one per session, in conversation. Writing them up front would produce text nobody reads and would waste the teaching, which is the point.
- **Per-phase visualization pages** (`site/phase-1.html` … `phase-9.html`). Built as each phase begins, so each reflects what actually proved difficult. The dashboard already shows `viz: not built yet` for every phase and is the place to wire each one in.
- **Recall banks and cheatsheets.** Grow with their phases. Their READMEs carry the rules that keep them honest.
