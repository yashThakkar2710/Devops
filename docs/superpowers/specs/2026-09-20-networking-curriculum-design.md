# Deep Networking and Linux Curriculum — Design Spec

**Date:** 2026-09-20
**Status:** Approved design, pending implementation plan
**Location:** `C:\Devops`

---

## 1. Goal

Build a complete, self-contained system for learning computer networking and Linux systems from first principles to production DevOps depth, such that the learner never needs to relearn the material.

The success criterion is **conceptual clarity, not coverage**. The learner must be able to *derive* answers from a causal model rather than recall facts. A module has succeeded when its mechanism can be explained to someone else without notes, including why it was designed that way and how it fails.

## 2. Learner profile

- Software developer, ~2 years experience.
- Working familiarity with AWS, HTTP, and socket APIs as a consumer of them.
- Predictable knowledge shape: strong on application-layer semantics and cloud-console operations; systematically weak on L2, how routing tables are populated, the Linux kernel datapath, and congestion control.
- Explicitly wants to start from scratch anyway, accepting redundancy in exchange for zero gaps.
- Target role: DevOps engineer with network-engineer-grade understanding.
- Study capacity: 3–4 hours/day, flexible schedule, no deadline.

## 3. Pedagogical approach

### 3.1 Sequencing: tracer bullet, then bottom-up, then close the loop

1. **Phase 0** — trace one real HTTP request end to end at surface level. Output is a labelled map of what the learner cannot yet explain.
2. **Phases 1–9** — rigorous bottom-up progression. Each phase fills in regions of that map.
3. **Capstone** — re-trace the identical request, explaining every byte, every layer, and every kernel hop.

Two Linux phases are interleaved rather than taught as one block, because Linux knowledge is needed at two distinct moments for two distinct reasons:

- **Phase L1** sits between Phase 0 and Phase 1. It supplies enough working knowledge to run labs without fighting the terminal. Critically it establishes file descriptors, without which `03-01` ("what a socket is in the kernel") has no foundation to stand on.
- **Phase L2** sits between Phase 5 and Phase 6. It supplies the systems depth that makes the kernel datapath comprehensible. Deferring it to this point means the material is applied within days rather than months, and cgroups/namespaces/overlayfs arrive immediately before the container phases they explain.

Teaching both blocks up front was rejected: L2 material decays without immediate application, and three months separate an up-front L2 from Phase 6.

Rejected alternatives:

- *Strict bottom-up with no tracer bullet* — rigorous but disorienting; ~78 hours of prerequisite material (Phases 1–3) before anything resembles the target job.
- *Pure spiral / "follow the packet" revisiting each layer 2–3 times* — keeps motivation high but requires accepting assertions on faith and returning later. Nothing is ever closed out, which harms retention.

Bottom-up is the only ordering in which each "why" has its prerequisite already established. The tracer bullet buys the spiral's motivation for the cost of a single session.

### 3.2 Module shape

Every module follows the same five parts, in order:

1. **The problem** — what breaks if this mechanism does not exist. Motivation precedes mechanism; a solution to an unfelt problem is not retained.
2. **The mechanism** — how it works, to byte level where byte level matters.
3. **The lab** — build it, then deliberately break it.
4. **Why is it like this** — the design trade-off or historical accident behind the current shape. This is the non-obvious material.
5. **Failure modes and recall questions** — production failure signatures, and questions that test derivation rather than recognition.

### 3.3 Retention

Knowledge is retained by active recall, not re-reading. Each phase has a question bank in `recall/`. Questions test derivation ("why would removing TIME_WAIT be unsafe?") rather than recognition ("what is TIME_WAIT?").

### 3.4 Teaching mode

Modules are taught **conversationally**. The markdown doc is the durable record; the understanding is built in back-and-forth dialogue with concrete examples and practical work. Theory is always grounded in something runnable. The learner may interrupt any module with "go deeper" and the session stops and digs.

