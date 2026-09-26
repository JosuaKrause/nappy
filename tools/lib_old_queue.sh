# Shared by tools/update-pr.sh and tools/land-prs.sh: whether a branch still edits the old
# single-file queue that main has as files. Not a script of its own -- `source` it, then run it
# inside the repository.
#
# Why a guard and not only the conflict: git merges an old-format edit into the new short
# docs/TODO.md, docs/DECISIONS.md or docs/REVIEW.md without a conflict when it touches lines the
# migration kept -- an insertion under `# Review` splices an old-format section into the new file,
# and the lint passes it. Such a branch is converted with tools/convert-queue-edits.py (the
# merging-main skill), never merged as it is.

OLD_QUEUE_FILES="docs/DECISIONS.md docs/TODO.md docs/REVIEW.md"

# True when docs/DECISIONS.md at revision $1 is the old single file: its third line is a record's
# `## ` heading rather than the short file's first paragraph. False when the revision has none.
queue_is_old() {
    local third
    third="$(git show "$1:docs/DECISIONS.md" 2>/dev/null | sed -n '3p')"
    [[ "$third" == "## "* ]]
}

# Prints the old queue files branch tip $1 edited since its merge base with main tip $2, one per
# line, when main has the queue as files and the merge base does not; prints nothing otherwise.
old_queue_edits() {
    local branch_tip="$1" main_tip="$2" base
    base="$(git merge-base "$branch_tip" "$main_tip" 2>/dev/null)" || return 0
    queue_is_old "$main_tip" && return 0
    queue_is_old "$base" || return 0
    # shellcheck disable=SC2086  # the list is three fixed paths with no spaces
    git diff --name-only "$base" "$branch_tip" -- $OLD_QUEUE_FILES
}

# The message both scripts print when old_queue_edits found something; $1 names the branch or PR,
# $2 is old_queue_edits' output.
old_queue_message() {
    printf '%s edits the old single-file queue, which main has as files:\n' "$1"
    printf '%s\n' "$2" | sed 's/^/  /'
    printf '%s\n' "Convert it instead of merging it as it is: in its worktree, git merge --no-ff --no-commit origin/main," \
        "then uv run python tools/convert-queue-edits.py, then the merging-main review, lint, commit and push."
}
