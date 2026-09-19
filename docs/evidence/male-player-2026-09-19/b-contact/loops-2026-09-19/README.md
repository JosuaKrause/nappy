# Father pushing splice trial

Review the [clean eight-direction sprite sheet](generated/father-spritesheet-6x.png),
its [native version](generated/father-spritesheet-native.png), and the
[native animation loop](generated/father-animation-native.gif) or
[6× animation loop](generated/father-animation-6x.gif).

The sheet columns are N, NE, E, SE, S, SW, W, NW. Its four rows are A, C, B, C. The GIF layout
is N/NE/E/SE across the top and S/SW/W/NW below, repeating the same four 190ms phases forever.
The outputs contain only the father sprites, without comparison panels or annotations.
They are retained review artifacts, not installed assets. [PLAYTEST-88](../../../../playtests/PLAYTEST-88.md)
accepts N/S and NE/NW but rejects E/W and SE/SW for repeating the leading leg and adding an
unnatural knee bend. The complete sheet is not approved for installation.

The [woman pushing recipe](../../../comic-pushing-strides-2026-09-12/GENERATION.md) supplies
the assembly authority. `assemble.py` imports its direction order, placement helper, gray review
background and GIF verifier. The sheet uses its 54×61 spacing, expanded to eight directions and
four phases; the GIF uses its four-column, two-row 54×62 layout and 190ms timing. Text margins and
annotations are omitted as requested. All image inputs used by the splice are father images.
No woman image enters this assembly, and no woman asset changes.

## Exact construction

Every A/C sprite and the accepted back-diagonal B is copied byte-for-byte from the existing father
family. NE/NW therefore retain their accepted pixels. SW/W/NW use the existing runtime horizontal
mirror. Individual outputs remain 24×46 for front/back and 26×46 for the side/diagonal views,
with the bottom-center anchor unchanged and visible alpha reaching y=46.

All four changed B poses preserve A's rows y=0 through 27 exactly. No head, hand, shirt, stature,
runtime scale or canvas adjustment is applied.

- Front/back: crop A's rectangle `[0,28,23,46)`, mirror it horizontally (`x -> 22-x`) and paste
  it at `(0,28)`. Both source hip bands span x=7 through 15, so reflection around pixel 11 keeps
  the join centered. Source column 23 below the cut is verified transparent. No resampling is used.
- Side: use the retained father donor's rectangle `[60,900,903,1613)`. This is the lower part of
  the correct-ownership side figure, below its shirt. Uniform Lanczos scaling fits the 713px leg
  height to 216px at 12× working resolution; the fitted width is 255px. Place at `(24,336)` in
  the 312×552 working canvas and reduce to 26×46. Paste the exact A upper rows last.
- Front diagonal: use the same father leg crop, fit and placement. Before reduction, apply the
  recorded affine projection: the trailing left foot rises three native pixels relative to the
  right foot, preserving the southeast ground direction. The inverse map is
  `source_y = output_y - (36/254) * output_x + (36/254) * 278`. Paste the exact front-diagonal
  A upper rows last. This is the splice trial the player judges, not an accepted diagonal redraw.

The side donor's near shin crosses in front and reaches the trailing left shoe, but its thigh
still points forward to a forward knee. The backwards-folded shin does not establish the opposite
contact. The diagonal projection inherits this defect while changing the two foot depths; it
does not create a three-quarter pelvis. These are the rejected E/W and SE/SW poses. No clipping
or overflow is hidden with padding, and no candidate upper body substitutes for the accepted father.

`father-side-leg-donor.png` is the unchanged original generated file; `donor-prompt.txt` preserves
its exact prompt from `../raster-attempts.json`. Its head/hand proportions and its bent leg chain
make it unsuitable for installation. Only its authorized leg crop is used in this rejected trial.

## Provenance and reproduction

`chronology.json` distinguishes the two failed atlas generations before splice authorization
from this authorized deterministic trial. Output times come from filesystem metadata; conversation
events retain their order without an invented timestamp. The exact failed prompts and their
input hashes live in `attempts/`. Their internally rejected output files stay outside the repo
at the recorded paths and never enter the final assembly. The failed retry's woman pose reference
is recorded honestly as history; it is not a current input or an edited/generated woman asset.
The chronology's initial "correct-ownership" assessment is a historical claim overturned by
PLAYTEST-88; its exact bytes remain frozen for reproduction of this trial.

`inputs.json` pins every final source image, the donor, recipe, chronology and reused P2 code.
`generated/manifest.json` records crops, transformations, compositing order, canvas/alpha bounds,
direction order, timing and output hashes. The original runtime images remain unchanged. The
rejected four-pose comparison remains preserved in `../review-2026-09-19/` as superseded evidence.

Run from the repository root with the locked Python 3.14/Pillow 12.3 environment and a fresh
destination. No font, Godot run, external generation or image installation is required.

```sh
uv run python docs/evidence/male-player-2026-09-19/b-contact/loops-2026-09-19/assemble.py \
  --output-dir /tmp/father-splice-review
diff -r docs/evidence/male-player-2026-09-19/b-contact/loops-2026-09-19/generated \
  /tmp/father-splice-review
```

The command rejects changed inputs. It checks native canvases, the ground anchor, preserved upper
pixels and protected A/C/back-diagonal inputs; verifies every sheet cell and its mirror; and
decodes both GIFs to require four phases with distinct A/C/B and repeated C, each lasting 190ms.
The 6× sheet is verified as an exact nearest-neighbor enlargement. Fresh output reproduces
byte-for-byte. The one-time `--freeze-inputs` option refuses to overwrite an existing record.

The shared SVG and illustrated-PNG procedures are unchanged. The successful method enters those
procedures only after the player approves the final image. No gameplay motion capture or live
stroller-contact claim is made by these deterministic sprite loops.
