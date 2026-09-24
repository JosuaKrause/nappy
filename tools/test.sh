#!/usr/bin/env bash
# Run the headless test suite.
#
#   tools/test.sh                 everything, sharded across TEST_SHARDS local processes
#   tools/test.sh crowd balance   only the suites whose file name contains one of these
#   tools/test.sh --serial        everything, in one process (what a shard failure is debugged in)
#   tools/test.sh --plan          print the shard split and run nothing
#   tools/test.sh --shard 3/8     run only shard 3 of 8 -- what one CI matrix leg runs
#   tools/test.sh --record-costs  run everything, then refresh tests/suite_costs.txt from it
#
# A full run is sharded -- locally across several Godot processes, in CI across matrix jobs, one
# runner per shard. The reason is the shape of the suite rather than a preference: the work is
# one core's worth of arithmetic per process, the suites are independent, and the two heaviest,
# `test_crowd.gd` and `test_events.gd`, are together most of the whole on their own. Serially
# that is minutes of one core while the rest of the machine (or fleet) idles, and minutes is long
# enough that the gate becomes something people skip.
#
# **Sharding changes nothing about what is checked.** Every suite still runs, every check still
# runs, and the count printed at the end is the sum (locally; in CI the final `test` job stands
# for the whole matrix). What it must never do is quietly run *fewer* suites than a serial run
# would, which is why the shards are built from the files on disk rather than from a list
# somebody maintains — see `_plan_the_shards`. A local run and a CI shard plan identically,
# because both read the same `tests/suite_costs.txt` through `_cost_of`.
#
# A shard that hangs is killed after TEST_SHARD_TIMEOUT_S (default 600) and reported by name
# rather than left to block the run forever -- see `run_one_process`'s own docstring.
set -uo pipefail
shopt -s nullglob

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# The longest suite sets a floor on wall time: see tests/suite_costs.txt for what it currently
# is. Locally, four shards is a reasonable default for one machine's cores; CI's matrix instead
# picks its own shard count by that floor (see .github/workflows/ci.yml) and always tells this
# script which shard to run via --shard, which sets SHARDS itself. Override this default for a
# machine with a different CPU or memory budget.
SHARDS="${TEST_SHARDS:-4}"

# How long the local parallel run below waits on one shard before killing it and reporting it
# hung. `tools/test.sh --plan`'s own bin-packing, read from tests/suite_costs.txt at the default
# four shards, currently tops out at ~313s (test_events.gd's shard); this is comfortably above
# that and still well inside a CI shard job's own 15-minute (`.github/workflows/ci.yml`) budget,
# so a real hang is caught and named long before anything blunter would cut the job off with no
# message at all. Only this one path uses it -- `--serial` and `--shard I/N` run more suites in
# one process than any single shard carries and are never bounded by a limit sized for a shard's
# share of the work.
SHARD_TIMEOUT_S="${TEST_SHARD_TIMEOUT_S:-600}"

# Where the measured per-suite costs live and what an unmeasured suite is assumed to cost. See
# tests/suite_costs.txt's own header for what the file is and how it is refreshed.
COST_FILE="$PROJECT_DIR/tests/suite_costs.txt"
DEFAULT_COST_MS=5000

usage() {
    cat <<'EOF'
usage: tools/test.sh [--help|-h] [--serial|--plan|--record-costs|--shard I/N] [suite-name-substring...]

Runs the headless test suite (tests/tests.tscn). With no arguments, runs everything, sharded
across TEST_SHARDS (default 4) Godot processes, planned from tests/suite_costs.txt. A
suite-name-substring argument filters to the suites whose file name contains it and runs
unfiltered/unsharded, in one process; that filtered run also accepts any flag the test scene
itself reads off OS.get_cmdline_user_args(), which is why this script does not
reject an argument it does not itself recognise -- only --serial, --plan, --record-costs,
--shard, --help and -h are its own.
  --serial          everything, in one process (what a shard failure is debugged in)
  --plan            print the shard split (TEST_SHARDS processes) and run nothing
  --record-costs    run everything sharded, then rewrite tests/suite_costs.txt from this run's
                     own per-suite lines
  --shard I/N       run only shard I of N (1-indexed), planned the same way every other shard
                     is, and let the runner's own PARTIAL RUN note say so -- one shard is never
                     a green build by itself

  tools/test.sh
  tools/test.sh crowd balance
  tools/test.sh --serial
  tools/test.sh --shard 3/8
EOF
}

