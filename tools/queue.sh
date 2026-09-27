#!/usr/bin/env bash
# Prints the queue in order, computed from the entries themselves: there is no shared order list to
# edit, so two pull requests collide on the queue only when they change the same entry.
#
#   tools/queue.sh               # every open entry, in order
#   tools/queue.sh --band now    # one band's entries, in the same order
#   tools/queue.sh --check       # the band lines' errors only, as tools/lint.sh reports them
#
# Every entry's docs/todo/<name>/README.md opens with its band line, then any `after:` lines, then a
# blank line and the entry's heading:
#
#   priority: next
#   after: 2026-09-09-M100
#
#   ## M56 — The resistance is noticed
#
# The band is one of now, next, later and parked (2026-09-26-brisk-heron, statements 13-14: "a
# priority system?" · "for "now" do reverse chronological maybe?"). An `after:` line names another
# entry's folder, in full, that this one truly waits on; an entry may carry several. An `after:`
# naming an entry that is closed -- no folder under docs/todo/, but a record under docs/decisions/
# named after it, `<name>.md` or `<name>-<n>.md` -- is a wait that is over: it holds nothing back
# and prints as `<name>, closed`, so the end-of-session pass sees the line and deletes it.
#
# The order: the bands in that sequence; within `now` the newest entry first, within every other
# band the oldest first, by the date the folder's name starts with. Entries filed on the same day
# sort by name, not by when they were filed: an old milestone number in number order and ahead of
# a named entry, named entries by their words (bytewise, LC_ALL=C, so every machine agrees), and
# `now` reverses that as well. An entry never prints before an open entry it waits on: one that
# would is held back to straight behind the last of them, wherever that is, and one already behind
# them stays where it is. A line is the band, the folder's name, the heading without its dated
# tail, and what the entry waits on.
#
# --check reports, as `<file>:<line>: <label>` lines and a non-zero exit, an entry with no
# `priority:` line opening its README.md, a band outside the set, an `after:` naming neither an
# open entry nor a closed one, an `after:` cycle, and a `priority:` or `after:` line anywhere but
# the opening block. tools/lint.sh runs it, so the band set and the rules live here only. Printing
# the queue refuses on the same errors.
#
# Bash 3.2-safe, like the rest of tools/ -- see tools/lint.sh's own header.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1

BANDS="now next later parked"

usage() {
    cat <<'EOF'
usage: tools/queue.sh [--help|-h] [--band now|next|later|parked] [--check]

Prints the open queue in order, from the band line every docs/todo/<entry>/README.md opens with
(`priority: now|next|later|parked`, then any `after: <entry folder name>` lines). The bands come
in that order; within `now` the newest entry first, within the others the oldest first, by the
date the folder's name starts with. Entries filed on the same day sort by name (old milestone
numbers in number order, then named entries by their words; reversed in `now`), not by filing
order. An entry never prints before an open entry its `after:` names: it is held back to straight
behind it. An `after:` naming a closed entry (a record under docs/decisions/ by that name) holds
nothing back and prints as `<name>, closed`. A line is the band, the entry's folder name, its
title and what it waits on.

  --band B   print only band B's entries, in the order the whole queue gives them
  --check    print nothing but the band lines' errors, as `<file>:<line>: <label>`, and exit
             non-zero if there is one (tools/lint.sh runs this)

  tools/queue.sh
  tools/queue.sh --band now
EOF
}

fail_usage() {
    echo "$1" >&2
    echo >&2
    usage >&2
    exit 2
}

band=""
check=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --band)
            [[ $# -ge 2 ]] || fail_usage "--band needs a value"
            band="$2"; shift 2 ;;
        --check) check=1; shift ;;
        -*) fail_usage "unknown option: $1" ;;
        *) fail_usage "unexpected argument: $1" ;;
    esac
done
if [[ -n "$band" ]]; then
    case " $BANDS " in
        *" $band "*) ;;
        *) fail_usage "unknown band: $band (now, next, later or parked)" ;;
    esac
fi
if [[ "$check" -eq 1 && -n "$band" ]]; then
    fail_usage "--check takes no --band: it checks every entry"
fi

[[ -d docs/todo ]] || { echo "queue.sh: no docs/todo/ under $root" >&2; exit 1; }

