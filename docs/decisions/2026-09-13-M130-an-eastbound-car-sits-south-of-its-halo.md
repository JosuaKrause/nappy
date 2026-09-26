## M130 — An eastbound car sits south of its halo · built 2026-09-13

*(2026-09-13, [PLAYTEST-69](../playtests/PLAYTEST-69.md): "just confirmed on current mobile a car
going west to east that is offset by a few pixel south and the halo is at the regular
position", on v0.10.0 — the sighting M123 closed on waiting for.)* Two agent commits on
`feature/m130-car-halo-offset`, reviewed on the PR; the evidence is
`evidence/m130-car-halo-anchor-2026-09-13/`.

**None of the three suspects; the redraw gate.** `CrowdAgent._redraw_if_the_picture_changed()`
keyed a car's retained draw list on the quantised view alone — sector, mirror, gait frame — while
`_draw_body()` reads the *live* heading twice: `_car_body_anchor()` registers the picture
`26·|heading.y| + 14·|heading.x|` south of the node and `_draw_shape_shadow()` sweeps the
capsule along the same vector. A car that came round an arc kept the anchor it had at the last
sector boundary, up to 22.5° back, for the rest of its run in that lane, since nothing quantised
changed again; twenty degrees off east is about 8px of southward error, always south because
14px is that expression's minimum, and small on a north-south lane, which is why the report is
about an east-west car. `EntityHalo` re-traces the body every frame it is drawn, so the rim sat
at the live anchor and the picture did not: "the halo is at the regular position", verbatim. The
gate dates from M111; the picture joined the continuous side of it at M121; v0.10.0 carries both.

**The three suspects, each answered.** The halo's trace goes through `_car_body_anchor()` — it is
built from the agent's own `_draw_body`, and the bursts show the rim 4px out on every side of a
mirrored side view and an unmirrored back view. There is no PNG transfer for the crowd car at
all — `assets/illustrated/svg-transfer/` has no `crowd` family, so the resolver returns the
authored SVG with or without `--svg`, which is also why desktop `--svg` captures never showed a
difference. And the 14px strike-box datum is right: a pixel column through a straight
east-west car's wheel puts the tyre bottom on the strike box's south line, and the place the
player calls "regular", where the halo stands, is that anchor. M121's rule is unchanged.

**The fix.** The redraw key gains the live heading quantised to `CAR_HEADING_STEPS` (128 per
unit component, so the anchor is held back by at most a sixth of a world pixel and the capsule
axis by a quarter of a degree), kept as a second field beside the quantised picture so neither
slot carries two meanings. A car in a lane costs nothing for it, since its heading there is an
exact cardinal built from `_direction` and the key never changes; only the seconds on an arc pay.
`tests/test_car_views.gd` holds that the rim's bounds equal the picture's grown by the halo
margin at every sector in both presentation modes, and that an arc sweep asks for a redraw at
every half-pixel of ground-line movement, with a non-vacuity guard; with the heading term
neutered the suite goes red. The cues skill gains the trap beside "`_draw()` is retained": a
redraw gate is a promise about everything the drawing reads.

**Open to overturn.** The step count and the two-field key are the agent's choices. No turning
car was caught under a halo on camera in five bursts, the same budget M121's record spent, so
the analytic sweep is the pin and the before frames show the straight-line case; `--invincible`
was left off because it empties the baby's source list and no halo would be drawn. Whether an
eastbound car now sits on its halo on a phone is in `REVIEW.md`.
