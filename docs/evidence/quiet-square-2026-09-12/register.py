"""Register the generated quiet-square paving without altering its illustrated material."""

from __future__ import annotations

import argparse
import hashlib
import json
import platform
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageStat, __version__ as PILLOW_VERSION


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
TILE = (32, 32)
RUNTIME = ROOT / "assets/illustrated/svg-transfer/tiles"
LAYER_RUNTIME = RUNTIME / "layers"
NEIGHBOR_FILES = {
	"sidewalk_base": LAYER_RUNTIME / "sidewalk_base.png",
	"asphalt_base": LAYER_RUNTIME / "asphalt_base.png",
	"grass_base": LAYER_RUNTIME / "grass_base.png",
}
REFERENCE_FILES = (
	"docs/evidence/graphics-reference-urban-01.jpeg",
	"docs/evidence/graphics-reference-urban-02.jpeg",
	"docs/evidence/graphics-reference-cardinal.jpeg",
)


def _sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def _fresh(path: Path) -> None:
	if path.exists():
		raise ValueError(f"refusing to replace existing output: {path}")


def _load(path: Path) -> Image.Image:
	image = Image.open(path).convert("RGBA")
	if image.size != TILE:
		raise ValueError(f"expected 32x32 ground tile: {path}")
	return image


def _mean_luma(image: Image.Image) -> float:
	return round(sum(ImageStat.Stat(image.convert("RGB")).mean) / 3, 4)


def _repeat_sheet(tile: Image.Image, neighbors: dict[str, Image.Image]) -> Image.Image:
	"""Render native and enlarged repeats plus nearby materials without changing their pixels."""
	font = ImageFont.load_default()
	sheet = Image.new("RGBA", (6 * 32, 160), "#222631")
	draw = ImageDraw.Draw(sheet)
	draw.text((2, 1), "quiet-square repeat", fill="white", font=font)
	for row in range(3):
		for column in range(6):
			sheet.alpha_composite(tile, (column * 32, 14 + row * 32))
	draw.text((2, 114), "shared ground bases", fill="white", font=font)
	for column, name in enumerate(("sidewalk_base", "quiet_square", "asphalt_base", "grass_base", "quiet_square", "sidewalk_base")):
		sheet.alpha_composite(tile if name == "quiet_square" else neighbors[name], (column * 32, 128))
	return sheet


