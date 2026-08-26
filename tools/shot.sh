#!/usr/bin/env bash
# Render the game to a PNG so the drawing can actually be checked.
#   tools/shot.sh out.png [frames-to-wait]
set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:?usage: shot.sh out.png [frames]}"
FRAMES="${2:-60}"

# Relative paths would resolve against the project dir inside Godot, not the caller's cwd.
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac

"$GODOT" --path "$PROJECT_DIR" --resolution 1280x720 -- --screenshot "$OUT" --after "$FRAMES"
echo "wrote $OUT"
