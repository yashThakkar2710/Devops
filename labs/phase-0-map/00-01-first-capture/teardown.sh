#!/usr/bin/env bash
# 00-01-first-capture - remove the capture. Safe to run twice.
set -euo pipefail
cd "$(dirname "$0")"

rm -rf out
echo "teardown complete"
