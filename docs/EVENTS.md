# Nappy — Events

An **event** is anything in the world that pushes the excitement meter. Events are data
(`EventDef` resources) plus an optional behaviour script.

## Where events are defined

Defs are constructed in code, in `src/events/event_catalogue.gd`, not saved as `.tres`
resources. They are reviewable in a diff, they can be validated on load, and the fairness
contract can be asserted over the whole catalogue in a test. Nothing here needs an editor
to tune, and a catalogue that lives in one file is easier to balance than forty resources.

## EventDef fields

| Field | Meaning |
| --- | --- |
| `id` | Unique string key |
| `display_name` | For the day summary / codex |
| `kind` | `RECURRING`, `ONE_SHOT`, `SCRIPTED`, `AMBIENT` |
| `first_day` | Earliest day it can appear (1-based) |
| `last_day` | Latest day it can appear (`0` = never expires) |
| `weight` | Relative likelihood when the scheduler picks recurring events |
| `max_per_day` | Cap on simultaneous instances |
| `placement` | Which tile types it may spawn on |
| `intensity` | Peak excitement per second at the centre |
| `inner_radius` / `outer_radius` | Falloff geometry (px) |
| `duration` | Seconds active (`0` = whole day) |
| `telegraph_time` | Seconds of visible warning before full intensity |
| `pulse_period` | Seconds per intensity cycle (`0` = constant) |
| `mobile` / `speed` | Whether it moves along a path, and how fast |
| `still_while_telegraphing` | Holds position until the telegraph is over, then goes. Default off, which is right when the telegraph *is* the approach; on when it is a posture — see the cat, below |
| `spawn_mode` | `MAP` (sited when the day is planned) or `AHEAD_OF_PLAYER` (sited in front of her, while she walks) — see "Where an event happens" |
| `hard_fail` | Whether contact ends the day immediately |
| `look` | How the instance draws itself |
| `act_tag` | Narrative act it belongs to, for palette/audio |

There is no `impulse` field. A "sharp spike" is just a short `duration` at high `intensity`
— which is exactly what a cat crossing the road *is* — and expressing it that way keeps the
entire excitement model a pure query with nothing pushing values at the baby.

### Kinds

- **`AMBIENT`** — permanently present, part of the map (playground, busy road).
- **`RECURRING`** — can be rolled on any eligible day, possibly many times in a run.
- **`ONE_SHOT`** — fires on exactly one day in the run, then never again (fire truck).
- **`SCRIPTED`** — the scheduler is told exactly which day it fires (story beats).

## Where an event happens *(M27)*

`kind` says *when* an event may happen. `spawn_mode` says **where**, and there are two answers.

**`MAP`, which is nearly everything.** The scheduler puts it on a tile when the day is planned,
and `EventManager` puts it in the world when the player comes within `EVENT_STREAM_RADIUS` of it
— of the nearest point of its *route*, for a mobile one, so a fire engine is in the world before
it sets off down the street she is on. It goes away again when she leaves, and once it has run
its course its plan is **spent**: walking back past it does not start it over.

An event that is somewhere is half of what makes a route a decision. It can be routed around,
and finding out it is there is what walking a street is for.

**`AHEAD_OF_PLAYER`, which today is the cat.** No tile. The day budgets it at the same cost as
everything else, and `EventDirector` sites it across her line, `AHEAD_LEAD_DISTANCE` in front of
her, while she is walking. Playtest 04: *"the cat is ineffective since it happens when it
spawns — the cat should get spawned in in front of the player while they walk."*

That is a real distinction and not a placement trick. A café spilling across a pavement is a
*place*. A cat bolting is not: you cannot plan around three seconds, and a cat that ran across
an empty road two blocks away was, for six milestones, an event the player had no way of ever
meeting. It only exists as an interruption, so it is authored as one.

Three rules on it, in the order they matter:

1. **The clock runs on walking, not on wall time.** A player who stops in a park to let the
   meter recover is not owed a cat for waiting, and must not come back to the pavement and be
   handed four of them.
2. **The lead is a reaction window stated as a distance.** `AHEAD_LEAD_DISTANCE` is two seconds
   at `WALK_SPEED`, and the run starts a street's width off to one side — so she is outside its
   outer radius for the whole time it is telegraphing. That is the telegraph fairness contract
   holding for an event that arrives without warning, which is the only way one is allowed to.
