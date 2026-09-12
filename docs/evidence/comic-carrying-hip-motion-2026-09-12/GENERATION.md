# F — Hip motion

F corrects the annotated front and northeast carrying poses with continuous whole-figure artwork.
The frozen source family uses
the runtime's 24×46 front/back canvases and 26×46 side/diagonal canvases, all bottom-center
anchored. Runtime order is A, C, B, C at four equal 190 ms diagnostic phases; C is also the idle
pose. East-authored side and diagonal sources are mirrored horizontally for west.

## SVG source review

The targeted correction changes the front A/C/B lower-body geometry and rear-diagonal A/B. Front A
leads with the screen-left leg, front B leads with the screen-right leg, and each connects that leg
from hip through knee to shoe with its own knee flexion, heel height and lower-coat rotation. Front
C plants both feet in the together pose. Both
rear-diagonal contacts use the NE projection: their leading endpoint is upper-right and their
trailing endpoint is lower-left while the leg ownership changes. The remaining source drawings
are frozen unchanged for family context.

`source/svg/` holds the exact reviewed SVG inputs. `source/source-manifest.json` records their
SHA-256 values, dimensions, anchor and the review font. `render-svg-sources.gd` rasterizes all 15
inputs at native size and 6× with Godot's SVG parser. `assemble-source-review.py` refuses changed
inputs, then writes per-view A/C/B strips, diagonal comparisons, four-phase eight-direction sheets
and GIFs. These are source previews, not generated PNGs or gameplay captures.

From the repository root:

```sh
./tools/check.sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script docs/evidence/comic-carrying-hip-motion-2026-09-12/render-svg-sources.gd \
  -- --output-dir /tmp/f-source-renders
uv run --project . \
  docs/evidence/comic-carrying-hip-motion-2026-09-12/assemble-source-review.py \
  --rendered-dir /tmp/f-source-renders --output-dir /tmp/f-source-review
```

The retained recipe uses Godot `4.7.2.stable.official.ed1daf0bf`, uv 0.12.10, Python 3.14.7 and Pillow
12.3.0. Labels use `/System/Library/Fonts/SFNS.ttf` at SHA-256
`2bfd40dc72e6759e248f82a52a40d551338979fffc9b5c070e685b4b7ad19e66`.

Review `source/strips/front-acb-6x.png` for the three targeted front poses and
`source/diagonals-acb-6x.png` for the authored southeast/northeast axes. The complete runtime mirror
and loop review is `source/eight-direction-acbc-6x.gif`; its static counterpart shows all four
phases without relying on GIF playback.

## Generated figures

The built-in image generator edits the high-resolution E atlas selected by the player in
`review/carrying-corrections-annotated.jpg`. `prompt.txt` supplies that image as the edit target,
the reviewed front and northeast SVG strips as pose authority, and the two approved comic
references as style inputs. `generation-inputs.json` records their ordered roles and hashes.
Its output is `raw/carrying-f-selected.png`: A/C/B rows and five view columns.

`prompt-proportions.txt` records a displayed whole-atlas proportion candidate in
`raw/carrying-f-proportions-attempt.png`. The final selection uses the separate whole standing
figures in `raw/carrying-f-c-row.png`, generated with `prompt-c-row.txt`. Its edit target is
the exact C-row crop, with the A-row crop supplying adult proportion and identity reference.
Rebuild those two inputs without changing their pixels:

```sh
uv run python docs/evidence/comic-carrying-hip-motion-2026-09-12/prepare-row-inputs.py \
  --output-dir /tmp/f-proportion-inputs
```

The retained copies and crop manifest are in `source/proportion-inputs/`. Generation is
nondeterministic; all deterministic work starts from the retained generator outputs.

## Registration and walking review

`registration.json` selects ten whole A/B figures from the first F output and five whole C
figures from the standing row. Exact cell rectangles, native dimensions, SVG pairings, input
hashes and horizontal registration offsets are explicit. The white background is extracted
through the recorded neutral-region remover. Each complete figure is fitted to 45 pixels high
within its 46-pixel canvas. No fixed upper rows, anatomical pieces, recolored replacement legs
or SVG alpha mask are composited into the figure.

The [registration recipe](RECIPE.md) explains the config and validations. Reproduce all native
sprites, contact sheets and eight-direction GIFs from the root in a fresh directory:

```sh
uv run python docs/evidence/comic-carrying-hip-motion-2026-09-12/register.py \
  register --config docs/evidence/comic-carrying-hip-motion-2026-09-12/registration.json \
  --output-dir /tmp/carrying-f-rebuild
uv run python docs/evidence/comic-carrying-hip-motion-2026-09-12/register.py \
  verify --config docs/evidence/comic-carrying-hip-motion-2026-09-12/registration.json \
  --registered-dir /tmp/carrying-f-rebuild \
  --compare-to docs/evidence/comic-carrying-hip-motion-2026-09-12/registered
```

`registered/registered-native.png` and its 6× counterpart show A/C/B in all eight directions.
`registered/animation-native.gif` and `animation-6x.gif` play A/C/B/C in four equal 190 ms
phases. The diagnostic timing illustrates pose order; runtime phase advances with distance.
The sheet labels use Pillow's embedded font and enlarge with the pixels. `verify` decodes the
actual GIF frames and checks the duplicate together frame, three distinct states, all directions
and identical regeneration. `registration-pass1.json` reproduces `registered-pass1/`, the
displayed first registration with all fifteen figures from the original F atlas.

These are exact sprite assemblies, not live gameplay captures. They establish the selected
pixels, mirroring, pose sequence and registered ground line. Live movement and state transitions
remain part of the visual review in `docs/REVIEW.md`.
