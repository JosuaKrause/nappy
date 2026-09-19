#!/usr/bin/env python3
"""Verify the complete player manifest, native male replacements and import identities."""

import argparse
import hashlib
import json
import re
from pathlib import Path
from xml.etree import ElementTree

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()
    manifest = json.loads((ROOT / "docs/graphics-creation/player/manifest.json").read_text())
    expected = {
        f"assets/rig/father_{state}{view}_{pose}.svg"
        for state in ("", "carrying_")
        for view in ("front", "back", "side", "front_diagonal", "back_diagonal")
        for pose in ("a", "c", "b")
    }
    actual = {path for path in manifest["assets"] if Path(path).name.startswith("father_")}
    if actual != expected:
        raise ValueError("the male source manifest is not the complete facing/pose/state matrix")
    frames = manifest["runtime_frames"]
    if set(frames["contacts"] + frames["together"]) != set(manifest["assets"]):
        raise ValueError("frame roles do not cover the player manifest")
    identities = {}
    for source, row in manifest["assets"].items():
        authoring = ROOT / row["authoring"]
        native = ROOT / row["accepted_png"]
        if digest(authoring) != row["source_sha256"] or digest(native) != row["accepted_png_sha256"]:
            raise ValueError(f"changed source or PNG: {source}")
        element = ElementTree.parse(authoring).getroot()
        if element.attrib["viewBox"] != row["canvas"]:
            raise ValueError(f"creation canvas mismatch: {source}")
        runtime_element = ElementTree.parse(ROOT / source).getroot()
        if runtime_element.attrib["viewBox"] != row["canvas"]:
            raise ValueError(f"runtime canvas mismatch: {source}")
        if source not in expected:
            continue
        if (ROOT / source).read_bytes() != authoring.read_bytes():
            raise ValueError(f"male creation/runtime source mismatch: {source}")
        with Image.open(native) as picture:
            if list(picture.size) != [int(n) for n in row["canvas"].split()[2:]]:
                raise ValueError(f"native dimensions mismatch: {native}")
            if picture.mode != "RGBA" or picture.getchannel("A").getextrema() != (0, 255):
                raise ValueError(f"missing real transparency: {native}")
        override = row.get("registration_override")
        if override is None:
            registered = Path(__file__).parent / "registered/rig" / native.name
            if registered.read_bytes() != native.read_bytes():
                raise ValueError(f"installed PNG differs from registered output: {native}")
        else:
            accepted_source = ROOT / override["accepted_source"]
            original_registered = ROOT / override["original_registered"]
            if digest(accepted_source) != override["accepted_source_sha256"]:
                raise ValueError(f"changed accepted override source: {accepted_source}")
            if native.read_bytes() != accepted_source.read_bytes():
                raise ValueError(f"installed PNG differs from accepted override: {native}")
            if digest(original_registered) != override["original_registered_sha256"]:
                raise ValueError(f"changed original registered PNG: {original_registered}")
    for folder in ("assets/rig", "assets/illustrated/svg-transfer/rig"):
        for sidecar in sorted((ROOT / folder).glob("*.import")):
            contents = sidecar.read_text()
            uid = re.search(r'^uid="([^"]+)"$', contents, re.MULTILINE)
            source_file = re.search(r'^source_file="([^"]+)"$', contents, re.MULTILINE)
            if uid is None or source_file is None:
                raise ValueError(f"missing source/identity: {sidecar}")
            if source_file[1] != "res://" + str(sidecar.relative_to(ROOT))[:-7]:
                raise ValueError(f"wrong import source: {sidecar}")
            if uid[1] in identities:
                raise ValueError(f"duplicate import identity: {sidecar} and {identities[uid[1]]}")
            identities[uid[1]] = sidecar
    print("Player pair hashes, source XML, native dimensions, transparency and import identities verified")


if __name__ == "__main__":
    main()
