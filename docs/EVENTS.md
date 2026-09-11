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
| `spawn_mode_switches_after_day` / `spawn_mode_after_first_day` | For a row whose siting changes once its first appearance is over: `spawn_mode_on(day)` answers `spawn_mode` through that day and `spawn_mode_after_first_day` past it. `0` (the default) means never — `spawn_mode` alone answers for every day. `charging_dog` is the one row that sets it: `AHEAD_OF_PLAYER` on `RUN_TAUGHT_DAY`, `MAP` after |
| `departs_at` | How fast it removes itself when it is over (px/s). **Nothing vanishes while you are looking at it** — see "Going away". Anything `mobile` leaves at its own `speed` and needs no value here |
| `pursues` / `pursue_speed` | Comes after **her** rather than along a path, at a speed strictly between a walk and a run. The one thing running is the answer to — see `Tuning.validate_pursuit` |
| `pursues_within` | How close she has to come before it takes an interest. `0` is *immediately*, which is a pursuer that is a **moment**; anything else is a pursuer that is a **place** until she walks up to it, and its telegraph and chase are both measured from when it notices |
| `paces` | Walks its route and turns round at the ends, for ever. The difference between a journey and a **beat** — see `homeless_yeller` |
| `obstructs_radius` | The reach (px) of the row's own `shape` — a `GroundShape`, and the body is that shape, not a second number. **A thing that stands still is solid at the width it is drawn** — see "Solid things are solid" |
| `pavement_side` | Which lane of a two-tile pavement it wants: `ANY`, `AT_THE_KERB`, `AGAINST_THE_BUILDING` |
| `hard_fail` | Whether contact ends the day immediately |
| `redetains` | Whether a `detain_seconds` row is armed again once she is released and outside `detain_radius`, rather than spent after one conversation. `false` for everything but `checkpoint_hut`/`checkpoint_post` — see "Checkpoints" |
| `heat_response` | How the row answers to the resistance: `NONE`, `PRESSES` (more of them, more expensive, and past half way it comes over), `HUNTS` (it stops being a place and starts being a hunter) — see "The heat" |
| `look` | Which picture it draws. **One per row, and no two rows share one** — see "The visual vocabulary", point 6 |
| `shape` | The row's own `GroundShape` (`src/ground_shape.gd`) — a point or a segment, independent of the picture — that its shadow and, when it obstructs, its collision body are both derived from. Set by `EventDef.solid(shape)` for anything with `obstructs_radius`, or directly for anything with a `look` that does not obstruct; `null` only for `look == NONE` — see "Solid things are solid" |
| `act_tag` | Narrative act it belongs to. No game code reads it; `tests/test_acts.gd` holds it consistent with the calendar `first_day` actually gates |

There is no `impulse` field. A "sharp spike" is just a short `duration` at high `intensity`
— which is exactly what a cat crossing the road *is* — and expressing it that way keeps the
entire excitement model a pure query with nothing pushing values at the baby.

### Kinds

- **`AMBIENT`** — permanently present, part of the map (playground, busy road).
- **`RECURRING`** — can be rolled on any eligible day, possibly many times in a run.
- **`ONE_SHOT`** — fires on exactly one day in the run, then never again (burning building).
- **`SCRIPTED`** — the scheduler is told exactly which day it fires (story beats).

## Where an event happens

`kind` says *when* an event may happen. `spawn_mode` says **where**, and there are three answers.

**`MAP`, which is nearly everything.** The scheduler puts it on a tile when the day is planned,
and `EventManager` puts it in the world when the player comes within `EVENT_STREAM_RADIUS` of it
— of the nearest point of its *route*, for a mobile one, so a dog walker is in the world before
it sets off down the street she is on. It goes away again when she leaves, and once it has run
its course its plan is **spent**: walking back past it does not start it over.

An event that is somewhere is half of what makes a route a decision. It can be routed around,
and finding out it is there is what walking a street is for.

**`AHEAD_OF_PLAYER`, which is the cat, the flock and the day-3 charging dog.** No tile. The day
budgets it at the same cost as everything else, and `EventDirector` sites it while she is walking. A
crossing row — the cat, the flock — is sited across her line, `AHEAD_LEAD_DISTANCE` in front of her.
A pursuer — `charging_dog`, on `Tuning.RUN_TAUGHT_DAY` — is sited down her line instead, outside the
view along the heading she is actually walking (`Tuning.offscreen_boundary()`), so it has an
offscreen approach to close before it reaches its stand-off; see "Everything arrives from off
screen" below.

**`charging_dog` is sited on her exact heading only on `Tuning.RUN_TAUGHT_DAY`.** The row recurs
after the teaching day — *"the tutorial dog may appear later but not as tutorial"* — and the same
placement that makes day 3's dog unavoidable would make every later one an ambush guaranteed to meet
her wherever she happened to be walking. `EventDef.spawn_mode_on(day)` answers `AHEAD_OF_PLAYER` up
to and including `RUN_TAUGHT_DAY` and `MAP` every day after, so past the teaching day the row is
placed on a tile the way `alley_robbery` is and met by routing into it rather than sited by the
director at all — see `EventDef.spawn_mode_switches_after_day` and `spawn_mode_after_first_day`.

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

**`TOWARD_PLAYER`, which is the cyclist and the loose dog.** Also no tile, also sited by
`EventDirector` while she walks — but *down* her own line instead of across it, outside the view
along her heading (`Tuning.offscreen_boundary()`) and coming the other way, so she meets it by
continuing to walk rather than by being crossed. It is neither of the other two: `MAP` sites it at
dawn, on a street the day has no way of knowing she will ever walk, so a bike sited that way is a
bike she may never see; and an `AHEAD_OF_PLAYER` crossing is gone in three seconds and asks her to
react, not to plan. A bike on her own pavement is a road, and the answer to a road is a route
decision — cross to the other side, or turn — made with the warning the screen-edge badge already
gives anything faster than a walk.

