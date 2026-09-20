#!/usr/bin/env bash
# Capture one full HTTPS request: DNS lookup, TCP handshake, TLS, teardown.
set -euo pipefail
cd "$(dirname "$0")"

TARGET="${1:-example.com}"
PCAP="out/capture.pcap"

echo "capturing traffic for https://$TARGET"

# 'any' catches loopback too, in case the resolver is local.
sudo tcpdump -i any -nn -s 0 -w "$PCAP" \
  "port 53 or port 443" >/dev/null 2>&1 &
TCPDUMP_PID=$!

cleanup() { sudo kill "$TCPDUMP_PID" 2>/dev/null || true; wait "$TCPDUMP_PID" 2>/dev/null || true; }
trap cleanup EXIT

sleep 1  # let tcpdump attach before traffic starts

# Query an external resolver directly so DNS is always on the wire and
# never served from a local cache. Caching is discussed in the module.
dig +short "$TARGET" @1.1.1.1 >/dev/null || true

curl -s -o /dev/null "https://$TARGET" || true

sleep 1  # let the teardown packets land

cleanup
trap - EXIT
sudo chown "$(id -u):$(id -g)" "$PCAP"

echo "wrote $PCAP ($(du -h "$PCAP" | cut -f1))"