case "${1:-}" in
    --help|-h) usage; exit 0 ;;
esac

if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT (override with GODOT=...)" >&2
    exit 127
fi

serial=0
plan_only=0
record_costs=0
shard_arg=""
case "${1:-}" in
    --serial)       serial=1; shift ;;
    --plan)         plan_only=1; shift ;;
    --record-costs) record_costs=1; shift ;;
    --shard)
        shard_arg="${2:-}"
        if [[ -z "$shard_arg" ]]; then
            echo "tools/test.sh: --shard needs an I/N argument, e.g. --shard 3/8" >&2
            echo >&2
            usage >&2
            exit 2
        fi
        shift 2
        ;;
esac

# --shard and --record-costs run the whole planned suite, not a hand-picked subset, so neither
# takes suite-name filters -- anything left over is a mistake to reject rather than to guess at.
if [[ ( -n "$shard_arg" || $record_costs -eq 1 ) && $# -gt 0 ]]; then
    echo "tools/test.sh: --shard and --record-costs take no suite-name filters" >&2
    echo >&2
    usage >&2
    exit 2
fi

shard_index=""
if [[ -n "$shard_arg" ]]; then
    if [[ ! "$shard_arg" =~ ^[0-9]+/[0-9]+$ ]]; then
        echo "tools/test.sh: --shard wants I/N, e.g. --shard 3/8 (got '$shard_arg')" >&2
        echo >&2
        usage >&2
        exit 2
    fi
    shard_index="${shard_arg%%/*}"
    SHARDS="${shard_arg#*/}"
    if [[ "$SHARDS" -lt 1 || "$shard_index" -lt 1 || "$shard_index" -gt "$SHARDS" ]]; then
        echo "tools/test.sh: --shard I/N wants 1 <= I <= N (got '$shard_arg')" >&2
        echo >&2
        usage >&2
        exit 2
    fi
    shard_index=$(( shard_index - 1 ))
fi

# The atlas pages, before the import pass that has to see them; no work when they are current.
"$PROJECT_DIR/tools/bake-atlases.sh" || exit 1

# The import pass, once and before anything runs in parallel. Several Godot processes importing
# the same project at the same time race on `.godot/`, and the failure looks like a missing
# `class_name` rather than like a race.
"$GODOT" --headless --import --path "$PROJECT_DIR" >/dev/null 2>&1

## Runs one Godot test process and classifies it the way tools/check.sh already classifies a
## boot: Godot can print an engine `ERROR:`, a `push_error()` or a completed `SCRIPT ERROR` /
## `Parse Error` and still exit 0, because `run_tests.gd` only counts failed `check()` /
## `close_to()` calls into its own array and that array is all `SceneTree.quit()` looks at. So the
## combined stdout+stderr is teed to a scratch file and grepped after the process ends, rather
## than trusting the exit code alone. `tee` rather than plain capture-then-print, so every existing
## caller keeps seeing output exactly where it already goes -- a live terminal for a filtered run,
## a redirected file for one shard of a local sharded run -- and only the returned status changes.
##
## **`RUN_TIMEOUT_S`, when set, bounds the wait and kills a process that outlives it** -- unset by
## every caller except the local parallel run below, which is the one path whose own "produced no
## count" branch further down turns a kill into a diagnosed failure rather than a silent one.
## `--serial` and `--shard I/N` run more suites in this one process than any single shard carries
## and must never be cut short by a limit sized for a shard's share of the work, so they leave it
## unset and wait however long the whole run actually takes.
##
## Piped through a process substitution rather than a plain `| tee` so that, when a timeout is
## set, `$!` right after backgrounding is Godot's own PID and not `tee`'s -- the watchdog has to
## kill the engine, not the thing copying its output to a file, and a bare `| tee` in the
## foreground gives no PID to kill at all.
run_one_process() {
	local scratch status
	scratch="$(mktemp)"
	if [[ -n "${RUN_TIMEOUT_S:-}" ]]; then
		# Everything after `--` reaches the runner as OS.get_cmdline_user_args().
		"$GODOT" --headless --path "$PROJECT_DIR" res://tests/tests.tscn -- "$@" \
				> >(tee "$scratch") 2>&1 &
		local godot_pid=$!
		# TERM first, then KILL after a short grace period for a process that is not merely slow
		# but genuinely will not respond -- SIGTERM's default disposition ends a hung process too
		# in every case that matters here, but the escalation costs nothing when it is not needed.
		(
			sleep "$RUN_TIMEOUT_S"
			kill -TERM "$godot_pid" 2>/dev/null
			sleep 5
			kill -KILL "$godot_pid" 2>/dev/null
		) &
		local watchdog_pid=$!
		wait "$godot_pid"
		status=$?
		kill "$watchdog_pid" 2>/dev/null
		wait "$watchdog_pid" 2>/dev/null
		# Godot's own exit closes the pipe the process substitution reads, so the `tee` on the
		# other end of it is already finishing -- this just lets it actually finish flushing
		# before the grep below reads the file it was writing.
		wait
	else
		"$GODOT" --headless --path "$PROJECT_DIR" res://tests/tests.tscn -- "$@" 2>&1 | tee "$scratch"
		status="${PIPESTATUS[0]}"
	fi
	if grep -qE "SCRIPT ERROR|Parse Error|ERROR:" "$scratch"; then
		status=1
	fi
	rm -f "$scratch"
	return "$status"
}

## Stages tests/runner_fixtures/<name>.gd.src to its real tests/runner_fixtures/<name>.gd path for
## one named argument, if that source exists and nothing is already sitting at the destination.
## Prints the staged path so the caller can remove it again.
##
## **Why a fixture is ever kept off its real .gd name.** A `.gd` anywhere in the project tree is
## something both Godot's global class-name scan and the atlas bake above walk, and when
## `.godot/`'s class-name cache is cold -- a fresh clone's first run, or any checkout with
## `.godot/` removed, which is the state every clone starts in since `.godot/` is gitignored -- an
## unparseable one among them makes every autoload that resolves through a `class_name` lookup
## fail to instantiate for that one process, not just the suite that named it. See
## tests/runner_fixtures/unparseable_suite.gd.src's own header for the measurement. Staging here
## happens after the bake and the import pass above have already run against a tree with no
## broken `.gd` in it, and only for the one process about to load it.
stage_runner_fixture() {
	local arg="$1" src dst
	case "$arg" in
		runner_fixtures/*.gd) ;;
		*) return 0 ;;
	esac
	src="$PROJECT_DIR/tests/${arg}.src"
	dst="$PROJECT_DIR/tests/${arg}"
	[[ -f "$src" ]] || return 0
	if [[ -f "$dst" ]]; then
		echo "tools/test.sh: $dst already exists on disk -- not staging over it" >&2
		return 1
	fi
	cp "$src" "$dst"
	printf '%s\n' "$dst"
}

# A filtered run is one process and says so loudly, which is the runner's own rule: a partial pass
# has to be impossible to mistake for a green build. `--serial` is the same path, unfiltered.
if [[ $# -gt 0 || $serial -eq 1 ]]; then
    staged=()
    # Removed on every exit from this branch -- a normal return, an error return, or a signal --
    # so a staged fixture never survives the one process it was staged for.
    cleanup_staged() {
		local f
		for f in "${staged[@]+"${staged[@]}"}"; do
			rm -f "$f" "$f.uid"
		done
    }
    trap cleanup_staged EXIT
    for arg in "$@"; do
        staged_path="$(stage_runner_fixture "$arg")" || exit 1
        if [[ -n "$staged_path" ]]; then
            staged+=("$staged_path")
        fi
    done
    run_one_process "$@"
    exit $?
fi
# ------------------------------------------------------------------- sharding ---

## Cost of a suite in milliseconds, read from tests/suite_costs.txt and only ever used to decide
## *which shard* it lands in. A stale number costs some balance and no correctness — the worst a
## wrong cost can do is make one shard finish later than another.
##
## **A missing row costs far more than a stale one, and that is the case to watch.** A suite
## nobody has measured yet is planned at DEFAULT_COST_MS below, with a warning, so a genuinely
## heavy new suite lands in a shard that was already full and adds its whole weight to the wall
## clock rather than vanishing silently. `tools/test.sh --record-costs` is how a fresh measurement
## replaces the default.
##
## **A linear scan of a file rather than an associative array, because macOS ships bash 3.2** —
## the last GPLv2 release, which has no `declare -A`. It does not fail on one either: it quietly
## makes an *indexed* array, and every `${COST[test_events.gd]}` then gets its subscript evaluated
## as arithmetic. The first version of this file did exactly that, every cost came back empty, and
## the bin-packer below put all twenty-three suites in one shard — a "parallel" run that was
## serial and looked fine apart from being no faster. A few dozen lines read per suite is free
## next to a suite that takes minutes.
_cost_of() {
	local file="$1" name ms
	if [[ -f "$COST_FILE" ]]; then
		while read -r name ms; do
			case "$name" in
				''|'#'*) continue ;;
			esac
			if [[ "$name" == "$file" ]]; then
				printf '%s\n' "$ms"
				return
			fi
		done < "$COST_FILE"
	fi
	echo "tools/test.sh: no measured cost for $file in $(basename "$COST_FILE") — planning it at the default ${DEFAULT_COST_MS}ms; run tools/test.sh --record-costs once it has run to fix this" >&2
	printf '%s\n' "$DEFAULT_COST_MS"
}

shard_filters=()
shard_cost=()

## Assigns every `tests/test_*.gd` on disk to the shard with the least work in it so far, heaviest
## suite first — which is the standard greedy bin-packing and is well inside "good enough" for a
## few dozen items.
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

if ! [[ "$SHARDS" =~ ^[0-9]+$ ]] || [[ "$SHARDS" -lt 1 ]]; then
	echo "TEST_SHARDS must be a positive integer (got '$SHARDS')" >&2
	echo >&2
	usage >&2
	exit 2
fi

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

# `--shard I/N` runs exactly the one shard a CI matrix leg was assigned, in this one process, and
# nothing else. It reuses the plan above rather than a separate code path, so a CI shard and a
# local sharded run always agree about which suite lands where. The filter list reaching
# run_one_process is never empty here in practice (N is chosen no larger than the suite count),
# but a shard with nothing assigned exits clean instead of silently falling through to "no
# filters", which run_tests.gd reads as "run everything" — the one way this flag could turn a
# single shard into a false green full build.
if [[ -n "$shard_index" ]]; then
	filters="${shard_filters[shard_index]}"
	if [[ -z "$filters" ]]; then
		echo "shard $(( shard_index + 1 ))/$SHARDS has no suites assigned (more shards than suites) — nothing to run"
		exit 0
	fi
	# The filters are file names and are meant to word-split.
	# shellcheck disable=SC2086
	run_one_process $filters
	exit $?
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

pids=()
for ((i = 0; i < SHARDS; i++)); do
	if [[ -z "${shard_filters[i]}" ]]; then
		continue
	fi
	# The filters are file names and are meant to word-split. `RUN_TIMEOUT_S` is what makes the
	# "produced no count -- it crashed or hung" branch below reachable: without it, a hung shard
	# blocks the `wait` loop forever and that branch is dead code with a comment claiming
	# otherwise.
	# shellcheck disable=SC2086
	RUN_TIMEOUT_S="$SHARD_TIMEOUT_S" run_one_process ${shard_filters[i]} \
			> "$work_dir/shard-$i.log" 2>&1 &
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

	# A shard can print a clean "N checks, 0 failures" line and still have carried an engine
	# error: `run_tests.gd` only counts failed check()/close_to() into that line, so Godot's own
	# ERROR:/SCRIPT ERROR/Parse Error never reaches it. Surface it here explicitly, or it is a line
	# this loop would otherwise drop on the floor along with every other non-timing, non-FAIL line.
	if grep -qE "SCRIPT ERROR|Parse Error|ERROR:" "$log"; then
		echo "shard $i printed an engine error -- its own check count does not see this. Offending lines:" >&2
		grep -E "SCRIPT ERROR|Parse Error|ERROR:" "$log" | sed 's/^/    /' >&2
		status=1
	fi

	counted="$(grep -E '^[0-9]+ checks, [0-9]+ failures$' "$log" | tail -1)"
	if [[ -z "$counted" ]]; then
		# A shard that printed no count did not finish. A suite that fails to load is a named
		# `FAIL` line and a normal exit now (`run_tests.gd`'s loader guard), so a missing count
		# here means the process crashed outright or is hung on something the guard does not
		# cover -- which is why this is a hard failure rather than a shard contributing zero.
		echo "shard $i produced no count — it crashed or hung. Its output:" >&2
		sed 's/^/    /' "$log" >&2
		status=1
		continue
	fi
	total_checks=$(( total_checks + ${counted%% *} ))
	failures_here="${counted#*, }"
	total_failures=$(( total_failures + ${failures_here%% *} ))
done

# `--record-costs` rewrites tests/suite_costs.txt from exactly the "-- suite  N ms" lines just
# printed above, across every shard log -- the same lines a developer reads off the screen, so
# the file can never record a number nobody's run actually produced. It asserts the row count
# against the suites on disk before overwriting anything, and leaves the old file alone if they
# don't match (a crashed shard is missing its rows, and a partial cost table is worse than a
# stale one).
if [[ $record_costs -eq 1 ]]; then
	# A failed run must not replace the previous table -- not from a crashed/hung shard (the
	# existing row-count check below), and not from an engine error or a genuine check() failure
	# either, both of which are already folded into $status and $total_failures above by the time
	# this runs. A stale table costs some shard balance; a table measured from a run that never
	# finished cleanly could record a suite's cost from a truncated run, or none at all for a
	# suite that never got to print its own "-- suite  N ms" line.
	if [[ $status -ne 0 || $total_failures -gt 0 ]]; then
		echo "tools/test.sh --record-costs: this run did not pass (see above) — not overwriting $COST_FILE" >&2
	else
		tmp_costs="$work_dir/suite_costs.new"
		{
			printf '%s\n' "# Per-suite wall time in milliseconds, one row per tests/test_*.gd. _cost_of() in tools/test.sh"
			printf '%s\n' "# reads it to bin-pack the shards, locally and in CI's matrix; it is a planning hint, never a"
			printf '%s\n' "# gate -- every suite still runs wherever it lands, so a stale row costs some balance between"
			printf '%s\n' "# shards and no correctness. A suite missing a row here is planned at _cost_of()'s stated"
			printf '%s\n' "# default, with a warning, rather than silently dropped."
			printf '%s\n' "#"
			printf '%s\n' "# Refresh it with \`tools/test.sh --record-costs\`, which runs the full suite and rewrites this"
			printf '%s\n' "# file from that run's own \"-- suite  N ms\" lines -- never hand-edited, so the numbers come from"
			printf '%s\n' "# the runner rather than from anybody's memory."
			grep -hoE -- '-- test_[a-zA-Z_]+\.gd +[0-9]+ ms' "$work_dir"/shard-*.log \
				| sed -E 's/^-- +//; s/ +ms$//' \
				| awk '{ printf "%s %s\n", $1, $2 }' \
				| sort -u
		} > "$tmp_costs"

		got="$(grep -cE '^test_.*\.gd [0-9]+$' "$tmp_costs")"
		want="$(find "$PROJECT_DIR/tests" -maxdepth 1 -name 'test_*.gd' | wc -l | tr -d ' ')"
		if [[ "$got" -ne "$want" ]]; then
			echo "tools/test.sh --record-costs: got $got suite lines, expected $want — not overwriting $COST_FILE" >&2
			status=1
		else
			mv "$tmp_costs" "$COST_FILE"
			echo "wrote $got suite costs to $COST_FILE"
		fi
	fi
fi

echo ""
echo "$total_checks checks, $total_failures failures (across $SHARDS shards)"
if (( total_failures > 0 )); then
	status=1
fi
exit $status