**And it comes down her own pavement, not the one across the carriageway.** *(2026-09-07: "also
biker should be on the same side of the road not the other side".)* Sited along her literal heading,
a lead of hundreds of pixels drifts across the road from a heading only a little off the corridor's
own axis, landing the row on the far sidewalk, where it reads as scenery rather than as a lane she
has to answer for. Where she is standing on a plain sidewalk edge, `EventDirector._toward_her()`
straightens the siting heading onto the corridor's own axis first — `CityMap.pavement_inward()`
names which side of the corridor she is on, and zeroing the heading's component on that axis keeps
the row on her side for its whole approach. **A preference, not a requirement**: off a plain
sidewalk edge — the carriageway, a junction, open ground — or heading straight across the street
with no along-corridor component to send it down, the literal heading is used exactly as before.

It does not adjust to her the way a pursuer does. `pursues` backs off, holds a stand-off and gives
up if she runs; `TOWARD_PLAYER` is traffic, not an ambush — it travels the straight line it was
sited on, at its own `speed`, whether or not she is in it. The same two rules bind it as bind
`AHEAD_OF_PLAYER`: the clock only runs while she is walking, and `EventDef.validate()` refuses one
whose `obstructs_radius` is nonzero, or whose `outer_radius` reaches `Tuning.min_offscreen_boundary()`
(180px, the vertical axis, the narrower of the two the director ever sites against) — a field that
wide would already be on her the moment it appeared, which is the one thing "she gets close and it
arrives" cannot mean.

### Everything arrives from off screen

**A row that travels toward her — a pursuer or a `TOWARD_PLAYER` row — is sited outside the view,
not against a flat number sized for one axis of it.** The camera sits on her at zoom 2 over a
1280x720 viewport, so the visible world is 640x360: 320px to the edge sideways, 180px vertically.
`Tuning.offscreen_boundary(heading)` is a ray to whichever of those two edges the heading in play
actually reaches first, so a row sited while she walks east is genuinely off screen on that axis
rather than merely off the narrower one the old flat number was sized for.

**And it stays off screen for at least its own notice of closing, not merely past the edge.**
*(2026-09-07: "events that go towards the player (biker / pursuing dog) should at least be 200ms
off screen with a warning.")* `Tuning.offscreen_lead(heading, closing_speed, notice)` adds
`notice` seconds of `closing_speed` on top of the boundary — the row's own speed plus `WALK_SPEED`,
because she is usually walking into it. The unit is **time**, and the pixels are what it costs at
each row's own speed — a slower row buys the same notice with fewer of them.

**The notice is per row, `EventDef.offscreen_notice`, because two rows needed to move in opposite
directions on the same day.** *(2026-09-07: "pursuing dog is still too short notice", "while biker
is now too long notice".)* `Tuning.OFFSCREEN_NOTICE` (0.2s) is the default every row gets unless it
overrides. `charging_dog` carries 0.5s: at 130px/s pursuing (222px/s closing) the default buys only
44px, and playtest 20 measured a 1.5s chase as the shortest one that ended in evasion against
0.8-0.9s for the two that killed her — 0.5s of notice closes from its worst-case siting to
`Tuning.pursuit_standoff()` in under a second at the closing speed she usually gives it while
walking toward it, well clear of the 0.8-0.9s that failed.

**A further siting needs a longer `telegraph_time` to spend it in**, or a player who only walks can
outlast the row's own budget before it ever catches her. `duration` stays at `Tuning.PURSUIT_TIME`
— `tests/test_events.gd` holds every pursuer to that exact ceiling, tighter than
`validate_pursuit`'s own — so `charging_dog`'s `telegraph_time` rises to 4.5s instead: closing the
whole worst-case gap at the rate walking away still loses by (`pursue_speed` − `WALK_SPEED` =
38px/s) takes about 7.0s, inside the 7.5s `telegraph_time` + `duration` gives it. `cyclist` stays
at the default notice; its own notice moved a different way, in its `outer_radius` and
`telegraph_time` — see the next paragraph.

**The margin applies to what travels toward her, not to a crossing.** `cat_dash` and
`pigeon_flock` keep `AHEAD_LEAD_DISTANCE` / `EventDef.ahead_of_player_lead()` unchanged: a crossing
row's whole content is a three-second interruption she reacts to as it happens, not an approach she
watches close, so there is no "closing speed" for the margin to be stated over. **Chosen as the
smaller reading of a silence** — the instruction named "events that go towards the player", not
every director-sited row, and a crossing already pays its own fairness in the reaction-window rule
above rather than in an offscreen phase.

**The screen-edge badge is what makes the offscreen phase worth anything.** `DangerEdge` already
draws one for anything lethal or faster than a walk that is off screen and closing under its own
steam; a pursuer sited outside the view is exactly that for as long as it stays there, so
`DangerEdge._is_worth_an_arrow` announces it the same way it announces `TOWARD_PLAYER` — a row moved
further out without the badge following it would have *less* warning than it had before, not more.

**A `hard_fail` `TOWARD_PLAYER` row is sited further still, so its telegraph is over before it
arrives.** `EventInstance.is_lethal_at()` refuses the whole time an event `is_telegraphing()`, so a
row sited only past the offscreen margin can close the gap and ride straight through her while
still telegraphing — declared lethal and never once able to fire. *(2026-09-07: "also a biker hit
should be lethal.")* `Tuning.outlasting_telegraph_lead()` takes whichever is further: the ordinary
offscreen margin, or the distance that takes `telegraph_time + notice` to close at the row's own
closing speed. For `cyclist` (telegraph 2.0s, closing 257px/s) the telegraph term wins on every
heading: `(2.0 + 0.2) * 257` = 565px, against at most 371px from the offscreen margin alone.

**How long that telegraph is is not a free choice — it is tied to `outer_radius` at a fixed
`hard_fail` margin, and shortening one means shrinking the other.** *(2026-09-07: "while biker is
now too long notice" — the player reversing the caution this row's own siting was built with, that
shortening the telegraph "buys the lethality back by taking the notice away". The complaint flipped
for this row: not too little warning, but watching it close from off screen for over three seconds.
`EventInstance.is_lethal_at()` still refuses the whole telegraph, so the arrival still has to land
after it ends, and the fairness floor above is what keeps that true at any size — so the field
moved along with the telegraph rather than the telegraph moving on its own.)*

## Solid things are solid

`obstructs_radius` is not a field to reach for when a particular event wants to block a pavement.
It is derived, by one line:

> **Anything that stands still is solid at the width it is drawn.**

**The body is the row's own `GroundShape` (`src/ground_shape.gd`) — a point or a segment, in the
object's own ground frame — and `obstructs_radius` is its `reach()`: the furthest any point of the
shape lies from its own centre.** A row that obstructs calls `EventDef.solid(shape)`, which sets
both in the one call that keeps them from disagreeing; `EventDef.validate()` refuses a row whose
`obstructs_radius` does not equal `shape.reach()`. A row drawn as a spread — a café frontage, a
roadblock, a protest rank — reduces to a segment (a capsule) of a fixed 24px rounding
(`GroundShape.BAND_RADIUS`), so a band-shaped picture stands on a band-shaped body rather than the
disc every shape used to collide as; a narrower row, or a point-drawn one, stays a plain circle.
The width it is drawn is the whole of it either way — the number is half the silhouette, not a
balance value — and `EventInstance._draw_spread` draws a blocking object at exactly the width its
shape reaches, for the same reason in the other direction: a body that disagrees with the picture
is a lie about where she can walk, whichever way it lies.

**The catalogue is not the only thing carrying this datum.** A building's collision is a rectangle
built from `shape.collision_shape()` on `GroundShape.rect(footprint * 0.5)` — `src/city/building.gd`
— the one caller of `GroundShape`'s rectangle kind, since nothing else has a footprint that is not
already a point or a band; and the crowd's walkers and cars each carry a `shape` of their own
(`CrowdAgent.shape`) read for their shadow, though neither has a body — a car's lethality stays the
separate `CAR_STRIKE_HALF_LENGTH`/`CAR_STRIKE_HALF_WIDTH` rectangle `will_be_lethal()` reads, on the
player's own *"lethal != noise"*.

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

### Checkpoints

A region door is solid, like anything else that stands still — `checkpoint_hut` and
`checkpoint_post` at 32px, `checkpoint_gate` at 32px — but it is not a closure. **A door is passable
only by detention, and the toll is the same both ways.** She walks up to a hut or a post, is held
for `Tuning.CHECKPOINT_DETAIN_SECONDS`, and comes out the other side of the crossing, on the same
pavement lane she went in on: `EventManager` reflects her release position through the crossing's
own cross-street line, pushed clear of `detain_radius`, and teleports her there — see
`Stroller.teleport_to()`. Walking round a hut into its own solid body does not open it; the only
way through is the conversation. `checkpoint_hut` and `checkpoint_post` both set `redetains`, so
the same body detains her again on the next approach, from either side — unlike `chatting_mother`,
who is spent after her one conversation.

The gate over the road between a door's two huts costs her nothing at all: it detains no one and
carries no field, and it only ever stops a car — see `docs/CITY.md`, "Regions and the wall", and
`Crowd._stop_for_gates()`.

### Which way a spread lies

`_draw_spread` and `_draw_cafe` lay their segments along local X by default — the right way to
block a north-south street, where the traffic runs along Y and a barrier across it has to span X.
On an east-west street the same default would lie parallel to the traffic and block nothing, so
`EventInstance._spread_is_vertical()` rotates the lay onto local Y whenever the tile it is asked
about sits on a corridor running that way. **It is a property of the street, decided once in
`setup()`, and never a field a row sets** — two rows on the same street face the same way for the
same reason, and `CityMap.corridor_offset` answers it for a `ROAD` or `CROSSING` tile exactly as it
answers it for a `SIDEWALK` one, with no second lookup for either. A junction (both of a tile's
coordinates inside a corridor band) and ground off any corridor at all (a square, a park, a
courtyard) both keep the default lay along local X: neither has one street to be wrong about.

The fallen tree, car accident and burst water main each use one complete street scene.
`EventInstance._draw_wide_scene()` fits the scene to the obstructed span. On an east–west street,
its vertical image and shadow are centred on the event's ground point; the bottom-centred anchor
used for an upright person would shift the whole scene onto the northern pavement.

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
  event with a `spawns_on_finish` stops **where the thing it leaves belongs** (a military convoy's
  barricade is where it stopped, not two streets past it), and anything with no departure speed is
  simply over, which is right for a café that closes.

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

**The pool is narrower than "every tile of the right type" before a single weight is applied.**
`EventScheduler._open_ground_for` refuses four kinds of ground outright, by construction rather than
as a check on what a roll came back with:

- a tile closed today (`CityMap.is_closed`);
- the street the front door opens onto (`_the_street_she_starts_on` — a notch with one exit is not
  a route decision, it is a tax);
- a tile whose street segment is **held** today (`CityMap.is_held_at`) — a hard seal's own segment,
  a region wall or door, or a segment bordering the home block, all in `CityMap.held_segments`; a
  soft seal is not held, since its carriageway is still walkable and a café standing on it is the
  price of that route;
- a tile inside the home block's own lot (`CityMap.is_on_home_block`), the same exemption stated
  the other way round.

None of this is a weight: a closed or held street is not somewhere anyone can get to, or is already
standing for something else, so nothing about the role table below ever sees it. See `docs/CITY.md`,
"Carve alleys" and "Place home", for why the home block's own ground never has an alley to be a
candidate in the first place.

A placement is a roll over every tile of the right type that survives the exclusions above, weighted
by whether the tile is in a precinct and by what the day is placing the thing **for** — its
**role**, in the vocabulary `docs/CITY.md` fixes — against the day's **corridor**, which is the ways
from the doorstep to the calm areas still worth reaching.

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

The role weighting moves *where* the budget is spent and never how much of it there is: the density
placed per day is unaffected by whether the weight is live, and so is the count of lethal rows —
the one the rule could have broken, since a `hard_fail` event must clear its whole outer radius of
everything else with no fallback, and refusing it a quarter of the city could have quietly stopped
placing it. What the weight does move is the split: costly rows land on the corridor far more often
than off it, and lethal rows land on the rim far more often than elsewhere, with the corridor's
share drifting down over the run as it fills up and `EVENT_SPACING_SAME` pushes the overflow
outward. The measurement that established this is in `docs/DECISIONS.md` under M50.

### A set piece is offered on every route and happens on one

The burning building is the only one-shot in the catalogue. Placed like everything else — a legal
spot somewhere on the map, on a day she may never walk that way — an authored set piece that fires
once per run is a fairness contract and a silhouette spent on nothing.

So the day plans it **at every site of a covering set** — `RouteTree.covering_sites`, the smallest
set of streets such that every route touches one — and the placements share a `set_piece_group`.
The first one to enter the world spends the rest, in `EventManager._stream_in`, which is also
where a scar is recorded: a run gets exactly one fire however many streets were offered. The fire
engine is not part of this — it is never scheduled at all, and arrives only once the building it
answers has been seen (`EventDef.spawns_on_sight`, `EventManager._summon_the_sighted_row()`).

Three things this gets right that choosing a site on her route would not:

- **Nothing has to predict her.** The guarantee is structural and holds whichever way she goes.
- **A bundle is not a guarantee.** Two distinct routes to one area share no *cell* by construction
  — a route is a chain of `ReachabilityGrid` cells, and the same-colour rule never lets one probe
  merge into ground the other already coloured. Almost always that also means they share no
  street, so the covering set is usually two to six streets and code that expects one is looking
  for a *tile she must cross*, which the city is built not to have. Rarely, the two routes use
  different cells of the very same street, and one site there covers both after all — the fallback
  a covering set of one is legal ground for, not a bug in either.
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
into an offer**: if it does resolve there, she meets a lethal field and a burning building at once,
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

### The heat

**The city gets worse the further into the resistance you are.** The subquest is optional and it is
also the difficulty dial, so the price of pursuing it is that the place you are pushing a pram
through starts paying attention to you.

`GameState.resistance_progress` is the number — an integer from 0 to `Tuning.RESISTANCE_GOAL`, the
four completed tasks that qualify for the good ending — and `EventDef.heat_response` is the whole of
how a row says whether it cares. `EventCatalogue.heated()` turns a row and a level into a **derived
copy** with its numbers moved, so nothing downstream of the day's plan has to know heat exists: an
`EventInstance` holds whichever copy the day handed it and reads `intensity`, `pursues` and the rest
exactly as it always has.

Three things about that shape are the design rather than the implementation:

- **It is a field, not a switch set per placement.** The same rule the blocking role follows —
  `EventScheduler._role_for` derives a role from the def, so no two placements of one row can
  disagree about what it is. Heat that could be set by hand would be a difficulty dial hidden inside
  the placement code, where nothing could see it.
- **Every shape is validated on load, not just the cold one.** Progress is a bounded integer, so the
  set of shapes is finite and `EventCatalogue.all()` runs the fairness contract over all of them. A
  row that *mutated* mid-run would be checked by `EventDef.validate()` in the shape it booted in —
  the harmless one — and the contract would simply not be stated about the dangerous one.
- **The heat is an argument to the day, not a global it reads.** `EventScheduler.build_day()` takes
  it, so planning a hot day is something a rig can do without a run having happened.

**The ladder has two rungs and only the top one kills.** `PRESSES` never gains `hard_fail` at any
level, and `tests/test_heat.gd` asserts that over the response rather than over the row that
currently carries it.

`abduction`, `night_raid` and `roadblock` all carry `HUNTS`. Below its own threshold,
`Tuning.HEAT_HUNTS_LEVEL`, each is untouched — population and intensity are `PRESSES`'s axes, not
this one's, so neither multiplies nor gets louder as the resistance progresses. At and above it, the
derived copy gains `pursues`, a stand-off inside its own field, and a chase-length `duration` in
place of its idling or static one, and it is `hard_fail`: the van keeps the lethality it already
had, and the raid and the roadblock — each a closed block or a closed street that costs the meter
and nothing more, cold — **gain** it, because the top rung kills by the ladder's own design. A
pursuer is exempt from the rule that nothing else happens inside a lethal event's field — see "The
contract is per event" below.

**`night_raid`'s own threshold is a calendar fact rather than a design one.** Its performs fall on
days 5, 7, 9, 11 and 13, so on day 10 — the only day the row ever appears — the most progress
anybody can hold is 3, `Tuning.HEAT_HUNTS_LEVEL` exactly: the raid hunts *only* a player who has
done every task on time, and a player one task behind meets the cold raid, still a closed block and
nothing more. Sharing the van's threshold rather than minting a third constant is what makes that
sentence true.

**`roadblock` cannot simply gain `pursues` on the body it already has — a band does not chase.** Its
solid picture is a 120px barrier, `_draw_spread` across `GroundShape.band(60.0)`
(`obstructs_radius` 60), and the row's own `inner_radius` had to move from the M61-derived 24 to 86
so that same body still leaves a hunting copy's kill reachable: `obstructs_radius` plus her 14px
`Tuning.PLAYER_BODY_RADIUS` sat over the old 24 by 50px, where `EventDef.validate()` would have
refused it outright. The hunting posture is therefore *guards leaving their post*: the same
`guard_standing.svg`/`guard_lunging.svg` pair the checkpoint kit already carries, drawn by
`EventInstance._draw_roadblock()` the instant the row stops `is_waiting()`, while the band's own
obstruction is freed the same frame by the generic pursuer rule every other hunting row already
uses. The band stays exactly as it is until then, and nothing is left behind once the guards go —
the design says nothing about that interval, and the smaller of the two rules available is to add
none.

**A hunting `abduction`, `night_raid` or `roadblock` is briefly less dangerous than the encounter it
is about to become, and that is the escalation working rather than a bug.**
`EventInstance.is_lethal_at()` returns false for the whole time a `pursues_within` row is only
`is_waiting()`, so a heated van standing at the kerb, a heated raid still parked over its block, or
a heated roadblock still manned can be brushed past for free until she comes inside its own trigger
— the same shape `alley_robbery` already has, now arriving in all three once they hunt.

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
| `cat_dash` | RECURRING (`AHEAD_OF_PLAYER`) | 1 | Crouches (telegraph), then bolts across the traffic. Intensity 17, tiny radius, 1.8s duration — long enough to carry it the whole way across the street it starts at the edge of, and raised from 15 for a sharper startle spike once the barrier fields it used to be judged against went quiet. Its dash, driven straight at a standing player, still projects under `Tuning.EXPECTED_IMPACT_POINTS`, so the crouch's own silhouette carries the warning rather than a caret. Sited at `EventDef.ahead_of_player_lead()` rather than the flat `AHEAD_LEAD_DISTANCE`, which prices in the ground she covers while it holds its crouch, so it crosses where she actually is by the time it moves rather than behind her. The tutorial obstacle. |
| `alley_mouse` | RECURRING | 1 | The cat's shape, `MAP`-placed on `ALLEY` tiles instead of director-sited — an alley she is routed through is already ground she is about to walk, unlike a `ROAD` tile that could be anywhere in the city. Half the cat's intensity (9, on a 60/15px field, the same 4:1 ratio) and half its cap (4), on top of the alley's own `Tuning.EXCITEMENT_FROM_ALLEY` (+3.0/s) ambient dread. No body, nothing lethal. Waits unclocked (`pursues_within` 150px, without `pursues`) until she is close, so a `MAP` placement streamed in from `EVENT_STREAM_RADIUS` does not telegraph and finish off screen before she arrives — see `EventDef.pursues_within` and `EventInstance._check_for_notice()`. Its two-point dash is read off `CityMap.alley_rects` and laid across whichever side of the alley is narrower — always the width, since she can only be walking the length — so it crosses her path rather than running down it (`EventInstance._alley_crossing_path()`). `EventScheduler._refuses_required_alleys`, stated over `def.placement == [ALLEY]` and shared with `alley_robbery`, keeps it off alleys she has no way around. |
| `dog_walker` | RECURRING | 1 | Mobile along the sidewalk at 32px/s — slower than walking, so the ordinary band rule applies. Intensity 26 on a tight radius, barking on a 3.5s pulse: it owns the pavement it is on, so walking straight through it is never the cheap option. Deliberately given no `obstructs_radius` — a moving wall on a two-tile pavement pins the player against a building. |
| `cafe_tables` | RECURRING | 1 | A café spilling out of its frontage, `obstructs_radius` 24px. The first thing in the game that is physically in the way on **day one**, and the thing that forces a crossing. Pleasant, which is worse: nothing about it looks like a hazard and it still costs the street. Stationary, so it can never pin anybody. The people at the tables are drawn as well as the tables, because the tables are what obstructs and the conversation is what it emits — a real source, derived from the body itself: `inner_radius` 38px (touching the tables), `outer_radius` 64px (the pavement band's own centre to the carriageway's), so it bills somebody at the tables and not somebody across the street. |
| `homeless_yeller` | RECURRING | 1 | Intensity 14 over a 210px field, yelling on a 5s **pulse**, and **pacing** eight tiles of pavement (`EventDef.paces`). A fixed source on a fixed patch is a line you draw once; a man walking up and down it is a timing problem on top of a routing one. Mobile, so he has no body. His silhouette is his own — a long coat, a raised arm, a beard, one shape where a passer-by is two. |
| `delivery_van` | RECURRING | 1 | Parked at the kerb, hazards going. Silent: standing in the way is its entire price, and `obstructs_radius` already charges it — see "Solid things are solid". At the kerb rather than on the carriageway, and solid at `VEHICLE_BODY`: 44px of van across a 64px footway is a street that costs the other side. |
| `busker` | RECURRING | 2 | Park and square spoiler. Nothing about it is threatening; it is simply interesting, which is the whole problem. Solid at 11px, which is a man to walk around and not a park closed — see `OBSTRUCTION_A_PARK_CAN_HOLD`. |
| `construction` | RECURRING | 2 | The widest body in act I (`obstructs_radius` `EventCatalogue.SIDEWALK_SPREAD_MAX`, 32px), and the one that leaves no gap: centred on the pavement band it stands on rather than on the tile the scheduler chose, it fills the full 64px of it and forces a reroute rather than inviting one — and since a street is sidewalk\|road\|sidewalk, the road is always still there, so it costs time, never the day. Silent, like `delivery_van`: a hoarding is not a source. |
| `burning_building` | ONE_SHOT | 3 | Placed in a building, `AGAINST_THE_BUILDING`, the way `reversing_lorry` is. `spawns_on_sight` calls `fire_truck` in the moment she first sees it. Burns for the rest of the day, and you cannot walk through the fire. |
| `fire_truck` | — | — | Never scheduled: a SCRIPTED def with no day, created only once `burning_building` has been seen. Drives an arterial at 190px/s with a 340px radius and a 6.27s telegraph (the fast-mover rule over its own forward reach — see docs/MECHANICS.md), entering along the fire's own street from off screen and ending there. |

**And the rest of act I**, which is where its variety and its danger come from — a
neighbourhood's own rather than a patrol's.

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `loose_dog` | RECURRING (`TOWARD_PLAYER`) | 1 | A dog whose owner has dropped the leash, sited on her own pavement when she gets close and running straight down it toward her. The counterpart to `dog_walker` and the reason both exist — that one is a **span** you decide whether to cross the street to avoid, this one is a **thing coming at you** that you cannot out-walk. 132px/s, so it earns a badge at the screen edge and pays the whole-radius telegraph. Not lethal, which is what separates it from `charging_dog`: this one is answered by getting out of the way, not by running. Intensity 32, raised from 24 for a bigger impact once a real meeting is priced against the fixed baseline rather than the barrier fields that used to pin it near the top of the meter regardless. |
| `market_stall` | RECURRING | 1 | The second thing on day 1 that forces a crossing, and it exists because one obstacle repeated eighteen times is a rule rather than a decision. Wider, louder, and on the other side of pleasant than `cafe_tables`: a café you squeeze past is a nuisance, a market is a crowd. A real source too, derived from the body the same way `cafe_tables` is — 38px/64px, the same pair, since both bodies share the same 24px rounding. |
| `leaf_blower` | RECURRING | 1 | The loudest thing in act I, and it is a man tidying a park. Allowed on `PARK` on purpose — a calm block with a leaf blower in it is calm ground she cannot use. Swept in bursts, so there is a rhythm to time a pass through. |
| `pigeon_flock` | RECURRING (`AHEAD_OF_PLAYER`) | 1 | The second thing that happens *to* her, and the reason to have one is that a director with a single trick makes every moment a cat. It is on the pavement for its whole telegraph, then up, then *away* — and it is **eleven birds**, each with its own heading, height and wingbeat, and each an emitter, so the middle of a flock stacks four or five fields and the rim stacks one. The only row in the game that is more than one source. |
| `cyclist` **`hard_fail`** | RECURRING (`TOWARD_PLAYER`) | 2 | **The first thing in the game that can end your day.** A kid on a bike on the pavement she is walking, bell going, coming toward her, down her own side of the road — sited when she gets close rather than on a street the day chose at dawn, so she answers it with a route decision (cross, or turn) instead of finding out too late it was never on her way. Everything about it is ordinary, which is the point: act I does not become sinister, it becomes a real street. The bell rings for 2.97s, what the doubled margin costs at a 90px field grown forward by its own speed — smaller than the fairness contract alone would allow, so the wait before it arrives stays a real reaction window rather than several seconds of watching it close from off screen. Its lethal `inner_radius` is 33px, widened from 26 so the far lane of her own pavement no longer clears it by construction — the same overturn `chatting_mother`'s `detain_radius` went through first. |
| `ice_cream_van` | RECURRING | 2 | The `busker` argument one size up: nothing about it is threatening, it is simply interesting. The widest ordinary radius in act I. At the kerb, and solid at 24px: a thing children cross a road to reach rather than a thing standing in one. |
| `reversing_lorry` **`hard_fail`** | RECURRING | 3 | Act I's second lethal thing, teaching the opposite lesson to the cyclist. That one comes *at* you and the answer is to get off the pavement; this one is **stationary and the danger is behind it**, so the answer is not to walk into the gap it is backing into — which you have to look at the world to know. The beeper is the telegraph. It stands `AGAINST_THE_BUILDING`, turned to face out of the frontage, solid at 28px inside the 46 that ends the day. |
| `charging_dog` **`hard_fail`** | RECURRING (`AHEAD_OF_PLAYER` on `RUN_TAUGHT_DAY`, `MAP` after) | `RUN_TAUGHT_DAY` | **The one thing running is the answer to**, and the day the run is taught. Sited 0.5s of closing outside the view (`offscreen_notice`), it spends `telegraph_time` 4.5s visibly closing at the stand-off, then chases at 130px/s for `Tuning.PURSUIT_TIME` — the further siting needs the longer telegraph so walking away still loses inside the row's own budget. Its 150px field is **wider than the stand-off** — a narrower one is a field the pursuer is never inside, so the warning would emit nothing at her and the `!` over her head would never go up; `validate_pursuit` refuses that. `max_per_day` 3, because a street with three of them turns the run button from an answer into a second walk speed. It trots off at 110px/s rather than blinking out: a dog that gives up in front of her and is then not there says the chase was never real. No `last_day`: it recurs after `RUN_TAUGHT_DAY`, but only that one day sites it on her exact heading — past it, `spawn_mode_on()` answers `MAP` and the row is placed on a tile and met by routing into it, the way `alley_robbery` is, rather than sited by the director — see "Where an event happens" above. |
| `chatting_mother` | RECURRING | 1 | Another mother with a pram, paced along eight tiles of pavement like `homeless_yeller`. Her ambient field is person-scale (intensity 4.5, near a passer-by's 4.2) and tight (56/70px — the inner radius sits just outside her capture, which the catalogue's own check requires), so a normal pass costs a normal close pass. Entering `detain_radius` (48px, three quarters of the pavement band, so neither lane of her own pavement walks past her while the far pavement still does) of an instance that has not chatted yet locks the player's movement input for `detain_seconds` (5s) — the one mechanic in the catalogue that takes the controls away rather than costing a meter; the existing idle rules price the stop, so nothing new prices the time. While the conversation runs and the baby is **awake** it adds a flat `Tuning.CHAT_EXCITEMENT` (25) over the whole capture; **asleep** it adds nothing, gated on the baby's own state read from `EventInstance.baby_awake` rather than scaled through `SLEEPING_SENSITIVITY` — a *pure* time loss means exactly zero, not a smaller number. One conversation per instance: she is then spent as a detainer and departs like a `dog_walker`. |

### Act II — Something is off (days 4–7)

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `police_patrol` | RECURRING | 4 | Mobile, unhurried, along a corridor. Not dangerous yet — the danger is that you start planning around it. |
| `poster_crew` | RECURRING | 4 | Static, weak, and solid at 11px. Cosmetic dread; it is here so the walls change. |
| `loudspeaker` | SCRIPTED | 5 | **City-wide**: no falloff, no edge, nowhere in the city it does not reach. The first event the player cannot walk away from. Pitched under the walking decay, so like a back street it does not raise the meter — it stops you clearing it. |
| `curfew_announce` | SCRIPTED | 6 | City-wide, brief, and fading (`intensity_ramp` 0.2). The mechanical bite is in `Tuning.day_length`, which shortens every day from 6 onward; this is the moment you are told. |
| `roadblock` **`heat_response HUNTS`** | RECURRING | 7 | Loud, and **physically closes a street** (`obstructs_radius` 60), drawn as one continuous barrier (`roadblock_segment.svg`/`roadblock_end.svg`) rather than a row of blocks. The first event that takes a route away rather than making it expensive. Named `roadblock` rather than `checkpoint` because the region wall's own door structure — a hut, a gate and guards you can pass at a price — took that word; the two rows mean opposite things about whether a street can be crossed. Below `Tuning.HEAT_HUNTS_LEVEL` that is all it ever does; at or above it its guards leave the post — the band cannot chase, so the hunting posture is a guard on foot, `guard_standing.svg` then `guard_lunging.svg`, coming at 130px/s once she comes within 180px, `hard_fail` inside `inner_radius` 86. |
| `checkpoint_hut` | SCRIPTED | 7 | `RegionPlanner`'s own structure, not a catalogue roll: two stand at every open region-boundary street crossing, one on each pavement, doorway facing the carriageway. Detains — `detain_radius` 48px inside `inner_radius` 52px — for `Tuning.CHECKPOINT_DETAIN_SECONDS` (6s), and `redetains`, so the same hut tolls her again on a later approach from either side. A small `intensity` (6.0) over a tight 52/66px band is the milestone's own "a bit of excitement" on top of the flat `Tuning.CHAT_EXCITEMENT` the detention charges — the smallest value that still clears "nothing is cheaper to walk through than around" against most of that band held at peak — see "Checkpoints". |
| `checkpoint_gate` | SCRIPTED | 7 | The boom over the road between a door's two huts. No detention, no field — it only ever stops a car, never her. Drawn raised or lowered from the shared `RegionPlanner.GateState` `Crowd` keeps current. |
| `checkpoint_post` | SCRIPTED | 7 | The alley half of a door: one guard at each mouth of a through-alley that crosses a region boundary. Detains exactly like `checkpoint_hut`, same numbers and the same `redetains`. |

### Act III — Disappearances (days 8–11)

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `abduction` **`heat_response HUNTS`** | RECURRING | 8 | An unmarked van idles first — that idling *is* the telegraph, and it runs 4.6s because the inner radius is a `hard_fail`. Getting close does not excite the baby; it takes you. Solid at 22px, comfortably inside the 54 that takes her, so the metal is metal and touching it is still fatal. While she is close enough to watch (`outer_radius`), it draws its own bystander walked to it and taken — a scripted figure rather than a `CrowdAgent`, since the crowd is recycled as she moves and could never be a lasting fact about the world. Below `Tuning.HEAT_HUNTS_LEVEL` that is all it ever does; at or above it, it stops idling for a stranger and starts hunting her instead — 130px/s once she comes within 180px, for the length of the chase rather than the length of the idle, `hard_fail` throughout. |
| `alley_robbery` **`hard_fail`** | RECURRING | 8 | **A man who is worth crossing the road for, and who comes after you if you do not.** Three numbers for three sentences: intensity 16 over a **200px** field, so the far end of an alley is already expensive and the meter is the only warning a robbery will ever give; `hard_fail` inside 30px; and `pursues_within` 140, inside which he takes 1.8s of visibly coming and then chases at 130px/s. The alley is the warning and it is not the only one — a lethal thing that does nothing at all until it does everything is a thing with no telegraph. |
| `night_raid` **`heat_response HUNTS`** | SCRIPTED | 10 | Enormous, static, pulsing, and it closes the block (`obstructs_radius` 44). Below `Tuning.HEAT_HUNTS_LEVEL` that is all it ever does; at or above it, it stops closing the block for the night and hunts her instead — 130px/s once she comes within 180px, and `hard_fail` inside 70px, which the cold raid never is. Its performs fall on days 5, 7, 9, 11 and 13, so on day 10 the most progress anybody can hold is 3: the raid hunts only a player who has done every task on time. |

### Act IV — Open conflict (days 12–14)

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `military_convoy` | RECURRING | 12 | Drives its street and stops where what it leaves belongs: a `barricade`, through `spawns_on_finish`. |
| `barricade` | — | — | Never scheduled directly by the ordinary catalogue roll — `scripted_day` 0 never equals a real day. Two things place it: left where a convoy stopped, and — via `scar_id` — left there for the rest of the **run**; or placed fresh, without a scar, every morning from act IV onward as a **hard seal** on a street off the day's route tree (`SealPlanner`, `obstructs_radius` 62 repeated across the street's whole width so nothing gets past it) — see docs/CITY.md, "Sealing the tree". |
| `protest` | RECURRING | 12 | `intensity_ramp` 1.9 over 150s: a protest you could have walked past when you saw it is not one you can walk past two minutes later. **Solid at 55px**, and `_draw_protest` draws two ranks across exactly that width — the clearest case in the catalogue of the picture deciding a gameplay number, because a body may not claim ground the drawing does not. Under its own 70px inner radius on purpose — the loudest part of a protest is something you stand in rather than bump into. **A rank points at the resistance's own objective**, one of eight `protester_point_*` poses picked by whichever 45° bearing from the protest to the objective is nearest, whenever today's resistance step has a position and is not a chalk mark. *(2026-09-11, the player: "the mark is findable now -- I don't think we need pointing for that. but the other tasks are not as easy and need pointing.")* A mark step, or no step at all, draws the plain rank. `max_per_day` is 12: a protest obstructs nothing off its own tile and pursues nothing, so raising it never competes with anything else's own cap. |
| `firefight` | SCRIPTED | 13 | The worst thing in the catalogue. Extreme, `hard_fail`, 6.5s telegraph, and it shuts a junction. Solid at the width of its cover. Its picture is **people** doing this, not a street on fire — that is a burning building's picture, and the two rows are not the same event. |

The day-14 sabotage is not a catalogue row: it is `GameState` logic (`sabotage_done`,
`sabotage_available()`), gated on the resistance goal rather than sited or scheduled like an
`EventDef`. `docs/NARRATIVE.md` and `docs/DESIGN.md` describe what completing it does.

### Seal pictures — off the day's route tree

Eight pictures so no single barrier is the city's signature (`docs/DECISIONS.md`, M64). Every row below
is `SCRIPTED` with `scripted_day` 0, so — like `barricade` above — the ordinary catalogue roll never
schedules one; `SealPlanner` places each fresh every morning on a street off the day's route tree,
reading `act_tag` for the first day it may. All eight are silent (`intensity` 0): *"static blockages
in general shouldn't increase excitement."*

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `fallen_tree` | SCRIPTED | day 1 | Placed fresh every morning as a **hard seal**: a tapered trunk down kerb to kerb, branching roots at one end and an irregular crown at the other. `obstructs_radius` 96, exactly half the 192px street, so `SealPlanner._hard_positions` places one body spanning it edge to edge. Each street axis has its own continuous scene, selected by `EventInstance._wide_scene_texture`. The picture spans equally to either side of the ground point across the street. On an east–west street its vertical extent is centred on that point too; on a north–south street its bottom edge meets the ground point. |
| `car_accident` | SCRIPTED | day 1 | A **hard seal**: two cars locked together across the carriageway, glass between them and an onlooker on each pavement. The cars follow the street: end views next to one another on a north–south street, side views arranged across an east–west street. Both pictures keep the people upright. Separate shadows ground each car and onlooker without darkening the space between them. The whole scene uses the same single-body geometry as `fallen_tree`. |
| `skip` / `scaffolding` | SCRIPTED | day 1 | A **soft seal**: a skip at the kerb facing scaffolding boards over the far footway — the two-obstacles-facing-each-other reading of a soft seal, drawn as two different pictures rather than one row twice. `skip` is kerb-pinned like `delivery_van`; `scaffolding` fills the whole pavement band like `construction`. |
| `burst_water_main` | SCRIPTED | day 1 | A **hard seal**: broken asphalt, an exposed pipe and water across the carriageway, with an upright municipal barrier at each kerb. The directional pictures place the damage across the street while retaining the barriers' standing projection. Same single-body geometry as `fallen_tree`. |
| `moving_van` | SCRIPTED | day 1 | A **soft seal**: a lorry at the kerb with its ramp down, the same body on each pavement. Its own side and end views show the cab, cargo box, open loading doors and ramp, with the view chosen from the street axis even while the vehicle is stationary. The picture stays distinct from the reversing lorry. |
| `burnt_out_car` | SCRIPTED | day 4 | A **hard seal**, from act II onward: a damaged car shell in the charred palette of `burnt_shell`. The cars lie perpendicular to the road: the side view serves north–south streets and the authored vertical view serves east–west streets. Vehicle-scale `obstructs_radius` lets `SealPlanner._hard_positions` place the individual wrecks across the street as a pile-up. |
| `collapsed_frontage` | SCRIPTED | day 4 | A **hard seal**, from act II onward: rubble spilled frontage to frontage, drawn the way `_burnt_shell` draws `rubble.svg` — a small debris segment repeated by `_draw_spread` — but its own picture, styled beside `rubble.svg` rather than sharing it. |



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
func contribution_at(world_position: Vector2, ...) -> float:
    var velocity := travel_velocity()  # or the override expected_impact_at() passes
    return Tuning.falloff(_field_distance(world_position, velocity),
            current_intensity(), def.inner_radius, def.outer_radius)
```

Because it is a pure query there is no ordering to get wrong, events compose by simple
addition, and an instance can be tested without a scene.

**The field is the Minkowski sum of the body and a kernel.** `Tuning.falloff()` is still the one
arithmetic home and still prices a plain distance `d` — what changed is what `d` means.
`GroundShape.field_distance()` supplies it: `distance_to_spine()` in the emitter's own frame for
a stationary body (a point's field is exactly the circle it always was; a segment's is a capsule
about the spine, so `inner_radius`/`outer_radius` mean distance *from the spine*, not from the
centre), or `eccentric_distance()` for a moving one — a conic with the emitter at one focus rather
than at the centre, per the player's own *"the entity itself lives in one of the focus points"*.
`GroundShape.eccentric_distance()`'s docstring carries the polar form and the derivation;
`Tuning.field_eccentricity()` turns a speed into the conic's own eccentricity, capped at
`FIELD_ECCENTRICITY_MAX` so nothing flattens to a line.

**The ellipse keeps the resting disc's own width, and motion only adds reach ahead of it.**
*(2026-09-10, playtest 55: "while the car moves the field gets narrower and oval -- this is good
but when the car stops it becomes round and bigger? this is counter intuitive. the stretching
should retain the area so an unstretched car field should be the same width with shorter
height" — and, asked to choose between retaining the area and retaining the width, "if anything
the moving size should be bigger than the rest size since moving causes more excitement.")* So the
boundary at the catalogued radius `R` is `r(θ) = R / (1 − e·cosθ)`: exactly `R` abeam whatever the
speed, `R · Tuning.field_scale(e)` (`R/(1−e)`) dead ahead, `R/(1+e)` behind. `field_scale()` is the
one function that states the growth, beside `field_eccentricity()` itself; a car at `CAR_SPEED.x`
(130px/s) sits at `e` = 0.26, forward reach 1.35R and rear 0.79R, and the eccentricity cap
(`FIELD_ECCENTRICITY_MAX` 0.5) holds every field in the game to at most twice its own catalogued
radius ahead of itself — `FIELD_ECCENTRICITY_SPEED` is chosen so nothing catalogued reaches it: the
fastest mobile row sits at 0.48.

**Moving objects are points.** The two kernels compose — body ⊕ disc standing still, point ⊕
ellipse moving — without ever building the general capsule-and-ellipse sum, because every emitting
segment row in the catalogue is stationary (`tests/test_shapes.gd` holds this as a regression
guard) and everything that moves in the catalogue is small enough to be a point already: the cat,
the loose dog, the cyclist, a flock's own birds and every pursuer. `CrowdAgent`'s walkers and cars
are the same — always points in field terms, moving or not, off `velocity()` rather than a shape of
their own — which is what keeps a car's horn jolt and a walker's bump jolt reading as the same
source being louder rather than a second falloff with its own idea of where the source is.

The debug view's fields layer (`DebugLayers`, `1`) traces the exact boundary
`GroundShape.field_outline()` computes from the same arithmetic, so a screenshot of a field cannot
disagree with what the meter does — see docs/TELEMETRY.md, "The debug view".

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

**The contract is stated over the spine-measured band and the row's own forward reach**, which is
larger than the catalogued `outer_radius` for anything that moves. `outer_radius − inner_radius` is
a band width, and subtracting a segment's `half_length` from both radii (see "Solid things are
solid") leaves that width untouched; every emitting segment row is stationary, so its own forward
reach never grows past `half_length + outer_radius`. For a moving point — a cat, a dog, a cyclist, a
pursuer — the escape she is owed is stated over `outer_radius · Tuning.field_scale(e)` (a full
forward-reach clearance for a row faster than a walk) or `(outer_radius − inner_radius) ·
Tuning.field_scale(e)` (a band clearance for a slower one), `e` from the row's own `speed` or
`pursue_speed`: `Tuning.required_telegraph_time()` and `Tuning.validate_pursuit()` are the two
places this is stated, and every row in the catalogue whose forward reach grew past what its
telegraph already bought had its `telegraph_time` re-derived — never its radii — to the new minimum
plus the margin it already carried. What changes for a "how far" rule that reads `outer_radius`
alone rather than a band width — the lethal clearance a placement keeps, the streaming radius,
`expected_impact_at()`'s early-out — is `EventDef.field_reach()`: a segment's along-axis reach
unchanged, or a moving point's own forward reach.

### The contract is per event, and the player experiences the sum

`validate_event()` checks each row in isolation. At one event per block the outer radii routinely
overlap — `firefight` alone reaches 374px against a 448px block period — so **walking out of one
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

Two cases are exempt, and both are about the field having no fixed place to keep clear of
anything. **Off the day's corridor**, where the whole point of the ground is that she should not
be on it, so an overlapping lethal field there is the city saying so rather than a fairness
failure — `EventScheduler._role_for` gives such a placement the `WALL` role, and
`_keeps_its_field_clear` reads that role directly. **A pursuer**, because it follows her rather
than sitting on a tile the day chose, so there is no ground for the rule to be stated about —
`charging_dog`, `alley_robbery` and a hunting `abduction`, `night_raid` or `roadblock` all carry a
lethal radius with them wherever she is, and `EventScheduler._keeps_its_field_clear` says so by name
rather than leaving it to follow from the `WALL` case by coincidence.

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

| Event | walk through | run through |
| --- | ---: | ---: |
| `loudspeaker` | — | — |
| `curfew_announce` | — | — |
| `construction` | −15.2 | +32.1 |
| `delivery_van` | −11.4 | +24.1 |
| `barricade` | −9.1 | +19.3 |
| `burnt_shell` | −2.7 | +14.3 |
| `poster_crew` | +0.7 | +22.6 |
| `alley_mouse` | +4.2 | +14.5 |
| `cafe_tables` | +9.6 | +18.2 |
| `market_stall` | +12.0 | +19.5 |
| `busker` | +13.3 | +45.7 |
| `police_patrol` | +15.9 | +46.2 |
| `charging_dog` * | +16.9 | — |
| `cyclist` * | +20.9 | +29.7 |
| `cat_dash` | +24.1 | +37.5 |
| `playground` | +25.5 | +44.3 |
| `checkpoint` | +29.0 | +59.4 |
| `homeless_yeller` | +31.2 | +59.6 |
| `ice_cream_van` | +31.5 | +65.8 |
| `reversing_lorry` * | +32.6 | +53.3 |
| `alley_robbery` * | +34.6 | — |
| `dog_walker` | +36.5 | +41.2 |
| `protest` | +42.3 | +77.6 |
| `leaf_blower` | +48.6 | +67.1 |
| `pigeon_flock` † | +54.1 | +63.6 |
| `burning_building` | +55.9 | +83.2 |
| `loose_dog` | +61.2 | +61.9 |
| `abduction` * | +61.3 | +84.1 |
| `military_convoy` | +84.9 | +107.2 |
| `night_raid` | +101.8 | +122.6 |
| `fire_truck` | +115.4 | +132.0 |
| `firefight` * | +152.4 | +159.2 |

**No column says which rows carry a caret, because no row does.** The caret is decided in play
from a source's own projected course at wherever she is standing — `expected_impact_at()`
against `Tuning.EXPECTED_IMPACT_POINTS`, `will_be_lethal()` for the doubled red — so the same
row reads red on one approach and carries nothing on another, and a stationary row never
carries one at all; see "Showing the danger".

**The pursuers' run-through column is empty, and that is the point:** they **follow**, so there is
no crossing to price and no line to run along. Walking away from either loses the day; running away
costs 35 points from the lunge and less the sooner it is given. See `docs/MECHANICS.md`, "Running
that matters", for the measured tables. The city-wide rows have no line through them at all, which
is why `EventDef.walk_through_cost()` answers zero for them and this table says nothing.

**One row is cheap to walk through by taste, and every zero-intensity row is cheap by
construction.** `burnt_shell` and `poster_crew` are scenery asked to be nearly free on purpose —
`tests/test_events.gd` names them as the sole exemptions among the rows that emit anything at all.
`construction`, `delivery_van` and `barricade` sit well below zero for a different reason: **a
thing whose whole job is to stand in the way costs route and nothing else**, so `intensity <= 0.0`
is its own blanket exemption — walking "through" a solid body was never a real choice to price, and
the negative figure is what `walk_through_cost()` answers once nothing at the centre is left to
outweigh the walking decay. Everything else — every row that still emits — must be more expensive
to walk through than to walk around, or the correct play is to plough into it. A new zero-cost row
is a decision about what a thing is (a pure obstruction) rather than a number nobody checked; a new
*positive* exemption is the one that still needs naming by hand.

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

**No entity is ringed for danger, and that is a standing decision rather than a style.** The
reason is worth keeping rather than merely acting on:

> A ring communicates a falloff radius, which is a number. A silhouette communicates a threat.
> How dangerous a thing is should be visible from looking at *the thing*.

The second half of that is what decided the shape of the vocabulary below. A ring also cannot cover
the field it is drawn for: a crowd agent has no def to ring, and a `city_wide` source has no edge to
draw, so on a normal street a few things would be ringed, most would not, and nothing would explain
the difference. **A cue that marks everything says nothing**, and every rule below exists to keep
the replacement from becoming that.

**One row in the table below draws a ring rather than a circle, and it answers questions the rest
of this vocabulary never had a cue for.** *Asked for no rings and no drawn fields, held since this
vocabulary was written · overturned on 2026-09-07 for the "Entity halo" row only, because the
player asked for exactly this:* "it should use the outline of the sprite. that's why it needs to be
a shader. or draw the sprite in a uniform color multiple times." The reasoning quoted above is about
*danger* — what a thing will do to you — and stays true of every other row here: nothing is ringed
to say how bad it is. The halo answers two different questions instead, one per axis:
*which of these things is charging the meter right now* and *how much has this one actually cost
her.* **It traces each entity's own silhouette rather than any radius drawn from a def.**
*(2026-09-07, the player: "halo meaning only the outline of the object not the influence radius ...
the halo should not extend more than a few pixels beyond the object's outline.")*
`EntityHalo` re-runs the entity's own `_draw_body()` at a ring of twelve offsets,
`HALO_MARGIN` (4px) out, so a busker's rim is its own 11px body and a barricade's is its own run of
segments — a shape a circle could never draw for either of them.

**A field-sized halo, then a circle sized off `obstructs_radius`, were each built and rejected on
screenshots before this one.** The field spanned `EventDef.outer_radius` (up to 200px against a
640x360 view) and painted most of the frame whatever brightness curve sat on top of it; the circle
fixed the footprint but was still a number's shape rather than the thing's, and a barricade's own
circle read smaller than the barricade the moment a ceiling was tried to stop a busker's from
swallowing the street.

**Brightness and colour both answer "how much has this actually cost her", on two different
curves, and a second played session is what settled that.** *(2026-09-07, the player: "the color
of the halo should be determined by the absolute magnitude with red being strong and light yellow
being weak and the faseout should be by the fraction of its value ... the intensity of the halo
states how far away I am. the color should state how dangerous it is.")* That first answer put
brightness on distance, and the same player overturned it the next session, once magnitude was
being tracked at all: *(2026-09-08: "the transparency shouldn't show distance since distance
actually doesn't matter. only the actual received amount counts ... this frees up transparency for
also encoding magnitude. color and transparency shouldn't be the same number. transparency can be
used to emphasize low values.")* `ExcitementHalo.colour_for()` is linear over `landed()`, pale to
red by forty points; `ExcitementHalo.magnitude_for()` is the same `landed()` on a curve that rises
fast and saturates by fifteen points, so a point or two already reads as a faint rim while colour
is still climbing — transparency carries the low end, colour carries the difference between
fifteen and forty. Both channels ease toward whatever they are last told over
`EntityHalo.FADE_IN_SECONDS` (0.3s) / `FADE_OUT_SECONDS` (0.8s) rather than jumping, *(2026-09-08,
the player: "all changes should transition (hue and transparency) instead of immediately showing
the actual value".)* so a burst brightens and reddens together and drains together rather than
switching on and off.

**Colour is points that actually reached the meter, traced from the meter's own sum rather than
recomputed.** *(2026-09-08, the player: "don't derive it from the source numbers but trace an
increase in excitement back to its constituents. if a honking car caused 35 excitement to the
player that's the number that informs the color of the halo. with 1/3 of the bar that's pretty
red already".)* `Baby._update_excitement()` is where the meter is fed, so it is where the
attribution happens: `WorldContext.excitement_sources_at()` returns every live source's own share
of what is about to land, and each one's `accumulate_landed()` gets exactly that share —
sensitivity included — rather than the halo pass recomputing anything from `contribution_at()` on
its own. `ExcitementHalo.colour_for()` is a pale-to-red ramp (`Palette.HALO_WEAK` to
`Palette.HALO_STRONG`) over `landed()`, a true five-second sliding sum of those shares — not a
decayed average, so a 35-point burst reads as 35 for the whole window and then drops — saturating
at `Tuning.EXPECTED_IMPACT_POINTS` (40 of the 100-point bar, the same line the caret goes amber at
read the other way round). A protest she skirted the edge of and a protest she walked through are
the same row and correctly different colours.
`EventInstance.set_halo_strength()`, called by `ExcitementHalo` once a frame, is what carries both
numbers to the shader. `.claude/skills/cues/SKILL.md`, "A glow, not a field" is the narrow version
of this exception, kept narrow enough to still refuse the next ring somebody wants.

**The candidate set is every live event and the whole crowd — every walker and every car, not
only a startled body.** *(2026-09-08, the player: "a busy street is noisy because of cars and a
busy sidewalk is noisy because of people ... that will allow us to attribute the source
exactly".)* The tabled question this answers — "The crowd has a halo" in `docs/TODO.md` — offered
three shapes and none of them is this one: the crowd is not a floor to fold into events, not one
combined outline, and not gated on a higher threshold. `ExcitementHalo.select_sources()` takes an
untyped candidate array rather than one typed to `EventInstance` — a duck type, documented on
`ExcitementHalo` itself since GDScript has no interface to lean on — so `Crowd.agents()` and
`EventManager.instances()` are offered on the same terms. `CONTRIBUTION_FLOOR` and `MAX_SOURCES`
(the eight strongest) are what keep a busy pavement legible rather than a special case admitting
only the caret-worthy.

Four cues, four sentences, each decided by one quantity — and the same two numbers, the points a
source lands on the meter and the five seconds either side of now, carry all of them:

- **Caret**: *stand here and this will cost you* (amber), or *end your day* (doubled red).
- **Halo**: *this is costing you now, and this much.*
- **Exclamation over the player**: *the clock on you has started.*
- **Badge**: *something lethal or faster than a walk is coming, and this is what.*

| Cue | Means | Where |
| --- | --- | --- |
| **Legible entity** | The thing itself reads as what it is: a crouched cat, an idling van, a scaffold, a burnt shell. **This carries most of the load, and everything below is for what it cannot carry.** It is a rule with a test rather than an aspiration — one picture per row, no two rows sharing one. See point 6 below. | the art, one `EventDef.Look` per row |
| **Caret over the entity** | *Stand here and this will cost you*, or *end your day.* Raised by what the thing is **projected to do to her, her position held still**, and by nothing else — see point 1 below. | `Sprites.draw_caret()`, from `EventInstance._draw_mark()` and `CrowdAgent._draw_mark()` |
| **Its colour** | **Amber** at `Tuning.EXPECTED_IMPACT_POINTS` expected over the horizon — go round it. **Deep red, doubled**, when a step of the projection puts her inside the thing's lethal reach on its current course — it ends your day. The same points the halo reads, read forward instead of back. | `EventInstance.mark_colour()`, `CrowdAgent._caret_strength()` |
| **Its flash** | *It has not started yet.* The telegraph phase, and the only channel carrying it — the colour cannot, because a telegraph is usually over before the event is on screen, so an amber that meant *telegraphing* would only ever be seen on the rows sited in front of the player and would read as *near*. | `EventInstance._draw_mark()` |
| **Breathing** | The caret's size and ride height track *current* emission, so a pulsing event visibly swells and settles and can be timed. A car with no jolt running holds full size, having no pulse of its own to breathe with. | `EventInstance.mark_swell()`, `CrowdAgent._draw_mark()` |
| **Entity halo** | *This is costing you now, and this much.* A thin rim hugging the thing's own silhouette — its own sprite re-drawn a few pixels out in a ring of offsets, never a radius — for every live event and every startled crowd body (a honking car, a bumped walker) whose `contribution_at()` at her own position clears a floor. **Colour** is pale-to-red, linear over what it has actually delivered to her in the last five seconds; **transparency** is the same five-second total on a curve that saturates by fifteen points, so it carries the low end colour cannot show yet. Both fade in and out over a third and four fifths of a second rather than switching. Drawn under the entities, the crowd and the player, and gone the instant she is out of reach of every candidate at once. | `ExcitementHalo`, `EntityHalo`, `assets/shaders/excitement_halo.gdshader` |
| **Edge badge** | *Something lethal or faster than a walk is coming, and this is what.* Off-screen and closing **under its own steam**: a disc at the screen edge carrying the thing's own silhouette, a chevron pointing at it and the distance. Says *what* is coming, not that something is. | `DangerEdge` |
| **Exclamation over the player** | *The clock on you has started.* A `hard_fail` event still telegraphing whose radius covers her, or a car closing on the lane she is standing in. Down the moment it stops being true. | `Stroller._draw_alert()` |
| **Doubled red over the player** | *The clock on you has started, and it is nearly out.* Something lethal is live, she is within `LETHAL_MARK_LEAD` seconds of the radius that ends the day, **and the gap is closing at the speeds in play**. Not *inside the outer radius*, which for a cyclist is thirty times the area that can hurt her and stays true while the bike rides away. | `EventManager._warn_about_the_ground_she_is_on()` |
| **zzz over the pram** | *The baby is asleep* — the return phase, and the state with the most consequence and the least presence on screen. Flashing instead of breathing: *she is stirring*, and waking costs half the sleepiness bar. | `Stroller._draw_baby_cue()` |
| **Waves over the pram** | *She is not settling* (amber, at the calm threshold, where the day stops progressing) and *she is nearly crying* (red, three of them, flashing). | `Stroller._draw_baby_cue()` |
| **HUD line** | For a `city_wide` source, which has no position and therefore nothing to stand under. | `hud.gd` |
| **Sound lines** | Concentric arcs thrown off a source on the rising edge of a pulse — the visual form of a discrete noise (a yell, a bark, a beep, a siren whoop) | not built; queued in `docs/TODO.md` |

**Nothing is ringed for danger, and that is the rule.** It is a standing decision rather than a
preference: if something new needs signalling, reach for one of the rows above; if none of them
fits, that is a design conversation and not a licence to draw a radius. The one ring in the
table — the entity halo — is not that licence exercised again, and the reason is its shape: it is
one cue, for the cost being charged right now, traced from the thing's own silhouette and nowhere
near a radius that thing reaches. It leaves the caret, the badge and the exclamation mark meaning
exactly what they meant before it existed.

Three rules underneath the table, in the order they matter:

1. **The caret is raised by expected impact, and by nothing else.**

   *(2026-09-08, the player, closing the fork this rule used to leave open: "carets shouldn't be
   chosen by source value but by expected impact value".)* What a row is declared to cost on
   paper decides nothing; what a source is actually projected to land on her, from wherever she is
   actually standing, does. `EventInstance.expected_impact_at()` and `CrowdAgent.expected_impact_at()`
   extrapolate the thing's own current velocity in quarter-second steps over
   `Tuning.EXPECTED_IMPACT_HORIZON` (5s), sample its field at her *current* position at each step,
   sum the points, and subtract its present rate times the horizon — so a stationary thing she is
   standing in front of expects nothing, an approaching thing expects its approach, and a
   departing one expects less than nothing and is unmarked. **Amber** at
   `Tuning.EXPECTED_IMPACT_POINTS` (40, the same line the halo saturates red at); **doubled red**
   when a step of the same projection puts her inside the thing's lethal reach — a `hard_fail`
   row's `inner_radius`, a car's strike box — on its current course. `tests/test_danger.gd` holds
   the scenarios this replaces the old catalogue-wide rule with.

   **Her stillness is the direction the whole rule turns on.** *(2026-09-08, the player: "I don't
   want a caret when walking into a car from the side".)* Projected with her held still, a car
   passing wide of her is never in its own path and carries no mark; one she is standing in the
   lane of is projected straight into her.

   **The trap it is written against** is a rule like *danger that changes over time* — lethal,
   telegraphing, swelling, or pulsing fast enough to be timed. Every clause of that is a true
   statement about a thing and **none alone says what it will do to a standing player**. A fire
   engine on a course that misses her may carry nothing; a stationary burning building uses its
   silhouette and active-cost halo, not an approach caret.

   **A cue that marks everything says nothing**, so the ordinary crowd at ordinary density is left
   alone — measured on the arterial, not argued: a crowd at ordinary busyness around a standing
   player raises no amber caret at all.

   What this gives up, as a decision rather than an oversight: **`cat_dash`, dashing at a standing
   player, carries no caret**, because its projected landing on her stays under the line —
   `tests/test_danger.gd` holds this scenario by name. The crouch is its own silhouette and the
   vocabulary's first row is that the entity carries it.
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

   **A vehicle needs two pictures the moment it can face more than one way.** One side-on sprite
   mirrored east and west shows a patrol car heading north its own flank. `police_patrol`,
   `fire_truck` and `military_convoy` travel from the moment they are placed and have an `_end`
   picture each; `abduction` earns its own the same way once it hunts, since a pursuer steers
   straight at her and a parked van never had to face anything but the kerb. `night_raid` hunts
   on the same rung and has no end view yet — the one open exception to this rule, filed in
   `docs/TODO.md` under M56. Each is *its own*
   picture rather than the crowd's (whose cars are end-on because at that angle the front and the
   back of a car are the same shape): the whole content of a vehicle row is which vehicle it is,
   and a van that becomes a generic box the moment it turns north loses the one silhouette the
   badge exists to show at the moment it starts coming towards her. The **badge keeps the side
   view**, because an icon is read at 40px against a row of other icons and a vehicle end-on is a
   box at any size.

**The traffic pays for its own warning.** The vocabulary's first row is *the entity itself carries
most of it*, and the traffic is the place that is easiest to miss: the caret is drawn by
`EventInstance`, and a car is not an event. A lethal thing bearing down on the player that produces
a mark over **her** head and nothing anywhere else is the load-bearing cue paying for a warning it
should only be adding to. The horn cannot carry it either — a horn is silent in a game with no
audio, which is *"audio is never the only channel"* failing in the one place the traffic fairness
contract depends on it. So a car whose projected course reaches her carries the same caret a
`hard_fail` event does, in the same two strengths, and the honk is a **consequence** of that rather
than the rule it follows: `Crowd._horn()` still sounds at closer range than the caret needs, so a
car can be marked before it has honked, and the mark breathes with the horn's own decay while one
is running. The shape lives in `Sprites.draw_caret()` so there is one chevron rather than two that
slowly stop being the same chevron.

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
3. Decide `spawn_mode` deliberately — `MAP` unless the entire content of the thing is *the moment
   it happens to you* (`AHEAD_OF_PLAYER`) or *a road she has to answer with a route decision*
   (`TOWARD_PLAYER`).
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
