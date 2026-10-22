# 01-03 · A VPC from scratch

**Week 1 · Day 3**
Interactive page: [`site/day-03.html`](../../site/day-03.html)

**After this day you can explain:** why the same IP address can exist in
millions of places at once, what the slash number means, what a VPC and a
subnet actually are, what an availability zone physically is, and the one
thing that makes a subnet public.

**Assumes:** nothing about networking. The parked
[Phase 0 work](../phase-0-map/00-01-journey-of-a-request.md) covers the same
ideas from the packet side and maps onto this directly.

---

## 1. The problem

AWS runs millions of servers in one building. Yours, mine, a bank's — all
physically near each other. If they shared one network, anyone could reach
anyone.

A **VPC** is a private network of your own inside AWS. Sealed by default:
nothing reaches your servers unless you deliberately build a path.

## 2. The mechanism

### 2.1 Two kinds of address

This is the thing that confuses everyone first, and nothing else makes sense
until it clicks.

**Every book has a page 5.** Millions of books, millions of page 5s, no
confusion — because "page 5" means nothing until you say *which book*.

IP addresses work the same way:

```
company A's network    company B's network    your network
10.0.0.5               10.0.0.5               10.0.0.5
```

All three exist. None collide. Because `10.0.0.5` is meaningless until you
say which network.

**Try to reach it from outside and the question is unanswerable.** Which
`10.0.0.5`? There are millions. The packet is dropped.

> Private addresses are safe not because of a firewall, but because the
> question has no answer.

Three ranges are reserved worldwide for this. Anyone may use them; nobody
routes them on the internet:

```
10.0.0.0    → 10.255.255.255
172.16.0.0  → 172.31.255.255
192.168.0.0 → 192.168.255.255
```

A **public** address is unique on the whole internet — like a street
address rather than a room number.

### 2.2 One machine has many addresses — one per door

Measured on this machine:

```
Wi-Fi                       192.168.31.9     on the home network
vEthernet (WSL)             172.26.0.1
vEthernet (Default Switch)  172.20.144.1
Loopback                    127.0.0.1        itself
```

Four addresses, one PC. An address belongs to an **interface**, not to a
computer.

### 2.3 The journey, and the rewrites

Three networks nested inside each other:

```
NETWORK 1   inside the PC        172.26.0.0/20
NETWORK 2   the home             192.168.31.0/24
NETWORK 3   the internet         public addresses
```

What the packet's **FROM** field says at each stage:

```
leaving the inner network   FROM 172.26.1.224   TO 104.20.23.154
leaving the PC              FROM 192.168.31.9   TO 104.20.23.154   rewritten
leaving the router          FROM 152.59.39.80   TO 104.20.23.154   rewritten
```

**The destination never changes. The sender is rewritten at every
boundary.** The far end only ever sees the public address and could not
reply to the private one.

Why rewrite? Because a private address is a page number — useless on the
next network out. If the router sent it unchanged, the reply would have
nowhere to go.

Each layer keeps a note of who asked, so replies find their way back. That
mechanism is **NAT**, covered on day 4.

### 2.4 The slash number

An IPv4 address is four numbers, each 0–255. The slash says **how many of
them are fixed**.

```
192.168.31.9 /24
└── street ──┘ └┬┘
              house
```

| Written | Numbers fixed | Addresses |
|---|---|---|
| `/8` | 1 | 16,777,216 |
| `/16` | 2 | 65,536 |
| `/24` | 3 | 256 |
| `/32` | 4 | 1 |

**Bigger slash, smaller range** — because more of the address is pinned
down. `/32` means everything is fixed, so exactly one address.

`/0` means *nothing* is fixed, so it matches every address that exists —
which is why `0.0.0.0/0` is the catch-all.

## 2a. Subnetting, properly

Added after the main build, because fluency here is assumed by every later
day — NAT, load balancers, databases, peering all start with "how do I split
this".

### An address is 32 switches, not 4 numbers

```
192  .  168  .  31  .  9
8 bits  8 bits 8 bits 8 bits   = 32 bits
```