## 4. Lab environment

Confirmed available on the machine:

| Tool | Version | Role |
|---|---|---|
| WSL2 Ubuntu | v2 | Real Linux kernel: netns, veth, bridges, nftables, tcpdump |
| Docker | 28.5.2 | Multi-node topologies, FRR routers, DNS servers, kind clusters |
| Python | 3.13.3 | Raw sockets, hand-built packets, serving the site |
| Node | 22.22.2 | Available, not required |
| Git | 2.49.0 | Optional version control of progress |

No simulator (GNS3/Packet Tracer) and no VM hypervisor are required. All topologies are built from real kernel primitives running real protocol implementations. This is a stronger lab than most certification tracks assume.

**Lab invariants:**

- Every lab has `setup.sh`, `verify.sh`, `teardown.sh`.
- `verify.sh` proves the lab worked; the learner never guesses.
- `teardown.sh` always fully cleans up. No lab leaves the system modified.
- Labs run inside WSL2 or Docker, never against the host network.

## 5. Curriculum

**83 modules, ~247 hours.** At 3–4 hrs/day this is 10–12 weeks of study time; **4 months is the realistic calendar estimate.**

Study order: `0 → L1 → 1 → 2 → 3 → 4 → 5 → L2 → 6 → 7 → 8 → 9`.

### Phase 0 — The Map (1 module, ~3h)

- `00-01` Journey of a request: lab setup, capture one HTTPS request end to end, name every layer, produce the map of ignorance.

### Phase L1 — Linux Working Knowledge (5 modules, ~13h)

Positioned after Phase 0, before Phase 1. Goal is competence at the terminal, not mastery. The learner is a developer and will move quickly here; skimming known material is expected and encouraged.

- `L1-01` Kernel vs userspace, syscalls, and `/proc` and `/sys` as interfaces
- `L1-02` Filesystem, paths, permissions, users, sudo
- `L1-03` Processes, signals, and **file descriptors** — "everything is a file"
- `L1-04` The shell for real: pipes, redirection, exit codes, job control
- `L1-05` Packages, systemd services, logs and journald

Key insight target: a socket is a file descriptor. Establishing this here converts `03-01` from a new concept into a familiar one pointed at the network.

### Phase 1 — Link Layer (7 modules, ~18h)

- `01-01` What a network is: links, nodes, addressing, and why layering
- `01-02` Bits to frames: encoding, clocking, framing, Ethernet anatomy, FCS
- `01-03` MAC addressing: structure, OUI, unicast/multicast/broadcast; why L2 addressing exists when L3 addressing also exists
- `01-04` Hubs to switches: collision vs broadcast domains, MAC learning, flooding, CAM tables
- `01-05` ARP: the L2/L3 glue, cache behaviour, gratuitous and proxy ARP, spoofing, and the absence of authentication
- `01-06` VLANs and 802.1Q: tagging, access vs trunk, native VLAN
- `01-07` STP: loops and broadcast storms, root election, port states, RSTP

Key insight targets: the 64-byte minimum frame as a disguised physics constant (slot time of a 2,500 m collision domain); why a switch needs no IP address.

**Labs:** build a switch from namespaces + Linux bridge; observe MAC table learning live; ARP-spoof yourself; VLAN trunk; induce a broadcast storm.

### Phase 2 — Network Layer (10 modules, ~28h)

- `02-01` Why L3 exists: scaling past a broadcast domain, hierarchical addressing
- `02-02` IPv4 addressing and binary fluency
- `02-03` Subnetting, CIDR, VLSM — drilled to automaticity
- `02-04` The IP header field by field: TTL, protocol, DSCP, flags
- `02-05` The routing decision: longest prefix match, the Linux FIB, connected vs gateway routes
- `02-06` How routing tables get populated: static, IGP (OSPF concepts), EGP (BGP concepts) — groundwork for Phase 8
- `02-07` MTU, fragmentation, PMTUD, and PMTUD black holes
- `02-08` ICMP and traceroute mechanics
- `02-09` NAT: SNAT/DNAT/masquerade, conntrack introduction, NAT traversal, hairpinning, CGNAT
- `02-10` IPv6: addressing, SLAAC, NDP, dual-stack operation

