# P2 — Three-pose push

This record preserves the reviewed three-pose pushing family requested in PLAYTEST-65. Every one
of the five authored views has two open contacts with opposite anatomical leg ownership and one
feet-together pose. The runtime mirrors the side and diagonal art for the other three directions
and plays `A, C, B, C`; stopping at any phase selects C.

The stroller composition remains the accepted grounded one. The review sheets use the runtime
pram PNGs at `7/6` scale, 24px horizontal distance, 17px north distance, 9px south distance, `0.7`
ground-plane Y projection and zero vertical lift. The mother retains the 24×46 front/back and
26×46 side/diagonal canvases, a bottom-center ground anchor and the accepted grip landmarks.

## SVG source and P1 comparison

The fifteen `docs/graphics-creation/player/mother_{view}_{a,c,b}.svg` files preserve the generation
poses; their [pairing manifest](../../graphics-creation/player/manifest.json) distinguishes the
runtime SVG fallback from the high-fidelity target. Contact A and
Contact B exchange complete legs from hip through knee and heel; C places both feet together on the
ground. Northeast contacts retain an upper-right lead and lower-left trail, while southeast keeps
the opposite screen axis. The coat hem and pelvis articulate with the legs, while the head, torso,
hands and canvas landmarks stay stable.

`source/p1/` freezes the ten original P1 — Two-pose push SVGs and illustrated PNGs directly from
git object f39bd59c19ba3ea59804723ddeedb9bd9e34da6c. These are comparison evidence and registration
anchors, not mutable runtime
inputs. `source/review/p1-source-{native,6x}.png` and
`source/review/p2-source-{native,6x}.png` show the source families. The P2 source GIF presents all
eight runtime directions in the exact `A, C, B, C` order. The source contact sheet uses the same
ground and pram transform as the registered sheet.

`render-svg-sources.gd` renders through Godot's SVG parser. Both that script and
`make-source-review.py` reject unknown arguments before creating output and require fresh output
directories:

Run this record's source-rendering and registration commands from a checkout of
5210f6d828cf61d22c95516fbb1c34ff7d96529d. Its runtime SVG paths hold the generation targets
whose hashes this recipe checks. The dedicated authoring folder preserves those same targets
independently of the in-game SVG restoration; the accepted PNG outputs remain identical.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script docs/evidence/comic-pushing-strides-2026-09-12/render-svg-sources.gd -- \
  --output-dir /tmp/p2-svg-render

UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/comic-pushing-strides-2026-09-12/make-source-review.py review \
  --render-dir /tmp/p2-svg-render --output-dir /tmp/p2-source-review
```

The scripts expose usage with both `--help` and `-h`. `make-source-review.py freeze-p1
--output-dir FRESH_DIRECTORY` can rebuild the named P1 snapshot from the fixed git object.

## Bitmap generation and selection

Generator: built-in `image_gen.imagegen`.

The binding identity target is
`docs/evidence/comic-carrying-redraw-2026-09-12/source/pushing-atlas-edit-target.png`. It contains
only the two accepted original pushing rows; rejected carrying rows never enter this generation.
`docs/evidence/graphics-reference-urban-01.jpeg` and
`docs/evidence/graphics-reference-cardinal.jpeg` are style references only. The reviewed P2 SVG
sheet supplies pose and leg-ownership guidance. `input-manifest.json` freezes the hashes and roles
of these inputs, all prompts, all raw selected results, the P1 anchor art, P2 generation SVGs, pram
PNGs, extraction code, recipe scripts, font, CPython 3.14.7 and Pillow 12.3.0.

The exact prompts are retained beside this document. `prompt.txt` produces the first complete
atlas in `raw/p2-acb-pass1.png`; it is retained as a displayed candidate with repeated forward-leg
ownership. `prompt-pass2.txt` produces `raw/p2-acb-pass2.png`. The final family selects eight whole
figures from that result: all five A figures plus front, back and front-diagonal B. The separate
`prompt-c-row.txt` produces the five whole full-height C figures in `raw/p2-c-row.png`; treating the
row as its own generation preserves adult leg length without enlarging the head or coat.

Visual review found that pass2's side B and northeast B still retained A's anatomical leg ownership.
`prompt-pass4-side-ne.txt` directs a continuous hip-to-knee-to-shoe correction and produces
`raw/p2-acb-pass4-side-ne.png`. The final selection uses its two whole B figures. It does not paste
legs onto fixed upper-body pixels. The thirteen previously accepted whole figures remain sourced
from pass2 and the separate C row. `registered/manifest.json` records this selection by asset name
and source hash. `versions/pass2-anatomically-ambiguous/` preserves the earlier registered review
and identifies its all-pass2 A/B selection.

## Registration

`convert.py` removes only connected bright neutral background through the repository's
`tools/remove-checkerboard.py`. It crops each complete generated figure, preserves its aspect ratio,
fits it to the 45px stature at 12× working resolution and aligns its feet to y=46. Horizontal
placement uses the opacity-weighted upper 68% of the figure against the average of the frozen P1 A
and B upper-body centroids for that view. Leg spread therefore cannot recenter the head, coat or
hands. `registered/registration.json` records every source cell, whole-figure bounds, source hash,
fit scale, stable anchor, placement adjustment, final alpha bounds and the explicit absence of an
anatomical splice.

The shared 28-color palette draws from the selected figures and frozen P1 PNGs. Color is extended
under transparent pixels before quantization and the generated alpha bytes are restored after
quantization. No SVG alpha is stamped or intersected onto the illustrated result.

Registration checks `input-manifest.json` before creating its fresh output directory:

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/comic-pushing-strides-2026-09-12/convert.py register \
  --selection final --output-dir /tmp/p2-registration

UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/comic-pushing-strides-2026-09-12/convert.py verify \
  --input-dir /tmp/p2-registration \
  --compare-to docs/evidence/comic-pushing-strides-2026-09-12/registered
```

The comparison checks every output byte. Verification also decodes the native and 6× GIFs,
requires four 190ms frames, proves A/C/B are distinct and proves the fourth frame repeats C. The
retained earlier result is reproducible with `register --selection pass2`.

After visual review, the final registered PNGs install with:

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/comic-pushing-strides-2026-09-12/convert.py install \
  --input-dir docs/evidence/comic-pushing-strides-2026-09-12/registered
```

Installation accepts only a manifest whose selection is `final`. Existing A/B Godot import
identities stay in place; Godot creates fresh resource identities for the new C files.

## Review outputs

- `registered/p2-selected-generation.png` shows the exact fifteen whole high-resolution figures
  selected from pass2, the separate C row and pass4.
- `registered/p2-frames-{native,6x}.png` show A/C/B for every authored view.
- `registered/p2-animation-{native,6x}.gif` show the four-phase loop in all eight runtime
  directions.
- `registered/p2-grounded-contact-{native,6x}.png` compose the final selected pixels with the
  unchanged pram PNGs and accepted runtime transforms.
- `registered/rig/` is byte-identical to the fifteen runtime pushing PNGs.

These sheets establish pose ownership, stature, registration, ground contact, hand contact,
direction coverage and loop order. They are deterministic source and composition evidence rather
than a live gameplay capture.
