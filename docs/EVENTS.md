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

## Solid things are solid *(M34)*

> *"None of the non-moving obstacles do anything — I can freely walk over them."*
> *"I can walk over the robber and he doesn't do anything."* — playtest 07, findings 16 and 13.

`obstructs_radius` was set on five rows out of thirty, because it had always been reached for
when a particular event wanted to block a pavement rather than derived from anything. So a
delivery van, an ice cream van and a burnt-out building were large, visibly solid, stationary
objects with no body at all, and the man shouting on the pavement outside the home block could be
stood on. The rule that replaced the list is one line:

> **Anything that stands still is solid at the width it is drawn.**

The width it is drawn is the whole of it — the number is half the silhouette, not a balance
value. `EventInstance._draw_spread` already drew a blocking object at exactly its
`obstructs_radius` for the same reason in the other direction: a body that disagrees with the
picture is a lie about where she can walk, whichever way it lies.

**Three exemptions, each for its own reason.**

- **Anything mobile.** A moving wall on a two-tile pavement pins her against a building, which is
  a different game from being priced out of a street. This is the `dog_walker` decision from M19
  and it is unchanged.
- **`AHEAD_OF_PLAYER`**, refused outright by `validate()` — see rule 3 above.
- **Anything with no silhouette**: a city-wide announcement, a playground the park itself draws.

**And one constraint that is not an exemption: a lethal radius and a solid body are the same
mechanism.** She is stopped with her centre `obstructs_radius + PLAYER_BODY_RADIUS` from the
centre of the thing, so on a `hard_fail` event a body that reaches the inner radius means the
kill can *never fire*, however carelessly she walks into it — a difficulty setting nobody chose,
arriving silently, in the one place the game cannot afford one. `EventDef.validate()` refuses that
arrangement on load. It is why `alley_robbery`'s inner radius moved 22 → 30 in M34: a man is 11px
wide and she is 14, so at 22 the pram would have been held three pixels *outside* the radius that
takes the baby.

### Which lane of the pavement *(M34)*

Two rows were reported as standing somewhere that made no sense of them, and `pavement_side` is
the answer to both. A corridor is sidewalk | road | sidewalk, so a pavement tile has a kerb on
one side and a frontage on the other, and `CityMap.pavement_inward()` says which.

- **`AT_THE_KERB`** — `delivery_van` and `ice_cream_van`. *"There is also a car obstacle on the
  road that is basically a still car standing on the road doing nothing."* It was on a `ROAD`
  tile, standing in a traffic lane that the crowd knows nothing about and drives straight
  through, blocking a route nobody walks. At the kerb it is on the pavement she is actually using
  and it takes it: 48px of van across a 64px footway means the answer is the other side of the
  street.
- **`AGAINST_THE_BUILDING`** — `reversing_lorry`. *"The backing out lorry does not connect to the
  building making it hard to visually read."* The whole event is that the danger is **behind** a
  wall of metal, which needs a wall. The placement also turns it to face out of that wall, so the
  box end is buried in the frontage and the cab is on the pavement. It asks for a frontage **east
  or west** of it, because the silhouettes that back into things are drawn side-on and a sprite
  cannot face north — half the pavements in the city are still eligible.

## Going away *(M35)*

> *"Running dog events etc — things that move disappear on screen; they should at least run
> offscreen before despawning."* — playtest 08, finding 3.
> *"Pigeons are also completely ineffective."* — finding 2, which is the same sentence.
> *"Birds just disappear if I get close and do nothing."* — playtest 07, finding 9, which is the
> same sentence again, a milestone earlier.

The end of an event was `_finish()` wherever it happened to be standing, and for the two
shortest-lived rows in the game that is directly in front of her. The rule now:

> **Nothing vanishes while you are looking at it.**

An event that is over enters a **leaving** phase: it stops emitting, it cannot end the day, it
carries no cue, and it moves until it is more than `Tuning.OUT_OF_SIGHT` from the player — 420px,
which is the far corner of a 640x360 view with the camera's look-ahead on top of it. Then it is
deleted, out of shot, where a deletion is what it looks like from the inside and nothing at all
from the outside.