entries=()
missing=()
for dir in docs/todo/*/; do
    [[ -d "$dir" ]] || continue
    if [[ -f "${dir}README.md" ]]; then
        entries+=("${dir}README.md")
    else
        missing+=("${dir%/}")
    fi
done

# One awk pass over every README.md: each entry becomes a record
#   R <rank> <sort key> <name> <band> <after,after> <title>
# (tab-separated), and each broken rule an error line `E <file>:<line>: <label>`.
parse() {
    [[ ${#entries[@]} -gt 0 ]] || return 0
    BANDS="$BANDS" awk '
        BEGIN {
            OFS = "\t"
            n = split(ENVIRON["BANDS"], b, " ")
            for (i = 1; i <= n; i++) rank[b[i]] = i - 1
        }
        function finish() {
            if (file == "") return
            if (!has_priority) {
                print "E", file ":1: no `priority:` line opening the entry (its README.md starts with `priority: now|next|later|parked`)"
                band = "?"
            }
            print "R", (band in rank) ? rank[band] : 9, key, name, band, afters, title
        }
        FNR == 1 {
            finish()
            file = FILENAME
            name = file; sub(/^docs\/todo\//, "", name); sub(/\/README\.md$/, "", name)
            date = substr(name, 1, 10); rest = substr(name, 12)
            if (rest ~ /^M[0-9]+$/) rest = sprintf("M%08d", substr(rest, 2) + 0)
            key = date " " rest
            band = ""; afters = ""; title = ""; has_priority = 0; opening = 1
        }
        {
            line = $0
            sub(/\r$/, "", line)
            if (opening && FNR == 1 && line ~ /^priority:/) {
                band = line; sub(/^priority:[ \t]*/, "", band); sub(/[ \t]+$/, "", band)
                has_priority = 1
                if (!(band in rank))
                    print "E", file ":" FNR ": band outside now, next, later and parked: `" line "`"
                next
            }
            if (opening && FNR > 1 && has_priority && line ~ /^after:/) {
                target = line; sub(/^after:[ \t]*/, "", target); sub(/[ \t]+$/, "", target)
                if (target == "" || target ~ /[ \t]/)
                    print "E", file ":" FNR ": an `after:` line names one entry folder: `" line "`"
                else
                    afters = afters (afters == "" ? "" : ",") target ":" FNR
                next
            }
            opening = 0
            if (line ~ /^(priority|after):/)
                print "E", file ":" FNR ": a band line outside the opening block of the file: `" line "`"
            if (title == "" && line ~ /^#/) {
                title = line
                sub(/^#+[ \t]*/, "", title)
                # The dated tail new-name.sh and the old headings carry: `· filed 2026-09-27`.
                sub(/[ \t]+·[ \t]+[^·]*[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][^·]*$/, "", title)
            }
        }
        END { finish() }
    ' "${entries[@]}"
}

