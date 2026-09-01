---
name: events
description: Rules for adding or changing an event in the catalogue — the fairness contracts every row must satisfy, what obstructs_radius and spawn_mode and role actually mean, and the drawing a row owes. Load this BEFORE touching src/events/event_catalogue.gd, EventDef, EventInstance, EventScheduler, or anything about telegraphs, pursuits, lethal radii or event placement.
---

# Events

The catalogue is data, validated on load. Almost everything a new row needs already exists as a
field; resist adding a script per event.

## Adding a row

`src/events/event_catalogue.gd` in the act's section, a line in the `docs/EVENTS.md` table, and **a
drawing**: an `EventDef.Look` of its own, an SVG in `assets/events/`, a `_draw_*` in
`EventInstance`, and a row in `EventInstance.icon_for()` so the screen-edge badge has a silhouette.
That last part is not optional and there is no generic to borrow — `tests/test_events.gd` fails the
build if two rows share a picture.

If it needs behaviour no field covers, add the field to `EventDef` and handle it in `EventInstance`.

## The fields that are decisions, and the ones that are not

**`spawn_mode` is a decision.** `MAP` is the default and is right for anything the player could plan
around: it is a place, and finding out it is there is what walking a street is for.
`AHEAD_OF_PLAYER` is for the small number whose entire content is *the moment it happens to you* —
three seconds of cat is not a place — and it may not obstruct.

**`hard_fail` is a decision, and it decides where the thing goes as well as what it does.**

**The role is not a decision.** `EventScheduler._role_for` reads it off the def — lethal is a
**wall** and goes off the day's corridor, a one-shot is a **set piece** and goes where every route
touches it, anything else placed on a tile is **friction** and is weighted onto the corridor. A new
row is placed against the day's routes without anybody writing a rule for it. If a new row wants a
role its effect does not imply, that is a design conversation and a change to `_role_for`, not a
field on the def.

**`obstructs_radius` is not a decision.** If it stands still and it is drawn, it is solid at half
its silhouette.

**`pavement_side` usually is not one either** — `ANY` is right for almost everything. The two rows
that use it do so because a parked vehicle belongs at a kerb and a thing that reverses into a yard
needs a wall.

**`departs_at` is only a decision for a stationary event with a `duration`.** Anything mobile
already leaves at its own speed, and anything without a duration never ends.

**`flock_size` changes what a row *is* rather than what it does.** Reach for it only when the event
genuinely is a number of creatures, and set `flock_spread` out of `outer_radius` rather than on top
of it.

## The telegraph fairness contract

**A player who starts walking away the instant an event becomes visible must get clear before it
hurts.** `Tuning.validate_event()` asserts it on load and `tests/test_events.gd` checks the whole
catalogue. A violation is a bug, not a difficulty setting.

Two documented exemptions: `AMBIENT` events (they never "appear") and `city_wide` ones (no edge to
walk out of).

An `AHEAD_OF_PLAYER` event is **not** an exemption — it has no telegraph phase the player can see
coming, so the contract is paid in geometry instead. It is sited far enough ahead that she is
outside its outer radius for the whole telegraph, and `EventDef.validate()` refuses one that
obstructs, because nothing checks a route around a thing with no tile.

## The contract is per event and the player experiences the sum

At one event per block the outer radii overlap, so walking out of one field can mean walking into
another — the density working, right up until the field she walks into is one of the three that end
the day.

**Nothing else happens inside a lethal event's field.** A `hard_fail` event keeps its whole
`outer_radius` clear of every other event at placement, and it is the one spacing rule with no
fallback — an abduction that cannot find room is not placed. `EventScheduler._room_around()`
enforces it. If a new event becomes lethal, it inherits this, not just the telegraph.

**Off the day's corridor is exempt, and the exemption is the design.** There is no route she is
meant to take off the corridor — the point of that ground is that she should not be on it — so
lethal fields there may overlap each other and everything else. Under the old rule "deadly all over"
was not merely hard, it was arithmetic: six lethal rows capped at three to five, at radii of
145–380px, cannot tile anything.

The exemption is exactly the `WALL` role, by construction: `_copies_of` offers a wall zero copies of
any tile inside the corridor, so a lethal placement carrying that role is off the routes or it does
not exist. `EventScheduler._keeps_its_field_clear` is the one place that decides. **The telegraph
contract is untouched by this** — that one is about a single event's own geometry.

## A lethal radius and a solid body are the same mechanism

The player is stopped with her centre `obstructs_radius + PLAYER_BODY_RADIUS` from the centre of a
thing, so a `hard_fail` event whose body reaches its own inner radius **can never fire at all** —
which is not an unfair event, it is an event that has quietly been switched off, and that is worse.
`EventDef.validate()` refuses the arrangement on load.

## Anything that stands still is solid at the width it is drawn

`obstructs_radius` is **half the silhouette** and not a balance value — `EventInstance._draw_spread`
draws a blocking object at exactly the width it obstructs for the same reason in the other
direction.

Three exemptions, each written down in `docs/EVENTS.md`, "Solid things are solid": anything
**mobile** (a moving wall pins her), anything `AHEAD_OF_PLAYER` (`validate()` refuses it), and
anything with no silhouette. `tests/test_events.gd` requires everything else to have one.

