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
# shellcheck source=tools/lib_dev_flags.sh
source "$PROJECT_DIR/tools/lib_dev_flags.sh"

usage() {
    cat <<EOF
usage: RESOLUTION=WxH tools/shot.sh [--help|-h] out.png [seconds-to-wait] [dev flags...]

Render the game to a PNG. RESOLUTION defaults to 1280x720. seconds-to-wait defaults to 1.5.
Anything after that is forwarded to the game as a dev flag -- gated behind a debug build -- so
--seed, --day, --spawn, --walk and the rest all work here too. See README.md's "Dev flags"
section for what each one means; the shapes below are read live out of src/dev/dev_flags.gd's
own DEV_FLAG_TABLE, so this list cannot go stale on its own.

  tools/shot.sh out.png 8 --seed 4242 --spawn arterial --walk north

flags:
$(dev_flag_usage_lines)
EOF
}

for arg in "$@"; do
    case "$arg" in
        --help|-h) usage; exit 0 ;;
    esac
done

if [[ $# -lt 1 ]]; then
    echo "usage: shot.sh out.png [seconds] [dev flags...]" >&2
    exit 1
fi

OUT="$1"
shift
# The seconds-to-wait positional is optional, so a caller who skips it and goes straight to dev
# flags (`shot.sh out.png --seed 4242`) must not have "--seed" swallowed into it.
SECONDS_TO_WAIT="1.5"
if [[ $# -gt 0 && "$1" != --* ]]; then
    SECONDS_TO_WAIT="$1"
    shift
    if ! [[ "$SECONDS_TO_WAIT" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        echo "seconds-to-wait must be a non-negative number, got '$SECONDS_TO_WAIT'" >&2
        echo >&2
        usage >&2
        exit 1
    fi
fi

if [[ $# -gt 0 ]] && ! validate_dev_flags "$@"; then
    echo >&2
    usage >&2
    exit 1
fi

if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT" >&2
    echo "install Godot 4.7, or point GODOT at your binary:" >&2
    echo "  GODOT=/path/to/Godot tools/shot.sh" >&2
    exit 127
fi

# Relative paths would resolve against the project dir inside Godot, not the caller's cwd.
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac

"$GODOT" --path "$PROJECT_DIR" --resolution "$RESOLUTION" \
	-- --screenshot "$OUT" --after "$SECONDS_TO_WAIT" "$@"
echo "wrote $OUT"
