# Puts back two files that tools which run Godot on the project have left rewritten. Not a script of
# its own -- `source` it, then
#
#   import_restore_arm PROJECT_DIR     # before Godot first runs; records which files are clean
#   import_restore_run                 # on every exit, from the caller's own EXIT trap
#
# **What is known, and what is not.** `project.godot` and `docs/ARCHITECTURE.md` have been found
# rewritten in the main checkout after these tools ran: `docs/ARCHITECTURE.md` with runs of spaces
# in its file tree turned into tabs (three times on 2026-11-01), `project.godot` with its `;`
# comment lines stripped and, once, `window/stretch/aspect="keep"` dropped, a key the presentation
# depends on. The writer is **not identified**: a headless `--import` was run against a clean tree
# and did not reproduce the `ARCHITECTURE.md` rewrite, so nothing here says the import pass (or any
# one tool) does it. The editor rewriting `project.godot` when it loads the project is the part
# that is established (the stripped comments); the tab rewrite of `ARCHITECTURE.md` is only
# observed. The restore is a safeguard, wide because the writer is unknown: a rewrite otherwise
# lands in whatever commit comes next, or leaves the main checkout dirty so that tools/land-prs.sh
# refuses to run.
#
# **A file is reverted only when it was clean at `import_restore_arm` and its change at exit is
# the rewrite described above.** Tools run for minutes, and somebody may edit the same checkout in
# that time; that edit is not ours to delete. So at exit:
#   - `docs/ARCHITECTURE.md` is reverted when its diff is whitespace-only
#     (`git diff --ignore-all-space` finds nothing);
#   - `project.godot` is reverted when its diff only removes lines, and each removed line is a `;`
#     comment, a blank line, or the `window/stretch/aspect=` key;
#   - any other change to a file that was clean is kept, and one line on stderr says so.
# A file that already carried changes at arm time is left alone and named.
#
# **Who sources it.** tools/check.sh, tools/test.sh, tools/cost-table.sh, tools/bake-atlases.sh,
# tools/export-web.sh, tools/scene-draft.sh, tools/scene-recipes.sh, tools/record.sh,
# tools/trailer.sh and tools/shot.sh -- every shell script that runs Godot on the project and
# stays alive to run a trap afterwards. Not covered: tools/run.sh, whose ordinary launch ends in
# `exec` (no shell is left to run a restore; `./tools/check.sh` is the gate that does), and
# tools/split-scenes.py, a Python tool that calls Godot once to crop art and has no shell trap to
# carry the call.
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

# Succeeds when $1's change against HEAD is the rewrite this file exists to undo.
import_restore_is_rewrite() {
    local f="$1"
    case "$f" in
        docs/ARCHITECTURE.md)
            git -C "$IMPORT_RESTORE_DIR" diff --quiet --ignore-all-space -- "$f"
            ;;
        project.godot)
            git -C "$IMPORT_RESTORE_DIR" diff -U0 --no-color -- "$f" | awk '
                /^(\+\+\+|---)/ { next }
                /^\+/ { bad = 1 }
                /^-/ { if ($0 !~ /^-(;|$|window\/stretch\/aspect=)/) bad = 1 }
                END { exit bad }'
            ;;
        *) return 1 ;;
    esac
}

import_restore_run() {
    local f
    [[ -n "$IMPORT_RESTORE_DIR" ]] || return 0
    for f in "${IMPORT_RESTORE_CLEAN[@]+"${IMPORT_RESTORE_CLEAN[@]}"}"; do
        [[ -n "$(git -C "$IMPORT_RESTORE_DIR" status --porcelain -- "$f")" ]] || continue
        if ! import_restore_is_rewrite "$f"; then
            echo "note: $f changed during the run and is not the known rewrite, so it was kept" >&2
        elif git -C "$IMPORT_RESTORE_DIR" checkout -- "$f"; then
            echo "reverted $f (rewritten during the run, not by you)" >&2
        else
            echo "WARNING: $f was rewritten during the run and could not be reverted" >&2
        fi
    done
    for f in "${IMPORT_RESTORE_DIRTY[@]+"${IMPORT_RESTORE_DIRTY[@]}"}"; do
        echo "note: $f already had changes before this ran, so it was left alone --" >&2
        echo "      check 'git diff $f' for lines a tool added to yours" >&2
    done
}
