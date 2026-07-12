#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$SCRIPT_DIR/deploy"
cd "$SCRIPT_DIR"

mkdir -p "$DEPLOY_DIR"
rm -f "$DEPLOY_DIR"/*

# On Windows, both PowerShell's Compress-Archive AND .NET's
# System.IO.Compression.ZipFile write entries with backslash path separators (verified
# against the zip's raw bytes, not a reader that may silently normalise on display) -
# that violates the zip spec and breaks non-Windows readers (e.g. a Linux dedicated
# server reports "info.json not found" inside an otherwise-valid archive). Python's
# zipfile.write() with an explicit forward-slash arcname is the one method confirmed
# to write correct bytes, so it's used whenever python3 is available.
if command -v python3 &>/dev/null; then
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
" "$1" "$1" "$DEPLOY_DIR/${1}.zip"
    }
else
    _pack() { zip -r "$DEPLOY_DIR/${1}.zip" "$1"; }
fi

for dir in */; do
    dir="${dir%/}"
    [[ -f "$dir/info.json" ]] || continue
    _pack "$dir"
    echo "Packed $DEPLOY_DIR/${dir}.zip"
done
