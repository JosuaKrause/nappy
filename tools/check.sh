#!/usr/bin/env bash
# Import assets, then boot the project headless and fail on any script error.
#
# A fresh clone has no .godot/ (it is gitignored), so the `class_name` registry does not
# exist yet and every typed reference fails to parse. The import pass builds it.
set -uo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT (override with GODOT=...)" >&2
    exit 127
fi

# **Two files are rewritten as a side effect of opening the project, and this puts them back.**
# The import pass makes the editor rewrite `project.godot` -- stripping every `;` comment, and on
# one occasion dropping `window/stretch/aspect="keep"` outright, which is load-bearing for the
# presentation -- and turns runs of spaces into tabs on whichever lines of `docs/ARCHITECTURE.md`'s
# file tree it feels like. Neither is a change anybody asked for, and both otherwise land in
# whatever commit comes next.
#
# **Only a file that was clean before this script ran is restored.** Reverting a `project.godot`
# somebody had deliberately edited would delete real work to fix a whitespace bug, so a file that
# already carried changes is left alone and named instead, which is the case where `git status`
# after is still yours to read.
#
# The restore runs from an EXIT trap so it also happens on the failure paths -- a check that fails
# is exactly when nobody thinks to look at the working tree.
SIDE_EFFECT_FILES=(project.godot docs/ARCHITECTURE.md)
WAS_CLEAN=()
WAS_DIRTY=()
if git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    for f in "${SIDE_EFFECT_FILES[@]}"; do
        if [[ -z "$(git -C "$PROJECT_DIR" status --porcelain -- "$f")" ]]; then
            WAS_CLEAN+=("$f")
        else
            WAS_DIRTY+=("$f")
        fi
    done
fi

restore_side_effects() {
    local f
    for f in "${WAS_CLEAN[@]+"${WAS_CLEAN[@]}"}"; do
        if [[ -n "$(git -C "$PROJECT_DIR" status --porcelain -- "$f")" ]]; then
            if git -C "$PROJECT_DIR" checkout -- "$f"; then
                echo "reverted $f (rewritten by the import pass, not by you)" >&2
            else
                echo "WARNING: $f was rewritten by the import pass and could not be reverted" >&2
            fi
        fi
    done
    for f in "${WAS_DIRTY[@]+"${WAS_DIRTY[@]}"}"; do
        echo "note: $f already had changes before this ran, so it was left alone --" >&2
        echo "      check 'git diff $f' for lines the import pass added to yours" >&2
    done
}
trap restore_side_effects EXIT

echo "== import =="
"$GODOT" --headless --import --path "$PROJECT_DIR" >/dev/null 2>&1
import_status=$?

echo "== boot =="
output=$("$GODOT" --headless --quit-after 60 --path "$PROJECT_DIR" 2>&1)
boot_status=$?
echo "$output"

if grep -qE "SCRIPT ERROR|Parse Error|ERROR:" <<<"$output"; then
    echo
    echo "FAILED: errors during boot" >&2
    exit 1
fi

if [[ $import_status -ne 0 ]]; then
    echo
    echo "FAILED: import pass exited $import_status" >&2
    exit 1
fi

if [[ $boot_status -ne 0 ]]; then
    echo
    echo "FAILED: boot exited $boot_status" >&2
    exit 1
fi

echo
echo "OK"
