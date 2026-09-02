#!/usr/bin/env bash
# Headless Web export, into build/web/ (gitignored).
#
#   tools/export-web.sh
#
# Uses the tracked "Web" preset in export_presets.cfg — gl_compatibility, threads off, so the
# templates Godot resolves are web_nothreads_debug.zip / web_nothreads_release.zip rather than
# the threaded pair, and GitHub Pages needs no cross-origin-isolation headers to serve the result.
set -uo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$PROJECT_DIR/build/web"

if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT (override with GODOT=...)" >&2
    exit 127
fi

mkdir -p "$OUT_DIR"

echo "== export (Web) =="
output=$("$GODOT" --headless --path "$PROJECT_DIR" --export-release "Web" "$OUT_DIR/index.html" 2>&1)
status=$?
echo "$output"

if grep -q "No export template found" <<<"$output"; then
    echo
    echo "FAILED: export templates for this Godot build are not installed." >&2
    echo "Install the 4.7.2 export templates that match the binary at \$GODOT --" >&2
    echo "  in the editor: Editor > Manage Export Templates" >&2
    echo "  or download the 4.7.2-stable set from https://godotengine.org/download/archive" >&2
    echo "into ~/Library/Application Support/Godot/export_templates/4.7.2.stable/" >&2
    exit 1
fi

if [[ $status -ne 0 ]]; then
    echo
    echo "FAILED: export exited $status" >&2
    exit 1
fi

echo
echo "OK: wrote $OUT_DIR"
