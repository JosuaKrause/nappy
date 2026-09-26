## M114 — The moving field grows forward · built 2026-09-11

*(2026-09-10, playtest 55: "while the car moves the field gets narrower and oval -- this is good
but when the car stops it becomes round and bigger? this is counter intuitive. the stretching
should retain the area so an unstretched car field should be the same width with shorter height"
— and, asked to choose between keeping the resting disc's area and keeping its width: "if anything
the moving size should be bigger than the rest size since moving causes more excitement".)* On
`feature/the-field-grows-forward`, three agent commits and one of the orchestrator's, reviewed
here. It overturns M61's field decision below — the catalogued `outer_radius` as a moving field's
*forward* reach — which was the orchestrator's and not the player's.

**The resting disc's width is what the ellipse keeps.** `Tuning.field_scale(e) = 1/(1−e)` is the
one function that states the growth, beside `field_eccentricity()`: the boundary at a catalogued
radius `R` is `R/(1 − e·cosθ)`, exactly `R` abeam at every speed, `R · field_scale(e)` dead ahead,
`R/(1+e)` behind, and the plain disc at `e = 0`. `GroundShape.eccentric_distance()` and the debug
outline both go through it so the growth curve has one owner; `eccentric_distance()`'s own formula
lost its division by `(1−e)`, because the growth and the old normalisation are exact inverses —
derived in both directions rather than assumed. `tests/test_shapes.gd` holds the abeam half-width
equal to the resting radius at every sampled speed, the disc at rest, forward reach growing
monotonically with speed, and approaching still costing more than leaving.

**The fairness contract moved onto the forward reach.** `Tuning.required_telegraph_time` and
`validate_pursuit` are stated over `outer_radius · field_scale(e)` at the row's own speed — the
band `(outer − inner) · field_scale(e)` for a row slower than a walk — `EventDef.field_reach()`
returns the same for a moving point and is unchanged for a segment (every emitting segment row is
stationary), and `CrowdAgent._current_reach()` is stated at the top of its kind's speed range so
the halo's early-out never undercuts a car at full speed. Six rows had their telegraph re-derived
to the new minimum plus the margin each already carried, and no radius moved: `cat_dash`
1.6→2.81s, `fire_truck` 4.0→6.27s, `loose_dog` 1.7→2.25s, `cyclist` 2.0→2.97s (the doubled
hard-fail margin), `police_patrol` 1.7→1.97s, `military_convoy` 3.4→4.43s. Every other mobile row
and both pursuers already cleared the new minimum, confirmed by the boot validation.

**The two constants, and how each was set.** `FIELD_ECCENTRICITY_MAX` 0.7→0.5, read against
`field_scale` rather than the shape alone: at 0.5 the forward reach is exactly 2R, so nothing
reaches more than twice its catalogued radius ahead of itself. `FIELD_ECCENTRICITY_SPEED` 260→500,
set by a measurement rather than by the cap's arithmetic. The agent's first value, 390, failed the
retried-day check in `tests/test_events.gd`: `fire_truck`'s reach grew from 340px to 663px, far
enough to touch an unvisited calm area along its own route in `EventScheduler._calm_to_leave_alone`,
and the day-3 one-shot found no site on 5 of 40 sampled seeds where the pre-M114 disc had placed
it on all 40. At 500 it placed on 40 of 40, then 150 of 150. The cat now sits at e = 0.48, so the
cap is a ceiling nothing in the catalogue reaches. **Open to overturn, and it is a global dial**:
raising the speed constant to rescue one row's placement lowered every row's growth, and the
per-row alternative — teaching placement to tolerate a bigger field — was outside the agent's fence
and is the better fix if a played verdict says a passing car is now too quiet.

**Measured.** The sealing probes (`tests/probes/m64_density.gd` and `m64_measure.gd`) on the same
eight seeds and five days before and after: no day lost its reachable calm area on either side,
per-band events-per-street identical, the role-by-depth counts moving by single digits out of
several hundred. Neither probe samples day 3, which is why the fire-engine regression needed the
direct measurement above. One debug-view capture of layer 1 (`docs/evidence/archive/
session-captures/2026-09-11/`) shows non-circular fields on moving bodies against discs on still
ones; it does not catch a car mid-stop, and the collapse to the disc at `e = 0` is held headless
by the outline test instead. **Unwalked**: whether a car stopping at a light now reads as its field
settling rather than growing, and whether the longer warnings on the fire engine and the cyclist
feel like warning or like waiting.
