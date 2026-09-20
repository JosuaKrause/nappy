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
# A page no current group names counts as staleness too. Folding one group into another leaves
# its page on disk, where every input hash still agrees and nothing says otherwise -- and because
# assets/atlases/baked/ is an imported folder, the engine imports that page and exports it into
# the pack. Reporting it here is what makes every tool that calls this rebake, and the bake is
# what deletes it.
#
# A mode mismatch is staleness like any other: a tree baked with --svg is stale for a default
# bake and the other way round, so the release build can never pick up a local SVG bake.
#
# **A bake that succeeds can still make the engine complain.** This runs Godot with --script,
# which still loads every autoload, and their dependency chain reaches picture preload()s; on a
# checkout whose import cache (.godot/imported/) has not seen a picture yet -- a fresh clone or
# worktree, or a pull that added one -- that load fails and the engine prints its own ERROR: and
# SCRIPT ERROR: lines for it, right after a bake that wrote every page correctly (the bake reads
# its sources itself and never through that cache). When that happens this script says so in
# plain words after the engine's own lines, which stay visible, and still exits 0 -- every caller
# runs this before its own import pass on purpose, on a fresh clone included, so failing here
# would break all of them for a condition tools/check.sh already repairs. A real bake failure
# (the engine process itself failing, or its outputs still stale afterwards) keeps its own
# message and its non-zero exit, and this explanation is never printed over it.
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
  --check   report whether a bake is needed and exit non-zero if it is; bake nothing. A page
            left behind by a group that no longer exists counts as needing one, and the bake
            is what removes it.
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
baked = os.path.dirname(manifest_path)
outputs = manifest.get("outputs", [])
for output in outputs:
    if not os.path.exists(os.path.join(root, output)):
        print("missing output: %s" % output)
        sys.exit(1)

# A page whose group is gone. `outputs` is exactly what the last bake wrote, so anything else
# under the baked folder is a leftover -- and the bake is what deletes it, which is why this is
# reported as staleness rather than as its own kind of failure.
pages = set(os.path.basename(o) for o in outputs if o.endswith(".png"))
orphans = sorted(
    name for name in os.listdir(baked)
    if (name.endswith(".png") or name.endswith(".png.import"))
    and name[:-len(".import")] not in pages and name not in pages
)
if orphans:
    print("pages no group names: %s" % ", ".join(orphans))
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
# Captured rather than left to stream straight through: the stale-cache check below reads it
# back, and the engine's own lines still land on stdout/stderr exactly where they always did,
# in order, via the echo right after.
bake_output="$("$GODOT" --headless --path "$PROJECT_DIR" --script tools/bake_atlases.gd -- \
        ${bake_args[@]+"${bake_args[@]}"} 2>&1)"
bake_status=$?
echo "$bake_output"
if [[ $bake_status -ne 0 ]]; then
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

# The pages above are correct: the bake reads its sources itself and never through the import
# cache. But --script still loads every autoload, and their dependency chain reaches picture
# preload()s (src/events/event_instance.gd among them) -- so on a checkout whose import cache
# has not seen a picture yet, or does not exist at all (a fresh clone or worktree, or a pull
# that added one), the engine prints its own ERROR:/SCRIPT ERROR: lines for that load failure
# and for every script the failure cascades into, right above this line, while the bake has
# already finished. check.sh's own error vocabulary is reused as the trigger rather than a
# narrower pattern that names the .ctex/preload/compile-cascade shapes specifically: which
# autoload fails first, and what it drags down with it, depends on load order and on the
# dependency graph of whatever changed, so a parser that requires every ERROR: line to match a
# fixed list of shapes would be chasing the engine's own diagnostics rather than checking a
# stable contract -- and a change to what it does not recognise would silently stop explaining
# the exact case this item exists for.
if grep -qE "SCRIPT ERROR|Parse Error|ERROR:" <<<"$bake_output"; then
    cat >&2 <<'EOF'

The pages above were baked correctly. The errors above them are the engine loading the game's
own scripts -- this wrapper starts Godot with --script, which still loads every autoload, and
their dependency chain reaches picture preload()s -- against an import cache
(.godot/imported/) that has not seen every picture yet, or does not exist at all. The bake reads
its sources directly rather than through that cache, so its pages are unaffected.

Run tools/check.sh: it bakes (nothing to redo, the pages above are current) and then runs the
import pass the engine's own errors above are missing.
EOF
fi

# Explicit: the grep above exits 1 on no match, and that must never become this script's own
# exit code -- a bake that succeeded with a clean engine run is exit 0 whichever way it reads.
exit 0