Three things worth keeping straight:

- **It is over the moment it starts leaving.** A cat that trailed its field behind it for the two
  seconds it took to reach the kerb would be a worse bug than the one being fixed.
- **Anything `mobile` leaves at its own `speed` and needs no data.** The cat runs on the way it was
  going; the dog walker carries on down the street. `departs_at` is for the rest — a flock, which
  has to fly, and a pursuer that has lost interest and trots off.
- **Two things never leave**, and both would break something that reads the finishing position: an
  event with a `spawns_on_finish` stops **where the thing it leaves belongs** (a fire engine's fire
  is at the building, not two streets past it), and anything with no departure speed has always
  simply been over, which is right for a café that closes.

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

### Where in the city, and why *(M50 step 2)*

Until M50 a placement was a uniform roll over every tile of the right type, weighted only by
whether the tile was in a precinct. It is now also weighted by what the day is placing the thing
**for** — its **role**, in the vocabulary `docs/CITY.md` fixes — against the day's **corridor**,
which is the ways from the doorstep to the calm areas still worth reaching.

`EventScheduler._role_for` answers it off the def and nothing else has to be written per row:

| kind of row | role | where it may go |
| --- | --- | --- |
| lethal (`hard_fail`) | **wall** | never inside the corridor; `EVENT_WALL_RIM_WEIGHT` toward a turning off it |
| everything else placed on a tile | **friction** | `EVENT_CORRIDOR_WEIGHT` toward the corridor |
| a `ONE_SHOT` | **set piece** | one placement at *each* site of a covering set; one of them happens |
| `AMBIENT`, `AHEAD_OF_PLAYER`, a scar, a park spoiler | **none** | wherever its own rule says |

Two things about the mechanism rather than the table. It is **the same weighting the precinct
already used** — a tile is offered to the roll several times over — so every spacing rule
downstream keeps working unchanged and nothing new can refuse a placement. And **exactly one of
these is a rule rather than a weight**: a wall is never inside the corridor. That one can be
absolute because the rest of the city stays available to it, so it cannot starve a row of ground;
everything else is a weight for exactly the reason it could.

Measured over six seeds, per day, with both weights flattened to 1 and then at 4. Flattened is the
honest control: it leaves the *rule* in place and takes only the *preference* away, so what the
arrows show is what the weighting bought rather than what the whole milestone did.

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

### A set piece is offered on every route and happens on one *(M50 step 2)*

*"The fire + fire truck — it should be used in a way that the player actually encounters it on
their chosen route, so we could dynamically choose it from a candidate set on that day."*

The fire engine is the only one-shot in the catalogue and it used to be placed like everything
else: a legal spot somewhere on the map, on a day she may never walk that way. An authored set
piece that fires once per run and is missed is a fairness contract and a silhouette spent on
nothing.

So the day plans it **at every site of a covering set** — `RouteTree.covering_sites`, the smallest
set of streets such that every route touches one — and the placements share a `set_piece_group`.
The first one to enter the world spends the rest, in `EventManager._stream_in`, which is also
where a scar is recorded: a run gets exactly one fire however many streets were offered.

Three things this gets right that choosing a site on her route would not:

- **Nothing has to predict her.** The guarantee is structural and holds whichever way she goes.
- **A bundle is not a guarantee.** Two distinct routes to one area share no street by
  construction, so no single site can ever cover both. The covering set is two to six streets and
  code that assumed one would be the *"tile she must cross"* the design names as its own first
  draft's mistake.
- **The moment of choosing is the moment of walking there.** `_stream_in` is where an event becomes
  real — where its scar is recorded and its block moves along its arc — so the alternatives stop
  being possible on the same frame rather than when it finishes.

The three counts this splits apart are worth keeping straight, because two tests moved with it.
`max_per_day` is a cap on **instances**, and the number of offers is not one — so a one-shot is
exempt from it in `tests/test_events.gd` and the real count is asserted in
`tests/test_event_manager.gd`, where an instance exists. And a **retried day plans none** of a
spent one-shot rather than one fewer, because the whole group goes with it.

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

