#!/usr/bin/env bash
# Import assets, then boot the project headless and fail on any script error.
#
# A fresh clone has no .godot/ (it is gitignored), so the `class_name` registry does not
# exist yet and every typed reference fails to parse. The import pass builds it.
set -uo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT (override with GODOT=...)" >&2
    exit 127
fi

echo "== import =="
"$GODOT" --headless --import --path "$PROJECT_DIR" >/dev/null 2>&1

echo "== boot =="
output=$("$GODOT" --headless --quit-after 60 --path "$PROJECT_DIR" 2>&1)
echo "$output"

if grep -qE "SCRIPT ERROR|Parse Error|ERROR:" <<<"$output"; then
    echo
    echo "FAILED: errors during boot" >&2
    exit 1
fi

echo
echo "OK"
