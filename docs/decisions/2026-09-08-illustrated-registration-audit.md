## Illustrated registration audit — 2026-09-08

The player asked to plan the illustrated graphics fixes, include updated main and new reference
photos, then "delegate to cheaper subagents". Two Luna agents audited the source assets and runtime
independently; a third implemented the stationary calibration view requested by PLAYTEST-32.
The repair queue and ILLUSTRATED-GAMEPLAY-FIXES.md keep the implementation order.

The audit found no reliable complete eight-direction modular assembly in the current source
sheets. The mother torso includes sleeves alongside a separate arms row; leg and shoe art reaches
crop boundaries. The pram has seven visible groups despite its eight-column registration, with
checkerboard contamination and pale fringe. Walker silhouettes cross the inferred column/limb
cuts. Exact replacement crop coordinates and the identity of the missing pram view were not
established; the rust-curls variant was not exhaustively measured. These are source inspection
findings, not a new runtime screenshot or a claim of visual acceptance.

The asset agent suggested complete precomposited direction cards as a simpler alternative.
The orchestrator did not adopt that suggestion: PLAYTEST-30 requests interchangeable modular
parts and layered animation. New versioned modular sheets are the prerequisite for authoritative
joint registration, rather than inventing anatomical endpoints in contaminated crops.

Runtime inspection found that applied-displacement wiring, reset/recycle wiring, direction
mapping and hysteresis already exist. The repair brief's descriptions of travel-angle limb
rotation and identical upper-body placement were stale: code uses a downward rest axis and
part-specific body offsets. Pram layers still collapse distinct pivots onto one target, and
walker crops remain inferred from fixed bands and half-cells. Tests cover registrations and
solver coordinates but do not prove the transformed painted joints meet. Strict registration
validation must arrive with valid data and stop failed construction cleanly.

The plan uses the new real-world photo collection for posture and architectural structure,
while keeping the supplied painted mother and urban illustrations as style authority. It
preserves current joystick/tap selection and the new event-outline excitement halo. Generic
crowd halos remain tabled; the graphics repair does not choose an answer to that question.

The calibration scene was captured at 1280x720 with a 25-second external timeout. It shows all
eight static facings, mother/pram and both walker variants at logical 1x scale, with original
SVG drawings offset 96 world pixels right. The screenshot is
`evidence/archive/session-captures/2026-09-08/illustrated-actor-calibration.png`; it is a standalone
scene with no gameplay route/seed, not a playable run. It deliberately exposes the broken source
art and connected-body defects. It does not approve a replacement family or prove motion.

Review caught walker `_ready()` resetting pre-added facings to south; the scene resets each
compositor after adding it. Legacy mother mirroring is restricted to side views, and pram offset
and order follow the player renderer. Headless standalone boot passed. The visual suite without
`--illustrated` emitted a missing-child script error despite its zero-failure assertion summary;
`./tools/test.sh visuals --illustrated` exercised that binding with the child present and passed
the assertions. Sandbox log/certificate diagnostics were separate from that script failure.
