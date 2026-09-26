## M61 — One shape per object · the field, built 2026-09-10

The last of the shape's three consumers, on `feature/one-shape-per-object-field`, five agent
commits reviewed here; with it M61 is closed. What was asked, 2026-09-02: *"fields should be
ellipses, not circles. the excentricity should be determined by movement speed. the rationale is
that an entity moving towards you has more of an effect than if it moves away or orthogonal. the
entity itself lives in one of the focus points"* — and on 2026-09-05 the general form: *"for every
base shape the minkowsky sum of a circle and the shape should be the influence field … for moving
objects one side of the sum is an oval … most moving objects are small enough to be a point."*

**One rule: the falloff is a function of the distance to the spine.** `Tuning.falloff` is
untouched; what changed is the `d` it is handed. `GroundShape.field_distance()` supplies it:
`distance_to_spine()` in the shape's own rotated frame for a stationary emitter, so a point body's
field is exactly the circle it always was and a segment's is a capsule about the spine, with
`inner_radius` and `outer_radius` now meaning *distance from the spine* and the body's 24px
rounding lying inside `inner`. A moving emitter is a point ⊕ ellipse, `GroundShape.
eccentric_distance()`: `d_eff = r·(1 − e·cosθ)/(1 − e)`, the polar form of a conic from its focus
with the emitter at the **rear** focus, so the boundary at level `L` is `L` dead ahead,
`L·(1−e)/(1+e)` behind and `L·(1−e)` abeam. Eccentricity `e = min(FIELD_ECCENTRICITY_MAX 0.7,
speed / FIELD_ECCENTRICITY_SPEED 260)`: a car at `CAR_SPEED.x` 130 sits at 0.5, a walker at
0.18–0.28, the cyclist at 0.63, the cat at the cap. Zero speed is the plain disc.

**The catalogued outer radius is the forward reach, and that was the orchestrator's decision
rather than the player's.** The alternative — the catalogued number as the ellipse's semi-major
axis, so the forward reach grows to `outer·(1+e)` — would have widened every moving row's field
ahead of it and forced the telegraph contract to be restated over the worst direction. Keeping the
forward reach at the catalogued number leaves `required_telegraph_time` and `validate_pursuit`
exactly as they were and moves every other number *down*, which is the player's own direction
(*"that number was so big because it was a point source before"*). **Overturned by the player
on 2026-09-10, in M114** (the record above): on seeing a car's field grow back into a bigger disc
the instant it stopped, they asked for the other way round — the resting disc is the field's own
width and motion only adds reach ahead of it — so the forward reach is now `outer · field_scale(e)`
and the contract is restated over it.

**Nobody computes the general capsule-and-ellipse sum.** Every emitting segment row in the
catalogue is stationary and everything that moves is a point in field terms — the cat, the dogs,
the cyclist, every pursuer, a flock's birds, and every walker and car in the crowd —
so the two kernels never compose; `tests/test_shapes.gd` holds it as a regression guard. A crowd
agent's field is `eccentric_distance()` off `CrowdAgent.velocity()`, its heading times its speed
times its yield factor, so a car stopped in a queue reads as a disc rather than a still-eccentric
field; a car's horn jolt and a walker's bump jolt use the same distance as the body's own field,
the same source being louder. Each bird of a flock is eccentric by its own `heading * speed`,
already carried for the wheel. An `EventInstance`'s velocity is `travel_velocity()` — zero for
anything not mobile or pursuing, and zero while a pursuer holds its telegraph stand-off — and
`contribution_at()` gained a `velocity_override`, mirroring `intensity_override`, because the
halo's `expected_impact_at()` translates the *sample point* by the caret's velocity and the
ellipse that point is measured against has to be oriented by the same velocity or the two
disagree about which way the thing is going.

**Every "how far" rule takes `EventDef.field_reach()`** — `half_length + outer_radius` for a
segment, `outer_radius` otherwise — in place of `outer_radius`: the lethal clearance
`_keeps_its_field_clear` keeps, the streaming rect, `expected_impact_at()`'s early-out.
`is_lethal_at()` and the car strike box are unchanged: lethal is contact, not noise
(*"lethal != noise"*), and stays a circle of `inner_radius` about the centre.

**The radii were derived, never carried across**, on two principles. For the two pavement rows
the player named: `inner` is the body's rounding plus her own radius (24 + 14 = 38, she is
touching the tables) and `outer` is the pavement band's centre to the carriageway's centre line
(32 + 32 = 64) — *"bill somebody at the tables and not somebody across the street"*, with
"across" beginning at the centre line. For every other emitting segment row, both radii lose the
segment's half-length so the along-axis reach from the centre is what it was and only the
across-axis over-reach goes; an inner that falls under the 24px rounding is clamped to it.

| Row | Shape (half-length/radius) | Old inner/outer | New inner/outer |
|---|---|---|---|
| `cafe_tables` | point, 24 | 40/90 | 38/64 |
| `market_stall` | 4/24 | 44/95 | 38/64 |
| `roadblock` | 36/24 | 52/215 | 24/179 (inner clamped from 16) |
| `protest` | 31/24 | 70/300 | 39/269 |
| `burnt_shell` | 12/24 | 30/90 | 24/78 (inner clamped from 18) |
| `firefight` | 6/24 | 90/380 | 84/374 |

Intensities untouched. The silent bands — `barricade`, `construction`, `delivery_van` and the
seals — had nothing to derive. **Measured with the sealing probes on the same seeds before and
after**: the per-row cost of `cafe_tables` fell from 12.3 to 9.6 and `market_stall` from 16.5 to
12.0, every other named row was unchanged, and the density, corridor-share, closure and
friction-placement figures moved within noise. No relationship in `tests/test_balance.gd` went
red, so nothing was retuned. The cost table in `docs/EVENTS.md` was regenerated.

**Choices open to overturn, made where the design was silent.** Nothing draws the field for the
player: the cues rule refuses to draw a field, and the asymmetry is the ordinary intuition that a
thing coming at you is louder than one going away, so the debug view (`1`) is where it is seen.
`firefight`'s `inner_radius` is also its lethal circle, so the derivation narrows that circle from
90 to 84px as a side effect — margins and tests hold, but it was not a lethality decision.
`EventScheduler._denial_radius()` and `_spoiling_grid()` (the park spoiler's weighting) and
`EventDef.emission_at()`/`walk_through_cost()` (the cost table's integral) still measure from the
centre along a line, an approximation for segment rows; and `event_manager.gd`, `main.gd`,
`resistance_director.gd`, `telemetry_map.gd`, `telemetry_observer.gd` and `danger_edge.gd` still
read `outer_radius` as a plain circle for "met the event" and badge-distance logic, now a slightly
looser approximation for a segment row. M111, cars follow their turns, asks for velocity derived
from actual motion; `CrowdAgent.velocity()` and `EventInstance.travel_velocity()` are that.

**Evidence**: `docs/evidence/m61-field-after.png` — seed 4242, day 1, `--layers 1,3 --walk 3s6e`,
the same rig as M104's `m104-layers-all.png` — a car's field is an egg along its travel and the
scaffolding's a capsule about its spine, where the earlier picture shows circles.
