# minty-quail — A live event's field_reaches answers with the field's real shape · 2026-11-17


minty-quail's `event-interface.md`, section 7, point 6, first bullet. The player's bar for each
answer the interface makes possible is "whatever is the *correct* implementation" (inbox #1278 in
olive-ferret), each its own pull request.

**Before.** `EventInstance.field_reaches(point)` and `EventPlan.field_reaches(point)` compared the
distance from the event's centre with `outer_radius` (`EventDef.heard_within()`), as the five
callers did (the run log's "what ended it" line, its "came within reach" watch, its nearest-event
line's "(out of range)", the abduction's take, the dusk map's met events). The field the meter is
charged from is not a disc: `GroundShape.field_distance()` prices a stationary body as a capsule
about its spine and a mover as an ellipse stretched ahead of it, and a flock as the sum of its
birds' own point kernels.

**Built.** The live event asks the same distance `field_at()` prices (`_field_distance()` over its
own datum, axis and `travel_velocity()`) against `outer_radius`, and a flock reaches where any one
bird's kernel does over `bird_outer()`. A plan whose event is in the world asks it; a plan with no
instance made keeps the disc about where it is placed, because a capsule is turned by the body's
heading and its street, which only a made body has. Geometry only: a telegraph's damping and a
finished event's zero stay `field_at()`'s.

**What moves.** Only rows with a long body (a segment) and movers; a point-shaped row answers as it
did. Thirteen rows have a segment body: along the spine the reach grows by the body's half length
(`fallen_tree`, `car_accident`, `burst_water_main` and `collapsed_frontage` by 72px over 96 to 120,
`roadblock` by 40 over 179, `barricade` by 38, `protest` by 31) and across it is unchanged. So the
run log's "out of range" suffix and "came within reach" watch fire further along such a body, and the
dusk map counts a plan met from further along it. `firefight` is the one segment row that ends the
day (half length 6 over 374), so the log's "what ended it" line differs by at most 6px along it.
**The unmarked van's take does not move**: `abduction` is a point row (`VEHICLE_BODY` is under
the band radius) and parked, so its disc is its field. `tests/probes/excitement_fingerprint.gd`
prints the same lines before and after (diff empty), as expected, since what a source charges is
`field_at()`'s and not this question's. Play does not visibly change, so there are no pictures.

**Tested.** `tests/test_event_phase.gd` walks every stationary segment row: a point a pixel inside
its capsule along the spine, past `outer_radius` from the centre, is reached (it failed at main for
the rows tried), one a pixel outside is not, and abeam the reach is `outer_radius`.
