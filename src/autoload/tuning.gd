extends Node
## Central balance table. Every gameplay constant lives here so tuning is one file.
##
## See docs/MECHANICS.md for the reasoning behind these numbers.

## The catalogue validates itself when it is first asked for; traffic has no catalogue to
## hang that on, so the one contract that is not about an event is checked here on boot.
func _ready() -> void:
	validate_traffic()
	validate_signals()

# ---------------------------------------------------------------- movement ---

const WALK_SPEED := 92.0
const RUN_SPEED := 168.0
const ACCELERATION := 700.0
const FRICTION := 900.0
## Below this speed the player counts as idle (sleepiness drains).
const IDLE_SPEED_THRESHOLD := 12.0

# ------------------------------------------------------------- sleepiness ---

const METER_MAX := 100.0

## The pitch these three make together is the whole loop, and it is the answer to findings
## 2 and 4 from the first playtest: a day used to be winnable by circling the starting block,
## which made the city decoration.
##
## An ordinary street makes real progress and never enough. A whole day of clean street
## walking reaches about three quarters of the meter, so the walk out is worth something and
## the walk out alone can never finish; only calm ground can. `tests/test_meters.gd` holds
## both halves of that, in terms of `day_length()` rather than in numbers, so a change to
## the day cannot quietly make the street sufficient again — which is what kept them honest
## when M18 cut the day from 330s to 180s.
const SLEEPINESS_GAIN_WALKING := 0.42
## Standing still has to be strictly worse than walking, or waiting is a strategy. It also
## has to stay cheaper than a calm zone gives, because stopping is the counterplay to a loud
## event and pricing it above the park's own rate would take that move away.
const SLEEPINESS_DRAIN_IDLE := 1.0
## Playtest 02, finding 1: *"the difference of a park is barely noticeable... I don't want to
## circle in a park for two minutes just to fill up the bar."* At M14's 3.5x a calm stretch
## ran 119s, which is not a reward, it is a wait — and at three and a half times a rate you
## cannot see, it did not even read as faster than the pavement.
##
## At 10x it was 24s from empty, and a second in a park was worth ten on the street. That makes
## a day comfortably winnable *once calm ground is reached*, which is the point: the day is
## meant to be lost on the way there, not in it. See docs/PLAYTEST-02.md, decision 1.
##
## **12x since M38**, which is the same decision taken one notch further: 20s from empty rather
## than 24. Every milestone since M28 has put more between the doorstep and the park — a solid
## catalogue, a crowd that bites, a pacing man, a robber — and all of that is spent on the way
## there, which is where the day is *supposed* to be lost. Making the walk out harder and leaving
## the reward at the end of it the same length quietly turns the park from a reward into a wait,
## which is playtest 02's finding 1 coming back by a different road.
## **14x since M41** — *"let's increase the sleepiness speed for calm zones again"* — which is the
## same argument a third time: 17s from empty rather than 20. What went between the doorstep and
## the park this time is a main road that is bad ground to recover on and a lattice a fifth wider.
## **21x since M52**, and this one was asked for twice before it was built: *"x1.5 the sleepiness
## effect of calm zones and double it for 1x1 calm zones"* (playtest 14, finding 11), restated as
## *"calm zones need to fill up the sleep meter faster in general"*. 11.3s from empty.
##
## One correction travelled with it. `docs/PLAYTEST-14.md` recorded the request against a value of
## **12**, which had been wrong since M41 — so the 1.5 is taken on the 14 that is actually here.
const SLEEPINESS_CALM_ZONE_MULTIPLIER := 21.0

## How much faster again a **small** calm area fills it, as a curve over the lot's size.
##
## *(Playtest 14, finding 11: "double it for 1x1 calm zones". Playtest 16: "the size of the calm
## zone increases the speed even further if it is small", then "2x1 calm zones have a proportional
## multiplier, the base is 2x2 — or maybe redefine the base to 1x1 and divide by the number of
## blocks".)*
##
## **The two phrasings of the curve give different answers and the arithmetic is why one was
## picked.** Three anchors were asked for: a 2x2 zone is the base, a 1x1 is **double** it, and a 2x1
## sits proportionally between. Dividing by the **number of blocks** cannot hold the first two at
## once — from a 2x2 base of 21 it makes a 1x1 *four* times as fast, and from a 1x1 base of 42 it
## makes a 2x2 half of what it is today. Dividing by the **side** holds both exactly, because a 1x1
## against a 2x2 is a factor of two in width and a factor of four in area, and the rate asked for
## doubles rather than quadrupling.
##
## So the rate goes as `1 / sqrt(blocks)`, normalised so a `CALM_ZONE_BLOCKS`-square zone is the
## base: **21x for four blocks (11.3s from empty), 29.7x for two (8.0s), 42x for one (5.7s)**.
##
## And that is the same thing the design says in words, which is the reason to trust it over the
## simpler formula: **a lap is a length, not an area.** A four-block zone is 22 tiles square and has
## a route through it; a single block is eight tiles across and has a lap round it, which is what
## M21 exists to remove. Paying inversely to the *width* of a lot pays each of them about the same
## for a lap of it — so the small ones stop being the weaker destination for a reason that has
## nothing to do with what they are for, and *which* calm area to head for goes back to being a real
## question. That is `docs/CITY.md`'s own argument for keeping single-block calm in the mix.
func sleepiness_calm_multiplier(blocks: int) -> float:
	var side := sqrt(float(maxi(blocks, 1)))
	return SLEEPINESS_CALM_ZONE_MULTIPLIER * float(CALM_ZONE_BLOCKS) / side
## Sleepiness the baby keeps after being woken up. Half the bar, which is now about twelve
## seconds of park — a fifth of a well-played day, which is what it was before and should
## stay whatever the rates are.
const WAKE_SLEEPINESS_PENALTY := 50.0

## Sleepiness per second on calm ground, for a lot of `blocks` blocks. The default is the
## `CALM_ZONE_BLOCKS`-square zone, which is the size every other constant here is pitched against.
func sleepiness_gain_calm(blocks := CALM_ZONE_BLOCKS * CALM_ZONE_BLOCKS) -> float:
	return SLEEPINESS_GAIN_WALKING * sleepiness_calm_multiplier(blocks)

# ------------------------------------------------------------- excitement ---

## While excitement is at or above this, sleepiness is frozen.
const EXCITEMENT_CALM_THRESHOLD := 35.0
## A sleeping baby woken above this goes back to AWAKE.
const EXCITEMENT_WAKE_THRESHOLD := 60.0

## The two the *pram* says out loud. *(Playtest 06, finding 5: "can you add a visual for when
## the excitement bar is almost full, and the same for when the sleep bar is fully full.")*
##
## Both are stated as **states with an instruction attached** rather than as points on a gauge,
## which is the whole difference between a cue and the HUD moved over the player's head. The
## other two the pram shows need no constant at all, because the game already has them: the calm
## threshold, where the day stops progressing, and asleep, which is a state.
##
## Nearly crying is the last band before `METER_MAX` ends the day. Far enough up that it is not
## a second name for "loud street" — a pavement sits under the calm threshold and a bad moment
## reaches the fifties — and far enough from 100 to be worth acting on: at the walking decay it
## is about six seconds of quiet ground back to safety.
const EXCITEMENT_NEARLY_CRYING := 80.0
## And how far below the wake threshold a sleeping baby starts to stir. Waking costs
## `WAKE_SLEEPINESS_PENALTY` — half the bar — so this is the most expensive thing in the return
## phase and the only warning of it was the excitement bar climbing in the corner of the screen.
const EXCITEMENT_STIR_MARGIN := 12.0
## Incoming excitement multiplier while the baby is asleep.
const SLEEPING_SENSITIVITY := 0.55

## **What settles a baby is being pushed.** *(Playtest 07, finding 3: "not walking at all
## shouldn't reduce excitement either — otherwise I can just stop in the middle of the street and
## wait until everything is good.")*
##
## It was 6.0, which was the **fastest** of the three, and that made standing still the strongest
## move in the game: a full meter cleared in seventeen seconds for seventeen points of sleepiness,
## anywhere, including the middle of a street she had no business being on. Two runs in the
## playtest 07 traces have a seventy-four-second gap with no entry in them at all.
##
## Zero rather than merely lower, because the model it states is worth stating exactly: the pram
## is a rocking chair with wheels on, and rocking it is the only thing that calms her. Standing
## still now *freezes* the excitement instead of clearing it — the day stops moving in both
## directions at once, which is the honest version of "waiting is not a plan". The counterplay it
## takes away has a replacement that was always the better one: **walk somewhere quiet**, which is
## what `EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER` is for and what the whole route is about.
##
## Running still decays, barely — it is motion, and `EXCITEMENT_FROM_RUNNING` is what makes it a
## bad idea. The ordering is now motion-shaped rather than arbitrary: walking calms most, running
## calms a little, standing calms nothing.
const EXCITEMENT_DECAY_IDLE := 0.0
const EXCITEMENT_DECAY_WALKING := 3.5
const EXCITEMENT_DECAY_RUNNING := 0.5
## What the **ground** does to the decay, best to worst. *(Playtest 12, finding 8: "excitement
## decay — best: calm, then pedestrian, then side road, then main road, worst.")*
##
## This is the first time since M14 that the ground under her feet has done anything except be
## calm or not, and it is the change that makes a route a **recovery rate** rather than only a set
## of things to walk past. It is also what makes a precinct worth walking to although it is loud:
## a retail street is busy, and it is still the best place in the city that is not a park to bring
## a meter down.
##
## The park has to read on *both* bars, not just the sleepiness one — half of "this is working" is
## the excitement visibly falling away as she walks in under the trees. The main road is the same
## sentence inverted: it is the one ground in the city that is actively bad at letting her recover,
## which is most of what "a main road is crossed, not walked" now means arithmetically.
const EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER := 2.2
const EXCITEMENT_DECAY_PRECINCT_MULTIPLIER := 1.5
const EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER := 0.6

## Excitement per second at full sprint, scaled by how far above walk speed we are.
##
## **9.0 → 14.0 in playtest 07, to keep a standing decision standing.** The run button is a trap
## by design — `CLAUDE.md`'s second measured fact about the catalogue is that running is the wrong
## move against *every* event in the game, and M25 is where that is supposed to change, by
## building a mechanic and a fairness contract rather than by moving a constant.
##
## `falloff`'s new shoulder broke it as a side effect. A fatter field makes time-in-field matter
## more, so running out of the four widest ones — `dog_walker`, `fire_truck`, `night_raid`,
## `firefight` — became a point or two cheaper than walking. Not "running works" but "running is a
## coin flip", which is the worst of the two and was nobody's decision. This is the number that
## restores the ordering across the whole catalogue, and `tests/test_events.gd` now asserts it
## rather than leaving it in a document, which is how it broke silently in the first place.
const EXCITEMENT_FROM_RUNNING := 14.0
## Constant dread while standing in an alley.
const EXCITEMENT_FROM_ALLEY := 3.0

# ----------------------------------------------------------------- the mark ---

