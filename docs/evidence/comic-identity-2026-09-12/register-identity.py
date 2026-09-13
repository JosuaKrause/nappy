"""Register the comic stroller redraw onto the four identity/export PNG contracts."""
from pathlib import Path
from PIL import Image
from PIL import ImageDraw
import json
import argparse

ROOT = Path(__file__).resolve().parents[3]
EVIDENCE = Path(__file__).resolve().parent
RAW = EVIDENCE / "raw" / "stroller-mark-generated.png"


def mark(size: tuple[int, int]) -> Image.Image:
    source = Image.open(RAW).convert("RGBA")
    alpha = source.getchannel("A")
    bounds = alpha.getbbox()
    assert bounds, "generated mark has no alpha"
    source = source.crop(bounds)
    scale = min(size[0] / source.width, size[1] / source.height)
    fitted = source.resize((round(source.width * scale), round(source.height * scale)), Image.Resampling.LANCZOS)
    return fitted


def centered(canvas: Image.Image, artwork: Image.Image, center: tuple[int, int]) -> Image.Image:
    x = center[0] - artwork.width // 2
    y = center[1] - artwork.height // 2
    canvas.alpha_composite(artwork, (x, y))
    return canvas


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, help="new evidence output directory")
    args = parser.parse_args()
    output = args.output.resolve()
    assert not output.exists(), output
    output.mkdir(parents=True)
    (output / "comparisons").mkdir()
    icon = Image.new("RGBA", (640, 640), (0, 0, 0, 0))
    ImageDraw.Draw(icon).rounded_rectangle((0, 0, 639, 639), radius=120, fill="#2b3a4a")
    centered(icon, mark((380, 475)), (320, 320)).save(output / "icon_stroller_640.png")
    wide = Image.new("RGBA", (1280, 640), (0, 0, 0, 0))
    ImageDraw.Draw(wide).rounded_rectangle((320, 0, 959, 639), radius=120, fill="#2b3a4a")
    centered(wide, mark((380, 475)), (640, 320)).save(output / "icon_stroller_1280x640.png")
    logo = Image.open(EVIDENCE / "source-references" / "logo-before.png").convert("RGBA")
    ImageDraw.Draw(logo).rounded_rectangle((492, 30, 788, 325), radius=56, fill="#2b3a4a")
    logo.alpha_composite(mark((296, 295)), (492, 30))
    logo.save(output / "logo.png")
    social = Image.new("RGB", logo.size, "white")
    social.paste(logo, mask=logo.getchannel("A"))
    social.save(output / "social-card.png")
    for path, expected in ((output / "logo.png", (1280, 640)), (output / "social-card.png", (1280, 640)),
                           (output / "icon_stroller_640.png", (640, 640)),
                           (output / "icon_stroller_1280x640.png", (1280, 640))):
        image = Image.open(path)
        assert image.size == expected, (path, image.size)
        image.resize((expected[0] * 2, expected[1] * 2), Image.Resampling.NEAREST).save(
            output / "comparisons" / f"{path.stem}-2x.png")
    (output / "registration.json").write_text(json.dumps({
        "logo.svg": {"png": "assets/logo.png", "canvas": [1280, 640], "stroller_region": [492, 30, 788, 325]},
        "icon_stroller.svg": [
            {"png": "assets/icon_stroller_640.png", "canvas": [640, 640], "anchor": [320, 320]},
            {"png": "assets/icon_stroller_1280x640.png", "canvas": [1280, 640], "anchor": [640, 320]},
        ],
        "social-card.png": {"derived_from": "assets/logo.png", "canvas": [1280, 640], "mode": "RGB", "background": "white"},
    }, indent=2) + "\n")


if __name__ == "__main__":
    main()