**The slash counts bits, not numbers.** `/24` means the first 24 bits are
fixed, which happens to be three whole numbers — which is why `/8`, `/16`
and `/24` feel clean. A slash can be anything from 0 to 32, and the ones
that land mid-number are where AWS actually lives.

### Size and slash: one relationship

```
addresses = 2 ^ (32 - slash)
```

In practice, don't compute powers. **Anchor at `/24` = 256 and count steps:**

```
256  →  /24       halve the size, add 1 to the slash
128  →  /25       double the size, subtract 1
 64  →  /26
 32  →  /27
 16  →  /28
```

```
512  →  /23
1,024 → /22
2,048 → /21
4,096 → /20
65,536 → /16
```

Counting steps from a known anchor is far more reliable than recalling
powers of two, and it is the method that survives exam pressure.

### AWS reserves five addresses per subnet

```
x.x.x.0     network address
x.x.x.1     the VPC router
x.x.x.2     DNS
x.x.x.3     reserved for future use
x.x.x.255   broadcast
```

```
usable = total − 5
```

| Subnet | Total | Usable |
|---|---|---|
| `/28` | 16 | 11 |
| `/27` | 32 | 27 |
| `/26` | 64 | 59 |
| `/24` | 256 | 251 |
| `/23` | 512 | 507 |

**`/28` is the smallest subnet AWS permits; `/16` the largest.** A `/24`
gives 251 usable, not 256 — a sizing done by instinct rather than
arithmetic fails at server number 252.

### Splitting a block: three steps

```
1. how many pieces do I want?
2. total ÷ pieces = size of each
3. what slash is that size?  then count up by that size
```

Splitting `10.0.1.0/24` into four:

```
256 ÷ 4 = 64 each  →  /26  →  block size 64

10.0.1.0/26      .0   – .63
10.0.1.64/26     .64  – .127
10.0.1.128/26    .128 – .191
10.0.1.192/26    .192 – .255
```

```
more pieces → each smaller → bigger slash number
every doubling of the piece count adds 1 to the slash
```

Pieces must start on clean boundaries — `10.0.1.50/26` is rejected. They
tile the space, each beginning exactly where the last ended.

### The address says where; the slash says how far

The most common slip is getting the starting addresses right and attaching
the wrong slash:

```
10.0.5.0/25     starts at .0, extends 128  →  .0 to .127     correct
10.0.5.0/24     starts at .0, extends 256  →  .0 to .255     claims everything
```

Both halves of the answer can be right while the label is wrong, and the
result is subnets that overlap. AWS rejects it, but on paper it looks fine.

### A worked design

> Six subnets, about 500 servers each.

```
1. per subnet:  500 + 5 reserved = 505 minimum
2. slash:       /24 = 251 usable, too small
                /23 = 507 usable  ✅
3. total:       6 × 512 = 3,072
4. VPC:         /21 = 2,048 too small
                /20 = 4,096  ✅
```

```
VPC      10.0.0.0/20
subnets  6 × /23, block size 512 → third number jumps by 2

10.0.0.0/23   10.0.2.0/23   10.0.4.0/23
10.0.6.0/23   10.0.8.0/23   10.0.10.0/23
```

**And in practice you would still choose `/16`.** The exam asks for the
minimum; real life asks what you will not regret. Unused addresses cost
nothing, a VPC can never be enlarged, and being wrong is cheap in one
direction and unfixable in the other.

That is why this VPC is `10.0.0.0/16` despite needing a fraction of it.

### 2.5 VPC and subnet

```
VPC     the neighbourhood     10.0.0.0/16    65,536 addresses
subnet  one street in it      10.0.1.0/24    256 addresses
```

The CIDR is chosen at creation and **cannot be changed afterwards** (blocks
can be added, never altered or shrunk). Choose generously — unused addresses
cost nothing.

**Why cut it into streets at all?** Not for tidiness — for *different
rules*:

```
10.0.1.0/24    web servers   the internet may reach these
10.0.11.0/24   database      the internet must never reach these
```

Put everything on one street and you cannot separate them.

### 2.6 Availability zones

A region is several **availability zones**, each a physically separate
datacenter — different buildings, different power, kilometres apart, joined
by fast fibre so traffic between them takes about a millisecond.

