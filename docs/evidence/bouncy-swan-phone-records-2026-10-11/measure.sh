#!/bin/bash
# Reruns the day-9 stall measurement: the phone's third day-9 attempt replayed on two revisions,
# timed headless, then the three attempts replayed under --invincible to compare every siting.
#
# usage: measure.sh <before-rev> <after-rev> <day-9-frame-record.json> [out-dir]
#
#   GODOT=/path/to/Godot  the engine (default: /Applications/Godot.app/Contents/MacOS/Godot)
#   RUNS=3                timed runs per side, alternating before and after
#
# Each revision is exported with `git archive` into a fresh scratch directory, given the replay
# (replay_patch.py) and the rig's log lines (instrument.py), baked and imported, and run with
# `--seed 67 --day 9 --no-title --no-save`. Nothing is written into the repository.
set -euo pipefail
if [[ $# -lt 3 || $1 == -h || $1 == --help ]]; then
    sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
    exit $([[ $# -lt 3 ]] && echo 2 || echo 0)
fi
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(git -C "$HERE" rev-parse --show-toplevel)
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
RUNS=${RUNS:-3}
RECORD=$(cd "$(dirname "$3")" && pwd)/$(basename "$3")
SCRATCH=$(mktemp -d)
OUT=${4:-$SCRATCH/out}
mkdir -p "$OUT"
echo "scratch: $SCRATCH  results: $OUT"

for side in before after; do
    rev=$1; [[ $side == after ]] && rev=$2
    mkdir -p "$SCRATCH/$side"
    git -C "$REPO" archive "$rev" | tar -x -C "$SCRATCH/$side"
    python3 -I "$HERE/replay_patch.py" "$SCRATCH/$side"
    if grep -q "static var judgements" "$SCRATCH/$side/src/events/event_scheduler.gd"; then
        python3 -I "$HERE/instrument.py" "$SCRATCH/$side" --judgements
    else
        python3 -I "$HERE/instrument.py" "$SCRATCH/$side"
    fi
    GODOT=$GODOT "$SCRATCH/$side/tools/bake-atlases.sh"
    "$GODOT" --headless --import --path "$SCRATCH/$side" >/dev/null 2>&1 || true
    echo "$side: $rev ($(git -C "$REPO" rev-parse "$rev"))" >> "$OUT/revisions.txt"
done

for attempt in 1 2 3; do
    python3 -I "$HERE/extract_track.py" "$RECORD" "$attempt" "$SCRATCH/track$attempt.txt"
done

run() {  # side track seconds log [extra flags]
    local side=$1 track=$2 limit=$3 log=$4; shift 4
    NAPPY_REPLAY=$SCRATCH/track$track.txt timeout "$limit" "$GODOT" --headless \
        --path "$SCRATCH/$side" -- --seed 67 --day 9 --no-title --no-save "$@" \
        > "$log" 2>&1 || true
}

# Timed: one at a time, alternating. The day is lost about 31s into the replay and the summary
# then waits for a key, so a run is cut off at 100s of wall time.
for i in $(seq 1 "$RUNS"); do
    for side in before after; do
        run "$side" 3 100 "$OUT/${side}$i.log"
    done
done
# Placements: --invincible, so the whole of each attempt is walked; not timed, so run together.
for track in 1 2 3; do
    for side in before after; do
        run "$side" "$track" 200 "$OUT/${side}_track$track.log" --invincible &
    done
done
wait

pairs=()
for i in $(seq 1 "$RUNS"); do pairs+=("$OUT/before$i.log" "$OUT/after$i.log"); done
for track in 1 2 3; do pairs+=("$OUT/before_track$track.log" "$OUT/after_track$track.log"); done
python3 -I "$HERE/analyse_stall.py" "${pairs[@]}" | tee "$OUT/analysis.txt"
