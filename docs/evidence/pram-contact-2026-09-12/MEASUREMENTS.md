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

- `comparison-native.png` and `comparison-8x.png` for the registered illustrated PNG family
- `svg-comparison-native.png` and `svg-comparison-8x.png` for the default SVG family, rasterized
  headlessly through Godot at source resolution

Each 8× image uses nearest-neighbor sampling so individual source pixels remain clear.

Regenerate both from the repository root with:

```sh
UV_CACHE_DIR=/tmp/nappy-pram-uv-cache uv run python \
  docs/evidence/pram-contact-2026-09-12/assemble.py \
  docs/evidence/pram-contact-2026-09-12/comparison-native.png

UV_CACHE_DIR=/tmp/nappy-pram-uv-cache uv run python \
  docs/evidence/pram-contact-2026-09-12/assemble.py \
  docs/evidence/pram-contact-2026-09-12/svg-comparison-native.png \
  --family svg
```

The source art, texture dimensions, collision bodies, navigation, steering, movement costs, and
touch radii are unchanged by this assembly.