Key insight targets: routing is one rule (longest prefix wins) plus bookkeeping; PMTUD black holes as the most misdiagnosed cloud failure.

**Labs:** three-router namespace topology with static routes; subnetting drills; implement traceroute in Python with raw sockets; construct and then diagnose an MTU black hole from symptoms alone; NAT lab; IPv6 lab.

### Phase 3 — Transport Layer (10 modules, ~32h)

- `03-01` Ports, sockets, the 5-tuple; what a socket is inside the kernel
- `03-02` UDP: the minimal transport and when it is correct
- `03-03` Connection establishment: the 3-way handshake and why three, ISN randomness, SYN queue vs accept queue, `somaxconn`, SYN flood and cookies
- `03-04` Reliability: sequence numbers, cumulative ACK, SACK, RTO, fast retransmit
- `03-05` Flow control: sliding window, window scaling, zero window, silly window syndrome
- `03-06` Congestion control I: why it exists, slow start, AIMD, Reno
- `03-07` Congestion control II: CUBIC, BBR, bufferbloat, AQM and fq_codel
- `03-08` Teardown: FIN vs RST, the 11 states, TIME_WAIT, port exhaustion
- `03-09` Nagle, delayed ACK, TCP_NODELAY, and the 40 ms stall
- `03-10` TCP tuning and the latency budget: sysctls, where microseconds go

Key insight targets: TCP reliability as an illusion assembled purely at the endpoints; TIME_WAIT as load-bearing rather than a bug to be tuned away.

**Labs:** hand-build a handshake with raw sockets; inject loss/latency with `tc netem` and graph the congestion window sawtooth; overflow the listen backlog; reproduce ephemeral port exhaustion; reproduce the Nagle stall.

### Phase 4 — Names and Trust (8 modules, ~24h)

- `04-01` DNS: why names, the hierarchy, zones and delegation
- `04-02` The resolution walk: stub, recursive, root, TLD, authoritative; iterative vs recursive
- `04-03` Record types and zone files: SOA, NS, A/AAAA, CNAME, MX, TXT, SRV, PTR
- `04-04` Caching, TTL, negative caching; why a change did not propagate
- `04-05` DNS in production: split-horizon, anycast roots, EDNS, DNSSEC, DoH/DoT, failure modes
- `04-06` TLS: the problem, symmetric vs asymmetric, the 1.2 handshake
- `04-07` TLS 1.3, certificates and chain of trust, SNI, ALPN, resumption, 0-RTT
- `04-08` PKI in practice: run your own CA, mTLS, rotation, pinning, error triage

Key insight targets: DNS as a distributed cache with no invalidation; SNI transmitting the hostname in plaintext despite TLS.

**Labs:** run an authoritative server and a recursive resolver in Docker and resolve against them; `dig` deep dive; decode a TLS handshake byte by byte in Wireshark; build a CA and issue certificates; configure mTLS; deliberately break validation and read the errors until they are obvious.

### Phase 5 — Application Layer (5 modules, ~14h)

- `05-01` HTTP/1.1: anatomy, keep-alive, pipelining failure, head-of-line blocking
- `05-02` HTTP/2: framing, multiplexing, HPACK, and its own TCP-level HOL blocking
- `05-03` HTTP/3 and QUIC: why UDP, streams, connection migration, 0-RTT
- `05-04` WebSockets and gRPC
- `05-05` Proxies: forward vs reverse, CONNECT, X-Forwarded-For, PROXY protocol, TLS termination

