## SVG artwork and upcoming milestone assets · 2026-09-09

The player followed the SVG review with "actually look at the images and make them look better /
correct", "get a vertical burnt car as well etc", and "also improve existing images as you see
fit". The pass uses rendered SVG previews and gameplay captures, retaining the muted palette,
dark outlines and upright person proportions. It follows the fetched author changes rather than
replacing the moving-van design from PLAYTEST-50.

The crash has end-view cars alongside one another on a north–south street and side-view cars
across an east–west street. The burnt car and moving van have separately authored side and end
views. The van shows a dark loading bay, cargo inside it, open doors and a ramp. Trees have tapered
trunks, branching roots and irregular crowns; broken mains have exposed hollow metal pipes,
jagged asphalt, water and upright barriers. The skip has an open rim, lifting lugs and debris;
the scaffold has braces, couplings and feet; collapsed frontage is a rubble heap with fallen timber.

Two screenshot corrections are the player's, not inferred design choices. "The shadow of the car
accident shouldn't be across everything" replaces its continuous shadow with separate car and
onlooker shadows. "The burnt cars should be perpendicular to the road --- from what I've seen
they need to be rotated by 90", clarified as "(just swap the use of the images)", changes the
binding to side views on north–south streets and vertical views on east–west streets. The van
keeps its street-parallel orientation. The earlier street-parallel burnt-car screenshot records
the rejected binding, not the accepted direction.

Side-view van width is fitted to its 56px collision diameter; the skip canvas is 44px. End views
keep their authored narrower proportions. Circular obstruction remains an approximation of the
vehicle silhouettes; this artwork pass does not change placement, density or collision rules.

The player also asked "also create visuals for checkpoints etc", "and note that they exist in the
milestones", then "yes scan all milestones for pending graphics requests -- let's add all graphics
that will be needed soon". The queue scan covers M62, checkpoints that divide the map; M56, the
resistance is noticed; M65, a protester points at the objective; M100, small, real, and nobody's;
and M101, the fire is found before the engine. Reusable art does not imply that detention, traffic
gates, objective selection, density, district placement or pulse timing are implemented. M79,
the city seen at an angle, remains tabled; the optional illustrated actor track keeps its own gates.

The remaining queue was checked for asset dependencies too. M93, the caret chosen by expected
impact, uses the existing caret vocabulary; M61, a field as body plus kernel, still has an open
question about making directional reach visible, so no new field cue was invented. M96, the
teaching day and dog, M97, calm areas that hold, M98, pressure in the empty acts, and M99, corridor
density after sealing, change placement, timing or balance and can use the existing pictures.
M100's park-tree clumping is a spacing change; its alley readability item is conditional on a
played finding. The prepared district accents and sound arcs are reusable assets, with placement
and pulse behavior still owned by that milestone.

The prepared checkpoint kit has four hut facings, standing and lunging guards, and raised/lowered
gates for both road axes. Paired gate states share a canvas and pivot; the closed state reaches a
far grounded socket. A north-facing hut's doorway is hidden behind its roof, so that view shows
the rear wall and a vent. Existing concrete blocks and improvised barricades were redrawn in their
original canvases. M62 and M56 list the available files without claiming their gameplay complete.

M65's eight pointing poses share a 44×52 canvas and feet anchor (22, 52); westward poses move the
placard to the other hand so the pointing arm remains legible. M100 has a 32×32 industrial roof
vent, a 32×48 civic portico and a 48×32 three-arc sound asset. District placement and sound-pulse
timing remain open. The fence drawing item is complete: its existing 32×32 tile now shows a thin
north–south line, post heads and a shadow from above instead of elevated palings. M101's existing
flame and burnt-facade assets were improved while its fire/engine sequence stays unchanged.
The complete kit preview is `evidence/svg-upcoming-assets-2026-09-09.png`; cells are fitted
individually for inspection. Every source SVG was rasterized and visually inspected, including
the gate states and the corrected hut rear view.

Before reconciliation with main, the complete asset set passed Godot import/boot, XML validation,
documentation lint and whitespace checks. The changed event behavior passed the focused events
suite. Gameplay captures verify the corrected bindings and shadows; prepared future assets have
rendered-source review, with runtime integration still in their owning milestones.

The rendered asset comparisons are `evidence/svg-seals-before-2026-09-09.png` and
`evidence/svg-seals-after-2026-09-09.png`. Individual cells are fitted previews, not a shared
world scale. The initial gameplay review preserves both whole run folders under
`evidence/archive/session-captures/2026-09-09/rig-182605-seed4000-v0.8.2-33-g2b1ee38-dirty/`
(day 5, burnt cars) and
`evidence/archive/session-captures/2026-09-09/rig-182622-seed4000-v0.8.2-33-g2b1ee38-dirty/`
(day 1, crash). The burnt-car rig loads
the real main scene and moves the player beside the first north–south wreck at (1816, 320);
the crash uses `--spawn event:car_accident`. Both capture at 1.5 seconds and normal camera zoom.
The corrected captures use the same scenarios:
`evidence/archive/session-captures/2026-09-09/rig-183151-seed4000-v0.8.2-33-g2b1ee38-dirty/`
shows the separate crash shadows, and
`evidence/archive/session-captures/2026-09-09/rig-183204-seed4000-v0.8.2-33-g2b1ee38-dirty/`
shows the burnt cars perpendicular to the street. Both were visually inspected after the user's
corrections; the roadway between the crash and onlookers has no continuous shadow.
