#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")/deploy"
cd "$SCRIPT_DIR"

mkdir -p "$DEPLOY_DIR"
rm -f "$DEPLOY_DIR"/*.zip

for dir in */; do
    dir="${dir%/}"
    [[ -f "$dir/info.json" ]] || continue
    powershell.exe -NoProfile -Command "Compress-Archive -Force -Path '$(cygpath -w "$dir")' -DestinationPath '$(cygpath -w "$DEPLOY_DIR/${dir}.zip")'"
    echo "Packed $DEPLOY_DIR/${dir}.zip"
done
