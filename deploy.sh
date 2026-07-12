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
    _pack() {
        local tmp
        tmp=$(mktemp -d)
        cp -r "$1" "$tmp/"
        # Compress-Archive stores entries with backslash path separators on Windows,
        # which violates the zip spec and breaks non-Windows readers (e.g. a Linux
        # dedicated server reports "info.json not found" inside an otherwise-valid
        # archive). System.IO.Compression.ZipFile always writes '/' separators.
        powershell.exe -NoProfile -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::CreateFromDirectory('$(_towin "$tmp")', '$(_towin "$DEPLOY_DIR/${1}.zip")')"
        rm -rf "$tmp"
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
