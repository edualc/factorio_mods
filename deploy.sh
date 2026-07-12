#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$SCRIPT_DIR/deploy"
cd "$SCRIPT_DIR"

mkdir -p "$DEPLOY_DIR"
rm -f "$DEPLOY_DIR"/*

# Python's zipfile.write() with an explicit forward-slash arcname is the one method
# confirmed (against the zip's raw bytes) to write correct '/' separators - both
# PowerShell's Compress-Archive and .NET's System.IO.Compression.ZipFile write
# backslash paths on Windows, which breaks non-Windows readers (a Linux dedicated
# server reports "info.json not found" inside an otherwise-valid archive).
if command -v python3 &>/dev/null; then
    # $1 = source dir, $2 = versioned name (e.g. CustomZomboid_2.0.7); the zip
    # filename and its internal top-level folder both use $2, not the source dir name.
    _pack() {
        python3 -c "
import os, sys, zipfile
src, name, dest = sys.argv[1], sys.argv[2], sys.argv[3]
with zipfile.ZipFile(dest, 'w', zipfile.ZIP_DEFLATED) as z:
    for root, _, files in os.walk(src):
        for f in files:
            full = os.path.join(root, f)
            rel = os.path.relpath(full, src).replace(os.sep, '/')
            z.write(full, arcname=name + '/' + rel)
" "$1" "$2" "$DEPLOY_DIR/${2}.zip"
    }
else
    _pack() {
        ln -sfn "$(realpath "$1")" "$2"
        zip -r "$DEPLOY_DIR/${2}.zip" "$2"
        rm "$2"
    }
fi

for dir in */; do
    dir="${dir%/}"
    [[ -f "$dir/info.json" ]] || continue
    name=$(python3 -c "import json; d=json.load(open('$dir/info.json')); print(d['name']+'_'+d['version'])")
    _pack "$dir" "$name"
    echo "Packed $DEPLOY_DIR/${name}.zip"
done
