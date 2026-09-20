# Lab conventions

Every lab in this repo obeys this contract. Four months of labs stay
predictable only if none of them is a special case.

## The four files

| File | Contract |
|---|---|
| `README.md` | Objective, prerequisites, steps, **what to observe**, and the question the lab answers. |
| `setup.sh` | Builds the environment. Idempotent — safe to re-run. |
| `verify.sh` | Proves the lab worked. Exits 0 or 1. **Never asks you to eyeball output.** |
| `teardown.sh` | Removes everything `setup.sh` created. Safe to run twice, and safe to run after a failed setup. |

## Rules

1. **`set -euo pipefail` at the top of every script.** A lab that fails
   silently teaches the wrong lesson.
2. **Labs run in WSL2 or Docker, never against the Windows host network.**
   Creating interfaces or firewall rules on the host is out of bounds.
3. **`teardown.sh` is not optional.** Run it even when the lab worked.
   Leftover namespaces and bridges will confuse the next lab, and you will
   spend an hour debugging a mess you made yesterday.
4. **`verify.sh` is binary.** It answers "did this work", not "here is some
   output, you decide". You should never have to guess.
5. **Artifacts go in `out/`**, which is gitignored. Captures can be large.
6. **Breaking the lab is part of the lab.** Most READMEs end with a
   "now break it" section. Do that part — it is where the understanding is.

## Naming

`labs/<phase-slug>/<module-id>-<kebab-name>/`

For example: `labs/phase-1-link-layer/01-04-build-a-switch/`

## Creating one

```bash
bash tools/new-lab.sh phase-1-link-layer 01-04-build-a-switch
```

## Running one

```bash
cd labs/<phase-slug>/<lab-name>
bash setup.sh
bash verify.sh
bash teardown.sh
```

## If a lab leaves a mess

Network namespaces are the usual culprit. To see and remove strays, **in WSL**:

```bash
ip netns list
sudo ip netns delete <name>
ip -br link show | grep -E 'veth|br-'
```

Docker strays:

```bash
docker ps -a
docker network ls
```
