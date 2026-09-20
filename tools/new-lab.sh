#!/usr/bin/env bash
# Scaffold a new lab from labs/_template.
# Usage: bash tools/new-lab.sh <phase-slug> <lab-name>
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "$#" -ne 2 ]; then
  echo "usage: bash tools/new-lab.sh <phase-slug> <lab-name>" >&2
  echo "example: bash tools/new-lab.sh phase-1-link-layer 01-04-build-a-switch" >&2
  exit 2
fi

PHASE_SLUG="$1"
LAB_NAME="$2"
DEST="labs/$PHASE_SLUG/$LAB_NAME"

if [ ! -d "labs/$PHASE_SLUG" ]; then
  echo "no such phase: labs/$PHASE_SLUG" >&2
  echo "phases:" >&2
  find labs -mindepth 1 -maxdepth 1 -type d -name 'phase-*' -printf '  %f\n' >&2
  exit 1
fi

if [ -e "$DEST" ]; then
  echo "already exists: $DEST" >&2
  exit 1
fi

cp -r labs/_template "$DEST"
for f in "$DEST"/*; do
  sed -i "s|{{LAB_NAME}}|$LAB_NAME|g; s|{{PHASE_SLUG}}|$PHASE_SLUG|g" "$f"
done

echo "created $DEST"
ls -1 "$DEST" | sed 's/^/  /'
