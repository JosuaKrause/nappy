## M129 — The leaf blower is a wall to walk past and a busker to stay near · built 2026-09-15

*(2026-09-15, [PLAYTEST-76](../playtests/PLAYTEST-76.md): "walking past a leaf blower should still
be like a wall. but staying away from it should only prevent sleeping in a calm area (much like
the busker)" — "a leaf blower should be able to close one side of a street and spaced out
correctly a calm area" — on counting walls at all, "option 2 is valid only if the influence at
a junction is low enough that it can be taken without having to worry or plan around it" — and
"can we influence the drop off of excitement per row?" — "we can introduce the exponent but
leave everything as is for now".)* Four agent commits and one of the session's on
`feature/m129-leaf-blower-field`, reviewed on the PR; the probe's output at each state is
`evidence/m129-leaf-blower-2026-09-15/probe-*.txt`.

**The probe, across the branch.** `tests/probes/m129_zero_cost_line.gd`, six seeds by one day
per act, under the decided reading.

| | before | the ground it charges for | walls count |
|---|---|---|---|
| routes with a zero-cost line | 99/296 (33.4%) | 161/296 (54.4%) | 183/296 (61.8%) |
| act I / II / III / IV | 37.2 / 39.8 / 35.1 / 12.5% | 66.3 / 65.9 / 45.9 / 25.0% | 83.7 / 67.0 / 54.1 / 25.0% |
| the junction itself is taken (routes / cuts) | 122 / 208 | 77 / 125 | 69 / 97 |
| one row spans the street | 15 / 27 | 5 / 15 | 1 / 1 |
| a pacing row with no opening | 5 / 18 | 2 / 3 | 2 / 3 |
| mid-block crossings, routes on a carriageway | 0, 0 | 0, 0 | 0, 0 |

**A field with two parts.** `EventDef.core_intensity` and `core_radius`, zero on every row but
one, are a louder inner band on the same curve, and `EventDef.emission_at_distance()` answers
the larger of the core and the field at every distance, so a core only ever adds and only
inside itself. `leaf_blower`'s field is the busker's number for number (19.3 over 45/190, its
own 4.0 s pulse kept) and its core is 22.2 out to 64 px, a pavement's width
(`Tuning.SIDEWALK_WIDTH * TILE_SIZE`): the line through the centre costs 37.8, over
`Tuning.WALL_WORTH_OF_COST` (35.0), so the row stays a wall by role, and a line past it at the
core's edge costs what the busker's does; the whole-radius cost fell from 67.1 to 64.8. The
instance hands `current_intensity()` in rather than the catalogued peak, so the telegraph and
the pulse damp the core by the fraction they damp the field by — a leaf blower between bursts
is a quarter of a wall inside a quarter of a busker. Handing the damped peak in, rather than
dividing a scale back out, is why no uncored row moved by a bit: `tests/test_events.gd` walks
every other row out past its rim at 16 px steps and requires `Tuning.falloff` on the plain
field exactly.

**A row denies the ground it charges for.** `EventScheduler._line_reach_of()` is the radius
inside which a row emits more than `Tuning.EXCITEMENT_DECAY_WALKING` (6.0/s) — the disc a walk
through nets a cost in — or `obstructs_radius` where that is larger; a `hard_fail` row keeps its
whole `outer_radius`, since nothing about being quiet at the rim makes walking into it
survivable. For a plain quadratic row that takes about 13% off the radius at intensity 20.
`_denial_radius()`, what a row denies to a pram trying to settle, shares the inversion
(`_reach_above`) at its own `CALM_ZONE_DENIAL_RATE` and answers as it did (the busker 157 px).

**Walls count, on that reading.** `_counts_against_the_line()` no longer exempts the `WALL`
role, and nothing else about a wall changes: `_copies_of` still offers it zero copies of
corridor ground, and the lethal-clearance rule's own wall exemption is a different rule about
keeping other events out of a lethal field. The exemption's argument was that a wall bounds the
corridor, so a field reaching from there onto the route is the guidance; what the probe showed
is that the same field covers the crossings, and being told to walk a corridor whose junctions
are covered by the thing bounding it is being charged for the guidance. The player's condition
— an influence at a junction low enough to take without planning — is exactly what the reading
above leaves a wall free to put over one.

**A row may shape its own drop-off, and none does.** `EventDef.falloff_power` (2.0) is the
exponent on the drop, `intensity * (1 - t ** power)`, and `Tuning.falloff` takes it. The default
is written out in two places — `t * t` at 2.0 in `falloff`, `sqrt` at 2.0 in the inversion —
because `pow(t, 2.0)` and `pow(x, 0.5)` are within a bit of the expressions the catalogue was
measured against rather than equal to them; the probe's output after the commit is
byte-identical to the one before it. `validate()` refuses a power at or below zero, a flock's
birds share their row's power, and the core goes through the same curve at the same default.

**The one fork, decided this side and open to overturn.** Under the reading, a leaf blower's
charging disc is its hum, 165 px, not its 64 px core — the busker's is the same 165 — so
neither may stand where that disc would close a route junction, a route street's width or a
beat's opening; *"close one side of a street"* holds wherever a wall does stand, which is off
the corridor by the weights. The alternative was to read a cored row's line reach as its core
alone, which would let a route's own pavement sit 112 to 144 px from a leaf blower on the far
one, inside 10 to 15/s of hum — 4 to 9/s over the walking decay, ground a walk has to plan
around by the player's own condition, and a line the probe would then have to call zero-cost
while the meter climbed on it. Shrinking the hum instead is the busker's field, which the player
named as the model, and the **balance** rule's decision. Kept as built, 2026-09-15; the player
was asked to choose and handed the choice back.

**What is left.** Two routes in five still carry no zero-cost line. The largest shape is a
route junction covered by several rows together (69 routes, 97 cuts), with the leaf blower in
the cut on 74 of the 113 broken routes; the day's own catalogue rows account for 66.9% on their
own, so the seals `SealPlanner` places before the scheduler runs cost about five points. The
three rules refuse a candidate cumulatively, so a crossing the probe finds under four rows is
one they were not asked about; which placement paths they never see is the open item under
M129 in `TODO.md`.
