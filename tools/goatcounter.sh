#!/usr/bin/env bash
# Print the nappy- GoatCounter event counts as a per-day funnel, for a date range. This is the
# only way anything in this repository talks to GoatCounter's API -- never a hand-written curl or
# web request against it; a question this cannot yet answer gets a new flag here instead.
#
#   tools/goatcounter.sh                              # last 30 days, plain text
#   tools/goatcounter.sh --days 7
#   tools/goatcounter.sh --start 2026-09-01 --end 2026-09-15
#   tools/goatcounter.sh --json
#   tools/goatcounter.sh --raw                        # every path and count, unfiltered
#   tools/goatcounter.sh --check                      # is the key valid, and for what
#
# Needs GOATCOUNTER_TOKEN (a read-only API key from the GoatCounter site's own Settings -> API
# page), either exported in the environment or in a .env file at the repository root
# (GOATCOUNTER_TOKEN=...) -- never pass it as a flag, which would land in shell history and process
# listings. See tools/goatcounter.py for the .env format and the API details, and
# .claude/skills/using-tools/SKILL.md for what a cloud session needs allowed to reach it.
#
# --help/-h and rejection of anything this does not recognise happen here, before uv is needed --
# see .claude/skills/cli-tools.
set -euo pipefail

usage() {
	cat <<'EOF'
usage: tools/goatcounter.sh [--help|-h] [--days N] [--start DATE] [--end DATE]
                             [--prefix PREFIX] [--site URL] [--json] [--raw | --check]

Prints the nappy- GoatCounter event counts as a per-day funnel for a date range, reading the API
key from GOATCOUNTER_TOKEN (never accepted as a flag). Default range is the last 30 days; --days,
--start and --end (YYYY-MM-DD or RFC3339) narrow it. --json prints the result as JSON instead of
plain text. --raw prints every path and its count for the range, unfiltered by --prefix -- events
and page loads alike. --check calls GET /api/v0/me and reports only whether the key works and its
permissions, never the key. GoatCounter's API is reached only through this script; a question it
cannot yet answer gets a new flag here rather than a one-off curl or web request.

  tools/goatcounter.sh
  tools/goatcounter.sh --days 7
  tools/goatcounter.sh --start 2026-09-01 --end 2026-09-15
  tools/goatcounter.sh --json
  tools/goatcounter.sh --raw
  tools/goatcounter.sh --check
EOF
}

for arg in "$@"; do
	case "$arg" in
		--help|-h) usage; exit 0 ;;
	esac
done

for arg in "$@"; do
	case "$arg" in
		--days|--start|--end|--prefix|--site|--json|--raw|--check) ;;
		-*)
			echo "unknown option: $arg" >&2
			echo >&2
			usage >&2
			exit 1
			;;
	esac
done

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v uv >/dev/null 2>&1; then
	echo "uv not found -- see .claude/skills/python-tooling/SKILL.md" >&2
	exit 127
fi

cd "$PROJECT_DIR"
exec uv run --quiet python tools/goatcounter.py "$@"
