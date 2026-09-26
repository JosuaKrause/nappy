#!/usr/bin/env bash
# Makes a new name for a queue entry, a decision, a review item or a playtest, writes its file or
# folder with a heading and the date, and prints the name.
#
#   tools/new-name.sh todo "The brief is the coming day's"         # docs/todo/<name>/README.md
#   tools/new-name.sh decision --entry busy-badger "What was built" # docs/decisions/<entry>.md
#   tools/new-name.sh review --entry busy-badger "Walk day 6"       # docs/review/<entry>.md
#   tools/new-name.sh playtest "Stars for nerves"                   # docs/playtests/<name>.md
#
# A name is `<YYYY-MM-DD>-<adjective>-<animal>` (PLAYTEST-144: "Date file, 2 words"), spoken and
# linked as its two words, so sorting a folder puts the newest last and no two branches ever have
# to agree on a number. The words come from tools/names/adjectives.txt and tools/names/animals.txt;
# a pair is used once across docs/todo, docs/decisions, docs/review and docs/playtests, whatever
# the date, since two things spoken "busy-badger" would be one name for two things.
#
# A decision and a review item usually take the name of the entry they come from (`--entry`), as
# `<entry name>.md`, and `<entry name>-2.md` and on when that is taken. `--entry` accepts the full
# name, its two words, or an old entry's milestone number (M210).
#
# Bash 3.2-safe, like the rest of tools/ -- see tools/lint.sh's own header.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    cat <<'EOF'
usage: tools/new-name.sh [--help|-h] [--date YYYY-MM-DD] [--entry NAME] <kind> "<title>"

Makes a name <date>-<adjective>-<animal> unused across docs/todo, docs/decisions, docs/review and
docs/playtests, writes the thing it names with a heading and the date, and prints the name.

  kind        todo       docs/todo/<name>/README.md, the entry's context file
              decision   docs/decisions/<name>.md
              review     docs/review/<name>.md
              playtest   docs/playtests/<name>.md
  --entry N   decision and review only: take the name of entry N (its full name, its two words,
              or an old entry's milestone number such as M210) instead of a new one, with -2, -3
              and on when that file exists
  --date D    the date in the name and the heading (default: today)

  tools/new-name.sh todo "The brief is the coming day's"
  tools/new-name.sh review --entry busy-badger "Walk day 6 with the new brief"
EOF
}

fail_usage() {
    echo "$1" >&2
    echo >&2
    usage >&2
    exit 2
}

kind=""
title=""
entry=""
day=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --date)
            [[ $# -ge 2 ]] || fail_usage "--date needs a value"
            day="$2"; shift 2 ;;
        --entry)
            [[ $# -ge 2 ]] || fail_usage "--entry needs a value"
            entry="$2"; shift 2 ;;
        -*) fail_usage "unknown option: $1" ;;
        *)
            if [[ -z "$kind" ]]; then
                kind="$1"
            elif [[ -z "$title" ]]; then
                title="$1"
            else
                fail_usage "unexpected argument: $1 (the title goes in one pair of quotes)"
            fi
            shift ;;
    esac
done

case "$kind" in
    todo|decision|review|playtest) ;;
    "") fail_usage "no kind given" ;;
    *) fail_usage "unknown kind: $kind (todo, decision, review or playtest)" ;;
esac
[[ -n "$title" ]] || fail_usage "no title given"
if [[ -n "$entry" && "$kind" != decision && "$kind" != review ]]; then
    fail_usage "--entry is for a decision or a review item, not a $kind"
fi
if [[ -z "$day" ]]; then
    day="$(date +%Y-%m-%d)"
