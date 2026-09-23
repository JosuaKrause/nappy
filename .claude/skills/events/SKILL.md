---
name: events
description: Rules for adding or changing an event in the catalogue — the fairness contracts every row must satisfy, what obstructs_radius and spawn_mode and role actually mean, and the drawing a row owes. Load this BEFORE touching src/events/event_catalogue.gd, EventDef, EventInstance, EventScheduler, or anything about telegraphs, pursuits, lethal radii or event placement.
---

# Events

The catalogue is data, validated on load. Almost everything a new row needs already exists as a
field; resist adding a script per event.

## Adding a row

The steps are `docs/EVENTS.md`, "Adding a new event". The one that gets skipped is **a drawing**:
an `EventDef.Look` of its own, an SVG in `art/events/`, a `_draw_*` in `EventInstance`, and a row
in `EventInstance.icon_for()` so the screen-edge badge has a silhouette. There is no generic to
borrow — `tests/test_events.gd` fails the build if two rows share a picture.

If it needs behaviour no field covers, add the field to `EventDef` and handle it in `EventInstance`.

## The fields that are decisions, and the ones that are not

**`spawn_mode` is a decision.** `MAP` is the default and is right for anything the player could plan
around: it is a place, and finding out it is there is what walking a street is for.
`AHEAD_OF_PLAYER` is for the small number whose entire content is *the moment it happens to you* —
three seconds of cat is not a place. `TOWARD_PLAYER` (`cyclist`, `loose_dog`) is sited on her line
coming at her: traffic she answers with a route, not an ambush. Neither director-sited mode may
obstruct.

**`sited_on_her_way` is a decision about *when* a place is chosen.** A `MAP` one-shot, never
mobile, placed by her walk rather than at dawn; `EventDef.validate()` refuses any other
combination.

**`hard_fail` is a decision, and it decides where the thing goes as well as what it does.**

**The role is not a decision.** `EventScheduler._role_for` reads it off the def: scenery, ambient
and director-sited rows get none; a one-shot is a **set piece** (sited where every route touches
it); `hard_fail`, a `walk_through_cost()` at or over `Tuning.WALL_WORTH_OF_COST` (48 points), or a
reach that leaves no line past it along a sidewalk makes a **wall** (zero copies on any cell a
route runs along); anything else is **friction** (weighted onto the corridor). A `paces` row's role
depends on where its beat runs, so `_a_pacing_beat_walls_a_sidewalk` decides it in the candidate
loop, where the beat exists. A row that wants a role its data does not imply needs a change to
`_role_for`, not a new field.

**`obstructs_radius` is not a decision.** If it stands still and it is drawn, it is solid at half
its silhouette.

**`pavement_side` usually is not one either** — `ANY` is right for most rows. A kerb
(`AT_THE_KERB`) is for what parks at the road's edge, a van or a skip; a wall
(`AGAINST_THE_BUILDING`) is for what belongs to a frontage, a lorry backing in or a poster crew.

**`departs_at` is only a decision for a stationary event with a `duration`.** Anything mobile
already leaves at its own speed, and anything without a duration never ends.

**`flock_size` changes what a row *is* rather than what it does.** Reach for it only when the event
genuinely is a number of creatures, and set `flock_spread` out of `outer_radius` rather than on top
of it.

## The telegraph fairness contract

**A player who starts walking away the instant an event becomes visible must get clear before it
hurts.** `Tuning.validate_event()` asserts it on load and `tests/test_events.gd` checks the whole
catalogue. A violation is a bug, not a difficulty setting.

One documented exemption: `AMBIENT` events, which never "appear". Nothing is city-wide: every row
has a place and an edge to walk out of, the loudspeaker masts included.

