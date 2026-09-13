"""Build and verify shared-base illustrated ground tiles.

The build freezes the current illustrated tile PNGs and matching existing SVG renders, preserves
illustrated curb, paint, and damage foregrounds as transparent layers, and composes review-only
tiles over shared bases. It never regenerates painted detail.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import platform
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, ImageStat, __version__ as PILLOW_VERSION


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
TILE_SIZE = (32, 32)
RUNTIME_DIR = ROOT / "assets/illustrated/svg-transfer/tiles"
SVG_RENDER_DIR = ROOT / "docs/evidence/style-transfer-tiles-2026-09-12/source"
ASPHALT_OFFSETS = ((0, 0), (16, 16), (8, 24), (24, 8))
ACCEPTED_DAMAGE_SOURCE_REVISION = "83a60d1522574714ce038dff3a607a536d800614"
SELECTED_SIDEWALK_SOURCE_REVISION = "62d1c344dccbf77e7cb8052ea09b337a76ce994e"
SELECTED_SIDEWALK_PNG_BLOB = "af36579547f3f1795a7549c4f3227a2a9e9f58db"
SELECTED_SIDEWALK_SVG_BLOB = "0d947890561585aacb1ac69196a3ebc9e10874d1"


@dataclass(frozen=True)
class LayerSpec:
	"""Names one retained transparent component and its source geometry or accepted PNG."""

	name: str
	base: str
	source_name: str
	source_svg: str
	method: str


CURBS = (
	"sidewalk_kerb_n", "sidewalk_kerb_s", "sidewalk_kerb_e", "sidewalk_kerb_w",
	"sidewalk_kerb_main_n", "sidewalk_kerb_main_s", "sidewalk_kerb_main_e", "sidewalk_kerb_main_w",
)
ROAD_PAINT = (
	"road_line_e", "road_line_w", "road_line_n", "road_line_s", "crossing_h", "crossing_v",
	"road_main_line_e", "road_main_line_w", "road_main_line_n", "road_main_line_s",
	"crossing_main_n", "crossing_main_s", "crossing_main_e", "crossing_main_w",
)
DAMAGE = tuple(
	f"{surface}_cracked_{state}_{side}"
	for surface in ("sidewalk", "road", "alley")
	for state in ("hairline", "cracked", "broken")
	for side in ("a", "b")
)
LAYER_SPECS = (
	LayerSpec("curbstone", "sidewalk", "sidewalk_kerb_n", "assets/tiles/sidewalk_kerb_n.svg", "svg-mask"),
	LayerSpec("main_edge_red", "sidewalk", "sidewalk_kerb_main_n", "assets/tiles/sidewalk_kerb_main_n.svg", "paint-color"),
	LayerSpec("yellow_half_line", "road", "road_line_n", "assets/tiles/road_line_n.svg", "paint-color"),
	LayerSpec("yellow_main_line", "road", "road_main_line_n", "assets/tiles/road_main_line_n.svg", "paint-color"),
	LayerSpec("crosswalk", "road", "crossing_h", "assets/tiles/crossing_h.svg", "paint-color"),
	LayerSpec("main_crosswalk", "road", "crossing_main_n", "assets/tiles/crossing_main_n.svg", "paint-color"),
) + tuple(
	LayerSpec(name, name.split("_cracked_", 1)[0], name, f"assets/tiles/{name}.svg", "damage-difference")
	for name in DAMAGE
)
COMPILED_NAMES = ("sidewalk", "road", "road_main") + CURBS + ROAD_PAINT + DAMAGE
FROZEN_NAMES = tuple(sorted(set(COMPILED_NAMES) | {"alley", "grass"}))


def _sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def _fresh(path: Path) -> None:
	if path.exists():
		raise ValueError(f"refusing to replace existing output: {path}")


def _load(path: Path) -> Image.Image:
	image = Image.open(path).convert("RGBA")
	if image.size != TILE_SIZE:
		raise ValueError(f"expected 32x32 image: {path}")
	return image


def _copy_frozen(path: Path, destination: Path) -> dict[str, str]:
	destination.parent.mkdir(parents=True, exist_ok=True)
	shutil.copyfile(path, destination)
	return {"path": str(path.relative_to(ROOT)), "sha256": _sha256(path)}


def _frozen_git_file(revision: str, relative: str, destination: Path) -> dict[str, str]:
	"""Copy an accepted source PNG without depending on a mutable checkout file."""
	destination.parent.mkdir(parents=True, exist_ok=True)
	data = subprocess.check_output(["git", "show", f"{revision}:{relative}"], cwd=ROOT)
	destination.write_bytes(data)
	return {"revision": revision, "path": relative, "sha256": _sha256(destination)}


def _dilate(mask: Image.Image) -> Image.Image:
	"""Keep the source-defined component and its one-pixel illustrated edge treatment."""
	pixels = mask.load()
	expanded = Image.new("L", TILE_SIZE)
	output = expanded.load()
	for y in range(TILE_SIZE[1]):
		for x in range(TILE_SIZE[0]):
			if any(
				0 <= nx < TILE_SIZE[0] and 0 <= ny < TILE_SIZE[1] and pixels[nx, ny]
				for nx in range(x - 1, x + 2)
				for ny in range(y - 1, y + 2)
			):
				output[x, y] = 255
	return expanded


def _component_mask(source_name: str, base_name: str, frozen_svg: Path) -> Image.Image:
	variant = _load(frozen_svg / f"{source_name}-svg.png")
	base = _load(frozen_svg / f"{base_name}-svg.png")
	mask = ImageChops.difference(variant, base).convert("L")
	return _dilate(mask.point(lambda value: 255 if value else 0))


def _damage_mask(name: str, detail: Image.Image, surface: str, source_base: Image.Image, accepted_base: Image.Image) -> Image.Image:
	"""Separate dark fissures, holes, debris, and growth from independently painted ground only."""
	pixels = detail.convert("RGB").load()
	base_pixels = source_base.convert("RGB").load()
	accepted_pixels = accepted_base.convert("RGB").load()
	base_fill = source_base.convert("RGB").getpixel((0, 0))
	mask = Image.new("L", TILE_SIZE)
	output = mask.load()
	# These broad audited regions retain the illustrated rather than the primitive SVG form. They
	# only fence off unrelated paving; color and seam handling below decide the actual alpha.
	regions = {
		"hairline_a": (0, 0, 20, 24), "hairline_b": (12, 0, 32, 32),
		"cracked_a": (0, 0, 23, 32), "cracked_b": (8, 0, 32, 32),
		"broken_a": (2, 0, 29, 32), "broken_b": (0, 0, 29, 32),
	}
	state_variant = name.rsplit("_", 2)[1] + "_" + name.rsplit("_", 1)[1]
	left, top, right, bottom = regions[state_variant]
	for y in range(top, bottom):
		for x in range(32):
			if not left <= x < right:
				continue
			red, green, blue = pixels[x, y]
			luma = (red + green + blue) / 3
			if surface == "sidewalk":
				selected = luma < 125 or (green > red * 1.04 and green > blue * 1.15)
			else:
				selected = luma < 60 or (green > red * 1.05 and green > blue * 1.12) or (
					luma > 85 and max(red, green, blue) - min(red, green, blue) > 18)
			# The source's long slab/alley seams belong to the shared base. A pixel on that geometry
			# is removed only when its accepted illustration also matches the accepted base there;
			# a crack, hole, or weed crossing a seam remains fully intact.
			is_base_structure = base_pixels[x, y] != base_fill
			resembles_accepted_base = max(
				abs(current - background)
				for current, background in zip((red, green, blue), accepted_pixels[x, y], strict=True)
			) <= 10
			if selected and not (is_base_structure and resembles_accepted_base):
				output[x, y] = 255
	# The illustrated alley variants inherited two full-width floor seams from their old individual
	# backgrounds. These hand-audited crossings retain actual fissures or holes where they cross a
	# seam and remove the otherwise doubled seam from the transparent layer.
	if surface == "alley":
		seam_crossings = {
			"hairline_a": {(9, 11), (10, 11)},
			"hairline_b": {(9, 16), (9, 17), (10, 17)},
			"cracked_a": {(9, 10), (9, 11), (23, 14), (23, 15), (24, 16)},
			"cracked_b": {(9, 15), (9, 16), (10, 17), (24, 14), (24, 15)},
			"broken_a": {(9, 11), (9, 12), (23, 12), (23, 13), (23, 14), (23, 15), (23, 16), (23, 17), (23, 18), (23, 19), (24, 23)},
			"broken_b": {(9, 9), (9, 10), (9, 12), (9, 13), (9, 24), (9, 25)},
		}[state_variant]
		for y in (9, 10, 23, 24):
			for x in range(32):
				if (x, y) not in seam_crossings:
					output[x, y] = 0
	# Remove only a long straight selected seam that has no perpendicular foreground connection.
	for y in range(32):
		for x in range(32):
			if not output[x, y] or base_pixels[x, y] == base_fill:
				continue
			horizontal = sum(output[nx, y] > 0 for nx in range(32))
			vertical = sum(output[x, ny] > 0 for ny in range(32))
			crosses_horizontal = 0 < y < 31 and output[x, y - 1] and output[x, y + 1]
			crosses_vertical = 0 < x < 31 and output[x - 1, y] and output[x + 1, y]
			if (horizontal >= 10 and not crosses_horizontal) or (vertical >= 10 and not crosses_vertical):
				output[x, y] = 0
	return mask


def _paint_mask(detail: Image.Image, paint: str) -> Image.Image:
	"""Separate the illustrated warm/red paint itself; source SVGs remain placement provenance."""
	pixels = detail.convert("RGB").load()
	mask = Image.new("L", TILE_SIZE)
	output = mask.load()
	for y in range(32):
		for x in range(32):
			red, green, blue = pixels[x, y]
			if paint == "red":
				selected = red > 80 and red > green * 1.18 and red > blue * 1.18
			else:
				selected = red > 105 and green > 95 and red > blue * 1.17 and green > blue * 1.12
			if selected:
				output[x, y] = 255
	return _dilate(mask)


def _extract_component(source: Image.Image, mask: Image.Image) -> Image.Image:
	component = source.copy()
	component.putalpha(mask)
	return component


def _oriented(component: Image.Image, direction: str) -> Image.Image:
	"""Turn the canonical north/top component to the TileSet direction without redrawing it."""
	return component.rotate({"n": 0, "e": 270, "s": 180, "w": 90}[direction], expand=False)


def _grass_feature_mask(source: Image.Image, background: Image.Image, index: int) -> Image.Image:
	"""Keep actual dark illustrated clumps within their audited source-tile regions."""
	bounds = ((2, 4, 13, 15), (19, 13, 32, 22), (2, 23, 14, 31))
	mask = Image.new("L", TILE_SIZE)
	pixels = source.convert("RGB").load()
	background_pixels = background.convert("RGB").load()
	output = mask.load()
	left, top, right, bottom = bounds[index]
	for y in range(top, bottom):
		for x in range(left, right):
			color = pixels[x, y]
			if max(abs(current - averaged) for current, averaged in zip(color, background_pixels[x, y], strict=True)) > 10:
				output[x, y] = 255
	return mask


def _mean_rotations(source: Image.Image, offsets: Iterable[tuple[int, int]]) -> Image.Image:
	"""Average four rotations with equal channel weights after wrapping each requested offset."""
	accumulator = [0] * (TILE_SIZE[0] * TILE_SIZE[1] * 3)
	count = 0
	for angle, offset in zip((0, 90, 180, 270), offsets, strict=True):
		rotated = source.rotate(angle, expand=False).convert("RGB")
		shifted = Image.new("RGB", TILE_SIZE)
		for y in range(TILE_SIZE[1]):
			for x in range(TILE_SIZE[0]):
				shifted.putpixel((x, y), rotated.getpixel(((x - offset[0]) % 32, (y - offset[1]) % 32)))
		for index, value in enumerate(shifted.tobytes()):
			accumulator[index] += value
		count += 1
	averaged = bytes(round(value / count) for value in accumulator)
	result = Image.frombytes("RGB", TILE_SIZE, averaged).convert("RGBA")
	result.putalpha(255)
	return result


def _median_rotations(source: Image.Image) -> Image.Image:
	"""Keep soft grass color variation while discarding a sparse feature seen in only one rotation."""
	rotations = [source.rotate(angle, expand=False).convert("RGB") for angle in (0, 90, 180, 270)]
	result = Image.new("RGBA", TILE_SIZE)
	for y in range(32):
		for x in range(32):
			channels = list(zip(*(image.getpixel((x, y)) for image in rotations), strict=True))
			result.putpixel((x, y), tuple(sorted(channel)[2] for channel in channels) + (255,))
	return result


def _seam_error(tile: Image.Image) -> float:
	"""Measure visible discontinuity across repeated horizontal and vertical tile edges."""
	rgb = tile.convert("RGB")
	error = 0
	for axis in (0, 1):
		for index in range(32):
			first = rgb.getpixel((0, index) if axis == 0 else (index, 0))
			last = rgb.getpixel((31, index) if axis == 0 else (index, 31))
			error += sum(abs(left - right) for left, right in zip(first, last, strict=True))
	return error / 192


def _edge_means(tile: Image.Image) -> dict[str, float]:
	rgb = tile.convert("RGB")
	def mean(points: Iterable[tuple[int, int]]) -> float:
		values = [sum(rgb.getpixel(point)) / 3 for point in points]
		return sum(values) / len(values)
	return {
		"top": mean((x, 0) for x in range(32)), "bottom": mean((x, 31) for x in range(32)),
		"left": mean((0, y) for y in range(32)), "right": mean((31, y) for y in range(32)),
	}


def _mean_luma(tile: Image.Image) -> float:
	return sum(ImageStat.Stat(tile.convert("RGB")).mean) / 3


def _compose(base: Image.Image, layer: Image.Image) -> Image.Image:
	result = base.copy()
	result.alpha_composite(layer)
	if result.getchannel("A").getextrema() != (255, 255):
		raise ValueError("compiled terrain must be opaque")
	for y in range(32):
		for x in range(32):
			if layer.getpixel((x, y))[3] == 0 and result.getpixel((x, y)) != base.getpixel((x, y)):
				raise ValueError("transparent overlay pixel changed its base")
	return result


def _panel(bundle: Path, bases: dict[str, Image.Image], layers: dict[str, Image.Image], compiled: dict[str, Image.Image]) -> None:
	"""Render a checkerboard layer sheet and clean native/enlarged street montages."""
	checker = Image.new("RGBA", (32, 32), "#a9a9a9")
	draw_checker = ImageDraw.Draw(checker)
	for y in range(0, 32, 4):
		for x in range(0, 32, 4):
			if (x // 4 + y // 4) % 2:
				draw_checker.rectangle((x, y, x + 3, y + 3), fill="#d8d8d8")
	layer_sheet = Image.new("RGBA", (8 * 64, ((len(layers) + 7) // 8) * 64), "#222631")
	font = ImageFont.load_default()
	labeler = ImageDraw.Draw(layer_sheet)
	for index, (name, layer) in enumerate(layers.items()):
		x, y = index % 8 * 64, index // 8 * 64
		layer_sheet.alpha_composite(checker, (x + 16, y))
		layer_sheet.alpha_composite(layer, (x + 16, y))
		labeler.text((x + 1, y + 33), name.replace("sidewalk_", "sw_"), fill="white", font=font)
	layer_sheet.save(bundle / "layers-checkerboard-native.png")
	layer_sheet.resize((layer_sheet.width * 4, layer_sheet.height * 4), Image.Resampling.NEAREST).save(
		bundle / "layers-checkerboard-4x.png")

	rows = (
		("sidewalk + curbs", (("sidewalk_kerb_n",) * 5, ("sidewalk",) * 5, ("sidewalk",) * 5, ("sidewalk_kerb_s",) * 5)),
		("normal road marks", (("road_line_e", "road_line_w") * 3,) * 4),
		("main road marks", (("road_main_line_e", "road_main_line_w") * 3,) * 4),
		("crosswalks", (("crossing_h",) * 5, ("crossing_v",) * 5, ("crossing_main_n",) * 5, ("crossing_main_e",) * 5)),
		("asphalt repeat", (("road",) * 8,) * 4),
	)
	street = Image.new("RGBA", (8 * 32, len(rows) * 4 * 32 + len(rows) * 14), "#222631")
	labeler = ImageDraw.Draw(street)
	y_offset = 0
	for label, grid in rows:
		labeler.text((2, y_offset), label, fill="white", font=font)
		y_offset += 14
		for y, row in enumerate(grid):
			for x, name in enumerate(row):
				street.alpha_composite(compiled[name], (x * 32, y_offset + y * 32))
		y_offset += len(grid) * 32
	street.save(bundle / "street-montage-native.png")
	street.resize((street.width * 4, street.height * 4), Image.Resampling.NEAREST).save(
		bundle / "street-montage-4x.png")
	grass_repeat = Image.new("RGBA", (8 * 32, 4 * 32))
	for y in range(4):
		for x in range(8):
			grass_repeat.alpha_composite(bases["grass"], (x * 32, y * 32))
	grass_repeat.save(bundle / "grass-base-repeat-native.png")
	grass_repeat.resize((grass_repeat.width * 4, grass_repeat.height * 4), Image.Resampling.NEAREST).save(
		bundle / "grass-base-repeat-4x.png")


def _foreground_review(bundle: Path, frozen_tiles: Path, bases: dict[str, Image.Image], layers: dict[str, Image.Image]) -> None:
	"""Show every retained foreground beside its accepted source and recomposed shared-base tile."""
	font = ImageFont.load_default()
	checker = Image.new("RGBA", TILE_SIZE, "#a9a9a9")
	draw_checker = ImageDraw.Draw(checker)
	for y in range(0, 32, 4):
		for x in range(0, 32, 4):
			if (x // 4 + y // 4) % 2:
				draw_checker.rectangle((x, y, x + 3, y + 3), fill="#d8d8d8")
	for surface in ("sidewalk", "road", "alley"):
		items = [name for name in DAMAGE if name.startswith(f"{surface}_")]
		panel = Image.new("RGBA", (6 * 64, 114), "#222631")
		labeler = ImageDraw.Draw(panel)
		for index, name in enumerate(items):
			x, y = index % 6 * 64, index // 6 * 114
			labeler.text((x + 1, y + 1), name.replace(f"{surface}_cracked_", ""), fill="white", font=font)
			original = _load(frozen_tiles / f"{name}.png")
			component = layers[name]
			panel.alpha_composite(original, (x + 16, y + 14))
			panel.alpha_composite(checker, (x + 16, y + 46))
			panel.alpha_composite(component, (x + 16, y + 46))
			panel.alpha_composite(_compose(bases[surface], component), (x + 16, y + 78))
		panel.save(bundle / f"{surface}-damage-original-stencil-recomposed-native.png")
		panel.resize((panel.width * 4, panel.height * 4), Image.Resampling.NEAREST).save(
			bundle / f"{surface}-damage-original-stencil-recomposed-4x.png")
	grass = Image.new("RGBA", (4 * 64, 128), "#222631")
	labeler = ImageDraw.Draw(grass)
	labeler.text((2, 1), "original", fill="white", font=font)
	grass.alpha_composite(_load(frozen_tiles / "grass.png"), (16, 14))
	for index, suffix in enumerate("abc"):
		x = (index + 1) * 64
		labeler.text((x + 1, 1), f"feature {suffix}", fill="white", font=font)
		grass.alpha_composite(checker, (x + 16, 14))
		grass.alpha_composite(layers[f"grass_feature_{suffix}"], (x + 16, 14))
		grass.alpha_composite(bases["grass"], (x + 16, 64))
		grass.alpha_composite(layers[f"grass_feature_{suffix}"], (x + 16, 64))
	grass.save(bundle / "grass-original-features-recomposed-native.png")
	grass.resize((grass.width * 4, grass.height * 4), Image.Resampling.NEAREST).save(
		bundle / "grass-original-features-recomposed-4x.png")


def build(output_dir: Path, input_bundle: Path | None = None) -> None:
	_fresh(output_dir)
	output_dir.mkdir(parents=True)
	frozen_tiles = output_dir / "frozen-inputs/tiles"
	accepted_surface_bases = output_dir / "frozen-inputs/accepted-surface-bases"
	frozen_runtime = output_dir / "frozen-inputs/runtime-targets"
	frozen_svg = output_dir / "frozen-inputs/svg-renders"
	if input_bundle is not None:
		reference = _read_manifest(input_bundle)
		if reference["script_sha256"] != _sha256(Path(__file__)):
			raise ValueError("retained input bundle was built by a different assembly script")
		shutil.copytree(input_bundle / "frozen-inputs", output_dir / "frozen-inputs")
		inputs = reference["inputs"]
	else:
		inputs: dict[str, dict[str, str]] = {}
		for name in FROZEN_NAMES:
			if name == "sidewalk":
				runtime_record = _frozen_git_file(
					SELECTED_SIDEWALK_SOURCE_REVISION,
					"assets/illustrated/svg-transfer/tiles/sidewalk.png",
					frozen_runtime / "sidewalk.png",
				)
			else:
				runtime_record = _copy_frozen(RUNTIME_DIR / f"{name}.png", frozen_runtime / f"{name}.png")
			runtime_record["frozen_path"] = str((frozen_runtime / f"{name}.png").relative_to(output_dir))
			inputs[f"runtime-target:{name}"] = runtime_record
			if name in DAMAGE:
				record = _frozen_git_file(ACCEPTED_DAMAGE_SOURCE_REVISION, f"assets/illustrated/svg-transfer/tiles/{name}.png", frozen_tiles / f"{name}.png")
			elif name == "sidewalk":
				record = _frozen_git_file(
					SELECTED_SIDEWALK_SOURCE_REVISION,
					"assets/illustrated/svg-transfer/tiles/sidewalk.png",
					frozen_tiles / "sidewalk.png",
				)
			else:
				record = _copy_frozen(RUNTIME_DIR / f"{name}.png", frozen_tiles / f"{name}.png")
			record["frozen_path"] = str((frozen_tiles / f"{name}.png").relative_to(output_dir))
			inputs[(f"accepted-damage:{name}" if name in DAMAGE else f"tile:{name}")] = record
		for surface in ("sidewalk", "road", "alley"):
			revision = SELECTED_SIDEWALK_SOURCE_REVISION if surface == "sidewalk" else ACCEPTED_DAMAGE_SOURCE_REVISION
			record = _frozen_git_file(revision, f"assets/illustrated/svg-transfer/tiles/{surface}.png", accepted_surface_bases / f"{surface}.png")
			record["frozen_path"] = str((accepted_surface_bases / f"{surface}.png").relative_to(output_dir))
			inputs[f"accepted-surface-base:{surface}"] = record
		for name in FROZEN_NAMES:
			record = _copy_frozen(SVG_RENDER_DIR / f"{name}-svg.png", frozen_svg / f"{name}-svg.png")
			record["frozen_path"] = str((frozen_svg / f"{name}-svg.png").relative_to(output_dir))
			inputs[f"svg-render:{name}"] = record
		for name in sorted({"sidewalk", "road", "road_main", "alley"}):
			inputs[f"svg-source:{name}"] = {"path": f"assets/tiles/{name}.svg", "sha256": _sha256(ROOT / f"assets/tiles/{name}.svg")}
		for spec in LAYER_SPECS:
			inputs[f"svg-source:{spec.name}"] = {"path": spec.source_svg, "sha256": _sha256(ROOT / spec.source_svg)}
		inputs["selected-sidewalk-authority"] = {
			"revision": SELECTED_SIDEWALK_SOURCE_REVISION,
			"png_blob": SELECTED_SIDEWALK_PNG_BLOB,
			"svg_blob": SELECTED_SIDEWALK_SVG_BLOB,
			"png_sha256": _sha256(frozen_tiles / "sidewalk.png"),
			"svg_sha256": _sha256(ROOT / "assets/tiles/sidewalk.svg"),
		}

	plain_sidewalk = _load(frozen_tiles / "sidewalk.png")
	plain_alley = _load(frozen_tiles / "alley.png")
	grass_seed = _load(frozen_tiles / "grass.png")
	road_seed = _load(frozen_tiles / "road.png")
	plain_asphalt = _mean_rotations(road_seed, ((0, 0),) * 4)
	offset_asphalt = _mean_rotations(road_seed, ASPHALT_OFFSETS)
	# The offset candidate is retained for review.  Use its seam score only when it improves on the
	# non-offset rotational mean, so an offset never wins merely because it looks busier.
	chosen_asphalt = offset_asphalt if _seam_error(offset_asphalt) < _seam_error(plain_asphalt) else plain_asphalt
	# A broad Gaussian blur leaves only soft green variation. Equal quarter-turn averaging then
	# balances its edge brightness while the three preserved illustrated clumps remain independent.
	soft_grass = grass_seed.filter(ImageFilter.GaussianBlur(radius=4)).convert("RGBA")
	grass_base = _mean_rotations(soft_grass, ((0, 0),) * 4)
	bases = {"sidewalk": plain_sidewalk, "road": chosen_asphalt, "alley": plain_alley, "grass": grass_base}
	layers: dict[str, Image.Image] = {}
	layer_records: dict[str, dict[str, object]] = {}
	component_dir = output_dir / "components"
	component_dir.mkdir()
	for spec in LAYER_SPECS:
		if spec.method == "svg-mask":
			# Curb and road paint have functional edge coordinates.  The SVG difference only locates
			# the component; the pixels themselves remain the illustrated PNG's own painted form.
			comparison_base = "sidewalk_kerb_n" if spec.name == "main_edge_red" else spec.base
			mask = _component_mask(spec.source_name, comparison_base, frozen_svg)
			layer = _extract_component(_load(frozen_tiles / f"{spec.source_name}.png"), mask)
		elif spec.method == "paint-color":
			paint = "red" if spec.name == "main_edge_red" else "yellow"
			mask = _paint_mask(_load(frozen_tiles / f"{spec.source_name}.png"), paint)
			layer = _extract_component(_load(frozen_tiles / f"{spec.source_name}.png"), mask)
		else:
			# Damage is deliberately not SVG-stamped: the accepted illustration decides every branch,
			# broken rim, and loose debris pixel by comparison with its accepted source surface.
			mask = _damage_mask(
				spec.source_name, _load(frozen_tiles / f"{spec.source_name}.png"), spec.base,
				_load(frozen_svg / f"{spec.base}-svg.png"),
				_load(accepted_surface_bases / f"{spec.base}.png"),
			)
			layer = _extract_component(_load(frozen_tiles / f"{spec.source_name}.png"), mask)
		layer.save(component_dir / f"{spec.name}.png")
		layers[spec.name] = layer
		layer_records[spec.name] = {
			"base": spec.base,
			"source_svg": spec.source_svg,
			"frozen_illustrated_input": f"frozen-inputs/tiles/{spec.source_name}.png",
			"svg_mask_input": f"frozen-inputs/svg-renders/{spec.source_name}-svg.png",
			"mask_rule": (
				"SVG component placement with a one-pixel illustrated edge rim"
				if spec.method == "svg-mask"
				else "illustrated red/yellow color separation with a one-pixel illustrated edge rim; SVG is provenance only"
				if spec.method == "paint-color"
				else "accepted-source foreground color segmentation; shared-base seam pixels are removed only when they match the accepted base"
			),
			"sha256": _sha256(component_dir / f"{spec.name}.png"),
		}
	for index, suffix in enumerate(("a", "b", "c")):
		name = f"grass_feature_{suffix}"
		layer = _extract_component(grass_seed, _grass_feature_mask(grass_seed, soft_grass, index))
		layer.save(component_dir / f"{name}.png")
		layers[name] = layer
		layer_records[name] = {
			"base": "grass",
			"source_svg": f"assets/tiles/layers/{name}.svg",
			"frozen_illustrated_input": "frozen-inputs/tiles/grass.png",
			"mask_rule": "audited illustrated clump region; retained pixels come from the illustrated grass PNG",
			"sha256": _sha256(component_dir / f"{name}.png"),
		}
	compiled = {"sidewalk": bases["sidewalk"], "road": bases["road"], "road_main": bases["road"]}
	for name in CURBS:
		direction = name.rsplit("_", 1)[1]
		result = _compose(bases["sidewalk"], _oriented(layers["curbstone"], direction))
		if "_main_" in name:
			result = _compose(result, _oriented(layers["main_edge_red"], direction))
		compiled[name] = result
	for name in ROAD_PAINT:
		if name.startswith("road_main_line_"):
			layer = _oriented(layers["yellow_main_line"], name.rsplit("_", 1)[1])
		elif name.startswith("road_line_"):
			layer = _oriented(layers["yellow_half_line"], name.rsplit("_", 1)[1])
		elif name.startswith("crossing_main_"):
			layer = _oriented(layers["main_crosswalk"], name.rsplit("_", 1)[1])
		elif name == "crossing_v":
			layer = layers["crosswalk"].rotate(90, expand=False)
		else:
			layer = layers["crosswalk"]
		compiled[name] = _compose(bases["road"], layer)
	for spec in LAYER_SPECS:
		if spec.name in DAMAGE:
			compiled[spec.name] = _compose(bases[spec.base], layers[spec.name])
	compiled_dir = output_dir / "compiled-tiles"
	compiled_dir.mkdir()
	for name in COMPILED_NAMES:
		compiled[name].save(compiled_dir / f"{name}.png")
	bases_dir = output_dir / "bases"
	bases_dir.mkdir()
	for name, image in bases.items():
		output_name = "asphalt_base" if name == "road" else f"{name}_base"
		image.save(bases_dir / f"{output_name}.png")
	_foreground_review(output_dir, frozen_tiles, bases, layers)
	_panel(output_dir, bases, layers, compiled)
	manifest = {
		"format": 1,
		"python_version": platform.python_version(),
		"pillow_version": PILLOW_VERSION,
		"script_sha256": _sha256(Path(__file__)),
		"tile_size": [32, 32],
		"inputs": inputs,
		"bases": {
			"sidewalk": {
				"frozen_input": "frozen-inputs/tiles/sidewalk.png",
				"source_revision": SELECTED_SIDEWALK_SOURCE_REVISION,
				"source_blob": SELECTED_SIDEWALK_PNG_BLOB,
				"sha256": _sha256(frozen_tiles / "sidewalk.png"),
			},
			"alley": {"frozen_input": "frozen-inputs/tiles/alley.png", "sha256": _sha256(frozen_tiles / "alley.png")},
			"asphalt": {
				"frozen_input": "frozen-inputs/tiles/road.png", "method": "equal channel-wise mean of rotations 0,90,180,270",
				"offset_candidate": list(ASPHALT_OFFSETS), "plain_seam_error": _seam_error(plain_asphalt),
				"offset_seam_error": _seam_error(offset_asphalt), "selected": "offset" if chosen_asphalt == offset_asphalt else "plain",
				"edge_means": _edge_means(chosen_asphalt), "sha256": _sha256(compiled_dir / "road.png"),
			},
			"grass": {
				"frozen_input": "frozen-inputs/tiles/grass.png",
				"method": "Gaussian blur radius 4 followed by equal channel-wise mean of rotations 0,90,180,270",
				"mean_luma": _mean_luma(grass_base), "seam_error": _seam_error(grass_base),
				"edge_means": _edge_means(grass_base),
				"sha256": _sha256(bases_dir / "grass_base.png"),
			},
		},
		"components": layer_records,
		"compiled": {name: _sha256(compiled_dir / f"{name}.png") for name in COMPILED_NAMES},
	}
	(output_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def _read_manifest(bundle: Path) -> dict[str, object]:
	return json.loads((bundle / "manifest.json").read_text())


def _engine_contract(bundle: Path) -> dict[str, object]:
	"""Return the one source-ID-to-layer contract consumed by the engine."""
	components = {name: f"{name}.png" for name in _read_manifest(bundle)["components"]}
	source_layers: dict[str, list[dict[str, object]]] = {}
	rotations = {"n": 0, "e": 90, "s": 180, "w": 270}
	for source_id, direction in ((8, "n"), (9, "s"), (10, "e"), (11, "w")):
		source_layers[str(source_id)] = [{"component": "curbstone", "rotation_degrees": rotations[direction]}]
	for source_id, direction in ((26, "n"), (27, "s"), (28, "e"), (29, "w")):
		source_layers[str(source_id)] = [
			{"component": "curbstone", "rotation_degrees": rotations[direction]},
			{"component": "main_edge_red", "rotation_degrees": rotations[direction]},
		]
	for source_id, direction in ((1, "e"), (2, "w"), (3, "n"), (4, "s")):
		source_layers[str(source_id)] = [{"component": "yellow_half_line", "rotation_degrees": rotations[direction]}]
	for source_id, direction in ((22, "e"), (23, "w"), (24, "n"), (25, "s")):
		source_layers[str(source_id)] = [{"component": "yellow_main_line", "rotation_degrees": rotations[direction]}]
	source_layers["6"] = [{"component": "crosswalk", "rotation_degrees": 0}]
	source_layers["5"] = [{"component": "crosswalk", "rotation_degrees": 90}]
	for source_id, direction in ((36, "n"), (37, "s"), (38, "w"), (39, "e")):
		source_layers[str(source_id)] = [{"component": "main_crosswalk", "rotation_degrees": rotations[direction]}]
	for source_id, name in zip(range(40, 46), (name for name in DAMAGE if name.startswith("road_")), strict=True):
		source_layers[str(source_id)] = [{"component": name, "rotation_degrees": 0}]
	for source_id, name in zip(range(46, 52), (name for name in DAMAGE if name.startswith("sidewalk_")), strict=True):
		source_layers[str(source_id)] = [{"component": name, "rotation_degrees": 0}]
	for source_id, name in zip(range(52, 58), (name for name in DAMAGE if name.startswith("alley_")), strict=True):
		source_layers[str(source_id)] = [{"component": name, "rotation_degrees": 0}]
	return {
		"version": 1,
		"tile_size": 32,
		"bases": {"sidewalk": "sidewalk_base.png", "asphalt": "asphalt_base.png", "alley": "alley_base.png", "grass": "grass_base.png"},
		"source_bases": {
			"0": "asphalt", "1": "asphalt", "2": "asphalt", "3": "asphalt", "4": "asphalt", "5": "asphalt", "6": "asphalt",
			"7": "sidewalk", "8": "sidewalk", "9": "sidewalk", "10": "sidewalk", "11": "sidewalk", "12": "grass", "14": "alley",
			"21": "asphalt", "22": "asphalt", "23": "asphalt", "24": "asphalt", "25": "asphalt", "26": "sidewalk", "27": "sidewalk", "28": "sidewalk", "29": "sidewalk",
			"36": "asphalt", "37": "asphalt", "38": "asphalt", "39": "asphalt",
			**{str(source_id): "asphalt" for source_id in range(40, 46)},
			**{str(source_id): "sidewalk" for source_id in range(46, 52)},
			**{str(source_id): "alley" for source_id in range(52, 58)},
		},
		"components": components,
		"source_layers": source_layers,
		"grass_features": [f"grass_feature_{suffix}" for suffix in "abc"],
	}


def verify(bundle: Path, component_dir: Path | None) -> None:
	manifest = _read_manifest(bundle)
	if manifest["script_sha256"] != _sha256(Path(__file__)):
		raise ValueError("assembly script differs from the retained authority")
	for key, record in manifest["inputs"].items():
		if "frozen_path" in record and _sha256(bundle / record["frozen_path"]) != record["sha256"]:
			raise ValueError(f"frozen input differs from authority: {record['frozen_path']}")
		if key.startswith("svg-source:"):
			path = ROOT / record["path"]
			if _sha256(path) != record["sha256"]:
				raise ValueError(f"SVG source differs from authority: {path}")
	for name, expected in manifest["components"].items():
		path = bundle / "components" / f"{name}.png"
		if _sha256(path) != expected["sha256"]:
			raise ValueError(f"component differs: {name}")
		if _load(path).getchannel("A").getextrema()[0] != 0:
			raise ValueError(f"component is not transparent: {name}")
	for name, expected in manifest["compiled"].items():
		path = bundle / "compiled-tiles" / f"{name}.png"
		if _sha256(path) != expected:
			raise ValueError(f"compiled tile differs: {name}")
		if _load(path).getchannel("A").getextrema() != (255, 255):
			raise ValueError(f"compiled tile is not opaque: {name}")
	if component_dir is not None:
		for name, expected in manifest["bases"].items():
			if name == "asphalt":
				filename = "asphalt_base.png"
			else:
				filename = f"{name}_base.png"
			if _sha256(component_dir / filename) != expected["sha256"]:
				raise ValueError(f"published base differs: {filename}")
		for name, expected in manifest["components"].items():
			if _sha256(component_dir / f"{name}.png") != expected["sha256"]:
				raise ValueError(f"published component differs: {name}")
		if json.loads((component_dir / "manifest.json").read_text()) != _engine_contract(bundle):
			raise ValueError("published engine manifest differs from the retained contract")


def publish(bundle: Path, component_dir: Path) -> None:
	"""Publish bases and transparent layers only; compiled tiles are evidence, never runtime assets."""
	verify(bundle, None)
	if component_dir.exists():
		raise ValueError(f"refusing to replace existing component directory: {component_dir}")
	component_dir.mkdir(parents=True)
	manifest_path = component_dir / "manifest.json"
	for source in sorted((bundle / "bases").glob("*.png")) + sorted((bundle / "components").glob("*.png")):
		shutil.copyfile(source, component_dir / source.name)
	manifest_path.write_text(json.dumps(_engine_contract(bundle), indent=2) + "\n")
	verify(bundle, component_dir)


def install_grass_base(bundle: Path, component_dir: Path, replace: bool) -> None:
	"""Replace only the verified grass base while preserving the published layer contract."""
	if not replace:
		raise ValueError("grass-base replacement requires --replace")
	verify(bundle, None)
	contract = _engine_contract(bundle)
	if json.loads((component_dir / "manifest.json").read_text()) != contract:
		raise ValueError("published engine manifest differs from the retained contract")
	for name, expected in _read_manifest(bundle)["bases"].items():
		filename = "asphalt_base.png" if name == "asphalt" else f"{name}_base.png"
		if name != "grass" and _sha256(component_dir / filename) != expected["sha256"]:
			raise ValueError(f"published base differs: {filename}")
	for name, expected in _read_manifest(bundle)["components"].items():
		if _sha256(component_dir / f"{name}.png") != expected["sha256"]:
			raise ValueError(f"published component differs: {name}")
	shutil.copyfile(bundle / "bases/grass_base.png", component_dir / "grass_base.png")
	verify(bundle, component_dir)


def install_sidewalk_floor(bundle: Path, component_dir: Path, replace: bool) -> None:
	"""Replace the verified shared sidewalk floor in both runtime resolver locations."""
	if not replace:
		raise ValueError("sidewalk-floor replacement requires --replace")
	verify(bundle, None)
	manifest = _read_manifest(bundle)
	if json.loads((component_dir / "manifest.json").read_text()) != _engine_contract(bundle):
		raise ValueError("published engine manifest differs from the retained contract")
	for name, expected in manifest["bases"].items():
		filename = "asphalt_base.png" if name == "asphalt" else f"{name}_base.png"
		if name != "sidewalk" and _sha256(component_dir / filename) != expected["sha256"]:
			raise ValueError(f"published base differs: {filename}")
	for name, expected in manifest["components"].items():
		if _sha256(component_dir / f"{name}.png") != expected["sha256"]:
			raise ValueError(f"published component differs: {name}")
	selected = bundle / manifest["bases"]["sidewalk"]["frozen_input"]
	if _sha256(selected) != manifest["bases"]["sidewalk"]["sha256"]:
		raise ValueError("selected sidewalk floor differs from retained authority")
	shutil.copyfile(selected, RUNTIME_DIR / "sidewalk.png")
	shutil.copyfile(selected, component_dir / "sidewalk_base.png")
	verify(bundle, component_dir)


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	subparsers = parser.add_subparsers(dest="command", required=True)
	build_parser = subparsers.add_parser("build", help="freeze inputs and build a new evidence bundle")
	build_parser.add_argument("--output-dir", type=Path, required=True)
	build_parser.add_argument("--input-bundle", type=Path, help="rebuild solely from an existing bundle's frozen inputs")
	verify_parser = subparsers.add_parser("verify", help="verify a retained bundle and optional published components")
	verify_parser.add_argument("--bundle-dir", type=Path, required=True)
	verify_parser.add_argument("--component-dir", type=Path)
	publish_parser = subparsers.add_parser("publish", help="publish bases and transparent components without runtime composites")
	publish_parser.add_argument("--bundle-dir", type=Path, required=True)
	publish_parser.add_argument("--component-dir", type=Path, required=True)
	install_parser = subparsers.add_parser("install-grass-base", help="replace one verified grass base in an existing component directory")
	install_parser.add_argument("--bundle-dir", type=Path, required=True)
	install_parser.add_argument("--component-dir", type=Path, required=True)
	install_parser.add_argument("--replace", action="store_true")
	sidewalk_parser = subparsers.add_parser("install-sidewalk-floor", help="replace the verified sidewalk floor in both runtime locations")
	sidewalk_parser.add_argument("--bundle-dir", type=Path, required=True)
	sidewalk_parser.add_argument("--component-dir", type=Path, required=True)
	sidewalk_parser.add_argument("--replace", action="store_true")
	arguments = parser.parse_args()
	if arguments.command == "build":
		build(arguments.output_dir.resolve(), arguments.input_bundle.resolve() if arguments.input_bundle else None)
	elif arguments.command == "verify":
		verify(arguments.bundle_dir.resolve(), arguments.component_dir.resolve() if arguments.component_dir else None)
	elif arguments.command == "publish":
		publish(arguments.bundle_dir.resolve(), arguments.component_dir.resolve())
	elif arguments.command == "install-grass-base":
		install_grass_base(arguments.bundle_dir.resolve(), arguments.component_dir.resolve(), arguments.replace)
	else:
		install_sidewalk_floor(arguments.bundle_dir.resolve(), arguments.component_dir.resolve(), arguments.replace)


if __name__ == "__main__":
	main()