3. **It may not obstruct.** An `AHEAD_OF_PLAYER` event has no tile, so
   `_ensure_the_city_is_still_walkable` never sees it and nothing checks that what it blocks
   leaves a route to a park. `EventDef.validate()` refuses one that does. Emitting is fine, and
   so is being lethal — it is in front of her and gone in three seconds, so it can never seal a
   street.

## Scheduling

```
EventScheduler.build_day(day_index, run_seed):
    rng = RNG(hash(run_seed, day_index))
    1. add all AMBIENT events for the current act
    2. add SCRIPTED events whose day == day_index
    3. roll ONE_SHOT events not yet consumed this run, gated by first_day/last_day
    4. fill remaining budget with RECURRING events by weight
    5. apply park spoiling rules  (docs/CITY.md)
    6. validate: a path from home to at least one usable calm zone must exist
```

The **event budget** grows with the day index: `budget = 17 + floor(day_index × 1.9)`.
Each event costs budget equal to its `intensity` tier, so late days are not just "more cats".

The budget is **not** the count, and the gap is about a third: `_ensure_one_usable_park` strips
whatever reaches the calmest block and `_ensure_the_city_is_still_walkable` drops obstructions
that would seal the city. Measure what a day *places*, over several seeds; deriving it from the
formula gets a number a third too small that looks right. Since M27 an `AHEAD_OF_PLAYER` event
costs the same budget and takes no tile, so a day's `plan` line reads as *n sited, m ahead*.

## Catalogue

### Act I — Normal life (days 1–3)

All implemented.

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `playground` | AMBIENT | 1 | Static aura in every park. The reason parks are not free wins. Sized (150px outer against a 256px park block) to dominate the middle and leave the far side genuinely calm. |
| `cat_dash` | RECURRING | 1 | Crouches (telegraph), then bolts across the traffic. High intensity, tiny radius, 1.4s duration. The tutorial obstacle. |
| `dog_walker` | RECURRING | 1 | Mobile along the sidewalk at 32px/s — slower than walking, so the ordinary band rule applies. Barks on a 3.5s pulse. **Re-pitched in M19** from intensity 7 to 26 with a tighter radius: it used to cost −0.1 points to walk straight through, so the correct play was to plough into it. It now owns the pavement it is on, which is what finding 3 asked for. Deliberately given no `obstructs_radius` — a moving wall on a two-tile pavement pins the player against a building. |
| `cafe_tables` | RECURRING | 1 | **M19.** A café spilling out of its frontage, `obstructs_radius` 24px. The first thing in the game that is physically in the way on **day one**, and the answer to *"there should be things that force me to cross the street"*. Pleasant, which is worse: nothing about it looks like a hazard and it still costs the street. Stationary, so it can never pin anybody. |
| `homeless_yeller` | RECURRING | 1 | Stationary, large radius, 5s yell **pulse**. The counterplay is timing a pass between yells, which is a different skill from routing around a hazard. |
| `delivery_van` | RECURRING | 1 | Parked, reversing beeper. Constant, medium. The plain obstacle route planning is practised on. |
| `busker` | RECURRING | 2 | Park and square spoiler. Nothing about it is threatening; it is simply interesting, which is the whole problem. |
| `construction` | RECURRING | 2 | The only Act I event that is physically in the way (`obstructs_radius` 34px). Blocking a 64px sidewalk forces a reroute rather than inviting one — and since a street is sidewalk\|road\|sidewalk, the road is always still there, so it costs time and exposure, never the day. |
| `fire_truck` | ONE_SHOT | 3 | Drives an arterial at 190px/s with a 340px radius and a 4s telegraph (the fast-mover rule — see docs/MECHANICS.md). `spawns_on_finish` leaves a `burning_building` where it stops. |
| `burning_building` | — | — | Never scheduled: a SCRIPTED def with no day, so only the fire engine can put one in the world. Burns for the rest of the day. |

### Act II — Something is off (days 4–7)

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `police_patrol` | RECURRING | 4 | Mobile, unhurried, along a corridor. Not dangerous yet — the danger is that you start planning around it. |
| `poster_crew` | RECURRING | 4 | Static, weak. Cosmetic dread; it is here so the walls change. |
| `loudspeaker` | SCRIPTED | 5 | **City-wide**: no falloff, no edge, nowhere in the city it does not reach. The first event the player cannot walk away from. Pitched under the walking decay, so like a back street it does not raise the meter — it stops you clearing it. |
| `curfew_announce` | SCRIPTED | 6 | City-wide, brief, and fading (`intensity_ramp` 0.2). The mechanical bite is in `Tuning.day_length`, which shortens every day from 6 onward; this is the moment you are told. |
| `checkpoint` | RECURRING | 7 | Loud, and **physically closes a street** (`obstructs_radius` 60). The first event that takes a route away rather than making it expensive. |

