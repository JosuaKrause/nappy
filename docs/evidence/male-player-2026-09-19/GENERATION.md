# Male player source, generation and registration

This record preserves the blue-overshirt player's complete pushing and carrying families:
five authored views, three poses per view, and west-facing mirrors in the runtime. It is
generation and static-registration evidence, not a motion or human-acceptance verdict.

## Sources and reference roles

The editable sources are `assets/rig/father_*.svg`, with byte-identical creation copies in
`docs/graphics-creation/player/`. The [player manifest](../../graphics-creation/player/manifest.json)
pairs every runtime source, creation reference and native illustrated PNG. The SVGs define
the short brown hair, blue overshirt, cream undershirt, canvas, pose and functional placement.
Their three-pose pushing/carrying geometry follows the current female creation family.
The SVGs are authored and inspected before the corresponding raster generation.
The [B-contact source review](b-contact/GENERATION.md) documents the four revised pushing
sources and their native/3× sheets. Their raster transfer remains incomplete; the raw atlases,
registered PNGs and original generation-input hashes below remain unchanged.
The [final-woman-leg crop evidence](b-contact/final-woman-legs-2026-09-19/README.md)
preserves the rejected literal-copy preview. The
[high-resolution normalization recipe](b-contact/normalized-crop-2026-09-19/README.md)
preserves the rejected P2 donor selection and its generated normalization. Its separately
labeled carrying GIFs show the current installed carrying family. These review artifacts
do not alter this registered family.
The [correct-contact donor recipe](b-contact/correct-contact-2026-09-19/README.md) uses the
final carrying family's actual opposite leg overlap and above-pelvis father identity inputs
for an uninstalled normalization preview. Its profile has the requested opposite overlap;
its southeast legs are too frontal. The [color-match recipe](b-contact/color-match-2026-09-19/README.md)
transforms trouser colors without changing geometry or pixels outside the material mask.
The [diagonal and carrying contact recipe](b-contact/diagonal-carrying-2026-09-19/README.md)
restores the accepted southeast contact and applies actual carrying B leg changes. These are
retained review artifacts: PLAYTEST-98 accepts their color-matched E/W result and rejects the
restored diagonal drawing. The [natural southeast recipe](b-contact/natural-southeast-2026-09-19/README.md)
uses colored leg chains to establish the crossing during generation, then restores the clothing
palette deterministically. Its pushing and carrying sheets preserve the accepted E/W pixels.

`source/` preserves Godot's 1×, 3× and 8× rasterization of every SVG.
`inputs/*_source-{1,3,8}x.png` assembles them in columns front, back, side, front diagonal,
back diagonal; rows are A, C, B. `inputs/*_female-{1,3,8}x.png` preserves the accepted female
PNGs in the same arrangement as a rendering and registration reference, not a replacement identity.
The source grids and individual renders use white only as a review background.

`reference-male-scene.jpeg` is the supplied AI-generated scene
`Gemini_Generated_Image_7080ww7080ww7080.jpeg`: its central man's short hair and blue shirt
supply the male silhouette and clothing identity. The two official style inputs,
`../graphics-reference-urban-01.jpeg` and `../graphics-reference-cardinal.jpeg`,
govern comic contours, material detail and deliberate shadows, excluding their interface.

## Generation

`prompt-pushing.txt` and `prompt-carrying.txt` are the exact built-in image-generator prompts.
Their attachment order is explicit:

1. Pushing: `inputs/pushing_source-8x.png`, `inputs/pushing_female-8x.png`,
   `reference-male-scene.jpeg`, urban style reference, cardinal style reference.
2. Carrying: `inputs/carrying_source-8x.png`, `raw/pushing.png`,
   `inputs/carrying_female-8x.png`, urban style reference, cardinal style reference.

`raw/pushing.png` and `raw/carrying.png` are the unmodified generator outputs, each 1298×1212
with real alpha. A new generator call is nondeterministic; the saved outputs make extraction
reproducible without another call. Carrying explicitly uses the generated pushing family as its
identity reference. Both batches retain the same head, collar, shirt pockets, trousers and shoes.

## Deterministic registration

