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

---

## NAT, security and endpoints - from day 01-04

**Routing vs security answer different questions:**
```
route table   WHERE does this go?
security      is it ALLOWED?
both must say yes
```

**Outbound-only, and why:**
```
-> internet gateway   two-way.  public.
-> NAT gateway        one-way.  private.

one-way is a SIDE EFFECT of rewriting the sender address,
not a firewall rule. no note = no way back in.
```

**Two independent switches for reachability:**
```
route, no public IP   can go out via NAT, cannot be reached
public IP, no route   nothing works at all
```
A NAT gateway must sit in a PUBLIC subnet - that is where both hold.

**Security group vs NACL:**
```
                 security group        NACL
attached to      a resource            a subnet
state            STATEFUL              STATELESS
deny rules       no                    yes
order            none, any allow wins  numbered, FIRST MATCH WINS
default          deny in, allow out    allow everything both ways
use it for       ~everything           blanket DENY only
```

**Stateless means both directions:**
```
NACL inbound   allow 443
NACL outbound  allow 1024-65535      <- forget this and replies vanish
```

**Diagnostic order, outside in:**
```
route table  ->  NACL  ->  security group  ->  the server
any one says no = blocked
```

**VPC endpoints:**
```
Gateway     S3 + DynamoDB ONLY.  route table entry.  FREE
Interface   everything else.     an ENI in your subnet.  paid, per AZ
```
Gateway endpoints write their own route:
`pl-xxxx (service) -> vpce-xxxx`. Most specific wins, so that traffic
takes the free private path automatically.

**Costs to remember:**
```
NAT gateway          $0.045/hr  ~$32/mo  + $0.045/GB
Elastic IP, idle     ~$3.60/mo            <- the one people forget
Elastic IP, attached free
gateway endpoint     free
interface endpoint   ~$0.01/hr per AZ + data
```

**Blackhole** in a route table = the target no longer exists. Traffic
matches the rule and vanishes with no error. Usually the answer to
"it worked yesterday".

---

## EC2, EBS and AMIs - from day 01-05

**Three things required for inbound reachability - all of them:**
```
1. a route to the internet gateway
2. a PUBLIC IP           <- off by default in a subnet you built
3. a security group rule
```

**Instance type naming:**
```
t3.micro
| |  `- size      nano small medium large xlarge ... (roughly doubling)
| `---- generation
`------ family    t burstable  m general  c compute  r memory
                  i/d storage  g/p GPU
```

**user data vs AMI:**
```
user data   runs at boot, flexible, slow, can differ per instance
AMI         prepared in advance, fixed, fast, every copy identical

AMI        things that DON'T change   nginx, your app, libraries
user data  things that DO change      hostname, environment, config
```
An AMI captures FILES, not the scripts that wrote them.

**EBS:**
```
a disk on the NETWORK. lives in ONE AZ. outlives the instance.
gp3  default answer          io2  guaranteed IOPS, databases
st1  sequential throughput   sc1  cold, cheapest

instance store = physically inside the host, WIPED on stop
```

**Snapshots:**
```
volume   = one AZ
snapshot = REGIONAL     <- this is how you move a disk between AZs
incremental: only changed blocks. deleting an old one is safe.
```

**AMI vs snapshot:**
```
AMI       instructions (boot from snap-xxx)
snapshot  the bytes
deregistering an AMI does NOT delete its snapshot
"delete associated snapshots" is UNCHECKED by default
```

**DeleteOnTermination:**
```
root volume    true    goes with the instance
extra volumes  false   survive, billing quietly
```

**Purchasing:**
```
On-Demand        per second, no commitment
Reserved         1 or 3 years, ~40-60% off
Savings Plans    commit $/hour, ~40-70%, flexible (also Lambda/Fargate)
Spot             up to 90% off, 2 minutes notice  -> interruptible work only
Dedicated Host   per-socket licensing
```

**Diagnosis - the most useful table in networking:**
```
hangs then times out       nothing replied   -> firewall / wrong IP / no route
"connection refused" fast  something replied -> network FINE, app is DOWN
"could not resolve host"   DNS               -> never got as far as connecting
```
Security groups and NACL denies always DROP, never reject.

**SSH to an instance:**
```
chmod 400 my-key.pem                      ssh refuses world-readable keys
ssh -i my-key.pem ec2-user@<public-ip>    ec2-user on Amazon Linux
                                          ubuntu on Ubuntu, admin on Debian
```
Windows / Git Bash, if chmod does not take:
```
icacls my-key.pem /inheritance:r
icacls my-key.pem /grant:r "$USERNAME:R"
```

**From inside an instance:**
```
systemctl status nginx       is the service running
sudo ss -tlnp | grep :80     is anything LISTENING, and on which address
curl localhost               the decisive test - no network layers involved
```

**Read a boot log without connecting:**
```
EC2 -> Instance -> Actions -> Monitor and troubleshoot -> Get system log
```

**Test with curl, not a browser.** Browsers do HTTPS upgrades, caching,
prefetch and extensions. Chrome's "Always use secure connections" rewrites
http:// to https:// and hangs if 443 is closed.

**Naming:** security group names may not start with `sg-` - that prefix is
reserved for IDs.
