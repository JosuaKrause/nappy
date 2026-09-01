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
| `departs_at` | How fast it removes itself when it is over (px/s). **Nothing vanishes while you are looking at it** — see "Going away". Anything `mobile` leaves at its own `speed` and needs no value here |
| `pursues` / `pursue_speed` | Comes after **her** rather than along a path, at a speed strictly between a walk and a run. The one thing running is the answer to — see `Tuning.validate_pursuit` |
| `pursues_within` | How close she has to come before it takes an interest. `0` is *immediately*, which is a pursuer that is a **moment**; anything else is a pursuer that is a **place** until she walks up to it, and its telegraph and chase are both measured from when it notices |
| `paces` | Walks its route and turns round at the ends, for ever. The difference between a journey and a **beat** — see `homeless_yeller` |
| `obstructs_radius` | Radius of solid body (px). **A thing that stands still is solid at the width it is drawn** — see "Solid things are solid" |
| `pavement_side` | Which lane of a two-tile pavement it wants: `ANY`, `AT_THE_KERB`, `AGAINST_THE_BUILDING` |
| `hard_fail` | Whether contact ends the day immediately |
| `look` | Which picture it draws. **One per row, and no two rows share one** — see "The visual vocabulary", point 6 |
| `act_tag` | Narrative act it belongs to, for palette/audio |

There is no `impulse` field. A "sharp spike" is just a short `duration` at high `intensity`
— which is exactly what a cat crossing the road *is* — and expressing it that way keeps the
entire excitement model a pure query with nothing pushing values at the baby.

### Kinds

- **`AMBIENT`** — permanently present, part of the map (playground, busy road).
- **`RECURRING`** — can be rolled on any eligible day, possibly many times in a run.
- **`ONE_SHOT`** — fires on exactly one day in the run, then never again (fire truck).
- **`SCRIPTED`** — the scheduler is told exactly which day it fires (story beats).

## Where an event happens

`kind` says *when* an event may happen. `spawn_mode` says **where**, and there are two answers.

**`MAP`, which is nearly everything.** The scheduler puts it on a tile when the day is planned,
and `EventManager` puts it in the world when the player comes within `EVENT_STREAM_RADIUS` of it
— of the nearest point of its *route*, for a mobile one, so a fire engine is in the world before
it sets off down the street she is on. It goes away again when she leaves, and once it has run
its course its plan is **spent**: walking back past it does not start it over.

An event that is somewhere is half of what makes a route a decision. It can be routed around,
and finding out it is there is what walking a street is for.

**`AHEAD_OF_PLAYER`, which is the cat, the flock and the charging dog.** No tile. The day budgets it
at the same cost as everything else, and `EventDirector` sites it across her line,
`AHEAD_LEAD_DISTANCE` in front of her, while she is walking.

That is a real distinction and not a placement trick. A café spilling across a pavement is a
*place*. A cat bolting is not: you cannot plan around three seconds, and a cat sited on a tile at
dawn is a cat that bolts across an empty road two blocks away — an event the player has no way of
ever meeting. It only exists as an interruption, so it is authored as one.

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

## Solid things are solid

`obstructs_radius` is not a field to reach for when a particular event wants to block a pavement.
It is derived, by one line:

> **Anything that stands still is solid at the width it is drawn.**

The width it is drawn is the whole of it — the number is half the silhouette, not a balance
value. `EventInstance._draw_spread` draws a blocking object at exactly its `obstructs_radius` for
the same reason in the other direction: a body that disagrees with the picture is a lie about where
she can walk, whichever way it lies.

**Three exemptions, each for its own reason.**

- **Anything mobile.** A moving wall on a two-tile pavement pins her against a building, which is
  a different game from being priced out of a street.
- **`AHEAD_OF_PLAYER`**, refused outright by `validate()` — see rule 3 above.
- **Anything with no silhouette**: a city-wide announcement, a playground the park itself draws.

**And one constraint that is not an exemption: a lethal radius and a solid body are the same
mechanism.** She is stopped with her centre `obstructs_radius + PLAYER_BODY_RADIUS` from the
centre of the thing, so on a `hard_fail` event a body that reaches the inner radius means the
kill can *never fire*, however carelessly she walks into it — a difficulty setting nobody chose,
arriving silently, in the one place the game cannot afford one. `EventDef.validate()` refuses that
arrangement on load. It is why `alley_robbery`'s inner radius is 30 rather than the 22 a man's own
width would suggest: a man is 11px wide and she is 14, so at 22 the pram is held three pixels
*outside* the radius that takes the baby.

### Which lane of the pavement

A corridor is sidewalk | road | sidewalk, so a pavement tile has a kerb on one side and a frontage
on the other, and `CityMap.pavement_inward()` says which. `pavement_side` is how a row that only
makes sense against one of them asks for it.

- **`AT_THE_KERB`** — `delivery_van` and `ice_cream_van`. On a `ROAD` tile a parked van stands in a
  traffic lane that the crowd knows nothing about and drives straight through, blocking a route
  nobody walks. At the kerb it is on the pavement she is actually using and it takes it: a
  `VEHICLE_BODY` is 22px of radius, so 44px of van across a 64px footway means the answer is the
  other side of the street.
- **`AGAINST_THE_BUILDING`** — `reversing_lorry`. The whole event is that the danger is **behind** a
  wall of metal, which needs a wall. The placement also turns it to face out of that wall, so the
  box end is buried in the frontage and the cab is on the pavement. It asks for a frontage **east
  or west** of it, because the silhouettes that back into things are drawn side-on and a sprite
  cannot face north — half the pavements in the city are still eligible.

## Going away

An event that ends where it stands blinks out in front of her, which for the shortest-lived rows in
the game is where they always are. The rule:

> **Nothing vanishes while you are looking at it.**

An event that is over enters a **leaving** phase: it stops emitting, it cannot end the day, it
carries no cue, and it moves until it is more than `Tuning.OUT_OF_SIGHT` from the player — 420px,
which is the far corner of a 640x360 view with the camera's look-ahead on top of it. Then it is
deleted, out of shot, where a deletion is what it looks like from the inside and nothing at all
from the outside.

Three things worth keeping straight:

- **It is over the moment it starts leaving.** A cat that trailed its field behind it for the two
  seconds it took to reach the kerb would be a worse bug than vanishing.
- **Anything `mobile` leaves at its own `speed` and needs no data.** The cat runs on the way it was
  going; the dog walker carries on down the street. `departs_at` is for the rest — a flock, which
  has to fly, and a pursuer that has lost interest and trots off.
