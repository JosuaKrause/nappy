#!/usr/bin/env bash
# Render the game to a PNG so the drawing can actually be checked.
#   tools/shot.sh out.png [seconds-to-wait]
set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:?usage: shot.sh out.png [seconds]}"
SECONDS_TO_WAIT="${2:-1.5}"

# Relative paths would resolve against the project dir inside Godot, not the caller's cwd.
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac

"$GODOT" --path "$PROJECT_DIR" --resolution 1280x720 -- --screenshot "$OUT" --after "$SECONDS_TO_WAIT"
echo "wrote $OUT"
