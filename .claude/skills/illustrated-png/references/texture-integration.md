# Texture integration procedure

Use this procedure for a new illustrated family or a revision to an existing one. The contracts
and commands describe the current pipeline; the dated evidence is in `docs/DECISIONS.md` under
Texture integration process. Keep the accepted style, source-art gate and gameplay simulation
separate from runtime registration.

## 1. Preserve and identify the inputs

Read the selected family's generation record and manifest before making another asset. Inspect
the approved source at native resolution. A runtime screenshot or generated diagnostic does not
become an approved style reference because it is useful for spotting a defect.

Record the exact prompt, reference roles, generator/tool identity when available, output file,
dimensions, actual direction map and any post-processing command. Generation is not guaranteed
to reproduce identical pixels: preserve the actual output as the reproducible input to later
steps. For extraction, preserve inputs and versioned outputs; do not overwrite reviewed artwork.
Run Python tooling through `uv run python` and the repository lockfile.

For layered assets, check both alpha-channel presence and alpha values in intended empty regions.
Composite over light, dark and colored backgrounds and inspect enclosed wheel/handle gaps. A
checkerboard can be painted into an RGBA file. The existing checkerboard extractor is documented
in `assets/illustrated/modular/pram-alpha-extraction-2026-09-08.md`; its hard-alpha heuristic can
leave jagged coverage and does not reconstruct antialiasing. Do not erase pale fabric or highlights
to clean a background. Follow the image-generation skill for new or edited raster artwork unless
the player explicitly requests another method.

## 2. Measure the artwork, then register it

Use the family's machine-readable manifest as the source of runtime crop/joint data. For each
part and facing, record its actual source region, crop-local pivot, proximal/distal points, rest
axis, ownership, draw order and scale. A generated sheet's apparent grid is not a measurement:
parts can cross columns, rows can be packed independently, a torso can already contain arms,
and one profile can contain only one leg set. Missing anatomy remains an explicit source gap.

The runtime order is N, NE, E, SE, S, SW, W, NW, with N screen-up. Check the body, pram and every
part against this convention independently. The mother and selected pram sheets start with
different views. Do not equate their column indices or silently mirror a missing facing.

Keep these spaces distinct:

| Space | Meaning and conversion |
| --- | --- |
| Sheet pixels | Absolute location in the PNG. Subtract the crop origin to obtain crop-local points. |
| Crop-local pixels | Joint measurements before sprite offset, scale or rotation. |
| Actor-local pixels | Assembled body relative to the logical ground anchor; apply source scale once. |
| World ground | Owner position plus ground-relative offsets; applied displacement drives gait here. |
| Screen projection | Art elevation and foreshortening applied for drawing; a knee bend or swing lift is not ground travel. |

`DirectionalParts.SpriteManifest.apply_segment()` maps authored endpoints to target joints with
an affine basis.
Its longitudinal ratio is target length divided by source-axis length; transverse width uses
the art scale. Applying the art scale again along the length detaches endpoints. Rotate from the
measured painted axis, not an assumed vertical crop. Verify the final transformed painted joints,
not only solver coordinates: compare `sprite.transform * (crop_local_point + sprite.offset)`
with its actor-local target, and inspect whether the measured point actually lies on the painted
joint. An endpoint chosen in transparent padding can pass the transform check. Enable region
filter clipping so neighboring atlas art cannot bleed.

## 3. Assemble a natural idle pose before animating

Use `scenes/dev/illustrated_actor_review.tscn` for all facings at gameplay scale with ground
baselines and the required legacy comparison offset. Compare complete opaque body bounds, not
transparent cells or one component. The complete pram includes chassis, seat, canopy and baby;
sizing only the chassis makes the finished object too large. Keep rigid layer contacts in one
chassis frame, using the measured seat and hinge contacts rather than collapsing all pivots.

Check hips, knees, ankles and soles as a chain. A connected knee can still bend inward, cross the
other leg or sit in a permanent crouch. Ground stride direction and the screen-space knee bend
need separate review: E/W travel must not tilt the entire leg pair diagonally as a substitute
for a walking pose, and N/S travel must not send the feet sideways into a spreading stance.
These are visual acceptance criteria, not instructions to force every projection into one pose.

