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
# a second and a half and defeat the point. A default bake is also stale when an illustrated PNG
# has appeared beside an SVG it baked from, since that PNG has no recorded hash to disagree with.
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
# **A mode only hashes what it bakes.** A group in membership.json lists the pictures both modes
# carry under "members" and the ones only one mode draws under "members_png" / "members_svg"; the
# bake reads and hashes its own mode's list alone, so editing a picture only the other mode draws
# leaves this tree up to date. The ground is the group that needs it: a default bake composes 46
# of its tiles out of layers, so those tiles' whole pictures are on an --svg page only.
#
# **The bake starts from a built class cache.** This runs Godot with --script, which loads every
# autoload first whatever the script references. On a checkout with no .godot/global_script_class_cache.cfg
# -- every fresh clone and every new worktree -- no class_name resolves, every autoload fails to
# parse and the engine prints its own ERROR: and SCRIPT ERROR: lines for the cascade (about 70 of
# them) right after a bake that wrote every page correctly. So when the cache file is missing this
# script first runs one quiet `--headless --import` pass, which builds it; the bake's output is then
# as clean as a second run's, and any ERROR: it still prints is a real one. The pass prints nothing
# unless it fails, and it runs only when the cache is missing and a bake is about to happen.
set -uo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$PROJECT_DIR/assets/atlases/baked/bake_manifest.json"
# shellcheck source=tools/lib_disk_headroom.sh
source "$PROJECT_DIR/tools/lib_disk_headroom.sh"

usage() {
    cat <<'EOF'
usage: tools/bake-atlases.sh [--help|-h] [--svg] [--check|--force]

Bakes assets/atlases/baked/ -- one PNG page per group in assets/atlases/membership.json, plus
regions.json and bake_manifest.json -- when the tree has moved since the last bake. With no
flags it compares the recorded source hashes and prints one line saying whether it baked.

  --svg     bake every paired picture from its authored SVG raster, ignoring its illustrated
            PNG; a family that exists only as PNG (the roof equipment) is baked from it. The custom
            local build; the release is always the default PNG bake, and a tree baked this way
            counts as stale for every tool that wants a release build. A group's page also
            holds what its mode draws: "members" is what both bake, "members_png" and
            "members_svg" what only that one does, and only that one's are read and hashed.
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

# A transfer that arrived beside a picture the last bake took from its SVG. It was never an input,
# so no recorded hash can notice it, yet a default bake would take it: every SVG the last bake
# read is asked whether its illustrated PNG now exists. The path rule is
# AtlasLibrary.illustrated_path_for()'s, restated because this runs without the engine.
added = []
if wanted_mode == "png":
    inputs = manifest.get("inputs", {})
    for relative in sorted(inputs):
        if not relative.startswith("art/") or not relative.endswith(".svg"):
            continue
        transfer = "art/illustrated/svg-transfer/" + relative[len("art/"):-len(".svg")] + ".png"
        if transfer not in inputs and os.path.exists(os.path.join(root, transfer)):
            added.append(transfer)

if missing or changed or added:
    parts = []
    if changed:
        parts.append("%d changed (%s)" % (len(changed), ", ".join(changed[:3])))
    if missing:
        parts.append("%d gone (%s)" % (len(missing), ", ".join(missing[:3])))
    if added:
        parts.append("%d new transfers (%s)" % (len(added), ", ".join(added[:3])))
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

# Checked only on the path that writes pages: --check, an up-to-date tree and a rejected argument
# allocate nothing.
headroom_preflight tools/bake-atlases.sh "$PROJECT_DIR/assets/atlases/baked" "" atlas-bake || exit 1

# project.godot and docs/ARCHITECTURE.md have been found rewritten after tools that run Godot; this
# reverts such a rewrite on exit and keeps a deliberate edit (tools/lib_import_restore.sh).
# shellcheck source=tools/lib_import_restore.sh
source "$PROJECT_DIR/tools/lib_import_restore.sh"
import_restore_arm "$PROJECT_DIR"
trap import_restore_run EXIT

echo "atlases: baking ($mode mode) -- $reason"
# Builds the class cache a fresh checkout lacks, so the bake below prints no cascade of parse errors
# (see the header). Quiet unless it fails.
if [[ ! -f "$PROJECT_DIR/.godot/global_script_class_cache.cfg" ]]; then
    import_output="$("$GODOT" --headless --import --path "$PROJECT_DIR" 2>&1)" || {
        echo "$import_output"
        echo "FAILED: the import pass that builds the class cache did not succeed" >&2
        exit 1
    }
fi
bake_args=()
if [[ "$mode" == "svg" ]]; then
    bake_args+=(--svg)
fi
# Captured and echoed right after, so the engine's own lines land on stdout in order, stderr
# folded in, before the bake's status is read.
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

exit 0
