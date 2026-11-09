---
name: events
description: Rules for adding or changing an event in the catalogue — the fairness contracts every row must satisfy, what obstructs_radius and spawn_mode and role actually mean, and the drawing a row owes. Load this BEFORE touching src/events/event_catalogue.gd, EventDef, EventInstance, EventScheduler, or anything about telegraphs, pursuits, lethal radii or event placement.
---

# Events

**The rules not to miss:**

- **The telegraph fairness contract**: a player who starts walking away the instant an event
  becomes visible gets clear before it hurts. A violation is a bug, not a difficulty setting.
- **Nothing else happens inside a lethal event's field.** No fallback: no room, no placement.
- **A lethal radius its own solid body covers never fires.** `EventDef.validate()` refuses it.
- **Anything that stands still and is drawn is solid at half its silhouette**, never a balance value.
- **A new row owes a drawing of its own.** No two rows share a picture or a badge silhouette.
- **Whether a row telegraphs its coming is the rule's question**, never switched to pass a contract.
- **Nothing appears in her view and nothing vanishes while she is looking at it.**
- **Excitement is a pure query.** Nothing writes `Baby.excitement` from outside.
- **A guarantee about a day is decided in `EventScheduler.build_day()`**, never in the streaming.
- **A number that moves regenerates `docs/COSTS.md` in the same commit** (the **balance** skill).
- **Before changing where any event is placed**, read `docs/EVENTS.md`, "The three views and the
  placement order": the player's design, and where the code does not follow it yet.

The catalogue is data, validated on load. Almost everything a new row needs already exists as a
field; resist adding a script per event. `docs/EVENTS.md` is the design and owns the detail. This
file keeps what a coder must not miss, and the reference files beside it hold the traps of one
area each, to be read whole before the first edit there:

| Before touching | Read |
|---|---|
| `warned_first`, `PendingWarning`, `EventSpawner.as_warned()`, a thing sent from out of her sight | `references/warned-first.md` |
| `EventDef.vehicle`, `EventCarDriving`, the patrol car, the fire engine | `references/event-cars.md` |
| `EventDef.pursuit`, `EventDef.notice`, `PursuitSpec`, `EventPursuit`, a charger, robber or guard | `references/pursuits.md` |
| `EventDef.flock_size`, `EventFlock`, a look that moves, a partly animated picture | `references/flocks-and-moving-pictures.md` |
| a new row, `spawn_mode`, `on_her_way`, `hard_fail`, the role, `pavement_side` | `references/fields.md` |
| `EventScheduler.build_day()`, `EventStreaming`, `ExcitementSource`, anything that emits | `references/plan-and-excitement.md` |

## Adding a row

The steps are `docs/EVENTS.md`, "Adding a new event". The one that gets skipped is **a drawing**
(its step 5): a look, an SVG, its pictures and a badge silhouette of the row's own. There is no
generic to borrow, and `tests/test_events_catalogue.gd` fails if two rows share a picture or two
looks share a silhouette.

If it needs behaviour no field covers, add the field to `EventDef` and handle it in the behaviour
that owns that rule under `src/events/behaviours/`, or in a new `EventBehaviour` that
`EventBehaviours.compose()` adds for the rows whose data ask for it. **A behaviour that keeps
state saves and restores it** (`save()`, `restore()`), or a streamed-out event comes back with it
fresh and nothing says so.

## The fields that are decisions, and the ones that are not

`references/fields.md` says what each means and is read before a row is added or one of these
changes. In one line each:

- **`spawn_mode` is a decision**: `MAP` unless the whole content is the moment it happens to her
  (`AHEAD_OF_PLAYER`) or traffic on her line she answers with a route (`TOWARD_PLAYER`). Neither
  director-sited mode may obstruct.
- **`on_her_way` and `hard_fail` are decisions**; `hard_fail` decides where the thing goes as well
  as what it does.
- **The role is not a decision.** `EventScheduler.role_for()` reads it off the def, and a row that
  wants another role needs a change there, not a new field.
