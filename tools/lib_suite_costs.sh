#!/usr/bin/env bash
# The row rules for tests/suite_costs.txt, shared by the two tools that write that file from
# timings measured in CI: tools/ci-costs.sh (the committed file, from the logs of recent runs) and
# tools/ci-costs-merge.sh (the file CI's cache carries, from the run that just finished). Source
# it; it has no entry point of its own.
#
#   costs_timing_lines          stdin: any text holding "-- test_x.gd   N ms" runner lines (a job
#                               log with its "<job>\t<step>\t<timestamp> " prefixes, a shard's own
#                               output); stdout: one "test_x.gd N" row per line found
#   costs_merge TOOL ROOT OLD MEASURED OUT
#                               OLD is a cost file (comments allowed), MEASURED is "name ms" rows,
#                               one per suite, sorted by name; OUT is the cost file written.
#                               TOOL prefixes every message. Sets COSTS_MEASURED, COSTS_KEPT and
#                               COSTS_TOTAL (rows from MEASURED, rows kept from OLD, rows written)
#
# The row rules, stated once: a suite MEASURED never mentions keeps its row from OLD (a missing
# row costs more than a stale one, the rule tools/test.sh's _cost_of() states), a row whose suite
# is no longer under ROOT/tests/ is dropped from both, and each of the two is named on stderr.
# Nothing here drops a row silently.

# Byte order for every sort and join, so the rows come out in one order whatever the locale, the
# order tools/test.sh --record-costs writes them in.
export LC_ALL=C

# The same line tests/run_tests.gd prints and tools/test.sh --record-costs reads.
costs_timing_lines() {
    grep -hoE -- '-- test_[a-zA-Z0-9_]+\.gd +[0-9]+ ms' \
        | sed -E 's/^-- +//; s/ +ms$//' \
        | awk '{ printf "%s %s\n", $1, $2 }'
}

costs_header() {
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
}

costs_merge() {
    local tool="$1" root="$2" old="$3" measured="$4" out="$5"
    local dir
    dir="$(mktemp -d)" || return 1

    local old_rows="$dir/old_rows" new_rows="$dir/new_rows"
    awk '$1 !~ /^#/ && NF { print $1, $2 }' "$old" | sort > "$old_rows"
    sort "$measured" > "$new_rows"

    # A row for a suite that is no longer under tests/ (deleted, or split into others) is dropped
    # from both, and named on stderr, so the file holds one row per suite that exists.
    local gone="$dir/gone" rows still row name
    : > "$gone"
    for rows in "$new_rows" "$old_rows"; do
        still="$rows.still"
        : > "$still"
        while IFS= read -r row; do
            [[ -z "$row" ]] && continue
            name="${row%% *}"
            if [[ -f "$root/tests/$name" ]]; then
                printf '%s\n' "$row" >> "$still"
            else
                printf '%s\n' "$name" >> "$gone"
            fi
        done < "$rows"
        mv "$still" "$rows"
    done
    if [[ -s "$gone" ]]; then
        echo "$tool: dropping the row of each suite no longer under tests/:" >&2
        sort -u "$gone" | sed 's/^/    /' >&2
    fi

    # Old suites nothing measured keep their row and are named on stderr -- comm -23 wants both
    # inputs sorted by the compared field, which both files already are.
    local missing="$dir/missing"
    comm -23 <(cut -d' ' -f1 "$old_rows") <(cut -d' ' -f1 "$new_rows") > "$missing"
    COSTS_KEPT=$(wc -l < "$missing" | tr -d ' ')
    COSTS_MEASURED=$(wc -l < "$new_rows" | tr -d ' ')
    if [[ "$COSTS_KEPT" -gt 0 ]]; then
        echo "$tool: $COSTS_KEPT suite(s) not measured -- keeping their existing row:" >&2
        sed 's/^/    /' "$missing" >&2
    fi

    local kept="$dir/kept"
    : > "$kept"
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        grep -F -- "$name " "$old_rows" >> "$kept"
    done < "$missing"

    local merged="$dir/merged"
    cat "$new_rows" "$kept" | sort > "$merged"
    COSTS_TOTAL=$(wc -l < "$merged" | tr -d ' ')
    if [[ "$COSTS_TOTAL" -ne $(( COSTS_MEASURED + COSTS_KEPT )) ]]; then
        echo "$tool: internal row-count mismatch ($COSTS_TOTAL merged, $COSTS_MEASURED measured, $COSTS_KEPT kept) -- not writing anything" >&2
        rm -rf "$dir"
        return 1
    fi

    { costs_header; cat "$merged"; } > "$out"
    local written
    written="$(grep -cE '^test_.*\.gd [0-9]+$' "$out")"
    rm -rf "$dir"
    if [[ "$written" -ne "$COSTS_TOTAL" ]]; then
        echo "$tool: rendered $written suite rows, expected $COSTS_TOTAL -- not writing anything" >&2
        return 1
    fi
}
