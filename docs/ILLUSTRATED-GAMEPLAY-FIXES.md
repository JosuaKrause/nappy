# Illustrated gameplay repair instructions

This brief addresses [the gameplay capture](evidence/archive/session-captures/2026-09-06/illustrated-gameplay-review.png).
The capture is dated evidence, not an approved art reference. These are implementation
instructions from inspection of that frame, its source sheets and the current compositors;
they are not a claim that repairs are implemented or visually accepted.

[PLAYTEST-45](PLAYTEST-45.md) adds directional leg posture, natural mother-to-handle reach,
pram image quality and actual-checkout loading to this repair. Follow the illustrated-png
skill's [texture integration procedure](../.claude/skills/illustrated-png/references/texture-integration.md)
for repeatable source, import, registration and acceptance steps.

Read `CLAUDE.md`, `HANDOFF.md`, `PLAYTEST-30.md`, `VISUALS.md` and the M84 record in
`DECISIONS.md` first. The handoff identifies the illustrated presentation and street study as
rejected; descriptions elsewhere of an approved street gate do not authorize reusing that study.
Use the supplied mother and urban reference images named in `VISUALS.md` for art direction.
Keep the cardinal camera, logical bodies, movement, collision, crowd density and gameplay RNG.

## Implementation contracts

Runtime registration must describe actual painted parts: per-facing crops, crop-local joints,
rest axes, scale and draw order. A declared grid or a passing parser does not establish connected
anatomy. Compare the rendered output with the source artwork and the ground contacts; the dated
frame's diagnosis is evidence rather than a description of every later implementation.

PLAYTEST-32 requires the original drawing beside each illustrated object at a fixed horizontal
offset. The compositors expose a 96-world-pixel comparison offset. Use the legacy yeller as the
pedestrian scale comparison and judge complete assembled bodies, not transparent sheet bounds.

The real-world inputs under `docs/reference/` supply stroller posture, continuous shopfronts,
recessed entrances, awnings, fire escapes, flat roofs, parapets, skylights, ducts and equipment
clusters. Translate their structure into the supplied illustrations' style. Keep references out
of runtime assets. Inspect the stroller video for movement before making claims about its turns.

Preserve the current joystick/tap choice and button behavior. Event and crowd artwork must preserve
the excitement halo that traces the actively contributing entity's silhouette: a layered PNG
replacement needs the outline of the animated assembly, not an invisible legacy body. Keep the
source selection across events, walkers and cars. Hue and transparency both follow each source's
attributed meter contribution over the last five seconds, with their separate curves and easing.

## What the frame establishes

| Visible issue | Repair priority |
| --- | --- |
| Detached trouser segments and tiny shoes surround pedestrians across the frame. | Reconstruct one complete registered pedestrian before expanding variants. |
| At the centre, the mother's head/clothing overlap near ground level while legs float above; the pram reads as separate horizontal slices. | Rebuild attachment transforms and the pram asset registration. |
| Pale rectangular speckling surrounds the central pram. | Inspect source transparency and crop contamination before attributing it to an occlusion effect. |
| Detailed cutout people sit in a flat, sparsely detailed street with large plain building surfaces and simpler vehicles/props. | Integrate a coherent illustrated environment after the actor assembly gate. |
| A large developer readout covers the right street; tutorial text dominates the lower centre. | Separate diagnostic evidence from a clean gameplay composition review. |

A still cannot establish foot sliding, frame-rate stability, correct recycling, or how limbs
behave while turning. Those need movement evidence. Nor does this frame prove a traffic,
collision or density defect: do not change those systems to hide a drawing problem.

## 1. Make the sheets and their manifests agree

Start in `assets/illustrated/modular/`, `assets/illustrated/walkers/` and
`src/visuals/directional_parts.gd`, which maps sheet regions and pivots to sprites.

- Inspect every direction crop at source resolution and assembled gameplay size. Measure actual
  artwork bounds and attachment points; an equal grid and a declared direction order are not
  evidence that a generated image follows them.