**A subnet lives in exactly one AZ and cannot span two.** That is why
surviving a datacenter failure needs at least two subnets, one per building.

```
public-1a, private-1a    ap-south-1a    building A
public-1b, private-1b    ap-south-1b    building B
```

Same shape as the MFA backup on day 1: *more than one way in, each one
strong*. AWS repeats this idea everywhere.

### 2.7 Route tables are signposts

```
Destination     Target
10.0.0.0/16     local          my own neighbourhood → direct
0.0.0.0/0       igw-xxxxx      everything else → the gate
```

Identical in shape to any machine's own routing table:

```
default  via 192.168.31.1      ← "default" IS 0.0.0.0/0
```

The table picks the **most specific** match. `10.0.1.50` matches
`10.0.0.0/16`, so it stays local. `104.20.23.154` matches only `0.0.0.0/0`,
so it goes to the gate.

`local` is created automatically and **cannot be deleted** — a VPC must
always be able to talk to itself.

### 2.8 What actually makes a subnet public

There is no "public" checkbox. The name means nothing.

> **A subnet is public if its route table has a line pointing to an internet
> gateway. That is the entire difference.**

```
public subnet   route table has  0.0.0.0/0 → igw
private subnet  it does not
```

It is a property of the **route table**, not of the subnet.

And a route to the gateway is not sufficient on its own for inbound traffic
— a server also needs a public IP for anyone outside to address it. Day 5.

### 2.9 Creating a gateway changes nothing

This is the most common "why can't my server reach the internet" question in
AWS.

```
gateway created and attached   →  nothing changes
a route table points to it     →  now it works
```

Building a gate does not put up signposts. The gateway can be twenty metres
away and entirely invisible to a subnet whose route table has never heard of
it.

### 2.10 Never put an internet route in the main route table

Every VPC has a **main route table** — the fallback for any subnet not
explicitly assigned one.

```
Explicit subnet associations     subnets you told which table to use
Subnets without associations     fall back to the main table
```

Adding an internet route to the main table makes **every** subnet public,
including ones created later and forgotten about.

> The main table is what you get when you forget something. It should
> therefore be the *safe* option.

So public subnets get their own table; private subnets stay on the main one.

## 2b. Designing a VPC: the method

Worked through after the build, from the question "how do we decide".

### Step 1 - subnets exist because rules differ

Not because of a target count. **If two things need the same rules they can
share a subnet; if they need different rules they must be separated.**

| Part | Who must reach it |
|---|---|
| Load balancer | the whole internet |
| App servers | only the load balancer |
| Database | only the app servers |

Three different answers, three subnets.

App and database are both private, so today their rules match. They are still
separated, because *only the app subnet may talk to the database subnet* is a
sentence you cannot write if they share one. **Separate what you might want to
treat differently later.**

A subnet lives in exactly one AZ, so surviving a building failure doubles the
count: 3 purposes x 2 buildings = 6 subnets. That is why real VPCs have six and
not three.

### Step 2 - size for peak and deployments, never for today

Three results that surprise people:

**The load balancer subnet holds none of your servers, and still needs room.**
An ALB consumes several addresses per subnet; AWS requires at least 8 free and
a `/27` minimum. NAT gateways and VPC endpoints do the same. AWS services eat
addresses you did not plan for.

**The app tier is the largest, because deployments double it.** A rolling
deployment starts the new servers *before* killing the old ones, so 40 running
briefly becomes 80. Size for today and the deploy fails at the worst moment.

**The database tier is the smallest.** Primary, standby, maybe a read replica.
Three, perhaps five ever. It feels like the most important tier so it gets the
biggest subnet; that is backwards. **Databases scale by getting bigger, not by
multiplying.**

```
load balancer   /27     32 addresses
app servers     /25    128 addresses
database        /28     16 addresses
```

A subnet can never be resized. The asymmetry is total: generous costs nothing,
tight is unfixable.

### Step 3 - allocate largest first

```
BIGGEST FIRST                      SMALLEST FIRST
10.0.0.0/23    B  500              10.0.0.0/25     A   60
10.0.2.0/25    A   60              10.0.0.128/25   C   60
10.0.2.128/25  C   60              10.0.1.0/24     -- stranded
                                   10.0.2.0/23     B  500
nothing wasted                     256 addresses skipped
```

