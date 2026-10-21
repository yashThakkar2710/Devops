# 01-02 · IAM in depth

**Week 1 · Day 2**
Interactive page: [`site/day-02.html`](../../site/day-02.html)

**After this day you can explain:** what a policy is and how AWS evaluates
one, the three permission states and which wins, why bucket and object
actions need different ARNs, what a role is and how it differs from a user,
why assuming a role removes your other permissions, and how to build a
guardrail that cannot be escaped.

**Assumes:** [`01-01`](01-01-account-safety-and-iam.md) — ARNs, users,
groups, MFA.

---

## 1. The problem

Every action in AWS — a console click, a CLI command, an API call from an
application — passes through exactly one question:

```
is this allowed?
```

Nothing else in AWS answers it. Not firewalls, not networks; those come
later and protect different things. **Who may do what is entirely
policies.**

So the whole of AWS security reduces to: can you read and write these
documents, and do you know which one wins when they disagree.

## 2. The mechanism

### 2.1 A policy is a JSON document, and nothing more

The most powerful permission in AWS, in full:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        { "Effect": "Allow", "Action": "*", "Resource": "*" }
    ]
}
```

That is `AdministratorAccess`. Five meaningful lines. It has no special
status — it is powerful only because `*` means everything.

### 2.2 The four parts of a statement

```json
{
  "Effect":    "Allow",                        Allow or Deny
  "Action":    "s3:GetObject",                 WHAT may be done
  "Resource":  "arn:aws:s3:::my-bucket/*",     to WHICH things
  "Condition": { ... }                         only IF (optional)
}
```

Read as a sentence: *allow the action `s3:GetObject` on `my-bucket/*`, if
the conditions hold.*

Actions are `service:Operation`. Resources are ARNs — which is why
`01-01` spent time on them. **Policies are built out of ARNs.**

### 2.3 Bucket actions and object actions need different ARNs

S3 has two levels of thing, and each has its own ARN:

```
arn:aws:s3:::company-reports        the bucket itself
arn:aws:s3:::company-reports/*      every object inside it
```

A filing cabinet and the papers in it. *Listing the cabinet* is an action on
the cabinet; *reading a paper* is an action on the paper.

```
s3:GetObject    on company-reports/*   ✅ correct
s3:ListBucket   on company-reports/*   ❌ silently grants nothing
```

The second one **looks fine in the console and does nothing**, because
`ListBucket` acts on the bucket ARN, which has no `/*`. The result is a user
who can download a file they know the name of but cannot see what exists.

**Rule of thumb:** read the action name. `...Object...` → needs `/*`.
`...Bucket...` → no `/*`.

The correct policy needs two statements, same bucket, two ARNs:

```json
"Statement": [
  { "Effect": "Allow", "Action": "s3:ListBucket",
    "Resource": "arn:aws:s3:::company-reports" },
  { "Effect": "Allow", "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::company-reports/*" }
]
```

There is a third level above both: `s3:ListAllMyBuckets` controls whether
you can see the *names* of buckets at all. Without it the S3 console home
page is empty even for a bucket you can read from — which produces the
common "the CLI works but the console shows nothing".

### 2.4 Withholding ListBucket is often the point

`GetObject` without `ListBucket` is not a broken policy. It is a deliberate
and common one.

| Holder has | An attacker who steals it can |
|---|---|
| `GetObject` only | fetch files whose names they can guess |
| `GetObject` + `ListBucket` | enumerate everything, then download all of it |

An application that fetches `avatars/user-12345.jpg` builds that key itself
and never needs to browse. Granting it `ListBucket` turns a small breach
into a total one.

> **Listing is the permission that turns "I can read a file" into "I can
> read everything."**

The question to ask of every policy: *does this thing need to look around,
or does it already know what it wants?* That is most of what least privilege
means in practice.

### 2.5 Three permission states, and the order

```
implicit deny    nothing mentioned it          → denied (the default)
explicit Allow   a policy said Allow           → permitted
explicit Deny    a policy said Deny            → denied, always
```

```
explicit Deny   ███████  beats everything
explicit Allow  ████
implicit deny   █        the default
```

Everything starts denied. Policies only ever add. A brand-new IAM user with
no policies can sign in and do literally nothing.

**An explicit `Deny` always wins** — regardless of how many Allows exist,
regardless of `AdministratorAccess`.

### 2.6 Deny is the only subtraction in AWS

`Allow` can only add. There is no way to subtract with it, so enforcement is
impossible with `Allow` alone:

```
Allow + Allow = more allowed
```

`Deny` winning is what makes one policy able to override every `Allow` in
the account at once, without editing any of them.

```
Allow  →  "here is what you CAN do"       permissions
Deny   →  "here is what NOBODY may do"    guardrails
```

Teams hand out `Allow` freely. Security writes a handful of `Deny` policies
nobody can escape. Two different jobs, and only the second needs `Deny`.

### 2.7 Conditions: the switch

The fourth part of a statement turns a blunt rule into a precise one.

```json
"Condition": { "BoolIfExists": { "aws:MultiFactorAuthPresent": "false" } }
"Condition": { "IpAddress":    { "aws:SourceIp": "203.0.113.0/24" } }
"Condition": { "StringEquals": { "aws:RequestedRegion": "ap-south-1" } }
```

Same shape, different key. Write one and you can write any of them.

### 2.8 The MFA enforcement policy, piece by piece

```json
{
    "Sid": "DenyAllExceptListedIfNoMFA",
    "Effect": "Deny",
    "NotAction": [
        "iam:CreateVirtualMFADevice", "iam:EnableMFADevice",
        "iam:GetUser", "iam:ListMFADevices",
        "iam:ListVirtualMFADevices", "iam:ResyncMFADevice",
        "sts:GetSessionToken"
    ],
    "Resource": "*",
    "Condition": {
        "BoolIfExists": { "aws:MultiFactorAuthPresent": "false" }
    }
}
```

**`NotAction` is the inverse of `Action`.** `Action` denies the things
listed; `NotAction` denies everything *except* them. So this reads: deny
everything except the MFA-setup calls, whenever MFA is absent.

That carve-out is the lockout trap avoided. Deny everything with no
exceptions and a user without MFA can never add MFA — permanently stuck.

**`BoolIfExists`, not `Bool`.** The key `aws:MultiFactorAuthPresent` can be
`true`, `false`, or **absent entirely** — it is absent on requests made with
long-term access keys, which have no MFA at all.

```
Bool          "deny if the label says false"
              → a request with NO label is not matched → walks through
BoolIfExists  "deny if the label says false, OR if there is no label"
              → closed
```

Plain `Bool` leaves access keys — **the most common path into a compromised
account** — completely unaffected, while the policy looks identical in the
console. One word is the difference between enforcement and theatre.

The accompanying Allow statements use a **policy variable**:

```json
"Resource": "arn:aws:iam::*:mfa/${aws:username}"
```

AWS substitutes the caller. One policy, and every user can manage only their
own MFA — without it, "let people manage MFA" would mean "let anyone remove
anyone's MFA".

### 2.9 Roles

A user *is* something. A role is something that gets *worn*.

```
USER                       ROLE
a person                   a set of permissions
has a password             has no password
has access keys            has no credentials at all
permanent                  assumed temporarily
you ARE it                 you BECOME it, for a while
```

**A role has two policies, and the second is unique to roles:**

```
trust policy        WHO may assume it      ← only roles have this
permissions policy  WHAT they can do then
```

Both must say yes. The trust policy introduces a part no identity policy
needs: **`Principal`** — because an identity policy is already attached to
the identity, while a role must name who may become it.

```json
{
  "Effect": "Allow",
  "Principal": { "Service": "budgets.amazonaws.com" },
  "Action": "sts:AssumeRole"
}
```

The five trusted-entity choices in the console are just five shapes of
`Principal`: an AWS service, another account, a web identity, a SAML
directory, or hand-written JSON.

### 2.10 Why roles replaced access keys

The old way of giving a server permission:

```
/home/app/.aws/credentials
    aws_access_key_id = AKIA...
```

| Problem | Consequence |
|---|---|
| The key never expires | it is valid forever once stolen |
| It works from anywhere | a thief uses it from their own laptop |
| Rotation means touching every server | so nobody rotates |
| Copying it leaves no trace | nothing notices |

With a role, the instance asks AWS for credentials, AWS checks the trust
policy, and issues **temporary** ones that rotate automatically. Nothing is
stored on disk; a compromised instance leaks something that expires in
hours and only does what the role allows.

> **Access keys are the old way. Roles are how AWS is actually built.** In a
> well-run account almost nothing has access keys.

### 2.11 Assuming a role replaces your permissions

Observed directly: an administrator assumed `S3ReadOnlyRole` and was then
refused by EC2.

```
yash-admin                   can do everything
yash-admin wearing the role  can only read S3
```

You do not carry your own permissions into the role. While wearing it, you
*are* only it.

This is why mature AWS shops do not let people hold admin all day: a narrow
role for routine work, deliberately assuming a powerful one for the few
minutes it is needed, then switching back. Smaller blast radius, and every
assumption appears in CloudTrail as a deliberate act.

### 2.12 Reading the error tells you which problem you have

```
arn:aws:sts::639679388494:assumed-role/S3ReadOnlyRole/yash-admin
      │                        │                │
      │                        │                └── who is wearing it
      │                        └── which role
      └── sts, not iam: these are temporary credentials
```

The ARN names both the role and the person, which is how CloudTrail can
still attribute the action.

And the wording of a denial distinguishes two opposite problems:

```
"no identity-based policy allows"  → implicit deny. You are missing an Allow.
"explicit deny in a policy"        → something is actively blocking you.
```

Those need opposite fixes. Adding permissions will never help against an
explicit Deny.

### 2.13 Budget actions: alerting versus enforcing

A budget alert emails. A budget **action** attaches a policy, applies an
SCP, or stops EC2/RDS instances — with no human involved.

**The design decision matters more than the wiring.** The obvious policy is
wrong:

```json
{ "Effect": "Deny", "Action": "*", "Resource": "*" }
```

If that fires, you also cannot *delete* the expensive thing. The breaker
locks you out of the cleanup while the bill keeps growing.

```
deny creation   stop the bleeding
allow deletion  keep the scalpel
```

Built here: a Deny on `ec2:RunInstances`, `ec2:CreateNatGateway`,
`rds:CreateDBInstance`, `elasticloadbalancing:CreateLoadBalancer` and
similar — with no `Terminate`, `Delete` or `Describe` anywhere in it.

And the narrow scope is what permits **automatic** firing. A deny-everything
breaker is too dangerous to auto-run, so it gets set to "require approval",
so it never fires at 3am — so it does not protect against the one scenario
it exists for.

> **A blunt guardrail must be manual, so it never fires. A precise guardrail
> can be automatic, so it actually works.**

## 3. What was built

```
✅ EnforceMFA policy, attached to the Admins group
   └─ tested with a throwaway mfa-test user, then deleted
✅ S3ReadOnlyRole, trust policy requiring MFA
   └─ assumed it, confirmed admin rights do not carry over
✅ BudgetBreaker-DenyExpensiveCreation policy
✅ AWSBudgetsActionRole (service role, principal budgets.amazonaws.com)
✅ Budget action wired to zero-spend-alert, automatic, targeting Admins
```

### The test that failed first, and why it mattered

The first `mfa-test` run **created an S3 bucket successfully** — the policy
had been created but never attached.

```
create policy   a JSON document exists somewhere
attach policy   it begins affecting someone
```

A correct security policy sat in the account doing nothing. That gap is
where real breaches live: the policy is written, it appears in the list, the
audit is ticked, and nothing is enforced. **Testing found it in thirty
seconds; assuming would never have found it.**

## 4. Why is it like this

**Why does explicit Deny beat Allow?** Because guardrails must be
unescapable. If Allow could override Deny, any team with permission to
attach policies could grant themselves past a security control, and central
policy would be advisory rather than binding.

**Why does assuming a role replace permissions rather than add to them?**
Because a role is meant to be a *complete* description of what a session may
do. Additive roles would make the effective permissions of any session the
union of everything it had ever touched — impossible to reason about, and
impossible to audit.

**Why do roles exist at all, rather than just long-lived keys?** Because a
credential that must physically exist somewhere will eventually exist
somewhere it should not. Roles remove the artifact instead of trying to
protect it better.

**Why is MFA fixed at sign-in while permissions are evaluated per request?**
Because they answer different questions. *How did you authenticate* happened
once, at a point in time, and cannot be revisited. *What may you do now* is
a fresh question each time, which is why attaching a policy takes effect
instantly on existing sessions.

## 5. Failure modes

- **Policy created but never attached** — the account is unprotected and
  looks protected. Always test.
- **`Bool` instead of `BoolIfExists`** — access keys bypass the control
  entirely while the policy looks correct.
- **Deny everything without MFA, with no `NotAction` carve-out** — a user
  without MFA can never add MFA. Permanent lockout.
- **`ListBucket` pointed at `bucket/*`** — silently grants nothing;
  produces "my permissions look right but it says access denied".
- **Adding Allows to fix an explicit Deny** — will never work. Read the
  denial wording first.
- **A deny-everything budget breaker** — fires, then prevents you deleting
  the thing that is costing money.
- **Assuming a role and expecting to keep admin** — you do not.

## 6. Recall

See [`recall/week-1-questions.md`](../../recall/week-1-questions.md).

## 7. Carried forward

| Met today | Used on |
|---|---|
| Trusted entity "AWS service" | day 5 — a role letting EC2 read S3 with no keys |
| Service Control Policies | day 25 — the same Deny mechanism, account-wide |
| `s3:ListAllMyBuckets`, bucket policies | day 6 — S3 in depth |
| Temporary credentials from STS | day 5, and everywhere after |
| AWS managed vs customer managed policies | throughout |
