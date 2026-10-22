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

---

## VPC — from day 01-03

**The hierarchy:**
```
region        ap-south-1          a city
  AZ          ap-south-1a         a building in it
    VPC       10.0.0.0/16         your neighbourhood (spans AZs)
      subnet  10.0.1.0/24         one street (lives in ONE AZ)
```

**Private ranges — reusable everywhere, routable nowhere:**
```
10.0.0.0/8        172.16.0.0/12        192.168.0.0/16
```

**Slash numbers:**
```
/8   1 number fixed   16,777,216 addresses
/16  2 numbers fixed       65,536
/24  3 numbers fixed          256
/32  4 numbers fixed            1
/0   nothing fixed      everything   ← 0.0.0.0/0, the catch-all
```
Bigger slash = smaller range.

**A route table:**
```
10.0.0.0/16   local        automatic, permanent, cannot be deleted
0.0.0.0/0     igw-xxxxx    YOU add this. it is what makes a subnet public.
```
Most specific match wins.

**What makes a subnet public:**
```
there is no checkbox. the name means nothing.
public  = its route table points 0.0.0.0/0 at an internet gateway
private = it does not
```

**Traps:**
```
gateway attached but no route    → nothing works, everything looks right
internet route in the MAIN table → every subnet becomes public, forever
all subnets in one AZ            → fine until that building has a problem
a /24 VPC                        → runs out, and cannot be enlarged
route to IGW from a private subnet → works BOTH ways. not what you want.
```

**Free while idle:** VPC, subnets, route tables, internet gateway.
**Not free:** NAT gateway (~$32/mo), Elastic IPs when unattached.

### Subnetting — the lookup to know cold

```
256 → /24     anchor. halve the size, add 1 to the slash.
128 → /25
 64 → /26
 32 → /27
 16 → /28

512 → /23     double the size, subtract 1
1,024 → /22
2,048 → /21
4,096 → /20
65,536 → /16
```

**AWS reserves 5 per subnet:** `usable = total − 5`
```
/28 → 11    /27 → 27    /26 → 59    /24 → 251    /23 → 507
```
Smallest allowed `/28`, largest `/16`.

**Splitting:**
```
1. how many pieces?
2. total ÷ pieces = size of each
3. what slash is that size? then count up by that size

/24 into 4:  256 ÷ 4 = 64 → /26 → starts at 0, 64, 128, 192
```

**The slip to avoid:**
```
the ADDRESS says where it starts
the SLASH says how far it extends
10.0.5.0/25 covers .0–.127     10.0.5.0/24 covers .0–.255
```

**Sizing a VPC:** the exam wants the minimum. Real life wants `/16` —
unused addresses are free and a VPC can never be enlarged.
