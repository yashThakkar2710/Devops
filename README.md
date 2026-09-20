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
