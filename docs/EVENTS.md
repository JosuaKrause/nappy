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

The **event budget** grows with the day index: `budget = 69 + floor(day_index × 6.2)`.
Each event costs budget equal to its `intensity` tier, so late days are not just "more cats".

The budget is **not** the count: `_ensure_one_usable_park` strips whatever reaches the calmest
block and `_ensure_the_city_is_still_walkable` drops obstructions that would seal the city.
Measure what a day *places*, over several seeds; deriving it from the formula gets a number that
is too small and looks right. Since M27 an `AHEAD_OF_PLAYER` event costs the same budget and
takes no tile, so a day's `plan` line reads as *n sited, m ahead*.

### Danger, and when it arrives *(M31)*

Playtest 05, finding 5: *"day two doesn't feel more difficult than day one. Having day one
relatively easy is okay **if** the difficulty increases. But right now there is never **any**
danger."* True by construction — every `hard_fail` event started on day 8 or later, so for half
a run the only lethal thing in the game was a car the player is never obliged to step in front
of. M28 made the street busy and M29 made it legible; neither made it dangerous, and those are
different axes: **expensive** is the meter moving, **dangerous** is something that can take the
day away that you can see coming and act on.

| | day 1 | day 2 | day 3 | day 8 | day 14 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Events placed | 48 | 49 | 52 | 69 | 88 |
| Of them lethal | **0** | **3** | **4** | 11 | 11 |

**The escalation is a change of kind, not of count.** Day 2 places about one more event than day
1 and no player could feel that; day 2 is *the day the streets acquire something that can take
the day off you*, and that is legible immediately. `tests/test_events.gd` asserts exactly this
pair — day 1 has nothing lethal on it, day 2 does — so a rebalance cannot quietly flatten it.

**A patrol was the obvious answer and it was rejected**, by the player, in those terms:
*"patrol shouldn't be there for act I."* Act I is a nice neighbourhood and a police patrol on
day 2 tells act II's story three days early. So the danger is the neighbourhood's own — a kid on
a bike and a lorry reversing across a pavement, which are what somebody pushing a pram is
actually frightened of. The two teach opposite lessons on purpose: the cyclist comes *at* you
and the answer is to get off the pavement; the lorry is static and the danger is *behind* it.

M25 — patrols, and running that matters — is unaffected and still queued. It is the answer for
acts III and IV, where the streets are deliberately empty and the threat should follow.

### The density, and why it is caps before budget *(M28)*

Playtest 05, finding 6, stated it as a number: **one event per block**. The city is 7×7 blocks,
so day 1 places **49** rather than the 13 it used to. Measured over five seeds:

| | before M28 | after |
| --- | --- | --- |
| Placed on day 1 (non-ambient) | 13 | **50** — 1.03 per block |
| Placed on day 14 | 25 | **97** |
| Live inside `EVENT_STREAM_RADIUS` | 1.8 | **10.9** |
| On screen at once, walking | ~1 | **3.3** (6.9 on day 14) |
| Met on a short errand and back | 1.0 | **2.0**, of which 0.8 dog walkers |
| Café tables seen on that errand | ~0.2 | **3.2** |

**The budget was never the binding constraint, and raising it alone does nothing.** The day-1
pool's `max_per_day` values summed to 18, so a budget of 100 placed the same 13 events — which
is what `CLAUDE.md`'s *"a budget the catalogue cannot spend is not density"* is about. The caps
moved first, several times over, and the budget followed. Repeats are explicitly fine
(*"it's fine if the same event happens multiple times"*), so **no new catalogue rows were
needed**: three dog walkers became twenty, three cafés eighteen.

Two things the caps were quietly doing that had to be replaced when they moved:

- **Separation.** `_place_one` picks a uniformly random tile, so the cap of three was the only
  reason two dog walkers never landed on the same pavement. It is a rule of its own now:
  `EVENT_SPACING_SAME` (256px, a block) between two of a kind, `EVENT_SPACING_ANY` (64px) between
  any two at all. The first bends on a full map, the second never does.
- **Keeping a lethal field uncluttered.** See the telegraph contract below.

The one cap that did *not* rise is `cat_dash`. A cat is sited by the director while she walks and
`AHEAD_INTERVAL` spreads them over the day, so a seventh has nowhere to happen.

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

