#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$SCRIPT_DIR/deploy"
cd "$SCRIPT_DIR"

mkdir -p "$DEPLOY_DIR"
rm -f "$DEPLOY_DIR"/*

if command -v powershell.exe &>/dev/null; then
    # Convert Unix path to Windows path: cygpath for Git Bash, wslpath for WSL.
    _towin() {
        if command -v cygpath &>/dev/null; then cygpath -w "$1"
        elif command -v wslpath &>/dev/null; then wslpath -w "$1"
        else echo "$1"; fi
    }
    # $1 = source dir, $2 = output zip name (without .zip)
    _pack() { powershell.exe -NoProfile -Command "Compress-Archive -Force -Path '$(_towin "$1")' -DestinationPath '$(_towin "$DEPLOY_DIR/$2.zip")'"; }
else
    _pack() { zip -r "$DEPLOY_DIR/$2.zip" "$1"; }
fi

for dir in */; do
    dir="${dir%/}"
    [[ -f "$dir/info.json" ]] || continue
    name=$(python3 -c "import json; d=json.load(open('$dir/info.json')); print(d['name']+'_'+d['version'])")
    _pack "$dir" "$name"
    echo "Packed $DEPLOY_DIR/${name}.zip"
done