- **Two things never leave**, and both would break something that reads the finishing position: an
  event with a `spawns_on_finish` stops **where the thing it leaves belongs** (a fire engine's fire
  is at the building, not two streets past it), and anything with no departure speed is simply
  over, which is right for a café that closes.

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

The **event budget** is stated *per block of lattice* and grows with the day index:
`blocks × (BUDGET_PER_BLOCK + day_index × BUDGET_PER_BLOCK_PER_DAY)`, both constants on
`EventScheduler`. Each event costs budget equal to its `intensity` tier, so late days are not just
"more cats".

The budget is **not** the count: `_ensure_one_usable_park` strips whatever reaches the calmest
block and `_ensure_the_city_is_still_walkable` drops obstructions that would seal the city.
Measure what a day *places*, over several seeds; deriving it from the formula gets a number that
is too small and looks right. An `AHEAD_OF_PLAYER` event costs the same budget and takes no tile,
so a day's `plan` line reads as *n sited, m ahead*.

### Where in the city, and why

A placement is a roll over every tile of the right type, weighted by whether the tile is in a
precinct and by what the day is placing the thing **for** — its **role**, in the vocabulary
`docs/CITY.md` fixes — against the day's **corridor**, which is the ways from the doorstep to the
calm areas still worth reaching.

`EventScheduler._role_for` answers it off the def and nothing else has to be written per row:

| kind of row | role | where it may go |
| --- | --- | --- |
| lethal (`hard_fail`) | **wall** | never inside the corridor; `EVENT_WALL_RIM_WEIGHT` toward a turning off it |
| everything else placed on a tile | **friction** | `EVENT_CORRIDOR_WEIGHT` toward the corridor |
| a `ONE_SHOT` | **set piece** | one placement at *each* site of a covering set; one of them happens |
| `AMBIENT`, `AHEAD_OF_PLAYER`, a scar, a park spoiler | **none** | wherever its own rule says |

Two things about the mechanism rather than the table. It is **the same weighting the precinct
uses** — a tile is offered to the roll several times over — so every spacing rule downstream keeps
working unchanged and nothing can refuse a placement. And **exactly one of these is a rule rather
than a weight**: a wall is never inside the corridor. That one can be absolute because the rest of
the city stays available to it, so it cannot starve a row of ground; everything else is a weight for
exactly the reason it could.

Measured on 2026-08-31 over six seeds, per day, with both weights flattened to 1 and then at 4.
Flattened is the honest control: it leaves the *rule* in place and takes only the *preference*
away, so what the arrows show is what the weighting buys.

| | day 1 | day 5 | day 9 | day 14 |
| --- | --- | --- | --- | --- |
| placed | 111 → 111 | 145 → 145 | 175 → 175 | 201 → 201 |
| costly rows on the corridor | 34% → **64%** | 39% → **63%** | 33% → **53%** | 31% → **52%** |
| lethal rows on the rim | — | 63% → **80%** | 40% → **64%** | 31% → **59%** |
| lethal rows placed | — | 8.8 → 9.0 | 16.7 → 16.7 | 17.0 → 17.0 |

Three things in it. **The density did not move**, which it must not: the role changes *where* the
budget is spent and never how much of it there is. **Neither did the lethal count**, which is the
one the rule could have broken — refusing a quarter of the city to the rows that are hardest to
place (a `hard_fail` event must clear its whole outer radius of everything else, with no fallback)
could have quietly stopped placing them, and it did not. And **the share drifts down with the
day** because the corridor fills up and `EVENT_SPACING_SAME` pushes the overflow outward, which is
the spacing rule doing its job rather than the weight failing.

### A set piece is offered on every route and happens on one

The fire engine is the only one-shot in the catalogue. Placed like everything else — a legal spot
somewhere on the map, on a day she may never walk that way — an authored set piece that fires once
per run is a fairness contract and a silhouette spent on nothing.

So the day plans it **at every site of a covering set** — `RouteTree.covering_sites`, the smallest
set of streets such that every route touches one — and the placements share a `set_piece_group`.
The first one to enter the world spends the rest, in `EventManager._stream_in`, which is also
where a scar is recorded: a run gets exactly one fire however many streets were offered.

Three things this gets right that choosing a site on her route would not:

- **Nothing has to predict her.** The guarantee is structural and holds whichever way she goes.
- **A bundle is not a guarantee.** Two distinct routes to one area share no street by
  construction, so no single site can ever cover both. The covering set is two to six streets, and
  code that expects one is looking for a *tile she must cross*, which the city is built not to
  have.
- **The moment of choosing is the moment of walking there.** `_stream_in` is where an event becomes
  real — where its scar is recorded and its block moves along its arc — so the alternatives stop
  being possible on the same frame rather than when it finishes.

**An offer takes up no room, and that is not a convenience.** Spacing the rest of the day around
all two-to-six offers would reserve ground for events that will not exist — and it breaks *"a
retried day is the same day"* outright, because the day after the set piece fires then has several
long routes' worth of ground freed rather than one. Measured on seed 4242 with offers spaced
against: `leaf_blower` seven to five and eight kinds moving between two attempts at the same day.
Because an offer costs nothing, the fill is **identical** between attempts.

Two exceptions, both load-bearing. **Siblings space against each other**, because two offers on top
of one another would be a real overlap on whichever one fires. And **nothing lethal may be planned
into an offer**: if it does resolve there, she meets a lethal field and a fire engine at once,
which is exactly the sum the telegraph contract refuses.

The three counts this splits apart are worth keeping straight, because two tests depend on it.
`max_per_day` is a cap on **instances**, and the number of offers is not one — so a one-shot is
exempt from it in `tests/test_events.gd` and the real count is asserted in
`tests/test_event_manager.gd`, where an instance exists. And a **retried day plans none** of a
spent one-shot rather than one fewer, because the whole group goes with it.

### Danger, and when it arrives

**Expensive** and **dangerous** are different axes: expensive is the meter moving, dangerous is
something that can take the day away that you can see coming and act on. A run whose every
`hard_fail` row started on day 8 would be half a run in which the only lethal thing in the game is a
car the player is never obliged to step in front of.

**The escalation is a change of kind, not of count.** Day 2 places about one more event than day
1, which no player could feel; what day 2 is, is *the day the streets acquire something that can
take the day off you*, and that is legible immediately. `tests/test_events.gd` asserts exactly this
pair — day 1 has nothing lethal on it, day 2 does — so a rebalance cannot quietly flatten it.