**M31 added seven more**, five of them on day 1. Playtest 05 asked for two things in the same
breath — *"there is never any danger"* and *"try to come up with more variety, we need more
events/entities in general"* — and ruled out the obvious answer: *"patrol shouldn't be there for
act I."* Act I is a nice neighbourhood, so its danger is a neighbourhood's own.

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `loose_dog` | RECURRING | 1 | *The player's idea: "a dog where the owner drops the leash and it starts running."* The counterpart to `dog_walker` and the reason both exist — that one is a **span** you decide whether to cross the street to avoid, this one is a **thing coming at you** that you cannot out-walk. 132px/s, so it earns a badge at the screen edge and pays the whole-radius telegraph. Not lethal: act I gets exactly two of those and this is not one. |
| `market_stall` | RECURRING | 1 | The second thing on day 1 that forces a crossing. `cafe_tables` has been the only one since M19 and M28 made it common, but one obstacle repeated eighteen times is a rule rather than a decision. Wider, louder, and on the other side of pleasant: a café you squeeze past is a nuisance, a market is a crowd. |
| `leaf_blower` | RECURRING | 1 | The loudest thing in act I, and it is a man tidying a park. Allowed on `PARK` on purpose — a calm block with a leaf blower in it is calm ground she cannot use, which is what M24 wants more of. Swept in bursts, so there is a rhythm to time a pass through. |
| `pigeon_flock` | RECURRING (`AHEAD_OF_PLAYER`) | 1 | The second thing that happens *to* her, and the reason to have one is that the director had a single trick: every moment was a cat. Three seconds of noise and gone. |
| `cyclist` **`hard_fail`** | RECURRING | 2 | **The first thing in the game that can end your day.** A kid on a bike on the pavement, bell going. Everything about it is ordinary, which is the point — the answer to *"there is never any danger"* is not that act I becomes sinister, it is that act I becomes a real street. The bell rings for 3.3s, which is what the doubled margin costs at 165px/s. |
| `ice_cream_van` | RECURRING | 2 | The `busker` argument one size up: nothing about it is threatening, it is simply interesting. The widest ordinary radius in act I. |
| `reversing_lorry` **`hard_fail`** | RECURRING | 3 | Act I's second lethal thing, teaching the opposite lesson to the cyclist. That one comes *at* you and the answer is to get off the pavement; this one is **stationary and the danger is behind it**, so the answer is not to walk into the gap it is backing into — which you have to look at the world to know. The beeper is the telegraph. |

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

The lookup is a **linear scan**, not a spatial hash. Since M28 a late day has around 26 events
instantiated at once — the whole day is four times that, but only what is inside
`EVENT_STREAM_RADIUS` exists as a node — and 26 distance checks per physics frame is nothing,
while a hash would be more code with more ways to be subtly wrong. Revisit if an act ever wants
hundreds of live sources at once; the streaming radius is what decides that, not the budget.

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

### The contract is per event, and the player experiences the sum *(M28)*

`validate_event()` checks each row in isolation. At one event per block the outer radii routinely
overlap — `cafe_tables` alone is 170px against a 448px block period — so **walking out of one
field can mean walking into another**, and nothing in the catalogue can see that. Playtest 05
named this as the way the density breaks quietly, and it is worth being exact about which half
of it is a problem:

- For the fifteen rows that only cost points, it is **not** a violation. She got clear of the
  thing she was told to get clear of; the next field costs her the meter, which is exactly what
  a dense street is supposed to do. This is the density working.
- For the three rows that **end the day** it is a real breach, because the escape she was
  offered would have walked her into a death she never had a telegraph for.

So the rule the scheduler enforces at placement is: **nothing else happens inside a lethal
event's field.** A `hard_fail` event keeps its whole `outer_radius` clear of every other event,
and it is the one spacing rule with no fallback — an abduction that cannot find room is simply
not placed. `tests/test_events.gd` asserts it across a whole run.

## What an event actually costs

Measured against the **playtest 07** rates, integrating the real falloff along a straight line
through the centre of the field and subtracting the walking decay. Every row moved that
milestone, because what changed was the *shape* of `Tuning.falloff` rather than any one event:
`(1−t)²` became `1−t²`, so a field now holds three quarters of its intensity at the midpoint of
its band instead of a quarter. Nothing is louder at its centre and nothing reaches further; what
changed is that the middle distances cost something, which is finding 18 — *"the excitement should
go substantially up from relatively far away. I shouldn't have to get actual contact to get
penalized."* The meter is 100, sleep freezes at
35, and the baby cries at 100. `tests/test_events.gd` computes the same integral, so the
numbers here and the assertion there cannot drift apart.