- PLAYTEST-44 selects `pram-layered-v3-draft-transparent.png`. Its eight views contain chassis,
  seat, canopy and baby layers packed at different vertical intervals. Register each against
  measured wheel, hinge and seat contacts; equal-height row cuts are not valid for this sheet.
- Map actual facings explicitly to N, NE, E, SE, S, SW, W, NW, with N meaning screen-up.
  The mother's source begins with its front view; the selected pram begins with its rear view.
  Their column mappings are independent. Check matching mother and pram facings together.
- The mother's painted parts are independently packed into rows. The torso already includes
  arms, and the shoe area contains additional shoe drawings. Extract exactly the part named by
  each registration; remove duplicate anatomy from newly authored modular layers. A whole row
  cell must not contribute unrelated shoes or a second pair of arms.
- Walker source silhouettes cross nominal column boundaries, and profile views provide only
  one complete leg set. Use measured per-part regions and explicit left/right ownership.
  Record any same-facing source reuse explicitly; a neighboring fragment or mirrored direction
  cannot stand in for a missing part. Distinct inner/outer profile artwork remains an authoring
  requirement where the single supplied profile cannot express it.
- Use one authoritative machine-readable manifest for runtime registration and asset inspection.
  Include crop, crop-local attachment points, rest-axis endpoints, scale, actual facing and
  per-direction order. Validate texture bounds, required parts and missing directions loudly.
  Stop construction cleanly after failed validation: callers must not ignore a failed
  registration and dereference a null sprite. A missing file, duplicate source direction or
  missing direction mapping must not silently select another view. Introduce strict endpoint
  requirements together with valid replacement registrations, so the schema change and its
  consumers agree in the same implementation item.

PLAYTEST-44 accepts the selected pram's extracted transparency. Preserve that PNG while repairing
registration. Its extraction record is `assets/illustrated/modular/pram-alpha-extraction-2026-09-08.md`.
For any replacement art, inspect alpha values in intended empty areas and composite over contrasting
backgrounds: an alpha channel alone does not establish a clean edge. Do not erase every pale pixel;
highlights belong to the drawing. Follow the image-generation skill for replacement raster art.

Acceptance: every isolated crop contains only its named part; every direction can be assembled
into a complete static person/pram with no foreign fragments, checker rectangles or duplicate limbs.

## 2. Rebuild attachment transforms from a common ground anchor

`src/visuals/modular_person.gd` must assemble upper-body parts against measured anatomical targets
and pram layers against one chassis frame. Independently packed source rows have their own local
coordinates; their pivots are not interchangeable positions on the actor.

- Define a per-direction rest skeleton relative to the owner's ground anchor: pelvis, neck,
  shoulders, hips, knees and ankles, plus hand and pram-handle contacts. Derive body placement
  from that skeleton. A neck pivot goes to the neck target, not to the actor origin.
- For a cropped part, transform a texture point as
  `target_joint + rotation * scale * (texture_point - crop_local_pivot)`.
  Keep texture pixels, actor-local drawing coordinates and world ground coordinates explicit.
  Apply the source-to-game scale once. The parent already supplies owner translation.
- Assemble rigid pram layers against one shared chassis coordinate system. Preserve their
  designed offsets from axle/ground baseline; do not collapse canopy, basket and wheels onto
  their separate pivots at a common position.
- Author per-facing pram placement that visibly
  joins the mother's hands to the handle. The combined visual stays registered to the existing
  logical owner. Changing its collision shape is outside this repair.
- Keep the handle within natural arm reach. Hand contact alone does not establish correct
  posture: compare shoulder-to-wrist length and elbow shape to the source, and bring the pram
  into reach rather than stretching the arm to an arbitrary offset.
- Calibrate mother, pram and walkers together at gameplay scale. Their torso heights, limb
  lengths and wheel sizes must agree before animation is enabled. The current independent art
  scales and gait lengths are inputs to review, not proportions to preserve blindly.