## What a row has to cost, in points of the meter, before it earns a caret over its head.
##
## *(M39, playtest 10 finding 9: "I would kind of expect for more dangerous entities to have danger
## indicators but it feels like some dangerous ones don't have indicators and some really benign
## ones do have indicators.")*
##
## The rule it replaces asked whether a danger *changes over time*, which is a true statement about
## a thing and not a statement about how bad it is — so a fire engine at +115 carried nothing and a
## burning building at +56 carried a caret, and the most expensive ordinary row in act I had none.
## See `EventInstance.wants_a_mark()`.
##
## **A quarter of the meter**, and it is a taste call stated rather than derived: one of these is a
## quarter of the bar and a route has three or four on it. What makes it a *safe* taste call is
## where it falls — the catalogue has a 7.5-point gap between `market_stall` (+27.8) and
## `construction` (+20.3), so the line sits in open ground rather than slicing a cluster, and a
## small rebalance cannot flip a row across it by accident.
##
## The number does not decide *which* rows are marked so much as *how many*: the ordering is the
## invariant, and `tests/test_danger.gd` holds it — if A is marked and B is not, A costs more than
## B, over the whole catalogue.
const MARK_WORTH_A_DETOUR := METER_MAX * 0.25

# ---------------------------------------------------------------- telegraph ---

## Fraction of full intensity an event emits while still telegraphing.
const TELEGRAPH_INTENSITY_FRACTION := 0.15
const TELEGRAPH_TIME_DEFAULT := 2.5
## Hard-fail events must give twice the escape margin of an ordinary event.
const TELEGRAPH_HARD_FAIL_MARGIN := 2.0

# ---------------------------------------------------------------------- run ---

const RUN_LENGTH_DAYS := 14
## How many days a run may lose before it is over. *(Playtest 08: "we need more nerves let's try
## 5?")*
##
## Three was the number from M6, when a lost day also *advanced the calendar* — so a nerve was a
## day of the fourteen thrown away as well as a life, and three of them was already a hard cap on
## how much of the run a player would ever see. M32 took that half away: a lost day is retried, so
## a nerve now costs only the time it took to lose. Three of those against an act I that grew teeth
## in M31 is what ended playtest 08's run on **day 3** — two of them spent on the same charging dog,
## which is the milestone's other half.
##
## Five is a number to be measured rather than derived, and the thing to read is `docs/TODO.md`'s
## open question: three nerves were never enough attempts to *learn* a day, and a run that ends
## before act II ends before the game has shown what it is. The run log's `nerve` entries say where
## they went.
const STARTING_NERVES := 5
## A day is aimed at **about a minute of play, with a grace of three**. Dusk is the grace,
## not the target: a day walked well is over in a minute, and the three minutes are there for
## a day that goes wrong — a bad route, a park that turned out to be spoiled, a baby woken on
## the way home.
##
## It was 330s until M18, which made the outer bound the *typical* length and the meter the
## thing standing between you and it. Cutting it was the other half of finding 1: two minutes
## of standing in a park inside a five and a half minute day is a game about waiting.
const DAY_LENGTH_SECONDS := 180.0
## Curfew (day 6+) shortens the day by this fraction.
const CURFEW_DAY_LENGTH_MULTIPLIER := 0.8

const RESISTANCE_GOAL := 4

# --------------------------------------------------------------------- city ---

const TILE_SIZE := 32
const BLOCK_SIZE := 8
## Sidewalk(2) | road(2) | sidewalk(2). A 1-tile sidewalk left only 2px of clearance for
## the rig, which made walking a street feel like threading a needle.
const STREET_WIDTH := 6
const SIDEWALK_WIDTH := 2
## Odd on both axes, and that is a constraint rather than a coincidence: an odd lattice has a
## **middle block**, and the home goes in it. See `CityGenerator._place_home`.
##
## **11x11 since M41** — *"I think we can make the map even bigger"* — which is the first resize
## taken for room rather than for a rule: nine blocks was what the home needed to be central, and
## eleven is what a city with one spine, two precincts and a ring of frontages needs to have a
## middle you can get lost in the middle of.
##
## The size is what lets the two rules about the home both hold. It has to be central, and it has to
## be `MIN_HOME_TO_PARK_TILES` of walking from calm ground — and those pull against each other, so
## the lattice has to be wide enough that the centre is still a long walk from the edge of anything.
## At 7x7 it was not: the home was walked outward until it was far enough, landing about two blocks
## off centre and often against the boundary, where most directions are a wall.
##
## Everything downstream of this is stated over it — the event budget per block, the crowd
## population per corridor, the arterial index — so a change here is a change to the whole density
## table. Re-measure it; see `docs/PLAYTEST-04.md`.
const CITY_BLOCKS := Vector2i(11, 11)

# -------------------------------------------------------- the street hierarchy ---
# Playtest 11, finding 7: *"we need a separation between easy-to-navigate road and heavily
# trafficked and pedestrianised road — there should be a visual difference and traffic lights."*
# Until M41 the city had **one kind of street**; the arterials differed from the rest only by how
# many cars were on them, so the only route question a junction ever asked was *which way*. With
# three kinds it also asks *which kind*, and that is the trade this game is made of.
#
# The lattice itself does not move. Every corridor is still `sidewalk | road | sidewalk` and the
# layout maths is still a modulo — see the note on `STREET_WIDTH`.

## How long a precinct is, in blocks. *(Playtest 12, finding 7: "a stretch of three blocks at the
## shore, like a coney island beach walk, and three blocks in the city somewhere — no more.")*
##
## The first version made a whole corridor of each axis pedestrianised, and the report on it was
## *"there are way too many pedestrian only zones"*. A kind of street you meet every third block is
## what a street is; three blocks with an end you can see is a place.
const PRECINCT_BLOCKS := 3

## How busy a precinct's pavement is against an ordinary street's. It is the other end of the same
## trade the main road is at: nothing on it can kill you, and there is a great deal more of it in
## your way. A retail street — *"a lot of foot traffic and restaurants"* — so this is the crowd
## half of that and `EVENT_PRECINCT_WEIGHT` is the other.
const PRECINCT_BUSYNESS := 3.6

## How many times over a precinct tile is offered to the event scheduler against an ordinary
## pavement tile. Weighting the candidates rather than adding a rule: a precinct is where the cafés
## and the market stalls and the buskers are, and the way to say that is to make the ground more
## likely rather than to give the catalogue a new field.
const EVENT_PRECINCT_WEIGHT := 4

## Seconds the **side** street gets, and the amber between the two arms. The main road gets
## whatever is left of the cycle, which is most of it.
##
## The side green is the one the player is actually spending: she crosses a main road while the
## main road is red, which is while the side street is green. So it has to be long enough to walk
## the carriageway with the doubled hard-fail margin a lethal thing owes — a light that turns
## while she is on the paint is the traffic contract broken by the one thing that was supposed to
## be keeping it. `validate_signals()` states exactly that.
##
## The amber is a clearance period rather than a warning — the crossing arm stays red through it,
## and a car too close to stop is treated as already in the box — so it only has to be long
## enough for a committed car to be out the far side. At `CAR_SPEED.x` two seconds is 260px
## against a 192px junction.
const SIGNAL_SIDE_GREEN_SECONDS := 5.0
const SIGNAL_AMBER_SECONDS := 2.0

## How many junctions apart a green wave repeats. **The whole cycle is derived from this**, and
## it is the difference between a signalled spine and a car park.
##
## Signals with arbitrary offsets stop a car at every junction it comes to: measured at act I
## density, two thirds of the traffic was stationary at any instant and the mean speed on the
## arterial was a quarter of a cruise. What fixes it is a *progression* — each junction's cycle
## starts one junction's travelling time after the last.
##
## **The wave serves one direction, not two, and M41 claimed otherwise.** *(M46.)* The old note
## here said a car going against the wave "arrives two travel times after the one going with it,
## so both are in step exactly when the cycle is an even multiple of the travel time", and that is
## the wrong condition. Walk it: with offsets `j·travel`, a car passing junctions `j0 + d·h` at
## `t0 + h·travel` sees phase `t0 + j0·travel + h·travel·(1 + d)`. Going **with** the wave (`d =
## -1`) the `h` term vanishes and the phase never moves — a perfect progression. Going **against**
## it the phase advances `2·travel` per junction, which is constant only if the cycle *divides*
## `2·travel`. "An even multiple" is that condition upside down, and it is only true at
## `blocks = 1`.
##
## Measured on the wave alone, twenty departures spread across a cycle, no traffic in it:
## **93% of arrivals green with the wave, 51% against it** — and 51% is chance, because the main
## green is 47% of the cycle.
##
## **A two-way wave is impossible here, which is why this is a note and not a fix.** It needs
## `cycle = 2·travel` = 5.7s, and the side green plus its two ambers is 9.0s before the main road
## gets a second. Widening `travel` instead means a spine cruise under 100px/s, which is barely
## above a walk. No offset scheme does better on average either: `θ = travel` buys one direction
## a perfect run and leaves the other at chance (72% overall), while `θ = cycle/2` puts *both*
## directions on a three-phase sweep at 47% each. The asymmetric answer is the good one.
##
## Three is what makes the cycle come out near a quarter of a minute: shorter and the side
## street's share stops being long enough to cross on, longer and a red is a wait a player will
## not spend — see M46 in `docs/TODO.md` for what a longer one costs her, measured.
const SIGNAL_PROGRESSION_BLOCKS := 3

## Calm **areas**, not calm blocks: since M21 an area may be a single block or a four-block
## zone, and what these count is places to go rather than lots. `MIN_CALM_BLOCKS` keeps its
## name because it is what `calm_blocks` returns — one entry per area — and renaming it would
## touch every guarantee that is stated over it without changing what any of them mean.
##
## **The floor is an act's worth plus one.** *(Playtest 12, finding 5: "since each day one gets
## removed we need as many as days in an act, plus one more as backup. That forces exploration.")*
## M24 spoils the calm area she settled in, and since M41 it spoils every one she has used *so far
## this act* — so an act of four days burns four, and the plus one is what stops the last day of
## an act being unwinnable rather than merely hard. It is derived from the act lengths below
## rather than authored beside them, because the two would otherwise drift the first time either
## moved: `calm_areas_needed()`.
const MIN_CALM_BLOCKS := 5
const MAX_CALM_BLOCKS := 7
## Walking distance in tiles, not straight-line: the calm has to be earned.
const MIN_HOME_TO_PARK_TILES := 30
const PARK_SPOIL_CHANCE := 0.35

# ------------------------------------------------ four-block calm zones (M21) ---
# Playtest 03, finding 2, restated by playtest 04 and again by playtest 05's finding 4: the
# traced player spent twenty seconds walking in a circle inside a courtyard. That is not a
# balance problem and no balance pass removes it — progress requires motion (standing still
# *drains* sleepiness) and a calm block is eight tiles across, which is jointly sufficient for
# a lap. A calm area has to be big enough to have a *route* through it.
#
# A zone is 2x2 blocks with the streets between them absorbed, so it is
# `2 * BLOCK_SIZE + STREET_WIDTH` = 22 tiles square — 704px, against a block's 256. At
# `WALK_SPEED` that is 7.6s to cross corner to corner against 24s to fill the meter from empty,
# so a stretch of calm is two or three traverses of somewhere with sides to it rather than
# eight laps of a lawn. See docs/CITY.md, "Calm zones".