Going smallest first leaves `10.0.1.0` free but unusable by a `/23`, because a
`/23` must start on a multiple of 512 and `10.0.1.0` is 256 in. The space is
not gone - a `/24` or smaller could still go there - but you have created a
**hole** that only certain sizes fit. Repeat that across a real VPC and you get
address space that is technically free and practically unusable:
**fragmentation**, the same problem as a car park.

### Step 4 - one address line, walk forward, never restart

Every subnet in the VPC takes its slice from the **same single line**, in
order. A common early mistake is restarting at `10.0.0.0` for each tier, which
makes them all overlap.

```
10.0.0.0/25     10.0.0.0   -> 10.0.0.127   app-1a    128
10.0.0.128/25   10.0.0.128 -> 10.0.0.255   app-1b    128
10.0.1.0/27     10.0.1.0   -> 10.0.1.31    lb-1a      32
10.0.1.32/27    10.0.1.32  -> 10.0.1.63    lb-1b      32
10.0.1.64/28    10.0.1.64  -> 10.0.1.79    db-1a      16
10.0.1.80/28    10.0.1.80  -> 10.0.1.95    db-1b      16
```

352 addresses of 65,536. Each begins exactly where the last stopped.

### Alignment: why a /23 cannot start at 10.0.1.0

Blocks of a given size sit in **fixed positions**, like tiles already glued
down. A `/23` is two third-numbers, pre-paired:

```
( 0 , 1 )  ( 2 , 3 )  ( 4 , 5 )  ( 6 , 7 )
```

`10.0.1.0/23` would take half of the first pair and half of the second. The
tiles do not slide.

**The test:** divide the starting number by the block size. A whole number is
legal.

```
/23 block 2    0 / 2 = 0     legal
               1 / 2 = 0.5   illegal
/26 block 64   128 / 64 = 2  legal
               50 / 64       illegal
```

This is not an AWS policy. A router does not count addresses - it checks
whether a fixed pattern of bits matches, which only describes a single clean
block when the free bits start at zero. Starting mid-tile makes the match
ambiguous. The rule holds everywhere: AWS, a home router, the internet
backbone.

### AWS does not divide the VPC by availability zone - you do

The whole range of the VPC is available in every AZ. **The split happens at the
moment you create a subnet** and choose its zone. Nothing is zone-bound before
that.

Which means the layout is a choice:

```
option A - grouped by tier        option B - a block per zone
10.0.0.0/25    app-1a             10.0.0.0/18     everything in A
10.0.0.128/25  app-1b             10.0.64.0/18    everything in B
10.0.1.0/27    lb-1a              10.0.128.0/18   reserved for C
10.0.1.32/27   lb-1b
```

**Option B is what to design on a real account.** Adding a third zone becomes
"use the block already waiting" rather than hunting for gaps, and a rule like
*allow all of zone A* is one line instead of six. Option A is used here only
because it is simpler to learn with.

### AZ letters are randomised per account

`ap-south-1a` is not the same physical building for two different accounts.
AWS shuffles the letters so that everyone default does not land on one
datacenter.

```
ap-south-1a  (your name for it)   ->   aps1-az3  (the stable AZ ID)
```

When two accounts need resources in the *same* physical building, they match on
the **AZ ID**, never the letter. Visible in the console as the "Availability
Zone ID" column.

### Why this VPC uses /24 for everything anyway

The method above was not applied to the subnets built on this account - all
four are `/24`. That is deliberate.

```
65,536 addresses available
 1,024 used
   1.5% consumed
```

| | Uniform /24 | Carefully sized |
|---|---|---|
| Readability | `10.0.11.x` is instantly private, zone A | look each range up |
| Adding a subnet | next free `/24`, no thought | recalculate and re-align |
| Overlap mistakes | nearly impossible | easy |
| Space used | wasteful | efficient |

Plenty of production VPCs do exactly this, on purpose. **The sizing method is
for when you cannot be generous** - a `/20` VPC, overlapping office ranges,
many peered VPCs, hundreds of subnets. With 65,000 spare addresses, simplicity
is worth more than efficiency.

