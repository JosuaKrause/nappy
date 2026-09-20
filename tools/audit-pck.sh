#!/usr/bin/env bash
# List an exported pack and report every baked constituent still inside it.
#
#   tools/audit-pck.sh                       # the newest build/web/*/index.pck
#   tools/audit-pck.sh path/to/index.pck     # a pack by name
#   tools/audit-pck.sh --list                # every path in the pack, sorted
#   tools/audit-pck.sh --fatal               # exit non-zero when a constituent is found
#
# The contract this serves is the player's: "they should cease existing in the build once they
# get baked into an atlas" (docs/playtests/PLAYTEST-105.md). A picture that is a member of an
# atlas group must not also travel as its own texture, or the build carries it twice and the
# memory the atlases were for is spent anyway.
#
# It asks two questions of a pack. **Is a baked constituent in it** -- a member picture, its
# .import sidecar or the imported .ctex that sidecar names. And **is a page in it that the pack's
# own regions.json names no group for** -- a page left behind by a group that was folded into
# another, which nothing loads and which the engine exports anyway because
# assets/atlases/baked/ is an imported folder. Neither can be answered from the repository
# alone, which is why this reads the shipped pack rather than the tree.
#
# **It reports and exits 0 unless --fatal is given**, so it can be run on any pack to see what is
# in one. tools/export-web.sh passes --fatal: an export that carries either is a failed export.
#
# **The pack is read directly rather than through the engine.** A .pck is a small binary header
# followed by a path table, so python's standard library can list one in milliseconds with no
# Godot binary, no export templates and no second process mounting the pack with --main-pack.
# The format version is checked and an unknown one fails loudly rather than being guessed at.
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    cat <<'EOF'
usage: tools/audit-pck.sh [--help|-h] [--fatal] [--list] [pack]

Lists an exported .pck and reports what should not be in it: every picture that is a member of
an atlas group and is still there -- as its own source, its .import sidecar or its imported
.ctex copy -- and every baked page the pack's own regions.json names no group for.
Reports only and exits 0 unless --fatal is given.

  pack      the .pck to read; defaults to the newest build/web/*/index.pck
  --fatal   exit non-zero when a constituent or an unnamed page is found
  --list    also print every path in the pack, sorted

  tools/audit-pck.sh
  tools/audit-pck.sh --fatal build/web/dev/index.pck
EOF
}

fatal=0
list=0
pack=""

for arg in "$@"; do
    case "$arg" in
        --help|-h) usage; exit 0 ;;
    esac
done

for arg in "$@"; do
    case "$arg" in
        --fatal) fatal=1 ;;
        --list)  list=1 ;;
        -*)
            echo "tools/audit-pck.sh: unknown argument '$arg'" >&2
            echo >&2
            usage >&2
            exit 2
            ;;
        *)
            if [[ -n "$pack" ]]; then
                echo "tools/audit-pck.sh: one pack at a time (got '$pack' and '$arg')" >&2
                echo >&2
                usage >&2
                exit 2
            fi
            pack="$arg"
            ;;
    esac
done

if [[ -z "$pack" ]]; then
    pack="$(ls -t "$PROJECT_DIR"/build/web/*/index.pck 2>/dev/null | head -1)"
fi
if [[ -z "$pack" || ! -f "$pack" ]]; then
    echo "tools/audit-pck.sh: no pack to read${pack:+ at $pack}" >&2
    echo "run tools/export-web.sh first, or name one" >&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "tools/audit-pck.sh needs python3 to read the pack" >&2
    exit 127
fi

python3 - "$PROJECT_DIR" "$pack" "$fatal" "$list" <<'PY'
import json
import os
import re
import struct
import sys

root, pack_path, fatal, want_list = sys.argv[1], sys.argv[2], sys.argv[3] == "1", sys.argv[4] == "1"

MAGIC = 0x43504447  # "GDPC"


