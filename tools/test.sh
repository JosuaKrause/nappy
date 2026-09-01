#!/usr/bin/env bash
# Run the headless test suite.
#
#   tools/test.sh                 everything — the only run a commit may rest on
#   tools/test.sh crowd balance   only the suites whose file name contains one of these
set -uo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT (override with GODOT=...)" >&2
    exit 127
fi

"$GODOT" --headless --import --path "$PROJECT_DIR" >/dev/null 2>&1
# Everything after `--` reaches the runner as OS.get_cmdline_user_args().
"$GODOT" --headless --path "$PROJECT_DIR" res://tests/tests.tscn -- "$@"
exit $?
