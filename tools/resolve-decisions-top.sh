#!/usr/bin/env bash
# Resolves the one merge-conflict shape merging origin/main into a PR branch produces in
# docs/DECISIONS.md almost every time: both sides insert a new `## ...` section directly under
# the file's `# Decisions` heading, from an empty merge base. The resolution is always the same:
# keep both sections, the branch's own ("ours") above main's ("theirs"), one blank line between
# them, then `git diff --check`. See .claude/skills/merging-main/SKILL.md for what this script does not
# replace: semantic review still applies to every merge, mechanical conflict or not.
#
# Run inside a checkout already mid-merge (`git merge --no-ff --no-commit origin/main`):
#
#   tools/resolve-decisions-top.sh
#
# Acts only on docs/DECISIONS.md, and only when its conflict is exactly that one shape: one hunk,
# an empty diff3/zdiff3 base, sitting directly under `# Decisions`, each side starting with a
# `## ` heading. Anything else -- more than one hunk, a non-empty base, a hunk elsewhere -- it
# refuses with a clear message and changes nothing.
#
# Never commits, never touches a file other than docs/DECISIONS.md, and `git add`s that file only
# once `git diff --check` on the resolved content passes.
#
# Bash 3.2-safe, like the rest of tools/ -- see tools/lint.sh's own header.
set -uo pipefail

usage() {
    cat <<'EOF'
usage: tools/resolve-decisions-top.sh [--help|-h]

Resolves docs/DECISIONS.md's merge conflict when, and only when, it is exactly one hunk with an
empty diff3/zdiff3 base, sitting directly under the file's `# Decisions` heading, with each side
starting with a `## ` heading. Writes ours (the branch) then theirs (main) with exactly one blank
line between them, prints both sides' headings and the resulting top-of-file headings, runs
`git diff --check`, and `git add`s the file only if that passes. Refuses and changes nothing for
any other shape -- the merging-main skill's three-way review applies there. Takes no arguments
besides --help/-h. Run it mid-merge, after `git merge --no-ff --no-commit origin/main`.

  tools/resolve-decisions-top.sh
EOF
}

for arg in "$@"; do
    case "$arg" in
        -h|--help) usage; exit 0 ;;
        *)         echo "unknown argument: $arg" >&2; echo >&2; usage >&2; exit 2 ;;
    esac
done

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1
file="docs/DECISIONS.md"

refuse() {
    echo "refusing: $*" >&2
    echo "docs/DECISIONS.md is unchanged; the merging-main skill's three-way review applies." >&2
    exit 1
}

git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repository" >&2; exit 1; }
git rev-parse -q --verify MERGE_HEAD >/dev/null || refuse \
    "no merge in progress (no MERGE_HEAD) -- run this after git merge --no-ff --no-commit origin/main"
[[ -f "$file" ]] || refuse "$file does not exist in this checkout"

unmerged="$(git diff --name-only --diff-filter=U -- "$file" 2>/dev/null)"
[[ "$unmerged" == "$file" ]] || refuse \
    "$file has no unresolved conflict (git diff --name-only --diff-filter=U does not list it)"

# ---- assert the anchors before writing anything --------------------------------------------
n_start=$(grep -c '^<<<<<<< ' "$file")
n_base=$(grep -c '^||||||| ' "$file")
n_sep=$(grep -c '^=======$' "$file")
n_end=$(grep -c '^>>>>>>> ' "$file")

if [[ "$n_start" -ne 1 || "$n_sep" -ne 1 || "$n_end" -ne 1 ]]; then
    refuse "$file's conflict is not exactly one hunk (found $n_start '<<<<<<<', $n_sep '======='," \
        "$n_end '>>>>>>>' -- want exactly 1 of each)"
fi
if [[ "$n_base" -ne 1 ]]; then
    refuse "$file's conflict has no single diff3/zdiff3 base section (found $n_base '|||||||' line(s)" \
        "-- want exactly 1; if this is 0, set merge.conflictstyle to diff3 or zdiff3 and redo the merge)"
fi

start_line=$(grep -n '^<<<<<<< ' "$file" | head -1 | cut -d: -f1)
base_line=$(grep -n '^||||||| ' "$file" | head -1 | cut -d: -f1)
sep_line=$(grep -n '^=======$' "$file" | head -1 | cut -d: -f1)
end_line=$(grep -n '^>>>>>>> ' "$file" | head -1 | cut -d: -f1)