Acceptance: the idle pose works in all eight directions. Feet and wheels meet the ground,
head meets neck, legs meet hips, hands meet handle, and switching facing does not teleport the
assembly away from its owner. Prove this before tuning a walk cycle.

## 3. Make rendered limbs follow the solved gait

Each painted limb has its own rest axis. `ModularPerson` and `ModularWalker` must map that axis
onto the solved joint segment, preserving transverse width while fitting its longitudinal extent.
Target distances are already world pixels: multiplying the longitudinal ratio by the source-to-world
scale a second time shortens the rendered segment and detaches its distal joint.

- Measure proximal and distal attachment points for each limb crop. Compute rotation from its
  authored rest axis to the desired joint segment. Match the rendered segment length to the
  solved length with suitable authored proportions and controlled longitudinal scaling.
- Make the upper leg end at the rendered knee and the lower leg end at the rendered ankle.
  Apply swing-foot height to the ankle used by the leg as well as the shoe; lifting only the
  shoe separates it from the shin.
- Keep `PlantedGait`'s world-ground stance constraint, but verify the rendered sole after all
  sprite transforms. A correct invisible foot target does not prove that the shoe lands there.
- Drive travel from applied displacement, including collision and shoves. Verify idle, walk,
  run, abrupt stop, reverse, turn, blocked movement and reset/recycle. Zero applied travel must
  not keep advancing a walking cycle. Maintain direction hysteresis without mismatching parts.
- Review east/west leg slant and north/south outward spreading explicitly for mustard and red
  walkers. Separate the ground stride from screen-space knee bend and swing lift; per-facing
  natural posture is a gate beyond connected endpoints. Cover every direction in movement
  evidence because the sampled review scene concentrates on south and north.

Acceptance: a planted rendered sole remains fixed against paving during stance; swing feet
lift and land connected to their legs; stopping and turning leave a complete connected actor.

## 4. Order whole actors and their parts correctly

Internal part order depends on facing. Keep that order within one actor assembly; positive child
z offsets can otherwise sort one person's shoes over another person's torso. Being a child is not
itself proof that the parts sort as one actor in the city.

- Author near/far leg and arm order for each facing. Put the pram in front of or behind the
  relevant body parts according to the view, with hands visibly meeting the handle.
- Inspect the actual actor/city sorting hierarchy. Keep internal part ordering confined to
  the actor's visual assembly so one person's shoes cannot sort through another's torso merely
  because all shoes share a higher z value. Sort world overlap using ground depth.
- Verify crossings between two people, player and car, and actor and foreground roof in both
  directions. Preserve stable local dotted occlusion and readable existing danger/baby cues.
  Do not use transparency to disguise a disconnected assembly.

Acceptance: each person reads as one body at overlaps, the pram occludes coherently, and roofs
do not hide the player or approaching threats. Review consecutive frames as well as stills.

## 5. Resolve the presentation mismatch and review composition

The live illustrated switch binds characters; it does not make the standalone illustrated
street the live city. Do not report the environment fixed because its separate scene renders.

- After actor assembly passes, build a representative live apartment frontage, pavement and
  crossing from the supplied urban references. Use consistent painted materials, line weight
  and apparent scale with the actors. Keep passable ground and crossings legible.
- Give the large plain building areas credible roof structure and multi-storey frontage,
  entrances and appropriate street detail. Use camera-specific depth compression and reviewed
  occlusion to retain visibility. Do not add visual doorways that imply nonexistent routes.
- Replace vehicles and authored props/events by their own reviewed families. Keep incomplete
  families explicit; generic pedestrians cannot substitute for event identities. Expand modular
  crowd variation only after the small initial set shares reliable joints and proportions.
- Produce a clean gameplay view without the diagnostic readout alongside targeted diagnostics.
  Review HUD/tutorial hierarchy against the current control behavior, including portrait/touch.
  Do not remove useful diagnostics or change the tutorial solely because this debug frame shows
  them. Do not inherit obsolete title choices from the graphics handoff.