Key insight target: HTTP/3 abandoning TCP is an admission that in-order delivery is the wrong abstraction for multiplexed streams, and that middlebox ossification made TCP itself unfixable.

### Phase L2 — Linux Systems Internals (8 modules, ~26h)

Positioned immediately before Phase 6, so the material is applied within days of being learned.

- `L2-01` Syscalls under the microscope: `strace`, the cost of the userspace/kernel transition
- `L2-02` Process internals: fork/exec, scheduling, process states
- `L2-03` Memory: virtual memory, page cache, the OOM killer, why `free` is misleading
- `L2-04` **cgroups**: what a resource limit actually is, and why a container was OOM-killed
- `L2-05` **Namespaces**, all eight types — the isolation half of containers
- `L2-06` Storage, filesystems, and **overlayfs** — how a container image actually works
- `L2-07` systemd in depth: units, dependency ordering, socket activation
- `L2-08` Performance methodology: the USE method, `vmstat`/`iostat`/`perf`, flamegraphs

Key insight target: `L2-04` + `L2-05` + `L2-06` constitute containers in full — limits, isolation, and images. By Phase 7, Docker should be a thing the learner could rebuild rather than a tool they invoke.

### Phase 6 — Linux Networking Internals (10 modules, ~30h)

**The highest-leverage phase in the curriculum.**

- `06-01` The kernel datapath: NIC, ring buffers, IRQ/softirq, NAPI, sk_buff, delivery to socket
- `06-02` iproute2 fluency: `ip link/addr/route/neigh/rule`
- `06-03` Netfilter architecture: the five hooks, tables, chains, traversal order
- `06-04` iptables in practice: filter/nat/mangle, rule anatomy, reading real rulesets written by other software
- `06-05` nftables
- `06-06` Conntrack in depth: states, table sizing, timeouts, the NAT dependency, exhaustion and mid-stream failure modes
- `06-07` Namespaces, veth, bridge, macvlan, ipvlan — the container primitives
- `06-08` Policy routing, multiple tables, VRF concepts
- `06-09` `tc` and qdiscs: shaping, policing, netem, fq_codel
- `06-10` eBPF and XDP: the modern datapath

Key insight target: containers, Kubernetes, service meshes and cloud VPCs are the same small set of kernel primitives arranged differently. Mastering this phase makes Phases 7 and 8 rearrangements rather than new material.

**Labs:** log a packet at every netfilter hook and observe traversal order; build container networking entirely by hand before ever invoking Docker; exhaust the conntrack table; policy routing; traffic shaping; a minimal XDP program.

### Phase 7 — Container and Kubernetes Networking (7 modules, ~22h)

- `07-01` Docker networking: bridge/host/none/macvlan and the iptables Docker writes
- `07-02` The Kubernetes network model: the flat pod network requirement and why
- `07-03` CNI: the specification, plugin invocation, flannel and VXLAN overlay
- `07-04` Calico (BGP-routed) vs Cilium (eBPF): trade-offs
- `07-05` Services and kube-proxy: ClusterIP as a DNAT rule, NodePort, LoadBalancer, iptables vs IPVS mode
- `07-06` CoreDNS, Ingress controllers, ExternalTrafficPolicy
- `07-07` NetworkPolicy and service mesh interception: sidecar iptables vs eBPF

Key insight target: a Service has no IP in any meaningful sense; ClusterIP is a DNAT rule and nothing listens at that address.

**Labs:** two-node `kind` cluster; dump and read kube-proxy's real iptables chains; trace one request pod-to-pod through every rewrite; enforce and verify a NetworkPolicy.

### Phase 8 — Cloud and Internet Scale (8 modules, ~22h)

Pitched at depth, not introduction, given existing AWS familiarity.

