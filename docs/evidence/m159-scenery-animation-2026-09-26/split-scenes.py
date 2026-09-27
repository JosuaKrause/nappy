"""Separate identical vector spans from changing spans without repainting any source art."""

import argparse
import copy
import difflib
import hashlib
import json
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="/Applications/Godot.app/Contents/MacOS/Godot")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[3]
    evidence = Path(__file__).resolve().parent
    stems = ["burst_water_main", "burst_water_main_vertical", "car_accident", "car_accident_vertical"]
    ET.register_namespace("", "http://www.w3.org/2000/svg")
    sources = {}
    layers = {}
    for stem in stems:
        paths = [root / "art/events" / f"{stem}{suffix}.svg" for suffix in ("", "_b")]
        scenes = [ET.parse(path).getroot() for path in paths]
        sources.update({str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest()
                        for path in paths})
        for scene in scenes:
            for element in scene:
                element.tail = None
        keys = [[ET.tostring(element) for element in scene] for scene in scenes]
        spans = difflib.SequenceMatcher(a=keys[0], b=keys[1], autojunk=False).get_opcodes()
        assert len(spans) == (7 if stem.startswith("burst") else 3), (stem, spans)
        result = []
        for number, (operation, i, j, k, end) in enumerate(spans):
            moving = operation != "equal"
            name = f"{stem}_{'motion' if moving else 'static'}_{number}"
            documents = []
            for frame, start, stop in ((0, i, j), (1, k, end)):
                scene = scenes[frame]
                layer = ET.Element(scene.tag, scene.attrib)
                definitions = [element for element in scene if element.tag.endswith("}defs")]
                layer.extend(copy.deepcopy(definitions))
                layer.extend(copy.deepcopy([element for element in list(scene)[start:stop]
                                            if not element.tag.endswith("}defs")]))
                documents.append(ET.tostring(layer, encoding="unicode"))
            result.append({"name": name, "moving": moving, "frames": documents if moving else documents[:1]})
        layers[stem] = result
    payload = {"sources": sources, "layers": layers}
    with tempfile.TemporaryDirectory(prefix="scenery-split-") as temporary:
        input_path = Path(temporary) / "layers.json"
        input_path.write_text(json.dumps(payload))
        subprocess.run([args.godot, "--headless", "--path", str(root), "--script",
                        str(evidence / "crop-scenes.gd"), "--", str(input_path)], check=True)
    metadata = json.loads((evidence / "layers.json").read_text())
    result = ["class_name EventSceneryParts", "extends RefCounted",
              "## Registered vector spans in painter order; split-scenes.py preserves their source artwork.",
              "", "const LAYERS := {"]
    for stem, entries in metadata["layers"].items():
        result.append(f'\t"{stem}": [')
        for entry in entries:
            result.append("\t\t" + json.dumps(entry) + ",")
        result.append("\t],")
    result.append("}\n")
    (root / "src/events/event_scenery_parts.gd").write_text("\n".join(result))
    membership_path = root / "assets/atlases/membership.json"
    membership = json.loads(membership_path.read_text())
    members = membership["groups"]["events"]["members"]
    for entries in metadata["layers"].values():
        for name, _x, _y, _width, _height, moving in entries:
            for suffix in (("", "_b") if moving else ("",)):
                path = f"art/events/{name}{suffix}.svg"
                assert (root / path).is_file(), path
                if path not in members:
                    members.append(path)
    members.sort()
    membership_path.write_text(json.dumps(membership, indent=2) + "\n")
    print(f"Registered {sum(len(entries) for entries in metadata['layers'].values())} ordered layers")


if __name__ == "__main__":
    main()
