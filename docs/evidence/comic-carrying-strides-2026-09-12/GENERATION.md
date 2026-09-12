# E — Clear strides

This record covers the carrying mother's three distinct gait poses and their four-phase runtime
loop. The frame letters are gait labels inside version E: **A / contact 1**, **C / passing**, and
**B / contact 2**. They are separate from the named carrying revisions A through D preserved in
`docs/evidence/comic-carrying-redraw-2026-09-12/versions/`.

The depicted and runtime loop is `A, C, B, C` over one full `TAU` turn of the existing
distance-driven walk clock. The four equal 190 ms diagnostic frames show that order without
changing its cadence. When movement stops, the carrying rig selects C so the feet settle together
regardless of the saved phase. The pushing state retains its existing two-frame selector.

## Source pose and identity contracts

The five `mother_carrying_*_c.svg` files are the closed passing poses. The previous B SVG geometry
supplied that concept. A and B legs and shoes are repaired as the two open contacts: front, rear and
diagonal views alternate one lower/full-length leg with one higher/receding leg; profile views keep
toes along travel while swapping the lighter near leg and darker far leg. Every SVG keeps its native
24×46 or 26×46 canvas and bottom-center ground anchor. Godot renders the source family at native
and 6× through `render-svg-sources.gd`; `source/svg-acb-6x.png` is the reviewed source sheet.

The illustrated adult identity comes from D — Matched proportions. Registration replaces generated
rows 0–33 with the exact corresponding D registered PNG rows: A uses D A, while C and B use D B.
The generated alpha remains authoritative below the hem. No SVG alpha mask is applied to the
illustrated output, and `tools/remove-checkerboard.py` extracts the selected white background.

## Generation inputs and passes

Built-in image generation receives local images only. `prompt.txt` uses D's selected illustrated
atlas as the exact identity target and `source/svg-acb-6x.png` as pose authority. The generated
5×3 layout is front, back, right profile, front diagonal and back diagonal across columns, with A,
C and B down rows.

`raw/carrying-acb-pass1.png` establishes the three-pose atlas. `prompt-b-row.txt` corrects the B
row's opposite contacts, producing `raw/carrying-acb-pass2.png`. `prompt-side-back-diagonal.txt`
then reverses profile near/far ownership without reversing toe direction and moves the back-diagonal
B foreground sole to the opposite side. Its output is `raw/carrying-acb-selected.png`.

Generation itself is nondeterministic. The three raw files and exact prompts preserve the selected
path; deterministic extraction starts from the selected raw bytes. `source/source-pair-manifest.json`
records every raw, prompt, SVG, Godot render and D identity SHA-256, dimensions, anchors and input
chain. `convert.py` asserts all of those hashes before registration or installation.

## Reproduction

The deterministic extraction and review build can run without deleting retained evidence. From the
repository root, choose a fresh output directory and use the root lockfile:

```sh
./tools/check.sh
uv run --project . docs/evidence/comic-carrying-strides-2026-09-12/convert.py \
  register --output-dir /tmp/carrying-e-rebuild
uv run --project . docs/evidence/comic-carrying-strides-2026-09-12/convert.py \
  verify --registered-dir /tmp/carrying-e-rebuild \
  --compare-to docs/evidence/comic-carrying-strides-2026-09-12/registered
```

`register` fails if the chosen output already exists, so it cannot silently reuse stale derivatives.
The authoring-only `prepare` command creates the frozen manifest before retention and likewise fails
if that manifest already exists. `install` copies a verified retained registration into the runtime
asset folder; neither command is needed for the safe comparison above.

The retained outputs reproduce byte-for-byte with uv 0.12.10, Python 3.14.7, Pillow 12.3.0 and
Godot 4.7.2 stable (`ed1daf0bf`). The scripts use `/System/Library/Fonts/SFNS.ttf` at SHA-256
`2bfd40dc72e6759e248f82a52a40d551338979fffc9b5c070e685b4b7ad19e66`; the manifest asserts the
same font before composing review sheets. Atlas extraction uses normalized 5×3 cell edges rounded
against the selected 1380×1140 output. Each subject is fitted to 45 of the 46 source pixels, centered
on the native canvas and bottom-grounded, then quantized against D's recorded shared palette after
its generated alpha is saved.

## Review outputs

- `raw/b-row-selected-preview.png` shows the final five unmirrored B cells before registration.
- `registered/e-frames-native.png` and `registered/e-frames-6x.png` show exact registered A/C/B
  frames for all eight runtime directions, including west mirrors.
- `registered/e-animation-native.gif` and `registered/e-animation-6x.gif` animate exact registered
  frames in `A, C, B, C` order at four equal 190 ms phases.

No live gameplay capture accompanies E. The exact-frame GIF covers the carrying motion itself;
headless import, focused runtime suites, forced-SVG visuals and lint cover binding and parser
behavior.