**A patrol is not act I's answer, and that is a standing decision.** Act I is a nice neighbourhood
and a police patrol on day 2 tells act II's story three days early. So act I's danger is the
neighbourhood's own — a kid on a bike and a lorry reversing across a pavement, which are what
somebody pushing a pram is actually frightened of. The two teach opposite lessons on purpose: the
cyclist comes *at* you and the answer is to get off the pavement; the lorry is static and the danger
is *behind* it.

Patrols belong to acts III and IV, where the streets are deliberately empty and the threat should
follow rather than sit; that is queued in `docs/TODO.md`.

### The density, and why it is caps before budget

The target is **one event per block**, which is why `EventScheduler.budget_for()` is stated *per
block* and not as a flat number. A flat budget is a statement about one lattice size: grow the city
and the same events spread thinner, which is the density quietly falling while every constant still
reads as correct.

**The budget is not the binding constraint on an early day, and raising it alone does nothing.**
The day's pool can only place what its `max_per_day` values add up to, so a budget above that sum
buys nothing — which is what the **balance** skill's *"a budget the catalogue cannot spend is not
density"* is about. **The caps come first and the budget follows.** Repeats are fine — the same
event several times over is what a street is — so density needs no new catalogue rows: the common
act I rows are capped in the teens and twenties.

Two things a low cap does quietly, both of which have to belong to somebody once the caps rise:

- **Separation.** `_place_one` picks a uniformly random tile, so a cap of three is the only reason
  two dog walkers never land on the same pavement — which is a coincidence rather than a rule. It
  is a rule of its own: `EVENT_SPACING_SAME` (256px, a block) between two of a kind,
  `EVENT_SPACING_ANY` (64px) between any two at all. The first bends on a full map, the second
  never does.
- **Keeping a lethal field uncluttered.** See the telegraph contract below.

The one cap deliberately kept low is `cat_dash`. A cat is sited by the director while she walks and
`AHEAD_INTERVAL` spreads them over the day, so past a certain count there is nowhere left for one
to happen and the budget would be spent on cats the day cannot fit.

## Catalogue

### Act I — Normal life (days 1–3)

All implemented.

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `playground` | AMBIENT | 1 | Static aura in every park. The reason parks are not free wins. Sized (150px outer against a 256px park block) to dominate the middle and leave the far side genuinely calm. |
| `cat_dash` | RECURRING | 1 | Crouches (telegraph), then bolts across the traffic. High intensity, tiny radius, 1.8s duration — long enough to carry it the whole way across the street it starts at the edge of. The tutorial obstacle. |
| `dog_walker` | RECURRING | 1 | Mobile along the sidewalk at 32px/s — slower than walking, so the ordinary band rule applies. Intensity 26 on a tight radius, barking on a 3.5s pulse: it owns the pavement it is on, so walking straight through it is never the cheap option. Deliberately given no `obstructs_radius` — a moving wall on a two-tile pavement pins the player against a building. |
| `cafe_tables` | RECURRING | 1 | A café spilling out of its frontage, `obstructs_radius` 24px. The first thing in the game that is physically in the way on **day one**, and the thing that forces a crossing. Pleasant, which is worse: nothing about it looks like a hazard and it still costs the street. Stationary, so it can never pin anybody. The people at the tables are drawn as well as the tables, because the tables are what obstructs and the conversation is what it emits. |
| `homeless_yeller` | RECURRING | 1 | Intensity 14 over a 210px field, yelling on a 5s **pulse**, and **pacing** eight tiles of pavement (`EventDef.paces`). A fixed source on a fixed patch is a line you draw once; a man walking up and down it is a timing problem on top of a routing one. Mobile, so he has no body. His silhouette is his own — a long coat, a raised arm, a beard, one shape where a passer-by is two. |
| `delivery_van` | RECURRING | 1 | Parked at the kerb, hazards going. Constant, medium. The plain obstacle route planning is practised on. At the kerb rather than on the carriageway, and solid at `VEHICLE_BODY`: 44px of van across a 64px footway is a street that costs the other side. |
| `busker` | RECURRING | 2 | Park and square spoiler. Nothing about it is threatening; it is simply interesting, which is the whole problem. Solid at 11px, which is a man to walk around and not a park closed — see `OBSTRUCTION_A_PARK_CAN_HOLD`. |
| `construction` | RECURRING | 2 | The widest body in act I (`obstructs_radius` 34px), and the one that leaves no gap: 68px across a 64px sidewalk forces a reroute rather than inviting one — and since a street is sidewalk\|road\|sidewalk, the road is always still there, so it costs time and exposure, never the day. |
| `fire_truck` | ONE_SHOT | 3 | Drives an arterial at 190px/s with a 340px radius and a 4s telegraph (the fast-mover rule — see docs/MECHANICS.md). `spawns_on_finish` leaves a `burning_building` where it stops. |
| `burning_building` | — | — | Never scheduled: a SCRIPTED def with no day, so only the fire engine can put one in the world. Burns for the rest of the day, and you cannot walk through the fire. |

