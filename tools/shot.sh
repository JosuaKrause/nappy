#!/usr/bin/env bash
# Render the game to a PNG so the drawing can actually be checked.
#   tools/shot.sh out.png [seconds-to-wait] [dev flags...]
#
# Anything after the wait is passed straight through to the game, so the flags that exist for
# looking at things -- --seed, --day, --spawn, --follow, --meters, --walk -- work here too.
# They did not until M22, and the failure was silent: the extra arguments were simply dropped,
# and a screenshot taken to look at one specific event was of the doorstep instead.
#
#   tools/shot.sh out.png 8 --seed 4242 --spawn arterial --walk north
#
# Since M27 the game only really happens when the player is moving, so --walk is usually the
# difference between photographing the game and photographing a woman standing on a pavement.
set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:?usage: shot.sh out.png [seconds] [dev flags...]}"
SECONDS_TO_WAIT="${2:-1.5}"
shift $(( $# > 2 ? 2 : $# ))

# Relative paths would resolve against the project dir inside Godot, not the caller's cwd.
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac

"$GODOT" --path "$PROJECT_DIR" --resolution 1280x720 \
	-- --screenshot "$OUT" --after "$SECONDS_TO_WAIT" "$@"
echo "wrote $OUT"