- **`obstructs_radius` is not a decision**, and `pavement_side` usually is not one either.
- **`flock_size` changes what a row *is***, and `departs_at` matters only for a stationary event
  with a `duration`.

## The telegraph fairness contract

**A player who starts walking away the instant an event becomes visible must get clear before it
hurts.** `EventDef.validate()` asserts it on load, through `Tuning.validate_event()`, for every row
at every heat, and `tests/test_events_catalogue.gd` checks the whole catalogue. A violation is a
bug, not a difficulty setting.

One documented exemption: `AMBIENT` events, which never "appear". Nothing is city-wide: every row
has a place and an edge to walk out of, the loudspeaker masts included.

A director-sited (`AHEAD_OF_PLAYER`/`TOWARD_PLAYER`) event is **not** an exemption. A crossing
has no telegraph she can see coming from down the street, so its contract is paid in geometry: the
director sites it a row-specific lead ahead of her. `EventDef.validate()` refuses a `TOWARD_PLAYER`
field that would reach her from where it is created, and any director-sited row that obstructs,
because nothing checks a route around a thing with no tile.

**For a row warned of before it exists, "becomes visible" is its badge**, and the contract is held
against a flat minimum, never a figure worked out from its field or speed
(`references/warned-first.md` has the whole of it).

## What telegraphs, and what is warned first

