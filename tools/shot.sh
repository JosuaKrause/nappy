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

# A bare `--` right after the two positionals -- the end-of-options marker Godot's own command
# line uses and the form the docs quote -- is accepted and dropped: everything after it is a
# forwarded flag, so it is only legal at the front of the flags, and a `--` anywhere later is
# rejected like any other unknown word. Godot gets exactly one `--`, the script's own.
if [[ $# -gt 0 && "$1" == "--" ]]; then
    shift
fi

if [[ $# -gt 0 ]] && ! validate_dev_flags "$@"; then
    echo >&2
    usage >&2
    exit 1
fi

# shot.sh always takes a screenshot itself, so the trailing "--screenshot" here stands for the one
# this script adds below -- the literal word never appears in "$@", the caller's own forwarded flags.
if ! reject_route_with_screenshot "$@" --screenshot; then
    exit 1
fi

if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT" >&2
    echo "install Godot 4.7, or point GODOT at your binary:" >&2
    echo "  GODOT=/path/to/Godot tools/shot.sh" >&2
    exit 127
fi

# The baked atlas pages, in the same shape tools/run.sh checks its import cache in: a picture
# that has changed since the last bake leaves the pages standing for the tree before it, and a
# capture is the one thing that would then be photographing yesterday's artwork with nothing on
# screen to say so. `--check` compares the recorded source hashes without starting the engine,
# so the common path pays a fraction of a second and the rare one repairs before the window
# opens.
#
# **The repair is tools/check.sh rather than a bake on its own**, because a freshly baked page
# is a file the engine has not imported yet, and a windowed run does no import pass of its own —
# check.sh bakes, imports, and puts back the project.godot and docs/ARCHITECTURE.md rewrites the
# import pass causes, which a bare `--import` here would leave in the working tree.
if ! "$PROJECT_DIR/tools/bake-atlases.sh" --check >/dev/null 2>&1; then
    # `--check` exits non-zero by design; this reprint is the reason, not a failure.
    "$PROJECT_DIR/tools/bake-atlases.sh" --check >&2 || true
    echo "rebuilding with tools/check.sh -- this takes a few seconds" >&2
    if ! "$PROJECT_DIR/tools/check.sh" >/dev/null; then
        echo "tools/check.sh failed; run it directly to see why" >&2
        exit 1
    fi
    if ! "$PROJECT_DIR/tools/bake-atlases.sh" --check >/dev/null 2>&1; then
        # `--check` exits non-zero by design; this reprint is the reason, not a failure.
        "$PROJECT_DIR/tools/bake-atlases.sh" --check >&2 || true
        echo "the bake ran and the pages are still stale, so this is not a stale checkout" >&2
        exit 1
    fi
    echo "atlases rebuilt" >&2
fi

# Relative paths would resolve against the project dir inside Godot, not the caller's cwd.
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac

# M195: every shot.sh run is a rig by definition, so both halves of the lockdown apply
# unconditionally, no flag needed. `--disable-vsync` is Godot's own engine flag (before the `--`),
# not a game one: an unfocused or covered window throttles the whole main loop -- not only drawing
# -- to about once a second on this Mac, which is what let `--after` run for minutes without
# firing; disabling vsync keeps the loop running at its own pace regardless of focus or occlusion.
# See docs/DECISIONS.md, M195, "a rig's window takes no focus, hears no stray key, and always
# closes" for the reproduction this fixes.
#
# The external kill below is the outer half of the "always closes" guarantee -- the game's own
# wall-clock timer (`DevFlags.rig_quit_seconds()`, `main._process()`) is the inner half, and this
# is what fires if that one somehow does not.
KILL_AFTER="$(rig_kill_after_seconds --after "$SECONDS_TO_WAIT" "$@")"
rm -f "$OUT"
# An edit -- and a capture is one -- fails loudly: Godot exiting cleanly is not by itself proof the
# picture exists (`--route` racing its own quit against `--after` is one way it would not, before
# `reject_route_with_screenshot` above closed that specific combination off; a display fallen back
# to headless mid-run, per `AutoScreenshot.can_photograph()`, is another). Checked here rather than
# left to whoever opens $OUT next.
if rig_can_launch_in_background; then
    # M198: on macOS, launched through `open -g -n -W` instead of as this script's own direct
    # child -- see rig_run_backgrounded's own doc comment in lib_dev_flags.sh for the mechanism,
    # what it actually delivers (a delay before Godot activates, not the milestone's full "never")
    # and the measurement behind both. A stub $GODOT (tools/test_cli_help.sh's own tests) or a
    # non-macOS checkout falls to the direct launch below unchanged.
    if ! rig_run_backgrounded "$KILL_AFTER" \
            --path "$PROJECT_DIR" --resolution "$RESOLUTION" --disable-vsync \
            -- --screenshot "$OUT" --after "$SECONDS_TO_WAIT" "$@"; then
        echo "shot.sh: killed Godot after ${KILL_AFTER}s -- it did not quit on its own" >&2
        exit 1
    fi
    if [[ ! -f "$OUT" ]]; then
        echo "shot.sh: Godot exited but $OUT was never written -- no picture written" >&2
        exit 1
    fi
else
    "$GODOT" --path "$PROJECT_DIR" --resolution "$RESOLUTION" --disable-vsync \
        -- --screenshot "$OUT" --after "$SECONDS_TO_WAIT" "$@" &
    GODOT_PID=$!
    if ! wait_or_kill "$GODOT_PID" "$KILL_AFTER"; then
        echo "shot.sh: killed Godot after ${KILL_AFTER}s -- it did not quit on its own" >&2
        exit 1
    fi
    if [[ "$WAIT_OR_KILL_STATUS" -ne 0 ]]; then
        echo "shot.sh: Godot exited $WAIT_OR_KILL_STATUS -- no picture written" >&2
        exit "$WAIT_OR_KILL_STATUS"
    fi
    if [[ ! -f "$OUT" ]]; then
        echo "shot.sh: Godot exited 0 but $OUT was never written" >&2
        exit 1
    fi
fi
echo "wrote $OUT"
