#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

for dir in */; do
    dir="${dir%/}"
    [[ -f "$dir/info.json" ]] || continue
    rm -f "${dir}.zip"
    python3 -c "import shutil; shutil.make_archive('${dir}', 'zip', '.', '${dir}')"
    echo "Packed ${dir}.zip"
done
