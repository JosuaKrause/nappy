#!/usr/bin/env bash
# Record any rig run as a video, the same frame-locked movie-writer + ffmpeg piece tools/trailer.sh
# renders shots with.
#
#   tools/record.sh --route mark,task,calm,home --seed 4242
#   tools/record.sh --out my-run.mp4 -- --route mark,task,calm,home --seed 4242
#
# PLAYTEST-139, M214: "the automated walking rig -- can we add an option to record there, too? so
# I can create videos of those runs and review them" -- "for you a number is enough to judge them
# but I want to also be able to see some runs myself" -- "no videos should be checked in of
# course".
#
# Every dev flag after the script's own two (`--help`/`-h`, `--out`) is forwarded to the game
# exactly as tools/run.sh forwards them, validated against the game's own DEV_FLAG_TABLE first.
# `--player-view`, `--no-focus-pause` and `--no-save` are always added -- the release build's own
# view, the same M195 lockdown a movie-writer window always needs since it never has real focus to
# begin with (see tools/trailer.sh's own header for the frame this misses without it), and keeping
# the recording off the player's own save the same way every other dev flag already does. The rig
# quits itself (a `--route` run does this on arrival; anything else needs its own `--after` or
# `--day-length`), and this waits for that with the same outside kill tools/trailer.sh uses
# (`rig_kill_after_movie_seconds`) rather than a fixed timer of its own. Frames are deleted once
# the video is encoded; the video is never written anywhere git tracks.
set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$PROJECT_DIR/build/records"
# shellcheck source=tools/lib_dev_flags.sh
source "$PROJECT_DIR/tools/lib_dev_flags.sh"

usage() {
    cat <<EOF
usage: tools/record.sh [--help|-h] [--out NAME.mp4] [--] <dev flags for the game>

Records a rig run through Godot's movie writer, frame-locked, at the game's own resolution with
its audio, then encodes it with ffmpeg. Every flag after the ones listed above is forwarded to the
game, validated against its own dev-flag table first; --player-view, --no-focus-pause and --no-save
are always added for you, ahead of whatever you give. The rig has to quit on its own -- a --route
run does, on arrival; anything else needs its own --after or --day-length, or this waits for the
wall-clock kill tools/trailer.sh's own runs share. Output goes to build/records/ (gitignored);
frames are deleted once it is encoded.

  --out NAME.mp4   name the output file (default: a seed/timestamp-based name)

  tools/record.sh --route mark,task,calm,home --seed 4242
  tools/record.sh --out review.mp4 -- --route calm,home --seed 1 --day 6

Opens a window. Needs ffmpeg on PATH, and Godot 4.7 at \$GODOT.
EOF
}

OUT_NAME=""
GAME_FLAGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --out)
            [[ $# -ge 2 ]] || { echo "--out is missing its file name" >&2; echo >&2; usage >&2; exit 1; }
            OUT_NAME="$2"; shift 2 ;;
        --) shift; GAME_FLAGS+=("$@"); break ;;
        *) GAME_FLAGS+=("$1"); shift ;;
    esac
done

