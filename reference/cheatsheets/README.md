# Cheatsheets

**Rule: a command appears here only after it has appeared in a lab.**

A cheatsheet of commands you have never run is a list of strings to forget.
These exist to reload context fast on something you already understand — not
to substitute for understanding it.

One file per tool: `tcpdump.md`, `iproute2.md`, `ss.md`, `iptables.md`,
`dig.md`, `tc.md`, and so on. Created on first use.

---

## ip (iproute2) — from module 00-01

| Command | What it shows |
|---|---|
| `ip -br addr show` | your interfaces and their addresses, one line each |
| `ip route show` | your whole routing rulebook |
| `ip route get <addr>` | how this machine would send to that address |
| `ip -6 route show default` | whether IPv6 can leave at all |

Reading `ip route get`:

```
no "via"   → direct, it is a neighbour
"via X"    → hand it to router X
"local"    → never leaves this machine
```

## tcpdump — from module 00-01

| Command | What it does |
|---|---|
| `tcpdump -r file.pcap -nn` | print a saved capture |
| `tcpdump -r file.pcap -nn \| cat -n` | with line numbers |
| `tcpdump -r file.pcap -nn port 53` | only name lookups |
| `tcpdump -i any -nn -w file.pcap` | record from every interface |

| Flag | Meaning |
|---|---|
| `-r` | read a file instead of the live network |
| `-nn` | raw numbers only; do not resolve names or port names |
| `-w` | write to a file |
| `-i any` | every interface at once |

## curl and dig — from module 00-01

| Command | What it does |
|---|---|
| `curl https://example.com` | fetch a page and print it |
| `curl -s -o /dev/null <url>` | fetch it and discard it (silent) |
| `curl -s ifconfig.me` | your public address |
| `curl -4 <url>` / `curl -6 <url>` | force one address family |
| `dig +short example.com` | just the addresses |
| `dig example.com @1.1.1.1` | ask a specific name server |

## ping and traceroute — from module 00-01

| Command | What it does |
|---|---|
| `ping -c 5 <addr>` | send 5 probes, report round trip time |
| `ping -c 5 127.0.0.1` | RTT to yourself — not zero, ~0.04 ms |
| `traceroute -n <addr>` | list every router on the way |
| `sudo apt install -y traceroute` | install it |

Reading `ping` output:

```
rtt min/avg/max/mdev = 23.6/25.9/27.8/1.4 ms
                                       └─┬─┘
                                      jitter
ttl=52   → 64 − 52 = 12 routers in between
ttl=64   → never left this machine
```

Reading `traceroute` output — three traps:

```
* * *              router chose not to reply. NOT broken.
high middle times  routers deprioritise complaints. Only the LAST line matters.
two addrs on one   parallel links. There is no single "the route".
```

Note: on Windows PowerShell the flag is `-n`, not `-c`. Everything in this
curriculum runs in WSL, where it is `-c`. If a command says "bad value for
option", check the prompt first.

## TCP flags in tcpdump — from module 00-01

The dot means ACK.

| Shown | Meaning |
|---|---|
| `[S]` | SYN — "let's start" |
| `[S.]` | SYN + ACK |
| `[.]` | ACK — "got yours" |
| `[P.]` | PUSH — actual content |
| `[F.]` | FIN — "I'm finished" |
| `[R]` | RST — "no, stop" |

---

## AWS console — from day 01-01

| Where | What |
|---|---|
| top-right account menu → Security credentials | root MFA and access keys |
| top-right region selector | **check this before creating anything** |
| Billing and Cost Management → Budgets | cost alerts |
| IAM → Users / User groups / Policies | identities and permissions |
| CloudTrail → Event history | who did what, last 90 days, free |

**Sign-in URL** (not the root email page):
```
https://<account-id>.signin.aws.amazon.com/console
```

**Traps that cost real time:**

```
resource "missing"        → wrong region. It is still running and billing.
CloudTrail event missing  → wrong region. IAM is global, logs to us-east-1.
billing access denied     → separate switch from admin rights.
console path not found    → menus move; the direct URL usually survives.
```

**Reading an ARN:**
```
arn : aws : service : region : account : resource
                        ↑
            empty for global services such as IAM
```

**Budget reality:**
```
a budget alerts. it never stops spending. data lags up to 24h.
the real protection is tearing down every lab the same day.
```

---

## IAM policies — from day 01-02

**A statement has four parts:**
```
Effect     Allow | Deny
Action     service:Operation        e.g. s3:GetObject
Resource   an ARN
Condition  optional. the precision knob.
```

**Evaluation order — explicit Deny always wins:**
```
explicit Deny   ███████
explicit Allow  ████
implicit deny   █        the default. everything starts denied.
```

**S3 ARNs — the most common permission bug:**
```
arn:aws:s3:::bucket        the bucket    ← ...Bucket... actions
arn:aws:s3:::bucket/*      the objects   ← ...Object... actions

s3:ListBucket  on bucket/*   silently grants nothing
```
Three levels of visibility: `ListAllMyBuckets` (see bucket names) →
`ListBucket` (see inside one) → `GetObject` (read one file).

**Useful condition keys:**
```
aws:MultiFactorAuthPresent    did this session use MFA
aws:SourceIp                  where the request came from
aws:RequestedRegion           which region was asked about
aws:username                  a VARIABLE - substituted with the caller
```

**BoolIfExists vs Bool:**
```
Bool          only matches when the key EXISTS and is false
BoolIfExists  also matches when the key is ABSENT  ← access keys
```

**NotAction** = everything except the listed actions.

**Roles:**
```
trust policy        WHO may assume it  (has a Principal) - only roles
permissions policy  WHAT they may do

assuming a role REPLACES your permissions. it does not add to them.
```

**Reading denial messages:**
```
"no identity-based policy allows"  → implicit deny. add an Allow.
"explicit deny in a policy"        → a Deny is blocking. adding Allows won't help.
arn:aws:sts::...:assumed-role/ROLE/USER   → temporary creds, role + wearer
```

**Traps:**
```
created a policy but never attached it   → zero effect, looks fine
Bool instead of BoolIfExists             → access keys walk through
no NotAction carve-out on an MFA deny    → permanent lockout
budget breaker that denies everything    → you can't delete the costly thing
```