**And the rest of act I**, which is where its variety and its danger come from — a
neighbourhood's own rather than a patrol's.

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `loose_dog` | RECURRING | 1 | A dog whose owner has dropped the leash. The counterpart to `dog_walker` and the reason both exist — that one is a **span** you decide whether to cross the street to avoid, this one is a **thing coming at you** that you cannot out-walk. 132px/s, so it earns a badge at the screen edge and pays the whole-radius telegraph. Not lethal, which is what separates it from `charging_dog`: this one is answered by getting out of the way. |
| `market_stall` | RECURRING | 1 | The second thing on day 1 that forces a crossing, and it exists because one obstacle repeated eighteen times is a rule rather than a decision. Wider, louder, and on the other side of pleasant than `cafe_tables`: a café you squeeze past is a nuisance, a market is a crowd. |
| `leaf_blower` | RECURRING | 1 | The loudest thing in act I, and it is a man tidying a park. Allowed on `PARK` on purpose — a calm block with a leaf blower in it is calm ground she cannot use. Swept in bursts, so there is a rhythm to time a pass through. |
| `pigeon_flock` | RECURRING (`AHEAD_OF_PLAYER`) | 1 | The second thing that happens *to* her, and the reason to have one is that a director with a single trick makes every moment a cat. It is on the pavement for its whole telegraph, then up, then *away* — and it is **eleven birds**, each with its own heading, height and wingbeat, and each an emitter, so the middle of a flock stacks four or five fields and the rim stacks one. The only row in the game that is more than one source. |
| `cyclist` **`hard_fail`** | RECURRING | 2 | **The first thing in the game that can end your day.** A kid on a bike on the pavement, bell going. Everything about it is ordinary, which is the point: act I does not become sinister, it becomes a real street. The bell rings for 3.3s, which is what the doubled margin costs at 165px/s. |
| `ice_cream_van` | RECURRING | 2 | The `busker` argument one size up: nothing about it is threatening, it is simply interesting. The widest ordinary radius in act I. At the kerb, and solid at 24px: a thing children cross a road to reach rather than a thing standing in one. |
| `reversing_lorry` **`hard_fail`** | RECURRING | 3 | Act I's second lethal thing, teaching the opposite lesson to the cyclist. That one comes *at* you and the answer is to get off the pavement; this one is **stationary and the danger is behind it**, so the answer is not to walk into the gap it is backing into — which you have to look at the world to know. The beeper is the telegraph. It stands `AGAINST_THE_BUILDING`, turned to face out of the frontage, solid at 28px inside the 46 that ends the day. |
| `charging_dog` **`hard_fail`** | RECURRING (`AHEAD_OF_PLAYER`) | `RUN_TAUGHT_DAY` | **The one thing running is the answer to**, and the day the run is taught. It is sited in front of her, spends `telegraph_time` 2.4s visibly closing at the stand-off, then chases at 130px/s for `Tuning.PURSUIT_TIME`. Its 150px field is **wider than the stand-off** — a narrower one is a field the pursuer is never inside, so the warning would emit nothing at her and the `!` over her head would never go up; `validate_pursuit` refuses that. `max_per_day` 3, because a street with three of them turns the run button from an answer into a second walk speed. It trots off at 110px/s rather than blinking out: a dog that gives up in front of her and is then not there says the chase was never real. |

### Act II — Something is off (days 4–7)

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `police_patrol` | RECURRING | 4 | Mobile, unhurried, along a corridor. Not dangerous yet — the danger is that you start planning around it. |
| `poster_crew` | RECURRING | 4 | Static, weak, and solid at 11px. Cosmetic dread; it is here so the walls change. |
| `loudspeaker` | SCRIPTED | 5 | **City-wide**: no falloff, no edge, nowhere in the city it does not reach. The first event the player cannot walk away from. Pitched under the walking decay, so like a back street it does not raise the meter — it stops you clearing it. |
| `curfew_announce` | SCRIPTED | 6 | City-wide, brief, and fading (`intensity_ramp` 0.2). The mechanical bite is in `Tuning.day_length`, which shortens every day from 6 onward; this is the moment you are told. |
| `checkpoint` | RECURRING | 7 | Loud, and **physically closes a street** (`obstructs_radius` 60). The first event that takes a route away rather than making it expensive. |

### Act III — Disappearances (days 8–11)

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `abduction` | RECURRING | 8 | An unmarked van idles first — that idling *is* the telegraph, and it runs 4.6s because the inner radius is a `hard_fail`. Getting close does not excite the baby; it takes you. Solid at 22px, comfortably inside the 54 that takes her, so the metal is metal and touching it is still fatal. |
| `alley_robbery` **`hard_fail`** | RECURRING | 8 | **A man who is worth crossing the road for, and who comes after you if you do not.** Three numbers for three sentences: intensity 16 over a **200px** field, so the far end of an alley is already expensive and the meter is the only warning a robbery will ever give; `hard_fail` inside 30px; and `pursues_within` 140, inside which he takes 1.8s of visibly coming and then chases at 130px/s. The alley is the warning and it is not the only one — a lethal thing that does nothing at all until it does everything is a thing with no telegraph. |
| `night_raid` | SCRIPTED | 10 | Enormous, static, pulsing, and it closes the block (`obstructs_radius` 44). |

### Act IV — Open conflict (days 12–14)

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `military_convoy` | RECURRING | 12 | Like the fire engine, but what it leaves behind is a `barricade`. |
| `barricade` | — | — | Never scheduled directly. Left where a convoy stopped, and — via `scar_id` — left there for the rest of the **run**. |
| `protest` | RECURRING | 12 | `intensity_ramp` 1.9 over 150s: a protest you could have walked past when you saw it is not one you can walk past two minutes later. **Solid at 55px**, and `_draw_protest` draws two ranks across exactly that width — the clearest case in the catalogue of the picture deciding a gameplay number, because a body may not claim ground the drawing does not. Under its own 70px inner radius on purpose — the loudest part of a protest is something you stand in rather than bump into. |
| `firefight` | SCRIPTED | 13 | The worst thing in the catalogue. Extreme, `hard_fail`, 6.5s telegraph, and it shuts a junction. Solid at the width of its cover. Its picture is **people** doing this, not a street on fire — that is a burning building's picture, and the two rows are not the same event. |

The day-14 sabotage is not a catalogue row: it is `GameState` logic (`sabotage_done`,
`sabotage_available()`), gated on the resistance goal rather than sited or scheduled like an
`EventDef`. `docs/NARRATIVE.md` and `docs/DESIGN.md` describe what completing it does.

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

The lookup is a **linear scan**, not a spatial hash. A late day has around 26 events
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

### The contract is per event, and the player experiences the sum

`validate_event()` checks each row in isolation. At one event per block the outer radii routinely
overlap — `cafe_tables` alone is 170px against a 448px block period — so **walking out of one
field can mean walking into another**, and nothing in the catalogue can see that. This is how the
density breaks quietly, and which half of it is a problem is worth being exact about:

- For a row that only costs points, it is **not** a violation. She got clear of the thing she was
  told to get clear of; the next field costs her the meter, which is exactly what a dense street is
  supposed to do. This is the density working.
- For a row that **ends the day** it is a real breach, because the escape she was offered would
  have walked her into a death she never had a telegraph for.

So the rule the scheduler enforces at placement is: **nothing else happens inside a lethal
event's field.** A `hard_fail` event keeps its whole `outer_radius` clear of every other event,
and it is the one spacing rule with no fallback — an abduction that cannot find room is simply
not placed. `tests/test_events.gd` asserts it across a whole run.

## What an event actually costs