Place the pram handle within the mother's natural reach, then fit the arms. Inspect shoulder,
elbow and wrist posture and compare arm length to the source. Exact hand-to-handle contact can
pass while the whole arm is stretched unnaturally. For each facing, record shoulder-to-grip
target distance and the authored arm-axis length at the chosen art scale before fitting; review
their ratio with the pose rather than treating arbitrary longitudinal stretch as a solution.
The illustrated compositor reads the legacy
`Stroller.PRAM_DISTANCE`, which also participates in other player presentation behavior; audit
its callers before changing it. Prefer measured per-facing illustrated placement when the
required change is only to illustrated posture. Keep gameplay collision and movement unchanged.

## 4. Check texture quality and motion independently

Trace the visible sprite to its bound source before diagnosing pixelation. The legacy comparison
is deliberately still visible beside the illustrated actor; a missing illustrated child can
leave only that comparison on screen. Check the opt-in flag, registration validity and earliest
resource error to distinguish legacy mode, invalid registration and a missing texture import.
Inspect source detail, extraction edge coverage, crop
size, complete assembly scale, inherited CanvasItem filtering and viewport/camera scaling.
`project.godot` sets `textures/canvas_textures/default_texture_filter=0` and actor parts do not
override filtering. Inspect the effective inherited filter in the assembled actor and the
project setting after import before attributing an artifact to a filter mode. A crisp atlas crop
does not prove good downsampling at gameplay size. Evaluate filtering on the illustrated family
before changing a project-wide setting that affects legacy sprites and UI. Linear filtering
alone cannot restore alpha coverage discarded during extraction.

Drive motion from displacement the owner actually applied. Exercise idle, walk, run, abrupt stop,
blocked movement, reverse, turns and reset/recycle in all facings. Check stance soles against the
paving after every transform, and lift the shin's ankle together with its shoe during swing.
Keep unfinished steps coherent through zero travel. A frozen intermediate pose can be connected
and still look unnatural; record it as a pose issue rather than passing it as an idle review.

`scenes/dev/illustrated_motion_review.tscn` provides sampled displacement poses, mostly south with
a north-facing reversal. It does not cover smooth motion or all directions. Add the missing
directional evidence to the relevant repair before claiming those cases reviewed. Check live
overlaps separately: children with positive z offsets can interleave between actors despite
sharing a parent. Internal facing order must coexist with whole-actor ground-depth sorting.

Use B to capture a gameplay sequence when a still cannot communicate the defect. The
session-captures skill describes the numbered frames, timing metadata and sibling MP4 conversion.
Keep the sequence with its video and compare actual frame timestamps before diagnosing gait speed.

## 5. Prepare and verify the actual checkout

Keep PNGs and `.import` sidecars under version control, including sidecars for evidence images.
Do not remove them during worktree cleanup merely because they are generated. `.godot/` is the
ignored per-checkout cache, and imported textures in it are not transferred by a branch switch.
Preserve existing sidecar settings; inspect new ones after import rather than deleting them.

Run from the folder that will be handed to the player:

```sh
./tools/check.sh
./tools/test.sh visuals limb_attachments mother_attachments --illustrated
./tools/test.sh visuals
./tools/lint.sh
git diff --check
git status --short
```

Use the installed Godot binary for an explicit bounded illustrated gameplay boot:

```sh
GODOT_BIN="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
"$GODOT_BIN" --headless --path . --quit-after 120 -- --illustrated --walk south
```

Inspect the complete output, including the first error. A missing `.ctex` can cause a texture
preload to fail, then a dependent GDScript to fail compilation, then repeated nonexistent `new()`
and nil-method errors. Fix the failed import/load before altering constructors or adding nil
guards to mask it. A zero process exit or passing assertion count does not excuse script errors;
focused validation suites contain deliberate invalid-input probes, which must be distinguished
from unexpected failures. `check.sh` boots legacy mode, so keep the explicit illustrated boot.

Read `verify` before testing or capturing. Use at most one or two purposeful bounded windowed
captures for visual evidence; headless output establishes loading and geometry, not appearance.
Inspect gameplay scale and light/dark contrast. Preserve a player's whole run folder in
`docs/evidence/`; preserve new diagnostics under the dated session-capture archive. Record the
build, flags, dirty changes and what each image actually covers in `DECISIONS.md`. A capture
from before a correction is evidence of the defect, not proof of the correction.

Report separate outcomes for source approval, registration tests, smooth motion, live sorting
and player acceptance. Keep any unverified or visibly failing gate open. Do not expand a family
or ask the player to rediscover known defects just because the endpoint assertions pass.
