#!/usr/bin/env python3
"""Extract the six sidewalk-origin damage stencils from retained frozen artwork."""

import argparse
import hashlib
import importlib.util
import json
import sys
from pathlib import Path
from types import ModuleType


ROOT = Path(__file__).resolve().parents[3]
ASSEMBLER_PATH = ROOT / "docs/evidence/layered-ground-2026-09-12/assemble.py"
SIDEWALK_DAMAGE = tuple(
    f"sidewalk_cracked_{state}_{side}"
    for state in ("hairline", "cracked", "broken")
    for side in ("a", "b")
)


def _sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def _assembler() -> ModuleType:
	spec = importlib.util.spec_from_file_location("layered_ground_assemble", ASSEMBLER_PATH)
	if spec is None or spec.loader is None:
		raise ValueError(f"cannot load assembly script: {ASSEMBLER_PATH}")
	module = importlib.util.module_from_spec(spec)
	sys.modules[spec.name] = module
	spec.loader.exec_module(module)
	return module


def _fresh(path: Path) -> None:
	if path.exists():
		raise ValueError(f"refusing to overwrite existing output: {path}")


def _alpha_profile(component) -> dict[str, list[int]]:
	alpha = component.getchannel("A")
	return {
		"selected_per_column": [sum(alpha.getpixel((x, y)) > 0 for y in range(32)) for x in range(32)],
		"selected_per_row": [sum(alpha.getpixel((x, y)) > 0 for x in range(32)) for y in range(32)],
	}


def extract(bundle: Path, output: Path) -> None:
	_fresh(output)
	manifest_path = bundle / "manifest.json"
	if not manifest_path.is_file():
		raise ValueError(f"missing retained bundle manifest: {manifest_path}")
	manifest = json.loads(manifest_path.read_text())
	assembler = _assembler()
	output.mkdir(parents=True)
	component_dir = output / "components"
	component_dir.mkdir()
	frozen_tiles = bundle / "frozen-inputs/tiles"
	frozen_svg = bundle / "frozen-inputs/svg-renders"
	accepted_bases = bundle / "frozen-inputs/accepted-surface-bases"
	records: dict[str, dict[str, str]] = {}
	for name in SIDEWALK_DAMAGE:
		detail_path = frozen_tiles / f"{name}.png"
		detail = assembler._load(detail_path)
		mask = assembler._damage_mask(
			name, detail, "sidewalk", assembler._load(frozen_svg / "sidewalk-svg.png"),
			assembler._load(accepted_bases / "sidewalk.png"),
		)
		component = assembler._extract_component(detail, mask)
		component_path = component_dir / f"{name}.png"
		component.save(component_path)
		if component.getchannel("A").getextrema()[0] != 0:
			raise ValueError(f"extracted stencil is not transparent: {name}")
		records[name] = {
			"frozen_input_sha256": _sha256(detail_path),
			"component_sha256": _sha256(component_path),
			**_alpha_profile(component),
		}
	result = {
		"assembly_script": str(ASSEMBLER_PATH.relative_to(ROOT)),
		"assembly_script_sha256": _sha256(ASSEMBLER_PATH),
		"retained_bundle": str(bundle.relative_to(ROOT)),
		"retained_bundle_manifest_sha256": _sha256(manifest_path),
		"accepted_damage_revision": manifest["inputs"]["accepted-damage:sidewalk_cracked_hairline_a"]["revision"],
		"components": records,
	}
	(output / "manifest.json").write_text(json.dumps(result, indent=2) + "\n")


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--bundle-dir", type=Path, required=True, help="retained frozen layered-ground bundle")
	parser.add_argument("--output-dir", type=Path, required=True, help="new directory for extracted components")
	arguments = parser.parse_args()
	extract(arguments.bundle_dir.resolve(), arguments.output_dir.resolve())


if __name__ == "__main__":
	main()