| Event | walk through | run through |
| --- | ---: | ---: |
| `loudspeaker` | −5.5 | +27.3 |
| `burnt_shell` | −3.0 | +16.5 |
| `poster_crew` | +0.7 | +22.6 |
| `barricade` | +3.0 | +26.0 |
| `curfew_announce` | +3.4 | +32.2 |
| `playground` | +5.8 | +33.6 |
| `delivery_van` | +8.3 | +34.9 |
| `alley_robbery` * | +9.1 | +13.5 |
| `busker` | +13.3 | +45.7 |
| `police_patrol` | +15.9 | +46.2 |
| `homeless_yeller` | +17.7 | +52.2 |
| `cafe_tables` | +20.1 | +45.4 |
| `cat_dash` | +20.2 | +35.4 |
| `construction` | +20.3 | +51.6 |
| `pigeon_flock` | +22.9 | +34.8 |
| `market_stall` | +27.9 | +52.7 |
| `checkpoint` | +29.0 | +59.4 |
| `cyclist` * | +30.2 | +45.9 |
| `ice_cream_van` | +31.5 | +65.8 |
| `reversing_lorry` * | +32.6 | +53.3 |
| `dog_walker` | +36.5 | +41.2 |
| `loose_dog` | +43.3 | +52.0 |
| `leaf_blower` | +48.6 | +67.1 |
| `protest` | +50.0 | +88.1 |
| `burning_building` | +55.9 | +83.2 |
| `abduction` * | +61.3 | +84.1 |
| `military_convoy` | +84.9 | +107.2 |
| `night_raid` | +101.8 | +122.6 |
| `fire_truck` | +115.4 | +132.0 |
| `firefight` * | +155.9 | +162.3 |

`*` is a `hard_fail`: the figure is notional, because nobody finishes the walk. Two rows the
playtest-02 version of this table was missing entirely (`burnt_shell`, `alley_robbery`) are
included now — the old one listed eighteen of what was then twenty.

**One of these is negative, and it is deliberate.** `burnt_shell` is a reminder rather than an
obstacle, so it does not have to cost anything. (`loudspeaker` is `city_wide` and has no line to
walk through at all, so its figure is meaningless.) It was three rows until playtest 07 —
`poster_crew` and `barricade` are now marginally positive, which costs their design nothing: both
are still very nearly free to walk through, which is all "scenery" ever asked for. Everything else must be more expensive to walk through than
to walk around, and `tests/test_events.gd` asserts exactly that with those three named as the
exemptions — so a **fourth** negative event has to be a decision somebody takes on purpose
rather than a number nobody checked.

**And what a *street* costs, measured after M31.** A rig walked home to the furthest calm block
and back — 7,500px, a real errand — through a real day with the crowd and the events both
running. Peak excitement **25 to 57** of a hundred across three seeds, and the meter frozen for
0–14% of it. Nobody cried. The same day, holding one arrow key east from the doorstep for
fifteen seconds, loses: the trace names four pedestrian contacts and a car's horn, and the
breakdown at the moment of each is `crowd 30–44/s` against `events 10–14/s`.

**So the crowd is still most of what a street costs, and the events are what make it a
decision.** That ratio is the design working: careless is fatal in seconds and careful is nearly
free, and the gap between them is where the game lives. It is also a warning about this table —
none of the numbers above are in it.

**What the table stopped being able to answer, in M28.** Every row prices *walking through one
event against walking around it*, and that was the player's actual question while a street
carried one event every four blocks. At one per block, going around one is often going through
the next, so the table now measures a move the player rarely has in front of her. It is still
the right way to price a **row** — it is how `dog_walker` was caught costing −0.1 points, and
the test that keeps every row above zero is written over it — but it is no longer a description
of what a street costs. The two numbers that are: **3.3 events on screen at once** on day 1, and
a contact with a pedestrian at ~15.6 points and a car's horn at ~8, neither of which is in the
catalogue at all. A balance argument that reaches for this table alone is answering a much
narrower question than it thinks, and since M28 it is narrower again.

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

**The rings are gone.** M22 deleted them rather than restyling them, and the reason is worth
keeping rather than merely acting on — playtest 02's finding 8, restated by playtest 04:

> A ring communicates a falloff radius, which is a number. A silhouette communicates a threat.
> How dangerous a thing is should be visible from looking at *the thing*.

The second half of that finding is the one that decided the shape of what replaced them. The
rings did not even cover the field they were drawn for: the crowd agents had none, and two
`city_wide` sources had none because a field with no edge cannot be a ring. So on a normal
street a few things were ringed, most were not, and nothing explained the difference. **A cue
that marks everything says nothing**, and every rule below exists to keep the replacement from
becoming that.

| Cue | Means | Where |
| --- | --- | --- |
| **Legible entity** | The thing itself reads as what it is: a crouched cat, an idling van, a scaffold, a burnt shell. **This carries most of the load, and everything below is for what it cannot carry.** | the art |
| **Caret over the entity** | *Danger that changes over time*, and only that: it is about to start, it ends the day, or it comes and goes. Amber telegraphing, red active, doubled and darker for `hard_fail`. | `Sprites.draw_caret()`, from `EventInstance._draw_mark()` and `CrowdAgent._draw_horn_mark()` |
| **Breathing** | The caret's size and ride height track *current* emission, so a pulsing event visibly swells and settles and can be timed. | `EventInstance.mark_swell()` |
| **Edge badge** | Off-screen and closing **under its own steam**: a disc at the screen edge carrying the thing's own silhouette, a chevron pointing at it and the distance. Says *what* is coming, not that something is. | `DangerEdge` |
| **Exclamation over the player** | *This will end your day, and the clock has started.* A `hard_fail` event still telegraphing whose radius covers her, or a car closing on the lane she is standing in. Down the moment it stops being true. | `Stroller._draw_alert()` |
| **Doubled red over the player** | *It is bad now and you are in it.* Something lethal is live and she is inside its reach with one step left to make. | `Stroller._draw_alert()` |
| **zzz over the pram** | *The baby is asleep* — the return phase, and the state with the most consequence and the least presence on screen. Flashing instead of breathing: *she is stirring*, and waking costs half the sleepiness bar. | `Stroller._draw_baby_cue()` |
| **Waves over the pram** | *She is not settling* (amber, at the calm threshold, where the day stops progressing) and *she is nearly crying* (red, three of them, flashing). | `Stroller._draw_baby_cue()` |
| **HUD line** | For a `city_wide` source, which has no position and therefore nothing to stand under. | `hud.gd` |
| **Sound lines** | Concentric arcs thrown off a source on the rising edge of a pulse — the visual form of a discrete noise (a yell, a bark, a beep, a siren whoop) | todo, M10 |

**Nothing draws a field.** That is the rule, and it is a standing decision rather than a
preference. If something new needs signalling, reach for one of the rows above; if none of them
fits, that is a design conversation and not a licence to draw a radius.

Three rules underneath the table, in the order they matter:

1. **The caret is for danger that *changes*.** Lethal, telegraphing, pulsing or swelling —
   nothing else. A barricade, a boarded shopfront and a burnt-out shell are large, distinct and
   visibly what they are, and pointing at them adds noise and no information. A first pass used
   "louder than the walking decay" instead and marked all three, which is the ring's own
   mistake in a new shape. `tests/test_danger.gd` holds the line.
2. **Breathing had to survive.** It is the one thing the ring did that a discrete symbol does
   not get for free, and without it a pulsing event stops being something to time a pass
   through and becomes something that hurts at random.
3. **The exclamation mark is the load-bearing one.** Every other cue says *a thing exists*;
   that one says the fairness contract is now about you and the clock has started, which is the
   difference between information and instruction. It shipped early, in M19, because a lethal
   car has no telegraph phase to ring and a ring round a car doing 185px/s is off the edge of
   the screen for most of the warning. M22 only had to add its second level and let the events
   raise it too.
4. **And the mark means one thing: *this will end your day*.** *(M30, playtest 05 finding 3.)*
   M22 raised it for **any** telegraphing event whose radius reached her, and the player's
   verdict was *"it doesn't actually have an effect on gameplay — I can just keep doing what I
   was doing."* That reading was correct for fifteen of the eighteen rows: for anything that is
   not a `hard_fail`, the mark meant *a number is about to move faster*, and the meter already
   says that continuously and proportionally. It is rule 1 in a second shape — a cue that marks
   everything says nothing — arriving at the one cue that cannot afford it. Only a `hard_fail`
   event and a car closing on her raise it now.

   The cost is real and is the right cost: acts I and II contain nothing lethal, so the mark is
   nearly silent before day 8. That is not the cue being broken; it is the cue being honest
   about a game where nothing is dangerous yet, which is playtest 05's finding 5 and a
   different milestone.
