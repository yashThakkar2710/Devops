#!/usr/bin/env bash
# {{LAB_NAME}} - remove everything setup.sh created.
# Safe to run twice, and safe after a failed setup.
set -euo pipefail
cd "$(dirname "$0")"

rm -rf out

echo "teardown complete"
