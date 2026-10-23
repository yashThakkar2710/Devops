# 01-05 · EC2, EBS and AMIs

**Week 1 · Day 5**
Interactive page: [`site/day-05.html`](../../site/day-05.html)

**After this day you can explain:** the three independent things required
before the internet can reach a server, why user data and AMIs are different
tools for different jobs, what an AMI actually captures, why a timeout and a
"connection refused" send you in opposite directions, and how to bisect a
failure instead of guessing at it.

**Assumes:** [`01-03`](01-03-vpc-from-scratch.md) and
[`01-04`](01-04-nat-security-endpoints.md) — subnets, route tables, public
IPs, security groups.

---

## 1. The problem

Everything so far has been empty plumbing. Today it carries something.

**EC2 — Elastic Compute Cloud — is renting a computer.** The launch wizard
asks five questions, and three of them were already answered in days 3 and 4:

```
1. which operating system?     AMI               new
2. how big a machine?          instance type     new
3. which network and subnet?   day 3
4. who may reach it?           day 4
5. how do you log in?          key pair          new
```

## 2. The mechanism

### 2.1 AMIs

An **AMI** is a saved copy of a complete, finished disk.

```
install the OS, install software, configure it   two hours
save the disk as an image                        once
launch twenty identical copies                   a minute each
```

Choosing "Amazon Linux 2023" does not install Linux. **AWS copies a finished
disk onto a fresh volume and boots it**, which is why it takes sixty seconds
rather than half an hour.

### 2.2 Instance types

```
t3.micro
│ │  └── size
│ └──── generation
└────── family
```

| Family | For |
|---|---|
| `t` | general purpose, **burstable** — cheap, low steady load |
| `m` | general purpose, steady |
| `c` | compute-heavy |
| `r` | memory-heavy |
| `i`, `d` | storage-heavy |
| `g`, `p` | GPU |

Sizes run `nano → micro → small → medium → large → xlarge → …`, roughly
doubling in both capability and price each step.

### 2.3 Three independent requirements for inbound reachability

Day 3 established that a route alone is not enough. Day 4 established that a
public IP alone is not enough. Both are true at once, and there is a third:

```
1. a route to the internet gateway    public-rt already had it
2. a public IP address                NOT automatic
3. a security group rule allowing in  you write it
```

**Miss any one and it fails silently.** The route exists, the security group
is perfect, and without a public IP nothing can address the machine at all.

> **In a subnet you built yourself, auto-assign public IP is OFF by
> default.** AWS enables it in the *default* VPC, which is why tutorials
> never mention it. In a hand-built subnet it must be switched on.

One machine, two addresses:

```
10.0.1.238    private — what it calls itself
13.233.89.217 public  — what the internet reaches
```

**The instance has no idea it has a public address.** The internet gateway
translates on the way in. Ask the server its IP and it says `10.0.1.238`.

### 2.4 Security group sources: different ports, different trust

```
HTTP  80   0.0.0.0/0          correct — the web should be public
SSH   22   152.59.54.26/32    only this one address
```

SSH open to `0.0.0.0/0` attracts automated login attempts within minutes.

**But "My IP" rules break.** The home address changed from `152.59.39.80` on
day 1 to `152.59.54.26` on day 5 — a dynamic ISP allocation. SSH stops
working and nothing looks wrong. Real teams use a VPN or a bastion host for
this reason.

### 2.5 User data

A script that runs **once, automatically, as root**, the first time an
instance boots — before anyone logs in.

```bash
#!/bin/bash
dnf install -y nginx
systemctl enable --now nginx
echo "<h1>Hello from $(hostname -f)</h1>" > /usr/share/nginx/html/index.html
```

```
without   launch, SSH in, install, configure, hope you remember the order
with      launch. done.
```

The second can be repeated a thousand times identically. **This is the
beginning of infrastructure as code** — and it is how Auto Scaling works at
all, because when a server is created at 3am nobody is there to SSH in.

### 2.6 What an AMI actually captures — and the lesson that proved it

An AMI made from `web-1` was used to launch `web-2` with **no user data**.

nginx came up automatically — `systemctl enable` had persisted in the image.
Then:

```
[ec2-user@ip-10-0-1-230 ~]$ curl localhost
<h1>Hello from ip-10-0-1-238.ap-south-1.compute.internal</h1>
```

**The machine is `.230`. The page says `.238`.**

Because the script ran once, on `web-1`, and `$(hostname -f)` was replaced
by its answer at that moment:

```
index.html literally contains:
<h1>Hello from ip-10-0-1-238...</h1>
```

The AMI copied **the file**, not the script that wrote it.

> Photographing a whiteboard. Someone wrote "Today is Monday" and you took a
> photo. On Tuesday the photo still says Monday — you captured the writing,
> not the person who wrote it.

