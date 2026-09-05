#!/usr/bin/env bash
# Render the game to a PNG so the drawing can actually be checked.
#   RESOLUTION=WxH tools/shot.sh out.png [seconds-to-wait] [dev flags...]
#
# Anything after the wait is passed straight through to the game, so the flags that exist for
# looking at things -- --seed, --day, --spawn, --follow, --meters, --walk, --touch -- work here
# too. They did not until M22, and the failure was silent: the extra arguments were simply
# dropped, and a screenshot taken to look at one specific event was of the doorstep instead.
#
#   tools/shot.sh out.png 8 --seed 4242 --spawn arterial --walk north
#
# Since M27 the game only really happens when the player is moving, so --walk is usually the
# difference between photographing the game and photographing a woman standing on a pavement.
#
# RESOLUTION defaults to 1280x720, the landscape window every screen is authored against. The
# rotated presentation (see src/ui/screen_orientation.gd) only engages for a touch device in a
# portrait window, so looking at it needs both halves of that on purpose:
#   RESOLUTION=720x1280 tools/shot.sh out.png 4 --touch --walk 3s
set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESOLUTION="${RESOLUTION:-1280x720}"

if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT" >&2
    echo "install Godot 4.7, or point GODOT at your binary:" >&2
    echo "  GODOT=/path/to/Godot tools/shot.sh" >&2
    exit 127
fi

OUT="${1:?usage: shot.sh out.png [seconds] [dev flags...]}"
SECONDS_TO_WAIT="${2:-1.5}"
shift $(( $# > 2 ? 2 : $# ))

# Relative paths would resolve against the project dir inside Godot, not the caller's cwd.
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac

"$GODOT" --path "$PROJECT_DIR" --resolution "$RESOLUTION" \
	-- --screenshot "$OUT" --after "$SECONDS_TO_WAIT" "$@"
echo "wrote $OUT"
