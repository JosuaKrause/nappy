# Comic dog SVG-to-PNG transfer

This folder transfers the walked dog and the charging dog from their authored SVG families into
comic PNGs. The player accepted both families for the game on 2026-09-27 (playtest dotted-panda:
"the graphics should be used in game"), with further comments to come. `install.py` copies each
accepted candidate byte for byte to `art/illustrated/svg-transfer/events/<name>.png` and verifies
the installed pictures against them:

```sh
uv run python docs/evidence/comic-dogs-2026-09-27/install.py install
uv run python docs/evidence/comic-dogs-2026-09-27/install.py verify
```

| Pictures | Accepted candidates |
|---|---|
| Normal dog, every a picture and the front and back b | `candidates/dog/` |
| Normal dog, side and diagonal b (the rest) | `walked-revision-4/candidates/` |
| Normal dog, every c | `walked-revision-5/candidates/` |
| Charging dog, all ten | `candidates/charging-dog/` |

[In-game bursts](../m109-comic-dogs-in-game-2026-09-27/README.md) show both families walking in the
game.

## The selected family

- [Three walked-dog poses](walked-revision-5/README.md) extends the selected family with five
  reviewed unbound SVG sources and their generated illustrations: opposite side/diagonal steps
  and neutral cardinal poses. [All-facing loops](walked-revision-5/review/all-facings-6x.gif)
  show step, rest, opposite step, rest; [native-size evidence](walked-revision-5/review/all-facings-1x.gif)
  and [three-pose sheets](walked-revision-5/review/all-facings-6x.png) show every mirrored facing.
  Existing selected images stay frozen. Its side opposite step carries the player's one seam
  correction, [with its crops](walked-revision-5/README.md#the-players-seam-on-the-side-opposite-step).
- [Walked-dog authored-geometry correction](walked-revision-4/README.md) supplies three B-frame
  resting images retained by the three-pose family. Its original two-frame
  [enlarged all-facing loop](walked-revision-4/review/all-facings-6x.gif),
  [native-size loop](walked-revision-4/review/all-facings-1x.gif) and
  [static A/B sheet](walked-revision-4/review/all-facings-6x.png) preserve every A and cardinal frame.
  comparisons preserve their displacement, ground-height and body-redraw differences.
- [Charging-dog source/candidate comparison](review-charging-dog.png) shows the same coverage for
  the charging family, whose appearance the player accepted. Its
  [A/B comparison](pose-comparison-charging-dog.gif) remains unchanged.
- The [first-pass walked-dog comparison](review-dog.png) and
  [first-pass A/B loop](pose-comparison-dog.gif) preserve the superseded frames that exposed the
  static hind legs and disappearing diagonal leg.
- [Revision 2](walked-revision-2/README.md) remains rejected evidence: its changing contact points
  do not establish stable leg attachments relative to the torso.
- [Revision 3](walked-revision-3/README.md) remains rejected evidence: plausible fixed roots and
  swapped near/far shading do not establish the requested leg geometry.
- [Walked-dog raw output](raw/walked-dog-grid.png) and
  [charging-dog raw output](raw/charging-dog-grid.png) preserve the generator's first useful
  results unchanged.

Every GIF in this folder is an assembled pose comparison, not a capture of live movement; the
[in-game bursts](../m109-comic-dogs-in-game-2026-09-27/README.md) are the captures.

Both raw grids contain ten visible cells in the requested five-view by two-stride order and carry
real alpha, with no floor, checkerboard, halo, leash, or cast shadow. The walked dog retains its
tan-and-cream coat, soft ears, raised tail, and blue collar. The charging dog retains its dark
black-and-tan identity, pinned ears, raised hackles, low head, red jaw, and white teeth. The source
and candidate comparisons were inspected at native size, game scale, and 6× enlargement.

The first attempt judged the proposed comic rendering; its walked side and diagonal B frames are
superseded, and every other frame of it is installed. Stride B changes head and body placement in the walked side and diagonal views, and changes the
charging silhouette in the side and diagonal views. The generated figures are also taller or
deeper than the SVG proportions in some views. Proportion-preserving registration therefore makes
some native candidates smaller than the source figure. The comparison sheets and GIFs leave those
differences visible.

## Authority and mapping

The twenty SVG files in [sources.txt](sources.txt) define identity, projection, pose, canvas,
bottom-center ground registration, and stride pairing. [source-manifest.json](source-manifest.json)
records every source path, SHA-256, native size, and grid cell. The two approved style references,
`docs/style-references/graphics-reference-urban-01.jpeg` and
`docs/style-references/graphics-reference-cardinal.jpeg`, supply comic line, shaped color and
shadow language only. They do not supply identity, projection, layout, interface, annotations, or
scenery.

[PROMPTS.md](PROMPTS.md) preserves the exact prompts and reference roles sent to Codex's built-in
`image_gen`. One call produced each family. The built-in tool exposes no model selector or model
version in this workflow. Generation is nondeterministic; the retained raw PNGs are the fixed
inputs for every reproducible step after it.

The raw walked-dog output is 1983×793 RGBA with SHA-256
`36b57216012e7c63398128bcd4bac717b946ac17cb5995495afc5bc92a923486`. The raw charging-dog
output is 2094×751 RGBA with SHA-256
`a674ad5a021b939ad90a40c91769cbd8dab7521dfddef8cb44e8bd96ec0ee793`.

[candidate-manifest.json](candidate-manifest.json) maps every SVG to its extracted crop and native
candidate, with the raw grid cell and visible bounds, source and candidate hashes, native canvas,
registration box, shared A/B scale, placement, and final alpha bounds. `install.py` installs the
accepted `candidates/` files, all but the three superseded walked side and diagonal B frames.

[input-manifest.json](input-manifest.json) is the separate, authoritative provenance boundary. It
freezes the hashes and roles of all twenty SVGs, both raw generations, forty saved source rasters,
both approved style references, and the road and sidewalk comparison backgrounds. Every
`assemble.py` rebuild and verification command checks the exact required path set, roles, file
existence and hashes before it reads or writes any output. There is no command that refreshes or
silently adopts changed input hashes.

## Extraction and registration

Each raw sheet uses inspected column and row boundaries recorded in `assemble.py`, because the
generator spaces the five views unevenly. Within each selected cell, alpha above 10 locates the
object and a two-pixel pad keeps its antialiased edge; the crop then preserves the original alpha
unchanged. This avoids both low-alpha dust expanding a crop and a neighboring dog leaking across a
uniform cell boundary. The threshold selects the framing box only and never rewrites artwork alpha.

The two strides for one authored view use one scale derived from the larger raw width and height
and the union of both SVG source alpha bounds. Each retains its own proportions, is centered
horizontally and bottom-aligned inside that shared target, then downsampled with Lanczos onto the
source's native canvas. The process applies no SVG alpha mask and does no pixel painting. Internal
A/B proportion and landmark drift remains in the candidates instead of being normalized away.

`assemble.py` also builds the comparison sheets and the two-frame GIFs. The game-scale rows use the
illustrated sidewalk and road textures and nearest-neighbor enlargement, matching the game's 2×
camera scale. The enlarged rows use a checker only in the review sheet to expose transparency; it
is not present in any candidate.

## Rebuild

Run from the repository root. The Godot command below records how the saved source rasters were
captured in the original batch; those rasters are now frozen inputs rather than ordinary rebuild
outputs. A fresh worktree runs the import check first so Godot has its class registry:

```sh
./tools/check.sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script docs/evidence/comic-dogs-2026-09-27/render-svgs.gd -- \
  docs/evidence/comic-dogs-2026-09-27/sources.txt . \
  docs/evidence/comic-dogs-2026-09-27/source-renders
uv run python docs/evidence/comic-dogs-2026-09-27/assemble.py source-grids
```

Use the built-in generator with the local reference paths and exact prompts in `PROMPTS.md`, then
preserve its raw outputs under `raw/` with the filenames and hashes above. Rebuild and verify every
deterministic derivative. Each command refuses a missing or changed frozen input before writing:

```sh
uv run python docs/evidence/comic-dogs-2026-09-27/assemble.py candidates
uv run python docs/evidence/comic-dogs-2026-09-27/assemble.py verify
```

The retained recipe ran with Godot 4.7.2 (`ed1daf0bf`), Python 3.14.7, and Pillow 12.3.0.
The preflight checks all sixty-six frozen inputs. `verify` then checks all twenty source hashes,
all twenty source-to-candidate mappings, exact native candidate dimensions, actual transparent
and visible alpha, and both comparison sheets and pose comparisons.