**A body is a route cost, not a closure.** `Tuning.OBSTRUCTION_A_PARK_CAN_HOLD` (16.0px) is the
`obstructs_radius` a spoiler may carry and still count as something a park can hold — a body you can
walk around does not close a 704px lot; one you have to route around does. **If a rule tests
`obstructs_radius > 0`, ask whether it means *has a body* or *closes ground*.**

## A fixture can move, and `EventDef.paces` is how

A **beat** rather than a journey: it walks its route, turns round at the ends, and neither departs
nor expires. A stationary source is a fixed price on a fixed patch of ground — a line you draw once
and never think about again — and a man pacing two hundred and fifty pixels of footway is a timing
problem on top of a routing one.

The price is the body: anything mobile is exempt from the solidity rule, so making something pace
**takes its `obstructs_radius` away**, and what has to replace it is intensity.

## Nothing vanishes while you are looking at it

An event that is over **leaves**. `EventInstance._be_done()` puts it in a leaving phase where it
emits nothing, cannot end the day and carries no cue, and it moves until it is past
`Tuning.OUT_OF_SIGHT` before it is deleted.

- **Anything `mobile` leaves at its own `speed` and needs no data.** `EventDef.departs_at` is for
  the rest — a flock, which has to fly, and a pursuer that has lost interest.
- **It is over the moment it starts leaving.** A cat that trailed its field behind it for the two
  seconds it took to reach the kerb would be a worse bug than the one being fixed.
- **Two things never leave**, and both would break something that reads the finishing position: an
  event with a `spawns_on_finish` stops where the thing it leaves belongs, and anything that was a
  *place* rather than a moment has always simply been over.

## Pursuits

**A pursuit has two shapes and a third state.** `charging_dog` is a **moment** — the director sites
it in front of her and the chase is all of it. `EventDef.pursues_within` is the other shape: a thing
that is *somewhere*, that can be seen and priced and routed around, and that becomes a chase if she
walks up to it. Two things about the waiting state are easy to get backwards:

- **The clock starts when it notices her**, not when the day put it there. A telegraph that ran at
  dawn four streets away arrives with no notice in it at all.
- **Its notice does not damp what it emits.** `TELEGRAPH_INTENSITY_FRACTION` means *this has not
  started yet*; a man standing in that alley has started, and what has not started is the lunge. It
  is the one telegraph in the game that does not quieten the thing it is warning about.

**A fairness contract stated in seconds is not stated at all.** When a contract is about a moving
encounter, **state it over distance and check it by walking**, not by asserting the numbers it was
written from. `Tuning.pursuit_standoff()` is the notice as a distance; `tests/test_events.gd` walks
the answers. Four traps:

- **Clamping the approach at zero is not a stand-off.** It leaves the pursuer standing politely
  still while *she* closes the last hundred pixels and dies on the first lethal frame — the contract
  true of the thing and false of the encounter. It has to back off, and the price is the wart: a
  stand-off wide enough to be seen doing it is a dog that visibly reverses.
- **A break-off stated as a distance needs two inequalities and they fight.**
  `Tuning.PURSUIT_SHAKEN_OFF` ends a chase at a **rate**: the pursuer is faster than a walk and
  slower than a run by construction, so *only running can open the gap*.
- **Check it with a rig that accelerates.** A rig holding a constant speed from frame one passes
  while a player reports the encounter as unplayable, because nobody can turn round in nought
  seconds. Reversing a walk into a run takes `(WALK + RUN) / ACCELERATION`. **Put every body in the
  encounter into the contract, including the cost of the player's own answer.**
- **A rig that runs on a timer runs into it.** The director sites what it owes in front of the
  direction she is *actually travelling*, so a `--flee` that starts before the pursuit is placed
  puts the pursuit in front of the run. It waits for the chase.

**When a rule is about what the player did, state it over the player.** A proxy that is equivalent
in the ideal case is not equivalent in a street, and every measurement you take of the proxy will
agree with you. `PURSUIT_SHAKEN_OFF` ends a chase when *she* has been opening the gap — stated over
the pursuer's geometry instead, a corner, a kerb, a body in the way or a 0.37s about-turn resets it
and the dog chases somebody who is plainly sprinting.

**A trigger at or past the break-off distance is a pursuit that loses interest the instant it
starts** — she is already standing where "it has lost her" means, so walking away works, and walking
away is the one answer that must never work. A break-off stated as a rate cannot reproduce it at any
trigger distance.

## A thing made of several bodies has to be made of several bodies

`EventDef.flock_size`, and three things about it are worth copying:

- **The excitement stays a pure query, one level down.** The world sums `contribution_at()` over
  instances; a flock sums over its birds. That is what makes the middle of a flock cost five times
  the rim, which is a *route* decision where one disc could only ever be a price.
- **The birds are held inside `flock_spread`, and `flock_spread` comes out of `outer_radius`.** A
  bird emits over `outer_radius - flock_spread`, so the union of eleven moving fields is inside the
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

**No spatial hash.** The budget tops out near 25 concurrent events; a linear scan is free.