This is a real production problem. AWS regenerates the things that matter
most (SSH host keys, the actual hostname), but **anything your script wrote
into a file is frozen.**

### 2.7 So: user data and AMIs are different tools

```
USER DATA                     AMI
a script run at boot          a disk prepared in advance
flexible, change anytime      fixed, rebuild to change
slow — installs every boot    fast — nothing to install
can differ per instance       every copy identical
```

```
AMI        things that DON'T change    nginx, your app, libraries
user data  things that DO change       hostname, environment, config
```

For Auto Scaling the difference is operational: an AMI with software baked
in is ready in ~30 seconds; a blank AMI plus user data takes ~3 minutes.
**Three minutes is a long time when the site is overloaded.**

### 2.8 EBS

The 8 GiB volume is **Elastic Block Store** — and it is not inside the
machine.

```
instance  ◄══ network ══►  EBS volume
```

A disk on the network, which is why the disk and the computer have separate
lifetimes:

```
terminate the instance   the volume can survive
detach it                attach it to a different instance
snapshot it              back it up while running
```

Two limits:

```
an EBS volume lives in ONE availability zone
one volume attaches to one instance at a time
```

Same AZ rule as subnets. Building A's disk cannot serve building B.

**Volume types:**

| Type | Use for |
|---|---|
| **gp3** | the default answer — boot disks, most workloads |
| **io2** | databases needing guaranteed consistent IOPS |
| **st1** | big sequential throughput — logs, data processing |
| **sc1** | cheapest, rarely accessed |

> **gp3 replaced gp2.** With gp2, speed was tied to volume size, so people
> bought oversized disks purely to get IOPS. gp3 lets size and speed be set
> separately. A question mentioning "paying for unused capacity to get
> performance" is pointing at gp3.

**Instance store** is the other kind:

```
EBS             over the network    SURVIVES stop/start
instance store  physically inside   WIPED on stop, permanently
```

Extremely fast, completely temporary — it is a different physical machine
when it starts again.

### 2.9 Snapshots

A backup of an EBS volume, and the key property is where it lives:

```
EBS volume   ONE availability zone
snapshot     REGIONAL
```

**That is how a disk moves between buildings.** A volume cannot be attached
across AZs; snapshot it and restore into the other AZ. The same mechanism
copies across regions for disaster recovery.

Snapshots are **incremental** — the first captures everything, later ones
only changed blocks. Deleting an old one is safe; AWS retains any blocks
later snapshots still need.

Observed: an 8 GiB volume produced a **1.7 GiB** snapshot. Only used blocks
are stored.

### 2.10 AMI and snapshot are different objects

```
AMI       instructions: boot from snap-xxx, 8 GiB, this is the root disk
snapshot  the actual bytes
```

Creating an AMI created a snapshot nobody asked for. And:

```
delete the snapshot, keep the AMI   the AMI is broken, launches fail
delete the AMI                      the snapshot stays, still billing
```

**Deregistering an AMI does not delete its snapshot.** The console offers a
"Delete associated snapshots" checkbox — **unchecked by default**. Click
straight through and the data keeps costing money. This is how organisations
accumulate hundreds of orphaned snapshots.

> Worth generalising: **on an AWS delete dialog, the default is usually the
> expensive one.**

### 2.11 Delete on termination

```
root volume      DeleteOnTermination = true     goes with the instance
extra volumes    DeleteOnTermination = false    survive, billing quietly
```

A very common source of orphaned storage.

### 2.12 Purchasing options

```
On-Demand          per second, no commitment            most expensive
Reserved Instance  commit 1 or 3 years                  ~40-60% off
Savings Plans      commit to $/hour, 1 or 3 years       ~40-70% off, flexible
Spot               spare capacity, 2 minutes' notice    up to 90% off
Dedicated Host     a whole physical server              most expensive
```

**Spot** is AWS selling unused capacity and reclaiming it when a paying
customer wants it.

```
✅ batch jobs, rendering, CI, big data — anything interruptible
❌ your database, your only web server
```

> **Exam phrasing:** "fault-tolerant", "can be interrupted", "flexible start
> and end times" → Spot. "Steady state, always on" → Reserved or Savings
> Plans.

**Savings Plans are the modern answer** — same discount as Reserved, applies
across instance types and even to Lambda and Fargate.

**Dedicated Host** exists for licensing. Some software is priced per
physical CPU socket, which requires visibility of the actual hardware.
"Bring your own licence" or "per-socket licensing" → Dedicated Host.

### 2.13 Drop versus reject — the most useful diagnostic in networking

Deleting the HTTP rule produced a **hang**, not an error.

```
DROP     the packet is binned, nothing sent back
         → the sender waits for a reply that never comes → TIMEOUT

REJECT   a refusal is sent back
         → the sender knows at once → INSTANT error
```