if [[ ${#GAME_FLAGS[@]} -eq 0 ]]; then
    echo "record.sh: no dev flags to record -- nothing to run" >&2
    echo >&2
    usage >&2
    exit 1
fi

# --player-view, --no-focus-pause and --no-save are always added, ahead of whatever the caller
# gave: --player-view is the release build's own view (a caller who still wants the debug readout
# in their own review video may pass --debug too, which --player-view does not turn off -- see
# DevFlags.player_view_requested()'s own doc, the readout stays behind its own flag);
# --no-focus-pause is the M195 lockdown a movie-writer window always needs; --no-save keeps a
# recording off the player's own save the same way every other dev flag already does, for a run
# that would otherwise carry none of its own (a bare --route).
FULL_FLAGS=(--player-view --no-focus-pause --no-save "${GAME_FLAGS[@]}")
if ! validate_dev_flags "${FULL_FLAGS[@]}"; then
    echo "record.sh: the game does not know one of those flags (see above)" >&2
    echo >&2
    usage >&2
    exit 1
fi

# Everything that follows does real work (an atlas rebuild, a Godot launch) -- checked only once
# the flags themselves are known good, so a typo is rejected before any of it runs.
if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT" >&2
    echo "install Godot 4.7, or point GODOT at your binary:" >&2
    echo "  GODOT=/path/to/Godot tools/record.sh ..." >&2
    exit 127
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "record.sh: ffmpeg not found on PATH" >&2
    exit 127
fi

if [[ -n "$OUT_NAME" ]]; then
    case "$OUT_NAME" in
        */*) echo "record.sh: --out takes a file name, not a path ($OUT_NAME)" >&2; exit 1 ;;
    esac
else
    OUT_NAME="record-$(date +%Y%m%d-%H%M%S).mp4"
fi
OUTPUT="$OUT_DIR/$OUT_NAME"

# The game's own resolution, read where the game declares it -- the same line tools/trailer.sh
# reads.
WIDTH="$(sed -n 's/^window\/size\/viewport_width=//p' "$PROJECT_DIR/project.godot")"
HEIGHT="$(sed -n 's/^window\/size\/viewport_height=//p' "$PROJECT_DIR/project.godot")"
if ! [[ "$WIDTH" =~ ^[0-9]+$ && "$HEIGHT" =~ ^[0-9]+$ ]]; then
    echo "record.sh: could not read the viewport size from project.godot" >&2
    exit 1
fi

# The baked atlas pages, repaired the way tools/shot.sh and tools/trailer.sh repair them.
if ! "$PROJECT_DIR/tools/bake-atlases.sh" --check >/dev/null 2>&1; then
    "$PROJECT_DIR/tools/bake-atlases.sh" --check >&2 || true
    echo "rebuilding with tools/check.sh -- this takes a few seconds" >&2
    if ! "$PROJECT_DIR/tools/check.sh" >/dev/null; then
        echo "tools/check.sh failed; run it directly to see why" >&2
        exit 1
    fi
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/nappy-record.XXXXXX")"
FOCUS_WATCHER_PID=""
cleanup() {
    rig_focus_watch_stop "$FOCUS_WATCHER_PID"
    rm -rf "$WORK"
}
trap cleanup EXIT

TREE_BEFORE="$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null || true)"

kill_after="$(rig_kill_after_movie_seconds "${FULL_FLAGS[@]}")"
echo "recording (rig's own wall-clock limit ${kill_after}s)..." >&2
noted="$(rig_focus_note)"
"$GODOT" --path "$PROJECT_DIR" --resolution "${WIDTH}x${HEIGHT}" --disable-vsync \
    --write-movie "$WORK/frame.png" --fixed-fps 60 \
    -- "${FULL_FLAGS[@]}" > "$WORK/godot.log" 2>&1 &
pid=$!
FOCUS_WATCHER_PID="$(rig_focus_watch_start "$pid" "$noted")"
if ! wait_or_kill "$pid" "$kill_after"; then
    rig_focus_watch_stop "$FOCUS_WATCHER_PID"; FOCUS_WATCHER_PID=""
    echo "record.sh: killed Godot after ${kill_after}s -- it did not quit on its own" >&2
    tail -20 "$WORK/godot.log" >&2
    exit 1
fi
rig_focus_watch_stop "$FOCUS_WATCHER_PID"; FOCUS_WATCHER_PID=""
if [[ "$WAIT_OR_KILL_STATUS" -ne 0 ]]; then
    echo "record.sh: Godot exited $WAIT_OR_KILL_STATUS" >&2
    tail -20 "$WORK/godot.log" >&2
    exit 1
fi
if grep -qE '^(SCRIPT )?ERROR' "$WORK/godot.log"; then
    echo "record.sh: the run printed an engine error while recording:" >&2
    grep -E -A2 '^(SCRIPT )?ERROR' "$WORK/godot.log" | head -20 >&2
    exit 1
fi
if [[ ! -f "$WORK/frame00000000.png" ]]; then
    echo "record.sh: no frames were written -- the rig quit before the first one saved" >&2
    exit 1
fi

mkdir -p "$OUT_DIR"
audio=(-f lavfi -i "anullsrc=r=48000:cl=stereo")
[[ -f "$WORK/frame.wav" ]] && audio=(-i "$WORK/frame.wav")
ffmpeg -hide_banner -loglevel error -y \
    -framerate 60 -i "$WORK/frame%08d.png" "${audio[@]}" \
    -shortest -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p \
    -c:a aac -b:a 192k -movflags +faststart "$OUTPUT"
# Frames are deleted here by the `cleanup` trap's `rm -rf "$WORK"` on exit -- not by name here,
# which used to be `rm -rf "$WORK/frame"*.png`: a route day can write over 12,000 frames (a full
# 210s day at 60fps), and a glob that long overflows the argument list, failing with "Argument
# list too long" right after the mp4 was written, under `set -e`.

status=0
after="$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null || true)"
if [[ "$after" != "$TREE_BEFORE" ]]; then
    echo "record.sh: the working tree's status changed while recording:" >&2
    diff <(printf '%s\n' "$TREE_BEFORE") <(printf '%s\n' "$after") >&2 || true
    status=1
fi
echo "wrote ${OUTPUT#"$PROJECT_DIR"/}" >&2
exit "$status"