Each figure integrates the real falloff along a straight line through the centre of the field and
subtracts the walking decay, against a meter of 100 where sleep freezes at 35 and the baby cries at
100. `tests/test_events.gd` computes the same integral, so the numbers here and the assertion there
cannot drift apart. Regenerate the table from `EventDef.walk_through_cost()` whenever a rate in
`Tuning` moves; it is the fastest way to see what a balance change did to the catalogue as a whole.

**The shape of `Tuning.falloff` is `1−t²`**, so a field holds three quarters of its intensity at the
midpoint of its band. The middle distances are what cost: the meter has to go substantially up from
some way off rather than waiting for contact, and a `(1−t)²` field — a quarter of its intensity at
the midpoint — is one you can stand almost inside for free.

**The integral prices a field, not a route.** Being stopped by a body is a route cost this table has
never counted, and a solid row is one most of these walks cannot actually be made through at all;
see "Solid things are solid". It is still the right way to price a **row**: it is what being close
costs.

**Two kinds of row are priced differently, and both are flagged in the table.** `*` is a `hard_fail`, where
the figure is notional because nobody finishes the walk. `†` is a **flock**, which is `flock_size`
birds sharing `intensity` between them and wheeling inside `flock_spread`, so *all of the intensity
is at the centre* — the assumption the rest of the table rests on — is false for it:

- **Its row is computed from the birds**, not from one disc. Priced as a disc it reads +97 and
  breaks the running rule on a row that in fact keeps it, which is exactly the kind of silent
  breakage that rule exists to catch. `tests/test_events.gd` models the flock the same way, so the
  two cannot drift.
- **The straight line through the middle is not the whole story for it.** Walked against the real
  instance it costs about **+35** through the centre, **+8** eighty pixels off it and **nothing at
  all** at the rim. Every other row falls away gently from the middle; a flock is a hot spot with a
  wide quiet margin, and that gradient is the reason to build it out of eleven sources rather than
  one.

**The ground every one of these rows stands on is the half the table does not show**, and it is
large:

- **An ordinary footway is net recovery to walk.** 55–87 points of crowd over forty seconds against
  a walking decay that pays back 140, at every line from the frontage to the kerb. So an authored
  row on an ordinary street is very nearly the *whole* of what that stretch costs, which is what the
  figures below assume.
- **The middle of a pavement is the cheapest line along it**, by `CrowdLanes.SIDEWALK_LANE_SPREAD`,
  which spreads the walkers off it: an ordinary midline is 56 points per forty seconds.
- **Crossing the main road costs about 30**, and the wait at its lights about 33 more — between them
  a `dog_walker` and a `loose_dog`, and neither is in this table because neither is an event.

That last point is the one to carry: the cost of a route is not only the events on it, and the
*street kind* is a bigger term than most rows here. A balance argument that reaches for this table
alone is answering a narrower question than it thinks.

| Event | walk through | run through | mark |
| --- | ---: | ---: | :---: |
| `loudspeaker` | — | — | — |
| `curfew_announce` | — | — | — |
| `burnt_shell` | −3.0 | +16.5 | |
| `poster_crew` | +0.7 | +22.6 | |
| `barricade` | +3.0 | +26.0 | |
| `delivery_van` | +8.3 | +34.9 | |
| `busker` | +13.3 | +45.7 | |
| `police_patrol` | +15.9 | +46.2 | |
| `charging_dog` * | +16.9 | — | ●● |
| `cafe_tables` | +20.1 | +45.4 | |
| `cat_dash` | +20.2 | +35.4 | |
| `construction` | +20.3 | +51.6 | |
| `playground` | +25.5 | +44.3 | — |
| `market_stall` | +27.9 | +52.7 | ● |
| `checkpoint` | +29.0 | +59.4 | ● |
| `cyclist` * | +30.2 | +45.9 | ●● |
| `homeless_yeller` | +31.2 | +59.6 | ● |
| `ice_cream_van` | +31.5 | +65.8 | ● |
| `reversing_lorry` * | +32.6 | +53.3 | ●● |
| `alley_robbery` * | +34.6 | — | ●● |
| `dog_walker` | +36.5 | +41.2 | ● |
| `loose_dog` | +43.3 | +52.0 | ● |
| `leaf_blower` | +48.6 | +67.1 | ● |
| `protest` | +50.0 | +88.1 | ● |
| `pigeon_flock` † | +54.1 | +63.6 | ● |
| `burning_building` | +55.9 | +83.2 | ● |
| `abduction` * | +61.3 | +84.1 | ●● |
| `military_convoy` | +84.9 | +107.2 | ● |
| `night_raid` | +101.8 | +122.6 | ● |
| `fire_truck` | +115.4 | +132.0 | ● |
| `firefight` * | +155.9 | +162.3 | ●● |

**The `mark` column.** ● is the amber caret — *worth going round* — and ●● the doubled deep red
that means it ends the day. The threshold is `Tuning.MARK_WORTH_A_DETOUR`, a quarter of the meter,
and it falls in the gap between `construction` and `market_stall`; a lethal row is marked whatever
it costs, which is why `charging_dog` at +16.9 carries one and `cat_dash` at +20.2 does not. Apart
from the lethal rows the column is **monotone** — if A is marked and B is not, A costs more than B —
and `tests/test_danger.gd` asserts exactly that.

`playground` is the one row above the line with no mark, because it is `AMBIENT`: it never appears,
there is no moment to mark, and the park's own swing frame is the picture.

**The pursuers' run-through column is empty, and that is the point:** they **follow**, so there is
no crossing to price and no line to run along. Walking away from either loses the day; running away
costs 35 points from the lunge and less the sooner it is given. See `docs/MECHANICS.md`, "Running
that matters", for the measured tables. The city-wide rows have no line through them at all, which
is why `EventDef.walk_through_cost()` answers zero for them and this table says nothing.

**Three rows are cheap to walk through on purpose, and no fourth may be.** `burnt_shell` is
negative — a reminder rather than an obstacle, so it does not have to cost anything — and
`poster_crew` and `barricade` are marginally positive, which costs their design nothing: scenery
only ever asked to be nearly free. Everything else must be more expensive to walk through than to
walk around, or the correct play is to plough into it, and `tests/test_events.gd` asserts that with
those three named as the exemptions. A fourth is a decision somebody takes on purpose rather than a
number nobody checked.

**Running is never correct** on any row here. It costs `EXCITEMENT_FROM_RUNNING` *and* collapses
the decay from 3.5/s to 0.5/s, and together those beat the shorter exposure every time. Making
running necessary is therefore a mechanic to build rather than a number to tune: it needs something
running escapes.

