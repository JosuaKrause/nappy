# Eight-direction SVG-to-PNG generation record

Sources were authored, visually reviewed and committed before generation; commit provenance is
in `docs/DECISIONS.md` under Eight-direction style transfer. `source-manifest.json` maps each PNG to its SVG and
records the exact source hash. The saved raw generator output is RGB with a painted checkerboard;
the preserved extracted output and native derivatives use the existing removal/registration step.

The diagonal source SVGs extend the mother/pram family. They are authored before transfer and
own geometry, colors, pose, direction, silhouette and canvas. The source sheet has three columns
(mother A, mother B, pram) and two rows (front diagonal, back diagonal), with 384×512 cells.
Each source is rasterized by Godot at native size and 8×, centered horizontally in its cell,
with its canvas bottom at y=448. West diagonals mirror the east diagonals explicitly at runtime.

`convert.py prepare <checkout>` saves the source rasters and `diagonal-sheet-svg.png`.
`convert.py register <new-output-directory>` extracts `diagonal-sheet-generated.png` with the
existing checkerboard remover, registers each cell to the 8× SVG bounds, extends retained
colors into transparent areas, downsamples to native size and applies the native SVG alpha.
Both run through `uv run python`. Registration reuses the previous transfer's saved algorithm.
The output includes six `rig/*.png`, measurements and a comparison with SVG left / PNG right.
Equal alpha guarantees silhouette registration, not exact positions of every interior detail.

Reproduce extraction and registration into a new directory:

```sh
uv run python docs/evidence/style-transfer-eight-directions-2026-09-10/convert.py register /tmp/nappy-diagonal-reproduction
```

The `directions <new-image-path>` mode builds the eight-direction SVG/PNG comparison from the
saved native rasters and runtime PNGs at 3×, using the runtime's 34px pram offset and 0.7 Y
projection. It is an assembled source comparison rather than a gameplay capture. Two actual
gameplay captures and their whole telemetry runs are indexed in `docs/DECISIONS.md`.

Generator: built-in `image_gen.imagegen`. Inputs in order: the diagonal SVG sheet as edit target;
`graphics-reference-urban-01.jpeg` and `graphics-reference-cardinal.jpeg` as style references;
the accepted cardinal `rig-sheet-generated.png` as matching-family rendering reference.
The latter reference contains a checkerboard that must not be reproduced as background.

Exact prompt:

> STYLE TRANSFER of IMAGE 1 only, an exact SVG game-sprite atlas. Image 1 owns all geometry, colors, poses and direction. It is 1152x1024, three columns and two rows of 384x512 cells, canvas baseline y448 in every cell. Top row: mother facing southeast three-quarter front pose A, same mother pose B, southeast pram. Bottom row: mother facing northeast three-quarter back pose A, same mother pose B, northeast pram. Images 2 and 3 are STYLE ONLY: fine dark urban comic linework and gently painted fabric/material details; exclude all scenery, UI and debug annotations. Image 4 supplies the already accepted matching-family rendering and identity only; do not copy its cardinal poses, atlas layout or checkerboard. Preserve each sprite's exact silhouette, relative pixel dimensions, full canvas padding, placement, clothing boundaries, head orientation, hands, legs, wheels, hood and every transparent gap from image 1. The diagonal views must remain actual upright three-quarter views, not rotated flat profiles. Same red coat, brown hair, blue jeans, dark shoes, dark navy pram and cream hood. Add fine ink, coat stitching, subtle fabric folds, wheel hubs and restrained shading inside the existing shapes. Keep the same woman across all frames and match image 4's level of rendering. Do not redesign, enlarge, shrink, shift, crop or rearrange anything. No additional objects, floor, cast shadow, text, cell borders, arrows, interface or debug notes. Genuinely transparent RGBA background, no painted checkerboard. Return only the registered restyled atlas with the same aspect ratio and arrangement.