## Blocks per side of the **square** calm zone, which is the size every rate here is pitched
## against. Two. It is a constant rather than a literal because a great deal of arithmetic follows
## from it — the normalisation of the sleepiness curve above, and every test that states a
## relationship in terms of a full-sized zone — and a 2 buried in five different files is how the
## next person changing this discovers the sixth.
const CALM_ZONE_BLOCKS := 2

## The footprints a multi-block calm area may have. *(M52, from M47's entry: "add calm varieties
## that take up 2x1 non-square shapes".)*
##
## **A zone stopped being a square and became a shape**, which is the change the arithmetic felt:
## everything downstream of `CALM_ZONE_BLOCKS` used to be that integer squared. What a footprint
## costs the lattice is stated over the rect now — a `w x h` zone absorbs `w*(h-1) + h*(w-1)`
## streets, which is four for the square and **one** for a rectangle — so a 2x1 is a lot of two
## blocks with the single street between them painted over.
##
## Both orientations are here on purpose. A city whose rectangles all run the same way is a rule
## somebody learns once rather than a place, and the two are genuinely different to walk: a 22x8
## strip is a length with two ends, and which end you come in at is a route decision.
##
## And the rate curve was already waiting for them: `sleepiness_calm_multiplier` is `1 / sqrt` of
## the block count, so two blocks fill in 8.0s against the square's 11.3s and a 2x1 pays for about
## one traverse of its long side, exactly as a square pays for one diagonal. Nothing here had to be
## balanced for the new shape — see M52 in docs/TODO.md.
const CALM_ZONE_SHAPES: Array[Vector2i] = [
	Vector2i(CALM_ZONE_BLOCKS, CALM_ZONE_BLOCKS),
	Vector2i(CALM_ZONE_BLOCKS, 1),
	Vector2i(1, CALM_ZONE_BLOCKS),
]

## How many of a city's calm areas are multi-block. At least one, because the lap is what M21
## exists to remove and a city with none of them still has it; and the first one placed is always
## the **square**, so *"every city has a big park"* stays true word for word while the rest of them
## may be rectangles. The remainder of the calm stays single-block, which is what keeps *which* calm
## area to head for a real question — a small quiet square close by against a big park further out
## is the decision M24 made matter.
const MIN_CALM_ZONES := 1
const MAX_CALM_ZONES := 2

# ------------------------------------------------------- hard blockers (M50) ---
# *"Hard blocker: the layout has pruned edges that cannot be traversed — permanent for the run.
# Cul-de-sacs, big buildings."* The soft ones re-cut the map every morning; these hold still for
# the whole run and are therefore the part of the city a player can **learn**. See docs/CITY.md,
# "Diversions — the design", and docs/TODO.md, M50 step 1.

## How many streets in a city genuinely stop. A handful of 264: enough that a run has a shape
## somebody could describe, few enough that the lattice is still a lattice — the number is what
## separates "this city has dead ends in it" from "this city is a maze", and a maze is the thing
## the two-routes guarantee exists to prevent.
##
## Measured rather than derived, like every other count in this file: see docs/TODO.md, M50, for
## what each gate strength lets a seed actually place.
const MIN_CUL_DE_SACS := 4
const MAX_CUL_DE_SACS := 8

## How deep the wall across a dead end is, in tiles. Two rather than one: a one-tile slab is a
## line rather than a building, and what has to read from the far end of the street is *this does
## not go through* rather than *something is painted here*.
const CUL_DE_SAC_WALL_TILES := 2

## Big buildings: a whole block plus the four streets around it, one solid mass twenty tiles
## across. One or two, because this is a **landmark** — a thing a player says "past the big grey
## one" about — and a city with five of them has landmarks the way a forest has notable trees.
const MIN_BIG_BUILDINGS := 1
const MAX_BIG_BUILDINGS := 2

## Per-purpose chance a block is split by a through-alley.
const ALLEY_CHANCE := {
	GameEnums.BlockPurpose.RESIDENTIAL: 0.25,
	# Commercial blocks already have a plaza carved out; a second hole through the same
	# lot leaves slivers of building and an alley that opens onto a square.
	GameEnums.BlockPurpose.COMMERCIAL: 0.0,
	GameEnums.BlockPurpose.INDUSTRIAL: 0.5,
	GameEnums.BlockPurpose.CIVIC: 0.0,
	# A courtyard block has a court cut out of it already, and an alley through that court
	# would open the one piece of calm that is supposed to be hidden.
	GameEnums.BlockPurpose.COURTYARD: 0.0,
	GameEnums.BlockPurpose.PARK: 0.0,
	GameEnums.BlockPurpose.FOREST: 0.0,
	GameEnums.BlockPurpose.QUIET_SQUARE: 0.0,
	# A big building is chosen after the blocks are carved and replaces whatever was cut into
	# it, so this is never actually read. It is here because the table is a statement about
	# every purpose, and a purpose missing from it would be a crash rather than a default the
	# day somebody assigns one earlier.
	GameEnums.BlockPurpose.BIG_BUILDING: 0.0,
}

# ---------------------------------------------------- block purposes and arcs ---
# Finding 7: more variety in areas, and a city that becomes a different city while you walk
# around in it. Every block is generated with an arc — the ordered purposes it may pass
# through — so the transitions are always coherent and the whole run can be checked at
# generation instead of rescued day by day. See docs/CITY.md, "Block purposes".

## Courtyards are cut into residential blocks rather than taking a block of their own.
const COURTYARD_CHANCE := 0.35
const MAX_COURTYARD_BLOCKS := 3
const COURTYARD_SIZE_TILES := 4

## The **apartment complex**: a courtyard lot four blocks across, with the streets between them
## built over and frontages all the way round. *(M52, from M47's entry, itself quoting a request
## from long before it: "an inner courtyard (surrounded by buildings) should have a footprint of
## 2x2 blocks (apartment complex) — this never got implemented".)*
##
## **It is M21's mechanism with the opposite ground.** A calm zone absorbs the streets between four
## blocks and paints park over them; this absorbs them and builds over them, so what comes out is a
## mass 22 tiles square with a court in the middle and one archway in. That is what makes it calm
## you have to *find* rather than calm you can see from the street — the courtyard's whole idea, at
## the size where the block around it is a landmark.
##
## The court is ten tiles rather than the four a single-block courtyard gets, because a hole four
## tiles wide in a mass twenty-two across is a light well rather than somewhere to stand. Ten
## leaves six tiles of building on every side and crosses in 4.9s against the 5.7s it fills in, so
## it sits with every other calm area at about one traverse per meter.
##
## One per city at most. It is a landmark and a secret, and two of them in a city is neither.
const APARTMENT_COURT_TILES := 10
const MAX_APARTMENT_COMPLEXES := 1

## The hard floor: this many blocks must still be calm on the last day. A day can only be
## won on calm ground, so an arc set that takes all of it makes an unwinnable run rather
## than a hard one. `CityGenerator.validate()` enforces it.
const MIN_CALM_BLOCKS_AT_END := 2

## Chance a calm block that *may* be taken is scheduled to be, and the earliest day it can
## happen. Act III, when the vans start: the parks go at the same time the people do.
const REQUISITION_CHANCE := 0.55
const REQUISITION_FIRST_DAY := 8

## A commercial block goes dark before anything else happens to it.
const BOARDING_CHANCE := 0.5
const BOARDING_FIRST_DAY := 8

## Chance a built block's arc ends in ashes. Event-caused, so it only happens if something
## actually burns there — most of these never fire, which is the point.
const BURN_CHANCE := 0.45
const BURN_FIRST_DAY := 3
const ALLEY_WIDTH_TILES := 2

## Tiles per side of the plaza carved out of a commercial block.
const SQUARE_SIZE_TILES := 4
## The home is a notch in the south edge of a residential block.
const HOME_SIZE_TILES := Vector2i(2, 2)

# ----------------------------------------------------------- road closures ---
# Playtest 01, finding 12: prune the road network per day so the route is a real decision —
# avoidable, but clearly "not that way". See docs/CITY.md, "Road closures".

## Streets closed per day, by act. Deliberately light. M16 was drafted as though closures
## would be the only thing making a route interesting; playtest 02's findings 2 and 3 put
## route pressure at the scale of a *block* instead — which side of the road to walk down,
## forty times a day — and closures tuned as the sole source of pressure would be far too
## heavy underneath that. Four closed streets out of 112 is a city that has had a bad
## morning, not a city under siege.
const CLOSURES_PER_ACT: Array[int] = [1, 2, 3, 4]

## How much likelier a closure is to land on a turning off the day's corridor than on a street
## somewhere else entirely. **A closure never lands on the corridor at all** — that is a rule in
## `ClosurePlanner._shuffled_candidates` rather than a weight, because a wall across the route is
## not a worse wall, it is the opposite of one.
##
## **It replaced `CLOSURE_ROUTE_BIAS`, which was the same number pointing the other way.** *(M50
## step 2: "a road block becomes guidance and is not a hindrance. It flips its role.")* That one
## aimed closures **at** the streets the player would have used, five to one, because a closure
## was an obstacle and an obstacle nobody meets is scenery. A wall's job is to prune the ways that
## lead nowhere she should go, and a wall nobody can see from the route prunes nothing — so the
## number survived the inversion and what it is measured against did not. The far corner of the
## map is still the thing it exists to avoid.
const CLOSURE_WALL_BIAS := 5.0

## The day-level invariant, and the whole reason the planner is allowed to close anything:
## **at least this many calm areas are still reachable.** Two areas, because a choice of
## destination is what makes a choice of route mean anything — and because one of them may be the
## one she used yesterday, which the day has deliberately spoiled.
##
## **It used to demand two *distinct routes* to each of them, and that is not a hard rule.**
## *(2026-08-31: "I already clarified that the two routes guarantee is not a hard rule."* The
## clarification is `docs/CITY.md` — *"having two distinct paths is really a niceness to the
## user… if we cannot construct a path B at all, let's not try"*, and *"sealing off a section of
## the map is allowed, and it is the point"*.) Edge-disjointness was a **stand-in** for winnability,
## by Menger: two routes means no single street is a cut. Under M50 that protection comes from
## where a wall is *placed* — off the day's tree, so it cannot cut the tree — and the second route
## is an offer the day makes when the map allows one. `RouteTree` measures it (241 areas of 241
## that the map allowed one to); nothing gates on it.
##
## What is deliberately **not** weakened is the count. Dropping to one reachable area would let a
## day arrive where the only calm left is the one it spoiled this morning, which is the unwinnable
## day this constant has existed to prevent since M16.
const MIN_CALM_AREAS_REACHABLE := 2

## How deep the barrier across a closed street's mouth is, in pixels. Thin enough to read as
## a line drawn across the road, thick enough that nothing walks through it in one frame.
const CLOSURE_BARRIER_DEPTH := 24.0

