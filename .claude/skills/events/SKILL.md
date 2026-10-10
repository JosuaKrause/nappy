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

A director-sited (`AHEAD_OF_PLAYER`/`TOWARD_PLAYER`) event is **not** an exemption. A crossing
has no telegraph she can see coming from down the street, so its contract is paid in geometry: the
director sites it a row-specific lead ahead of her. `EventDef.validate()` refuses a `TOWARD_PLAYER`
field that would reach her from where it is created, and any director-sited row that obstructs,
because nothing checks a route around a thing with no tile.

**For a row warned of before it exists, "becomes visible" is its badge**, and the contract holds
`EventDef.warning_time()` — the badge to the earliest it can reach her — against
`minimum_telegraph()`, which for such a non-pursuer is the flat `Tuning.OFFSCREEN_WARNING_MIN` (a
second, the player's time to react), never a figure worked out from its field or speed — the fire
engine and day 13's column included, whose place follows her so a walk out of their
field is not one she can take during the badge. A pursuer warned first is held to
`validate_pursuit` like every pursuer: its telegraph is the approach she watches once it exists.
A sent robber or guard instead arrives chasing, with no approach: its notice is its badge alone.
Running while it is offscreen counts toward `PURSUIT_SHAKEN_OFF`, so it can be shaken off before
it becomes visible ([tall-owl](../../../docs/playtests/2026-10-07-tall-owl.md)).
`EventDef.validate()` requires that badge and validates its chase without inventing an approach.
Standing robbers and the day-3 dog's approach keep their separate notice floor. Verify escape
with the actual Baby meter: reaching the pursuit cap after the baby cries is a lost day.

## What telegraphs

**A thing telegraphs its coming only if it goes fast, comes toward her, and carries a heavy penalty
— it can end the day or hit her hard.** *(PLAYTEST-145, statements 18-23; inbox #598: "the
telegraphing rule was about heavy penalty not *only* lethal" · "fire truck has heavy penalty".)* A
thing that does not telegraph its coming is **outside** the screen-edge badge and warning-first
placement: `EventDef.telegraphs` is false. Its in-world telegraph still satisfies the fairness
contract, including the waiting flock and mouse. Only the loose dog, met with its telegraph already
spent, has no in-world telegraph to validate. A heavy hit is a quarter of the meter or more in one
pass. By that, `loose_dog` (created at once just off screen down her sidewalk), `cat_dash`,
`alley_mouse`, `pigeon_flock` and `police_patrol` do not telegraph; the cyclist, the fire engine,
the column and the planned convoy, and every pursuer do. A row that stands still has no coming to
telegraph and keeps its in-world telegraph inside the contract. `docs/EVENTS.md`, "What telegraphs",
has each row's numbers. Do not turn a row's telegraphing off to make a contract pass: whether it
telegraphs is the rule's question, not the contract's.

## Everything from off screen is warned first, for at most a second, and is placed just out of sight

*(PLAYTEST-145: "the warning appears by itself with a reasonable position and when the time is
right the object is spawned in at that location just offscreen"; calm-kestrel, inbox #559: "never
longer than 2s ... place the object immediately off screen so it will immediately start coming on
the screen turning off the warning ... they jump around wildly"; busy-quail, inbox #569: "1s warning
should be enough".)* A row that arrives from off screen under the screen-edge badge — `cyclist`,
`charging_dog` sent down her heading, the fire engine, the resistance's own
`robber_giving_chase` and `van_guard_giving_chase`, day 13's column, each a row
`warns_before_it_exists()` answers true for (flagged `warned_first` on its row, or made so by
`EventManager.as_warned()`, which every warning goes through) — is a `PendingWarning` first
(`EventManager.warn_first()`): nothing in the world, the badge up at once for the row's own
`EventDef.warned_for()`, **at most `Tuning.WARNING_ALONE_MAX`** (`validate()` refuses longer), its
place fixed against her so the badge moves only with her walking and never jumps. Then the thing is
created **just off screen** where its ground has a place for it from where she is by then
(`PendingWarning.just_out_of_sight()`: everything it can draw, `EventInstance.footprint_of()`,
wholly outside the camera's whole view, corners included, never nearer than
`PendingWarning.least_distance()`) — **no pop-in** *(amendment 6 of M226: "I don't want any pop
in")*, and `tests/test_no_pop_in.gd` holds it — a sidewalk for the bike, walkable ground down her
heading for the day-3 dog, the road on its way to the fire for the engine, its lane for the column,
the director's own rules for the trap. A non-pursuer is created with its telegraph spent
(`EventManager.spawn_warned()`); **a pursuer with its telegraph still to run**, since its telegraph
is its approach — except one that `arrives_chasing` (the resistance's sent robber and guard: "the
proximity rule is only for standing robbers"). Where its ground has no place when the second is up,
the warning is withdrawn; a withdrawn day-3 dog is owed again.

**The warning time is the row's own number.** *(PLAYTEST-145: "I don't like that the warning is
tied to the size of the field or the speed.")* Nothing about where a thing is created may be
derived from its telegraph, and a row's telegraph is not shortened by shrinking its field.

**The day-3 dog keeps its gold timing, in the player's terms**: the warning is badge to visible
(its half second), the chase is lunge to catch (0.35s, 0.60s and 2.05s walking into it, standing and
walking away). `tests/test_events_pursuit.gd` fails if either moves. **No pursuer gives up on a
walker** *(amendment 8: "pursuers should never (or a long time) stop pursuing if she walks")*: every
chase lasts `Tuning.PURSUIT_TIME`, a long cap (30s), so walking away loses by construction; running
ends it at `PURSUIT_SHAKEN_OFF`'s rate.

**Not warned first: a patrol sent down the road and a `MAP` mover** (`military_convoy`). The patrol
does not telegraph its coming at all (slower than a walk, never ends the day); the planned convoy
telegraphs in the world (4.43s, with a badge because 120px/s is faster than a walk) as a place the
day planned, not something sent at her. **Do not add a row to this list, and do not cite it as the
reason something else is not warned first.** What stands in the way of it is `docs/EVENTS.md`,
"Everything arrives from off screen".

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
  the gap and dies on the first lethal frame. It closes to its stand-off (`Tuning.pursuit_standoff()`)
  and lunges the moment she reaches it, so the chase starts at the stand-off however she came. A
  wall between them that holds the lunge back is the same trap: at an alley mouth the line clears
  with her already inside the stand-off. The notice, the lunge and the catch all ask for a clear
  line, so a held lunge is not deferred until the line clears: the pursuer holds the door guard's
  ground (`EventInstance._lunge_held`) and lunges once she is back at the full stand-off.
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

## A partially animated scene has separate pixel owners

When only part of an event picture moves, the stationary scene stays in retained static layers and
the moving pixels live in separately registered layers. The owner's picture key stays stable when
only those details swap. Static art may overlap a moving crop where it supplies the background a
phase uncovers or foreground occlusion that belongs above it; the rule forbids duplicate moving
pixels, not overlap between the layers' rectangles or opaque pixels. Preserve source painter order,
orientation, halo and badge sources, collision and the authored clock. Compare every composited
phase with the complete source rather than treating a difference mask or a crop rectangle as proof
of correct separation.

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

**Nothing reaches her through a building, and a new source has to ask.** `EventInstance.
contribution_at()` and `CrowdAgent.contribution_at()` zero a positive field when
`CityMap.wall_between()` finds the line from the source to her a tile deep in a building, or at
the middle of a wall only one tile thick;
anything else that ever emits goes through the same question. The trap is the caret's projection:
it translates *her* point rather than moving the source, which is right for the field and wrong for
the wall — a wall stays where it is, so the projection asks it between the two bodies' own
projected places.

A contact **startles the person she walked into** — the jolt is a decaying source on that agent's
own `contribution_at()`. Anything that wants to "add excitement" should find a body to put it on
rather than a third summand; if there genuinely is no body, that is a design conversation, not a
plumbing one.

**No `impulse` field.** A sharp spike is a short `duration` at high `intensity`.

**Events are defined in code, not `.tres`** — reviewable in a diff, validated on load, assertable as
a whole catalogue in a test.

**No spatial hash.** The concurrent count stays a few dozen even on the last day; a linear scan is
free.
