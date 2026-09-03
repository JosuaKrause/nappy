#!/usr/bin/env bash
# Run the headless test suite.
#
#   tools/test.sh                 everything — the only run a commit may rest on
#   tools/test.sh crowd balance   only the suites whose file name contains one of these
#   tools/test.sh --serial        everything, in one process (what a shard failure is debugged in)
#
# A full run is sharded across several Godot processes and a filtered run is not. The reason is
# the shape of the suite rather than a preference: the work is one core's worth of arithmetic per
# process, the suites are independent, and one of them — `test_events.gd` — is a quarter of the
# whole on its own. Serially that is minutes of one core while the rest of the machine idles, and
# minutes is long enough that the gate becomes something people skip.
#
# **Sharding changes nothing about what is checked.** Every suite still runs, every check still
# runs, and the count printed at the end is the sum. What it must never do is quietly run *fewer*
# suites than a serial run would, which is why the shards are built from the files on disk rather
# than from a list somebody maintains — see `_plan_the_shards`.
set -uo pipefail
shopt -s nullglob

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# More than this buys nothing: the wall clock cannot go below the slowest single suite, and that
# is `test_events.gd` at about two minutes. Override for a machine with a different shape.
SHARDS="${TEST_SHARDS:-4}"

if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT (override with GODOT=...)" >&2
    exit 127
fi

serial=0
plan_only=0
case "${1:-}" in
    --serial) serial=1; shift ;;
    --plan)   plan_only=1; shift ;;
esac

# The import pass, once and before anything runs in parallel. Several Godot processes importing
# the same project at the same time race on `.godot/`, and the failure looks like a missing
# `class_name` rather than like a race.
"$GODOT" --headless --import --path "$PROJECT_DIR" >/dev/null 2>&1

run_one_process() {
	# Everything after `--` reaches the runner as OS.get_cmdline_user_args().
	"$GODOT" --headless --path "$PROJECT_DIR" res://tests/tests.tscn -- "$@"
}

# A filtered run is one process and says so loudly, which is the runner's own rule: a partial pass
# has to be impossible to mistake for a green build. `--serial` is the same path, unfiltered.
if [[ $# -gt 0 || $serial -eq 1 ]]; then
    run_one_process "$@"
    exit $?
fi

# ------------------------------------------------------------------- sharding ---

## Rough cost of a suite in milliseconds, measured rather than guessed, and only ever used to
## decide *which shard* it lands in. A stale number costs some balance and no correctness — the
## worst a wrong cost can do is make one shard finish later than another.
##
## **A `case` rather than an associative array, because macOS ships bash 3.2** — the last GPLv2
## release, which has no `declare -A`. It does not fail on one either: it quietly makes an
## *indexed* array, and every `${COST[test_events.gd]}` then gets its subscript evaluated as
## arithmetic. The first version of this file did exactly that, every cost came back empty, and
## the bin-packer below put all twenty-three suites in one shard — a "parallel" run that was
## serial and looked fine apart from being no faster.
_cost_of() {
	case "$1" in
		test_events.gd)      echo 127000 ;;
		test_routes.gd)      echo  90000 ;;
		test_generator.gd)   echo  79000 ;;
		test_crowd.gd)       echo  55000 ;;
		test_balance.gd)     echo  22000 ;;
		test_full_run.gd)    echo  20000 ;;
		test_telemetry.gd)   echo  18000 ;;
		test_route_tree.gd)  echo  11000 ;;
		test_acts.gd)        echo   8000 ;;
		test_event_manager.gd) echo 8000 ;;
		test_blocks.gd)      echo   5000 ;;
		test_reachability_grid.gd) echo 4000 ;;
		test_heat.gd)        echo   2000 ;;
		# What an unlisted suite is assumed to cost. Deliberately not tiny: a new suite nobody
		# has measured is planned for as though it were middling, rather than being swept into
		# whichever shard is already fullest.
		*)                   echo   5000 ;;
	esac
}

shard_filters=()
shard_cost=()

