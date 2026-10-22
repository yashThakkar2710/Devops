# 01-04 · NAT, security groups, NACLs and endpoints

**Week 1 · Day 4**
Interactive page: [`site/day-04.html`](../../site/day-04.html)

**After this day you can explain:** why a route to an internet gateway is
the wrong answer for a private subnet, what NAT actually does and why
outbound-only is a side effect rather than a rule, the difference between
stateful and stateless filtering, why two servers in one subnet can have
different rules, and how a gateway endpoint removes the need for NAT
entirely.

**Assumes:** [`01-03`](01-03-vpc-from-scratch.md) — subnets, route tables,
internet gateways, CIDR.

---

## 1. The problem

A database in `private-1a` needs to download security updates. It has no
route out.

The obvious fix is to add `0.0.0.0/0 → internet gateway`. **That is wrong,
and the reason is the whole day:**

```
database  →  internet     allowed       what you wanted
internet  →  database     also allowed  what you just created
```

A route to an internet gateway works **both ways**. Adding it makes the
database public.

What is actually needed is one-way:

```
out  yes
in   no
```

## 2. The mechanism

### 2.1 NAT, and why one-way is a side effect

This was already observed on the learner's own machine in the parked
networking work:

```
leaving the PC        FROM 192.168.31.9    private
leaving the router    FROM 152.59.39.80    rewritten to public
```

A home router does exactly this. The laptop reaches the internet; the
internet cannot reach the laptop. **Nobody wrote a firewall rule for that.**

The router keeps a note — *"I sent a request to example.com on behalf of
192.168.31.9"* — and matches replies against it.

```
a reply to something I sent     a note exists   → forwarded
an unexpected inbound connection no note        → dropped
```

> **One-way is a consequence of the rewriting, not a policy.** Outbound
> works because a note exists; inbound fails because one does not.

**NAT** — Network Address Translation — is that rewriting. AWS sells it as a
managed service, the NAT gateway. Same job as the home router.

### 2.2 A public IP and a route are two independent things

A good question came up: would a NAT gateway work in a *private* subnet if
given an Elastic IP?

**No.** It would have a perfectly good public address and no road.

```
NAT asks:    where does 104.20.23.154 go?
route table: 10.0.0.0/16 local ... and nothing else
             → dropped
```

> A street address on a house with no road to it. The postman knows where
> you live and still cannot get there — and you cannot leave either.

This is the mirror of day 3's observation that a route alone is not enough
for inbound. Both halves:

```
route, no public IP   can go out via NAT, cannot be reached
public IP, no route   nothing works at all
both                  reachable both ways
neither               sealed
```

**Every "is this reachable?" question in AWS is these two switches.** The
NAT lives in a public subnet precisely because that is where both are
satisfied.

### 2.3 The finished routing

```
private-1a  ┐
            ├─►  private-rt  →  0.0.0.0/0 → NAT  ──┐
private-1b  ┘                                       │
                                                    ▼
public-1a   ┐                              NAT (in public-1a)
            ├─►  public-rt   →  0.0.0.0/0 → IGW  ──► internet
public-1b   ┘
```

**Same destination, different target.** That is the entire difference:

```
→ internet gateway   two-way.  public.
→ NAT gateway        one-way.  private.
```

### 2.4 Regional vs zonal NAT, and the failure that motivates it

The console now offers an **Availability mode**:

```
Regional   spans all AZs automatically
Zonal      lives in one subnet, one AZ
```

**Zonal was chosen deliberately**, because the exam was written around it
and because the limitation is the lesson:

```
my-nat lives in public-1a (building A)
private-1b routes 0.0.0.0/0 → my-nat

building A fails
  → the NAT is gone
  → private-1b has a route pointing at nothing
  → building B is healthy and its servers are cut off anyway
```

The classic answer, and the exam answer:

```
public-1a  →  nat-1a       private-rt-a  →  0.0.0.0/0 → nat-1a
public-1b  →  nat-1b       private-rt-b  →  0.0.0.0/0 → nat-1b
```

**One NAT per AZ, one private route table per AZ.** Cost: two NAT gateways,
roughly $64/month — which is why many small setups knowingly accept the
risk and run one. A real trade-off, not an obvious win.

