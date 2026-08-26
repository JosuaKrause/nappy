#!/usr/bin/env bash
# Run the headless test suite.
set -uo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$GODOT" --headless --import --path "$PROJECT_DIR" >/dev/null 2>&1
"$GODOT" --headless --path "$PROJECT_DIR" res://tests/tests.tscn
exit $?