## Streets closed on a given day.
func closures_for_day(day: int) -> int:
	return CLOSURES_PER_ACT[clampi(act_for_day(day) - 1, 0, CLOSURES_PER_ACT.size() - 1)]

# --------------------------------------------------------------- the crowd ---
# Findings 3, 8 and 9 from the first playtest: there was nobody about, and passing the one
# person who was barely moved the meter. The crowd is also the answer to finding 4 — the
# base noise floor a day needs so that standing in one place cannot work. It is emergent
# rather than a city-wide constant, because a number nobody can see means nothing.

## People, then cars, on the streets in each act. The city empties as the acts turn, and
## this is the cruellest number in the game: from act III the streets are *quieter*, because
## there is nobody left going out on them. The city becomes an easier place to put a baby to
## sleep, and that is the horror. Act IV puts a little back, but it is not the same traffic.
##
## This used to be an invisible ambient band on the arterials (`busy_road` / `quiet_road`),
## which meant the player felt the city empty out without ever being able to see it. Now the
## emptiness is the empty pavement.
##
## **Since M27 these are populations of the *field*, not of the city.** The crowd lives in a
## `CROWD_FIELD_RADIUS` box that travels with the player, so the number here is what is on the
## streets *around her* rather than what is scattered over ten thousand tiles. The old numbers
## were whole-city and read a third as dense as they looked: 110 cars over sixteen corridors is
## one every six seconds in your lane, which is playtest 04's *"I can just ignore it and cross
## the street whenever"*. These are measured — see `tests/test_crowd.gd`, "the road has to be
## waited for" — rather than converted from the old ones by area.
## **And since M41 a junction is a place a car can be stopped**, which gave the road a capacity
## it never had. Until then two cars on crossing arms simply drove through each other, so the
## network's throughput was unbounded and 46 cars was whatever 46 cars looked like. With the box
## rationed, the same 46 put the arterial floor at 11.3/s against the 10.5 ceiling
## `tests/test_crowd.gd` states — *"expensive to cross, not impossible"* — because a car waiting
## at a light beside you is louder for longer than one going past. Thirty restores the floor
## to 8.0, which is what the same street measured before any of this. Measured, not converted.
##
## **And the cars came back down when the spine finally got the share it was always weighted for.**
## *(Playtest 13, finding 7.)* Forty was set after playtest 12 said the main road was too sparse,
## and it was the wrong lever for a reason nothing could see: half the arterial weight was being
## spent on a phantom east-west arterial (`CrowdLanes.busyness`) and the axis was chosen 50/50
## *before* the corridor, so no weight could put more than half the traffic on one north-south
## street. With both fixed the spine holds **15.4 cars of the city's total against 11.2 before**,
## and forty of them put junction contention over the rate `tests/test_crowd.gd` allows. So the
## number goes down and the street the player is complaining about gets busier: this is the
## capacity clause above arriving for real, and it is the second time the honest answer to
## *"the main road is too quiet"* has been something other than *more cars*.
const CROWD_PEDESTRIANS_PER_ACT: Array[int] = [200, 150, 42, 70]
const CROWD_CARS_PER_ACT: Array[int] = [34, 26, 8, 16]

## Half-extent of the box the crowd lives in, in px. Everything inside it is simulated;
## anything that leaves it is recycled to the far edge and walks back in.
##
## The floor is the screen: the viewport is 1280x720, so an agent recycled at 800px from the
## camera is always off-screen when it appears, whichever way the player is facing. The ceiling
## is honesty — a box much larger than this is spending frames on pavement nobody can see, which
## is the thing M27 exists to stop.
const CROWD_FIELD_RADIUS := 800.0

## Speed range, min..max. Walkers are slower than the player on purpose: passing someone is
## something *she* does, at a distance she chooses.
const PEDESTRIAN_SPEED := Vector2(46.0, 74.0)
## Ordinary traffic outpaces a walk but never quite matches the fire engine: an emergency
## vehicle has to stay the fastest thing on the road, or its long telegraph stops reading as
## urgency and starts reading as ordinary traffic.
const CAR_SPEED := Vector2(130.0, 185.0)

## One person, close enough to brush past. Deliberately above the walking decay: a close
## pass has to cost something or the crowd is scenery again. Walking wide of them does not
## — the pavement is two tiles, so how close to pass is a real choice.
##
## **The outer radius was 88 and came in to 55 in playtest 07, and the number did not change so
## much as the shape under it did.** `falloff` grew a shoulder that milestone (see the note there):
## every source in the game now holds three quarters of its intensity at the midpoint of its band
## instead of a quarter. That is what finding 18 asked for and it is right for an **event**, which
## is a thing on the map to route around — and wrong for a **body**, which is one of two hundred
## and forty and is supposed to be inaudible from across the pavement. Left alone it put the
## arterial floor at 18.4/s against a walking decay of 3.5, which is a main road that fills the
## meter in six seconds.
##
## So the crowd pays the shape back in radius, and the character it is defending is M27's measured
## one: **careless is expensive and careful is free.** A close pass still costs 4.2/s, because the
## intensity and the inner radius did not move; two tiles away is 0/s again, as it was. What is
## gone is the wide, cheap middle that used to be worth almost nothing and is now worth a lot.
##
## **"Two tiles away" is true of one walker and was unreachable on a footway.** *(M46, measured
## twice.)* A footway is two tiles, and while its lanes sat on their tile centres they were 32px
## apart — so the midline, the only line with no head-on contact on it, was 16px from two lane
## centres and inside the **full-intensity core** of both. The ambient floor measured flat across a
## pavement (4.30 frontage / 4.96 midline / 4.76 kerb), the careful line for contacts was the
## careless one for noise, and *how close to pass* was not the choice this comment claims.
##
## `CrowdLanes.SIDEWALK_LANE_SPREAD` is what made it one: the lanes are 48px apart now, so the
## midline is **24px from each of them and outside `PEDESTRIAN_INNER_RADIUS`** rather than inside
## it. Measured over the same walk, the field at an ordinary midline fell 74 → 56 points per forty
## seconds. That is the one change to make if this ever stops being true again — the intensity and
## the radii are pinned by the arterial floor and the shoulder, and the geometry is not.
const PEDESTRIAN_INTENSITY := 4.2
const PEDESTRIAN_INNER_RADIUS := 22.0
const PEDESTRIAN_OUTER_RADIUS := 55.0

## A car is louder than a person and passes much faster. No single car outruns the walking
## decay — the point is not that one car is dangerous, it is that on a main road there is
## always another one. The floor is the *street*, and it is emergent; the first pass at these
## numbers put the arterial at +15/s, which filled the meter in seven seconds and made the
## main road not expensive but impassable.
##
## 170 → 104 for the same reason the pedestrian's radius came in, and measured the same way: the
## arterial has to stay between the walking decay and three times it, which is `tests/test_crowd.gd`
## and is the one place the noise floor is pinned to anything.
##
## **And 104 is wider than the street it is on.** *(M46, measured.)* A corridor is six tiles —
## 192px — and a car's field is 208px across, so every tile of both footways is inside it and the
## frontage lane, the furthest place from a carriageway there is, sits 64px from the nearer lane
## centre. Nowhere on an ordinary street is out of the traffic's earshot, which is most of why the
## noise floor measures flat across a pavement. See M46 in `docs/TODO.md`.
const CAR_INTENSITY := 5.4
const CAR_INNER_RADIUS := 38.0
const CAR_OUTER_RADIUS := 104.0

## Chance a walker turns a corner rather than carrying straight on, rolled once per
## junction. High enough that the crowd churns, low enough that streets still have flow.
const PEDESTRIAN_TURN_CHANCE := 0.35

# ------------------------------------------------- bodies on the street (M19) ---
# Playtest 02, findings 2 and 3: *"going to and from a park bears no risk. I don't bump into
# people... I cannot hit cars."* Until M19 the crowd was a field with a picture attached —
# every pavement was identical and none of them could hurt you, which is why the route was
# never a decision. See docs/MECHANICS.md, "The street has physics".

## The pram's own collision circle, in px. Authored in `scenes/player/stroller.tscn`; this is
## the copy the rules that reason *about* it can read, and `tests/test_events.gd` asserts the two
## agree, because a duplicated number that nothing checks is a lie waiting to happen.
##
## It is the same 14 as `BUMP_RADIUS` and they are not the same quantity: that one is a tuning of
## when a *crowd contact* fires and is stated against the lane spacing, this one is how much room
## she physically takes up. Either may move without the other.
const PLAYER_BODY_RADIUS := 14.0

## Centre-to-centre distance at which the player and a pedestrian are touching.
##
## It has to be **under half a lane spacing**, and that is the whole of why it is 14 rather
## than a body's width. The only line with no contact on it is the midline between two lanes; at 18
## there was no such line anywhere on a two-tile pavement and walking the arterial cost eleven
## bumps in forty seconds however carefully it was done. At 14, holding that line takes the same
## walk down to two — which turns the crowd from a toll into the thing playtest 02 finding 3 asked
## for.
##
## **What M19 did not check is how *wide* that line is, and until M46 it was four pixels.** The
## lanes were a tile apart, so the clear line was `32 - 2 × 14` — something a player is
## occasionally on rather than something she can aim at, while forty seconds down an arterial lane
## centre cost 15.3 contacts against the midline's none. The fix is deliberately **not** here:
## `CrowdLanes.SIDEWALK_LANE_SPREAD` moves the lanes apart instead, because this number is what
## makes a contact mean *walking into somebody* and buying the line by shrinking it would make one
## require a near-perfect overlap. See M46 in `docs/TODO.md`.
const BUMP_RADIUS := 14.0

## How far apart a contact is pushed, and how far apart it has to get before it counts as over.
##
## **The two numbers that make a bump end.** *(Playtest 07, finding 5: "bumping into a person
## should resolve more — right now you can get trapped and stick to the other person which
## basically leads to instant death.")*
##
## The separation used to resolve to exactly `BUMP_RADIUS`, which is the distance at which
## `touching` flips back to false — so a resolved contact sits precisely on its own release
## threshold and flickers across it, firing a fresh `BUMP_INTENSITY` jolt every couple of frames
## for as long as the pair are near each other. A contact that costs 26/s once is a decision; one
## that costs it ten times in two seconds is the "instant death", and three of those in half a
## minute is how the playtest 07 traces lose a day.
##
## So it is a hysteresis band rather than one number: pushed apart to `BUMP_CLEAR_RADIUS`, and
## `touching` is only released past it. A bump therefore ends the frame it is resolved, and it can
## never re-fire without a genuine second approach.
##
## Deliberately a small band. Widening it would widen the corridor she has to thread down a
## pavement, and the note on `BUMP_RADIUS` is what happens when that number grows.
const BUMP_CLEAR_RADIUS := 19.0

## How much of the separation the player takes; the pedestrian takes the rest. She is pushing
## a pram and they are not, and being shoved by strangers must never take the verb away.
const BUMP_PLAYER_SHARE := 0.3

