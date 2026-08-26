#!/usr/bin/env bash
# Play the game. Everything you pass is forwarded to the game as a dev flag.
#
#   tools/run.sh                        # a fresh run
#   tools/run.sh --seed 12345           # a specific city
#   tools/run.sh --day 9 --overview     # look at act III from above
#
# See README.md for the full flag list.
set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT" >&2
    echo "install Godot 4.7, or point GODOT at your binary:" >&2
    echo "  GODOT=/path/to/Godot tools/run.sh" >&2
    exit 127
fi

# `--` separates Godot's own arguments from the game's.
exec "$GODOT" --path "$PROJECT_DIR" -- "$@"