**Security groups and NACL denies always drop, never reject.**

| Symptom | Meaning |
|---|---|
| hangs, then times out | nothing replied — **firewall, wrong IP, or no route** |
| "Connection refused", instantly | something replied — **the network is fine, the app is down** |
| "Could not resolve host" | DNS — never got as far as connecting |

**These send you in opposite directions.** People spend hours checking
firewalls when the error already said the application had crashed.

Dropping rather than rejecting is deliberate: a rejection confirms a machine
exists. Silence gives an attacker nothing.

## 3. The debugging session

`web-2` timed out in the browser while `web-1` had worked. The resolution
is worth more than the building.

```
1. the failure was a TIMEOUT, not "connection refused"
   → so the packet never reached nginx → not an application problem

2. checked the security group          port 80 from 0.0.0.0/0 present  ✅
   → the first hypothesis was wrong

3. SSH to web-2 WORKED
   → route table, internet gateway, public IP and instance all proven fine
   → only port 80 was affected

4. from inside web-2:
     systemctl status nginx    active (running)
     ss -tlnp | grep :80       0.0.0.0:80 and [::]:80
     curl localhost            200 OK
   → the server is perfect

5. from inside web-2, curl both public IPs    both 200 OK
   → the whole AWS side is proven working

6. curl from the Windows machine, both IPs    both 200 OK
   → the network path from home is proven working

7. therefore: the browser
```

**Chrome's "Always use secure connections" was silently rewriting
`http://` to `https://`.** Port 443 was closed, so it hung. Incognito
confirmed it.

> **Four tests, each eliminating a whole category.** No guessing at any
> point. That is the difference between fixing problems and restarting
> things until they work.
>
> And the lesson underneath: **your test tool can be the bug.** Browsers
> perform HTTPS upgrades, caching, prefetching and extension interference.
> `curl` does exactly what you typed and nothing more. **Diagnose with
> `curl` first** — if curl works and the browser does not, stop looking at
> the server.

## 4. What was built, and torn down

```
built:    web-1       t3.micro in public-1a, nginx via user data
          web-sg      22 from home IP, 80 from anywhere
          my-key      RSA key pair
          web-1-ami   + its automatic snapshot
          web-2       launched from the AMI, no user data

deleted:  both instances, the AMI, the snapshot, both volumes

kept:     my-key, web-sg, my-vpc and everything from days 3-4   all free
```

**A naming failure worth recording:** the first launch failed with
`Group names may not be in the format sg-*`. Security group *IDs* start with
`sg-`, so AWS blocks that prefix in names. The error said exactly that —
another case where reading the message beats searching for it.

## 5. Why is it like this

**Why is auto-assign public IP off by default in a custom subnet?** Because
a subnet you built is assumed to be deliberate. The default VPC is a
convenience for people who do not want to think about networking; a
hand-built one assumes you do, so nothing is made public without being
asked for.

**Why does an AMI capture files rather than re-running scripts?** Because it
is a disk image, not a configuration system. The distinction is what makes
launches fast — there is nothing to execute, only blocks to copy.

**Why is EBS on the network rather than inside the machine?** Because tying
a disk to a physical host would make the disk die with the host. Separating
them allows the volume to outlive the instance, be snapshotted live, and be
reattached elsewhere — at the cost of some latency.

**Why do firewalls drop rather than reject?** Because a rejection is
information. A dropped packet leaves an attacker unable to distinguish a
firewall from a wrong address from a dead machine.

## 6. Failure modes

- **Auto-assign public IP left off** — everything else correct, instance
  unreachable, no error anywhere.
- **SSH open to `0.0.0.0/0`** — automated login attempts within minutes.
- **"My IP" rule after the home address changes** — SSH stops working for no
  visible reason.
- **AMI baked with per-instance data in files** — fifty servers all claiming
  to be the same machine.
- **AMI deregistered without ticking "delete snapshots"** — storage bills
  forever for data nothing references.
- **Extra EBS volumes after terminating an instance** — `DeleteOnTermination`
  defaults to false for non-root volumes.
- **Instance store assumed to persist** — data is gone after a stop, not
  recoverable.
- **Diagnosing a timeout as an application problem** — it is the opposite.

## 7. Recall

See [`recall/week-1-questions.md`](../../recall/week-1-questions.md).

## 8. Carried forward

| Met today | Used on |
|---|---|
| AMIs and launch templates | day 9 — Auto Scaling launches from these |
| Why AMI speed matters | day 9 — 30 seconds versus 3 minutes |
| Security groups referencing other security groups | day 8 — ALB to instances |
| EBS types and IOPS | day 12 — storage in depth |
| Snapshots across regions | day 23 — disaster recovery |
| Spot and Savings Plans | day 22 — cost architecture |
| No TLS yet, hence "Not secure" | day 18 — ACM certificates |