def paths_in(path):
    """Every path in a Godot pack and its own bytes, read from the pack's own file table.

    Format 2 and 3 put the table straight after the header; format 4 -- what 4.7 writes --
    puts the file data first and the table at the offset the header names, and drops the
    `res://` prefix from each stored path. Both shapes are normalised to a bare project-relative
    path here. An unknown format version stops rather than guessing, because a mis-parsed table
    reads as an empty pack, which is exactly the answer this audit must never give wrongly.
    """
    with open(path, "rb") as handle:
        blob = handle.read()
    magic, = struct.unpack_from("<I", blob, 0)
    if magic != MAGIC:
        sys.exit("FAILED: %s does not start with a GDPC header" % path)
    version, = struct.unpack_from("<I", blob, 4)
    if version not in (2, 3, 4):
        sys.exit("FAILED: pack format version %d is not one this script has been taught" % version)
    at = 8 + 12  # the format version, then the engine's major/minor/patch
    base = 0
    if version >= 3:
        at += 4   # pack flags
        # Every file offset below is relative to this, which is what lets a file's own bytes be
        # read back out of the pack -- regions.json's, here.
        base, = struct.unpack_from("<Q", blob, at)
        at += 8
    if version >= 4:
        directory, = struct.unpack_from("<Q", blob, at)
        at = directory
    else:
        at += 16 * 4  # reserved
    count, = struct.unpack_from("<I", blob, at)
    at += 4
    found = {}
    for _ in range(count):
        length, = struct.unpack_from("<I", blob, at)
        at += 4
        name = blob[at:at + length].split(b"\0")[0].decode("utf-8")
        at += length
        offset, size = struct.unpack_from("<QQ", blob, at)
        at += 8 + 8 + 16   # offset, size, md5
        at += 4            # per-file flags
        bare = name[len("res://"):] if name.startswith("res://") else name
        found[bare] = blob[base + offset:base + offset + size]
    return found


members = []
membership = os.path.join(root, "assets/atlases/membership.json")
with open(membership, encoding="utf-8") as handle:
    for group, record in json.load(handle)["groups"].items():
        for member in record["members"]:
            members.append((group, member))

# What a member can look like inside a pack: its own path, the .import sidecar that is the only
# listing an exported source keeps, and the imported .ctex the sidecar names.
wanted = {}
for group, member in members:
    candidates = [member, member + ".import"]
    sidecar = os.path.join(root, member + ".import")
    if os.path.exists(sidecar):
        with open(sidecar, encoding="utf-8") as handle:
            candidates += re.findall(r'"res://(\.godot/imported/[^"]+)"', handle.read())
    for candidate in candidates:
        wanted[candidate] = (group, member)

inside = paths_in(pack_path)
if want_list:
    for name in sorted(inside):
        print(name)
    print()

hits = {}
for name in inside:
    if name in wanted:
        group, member = wanted[name]
        hits.setdefault(member, (group, []))[1].append(name)

# The pages the pack itself says exist, read out of the pack's own regions.json rather than out
# of the tree: what is being audited is the artefact, and a tree rebaked since the export would
# answer for a different one.
BAKED = "assets/atlases/baked/"
groups = None
if BAKED + "regions.json" in inside:
    try:
        groups = set(json.loads(inside[BAKED + "regions.json"].decode("utf-8"))["pages"])
    except (ValueError, KeyError, UnicodeDecodeError) as error:
        sys.exit("FAILED: the pack's %sregions.json does not parse (%s)" % (BAKED, error))

# A page in the pack that regions.json names no group for. Both shapes one takes: the sidecar
# under the baked folder -- the only listing an exported source keeps -- and the imported .ctex
# that sidecar names, which is where the pixels actually are. A .ctex is only read as a page when
# its own sidecar is in the pack beside it, so an imported PNG from somewhere else could never be
# mistaken for one.
pages_in_pack = set()
for name in inside:
    if name.startswith(BAKED) and name.endswith((".png", ".png.import")):
        pages_in_pack.add(name[len(BAKED):].split(".png")[0])

unnamed = []
if groups is not None:
    for name in sorted(inside):
        page = None
        if name.startswith(BAKED) and name.endswith((".png", ".png.import")):
            page = name[len(BAKED):].split(".png")[0]
        else:
            match = re.match(r"^\.godot/imported/(.+)\.png-[0-9a-f]+\.[a-z0-9]+$", name)
            if match and match.group(1) in pages_in_pack:
                page = match.group(1)
        if page is not None and page not in groups:
            unnamed.append(name)

# Relative to the repository when it is inside one, and as given when it is not: a pack under
# /tmp printed relative to the project root is seven `..` segments nobody can read.
shown = os.path.relpath(pack_path, root)
print("pack: %s" % (pack_path if shown.startswith("..") else shown))
print("      %d files, %d atlas members, %d of them still in the pack"
      % (len(inside), len(members), len(hits)))
if groups is None:
    print("      no regions.json in the pack, so no page could be checked against its groups")
else:
    print("      %d baked pages, %d of them named by no group" % (len(groups), len(unnamed)))
for name in unnamed:
    print("      orphan page: %s" % name)
by_group = {}
for member, (group, names) in hits.items():
    by_group.setdefault(group, []).append(member)
for group in sorted(by_group):
    print("      %-16s %4d" % (group, len(by_group[group])))
if hits:
    for member in sorted(hits)[:5]:
        print("      e.g. %s as %s" % (member, ", ".join(sorted(hits[member][1]))))
if hits and fatal:
    sys.exit("FAILED: %d baked constituents are still in the pack" % len(hits))
if unnamed and fatal:
    sys.exit("FAILED: %d baked page files in the pack belong to no group" % len(unnamed))
PY
status=$?
exit $status
