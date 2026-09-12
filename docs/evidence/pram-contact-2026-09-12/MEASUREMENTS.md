# Pram hand-contact assembly

This source-level assembly compares the registered runtime mother and pram PNGs at the former
34px lead and at the proposed presentation offset. It uses both authored pushing gait frames,
mirrors the west-facing views exactly as the game does, and follows the game's canonical draw
order. It does not prove interpolation during a live turn or animation timing.

The proposed continuous offset is:

| Facing | Screen offset from her feet |
|---|---:|
| north | `(0, -13.800)` |
| north-east | `(15.556, -10.930)` |
| east | `(22, -4)` |
| south-east | `(15.556, -0.040)` |
| south | `(0, 1.600)` |

West-facing offsets mirror the X coordinate. The formula uses a 22px horizontal distance, 14px
north distance, 8px south distance, the existing 0.7 Y projection, and a shared 4px upward lift.
The directional term approaches zero continuously at east and west, where the shared lift remains.

The native registered side textures are 26×46px for the mother and 36×30px for the pram. In gait
frame A, her forward hand pixel `(21, 20)` and the handle tip pixel `(4, 8)` both land at `(8, -26)`
relative to her feet after the east-facing placement. In frame B, the closest visible hand and
handle pixels are one native pixel apart. For the authored diagonal views, nearest visible
hand-to-handle pixels are less than half a native pixel apart in both gait frames: about 0.45px at
the north-east and south-east placements. The south-facing hands overlap the handle bar in both
frames. These checks use the visible handle pixels, rather than the hood edge.

The comparison files are:

- `comparison-native.png` and `comparison-8x.png` for the registered illustrated PNG family,
  using the runtime's `facing.y < 0` draw-order rule
- `svg-comparison-native.png` and `svg-comparison-8x.png` for the default SVG family, rasterized
  headlessly through Godot at source resolution and using that same draw-order rule
- `review-snapshot-{png,svg}-{native,8x}.png` for the exact sheets first shown during review

The review snapshots selected draw order from the lifted screen offset, which put the stroller
behind her at east, west, south-east, and south-west even though the runtime selects layering from
the unsquashed facing Y. They remain reproducible records of what was reviewed, while the primary
comparison files correct the assembly to match the runtime. The placement coordinates and contact
measurements are identical in both sets.

Each 8× image uses nearest-neighbor sampling so individual source pixels remain clear.

## Reproducibility record

The recipe does not read the mutable runtime asset folders or the current stroller source. Its
`inputs/png/` and `inputs/svg/` directories preserve the exact 15 pushing-rig inputs from
`assets/illustrated/svg-transfer/rig/` and `assets/rig/` at source commit
`55b566834899c1ac95f7b09cc216064cc50af996`. The former and selected placement values are fixed
inside `assemble.py`. `SHA256SUMS` records every preserved input, the SVG rasterizer, and all four
primary outputs plus the four review snapshots; the recipe refuses a missing or changed input and
refuses an output whose byte hash differs.

The Python assembly ran through uv 0.12.10 with Python 3.14.7 and Pillow 12.3.0. The repository
environment files used for that run have these hashes:

| File | SHA-256 |
|---|---|
| `.python-version` | `a876e0b10411037a012498b9fe18d9bc1df32ed8b722a13564dc944ddcfd9135` |
| `pyproject.toml` | `443e80e1b9adf1bc25fd1ce97b6a64e172b58bb864acd63c83a7ba4cf111f077` |
| `uv.lock` | `6170c24b1300fb0447a2f10a3f72049dd42fec8f30bdbfd93a1b94439a078bb2` |

Labels use Pillow's embedded Aileron Regular font at 10px through an explicit
`ImageFont.load_default()` call; there is no system-font fallback. The native sheet is 642×286 RGBA
on `#68767c`, and the enlarged sheet is exactly 8× using nearest-neighbor sampling.

SVG inputs are rasterized one at a time with Godot 4.7.2.stable.official.ed1daf0bf and the preserved
`rasterize-svg.gd` at scale 1. The script checks that exact Godot version before running this command
shape for each source name:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path <repository-root> \
  --script docs/evidence/pram-contact-2026-09-12/rasterize-svg.gd -- \
  docs/evidence/pram-contact-2026-09-12/inputs/svg/<name>.svg \
  <temporary-directory>/<name>.png 1
```

Regenerate both from the repository root with:

```sh
UV_CACHE_DIR=/tmp/nappy-pram-uv-cache uv run --frozen python \
  docs/evidence/pram-contact-2026-09-12/assemble.py \
  docs/evidence/pram-contact-2026-09-12/comparison-native.png

UV_CACHE_DIR=/tmp/nappy-pram-uv-cache uv run --frozen python \
  docs/evidence/pram-contact-2026-09-12/assemble.py \
  docs/evidence/pram-contact-2026-09-12/svg-comparison-native.png \
  --family svg

UV_CACHE_DIR=/tmp/nappy-pram-uv-cache uv run --frozen python \
  docs/evidence/pram-contact-2026-09-12/assemble.py \
  docs/evidence/pram-contact-2026-09-12/review-snapshot-png-native.png \
  --draw-order offset-snapshot

UV_CACHE_DIR=/tmp/nappy-pram-uv-cache uv run --frozen python \
  docs/evidence/pram-contact-2026-09-12/assemble.py \
  docs/evidence/pram-contact-2026-09-12/review-snapshot-svg-native.png \
  --family svg --draw-order offset-snapshot
```

The source art, texture dimensions, collision bodies, navigation, steering, movement costs, and
touch radii are unchanged by this assembly.
