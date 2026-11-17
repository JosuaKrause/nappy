# minty-quail — A live event's field_reaches answers with the field's real shape · 2026-11-17


minty-quail's `event-interface.md`, section 7, point 6, first bullet. The player's bar for each
answer the interface makes possible is "whatever is the *correct* implementation" (inbox #1278 in
olive-ferret), each its own pull request.

**Before.** `EventInstance.field_reaches(point)` and `EventPlan.field_reaches(point)` compared the
distance from the event's centre with `outer_radius` (`EventDef.heard_within()`), as the five
callers did: the run log's `cue` line (the suffix naming what raised the mark over her head,
`TelemetryObserver._what_raised_the_mark()`), its "came within reach" watch, its nearest-event
readout's "(out of range)", the abduction's take, and the dusk map's met events. The field the
meter is charged from is not a disc: `GroundShape.field_distance()` prices a stationary body as a
capsule about its spine and a mover as an ellipse with the mover at one focus, and a flock is the
sum of its birds' own point kernels.

**Built.** The live event asks the same distance `field_at()` prices (`_field_distance()` over its
own datum, axis and `travel_velocity()`) against `outer_radius`, and a flock reaches where any one
bird's kernel does over `bird_outer()`; one helper, `_bird_distance()`, is the bird's distance for
both the field and the reach. A plan asks its live event while it is in the world and answers false
otherwise: its only caller, the met-events watch, asks of plans in the world alone, so a plan out of
the world has no field to reach and keeps no disc of its own. Geometry only: a telegraph's damping
and a finished event's zero stay `field_at()`'s.

**What moves**, measured with a probe that walks outward from an instance along and across its
heading until `field_reaches()` turns false (the figures are the edge on each side; `outer` is what
main answered every way):

- **Movers become ellipses**, while they move (a pursuer waiting or telegraphing, and a mover
  telegraphing, has zero velocity and stays a disc): `fire_truck` outer 340 to 548 ahead and 246
  behind; `cyclist` (ends the day) 90 to 134 ahead and 68 behind; every chasing pursuer at chase
  speed, `robber_giving_chase`, `policeman_giving_chase`, `guardsman_giving_chase` 200 to 270 ahead
  and 158 behind, `door_guard`, `van_guard_giving_chase`, `masked_pursuer` 120 to 162 and 95;
  `military_convoy` 300 to 394 and 242; `loose_dog` 140 to 190 and 110; `alley_mouse` 60 to 100
  and 42; `police_patrol` driving 185 to 217 and 161. Slow walkers move a little (`dog_walker`
  105 to 112 and 98). Abeam of any mover the reach is unchanged.
- **The pigeon flock** is the union of its 11 birds' kernels over `bird_outer()` (106) and no
  longer a 168 disc: from its centre the edge lies 127 to 152 out along the rays, so a point
  within 168 that no bird covers is no longer reached.
- **Thirteen stationary segment bodies and `police_patrol` standing** (a 14th) are capsules; along
  the spine the reach grows by the body's half length (`fallen_tree`, `car_accident`,
  `burst_water_main`, `collapsed_frontage` by 72px, `roadblock` 40, `barricade` 38, `protest` 31,
  `firefight` 6) and across it is unchanged.

In the run log: the `cue` line's `| <cause>` suffix names a cyclist or a chasing pursuer when it is
44 to 70px further ahead of its heading than before (`cyclist` 44, `robber_giving_chase` 70) and no
longer names one 22 to 42px inside the old disc behind it (`cyclist` 22, `robber_giving_chase` 42);
the `near` watch and the nearest-event readout's "(out of range)" move the same way for every row
above, and the dusk map's met marks with them. **The unmarked van's take does not move**:
`abduction` is a point row, and its take runs only while it waits, when its velocity is zero.
`tests/probes/excitement_fingerprint.gd` prints the same lines before and after (diff empty), since
what a source charges is `field_at()`'s and not this question's. Play does not visibly change:
the answer reaches log lines and the dusk map and no number the meter is charged from, so there are
no pictures.

**Tested.** `tests/test_event_phase.gd`: every stationary segment row is reached a pixel inside
its capsule along the spine and not a pixel outside; the cyclist, given a route, reaches
`heard_within() / (1 - e)` ahead and `/ (1 + e)` behind and exactly `heard_within()` abeam; the
flock reaches where a bird stands and not a point just inside its row's radius that no bird covers.
`tests/test_event_plan.gd`: a plan answers its live event and is false out of the world. Each was
checked to fail when its line is removed (the flock branch, `travel_velocity()` replaced by zero,
the plan's hand-off replaced by false), and the capsule case fails at main.
