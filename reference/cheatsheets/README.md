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
