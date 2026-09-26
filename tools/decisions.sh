#!/usr/bin/env bash
# Lists and searches the records: the decisions, and with --in the queue entries, the review items
# or the playtests. There is no index checked in (an index every pull request edits is the same
# merge conflict the one-file-per-record layout exists to end), so this is how a record is found.
#
#   tools/decisions.sh                    # every decision, oldest first
#   tools/decisions.sh M129               # the decisions whose title names M129, then those whose text does
#   tools/decisions.sh spent park         # every word, whole and in any case
#   tools/decisions.sh --in todo roadblock
#
# A line is `<path>  <title>`, the title being the file's first heading (a todo entry's is its
# README.md's). Titles that match come first, then the records that match only in their text,
# each group oldest first -- a name starts with its date, and an old PLAYTEST-NN sorts before
# every dated playtest. A citation such as "`DECISIONS.md`, M129, a spent park is closed" in a
# code comment resolves with `tools/decisions.sh M129` and the title.
#
# Uses rg for the text search. Bash 3.2-safe, like the rest of tools/ -- see tools/lint.sh.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1

usage() {
    cat <<'EOF'
usage: tools/decisions.sh [--help|-h] [--in decisions|todo|review|playtests|all] [word...]

Lists the records under docs/decisions/ oldest first, one `<path>  <title>` line each. Given
words, lists the records whose name or title has every word (whole words, any case), then, under
a line `-- in the text:`, those that have every word only in their text. --in searches the queue
entries (docs/todo/), the review items (docs/review/), the playtests (docs/playtests/) or all four
instead of the decisions.

  tools/decisions.sh M129
  tools/decisions.sh spent park
  tools/decisions.sh --in todo roadblock
EOF
}

fail_usage() {
    echo "$1" >&2
    echo >&2
    usage >&2
    exit 2
}

scope="decisions"
words=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --in)
            [[ $# -ge 2 ]] || fail_usage "--in needs a value"
            scope="$2"; shift 2 ;;
        -*) fail_usage "unknown option: $1" ;;
        *) words+=("$1"); shift ;;
    esac
done
case "$scope" in
    decisions|todo|review|playtests) folders=("docs/$scope") ;;
    all) folders=(docs/decisions docs/todo docs/review docs/playtests) ;;
    *) fail_usage "unknown --in: $scope (decisions, todo, review, playtests or all)" ;;
esac
if [[ ${#words[@]} -gt 0 ]] && ! command -v rg >/dev/null 2>&1; then
    echo "decisions.sh: needs ripgrep (rg) on PATH for a search" >&2
    exit 1
fi

# One record per line, as `<sort key>\t<path>`: a decision, review item or playtest is a file; a
# todo entry is its folder.
records() {
    local folder path base key
    for folder in "${folders[@]}"; do
        [[ -d "$folder" ]] || continue
        for path in "$folder"/*; do
            [[ -e "$path" ]] || continue
            if [[ "$folder" == docs/todo ]]; then
                [[ -d "$path" ]] || continue
            else
                [[ "$path" == *.md ]] || continue
            fi
            base="${path##*/}"
            base="${base%.md}"
            if [[ "$base" =~ ^PLAYTEST-([0-9]+)$ ]]; then
                key="$(printf '0-%06d' "$((10#${BASH_REMATCH[1]}))")"
            else
                key="1-$base"
            fi
            printf '%s\t%s\n' "$key" "$path"
        done
    done | sort
}


# `<path>\t<title>` for every record, in records' order: the first heading of the file (a todo
# entry's README.md), or for a file with none -- a review item moved from the old single list --
# its first line, which leads with the task. One awk pass, since a process per file is seconds.
titled_records() {
    local listing
    listing="$(records | cut -f2)"
    [[ -n "$listing" ]] || return 0
    printf '%s\n' "$listing" | while IFS= read -r path; do
        if [[ -d "$path" ]]; then printf '%s/README.md\n' "$path"; else printf '%s\n' "$path"; fi
    done | tr '\n' '\0' | xargs -0 awk '
        function emit() { if (cur != "") { p = cur; sub(/\/README\.md$/, "", p); print p "\t" (t != "" ? t : f) } }
        FNR == 1 { emit(); cur = FILENAME; t = ""; f = "" }
        t == "" && /^#/ { t = $0; sub(/^#+[ \t]*/, "", t) }
        f == "" && NF { f = substr($0, 1, 100) }
        END { emit() }'
}

# Reads `<path>\t<title>` lines and keeps those whose name and title hold every word: a word of
# letters and digits must be a whole token, anything else a substring; case never matters.
title_filter() {
    # Through the environment: the BSD awk macOS ships refuses a newline in a -v value.
    WANT="$(printf '%s\n' "${words[@]}")" awk -F'\t' '
        BEGIN { n = split(tolower(ENVIRON["WANT"]), want, "\n"); if (want[n] == "") n-- }
        {
            name = $1; sub(/.*\//, "", name); sub(/\.md$/, "", name)
            hay = tolower(name " " $2)
            m = split(hay, tokens, /[^a-z0-9]+/)
            split("", have)
            for (i = 1; i <= m; i++) have[tokens[i]] = 1
            ok = 1
            for (i = 1; i <= n; i++) {
                if (want[i] ~ /^[a-z0-9]+$/) { if (!(want[i] in have)) ok = 0 }
                else if (index(hay, want[i]) == 0) ok = 0
            }
            if (ok) print
        }'
}

# Paths (files, or todo folders) whose text has every word, one per line.
text_matches() {
    local folder word found first=1 current=""
    for word in "${words[@]}"; do
        found="$(for folder in "${folders[@]}"; do
                    if [[ -d "$folder" ]]; then rg -l -i -w -F -- "$word" "$folder"; fi
                 done | sed -E 's#^(docs/todo/[^/]+)/.*#\1#' | sort -u)"
        if [[ $first -eq 1 ]]; then
            current="$found"
            first=0
        else
            current="$(comm -12 <(printf '%s\n' "$current") <(printf '%s\n' "$found"))"
        fi
    done
    printf '%s\n' "$current" | sed '/^$/d'
}

show() {
    awk -F'\t' '{ print $1 "  " $2 }'
}

if [[ ${#words[@]} -eq 0 ]]; then
    titled_records | show
    exit 0
fi

all="$(titled_records)"
titled="$(printf '%s\n' "$all" | title_filter)"
in_text="$(text_matches)"
rest="$(printf '%s\n' "$all" | SKIP="$(printf '%s\n' "$titled" | cut -f1)" KEEP="$in_text" awk -F'\t' '
    BEGIN { split(ENVIRON["SKIP"], s, "\n"); for (i in s) no[s[i]] = 1
            split(ENVIRON["KEEP"], k, "\n"); for (i in k) yes[k[i]] = 1 }
    ($1 in yes) && !($1 in no)')"

if [[ -z "$titled" && -z "$rest" ]]; then
    echo "no record under ${folders[*]} has every one of: ${words[*]}" >&2
    exit 1
fi
if [[ -n "$titled" ]]; then
    printf '%s\n' "$titled" | show
fi
if [[ -n "$rest" ]]; then
    echo "-- in the text:"
    printf '%s\n' "$rest" | show
fi
