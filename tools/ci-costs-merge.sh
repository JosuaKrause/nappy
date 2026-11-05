#!/usr/bin/env bash
# Folds the timings one CI run measured into the cost file that run planned from, for CI's cache.
#
#   tools/ci-costs-merge.sh --frozen plan.txt --measured shards.txt --out next.txt
#
# CI freezes the cost file once per run (the `plan` job) and every shard plans from that one copy;
# the `costs` job at the end of the run calls this to make the file the next run plans from.
# --measured is the shards' output put together: any text holding the runner's own
# "-- test_x.gd   N ms" lines, which are read out of it (tools/lib_suite_costs.sh).
#
# **A measured row is blended with the frozen one, half and half, rounded**, so one slow runner
# moves a suite's row halfway rather than all the way: the file follows a lasting change within a
# few runs and shrugs off a single bad one. A suite the frozen file has no row for takes its
# measurement as it stands.
#
# **Every suite under tests/ must be measured exactly once.** A suite missing or measured twice
# means a shard did not run what it was planned or the shards overlapped -- the plan the run used
# was not the plan it meant to -- and a file written from that would be worse than the one the
# cache already holds, so nothing is written and the exit is non-zero. The row rules after that
# (a row for a suite no longer under tests/ is dropped, named on stderr) are the ones
# tools/ci-costs.sh uses, from tools/lib_suite_costs.sh.
set -uo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=tools/lib_suite_costs.sh
source "$root/tools/lib_suite_costs.sh"

usage() {
    cat <<'EOF2'
usage: tools/ci-costs-merge.sh [--help|-h] --frozen FILE --measured FILE --out FILE

Reads the "-- test_x.gd   N ms" lines out of --measured, blends each with the same suite's row in
--frozen (the cost file the run planned from; half and half, rounded; a suite with no row there
keeps its measurement), and writes the result to --out in the format of tests/suite_costs.txt.
Fails, writing nothing, when a suite under tests/ is not measured exactly once.

  tools/ci-costs-merge.sh --frozen plan.txt --measured shards.txt --out next.txt
EOF2
}

frozen="" measured="" out=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --frozen|--measured|--out)
            if [[ $# -lt 2 || -z "$2" ]]; then
                echo "tools/ci-costs-merge.sh: $1 needs a value" >&2
                echo >&2
                usage >&2
                exit 2
            fi
            case "$1" in
                --frozen) frozen="$2" ;;
                --measured) measured="$2" ;;
                --out) out="$2" ;;
            esac
            shift 2
            ;;
        *)
            echo "tools/ci-costs-merge.sh: unknown argument '$1'" >&2
            echo >&2
            usage >&2
            exit 2
            ;;
    esac
done
if [[ -z "$frozen" || -z "$measured" || -z "$out" ]]; then
    echo "tools/ci-costs-merge.sh: --frozen, --measured and --out are all required" >&2
    echo >&2
    usage >&2
    exit 2
fi
for f in "$frozen" "$measured"; do
    if [[ ! -f "$f" ]]; then
        echo "tools/ci-costs-merge.sh: no such file: $f" >&2
        exit 1
    fi
done

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

costs_timing_lines < "$measured" | sort > "$work_dir/rows"

dupes="$(cut -d' ' -f1 "$work_dir/rows" | uniq -d)"
if [[ -n "$dupes" ]]; then
    echo "tools/ci-costs-merge.sh: suites measured more than once -- the shards overlapped:" >&2
    printf '%s\n' "$dupes" | sed 's/^/    /' >&2
    exit 1
fi
(cd "$root/tests" && ls test_*.gd) | sort > "$work_dir/on_disk"
unmeasured="$(comm -23 "$work_dir/on_disk" <(cut -d' ' -f1 "$work_dir/rows"))"
if [[ -n "$unmeasured" ]]; then
    echo "tools/ci-costs-merge.sh: suites under tests/ that no shard measured -- a shard did not run its whole plan:" >&2
    printf '%s\n' "$unmeasured" | sed 's/^/    /' >&2
    exit 1
fi

awk '$1 !~ /^#/ && NF { print $1, $2 }' "$frozen" | sort > "$work_dir/old"
join -a 1 -e - -o 0,1.2,2.2 "$work_dir/rows" "$work_dir/old" \
    | awk '{ ms = ($3 == "-") ? $2 : int(($2 + $3) / 2 + 0.5); printf "%s %d\n", $1, ms }' \
    > "$work_dir/blended"

if ! costs_merge "tools/ci-costs-merge.sh" "$root" "$frozen" "$work_dir/blended" "$work_dir/next"; then
    exit 1
fi
cp "$work_dir/next" "$out" || exit 1
echo "tools/ci-costs-merge.sh: wrote $COSTS_TOTAL suite costs ($COSTS_MEASURED blended from this run, $COSTS_KEPT kept) to $out" >&2