A director-sited (`AHEAD_OF_PLAYER`/`TOWARD_PLAYER`) event is **not** an exemption — it has no
telegraph she can see coming from down the street, so the contract is paid in geometry: the
director sites it a row-specific lead ahead of her, `EventDef.validate()` refuses a `TOWARD_PLAYER`
field that would reach her from that lead, and it refuses any director-sited row that obstructs,
because nothing checks a route around a thing with no tile.

## The contract is per event and the player experiences the sum

**Nothing else happens inside a lethal event's field.** A `hard_fail` event keeps its whole
`outer_radius` clear of every other event at placement (`EventScheduler._room_around()`), and it is
the one spacing rule with no fallback — one that cannot find room is not placed. A new lethal row
inherits this, not just the telegraph.

Two exemptions, both about a field with no fixed place to keep clear: a **wall** placement, which
is off the day's routes by construction, and a **pursuer**, which follows her.
`EventScheduler._keeps_its_field_clear` names both. The reasoning is `docs/EVENTS.md`, "The contract
is per event, and the player experiences the sum".

## A lethal radius and a solid body are the same mechanism

The player is stopped with her centre `obstructs_radius + PLAYER_BODY_RADIUS` from the centre of a
thing, so a `hard_fail` event whose body reaches its own inner radius **can never fire at all** —
which is not an unfair event, it is an event that has quietly been switched off, and that is worse.
`EventDef.validate()` refuses the arrangement on load.

## Anything that stands still is solid at the width it is drawn

`obstructs_radius` is **half the silhouette** and not a balance value — `EventInstance._draw_spread`
draws a blocking object at exactly the width it obstructs for the same reason in the other
direction.

Four exemptions, each written down in `docs/EVENTS.md`, "Solid things are solid": anything
**mobile** (a moving wall pins her), anything **director-sited** (`validate()` refuses it), anything
with no silhouette, and a **flock** (`validate()` refuses that too — several bodies wheeling inside
one disc have no silhouette to be half of, and being walked into is the event).
`tests/test_events.gd` requires everything else to have one.

**A body is a route cost, not a closure.** `Tuning.OBSTRUCTION_A_PARK_CAN_HOLD` (16.0px) is the
`obstructs_radius` a spoiler may carry and still count as something a park can hold — a body you can
walk around does not close a park; one you have to route around does. **If a rule tests
`obstructs_radius > 0`, ask whether it means *has a body* or *closes ground*.**

## A fixture can move, and `EventDef.paces` is how

A **beat** rather than a journey: it walks its route, turns round at the ends, and neither departs
nor expires. A stationary source is a line the player draws once; a man pacing a stretch of
sidewalk is a timing problem on top of a routing one.

The price is the body: anything mobile is exempt from the solidity rule, so making something pace
**takes its `obstructs_radius` away**, and what has to replace it is intensity.

## Nothing vanishes while you are looking at it

An event that is over **leaves**: `EventInstance._be_done()` puts it in a phase where it emits
nothing, cannot end the day and carries no cue, and moves until it is past `Tuning.OUT_OF_SIGHT`
(420px) before it is deleted. **It is over the moment it starts leaving.**

**Three things never leave**, and each would break something that reads the finishing position: a
`spawns_on_finish` row stops where the thing it leaves belongs; a `stops_where_it_arrives` row parks
and stays — still emitting, still the same event (the fire engine at its fire); and anything that
was a *place* rather than a moment is simply over. The rest is `docs/EVENTS.md`, "Going away".

## Pursuits

The mechanics — the stand-off, the break-off as a rate, the waiting state — are
`docs/MECHANICS.md`, "Running that matters" and the sections under it. **A fairness contract about
a moving encounter is stated over distance and checked by walking**, never by asserting the numbers
it was written from. The traps:

- **Clamping the approach at zero is not a stand-off.** The pursuer stands still while *she* closes
  the gap and dies on the first lethal frame; it has to back off (`Tuning.pursuit_standoff()`).