5. **And a cue is a claim about a *moment*.** *(Playtest 06, findings 1 and 3.)* Rules 1 and 4
   are both about *which* things a cue is raised for, and both were kept — and the player's next
   two complaints were about **when**: *"I get the flashing exclamation marks after the fact"*
   and *"the offscreen indicators show events far away, and if you walk towards them they
   sometimes disappear"*. Membership was right in both cases and the timing was wrong, which no
   test in `tests/test_danger.gd` could see, because it asserts what is marked and not when.

   Two rules fall out, and they are the same rule at two ends:

   - **A cue is lowered when its condition stops being true, by the system that can see the
     condition.** The traffic's mark has a 1.4s hold that survives the gap between two cars in
     one lane, and nothing lowered it when she stepped over the kerb — where a car cannot reach
     her at all. `Stroller.stand_down()` lets the raiser take *its own* mark down without
     handing anybody a setter for everyone else's.
   - **Measure the thing, not the gap.** The badge tested how fast the *distance* was shrinking,
     which is her 92px/s plus its speed against a threshold of 20, so walking towards anything
     lethal announced it. It measures the event's own approach with the player held still now,
     caps the range as a *window* (announce what would reach her within `LEAD_TIME`), and holds
     a raised badge — plus a margin outside the screen edge, without which a thing on the
     boundary trades places with its own badge every frame. That last one is most of *"they
     flicker a lot"*.

**The traffic pays for its own warning now.** *(M30.)* The table's first row is *the entity
itself carries most of it*, and the traffic was the one place nothing did: the caret was drawn
by `EventInstance`, and a car is not an event. So a lethal thing bearing down on the player
produced a mark over **her** head and nothing anywhere else — the load-bearing cue paying for a
warning it should only have been adding to. The horn was supposed to carry it, and the horn is
silent in a game with no audio, which is *"audio is never the only channel"* failing in the one
place the traffic fairness contract depends on it. A car sounding its horn now carries the same
doubled lethal caret a `hard_fail` event does, breathing with the horn's own decay. The shape
lives in `Sprites.draw_caret()` so there is one chevron rather than two that slowly stop being
the same chevron.

### What the edge badge is for, and what it is not

`fire_truck` does 190px/s with a 340px radius and `military_convoy` is the same shape. Both are
*designed* around a long telegraph that the player spends getting off that street — and a ring
is only useful once it is on screen, which at that speed is most of the warning gone. The
fairness contract was being met by the geometry and missed by the player.

So it announces two things and no others: anything **lethal**, and anything **faster than a
walk**. Everything else she can turn round and leave, which is the same line
`required_telegraph_time()` draws when it decides whether the escape distance is the falloff
band or the whole radius. It also requires a silhouette to put in the badge — an arrow that can
only say "something" is an anxiety rather than a warning — and it caps at three at once,
because the day the edge of the screen becomes wallpaper is the day it stops being read.

Three things it does **not** announce, each for its own reason:

- **Anything that is not coming at her.** The speed it measures is the event's own approach with
  the player held still. A stationary abduction two streets away is a place, and finding out it
  is there is what walking a street is for; her own footsteps are not news.
- **Anything further off than its own arrival window.** The cap is `LEAD_TIME` seconds of its
  approach, not a distance — the same 800px is a fire engine four seconds away and a dawdler
  twenty seconds away, and only one of those is a route decision.
- **An `AHEAD_OF_PLAYER` event.** The director sites it across her line a fixed lead in front of
  her and its entire content is the moment it happens to her. Announcing it from the edge of the
  screen is M27's complaint from the other end — and in practice it was a badge that appeared
  and vanished within the same second as the cat walked into view.

Three at once is also chosen *by arrival* rather than by distance: what the cap is choosing
between is warnings, and the one worth keeping is the one that gets here first.

### The cue that is not about the world *(playtest 06, finding 5)*

Every cue above says something about the **world**. Nothing said anything about the **baby**,
who is the only thing the player is trying to change — and the two meters live in the corner of
a screen whose camera is on the pram. *"Can you add a visual for when the excitement bar is
almost full, and the same for when the sleep bar is fully full — like a zzz above the stroller."*

