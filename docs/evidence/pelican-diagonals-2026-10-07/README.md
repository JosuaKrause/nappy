# spotted-osprey — Pelican depth and diagonal comparisons

## Current source candidate

`candidate-4-1x.png` and `candidate-4-6x.png` show only the current candidate. Every cell is
labeled: northeast, southeast and east, each in A/B pedal phases; the second row contains
their northwest, southwest and west mirrors. The native sheet preserves each source pixel;
the enlarged sheet rasterizes at 6×. Side-view feet and diagonal feet share the same baseline.

The far leg is behind both wheels and every bicycle tube, and the near leg is in front of
all those parts in all six sources. The southeast handlebars also precede the near-leg draw.
Both northeast wing roots are covered by the torso; only their forward reaches toward the
handlebars emerge from its front silhouette. This is the concrete visual proposal answering
jolly-puffin, not approval of the anatomy. The southeast second eye is preserved.
The northeast far leg keeps hip (16,23.6) as its foot changes from the right pedal position
in A to the left one in B; the near leg keeps hip (20.2,23) and the opposite pedal position.
Both east-facing near phases share hip (16,25), with the shin or raised foot covering the
vertical pedal bar. Candidate 4 preserves all candidate-3 geometry and changes painter order.

The sources, `current.gd`, `label-current.py` and these two images are committed together.
The renderer uses Godot 4.7.2's SVG parser; Pillow adds cell labels without resampling art.
Reproduce from the commit that adds the candidate-4 images, reachable through
`git fetch origin refs/pull/605/head`, with `$GODOT` naming the engine:

```sh
pelican_current=$(mktemp -d)
mkdir -p "$pelican_current/project" "$pelican_current/render"
printf 'config_version=5\n' > "$pelican_current/project/project.godot"
"$GODOT" --headless --path "$pelican_current/project" --script \
    "$PWD/docs/evidence/pelican-diagonals-2026-10-07/current.gd" -- \
    "$PWD/art/events" "$pelican_current/render"
uv run python docs/evidence/pelican-diagonals-2026-10-07/label-current.py \
    "$pelican_current/render" "$pelican_current" --candidate 4
```

## Third-attempt evidence

`candidate-3-1x.png` and `candidate-3-6x.png` document source revision
`9c431ff96b903d8602e1865526ec8a56e6000389`. The source-render command and labeler at that revision
take `--candidate 3`. Jolly-puffin records the remaining wheel-depth correction.

## Second-attempt evidence

`candidate-2-1x.png` and `candidate-2-6x.png` document source revision
`a45b6e7da648b19c335df9e8aaa3327858bbadc0`. To reproduce that proposal, check out that revision
and use the same source-render command and labeler without a candidate option. The
dappled-dolphin playtest records the remaining leg-identity and pedal-bar defects in it.

## First-attempt evidence

The comparisons and runtime burst below document the first attempt's source revision, not
the current candidate. Its visual review is in the spotted-osprey decision record and
plaid-kestrel playtest. Keep these earlier images as plain links when presenting the candidate.

The source sheets compare northeast and southeast anatomy in both pedal phases. Each column
is, from left to right: northeast A, northeast B, southeast A, southeast B. The top row is the
baseline; the middle row is this repair; the bottom row is the repair mirrored westward.
`comparison-1x.png` uses the native 40×44 sources. `comparison-6x.png` rasterizes those same
sources at six times native size. The gray background is a neutral sheet, not game ground.

These are source previews made with Godot 4.7.2's SVG parser, not runtime captures or approval.
The unchanged bicycle, canvas and bottom-center (20,44) anchor provide registration between
frames. In this source revision, the near wing follows the northeast body's side and the far
wing is hidden by its back. The southeast far eye is smaller, above the bill root. Knees point forward in both phases;
the far shins use the side-view family's darker orange to separate the legs.

The baseline is commit `420dcd96671432422f5cc6d80e220c1826ca1d70`. The repaired art is
`734a41c06dbcf8b6cd950f9225e177138cae4f5b`, which also contains these sheets and their renderer.
Fetch the durable ref with `git fetch origin refs/pull/605/head` before checking out either
revision in a fresh clone. For the runtime collector as well, check out the fetched PR head.

To rerender the first-attempt sheets, check out `734a41c06dbcf8b6cd950f9225e177138cae4f5b`
and run from that repository root with a fresh scratch folder:

```sh
pelican_out=$(mktemp -d)
mkdir -p "$pelican_out/project" "$pelican_out/baseline" "$pelican_out/render"
printf 'config_version=5\n' > "$pelican_out/project/project.godot"
for view in back_diagonal back_diagonal_b front_diagonal front_diagonal_b; do
    git show 420dcd96:art/events/pelican_cyclist_$view.svg > "$pelican_out/baseline/pelican_cyclist_$view.svg"
done
"$GODOT" --headless --path "$pelican_out/project" --script \
    "$PWD/docs/evidence/pelican-diagonals-2026-10-07/render.gd" -- \
    "$pelican_out/baseline" "$PWD/art/events" "$pelican_out/render"
```

## First-attempt runtime burst

`runtime.mp4` is a timing-preserving clip of 36 frames over 2.923 seconds, collected through
Godot 4.7.2's desktop Compatibility renderer on Apple M2. `runtime-burst.json` retains the
original frame times and pedal phases; `runtime-still.png` is its first frame. Columns are
northeast, southeast, northwest, southwest. Both pedal phases occur for every rider.

This is a controlled fixture of real `EventInstance` nodes following four diagonal routes,
using their production movement, gait selection, SVG atlas textures, painter order and draw
path. The 2× parent scale equals the normal camera zoom. Each carrier follows its rider to
keep it visible; the gray background has no city, player, collisions, spawns or cost model.
It establishes runtime view selection and frame transitions, not natural route frequency or
gameplay fairness. No seed applies to the fixed routes. `--no-save --invincible` are present.

Art/runtime source revision: `734a41c06dbcf8b6cd950f9225e177138cae4f5b`. The collector is the
checked-in `runtime.gd`, SHA-256
`3cece3537d06cf2eaadfbe9e55b3740ac0de676d4e2e36a613be16bc433d38a6`, alongside `runtime.tscn`.
The capture runs with only these two evidence files uncommitted; production code and art match
that revision. The first launch adds `--quit-after 900` and exits before the two-second warmup:
that engine flag counts frames. The retained run uses the collector's 12-second wall-clock
deadline and completes without engine errors. A source-render launch without filesystem
permission reports blocked Godot log writes; the permission-enabled rerun completes cleanly.

Rerun from a checkout of the fetched PR head, with `$GODOT` naming the engine:

```sh
./tools/check.sh
pelican_run=$(mktemp -d)
PELICAN_CAPTURE_OUTPUT="$pelican_run" "$GODOT" --path "$PWD" --resolution 640x240 \
    --disable-vsync res://docs/evidence/pelican-diagonals-2026-10-07/runtime.tscn -- \
    --no-save --invincible
./tools/clip.sh "$pelican_run" "$pelican_run/runtime.mp4"
```

Retained: two source sheets, their renderer, the runtime collector and scene, a short clip,
one still and the burst timing/phase record. Individual duplicate rasters, the other raw burst
frames and routine check logs stay out. The clip and original timing/phase record carry the
motion claim, and the still provides a directly embeddable runtime-scale view.
