# 01-01 · Account safety and the IAM model

**Week 1 · Day 1**
Interactive page: [`site/day-01.html`](../../site/day-01.html)

**After this day you can explain:** what the root user is and why it is
dangerous, what an IAM user, group and policy are, what an access key is and
why root must never have one, why a budget alert does not stop spending,
what a region is and why resources vanish when you change it, and what an
ARN tells you.

**Assumes:** nothing about AWS.

---

## 1. The problem

An AWS account starts with exactly one identity: **root**, created from the
email address used to sign up.

Root can do anything. Delete every resource, change the billing details,
**close the account permanently**. And the critical part:

> **No policy can restrict root.** There is no block you can place on it. It
> is unconditionally all-powerful, by design.

So if root credentials leak, you do not lose some data — you lose the
account, including the ability to get back into it.

The job of day 1 is to make root unusable to an attacker, and to create a
second identity for daily work that *can* be restricted.

## 2. The mechanism

### 2.1 Root versus IAM user

```
┌─────────────── one AWS account ────────────────┐
│                                                 │
│   root                      IAM user            │
│   ├─ unlimited              ├─ limited by policy│
│   ├─ cannot be restricted   ├─ can be restricted│
│   ├─ can close the account  ├─ cannot           │
│   └─ use 1-2x per year      └─ use daily        │
│                                                 │
└─────────────────────────────────────────────────┘
```

Both are logins to the **same account**. They are different identities, not
different accounts. This separation is the entire point of IAM: *who are
you* and *what may you do* are two distinct questions.

### 2.2 Users, groups, policies

| Term | What it is |
|---|---|
| **User** | one login — a person |
| **Group** | a container of users who share permissions |
| **Policy** | the document stating what is allowed or denied |

Permissions attach to the **group**, not to the person. Change the group
once and every member updates. This is how every real AWS account is run,
even when there is only one person in it.

(The fourth concept, **role**, is day 2. It is the one most people never
properly understand.)

### 2.3 Access keys

MFA protects a human logging in through a browser. Programs cannot type
passwords, so AWS has a second credential:

```
Access key ID:      AKIA...
Secret access key:  wJalr...
```

That pair is **a password for code**. Anything holding it acts as that
identity — no MFA, no browser, no prompt. MFA does not protect it, because
MFA only guards the sign-in page.

> **Root must never have access keys.** There is no valid reason. Bots scan
> public commits for these strings and find them within seconds.

Checked on this account: root has **0 access keys**, and so does
`yash-admin`. Nothing to remove.

### 2.4 Budgets alert; they do not stop

> **An AWS budget is a smoke alarm, not a sprinkler.**

```
budget at $5 → you spend $5 → AWS emails you
                              AWS keeps charging
                              nothing is stopped
```

AWS will never cut off services for cost, because it cannot distinguish a
student's mistake from a company's busiest day. Billing data also lags up to
**24 hours**, so the alert describes yesterday.

What actually protects you is tearing down every lab the same day. The
budget only buys time to react.

**Zero-spend budget** was chosen over a $5 monthly budget: with $100 of
credits, a $5 threshold would never fire. Zero-spend alerts on any charge
above $0.01 — the moment something starts costing, not a week later.

### 2.5 Billing access is a separate switch

By default even a full administrator gets *access denied* on billing pages.
Billing permission sits behind its own switch, historically root-only.

The reasoning is sound: a company may want twenty engineers with wide
infrastructure permissions and **none** of them seeing invoices or card
details. Admin over resources ≠ allowed to see the bill.

On this account it was already active — newer accounts often ship that way.
Confirmed by testing rather than hunting for the setting.

### 2.6 Regions

AWS is divided into **regions** — separate physical locations, each with its
own datacenters.

> **A resource exists in exactly one region, and is only visible while the
> console is pointed at that region.**

```
create an instance in Mumbai
switch the console to Stockholm
→ EC2 shows "no instances"
```

The instance is still running. It is still billing. You simply cannot see
it. This is the most common and most expensive beginner mistake in AWS.

Chosen for this account: **`ap-south-1` (Mumbai)** — nearest, and keeping
everything in one region means nothing gets abandoned somewhere forgotten.

**CloudTrail Event history is also per-region**, which is why `CreateUser`
did not appear in Mumbai: **IAM is global and logs to `us-east-1`**.

### 2.7 ARNs

Every resource in AWS has an **Amazon Resource Name**:

```
arn:aws:iam::639679388494:user/yash-admin
 │   │   │   │      │            │
 │   │   │   │      │            └── the resource
 │   │   │   │      └─────────────── account id
 │   │   │   └────────────────────── region (empty: IAM is global)
 │   │   └────────────────────────── service
 │   └────────────────────────────── partition
 └────────────────────────────────── fixed
```

The empty region slot is meaningful, not a formatting quirk. Compare an S3
or EC2 ARN and a region appears.

## 3. What was built

```
✅ MFA on root (virtual, authenticator app)
✅ Root has zero access keys — confirmed, not assumed
✅ Registration completed; $100 credits, 183 days
✅ zero-spend-alert budget, email notification
✅ IAM user yash-admin, in group Admins (AdministratorAccess)
✅ MFA on yash-admin
✅ Billing access confirmed working as the IAM user
✅ Region fixed to ap-south-1
✅ CloudTrail Event history reviewed (already on, 90 days, free)
```

Sign-in from now on: `https://<account-id>.signin.aws.amazon.com/console`

**No trail was created.** Event history is already on and free; a trail
writes to S3 and costs storage that is not needed yet.

## 4. Why is it like this

**Why can root not be restricted?** Because something has to be able to
recover the account when everything else is misconfigured. If a policy could
lock root out, a bad policy could make an account permanently unusable with
no way back. Root is the escape hatch, and an escape hatch with a lock on it
is not an escape hatch.

**Why do budgets not stop spending?** Because AWS cannot tell a runaway lab
from a business having its best day. Automatically cutting off a customer's
production traffic over a threshold would be far more damaging than the
bill. The cost of that choice is pushed onto the customer: alerting is
provided, enforcement is not.

**Why is billing a separate permission?** Because infrastructure access and
financial access are different kinds of trust, and most organisations want
to grant one without the other.

**Why are regions so isolated?** Because isolation is the point. A failure
in one region should not propagate to another, so they share almost nothing
— which also means your view of one tells you nothing about the others.

## 5. Failure modes

- **Root credentials leak** — the account is lost, not just its data. MFA on
  root is the single highest-value action in AWS.
- **Root access key committed to a repository** — found by scanners in
  seconds. MFA does not help; access keys bypass the sign-in page entirely.
- **"My instance disappeared"** — almost always the wrong region. The
  resource is still running and still charging.
- **"My budget didn't warn me"** — it did, up to 24 hours late, and it was
  never going to stop anything.
- **"I can't find the CloudTrail event"** — wrong region. Global services
  such as IAM log to `us-east-1`.

## 6. Recall

See [`recall/week-1-questions.md`](../../recall/week-1-questions.md).

## 7. Carried forward

| Observed today | Explained on |
|---|---|
| AWS auto-created a **default VPC** (`AutomatedDefaultVpcCreation`) | day 3 — built from scratch instead |
| `AdministratorAccess` is not least-privilege | day 2 — write a narrow policy by hand |
| Roles, the fourth IAM concept | day 2 |
| Cost Explorer forecast showed *access denied* | up to 24h to activate; recheck day 2 |
