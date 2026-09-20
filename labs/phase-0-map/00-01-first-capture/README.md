# 00-01 · First capture

**Phase:** phase-0-map
**Time:** ~30 minutes
**Runs in:** WSL2 Ubuntu (not Git Bash)

## The question this answers

What actually crosses the wire when you fetch one HTTPS page — and how much
of it can you not yet explain?

This lab does not teach you the answers. It produces the evidence, and an
honest list of what you do not know. That list is the map the next four
months fill in.

## Prerequisites

- WSL2 Ubuntu.
- `tcpdump`, `curl`, `dig`, `ip`, `ss` — all already installed on this
  machine. `setup.sh` installs any that are missing.
- `sudo` is needed: capturing packets is a privileged operation, for
  reasons that will make sense after Phase L1. You will be asked for your
  WSL password.

## Steps

Open a WSL terminal (type `wsl` in your Windows terminal), then:

```bash
cd /mnt/c/Devops/labs/phase-0-map/00-01-first-capture
bash setup.sh
bash verify.sh
```

`setup.sh` starts `tcpdump`, resolves `example.com` against `1.1.1.1`,
fetches the page over HTTPS, and stops capturing. Everything lands in
`out/capture.pcap`.

`verify.sh` should print six `ok` lines and `PASS`.

## What to observe

Read the capture:

```bash
tcpdump -r out/capture.pcap -nn | head -40
```

Find these five things, in this order. Write down the line number of each:

1. **A DNS query and its response** (port 53). A name goes out, an address
   comes back.
2. **Three packets in a row** between your machine and that address: `SYN`,
   `SYN-ACK`, `ACK`. Nothing useful has been sent yet — this is setup.
3. **A burst of encrypted-looking traffic on port 443** immediately after.
   That is the TLS handshake. Note how many round trips it takes.
4. **The actual request and response**, indistinguishable from the
   handshake because it is encrypted.
5. **`FIN` or `RST`** at the end. The connection closing.

Now count: **how many round trips happened before a single byte of the web
page moved?** That number is why the rest of this curriculum exists.

## Build your map of ignorance

This is the real deliverable. For each item below, write one honest line:
*what you think it does*, and *what you cannot explain*.

- Why did DNS use UDP, and what happens if the response is too big?
- Why does TCP need three packets to start, rather than two?
- What is a sequence number, and why is the first one not zero?
- What does the `win` value in the tcpdump output mean?
- Why is TLS a separate handshake instead of part of TCP?
- What decided which network interface this traffic left from?
- What did your packet look like *before* the kernel put it on the wire?
- Why does the connection need closing at all?

Save it as `docs/phase-0-map/00-01-map-of-ignorance.md`. You will re-read it
at the capstone, and the difference will be the measure of what you learned.

## Now break it

Capture again, but block the DNS response:

```bash
bash teardown.sh
sudo iptables -I INPUT -p udp --sport 53 -j DROP
bash setup.sh          # this will hang, then fail
sudo iptables -D INPUT -p udp --sport 53 -j DROP
```

Observe: `curl` does not say "DNS is broken". It hangs, then reports it
could not resolve the host — and the capture shows the query going out
repeatedly with no answer. **Retry behaviour is the symptom; the cause is
silence.** That pattern recurs constantly in production, and recognising it
is most of what diagnosis is.

Make sure the second `iptables` line runs, or DNS stays broken in WSL.

## Clean up

```bash
bash teardown.sh
```
