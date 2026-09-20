#!/usr/bin/env bash
# 00-01-first-capture - check tooling, then capture one HTTPS request.
# Idempotent: re-running replaces the capture.
set -euo pipefail
cd "$(dirname "$0")"

if ! grep -qi microsoft /proc/version 2>/dev/null; then
  echo "This lab must run inside WSL2, not Git Bash." >&2
  echo "Open a WSL shell and run it from there." >&2
  exit 1
fi

MISSING=()
for t in tcpdump curl dig ip ss; do
  command -v "$t" >/dev/null 2>&1 || MISSING+=("$t")
done

if [ "${#MISSING[@]}" -gt 0 ]; then
  echo "missing tools: ${MISSING[*]}"
  echo "installing..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq tcpdump curl dnsutils iproute2
fi

mkdir -p out
bash capture.sh
echo "setup complete - now run: bash verify.sh"