### Gaps between groups are deliberate

```
10.0.1.0/24     public-1a
10.0.2.0/24     public-1b
10.0.3.0/24  .. 10.0.10.0/24    free - room for the public tier to grow
10.0.11.0/24    private-1a
10.0.12.0/24    private-1b
10.0.21.0/24    db-1a           waiting, obvious without a lookup
```

Packed tight, a third public subnet would land *after* the private ones and the
scheme that lets an address identify itself at a glance breaks forever.
**Leave gaps between groups. Addresses are free; a numbering scheme that stops
making sense is not.**

## 3. What was built

```
my-vpc           10.0.0.0/16
  public-1a      10.0.1.0/24    ap-south-1a
  public-1b      10.0.2.0/24    ap-south-1b
  private-1a     10.0.11.0/24   ap-south-1a
  private-1b     10.0.12.0/24   ap-south-1b

my-igw           attached to my-vpc
public-rt        0.0.0.0/0 → my-igw
                 associated with public-1a and public-1b only
main route table only "local" — used by both private subnets
```

**Addressing scheme:** `10.0.1.x` and `10.0.2.x` public, `10.0.11.x` and
`10.0.12.x` private. Nothing technical about it — it means an address read
in a log at 2am identifies itself without a lookup. Pick a scheme early and
keep it.

**No teardown.** VPCs, subnets, route tables and internet gateways are all
free while idle, and this VPC is the foundation for days 4 and 5. The
teardown rule is about *money*, not tidiness: never leave running something
that charges.

### Billing access, corrected

Day 1 concluded that IAM billing access was already active because the
Budgets page loaded. **That was wrong.** Budgets has its own permissions
which `AdministratorAccess` grants directly; the switch was still off, and
the **Bills** page refused outright.

Fixed as root at `billing/home#/account` →
*IAM user and role access to Billing information* → Activate.

```
testing one page  →  tells you about that one page
```

Not an argument against testing — an argument for testing **the thing you
actually care about**. We cared about seeing the bill, so we should have
opened the bill.

Confirmed at the same time: **total spend so far is USD 0.00**, including
the budget action whose cost was uncertain.

## 4. Why is it like this

**Why are private ranges not routable?** Because routing requires a unique
destination. Reusable addresses and global routing are mutually exclusive;
the private ranges trade one for the other deliberately, and that trade is
what makes them safe by default.

**Why can a subnet not span availability zones?** Because an AZ is a real
building. A subnet is a range of addresses that physically live somewhere,
and "somewhere" cannot be two buildings at once without the isolation
between them becoming a lie.

**Why is "public" a route table property rather than a subnet setting?**
Because reachability is a routing question, not a storage question. Making
it a checkbox would hide the mechanism and make the answer to "how does
traffic actually leave" unavailable — which is exactly the knowledge needed
when it stops working.

**Why can the CIDR never be changed?** Because every route, every security
rule and every peering relationship in and beyond the VPC is expressed in
terms of it. Changing it would invalidate state held in systems AWS does not
control.

## 5. Failure modes

- **Gateway created, route table untouched** — everything looks correct and
  nothing can reach the internet. The single most common VPC question.
- **Internet route added to the main route table** — every subnet becomes
  public, including the database, including subnets created next month.
- **A subnet named "public" with no route** — the name is a label, not a
  configuration.
- **Overlapping CIDRs between VPCs** — blocks peering later, and cannot be
  fixed without rebuilding. Day 24.
- **All subnets in one AZ** — looks fine until that building has a problem.
- **A `/24` VPC** — runs out of addresses, and cannot be enlarged.

## 6. Recall

See [`recall/week-1-questions.md`](../../recall/week-1-questions.md).

## 7. Carried forward

| Met today | Explained on |
|---|---|
| Private subnets needing outbound-only internet | day 4 — NAT gateway |
| Address rewriting at each boundary | day 4 — NAT properly |
| A public IP being needed as well as a route | day 5 — EC2 |
| Security groups and NACLs | day 4 |
| Overlapping CIDRs blocking peering | day 24 |