## Verification and handoff

`scenes/dev/illustrated_actor_review.tscn` displays static mother/pram and both walker variants
in all eight directions at logical scale, with ground baselines and the legacy drawing at the
fixed comparison offset. It instantiates compositors only, so it does not move gameplay actors.
Run it with Godot's normal scene argument; the existing screenshot flags work:

```sh
godot --path . res://scenes/dev/illustrated_actor_review.tscn --resolution 1280x720 \
  -- --screenshot /private/tmp/illustrated-actor-review.png --after 1
```

Use an external timeout for a windowed capture. This is a static registration diagnostic;
it cannot establish motion quality, live-world sorting or visual acceptance. Light actor-row
backdrops expose the dark frame and limb contours. Dated captures and their exact build limits,
including the [contact review](evidence/archive/session-captures/2026-09-08/illustrated-limbs-contact-review.png),
are indexed in DECISIONS.md under Limb attachment repair.

`scenes/dev/illustrated_motion_review.tscn` samples the compositors through applied-displacement
sequences: idle, initial stride, each foot in mid-swing, sustained walk, run, blocked stop,
reverse and reset. Most samples face south for comparison; the reverse faces north. Foot ticks
show the solver's ground targets so the rendered shoe can be compared with its intended contact.
The virtual owner position accumulates travel while each display cell stays fixed. Run this
scene with the same bounded screenshot command, substituting its scene path and output name.
It checks sampled assembly poses; it does not establish smooth motion or live city sorting.

Run `./tools/test.sh visuals limb_attachments mother_attachments --illustrated` for the focused
registration, rendered-endpoint and displacement checks. Exercise the legacy path with
`./tools/test.sh visuals`. The live-owner test checks that the opt-in child is absent in legacy
mode. A zero-failure assertion summary does not excuse a script error.

PLAYTEST-42 requires higher raster resolution for the current view: preserve the physical window,
visible world extent, actor size, HUD and input mapping, and downsample additional rendered pixels.
A wider camera view does not satisfy the request. For the same-view raster experiment, use
`--illustrated --illustrated-render-scale 2` at the same `1280x720` window size. The scene keeps
its existing 2× camera framing, so the visible world, actor size, HUD layout and input coordinates
remain the baseline while the root target draws at `2560x1440` and resolves each 2×2 block before
it reaches the `1280x720` window. The command is debug-only and does nothing to legacy presentation.
Compare the printed logical, target and output dimensions before reviewing a capture; the saved
root-viewport PNG is resolved render output, not a pristine high-resolution source. The experiment
is not visually verified; its open checks are in TODO.md and HANDOFF.md. Resolution does not
establish a fix for anatomy, gait, compositing or source-art noise.

Implement in bounded sequential pieces: sheet/manifest repair, static assembly, gait and sorting,
then environment integration. Use isolated implementation worktrees under the orchestration
rules; the orchestrator owns queue changes and visual acceptance. Load the path-matched skills,
especially illustrated-PNG, Godot and verification; load city/crowd/cues rules if those areas change.

Run `./tools/check.sh`, `./tools/lint.sh` and the affected focused suites. Extend the existing
visual tests to check rendered attachment continuity, sole placement and clean reset behavior,
not just sprite existence, region count or the solver's own coordinates. Compare equivalent
legacy/illustrated scenarios to ensure the presentation changes no simulation state.

Use a bounded contact/movement review covering all facings and at most one or two purposeful
windowed captures at the end. Include the capture's visible seed, 3224974826, when reproducing
the busy street; the screenshot alone does not supply the exact original route or build state.
Save new evidence under its dated session-capture directory. Inspect native gameplay size,
overlap, clean alpha and motion. If a display is unavailable, report the visual gate unverified.

Keep the illustrated presentation review-only until the player accepts the repaired result.
Report each repaired defect, the checks and images supporting it, and any remaining family or
motion gap. Passing headless checks cannot override visible disconnection in the rendered game.