Four states, over the pram, and the two rules that keep it from becoming the rings again:

- **Stages, not a gauge.** A meter drawn over her head is the HUD moved, and a mark that is up
  whenever a number is moving is the thing rule 1 exists to stop. What earns a place is a small
  number of states, each a different instruction: *the day has stopped progressing* (excitement
  at the calm threshold, where sleepiness freezes), *the day is about to end*
  (`EXCITEMENT_NEARLY_CRYING`), *you are on the way home*, and *she is about to wake and it will
  cost you half the bar*.
- **It must not collide with the exclamation mark**, which means one thing and had a milestone
  spent on making it mean only that. Different motif — waves and a zzz, never a chevron or a
  bar — and a different anchor: the pram, stepped aside when the pram is on her own axis, since
  walking away from the viewer puts it exactly where the mark lives.

The colours are the vocabulary's own — amber for *about to be a problem*, red for *about to end
the day* — because a crying baby **is** a lost day. The escalation is more of the motif as well
as a colour change, the same rule `alert_close.svg` is drawn to.

### Where the visual channel is currently incomplete

- **Sound lines.** A discrete noise — a yell, a bark, a beep — currently reads only as the
  caret swelling. Concentric arcs thrown off on a pulse's rising edge would give it a "that
  just happened" beat. M10.
- **The entities themselves.** Row one of the table is doing most of the work and some of the
  art is not yet up to it: `homeless_yeller`, `busker` and `poster_crew` all draw the same
  `person.svg` as each other and as a crowd walker, so what tells them apart today is the
  caret over two of them. That is the vocabulary covering for the art, which is the wrong way
  round. Not urgent — the standing decision on assets is "something workable for now" — but it
  is the first thing to fix when the art gets a pass.
- **~~The traffic carries no entity-side cue.~~** *(Closed in M30: a car sounding its horn
  draws the doubled lethal caret.)* Worth keeping the shape of the gap, because it is the one
  that hid longest: the caret was a method **on `EventInstance`**, so "an entity carries its own
  cue" silently meant "an *event* entity carries its own cue", and the one lethal thing in the
  game that is not in the catalogue had nothing. A vocabulary written as one class's private
  method is a vocabulary with an invisible edge.

## Keeping a day winnable

Two rules run after a day is planned:

- **At least one park is left unspoiled.** Whichever park has the fewest events reaching it
  has them removed. Ambient events do not count as spoiling — a playground makes a park
  *contested*, which is the design, and stripping one out every day would be absurd.
  *(M24: where there is a choice, the park it protects is **not** the one she used yesterday.)*
- **A park stays reachable on foot.** See "Keeping a late day walkable" below.

### The city remembers where she went *(M24)*

Playtest 05, finding 4: *"I was able to go to the same park on day one and two — this shouldn't
be possible."* The complaint is not about repetition. It is that **the game's only verb stopped
being a decision on day two**: a player who finds a good park on day 1 has no question left to
answer, and answering that question is the whole game.

So the calm block the baby actually fell asleep in is remembered — by `GameState`, not by
reading the telemetry; see docs/TELEMETRY.md — and the next day plans one loud thing into it.
Measured over five seeds and a whole run, the chance that the quietest calm block today is the
same one as yesterday goes from **28% of days to zero**.

Three things keep it from being a punishment for playing well, and all three are load-bearing:

- **It spoils with an event, not by taking the ground away.** The park is still calm ground and
  still walkable; something loud is standing in it, visible from the street, and she decides.
  Nothing lethal, obstructing or mobile is ever chosen for this.
- **The usable-park rule is told to protect a different one**, or the two halves fight — the day
  puts one event in her park, and the rule, looking for the least disturbed calm ground, finds
  the block with exactly one spoiler on it and strips the very event that was the point.
- **It is one ordinary event from the same day's pool.** Day 2 is not day 1 plus a punishment,
  it is a day whose noise happens to be somewhere she was counting on.

Two exemptions, both the same one: if the city has only one calm block, or every other calm
block is already spoiled, a **winnable day outranks a fresh decision** and she gets her park
back.

This is playtest 03's finding 2 one scale up. That one found the calm area was a lap rather than
a route (M21); this one finds that *which* calm area was not a choice either.

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