### Act III — Disappearances (days 8–11)

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `abduction` | RECURRING | 8 | An unmarked van idles first — that idling *is* the telegraph, and it runs 4.6s because the inner radius is a `hard_fail`. Getting close does not excite the baby; it takes you. |
| `alley_robbery` | RECURRING | 8 | Alleys only, and deliberately tiny (22/42px) so the fairness rule is satisfied by half a second. That is as close to "no warning" as the contract allows, and it is honest: **the alley is the warning**. You knew what an alley was when you turned into it. |
| `night_raid` | SCRIPTED | 10 | Enormous, static, pulsing, and it closes the block (`obstructs_radius` 44). |

### Act IV — Open conflict (days 12–14)

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `military_convoy` | RECURRING | 12 | Like the fire engine, but what it leaves behind is a `barricade`. |
| `barricade` | — | — | Never scheduled directly. Left where a convoy stopped, and — via `scar_id` — left there for the rest of the **run**. |
| `protest` | RECURRING | 12 | `intensity_ramp` 1.9 over 150s: a protest you could have walked past when you saw it is not one you can walk past two minutes later. |
| `firefight` | SCRIPTED | 13 | The worst thing in the catalogue. Extreme, `hard_fail`, 6.5s telegraph, and it shuts a junction. |
| `sabotage_run` | SCRIPTED | 14 | The good-ending finale route. *(M8/M9)* |

## Permanent marks

`scar_id` records an event's position in `GameState.scars`, and the scheduler places that
event again on every **later day of the run**. The burnt-out shell from the day-3 fire is
still on that corner on day 12, cordoned off and never repaired; barricades from Act IV
convoys accumulate. This is most of how the escalation is told — the city remembers, and
the route you memorised on day 2 stops existing.

## Keeping a late day walkable

From Act II several events physically close streets, and from Act IV a run accumulates
permanent barricades. Any combination that seals the home off from every park makes the day
unwinnable in a way the player cannot see coming, so after planning, obstructions are
dropped — widest first — until a route exists again. Hard-fail events count as walls for
this check: an abduction in progress is not something you walk through to reach the park
behind it.

## The emission model

An event never pushes a value at the baby. Each frame the baby asks the world for the total
stimulus at its position, and the world sums `contribution_at()` over the live instances:

```gdscript
func contribution_at(world_position: Vector2) -> float:
    return Tuning.falloff(global_position.distance_to(world_position),
            current_intensity(), def.inner_radius, def.outer_radius)
```

Because it is a pure query there is no ordering to get wrong, events compose by simple
addition, and an instance can be tested without a scene.

The lookup is a **linear scan**, not a spatial hash. The budget formula tops out around 22
concurrent events on the last day; 22 distance checks per physics frame is nothing, and a
hash would be more code with more ways to be subtly wrong. Revisit if an act ever wants
hundreds of sources at once.

## Telegraph contract

Every event must satisfy, at authoring time:

```
telegraph_time × WALK_SPEED >= outer_radius − inner_radius
```

i.e. *a player walking at normal pace, standing at the edge of the danger zone the instant
the event becomes visible, can get clear before it hurts.* `hard_fail` events get double
that margin. This is asserted in `Tuning.validate_event()`; a violation is a bug, not a
difficulty setting, and `tests/test_events.gd` checks the whole catalogue.

**`AMBIENT` events are exempt**, and have to be: they are permanent features of a fixed
map, so there is no moment at which they appear and nothing to warn about. The player
learns where the playgrounds are on day 1 and that knowledge holds for the whole run, which
is the point of a city that does not change.

## What an event actually costs

Measured against the M19 rates, integrating the real falloff along a straight line through
the centre of the field and subtracting the walking decay. The meter is 100, sleep freezes at
35, and the baby cries at 100. `tests/test_events.gd` computes the same integral, so the
numbers here and the assertion there cannot drift apart.

