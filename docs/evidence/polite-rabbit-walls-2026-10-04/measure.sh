#!/usr/bin/env bash
# Interleaved before/after timing of excitement through walls, on two clean checkouts.
#
#   measure.sh --before DIR --after DIR --output DIR [--godot PATH] [--pairs N]
#
# For each pair, in alternating order: a headless frame-record run of seed 4242 on days 1 and 9,
# walking 3s8e4s8w and quitting 25s in (its record summarised by analyse.py beside this script),
# then tests/probes/m159_contribution_cost.gd, the crowd's own source sweep. Each checkout is
# imported with its own tools/check.sh first. --output must not exist yet.
set -euo pipefail

usage() {
    sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
}

before="" after="" output="" pairs=3
godot="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --before) before="${2:?--before needs a directory}"; shift 2 ;;
        --after) after="${2:?--after needs a directory}"; shift 2 ;;
        --output) output="${2:?--output needs a directory}"; shift 2 ;;
        --godot) godot="${2:?--godot needs a path}"; shift 2 ;;
        --pairs) pairs="${2:?--pairs needs a number}"; shift 2 ;;
        *) usage >&2; exit 2 ;;
    esac
done
if [ -z "$before" ] || [ -z "$after" ] || [ -z "$output" ]; then
    usage >&2
    exit 2
fi
if [ -e "$output" ]; then
    echo "measure.sh: $output already exists" >&2
    exit 2
fi
here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$output"
output="$(cd "$output" && pwd)"

for side in before after; do
    dir="$before"
    [ "$side" = after ] && dir="$after"
    (cd "$dir" && GODOT="$godot" ./tools/check.sh > "$output/$side-check.log" 2>&1)
    git -C "$dir" rev-parse HEAD > "$output/$side-revision.txt"
done

frame_record() {
    local side=$1 day=$2 pair=$3 dir
    dir="$before"
    [ "$side" = after ] && dir="$after"
    local log="$output/$side-day$day-$pair.log"
    "$godot" --headless --path "$dir" -- --seed 4242 --day "$day" --no-title --no-save \
        --frame-record --walk 3s8e4s8w --after 25 > "$log" 2>&1
    local record
    record="$(sed -n 's/^Frame record: //p' "$log")"
    cp "$record" "$output/$side-day$day-$pair.json"
    python3 "$here/analyse.py" "$output/$side-day$day-$pair.json"
}

crowd_sweep() {
    local side=$1 pair=$2 dir
    dir="$before"
    [ "$side" = after ] && dir="$after"
    (cd "$dir" && GODOT="$godot" ./tools/test.sh probes/m159_contribution_cost.gd \
        > "$output/$side-m159-$pair.log" 2>&1)
    python3 - "$output/$side-m159-$pair.log" "$side" "$pair" <<'PY'
import json, statistics, sys
path, side, pair = sys.argv[1:]
line = next(l for l in open(path) if l.startswith("CROWD_COST_JSON "))
data = json.loads(line[len("CROWD_COST_JSON "):])
medians = {}
for run in data["runs"]:
    medians.setdefault(run["day"], []).append(statistics.median(s[1] for s in run["samples"]))
print(json.dumps({"crowd_sweep": side, "pair": int(pair),
                  "median_usec_by_day": medians,
                  "mismatches": sum(r["mismatches"] for r in data["runs"])}))
PY
}

for pair in $(seq 1 "$pairs"); do
    order="before after"
    [ $((pair % 2)) -eq 0 ] && order="after before"
    for side in $order; do
        frame_record "$side" 1 "$pair"
        frame_record "$side" 9 "$pair"
        crowd_sweep "$side" "$pair"
    done
done
