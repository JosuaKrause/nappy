# Comic carrying-mother redraw

This record preserves **D — Matched proportions**, the two-frame carrying redraw requested in
PLAYTEST-65. The ten PNG derivatives use
the same adult woman, directions and gait as the current pushing raster family while replacing her
pushing arms with a secure two-arm cradle. The baby lies horizontally or diagonally in the front,
profile and front-diagonal views. The direct back view hides the baby except for a narrow blanket
edge; the back diagonal exposes only the outside edge of the bundle.
The current runtime carrying family is documented in
[E — Clear strides](../comic-carrying-strides-2026-09-12/GENERATION.md); D remains a fixed identity
reference and comparison snapshot.

The previous carrying result and its provenance remain intact under
`docs/evidence/comic-rig-2026-09-12/`: `mother-atlas-generated.png` is its raw shared atlas and
`registered/rig/mother_carrying_*.png` are the registered snapshots. They document the result the
player rejected and are evidence rather than inputs to this redraw. That prior runtime family is
named **A — Upright bundle**. The human-visible alternatives **B — Round silhouette** and
**C — Alternating stride** are preserved under `versions/` with their raw outputs, exact prompts
and native previews. B and C fix the baby's support but enlarge the head and shorten the adult
proportions. They are comparison evidence, never visual references or inputs to D.

## Generator inputs and selected output

Generator: built-in `image_gen.imagegen`.

The generator inputs, in order, are:

1. `source/pushing-atlas-edit-target.png` — the edit target and binding identity, anatomy, clothing,
   direction, gait, layout and rendering reference. `convert.py prepare` derives it by taking only
   the top two pushing rows, crop `(0, 0, 1194, 658)`, from
   `docs/evidence/comic-rig-2026-09-12/mother-atlas-generated.png`. The rejected carrying rows in
   that source atlas are outside the crop and never reach the generator.
2. `source/carrying-sheet-svg.png` — the authoritative carrying pose, baby direction and occlusion
   reference, copied from the reviewed SVG evidence.
3. `docs/evidence/graphics-reference-urban-01.jpeg` — approved comic style reference only.
4. `docs/evidence/graphics-reference-cardinal.jpeg` — approved comic style reference only.

`prompt.txt` is the exact edit prompt. It directs the generator to preserve each pushing figure's
head, hair, torso, coat, legs, shoes, height, direction and gait while changing only the arms and
chest overlap needed to add the supported baby.

The selected raw result is `carrying-atlas-selected.png`, a 1689×931 RGB image with five columns
(`front`, `back`, `side`, `front_diagonal`, `back_diagonal`) and two rows (`a`, `b`). Its SHA-256 is
`1b79199cfe6be78013804771f61a5279008f5487927fc52d83523208d4146b61`. The requested uniform white
background was delivered without a painted checkerboard. The repository's authorized
`tools/remove-checkerboard.py` removes that connected neutral background into
`registered/carrying-atlas-extracted.png`; inspection over the slate review background found no
retained background grid or fringe.

## Reproducible source preparation and registration

`source/source-manifest.json` records every SVG/PNG pair, SVG hash, native and enlarged source
raster hash, canvas, bottom-center anchor and generated cell. `source/input-manifest.json` records
the pushing crop and approved style-reference roles. Preparation refuses an existing output
directory and fails if any current SVG no longer matches the preserved source raster record.

D's source SVG hashes differ from E's repaired legs. To reproduce D's registration, use its
preserved source checkout first; the source guard intentionally rejects the E checkout:

```sh
git worktree add --detach /tmp/nappy-d-source 92bc41d85a35d0025ec9bfff2e4b9e4c78e8eb05
cd /tmp/nappy-d-source
```

The D walking GIF and four-version comparison use frozen registered inputs and can be rebuilt
from the current checkout using their own recipes; they do not require this source checkout.

Run source preparation with the project lock and a fresh destination:

```sh
uv run python docs/evidence/comic-carrying-redraw-2026-09-12/convert.py prepare \
  /tmp/comic-carrying-redraw-source
```

Register the preserved selected output into another fresh directory:

```sh
uv run python docs/evidence/comic-carrying-redraw-2026-09-12/convert.py register \
  /tmp/comic-carrying-redraw-registration \
  docs/evidence/comic-carrying-redraw-2026-09-12/source \
  docs/evidence/comic-carrying-redraw-2026-09-12/carrying-atlas-selected.png
```

Preparation and registration use CPython 3.14.7 and Pillow 12.3.0 from the locked `uv`
environment. Registration divides the saved output by normalized five-column, two-row bounds,
crops the extracted art, preserves its aspect ratio, gives every figure the same 45-pixel
registered height, centers it on the native canvas and aligns its feet to the unchanged bottom
ground line. The shared 28-color palette comes from the selected carrying art and current pushing
PNGs together.

The script saves generated alpha before extending colors beneath transparent pixels and restores
the same alpha bytes afterward. It does not stamp, intersect or otherwise reuse SVG alpha.
`registered/registration.json` records each fit and verifies generated alpha, aspect ratio, native
canvas size and ground-line preservation. The ten files under `registered/rig/` are byte-for-byte
the selected D snapshot. The runtime uses E's revised leg poses while preserving D's upper-body
pixels and the existing asset resource identities.

## Review sheets

- `registered/carrying-native.png` is the complete five-view, two-frame family at true native
  scale; `registered/carrying-6x.png` enlarges the same pixels without smoothing.
- `registered/identity-family-native.png` compares pushing and carrying states across all eight
  runtime directions, including west mirrors, at native scale;
  `registered/identity-family-5x.png` enlarges that comparison.
- `registered/source-comparison-native.png` pairs every carrying SVG with its registered redraw;
  `registered/source-comparison-5x.png` enlarges the same comparison.

The sheets establish matching adult proportions, source-facing coverage, secure support, back-view
occlusion, true alpha, stable A/B upper bodies, distinct gait feet, equal stature and bottom-center
registration. They do not establish live gameplay motion or player acceptance.