| Event | walk through | run through |
| --- | ---: | ---: |
| `burnt_shell` | −4.1 | +10.6 |
| `poster_crew` | −2.2 | +14.5 |
| `barricade` | −0.4 | +16.9 |
| `playground` | +0.3 | +21.6 |
| `delivery_van` | +1.9 | +22.5 |
| `busker` | +3.8 | +29.2 |
| `police_patrol` | +5.7 | +29.6 |
| `homeless_yeller` | +5.8 | +33.2 |
| `alley_robbery` * | +6.8 | +9.7 |
| `construction` | +8.1 | +33.0 |
| `cafe_tables` | +8.8 | +29.1 |
| `cat_dash` | +10.4 | +22.9 |
| `checkpoint` | +13.7 | +38.2 |
| `dog_walker` | +21.6 | +26.8 |
| `protest` | +25.0 | +56.5 |
| `burning_building` | +29.8 | +53.5 |
| `abduction` * | +32.9 | +53.7 |
| `military_convoy` | +49.2 | +69.8 |
| `night_raid` | +56.6 | +78.2 |
| `fire_truck` | +64.6 | +83.9 |
| `firefight` * | +92.8 | +105.1 |

`*` is a `hard_fail`: the figure is notional, because nobody finishes the walk. Two rows the
playtest-02 version of this table was missing entirely (`burnt_shell`, `alley_robbery`) are
included now — the old one listed eighteen of what was then twenty.

**Three of these are negative, and all three are deliberate.** `poster_crew` is cosmetic
dread, `barricade` is a scar and `burnt_shell` is a reminder; none of them is an obstacle, so
none of them has to cost anything. Everything else must be more expensive to walk through than
to walk around, and `tests/test_events.gd` asserts exactly that with those three named as the
exemptions — so a **fourth** negative event has to be a decision somebody takes on purpose
rather than a number nobody checked.

What the table said before M19, and what changed:

