#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$SCRIPT_DIR/deploy"
cd "$SCRIPT_DIR"

mkdir -p "$DEPLOY_DIR"
rm -f "$DEPLOY_DIR"/*

# Convert Unix path to Windows path: cygpath for Git Bash, wslpath for WSL.
_towin() {
    if command -v cygpath &>/dev/null; then cygpath -w "$1"
    elif command -v wslpath &>/dev/null; then wslpath -w "$1"
    else echo "$1"; fi
}

# $1 = source dir, $2 = versioned name (e.g. CustomZomboid_2.0.5)
# The internal folder inside the zip must be named $2, not $1.
_pack() {
    local src="$1" name="$2"
    if command -v powershell.exe &>/dev/null; then
        local tmp
        tmp=$(mktemp -d)
        cp -r "$src" "$tmp/$name"
        powershell.exe -NoProfile -Command "Compress-Archive -Force -Path '$(_towin "$tmp/$name")' -DestinationPath '$(_towin "$DEPLOY_DIR/$name.zip")'"
        rm -rf "$tmp"
    else
        ln -sfn "$(realpath "$src")" "$name"
        zip -r "$DEPLOY_DIR/$name.zip" "$name"
        rm "$name"
    fi
}

for dir in */; do
    dir="${dir%/}"
    [[ -f "$dir/info.json" ]] || continue
    name=$(python3 -c "import json; d=json.load(open('$dir/info.json')); print(d['name']+'_'+d['version'])")
    _pack "$dir" "$name"
    echo "Packed $DEPLOY_DIR/${name}.zip"
done