**A thing telegraphs its coming only if it goes fast, comes toward her, and carries a heavy penalty
— it can end the day or hit her hard** (PLAYTEST-145 18-23; olive-hedgehog #598). A thing that does
not is **outside** the screen-edge badge and warning-first placement (`EventDef.telegraphs` is
false), and its in-world telegraph still satisfies the fairness contract. `docs/EVENTS.md`, "What
telegraphs", has the rule row by row with each row's numbers. **Do not turn a row's telegraphing
off to make a contract pass**: whether it telegraphs is the rule's question, not the contract's.

**A row that arrives from off screen under the badge is warned first, for at most
`Tuning.WARNING_ALONE_MAX`, and is then created just out of sight** (PLAYTEST-145 2; busy-quail
#569; calm-kestrel #559), with **no pop-in** (olive-hedgehog #598), which `tests/test_no_pop_in.gd`
holds. **The warning time is the row's own number** (PLAYTEST-145 1): nothing about where a thing is
created is derived from its telegraph. **No pursuer gives up on a walker** (olive-hedgehog #598).
The design is `docs/EVENTS.md`, "Everything arrives from off screen"; the contract such a row is
held to, what is created with its telegraph spent, and the two things that are not warned first are
`references/warned-first.md`.

## The contract is per event and the player experiences the sum

**Nothing else happens inside a lethal event's field.** A `hard_fail` event keeps its whole
`outer_radius` clear of every other event at placement (`StreetInvalidation.room_around()`), and it
is the one spacing rule with no fallback — one that cannot find room is not placed. A new lethal row
inherits this, not just the telegraph. `tests/test_events_costs.gd` holds it across a run.

Two exemptions, both about a field with no fixed place to keep clear: a **wall** placement, which
is off the day's routes by construction, and a **pursuer**, which follows her.
`EventScheduler.Planned.keeps_its_field_clear()` names both. The reasoning is `docs/EVENTS.md`, "The
contract is per event, and the player experiences the sum".

## A lethal radius and a solid body are the same mechanism

The player is stopped with her centre `obstructs_radius + PLAYER_BODY_RADIUS` from the centre of a
thing, so a `hard_fail` event whose body reaches its own inner radius **can never fire at all** —
which is not an unfair event, it is an event that has quietly been switched off, and that is worse.
`EventDef.validate()` refuses the arrangement on load.

## Anything that stands still is solid at the width it is drawn

`obstructs_radius` is **half the silhouette** and not a balance value — `SpreadLook._draw_spread()`
draws a blocking object at exactly the width it obstructs for the same reason in the other
direction.

Four exemptions, each written down in `docs/EVENTS.md`, "Solid things are solid": anything
**mobile** (a moving wall pins her) but a car that drives, anything **director-sited**
(`validate()` refuses it), anything with no silhouette, and a **flock** (`validate()` refuses that
too — several bodies wheeling inside one disc have no silhouette to be half of, and being walked into
is the event). `tests/test_events_solid.gd` requires everything else to have one.

**A body is a route cost, not a closure.** `EventScheduler.OBSTRUCTION_A_PARK_CAN_HOLD` is the
`obstructs_radius` a spoiler may carry and still count as something a park can hold — a body you can
walk around does not close a park; one you have to route around does. **If a rule tests
`obstructs_radius > 0`, ask whether it means *has a body* or *closes ground*.**

**A car that drives is the one body that moves** (`EventDef.vehicle`: the patrol car and the fire
engine). It never moves into her, its `obstructs_radius` stays zero, and its lethality is a strike
area ahead of its nose, only while it drives its route, only with her on the carriageway, under the
crowd car's contract of the carriageway and the horn instead of a telegraph. It gives way where the
crowd's cars do. `references/event-cars.md` owns that rule and the seven traps.

## A fixture can move, and `EventDef.paces` is how

A **beat** rather than a journey: it walks its route, turns round at the ends, and neither departs
nor expires. A stationary source is a line the player draws once; a man pacing a stretch of
sidewalk is a timing problem on top of a routing one.

The price is the body: anything mobile is exempt from the solidity rule, so making something pace
**takes its `obstructs_radius` away**, and what has to replace it is intensity.

## Nothing vanishes while you are looking at it

An event that is over **leaves** (`EventInstance._be_done()`): it emits nothing, cannot end the day,
carries no cue, and moves until it is past `Tuning.OUT_OF_SIGHT` before it is deleted. **It is over
the moment it starts leaving.** What never leaves, the one thing that leaves and is not deleted (the
guard who set off from a barrier), and how streaming treats a departure are `docs/EVENTS.md`, "Going
away". Three things a coder must not miss:

- **A departure she can see is held to the sight rule** (`EventDeparture._must_clear_sight`), not
  to the backstop clock, which is for a departure with no player to be out of sight of.
- **A plan streamed out while its guard is spent or leaving must carry that**
  (`EventBarrierPost.save()`), or the barrier comes back armed.
- **Streaming is a way out too.** `EventManager.stream_around()` keeps any live instance within
  `Tuning.OUT_OF_SIGHT` of her in the world however far its route is, or a car she follows out of
  its street is deleted in front of her; a leaving plan it does stream out is spent.

## Pursuits, flocks and moving pictures

**A fairness contract about a moving encounter is stated over distance and checked by walking**,
never by asserting the numbers it was written from. A pursuer closes to its stand-off
(`PursuitSpec.standoff()`) and lunges from there; a charger that waits for her charges on a clock,
never on a distance; **no row but the checkpoint guard may start `CHARGES_AT_ONCE` without the
player's word** (inbox #764 in minty-lemur, inbox #788 in minty-lemur). The traps are
`references/pursuits.md`.

A thing made of several bodies is `EventDef.flock_size`; a moving thing bobs by distance covered;
a partly animated scene keeps its still pixels and its moving pixels in separate layers. All three
are `references/flocks-and-moving-pictures.md`.

## The day is planned whole, and excitement is a pure query

**Do not move a guarantee out of `EventScheduler.build_day()` and into the streaming.** Every
guarantee is stated over a day and is a property of the plan; what streams is the instantiation,
and a spent plan stays spent while a running one resumes. **Do not add a code path that writes to
`Baby.excitement` from outside**: `Baby` asks the world for its sources and sums them, and anything
that emits is an `ExcitementSource`, which asks whether a wall stands between it and her. The
reasons and the traps (the stream radius against the widest field, what a stream-out carries, the
caret's projection and the wall) are `references/plan-and-excitement.md`.

## Things deliberately not done

**No `impulse` field.** A sharp spike is a short `duration` at high `intensity`.

**Events are defined in code, not `.tres`** — reviewable in a diff, validated on load, assertable as
a whole catalogue in a test.

**No spatial hash.** The concurrent count stays a few dozen even on the last day; a linear scan is
free.