- `08-01` VPC internals: SDN, the mapping service, ENI as the real unit of networking, subnets and route tables
- `08-02` Gateways: IGW, NAT Gateway vs NAT instance (cost and throughput reality), egress-only, gateway vs interface endpoints and PrivateLink
- `08-03` Security groups (stateful, hypervisor-enforced) vs NACLs (stateless): why the asymmetry exists
- `08-04` Connecting VPCs and on-prem: peering, Transit Gateway, VPN, Direct Connect, overlapping CIDR pain
- `08-05` Load balancing: L4 vs L7, NLB/ALB internals, algorithms, health checks, connection draining, session affinity
- `08-06` DNS and traffic management at scale: routing policies, anycast, CDN and edge
- `08-07` BGP for real: AS numbers, eBGP/iBGP, path attributes, the path selection algorithm in order, peering vs transit
- `08-08` Internet failure modes: route leaks, hijacks, RPKI, outage case studies

**Labs:** run FRR routers in containers and establish real BGP peering, advertise prefixes, then leak a route and watch propagation; load balancer behaviour under failure; a VPC design exercise.

### Phase 9 — Observability and Capstone (4 modules, ~15h)

- `09-01` A troubleshooting methodology: layer bisection, hypothesis-driven diagnosis, avoiding the guess-and-check trap
- `09-02` tcpdump and Wireshark mastery; BPF filter syntax from the ground up
- `09-03` The toolbox: `ss`, `ip`, `nstat`, `conntrack`, `mtr`, `ethtool`
- `09-04` **Capstone**: a set of deliberately broken environments diagnosed from symptoms with no hints, then a full re-trace of the Phase 0 request explaining every byte.

## 6. Directory architecture

```
C:\Devops\
  README.md                   how to use the system
  PROGRESS.md                 master checklist of all modules
  docs/
    phase-0-map/00-01-journey-of-a-request.md
    phase-l1-linux-foundations/L1-01-....md
    phase-1-link-layer/01-01-....md
    ...
    phase-l2-linux-internals/L2-01-....md
    phase-6-linux-networking/06-01-....md
    ...
    superpowers/specs/        design specs (this file)
  labs/
    phase-1-link-layer/01-04-build-a-switch/
      README.md setup.sh verify.sh teardown.sh
  site/
    index.html                dashboard, progress, search
    assets/site.css site.js viz.js
    phase-1.html ... phase-9.html
  reference/
    glossary.md               every term, one line, link to its module
    cheatsheets/              tcpdump, iproute2, ss, iptables, dig, tc
    rfc-index.md              which RFCs are worth reading, and which sections
  recall/
    phase-N-questions.md      active recall bank
```

Numbered prefixes throughout so directory listings sort in study order.

**Decision: markdown is the source of truth; HTML is a companion, not a rendering of it.** Duplicating prose into the site would rot on first edit, and the two media are good at different jobs: prose explains *why*, an interactive diagram shows *how a thing moves*. The site carries only the second. The learner reads the doc in an editor, then opens the matching page to manipulate the mechanism.

## 7. The interactive site

Plain HTML, CSS, and hand-written SVG/JS. No framework, no CDN, no build step, no account. Works opened directly from disk via `file://` and when served with `python -m http.server`. Dark technical theme, left sidebar navigation, per-module progress stored in `localStorage`.

Constraint: no `fetch()` of local files, since `file://` blocks it. Any data a page needs is inlined. Shared CSS/JS via relative `<link>`/`<script>` is fine under `file://`.

Planned visualizations, one page per phase:

| Phase | Visualization |
|---|---|
| 0 | Encapsulation animator: headers wrap and unwrap layer by layer |
| 1 | Switch simulator with live MAC learning; STP convergence |
| 2 | Subnet explorer with live binary; longest-prefix-match router; fragmentation |
| 3 | Clickable 11-state TCP machine; handshake animator; congestion-window grapher; sliding window |
| 4 | DNS resolution tree walk; TLS 1.2 vs 1.3 side by side; certificate chain explorer |
| 5 | HTTP/1.1 vs /2 vs /3 waterfall showing head-of-line blocking |
| 6 | Netfilter hook traversal map; namespace/veth/bridge topology builder |
| 7 | Kubernetes packet tracer through every DNAT rewrite |
| 8 | VPC topology; BGP path-selection walker; load balancer algorithm simulator |
| 9 | Diagnostic decision tree: symptom in, next command out |

