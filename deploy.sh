#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")/deploy"
cd "$SCRIPT_DIR"

mkdir -p "$DEPLOY_DIR"

for dir in */; do
    dir="${dir%/}"
    [[ -f "$dir/info.json" ]] || continue
    rm -f "$DEPLOY_DIR/${dir}.zip"
    python3 -c "import shutil; shutil.make_archive('$DEPLOY_DIR/${dir}', 'zip', '.', '${dir}')"
    echo "Packed $DEPLOY_DIR/${dir}.zip"
done
