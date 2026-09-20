#!/usr/bin/env bash
# Regenerates docs/COSTS.md -- the checked-in survey of what every catalogue row costs, at fixed
# distances and in a real pass, computed from the same EventDef/EventInstance/Tuning code the
# game charges with. See that file's own header for what it records and PLAYTEST-115 for why it
# exists: "the 'survey' should happen automatically every time and should show up in the commit
# diff if it changes."
#
#   tools/cost-table.sh            # rewrite docs/COSTS.md
#   tools/cost-table.sh --check    # compare against the checked-in file; name every row and
#                                  # column that moved, old -> new; exit non-zero if it differs;
#                                  # write nothing
#
# Wired into the `gates` job in .github/workflows/ci.yml as --check, so a balance change that
# moved the table without regenerating it cannot merge.
set -uo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    cat <<'EOF'
usage: tools/cost-table.sh [--help|-h] [--check]

Runs a headless Godot scene (tools/cost_table.tscn) that walks the real event catalogue and the
real Tuning constants and writes docs/COSTS.md. With no flags it rewrites the file. --check
regenerates the table to memory, compares it against the checked-in file, and exits non-zero if
they differ, naming every row and column that moved, old -> new; writes nothing.

  tools/cost-table.sh
  tools/cost-table.sh --check
  GODOT=/path/to/Godot tools/cost-table.sh --check
EOF
}

for arg in "$@"; do
    case "$arg" in
        --help|-h) usage; exit 0 ;;
    esac
done

check_mode=0
for arg in "$@"; do
    case "$arg" in
        --check) check_mode=1 ;;
        *)
            echo "tools/cost-table.sh: unknown argument '$arg'" >&2
            echo >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT (override with GODOT=...)" >&2
    exit 127
fi

# The atlas bake and the import pass, the same preamble tools/test.sh runs before anything that
# needs EventCatalogue's class_name to resolve -- a fresh checkout's .godot/ cache does not exist
# until this runs once. No project.godot/ARCHITECTURE.md restore dance the way tools/check.sh
# does: this runs after check.sh in the `gates` job and in a developer's own loop, by which point
# .godot/ is already settled, and tools/test.sh's own import pass skips the same dance for the
# same reason.
"$PROJECT_DIR/tools/bake-atlases.sh" || exit 1
"$GODOT" --headless --import --path "$PROJECT_DIR" >/dev/null 2>&1

args=()
if [[ $check_mode -eq 1 ]]; then
    args+=(--check)
fi

# Combined stdout+stderr, classified the way tools/test.sh's run_one_process is: Godot can print
# an engine ERROR: and still exit 0, so the two are checked together rather than trusting the
# exit code alone.
scratch="$(mktemp)"
trap 'rm -f "$scratch"' EXIT
"$GODOT" --headless --path "$PROJECT_DIR" res://tools/cost_table.tscn -- \
        "${args[@]+"${args[@]}"}" 2>&1 | tee "$scratch"
status="${PIPESTATUS[0]}"
if grep -qE "SCRIPT ERROR|Parse Error|ERROR:" "$scratch"; then
    status=1
fi
exit "$status"
