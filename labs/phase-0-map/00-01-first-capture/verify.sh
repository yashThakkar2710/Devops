#!/usr/bin/env bash
# 00-01-first-capture - prove the capture contains a full request.
set -euo pipefail
cd "$(dirname "$0")"

PCAP="out/capture.pcap"
FAIL=0
check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then printf '  ok   %s\n' "$label"
  else printf '  FAIL %s\n' "$label"; FAIL=1; fi
}
count() { tcpdump -r "$PCAP" -nn "$1" 2>/dev/null | wc -l; }
atleast() { [ "$(count "$1")" -ge "$2" ]; }

if [ ! -s "$PCAP" ]; then
  echo "  FAIL $PCAP missing or empty - run: bash setup.sh"
  echo "FAIL"
  exit 1
fi

check "capture is readable"            tcpdump -r "$PCAP" -nn -c 1
check "contains DNS traffic"           atleast "port 53" 1
check "contains a TCP SYN"             atleast "tcp[tcpflags] & tcp-syn != 0" 1
check "contains a TCP SYN-ACK"         atleast "tcp[tcpflags] & (tcp-syn|tcp-ack) == (tcp-syn|tcp-ack)" 1
check "contains HTTPS traffic on 443"  atleast "tcp port 443" 1
check "contains a connection teardown" atleast "tcp[tcpflags] & (tcp-fin|tcp-rst) != 0" 1

echo
if [ "$FAIL" -eq 0 ]; then
  echo "PASS - capture contains DNS, a TCP handshake, TLS and a teardown."
  echo "Packets captured: $(count '')"
else
  echo "FAIL - see above. Re-run: bash teardown.sh && bash setup.sh"
fi
exit "$FAIL"