**And what a *street* costs, which is the question this table does not answer.** A rig walked home
to the furthest calm block and back — 7,500px, a real errand — through a real day with the crowd
and the events both running: peak excitement **25 to 57** of a hundred across three seeds, the meter
frozen for 0–14% of it, nobody cried. The same day, holding one arrow key east from the doorstep for
fifteen seconds, loses; the trace names four pedestrian contacts and a car's horn, and the breakdown
at the moment of each is `crowd 30–44/s` against `events 10–14/s`.

**So the crowd is most of what a street costs, and the events are what make it a decision.** That
ratio is the design working: careless is fatal in seconds, careful is nearly free, and the gap
between them is where the game lives. None of it is in the table above — a contact with a pedestrian
is ~15.6 points and a car's horn ~8, and neither is in the catalogue at all. See MECHANICS.md.

**And every row prices walking through one event against walking around it**, which at one event
per block is a move the player rarely has in front of her: going around one is often going through
the next. It stays the right way to price a **row** and it is not a description of what a street
costs.

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

**Nothing is ringed, and that is a standing decision rather than a style.** The reason is worth
keeping rather than merely acting on:

> A ring communicates a falloff radius, which is a number. A silhouette communicates a threat.
> How dangerous a thing is should be visible from looking at *the thing*.

The second half of that is what decided the shape of the vocabulary below. A ring also cannot cover
the field it is drawn for: a crowd agent has no def to ring, and a `city_wide` source has no edge to
draw, so on a normal street a few things would be ringed, most would not, and nothing would explain
the difference. **A cue that marks everything says nothing**, and every rule below exists to keep
the replacement from becoming that.

| Cue | Means | Where |
| --- | --- | --- |
| **Legible entity** | The thing itself reads as what it is: a crouched cat, an idling van, a scaffold, a burnt shell. **This carries most of the load, and everything below is for what it cannot carry.** It is a rule with a test rather than an aspiration — one picture per row, no two rows sharing one. See point 6 below. | the art, one `EventDef.Look` per row |
| **Caret over the entity** | *This is worth changing your route for.* Raised by what a row **costs to walk through**, and by nothing else — see point 1 below. | `Sprites.draw_caret()`, from `EventInstance._draw_mark()` and `CrowdAgent._draw_horn_mark()` |
| **Its colour** | **Amber** = go round it. **Deep red, doubled** = it ends your day. Two colours, and they are a scale rather than a sequence. | `EventInstance.mark_colour()` |
| **Its flash** | *It has not started yet.* The telegraph phase, and the only channel carrying it — the colour cannot, because a telegraph is usually over before the event is on screen, so an amber that meant *telegraphing* would only ever be seen on the rows sited in front of the player and would read as *near*. | `EventInstance._draw_mark()` |
| **Breathing** | The caret's size and ride height track *current* emission, so a pulsing event visibly swells and settles and can be timed. | `EventInstance.mark_swell()` |
| **Edge badge** | Off-screen and closing **under its own steam**: a disc at the screen edge carrying the thing's own silhouette, a chevron pointing at it and the distance. Says *what* is coming, not that something is. | `DangerEdge` |
| **Exclamation over the player** | *This will end your day, and the clock has started.* A `hard_fail` event still telegraphing whose radius covers her, or a car closing on the lane she is standing in. Down the moment it stops being true. | `Stroller._draw_alert()` |
| **Doubled red over the player** | *It is bad now and you are in it.* Something lethal is live, she is within `LETHAL_MARK_LEAD` seconds of the radius that ends the day, **and the gap is closing at the speeds in play**. Not *inside the outer radius*, which for a cyclist is thirty times the area that can hurt her and stays true while the bike rides away. | `EventManager._warn_about_the_ground_she_is_on()` |
| **zzz over the pram** | *The baby is asleep* — the return phase, and the state with the most consequence and the least presence on screen. Flashing instead of breathing: *she is stirring*, and waking costs half the sleepiness bar. | `Stroller._draw_baby_cue()` |
| **Waves over the pram** | *She is not settling* (amber, at the calm threshold, where the day stops progressing) and *she is nearly crying* (red, three of them, flashing). | `Stroller._draw_baby_cue()` |
| **HUD line** | For a `city_wide` source, which has no position and therefore nothing to stand under. | `hud.gd` |
| **Sound lines** | Concentric arcs thrown off a source on the rising edge of a pulse — the visual form of a discrete noise (a yell, a bark, a beep, a siren whoop) | not built; queued in `docs/TODO.md` |

**Nothing draws a field.** That is the rule, and it is a standing decision rather than a
preference. If something new needs signalling, reach for one of the rows above; if none of them
fits, that is a design conversation and not a licence to draw a radius.

Three rules underneath the table, in the order they matter:

1. **The caret is raised by what a thing costs, and by nothing else.**

   The rule is the player's own expectation, stated so a test can hold it: **if A is marked and
   B is not, A costs more than B.** `EventDef.walk_through_cost()` is the order,
   `Tuning.MARK_WORTH_A_DETOUR` is where the line falls (a quarter of the meter, which lands in
   the 7.5-point gap between `market_stall` and `construction` rather than slicing a cluster),
   and lethal rows are marked whatever they cost — *ends your day* is a different kind of thing
   rather than a larger amount of the same one. `tests/test_danger.gd` holds all of it.

   **The trap it is written against** is a rule like *danger that changes over time* — lethal,
   telegraphing, swelling, or pulsing fast enough to be timed. Every clause of that is a true
   statement about a thing and **none of them is a statement about how bad it is**, so the marked
   set and the danger come apart: a fire engine carries nothing while a burning building half its
   price carries a caret, and a leaf blower is marked over the dog walker beside it because its
   beat is 4.0s rather than 8.0s.

   **A cue that marks everything says nothing**, so the cheap end of the street is left alone: a
   barricade, a poster crew and a burnt-out shell are large, distinct and visibly what they are,
   and pointing at them adds noise and no information.

   What this gives up, as a decision rather than an oversight: **a crouching cat (+20) has no
   caret.** The crouch is its own silhouette and the vocabulary's first row is that the entity
   carries it.
2. **Breathing is load-bearing.** It is the one thing a ring gives for free that a discrete
   symbol does not, and without it a pulsing event stops being something to time a pass
   through and becomes something that hurts at random.