## How far across their own pavement somebody she walked into steps, and for how long.
##
## The other half of finding 5, and the half the hysteresis alone cannot fix. A walker steers to
## its lane centre at `CrowdAgent.STEER_SPEED`; if she is standing on that centre, the walker
## resolves out of the contact and then immediately steers back into her, forever. The separation
## being positional is what stops them being *inside* each other and cannot stop them being
## *against* each other.
##
## So the person she walked into gets out of the way, which is what a person does. Positional
## still — it is a target the walker steers to, not a force on the player — and clamped inside its
## own pavement band by `CrowdAgent.step_aside`, because a walker that yields into the carriageway
## is a walker under a car.
##
## A tile is the width of one pedestrian lane, so this is exactly "they move over one".
const BUMP_STEP_ASIDE := float(TILE_SIZE)
const BUMP_STEP_ASIDE_TIME := 2.5

## How far ahead somebody notices a pram coming and moves over, and how near her line they have
## to be to bother.
##
## **This is the fix for "the only thing that really kills my runs are just pedestrians".**
## *(Playtest 07, finding 17.)*
##
## The design M19 and M27 wrote down is that the crowd is *expensive to be careless in and free to
## be careful in*, and that the **ratio** is what makes a pavement a decision. It measured eleven
## contacts in forty seconds down a lane centre against one holding the midline between two lanes.
## A probe re-run on `main` for this playtest says that ratio is gone: thirteen against fifteen on
## the arterial, eleven against nine on a back street. There is no careful line any more, so the
## crowd stopped being a decision and became a toll — and at ~30 points a contact, a toll that
## ends the day.
##
## The reason it went is arithmetic and cannot be tuned back: pedestrian lanes are one tile apart,
## so a midline is 16px from two lane centres and `BUMP_RADIUS` is 14. That line was two pixels
## wide when M19 measured it, and every milestone since has given walkers more reason to be off
## their exact centre — M21's T-junctions, M27's recycling, and this milestone's own sidestep.
##
## So the careful line is not a *line* any more, it is a **behaviour**: somebody who sees a pram
## coming moves over. That restores the ratio the design is built on without needing two pixels of
## pavement to be found, and it prices the right thing — a contact is now what carelessness costs,
## not what walking costs. It stays honest three ways: they only move a lane, they cannot move
## into the carriageway (`CrowdAgent._pavement_band`), and at `RUN_SPEED` she covers the notice
## distance in 0.57s against the 0.36s they need to clear a lane, so **running still hits people**.
const CROWD_YIELD_DISTANCE := 96.0
## How near they have to come to her — at their **closest approach**, not right now — to bother
## getting out of the way. A little over `BUMP_RADIUS`, so it is "we are going to touch" rather
## than "we will be near each other", and a pavement does not part like the Red Sea in front of
## her.
const CROWD_YIELD_LATERAL := 22.0
## How far ahead that approach is predicted. Long enough to be worth acting on — a walker needs
## 0.36s to clear a lane — and short enough that somebody two seconds away carries on as normal.
const CROWD_YIELD_LEAD := 1.4
## Speed of the deflection a contact gives the player. Well under `WALK_SPEED`, so a bump
## knocks her off her line without steering her.
const BUMP_SHOVE_SPEED := 55.0

## A contact is not a write to `Baby.excitement` — it agitates the *person* she walked into,
## and the crowd sums them like it always did. See the invariant in CLAUDE.md.
##
## **26 → 18 in playtest 07, and it is the mix that moved rather than the difficulty.**
## *(Finding 17: "currently the only thing that really kills my runs are just pedestrians" /
## "the actual dangers are not really dangerous since they don't have an effect at all.")*
##
## A bump was about sixteen points of a hundred-point meter, so four of them lost a day — and the
## traces have three day-2 attempts lost inside half a minute with the crowd supplying between 82%
## and 100% of the excitement in each. Meanwhile `falloff`'s new shoulder roughly doubled what
## every **event** is worth from a distance. Left alone, that would have made an already lethal
## street lethal sooner; what it should do instead is hand the day back to the authored content.
##
## So a contact is about eleven points now. Still the single most expensive instant on a pavement,
## still four or five of them to lose a day on the crowd alone, and no longer the only thing in
## the game with an opinion. The two halves of the fix are meant to be read together: people get
## out of her way (`CROWD_YIELD_DISTANCE`) so a contact is carelessness rather than a toll, and it
## costs less when it happens because it is no longer the whole game.
const BUMP_INTENSITY := 18.0
const BUMP_DURATION := 1.2
const BUMP_INNER_RADIUS := 30.0
## 90 until playtest 07. The jolt is a body's own source, so it took the same shoulder every
## other source took, and a bump she is walking away from was being charged for most of its
## tail rather than a sixth of it. The cost at the moment of contact is unchanged.
const BUMP_OUTER_RADIUS := 62.0

## The car's body, as a box rather than a circle: a car is two tiles long and one wide, and a
## radius that covered its length would kill people standing beside it.
const CAR_STRIKE_HALF_LENGTH := 26.0
const CAR_STRIKE_HALF_WIDTH := 14.0
## Below this a car cannot run anybody over, however close they stand to it. A car halted at a
## zebra is scenery, and walking into one must not end the day.
const CAR_STRIKE_MIN_SPEED := 20.0

## Seconds of travel at which a car sounds its horn at somebody standing in its lane. This is
## the traffic fairness contract, and `validate_traffic()` checks it: the warning has to be
## long enough to walk out of the carriageway before the car arrives, with the same doubled
## margin every other hard fail gets.
const CAR_HORN_TIME := 1.6
## The horn itself, as a jolt on the car that sounded it. A near miss costs something even
## when it is only a near miss.
const CAR_HORN_INTENSITY := 18.0
const CAR_HORN_DURATION := 0.9
const CAR_HORN_INNER_RADIUS := 45.0
## 190 until playtest 07, brought in with the rest of the crowd's radii when `falloff` grew its
## shoulder. A horn is still heard from a good deal further than a car is.
const CAR_HORN_OUTER_RADIUS := 132.0
## How long the exclamation mark stays up over the player after the last horn. Long enough to
## survive the gap between two cars in the same lane.
const CAR_WARNING_HOLD := 1.4

## How near the end of the day, in seconds, the doubled mark means *now*.
##
## *(M39, playtest 10 finding 11.)* The mark over her head is the one cue in the game that gives an
## **instruction**, and its second level says *it is bad now and you are in it: one step left*. That
## is a claim about a moment, so it needs a clock rather than a radius — it was raised anywhere
## inside a lethal event's **outer** radius, which for a cyclist is more than thirty times the area
## that can actually end the day, and it stayed up while the bike rode away.
##
## Read it as the step: at `WALK_SPEED` it is 64px, which is two tiles, which is the width of the
## pavement she would have to leave. Long enough to be an instruction she can still obey and short
## enough that it is never up while the answer is "carry on walking".
const LETHAL_MARK_LEAD := 0.7

## Traffic that queues instead of driving through itself. *(M27, playtest 04: "cars still bump
## into each other".)* A car keeps `CAR_HEADWAY_TIME` seconds of clear road in front of it and
## never closes to less than `CAR_GAP_MIN`, which is a car's own length plus a nose.
##
## The relationship that matters, and the one `tests/test_crowd.gd` states: the headway has to
## be longer than the *braking* time from cruise, or a car physically cannot honour it and the
## queue resolves by interpenetration again. `CAR_BRAKE` is shared with the zebra, so this is
## free to check and cheap to get wrong.
const CAR_HEADWAY_TIME := 0.85
const CAR_GAP_MIN := 66.0

## Deceleration when a car gives way at a crossing, and how far ahead it looks for one. The
## relationship that matters is `CAR_ZEBRA_SIGHT > braking_distance(CAR_SPEED.y) +
## CAR_STOP_LINE_SETBACK`: a car always has room to stop **at the line** for a zebra it can see,
## so giving way is never a screech.
const CAR_BRAKE := 320.0
const CAR_ACCELERATE := 150.0
const CAR_ZEBRA_SIGHT := 200.0
## How far before the paint a car giving way comes to rest, measured to the car's centre. Its
## nose is `CAR_STRIKE_HALF_LENGTH` in front of that, so it stops a few pixels short of the
## zebra rather than over it.
##
## Playtest 05, finding 1: *"the cars stop at weird positions for the zebra crossing. Sometimes
## half a block away, sometimes **on** the crosswalk."* Both are the same missing thing. Until
## M29 a car braked toward **zero speed** from wherever it happened to notice, so where it ended
## up was wherever the braking curve ran out — and `CAR_ZEBRA_SIGHT` is nearly four times the
## distance it needs, so that was usually most of a block short. Nothing said *do not stop on the
## paint* either. Giving way is now aimed at a place, and the place is this one.
##
## Why it matters more than it sounds: the painted carriageway is one of the two things standing
## in for a telegraph in the traffic fairness contract. A car halted on the zebra is scenery by
## `CAR_STRIKE_MIN_SPEED` and cannot hurt anybody — but it is *unreadable* scenery sitting on the
## one place the game has told the player is the safe way across.
const CAR_STOP_LINE_SETBACK := 34.0
## The deceleration a car *aims* at when it eases up to a stop line, as opposed to `CAR_BRAKE`,
## which is the hardest it can push. Giving way has to be **visible from the kerb** — that is why
## the looking starts at `CAR_ZEBRA_SIGHT` and not at the line, and that reason survives M29 — so
## the approach is shaped by a gentle rate and only the emergency uses the hard one.
##
## The relationship, and the one `tests/test_crowd.gd` states:
## `sqrt(2 · CAR_ZEBRA_APPROACH_BRAKE · CAR_ZEBRA_SIGHT) >= CAR_SPEED.y` — the fastest car in the
## city begins easing at the moment the zebra comes into sight, rather than holding speed and
## then grabbing the brake at the last legal instant.
##
## Getting this wrong in the obvious way is instructive: shaping the approach with `CAR_BRAKE`
## itself makes the onset of braking and the commit point the *same* moment, so a car glides up
## to the line at full speed, decides it can no longer stop, and drives through. Every car in the
## first M29 build did exactly that, and the test that caught it is the one that says where a
## car stops rather than whether.
const CAR_ZEBRA_APPROACH_BRAKE := 90.0
## How close to the crossing the player has to be for the traffic to yield. Roughly "standing
## at the kerb waiting", which is the gesture the crossing is for.
const CAR_ZEBRA_WAIT_RADIUS := 56.0

## How far out a car starts watching the junction it is coming to.
##
## The relationship, the same one `CAR_ZEBRA_SIGHT` keeps and for the same reason: it has to
## exceed `braking_distance(CAR_SPEED.y)` by the setback, or a car that has only just seen a box
## it must wait at cannot stop before it. Below that the give-way turns into a car standing in the
## middle of the junction, which is the failure it exists to prevent rather than a milder version
## of it.
const CAR_JUNCTION_SIGHT := 200.0
## How close two arrivals have to be for the box to be a *conflict* rather than a queue, and
## therefore for right-before-left to decide it instead of distance.
##
## A car's own length, near enough: closer than that and the second car is behind the first
## through the box rather than beside it. Wider and a car yields to somebody who was never in its
## way; narrower and a symmetric arrival is settled by a couple of pixels of float noise, which is
## right-before-left never actually running.
const CAR_JUNCTION_TIE := 60.0