Playtest 05, finding 6, stated it as a number: **one event per block** — which is why
`EventScheduler.budget_for()` is stated *per block* and not as a flat number. A flat budget is a
statement about one lattice size: grow the city and the same events spread thinner, which is the
density quietly falling while every constant still reads as correct. At 9×9 that is **76 placed on
day 1**, 0.94 per block, against 0.97 at the 7×7 the table below was measured on.

The original measurement, over five seeds at 7×7:

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
| `cafe_tables` | RECURRING | 1 | **M19.** A café spilling out of its frontage, `obstructs_radius` 24px. The first thing in the game that is physically in the way on **day one**, and the answer to *"there should be things that force me to cross the street"*. Pleasant, which is worse: nothing about it looks like a hazard and it still costs the street. Stationary, so it can never pin anybody. **M37 put people at the tables** — playtest 07's finding 11: the tables were what obstructs and the conversation was what it emits, and only the first was drawn. |
| `homeless_yeller` | RECURRING | 1 | Large radius, 5s yell **pulse**, and since M36 he **paces** eight tiles of pavement (`EventDef.paces`). *"It didn't move and it took a long time to have any effect"* — playtest 09, about the man who killed a day-1 attempt by standing still. A fixed source on a fixed patch is a line you draw once; a man walking up and down it is a timing problem on top of a routing one. He is louder (10 → 14) and he lost the body M34 gave him, because anything mobile does. M37 gave him a silhouette of his own — a long coat, a raised arm, a beard, one shape where a passer-by is two. |
| `delivery_van` | RECURRING | 1 | Parked at the kerb, hazards going. Constant, medium. The plain obstacle route planning is practised on. **M34** moved it off the carriageway and gave it a body: it was *"a still car standing on the road doing nothing"*, standing in a traffic lane the crowd drove through. 48px of van across a 64px footway. |
| `busker` | RECURRING | 2 | Park and square spoiler. Nothing about it is threatening; it is simply interesting, which is the whole problem. Solid at 11px, which is a man to walk around and not a park closed — see `OBSTRUCTION_A_PARK_CAN_HOLD`. |
| `construction` | RECURRING | 2 | The only Act I event that is physically in the way (`obstructs_radius` 34px). Blocking a 64px sidewalk forces a reroute rather than inviting one — and since a street is sidewalk\|road\|sidewalk, the road is always still there, so it costs time and exposure, never the day. |
| `fire_truck` | ONE_SHOT | 3 | Drives an arterial at 190px/s with a 340px radius and a 4s telegraph (the fast-mover rule — see docs/MECHANICS.md). `spawns_on_finish` leaves a `burning_building` where it stops. |
| `burning_building` | — | — | Never scheduled: a SCRIPTED def with no day, so only the fire engine can put one in the world. Burns for the rest of the day, and since M34 you cannot walk through the fire. |

