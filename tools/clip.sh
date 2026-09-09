#!/usr/bin/env bash
# Convert a completed gameplay burst to an MP4 beside its source folder.
#
#   tools/clip.sh                         # newest completed burst
#   tools/clip.sh <burst-directory>       # explicit burst, including cancelled partial bursts
#   tools/clip.sh <burst-directory> <output.mp4>
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if ! command -v uv >/dev/null 2>&1; then
    echo "uv not found -- see .claude/skills/python-tooling/SKILL.md" >&2
    exit 127
fi
exec uv run --quiet --project "$PROJECT_DIR" python "$PROJECT_DIR/tools/clip.py" "$@"
