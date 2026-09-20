# 00-01 · Journey of a request

**Phase 0 · The Map**
Interactive page: [`site/phase-0.html`](../../site/phase-0.html)
Lab: [`labs/phase-0-map/00-01-first-capture/`](../../labs/phase-0-map/00-01-first-capture/)

**After this module you can explain:** what a packet is, what an IP address
and a port each identify, what a name lookup is and why it happens first,
and how to read a single line of `tcpdump` output.

**Assumes:** nothing.

---

## 1. The problem

Two computers want to exchange something. They are not connected by a wire
you own, and the thing being sent is too big to send in one go.

So it is cut into small chunks. Each chunk is a **packet**.

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
