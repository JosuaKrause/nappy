#!/usr/bin/env bash
# Headless Web export, into build/web/ (gitignored).
#
#   tools/export-web.sh          # release -- what .github/workflows/deploy.yml publishes
#   tools/export-web.sh debug    # debug -- OS.is_debug_build() is true in the result, so
#                                # ?telemetry=1 answers; see tools/serve-web.sh, which exports
#                                # this way and serves the result
#
# Uses the tracked "Web" preset in export_presets.cfg — gl_compatibility, threads off, so the
# templates Godot resolves are web_nothreads_debug.zip / web_nothreads_release.zip rather than
# the threaded pair, and GitHub Pages needs no cross-origin-isolation headers to serve the result.
#
# RELEASE_TAG=<tag> tools/export-web.sh   # names build/web/<tag>/, default "dev"
#
# index.js, index.wasm and index.pck move into build/web/$RELEASE_TAG/ after the export, and
# index.html is rewritten to name them there — see the export-versioning step below for why.
# .github/workflows/deploy.yml sets RELEASE_TAG to the pushed tag; a local export has none, so
# it falls back to "dev", which is also what tools/serve-web.sh gets since it calls this script
# with no RELEASE_TAG of its own.
set -uo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$PROJECT_DIR/build/web"

MODE="${1:-release}"
case "$MODE" in
    release) EXPORT_FLAG="--export-release" ;;
    debug)   EXPORT_FLAG="--export-debug" ;;
    *)
        echo "usage: tools/export-web.sh [release|debug]" >&2
        exit 2
        ;;
esac

if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT (override with GODOT=...)" >&2
    exit 127
fi

mkdir -p "$OUT_DIR"
# The export's own output is not a resource. Without this, the next import pass finds the
# exported icons under build/web/ and writes .import sidecars beside them — Godot importing its own
# export — so the ignore marker is written every time rather than trusted to survive a clean.
touch "$PROJECT_DIR/build/.gdignore"

echo "== export (Web, $MODE) =="
output=$("$GODOT" --headless --path "$PROJECT_DIR" "$EXPORT_FLAG" "Web" "$OUT_DIR/index.html" 2>&1)
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

# GitHub Pages sends Cache-Control: max-age=600 on every file with no way to turn it off from
# this repo, and index.html/.js/.wasm/.pck all keep fixed names between releases, so each file's
# ten minutes starts independently and a reload mid-window can pair a fresh index.html against a
# previous release's index.pck — not stale, mixed (docs/PLAYTEST-27.md finding 1). The fix has
# to be in the names: index.js, index.wasm and index.pck move into a directory named for the
# release, and index.html stays at the root and unversioned, since it is 6 KB and always fetched
# before anything else names a path.
#
# The engine builds the wasm and pack URLs by concatenating GODOT_CONFIG.executable with .wasm
# and .pck (Engine.load and Engine.prototype.startGame in the exported index.js), so a path
# prefix on "executable" carries both. The same loadPath also names the two audio-worklet files
# — GodotConfig.locate_file("godot.audio.worklet.js") and the .position. variant, read the
# instant audio initialises — so those move too, or the first sound the game tries to play
# 404s. index.js is a third file the same query would go stale on, so it moves as well. The
# small favicon/splash images (index.png, index.icon.png, index.apple-touch-icon.png) are plain
# hrefs Godot's own shell writes and never touch GODOT_CONFIG, so they stay at the root.
RELEASE_TAG="${RELEASE_TAG:-dev}"
VERSIONED_DIR="$OUT_DIR/$RELEASE_TAG"

echo
echo "== version index.js/.wasm/.pck under $RELEASE_TAG/ =="

# Drop any subdirectory a previous local run left under a different tag, so build/web/ never
# accumulates more than the current export's files.
find "$OUT_DIR" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
mkdir -p "$VERSIONED_DIR"

for f in index.js index.wasm index.pck index.audio.worklet.js index.audio.position.worklet.js; do
    if [[ ! -f "$OUT_DIR/$f" ]]; then
        echo "FAILED: expected $OUT_DIR/$f, the export did not write it" >&2
        exit 1
    fi
    mv "$OUT_DIR/$f" "$VERSIONED_DIR/$f"
done

# Every anchor below is asserted to occur exactly once before it is touched, so a future Godot
# shell change that moves or renames one of these fails the export loudly rather than shipping a
# page that quietly points at the wrong place.
python3 - "$OUT_DIR/index.html" "$RELEASE_TAG" <<'PY'
import sys

path, tag = sys.argv[1], sys.argv[2]
html = open(path, encoding="utf-8").read()


def replace_once(html, old, new, label):
    count = html.count(old)
    if count != 1:
        sys.exit(f"FAILED: expected exactly one {label}, found {count}")
    return html.replace(old, new, 1)


html = replace_once(html, '<script src="index.js">', f'<script src="{tag}/index.js">', 'index.js script tag')
html = replace_once(html, '"executable":"index"', f'"executable":"{tag}/index"', 'GODOT_CONFIG.executable')
html = replace_once(html, '"index.pck"', f'"{tag}/index.pck"', 'fileSizes index.pck key')
html = replace_once(html, '"index.wasm"', f'"{tag}/index.wasm"', 'fileSizes index.wasm key')

# Godot's own shell writes <title>Nappy</title> before html/head_include's longer, descriptive
# one is appended (export_presets.cfg) -- two <title> elements, so a scraper reading the first
# gets the short one (docs/PLAYTEST-27.md finding 5). Removed here, from the shell's side,
# rather than from head_include, since head_include's title is the one meant to survive.
html = replace_once(html, '<title>Nappy</title>', '', 'Godot shell <title>Nappy</title>')

open(path, "w", encoding="utf-8").write(html)
PY
status=$?
if [[ $status -ne 0 ]]; then
    echo "FAILED: index.html post-processing did not succeed" >&2
    exit 1
fi

echo
echo "OK: wrote $OUT_DIR ($RELEASE_TAG/index.js, $RELEASE_TAG/index.wasm, $RELEASE_TAG/index.pck)"
