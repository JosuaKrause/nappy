#!/usr/bin/env bash
# Boots the game natively COUNT times and keeps, per boot, the run log's `atlas page` lines, the
# boot's own `[Main] N atlas pages held ...` line and the load average before the launch.
#
#   run-native.sh OUT_DIR MODE SCENARIO COUNT       MODE: headless (the only one)
#                                                   SCENARIO: startup | escape
# Run it from a clean checkout of the revision under test, with the baked pages up to date
# (tools/check.sh bakes them). GODOT=/path/to/Godot overrides the engine. Never writes the save
# (--no-save). Output goes to OUT_DIR/<mode>-<scenario>-<n>.txt.
set -euo pipefail
if [[ $# -ne 4 || "$1" == "--help" || "$1" == "-h" ]]; then
    sed -n 2,9p "$0"; [[ $# -eq 4 ]] && exit 0 || exit 2
fi
out="$1"; mode="$2"; scenario="$3"; count="$4"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
project="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
case "$mode" in
    headless) engine_flags=(--headless) ;;
    *) echo "bad MODE $mode" >&2; exit 2 ;;
esac
case "$scenario" in
    startup) game_flags=(--seed 1) ;;
    escape) game_flags=(--seed 1 --start-escape) ;;
    *) echo "bad SCENARIO $scenario" >&2; exit 2 ;;
esac
mkdir -p "$out"
for n in $(seq 1 "$count"); do
    load=$(uptime | sed 's/.*load averages*: //')
    stdout=$("$GODOT" "${engine_flags[@]}" --path "$project" --quit-after 240 -- --no-save "${game_flags[@]}" 2>&1 || true)
    log=$(printf '%s\n' "$stdout" | sed -n 's/^\[Telemetry\] //p' | head -1)
    {
        echo "# $mode $scenario run $n, load average before launch: $load"
        printf '%s\n' "$stdout" | grep -F 'atlas pages held' || echo "# no boot line"
        grep -F "atlas page '" "$log" || echo "# no page lines"
    } > "$out/$mode-$scenario-$n.txt"
done
