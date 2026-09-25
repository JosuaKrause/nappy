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
| `core_intensity` / `core_radius` | A louder inner part of the same field, both `0` for every row but `leaf_blower`. The same curve over the shorter band `inner_radius`..`core_radius`, and the row's price is **the larger** of the core and the field — see "The emission model" |
| `falloff_power` | The exponent on the drop between the two radii: `intensity * (1 - t ** falloff_power)`. `2.0` is the curve every number in this document was measured at; under 1 drops fast and tails long, over 2 holds near full and then falls off a cliff. Nothing sets it |
| `duration` | Seconds active (`0` = whole day) |
| `telegraph_time` | Seconds of visible warning before full intensity |
| `pulse_period` | Seconds per intensity cycle (`0` = constant) |
| `mobile` / `speed` | Whether it moves along a path, and how fast |
| `still_while_telegraphing` | Holds position until the telegraph is over, then goes. Default off, which is right when the telegraph *is* the approach; on when it is a posture — see the cat, below |
| `spawn_mode` | `MAP` (sited when the day is planned) or `AHEAD_OF_PLAYER` (sited in front of her, while she walks) — see "Where an event happens" |
| `spawn_mode_switches_after_day` / `spawn_mode_after_first_day` | For a row whose siting changes once its first appearance is over: `spawn_mode_on(day)` answers `spawn_mode` through that day and `spawn_mode_after_first_day` past it. `0` (the default) means never — `spawn_mode` alone answers for every day. `charging_dog` is the one row that sets it: `AHEAD_OF_PLAYER` on `RUN_TAUGHT_DAY`, `MAP` after |
| `departs_at` | How fast it removes itself when it is over (px/s). **Nothing vanishes while you are looking at it** — see "Going away". Anything `mobile` leaves at its own `speed` and needs no value here |
| `pursues` / `pursue_speed` | Comes after **her** rather than along a path, at a speed strictly between a walk and a run. The one thing running is the answer to — see `Tuning.validate_pursuit` |
| `pursues_within` | How close she has to come before it takes an interest. `0` is *immediately*, which is a pursuer that is a **moment**; anything else is a **place** until she walks up to it, and its telegraph and whatever follows are both measured from when it notices. Wider than its name: a row that sets it without `pursues` waits the same way and then runs its own event instead of chasing her — `alley_mouse`, `pigeon_flock` |
| `quiet_until_noticed` | Whether the wait and the notice emit `Tuning.TELEGRAPH_INTENSITY_FRACTION` of `intensity`, as an ordinary telegraph does, rather than the full rate a waiting pursuer carries. `false` is the default and is right wherever the thing standing there *is* the threat; `pigeon_flock` is the row it exists for, since birds pecking are nearly nothing and the event is them going up. `validate()` refuses it on a row with no trigger to be noticed at |
| `pursues_within_after_first_day` | What `pursues_within_on(day)` answers past `spawn_mode_switches_after_day` — the same day-keyed switch, read for the trigger rather than the siting. `0` (the default) is unread while that switch is `0`. `charging_dog` is the one row that sets it: `0` through `RUN_TAUGHT_DAY`, 130px past it (inside its own 150px `outer_radius`, an "on sight" band before it decides, `alley_robbery`'s shape) so a `MAP` placement waits for her instead of announcing itself the moment it streams in — see "Where an event happens" |
| `paces` | Walks its route and turns round at the ends, for ever. The difference between a journey and a **beat** — see `homeless_yeller` |
| `obstructs_radius` | The reach (px) of the row's own `shape` — a `GroundShape`, and the body is that shape, not a second number. **A thing that stands still is solid at the width it is drawn** — see "Solid things are solid" |
| `solid_once_it_starts` | Whether the body arrives at the end of the row's own notice rather than with the instance, and is withheld while she stands in the footprint. For a row that turns on where she may already be — `basement_steam` is the only one — see "Solid things are solid" |
| `pavement_side` | Which lane of a two-tile pavement it wants: `ANY`, `AT_THE_KERB`, `AGAINST_THE_BUILDING` |
| `hard_fail` | Whether contact ends the day immediately |
| `lethal_radius` | How close the thing that ends the day has to get, when that is **not** the field's own core. `0` — almost every row — means `inner_radius`, and `lethal_reach()` is what every caller asks. It exists for a row whose killer is not what the field is drawn around: a `roadblock`'s field is cored on the barrier and its guard catches at a man's reach — see "The heat" |
| `body_stays_behind` | Whether this row's body is a **fixture of the street** a pursuer leaves standing rather than the pursuer's own bulk. Every other pursuer's body comes down the frame it starts hunting; a roadblock's barrier is pinned where it was built, so the street stays shut behind the man who left it |
| `redetains` | Whether a `detain_seconds` row is armed again once she is released and outside `detain_distance()`, rather than spent after one conversation. `false` for everything but the two region-door rows that inspect her, `checkpoint_hut` and `checkpoint_post` — see "Checkpoints" |
| `sets_off_beside_her` | Whether a pursuer starts **inside its own stand-off**, spawned beside her rather than sited or noticing her outside it. Its notice then cannot be cut short by her being close and it never backs off: it holds its ground, follows at the stand-off once she is further, and chases when the notice has run its whole length. `door_guard` is the one row — see "Checkpoints" |
| `lifts_for_traffic` | Whether this row is a **boom**: a bar across a door's carriageway that the cars raise and lower, solid to her only while it is down, and never an inspection. `checkpoint_gate` is the one row — see "Checkpoints" |
| `barrier_structure` | Whether this row is a piece of the region boundary — a street being held. The four that are (`checkpoint_hut`, `checkpoint_gate`, `checkpoint_post`, `roadblock`) charge the meter as **one** source, the strongest at her position, rather than as their sum; everything else in the catalogue still sums — see "Checkpoints" |
| `heat_response` | How the row answers to the resistance: `NONE`, `PRESSES` (more of them, more expensive, and past half way it comes over), `HUNTS` (it stops being a place and starts being a hunter) — see "The heat" |
| `look` | Which picture it draws. **One per row, and no two rows share one** — see "The visual vocabulary", point 6 |
| `shape` | The row's own `GroundShape` (`src/ground_shape.gd`) — a point or a segment, independent of the picture — that its shadow and, when it obstructs, its collision body are both derived from. Set by `EventDef.solid(shape)` for anything with `obstructs_radius`, or directly for anything with a `look` that does not obstruct; `null` only for `look == NONE` — see "Solid things are solid" |
| `draws_body_shadow` | Whether `EventInstance._draw_body_shadow()` puts anything down for this row. `true` for every row but `burst_water_main`, whose crater is sunk into the road rather than standing on it |
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

**`AHEAD_OF_PLAYER`, which is the cat and the day-3 charging dog.** No tile. The day
budgets it at the same cost as everything else, and `EventDirector` sites it while she is walking. A
crossing row — the cat — is sited across her line, `AHEAD_LEAD_DISTANCE` in front of her.
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

**And a `MAP` placement's own dog waits for her.** *(2026-09-13, PLAYTEST-68: "The waiting is
good. But we can sprinkle the day 3 charging dog in every now and then, too.")* Day 3's dog carries
no `pursues_within` — the lesson depends on it charging the moment it streams in, and
`tests/test_danger.gd` pins that — but a row placed on a tile past the teaching day would otherwise
begin its charge the instant it streams into `Tuning.EVENT_STREAM_RADIUS` (900px), past the edge of
the view, rather than when she comes inside its own field. `EventDef.pursues_within_on(day)` is the
same day-keyed switch answered a second way: `0` through `RUN_TAUGHT_DAY`, 130px past it — inside
its own 150px `outer_radius`, an "on sight" band before it decides — so a dog she can see is a dog
she can route around, `alley_robbery`'s shape. Nothing mutates the shared def:
`EventScheduler._for_day()` hands a `MAP` placement past the switch a copy carrying the day's own
answer, the way `EventCatalogue.heated()` hands a placement a copy carrying a heat level's.

**And a flock is a place for the same reason, with the same wait.** *(2026-09-13, PLAYTEST-69:
"pigeons pop in on screen — they should exist before they are visible.")* `AHEAD_LEAD_DISTANCE`
(184px) is inside the 320px half-view sideways, which a cat can afford — its whole content is the
three seconds it is there — and eleven birds cannot: a flock is a *patch of pavement*, and a patch
of pavement that was not there a second ago is not one anybody can plan around. `pigeon_flock` is
`MAP`-placed on sidewalk, square and park, so the birds are pecking about from the moment the day
streams them in, and `pursues_within` 150px — inside their own 168px field, more than twice the
62px wheel — is when they go up. The telegraph is then paid in geometry exactly as the robber's is:
1.7s of a flock on the ground about to go, starting when she is near rather than at dawn.

**And a flock's wait is quiet, which is the one place the waiting rule flips.** A pursuer that
waits emits at full strength undamped — a man standing in an alley has started, and what has not
started is the lunge — but birds pecking on a pavement are nearly nothing and the event *is* them
going up. `EventDef.quiet_until_noticed` is that distinction as a field: with it, the wait and the
notice both emit `Tuning.TELEGRAPH_INTENSITY_FRACTION` of `intensity` the way an ordinary telegraph
does. Without it a flock nobody had walked up to yet would charge its full rate all morning, which
is a place that cannot be walked past rather than one that can be walked around.

**And the day-3 shape does not retire.** Past the teaching day, `EventDirector` now and then still
sends the same unmodified def off her heading — `Tuning.CHARGING_DOG_SPRINKLE_CHANCE`, rolled once a
day in `EventDirector._owe_the_sprinkled_dog()` — already noticing her, no tip, unguaranteed. The
lesson's dog and the later dogs are one animal; the guarantee and the tip are the whole of what
`RUN_TAUGHT_DAY` still buys.

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

**A `TOWARD_PLAYER` row whose `placement` names `ROAD` runs down the carriageway instead of her
pavement.** `police_patrol` is the one row that does: `EventDirector.owe_the_return()` hands the
return leg a few extra copies of it in acts III and IV, sited `TOWARD_PLAYER` by
`_toward_her_on_the_road()` rather than `_toward_her()` — the same offscreen margin and the same
"straighten onto the corridor's own axis" idea, but the lane it straightens onto is
`CrowdLanes.road_lane()`'s own carriageway lane, driving opposite her heading so it meets her, on
tiles `CityMap.is_driveable_at()` actually calls a road. Empty wherever there is no carriageway to
drive on — a park, a square, a precinct — the same "retry later" the rest of the director's siting
already does. The copy this hands out is its own duplicate, never the shared, cached row every
ordinary `MAP` placement of `police_patrol` reads (`EventCatalogue.heated()`): only its `spawn_mode`
differs, so the row's cost and picture are exactly the ones the day's own plan already uses.

### The return owes her patrols

**The streets that go quiet from act III on get something back, on the walk home.** The crowd
table empties them on purpose — see `docs/MECHANICS.md`, "the cruellest number in the game" — and
the return phase (`DayPhase.RETURNING`, entered the moment the baby falls asleep) is the one
stretch of a day nothing in the catalogue was ever pacing for. `Tuning.RETURN_PATROLS_PER_ACT`
(`[0, 0, 2, 3]`, one entry per act) is what `EventDirector.owe_the_return()` adds to the owed
queue the moment `EventBus.return_phase_started` fires, at the day's own heat — the same heated
`police_patrol` copy the day's other plans of that row already use — and from then on the queue
rolls `Tuning.RETURN_PATROL_INTERVAL` (9–16s) instead of `Tuning.AHEAD_INTERVAL` (11–26s) for the
rest of the day, so the extra rows have a real chance of landing inside a 33–47s leg rather than
after she is already home. Acts I and II carry nothing, so the teaching days and the return she
learns the mechanic on stay exactly as they were measured.

It is owed exactly once a day — a baby that wakes and settles again does not owe a second batch —
and the rows already owed stay owed if the phase drops back to `WALKING`. `--force` leaves the
forced queue alone: there is no ordinary queue under it for this to add to or re-pace.

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

**The margin applies to what travels toward her, not to a crossing.** `cat_dash` keeps
`AHEAD_LEAD_DISTANCE` / `EventDef.ahead_of_player_lead()`: a crossing row's whole content is a
three-second interruption she reacts to as it happens, not an approach she watches close, so there
is no "closing speed" for the margin to be stated over. **Chosen as the smaller reading of a
silence** — the instruction named "events that go towards the player", not every director-sited
row, and a crossing already pays its own fairness in the reaction-window rule above rather than in
an offscreen phase. The other way out of the same trade is to stop being director-sited at all,
which is `pigeon_flock`'s: a row on a tile is streamed in from `EVENT_STREAM_RADIUS` and is never
sited against the view in the first place.

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

**A row may be solid in parts, and one is.** `EventDef.solid_parts` is a list of pieces — each an
offset along the scene's own spread axis and a `GroundShape` of its own — and `EventInstance` puts
down one collision shape, one shadow patch and one entry in the per-tile solid record per piece.
Every other row declares none, which means one piece at the origin carrying `shape`: exactly the
single body they always had. **The pieces live inside `shape` and never past it**, which
`EventDef.validate()` refuses, and that is what keeps every planner reading one disc:
`obstructs_radius` stays the ground a row *closes*, `EventDef.solid_reach()` is how far it is
actually *solid*, and the two are the same number for all but the crash.

**The crash is the row it exists for.** *(2026-09-12: "a car crash right now has a full bounding box
even though there are gaps in the sprite. the bounding box should only be the crashed cars but it
should emanate an excitement field that prevents the player from walking past it".)* `car_accident`
draws two cars locked across the carriageway with debris between them and an onlooker on each
pavement, and it closes the whole 192px street; its bodies are the two cars alone, read off the two
authored pictures at the scale each is fitted to the street, so the debris and both pavements are
ground she can walk. What stands in the gaps instead is a field —
`Tuning.CAR_ACCIDENT_INTENSITY`, stated over the scene's own band so the whole footprint is charged
at the full rate and the shoulder outside it is short. **It is the one seal that emits at all**, and
it is the one place `docs/CITY.md`'s *a closure is silent* does not hold; squeezing past costs more
than half the meter, which `tests/test_seals.gd` walks rather than asserts.

**A body is solid to the crowd as well as to her.** `EventManager` rasterises every stationary
solid body's own pieces — `EventDef.parts()`, which is one piece carrying `shape` for every row but
the crash — at the placement and along the axis the instance itself would draw them, into
`CityMap.obstructed_tiles`, and the walkers and the cars read that record: a walker steps
into the other lane of its footway to get past a café and a car turns at the last junction rather
than driving through a stall. It is taken from the day's **plan** rather than from the live
instances, since the crowd is steered across the whole map while an instance only exists within
`Tuning.EVENT_STREAM_RADIUS` of the player. A piece stands on the tiles whose **middle** it covers
(`GroundShape.tiles_under()`), since every lane is travelled down its own centre line: a van
pinned to the kerb overhangs the roadway by a few pixels and takes none of it. The exemptions
below are the rows the record leaves out, plus one the crowd has its own answer for already: a
door body holds walkers at the hut and cars at the boom. A hard seal's and a region wall's bodies
are in the record like any other, because they are what a walker walks up to; a car is turned a
junction earlier by the segment being held. See docs/MECHANICS.md, "The crowd goes round a seal".

**The catalogue is not the only thing carrying this datum.** A building's collision is a rectangle
built from `shape.collision_shape()` on `GroundShape.rect(footprint * 0.5)` — `src/city/building.gd`
— the one caller of `GroundShape`'s rectangle kind, since nothing else has a footprint that is not
already a point or a band; and the crowd's walkers and cars each carry a `shape` of their own
(`CrowdAgent.shape`) read for their shadow, though neither has a body — a car's lethality stays the
separate `CAR_STRIKE_HALF_LENGTH`/`CAR_STRIKE_HALF_WIDTH` rectangle `will_be_lethal()` reads, on the
player's own *"lethal != noise"*.

**Four exemptions, each for its own reason.**

- **Anything mobile.** A moving wall on a two-tile pavement pins her against a building, which is
  a different game from being priced out of a street.
- **`AHEAD_OF_PLAYER`**, refused outright by `validate()` — see rule 3 above.
- **Anything with no silhouette**: a playground the park itself draws, or a curfew announcement
  carried by a mast that is already solid on its own.
- **A flock**, refused outright by `validate()` too. `flock_size` bodies wheeling inside
  `flock_spread` have no one silhouette to be half of — each bird is an 18px picture with pavement
  between it and the next — and being walked into is the whole event, which a body would stop at
  the rim. `solid_parts` is how a row declares several bodies, and a flock's are neither still nor
  in one place.

**And one row whose body arrives late rather than never.** `EventDef.solid_once_it_starts` is not a
fifth exemption — the thing is solid, at exactly the width it is drawn — it is a statement about
*when*. Every other solid row is a **place**: it is on its tile before she is anywhere near it, so a
body from the instance's first frame is the honest picture and she can never be inside one. A vent
on a timer is the opposite, and the ground it closes is ground she may be walking down when it
fires; a body that appears around her is not something a telegraph can be an answer to, however long
the telegraph is. So the notice runs with no body and the body goes down at the end of it, and
`EventInstance._become_solid_once_it_starts()` withholds it for as long as she is inside the
footprint — **a vent never turns on with her in it**. It is a precondition rather than a repair,
nothing is placed and then moved, and it fails in the safe direction, since withholding obstruction
can only leave more ground reachable. She pays the field the whole time, so standing in a vent to
hold it open is the most expensive way through it rather than a way past it. **A planner's own
per-tile record does not know about this and cannot**: the record is rasterised from the *plan*,
before any instance exists, so such a row reads as solid to the crowd and to route-clearing for the
whole of its life. `basement_steam` is placed indoors, where there is no lattice to clear.

**And one constraint that is not an exemption: a lethal radius and a solid body are the same
mechanism.** She is stopped with her centre `solid_reach() + PLAYER_BODY_RADIUS` from the
centre of the thing, so on a `hard_fail` event a body that reaches the inner radius means the
kill can *never fire*, however carelessly she walks into it — a difficulty setting nobody chose,
arriving silently, in the one place the game cannot afford one. `EventDef.validate()` refuses that
arrangement on load. It is why `alley_robbery`'s inner radius is 30 rather than the 22 a man's own
width would suggest: a man is 11px wide and she is 14, so at 22 the pram is held three pixels
*outside* the radius that takes the baby.

**It is a rule about a thing that stands still, so a pursuer is outside it rather than excepted
from it.** The inference only holds while the body and the thing that kills are the same point, and
a pursuer's never are: it comes to her, and every one of them either drops its body the frame it
starts hunting or — with `EventDef.body_stays_behind`, which only `roadblock` sets — walks out of a
body it leaves standing where it was built. Either way the kill fires from ground the body does not
cover. That pairing is what `tests/test_heat.gd` holds, so the exemption cannot quietly become a
loophole for a pursuer that kept its body and carried it along.

### Checkpoints

A region door is solid, like anything else that stands still — `checkpoint_hut`,
`checkpoint_gate` and `checkpoint_post` at 32px each — but it is not a closure. **The lawful way
through is an inspection at a hut or a post, and the toll is the same both ways.** She walks up to a
hut or a post, is held for `Tuning.CHECKPOINT_DETAIN_SECONDS`, and comes out the other side of the
crossing, on the same pavement lane she went in on: `EventManager` reflects her release position
through the crossing's own cross-street line, sets her down just clear of the body by
`Tuning.CHECKPOINT_RELEASE_MARGIN`, and teleports her there — see `Stroller.teleport_to()`. Walking
round a hut into its own solid body does not open it; the lawful way through is the conversation.
Both rows set `redetains`, so the same body detains her again on the next approach, from either
side — unlike `chatting_mother`, who is spent after her one conversation.

**She is let out inside the door's own trigger, and a latch rather than distance is what keeps her
there.** The far side of a body she cannot walk through is a body's width away and the trigger
reaches further than that, so no release that leaves her at the door can land outside it — and one
that throws her past the door is a teleport further than the door is wide. `ReleaseLatch`
(`src/world/release_latch.gd`) is the flag instead: armed on the way out with the trigger's own
circle, it holds until she is measured outside that circle, so standing where she was let out costs
nothing however long she stands there and the toll comes back the moment she leaves and walks in
again. **It is armed for every redetaining body whose reach she lands in**, not only the one that
let her out: where two doors meet at a corner, the ground one hut lets her out onto can be inside the
other door's reach, and one crossing has to be one toll. The building's own doors in the escape
scene reuse the same class.

**The hold starts a reach past the door body's own wall, not a radius from its middle.** Her centre
is stopped `obstructs_radius + PLAYER_BODY_RADIUS` from a body it cannot walk through, and further
when the pram's body is between her and it, so a trigger stated from the middle has to be wider
than whatever she is pushing that day — and when the pram moved, the hut became a wall she could
stand against and never open. `EventDef.detain_distance()` is the same reach as a distance between
centres, which is what `validate()` checks against `inner_radius` and what the release has to
clear. **Only the nearest eligible body captures her**: each body reaches a reach past its own edge
and doors can stand close together — two meeting at a corner — so ground inside two triggers at once
exists, and two holds beginning together would end as two releases, the second sending her back
through the door the first had just let her out of.

**The boom never inspects her; it blocks her while it is down.** *(2026-09-24, the player: "Boom
shouldn't inspect her. It should block her." · "I didn't say it should stay solid when it's
open".)* The gate over the road between a door's two huts carries no field of its own — a car
passing under it costs her nothing — and no detention: it is `lifts_for_traffic`, so its collision
body follows the arm the cars work (`Crowd._stop_for_gates()`: up once a car has waited at it
`Tuning.GATE_STOP_SECONDS`, 1.2s, down the moment no car is within a length of it). Lowered, it is a
wall across the carriageway; raised, it is ground she may walk under, and the price is the car that
raised it — she is on its carriageway, and the horn and the strike apply as on any street, under the
traffic fairness contract `Tuning.validate_traffic()` states for every carriageway.

**And a hut never takes her in from the carriageway its own door's boom spans.** A hut's trigger
reaches a reach past its wall, which is further than the kerb, so without this the hut beside the
boom would reach out into the road and inspect her there — the boom inspecting her in all but name.
`EventManager._on_a_booms_carriageway()` is the test, stated over the door's own geometry: on the
boom's cross-street line and no further across it than the boom's own body reaches, which is the
carriageway. So walking up the road to a lowered boom is walking into a wall, and walking under a
raised one skips the toll.

**The arm never comes down on her.** Its body goes down with it, so an arm lowered with her — or
the pram she is pushing — beneath it would put a solid body around her, which no warning can be an
answer to. `Crowd._stop_for_gates()` keeps a raised gate up for as long as any of her rig is under
it, as it already does for a car within a length; cars go on passing under it meanwhile. It is a
precondition rather than a repair, since the arm never moves while she is there. See
`docs/CITY.md`, "Regions and the wall".

**Walking under a raised boom is detected, not guessed.** Every physics frame
`EventManager._watch_the_door_lines()` asks whether she has crossed a door body's own cross-street
line — the one an inspection's release is reflected through — within that body's own reach along
it, since the last frame, with no `Stroller.teleport_to()` or `reset_at()` in between
(`Stroller.outright_moves` counts them). The huts, the posts and a lowered boom are solid and a
release is a teleport, so a crossing she walked is a crossing under a raised boom and nothing else;
nothing asks where the arm is. The run log's `checkpoint` line records each one
(`docs/TELEMETRY.md`), and `EventManager.walks_under_a_boom()` counts them for a rig.

**And it sets a guard on her.** *(2026-09-24: "The guards should start pursuing her in that case" ·
"Or guards that pursue her should spawn at the huts" · "The day ends, not going through the
checkpoint is a clear unlawful thing here. She gets detained/imprisoned or whatever in that case.
This is independent of the resistance. She shouldn't do it. One guard is enough".)* One `door_guard`
steps out of the wall of the door's hut nearer to her, on the side she crossed to; the guards drawn
at the huts stay at their posts, so the door stays manned. He is the roadblock's hunting guard
copied — the same man in the same postures, 130px/s, the roadblock's 1.8s notice, a chase of
`Tuning.PURSUIT_TIME` after it, and a catch at `MASKED_MAN_REACH` (28px) — under the ordinary
pursuit contract: running outpaces him and `Tuning.PURSUIT_SHAKEN_OFF` of it makes him give up,
walking away does not. A catch is `hard_fail` on every day a door stands and at every heat level,
not a rung of the heat ladder, and the summary says she was taken in. **He sets off a hut's width
from her, inside his own 106px stand-off** (`EventDef.sets_off_beside_her`): the ordinary rule
would lunge on his first frame, so instead his notice runs its whole length while he holds his
ground and then follows at the stand-off, and walking into him during it is caught when it ends.
One at a time: a second walk under while he is after her sets nobody else on her.
`tests/test_checkpoints.gd` walks the chase at the door's own geometry, since the catalogue's
pursuer rigs walk the director's.

**And a hut's hold ends his chase.** *(2026-09-24, the player, on whether the chase should survive a
voluntary trip through a checkpoint: "we can try b. if she voluntarily goes to a hut the whole
pursuit has been accomplished".)* The moment any checkpoint hut or alley post starts holding her for
its inspection — the one he stepped out of included — `EventManager._end_the_guard_for_a_hold()`
ends his chase through `EventInstance.give_up_the_chase()`, the same state, the same drawing and the
same telemetry line as running him out of `Tuning.PURSUIT_SHAKEN_OFF`; no catch can land during the
hold or after it. A guard still in his own 1.8s notice when the hold starts gives up too — nothing
asks whether it has finished. The roadblock's hunting guard and the escape's masked pursuer are
never the one guard this reaches, so a hold does not touch either.

**The boundary's structures charge as one source, never their sum.** *(2026-09-20, the player:
"since two gates can be adjacent to each other their influence shouldn't add up" · "otherwise
going into a hut at a corner with two huts double counts the influence".)* `EventDef.
barrier_structure` is the flag, and four rows carry it: `checkpoint_hut`, `checkpoint_gate`,
`checkpoint_post` and `roadblock` — a door, and the body the region wall stands as. One street
being held is one source however many bodies hold it, so a wall's three barriers across a street
read one barrier's rate rather than three, and a corner where a wall meets a door reads one barrier
rather than five. **And that one source's own rate is set against a door having company**
*(2026-09-20: "guard posts should emit less excitement by themselves, too" · "since there can be
other obstacles around")*: a hold is spent standing still, where `Tuning.EXCITEMENT_DECAY_IDLE` is
zero and nothing is earned back, so what the strongest barrier charges per second is most of what
standing in a door costs. The rates are in [COSTS.md](COSTS.md). `EventManager.excitement_sources_at()` keeps the strongest of them at her position and drops
the rest from the pairs entirely, so what lands on the bar is attributed to the body that was the
maximum, and the halo's colour — traced from that same sum — follows without a second rule.
`EventInstance.outranked_by_a_stronger_barrier` is how the caret and the halo's own rim selection
learn the same answer, so a corner draws one mark on the barrier that is charging her rather than
five promising the cost over again. Everything else in the catalogue still sums.

**The hold charges its toll and nothing else.** She is inside the hut, not on the pavement, so
while a hold is running the meter sums that hold's own flat `Tuning.CHAT_EXCITEMENT` and no other
event field and no crowd body — `EventManager.door_holding_her_at()`, asked by both halves of
`City.excitement_sources_at()`. With `EXCITEMENT_DECAY_IDLE` at zero for a player held still, the
crossing therefore costs exactly the toll wherever the door happens to stand, which is what "the
same cost each time" has to mean. `chatting_mother` keeps the ordinary sum: her conversation is in
the street with both of them drawn.

**The release owns both halves of coming back: she is moved, then shown, on one physics frame.**
A hold's own seconds run down in `EventInstance._process()`, a drawn frame, and the teleport is in
`EventManager._physics_process()` — so un-hiding her where the clock ran out put her back on the
screen at the place she went in until the next physics tick. `_enter_inspection()` is the only
half the row still owns, because hiding her already happens on the same physics frame the hold
starts.

**The guard goes inside with her; the door does not.** `EventInstance.is_its_guard_inside()` takes
the guard out of a hut's drawing for the hold, and the hut, the boom and their shadows stay exactly
where they are — a structure that blinks out for two seconds reads as the door having been removed
rather than as her having passed through it. `is_suppressed_by_its_own_hold()` is the narrower
question, true only of `checkpoint_post`, where the guard is the whole of what the row draws, and
the halo gates on it for the same reason.

**The boom hangs from a point midway between its own two posts, not from one of them.** A gate
stands on the carriageway's centre line, level with the huts on either pavement, so a picture hung
by the near post alone puts its whole arm to one side of where the body is — along a kerb, with the
lanes it exists to bar open underneath it. Anchored between the posts, each post lands just outside
a kerb and the striped arm crosses the lanes. `EventInstance.boom_arm_span()` states that reach as
a number, because `_draw()` never runs in a headless test and the arm's own extent is the whole of
what the player sees.

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
its vertical image (and its shadow, for the two of the three that draw one — see
`draws_body_shadow` above) is centred on the event's ground point; the bottom-centred anchor
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
- **Three things never leave**, and each would break something that reads the finishing position:
  an event with a `spawns_on_finish` stops **where the thing it leaves belongs** (a military
  convoy's barricade is where it stopped, not two streets past it); anything with no departure
  speed is simply over, which is right for a café that closes; and a row with
  `EventDef.stops_where_it_arrives` **parks and stays**, which is the fire engine at its fire.
  Parking is not an ending: it still emits, still carries its cue, and is still the same event —
  the standing field is the whole point of it.

## Scheduling

```
EventScheduler.build_day(day_index, run_seed):
    rng = RNG(hash(run_seed, day_index))
    1. add all AMBIENT events for the current act
    2. add SCRIPTED events whose day == day_index
    3. roll ONE_SHOT events not yet consumed this run, gated by first_day/last_day —
       except one the day owes her walk, which is budgeted here and sited later
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
`EventScheduler._open_ground_for` refuses five kinds of ground outright, by construction rather than
as a check on what a roll came back with:

- a tile closed today (`CityMap.is_closed`);
- **a tile a standing street tree occupies or reaches over** (`StreetTrees.footprint_tiles`, the
  tree's own ground shape — the one the shadow is drawn from). *(2026-09-12, the player: "events
  can only be placed where no trees are (except for the fallen tree which must empty out one tree
  lot)".)* The trees are the city's and fixed for the run while the events are the day's, so the
  day is what yields, and a van, a café, a market stall, a yeller or a dog walker is never in or
  behind one. `docs/CITY.md`, "Street trees", is why they are rare enough for this to cost the day
  almost nothing;
- the street the front door opens onto (`_the_street_she_starts_on` — a notch with one exit is not
  a route decision, it is a tax);
- a tile whose street segment is **held** today (`CityMap.is_held_at`) — a hard seal's own segment,
  a region wall or door, or a segment bordering the home block, all in `CityMap.held_segments`; a
  soft seal is not held, since its carriageway is still walkable and a café standing on it is the
  price of that route;
- a tile inside the home block's own lot (`CityMap.is_on_home_block`), the same exemption stated
  the other way round.

None of this is a weight: a closed or held street is not somewhere anyone can get to, or is already
standing for something else, or is a tree, so nothing about the role table below ever sees it.

**And one refusal is about what a candidate would *do* rather than about the ground it stands on**,
so it is asked of the placement instead of the pool: a row may not take a crossing the day's routes
depend on. `EventScheduler._leaves_the_route_junctions_open` asks, before the row is accepted,
whether the junction box still carries a walk joining the route streets that meet there — with this
row standing and everything already down standing too — and re-rolls where it does not. A junction
is the only place a line may change pavement, so this is the one refusal a street's far side cannot
answer; see `docs/CITY.md`, "A route's junctions stay clear", for the rule and for the four kinds of
row that are outside it.

**The stretch between two junctions is asked the same way, of the sidewalk the route is walked
along.** `EventScheduler._leaves_the_routes_sidewalk_open` refuses a counted **standing** row whose
reach, together with everything already down, would leave no walk from one of that street's
junctions to the other along that band. The far side of a street is the answer to a van; nothing
answers a van on the side the route is drawn down. See `docs/CITY.md`, "Nothing takes the sidewalk a
route is walked along".

**A pacing row is answered in time rather than in width, and twice.** It is out of the rule above —
a beat takes its ground for part of a loop, so what a walk past one needs is a phase rather than a
lane. What it is asked instead is whether its beat passes a **way out**, of which there are two
kinds: a **junction box**, the ground every crosswalk in the city is painted on, which she leaves by
the zebra while he is at the far end of his loop; or a **side route** — ground off the street
opening off the sidewalk's own side, an alley mouth, a park or square edge, a courtyard — which she
leaves by without crossing anything. A beat with neither leaves her nothing but walking through him.
`EventScheduler._a_pacing_beat_walls_a_sidewalk` is that question, asked of the candidate in the
placement loop, and a beat that fails it is a wall and may not stand on the sidewalk a route walks.

**And a pacing row's opening is ground.** `EventDef.paces` means a beat rather than a journey, so
what it denies is the ground the loop never leaves free and the rest is passed by waiting — which
makes the one end it is away from worth protecting. `EventScheduler._leaves_a_pacing_beats_opening`
asks the rows reaching a route street that carries a pacing row whether a walk along that street
survives all of them together, and refuses the placement that would close it, in both directions:
the pacing row that would land in a closed street and the standing row that would close an opening.
See `docs/CITY.md`, "A pacing row is passed by waiting, or left at a crossing".

**A seal is checked the same way in a different place.** `SealPlanner` puts a body on every
off-tree street whether or not the scheduler would have offered that tile, so it never asks
`_open_ground_for` at all; `SealPlanner._seal_along_tile` applies the tree refusal at the one place
a seal's site is chosen, stepping along the street from its midpoint to the nearest cross-section
with no pit in it. The single exception in the whole game is `fallen_tree_seal`, which stands *on*
a pit and empties it — see `docs/CITY.md`, "What closes a street". See `docs/CITY.md`,
"Carve alleys" and "Place home", for why the home block's own ground never has an alley to be a
candidate in the first place.

A placement is a roll over every tile of the right type that survives the exclusions above, weighted
by whether the tile is in a precinct and by what the day is placing the thing **for** — its
**role**, in the vocabulary `docs/CITY.md` fixes — against the day's **corridor**, which is the ways
from the doorstep to the calm areas still worth reaching.

`EventScheduler._role_for` answers it off the def and nothing else has to be written per row:

| kind of row | role | where it may go |
| --- | --- | --- |
| lethal (`hard_fail`), or a walk-through cost of `WALL_WORTH_OF_COST` or more | **wall by cost** | never on ground a route runs along; `EVENT_WALL_RIM_WEIGHT` toward a turning off the corridor |
| a standing row that leaves no line past it along a sidewalk it may stand on, by cost (`cafe_tables`, `construction`, `market_stall`, `ice_cream_van`) | **wall by cost** | the same, which includes the far sidewalk of a route's own street |
| a standing row that leaves no line past it along a sidewalk it may stand on, by physical fit alone (`delivery_van`, and any future row this narrow) | **wall by fit** | never on ground a route runs along; otherwise weighted like friction — no pull toward a rim, since nothing about it is the noisy, seen-from-a-distance thing the rim exists for |
| a **pacing** row that leaves no line past it and whose beat passes no way off its sidewalk (`homeless_yeller`, where its beat is truncated short of one) | **wall** | the same, decided per placement rather than per row |
| a **pacing** row whose beat passes a junction's crosswalk or a side route (`homeless_yeller`, almost everywhere) | **friction** | `EVENT_CORRIDOR_WEIGHT` toward the corridor, the route's own sidewalk included |
| everything else placed on a tile | **friction** | `EVENT_CORRIDOR_WEIGHT` toward the corridor |
| a `ONE_SHOT` | **set piece** | one placement at *each* site of a covering set; one of them happens — or, with `EventDef.sited_on_her_way`, one placement with no position, put on a building face ahead of her once her heading for the day is clear |
| `AMBIENT`, `AHEAD_OF_PLAYER`, a scar, a park spoiler, `EventDef.scenery` (`pigeon_flock`) | **none** | wherever its own rule says |

**The second row is a question about the ground, not about the price, and it is asked two ways.**
*(PLAYTEST-77: "how is market stall a friction? you can't walk through it"; "a wall is also when you
physically cannot walk through".)* A sidewalk is `Tuning.SIDEWALK_WIDTH` tiles — two lanes, 64px —
so the only line past a row standing in one of them is the other lane, a tile away; a row whose body
and charging disc (`EventScheduler._line_reach_of`, "What a row denies is what it charges for" in
`docs/CITY.md`) reach that far leaves no line at all. A market stall costs 8.5 points to walk
through, well under `WALL_WORTH_OF_COST`, and denies 58px of the 64: cheap and impassable are not the
same question, and friction is the role aimed *at* the route, so a row aimed there has to be one she
can get past there.

**A silent, narrow body can still close a lane no cost ever priced.** *(PLAYTEST-94: "I still get
hard walls on the side of the sidewalk that is on the path -- how can this be so hard to do
correctly?")* `delivery_van` bills nothing (`intensity` 0) and its 22px `obstructs_radius` stays
under the cost clause's 32px threshold, but parked `AT_THE_KERB` — 16px in from the kerb edge, the
lane tile it is never re-centred off — it leaves `(SIDEWALK_WIDTH * TILE_SIZE - TILE_SIZE * 0.5) -
22 = 26px` to the frontage, narrower than the 28px she needs (`2 * PLAYER_BODY_RADIUS`). So
`EventScheduler._closes_the_band_by_its_own_placement` reads a row's own numbers against the exact
edge its `pavement_side` stands it at — the kerb or the frontage lane's own tile centre, or the
band's true middle for `ANY` (where `EventInstance._centred_on_the_pavement_band()` always puts a
stationary, unpinned body) — rather than against a fixed threshold, so a row narrow enough to slip
under the cost clause is still caught if its body alone leaves no edge-to-edge gap that wide. The
same reading is also why `poster_crew` stands `AGAINST_THE_BUILDING` rather than `ANY`: centred, an
11px body would leave only `32 - 11 = 21px` on each side of the band, under the 28px she needs; at
the frontage lane's own tile centre it spans 5-27px of the band from that edge and leaves 37px to
the kerb, over 28 — a body this narrow only needs to move off the exact middle to stay friction,
where a wider one could not.

**A pinned row is a sidewalk row, because a square has no sides.** `CityMap.pavement_inward`
answers nothing on a square, so `EventScheduler._wants_this_side` refuses every square tile to a
row carrying `AT_THE_KERB` or `AGAINST_THE_BUILDING` — which means a `placement` listing that
ground is listing ground the row can never be offered. `poster_crew_square` is the poster crew's
answer to it: the same event on the ground the pinned row cannot take, standing at the free-standing
advertising column a square has instead of a wall. *(2026-09-19: "we need a separate square poster
crew entity for this".)* `tests/test_events.gd` holds the whole catalogue to it, so the next row
given a pavement side cannot quietly lose a kind of ground the same way.

Both readings are read off the row's own numbers rather than a list of ids, and asked of *a*
sidewalk rather than of the tile — the role is decided before a tile is chosen, so a row that may
stand on a sidewalk is judged on the narrowest ground it may be rolled onto.

**A pacing row is the one whose role is a fact about its placement.** *(PLAYTEST-77, 2026-09-19:
"yeller is something you can time. it stays on the route"; "if the yeller paces across a crosswalk
then there is a way to avoid them. if they stay on the segment for the whole time with no side
route then there is no way to avoid them. distinguish those cases when deciding whether the yeller
is a wall".)* A beat runs *along* a sidewalk and moves the row nowhere across it, so the width of
the line past a man walking one is the same at every phase of his loop — but the way past him was
never a wider sidewalk. It is somewhere his beat passes that she can **leave** by: a junction box,
where she takes the zebra while he is at the far end of his loop, or a side route off the sidewalk's
own side. So the same numbers are friction where the beat passes one and a wall where it passes
neither, and `EventScheduler._a_pacing_beat_walls_a_sidewalk` asks it of the candidate inside the
placement loop, where the beat exists. A junction box is where every crosswalk in the city is
painted, so *crosses a crosswalk* and *reaches a junction* are one question — and it is the crossing
this whole design counts on, since a mid-block crossing exists in play and is never planned around.
`homeless_yeller` paces eight tiles against a block of eight, so its beat runs into a junction unless
a closure, a calm zone's absorbed corridor or the map's own margin cuts it short: friction almost
everywhere, a wall where the street gave it no way out.

**A pacing wall is offered its ground at friction's weights and takes only the wall's refusal**, and
that is the one place the two halves of a role come apart: `_ground_for` builds a pool per role
before any tile is rolled, and a beat does not exist until one is — so the tile it lands on was
offered as friction's and the corridor's own sidewalk is then refused it. What it lands on in
practice is the far side of a route street, which is where the rim weight would have sent it
anyway.

Two things about the mechanism rather than the table. It is **the same weighting the precinct
uses** — a tile is offered to the roll several times over — so every spacing rule downstream keeps
working unchanged and nothing can refuse a placement. And **exactly one of these is a rule rather
than a weight**: a wall never stands on ground a route runs along. That one can be absolute because
the rest of the city stays available to it, so it cannot starve a row of ground; everything else is
a weight for exactly the reason it could.

**And that rule is asked per sidewalk while the weights are asked per street**, which is the one
place the corridor's two grains differ on purpose. A price is stated over a street because a player
may be anywhere across it; where a thing may *stand* is narrower, and a branch runs along one
sidewalk of a street rather than down the middle of it — so the far side of a route's own street is
ground no route walks, and a wall may stand there. *(PLAYTEST-77: "the market stall should appear on
the other side of the street where for some reason no event was chosen".)*
`Corridor.carries_a_route` is the question — the kerb tint asks the wider, street-grained one
(`Corridor.depth() == 0`) instead, since the mark says *this street*, not *this sidewalk*.

**It is also where a very costly wall wants to be — a wall by cost, not a wall by fit.** The
**rim** — the ground `EVENT_WALL_RIM_WEIGHT` pulls a costly wall toward — has two members: a
turning off the corridor, one street out, and the far side of the street the route is already on.
The second is the nearer of the two and the one she can read without leaving her own line, so a
street with a route down one side of it is a street with the day's cafés and stalls down the
other. The **lethal** half of the band keeps its own gradient and is pulled past the rim by
`WALL_DEEP_WEIGHT`, so nothing that ends the day is drawn to the other side of her street in
particular.

**A wall by fit alone gets none of that pull.** *(2026-09-19, the player, asked whether
`delivery_van` should also be weighted toward junctions once it became a wall: "A. No (my
recommendation). -- do that")* The rim is for the big, noisy things meant to be seen from a
distance before she commits to a street; `delivery_van` is silent and a wall only because its own
body leaves no lane, which the
cost clause never sees (`EventScheduler._is_a_wall_by_cost` is the question `_copies_of` asks
before choosing a `WALL`'s weight). So a wall by fit keeps only the one consequence every wall
gets — zero copies of a route-carrying cell — and is weighted everywhere else exactly as friction
is, landing on the far side of a route street through `EVENT_CORRIDOR_WEIGHT` rather than through
the rim. A pacing wall's own reach is wide enough that it answers the cost question too, so its own
landing on the far side (above) is unchanged.

The role weighting moves *where* the budget is spent and never how much of it there is: the density
placed per day is unaffected by whether the weight is live, and so is the count of lethal rows —
the one the rule could have broken, since a `hard_fail` event must clear its whole outer radius of
everything else with no fallback, and refusing it a quarter of the city could have quietly stopped
placing it. What the weight does move is the split: costly rows land on the corridor far more often
than off it, and lethal rows land on the rim far more often than elsewhere, with the corridor's
share drifting down over the run as it fills up and `EVENT_SPACING_SAME` pushes the overflow
outward. The measurement that established this is in `docs/DECISIONS.md` under M50.

### A set piece happens where she is going

*(And so does a poster crew, which is not a set piece — see "The crews paste the walls she
passes" below.)*

An authored one-shot has to be **met**: one that fires on a street she never walks down is a
fairness contract and a silhouette spent on nothing. There are two ways of guaranteeing that, and
which one a row gets is `EventDef.sited_on_her_way`.

**The fire is sited from the walk she is taking, on the path she is on.** `burning_building`, day
3's one-shot and the only set piece carrying the flag, is budgeted at dawn with **no position at
all**.
Once she has been walking `EventDirector.ON_HER_WAY_AFTER` seconds and is `ON_HER_WAY_BEYOND_HOME`
pixels clear of the doorstep — far enough in that a heading means something, and past the day's run
lesson — `EventDirector.site_what_is_on_her_way()` puts it on a building face **on the branch of the
day's `RouteTree` she is walking**, and nowhere else: *"valid spawn locations are only on the path"*
(PLAYTEST-119).

The window is the day's own route rather than a line from her. `EventScheduler.WalkSiting.ahead_of()`
walks the cells of every route through the cell she is standing on, in the direction that agrees
with the way she is travelling, and offers the building faces standing on them. **The far end of the
band is read along that route** — `ON_HER_WAY_SIGHT` seconds of walking past the streaming band,
through every corner and junction, which is how much further she actually has to walk. **The near
end is a distance across the block**, the streaming radius plus its hysteresis, because that is what
decides whether the placement is in the world at all: a site 1200px along a route that doubles back
can be 500px away as the crow flies, streamed in and so real and unmovable on the frame it was
placed. A straight line is never longer than the route to the same place, so clearing the streaming
band clears both ends at once.

Three consequences worth stating, because none of them is true of a rule stated as a straight line:

- **At a fork, either way out is a site**, since every route through her own cell is walked. Once
  she commits, her cell carries one of them and an unseen fire on the other moves onto the way she
  took.
- **Momentarily off the tree she waits.** A park cut, an alley, a thinned seal — there is no branch
  to be ahead on, so the attempt is refused and asked again a second later. Nothing is ever sited
  off the path to answer a wait.
- **The walk from the siting to the first sight is a walk of the route**, not of a line, so it is
  longer than the straight-line band suggests. `tools/test.sh probes/m179_fire_on_her_way.gd` prints
  what it comes to.

*"the fire should come first and be on your way **guaranteed** (a dynamic event dependent on the
route you chose that day)"* (PLAYTEST-117). Three things make that hold:

- **It is a place, sited late, not a moment with no place.** The tile, the role, the corridor's own
  questions, the doors, the protected calm and the body in the street are all exactly what dawn
  would have asked; `EventScheduler.WalkSiting` keeps the day's placement context past dawn so that
  one candidate is judged against the same ground as every other placement. What waits is only
  *which* of the legal tiles it takes.
- **It may be moved until it is real, and never after.** If it has stopped being on the way she is
  walking — behind her past `ON_HER_WAY_BEHIND`, or off the branch she is now on — for
  `ON_HER_WAY_TURNED_AWAY` seconds of walking, it is sited again on the way she is going now. **The
  walk home changes nothing**: *"if they managed to avoid it thus far they should still have to try
  avoid it further. only once the event has actually taken place does it become fixed"*
  (PLAYTEST-120). Nothing in the rule asks which leg of the day she is on. The
  moment it streams in it has recorded its scar and moved its block along its arc, and from then on
  it stands where it burned for the rest of the run. That line is drawn at the streaming radius
  rather than at the screen edge, which is six seconds of walking earlier than she could have seen
  it.
- **Nothing is placed illegally to satisfy the guarantee.** No building face on the branch ahead of
  her, a door's clear ground, calm she has not used, a site that would close her own way out — any
  of these and the siting is simply refused and asked again a second later, from wherever she has
  got to. A day she walks into a corner is a day it waits. Where the band itself holds no face the
  window widens **along the same branch**, first to twice its width and then to the end of the route
  she is on, before anything else is considered; it never leaves the tree.
- **And a day she wins while it waited still burns.** *"I agree with the fire fix"* (PLAYTEST-121).
  The row runs on day 3 and no other day and is spent where it enters the world, so a won day on
  which every siting was refused would leave the run with no fire, no scar and no shell — and the
  shell is what the city remembering day 3 is made of. `EventManager.light_what_she_never_met()`
  lights it at the end of such a day, **off her path**: past the streaming band from where she
  finished, so it is nowhere she could have seen it happen, and off the ground the day's routes run
  along where there is any, by the same acceptance rules every other site is chosen by. It records
  what a fire records — the scar, the block's arc, the one-shot spent — and is taken back out of the
  world, since the day is over. Meeting it stays the strong guarantee; this is what the weak one
  owes. A **lost** day never lights one: a loss gives the whole attempt back (`GameState.finish_day`)
  and the retry owes a fire again.

The fire engine is not part of this. It is never scheduled at all, and arrives only once the
building it answers has been seen (`EventDef.spawns_on_sight`,
`EventManager._summon_the_sighted_row()`) — which is why the fire being on her way is also the
engine being on her way.

**And a siting she did not choose owes her a way out of it.** She meets this one because the day put
it in front of her rather than because she picked the street, so the pair of them have to leave her
somewhere to go. Three things hold at the moment she first sees it, and all three are checked rather
than argued. She is **outside the inner radius where the field is at full strength, with the walk
out of the rest of it inside the 2.2s telegraph** — which is the contract's own worst case rather
than a hole in it: the fire stands on the route she is walking, so it can come into view from any
direction, and the view is 180px deep against the fire's 260px field, so an approach up or down the
screen has the outer edge of the field on her already. The engine is created **outside its own
forward reach of her**, measured from the worst position the sighting allows, which is the view's
half diagonal up the street rather than directly under the fire. And **the home and a calm area she
has not used are still reachable from where she is standing**, outside both fields — the same
question `EventScheduler.WalkSiting` asks before it accepts a candidate at all.

**A one-shot without the flag is offered on every route and happens on one.** The day plans it **at
every site of a covering set** — `RouteTree.covering_sites`, the smallest set of streets such that
every route touches one — and the placements share a `set_piece_group`. The first one to enter the
world spends the rest, in `EventManager._stream_in`, which is also where a scar is recorded: a run
gets exactly one of it however many streets were offered. Two things this gets right that choosing
a site on her route would not:

- **Nothing has to predict her.** The guarantee is structural and holds whichever way she goes.
- **A bundle is not a guarantee.** Two distinct routes to one area share no *cell* by construction
  — a route is a chain of `ReachabilityGrid` cells, and the same-colour rule never lets one probe
  merge into ground the other already coloured. Almost always that also means they share no
  street, so the covering set is usually two to six streets and code that expects one is looking
  for a *tile she must cross*, which the city is built not to have. Rarely, the two routes use
  different cells of the very same street, and one site there covers both after all — the fallback
  a covering set of one is legal ground for, not a bug in either.

**The moment of choosing is the moment of walking there**, either way round. `_stream_in` is where
an event becomes real — where its scar is recorded and its block moves along its arc — so the
alternatives stop being possible on the same frame rather than when it finishes, and so does the
fire's own freedom to move.

**An offer takes up no room, and that is not a convenience.** Spacing the rest of the day around
all two-to-six offers would reserve ground for events that will not exist — and it breaks *"a
retried day is the same day"* outright, because the day after the set piece fires then has several
long routes' worth of ground freed rather than one. Measured on seed 4242 with offers spaced
against: `leaf_blower` seven to five and eight kinds moving between two attempts at the same day.
Because an offer costs nothing, the fill is **identical** between attempts.

Two exceptions, both load-bearing. **Siblings space against each other**, because two offers on top
of one another would be a real overlap on whichever one fires. And **nothing lethal may be planned
into an offer**: if it does resolve there, she meets a lethal field and a set piece at once, which
is exactly the sum the telegraph contract refuses. A siting made from her walk is held to the same
rule from the other side — `EventScheduler._room_around` measures the candidate against everything
the day has already placed, so a building face inside a lethal field is not a face it may take.

The three counts this splits apart are worth keeping straight, because two tests depend on it.
`max_per_day` is a cap on **instances**, and the number of offers is not one — so a one-shot is
exempt from it in `tests/test_events.gd` and the real count is asserted in
`tests/test_event_manager.gd`, where an instance exists. And a **retried day plans none** of a
spent one-shot rather than one fewer, because the whole group goes with it.


### The crews paste the walls she passes

A poster crew placed anywhere in the city is a crew she never meets, and a wall she never sees
changing. So `poster_crew` carries `EventDef.sited_on_her_way` and `EventDef.pastes_a_front`. **The
day still rolls and places its crews at dawn** exactly as before, which is what keeps every other
row the roll places where it was; `EventScheduler._hand_to_her_walk` then drops their positions,
and `EventDirector.site_what_is_on_her_way()` sites them the way it sites the fire — on the branch
of the day's route tree she is walking, beyond the streaming band and within
`EventDirector.ON_HER_WAY_SIGHT` seconds of walking along the route, moved while unreal, fixed once
real — with three differences. **One at a time**: the next crew waits while another is sited and
not yet in the world, so the day's crews are spread along her walk rather than bunched in one band.
**At a front**: its ground is the frontage lane in front of a blank ground-floor cell
(`Pavement.AT_THE_FRONT`, narrowed to `PosterWalls.fronts()`), facing the wall, and the line rules
still apply to it, since a crew closes nothing. **Not a set piece**: it is not spent as a one-shot
and not lit at dusk if she never met it. Once in the world, `PosterWalls` has it paste the wall it
stands at, a sheet every `PosterWalls.PASTE_EVERY` seconds while it is inside her view, with its
brush raised on alternate frames (`poster_crew_back_b.svg`), and the wall keeps its sheets for the
rest of the run. Its field and its cost are unchanged. `tools/test.sh
probes/m180_crews_on_her_way.gd` walks the day's routes and prints how many crews were sited, met
and how much they pasted.

**A torn poster can send a patrol.** When the tear's marble says so (`docs/MECHANICS.md`, "Tearing
a poster down"), `EventDirector.send_a_patrol()` sends a `police_patrol` at the run's heat the way
the return leg's patrols come: `TOWARD_PLAYER` down the carriageway lane driving toward her, at
least its `offscreen_notice` outside the view (`_toward_her_on_the_road()`), so its telegraph
contract is the one that row already keeps. It is held apart from the day's owed queue — it takes
no turn in it, rolls no interval and draws from no stream — so a day she tears a poster hands every
other director-sited row what it would have had anyway. At most one is waiting at a time, it is
sited only once she walks on along a street, and nothing is sent during the escape.

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

**`night_raid`'s own threshold is a calendar fact rather than a design one.** The tasks before it
fall on days 6 to 9, so on day 10 — the only day the row ever appears — the most progress anybody
can hold is four, `Tuning.HEAT_HUNTS_LEVEL` exactly: the raid hunts *only* a player who has
done every task on time, and a player one task behind meets the cold raid, still a closed block and
nothing more. Sharing the van's threshold rather than minting a third constant is what makes that
sentence true.

**`roadblock` does not chase with the body it already has — a band does not chase, a man does.** Its
solid picture is a 120px barrier, `_draw_spread` across `GroundShape.band(60.0)`
(`obstructs_radius` 60), and **a guard stands at it from the moment it is placed**, cold or
hunting: *"the guard needs to be at the barrier from the beginning, standing. only then does it
make sense for it to start pursuing."* Cold he is a drawing and nothing else — the field, the body
and the cost are all the band's.

When a heated copy notices her, **he** is what sets off, from exactly where he was standing. Two
fields make that work and both are general rather than written for this row:

- **`EventDef.body_stays_behind`.** Every other pursuer's obstruction comes down the frame it
  stops waiting, because a moving pursuer with a body is a wall. A barrier is not the man's own
  bulk: `EventInstance` pins it at the place it was left and draws it there for the rest of the
  event's life, so **the street he abandoned stays shut behind him**. Nothing appears and nothing
  disappears.
- **`EventDef.lethal_radius`**, and `lethal_reach()` is what every caller asks. The field and the
  killer are no longer the same object — the field is a street being held and is cored on the band
  at `inner_radius` 86, while what ends the day is a pair of arms at 28px, the same
  `EventCatalogue.MASKED_MAN_REACH` the escape's own `masked_pursuer` catches at. One figure, one
  reach, stated once.

`EventDef.validate()`'s rule that a lethal radius must not sit inside its own solid body is a rule
about **a thing that stands still**, and it is stated that way rather than excepted for this row:
the inference only holds while the body and the killer are the same point, and no pursuer's are —
each of them either drops its body or walks out of one it leaves standing.

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
| `playground` | AMBIENT | 1 | Free — intensity 0. The swing frame in every park is `map.playgrounds`' own prop, drawn whether or not this row costs anything; a one-block park has no ground left to settle her on once anything standing in the middle of it costs, so nothing here does. |
| `cat_dash` | RECURRING (`AHEAD_OF_PLAYER`) | 1 | Crouches (telegraph), then bolts across the traffic. Intensity 17, tiny radius, 1.8s duration — long enough to carry it the whole way across the street it starts at the edge of, and raised from 15 for a sharper startle spike once the barrier fields it used to be judged against went quiet. Its dash, driven straight at a standing player, still projects under `Tuning.EXPECTED_IMPACT_POINTS`, so the crouch's own silhouette carries the warning rather than a caret. Sited at `EventDef.ahead_of_player_lead()` rather than the flat `AHEAD_LEAD_DISTANCE`, which prices in the ground she covers while it holds its crouch, so it crosses where she actually is by the time it moves rather than behind her. The tutorial obstacle. |
| `alley_mouse` | RECURRING | 1 | The cat's shape, `MAP`-placed on `ALLEY` tiles instead of director-sited — an alley she is routed through is already ground she is about to walk, unlike a `ROAD` tile that could be anywhere in the city. Intensity 21 on a 60/15px field (the cat's 4:1 ratio) and half its cap (4), on top of the alley's own `Tuning.EXCITEMENT_FROM_ALLEY` (+3.0/s) ambient dread. **Priced above the cat on each row's own ground**, which is not the same ground — *(2026-09-12: "alley mouse is a bit above charging cat"; "consider that the mouse is in the alley but the cat is usually not")*. A cat is met on a street that gives back 6.0/s; a mouse only ever in an alley, which gives back 3.5/s and is charging the dread as well, so the alley hands this row most of the gap before its intensity is touched. It walks to **+19.9 in an alley** against the cat's **+17.6 on a street**. The field is only 60px across, so the crossing is a second and a third and the spike has to be bought in intensity — there is no `impulse` field. No body, nothing lethal. Waits unclocked (`pursues_within` 150px, without `pursues`) until she is close, so a `MAP` placement streamed in from `EVENT_STREAM_RADIUS` does not telegraph and finish off screen before she arrives — see `EventDef.pursues_within` and `EventInstance._check_for_notice()`. Its two-point dash is read off `CityMap.alley_rects` and laid across whichever side of the alley is narrower — always the width, since she can only be walking the length — so it crosses her path rather than running down it (`EventInstance._alley_crossing_path()`). `EventScheduler._refuses_required_alleys`, stated over `def.placement == [ALLEY]` and shared with `alley_robbery`, keeps it off alleys she has no way around. |
| `dog_walker` | RECURRING | 1 | Mobile along the sidewalk at 32px/s — slower than walking, so the ordinary band rule applies. Intensity 33 on a tight radius, barking on a 3.5s pulse: it owns the pavement it is on, so walking straight through it is never the cheap option. **The measure is a pass, not standing beside it**: she and the dog walker going different ways at `Tuning.WALK_SPEED`, the row moving as the game moves it. What a pass nets, and the walk-through cost that has to stay under `Tuning.WALL_WORTH_OF_COST` for this row to be met on her route, are its line in [COSTS.md](COSTS.md). Deliberately given no `obstructs_radius` — a moving wall on a two-tile pavement pins the player against a building. |
| `cafe_tables` | RECURRING | 1 | A café spilling out of its frontage, `obstructs_radius` 24px. The first thing in the game that is physically in the way on **day one**, and a **wall** by passability rather than by price: 24px of tables billing anybody within 56px of them leaves no line along the 64px sidewalk it stands on, so it is what the far side of a day-one street carries and never what the route's own sidewalk does. Pleasant, which is worse: nothing about it looks like a hazard and it still costs the street. Stationary, so it can never pin anybody. The people at the tables are drawn as well as the tables, because the tables are what obstructs and the conversation is what it emits — a real source, derived from the body itself: `inner_radius` 38px (touching the tables), `outer_radius` 64px (the pavement band's own centre to the carriageway's), so it bills somebody at the tables and not somebody across the street. |
| `homeless_yeller` | RECURRING | 1 | Intensity 20 over a 210px field, yelling on a 5s **pulse**, and **pacing** eight tiles of pavement (`EventDef.paces`). A fixed source on a fixed patch is a line you draw once; a man walking up and down it is a timing problem on top of a routing one. Mobile, so he has no body. **The measure is a pass, not standing beside him**: she and he going different ways at `Tuning.WALK_SPEED` while he paces. What a pass nets, and the walk-through cost that keeps him under `Tuning.WALL_WORTH_OF_COST`, are his line in [COSTS.md](COSTS.md). **Friction or a wall depending on where his beat runs**: the way past him is never a lane and always a crossing — a beat that reaches a junction box is one she can leave at the zebra there while he is at the far end of it, and he stays on the route like any other timing problem; a beat truncated short of a junction by a closure or a calm zone leaves no way off his sidewalk, and that placement is a wall. His silhouette is his own — a long coat, a raised arm, a beard, one shape where a passer-by is two. One of him is also the resistance's first contact: the instance she actually hands the note to stops shouting and walks off at once, the same departure any finished event takes (`EventInstance.leave_for_a_completed_task()`), while every other live one carries on. `paces` never reaches the end of its own path and he carries no `duration`, so this is the only way he ever leaves — at `departs_at` (60px/s, faster than his 30px/s shuffle and well under her own walk), and not until she is `Tuning.OUT_OF_SIGHT` of him: he does not pop out of existence mid-screen if she is standing right there watching. |
| `delivery_van` | RECURRING | 1 | Parked at the kerb, hazards going. Silent: standing in the way is its entire price, and `obstructs_radius` already charges it — see "Solid things are solid". At the kerb rather than on the carriageway, and solid at `VEHICLE_BODY`: 44px of van across a 64px footway leaves 26px to the frontage, narrower than the pram — a **wall** by physical fit, silent or not, so the street it is on is one she walks the far side of. |
| `busker` | RECURRING | 2 | Park and square spoiler. Nothing about it is threatening; it is simply interesting, which is the whole problem. Solid at 11px, which is a man to walk around and not a park closed — see `OBSTRUCTION_A_PARK_CAN_HOLD`. |
| `construction` | RECURRING | 2 | The widest body in act I (`obstructs_radius` `EventCatalogue.SIDEWALK_SPREAD_MAX`, 32px), and the one that leaves no gap: centred on the pavement band it stands on rather than on the tile the scheduler chose, it fills the full 64px of it — which is what makes it a **wall** by passability although it is silent and cheap, since a band with no lane left is a band with no line along it. Since a street is sidewalk\|road\|sidewalk the road is always still there, so it costs time, never the day. Silent, like `delivery_van`: a hoarding is not a source. |
| `burning_building` | ONE_SHOT | 3 | Against a frontage, `AGAINST_THE_BUILDING`, the way `reversing_lorry` is — and **sited from the walk she is taking** (`sited_on_her_way`) rather than from a street chosen at dawn: on the branch of the day's route tree she is walking and never off it, off screen, beyond the streaming band across the block and at most `EventDirector.ON_HER_WAY_SIGHT` seconds of walking further along that route. It may be moved while she has not reached it and never once it is real. `spawns_on_sight` calls `fire_truck` in the moment she first sees it. Burns for the rest of the day, you cannot walk through the fire, and the shell it leaves stands where it actually burned. |
| `fire_truck` | — | — | Never scheduled: a SCRIPTED def with no day, created only once `burning_building` has been seen. Drives an arterial at 190px/s with a 340px radius and a 6.27s telegraph (the fast-mover rule over its own forward reach — see docs/MECHANICS.md), entering along the fire's own street from off screen and driving to the near kerb across from it. **It parks there for the rest of the day** (`stops_where_it_arrives`): a standing 26/s field out to 340px beside a fire she was led to is what makes the pair a street to turn round on — *"a fire engine has a high cost"*, *"you're not supposed to go past it"* (PLAYTEST-119). It has no body, so what it closes is the ground its field covers rather than the road itself. |

**And the rest of act I**, which is where its variety and its danger come from — a
neighbourhood's own rather than a patrol's.

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `loose_dog` | RECURRING (`TOWARD_PLAYER`) | 1 | A dog whose owner has dropped the leash, sited on her own pavement when she gets close and running straight down it toward her. The counterpart to `dog_walker` and the reason both exist — that one is a **span** you decide whether to cross the street to avoid, this one is a **thing coming at you** that you cannot out-walk. 132px/s, so it earns a badge at the screen edge and pays the whole-radius telegraph. Not lethal, which is what separates it from `charging_dog`: this one is answered by getting out of the way, not by running. Intensity 39, so that a real meeting lands as a startle against the fixed baseline. **The measure is a pass**, she and the dog going different ways at `Tuning.WALK_SPEED`; what it nets at each sideways offset is its line in [COSTS.md](COSTS.md). `TOWARD_PLAYER` never earns a `WALL` role, so nothing here trades against `Tuning.WALL_WORTH_OF_COST`. 39 is the running rule's ceiling: past it, running past the dog costs less than walking past it, which nothing but `car_accident` is allowed to do — so **it is loud while it passes her by being sited further out, not by being louder**: `EventDef.toward_player_lead()` puts it where its telegraph ends a notice before its field reaches her, and a dog that arrives inside its own telegraph is one that spent the whole meeting at `Tuning.TELEGRAPH_INTENSITY_FRACTION` saying it was coming. The badge is what carries the warning while it is still off screen. |
| `market_stall` | RECURRING | 1 | The second thing on day 1 she has to walk round, and it exists because one obstacle repeated eighteen times is a rule rather than a decision. A **wall** by passability, like `cafe_tables`: 28px of stall denying 58px of a 64px sidewalk is the row the reading was written from. Wider, louder, and on the other side of pleasant than `cafe_tables`: a café you squeeze past is a nuisance, a market is a crowd. A real source too, derived from the body the same way `cafe_tables` is — 38px/64px, the same pair, since both bodies share the same 24px rounding. |
| `leaf_blower` | RECURRING | 1 | A man tidying a park, and a field with two parts: away from him it is the busker's exactly, so a park with a few of them spaced across it stays awake; inside `core_radius` — a pavement's own width — it is a wall. One of them closes one side of a street and never the street. `core_intensity` 35: this is the row that anchors the wall side of `Tuning.WALL_WORTH_OF_COST`, as `dog_walker` anchors the friction side, so its walk-through cost sits over that line with a margin ([COSTS.md](COSTS.md) has both). |
| `pigeon_flock` | RECURRING | 1 | **A patch of pavement that goes up when she walks into it.** `MAP`-placed, so the birds are pecking about from the moment the day streams them in at `EVENT_STREAM_RADIUS` — a flock she can see from down the street is one she can price and route around, which is the whole difference between a place and a moment. `pursues_within` 150px, inside its own 168px field and more than twice the 62px wheel, is the wait: unclocked and `quiet_until_noticed` (a fraction of its rate while they peck), then a flock on the ground about to go, then up, then *away*. **What ends the wait is her arrival, not the clock**: `EventInstance._flush_the_flock_if_she_is_among_them()` puts them up the moment she is inside `flock_spread` plus her own body, because the birds are grounded for the whole telegraph and a clock cannot know when she reached them — under one alone they went up behind her. `telegraph_time` stays the backstop for a flock she came near and never reached, which is why it is not shortened. **Its `intensity` is set by walking a real instance rather than read off the page**: flushing at the birds charges the burst while she is among them instead of behind her, which multiplied the line through the middle several times over, and going up on time was the request rather than costing more — so the rate came down to put that line back in proportion, above a loose dog's pass and well under half the meter. The rig has to put the instance in the tree, or `_build_the_flock()` never runs and `contribution_at()` answers off the def's modelled ring instead of eleven birds that fly away from her. The rim pays for the cut: a flock skirted 80px off the middle never fires the flush and so felt the rate and nothing else. It is **eleven birds**, each with its own heading, height and wingbeat, and each an emitter, so the middle of a flock stacks four or five fields and the rim stacks one — the only row in the game that is more than one source, and the one row exempt from a body for it. `EventDef.scenery` is set, so `EventScheduler._role_for` answers `NONE` for it rather than the `WALL` its cost would otherwise earn — a flock is scenery, not a block, and it lands on a route corridor exactly as it lands anywhere else. |
| `cyclist` **`hard_fail`** | RECURRING (`TOWARD_PLAYER`) | 2 | **The first thing in the game that can end your day.** A kid on a bike on the pavement she is walking, bell going, coming toward her, down her own side of the road — sited when she gets close rather than on a street the day chose at dawn, so she answers it with a route decision (cross, or turn) instead of finding out too late it was never on her way. Everything about it is ordinary, which is the point: act I does not become sinister, it becomes a real street. The bell rings for 2.97s, what the doubled margin costs at a 90px field grown forward by its own speed — smaller than the fairness contract alone would allow, so the wait before it arrives stays a real reaction window rather than several seconds of watching it close from off screen. Its lethal `inner_radius` is 33px, widened from 26 so the far lane of her own pavement no longer clears it by construction — the same overturn `chatting_mother`'s `detain_radius` went through first. |
| `ice_cream_van` | RECURRING | 2 | The `busker` argument one size up: nothing about it is threatening, it is simply interesting. The widest ordinary radius in act I. At the kerb, and solid at 24px: a thing children cross a road to reach rather than a thing standing in one. A **wall** by passability — 189px of charging disc leaves no lane of a sidewalk free — so the street it is on is one she walks the far side of. |
| `reversing_lorry` **`hard_fail`** | RECURRING | 3 | Act I's second lethal thing, teaching the opposite lesson to the cyclist. That one comes *at* you and the answer is to get off the pavement; this one is **stationary and the danger is behind it**, so the answer is not to walk into the gap it is backing into — which you have to look at the world to know. The beeper is the telegraph. It stands `AGAINST_THE_BUILDING`, turned to face out of the frontage, solid at 28px inside the 46 that ends the day. |
| `charging_dog` **`hard_fail`** | RECURRING (`AHEAD_OF_PLAYER` on `RUN_TAUGHT_DAY`, `MAP` after) | `RUN_TAUGHT_DAY` | **The one thing running is the answer to**, and the day the run is taught. Sited 0.5s of closing outside the view (`offscreen_notice`), it spends `telegraph_time` 4.5s visibly closing at the stand-off, then chases at 130px/s for `Tuning.PURSUIT_TIME` — the further siting needs the longer telegraph so walking away still loses inside the row's own budget. Its 150px field is **wider than the stand-off** — a narrower one is a field the pursuer is never inside, so the warning would emit nothing at her and the `!` over her head would never go up; `validate_pursuit` refuses that. `max_per_day` 3, because a street with three of them turns the run button from an answer into a second walk speed. It trots off at 110px/s rather than blinking out: a dog that gives up in front of her and is then not there says the chase was never real. No `last_day`: it recurs after `RUN_TAUGHT_DAY`, but only that one day sites it on her exact heading — past it, `spawn_mode_on()` answers `MAP` and the row is placed on a tile and met by routing into it, the way `alley_robbery` is, rather than sited by the director — see "Where an event happens" above. **It does not stop being director-sited, either.** Past `RUN_TAUGHT_DAY` a `MAP` placement waits for her — `pursues_within_after_first_day` 130px, inside its own 150px `outer_radius` — rather than announcing itself the moment it streams in, and `EventDirector` now and then still sends the day-3 shape itself — off her heading, already noticing her, no tip, `Tuning.CHARGING_DOG_SPRINKLE_CHANCE` of the days it is eligible — so the lesson's dog and the later dogs are one animal, and the guarantee plus the tip are the whole of the difference. See "Where an event happens" and `EventDef.pursues_within_on()`. |
| `chatting_mother` | RECURRING | 1 | Another mother with a pram, paced along eight tiles of pavement like `homeless_yeller`. Her ambient field is person-scale (intensity 4.5, near a passer-by's 4.2) and tight (56/70px — the inner radius sits just outside her capture, which the catalogue's own check requires), so a normal pass costs a normal close pass. Entering `detain_radius` (48px, three quarters of the pavement band, so neither lane of her own pavement walks past her while the far pavement still does) of an instance that has not chatted yet locks the player's movement input for `detain_seconds` (5s) — the one mechanic in the catalogue that takes the controls away rather than costing a meter; the existing idle rules price the stop, so nothing new prices the time. While the conversation runs and the baby is **awake** it adds a flat `Tuning.CHAT_EXCITEMENT` (25) over the whole capture; **asleep** it adds nothing, gated on the baby's own state read from `EventInstance.baby_awake` rather than scaled through `SLEEPING_SENSITIVITY` — a *pure* time loss means exactly zero, not a smaller number. One conversation per instance: she is then spent as a detainer and departs like a `dog_walker`. |

### Act II — Something is off (days 4–7)

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `police_patrol` | RECURRING | 4 | Mobile, unhurried, along a corridor. Not dangerous yet — the danger is that you start planning around it. In acts III and IV, extra copies of this row are also what the return leg owes — see "The return owes her patrols" above. |
| `poster_crew` | RECURRING | 4 | Static, weak, and solid at 11px. Cosmetic dread; it is here so the walls change. **Sited from her walk** (`sited_on_her_way`, `pastes_a_front`): rolled and placed at dawn like any recurring row, then handed to her walk and sited one crew at a time on the branch she is walking, in front of a blank ground-floor cell and facing it, where it pastes its wall while she can see it — see "The crews paste the walls she passes". At dawn it stands `AGAINST_THE_BUILDING`, the way `reversing_lorry` stands, on a north-south street with a real building on the far side, and that placement is what spends the day's stream exactly as before. Centred (`ANY`, the default) it would leave under 28px on each side of the band and be a wall by physical fit; pinned at the frontage, it spans 5-27px of the band and leaves 37px to the kerb, so it stays friction. A sidewalk row only: a square has no frontage lane for a pinned body to stand in, and `poster_crew_square` below is the square's own crew. |
| `poster_crew_square` | RECURRING | 4 | The same crew on a square, pasting onto a free-standing advertising column — every number is `poster_crew`'s, because it is the same event on the ground a row pinned against a building cannot stand on. It takes no pavement side, so `EventInstance` centres its 11px body on the tile it is given, and its picture carries the column beside the worker. The density is the sidewalk row's own, split rather than added: about one poster crew in a hundred used to land on a square, which is the square share of the ground the roll draws from, so this row carries a hundredth of that row's weight and is a rare sight by measurement. |
| `loudspeaker` | SCRIPTED | 5 | **A mast on a street, with a field.** Six of them (`Tuning.MAST_COUNT`), sited once by `MastSites.compute()` — junction corners, commercial squares, the main road, each snapped to her own sidewalk or a square's paving — and placed fresh every day from `Tuning.MAST_FIRST_DAY` by `EventScheduler._place_masts()`, bypassing the ordinary roll: `scripted_day` stays 0, the seal pictures' own sentinel. `MastSites` also refuses a site near where a region door could ever stand (`Tuning.CHECKPOINT_EVENT_GAP` of any boundary segment's own door position — the boundary is fixed at generation, so the refusal costs no day-to-day variety); a site is skipped for the day rather than planted over them for the narrower case a day's own closures, region wall or checkpoints still catch — an alley door among them, or held ground — rare, since a closure is one street's own width against the whole city. Same field shape as `homeless_yeller` (inner 45px, outer 210px), so walking past a speaking mast on its own sidewalk costs what walking past him does — [COSTS.md](COSTS.md): both 40.0 to walk straight through. `pulse_period` 22s, `telegraph_time` 3s, repeating: `EventInstance._mast_is_telegraphing_now()` reads the mast's own `age`, which is `EventManager._broadcast_clock` rather than a clock of its own, so every mast telegraphs and speaks in the same phase. Solid at `EventCatalogue.MAST_BODY` (6px), a pole rather than a body to edge past. **A mast she silenced stays silenced**: day 11's task sends her to the foot of one live mast, and reaching it silences it through `EventManager.silence_mast()` and leaves an `EventScheduler.SILENCED_MAST` scar at its foot, which `_place_masts()` reads on every later day to plan that mast already silenced — pole and horns standing, lamp out, no field. |
| `curfew_announce` | SCRIPTED | 6 | What the masts carry on `Tuning.CURFEW_ANNOUNCE_DAY` instead of their ordinary broadcast — placed by `_place_masts()` at every mast site alongside that day's `loudspeaker` plan, `Look.NONE` so the mast's own picture (the pole, the lamp, the arcs) is what is seen. Same field shape as the ordinary broadcast, stronger (intensity 30 against 20), brief and fading (`intensity_ramp` 0.2, `duration` 26s). The mechanical bite is in `Tuning.day_length`, which shortens every day from 6 onward; this is the moment you are told. |
| `roadblock` **`heat_response HUNTS`** | RECURRING | 7 | Loud, and **physically closes a street** (`obstructs_radius` 60), drawn as one continuous barrier (`roadblock_segment.svg`/`roadblock_end.svg`) rather than a row of blocks. The first event that takes a route away rather than making it expensive. Named `roadblock` rather than `checkpoint` because the region wall's own door structure — a hut, a gate and guards you can pass at a price — took that word; the two rows mean opposite things about whether a street can be crossed. **A guard stands at it from the moment it is placed** (the eight-view `guard_standing_*` family, drawn at the band's own centre), cold or hot; cold he is a drawing with no field, body or cost of his own. Below `Tuning.HEAT_HUNTS_LEVEL` that is all it ever does; at or above it **that guard** is what sets off, from where he stood, coming at 130px/s once she is within 180px and switching to `guard_lunging_*`, turned to face where he is heading, when his 1.8s notice ends. The barrier he leaves stays drawn and stays solid where it was built (`body_stays_behind`), so the street stays shut behind him; the catch is `lethal_radius` 28px measured from **him**, a man's reach rather than a barricade's, and the band itself takes nobody. |
| `checkpoint_hut` | SCRIPTED | 7 | `RegionPlanner`'s own structure, not a catalogue roll: two stand at every open region-boundary street crossing, one on each pavement, doorway facing the carriageway. Detains for `Tuning.CHECKPOINT_DETAIN_SECONDS` (2s) as she comes within `Tuning.CHECKPOINT_DETAIN_REACH` (48px) of its own solid edge — 80px from its centre, inside `inner_radius` 84px — and `redetains`, so the same hut tolls her again on a later approach from either side. A small `intensity` (4.0) over a tight 84/98px band is "a bit of excitement" on top of the flat `Tuning.CHAT_EXCITEMENT` the detention charges, and it is deliberately not what makes the row expensive: it is one of the three **detainers** exempt from "nothing is cheaper to walk through than around", priced by its capture instead. Low because a door is several bodies and a hold earns no decay — see "Checkpoints" and the `barrier_structure` note above. |
| `checkpoint_gate` | SCRIPTED | 7 | The boom over the road between a door's two huts. No field of its own — a car passing under it costs her nothing — and **never an inspection**: `lifts_for_traffic`, so it is solid to her while the arm is down and ground she may walk under while a car holds it up, and it does not come down while any of her rig is beneath it. A hut beside it does not take her in from the carriageway it spans. Drawn raised or lowered from the shared `RegionPlanner.GateState` `Crowd` keeps current. |
| `checkpoint_post` | SCRIPTED | 7 | The alley half of a door: one guard at each mouth of a through-alley that crosses a region boundary. Detains exactly like `checkpoint_hut`, same numbers and the same `redetains`. |
| `door_guard` **`hard_fail`** | SCRIPTED | 9 | The guard a door sets on her when she walks across its line rather than through a hut — under a raised boom — placed by `EventManager` alone, one at a time, stepping out of the wall of the nearer hut on the side she crossed to. The roadblock's hunting guard copied: the eight-view `guard_standing_*` then `guard_lunging_*`, 130px/s, a 1.8s notice, a `Tuning.PURSUIT_TIME` chase, a 28px catch (`MASKED_MAN_REACH`), and `masked_pursuer`'s field (18 over 28–120px). `hard_fail` on every day and at every heat, not through `heat_response`. `sets_off_beside_her`, so his notice is held ground rather than an approach — see "Checkpoints". His badge is the side view, the one picture of the man no other look stands for. |

### Act III — Disappearances (days 8–11)

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `abduction` **`heat_response HUNTS`** | RECURRING | 8 | An unmarked van idles first — that idling *is* the telegraph, and it runs 4.6s because the inner radius is a `hard_fail`. Getting close does not excite the baby; it takes you. Solid at 22px, comfortably inside the 54 that takes her, so the metal is metal and touching it is still fatal. While she is close enough to watch (`outer_radius`), it draws its own bystander walked to it and taken — a scripted figure rather than a `CrowdAgent`, since the crowd is recycled as she moves and could never be a lasting fact about the world. Below `Tuning.HEAT_HUNTS_LEVEL` that is all it ever does; at or above it, it stops idling for a stranger and starts hunting her instead — 130px/s once she comes within 180px, for the length of the chase rather than the length of the idle, `hard_fail` throughout. |
| `alley_robbery` **`hard_fail`** | RECURRING | 8 | **A man who is worth crossing the road for, and who comes after you if you do not.** Three numbers for three sentences: intensity 16 over a **200px** field, so the far end of an alley is already expensive and the meter is the only warning a robbery will ever give; `hard_fail` inside 30px; and `pursues_within` 140, inside which he takes 1.8s of visibly coming and then chases at 130px/s. The alley is the warning and it is not the only one — a lethal thing that does nothing at all until it does everything is a thing with no telegraph. |
| `night_raid` **`heat_response HUNTS`** | SCRIPTED | 10 | Enormous, static, pulsing, and it closes the block (`obstructs_radius` 44). Below `Tuning.HEAT_HUNTS_LEVEL` that is all it ever does; at or above it, it stops closing the block for the night and hunts her instead — 130px/s once she comes within 180px, and `hard_fail` inside 70px, which the cold raid never is. The tasks before it fall on days 6 to 9, so on day 10 the most progress anybody can hold is four, which is `HEAT_HUNTS_LEVEL`: the raid hunts only a player who has done every task on time. **The raid at her own building is this row too**: two vans on the far sidewalk of her street, `RAID_VAN_OFFSET_TILES` either side of her door, with a `police_patrol` pacing the carriageway between them, placed by `ResistanceHappenings` once she is out of sight of her door — always cold, since a van hunting her at her own door would make the doorstep the one place the day cannot end. Her own sidewalk stays open past the door both ways. |

### Act IV — Open conflict (days 12–14)

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `military_convoy` | RECURRING | 13 | Drives its street and stops where what it leaves belongs: a `barricade`, through `spawns_on_finish`. From day 13, the morning the army arrives, rather than with act IV: day 12 is the parks. **Day 13's column is this row too**: `ResistanceHappenings` sends `Tuning.COLUMN_TRUCKS` (3) of them, `Tuning.COLUMN_SPACING` (128px) apart in one lane of the main road, toward the point level with her once she is within `Tuning.COLUMN_WITHIN` (480px) of it across, or at `Tuning.COLUMN_BY` (100s) into the day wherever she is — from `Tuning.outlasting_telegraph_lead()` up the road, so each truck's telegraph is over before its field reaches her, or from the map's edge where the road runs out first. Only the rear truck keeps its `barricade`, stopping `Tuning.OUT_OF_SIGHT` plus its own field reach beyond her, mid-street rather than in a junction, at the first such point whose barricade still leaves her a way home and to a calm area (`EventScheduler.WalkSiting.leaves_her_a_way()`); the trucks ahead of it drive on to the map's edge and leave nothing. |
| `barricade` | — | — | Never scheduled directly by the ordinary catalogue roll — `scripted_day` 0 never equals a real day. Two things place it: left where a convoy stopped, and — via `scar_id` — left there for the rest of the **run**; or placed fresh, without a scar, every morning from act IV onward as a **hard seal** on a street off the day's route tree (`SealPlanner`, `obstructs_radius` 62 repeated across the street's whole width so nothing gets past it) — see docs/CITY.md, "Sealing the tree". |
| `protest` | RECURRING | 12 | `intensity_ramp` 1.9 over 150s: a protest you could have walked past when you saw it is not one you can walk past two minutes later. **Solid at 55px**, and `_draw_protest` draws two ranks across exactly that width — the clearest case in the catalogue of the picture deciding a gameplay number, because a body may not claim ground the drawing does not. Under its own `inner_radius` on purpose — the loudest part of a protest is something you stand in rather than bump into. **A wide field at a moderate rate loses more of its price to the walking decay than any other row**, netted off as that is over the whole of a long crossing, which is why its intensity is set high against `Tuning.WALL_WORTH_OF_COST` rather than comfortably under it: a little more and `walk_through_cost()` crosses that line, `_role_for` calls it a `WALL` and it is pulled off every route the day carries — and a protest is where a resistance task sends her. [COSTS.md](COSTS.md) has where it actually sits. **A rank points at the resistance's own objective**, one of eight `protester_point_*` poses picked by whichever 45° bearing from the protest to the objective is nearest, whenever today's resistance step has a position and is not a chalk mark. *(2026-09-11, the player: "the mark is findable now -- I don't think we need pointing for that. but the other tasks are not as easy and need pointing.")* A mark step, or no step at all, draws the plain rank. `max_per_day` is 12: a protest obstructs nothing off its own tile and pursues nothing, so raising it never competes with anything else's own cap. |
| `firefight` | SCRIPTED | 13 | The worst thing in the catalogue. Extreme, `hard_fail`, 6.5s telegraph, and it shuts a junction. Solid at the width of its cover. Its picture is **people** doing this, not a street on fire — that is a burning building's picture, and the two rows are not the same event. |

The day-14 sabotage is not a catalogue row: it is `GameState` logic (`sabotage_done`,
`sabotage_available()`), gated on the resistance goal rather than sited or scheduled like an
`EventDef`. `docs/NARRATIVE.md` and `docs/DESIGN.md` describe what completing it does.

### Seal pictures — off the day's route tree

Eight pictures so no single barrier is the city's signature (`docs/DECISIONS.md`, M64). Every row below
is `SCRIPTED` with `scripted_day` 0, so — like `barricade` above — the ordinary catalogue roll never
schedules one; `SealPlanner` places each fresh every morning on a street off the day's route tree,
reading `act_tag` for the first day it may. Seven of the eight are silent (`intensity` 0): *"static
blockages in general shouldn't increase excitement."* `car_accident` is the one that is not, because
it is the one whose body cannot match its picture without leaving a way through — see "Solid things
are solid", and `docs/CITY.md`, "A closure is silent".

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `fallen_tree` | SCRIPTED | day 1 | Placed fresh every morning as a **hard seal**: a tapered trunk down kerb to kerb, branching roots at one end and an irregular crown at the other. `obstructs_radius` 96, exactly half the 192px street, so `SealPlanner._hard_positions` places one body spanning it edge to edge. Each street axis has its own continuous scene, selected by `EventInstance._wide_scene_texture`. The picture spans equally to either side of the ground point across the street. On an east–west street its vertical extent is centred on that point too; on a north–south street its bottom edge meets the ground point. |
| `car_accident` | SCRIPTED | day 1 | A **hard seal**: two cars locked together across the carriageway, glass between them, smoke puffing up off the wreck in two alternating frames, and an onlooker on each pavement. The cars follow the street: end views next to one another on a north–south street, side views arranged across an east–west street. Both pictures keep the people upright. Separate shadows ground each car and onlooker without darkening the space between them. The scene closes the whole 192px street the way `fallen_tree` does, and is **solid only at the two cars** — 14px of body apiece, placed from each picture's own ground contacts — so the debris and both pavements are walkable. What closes them is the field: `Tuning.CAR_ACCIDENT_INTENSITY`, the only seal that emits, at `inner_radius` `GroundShape.BAND_RADIUS` over the scene's own band with a 72px shoulder. Squeezing past costs more than half the meter (`tests/test_seals.gd`). |
| `skip` / `scaffolding` | SCRIPTED | day 1 | A **soft seal**: a skip at the kerb facing scaffolding boards over the far footway — the two-obstacles-facing-each-other reading of a soft seal, drawn as two different pictures rather than one row twice. `skip` is kerb-pinned like `delivery_van`; `scaffolding` fills the whole pavement band like `construction`. |
| `burst_water_main` | SCRIPTED | day 1 | A **hard seal**: broken asphalt, an exposed pipe and water fountaining and splashing across the carriageway in two alternating frames, with an upright municipal barrier at each kerb. The directional pictures place the damage across the street while retaining the barriers' standing projection. Same single-body geometry as `fallen_tree`, but draws no body shadow (`draws_body_shadow = false`) — the crater is a hole in the ground, not an object standing above it. |
| `moving_van` | SCRIPTED | day 1 | A **soft seal**: a lorry at the kerb with its ramp down, the same body on each pavement. Its own side and end views show the cab, cargo box, open loading doors and ramp, with the view chosen from the street axis even while the vehicle is stationary. The picture stays distinct from the reversing lorry. |
| `burnt_out_car` | SCRIPTED | day 4 | A **hard seal**, from act II onward: a damaged car shell in the charred palette of `burnt_shell`. The cars lie perpendicular to the road: the side view serves north–south streets and the authored vertical view serves east–west streets. Vehicle-scale `obstructs_radius` lets `SealPlanner._hard_positions` place the individual wrecks across the street as a pile-up. |
| `collapsed_frontage` | SCRIPTED | day 4 | A **hard seal**, from act II onward: rubble spilled frontage to frontage, drawn the way `_burnt_shell` draws `rubble.svg` — a small debris segment repeated by `_draw_spread` — but its own picture, styled beside `rubble.svg` rather than sharing it. |

### The story's own figure — the neighbor

One row the ordinary roll never reaches (`SCRIPTED`, `scripted_day` 0): the resistance places it.

| id | kind | from | Behaviour |
| --- | --- | --- | --- |
| `neighbor` | SCRIPTED | day 1 | The neighbor down the hall, who works at the power station (`docs/NARRATIVE.md`, "What the tasks are for"): a figure in work clothes — steel-blue coveralls, a reflective band, a dark work cap — drawn in the passer-by's own five views and feet-passing frames. **Scenery, not a cost**: intensity 0 on a formal field drawn tight round the figure, mobile and therefore bodiless, walking at `EventCatalogue.NEIGHBOR_WALK_SPEED` (46px/s, half hers). On every morning before day 10, `ResistanceHappenings` walks it out of her building beside her and off along her street, away from her, until the street runs out or a closure stops it, and it leaves the ordinary way; nothing points at it. **On day 10 it is walking home**: once her mark is touched, `ResistanceDirector._send_the_neighbor_home()` spawns `EventCatalogue.neighbor_heading_home()` — the same row, `stops_where_it_arrives` — on a sidewalk about `Tuning.NEIGHBOR_WALK_HOME_SECONDS` (55s) of its own walk from her door and off screen from her, and hands it the walk home over the day's open ground as its path; the red arrow rides it. Reached first, it runs, away from her, at `departs_at` `EventCatalogue.NEIGHBOR_RUN_SPEED` (150px/s); reaching the door first, it stands there, the task is lost, and it is taken away with the raid once it is off screen. From day 11 it never appears. |

### The escape — the walk that is not a day

Four rows nothing but the escape ever places. All four are `SCRIPTED` with `scripted_day` 0, the
same gate the seal pictures use, so the ordinary catalogue roll can never reach one:
`FinalePlanner` places the first two on the city's open chains and `InteriorEvents` places the last
two inside the building. Three rows the escape uses are not new and are not changed —
`military_convoy` is the army truck (with the barricade it ordinarily leaves stripped, since a
convoy in the escape is traffic rather than the aftermath of something), `abduction` is the masked
men in a van, and `roadblock` at full heat is the masked man on foot who leaves the post — the barrier he was standing at stays where it is and stays shut.

**The escape rolls its ground per street rather than per city** — `EventScheduler._finale_ground`
over one segment's own rect, since the chains already say which streets exist for it, there is no
corridor to weight against and no closure to avoid. Of the five refusals above it keeps the two
that are still true of a walk with no day behind it: a tile must be open, and **a standing street
tree's ground is refused here exactly as it is on a day** (`docs/CITY.md`, "Street trees").

**And the ground she is put down on is refused to everything that could already be reaching her**
(`EventScheduler._clearance_around_her`), because *"the spawning shouldn't be a check. the pathing
should start from the position. then obstacles can never happen."* Two reaches, and the wider one
wins: a row with a body keeps her body plus its body clear, and a `hard_fail` row keeps its whole
**`outer_radius`** clear — the radius `EventManager` raises the doubled exclamation mark over,
because it is what the telegraph contract promises her time to walk out of, and a lethal row
placed inside it has spent her notice before she has taken a step. Both carry half a tile on top,
since a stationary body is recentred on the pavement band when the instance is built. Refused at
the candidate loop, never moved afterwards.

| id | kind | where | Behaviour |
| --- | --- | --- | --- |
| `finale_explosion` | SCRIPTED | the chains' carriageways, and once a beat indoors | The bang she hears and does not see. **Draws nothing** — the fourth row in the catalogue with no picture — because there is no burst on the street, only the noise and the hole afterwards. Off screen is bought with the streaming radius rather than with a rule: a `MAP` placement enters the world at `Tuning.EVENT_STREAM_RADIUS` (900px) against a 640×360 view, and its telegraph plus duration (3.7s, about 340px of walking) are over before she can reach it. `intensity` 24 over a 300–520px band, so a burst just past the screen edge still lands close to full strength. Not lethal: *the danger is always noise*. `spawns_on_finish` names the crater. |
| `impact_crater` | SCRIPTED | wherever a burst went off | What is left in the road, for the rest of the sequence (`duration` 0). Silent and solid, with `barricade`'s own radii; `obstructs_radius` 32 against a 64px picture, so the ground she cannot walk on is exactly the hole she can see. Also one of the escape's four seal pictures, where `SealPlanner._hard_positions` spaces three of them across a street. No `scar_id`: the escape is the last thing in a run, so there is nothing for a scar to persist into. |
| `masked_pursuer` | SCRIPTED | the stairwell the fire did not close | A masked man running up the shaft. **Mobile, not `pursues`**, and that is the counterplay: he runs a line — bottom landing to top — and the answer is not being on it, which in a building whose stairwell doors are a fade and a teleport means stepping through the nearest one and letting him go past. Faster than a walk (`Tuning.HEAT_HUNTS_SPEED`, 130px/s) so he cannot be out-walked, `hard_fail` on contact, and no body, like everything mobile. He waits at the foot of the shaft until she is in it (`pursues_within` 900, the shaft's own height with room over it) and spends his 3.6s telegraph standing. **One of him at a time, and there is always another**: `InteriorEvents` places a fresh instance `Tuning.FINALE_PURSUER_RESPAWN_SECONDS` after the last one has run out of the top of the shaft, for as long as she is in the building — a fresh instance rather than a rewound one, so every run waits and telegraphs exactly as the first did. From every cell of his line a door is under two seconds' walk away against the three and a half he stands still for, which is what keeps *stepping aside* an answer he cannot outpace. Drawn from the eight-view `guard_standing_*` family then `guard_lunging_*`, turned to face where he is heading, the same two postures a heated roadblock's guards take. |
| `basement_steam` | SCRIPTED | a fixed vent on the basement corridor | One blow of a vent that stands on a timer, its plume billowing in two alternating frames for as long as the blow lasts. **It is a gate, not a lane to thread**: the body is half of `steam.svg` like any other, but it stands on a cell where the basement corridor is **one tile wide** (`InteriorMap.BASEMENT_NARROWS` — the two jogs between its bands and one narrowing laid across the middle band), so her centre is held 30px out where the walls leave it 16px of play — there is no way past a vent that is blowing, and the answer is waiting rather than aiming. A vent in a two-row band leaves her the far row whichever row it stands on, which is why all three stand in the narrow stretches; each is a cell the walk to the exit cannot go round, checked by taking it out of the map. **The notice is what makes that fair, and `solid_once_it_starts` is what makes the notice worth anything**: the body goes down at the end of the telegraph rather than with the instance, and is withheld for as long as she is standing in the footprint, so a vent never closes around her. 14 over a 24–90px band, pulsing every 4s, for `Tuning.FINALE_STEAM_BLOWS_FOR`. `InteriorEvents` owns the vents themselves — where they stand, and a period each out of `Tuning.FINALE_STEAM_PERIODS` — and spawns one of these per blow; between blows there is no instance at all, so a vent that is off costs nothing. **Its floor grate is there the whole time**: `InteriorEvents` lays `steam_grate.svg` at every vent for the whole section, blowing or not, with no body and no field, so the gate is in sight before it shuts and she times it from the corner rather than finding it by its notice. The grate is ground, drawn under her and under each blow, so she walks over it between blows and the cloud rises out of it. |

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

**On the three days the resistance sends her to one narrow place** — day 9's region door, day
12's swing, the power station's front door on the last night — the same pass also keeps a route to one tile of that place,
counting the day's seals and region wall as standing (it never drops those). The day is planned
so that route exists before this pass ever runs; the pass is the last line for the catalogue's
own bodies. `docs/CITY.md`, "Guarantees", has the whole of it.

## The emission model

An event never pushes a value at the baby. Each frame the baby asks the world for the total
stimulus at its position, and the world sums `contribution_at()` over the live instances:

```gdscript
func contribution_at(world_position: Vector2, ...) -> float:
    var velocity := travel_velocity()  # or the override expected_impact_at() passes
    return def.emission_at_distance(_field_distance(world_position, velocity),
            current_intensity())
```

Because it is a pure query there is no ordering to get wrong, events compose by simple
addition, and an instance can be tested without a scene.

**A row may carry a second, louder part close in, and one does.** `EventDef.core_intensity` and
`core_radius` are a core: the same curve over a shorter band, and the row emits **the larger** of
the core and the field at every distance, so a core only ever adds and only ever inside itself.
`leaf_blower` is the row it exists for — past `core_radius` it is a busker, number for number, and
inside it, it is a wall. Every other row leaves both at zero and is one field as before. **A core
answers a body standing still at `inner_radius`, not a pass at `Tuning.WALK_SPEED`**: at walking
speed a body crosses even a wide core in a fraction of a second, so a core buys little against a
pass measured that way — see `homeless_yeller`'s own entry above for the row this ruled out.

**`EventDef.emission_at_distance()` is the one place the two parts are put together**, and
everything that prices this row goes through it: the cost table below, the placement rules that
read what a row denies, and `contribution_at()` above, which is what the baby is actually charged.
The instance hands it `current_intensity()` rather than the catalogued peak, so **the telegraph and
the pulse damp the core by the same fraction they damp the field by** — a leaf blower between
bursts is a quarter of a wall inside a quarter of a busker, not a full wall inside a quiet field.
A row with no core comes back as `Tuning.falloff` on its own field and nothing else, bit for bit;
`tests/test_events.gd` walks the whole catalogue at 16px steps and holds that.

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

**[`docs/COSTS.md`](COSTS.md) is the generated, checked-in table**: one line per catalogue row, its
geometry and role, the net rate while walking a fixed distance from it, and the net points from a
real pass at `Tuning.WALK_SPEED` — awake and asleep, at fixed distances and offsets identical for
every row. `tools/cost-table.sh` regenerates it from the real `EventDef`/`EventInstance`/`Tuning`
code the game charges with, never a hand-computed copy; `tools/cost-table.sh --check` (wired into
CI) fails and names every row and column that moved when a balance change touched the catalogue or
a decay constant without regenerating it. What follows here is the reasoning the table's own numbers
rest on — regenerate the table itself, do not hand-edit numbers back into it.

**The shape of `Tuning.falloff` is `1−t^power`, and every row is at the 2.0 default**, so a field
holds three quarters of its intensity at the midpoint of its band. The middle distances are what cost: the meter has to go substantially up from
some way off rather than waiting for contact, and a `(1−t)²` field — a quarter of its intensity at
the midpoint — is one you can stand almost inside for free.

**The integral prices a field, not a route.** Being stopped by a body is a route cost neither
`walk_through_cost()` nor `docs/COSTS.md` counts, and a solid row is one most straight-line walks
cannot actually be made through at all; see "Solid things are solid". It is still the right way to
price a **row**: it is what being close costs.

**A row is priced at the point of its own life she meets it at, and for a `TOWARD_PLAYER` row that
is inside its telegraph.** A `MAP` placement was made at dawn, so by the time she walks up to it
the telegraph is hours over and the pass is the whole field at full strength. A row the director
sites down her own line is created the moment it is owed and covers the ground between at
`Tuning.TELEGRAPH_INTENSITY_FRACTION` of its intensity, so how far out it is sited decides how much
of the meeting is spent on the warning rather than on the event. That is a placement decision
rather than a field one, `EventDef.toward_player_lead()` is where it is taken, and the pass columns
of `docs/COSTS.md` are measured through it — a row that arrives while still telegraphing has spent
its whole encounter warning about itself.

**Three kinds of row are priced differently from what a straight read of the field would suggest.**
A `hard_fail` row's `walk_through_cost()` is notional, because nobody finishes the walk. `car_accident`
is the one row whose body does not span its own field — solid at its two cars and open between them,
so the line it prices is one she can actually walk, which is what "the integral prices a field, not a
route" costs everywhere else. A **flock** (`flock_size` birds sharing `intensity` between them and
wheeling inside `flock_spread`) breaks the assumption every other row's figure rests on, that *all of
the intensity is at the centre*:

- **Its cost is computed from the birds**, not from one disc. Priced as a disc it reads roughly
  twice its true figure and breaks the running rule on a row that in fact keeps it, which is
  exactly the kind of silent breakage that rule exists to catch. `tests/test_events.gd` models the
  flock the same way, so the two cannot drift.
- **The straight line through the middle is not the whole story for it.** Walked against the real
  instance it costs several times as much through the centre as eighty pixels off it, and nothing
  at all at the rim. Every other row falls away gently from the middle; a flock is a hot spot with
  a wide quiet margin, and that gradient is the reason to build it out of eleven sources rather
  than one.

**The ground every one of these rows stands on is a fact the table does not carry**, and it is
large:

- **An ordinary footway is net recovery to walk, and visibly so.** The quietest pavement in the
  city charges 70–120 points of crowd over a forty-second walk against a decay that pays back 240
  — measured over three seeds by `tests/probes/m117_decay.gd`, which is what to run again when a
  rate moves. So an authored row on an ordinary street is very nearly the *whole* of what that
  stretch costs, which is what the table's own figures assume.
- **The middle of a pavement is the cheapest line along it**, by `CrowdLanes.SIDEWALK_LANE_SPREAD`,
  which spreads the walkers off it: an ordinary midline is 56 points per forty seconds.
- **Crossing the main road costs about 30**, and the wait at its lights about 33 more — between them
  a `dog_walker` and a `loose_dog`, and neither is in `docs/COSTS.md` because neither is an event.

That last point is the one to carry: the cost of a route is not only the events on it, and the
*street kind* is a bigger term than most rows in the table. A balance argument that reaches for the
table alone is answering a narrower question than it thinks.

**No cue says which rows carry a caret, because no row does.** The caret is decided in play
from a source's own projected course at wherever she is standing — `expected_impact_at()`
against `Tuning.EXPECTED_IMPACT_POINTS`, `will_be_lethal()` for the doubled red — so the same
row reads red on one approach and carries nothing on another, and a stationary row never
carries one at all; see "Showing the danger".

**A pursuer follows, so there is no crossing to price for it and no pass to measure either** — the
same reason `docs/COSTS.md`'s own pass columns are dashed for one. Walking away from a pursuer loses
the day; running away costs 35 points from the lunge and less the sooner it is given. See
`docs/MECHANICS.md`, "Running that matters", for the measured tables.

**Three rows are cheap to walk through by taste, three are priced somewhere else, and every
zero-intensity row is cheap by construction.** `burnt_shell` and the two poster crews —
`poster_crew` against a wall, `poster_crew_square` at a column — are scenery asked to be nearly
free on purpose, and the crews are one decision rather than two: the same field on two kinds of
ground. `chatting_mother`, `checkpoint_hut` and `checkpoint_post` are the
**detainers**, whose price is not their field at all: coming close locks her movement and charges
`Tuning.CHAT_EXCITEMENT` flat over the hold, so a disc sized to clear the walking decay as well
would be charging the same body twice. `tests/test_events.gd` names both lists, and holds the
detainers to charging their capture instead — an exemption that owes no check of its own is a way
of not being tested.
`construction`, `delivery_van` and `barricade` sit well below zero for a different reason: **a
thing whose whole job is to stand in the way costs route and nothing else**, so `intensity <= 0.0`
is its own blanket exemption — walking "through" a solid body was never a real choice to price, and
the negative figure is what `walk_through_cost()` answers once nothing at the centre is left to
outweigh the walking decay. Everything else — every row that still emits — must be more expensive
to walk through than to walk around, or the correct play is to plough into it. A new zero-cost row
is a decision about what a thing is (a pure obstruction) rather than a number nobody checked; a new
*positive* exemption is the one that still needs naming by hand.

**Running is correct on exactly one row in the catalogue, and every other row is why that is a
threshold rather than a taste.** Running costs `EXCITEMENT_FROM_RUNNING` (14.0/s) *and* collapses
the decay from 6.0/s to 0.5/s, so it is a fixed price per second against a saving that is only ever
the shorter exposure — which means walking wins on every field whose mean emission along the line
sits under about 30/s, and that is every row but `car_accident`. The crash is the one asked to cost
more than half the meter to squeeze past, and no field short enough to be *felt walking up to it*
rather than from down the street can charge that without clearing the threshold. So sprinting past
a crash saves about seven points of a hundred, and the answer to it is still the route rather than
the run. Making running *necessary* remains a mechanic to build rather than a number to tune: it
needs something running escapes, which is a pursuer.

**And what a *street* costs, which is the question `docs/COSTS.md` does not answer.** An errand — home
to the furthest calm block and back, 7,500px through a real day with the crowd and the events both
running — is walked well inside the meter on an ordinary route, and the same day walked carelessly
straight down a busy pavement loses in seconds. What separates them is the crowd rather than the
catalogue: the breakdown at the moment of a contact reads `crowd 30–44/s` against `events 10–14/s`.

**So the crowd is most of what a street costs, and the events are what make it a decision.** That
ratio is the design working: careless is fatal in seconds, careful is nearly free, and the gap
between them is where the game lives. None of it is in `docs/COSTS.md` — a contact with a pedestrian
lands about 10.8 points of jolt and a car's horn about 8, and neither is in the catalogue at all.
See MECHANICS.md.

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
the field it is drawn for: a crowd agent has no def to ring, so on a normal street a few things
would be ringed, most would not, and nothing would explain the difference. **A cue that marks
everything says nothing**, and every rule below exists to keep the replacement from becoming that.

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

**And it re-runs it on every frame the rim is drawn at all, not only while the glow is changing.**
A `_draw()` in Godot is retained: it re-runs when something asks for it and not otherwise, so a rim
traced once is that instant's silhouette until another trace is asked for. The body under a
perfectly steady glow moves all the time — a car changes view as its heading sweeps round a turn, a
flock's birds are somewhere new every frame, a walker swaps gait frame — so the rule is *while
anything is drawn*: at zero alpha nothing is traced, and above it the rim is re-traced every frame
and is always the rim of the body being drawn now. The cost is bounded by the selection rather than
by the crowd, `ExcitementHalo.MAX_SOURCES` (8) rims of twelve re-draws apiece, whatever is happening
on screen.

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
| **Caret over the entity** | *If you both keep doing what you are doing, this will cost you*, or *end your day.* Raised by what the thing is **anticipated to net her — her own current velocity carried forward, not held still** — and by nothing else — see point 1 below. | `Sprites.draw_caret()`, from `EventInstance._draw_mark()` and `CrowdAgent._draw_mark()` |
| **Its colour** | **Amber** at `Tuning.EXPECTED_IMPACT_POINTS` net over the horizon — go round it, or slow down, or speed up. **Deep red, doubled**, when a step of the *source's own* projection (her position held fixed for this one, since it is an absolute claim about the day ending) puts her inside the thing's lethal reach on its current course. The amber threshold reads the same net quantity the halo reads back — points anticipated over the horizon less what her own current decay would give back over it, floored at zero — so a source is amber only while it is actually projected to cost more than walking is already earning back. | `EventInstance.mark_colour()`, `CrowdAgent._caret_strength()` |
| **Its flash** | *It has not started yet.* The telegraph phase, and the only channel carrying it — the colour cannot, because a telegraph is usually over before the event is on screen, so an amber that meant *telegraphing* would only ever be seen on the rows sited in front of the player and would read as *near*. | `EventInstance._draw_mark()` |
| **Breathing** | The caret's size and ride height track *current* emission, so a pulsing event visibly swells and settles and can be timed. A car with no jolt running holds full size, having no pulse of its own to breathe with. | `EventInstance.mark_swell()`, `CrowdAgent._draw_mark()` |
| **Entity halo** | *This is costing you now, and this much — and the bar is rising because of it.* A thin rim hugging the thing's own silhouette — its own sprite re-drawn a few pixels out in a ring of offsets, never a radius, and re-traced every frame so a turning car or a flying flock wears the rim of the body it is drawing now — for every live event and every startled crowd body (a honking car, a bumped walker) whose `contribution_at()` at her own position clears a floor. **Colour** is pale-to-red, linear over its own **net** — what it delivered to her in the last five seconds less its own share of the decay the bar took in that same five seconds, shared between every source in proportion to what each delivered, never below zero (`ExcitementHalo.net_landed()`) — so the halos of every source live at once sum to the bar's own rise over the window, and a rim reads red only while the bar is actually climbing because of it. **Transparency** is the same net on a curve that saturates by fifteen points, so it carries the low end colour cannot show yet. Both fade in and out over a third and four fifths of a second rather than switching. Drawn under the entities, the crowd and the player, and gone the instant she is out of reach of every candidate at once. | `ExcitementHalo`, `EntityHalo`, `assets/shaders/excitement_halo.gdshader` |
| **Edge badge** | *Something lethal or faster than a walk is coming, and this is what.* Off-screen and closing **under its own steam**: a disc at the screen edge carrying the thing's own silhouette, a chevron pointing at it and the distance. Says *what* is coming, not that something is. | `DangerEdge` |
| **Exclamation over the player** | *The clock on you has started.* A `hard_fail` event still telegraphing whose radius covers her, or a car closing on the lane she is standing in. Down the moment it stops being true. | `Stroller._draw_alert()` |
| **Doubled red over the player** | *The clock on you has started, and it is nearly out.* Something lethal is live, she is within `LETHAL_MARK_LEAD` seconds of the radius that ends the day, **and the gap is closing at the speeds in play**. Not *inside the outer radius*, which for a cyclist is thirty times the area that can hurt her and stays true while the bike rides away. | `EventManager._warn_about_the_ground_she_is_on()` |
| **zzz over the pram** | *The baby is asleep* — the return phase, and the state with the most consequence and the least presence on screen. Flashing instead of breathing: *she is stirring*, and waking costs half the sleepiness bar. | `Stroller._draw_baby_cue()` |
| **Waves over the pram** | *She is not settling* (amber, at the calm threshold, where the day stops progressing) and *she is nearly crying* (red, three of them, flashing). | `Stroller._draw_baby_cue()` |
| **Sound lines** | Concentric arcs thrown off a source on the rising edge of a pulse — the visual form of a discrete noise (a yell, a bark, a beep, a siren whoop). Built for the mast (`art/events/sound_pulse.svg`, drawn while it speaks — `EventInstance._draw_mast()`); every other source this row could carry stays queued in `docs/TODO.md`. | `EventInstance._draw_mast()` |

**Nothing is ringed for danger, and that is the rule.** It is a standing decision rather than a
preference: if something new needs signalling, reach for one of the rows above; if none of them
fits, that is a design conversation and not a licence to draw a radius. The one ring in the
table — the entity halo — is not that licence exercised again, and the reason is its shape: it is
one cue, for the cost being charged right now, traced from the thing's own silhouette and nowhere
near a radius that thing reaches. It leaves the caret, the badge and the exclamation mark meaning
exactly what they meant before it existed.

Three rules underneath the table, in the order they matter:

1. **The caret is raised by anticipated net gain, and by nothing else.**

   *(2026-09-08, the player, closing the fork this rule used to leave open: "carets shouldn't be
   chosen by source value but by expected impact value".)* What a row is declared to cost on
   paper decides nothing; what a source is actually projected to land on her, from wherever she is
   actually standing and headed, does. `EventInstance.expected_gross_at()` and
   `CrowdAgent.expected_gross_at()` extrapolate the thing's own current velocity **and her own**
   in quarter-second steps over `Tuning.EXPECTED_IMPACT_HORIZON` (5s), sample the thing's field at
   her own projected position at each step, sum the points, subtract its present rate times the
   horizon, then scale that gross figure by `Baby.current_sensitivity()` and floor it at zero.
   `expected_impact_at()` is that gross figure less what her own current decay (`Baby.decay_rate()`)
   would give back over the same horizon — so two bodies both held still expect nothing, an
   approach either of them is making expects its approach less what walking is already earning
   back, and a departure expects nothing rather than a negative figure. **Amber** at
   `Tuning.EXPECTED_IMPACT_POINTS` (40, the same line the halo saturates red at); **doubled red**
   when a step of the *source's own* projection, her position still held fixed for this one claim,
   puts her inside the thing's lethal reach — a `hard_fail` row's `inner_radius`, a car's strike
   box — on its current course. `tests/test_danger.gd` holds the scenarios this replaces the old
   catalogue-wide rule with.

   **A pulsing row's own rate is the horizon's own mean, not this instant's beat.**
   `homeless_yeller`'s pulse (5s) and `busker`'s (7s) both turn over inside the horizon (5s), so
   holding "as it stands now" for the whole projection could read anywhere from a quarter to the
   full peak depending on which beat the caret happens to be asked on. `EventInstance.
   _pulse_mean_multiplier()` integrates the envelope's own `0.25..1.0` cosine in closed form from
   this instant's own phase forward, so a caret opened at a beat's quiet trough and one opened at
   its loud peak both project the same *whole* five seconds rather than five seconds of whichever
   instant they happened to ask on — exactly `0.625` (the envelope's own mean) whenever the horizon
   is a whole multiple of the period, as it is for `homeless_yeller`, and genuinely phase-dependent
   otherwise, as it is for `busker`.

   **Shared between every source worth a mark, the way the halo shares its own decay.** *(2026-09-20,
   PLAYTEST-115: "with two sources near her every caret reads low", each netting the whole of her
   decay against itself.)* `ExcitementHalo` sums `expected_gross_at()` over every live event and
   crowd body once a frame — the same once-a-frame pass it already runs for the halo's own
   `total_landed` — and hands the sum to every source through `set_expected_total_gross()` before
   asking any of them for a caret; each source's own `expected_impact_at()` then takes its share of
   the horizon's decay in proportion to its own gross, `ExcitementHalo.net_landed()`'s own
   arithmetic read forward instead of back, so summing every source's own answer back up reproduces
   the frame's total gross less the whole decay exactly rather than approximately. A caller that
   never tells a source the frame's total — a data-level test among them — keeps the old, simpler
   answer: the whole of the decay charged against that one source alone.

   **Her own motion is now part of the projection, and that overturns the rule this replaced.**
   *(2026-09-08: "I don't want a caret when walking into a car from the side" · overturned
   2026-09-20: "caret communicates anticipated net gain. basically if I keep doing what I'm doing
   I very likely get that amount in net gain (so the halo will match roughly the caret if that
   happens)".)* A car passing wide of wherever she is *headed* still carries no mark, and one
   whose course crosses her own projected path does — including a car she is walking toward from
   the side, which used to be exempt because her position never moved under the old projection.

   **The trap it is written against** is a rule like *danger that changes over time* — lethal,
   telegraphing, swelling, or pulsing fast enough to be timed. Every clause of that is a true
   statement about a thing and **none alone says what it will net a player who keeps doing what
   she is doing**. A fire engine on a course that misses her may carry nothing; a stationary
   burning building uses its silhouette and active-cost halo, not an approach caret, unless she is
   walking straight at it.

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

   **A vehicle needs more than one picture the moment it can face more than one way.** One
   side-on sprite mirrored east and west shows a patrol car heading north its own flank, so every
   vehicle row draws a front, a back, a side and two diagonals through the same
   `EventInstance._draw_eight_view()` every other eight-view family in the catalogue uses.
   `police_patrol`, `fire_truck` and `military_convoy` read the octant from their own actual
   travel, turning corners along their routes; `abduction` and `night_raid` read it from their
   placement heading while idling or closing to their stand-off and from the chase direction once
   they hunt; `delivery_van`, `ice_cream_van` and `reversing_lorry` read it from their own
   placement heading too, which in play never actually turns away from the kerb or the wall the
   lorry backs into, so only their side view is ever seen. Each is *its own* picture rather than
   the crowd's (whose cars are end-on because at that angle the front and the back of a car are
   the same shape): the whole content of a vehicle row is which vehicle it is, and a van that
   becomes a generic box the moment it turns north loses the one silhouette the badge exists to
   show at the moment it starts coming towards her. The **badge keeps the side view**, because an
   icon is read at 40px against a row of other icons and a vehicle end-on is a box at any size.

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
  else. Ambient events and scars are exempt — a playground is a permanent, free feature of the map
  rather than something today placed there, and a scar is something that already burnt.

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

**What denies calm ground is not reaching it, it is out-emitting `Tuning.CALM_ZONE_DENIAL_RATE`**,
7.7/s — so a busker at intensity 19.3 is useless past 157px however far his 190px
field reaches, in a lot that is 704px across. One spoiler is a small share of a four-block calm
zone: the day rolls its spoiler for the block she used, and she settles in that same block anyway.
**The rate is fixed and a row's intensity is not**, so intensity is the one thing that widens a
denial radius — which is why a row that stands on calm ground is raised no further than it has to
be.

`EventScheduler._denial_radius()` is that arithmetic, and a spoiler is a **crowd** laid out on a grid
over the calm ground, sized from what each of them actually denies and capped at
`Tuning.SPOILERS_TO_DENY_A_PARK`. Two details that are not incidental:

- **Each cell rolls its own def**, so a spoiled park is a busker *and* a leaf blower *and* a market
  stall. A park that is busy today is busy with several different things, and nine copies of one
  sprite in a field would read as a duplicated sprite — which is what `EVENT_SPACING_SAME` exists
  to prevent everywhere else in the scheduler.
- **The roll is weighted by area, not just by `weight`.** Everywhere else a def's weight says how
  *common* it is; here the job is covering a lot, and what a row denies goes as the square of its
  reach — a busker covers several times the ground a market stall does.

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
5. **Draw it.** A new `EventDef.Look`, a new SVG in `art/events/`, a `_draw_*` in
   `EventInstance`, and a row in `EventInstance.icon_for()` so the screen-edge badge has a
   silhouette to show. There is no generic look to borrow — that is deliberate, and
   `tests/test_events.gd` fails the build if two rows share a picture. See "The visual
   vocabulary", point 6.
6. Run the project. `EventDef.validate()` rejects unfair geometry, a body on something sited
   ahead of the player, and a lethal radius its own body would hide, all on load.
7. If it needs behaviour no field covers, add the **field** to `EventDef` and handle it in
   `EventInstance`. Resist a script per event: `pursues`, `still_while_telegraphing` and
   `pavement_side` are all one field each, and each one is shared or checkable.
