#!/usr/bin/env bash
# Bake the atlas pages if the tree has moved since the last bake.
#
#   tools/bake-atlases.sh            # bake only if something changed, and say which
#   tools/bake-atlases.sh --check    # say whether a bake is needed; bake nothing; exit 1 if it is
#   tools/bake-atlases.sh --force    # bake regardless
#   tools/bake-atlases.sh --svg      # the custom local SVG bake -- never the release
#
# tools/check.sh, tools/test.sh, tools/run.sh and tools/export-web.sh all call this before they
# import, so a checkout whose art has changed bakes on the way into whatever was actually asked
# for. That is the whole of "baked on demand": nothing is committed and nothing has to be
# remembered.
#
# **The staleness question is answered without starting the engine.** assets/atlases/baked/
# bake_manifest.json records the mode and the SHA-256 of every input the last bake read -- each
# member picture, each illustrated PNG it used, the membership file and the two scripts that
# decide the layout -- so the check is one pass of hashlib over a few hundred files, tens of
# milliseconds, cheap enough to pay on every run of every tool. Launching Godot to ask would cost
# a second and a half and defeat the point.
#
# A mode mismatch is staleness like any other: a tree baked with --svg is stale for a default
# bake and the other way round, so the release build can never pick up a local SVG bake.
set -uo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$PROJECT_DIR/assets/atlases/baked/bake_manifest.json"

usage() {
    cat <<'EOF'
usage: tools/bake-atlases.sh [--help|-h] [--svg] [--check|--force]

Bakes assets/atlases/baked/ -- one PNG page per group in assets/atlases/membership.json, plus
regions.json and bake_manifest.json -- when the tree has moved since the last bake. With no
flags it compares the recorded source hashes and prints one line saying whether it baked.

  --svg     bake the authored SVG rasters alone, ignoring the illustrated PNGs. The custom
            local build; the release is always the default PNG bake, and a tree baked this way
            counts as stale for every tool that wants a release build.
  --check   report whether a bake is needed and exit non-zero if it is; bake nothing.
  --force   bake whether or not anything changed.

  tools/bake-atlases.sh
  tools/bake-atlases.sh --check
  GODOT=/path/to/Godot tools/bake-atlases.sh --svg
EOF
}

mode="png"
check_only=0
force=0

for arg in "$@"; do
    case "$arg" in
        --help|-h) usage; exit 0 ;;
    esac
done

for arg in "$@"; do
    case "$arg" in
        --svg)   mode="svg" ;;
        --check) check_only=1 ;;
        --force) force=1 ;;
        *)
            echo "tools/bake-atlases.sh: unknown argument '$arg'" >&2
            echo >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ $check_only -eq 1 && $force -eq 1 ]]; then
    echo "tools/bake-atlases.sh: --check and --force contradict each other" >&2
    echo >&2
    usage >&2
    exit 2
fi

# Prints one line of reason and exits 1 when a bake is needed, exits 0 when the outputs are
# current. Standard library only: this runs on every tool invocation, including on a CI runner
# with nothing installed but bash, python3 and the engine.
staleness_reason() {
    python3 - "$PROJECT_DIR" "$MANIFEST" "$mode" <<'PY'
import hashlib
import json
import os
import sys

root, manifest_path, wanted_mode = sys.argv[1], sys.argv[2], sys.argv[3]

if not os.path.exists(manifest_path):
    print("no bake manifest: nothing has been baked yet")
    sys.exit(1)
try:
    manifest = json.load(open(manifest_path, encoding="utf-8"))
except (OSError, ValueError) as error:
    print("unreadable bake manifest (%s)" % error)
    sys.exit(1)
if manifest.get("version") != 1:
    print("bake manifest is not version 1")
    sys.exit(1)
if manifest.get("mode") != wanted_mode:
    print("baked in %s mode, %s mode wanted" % (manifest.get("mode"), wanted_mode))
    sys.exit(1)
for output in manifest.get("outputs", []):
    if not os.path.exists(os.path.join(root, output)):
        print("missing output: %s" % output)
        sys.exit(1)

changed, missing = [], []
for relative, digest in sorted(manifest.get("inputs", {}).items()):
    path = os.path.join(root, relative)
    try:
        with open(path, "rb") as handle:
            actual = hashlib.sha256(handle.read()).hexdigest()
    except OSError:
        missing.append(relative)
        continue
    if actual != digest:
        changed.append(relative)

if missing or changed:
    parts = []
    if changed:
        parts.append("%d changed (%s)" % (len(changed), ", ".join(changed[:3])))
    if missing:
        parts.append("%d gone (%s)" % (len(missing), ", ".join(missing[:3])))
    print("sources moved: " + "; ".join(parts))
    sys.exit(1)
sys.exit(0)
PY
}

if ! command -v python3 >/dev/null 2>&1; then
    echo "tools/bake-atlases.sh needs python3 to compare the source hashes" >&2
    exit 127
fi

reason=""
if [[ $force -eq 1 ]]; then
    reason="--force"
else
    reason="$(staleness_reason)"
    fresh=$?
    if [[ $fresh -eq 0 ]]; then
        if [[ $check_only -eq 1 ]]; then
            echo "atlases: up to date ($mode mode)"
        else
            echo "atlases: up to date ($mode mode), nothing baked"
        fi
        exit 0
    fi
fi

if [[ $check_only -eq 1 ]]; then
    echo "atlases: STALE -- $reason" >&2
    echo "run tools/bake-atlases.sh to rebuild them" >&2
    exit 1
fi

if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT (override with GODOT=...)" >&2
    exit 127
fi

echo "atlases: baking ($mode mode) -- $reason"
bake_args=()
if [[ "$mode" == "svg" ]]; then
    bake_args+=(--svg)
fi
if ! "$GODOT" --headless --path "$PROJECT_DIR" --script tools/bake_atlases.gd -- \
        ${bake_args[@]+"${bake_args[@]}"}; then
    echo "FAILED: the atlas bake did not succeed" >&2
    exit 1
fi

# The bake is only done when its own manifest says the tree it just read is the tree on disk --
# a page written from a half-read source would otherwise look exactly like a fresh bake.
if ! staleness_reason >/dev/null; then
    echo "FAILED: the bake ran and its outputs are still stale" >&2
    staleness_reason >&2
    exit 1
fi
