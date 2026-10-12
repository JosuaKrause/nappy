#!/usr/bin/env bash
# Records the per-system frame record (--frame-record) for several revisions of this repository on
# the same seed, days and walk over equal windows, headless and windowed, rotating through the
# revisions round by round so a drift in the machine's load falls on every one.
#
#   docs/evidence/m159-offscreen-2026-10-11/run.sh <scratch-dir> <rounds> <label=sha>...
#
# <scratch-dir> must not exist yet. Each <label=sha> gets a detached, sparse worktree in it,
# imported by `tools/check.sh`. Every run is seed 67 on days 1 and 14 with the player's walk
# (docs/evidence/m159-frame-record-2026-10-04/measure.py's WALK), --invincible so the day runs its
# whole window, --after 40; windowed runs are 1280x720, always on top, VSync off. Before each run
# it waits (up to 5 minutes) for every other Godot process to end and records how many were still
# running and the 1-minute load average in out/runs.tsv. Each frame record is copied, gzipped, to
# out/<label>-<mode>-d<day>-r<round>.json.gz. GODOT names the engine (default: the macOS app
# bundle's binary). Read the result with analyse.py.
set -euo pipefail

usage() {
	echo "usage: $0 [--help|-h] <scratch-dir> <rounds> <label=sha>..." >&2
}

case "${1:-}" in
	-h|--help)
		sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
		exit 0 ;;
	""|-*)
		usage
		exit 2 ;;
esac
[ $# -ge 3 ] || { usage; exit 2; }
SCRATCH="$1"
ROUNDS="$2"
shift 2
case "$ROUNDS" in ''|*[!0-9]*) echo "rounds must be a positive integer" >&2; exit 2 ;; esac
[ "$ROUNDS" -ge 1 ] || { echo "rounds must be a positive integer" >&2; exit 2; }
for spec in "$@"; do
	case "$spec" in
		[a-z0-9_]*=[0-9a-f]*) ;;
		*) echo "$spec is not label=sha" >&2; exit 2 ;;
	esac
done
[ ! -e "$SCRATCH" ] || { echo "$SCRATCH already exists" >&2; exit 2; }

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
REPO="$(cd "$(dirname "$0")" && git rev-parse --show-toplevel)"
WALK="2.6e15.5n1w4n1e11n11s1w4s1e15.5s"
FLAGS=(--seed 67 --no-title --invincible --no-focus-pause --no-save --no-telemetry --player-view
	--frame-record --after 40 --walk "$WALK")
FILES="src/crowd/crowd_agent.gd src/events/event_instance.gd src/ui/danger_edge.gd src/ui/home_arrow.gd"

mkdir -p "$SCRATCH/out"
SCRATCH="$(cd "$SCRATCH" && pwd)"
LABELS=""
for spec in "$@"; do
	label="${spec%%=*}"
	sha="${spec#*=}"
	(cd "$REPO" && git cat-file -e "$sha^{commit}") || {
		echo "$sha is not in this clone: fetch the pull request's head first" >&2; exit 1; }
	LABELS="$LABELS $label"
	(cd "$REPO" && git worktree add --detach --no-checkout "$SCRATCH/$label" "$sha")
	(cd "$SCRATCH/$label" && git sparse-checkout set --no-cone '/*' '!/docs/evidence/' \
		'!/docs/reference/' '!/docs/style-references/' && git checkout --detach "$sha")
	(cd "$SCRATCH/$label" && ./tools/check.sh > "$SCRATCH/out/$label-import.log" 2>&1)
done

wait_for_engines() {
	local waited=0
	while pgrep -x Godot > /dev/null && [ "$waited" -lt 300 ]; do
		sleep 10
		waited=$((waited + 10))
	done
}

printf 'round\tlabel\tmode\tday\tcommit\tstarted\tload_1m\tother_engines' > "$SCRATCH/out/runs.tsv"
for file in $FILES; do printf '\t%s' "$(basename "$file")" >> "$SCRATCH/out/runs.tsv"; done
printf '\n' >> "$SCRATCH/out/runs.tsv"
for round in $(seq 1 "$ROUNDS"); do
	for mode in headless windowed; do
		for day in 1 14; do
			for label in $LABELS; do
				dir="$SCRATCH/$label"
				wait_for_engines
				others="$( (pgrep -x Godot || true) | wc -l | tr -d ' ')"
				load="$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')"
				hashes=""
				for file in $FILES; do
					hashes="$hashes	$(shasum -a 256 "$dir/$file" | cut -c1-64)"
				done
				printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s%s\n' "$round" "$label" "$mode" "$day" \
					"$(cd "$dir" && git rev-parse HEAD)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$load" \
					"$others" "$hashes" >> "$SCRATCH/out/runs.tsv"
				name="$label-$mode-d$day-r$round"
				if [ "$mode" = headless ]; then
					engine=(--headless)
				else
					engine=(--always-on-top --disable-vsync --resolution 1280x720)
				fi
				(cd "$dir" && "$GODOT" "${engine[@]}" --path . -- "${FLAGS[@]}" --day "$day" \
					> "$SCRATCH/out/$name.log" 2>&1) || true
				record="$(sed -n 's/^Frame record: //p' "$SCRATCH/out/$name.log" | tail -1)"
				[ -n "$record" ] && [ -f "$record" ] || {
					echo "no frame record for $name: see $SCRATCH/out/$name.log" >&2; exit 1; }
				gzip -c "$record" > "$SCRATCH/out/$name.json.gz"
			done
		done
	done
done
echo "wrote $SCRATCH/out"
