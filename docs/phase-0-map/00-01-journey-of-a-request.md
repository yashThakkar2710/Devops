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

### 2.4 The name lookup

```
0 ms    Out   172.26.1.224.59573 > 1.1.1.1.53    A? example.com.
83 ms   In    1.1.1.1.53 > 172.26.1.224.59573    A 104.20.23.154
```

A name in, an address out. This is **DNS**. It has to happen before
anything else, because the rest of the machinery only understands numbers.

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
