#!/usr/bin/env bash
# Import assets, then boot the project headless and fail on any script error.
#
# A fresh clone has no .godot/ (it is gitignored), so the `class_name` registry does not
# exist yet and every typed reference fails to parse. The import pass builds it.
set -uo pipefail

usage() {
    cat <<'EOF'
usage: tools/check.sh [--help|-h]

Imports assets, boots the project headless, and fails on any script error. Takes no arguments
of its own; point it at a different Godot binary with GODOT=/path/to/Godot.

  tools/check.sh
  GODOT=/path/to/Godot tools/check.sh
EOF
}

case "${1:-}" in
    --help|-h) usage; exit 0 ;;
esac

if [[ $# -gt 0 ]]; then
    echo "tools/check.sh takes no arguments; got: $*" >&2
    echo >&2
    usage >&2
    exit 2
fi

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT (override with GODOT=...)" >&2
    exit 127
fi

# The import pass rewrites `project.godot` and `docs/ARCHITECTURE.md`; tools/lib_import_restore.sh
# records which of the two were clean and puts them back from the EXIT trap, failure paths included.
# shellcheck source=tools/lib_import_restore.sh
source "$PROJECT_DIR/tools/lib_import_restore.sh"
import_restore_arm "$PROJECT_DIR"
trap import_restore_run EXIT

# Before the import pass, because the pages it writes are resources the import pass has to see:
# a tree whose art has changed carries stale atlases until something bakes them, and this is the
# gate a fresh clone and CI both go through. It prints one line and does nothing when the
# recorded source hashes still match.
echo "== atlases =="
if ! "$PROJECT_DIR/tools/bake-atlases.sh"; then
    echo >&2
    echo "FAILED: the atlas bake did not succeed" >&2
    exit 1
fi

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