if ! [[ "$start_line" -lt "$base_line" && "$base_line" -lt "$sep_line" && "$sep_line" -lt "$end_line" ]]; then
    refuse "$file's conflict markers are out of order" \
        "(<<<<<<< $start_line, ||||||| $base_line, ======= $sep_line, >>>>>>> $end_line)"
fi

base_len=$(( sep_line - base_line - 1 ))
if [[ "$base_len" -ne 0 ]]; then
    refuse "$file's conflict base is not empty ($base_len line(s) between ||||||| and =======)" \
        "-- this script only resolves a two-sided insertion from an empty base"
fi

ours_first=$(( start_line + 1 ))
ours_last=$(( base_line - 1 ))
theirs_first=$(( sep_line + 1 ))
theirs_last=$(( end_line - 1 ))
[[ "$ours_first" -le "$ours_last" ]]     || refuse "$file's branch side of the conflict is empty"
[[ "$theirs_first" -le "$theirs_last" ]] || refuse "$file's main side of the conflict is empty"

head1=$(sed -n '1p' "$file")
[[ "$head1" == "# Decisions" ]] || refuse "$file's first line is not '# Decisions' (found: $head1)"
if [[ "$start_line" -gt 2 ]]; then
    between=$(sed -n "2,$(( start_line - 1 ))p" "$file")
    if printf '%s\n' "$between" | grep -q '[^[:space:]]'; then
        refuse "$file's conflict hunk does not sit directly under # Decisions" \
            "(non-blank content between the heading and the hunk)"
    fi
fi

ours_heading=$(sed -n "${ours_first}p" "$file")
theirs_heading=$(sed -n "${theirs_first}p" "$file")
case "$ours_heading" in
    "## "*) ;;
    *) refuse "the branch side does not start with a '## ' heading (found: $ours_heading)" ;;
esac
case "$theirs_heading" in
    "## "*) ;;
    *) refuse "the main side does not start with a '## ' heading (found: $theirs_heading)" ;;
esac

# ---- the shape matches; write the resolution ------------------------------------------------
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

sed -n "${ours_first},${ours_last}p" "$file" > "$work_dir/ours"
sed -n "${theirs_first},${theirs_last}p" "$file" > "$work_dir/theirs"

# Strip trailing blank lines from ours and leading blank lines from theirs, so exactly one blank
# line ends up between them regardless of what sat at the boundary either side wrote.
awk 'BEGIN{n=0} {a[++n]=$0} END{last=n; while (last>0 && a[last] ~ /^[ \t]*$/) last--
    for (i=1;i<=last;i++) print a[i]}' "$work_dir/ours" > "$work_dir/ours.trim"
awk 'BEGIN{started=0} {if (!started && $0 ~ /^[ \t]*$/) next; started=1; print}' \
    "$work_dir/theirs" > "$work_dir/theirs.trim"

cp "$file" "$work_dir/original-conflicted"

{
    sed -n "1,$(( start_line - 1 ))p" "$file"
    cat "$work_dir/ours.trim"
    echo
    cat "$work_dir/theirs.trim"
    sed -n "$(( end_line + 1 )),\$p" "$file"
} > "$work_dir/resolved"

# Verify before it ever touches the working tree: no marker survived the rewrite.
if grep -q '^<<<<<<< ' "$work_dir/resolved" || grep -q '^||||||| ' "$work_dir/resolved" \
    || grep -q '^=======$' "$work_dir/resolved" || grep -q '^>>>>>>> ' "$work_dir/resolved"; then
    refuse "internal error: the resolved content still has a conflict marker in it -- nothing written"
fi

cp "$work_dir/resolved" "$file"

# Verify after: the anchor that must have survived the write.
if [[ "$(sed -n '1p' "$file")" != "# Decisions" ]]; then
    cp "$work_dir/original-conflicted" "$file"
    refuse "internal error: # Decisions heading lost after write -- restored the original conflict"
fi

echo "branch (ours):   $ours_heading"
echo "main (theirs):   $theirs_heading"
echo "top of file now:"
grep -n -m3 '^## ' "$file" | sed 's/^/  /'

if ! git diff --check -- "$file"; then
    cp "$work_dir/original-conflicted" "$file"
    refuse "git diff --check failed on the resolved content -- restored the original conflict; nothing added"
fi

git add -- "$file"
echo "docs/DECISIONS.md resolved and staged; git diff --check passed."
