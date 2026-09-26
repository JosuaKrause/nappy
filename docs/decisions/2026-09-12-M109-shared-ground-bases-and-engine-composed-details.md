## M109 — Shared ground bases and engine-composed details — 2026-09-12

PLAYTEST-65 replaces independently textured ground variants with one base per material and
transparent detail layers. Sidewalks share one floor beneath curbstones, red main-street edge
paint and damage. Normal and main roads share one asphalt beneath yellow lines and crosswalks;
alleys have their own base. The player explicitly places those blends, and grass-feature placement,
inside the engine. Only smoothing the asphalt base is an offline graphics operation.

The asphalt recipe averages the normal-road texture at 0°, 90°, 180° and 270° with equal channel
weights. A wrapped-offset candidate uses offsets (0,0), (16,16), (8,24) and (24,8). Comparing
opposite edge pixels in both axes gives mean absolute RGB errors of 0.625 for the plain rotational
mean and 0.792 for the offset candidate. The plain mean is selected; each edge's mean RGB-channel
brightness is 73.5625. Repeated native and enlarged previews show no directional brightness skip.

All eighteen sidewalk, road and alley hairline/cracked/broken A/B damage stencils retain the
illustrated artwork accepted by the player from 83a60d1522574714ce038dff3a607a536d800614.
Independent-base image differences retained too much floor, and tight color thresholds broke
fissures into dots. Audited foreground regions and color segmentation preserve the original crack,
hole, debris and growth pixels while excluding floor-only joints. Three complete grass clumps are
extracted from the illustrated grass tile; a Gaussian blur of radius four supplies its soft base.
Fixed crop boxes based on SVG clump locations clipped the illustrated plants and were rejected.

`GroundLayers` composes the separate 32×32 PNG components into a presentation TileSet. The authored
TileSet remains the input for each repaint, preventing repeated blending. Empty overlay pixels
preserve the base exactly. Grass uses eight generated atlas arrangements containing zero, one or
two whole clumps, with cell selection hashed from the city seed and coordinates. This bounded
atlas is an implementation choice for sparse variation without per-frame image work. Component
placement keeps each clump's visible bounds inside the tile. Source IDs, map selection and
gameplay geometry stay fixed; SVG mode retains authored vector textures.

The component manifest's source mappings are checked against the authored TileSet. Integration
review caught reversed road/sidewalk damage groups, reversed east/west main crossings and grass
filenames where component IDs were required. Focused checks cover those distinctions and verify
that the actual grass atlas exists, so a fallback cannot silently hide a failed composition.
The JSON manifest has an explicit export include rule; a local web export contains the manifest
and component resources without publishing a release.

`docs/evidence/layered-ground-2026-09-12/` keeps component SVG/PNG pairings, frozen inputs, exact
stencils, both asphalt recipes and an assembly script whose retained-input rebuild matches the
bundle byte for byte. `docs/evidence/layered-ground-layout-2026-09-12/` captures the engine's
composed texture pixels in seed 4242 streets, junctions and parks on days 1 and 14. Native and 4×
ground-only assemblies show shared paving through curb joins, aligned markings and sparse grass.
They establish static layout appearance; playtest questions remain in `REVIEW.md`.

The shared checkout passes import/boot, focused `ground_layers`, `visuals` and `presentation_mode`
suites in both PNG and forced-SVG modes, and doc/XML lint. The frozen-input component rebuild
matches the retained bundle byte for byte, and the installed manifest and PNG hashes verify
against it. Repeating the engine capture in the shared checkout reproduces every saved PNG and
source-grid JSON byte for byte. The full suite remains CI's gate.