## Assigns every `tests/test_*.gd` on disk to the shard with the least work in it so far, heaviest
## suite first — which is the standard greedy bin-packing and is well inside "good enough" for two
## dozen items.
##
## **The suites are discovered from disk, never listed here.** A hand-maintained list is one
## forgotten line away from a new suite that never runs while the gate still prints "0 failures",
## and that is the one failure this whole file must not have. The filter passed to the runner is
## the full file name, which its substring matching resolves to exactly one suite.
_plan_the_shards() {
	local i
	for ((i = 0; i < SHARDS; i++)); do
		shard_filters[i]=""
		shard_cost[i]=0
	done

	local weighted=()
	local path file
	for path in "$PROJECT_DIR"/tests/test_*.gd; do
		file="$(basename "$path")"
		weighted+=("$(printf '%09d %s' "$(_cost_of "$file")" "$file")")
	done
	if [[ ${#weighted[@]} -eq 0 ]]; then
		echo "no test suites found in $PROJECT_DIR/tests" >&2
		exit 1
	fi

	local line lightest
	while IFS= read -r line; do
		file="${line#* }"
		lightest=0
		for ((i = 1; i < SHARDS; i++)); do
			if (( shard_cost[i] < shard_cost[lightest] )); then
				lightest=$i
			fi
		done
		shard_filters[lightest]+=" $file"
		# `10#` because the cost is zero-padded to sort numerically, and bash reads a leading
		# zero as octal — `000090000` is not a number, it is an error about digit 9.
		shard_cost[lightest]=$(( shard_cost[lightest] + 10#${line%% *} ))
	done < <(printf '%s\n' "${weighted[@]}" | sort -rn)
}

_plan_the_shards

# `tools/test.sh --plan` prints the split and runs nothing. Worth having as a flag rather than as
# a comment: the failure this file has already had once was a *planning* bug that looked exactly
# like a working run, and the only cheap way to see it is to look at the plan itself.
if [[ $plan_only -eq 1 ]]; then
	for ((i = 0; i < SHARDS; i++)); do
		printf 'shard %d  ~%3ds %s\n' "$i" "$(( shard_cost[i] / 1000 ))" "${shard_filters[i]}"
	done
	exit 0
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

pids=()
for ((i = 0; i < SHARDS; i++)); do
	if [[ -z "${shard_filters[i]}" ]]; then
		continue
	fi
	# shellcheck disable=SC2086 -- the filters are file names and are meant to word-split.
	run_one_process ${shard_filters[i]} > "$work_dir/shard-$i.log" 2>&1 &
	pids+=("$i:$!")
done

status=0
for entry in "${pids[@]}"; do
	if ! wait "${entry#*:}"; then
		status=1
	fi
done

# ------------------------------------------------------------------ reporting ---

total_checks=0
total_failures=0
for ((i = 0; i < SHARDS; i++)); do
	log="$work_dir/shard-$i.log"
	[[ -f "$log" ]] || continue

	# The per-suite timings and any FAIL lines, exactly as a serial run prints them. The runner's
	# own "PARTIAL RUN" line is dropped here and only here: each shard is genuinely partial, and
	# the union of them is not, so repeating it would say the opposite of what is true.
	grep -E '^(-- |FAIL )' "$log"

	counted="$(grep -E '^[0-9]+ checks, [0-9]+ failures$' "$log" | tail -1)"
	if [[ -z "$counted" ]]; then
		# A shard that printed no count did not finish. A parse error in any suite aborts the
		# runner's `_ready()` before it can quit, so the process sits there printing nothing —
		# which is why this is a hard failure rather than a shard contributing zero.
		echo "shard $i produced no count — it crashed or hung. Its output:" >&2
		sed 's/^/    /' "$log" >&2
		status=1
		continue
	fi
	total_checks=$(( total_checks + ${counted%% *} ))
	failures_here="${counted#*, }"
	total_failures=$(( total_failures + ${failures_here%% *} ))
done

echo ""
echo "$total_checks checks, $total_failures failures (across $SHARDS shards)"
if (( total_failures > 0 )); then
	status=1
fi
exit $status
