#!/usr/bin/env bash
# Aggregate the run logs. The consumer for playtest 17, finding 3: "otherwise it looks like a
# lot of plays happened when they were just regular tests. this skew statistics and muddies
# inferences we can do".
#
#   tools/stats.sh          # playtest runs only (run-*/ folders)
#   tools/stats.sh --rigs   # rig runs only (rig-*/ folders) -- check.sh, shot.sh, --walk/--flee/--press
#   tools/stats.sh --all    # both, printed as two groups
#
# The folder is mostly three-second rig runs (check.sh and shot.sh boot the game too), so
# counting everything by default is exactly the skew the player named. `run-` vs `rig-` is the
# game's own naming: see main.gd's _somebody_is_playing() and Telemetry.begin_run()'s `played`
# argument, documented in docs/TELEMETRY.md under "Where the logs are".
#
# Each run is a folder, `<day>/<minute>/<run>/`, with the log at `<run>/run.log` -- see
# Telemetry.begin_run() and docs/TELEMETRY.md. This script only ever reads that one file per run.
#
# Prints only what a log entry actually carries -- see docs/TELEMETRY.md's entry-kind table.
# A "day" is one `home` or `lost` line; a "run" is one run folder, and one sitting can hold
# several days if the process was never restarted, so the two counts are not the same thing.
set -uo pipefail

case "$(uname -s)" in
    Darwin) DIR="$HOME/Library/Application Support/Godot/app_userdata/Nappy/telemetry" ;;
    *)      DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/app_userdata/Nappy/telemetry" ;;
esac

if [[ ! -d "$DIR" ]]; then
    echo "no telemetry yet: $DIR" >&2
    echo "play a run with tools/run.sh — it is on unless you pass --no-telemetry" >&2
    exit 1
fi

mode="playtest"
case "${1:-}" in
    --rigs) mode="rigs" ;;
    --all)  mode="all" ;;
    "")     ;;
    *)      echo "usage: stats.sh [--rigs|--all]" >&2; exit 1 ;;
esac

# One group's worth of logs: run count, days won/lost, loss causes, most-met events. Each figure
# is a straight count of a `kind` column in docs/TELEMETRY.md's table -- `home`, `lost` and
# `near` -- never a rate or an average, so nothing here is a number a log entry does not carry
# on its own.
print_group() {
	local label="$1" prefix="$2"
	# Every run folder's log, wherever its `<day>/<minute>/` ancestors are -- `-path` matches the
	# whole reported path, so the leading `*/` is what lets the day and minute segments be anything.
	local logs=()
	while IFS= read -r log; do logs+=("$log"); done < <(
		find "$DIR" -mindepth 4 -maxdepth 4 -type f -name run.log \
			-path "*/${prefix}-*/run.log" 2>/dev/null)

	echo "== $label =="
	if [[ ${#logs[@]} -eq 0 ]]; then
		echo "  none in $DIR"
		echo
		return
	fi
	echo "  runs: ${#logs[@]}"

	local wins losses near_count
	wins=$(awk '$2=="home"{c++} END{print c+0}' "${logs[@]}")
	losses=$(awk '$2=="lost"{c++} END{print c+0}' "${logs[@]}")
	echo "  days: $wins won, $losses lost"

	if [[ "$losses" -gt 0 ]]; then
		echo "  loss causes:"
		awk '$2=="lost"{print $3}' "${logs[@]}" | sort | uniq -c | sort -rn |
			while read -r n cause; do printf "    %-16s %d\n" "$cause" "$n"; done
	fi

	near_count=$(awk '$2=="near"{c++} END{print c+0}' "${logs[@]}")
	if [[ "$near_count" -gt 0 ]]; then
		echo "  most-met events (count of near-lines, not distinct encounters — see docs/TELEMETRY.md's near entry):"
		awk '$2=="near"{print $3}' "${logs[@]}" | sort | uniq -c | sort -rn | head -10 |
			while read -r n id; do printf "    %-24s %d\n" "$id" "$n"; done
	fi
	echo
}

case "$mode" in
	playtest) print_group "playtest runs (run-*/)" "run" ;;
	rigs)     print_group "rig runs (rig-*/)" "rig" ;;
	all)
		print_group "playtest runs (run-*/)" "run"
		print_group "rig runs (rig-*/)" "rig"
		;;
esac
