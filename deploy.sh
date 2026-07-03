#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$SCRIPT_DIR/deploy"
cd "$SCRIPT_DIR"

mkdir -p "$DEPLOY_DIR"
rm -f "$DEPLOY_DIR"/*.zip

if command -v powershell.exe &>/dev/null; then
    _pack() { powershell.exe -NoProfile -Command "Compress-Archive -Force -Path '$(wslpath -w "$1")' -DestinationPath '$(wslpath -w "$DEPLOY_DIR/${1}.zip")'"; }
else
    _pack() { zip -r "$DEPLOY_DIR/${1}.zip" "$1"; }
fi

for dir in */; do
    dir="${dir%/}"
    [[ -f "$dir/info.json" ]] || continue
    _pack "$dir"
    echo "Packed $DEPLOY_DIR/${dir}.zip"
done
