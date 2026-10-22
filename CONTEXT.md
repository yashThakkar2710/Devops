# Context handoff

**Paste this file, or point at it, when starting a fresh chat.** It carries
everything an assistant needs to continue without re-deriving anything.

Updated at the end of each day.

---

## Current state

| | |
|---|---|
| **Day** | 3 of 30 complete |
| **Last completed** | `01-03` A VPC from scratch |
| **Next** | `01-04` NAT, security groups, NACLs, VPC endpoints — **first day that costs money** |
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

0. **Revise — 30 min, before anything new.** Answer yesterday's recall
   questions from memory, then check against yesterday's page. Taken from
   the day's budget, not added to it.
1. **Concept** — what problem the service solves, before any clicking. 20–30 min.
2. **Build** — console first to understand, CLI second to repeat. Most of the time.
3. **Break** — remove a permission, kill an instance, block a port. Read the error.
4. **Tear down** — same day, without exception.
5. **Record** — notes to `docs/week-N-*/`, **a page at `site/day-NN.html`**,
   commands to `reference/cheatsheets/`, questions to `recall/`, tick
   `PROGRESS.md`, commit and push, update this file.

**One page per day, not per week** (changed on day 1): weekly pages arrive
too late to revise from. Add the day id to `BUILT_DAYS` in
`site/assets/site.js` so the dashboard links it.

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
| `site/day-NN.html` | One page per day — what revision is checked against. |
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
| 2 | `01-02` IAM in depth | 2026-10-22 | Policies, roles, MFA enforcement, budget breaker. All tested, not assumed. |
| 3 | `01-03` A VPC from scratch | 2026-10-22 | VPC, 4 subnets, IGW, public route table. Built by hand, no wizard. |
| 3+ | Subnetting deep dive | 2026-10-23 | Asked for extra depth. Drilled size-to-slash until automatic. |

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
root                 MFA on (authenticator app + laptop passkey), zero access keys
yash-admin           IAM user, MFA on, no access keys, in group Admins
Admins               group: AdministratorAccess + EnforceMFA
EnforceMFA           customer policy. Deny all unless MFA, NotAction carve-out,
                     BoolIfExists. TESTED with a throwaway user, then deleted.
S3ReadOnlyRole       role, trust policy requires MFA, AmazonS3ReadOnlyAccess
BudgetBreaker-DenyExpensiveCreation
                     customer policy. Denies RunInstances, CreateNatGateway,
                     CreateDBInstance, CreateLoadBalancer etc.
                     NO Terminate/Delete/Describe - deliberately.
AWSBudgetsActionRole service role, principal budgets.amazonaws.com
zero-spend-alert     budget, emails over $0.01, AUTOMATIC action attaching
                     BudgetBreaker to the Admins group
CloudTrail           Event history on by default, 90 days, free. No trail.
default VPC          created automatically by AWS - ignored, we built our own

my-vpc               10.0.0.0/16, built by hand on day 3
  public-1a          10.0.1.0/24   ap-south-1a   → public-rt
  public-1b          10.0.2.0/24   ap-south-1b   → public-rt
  private-1a         10.0.11.0/24  ap-south-1a   → main rt (sealed)
  private-1b         10.0.12.0/24  ap-south-1b   → main rt (sealed)
my-igw               attached to my-vpc
public-rt            0.0.0.0/0 → my-igw, associated with the 2 public subnets
```

Addressing scheme: **low numbers public (1.x, 2.x), teens private (11.x,
12.x)**. Keep it for every future subnet.

**Subnetting is now fluent** (drilled on day 3). Anchor at `/24` = 256,
halve the size to add 1 to the slash. `usable = total - 5`. The recurring
slip to watch for: getting the starting addresses right and attaching the
wrong slash, which silently produces overlapping subnets.

**Not torn down, deliberately** — all of the above is free while idle and is
the foundation for days 4 and 5. The teardown rule is about money, not
tidiness.

**If the budget breaker ever fires** and you cannot create resources: detach
`BudgetBreaker-DenyExpensiveCreation` from the `Admins` group in IAM. You
can still delete things while it is attached — that was the design.

Credit activities remaining: EC2 instance (day 5), RDS/Aurora (day 10),
Lambda web app (day 15), Bedrock model (not in plan — 10 min, worth taking).
Cost budget already claimed.

**Asked for and agreed, to be built on day 2:**
- **Account-wide MFA enforcement** — a `Deny` policy conditioned on
  `BoolIfExists aws:MultiFactorAuthPresent`, with `NotAction` carving out
  the MFA-setup calls so nobody can lock themselves out. Root is unaffected;
  IAM policies cannot restrict root, and its MFA is already set by hand.
- **Budget actions** — the real circuit breaker. A budget alert only emails;
  a budget *action* can attach a deny policy or stop EC2/RDS when a
  threshold is crossed. Matters most once the account moves off the free
  plan, so build it now while learning policies.

**Known quirks on this account:**
- Cost Explorer forecast showed *access denied* on day 1 — needs up to 24h
  to activate on a new account. Recheck.
- **Billing access was NOT already active**, contrary to the day 1
  conclusion. The Budgets page loaded because Budgets has its own
  permissions that `AdministratorAccess` grants directly; the **Bills** page
  refused outright. Fixed as root on day 3 at
  `billing/home#/account` → *IAM user and role access to Billing
  information* → Activate. The console sidebar does not contain that page;
  reach it from the top-right account menu, or paste the URL **and press
  F5**, since changing only the `#` fragment does not reload.
- **Total spend as of day 3: USD 0.00.** Everything built so far is free,
  including the budget action whose cost was uncertain.
