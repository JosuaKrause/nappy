## M171, the bake and the loader — built 2026-09-20

The first of the milestone's pull requests: the machinery, with no consumer moved.

**Built.** `tools/bake_atlases.gd`, a headless engine script, reads
`assets/atlases/membership.json` (ten groups, 563 pictures derived from what `src/`, the ground
TileSet and the layer manifest reference), rasterizes with `Image.load_svg_from_buffer()` at
scale 1 or loads the illustrated PNG, applies `fix_alpha_edges()`, shelf-packs inside 2048px
and writes one page per group plus `regions.json` and a manifest of input hashes into the
gitignored `assets/atlases/baked/`. `tools/bake-atlases.sh` compares hashes without starting
the engine (about a quarter of a second) and bakes only when stale; a bake in the other mode
is stale; `--svg` is the custom local bake and `export-web.sh` refuses to export one. Every
tool that starts the engine calls it: `check.sh`, `test.sh`, `run.sh`, `shot.sh`,
`export-web.sh`, and `serve-web.sh` through the export. `AtlasLibrary` is static,
reference-counted per group, answers sizes and rects from the table with nothing loaded, and
refuses with an error to hand out a region of a group nobody acquired, since loading it
quietly is the second resident copy the milestone exists to remove. `tools/audit-pck.sh`
parses the exported pack's file table (format 4, read from the bytes) and reports every
constituent; it found 563 of 563, as it must until the sources move.

**Measured.** Every baked region equals today's runtime picture byte for byte, in both modes;
before the bake was written, 764 pictures across all families differed from the import pass
in 0 pixels. The bake takes 0.25 to 0.76s for all ten pages; the largest are the events at
2042 by 382 and the ground at 2042 by 70. Two forced bakes are byte-identical. A fresh-clone
shape (no baked folder, no import cache) bakes, imports and boots under `check.sh`.

**Found on the way.** The engine's default import would run a second alpha bleed over an
assembled page and pull one region's colour into its neighbour, so the bake writes each page's
import sidecar itself, once. `run.sh`'s first wiring never ran: `--check` exits non-zero by
design and the script runs under `set -e`, so the line that reprinted the reason was the last
one executed; found by running the stale path rather than reading it. The windowed tools
repair through `check.sh` rather than a bare bake, because a baked page the engine has not
imported would be photographed as its previous import.

**Open to overturn.** The checkpoint pictures are on the events page and the mountain tile on
the ground page, both because of which file holds them; regions sit two pixels apart so each
owns its extruded border; a size mismatch between an illustrated PNG and its SVG fails the
bake where the runtime resolver only warned; `tools/test_cli_help.sh`'s two separator cases
skip where no atlases exist, which is CI's help job. 45 pictures nothing in `src/` references
are not baked — the chalk mark pair, the unbound gunman and mouse views, the vehicles' end
views, four stair parts, two impact craters, `alley_draft` — the prepared art `TODO.md` lists
as unbound.
