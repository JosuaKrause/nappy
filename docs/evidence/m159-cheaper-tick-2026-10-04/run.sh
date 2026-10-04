#!/usr/bin/env bash
# Measures the crowd's physics tick before and after the M159 cheaper-tick change, alternating
# the two revisions round by round so a drift in the machine's load falls on both.
#
#   docs/evidence/m159-cheaper-tick-2026-10-04/run.sh <scratch-dir> [rounds]
#
# <scratch-dir> must not exist yet. It gets two detached worktrees of this repository (`before`,
# `after`, each sparse like an agent worktree and imported by `tools/check.sh`) and `out/`, one
# probe log per revision and round plus `runs.tsv`, which says what ran when, the load average
# before it, and the SHA-256 of the three files the comparison is about. The worktrees are left in
# place for a second look; `git worktree remove <scratch-dir>/before` (and `after`) clears them.
# GODOT names the engine (default: the macOS app bundle's binary); rounds defaults to 3.
set -euo pipefail

usage() {
	echo "usage: $0 [--help|-h] <scratch-dir> [rounds]" >&2
}

case "${1:-}" in
	-h|--help)
		sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
		exit 0 ;;
	""|-*)
		usage
		exit 2 ;;
esac
[ $# -le 2 ] || { usage; exit 2; }
SCRATCH="$1"
ROUNDS="${2:-3}"
case "$ROUNDS" in ''|*[!0-9]*) echo "rounds must be a positive integer" >&2; exit 2 ;; esac
[ "$ROUNDS" -ge 1 ] || { echo "rounds must be a positive integer" >&2; exit 2; }
[ ! -e "$SCRATCH" ] || { echo "$SCRATCH already exists" >&2; exit 2; }

export GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
BEFORE=dcd052a56a4ccf27f207eae30a6aaba47f25b28e
AFTER=a7623b36303d1deb6a61f645d364212d6db27b69
REPO="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
FILES="src/crowd/crowd.gd src/crowd/crowd_agent.gd tests/probes/m159_crowd_tick_cost.gd"

mkdir -p "$SCRATCH/out"
SCRATCH="$(cd "$SCRATCH" && pwd)"
for rev in before after; do
	sha=$BEFORE
	[ "$rev" = after ] && sha=$AFTER
	git -C "$REPO" cat-file -e "$sha^{commit}" || {
		echo "$sha is not in this clone: fetch the pull request's head first" >&2; exit 1; }
	git -C "$REPO" worktree add --detach --no-checkout "$SCRATCH/$rev" "$sha"
	git -C "$SCRATCH/$rev" sparse-checkout set --no-cone '/*' '!/docs/evidence/' \
		'!/docs/reference/' '!/docs/style-references/'
	git -C "$SCRATCH/$rev" checkout --detach "$sha"
	(cd "$SCRATCH/$rev" && ./tools/check.sh > "$SCRATCH/out/$rev-import.log" 2>&1)
done

printf 'round\trevision\tcommit\tstarted\tload_1m\tcrowd.gd\tcrowd_agent.gd\tprobe\n' \
	> "$SCRATCH/out/runs.tsv"
for round in $(seq 1 "$ROUNDS"); do
	for rev in before after; do
		dir="$SCRATCH/$rev"
		[ -z "$(git -C "$dir" status --porcelain --untracked-files=no)" ] || {
			echo "$dir has tracked changes" >&2; exit 1; }
		hashes=""
		for file in $FILES; do
			hashes="$hashes	$(shasum -a 256 "$dir/$file" | cut -c1-64)"
		done
		load="$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')"
		printf '%s\t%s\t%s\t%s\t%s%s\n' "$round" "$rev" "$(git -C "$dir" rev-parse HEAD)" \
			"$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$load" "$hashes" >> "$SCRATCH/out/runs.tsv"
		(cd "$dir" && ./tools/test.sh probes/m159_crowd_tick_cost.gd \
			> "$SCRATCH/out/$rev-$round.log" 2>&1)
	done
done
echo "wrote $SCRATCH/out"