# ------------------------------------------------- the world near you (M27) ---
# Playtest 04: *"the cat is ineffective since it happens when it spawns — the cat should get
# spawned in in front of the player while they walk"*, and *"don't load everything upfront"*.
# Both are the same change: the world is populated around the player instead of authored across
# a map she mostly never visits. See docs/MECHANICS.md, "The world near you".

## How close the player has to get before a planned event is actually put in the world.
##
## Two floors, and the larger wins. The **screen**: half the viewport diagonal is 735px, so at
## 900 an event always appears off-camera and never pops into an empty pavement. The **fairness
## contract**: the widest field in the catalogue is 380px, so an event that streams in is
## already outside its own outer radius when it becomes visible — which is what makes streaming
## an event legal at all. `tests/test_events.gd` checks the second against the catalogue.
const EVENT_STREAM_RADIUS := 900.0
## And how far past it an event has to get before it is taken away again, so an event on the
## boundary does not flicker in and out as the player paces.
const EVENT_STREAM_HYSTERESIS := 260.0

## Far enough from the player that nothing there can be seen. *(M35, playtest 08 finding 3.)*
##
## The camera sits on her at zoom 2 over a 1280x720 viewport, so the visible world is 640x360 and
## its far corner is 367px away; `Stroller.CAMERA_LOOK_AHEAD` can push that to about 410 on the
## trailing side. 420 is the first round number outside it.
##
## Not to be confused with `EVENT_STREAM_RADIUS`, which is deliberately more than twice this: an
## event is put in the world *long* before it can be seen, so that nothing is ever watched into
## existence. This is the other end of the same rule — nothing is watched out of existence either.
const OUT_OF_SIGHT := 420.0

## How far ahead of the player an `AHEAD` event crosses her line, in px. This is a *reaction
## window* stated as a distance: at `WALK_SPEED` it is the two seconds she gets between seeing
## the cat crouch and reaching the place it bolts through.
const AHEAD_LEAD_DISTANCE := 184.0
## The furthest ahead of her something may be sited and still be **on screen** when it gets there.
##
## *(M39.)* The camera sits on her at zoom 2 over a 1280x720 viewport, so the visible world is
## 640x360 and the worst axis is the vertical one: 180px, plus about 32 of camera look-ahead. A
## pursuer is sited beyond its own stand-off so that it visibly closes into it, and this is the cap
## on that — a dog telegraphing off the top of the screen is a dog with no telegraph, and the sight
## of it is the whole cue.
##
## Not to be confused with `OUT_OF_SIGHT`, which is the *other* end of the same measurement and is
## deliberately more generous: nothing may be watched out of existence, so that number is the far
## corner of the view and this one is the near edge of it.
const SIGHT_AHEAD := 200.0

## She has to actually be going somewhere for something to happen in front of her. Below this
## there is no "in front".
const AHEAD_MIN_SPEED := 40.0
## Seconds between two `AHEAD` events, so the day's allowance is spread over the walk rather
## than spent in the first ten seconds. The director rolls within this band.
const AHEAD_INTERVAL := Vector2(11.0, 26.0)

# ------------------------------------------------ one event per block (M28) ---
# Playtest 05, finding 6: *"I want one event per block. The dog walker decision should happen
# meaningfully — I want to have to make that decision at least twice on day one."*
#
# The density lives in `EventScheduler.budget_for()` and the catalogue's `max_per_day`, both
# **measured** rather than derived. What lives here is the thing that had to be invented to
# make the density legible: until M28 the per-type caps were the only reason two of the same
# event never landed on one pavement, because placement is a uniform random tile. Raising the
# caps takes that away, so the separation becomes a rule of its own.

## Two events of the same kind never land closer than this. A block is 256px across, so this
## is "not on the same stretch of pavement" — the objection was never to seeing a second dog
## walker, it is to seeing it thirty pixels from the first, which reads as a duplicate rather
## than as a second incident.
const EVENT_SPACING_SAME := 256.0
## And nothing of any kind lands inside this of anything else, which is about two tiles: close
## enough that a café and a shouting man can share a corner, far enough that neither is drawn
## inside the other.
const EVENT_SPACING_ANY := 64.0
## Candidate tiles tried per placement before taking the roomiest one that was offered. A
## fallback rather than a failure: a scripted event has to happen, and on a full map the honest
## answer is the best spot left, not no event.
const EVENT_PLACEMENT_TRIES := 24

# --------------------------------------------------- placement by role (M50) ---
# docs/CITY.md, "The words for it" and "Diversions — the design". A day is planned against a
# **corridor** now — the ways from the doorstep to the calm areas still worth reaching — and what
# each of these two numbers does is pull one kind of thing toward one part of it.
#
# Both are stated as **how many times a tile is offered to the roll**, which is `_ground_for`'s
# existing mechanism rather than a new one: the roll is an index into the candidate array, so
# offering a tile four times over *is* the weight, and every spacing rule downstream keeps working
# unchanged. The precinct weight above is the same shape and is multiplied through, so a corridor
# tile in a precinct is offered sixteen times.
#
# Neither is a filter, and the one filter there is lives in `EventScheduler._copies_of`: **a wall
# is never inside the corridor.** That one can be absolute because the whole off-corridor city
# remains available to it, so it cannot starve a row of ground — which is what a weight buys
# everywhere else here and is why these are weights.

## How many times over a tile on the day's routes is offered to a **friction** placement.
##
## *"Benign blockers go on the route… to make it more challenging / force the player to think their
## route through better."* About a quarter of the lattice is on the tree, so at 4 rather better
## than half of the costly rows land on the corridor and the rest of the city keeps a scatter — a
## city where every street off the route is empty would read as a set rather than as a place, and
## nothing in the design asks for that.
const EVENT_CORRIDOR_WEIGHT := 4

## How many times over a turning off the corridor is offered to a **wall** placement, against a
## street further out.
##
## A wall bounds the corridor, so it has to be somewhere the corridor can see; a lethal thing four
## streets away bounds nothing. That is the preference. What is not a preference is the exclusion
## beside it — the same reasoning as `CLOSURE_WALL_BIAS`, which is this number's twin one system
## over and deliberately the same value.
##
## **Since the range arrived it applies to the *costly* half of the wall band only.** A very costly
## row is what the rim is for — she has strayed one turning and it is expensive — and a lethal row
## wants the ground beyond it. See `EventScheduler._copies_of` and `WALL_DEEP_WEIGHT`.
const EVENT_WALL_RIM_WEIGHT := 4

## How many times over ground two or more turnings off the corridor is offered to a **lethal** wall,
## against the rim.
##
## *(2026-08-31: "areas that outside the paths should have blocking events all over — we don't want
## the player to step in those areas and it ranges from very costly to deadly.")* The range is over
## distance from the routes, so the two ends of it pull in opposite directions and this is the
## second one. Deliberately the same strength as the rim weight it mirrors: the design is a gradient
## rather than a preference for one band, and giving deadly a stronger pull than very costly would
## make the rim the quiet part of the off-corridor city, which inverts the sentence.
const WALL_DEEP_WEIGHT := 4

## Where the line between *friction* and a *very costly* wall falls, in points of the meter it costs
## to walk through the middle of a row.
##
## Below it a row is friction and is weighted **onto** the routes; at or above it the row is what
## closes the ground **off** them. Stated over `EventDef.walk_through_cost()` — the same integral
## the caret is ordered by — rather than over a field somebody sets per row, because a second answer
## to *how expensive is this* is the defect M37 found in `DangerEdge`.
##
## **It was `MARK_WORTH_A_DETOUR` for one measurement and that was wrong, which is worth keeping
## because the argument for it was good.** That constant is where the game raises a caret — *this is
## worth going round* — so putting the same rows off the corridor made the cue and the placement say
## one sentence. What it actually did was empty the routes: at 25 points **two thirds of every day
## became a wall**, and day 1's corridor went from 69.6 placements to 27.8 of 113. The player asked
## for the ground off the paths to be closed; nobody asked for the paths to be cleared.
##
## The line is set by one row instead, and by the right one. **`dog_walker` costs 36.5 and has to
## stay friction**: *"the dog walker decision should happen meaningfully — I want to have to make
## that decision at least twice on day one"* (playtest 05) is the route decision this game is made
## of, and a dog walker that is never on her route is that decision deleted. So the line goes above
## it, and the first row above it is `loose_dog` at 43.3 — which is where *very costly* starts
## reading as the player's own word rather than as "costly". Forty points is four tenths of the
## meter to walk through the middle of.
##
## What that leaves on the corridor is `cafe_tables`, `market_stall`, `homeless_yeller`,
## `delivery_van` and the dog walker — the ordinary expensive city — and what it puts off it is
## `loose_dog`, `leaf_blower`, `burning_building`, `protest`, `military_convoy`, `night_raid` and
## every lethal row. Re-measure with a probe if the cost table moves; do not re-derive it.
const WALL_WORTH_OF_COST := METER_MAX * 0.4

# ------------------------------------------------ solid things are solid (M34) ---
# Playtest 07, finding 16: *"none of the non-moving obstacles do anything — I can freely walk
# over them."* `obstructs_radius` was set on five rows of thirty, so a delivery van, an ice cream
# van and a burnt-out shell were all large, visibly solid, stationary objects with no body at all.
#
# The rule that replaced the list is in `EventDef.obstructs_radius`: **anything that stands still
# is solid at the width it is drawn**. What lives here is the one number that rule needs from
# outside itself.

## The widest body an event may have and still be allowed to stand on calm ground.
##
## `EventScheduler._something_to_put_in_a_park` used to refuse *anything* with a body, which was
## the right rule while the only things that had one were scaffolding and barricades: a spoiler
## has to make the park loud rather than take the ground away. Once a busker is solid — a person
## is 18px across — that reading would have emptied the pool and quietly retired M24 altogether.
##
## So the rule is stated as what it always meant. A body you can walk around does not close a
## 704px lot; one you have to route around does. Sized to sit above a person and well under
## `construction`, which is exactly the thing it is there to keep out.
const OBSTRUCTION_A_PARK_CAN_HOLD := 16.0

## The most things M24 will put in the park she used yesterday. *(M35, playtest 08 finding 1: "the
## robber in the park is still ineffective — I can use the same park every day — and there is only
## one robber".)*
##
## It was one, and one is three percent of a four-block calm zone — see
## `EventScheduler._denial_radius` for the arithmetic nobody did in M24. A cap rather than a target:
## the grid asks for as many as it takes to cover the ground and this is where it stops asking,
## because the events are drawn from the day's own pool and a park with a dozen things in it is not
## a spoiled park, it is a different kind of city.
##
## Nine is a 3x3 grid, and it is measured: over twenty lots and five seeds it denies **99%** of a
## four-block calm zone and 91% of a one-block courtyard, against 8-12% for the same lot on an
## ordinary day. Six — a 3x2 grid — was the first try and left 15% of the biggest zones standing,
## which is a hundred tiles of usable park and *"I can use the same park every day"* all over again.
##
## A small lot never asks for nine: the grid is sized from what one of them actually denies, so a
## 46-tile courtyard takes one or two and this cap is never reached. What it costs is a day with
## nine more events in it, all of them inside the one lot she is being asked not to use.
const SPOILERS_TO_DENY_A_PARK := 9

