#!/usr/bin/env bash
# Measures the influence sweep and the events' physics step across several revisions of this
# repository, round by round, starting each round one revision further along the list so a drift
# in the machine's load and a revision's place in the round fall on every one.
#
#   docs/evidence/m159-tick-sweep-events-2026-10-12/run.sh <scratch-dir> <rounds> <label=sha>...
#
# <scratch-dir> must not exist yet. Each <label=sha> gets a detached, sparse worktree in it,
# imported by `tools/check.sh`; the first label is the baseline the report compares against. Every
# revision runs the probe file of the LAST revision given, copied over its own (the probe is the
# instrument, and every revision must be read by the same one). `out/` gets one probe log per
# label and round plus `runs.tsv`: when it ran, its place in the round, the 1-minute load average
# before it, and the SHA-256 of the files the comparison is about. GODOT names the engine
# (default: the macOS app bundle's binary).
set -euo pipefail

usage() {
	echo "usage: $0 [--help|-h] <scratch-dir> <rounds> <label=sha>..." >&2
}

case "${1:-}" in
	-h|--help)
		sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
		exit 0 ;;
	""|-*)
		usage
		exit 2 ;;
esac
[ $# -ge 4 ] || { usage; exit 2; }
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

export GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
REPO="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
PROBE="tests/probes/m159_tick_sweep_events_cost.gd"
FILES="src/events/event_def.gd src/events/event_instance.gd src/events/event_manager.gd"
FILES="$FILES src/crowd/crowd.gd src/crowd/crowd_agent.gd src/player/baby.gd $PROBE"

mkdir -p "$SCRATCH/out"
SCRATCH="$(cd "$SCRATCH" && pwd)"
LABELS=()
PROBE_SHA=""
for spec in "$@"; do
	sha="${spec#*=}"
	git -C "$REPO" cat-file -e "$sha^{commit}" || {
		echo "$sha is not in this clone: fetch the pull request's head first" >&2; exit 1; }
	LABELS+=("${spec%%=*}")
	PROBE_SHA="$sha"
done
for spec in "$@"; do
	label="${spec%%=*}"
	sha="${spec#*=}"
	git -C "$REPO" worktree add --detach --no-checkout "$SCRATCH/$label" "$sha"
	git -C "$SCRATCH/$label" sparse-checkout set --no-cone '/*' '!/docs/evidence/' \
		'!/docs/reference/' '!/docs/style-references/'
	git -C "$SCRATCH/$label" checkout --detach "$sha"
	git -C "$REPO" show "$PROBE_SHA:$PROBE" > "$SCRATCH/$label/$PROBE"
	(cd "$SCRATCH/$label" && ./tools/check.sh > "$SCRATCH/out/$label-import.log" 2>&1)
done

header="round	slot	label	commit	started	load_1m"
for file in $FILES; do
	header="$header	$(basename "$file")"
done
printf '%s\n' "$header" > "$SCRATCH/out/runs.tsv"
count=${#LABELS[@]}
for round in $(seq 1 "$ROUNDS"); do
	for slot in $(seq 0 $((count - 1))); do
		label="${LABELS[$(((round - 1 + slot) % count))]}"
		dir="$SCRATCH/$label"
		hashes=""
		for file in $FILES; do
			hashes="$hashes	$(shasum -a 256 "$dir/$file" | cut -c1-64)"
		done
		load="$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')"
		printf '%s\t%s\t%s\t%s\t%s\t%s%s\n' "$round" "$slot" "$label" \
			"$(git -C "$dir" rev-parse HEAD)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$load" "$hashes" \
			>> "$SCRATCH/out/runs.tsv"
		(cd "$dir" && ./tools/test.sh "probes/$(basename "$PROBE")" \
			> "$SCRATCH/out/$label-$round.log" 2>&1)
	done
done
echo "wrote $SCRATCH/out"
