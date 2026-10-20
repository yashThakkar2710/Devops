# AWS Solutions Architect, in 30 days

A 30-day, 99-hour plan reaching Solutions Architect Associate level by
building rather than reading. The certificate is a checkpoint near day 30,
not the point.

**Goal: be able to choose and defend an architecture** — not recall service
names.

## Start here

1. Open `site/plan.html` — the full plan: what you build each day, and what
   every lab costs.
2. Track days in [PROGRESS.md](PROGRESS.md).
3. Begin with `docs/week-1-foundations/`.

**Starting a fresh chat?** Point the assistant at [CONTEXT.md](CONTEXT.md).
It carries the plan, the teaching rules, what is done and what is next.

## How a day works

1. **Concept** — what problem the service solves, before any clicking. 20–30 min.
2. **Build** — console first to understand, CLI second to repeat. Most of the time.
3. **Break** — remove a permission, kill an instance, block a port. Read the error.
4. **Tear down** — same day, without exception.
5. **Record** — notes, cheatsheet, recall questions; tick `PROGRESS.md`.

Video is welcome as a *second* explanation, after building. Not before.

## Layout

| Path | What it holds |
|---|---|
| `docs/week-*/` | Day notes. **Source of truth.** Read these in your editor. |
| `docs/phase-0-map/` | The networking work. Parked, intact, feeds week 1. |
| `labs/` | Runnable labs. Each has `setup.sh`, `verify.sh`, `teardown.sh`. |
| `site/` | `plan.html` is the plan; the rest are interactive companions. |
| `reference/` | Cheatsheets and glossary, grown as commands are used. |
| `recall/` | Active-recall questions. |
| `tools/` | Generator, verifier, lab scaffolder, local server. |

## Money

Free tier is not free. A forgotten NAT Gateway is ~$32/month, an ALB ~$16.

1. Budget alarm at $5 before creating anything.
2. Every lab torn down the same day.
3. Billing console checked every Monday.

`site/plan.html` states the cost risk for each day.

## Labs

AWS labs run in the console and CLI. The parked networking labs run in
**WSL2 Ubuntu**, never against the Windows host network.

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

- **Two tiers.** ~25 services get built by hand; ~30 are only ever chosen
  correctly. Attempting hands-on across all of AWS is why one-month attempts
  collapse.
- **One architecture, grown weekly** — not thirty disconnected tutorials.
- **Practice questions in week 4 only.** Earlier, they test recall of
  material not yet built.
- **Markdown is the source of truth.** The site shows mechanisms moving; it
  never duplicates prose.
- **The networking curriculum is parked, not deleted.** Subnets, route
  tables and ports map straight onto VPC — the hardest part of AWS for most
  people, already half done.

Full reasoning: [design spec](docs/superpowers/specs/2026-10-21-aws-saa-30-day-design.md)
Parked plan: [networking spec](docs/superpowers/specs/2026-09-20-networking-curriculum-design.md)

## Out of scope

Terraform and infrastructure as code, CI/CD, Kubernetes operations, and
observability platforms beyond CloudWatch. Console and CLI only, so attention
stays on the services themselves. IaC is the natural next project.