`registration.json` freezes the tool version, script/input SHA-256 hashes, cell order, row
boundaries and anchor rule. `registered/manifest.json` records every exact cell/crop rectangle,
whole-figure scale, 12× working placement, native alpha bounds and output hash.

Columns divide the generator's actual width into five rounded bounds. Rows cut through the empty
gutters: pushing 0/420/824/1212, carrying 0/430/832/1212. The extractor crops visible alpha
greater than 1 to exclude sub-visible margin specks, retaining original alpha inside the crop.
It does not stamp an SVG mask onto the drawing, quantize the outline or splice fixed head/torso
rows over changing legs. Both retained batches use their original alpha; the script's neutral
background fallback is inactive for them.

Each figure is scaled uniformly to a 45px visible height, placed on a 46px-tall native canvas,
and rejected if that stature cannot fit its width. Front/back canvases are 24×46; side/diagonal
canvases are 26×46. Horizontal placement matches the corresponding female pose's
opacity-weighted upper-body centroid (top 68%), keeping a wider stride from translating the
hands. The fit is performed at 12× and reduced with Lanczos. Runtime scale, offsets, movement,
shadows, camera and shared stroller artwork are unchanged.

The reproducibility environment is Godot 4.7.2, Python 3.14 and Pillow 12.3.0 from the locked
project environment. Review text uses Pillow's bundled default font. All commands run from
the repository root; choose fresh output directories:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script docs/evidence/male-player-2026-09-19/render-sources.gd -- \
  --output-dir /tmp/male-player-source-review
uv run python docs/evidence/male-player-2026-09-19/prepare.py \
  --render-dir /tmp/male-player-source-review --output-dir /tmp/male-player-source-grids
uv run python docs/evidence/male-player-2026-09-19/register.py register \
  --config docs/evidence/male-player-2026-09-19/registration.json \
  --output-dir /tmp/male-player-registration
uv run python docs/evidence/male-player-2026-09-19/register.py verify \
  --config docs/evidence/male-player-2026-09-19/registration.json \
  --output-dir docs/evidence/male-player-2026-09-19/registered
uv run python docs/evidence/male-player-2026-09-19/contact.py \
  --registered-dir docs/evidence/male-player-2026-09-19/registered \
  --output-dir /tmp/male-player-contact
uv run python docs/evidence/male-player-2026-09-19/verify-pairs.py
```

`freeze --config FRESH_FILE` is the registration script's authoring command for a deliberately
new input set, not a way to bypass the retained record's hash checks. The original source
render and grid commands use the same arguments with `source/` and `inputs/` here as their
fresh outputs. Runtime PNGs are exact copies of `registered/rig/*.png`; Godot creates each
new resource's own import sidecar.

## Static review

The `registered/{pushing,carrying}-male-{native,3x}.png` sheets contain the complete male
matrix. The corresponding `*-female-male-*.png` comparisons show female then male in each
direction. Columns are N, NE, E, SE, S, SW, W, NW; rows are A, C, B. Western cells mirror their
east-authored source. The native sheets, enlarged sheets and extracted transparent cells are
inspected for identity, stature, contact/together leg ownership and retained gaps.

`contact/contact-{native,3x}.png` assembles all pushing poses with the installed shared stroller.
`contact.py` uses the current continuous runtime offsets, north-diagonal correction, draw order
and 7/6 stroller scale, then rounds placement to static-sheet pixels. It checks source and
registered-output hashes before assembling. This approximation checks registration; it does not
establish live turning or smooth gait. No motion claim rests on these sheets or on a gameplay still.

Human review of the two presentations in motion remains in [REVIEW.md](../../REVIEW.md).

## Runtime appearance

The [normal-scale gameplay still](../archive/session-captures/2026-09-19/rig-074419-seed3-v0.11.1-3-gaa5a6b38-dirty/m157-male-player.png)
shows the blue-shirted player walking east with the shared stroller on seed 3, day 1.
The whole run folder, map, log and `capture.json` retain build and command provenance.
It is one 1280×720 capture after four seconds of `--walk 1s3e --invincible`.
Invincibility keeps the appearance check running but freezes the clock and meter; this is
neither a route-cost measurement nor motion/performance evidence. The capture uses the default PNG
mode; forced SVG is covered by source inspection and focused headless checks, not a second still.
