# Context handoff

**Paste this file, or point at it, when starting a fresh chat.** It carries
everything an assistant needs to continue without re-deriving anything.

Updated at the end of each day.

---

## Current state

| | |
|---|---|
| **Day** | 1 of 30 complete |
| **Last completed** | `01-01` Account safety and the IAM model |
| **Next** | `01-02` IAM in depth — policies, roles, trust |
| **Started** | 2026-10-21 |
| **Target** | AWS Solutions Architect Associate level by ~2026-11-20 |

Authoritative checklist: [`PROGRESS.md`](PROGRESS.md). If this file and
`PROGRESS.md` disagree, `PROGRESS.md` is right.

---

## Who I am

- Developer, 2 years experience. Strong on application code.
- **Near-zero AWS hands-on.** Know the service names, haven't built with them.
- AWS account exists, **free tier still active**.
- Windows 11 + WSL2 Ubuntu + Docker. Working directory `C:\Devops`.
- Not a native English speaker.

## How I want to be taught

These are corrections I have already given. They hold.

1. **Short, simple replies.** Plain words. No menus of options with
   trade-offs — pick the best one and say which.
2. **Never skip the basics.** Define what a thing *is* before explaining how
   to use it. State the obvious. A missing foundation is what forces
   relearning later.
3. **Define every term the first time it appears.** Do not use a word the
   docs have not introduced.
4. **Teach in conversation**, with real examples from my own machine and
   account — not textbook examples.
5. I will say **"go deeper"** when I want to dig. I will say **"next"** when
   ready to move on.
6. **No Claude artifacts.** Local HTML files only — I may switch accounts.
7. Depth is wanted in *teaching*. Brevity is wanted in *status updates*.

## How a day runs

1. **Concept** — what problem the service solves, before any clicking. 20–30 min.
2. **Build** — console first to understand, CLI second to repeat. Most of the time.
3. **Break** — remove a permission, kill an instance, block a port. Read the error.
4. **Tear down** — same day, without exception.
5. **Record** — notes to `docs/week-N-*/`, commands to
   `reference/cheatsheets/`, questions to `recall/`, tick `PROGRESS.md`,
   commit and push, update this file.

Video is welcome as a *second* explanation after building, never instead.

---

## The plan

30 days, ~99 hours, ~3.5 hrs/day. Reach **Solutions Architect Associate
level by building**. The certificate is a checkpoint near day 30, decided
then — the goal is being able to choose and defend an architecture.

```
Week 1   a server, inside a network built by hand
Week 2   survives an AZ failure, scales under load
Week 3   event-driven, encrypted, locked down
Week 4   monitored, cost-optimised, with a DR plan
```

One architecture, grown weekly — not thirty disconnected tutorials.

**Two tiers, and this is what makes a month possible:**

- **BUILD** (~25 services) — created, broken and fixed by hand.
- **KNOW** (~30 services) — chosen correctly, never deployed.

Full detail: [`site/plan.html`](site/plan.html) and
[`docs/superpowers/specs/2026-10-21-aws-saa-30-day-design.md`](docs/superpowers/specs/2026-10-21-aws-saa-30-day-design.md).

## Money rules

Free tier is not free. NAT Gateway ~$32/month, ALB ~$16/month if left running.

1. Budget alarm at $5, set day 1.
2. Every lab torn down the same day.
3. Billing console checked every Monday.

---

## Where things live

| Path | What |
|---|---|
| `PROGRESS.md` | The 30-day checklist. Generated — tick boxes by hand, they survive. |
| `site/plan.html` | The plan: every day, every service, cost per day. |
| `site/index.html` | Progress dashboard. |
| `docs/week-N-*/` | Day notes. **Source of truth.** |
| `docs/phase-0-map/` | Parked networking work. Intact. |
| `labs/` | Runnable labs: `setup.sh`, `verify.sh`, `teardown.sh`. |
| `reference/cheatsheets/` | Commands — added only after being used. |
| `recall/` | Active-recall questions. |
| `tools/` | See below. |