3. **The exclamation mark is the load-bearing one.** Every other cue says *a thing exists*;
   that one says the fairness contract is now about you and the clock has started, which is the
   difference between information and instruction. It is also the one cue a ring could never have
   replaced: a lethal car has no telegraph phase to ring, and a ring round a car doing 185px/s is
   off the edge of the screen for most of the warning.
4. **And the mark means one thing: *this will end your day*.** Only a `hard_fail` event and a car
   closing on her raise it. Raised for **any** telegraphing event whose radius reaches her it
   means *a number is about to move faster* — which the meter already says continuously and
   proportionally, so the mark says nothing the player has to act on. It is rule 1 in a second
   shape, arriving at the one cue that cannot afford to mark everything.

   The cost is real and is the right cost: acts I and II contain nothing lethal, so the mark is
   nearly silent before day 8. That is not the cue being broken; it is the cue being honest about
   a game where nothing is dangerous yet.
5. **And a cue is a claim about a *moment*.** Rules 1 and 4 are about *which* things a cue is
   raised for; this one is about **when**, which no test in `tests/test_danger.gd` can see,
   because it asserts what is marked and not when.

   Two rules, and they are the same rule at two ends:

   - **A cue is lowered when its condition stops being true, by the system that can see the
     condition.** The traffic's mark has a 1.4s hold that survives the gap between two cars in
     one lane, and the thing that ends it is her stepping over the kerb — where a car cannot
     reach her at all. `Stroller.stand_down()` lets the raiser take *its own* mark down without
     handing anybody a setter for everyone else's.
   - **Measure the thing, not the gap.** A badge that tests how fast the *distance* is shrinking
     is measuring her 92px/s plus its speed, so walking towards anything lethal announces it. It
     measures the event's own approach with the player held still, caps the range as a *window*
     (announce what would reach her within `LEAD_TIME`), and holds a raised badge — plus a margin
     outside the screen edge, without which a thing on the boundary trades places with its own
     badge every frame and flickers.

6. **And row one is a rule, not an aspiration: one picture per row.** A look is the name of one
   picture and there is no generic to reach for. `tests/test_events.gd` holds both halves: **no
   two rows share a look**, and **no two looks share a silhouette**. `EventInstance.icon_for()` is
   the single table, and it is also what the badge draws — a second table of which picture a look
   means is how a badge ends up showing a delivery van for a fire engine.

   **The trap is the category.** `PERSON`, `VEHICLE`, `OBJECT`, `ANIMAL`, `FIRE` are all things
   you can always put one more row into, and rows collapse into them until a man shouting, a
   busker, a poster crew, a protest and the robbery that ends the day are one drawing. It reads as
   an art chore and it costs findings: a player can only report *"the robber"*, so two rows drawn
   as the same man are one row as far as any feedback is concerned, and *"who is the person
   killing me?"* is the question this row of the vocabulary exists to answer.

   The cost of adding an event is a drawing, and that is the point — the same move as deriving
   `obstructs_radius` from the silhouette, on the other half of the vocabulary: a field that is
   only ever *reached for* is a list wearing a rule's clothes.

   **A mobile vehicle needs two pictures.** One side-on sprite mirrored east and west shows a
   patrol car heading north its own flank. The three mobile rows — `police_patrol`, `fire_truck`,
   `military_convoy` — have an `_end` picture each, and *their own* rather than the crowd's
   (whose cars are end-on because at that angle the front and the back of a car are the same
   shape): the whole content of a vehicle row is which vehicle it is, and a police car that
   becomes a generic saloon the moment it turns north loses the one silhouette the badge exists to
   show at the moment it starts coming towards her. The **badge keeps the side view**, because an
   icon is read at 40px against a row of other icons and a vehicle end-on is a box at any size.

**The traffic pays for its own warning.** The vocabulary's first row is *the entity itself carries
most of it*, and the traffic is the place that is easiest to miss: the caret is drawn by
`EventInstance`, and a car is not an event. A lethal thing bearing down on the player that produces
a mark over **her** head and nothing anywhere else is the load-bearing cue paying for a warning it
should only be adding to. The horn cannot carry it either — a horn is silent in a game with no
audio, which is *"audio is never the only channel"* failing in the one place the traffic fairness
contract depends on it. So a car sounding its horn carries the same
doubled lethal caret a `hard_fail` event does, breathing with the horn's own decay. The shape
lives in `Sprites.draw_caret()` so there is one chevron rather than two that slowly stop being
the same chevron.

### What the edge badge is for, and what it is not

`fire_truck` does 190px/s with a 340px radius and `military_convoy` is the same shape. Both are
*designed* around a long telegraph that the player spends getting off that street — and an on-screen
cue is only useful once it is on screen, which at that speed is most of the warning gone. Without a
badge the fairness contract is met by the geometry and missed by the player.

It announces two things and no others: anything **lethal**, and anything **faster than a
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
  her and its entire content is the moment it happens to her. A badge for one appears and vanishes
  within the same second as the cat walks into view, which is an interruption announced away.

Three at once is also chosen *by arrival* rather than by distance: what the cap is choosing
between is warnings, and the one worth keeping is the one that gets here first.

### The cue that is not about the world

Every cue above says something about the **world**. The **baby** is the only thing the player is
trying to change, and her two meters live in the corner of a screen whose camera is on the pram — so
four of her states are drawn over the pram itself.

Four states, and the two rules that keep them from becoming rings again:

- **Stages, not a gauge.** A meter drawn over her head is the HUD moved, and a mark that is up
  whenever a number is moving is the thing rule 1 exists to stop. What earns a place is a small
  number of states, each a different instruction: *the day has stopped progressing* (excitement
  at the calm threshold, where sleepiness freezes), *the day is about to end*
  (`EXCITEMENT_NEARLY_CRYING`), *you are on the way home*, and *she is about to wake and it will
  cost you half the bar*.
- **It must not collide with the exclamation mark**, which means one thing only. Different motif —
  waves and a zzz, never a chevron or a bar — and a different anchor: the pram, stepped aside when
  the pram is on her own axis, since walking away from the viewer puts it exactly where the mark
  lives.

The colours are the vocabulary's own — amber for *about to be a problem*, red for *about to end
the day* — because a crying baby **is** a lost day. The escalation is more of the motif as well
as a colour change, the same rule `alert_close.svg` is drawn to.

### Where the visual channel is incomplete

