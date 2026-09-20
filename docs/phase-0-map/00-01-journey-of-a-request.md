# 00-01 · Journey of a request

**Phase 0 · The Map**
Interactive page: [`site/phase-0.html`](../../site/phase-0.html)
Lab: [`labs/phase-0-map/00-01-first-capture/`](../../labs/phase-0-map/00-01-first-capture/)

**After this module you can explain:** what a packet is, what an IP address
and a port each identify, what a name lookup is and why it happens first,
and how to read a single line of `tcpdump` output.

**Assumes:** nothing.

---

## 0. What a network is

**A network is two or more computers that can send each other messages.**
That is the entire definition. Everything that follows in this curriculum is
detail about making that happen reliably, quickly and securely.

You need one because the thing you want is on a different computer than the
one in front of you.

### They are not plugged into each other

Your laptop is not wired to a server in another country. The message travels
in short jumps:

```
your laptop → home router → your ISP → ~10 more hops → the server
172.26.1.224                                           104.20.23.154
```

**No machine in that chain knows the whole route.** Each one knows only
where to pass the message next — like asking directions at every corner
rather than memorising the map. That single property is what allows the
internet to scale and to survive parts of itself breaking.

### What physically travels

Electricity down copper, light down glass fibre, radio through air. All
three carry the same thing: **ones and zeros**. On or off, repeated very
fast. Everything above that layer is agreements about what particular
patterns mean.

### Why it is cut into pieces

A message is not sent in one go. It is cut into chunks called **packets**,
for three reasons:

1. **The line is shared.** If one person sent a 2 GB file as an unbroken
   stream, everyone else would wait for it to finish.
2. **Losing a little beats losing a lot.** Packets do get dropped. Resending
   one small chunk is cheap; resending a whole film is not.
3. **Pieces can take different routes.** If a path congests or breaks, later
   packets go another way with nothing restarted.

### What "the internet" is

Many separate networks — a home, an office, a university, a hosting company
— that have agreed to pass each other's packets. There is no central
computer running it. It is an agreement, kept independently by millions of
machines.

## 1. The problem

Packets travel through machines that have never heard of you and keep no
memory of the conversation.

Every packet has to carry its own addressing, because nothing in between
remembers the conversation. A packet arrives at a machine that has never
heard of you and must still be able to work out what to do with it. That
requirement — no memory in the middle — shapes almost every design decision
in the rest of this curriculum.

## 2. The mechanism

### 2.1 A packet has two parts

```
┌──────────────────────────────┐
│  FROM: 172.26.1.224          │   header — the addressing
│  TO:   104.20.23.154         │
├──────────────────────────────┤
│  the actual content          │   payload
└──────────────────────────────┘
```

### 2.2 Address and port

Each end of a conversation is written as two numbers joined by a dot:

```
172.26.1.224 . 59573
└─────┬────┘   └─┬─┘
   address      port
```

- **IP address** — which machine.
- **Port** — which program inside that machine.

One machine runs many programs. The port is how an arriving packet is
routed to the right one.

Some port numbers are fixed by worldwide agreement:

| Port | Meaning |
|---|---|
| 53 | name lookups (DNS) |
| 80 | plain web |
| 443 | encrypted web |

These are conventions, not settings. That is precisely why they work: a
server you have never contacted knows what kind of request arrived, purely
from the number.

A client's own port is chosen at random just before sending, and discarded
afterwards. Its only job is to match an incoming answer to the question
that is waiting for it.

### 2.3 Reading one line of tcpdump

```
12:44:53.223421 eth0 Out IP 172.26.1.224.59573 > 1.1.1.1.53: A? example.com.
└──────┬──────┘ └─┬┘ └┬┘    └─────┬──────┘└─┬─┘  └──┬──┘└┬┘  └──────┬─────┘
     when      iface  dir        from      port    to   port     payload
```

In plain words: at 12:44:53, this machine sent a packet out through `eth0`
to `1.1.1.1` port 53, asking for the address of `example.com`.

The reply is the same line with the ends swapped and `Out` replaced by
`In`. That reversal is the entire matching mechanism.

### 2.4 Interfaces: the doors out of a machine

An **interface** is a way out of a computer. `ip -br addr show`:

```
lo      UNKNOWN   127.0.0.1/8  10.255.255.254/32  ::1/128
eth0    UP        172.26.1.224/20  fe80::215:5dff:feee:ae93/64
```

- **`eth0`** — the real door. Packets through it leave the machine.
- **`lo`** — loopback. Packets through it never leave. This is what
  `localhost` has always been.

Loopback exists so programs on one machine can talk to each other without
inventing a second mechanism. Same addressing, same ports, same rules, no
cable.

Two ways to spot loopback in a capture: the interface name is the second
item on the line, and on a loopback line **both addresses are identical**.

### 2.5 A machine has several addresses, all correct at once

| Address | On | Visible to |
|---|---|---|
| `127.0.0.1` | lo | programs on this machine |
| `10.255.255.254` | lo | WSL's DNS helper only |
| `172.26.1.224` | eth0 | the local network |
| `172.26.0.1` | the router | the way out |
| (public address) | the ISP | the entire internet |

Find the public one with `curl -s ifconfig.me`. It belongs to the router,
and everything in the building shares it. Phase 2 covers why (NAT).

**The slash number** says how large the neighbourhood is:

| Written | Addresses |
|---|---|
| `/32` | 1 |
| `/24` | 256 |
| `/20` | 4,096 |
| `/8` | 16,777,216 |

