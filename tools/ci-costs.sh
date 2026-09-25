#!/usr/bin/env bash
# Refreshes tests/suite_costs.txt from CI's own timings instead of a local run.
#
#   tools/ci-costs.sh              # average the last 3 successful `ci` runs on main, write the file
#   tools/ci-costs.sh --runs 5     # average the last 5 instead
#   tools/ci-costs.sh --dry-run    # print the diff tools/ci-costs.sh would make; write nothing
#
# tools/test.sh --record-costs measures from a run on this one machine; this instead reads the
# same "-- suite  N ms" lines (tests/run_tests.gd's own "-- %-26s %7d ms" line) out of the shard
# job logs of the last few green `ci` runs on main via `gh`, and averages each suite across
# however many of those runs actually carry a measurement for it -- a shard that crashed or hung
# on one run still leaves the others. `gh run view <run-id> --job <job-id> --log` prefixes every
# line with "<job name>\t<step name>\t<timestamp> ", which is why the suite-line pattern below
# matches from "-- test_" onward rather than anchoring the start of the line.
#
# A suite the fetched logs never mention -- a new suite CI has not measured yet, or an old one
# whose every fetched run crashed before it printed -- keeps its row from the current file and is
# named on stderr, the same "missing row costs more than a stale one" rule tools/test.sh's own
# _cost_of() states. Nothing here ever drops a row silently.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1

COST_FILE="$root/tests/suite_costs.txt"
WORKFLOW="ci.yml"
BRANCH="main"
DEFAULT_RUNS=3

usage() {
    cat <<'EOF'
usage: tools/ci-costs.sh [--help|-h] [--runs N] [--dry-run]

Fetches the shard job logs of the last N (default 3) successful `ci` workflow runs on main with
`gh`, parses each suite's own "-- test_*.gd  N ms" timing line out of them, averages each suite
across the runs that measured it, and rewrites tests/suite_costs.txt in exactly the format
tools/test.sh --record-costs writes -- same header, same "name ms" rows, sorted the same way.

A suite missing from every fetched run keeps its existing row in tests/suite_costs.txt and is
named on stderr rather than dropped or reset to the default.

--dry-run fetches and averages the same way but prints the diff tools/ci-costs.sh would make
against tests/suite_costs.txt instead of writing it.

  tools/ci-costs.sh
  tools/ci-costs.sh --runs 5
  tools/ci-costs.sh --dry-run
EOF
}