fi
[[ "$day" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || fail_usage "--date is not YYYY-MM-DD: $day"

adjectives="$root/tools/names/adjectives.txt"
animals="$root/tools/names/animals.txt"
for list in "$adjectives" "$animals"; do
    [[ -s "$list" ]] || { echo "new-name.sh: missing word list $list" >&2; exit 1; }
done

folders=("$root/docs/todo" "$root/docs/decisions" "$root/docs/review" "$root/docs/playtests")

# Every basename in the four folders, one per line, without .md.
existing_names() {
    local folder
    for folder in "${folders[@]}"; do
        [[ -d "$folder" ]] || continue
        ls -1 "$folder" 2>/dev/null
    done | sed 's/\.md$//'
}

# The names an entry can go by: the entry folders, and the decisions and review items named
# after one (a suffixed -2 is the same entry's second file, not a name of its own).
entry_names() {
    local folder
    for folder in "$root/docs/todo" "$root/docs/decisions" "$root/docs/review"; do
        [[ -d "$folder" ]] || continue
        ls -1 "$folder" 2>/dev/null
    done | sed 's/\.md$//'
}

pair_taken() {
    existing_names | grep -Eq "^[0-9]{4}-[0-9]{2}-[0-9]{2}-$1(-[0-9]+)?$"
}

# The first free <base>, <base>-2, <base>-3 ... in $1 (a folder), as a file <x>.md.
free_suffix() {
    local folder="$1" base="$2" candidate n=2
    candidate="$base"
    while [[ -e "$folder/$candidate.md" ]]; do
        candidate="$base-$n"
        n=$((n + 1))
    done
    printf '%s\n' "$candidate"
}

resolve_entry() {
    local want="$1" matches
    matches="$(entry_names | grep -E "^([0-9]{4}-[0-9]{2}-[0-9]{2}-)?$want$" | sort -u)"
    if [[ -z "$matches" ]]; then
        echo "new-name.sh: no entry named $want under docs/todo, docs/decisions or docs/review" >&2
        exit 1
    fi
    if [[ "$(printf '%s\n' "$matches" | wc -l | tr -d ' ')" -gt 1 ]]; then
        echo "new-name.sh: $want names more than one thing:" >&2
        printf '  %s\n' $matches >&2
        exit 1
    fi
    printf '%s\n' "$matches"
}

if [[ -n "$entry" ]]; then
    base="$(resolve_entry "$entry")" || exit 1
    words="${base#??????????-}"
else
    adjective_list=()
    while IFS= read -r w; do [[ -n "$w" ]] && adjective_list+=("$w"); done < "$adjectives"
    animal_list=()
    while IFS= read -r w; do [[ -n "$w" ]] && animal_list+=("$w"); done < "$animals"
    words=""
    tries=0
    while [[ $tries -lt 500 ]]; do
        candidate="${adjective_list[$((RANDOM % ${#adjective_list[@]}))]}-${animal_list[$((RANDOM % ${#animal_list[@]}))]}"
        if ! pair_taken "$candidate"; then
            words="$candidate"
            break
        fi
        tries=$((tries + 1))
    done
    if [[ -z "$words" ]]; then
        echo "new-name.sh: no free adjective-animal pair in 500 draws; add words to tools/names/" >&2
        exit 1
    fi
    base="$day-$words"
fi

case "$kind" in
    todo)
        dir="$root/docs/todo/$base"
        [[ -e "$dir" ]] && { echo "new-name.sh: $dir already exists" >&2; exit 1; }
        mkdir -p "$dir"
        printf '# %s — %s · filed %s\n\n' "$words" "$title" "$day" > "$dir/README.md"
        name="$base"
        written="docs/todo/$base/README.md"
        ;;
    decision|review)
        sub="decisions"
        [[ "$kind" == review ]] && sub="review"
        mkdir -p "$root/docs/$sub"
        name="$(free_suffix "$root/docs/$sub" "$base")"
        printf '# %s — %s · %s\n\n' "$words" "$title" "$day" > "$root/docs/$sub/$name.md"
        written="docs/$sub/$name.md"
        ;;
    playtest)
        mkdir -p "$root/docs/playtests"
        name="$base"
        [[ -e "$root/docs/playtests/$name.md" ]] && { echo "new-name.sh: $name.md already exists" >&2; exit 1; }
        printf '# Playtest %s — %s\n\n%s.\n' "$words" "$title" "$day" > "$root/docs/playtests/$name.md"
        written="docs/playtests/$name.md"
        ;;
esac

[[ -s "$root/$written" ]] || { echo "new-name.sh: $written was not written" >&2; exit 1; }
echo "$name"
echo "wrote $written" >&2
