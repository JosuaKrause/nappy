# Puts back the files Godot's import pass rewrites. Not a script of its own -- `source` it, then
#
#   import_restore_arm PROJECT_DIR     # before the first import; records which files are clean
#   import_restore_run                 # on every exit, from the caller's own EXIT trap
#
# **Two files are rewritten as a side effect of opening the project.** The import pass makes the
# editor rewrite `project.godot` -- stripping every `;` comment, and on one occasion dropping
# `window/stretch/aspect="keep"` outright, which is load-bearing for the presentation -- and turns
# runs of spaces into tabs on whichever lines of `docs/ARCHITECTURE.md`'s file tree it feels like.
# Neither is a change anybody asked for, and both otherwise land in whatever commit comes next, or
# leave the main checkout dirty so that tools/land-prs.sh refuses to run. Every tool that runs
# `--import` (tools/check.sh, tools/test.sh, tools/cost-table.sh) sources this.
#
# **Only a file that was clean when `import_restore_arm` ran is restored.** Reverting a
# `project.godot` somebody had deliberately edited would delete real work to fix a whitespace bug,
# so a file that already carried changes is left alone and named instead.
#
# **The caller calls `import_restore_run` from its own EXIT trap** rather than this file setting
# one, because a script that already has an EXIT trap (a scratch directory to remove) would
# silently replace it, or be replaced by it. The restore then also happens on the failure paths --
# a run that fails is exactly when nobody thinks to look at the working tree.
#
# Bash 3.2-safe, like the rest of tools/.

IMPORT_RESTORE_FILES=(project.godot docs/ARCHITECTURE.md)
IMPORT_RESTORE_DIR=""
IMPORT_RESTORE_CLEAN=()
IMPORT_RESTORE_DIRTY=()

import_restore_arm() {
    local f
    IMPORT_RESTORE_DIR="$1"
    IMPORT_RESTORE_CLEAN=()
    IMPORT_RESTORE_DIRTY=()
    git -C "$IMPORT_RESTORE_DIR" rev-parse --git-dir >/dev/null 2>&1 || return 0
    for f in "${IMPORT_RESTORE_FILES[@]}"; do
        if [[ -z "$(git -C "$IMPORT_RESTORE_DIR" status --porcelain -- "$f")" ]]; then
            IMPORT_RESTORE_CLEAN+=("$f")
        else
            IMPORT_RESTORE_DIRTY+=("$f")
        fi
    done
}

import_restore_run() {
    local f
    [[ -n "$IMPORT_RESTORE_DIR" ]] || return 0
    for f in "${IMPORT_RESTORE_CLEAN[@]+"${IMPORT_RESTORE_CLEAN[@]}"}"; do
        if [[ -n "$(git -C "$IMPORT_RESTORE_DIR" status --porcelain -- "$f")" ]]; then
            if git -C "$IMPORT_RESTORE_DIR" checkout -- "$f"; then
                echo "reverted $f (rewritten by the import pass, not by you)" >&2
            else
                echo "WARNING: $f was rewritten by the import pass and could not be reverted" >&2
            fi
        fi
    done
    for f in "${IMPORT_RESTORE_DIRTY[@]+"${IMPORT_RESTORE_DIRTY[@]}"}"; do
        echo "note: $f already had changes before this ran, so it was left alone --" >&2
        echo "      check 'git diff $f' for lines the import pass added to yours" >&2
    done
}