def build(raw: Path, svg_render: Path | None, output_dir: Path, input_bundle: Path | None) -> None:
	_fresh(output_dir)
	if not raw.is_file():
		raise ValueError(f"missing generated raw image: {raw}")
	if input_bundle is None and (svg_render is None or not svg_render.is_file()):
		raise ValueError("initial build requires --svg-render from render-quiet-square-source.gd")
	output_dir.mkdir(parents=True)
	raw_image = Image.open(raw).convert("RGBA")
	if raw_image.width != raw_image.height:
		raise ValueError(f"generated image is not square: {raw_image.size}")
	if raw_image.getchannel("A").getextrema() != (255, 255):
		raise ValueError("generated image must be fully opaque")
	registered = raw_image.resize(TILE, Image.Resampling.LANCZOS).convert("RGBA")
	registered.putalpha(255)
	(output_dir / "raw").mkdir()
	shutil.copyfile(raw, output_dir / "raw/quiet-square-generated.png")
	inputs = output_dir / "frozen-inputs"
	if input_bundle is None:
		inputs.mkdir()
		shutil.copyfile(RUNTIME / "quiet_square.png", inputs / "quiet_square_brightness_reference.png")
		for name, path in NEIGHBOR_FILES.items():
			shutil.copyfile(path, inputs / f"{name}.png")
		shutil.copyfile(ROOT / "assets/tiles/quiet_square.svg", inputs / "quiet_square.svg")
		shutil.copyfile(svg_render, inputs / "quiet_square-svg-8x.png")
		shutil.copyfile(HERE / "render-quiet-square-source.gd", inputs / "render-quiet-square-source.gd")
		for relative in REFERENCE_FILES:
			target = inputs / Path(relative).name
			shutil.copyfile(ROOT / relative, target)
	else:
		shutil.copytree(input_bundle / "frozen-inputs", inputs)
	registered_dir = output_dir / "registered"
	registered_dir.mkdir()
	registered.save(registered_dir / "quiet_square.png")
	neighbors = {name: _load(inputs / f"{name}.png") for name in NEIGHBOR_FILES}
	sheet = _repeat_sheet(registered, neighbors)
	review = output_dir / "review"
	review.mkdir()
	sheet.save(review / "repeat-neighbors-native.png")
	sheet.resize((sheet.width * 4, sheet.height * 4), Image.Resampling.NEAREST).save(review / "repeat-neighbors-4x.png")
	manifest = {
		"format": 1,
		"python_version": platform.python_version(),
		"pillow_version": PILLOW_VERSION,
		"script_sha256": _sha256(Path(__file__)),
		"method": "built-in imagegen raw output, direct LANCZOS downsample to 32x32; no recoloring or paint-over",
		"raw": {"path": "raw/quiet-square-generated.png", "sha256": _sha256(output_dir / "raw/quiet-square-generated.png"), "size": list(raw_image.size)},
		"sources": {path.name: _sha256(path) for path in sorted(inputs.iterdir())},
		"registered": {"path": "registered/quiet_square.png", "sha256": _sha256(registered_dir / "quiet_square.png"), "size": list(registered.size), "opaque": registered.getchannel("A").getextrema() == (255, 255)},
		"mean_luma": {
			"quiet_square": _mean_luma(registered),
			"quiet_square_brightness_reference": _mean_luma(_load(inputs / "quiet_square_brightness_reference.png")),
			**{name: _mean_luma(image) for name, image in neighbors.items()},
		},
	}
	(output_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def verify(bundle: Path, target: Path | None) -> None:
	manifest = json.loads((bundle / "manifest.json").read_text())
	if manifest["script_sha256"] != _sha256(Path(__file__)):
		raise ValueError("registration script differs from the retained authority")
	registered = _load(bundle / manifest["registered"]["path"])
	if _sha256(bundle / manifest["registered"]["path"]) != manifest["registered"]["sha256"]:
		raise ValueError("registered tile differs from manifest")
	if registered.getchannel("A").getextrema() != (255, 255):
		raise ValueError("registered tile is not opaque")
	if target is not None and _sha256(target) != manifest["registered"]["sha256"]:
		raise ValueError("runtime quiet square differs from registered tile")


def install(bundle: Path, target: Path, replace: bool) -> None:
	if not replace:
		raise ValueError("runtime replacement requires --replace")
	verify(bundle, None)
	shutil.copyfile(bundle / "registered/quiet_square.png", target)
	verify(bundle, target)


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	commands = parser.add_subparsers(dest="command", required=True)
	build_parser = commands.add_parser("build", help="register one generated raw image into a new evidence bundle")
	build_parser.add_argument("--raw", type=Path, required=True)
	build_parser.add_argument("--svg-render", type=Path)
	build_parser.add_argument("--output-dir", type=Path, required=True)
	build_parser.add_argument("--input-bundle", type=Path, help="reuse frozen references instead of reading runtime artwork")
	verify_parser = commands.add_parser("verify", help="verify a bundle and optional runtime target")
	verify_parser.add_argument("--bundle-dir", type=Path, required=True)
	verify_parser.add_argument("--target", type=Path)
	install_parser = commands.add_parser("install", help="replace the runtime quiet-square image from a verified bundle")
	install_parser.add_argument("--bundle-dir", type=Path, required=True)
	install_parser.add_argument("--target", type=Path, required=True)
	install_parser.add_argument("--replace", action="store_true")
	arguments = parser.parse_args()
	if arguments.command == "build":
		build(
			arguments.raw.resolve(),
			arguments.svg_render.resolve() if arguments.svg_render else None,
			arguments.output_dir.resolve(),
			arguments.input_bundle.resolve() if arguments.input_bundle else None,
		)
	elif arguments.command == "verify":
		verify(arguments.bundle_dir.resolve(), arguments.target.resolve() if arguments.target else None)
	else:
		install(arguments.bundle_dir.resolve(), arguments.target.resolve(), arguments.replace)


if __name__ == "__main__":
	main()