- **Act I and act II had no teeth.** Eleven of eighteen cost under fifteen points, and
  `dog_walker` was −0.1 — walking through it beat walking around it. The whole escalation was
  back-loaded into acts III and IV, so the days that teach the player taught them that events
  are safe. `dog_walker` is +21.6 now, `cafe_tables` blocks a pavement from day 1, and the
  street itself costs something whatever is on it (see MECHANICS.md, "The street has
  physics"). The rest of act II is still gentle and is still open.
- **Running is never correct.** Unchanged, and still true of every row. It costs
  `EXCITEMENT_FROM_RUNNING` *and* collapses the decay from 3.5/s to 0.5/s, and together those
  beat the shorter exposure every time. Making running necessary (finding 9, M25) is
  therefore a mechanic to build, not a number to tune: it needs something running escapes.

The table is only about *events*, and since M19 it is no longer the whole cost of a street.
A contact with a pedestrian is ~15.6 points and a car's horn ~8, and neither is in the
catalogue. See MECHANICS.md.

Regenerate this table whenever the rates in `Tuning` move; it is the fastest way to see what
a balance change did to the catalogue as a whole.

## Showing the danger

### Audio is never the only channel

**Every cue that will eventually be audio must also exist visually, and the visual must be
sufficient on its own.** Audio reinforces; it never carries. A player with the sound off, or
who cannot hear it, must be able to play the game exactly as well.

This is not an accessibility afterthought bolted onto a sound design — it is the order the
work happens in. The visual channel is built first and judged on its own; audio is added
afterwards as redundancy. Any event whose telegraph only works "because you hear it coming"
is an unfinished event.

The rule has teeth because of the fairness contract: a telegraph the player cannot perceive
is not a telegraph, and `Tuning.validate_event()` cannot tell the difference.

### The visual vocabulary

**This is being replaced. See M22 in [PLAYTEST-02.md](PLAYTEST-02.md).** The rings below are
what ships today; playtest 02's finding 8 rejects them, and the reason is worth keeping
rather than merely acting on:

> A ring communicates a falloff radius, which is a number. A silhouette communicates a
> threat. How dangerous a thing is should be visible from looking at *the thing*.

The second half of the same finding is that the rings do not even cover the field they are
drawn for: the ~530 crowd agents have none, because the crowd is an emergent noise floor
rather than a set of authored dangers, and two `city_wide` sources have none because a field
with no edge cannot be a ring. So on a normal street most of what you can see is unmarked, a
few things are ringed, and nothing explains the difference.

| Cue | Means | Status |
| --- | --- | --- |
| **Ring + fill** | The danger geometry: outer radius, inner radius | ships today, **removed in M22** |
| **Flashing amber ring** | Telegraphing — visible, not yet at full strength | ships today, **removed in M22** |
| **Red ring** | Active; darker red for `hard_fail` | ships today, **removed in M22** |
| **Breathing** | Fill and ring track *current* emission, so a pulsing event visibly swells and fades and can be timed | ships today — **M22 must keep this somehow** |
| **Legible entity** | The thing itself reads as dangerous: posture, size, what it is doing | **M22** |
| **Symbol over the entity** | Flashing, and only when the entity cannot carry the warning alone | **M22** |
| **Edge indicator** | A symbol at the screen edge for anything closing from off-screen. Says *what* is coming, not merely that something is | **M22** |
| **Exclamation over the player** | Flashing: *you are standing in a soon-to-be danger zone, move.* A telegraph whose radius already covers you, the path of something fast still off-screen, the road with a car coming through | **ships for traffic (M19)**; events in M22 |
| **"Too close" over the player** | Danger already live and already on you — the cue that lets the others be quieter | **M22** |
| **Sound lines** | Concentric arcs thrown off a source on the rising edge of a pulse — the visual form of a discrete noise (a yell, a bark, a beep, a siren whoop) | todo |
| **HUD band** | For a `city_wide` source, which has no position and therefore nothing to stand under | todo |

The one thing the ring does well and a discrete symbol cannot is **breathing** — it tracks
current emission, so a pulsing event can be timed and slipped past between beats. Whatever
M22 puts in its place has to keep some form of that, or the pulse envelope stops being
something to play against and becomes random.

**M19 built the exclamation mark early, and on purpose.** It is the load-bearing cue of the
vocabulary — every other one says *a thing exists*, that one says *the contract is now about
you and the clock has started* — and M19 is what creates the danger it warns about: a lethal
car has no telegraph phase to ring, and a ring drawn round a car doing 185px/s would be off
the edge of the screen for most of the warning anyway. It flashes over the player whenever
she is standing on the carriageway with a car closing (`Stroller._draw_alert`). M22 inherits
it and generalises it to events; nothing about it is provisional.

Each live event's field is currently drawn on an aura layer between the ground and the
y-sorted entities — so a field never paints over a roof, and a building genuinely hides the
field behind it. Whatever replaces it inherits that constraint.

### Where the visual channel is currently incomplete

Two real gaps, both of which would today be papered over by audio if audio existed:

- **`city_wide` sources have no visual at all.** `EventAuraLayer` explicitly skips them —
  correctly, since a field with no edge cannot be drawn as a ring — and nothing else picked
  up the job. So from day 5 the loudspeaker masts hold a floor under the meter with *nothing
  on screen to say so*, and the player just sees excitement refusing to drain. This is the
  most misleading thing in the game right now. Needs the HUD band.
- **Fast movers approaching from off-screen.** `fire_truck` (190px/s, 340px radius) and
  `military_convoy` are both designed around a long telegraph that you spend getting off
  that street — but the ring is only useful once it is on screen, and at 190px/s that is
  most of the warning gone. Needs the edge indicator.

Everything else already has a sufficient visual: the cat's crouch before it bolts, the
abduction van idling, the pulse breathing on the yeller and the protest.

## Keeping a day winnable

Two rules run after a day is planned:

- **At least one park is left unspoiled.** Whichever park has the fewest events reaching it
  has them removed. Ambient events do not count as spoiling — a playground makes a park
  *contested*, which is the design, and stripping one out every day would be absurd.
- **A park stays reachable on foot.** See "Keeping a late day walkable" below.

## Pulsing events

`homeless_yeller` and `protest` use an intensity envelope rather than a constant:

```
intensity(t) = base × (0.25 + 0.75 × pulse(t))
```

with a visible/audible tell on the rising edge. This rewards the player for *waiting and
watching* rather than just avoiding — a different skill from pure pathing.

## Adding a new event

1. Create `src/events/defs/<id>.tres` (an `EventDef`).
2. If it needs behaviour, add `src/events/behaviours/<id>.gd` extending `EventBehaviour`.
3. Register it in `src/events/event_catalogue.gd`.
4. Run the project — `Tuning.validate_event()` will reject unfair geometry on load.
