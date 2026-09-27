"""Rebuild and verify the targeted walked-dog gait correction.

Usage:
  uv run python assemble.py inputs
  uv run python assemble.py candidates
  uv run python assemble.py verify

Image generation is nondeterministic. This script reads its retained outputs and never refreshes
the frozen manifests that authorize its deterministic stages.
"""

from __future__ import annotations

import hashlib
import io
import json
import sys
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont


HERE = Path(__file__).resolve().parent
BASE = HERE.parent
ROOT = HERE.parents[3]
SOURCE_INPUT_MANIFEST = HERE / "source-input-manifest.json"
INPUT_MANIFEST = HERE / "input-manifest.json"
RENDERS = BASE / "source-renders" / "art" / "events"
BASE_CANDIDATES = BASE / "candidates" / "dog"
BASE_CROPS = BASE / "crops" / "dog"
TILES = ROOT / "art" / "illustrated" / "svg-transfer" / "tiles"
PAPER = (238, 235, 228, 255)
INK = (42, 34, 38, 255)
GOLD = (210, 164, 58, 255)
AFFECTED = ("dog", "dog_front_diagonal", "dog_back_diagonal")
PAIRED_NAMES = tuple(name for base in AFFECTED for name in (base, f"{base}_b"))
LABELS = (
    "SIDE A", "SIDE B", "FRONT DIAGONAL A", "FRONT DIAGONAL B",
    "BACK DIAGONAL A", "BACK DIAGONAL B",
)
B_CELL_BOUNDS = ((0, 0, 700, 724), (700, 0, 1430, 724), (1430, 0, 2172, 724))


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def repo_path(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def source_path(name: str) -> Path:
    return ROOT / "art" / "events" / f"{name}.svg"


def source_inputs() -> dict[str, str]:
    result: dict[str, str] = {}
    for name in PAIRED_NAMES:
        result[repo_path(BASE_CROPS / f"{name}.png")] = "defective_target_crop"
        result[repo_path(RENDERS / f"{name}@6.png")] = "authoritative_pose_raster"
    return result


def accepted_charging_paths() -> list[Path]:
    paths = [
        BASE / "raw" / "charging-dog-grid.png",
        BASE / "review-charging-dog.png",
        BASE / "pose-comparison-charging-dog.gif",
    ]
    paths.extend(sorted((BASE / "crops" / "charging-dog").glob("*.png")))
    paths.extend(sorted((BASE / "candidates" / "charging-dog").glob("*.png")))
    return paths


def derivative_inputs() -> dict[str, str]:
    result = {
        repo_path(HERE / "inputs" / "defective-target-grid.png"): "generation_reference_grid",
        repo_path(HERE / "inputs" / "authoritative-pose-grid.png"): "generation_reference_grid",
        repo_path(HERE / "raw" / "attempt-1.png"): "shown_rejected_generation",
        repo_path(HERE / "raw" / "attempt-2-b-frames.png"): "selected_generation",
        repo_path(BASE / "raw" / "walked-dog-grid.png"): "preserved_first_pass_raw",
        repo_path(BASE / "review-dog.png"): "preserved_first_pass_review",
        repo_path(BASE / "pose-comparison-dog.gif"): "preserved_first_pass_review",
        "docs/style-references/graphics-reference-urban-01.jpeg": "style_reference",
        "docs/style-references/graphics-reference-cardinal.jpeg": "style_reference",
        repo_path(TILES / "sidewalk.png"): "comparison_background",
        repo_path(TILES / "road.png"): "comparison_background",
    }
    for name in PAIRED_NAMES:
        result[repo_path(source_path(name))] = "svg_source"
        result[repo_path(RENDERS / f"{name}@1.png")] = "registration_source_raster"
    for path in sorted(BASE_CANDIDATES.glob("*.png")):
        result[repo_path(path)] = "preserved_first_pass_walked_candidate"
    for path in sorted(BASE_CROPS.glob("*.png")):
        result[repo_path(path)] = "preserved_first_pass_walked_crop"
    for path in accepted_charging_paths():
        result[repo_path(path)] = "accepted_charging_artifact"
    return result


def manifest_entries(path: Path) -> dict[str, dict[str, str]]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise SystemExit(f"missing frozen manifest: {path}") from None
    except json.JSONDecodeError as error:
        raise SystemExit(f"invalid frozen manifest {path}: {error}") from None
    if document.get("schema") != 1 or not isinstance(document.get("inputs"), list):
        raise SystemExit(f"{path}: expected schema 1 and an inputs list")
    entries: dict[str, dict[str, str]] = {}
    for item in document["inputs"]:
        if not isinstance(item, dict):
            raise SystemExit(f"{path}: every input must be an object")
        relative = item.get("path")
        role = item.get("role")
        digest = item.get("sha256")
        if not all(isinstance(value, str) for value in (relative, role, digest)):
            raise SystemExit(f"{path}: every input needs string path, role, and sha256")
        if relative in entries:
            raise SystemExit(f"{path}: duplicate input path: {relative}")
        entries[relative] = item
    return entries


def preflight(path: Path, expected: dict[str, str]) -> None:
    entries = manifest_entries(path)
    missing = sorted(set(expected) - set(entries))
    extra = sorted(set(entries) - set(expected))
    if missing or extra:
        raise SystemExit(f"{path}: path set drift; missing={missing}, extra={extra}")
    for relative, role in expected.items():
        item = entries[relative]
        if item["role"] != role:
            raise SystemExit(f"{path}: {relative} role {item['role']!r}, expected {role!r}")
        target = ROOT / relative
        if not target.is_file():
            raise SystemExit(f"frozen input missing: {relative}")
        actual = sha256(target)
        if actual != item["sha256"]:
            raise SystemExit(
                f"frozen input changed: {relative}; expected {item['sha256']}, got {actual}")
    print(f"verified {len(expected)} frozen inputs from {path.name}")


def png_bytes(image: Image.Image) -> bytes:
    buffer = io.BytesIO()
    image.save(buffer, format="PNG", optimize=True)
    return buffer.getvalue()


def input_sheet(source: bool) -> Image.Image:
    cell_w, cell_h = 520, 390
    result = Image.new("RGBA", (cell_w * 3, cell_h * 2), PAPER)
    draw = ImageDraw.Draw(result)
    font = ImageFont.load_default()
    for index, (name, label) in enumerate(zip(PAIRED_NAMES, LABELS)):
        column = index // 2
        row = index % 2
        x0, y0 = column * cell_w, row * cell_h
        draw.rectangle(
            (x0, y0, x0 + cell_w - 1, y0 + cell_h - 1),
            outline=(166, 158, 151, 255), width=2)
        draw.text((x0 + 12, y0 + 10), label, fill=INK, font=font)
        if source:
            image = Image.open(RENDERS / f"{name}@6.png").convert("RGBA")
            image = image.resize(
                (round(image.width * 1.7), round(image.height * 1.7)),
                Image.Resampling.NEAREST)
        else:
            image = Image.open(BASE_CROPS / f"{name}.png").convert("RGBA")
        x = x0 + (cell_w - image.width) // 2
        y = y0 + cell_h - 28 - image.height
        result.alpha_composite(image, (x, y))
    return result.convert("RGB")


def build_inputs() -> None:
    preflight(SOURCE_INPUT_MANIFEST, source_inputs())
    expected = manifest_entries(INPUT_MANIFEST)
    outputs = {
        HERE / "inputs" / "defective-target-grid.png": png_bytes(input_sheet(False)),
        HERE / "inputs" / "authoritative-pose-grid.png": png_bytes(input_sheet(True)),
    }
    for path, data in outputs.items():
        relative = repo_path(path)
        if relative not in expected or sha256_bytes(data) != expected[relative]["sha256"]:
            raise SystemExit(f"rebuilt generation reference differs from frozen hash: {relative}")
    for path, data in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        print(path)


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    box = image.convert("RGBA").getchannel("A").getbbox()
    if box is None:
        raise SystemExit("image has no visible alpha")
    return box


def meaningful_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    mask = image.getchannel("A").point(lambda value: 255 if value > 10 else 0)
    box = mask.getbbox()
    if box is None:
        raise SystemExit("correction cell has no alpha above 10")
    return (
        max(0, box[0] - 2), max(0, box[1] - 2),
        min(image.width, box[2] + 2), min(image.height, box[3] + 2),
    )


def tiled(kind: str, width: int, height: int, scale: int) -> Image.Image:
    tile = Image.open(TILES / f"{kind}.png").convert("RGBA")
    tile = tile.resize((tile.width * scale, tile.height * scale), Image.Resampling.NEAREST)
    result = Image.new("RGBA", (width, height))
    for y in range(0, height, tile.height):
        for x in range(0, width, tile.width):
            result.alpha_composite(tile, (x, y))
    return result


def selected_candidate(name: str, phase_b: bool) -> Path:
    if phase_b and name in AFFECTED:
        return HERE / "candidates" / f"{name}_b.png"
    selected = f"{name}_b" if phase_b else name
    return BASE_CANDIDATES / f"{selected}.png"


def facing_entries() -> tuple[tuple[str, bool, str], ...]:
    return (
        ("dog", False, "E"), ("dog_front_diagonal", False, "SE"),
        ("dog_front", False, "S"), ("dog_front_diagonal", True, "SW"),
        ("dog", True, "W"), ("dog_back_diagonal", True, "NW"),
        ("dog_back", False, "N"), ("dog_back_diagonal", False, "NE"),
    )


def lineup(phase_b: bool, scale: int, affected_only: bool = False) -> Image.Image:
    entries = facing_entries()
    if affected_only:
        entries = (
            ("dog", False, "E"), ("dog", True, "W"),
            ("dog_front_diagonal", False, "SE"),
            ("dog_front_diagonal", True, "SW"),
            ("dog_back_diagonal", False, "NE"),
            ("dog_back_diagonal", True, "NW"),
        )
    images: list[Image.Image] = []
    for name, mirror, _label in entries:
        image = Image.open(selected_candidate(name, phase_b)).convert("RGBA")
        if mirror:
            image = image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        images.append(image.resize(
            (image.width * scale, image.height * scale), Image.Resampling.NEAREST))
    gap = 10 * scale
    width = gap + sum(image.width + gap for image in images)
    height = 28 + max(image.height for image in images) + 10
    result = tiled("sidewalk", width, height, scale)
    draw = ImageDraw.Draw(result)
    title = (
        "ASSEMBLED A/B AFFECTED FACINGS - NOT LIVE GAMEPLAY"
        if affected_only else "ASSEMBLED A/B COMPARISON - NOT LIVE GAMEPLAY"
    )
    draw.text((4, 4), title, fill=INK, font=ImageFont.load_default())
    x = gap
    for image, (_name, _mirror, label) in zip(images, entries):
        draw.text((x, 16), label, fill=INK, font=ImageFont.load_default())
        result.alpha_composite(image, (x, height - 10 - image.height))
        x += image.width + gap
    return result.convert("RGB")


def save_loop(name: str, affected_only: bool) -> list[Image.Image]:
    frames = [lineup(False, 6, affected_only), lineup(True, 6, affected_only)]
    frames[0].save(
        HERE / "review" / f"{name}.gif", save_all=True, append_images=frames[1:],
        duration=450, loop=0, optimize=False)
    return frames


def save_sheet(name: str, frames: list[Image.Image]) -> None:
    width = max(frame.width for frame in frames)
    height = sum(frame.height for frame in frames) + 24
    sheet = Image.new("RGB", (width, height), PAPER[:3])
    draw = ImageDraw.Draw(sheet)
    draw.text((4, 2), "A", fill=INK[:3], font=ImageFont.load_default())
    sheet.paste(frames[0], (0, 12))
    draw.text((4, frames[0].height + 14), "B", fill=INK[:3], font=ImageFont.load_default())
    sheet.paste(frames[1], (0, frames[0].height + 24))
    sheet.save(HERE / "review" / f"{name}.png", optimize=True)


def enlarged_overrides() -> None:
    cell_w, cell_h = 380, 330
    result = Image.new("RGBA", (cell_w * 3, cell_h * 2), PAPER)
    draw = ImageDraw.Draw(result)
    font = ImageFont.load_default()
    for index, base in enumerate(AFFECTED):
        for row, phase_b in enumerate((False, True)):
            name = f"{base}_b" if phase_b else base
            path = HERE / "crops" / f"{name}.png" if phase_b else BASE_CROPS / f"{name}.png"
            image = Image.open(path).convert("RGBA")
            max_w, max_h = cell_w - 20, cell_h - 36
            fit = min(max_w / image.width, max_h / image.height, 1.0)
            if fit < 1.0:
                image = image.resize(
                    (round(image.width * fit), round(image.height * fit)),
                    Image.Resampling.LANCZOS)
            x0, y0 = index * cell_w, row * cell_h
            x = x0 + (cell_w - image.width) // 2
            y = y0 + cell_h - 20 - image.height
            result.alpha_composite(image, (x, y))
            draw.line((x0, y0 + cell_h - 20, x0 + cell_w - 1, y0 + cell_h - 20), fill=GOLD)
            draw.text((x0 + 5, y0 + 5), name, fill=INK, font=font)
    result.convert("RGB").save(HERE / "review" / "affected-high-resolution.png", optimize=True)


def build_candidates() -> None:
    preflight(SOURCE_INPUT_MANIFEST, source_inputs())
    preflight(INPUT_MANIFEST, derivative_inputs())
    raw = Image.open(HERE / "raw" / "attempt-2-b-frames.png").convert("RGBA")
    records: list[dict[str, Any]] = []
    (HERE / "crops").mkdir(parents=True, exist_ok=True)
    (HERE / "candidates").mkdir(parents=True, exist_ok=True)
    (HERE / "review").mkdir(parents=True, exist_ok=True)
    for base, bounds in zip(AFFECTED, B_CELL_BOUNDS):
        name = f"{base}_b"
        cell = raw.crop(bounds)
        crop_box = meaningful_bbox(cell)
        crop = cell.crop(crop_box)
        crop_path = HERE / "crops" / f"{name}.png"
        crop.save(crop_path, optimize=True)
        source_images = [
            Image.open(RENDERS / f"{member}@1.png").convert("RGBA")
            for member in (base, name)
        ]
        source_boxes = [alpha_bbox(image) for image in source_images]
        target = (
            min(box[0] for box in source_boxes), min(box[1] for box in source_boxes),
            max(box[2] for box in source_boxes), max(box[3] for box in source_boxes),
        )
        scale = min((target[2] - target[0]) / crop.width, (target[3] - target[1]) / crop.height)
        fitted = crop.resize(
            (max(1, round(crop.width * scale)), max(1, round(crop.height * scale))),
            Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", source_images[1].size)
        x = round((target[0] + target[2] - fitted.width) / 2)
        y = target[3] - fitted.height
        canvas.alpha_composite(fitted, (x, y))
        candidate_path = HERE / "candidates" / f"{name}.png"
        canvas.save(candidate_path, optimize=True)
        records.append({
            "name": name,
            "replaces": repo_path(BASE_CANDIDATES / f"{name}.png"),
            "replaced_sha256": sha256(BASE_CANDIDATES / f"{name}.png"),
            "candidate": repo_path(candidate_path),
            "candidate_sha256": sha256(candidate_path),
            "source": repo_path(source_path(name)),
            "source_sha256": sha256(source_path(name)),
            "native_size": list(canvas.size),
            "raw_cell_bounds": list(bounds),
            "crop_bounds_in_cell": list(crop_box),
            "crop": repo_path(crop_path),
            "crop_sha256": sha256(crop_path),
            "source_pair_union_bounds": list(target),
            "raw_to_native_scale": scale,
            "candidate_position": [x, y],
            "candidate_alpha_bounds": list(alpha_bbox(canvas)),
        })
    affected_frames = save_loop("affected-a-b", True)
    save_sheet("affected-a-b-sheet", affected_frames)
    current_frames = save_loop("current-walked-a-b", False)
    save_sheet("current-walked-a-b-sheet", current_frames)
    enlarged_overrides()
    review_files = sorted((HERE / "review").iterdir())
    preserved = {
        "unaffected_walked_cardinals": {
            name: sha256(BASE_CANDIDATES / f"{name}.png")
            for name in ("dog_front", "dog_front_b", "dog_back", "dog_back_b")
        },
        "all_walked_a_frames": {
            name: sha256(BASE_CANDIDATES / f"{name}.png") for name in AFFECTED
        },
        "accepted_charging_artifacts": {
            repo_path(path): sha256(path) for path in accepted_charging_paths()
        },
    }
    manifest = {
        "recipe": "Three B-only overrides extracted from the selected raw with alpha > 10 for framing and original alpha preserved; each fits proportionally into its SVG pair-union bounds, then center/bottom aligns on the native canvas. All A frames, walked cardinals, and charging artifacts remain first-pass bytes.",
        "selected_raw": repo_path(HERE / "raw" / "attempt-2-b-frames.png"),
        "selected_raw_sha256": sha256(HERE / "raw" / "attempt-2-b-frames.png"),
        "overrides": records,
        "preserved": preserved,
        "reviews": {repo_path(path): sha256(path) for path in review_files},
    }
    (HERE / "revision-manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    for path in review_files:
        print(path)


def verify() -> None:
    preflight(SOURCE_INPUT_MANIFEST, source_inputs())
    preflight(INPUT_MANIFEST, derivative_inputs())
    manifest = json.loads((HERE / "revision-manifest.json").read_text(encoding="utf-8"))
    if manifest.get("selected_raw_sha256") != sha256(HERE / "raw" / "attempt-2-b-frames.png"):
        raise SystemExit("selected correction raw hash drift")
    records = manifest.get("overrides", [])
    if [record.get("name") for record in records] != [f"{name}_b" for name in AFFECTED]:
        raise SystemExit("expected exactly the three affected B-frame overrides")
    for record in records:
        candidate = ROOT / record["candidate"]
        crop = ROOT / record["crop"]
        if sha256(candidate) != record["candidate_sha256"] or sha256(crop) != record["crop_sha256"]:
            raise SystemExit(f"{record['name']}: derivative hash drift")
        image = Image.open(candidate).convert("RGBA")
        if list(image.size) != record["native_size"]:
            raise SystemExit(f"{record['name']}: native size drift")
        low, high = image.getchannel("A").getextrema()
        if low != 0 or high == 0:
            raise SystemExit(f"{record['name']}: expected real transparent and visible alpha")
    preserved = manifest["preserved"]
    for name, digest in preserved["unaffected_walked_cardinals"].items():
        if sha256(BASE_CANDIDATES / f"{name}.png") != digest:
            raise SystemExit(f"unaffected walked cardinal changed: {name}")
    for name, digest in preserved["all_walked_a_frames"].items():
        if sha256(BASE_CANDIDATES / f"{name}.png") != digest:
            raise SystemExit(f"walked A frame changed: {name}")
    for relative, digest in preserved["accepted_charging_artifacts"].items():
        if sha256(ROOT / relative) != digest:
            raise SystemExit(f"accepted charging artifact changed: {relative}")
    required_reviews = (
        "affected-a-b.gif", "affected-a-b-sheet.png", "current-walked-a-b.gif",
        "current-walked-a-b-sheet.png", "affected-high-resolution.png",
    )
    for name in required_reviews:
        path = HERE / "review" / name
        if not path.is_file():
            raise SystemExit(f"missing review artifact: {name}")
        if manifest.get("reviews", {}).get(repo_path(path)) != sha256(path):
            raise SystemExit(f"review artifact hash drift: {name}")
    print(
        "verified three native B overrides with true alpha; all walked A/cardinal and accepted "
        "charging hashes unchanged; five correction reviews present")


def main() -> None:
    if len(sys.argv) != 2 or sys.argv[1] in {"-h", "--help"}:
        print(__doc__)
        raise SystemExit(0 if len(sys.argv) == 2 else 2)
    command = sys.argv[1]
    if command == "inputs":
        build_inputs()
    elif command == "candidates":
        build_candidates()
    elif command == "verify":
        verify()
    else:
        raise SystemExit(f"unknown command: {command}")


if __name__ == "__main__":
    main()
