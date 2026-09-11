#!/usr/bin/env bash
# Bring real-world reference photos and videos into docs/reference/.
#   tools/reference.sh <file-or-directory>...
#   tools/reference.sh --force <file>          # overwrite one that is already there
#
# Everything is shrunk to fit inside 1280x720 with its aspect ratio kept, and every scrap of
# metadata is dropped. A video also loses its audio track and drops to 15fps. See
# tools/reference.py for what each of those is for, and .claude/skills/reference-photos for
# when a photo belongs in the repo at all.
#
# Videos need ffmpeg on PATH. Stills need nothing but the locked Python environment, which
# `uv run` builds from pyproject.toml on first use.
#
# --help/-h and rejection of anything this does not forward happen here, before uv is needed --
# see .claude/skills/cli-tools.
set -euo pipefail

usage() {
	cat <<'EOF'
usage: tools/reference.sh [--help|-h] [--force] <file-or-directory>...

Brings real-world reference photos and videos into docs/reference/, shrunk to fit inside
1280x720 with every scrap of metadata dropped. --force overwrites a file already there.

  tools/reference.sh <file-or-directory>...
  tools/reference.sh --force <file>
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
		--force) ;;
		-*)
			echo "unknown option: $arg" >&2
			echo >&2
			usage >&2
			exit 1
			;;
		*) positional=$(( positional + 1 )) ;;
	esac
done
if [[ "$positional" -eq 0 ]]; then
	echo "at least one file or directory is required" >&2
	echo >&2
	usage >&2
	exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v uv >/dev/null 2>&1; then
	echo "uv not found -- see .claude/skills/python-tooling/SKILL.md" >&2
	exit 127
fi

cd "$PROJECT_DIR"
exec uv run --quiet python tools/reference.py "$@"
