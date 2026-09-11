#!/usr/bin/env bash
# Convert a completed gameplay burst to an MP4 beside its source folder.
#
#   tools/clip.sh                         # convert every pending burst recursively
#   tools/clip.sh <burst-directory>       # explicit burst, including cancelled partial bursts
#   tools/clip.sh <burst-directory> <output.mp4>
#
# --help/-h and rejection of anything else this does not forward happen here, before uv is
# needed, so a runner with no uv still gets a straight answer -- see .claude/skills/cli-tools.
set -euo pipefail

usage() {
    cat <<'EOF'
usage: tools/clip.sh [--help|-h] [<burst-directory> [<output.mp4>]]

Converts a completed gameplay burst to an MP4 beside its source folder. With no arguments,
converts every pending burst recursively.

  tools/clip.sh
  tools/clip.sh <burst-directory>
  tools/clip.sh <burst-directory> <output.mp4>
EOF
}

for arg in "$@"; do
    case "$arg" in
        --help|-h) usage; exit 0 ;;
    esac
done

positional=0
for arg in "$@"; do
    case "$arg" in
        -*)
            echo "unknown option: $arg" >&2
            echo >&2
            usage >&2
            exit 1
            ;;
        *) positional=$(( positional + 1 )) ;;
    esac
done
if [[ "$positional" -gt 2 ]]; then
    echo "unexpected extra argument(s): $*" >&2
    echo >&2
    usage >&2
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if ! command -v uv >/dev/null 2>&1; then
    echo "uv not found -- see .claude/skills/python-tooling/SKILL.md" >&2
    exit 127
fi
exec uv run --quiet --project "$PROJECT_DIR" python "$PROJECT_DIR/tools/clip.py" "$@"