runs="$DEFAULT_RUNS"
dry_run=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --dry-run) dry_run=1; shift ;;
        --runs)
            if [[ $# -lt 2 || -z "$2" ]]; then
                echo "tools/ci-costs.sh: --runs needs a value, e.g. --runs 5" >&2
                echo >&2
                usage >&2
                exit 2
            fi
            runs="$2"
            shift 2
            ;;
        *)
            echo "tools/ci-costs.sh: unknown argument '$1'" >&2
            echo >&2
            usage >&2
            exit 2
            ;;
    esac
done

if ! [[ "$runs" =~ ^[0-9]+$ ]] || [[ "$runs" -lt 1 ]]; then
    echo "tools/ci-costs.sh: --runs wants a positive integer (got '$runs')" >&2
    echo >&2
    usage >&2
    exit 2
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "tools/ci-costs.sh: gh not found on PATH" >&2
    exit 127
fi
if ! command -v jq >/dev/null 2>&1; then
    echo "tools/ci-costs.sh: jq not found on PATH" >&2
    exit 127
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

# ----------------------------------------------------------------- fetch ---

run_ids_file="$work_dir/run_ids"
if ! gh run list --workflow "$WORKFLOW" --branch "$BRANCH" --status success \
        --limit "$runs" --json databaseId -q '.[].databaseId' > "$run_ids_file" 2>"$work_dir/run_list.err"; then
    echo "tools/ci-costs.sh: gh run list failed:" >&2
    sed 's/^/    /' "$work_dir/run_list.err" >&2
    exit 1
fi

found_runs=$(wc -l < "$run_ids_file" | tr -d ' ')
if [[ "$found_runs" -eq 0 ]]; then
    echo "tools/ci-costs.sh: no successful '$WORKFLOW' runs found on $BRANCH" >&2
    exit 1
fi
if [[ "$found_runs" -lt "$runs" ]]; then
    echo "tools/ci-costs.sh: only $found_runs successful run(s) on $BRANCH, wanted $runs -- averaging over what exists" >&2
fi

all_lines="$work_dir/all_lines.txt"
: > "$all_lines"

jobs_seen=0
jobs_failed=0
while IFS= read -r run_id; do
    [[ -z "$run_id" ]] && continue
    job_ids_file="$work_dir/jobs_$run_id"
    if ! gh run view "$run_id" --json jobs \
            -q '.jobs[] | select(.name | startswith("shards")) | .databaseId' \
            > "$job_ids_file" 2>"$work_dir/jobs_$run_id.err"; then
        echo "tools/ci-costs.sh: could not list shard jobs for run $run_id:" >&2
        sed 's/^/    /' "$work_dir/jobs_$run_id.err" >&2
        continue
    fi
    while IFS= read -r job_id; do
        [[ -z "$job_id" ]] && continue
        jobs_seen=$(( jobs_seen + 1 ))
        log_file="$work_dir/log_${run_id}_${job_id}"
        if ! gh run view "$run_id" --job "$job_id" --log > "$log_file" 2>"$work_dir/log_${run_id}_${job_id}.err"; then
            jobs_failed=$(( jobs_failed + 1 ))
            echo "tools/ci-costs.sh: could not fetch the log for run $run_id job $job_id:" >&2
            sed 's/^/    /' "$work_dir/log_${run_id}_${job_id}.err" >&2
            continue
        fi
        # The same line tests/run_tests.gd prints and tools/test.sh --record-costs reads, just
        # with "<job>\t<step>\t<timestamp> " ahead of it here -- matched from "-- test_" on.
        grep -hoE -- '-- test_[a-zA-Z_]+\.gd +[0-9]+ ms' "$log_file" \
            | sed -E 's/^-- +//; s/ +ms$//' \
            | awk '{ printf "%s %s\n", $1, $2 }' \
            >> "$all_lines"
    done < "$job_ids_file"
done < "$run_ids_file"

if [[ "$jobs_seen" -eq 0 ]]; then
    echo "tools/ci-costs.sh: no shard jobs found across $found_runs run(s)" >&2
    exit 1
fi
if [[ ! -s "$all_lines" ]]; then
    echo "tools/ci-costs.sh: fetched $jobs_seen shard job log(s) but found no suite timing lines in any of them" >&2
    exit 1
fi

# --------------------------------------------------------------- average ---

# name -> round(mean(ms)), one row per suite the logs mentioned at least once.
averaged="$work_dir/averaged.txt"
awk '{ sum[$1] += $2; cnt[$1]++ } END { for (n in sum) printf "%s %d\n", n, int(sum[n] / cnt[n] + 0.5) }' \
    "$all_lines" | sort > "$averaged"

# The rows already on disk, same "name ms" shape, so the two files can be compared by name.
old_rows="$work_dir/old_rows.txt"
awk '$1 !~ /^#/ && NF { print $1, $2 }' "$COST_FILE" | sort > "$old_rows"

# Old suites the fetched logs never measured keep their row and are named on stderr -- comm -23
# wants both inputs sorted by the compared field, which both files already are (sort on "name ms"
# sorts by name first since name has no spaces).
missing_names="$work_dir/missing_names.txt"
comm -23 <(cut -d' ' -f1 "$old_rows") <(cut -d' ' -f1 "$averaged") > "$missing_names"
missing_count=$(wc -l < "$missing_names" | tr -d ' ')
if [[ "$missing_count" -gt 0 ]]; then
    echo "tools/ci-costs.sh: $missing_count suite(s) not seen in any fetched run's logs -- keeping their existing row:" >&2
    sed 's/^/    /' "$missing_names" >&2
fi

kept_rows="$work_dir/kept_rows.txt"
: > "$kept_rows"
while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    grep -F -- "$name " "$old_rows" >> "$kept_rows"
done < "$missing_names"

merged_rows="$work_dir/merged_rows.txt"
cat "$averaged" "$kept_rows" | sort > "$merged_rows"

merged_count=$(wc -l < "$merged_rows" | tr -d ' ')
old_count=$(wc -l < "$old_rows" | tr -d ' ')
new_count=$(wc -l < "$averaged" | tr -d ' ')
if [[ "$merged_count" -ne $(( new_count + missing_count )) ]]; then
    echo "tools/ci-costs.sh: internal row-count mismatch ($merged_count merged, $old_count old, $new_count averaged, $missing_count kept) -- not writing anything" >&2
    exit 1
fi

# --------------------------------------------------------------- render ---

rendered="$work_dir/suite_costs.new"
{
    printf '%s\n' "# Per-suite wall time in milliseconds, one row per tests/test_*.gd. _cost_of() in tools/test.sh"
    printf '%s\n' "# reads it to bin-pack the shards, locally and in CI's matrix; it is a planning hint, never a"
    printf '%s\n' "# gate -- every suite still runs wherever it lands, so a stale row costs some balance between"
    printf '%s\n' "# shards and no correctness. A suite missing a row here is planned at _cost_of()'s stated"
    printf '%s\n' "# default, with a warning, rather than silently dropped."
    printf '%s\n' "#"
    printf '%s\n' "# Refresh it with \`tools/test.sh --record-costs\`, which runs the full suite locally and"
    printf '%s\n' "# rewrites this file from that run's own \"-- suite  N ms\" lines, or with \`tools/ci-costs.sh\`,"
    printf '%s\n' "# which reads those same lines out of the last few green CI runs on main and averages them"
    printf '%s\n' "# instead -- either way never hand-edited, so the numbers come from a runner rather than from"
    printf '%s\n' "# anybody's memory."
    cat "$merged_rows"
} > "$rendered"

# --------------------------------------------------------------- verify before writing ---

rendered_row_count="$(grep -cE '^test_.*\.gd [0-9]+$' "$rendered")"
if [[ "$rendered_row_count" -ne "$merged_count" ]]; then
    echo "tools/ci-costs.sh: rendered $rendered_row_count suite rows, expected $merged_count -- not writing anything" >&2
    exit 1
fi

echo "tools/ci-costs.sh: averaged $new_count suite(s) from $jobs_seen shard log(s) across $found_runs run(s) ($jobs_failed log fetch failure(s)); $missing_count kept from the existing file; $rendered_row_count total" >&2

if [[ "$dry_run" -eq 1 ]]; then
    if diff -u "$COST_FILE" "$rendered" > "$work_dir/diff.txt"; then
        echo "tools/ci-costs.sh: --dry-run: no change from tests/suite_costs.txt"
    else
        cat "$work_dir/diff.txt"
    fi
    exit 0
fi

cp "$rendered" "$COST_FILE"

# And verify after, per CLAUDE.md's "an edit fails loudly": the file on disk now has exactly the
# row count just rendered, and the refresh sentence names both tools.
written_row_count="$(grep -cE '^test_.*\.gd [0-9]+$' "$COST_FILE")"
if [[ "$written_row_count" -ne "$merged_count" ]]; then
    echo "tools/ci-costs.sh: wrote $COST_FILE but it has $written_row_count suite rows, expected $merged_count" >&2
    exit 1
fi
if ! grep -qF 'tools/ci-costs.sh' "$COST_FILE"; then
    echo "tools/ci-costs.sh: wrote $COST_FILE but its header no longer names tools/ci-costs.sh" >&2
    exit 1
fi
echo "wrote $written_row_count suite costs to $COST_FILE"