**M31 added seven more**, five of them on day 1. Playtest 05 asked for two things in the same
breath — *"there is never any danger"* and *"try to come up with more variety, we need more
events/entities in general"* — and ruled out the obvious answer: *"patrol shouldn't be there for
act I."* Act I is a nice neighbourhood, so its danger is a neighbourhood's own.

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `loose_dog` | RECURRING | 1 | *The player's idea: "a dog where the owner drops the leash and it starts running."* The counterpart to `dog_walker` and the reason both exist — that one is a **span** you decide whether to cross the street to avoid, this one is a **thing coming at you** that you cannot out-walk. 132px/s, so it earns a badge at the screen edge and pays the whole-radius telegraph. Not lethal: act I gets exactly two of those and this is not one. |
| `market_stall` | RECURRING | 1 | The second thing on day 1 that forces a crossing. `cafe_tables` has been the only one since M19 and M28 made it common, but one obstacle repeated eighteen times is a rule rather than a decision. Wider, louder, and on the other side of pleasant: a café you squeeze past is a nuisance, a market is a crowd. |
| `leaf_blower` | RECURRING | 1 | The loudest thing in act I, and it is a man tidying a park. Allowed on `PARK` on purpose — a calm block with a leaf blower in it is calm ground she cannot use, which is what M24 wants more of. Swept in bursts, so there is a rhythm to time a pass through. |
| `pigeon_flock` | RECURRING (`AHEAD_OF_PLAYER`) | 1 | The second thing that happens *to* her, and the reason to have one is that the director had a single trick: every moment was a cat. **Rebuilt twice.** M35 fixed the event — on the pavement for its whole telegraph, then up, then *away*, where it used to expire as she arrived and blink out. **M38 fixed the birds**, which was the reason it still read as broken: eleven of them now, each with its own heading, height and wingbeat, and each an emitter — so the middle of a flock stacks four or five fields and the rim stacks one. The only row in the game that is more than one source. |
| `cyclist` **`hard_fail`** | RECURRING | 2 | **The first thing in the game that can end your day.** A kid on a bike on the pavement, bell going. Everything about it is ordinary, which is the point — the answer to *"there is never any danger"* is not that act I becomes sinister, it is that act I becomes a real street. The bell rings for 3.3s, which is what the doubled margin costs at 165px/s. |
| `ice_cream_van` | RECURRING | 2 | The `busker` argument one size up: nothing about it is threatening, it is simply interesting. The widest ordinary radius in act I. At the kerb since M34, and solid at 24px: a thing children cross a road to reach rather than a thing standing in one. |
| `reversing_lorry` **`hard_fail`** | RECURRING | 3 | Act I's second lethal thing, teaching the opposite lesson to the cyclist. That one comes *at* you and the answer is to get off the pavement; this one is **stationary and the danger is behind it**, so the answer is not to walk into the gap it is backing into — which you have to look at the world to know. The beeper is the telegraph. **M34** gave it the yard: `AGAINST_THE_BUILDING`, turned to face out of the frontage, solid at 28px inside the 46 that ends the day. |

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
| `alley_robbery` **`hard_fail`** | RECURRING | 8 | **A man who is worth crossing the road for, and who comes after you if you do not.** *(M36, playtest 09: "a robber should increase excitement on sight and getting close to them should be day ending", then "if you get close they should start moving towards you".)* Three numbers for three sentences: 16 over a **200px** field, so the far end of an alley is already expensive and the meter is the only warning a robbery will ever give; `hard_fail` inside 30px, unchanged except that it can now be reached; and `pursues_within` 140, inside which he takes 1.8s of visibly coming and then chases at 130px/s. It was a 42px field that never moved — a thing that did nothing at all until it did everything. The alley is still the warning; it is no longer the only one. |
| `night_raid` | SCRIPTED | 10 | Enormous, static, pulsing, and it closes the block (`obstructs_radius` 44). |

### Act IV — Open conflict (days 12–14)

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `military_convoy` | RECURRING | 12 | Like the fire engine, but what it leaves behind is a `barricade`. |
| `barricade` | — | — | Never scheduled directly. Left where a convoy stopped, and — via `scar_id` — left there for the rest of the **run**. |
| `protest` | RECURRING | 12 | `intensity_ramp` 1.9 over 150s: a protest you could have walked past when you saw it is not one you can walk past two minutes later. **Solid at 55px since M37**, which is the clearest case in the catalogue of art deciding a gameplay number: it obstructed one person's width because `Look.PERSON` drew one man, and the body may not claim ground the picture does not. `_draw_protest` draws two ranks across exactly that width now. Under its own 70px inner radius on purpose — the loudest part of a protest is something you stand in rather than bump into. |
| `firefight` | SCRIPTED | 13 | The worst thing in the catalogue. Extreme, `hard_fail`, 6.5s telegraph, and it shuts a junction. Solid at the width of its cover. It drew the same five flames as a burning building until M37, which said *this street is on fire* about the one event whose content is that there are **people** doing this. |
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

**M34 moved exactly one row** — `alley_robbery`, 9.1 → 10.0, because its inner radius grew to fit
a man's body plus a pram's — and made most of the others **impossible to actually walk**, which is
the point of it and does not change what they are worth. The integral is still the right way to
price a field: it is what it costs to be close, and being stopped by a body is a *route* cost that
this table has never counted. See "Solid things are solid".

