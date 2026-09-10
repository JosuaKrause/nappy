#!/usr/bin/env bash
# One command from a clean checkout to a debug Web build reachable in a browser.
#
#   tools/serve-web.sh [port]      # default port 8060
#
# A Godot Web export cannot be opened from file:// — the browser refuses the WASM and pack
# fetches — and nothing else in tools/ serves anything, so there was previously no way to run
# this project's web build locally at all, on any build type. That gap is almost certainly why a
# runtime error in the web build reached the live site before anyone met it (docs/playtests/PLAYTEST-25.md).
#
# A **separate** script from tools/export-web.sh rather than another mode of it: exporting and
# serving are two different jobs — export-web.sh's job is done the moment build/web/ exists, and
# this one's job is not done until something is listening on a port — and every other tool here
# (shot.sh, run.sh, telemetry.sh) is already one script per job rather than one script accreting
# every mode a task might need.
#
# **Exports debug**, not release: `tools/export-web.sh debug`, so `OS.is_debug_build()` is true in
# the served build and `?telemetry=1` — gated behind `DevFlags.enabled()` — actually answers.
# Serving a release export locally would defeat the whole point of a local dev server, since the
# flag would silently do nothing.
#
# **Fails loudly if the export failed**, rather than serving a stale build/web/ from a previous
# run. build/web/ is gitignored, so a stale directory left over from an earlier success is exactly
# the kind of thing that would otherwise look like this run succeeded too.
#
# **Serves plain HTTP with no special headers.** The tracked "Web" export preset is
# gl_compatibility with threads off (see tools/export-web.sh's own header comment), so Godot
# resolves the *_nothreads_* templates and the page needs no cross-origin-isolation (COOP/COEP)
# headers to run. If the preset ever gains threads, this script stops working and needs both of
# those headers added to whatever serves the result.
#
# **Prints the URL and stops — it does not open a browser itself.** A tool that launches a tab
# cannot be run from a rig or a CI step, the same reasoning tools/release.sh takes a literal
# `push` argument instead of prompting for one on a TTY nothing but a person has.
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$PROJECT_DIR/build/web"
PORT="${1:-8060}"

"$PROJECT_DIR/tools/export-web.sh" debug
status=$?
if [[ $status -ne 0 ]]; then
    echo "FAILED: debug export did not succeed — not serving a possibly-stale $OUT_DIR" >&2
    exit $status
fi

echo
echo "serving $OUT_DIR"
echo "open:  http://localhost:$PORT/index.html"
echo "(Ctrl-C to stop)"
cd "$OUT_DIR" && exec python3 -m http.server "$PORT"
