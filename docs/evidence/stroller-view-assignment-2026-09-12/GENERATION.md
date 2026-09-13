# Stroller view assignment

**Final runtime contract: direction names mean travel direction.** N, NE and NW show the baby
and canopy opening. S, SE and SW show the outside of the hood. E and W retain the original side
image. This is the player's accepted directional interpretation, and it is the authority for
future illustrated stroller work. Upstream `front`/`back` labels are source identifiers, not a
reason to change these runtime directions.

**Do not swap the installed textures again.** The table below describes a transformation from
the immutable `inputs/` images only. `reassign.py` never reads runtime PNGs as its source, so a
rebuild always produces the same final assignment rather than toggling it.

The five registered textures supply eight facings through the runtime's west mirrors.
The side texture keeps its original canopy. The other views are assigned to their opposite
directions: N ↔ S, NE ↔ SW and NW ↔ SE. Because the runtime stores east-facing diagonal slots,
assigning the opposite diagonal requires a horizontal mirror as well as exchanging front/back.

| Runtime slot | Frozen source | Operation |
| --- | --- | --- |
| `pram_side` (E, mirrored W) | `pram_side` | Exact byte copy |
| `pram_front` (S) | `pram_back` | Exact byte copy |
| `pram_back` (N) | `pram_front` | Exact byte copy |
| `pram_front_diagonal` (SE, mirrored SW) | `pram_back_diagonal` | Horizontal mirror |
| `pram_back_diagonal` (NE, mirrored NW) | `pram_front_diagonal` | Horizontal mirror |

`inputs/manifest.json` records the immutable source revision and hashes of all five original
PNGs and their SVG sources. The [comic rig recipe](../comic-rig-2026-09-12/GENERATION.md) owns
upstream generation and registration; this recipe owns the final runtime view assignment.
The [wheel arrangement recipe](../stroller-southern-wheel-swap-2026-09-12/GENERATION.md) owns
the final SE/SW wheel and lower attachment pixels after this assignment and donor extraction.
It reads a hash-checked frozen input; do not exchange installed wheels again. The bundle here
preserves the view assignment inputs; rebuilding it alone does not reproduce the final wheels.
The operation preserves native dimensions, color/alpha pixels and bottom-center anchors, with
no rescaling, redrawing or changes to the mother or the runtime's drawing transforms.

Reproduce from the repository root using the project's locked Pillow environment:

```sh
uv run python docs/evidence/stroller-view-assignment-2026-09-12/reassign.py \
  --output-dir /tmp/stroller-view-rebuild
diff -r docs/evidence/stroller-view-assignment-2026-09-12/bundle /tmp/stroller-view-rebuild
```

The bundle includes all five runtime PNGs, input/output/script hashes and labeled native and
6× nearest-neighbor sheets in order N, NE, E, SE / S, SW, W, NW. Labels use Pillow's default font.
The sheets compare static view assignments; they do not establish animation or live turning.
`--help` and `-h` print usage; unknown arguments and existing output paths are rejected.