**M35 moved exactly one row too** — `pigeon_flock`, 22.9 → 34.9, which is playtest 08's *"pigeons
are also completely ineffective"* and playtest 07's *"birds just disappear if I get close and do
nothing"* priced. It was a 110px field at intensity 17 in a game where a café is 170px at 12, and
it expired as she reached it. It is 140px at 20 now, it lasts long enough to be arrived at, and it
sits between a reversing lorry and a dog walker — which is what a flock going up in a pram's face
should be worth. `charging_dog` dropped from 22 to 12 and still has no row; see below.

**And M38 moved it again, to +54.1, and changed what the number even means for that one row.**
A flock is `flock_size` birds sharing `intensity` between them and wheeling inside `flock_spread`,
so "all of the intensity is at the centre" — the assumption the whole table rests on — is false
here. Two things follow, and both matter to anyone reading the table:

- **The row is computed from the birds**, not from one disc. Left as a disc it read +97 and broke
  the running rule on a row that in fact keeps it, which is exactly the silent breakage M33 wrote
  that rule to catch. `tests/test_events.gd` models the flock the same way, so the two still
  cannot drift.
- **The straight line through the middle is no longer the whole story for it.** Walked against
  the real instance it costs about **+35** through the centre, **+8** eighty pixels off it and
  **nothing at all** at the rim. Every other row in this table falls away gently from the middle;
  a flock is a hot spot with a wide quiet margin, and that gradient is the reason to build it out
  of eleven sources rather than one.

**M46 moved no row at all, and that is the result rather than the absence of one.** The milestone
rebalanced the crowd and the traffic, and `CLAUDE.md` says to re-measure this table whenever a rate
moves — so it was regenerated from `EventDef.walk_through_cost()` and compared row for row.
Identical, because nothing in it touched an intensity, a radius, `Tuning.falloff` or a decay. The
table is a property of the **catalogue**, and M46 was a milestone about the street.

What did move is the ground every one of these rows stands on, which is the half the table has
never shown:

- **An ordinary footway is net recovery to walk.** 55–87 points of crowd over forty seconds against
  a walking decay that pays back 140, at every line from the frontage to the kerb. So an authored
  row on an ordinary street is very nearly the *whole* of what that stretch costs, which is what
  the figures below have always quietly assumed and had never been checked.
- **The middle of a pavement got cheaper**: `CrowdLanes.SIDEWALK_LANE_SPREAD` took an ordinary
  midline from 74 to 56 points per forty seconds.
- **Crossing the main road costs about 30**, and the wait at its lights about 33 more — between them
  a `dog_walker` and a `loose_dog`, and neither is in this table because neither is an event.

That last point is the one to carry: since M19 the cost of a route has not been only the events on
it, and since M41 the *street kind* is a bigger term than most rows here. A balance argument that
reaches for this table alone is answering a narrower question than it thinks.

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

**The `mark` column is M39, and reading it downwards is the whole of playtest 10's findings 1, 8
and 9.** ● is the amber caret — *worth going round* — and ●● the doubled deep red that means it ends
the day. The threshold is `Tuning.MARK_WORTH_A_DETOUR`, a quarter of the meter, and it falls in the
gap between `construction` and `market_stall`; a lethal row is marked whatever it costs, which is
why `charging_dog` at +16.9 carries one and `cat_dash` at +20.2 does not. The column has to be
**monotone** apart from the lethal rows, and `tests/test_danger.gd` asserts exactly that — before
M39 it was not, and a fire engine carried nothing while a burning building did.

`playground` is the one row above the line with no mark, because it is `AMBIENT`: it never appears,
there is no moment to mark, and the park's own swing frame is the picture. It is also the row M39
had to fix — see below.

**The two pursuers' run-through column is empty, and that is the point:** they **follow**, so there
is no crossing to price and no line to run along. Walking away from either loses the day; running
away costs 35 points from the lunge and less the sooner it is given. See `docs/MECHANICS.md`,
"Running that matters", for the measured tables. The city-wide rows have no line through them at
all, which is why `EventDef.walk_through_cost()` answers zero for them and this table says nothing.