Regional mode is AWS solving this in the product. It is newer than the
exam material; worth knowing it exists, not worth learning instead of the
zonal model.

### 2.5 Routing and security answer different questions

```
route table   WHERE does this packet go?
security      is it ALLOWED?
```

Both must say yes. Day 3's "cannot reach the internet" was a routing
problem. Most "cannot connect to my server" problems are security
problems. **Knowing which one you are looking at saves hours.**

### 2.6 Security groups

A firewall attached to **a thing** — a server, a database, a load balancer
— not to a subnet.

```
┌─ private-1a ──────────────────────┐
│   server A  [sg-web]              │  different rules
│   server B  [sg-database]         │  same subnet
└───────────────────────────────────┘
```

Two servers in one subnet with completely different rules, because each has
its own guard at its own door.

A rule names a protocol, a port and a source:

```
HTTP   TCP  80   0.0.0.0/0          anyone, web traffic
SSH    TCP  22   152.59.39.80/32    one address only
```

### 2.7 Stateful versus stateless — the most-tested fact

Every conversation has two directions. The question is whether you need a
rule for each.

**A guard who takes notes (stateful):**

```
visitor arrives   → on the list → let in, and write it down
visitor leaves    → check the notebook → let out
```

One rule. Leaving is handled by the note.

**A guard with no notes (stateless):**

```
visitor arrives   → on the IN list → let in
visitor leaves    → no memory → check a separate OUT list → blocked
```

Two rules required.

```
Security group  =  takes notes     STATEFUL
NACL            =  no notes        STATELESS
```

In practice:

```
security group    inbound: allow 80                      done
NACL              inbound: allow 80
                  outbound: allow 1024-65535             mandatory
```

**Forgetting the second NACL rule is one of the most common AWS mistakes.**
The request arrives, the reply is blocked, the page never loads, and the
inbound rule sits there looking correct. With a security group that cannot
happen.

Because replies are automatic, outbound rules on a security group are
usually left wide open. The default — **deny all inbound, allow all
outbound** — is what you want nearly every time.

### 2.8 The other three differences

**Where they attach:**

```
NACL  →  a SUBNET    one guard at the street entrance
SG    →  a RESOURCE  one guard at each front door
```

**Security groups cannot deny.** Allow rules only; anything unlisted is
implicitly blocked. To block one specific address you need a NACL.

> The same shape as IAM: Allow grants, Deny blocks, and you need Deny to
> build a guardrail.

**NACL rules are numbered and the first match wins.**

```
rule 100   DENY   203.0.113.50     matched first → stop
rule 200   ALLOW  0.0.0.0/0        never read for that address
```

Flip the numbers and the block does nothing — rule 100 would allow
everyone, including the address you meant to stop. Security groups have no
order: all rules are evaluated and any allow is sufficient.

### 2.9 The layers, in order

```
internet
   ▼
route table      does a path exist?
   ▼
NACL             subnet border    stateless, ordered, can deny
   ▼
security group   the door         stateful, unordered, allow-only
   ▼
the server
```

**Any one says no and it is blocked.** Checking them outside-in is the
professional diagnostic order.

### 2.10 Which to actually use

```
security groups   for essentially everything
NACLs             leave at the default unless you need a blanket DENY
```

The default NACL allows everything both ways, deliberately, so it stays out
of the way. Most companies never touch it. Reach for one when blocking a
known-bad range across a whole subnet, when a compliance rule demands a
second layer, or for "nothing in this subnet may ever talk to X".

**NACLs exist for what security groups structurally cannot do** — which is
exactly the Deny case.

### 2.11 VPC endpoints

Without one, a private server reading from S3 does this:

```
private subnet → NAT → internet gateway → the public internet → S3
```

S3 is an AWS service in the same region. The traffic leaves AWS and comes
straight back, paying NAT data charges and crossing the public internet to
reach a service next door.

A **VPC endpoint** is a private door to AWS services.

```
Gateway endpoint     S3 and DynamoDB only.  A route table entry.  Free.
Interface endpoint   almost everything else. A network card with a
                     private IP in your subnet. ~$0.01/hr per AZ + data.
```

Interface endpoints are built on PrivateLink.

> **Exam trap:** both types now exist for S3. A question mentioning cost
> wants the **gateway** endpoint.

Creating the gateway endpoint wrote a route by itself:

```
pl-78a54011 (…ap-south-1.s3)   →  vpce-02056949513302f39   Active
0.0.0.0/0                      →  nat-...                  Active
10.0.0.0/16                    →  local                    Active
```

`pl-` is a **prefix list** — AWS's managed list of every IP range S3 uses in
this region, kept updated by AWS. You reference the list, never the
addresses.

**Most specific wins**, so S3 traffic silently takes the free private path
and everything else still goes via NAT. The same rule from day 3, now doing
real work.

### 2.12 Blackhole routes

Deleting the NAT left this behind:

```
0.0.0.0/0    nat-0a27882dca7762a5f    ⚠️ Blackhole
```

**A route pointing at something that no longer exists.** Traffic matches the
rule and then evaporates, with no error anywhere.

> In a real job, "blackhole" in a route table is frequently the answer to
> *"it worked yesterday"*.

### 2.13 Elastic IPs charge when idle

```
attached to something running   free
sitting unattached              ~$3.60/month
```

Deleting the NAT leaves its address allocated and billing. **This is the
one people forget.** AWS charges for held-but-unused public addresses
deliberately — IPv4 addresses are scarce, and hoarding should cost
something.

## 3. What was built, and torn down

```
built:    my-nat (zonal, public-1a) + Elastic IP
          private-rt → 0.0.0.0/0 → my-nat, associated with both private subnets
          s3-endpoint (Gateway) → wrote its own route into private-rt

deleted:  my-nat
          the blackhole route
          the Elastic IP

kept:     my-vpc, subnets, route tables, my-igw, s3-endpoint    all free
```

End state: **the private subnets reach S3 and nothing else.** No internet,
no NAT, no cost — and a lot of real architectures look exactly like this.

Security groups were covered conceptually only; they get built and broken on
day 5, when there is a server to attach one to.

## 4. Why is it like this

**Why does an internet gateway route work both ways while NAT does not?**
Because an internet gateway does not rewrite anything — it forwards, and a
packet with a reachable public address can be addressed from either end.
NAT replaces the sender's address, which destroys the information anyone
outside would need to initiate a connection inward. The asymmetry is a
by-product of the translation, not a feature bolted on.

**Why are security groups stateful and NACLs not?** A security group is
attached to one resource and can afford to track that resource's
connections. A NACL sits on a subnet boundary carrying traffic for
everything inside it; tracking state for all of it would be far more
expensive and would make the NACL a bottleneck. Statelessness is the price
of being a cheap, high-throughput filter.

**Why can a security group not express Deny?** Because its rules are
additive and unordered, which is what makes them safe to attach several of
at once. Introducing Deny would require evaluation order, and order is
exactly what NACLs provide. The two are deliberately different tools.

**Why is a gateway endpoint free and an interface endpoint not?** A gateway
endpoint is a route table entry — AWS adds a line to a table it already
maintains. An interface endpoint provisions a real network interface with a
private IP in your subnet, which consumes actual capacity.

## 5. Failure modes

- **Internet gateway route on a private subnet** — the subnet is now public
  and nothing warns you.
- **NAT gateway placed in a private subnet** — builds fine, never works.
- **NAT in one AZ** — the other AZ's private subnet loses internet when that
  building fails, while its own servers are perfectly healthy.
- **NACL inbound rule without the matching outbound rule** — requests
  arrive, replies are silently dropped, and the configuration looks right.
- **NACL deny rule numbered after a broad allow** — never evaluated.
- **Elastic IP left allocated after deleting the NAT** — ~$3.60/month,
  invisible.
- **Blackhole route** — traffic matches and disappears, with no error.
- **Interface endpoint chosen where a gateway endpoint would do** — a
  recurring monthly charge for something that was free.

## 6. Recall

See [`recall/week-1-questions.md`](../../recall/week-1-questions.md).

## 7. Carried forward

| Met today | Used on |
|---|---|
| Security groups, hands-on | day 5 — attached to a real server, then broken |
| Why NACL outbound needs ports 1024-65535 | day 5 — ephemeral ports |
| One NAT per AZ | day 14 — making the whole stack survive an AZ failure |
| PrivateLink / interface endpoints | day 24 — connecting VPCs and on-prem |
| Prefix lists | day 24 |
