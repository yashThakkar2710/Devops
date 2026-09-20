#!/usr/bin/env bash
# Serve site/ locally. Optional - index.html also works opened directly.
set -euo pipefail
cd "$(dirname "$0")/../site"

PORT="${1:-8080}"
echo "serving site/ at http://localhost:$PORT  (ctrl-c to stop)"
python -m http.server "$PORT" --bind 127.0.0.1