- **Sound lines.** A discrete noise — a yell, a bark, a beep — reads only as the caret swelling.
  Concentric arcs thrown off on a pulse's rising edge would give it a "that just happened" beat.
  Queued in `docs/TODO.md`.

And the shape of two gaps that are closed, because both hid for milestones and both hid the same
way:

- **A vocabulary written as one class's private method has an invisible edge.** The caret lived on
  `EventInstance`, so *an entity carries its own cue* silently meant *an **event** entity does*, and
  the one lethal thing in the game that is not in the catalogue — a car — had nothing.
- **A player can only name what they can see.** While rows shared a drawing, a complaint about one
  of them was filed against another, and a milestone went on the wrong row. Row one of the
  vocabulary is the row that carries the load; when it fails, the failure arrives disguised as a
  finding about something else.

## Keeping a day winnable

One rule runs while a day is planned and two run after it:

- **Nothing is placed near calm she has not used this act.** The calm ground of every area she has
  not settled in is refused to `_place_one`, so the events that would have landed there go somewhere
  else. Ambient events and scars are exempt — a playground makes a park *contested*, which is the
  design, and a scar is something that already burnt.

  **It is a refusal rather than a repair**, which is the rule about checking before accepting: a day
  planned in full and then stripped of whatever landed on the calm spends its budget twice, and
  leaves the guarantee running only on the days a weaker one has already failed. Refusing the ground
  keeps every unvisited area clean on 64 planned days of 64 *and* raises the density, because
  nothing is placed to be thrown away.
- **At least one park is left unspoiled.** The last line rather than the rule, and it has work to do
  in exactly one case: she has settled in every calm area there is, so the placement rule protects
  nothing. Whichever park has the fewest events reaching it has them removed — and where there is a
  choice, the park it protects is **not** the one she used yesterday.
- **A park stays reachable on foot.** See "Keeping a late day walkable".

### The city remembers where she went

Going to the same park on day one and day two must not be possible, and the reason is not
repetition. It is that **the game's only verb stops being a decision on day two**: a player who
finds a good park on day 1 has no question left to answer, and answering that question is the whole
game.

So the calm block the baby actually fell asleep in is remembered — by `GameState`, not by
reading the telemetry; see docs/TELEMETRY.md — and the next day plans something loud into it.

Three things keep it from being a punishment for playing well, and all three are load-bearing:

- **It spoils with events, not by taking the ground away.** The park is still calm ground and
  still walkable; things are standing in it, visible from the street, and she decides.
  Nothing lethal or mobile is ever chosen for this, and nothing whose body would close the lot.
- **The usable-park rule is told to protect a different one**, or the two halves fight — the day
  puts spoilers in her park, and the rule, looking for the least disturbed calm ground, finds the
  block with spoilers on it and strips the very events that were the point.
- **They are ordinary events from the same day's pool.** Day 2 is not day 1 plus a punishment,
  it is a day whose noise happens to be somewhere she was counting on.

Two exemptions, both the same one: if the city has only one calm block, or every other calm
block is already spoiled, a **winnable day outranks a fresh decision** and she gets her park
back.

It is the same finding as *the calm area is a lap rather than a route* one scale up: that one found
the destination was not a decision, this one that *which* destination was not one either.

#### It has to cover the ground, not stand in it

**What denies calm ground is not reaching it, it is out-emitting the decay** the calm multiplier has
already raised to 7.7/s — so a busker at intensity 9 is useless past 100px however far his 190px
field reaches, in a lot that is 704px across. One spoiler denies about three percent of a four-block
calm zone: the day rolls its spoiler for the block she used, and she settles in that same block
anyway.

`EventScheduler._denial_radius()` is that arithmetic, and a spoiler is a **crowd** laid out on a grid
over the calm ground, sized from what each of them actually denies and capped at
`Tuning.SPOILERS_TO_DENY_A_PARK`. Two details that are not incidental:

- **Each cell rolls its own def**, so a spoiled park is a busker *and* a leaf blower *and* a market
  stall. A park that is busy today is busy with several different things, and nine copies of one
  sprite in a field would read as a duplicated sprite — which is what `EVENT_SPACING_SAME` exists
  to prevent everywhere else in the scheduler.
- **The roll is weighted by area, not just by `weight`.** Everywhere else a def's weight says how
  *common* it is; here the job is covering a lot, and a leaf blower covers four times the ground a
  busker does.

Measured over five seeds and twenty lots: the share of the calm ground she cannot settle on goes
from **8–12% on an ordinary day to 91% of a one-block courtyard and 99% of a four-block zone**. The
body a spoiler may have scales with the lot too — a sixteenth of its shortest side, floored at
`OBSTRUCTION_A_PARK_CAN_HOLD` — because a 28px market trestle is nothing in a 704px zone and a wall
across a four-tile courtyard.

## Pulsing events

`homeless_yeller` and `protest` use an intensity envelope rather than a constant:

```
intensity(t) = base × (0.25 + 0.75 × pulse(t))
```

with a visible/audible tell on the rising edge. This rewards the player for *waiting and
watching* rather than just avoiding — a different skill from pure pathing.

## Adding a new event

Defs live in code, not in `.tres` files — see "Where events are defined".

1. Add a `static func _<id>() -> EventDef` in `src/events/event_catalogue.gd`, in its act's
   section, and list it in `_build()`.
2. Add a row to the catalogue table above. The docs are the design; a def with no row is an
   event nobody decided on.
3. Decide `spawn_mode` deliberately — `MAP` unless the entire content of the thing is *the
   moment it happens to you*.
4. If it stands still and is drawn, give it an `obstructs_radius` of half its silhouette. That
   is a rule rather than a choice; see "Solid things are solid".
5. **Draw it.** A new `EventDef.Look`, a new SVG in `assets/events/`, a `_draw_*` in
   `EventInstance`, and a row in `EventInstance.icon_for()` so the screen-edge badge has a
   silhouette to show. There is no generic look to borrow — that is deliberate, and
   `tests/test_events.gd` fails the build if two rows share a picture. See "The visual
   vocabulary", point 6.
6. Run the project. `EventDef.validate()` rejects unfair geometry, a body on something sited
   ahead of the player, and a lethal radius its own body would hide, all on load.
7. If it needs behaviour no field covers, add the **field** to `EventDef` and handle it in
   `EventInstance`. Resist a script per event: `pursues`, `still_while_telegraphing` and
   `pavement_side` are all one field each, and each one is shared or checkable.