- **A break-off stated as a distance needs two inequalities, and they fight.**
  `Tuning.PURSUIT_SHAKEN_OFF` ends a chase at a **rate** — the gap opening — which only running can
  do, and it is stated over *her*, because a proxy over the pursuer's geometry resets at every
  corner and kerb.
- **Check it with a rig that accelerates.** Nobody turns round in nought seconds; reversing a walk
  into a run takes `(WALK + RUN) / ACCELERATION`, and the contract includes it.
- **A rig that runs on a timer runs into it.** The director sites a pursuit in front of the
  direction she is *actually travelling*, so a `--flee` that starts early puts the pursuit in front
  of the run. It waits for the chase.

Two more about the waiting state (`pursues_within`): **the clock starts when it notices her**, not
at dawn; and **whatever draws it asks `is_waiting()` as well as `is_telegraphing()`** — each is
false in the other's phase, so a picture that asks only the second holds its whole wait in the
wrong posture.

## A thing made of several bodies has to be made of several bodies

`EventDef.flock_size`, and three things about it are worth copying:

- **The excitement stays a pure query, one level down.** The world sums `contribution_at()` over
  instances; a flock sums over its birds. That is what makes the middle of a flock cost more than
  the rim, which is a *route* decision where one disc could only ever be a price.
- **The birds are held inside `flock_spread`, and `flock_spread` comes out of `outer_radius`.** A
  bird emits over `outer_radius - flock_spread`, so the union of the moving fields is inside the
  one disc `validate_event` checked. A moving emitter is only legal while that is true.
- **`lerp` cannot turn a vector round.** Interpolating a unit vector toward its opposite runs down
  the same line to zero and back out the way it came, so normalising gives the heading it started
  with. Rotate by a bounded angle (`EventInstance._steer`), and steer from *half way out*, because a
  turn costs ground.

## A moving thing has to look like it is moving

A bob driven by **distance covered** rather than by time, so what shows is the movement itself: a
stopped thing is still and a fast thing bobs faster. A sprite cannot swing its own legs, so a bob is
what there is.

## The day is planned whole; only the world near the player is built

Every guarantee is stated over a **day** — one usable park, two distinct routes to two distinct calm
areas, a one-shot that fires once per run, determinism from a seed — and all of them are properties
of the *plan*. `EventScheduler.build_day()` plans the entire map at dawn. What streams is the
*instantiation*.

- **Nothing may be seen to appear.** Both radii are wider than half the viewport diagonal.
- **`EVENT_STREAM_RADIUS` must stay wider than the widest field in the catalogue.** Otherwise
  streaming is a way of dropping events on people. `tests/test_event_manager.gd` asserts it.
- **A spent plan stays spent, and a running one resumes.** Streaming may take a running event away
  and give it back; it may never rewind one that has finished, and the bookkeeping an event does
  once — a scar, a block arc — happens on its first instantiation and never again. `Planned.age` and
  `Planned.travelled` carry it over. It **resumes** rather than catching up on lost time.

**Do not move a guarantee out of `build_day` and into the streaming.** If something has to be true
of a day, it has to be decided where the day is.

## Excitement is a pure query

Events never push a value at the baby. `Baby` asks the `WorldContext` for the total at its position,
and the world sums `contribution_at()` over live instances. This is why events compose by simple
addition, there is no ordering to get wrong, and an event can be tested without a scene. **Do not
add a code path that writes to `Baby.excitement` from outside.**

A contact **startles the person she walked into** — the jolt is a decaying source on that agent's
own `contribution_at()`. Anything that wants to "add excitement" should find a body to put it on
rather than a third summand; if there genuinely is no body, that is a design conversation, not a
plumbing one.

**No `impulse` field.** A sharp spike is a short `duration` at high `intensity`.

**Events are defined in code, not `.tres`** — reviewable in a diff, validated on load, assertable as
a whole catalogue in a test.

**No spatial hash.** The concurrent count stays a few dozen even on the last day; a linear scan is
free.
