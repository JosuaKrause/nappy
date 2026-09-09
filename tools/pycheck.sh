#!/usr/bin/env bash
# The gate for the Python under tools/: lint, format, types, and the two unittest files, in that
# order of cost. Everything runs through uv's locked environment (pyproject.toml, uv.lock,
# .python-version), so the answer is the same on a laptop and in CI.
#
#   tools/pycheck.sh          # everything
#   tools/pycheck.sh --fix    # let ruff rewrite what it can (imports, formatting) first
#
# One script the hook adapter is a partial exception to: tools/codex-hooks.py is checked here like
# everything else, but Codex runs it with the host's own `python3`, so it stays 3.9-compatible and
# pyproject.toml pins ruff's per-file target for it. Nothing here proves that compatibility; running
# the hook once under an older interpreter does.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1

if ! command -v uv >/dev/null 2>&1; then
    echo "uv is not on PATH; see .claude/skills/python-tooling/SKILL.md" >&2
    exit 127
fi

if [[ "${1:-}" == "--fix" ]]; then
    uv run ruff check --fix tools
    uv run ruff format tools
fi

status=0
run() {
    echo "== $*"
    if ! "$@"; then
        status=1
    fi
}

run uv run ruff check tools
run uv run ruff format --check tools
run uv run mypy
run uv run python tools/test_codex_hooks.py
run uv run python tools/test_clip.py

if [[ $status -ne 0 ]]; then
    echo
    echo "FAILED: see above" >&2
    exit 1
fi

echo
echo "OK"