# ------------------------------------------------------ running that matters ---
# Playtest 07: *"the run button is a trap shouldn't be an invariant — there should be legitimate
# cases where running is required."* And, in the same breath, when: *"can we make it so those
# cases only start appearing on day 3"*, with *"an incident at the start to force running"*.
#
# So the run is **taught** rather than merely permitted, and it is taught the day it starts to
# matter. Day 1 is arrow keys and nothing else; day 3 is the day something comes after the pram.

## The day running stops being a bad idea and starts being the answer.
##
## Day 3 is act I's last day and already the day it grows teeth — `reversing_lorry` arrives then,
## and `cyclist` on day 2 — so this is the third of three escalations rather than a fourth kind of
## thing. It is also late enough that a player has had two days of the meter to learn that running
## is expensive, which is what makes being *made* to run land as a change of rules rather than as
## the rules finally being explained.
const RUN_TAUGHT_DAY := 3

## How long a pursuer keeps coming once it turns lethal, before it gives up.
##
## Bounded by the cost of the answer, not by the fiction: at `EXCITEMENT_FROM_RUNNING` a sprint is
## fourteen points a second, so a six-second chase is most of the meter and being *made* to run
## would be being made to lose.
##
## It is the cap on **doing nothing**. A player who answers is out of it well before the clock is,
## because `PURSUIT_SHAKEN_OFF` ends the chase when she has beaten it; a player who does not is
## caught, which is the point.
##
## It cannot fall much below this, and the constraint is worth knowing before reaching for it:
## walking away must still lose *inside the chase*, so the chase has to be long enough to close the
## stand-off at `pursue_speed - WALK_SPEED` — 38px/s against the day-3 dog. Every extra pixel of
## stand-off therefore costs 1/38 s of chase, which is why a **narrower** stand-off is what buys a
## shorter one.
const PURSUIT_TIME := 3.0

## And the least a pursuer's speed may differ from either of hers.
##
## The contract in one line: **walking must lose and running must win.** So its speed sits
## strictly between the two, far enough into the band that the difference is worth acting on
## inside `PURSUIT_TIME`. The margin is small at the top end on purpose — a run that only just
## outpaces it is a run she has to actually commit to.
const PURSUIT_MIN_MARGIN := 20.0

## And the least notice one has to give: its telegraph, during which it is visibly coming and
## emitting `TELEGRAPH_INTENSITY_FRACTION`, but cannot yet end the day.
##
## A pursuer's telegraph is the **approach**, the way a fire engine's is — a dog that has to bark
## for two seconds before it is allowed to start running is not a dog. So the notice is the sight
## of it closing, and this is how much of that she is owed before it can touch her.
const PURSUIT_MIN_NOTICE := 1.5

## How long she is allowed to take to answer the lunge, at the speed the gap is actually closing.
##
## *(Playtest 08, finding 4: "I like the running tutorial on day 3 but I don't know how to solve it
## yet — I died every time".)* **A notice stated as a duration is not a notice.** M33 bought the
## telegraph time and never asked where the dog spends it, and the trace says where: sited 184px
## across her line by the director and closing at 148px/s while she walked *towards* it at 92, it
## covered the gap in three quarters of a second and then stood inside its own lethal radius for
## the remaining 1.7s of a telegraph that was not allowed to kill her yet. The instant it ended, it
## did — at 12px, from a standing start, with nothing she could have done after the first second.
##
## So the telegraph is spent **closing to a stand-off and holding there**, which is
## `pursuit_standoff()` below, and this is the number that sets it: far enough out that the lunge
## itself can be answered rather than merely watched.
##
## **This number is the one thing about the day-3 dog a player has said is right.** *(Playtest 10:
## "the charging start earlier was fine — it was enough time to react properly".)* M39's own analysis
## of finding 13 read it as a reaction-window problem, derived that the window is really two tenths
## of a second once her own walking speed and the cost of the about-turn are counted, and cut this to
## 0.45 with a much wider stand-off to compensate. The arithmetic was correct and it was answering a
## question nobody had asked: the complaint was *"the dog kept following for too long"*, which is the
## break-off. The reaction stays at 0.6 and the price of the answer is what moved. See
## `PURSUIT_SHAKEN_OFF` and `docs/PLAYTEST-10.md`, section C.
##
## What boxes it in, in both directions: **walking must still lose** and **running must still win**
## inside `PURSUIT_TIME`, both at 38px/s of authority against the day-3 dog, and the stand-off has to
## be **on screen** — the visible world is 640x360 at zoom 2, so a dog standing much past 180px in
## front of her telegraphs off the top of the screen when she walks north or south, and the sight of
## it is the whole cue.
const PURSUIT_REACTION := 0.6

## How long she has to be **running** before it gives up, in seconds.
##
## The half that makes running **payable**, and the whole of what the chase costs when it is
## answered. Running is `EXCITEMENT_FROM_RUNNING` a second, so a chase priced by its own clock costs
## the same whether she reacted on the first frame or the last — a toll rather than a lesson.
##
## **Stated over the player, not over the gap.** *(Playtest 14: "the pursuing dog still doesn't
## stop. It's a very simple rule — when I run the dog backs down almost immediately.")* It was
## 0.8s of the *gap actually opening*, which is the same idea expressed as geometry, and the two
## are not the same rule in a real street. A run opens the gap at 38px/s against the day-3 dog —
## a fifth of a pixel a frame — so anything that momentarily stopped her gaining ground reset the
## timer to zero: a corner, a kerb, a pedestrian, the 0.37s the about-turn itself takes. The dog
## went on chasing somebody who was visibly sprinting, which is the one outcome that makes the
## mechanic unteachable, and it was reported three playtests running.
##
## The contract it used to carry is unaffected, because it never rested here — it rests on the
## speed clauses in `validate_pursuit`. A pursuer is faster than a walk and slower than a run by
## `PURSUIT_MIN_MARGIN` on both sides, so **walking away still cannot end it** (she is never
## running, so this timer never starts) and **running away always can**.
##
## 0.8 → 0.35, which is "almost immediately" and is about what the about-turn costs: the dog breaks
## off as she comes up to speed rather than after she has opened thirty pixels of daylight on it.
## It buys back the bulk of what the answer used to cost — see M49 in `docs/TODO.md`.
const PURSUIT_SHAKEN_OFF := 0.35

## How close a pursuer comes while it is still only telegraphing.
##
## Derived rather than authored, because it is the fairness contract in geometric form: between the
## moment it is allowed to end her day and the moment it can, she is owed `PURSUIT_REACTION` seconds
## of the thing's own approach. Anything nearer and the telegraph is a formality; anything much
## further and it is off the screen, which is worse — the sight of it closing is the whole cue.
##
## **The edge case it does not price, and it is a known gap.** At the instant of the lunge she is
## usually walking *into* it — a pursuer is sited in front of her, forward is where she was going,
## and the stand-off is held by the thing backing off rather than by her stopping — so the gap closes
## at `pursue_speed + WALK_SPEED` and the notice is worth about a third of what this buys. Reversing
## a walk into a run costs another `(WALK_SPEED + RUN_SPEED) / ACCELERATION` seconds on top, during
## which the thing keeps coming. Measured against the day-3 dog the real window is about **two tenths
## of a second**.
##
## Both terms were folded into this function and then taken back out. The stand-off they produce is
## 70px wider, and the extra ground is spent *reversing away from her* through the telegraph, which
## reads to a player as a dog that has changed its mind. What it bought was a wider window on the one
## part of the encounter a player has said was already right. The cost of the answer is priced by
## `PURSUIT_SHAKEN_OFF` instead, which is where the complaint actually was.
func pursuit_standoff(pursue_speed: float, inner: float) -> float:
	return inner + pursue_speed * PURSUIT_REACTION

## The pursuit fairness contract, and the one place it is stated.
##
## `validate_event`'s escape-distance rule is about walking out of a *field*, and a pursuer has no
## field to walk out of — it follows. So it needs its own contract, and `docs/TODO.md` said what it
## would have to be stated over before there was anything to state it about: `RUN_SPEED`.
##
## The clauses, each of them one of the ways a pursuit can be unfair:
##
## - **Walking must lose.** Faster than `WALK_SPEED` by a real margin, or the mechanic teaches
##   nothing — she strolls away and the run key stays a trap.
## - **Running must win.** Slower than `RUN_SPEED` by the same margin, or it is not a lesson, it
##   is a death sentence with a keypress attached.
## - **It must let go.** A chase with no end is a chase she cannot afford: running is priced per
##   second, so an unbounded one is a loss however well it is played.
## - **Running has to open more than the radius that ends the day**, over the whole chase. Otherwise
##   running is the correct answer and still not enough.
## - **The notice is the sight of it coming**, and there has to be at least `PURSUIT_MIN_NOTICE` of
##   it before the thing may end her day.
## - **It stands off inside its own field.** A pursuer holding a stand-off outside `outer_radius`
##   emits nothing at her for the whole of the phase that is supposed to *be* the warning: no meter,
##   no `!` over her head, and a telemetry entry that cannot say what raised the mark. This one was
##   found by walking a rig rather than by reading it.
## - **It notices her from outside its own stand-off**, or the notice is spent somewhere it was
##   never going to move from and the telegraph is a formality. (`pursues_within` only.)
## - **It cannot notice her from outside its own field.** What she is owed before a lethal thing
##   starts making decisions about her is the chance to have felt it: the meter is the only thing
##   that says a stranger in an alley is worth crossing the road for, and it says nothing at all
##   past `outer_radius`. (`pursues_within` only.)
##
## **Two clauses that used to be here are gone, and their absence is the design.** The chase used to
## end at a *distance*, so the contract needed "walking cannot reach it inside the chase" and
## "running can" — two inequalities in the same three numbers, pulling opposite ways, which is why
## widening a stand-off silently ate an escape and a robber's trigger once had an eleven-pixel window
## to live in. `PURSUIT_SHAKEN_OFF` ends it at a *rate* instead, and the first two clauses above then
## make both facts true by construction: nothing slower than the pursuer can open the gap at all, and
## nothing faster can fail to.
##
## **What this contract still cannot see**, and it is why the rig exists: every clause is about the
## pursuer, and none is about *her*. She is usually walking into the thing when it lunges, and
## turning round costs ground before the run gains any — so a row can satisfy every line below and
## still leave a two-tenths-of-a-second window. See `pursuit_standoff()`. The rig in
## `tests/test_events.gd` that has to accelerate is what checks the half this cannot.
func validate_pursuit(id: String, speed: float, chase_time: float, inner: float,
		telegraph: float, notice_within := 0.0, outer := 0.0) -> bool:
	if speed < WALK_SPEED + PURSUIT_MIN_MARGIN:
		push_error("Unfair pursuit '%s': %.0fpx/s is not enough faster than a walk (%.0f)"
				% [id, speed, WALK_SPEED])
		return false
	if speed > RUN_SPEED - PURSUIT_MIN_MARGIN:
		push_error("Unfair pursuit '%s': %.0fpx/s cannot be outrun (%.0f)"
				% [id, speed, RUN_SPEED])
		return false
	if chase_time <= 0.0 or chase_time > PURSUIT_TIME * 2.0:
		push_error("Unfair pursuit '%s': a %.1fs chase is not something a run can end"
				% [id, chase_time])
		return false
	# And the gap a run opens over the whole chase has to actually clear the lethal radius, or
	# running is correct and still not enough.
	var opened := (RUN_SPEED - speed) * chase_time
	if opened < inner:
		push_error("Unfair pursuit '%s': running opens %.0fpx over %.1fs, less than the %.0fpx "
				% [id, opened, chase_time, inner] + "that ends the day")
		return false
	if telegraph < PURSUIT_MIN_NOTICE:
		push_error("Unfair pursuit '%s': %.1fs of it coming is not enough notice (%.1fs)"
				% [id, telegraph, PURSUIT_MIN_NOTICE])
		return false
	# Being shaken off has to be reachable inside the chase at all, or the rate rule is decorative
	# and the clock is back to pricing the answer.
	if chase_time <= PURSUIT_SHAKEN_OFF:
		push_error("Unfair pursuit '%s': a %.1fs chase is shorter than the %.1fs of being outrun "
				% [id, chase_time, PURSUIT_SHAKEN_OFF] + "that ends it, so nothing she does matters")
		return false
	# A pursuer that holds its stand-off outside its own `outer_radius` emits nothing at her for the
	# whole of the phase that is supposed to be the warning — no meter, no `!` over her head, and a
	# telemetry entry that cannot say what raised the mark.
	var standoff := pursuit_standoff(speed, inner)
	if standoff > outer and outer > 0.0:
		push_error("Unfair pursuit '%s': it stands off at %.0fpx and reaches %.0fpx, so its whole "
				% [id, standoff, outer] + "notice is spent outside its own field")
		return false
	if notice_within <= 0.0:
		return true
	if notice_within <= standoff:
		push_error("Unfair pursuit '%s': it notices her at %.0fpx and stands off at %.0fpx, so its "
				% [id, notice_within, standoff] + "whole notice is spent standing still")
		return false
	if notice_within > outer:
		push_error("Unfair pursuit '%s': it notices her at %.0fpx and reaches %.0fpx, so it decides "
				% [id, notice_within, outer] + "about her before she can feel it at all")
		return false
	return true