parsed="$(parse)"
errors="$(printf '%s\n' "$parsed" | awk -F'\t' '$1 == "E" { print $2 }')"
for dir in ${missing[@]+"${missing[@]}"}; do
    errors="$(printf '%s\n%s' "$errors" "$dir/README.md:1: an entry folder with no README.md, so no \`priority:\` line")"
done
records="$(printf '%s\n' "$parsed" | awk -F'\t' '$1 == "R"' | cut -f2-)"

# The base order: `now` newest first, the rest oldest first, bands in sequence.
base="$(
    printf '%s\n' "$records" | awk -F'\t' '$1 == 0' | LC_ALL=C sort -t "$(printf '\t')" -k2,2r
    printf '%s\n' "$records" | awk -F'\t' '$1 != 0 && NF' | LC_ALL=C sort -t "$(printf '\t')" -k1,1n -k2,2
)"

# The closed entries: a decision record named after an entry, `<name>.md` or `<name>-<n>.md`, is
# what closing it writes (new-name.sh decision --entry), so an `after:` naming one is a wait that is
# over rather than a typo.
closed="$(for f in docs/decisions/*.md; do
    [[ -e "$f" ]] || continue
    f="${f##*/}"; f="${f%.md}"
    printf '%s\n' "$f"
    [[ "$f" =~ ^(.*)-[0-9]+$ ]] && printf '%s\n' "${BASH_REMATCH[1]}"
done)"

# Holds every entry back until what it names has printed, reports the names that are neither an
# open entry nor a closed one and the cycles, and prints `<band>\t<name>\t<title>\t<waits>` in the
# final order, a closed wait shown as `<name>, closed`.
ordered="$(printf '%s\n' "$base" | CLOSED="$closed" awk -F'\t' '
    BEGIN { m = split(ENVIRON["CLOSED"], c, "\n"); for (i = 1; i <= m; i++) if (c[i] != "") done[c[i]] = 1 }
    NF {
        n++; name[n] = $3; band[n] = $4; title[n] = $6; after[n] = $5
        idx[$3] = n
    }
    END {
        for (i = 1; i <= n; i++) {
            deps[i] = 0
            if (after[i] == "") continue
            m = split(after[i], a, ",")
            shown = ""
            for (j = 1; j <= m; j++) {
                split(a[j], tl, ":")
                if (j == 1) first_line[i] = tl[2]
                if (!(tl[1] in idx) && (tl[1] in done)) {
                    shown = shown (shown == "" ? "" : ";") tl[1] ", closed"
                    continue
                }
                shown = shown (shown == "" ? "" : ";") tl[1]
                if (!(tl[1] in idx)) {
                    print "E\tdocs/todo/" name[i] "/README.md:" tl[2] ": `after: " tl[1] "` names no entry under docs/todo/ and no record under docs/decisions/"
                    continue
                }
                deps[i]++; dep[i, deps[i]] = idx[tl[1]]
            }
            after[i] = shown
        }
        placed_count = 0
        while (placed_count < n) {
            found = 0
            for (i = 1; i <= n; i++) {
                if (placed[i]) continue
                ready = 1
                for (j = 1; j <= deps[i]; j++) if (!placed[dep[i, j]]) { ready = 0; break }
                if (ready) { found = i; break }
            }
            if (!found) break
            placed[found] = 1; placed_count++
            print "O\t" band[found] "\t" name[found] "\t" title[found] "\t" after[found]
        }
        if (placed_count == n) exit
        # What is left waits on a cycle or is in one; strip the ones nothing left waits on until
        # only the cycle remains, and name it.
        do {
            changed = 0
            for (i = 1; i <= n; i++) {
                if (placed[i]) continue
                wanted = 0
                for (k = 1; k <= n && !wanted; k++) {
                    if (placed[k]) continue
                    for (j = 1; j <= deps[k]; j++) if (dep[k, j] == i) { wanted = 1; break }
                }
                if (!wanted) { placed[i] = 1; changed = 1 }
            }
        } while (changed)
        cycle = ""
        for (i = 1; i <= n; i++) if (!placed[i]) cycle = cycle (cycle == "" ? "" : ", ") name[i]
        for (i = 1; i <= n; i++)
            if (!placed[i])
                print "E\tdocs/todo/" name[i] "/README.md:" first_line[i] ": an `after:` cycle among " cycle
    }')"
errors="$(printf '%s\n%s\n' "$errors" "$(printf '%s\n' "$ordered" | awk -F'\t' '$1 == "E" { print $2 }')" | sed '/^$/d')"

if [[ "$check" -eq 1 ]]; then
    if [[ -n "$errors" ]]; then
        printf '%s\n' "$errors"
        exit 1
    fi
    exit 0
fi
if [[ -n "$errors" ]]; then
    printf '%s\n' "$errors" >&2
    echo >&2
    echo "queue.sh: the band lines above are broken, so there is no order to print" >&2
    exit 1
fi

printf '%s\n' "$ordered" | awk -F'\t' -v only="$band" '
    $1 == "O" && (only == "" || $2 == only) {
        n++; b[n] = $2; nm[n] = $3; t[n] = $4; a[n] = $5
        if (length($3) > width) width = length($3)
    }
    END {
        for (i = 1; i <= n; i++) {
            waits = ""
            if (a[i] != "") { waits = a[i]; gsub(/;/, "; ", waits); waits = "  (after " waits ")" }
            printf "%-6s  %-" width "s  %s%s\n", b[i], nm[i], t[i], waits
        }
    }'