**M39 moved two rows and both are defects rather than rebalances.** `playground` went +5.8 →
**+25.5**, because at intensity 7 it never once out-emitted the calm-ground decay it stands on
(7.7/s) and its denial radius was its own inner radius, 40px of 150 — *"playground doesn't increase
excitement"*, and it had been true since M18 raised the calm multiplier. And `alley_robbery` has a
row again at **+34.6**: the pursuers used to be priced as "see below", and a thing that is a *place*
for as long as she is outside its trigger has a line through it like anything else.

**M36 moved two rows and neither is a rebalance.** `homeless_yeller` went +17.7 → **+31.2** because
he **paces** now and 10 was not enough to notice — *"it didn't move and it took a long time to have
any effect"* — and he lost his body, because anything mobile does. And `alley_robbery` left the
table altogether: it was +10.0 with a 42px field, and it is a 200px field with a trigger in it now,
so it is priced like the dog rather than like an obstacle.

`*` is a `hard_fail`: the figure is notional, because nobody finishes the walk. Two rows the
playtest-02 version of this table was missing entirely (`burnt_shell`, `alley_robbery`) are
included now — the old one listed eighteen of what was then twenty.

`†` is a **flock**, priced from its birds rather than from one disc, and the only row where the
straight line through the middle is not most of the story: about +35 walked against the real
instance, +8 eighty pixels to one side and nothing at the rim. See the M38 note above.

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
| **Legible entity** | The thing itself reads as what it is: a crouched cat, an idling van, a scaffold, a burnt shell. **This carries most of the load, and everything below is for what it cannot carry.** Since M37 it is a rule with a test rather than an aspiration — one picture per row, no two rows sharing one. See point 6 below. | the art, one `EventDef.Look` per row |
| **Caret over the entity** | *This is worth changing your route for.* Raised by what a row **costs to walk through**, and by nothing else — see point 1 below. | `Sprites.draw_caret()`, from `EventInstance._draw_mark()` and `CrowdAgent._draw_horn_mark()` |
| **Its colour** | **Amber** = go round it. **Deep red, doubled** = it ends your day. Two colours, and they are a scale rather than a sequence. | `EventInstance.mark_colour()` |
| **Its flash** | *It has not started yet.* The telegraph phase, and the only channel carrying it. *(M39: the colour was carrying it and could not — a telegraph is over before the event is on screen, so amber was only ever seen on the two rows sited in front of the player and read as "near".)* | `EventInstance._draw_mark()` |
| **Breathing** | The caret's size and ride height track *current* emission, so a pulsing event visibly swells and settles and can be timed. | `EventInstance.mark_swell()` |
| **Edge badge** | Off-screen and closing **under its own steam**: a disc at the screen edge carrying the thing's own silhouette, a chevron pointing at it and the distance. Says *what* is coming, not that something is. | `DangerEdge` |
| **Exclamation over the player** | *This will end your day, and the clock has started.* A `hard_fail` event still telegraphing whose radius covers her, or a car closing on the lane she is standing in. Down the moment it stops being true. | `Stroller._draw_alert()` |
| **Doubled red over the player** | *It is bad now and you are in it.* Something lethal is live, she is within `LETHAL_MARK_LEAD` seconds of the radius that ends the day, **and the gap is closing at the speeds in play**. *(M39: it was "inside the outer radius", which for a cyclist is thirty times the area that can hurt her and stayed up while the bike rode away.)* | `EventManager._warn_about_the_ground_she_is_on()` |
| **zzz over the pram** | *The baby is asleep* — the return phase, and the state with the most consequence and the least presence on screen. Flashing instead of breathing: *she is stirring*, and waking costs half the sleepiness bar. | `Stroller._draw_baby_cue()` |
| **Waves over the pram** | *She is not settling* (amber, at the calm threshold, where the day stops progressing) and *she is nearly crying* (red, three of them, flashing). | `Stroller._draw_baby_cue()` |
| **HUD line** | For a `city_wide` source, which has no position and therefore nothing to stand under. | `hud.gd` |
| **Sound lines** | Concentric arcs thrown off a source on the rising edge of a pulse — the visual form of a discrete noise (a yell, a bark, a beep, a siren whoop) | todo, M10 |