## The carriageway, in px — the width the player has to clear when a horn goes.
func carriageway_width() -> float:
	return (STREET_WIDTH - SIDEWALK_WIDTH * 2) * float(TILE_SIZE)

## How long a car takes to get from one junction to the next at a middling cruise. The unit the
## whole signal cycle is built out of; see `SIGNAL_PROGRESSION_BLOCKS`.
func signal_travel_seconds() -> float:
	return (BLOCK_SIZE + STREET_WIDTH) * float(TILE_SIZE) \
			/ ((CAR_SPEED.x + CAR_SPEED.y) * 0.5)

## One full cycle of a signalled junction, both arms and both ambers.
func signal_cycle_seconds() -> float:
	return 2.0 * SIGNAL_PROGRESSION_BLOCKS * signal_travel_seconds()

## What is left of the cycle for the main road, which is most of it — the spine carries five times
## an ordinary street's traffic, so an even split starves it and backs the queue through the
## junction behind.
func signal_main_green_seconds() -> float:
	return signal_cycle_seconds() - SIGNAL_SIDE_GREEN_SECONDS - SIGNAL_AMBER_SECONDS * 2.0

## The signalled half of the traffic contract. *(M41.)*
##
## A zebra on an ordinary street is kept by the drivers: traffic gives way to somebody standing
## at the kerb, and `CAR_ZEBRA_SIGHT` is what makes that visible before she steps off. On a main
## road nobody gives way, and the only thing standing between her and a hard fail is the length
## of the light — so the side street's green has to be long enough to cross the carriageway with
## the **same doubled margin** every other lethal thing in the game owes.
##
## Stated over the crossing she is making rather than over the light she is watching: it is the
## side street that is green while the main road is stopped.
func validate_signals() -> bool:
	var required := required_horn_time()
	if SIGNAL_SIDE_GREEN_SECONDS + 0.001 < required:
		push_error("Unfair signal: side green %.2fs < %.2fs needed to cross %.0fpx of carriageway"
				% [SIGNAL_SIDE_GREEN_SECONDS, required, carriageway_width()])
		return false
	return true

## The traffic fairness contract, and the one place it is stated.
##
## A car is not an event, so `validate_event()` never sees it: it has no telegraph, it is not
## in the catalogue, and it is lethal. What stands in for the telegraph is the road itself —
## the carriageway is painted, permanent and learnable, and stepping off the kerb is a choice
## the player makes. On top of that, a car that is actually going to hit somebody sounds its
## horn `CAR_HORN_TIME` out, and that warning must be long enough to walk the whole width of
## the carriageway with the doubled margin a hard fail is owed.
##
## Returns true if the geometry is fair; pushes an error and returns false if it is not.
func validate_traffic() -> bool:
	var required := required_horn_time()
	if CAR_HORN_TIME + 0.001 < required:
		push_error("Unfair traffic: CAR_HORN_TIME %.2fs < required %.2fs (carriageway %.0fpx)"
				% [CAR_HORN_TIME, required, carriageway_width()])
		return false
	return true

## Shortest horn a lethal car may fairly give. Kept separate from `validate_traffic()` so a
## test can check the contract without tripping the error it raises.
func required_horn_time() -> float:
	return carriageway_width() * TELEGRAPH_HARD_FAIL_MARGIN / WALK_SPEED

## Distance a car needs to stop from a given speed. Used by the crossing logic and asserted
## against `CAR_ZEBRA_SIGHT` in `tests/test_crowd.gd`.
func braking_distance(speed: float) -> float:
	return speed * speed / (2.0 * CAR_BRAKE)

## People on the streets in a given act.
func crowd_pedestrians(act: int) -> int:
	return CROWD_PEDESTRIANS_PER_ACT[clampi(act - 1, 0, CROWD_PEDESTRIANS_PER_ACT.size() - 1)]

## Cars on the roads in a given act.
func crowd_cars(act: int) -> int:
	return CROWD_CARS_PER_ACT[clampi(act - 1, 0, CROWD_CARS_PER_ACT.size() - 1)]

# -------------------------------------------------------------------- acts ---

## Day index (1-based, inclusive) at which each act begins.
const ACT_START_DAYS := [1, 4, 8, 12]

## The longest act, in days. What the calm-area floor is stated over.
func longest_act_days() -> int:
	var longest := 0
	for i in ACT_START_DAYS.size():
		var ends: int = ACT_START_DAYS[i + 1] if i + 1 < ACT_START_DAYS.size() \
				else RUN_LENGTH_DAYS + 1
		longest = maxi(longest, ends - ACT_START_DAYS[i])
	return longest

## How many calm areas a city has to have: one per day of the longest act, plus one in reserve.
## See `MIN_CALM_BLOCKS`, which this is asserted against on boot.
func calm_areas_needed() -> int:
	return longest_act_days() + 1

## Returns the 1-based act number for a given 1-based day.
func act_for_day(day: int) -> int:
	var act := 1
	for i in ACT_START_DAYS.size():
		if day >= ACT_START_DAYS[i]:
			act = i + 1
	return act

## Length of a given day in seconds, accounting for the curfew announcement.
func day_length(day: int) -> float:
	var length := DAY_LENGTH_SECONDS
	if day >= 6:
		length *= CURFEW_DAY_LENGTH_MULTIPLIER
	return length

# --------------------------------------------------------------- validation ---

## The fairness contract from docs/EVENTS.md: a player who starts walking away the instant
## an event becomes visible must clear its outer radius before it reaches full intensity.
##
## Returns true if the geometry is fair; pushes an error and returns false if it is not.
func validate_event(id: String, telegraph_time: float, inner_radius: float,
		outer_radius: float, hard_fail: bool, speed: float = 0.0) -> bool:
	var required := required_telegraph_time(inner_radius, outer_radius, hard_fail, speed)
	if telegraph_time + 0.001 < required:
		push_error("Unfair event '%s': telegraph_time %.2fs < required %.2fs "
				% [id, telegraph_time, required]
				+ "(inner %.0f, outer %.0f, hard_fail %s)"
				% [inner_radius, outer_radius, hard_fail])
		return false
	return true

## Shortest telegraph an event with this geometry may have and still be fair.
## Kept separate from validate_event() so tests can check the contract without tripping
## the error it raises.
##
## A stationary event only has to be walked out of, so the escape distance is the falloff
## band. An event travelling FASTER than the player sweeps its whole outer radius across
## the street instead — you cannot outwalk it, you can only get off its line — so the
## escape distance is the full radius. An event slower than walking pace (a dog walker)
## can simply be walked away from, so it uses the stationary rule.
func required_telegraph_time(inner_radius: float, outer_radius: float,
		hard_fail: bool, speed: float = 0.0) -> float:
	var margin := TELEGRAPH_HARD_FAIL_MARGIN if hard_fail else 1.0
	var escape := outer_radius if speed > WALK_SPEED else outer_radius - inner_radius
	return escape * margin / WALK_SPEED

## Excitement contribution of a source of `intensity` at distance `d`.
##
## **The shape has a shoulder on it.** *(Playtest 07, finding 18: "the radius of excitement for
## obstacles needs to be bigger — with most obstacles, dogs, robbers, etc, the excitement should
## go substantially up from relatively far away. I shouldn't have to get actual contact to get
## penalized.")*
##
## It was `(1−t)²`, which put a quarter of the intensity at the midpoint of the falloff band and
## six percent three quarters of the way out. A café at 12/s was therefore under the 3.5/s walking
## decay across the whole outer 60% of its own field, and the trace says so in as many words —
## every `near` entry written at an event's outer radius reads `events 0.0`. An event you are not
## charged for until you touch it is not a thing to route around, it is a thing to bump into, and
## that is playtest 07's headline finding arriving from the other side.
##
## `1 − t²` instead: full strength at the inner edge, three quarters of it at the midpoint, and
## zero only at the outer edge, where the contract says it must be. The whole catalogue got wider
## teeth without a single radius moving, which is the point of fixing it here — thirty rows of
## hand-widened radii would have been thirty chances to break the fairness contract.
##
## **The contract is untouched and this is why.** `required_telegraph_time` is stated over
## *distance* — how far she has to walk to be outside the radius — and neither radius moved. What
## changed is what she pays while she is inside one, which the contract has never had an opinion
## about. `tests/test_events.gd` re-checks the whole catalogue either way.
##
## See docs/MECHANICS.md.
func falloff(d: float, intensity: float, inner_radius: float, outer_radius: float) -> float:
	if d <= inner_radius:
		return intensity
	if d >= outer_radius:
		return 0.0
	var t := (d - inner_radius) / (outer_radius - inner_radius)
	return intensity * (1.0 - t * t)