```bash
bash tools/verify-scaffold.sh   # is the repo structurally healthy
python tools/gen-curriculum.py  # rebuild PROGRESS.md + site data from the spec
bash tools/new-lab.sh <week-slug> <lab-name>
bash tools/serve.sh             # serve site/ at localhost:8080
```

Git: repo is `https://github.com/yashThakkar2710/Devops`. Pushing needs the
personal account token, not the machine default:

```bash
GH_TOKEN=$(gh auth token -u yashThakkar2710) \
  git -c credential.helper='!gh auth git-credential' push origin main
```

---

## Decisions already made — do not reopen

| Decision | Why |
|---|---|
| AWS plan replaces the 247-hour networking curriculum | Timeline shrank to one month |
| Networking work **parked, not deleted** | Subnets, routing and ports feed VPC directly |
| Certificate is a checkpoint, not the goal | Learner wants capability; exam decided at day 30 |
| No Cisco, no CCNA | Vendor syntax is a lookup, not a competency |
| Console and CLI only, no Terraform | Keeps attention on services; IaC is the next project |
| Practice questions in week 4 only | Earlier, they test material not yet built |
| Markdown is source of truth; HTML never duplicates prose | Two copies rot |
| Local HTML, never Claude artifacts | Account may change |

---

## Already learned (networking, parked)

Completed module `00-01`, from a real packet capture on this machine:

- What a network is; packets; why messages are split
- IP address vs port; interfaces (`eth0` vs `lo`); `localhost` is loopback
- A machine has several IPs at once, all correct
- `/20` vs `/32` — neighbourhood size
- The routing decision: `via` means hand it to the router, no `via` means direct
- DNS question and answer, matched by mirrored ports
- IPv4 vs IPv6, and why both are requested
- Transaction IDs — observed out-of-order replies that make them necessary
- UDP vs TCP
- The three-way handshake, and why three is the minimum rather than a convention
- RTT, jitter, TTL as a hop counter; traceroute and the three ways it is misread

Tools used: `tcpdump`, `ip addr`, `ip route`, `curl`, `dig`, `ss`, `ping`,
`traceroute`.

**This maps onto AWS:** subnets and prefixes → VPC subnet design (day 3);
route tables → VPC route tables (day 3); ports and TCP → security groups
(day 4); DNS and TTL → Route 53 (day 13).

---

## Day log

| Day | Module | Done | Notes |
|---|---|---|---|
| — | `00-01` journey of a request (parked curriculum) | 2026-09-21 | Full packet capture read end to end |
| 1 | `01-01` Account safety and the IAM model | 2026-10-21 | Account secured end to end. See AWS account state below. |

---

## AWS account state

Carry this forward — it is what exists in the account right now.

| | |
|---|---|
| Account | `yash2710` · id `639679388494` |
| Plan | **free plan** with credits — cannot currently be charged |
| Credits | $100, expiring Apr 2027. $100 more available, $20 per activity |
| **Region** | **`ap-south-1` (Mumbai)** — use this for everything |
| Sign-in | `https://<account-id>.signin.aws.amazon.com/console` as `yash-admin` |

Built so far:

```
root           MFA on, zero access keys, not used for daily work
yash-admin     IAM user, MFA on, no access keys, in group Admins
Admins         group with AdministratorAccess
zero-spend-alert   budget, emails on any charge over $0.01
CloudTrail     Event history on by default, 90 days, free. No trail created.
default VPC    created automatically by AWS - ignored, we build our own on day 3
```

Credit activities remaining: EC2 instance (day 5), RDS/Aurora (day 10),
Lambda web app (day 15), Bedrock model (not in plan — 10 min, worth taking).
Cost budget already claimed.

**Known quirks on this account:**
- Cost Explorer forecast showed *access denied* on day 1 — needs up to 24h
  to activate on a new account. Recheck.
- Billing access for IAM users was already active; newer accounts ship that
  way. Confirmed by testing rather than hunting for the setting.