**Built incrementally, one phase at a time, when that phase begins** — not all nine up front. Each page then reflects what actually proved difficult.

## 8. Session workflow

1. Learner requests the next module, or names a specific one.
2. The module doc is written to `docs/`, and the module is taught conversationally with concrete examples.
3. Learner runs the lab in WSL; breakage is expected and is part of the lab.
4. Recall questions are added; `PROGRESS.md` is updated.
5. Approximately once per phase, that phase's interactive page is built.

"Go deeper" at any point suspends progression and digs into the current topic.

## 9. Conventions

- Module docs are named `NN-MM-kebab-title.md` matching their phase folder.
- Every doc opens with: what you will be able to explain after this, and what it assumes you already know.
- Every technical claim that could be checked is checkable: commands are runnable as written, and captures are reproducible.
- Numbers, RFC references, and protocol details are stated precisely or not at all. No approximations presented as facts.
- Cheatsheets contain only commands that appeared in a lab, so nothing is memorized without context.

## 10. Success criteria

The system has succeeded when the learner can:

1. Explain what happens between typing a URL and receiving a response, at every layer including the kernel path, without notes.
2. Diagnose an unfamiliar network failure by hypothesis and bisection rather than by pattern-matching to a remembered symptom.
3. Read an unfamiliar iptables ruleset or routing table and predict behaviour.
4. Derive, not recall, why a mechanism is designed the way it is.
5. Return to any topic months later via the docs and re-acquire it in minutes rather than relearning it.

## 10a. Relationship to the wider DevOps skill set

This curriculum is **Project 1 of an expected three**. On completion the learner will hold networking and Linux at a depth exceeding most working DevOps engineers, plus the networking slice of containers, Kubernetes and cloud.

Deliberately **not** covered here, and expected to form later projects (~3–4 further months):

| Area | State after this project |
|---|---|
| AWS breadth: IAM, EC2/ASG, S3, RDS, cost | Networking services only |
| Terraform / infrastructure as code | Not covered |
| CI/CD pipelines and deployment strategies | Not covered |
| Kubernetes operations: workloads, Helm, RBAC, storage, autoscaling | Networking only |
| Observability: Prometheus, Grafana, tracing, SLOs | Network tooling only |
| Secrets management and supply-chain security | TLS/PKI only |

The sequencing rationale: the remaining material is tool-shaped and largely rule-based, and is acquired far faster by someone who can already reason about packets, processes and namespaces. The foundational material is the slow part and is taken first deliberately.

Later projects are intentionally left undesigned. Requirements will be clearer from the far side of this one.

## 11. Out of scope

- Linux kernel development: writing kernel modules, reading kernel source, driver authoring. Linux *usage and internals* are in scope via Phases L1 and L2; modifying the kernel is not.
- Wireless (802.11) beyond a conceptual mention; not relevant to the target role.
- Physical layer detail below framing: modulation, line coding, optics.
- Telco/carrier material: MPLS, SDH, carrier Ethernet.
- Vendor CLI (Cisco IOS, JunOS) configuration syntax. Concepts are covered vendor-neutrally and practised on Linux/FRR.
- Certification exam preparation as an objective. Coverage substantially exceeds CCNA in the areas that matter for the target role and deliberately omits areas that do not.

**Confirmed decision (2026-09-20):** the learner explicitly chose skill over credential — no Cisco track, no CCNA preparation, not even the low-cost "how Cisco says it" annotations. Vendor syntax is a lookup, not a competency. This was a deliberate choice, not an oversight; revisit only if the target role changes to enterprise network operations.