**Nothing draws a field.** That is the rule, and it is a standing decision rather than a
preference. If something new needs signalling, reach for one of the rows above; if none of them
fits, that is a design conversation and not a licence to draw a radius.

Three rules underneath the table, in the order they matter:

1. **The caret is raised by what a thing costs.** *(M39, playtest 10 findings 1, 8 and 9: "there
   is no danger indicator over the homeless person", "I don't understand the difference between
   yellow and red", and "some dangerous ones don't have indicators and some really benign ones
   do".)*

   It was *danger that changes over time* — lethal, telegraphing, swelling, or pulsing fast
   enough to be timed — and every clause of that is a true statement about a thing and **none of
   them is a statement about how bad it is**. So the marked set and the danger came apart: a
   fire engine (+115, the second most expensive row in the game) carried nothing and a burning
   building (+56) carried a caret; the most expensive ordinary row in act I, a dog walker at
   +36, carried nothing and the leaf blower beside it carried one, because its beat is 4.0s
   rather than 8.0s; and `homeless_yeller` at +31 — the man who ends day 1 in three separate
   traces — missed the pulse rule by four tenths of a second.

   The rule is the player's own expectation, stated so a test can hold it: **if A is marked and
   B is not, A costs more than B.** `EventDef.walk_through_cost()` is the order,
   `Tuning.MARK_WORTH_A_DETOUR` is where the line falls (a quarter of the meter, which lands in
   the 7.5-point gap between `market_stall` and `construction` rather than slicing a cluster),
   and lethal rows are marked whatever they cost — *ends your day* is a different kind of thing
   rather than a larger amount of the same one. `tests/test_danger.gd` holds all of it.

   What survives from the old rule is what it was right about: **a cue that marks everything
   says nothing.** Day 1 marks six of nine rows and leaves the cheap end of the street alone; a
   barricade, a poster crew and a burnt-out shell are large, distinct and visibly what they are,
   and pointing at them adds noise and no information.

   What is given up, as a decision rather than an oversight: **a crouching cat (+20) loses its
   caret.** The crouch is its own silhouette and the vocabulary's first row is that the entity
   carries it.
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

6. **And row one is a rule, not an aspiration: one picture per row.** *(M37, playtest 07 finding
   2: "not sure what that person was supposed to be".)* Every rule above is about what to add
   *on top of* a legible entity, and for thirty-six milestones the entity underneath was often
   not legible at all. `EventDef.Look` opened with five **categories** — `PERSON`, `VEHICLE`,
   `OBJECT`, `ANIMAL`, `FIRE` — and a category is something you can always put one more row
   into, so sixteen of the twenty-eight visible rows drew five pictures between them. A man
   shouting, a busker, a poster crew, a protest and the robbery that ends the day were one
   `person.svg`; a delivery van, a fire engine, a police car, a riot van, an army truck and the
   unmarked van that takes the baby were one van.

   **It reads as an art chore and it was costing findings.** M34 spent a milestone fixing
   `alley_robbery` for a complaint about `homeless_yeller`, because a player can only say *"the
   robber"* and the two drew the same man; playtest 09 then asked *"who is the person killing
   me?"*, which is the question this row of the table exists to answer. And the badge — the one
   cue whose whole content is *what* is coming — was showing a delivery van for a fire engine,
   because `DangerEdge` kept a **second** table of which picture a look meant.

   So a look is the name of one picture, there is no generic left to reach for, and
   `tests/test_events.gd` holds both halves: **no two rows share a look**, and **no two looks
   share a silhouette**. `EventInstance.icon_for()` is the single table, which is also what the
   badge draws. The cost of adding an event is a drawing, and that is the point — it is the same
   move M34 made with `obstructs_radius`, one milestone later and on the other half of the
   vocabulary: a field that is only ever *reached for* is a list wearing a rule's clothes.

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
- **~~The entities themselves.~~** *(Closed in M37 — see "One picture per row" below.)* Every
  visible row draws something of its own now, and the reason it took four milestones to fix a
  thing that reads as an art chore is worth keeping: it was never *"not urgent"*. Row one of the
  table is the row that carries the load, and two findings had already been misfiled because it
  was failing — M34 spent a milestone on `alley_robbery` because of a complaint about
  `homeless_yeller`, and playtest 09 asked *"who is the person killing me?"*. A player can only
  name what they can see.
- **~~The traffic carries no entity-side cue.~~** *(Closed in M30: a car sounding its horn
  draws the doubled lethal caret.)* Worth keeping the shape of the gap, because it is the one
  that hid longest: the caret was a method **on `EventInstance`**, so "an entity carries its own
  cue" silently meant "an *event* entity carries its own cue", and the one lethal thing in the
  game that is not in the catalogue had nothing. A vocabulary written as one class's private
  method is a vocabulary with an invisible edge.

## Keeping a day winnable

One rule runs while a day is planned and two run after it:

- **Nothing is placed near calm she has not used this act.** *(2026-08-31: "why are 7-9 unvisited
  calm areas spoiled? Just don't place events there!")* The calm ground of every area she has not
  settled in is refused to `_place_one`, so the events that would have landed there go somewhere
  else. Ambient events and scars are exempt — a playground makes a park *contested*, which is the
  design, and a scar is something that already burnt.

  It replaced a **repair**: the day used to be planned in full and whatever landed on the calm was
  then deleted, which spent the budget twice and left the guarantee running only on the days a
  weaker one had already failed. Refusing the ground keeps every unvisited area clean on 64 planned
  days of 64 *and* raises the density, because nothing is placed to be thrown away.
- **At least one park is left unspoiled.** The last line rather than the rule, and it now has
  work to do in exactly one case: she has settled in every calm area there is, so the placement
  rule protected nothing. Whichever park has the fewest events reaching it has them removed.
  *(M24: where there is a choice, the park it protects is **not** the one she used yesterday.)*
- **A park stays reachable on foot.** See "Keeping a late day walkable" below.

### The city remembers where she went *(M24)*

Playtest 05, finding 4: *"I was able to go to the same park on day one and two — this shouldn't
be possible."* The complaint is not about repetition. It is that **the game's only verb stopped
being a decision on day two**: a player who finds a good park on day 1 has no question left to
answer, and answering that question is the whole game.

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

This is playtest 03's finding 2 one scale up. That one found the calm area was a lap rather than
a route (M21); this one finds that *which* calm area was not a choice either.

#### It has to cover the ground, not stand in it *(M35)*

> *"The robber in the park is still ineffective — I can use the same park every day — and there is
> only one robber."* — playtest 08, finding 1, which is playtest 07's finding 10 asked a second
> time: *"blocking a park etc should have multiple robbers so the entire area is dangerous or a
> full block party or other things that completely block out the space."*

M24 placed exactly **one** event and nobody did the arithmetic. What denies calm ground is not
reaching it, it is out-emitting the decay the calm multiplier has already raised to 7.7/s — so a
busker at intensity 9 is useless past 100px however far his 190px field reaches, in a lot that is
704px across. He denied about three percent of a four-block calm zone, and the traces show exactly
that: day 2 rolls a spoiler for the block she used, and she settles in that same block anyway.

`EventScheduler._denial_radius()` is that arithmetic, and the spoiler is now a **crowd** laid out
on a grid over the calm ground, sized from what each of them actually denies and capped at
`Tuning.SPOILERS_TO_DENY_A_PARK`. Two details that are not incidental:

- **Each cell rolls its own def**, so a spoiled park is a busker *and* a leaf blower *and* a market
  stall. That is the fiction — a park that is busy today is busy with several different things —
  and it is also the honest way round the art gap it was written under: nine copies of one sprite
  in a field would read as a duplicated sprite, which is what `EVENT_SPACING_SAME` exists to
  prevent everywhere else in the scheduler. *(M37 closed the gap — every row draws something of
  its own now — and the rule stands on the fiction alone, which is where it should have stood.)*
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

Defs live in code, not in `.tres` files — see "Where events are defined". This list said
otherwise for thirty-odd milestones; it was describing a plan that was abandoned in M4.

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
   `pavement_side` are all one field each, and each one is now shared or checkable.