Bigger number, smaller neighbourhood. Fully covered in Phase 2.

### 2.6 The routing decision

Before sending, the machine asks one question: **is this address in my
neighbourhood?** `ip route get` shows the answer without sending anything.

```
$ ip route get 172.26.1.99
172.26.1.99 dev eth0 src 172.26.1.224          ← no "via": direct

$ ip route get 8.8.8.8
8.8.8.8 via 172.26.0.1 dev eth0                ← "via": hand to the router

$ ip route get 127.0.0.1
local 127.0.0.1 dev lo                         ← never leaves
```

The whole rulebook is two lines:

```
$ ip route show
default       via 172.26.0.1 dev eth0
172.26.0.0/20               dev eth0
```

```
Is it inside 172.26.0.0/20?   yes → straight out eth0
                              no  → "default" → give to 172.26.0.1
```

`default` catches every address the machine does not recognise — billions
of them, in one line. This is the "nobody knows the whole route" property
made concrete: the machine has no idea where `8.8.8.8` is, only that it is
not local.

### 2.7 The name lookup

```
0 ms    Out   172.26.1.224.59573 > 1.1.1.1.53    A? example.com.
83 ms   In    1.1.1.1.53 > 172.26.1.224.59573    A 104.20.23.154
```

A name in, an address out. This is **DNS**. It has to happen before
anything else, because the rest of the machinery only understands numbers.

### 2.8 Lines 3–6: two questions, and why they need IDs

The capture contains a *second* lookup, on loopback:

```
3  .333082  lo  10.255.255.254.42162 > …53   47200+  A?    example.com.
4  .333109  lo  10.255.255.254.42162 > …53   38510+  AAAA? example.com.
5  .366140  lo  …53 > 10.255.255.254.42162   38510   AAAA  2606:4700:9a65:…
6  .370801  lo  …53 > 10.255.255.254.42162   47200   A     104.20.23.154, 172.66.147.243
```

Lines 1–2 were `dig` (a tool that only asks name questions, run by the lab
to guarantee a visible lookup). Lines 3–6 are `curl` asking for itself.
**Programs do not share name answers with each other.**

**Two address families.** `A?` asks for an IPv4 address; `AAAA?` asks for
IPv6. IPv4's roughly 4.3 billion addresses ran out; IPv6 is the
replacement. The transition has taken twenty-five years and is unfinished,
so programs ask for both. The two questions went out 27 *microseconds*
apart — asking sequentially would have doubled the delay.

**The answers came back in the wrong order.** Question `47200` (A) was
asked first and answered second. And both questions used the **same source
port**, `42162`, so the two replies are indistinguishable from the outside.
The only thing pairing them is the **transaction ID** copied from question
to answer.

This is the observed justification for a mechanism usually taught as a bare
fact. There is a second, security reason for the ID being random — Phase 4.

**Two answers for one name.** `2/0/0` means two answer records:
`104.20.23.154` and `172.66.147.243`. Either works; packet 7 used the
first.

**The IPv6 answer was ignored.** There is no IPv6 default route out of WSL,
and `curl -6` fails while `curl -4` succeeds. The `fe80::` address on
`eth0` is link-local and cannot leave. The silent fallback to IPv4 is
called **Happy Eyeballs**, and it is why an unfinished IPv6 transition has
not broken the web.

## 3. The lab

`labs/phase-0-map/00-01-first-capture/` records one real HTTPS request and
saves it as `out/capture.pcap`.

```bash
cd /mnt/c/Devops/labs/phase-0-map/00-01-first-capture
bash setup.sh
bash verify.sh
tcpdump -r out/capture.pcap -nn | cat -n
```

Result on this machine: 33 packets in 299 ms.

## 4. Why is it like this

**Why separate the address from the port at all?** Because the two
questions are answered by different parties. Getting the packet to the
right machine is the network's job, and it happens hop by hop with no
knowledge of what is inside. Getting it to the right program is the
destination kernel's job, and only it knows what is running. Splitting the
identifier splits the responsibility, and lets every router in between stay
ignorant of applications entirely.

**Why is the name lookup a separate step rather than built into the
connection?** Because names and addresses change on completely different
schedules and are owned by different people. Keeping them separate is what
lets a site move to a new address without anything that refers to it by
name having to change.

**Why are ports like 53 and 443 fixed worldwide?** Because there is no
prior conversation in which to negotiate them. The first packet must
already be addressed correctly. A fixed number is the only thing that works
when neither side has spoken yet.

## 5. Failure modes

- **Name lookup fails** — nothing else can start. The symptom is a hang
  followed by "could not resolve host", not an error naming DNS. The
  capture shows the question going out repeatedly with no answer. Silence
  is the signature, and it is the most common shape of network failure.
- **Right machine, wrong port** — the packet arrives and is rejected, or
  simply ignored. Reachability and usefulness are different questions.

## 6. Recall

See [`recall/phase-0-questions.md`](../../recall/phase-0-questions.md).

## 7. Carried forward

Observations from the capture that this module does not yet explain:

| Seen in the capture | Answered in |
|---|---|
| `Flags [S]` — three packets before any content | Phase 3 |
| `seq 639031898` — counting starts at a random number | Phase 3 |
| `win 64240` shrinking to `502` | Phase 3 |
| `mss 1460` out vs `mss 1282` in — a disagreement | Phase 2 |
| `sack {684:743}` — packets arriving out of order | Phase 3 |
| 3,991 bytes of identity proof vs 1,332 bytes of page | Phase 4 |
| `AAAA?` asked and answered, then ignored | Phase 2 |
