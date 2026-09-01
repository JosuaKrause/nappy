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

## The pitch these three make together is the whole loop: **an ordinary street makes real
## progress and never enough.** A whole day of clean street walking reaches about three quarters
## of the meter, so the walk out is worth something and the walk out alone can never finish.
## Only calm ground can, which is what stops a day being winnable by circling the doorstep and
## the city being decoration.
##
## `tests/test_meters.gd` holds both halves in terms of `day_length()` rather than in numbers,
## so a change to the length of a day cannot quietly make the street sufficient again.
const SLEEPINESS_GAIN_WALKING := 0.42
## Standing still has to be strictly worse than walking, or waiting is a strategy. It also
## has to stay cheaper than a calm zone gives, because stopping is the counterplay to a loud
## event and pricing it above the park's own rate would take that move away.
const SLEEPINESS_DRAIN_IDLE := 1.0
## How much faster calm ground fills the meter than an ordinary street. A four-block zone is
## **11.3s from empty**, against a whole day of clean pavement reaching three quarters of the bar.
##
## Deliberately generous once the park is reached, because **the day is meant to be lost on the
## way there and not in it.** That makes this the constant that decides whether a day is winnable
## at all once she arrives, and it is why it moves whenever the walk out gets harder: leaving the
## reward the same length while adding to the journey turns a park from a reward into a wait, and
## a calm stretch that reads as a wait is the failure this number exists to prevent.
##
## It also has to be visibly faster than the pavement, not merely faster. A small multiple of a
## rate nobody can see does not read as a reward at all.
const SLEEPINESS_CALM_ZONE_MULTIPLIER := 21.0

## How much faster again a **small** calm area fills it, as a curve over the lot's size.
##
## The rate goes as `1 / sqrt(blocks)`, normalised so a `CALM_ZONE_BLOCKS`-square zone is the base:
## **21x for four blocks (11.3s from empty), 29.7x for two (8.0s), 42x for one (5.7s)**.
##
## **It divides by the side and not by the area, because a lap is a length.** A four-block zone is
## 22 tiles square and has a route through it; a single block is eight tiles across and has a lap
## round it. Paying inversely to the *width* of a lot pays each of them about the same for a lap, so
## a small area stops being the weaker destination for a reason that has nothing to do with what it
## is for, and *which* calm area to head for stays a real question — which is `docs/CITY.md`'s own
## argument for keeping single-block calm in the mix.
##
## The trap, since the two formulas look equally reasonable: dividing by the **block count** makes a
## single block *four* times a four-block zone rather than twice it, because a factor of two in
## width is a factor of four in area.
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

## The two the *pram* says out loud, stated as **states with an instruction attached** rather than
## as points on a gauge — which is the whole difference between a cue and the HUD moved over the
## player's head. The other two states the pram shows need no constant at all, because the game
## already has them: the calm threshold, where the day stops progressing, and asleep.
##
## Nearly crying is the last band before `METER_MAX` ends the day. Far enough up that it is not
## a second name for "loud street" — a pavement sits under the calm threshold and a bad moment
## reaches the fifties — and far enough from 100 to be worth acting on: at the walking decay it
## is about six seconds of quiet ground back to safety.
const EXCITEMENT_NEARLY_CRYING := 80.0
## And how far below the wake threshold a sleeping baby starts to stir. Waking costs
## `WAKE_SLEEPINESS_PENALTY` — half the bar — so this is the most expensive thing in the return
## phase, and without a cue at the pram the only warning is a bar climbing in a corner.
const EXCITEMENT_STIR_MARGIN := 12.0
## Incoming excitement multiplier while the baby is asleep.
const SLEEPING_SENSITIVITY := 0.55

## **What settles a baby is being pushed.** The pram is a rocking chair with wheels on, and
## rocking it is the only thing that calms her.
##
## **Zero and not merely low**, because standing still must *freeze* the excitement rather than
## clear it: the day then stops moving in both directions at once, which is the honest version of
## "waiting is not a plan". Any positive idle decay makes standing the strongest move in the game
## — a full meter cleared for a few points of sleepiness, anywhere, including the middle of a
## street she has no business being on.
##
## The counterplay this removes has a better replacement: **walk somewhere quiet**, which is what
## `EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER` is for and what the whole route is about.
##
## Running still decays, barely — it is motion, and `EXCITEMENT_FROM_RUNNING` is what makes it a
## bad idea. The ordering is motion-shaped rather than arbitrary: walking calms most, running calms
## a little, standing calms nothing.
const EXCITEMENT_DECAY_IDLE := 0.0
const EXCITEMENT_DECAY_WALKING := 3.5
const EXCITEMENT_DECAY_RUNNING := 0.5
## What the **ground** does to the decay, best to worst: calm, then precinct, then ordinary
## street, then main road.
##
## This is what makes a route a **recovery rate** rather than only a set of things to walk past,
## and what makes a precinct worth walking to although it is loud: a retail street is busy, and it
## is still the best place in the city that is not a park to bring a meter down.
##
## The park has to read on *both* bars, not just the sleepiness one — half of "this is working" is
## the excitement visibly falling away as she walks in under the trees. The main road is the same
## sentence inverted: it is the one ground in the city that is actively bad at letting her recover,
## which is most of what "a main road is crossed, not walked" now means arithmetically.
const EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER := 2.2
const EXCITEMENT_DECAY_PRECINCT_MULTIPLIER := 1.5
const EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER := 0.6

## Layered on top of the ground's own multiplier for the rest of a day once the resistance's
## package is picked up (`GameState.resistance_carrying_package`) — the one cost in the subquest
## that is deferred and total rather than local, so it changes the afternoon's routing rather than
## one minute of it. Chosen on the same severity as a main road's own 0.6, on the harsher side of
## it: this is a decision she made, not ground she has to cross.
const RESISTANCE_PACKAGE_DECAY_MULTIPLIER := 0.5

## Excitement per second at full sprint, scaled by how far above walk speed we are.
##
## **The run button is a trap by design**: running is the wrong move against every row that merely
## emits, and the right move only against the things that follow you. This constant is what keeps
## that ordering true across the whole catalogue.
##
## It is sensitive to the shape of `falloff` and not only to the radii. A fatter field makes
## time-in-field matter more, so a shoulder that is too generous makes running *out* of the widest
## rows cheaper than walking — which is not "running works" but "running is a coin flip", the worst
## of the two. `tests/test_events.gd` asserts the ordering row by row rather than leaving it in a
## document, because that is how it can break silently.
const EXCITEMENT_FROM_RUNNING := 14.0
## Constant dread while standing in an alley.
const EXCITEMENT_FROM_ALLEY := 3.0

# ----------------------------------------------------------------- the mark ---

## What a row has to cost, in points of the meter, before it earns a caret over its head.
##
## The rule is about **cost**, not about whether a danger changes over time — asking the latter
## marks a burning building and not the fire engine that made it. See `EventInstance.wants_a_mark()`.
##
## **A quarter of the meter**, and it is a taste call stated rather than derived: one of these is a
## quarter of the bar and a route has three or four on it. What makes it a *safe* taste call is
## where it falls — the catalogue has a 7.5-point gap between `market_stall` (+27.8) and
## `construction` (+20.3), so the line sits in open ground rather than slicing a cluster, and a
## small rebalance cannot flip a row across it by accident.
##
## The number decides *how many* rows are marked rather than which: the ordering is the invariant,
## and `tests/test_danger.gd` holds it — if A is marked and B is not, A costs more than B, over the
## whole catalogue.
const MARK_WORTH_A_DETOUR := METER_MAX * 0.25

# ---------------------------------------------------------------- telegraph ---

## Fraction of full intensity an event emits while still telegraphing.
const TELEGRAPH_INTENSITY_FRACTION := 0.15
const TELEGRAPH_TIME_DEFAULT := 2.5
## Hard-fail events must give twice the escape margin of an ordinary event.
const TELEGRAPH_HARD_FAIL_MARGIN := 2.0

# ---------------------------------------------------------------------- run ---

const RUN_LENGTH_DAYS := 14
## How many days a run may lose before it is over.
##
## **A nerve is an attempt, not a day thrown away.** A lost day is retried and the calendar does
## not advance, so a nerve costs only the time it took to lose — which is why the number can be
## this generous. It is the budget for *learning* a day, and a run that ends before act II ends
## before the game has shown what it is.
##
## Asked for rather than derived, and still unmeasured: the run log's `nerve` entries say where
## they went. See `docs/TODO.md`'s open question.
const STARTING_NERVES := 5
## A day is aimed at **about a minute of play, with a grace of three**. Dusk is the grace,
## not the target: a day walked well is over in a minute, and the three minutes are there for
## a day that goes wrong — a bad route, a park that turned out to be spoiled, a baby woken on
## the way home.
##
## **Dusk must not become the typical length.** A day long enough that the clock is what stands
## between the player and the end of it is a game about waiting rather than about routing.
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
## **Eleven is room rather than a rule.** Nine is the smallest lattice on which the home can be
## central; eleven is what a city with one spine, two precincts and a ring of frontages needs in
## order to have a middle you can get lost in the middle of.
##
## The size is what lets the two rules about the home both hold. It has to be central, and it has to
## be `MIN_HOME_TO_PARK_TILES` of walking from calm ground — and those pull against each other, so
## the lattice has to be wide enough that the centre is still a long walk from the edge of anything.
## On a lattice too small for both, the home gets walked outward until it is far enough, landing
## against the boundary, where most directions are a wall.
##
## Everything downstream of this is stated over it — the event budget per block, the crowd
## population per corridor, the arterial index — so a change here is a change to the whole density
## table. **Re-measure rather than convert.**
const CITY_BLOCKS := Vector2i(11, 11)

# -------------------------------------------------------- the street hierarchy ---
# Three kinds of street: a main road, two retail precincts, and ordinary streets everywhere else.
# With one kind, the only route question a junction asks is *which way*; with three it also asks
# *which kind*, and that is the trade this game is made of.
#
# The lattice itself does not move. Every corridor is still `sidewalk | road | sidewalk` and the
# layout maths is still a modulo — see the note on `STREET_WIDTH`.

## How long a precinct is, in blocks. **Three, with an end you can see, because a precinct has to
## be a place rather than a kind of street.** A whole corridor of it is not a precinct — a kind of
## street you meet every third block is simply what a street is.
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
## **The wave serves one direction, not two, and no setting of this constant changes that.** With
## offsets `j·travel`, a car passing junctions `j0 + d·h` at `t0 + h·travel` sees phase
## `t0 + j0·travel + h·travel·(1 + d)`. Going **with** the wave (`d = -1`) the `h` term vanishes and
## the phase never moves — a perfect progression. Going **against** it the phase advances `2·travel`
## per junction, which is constant only if the cycle *divides* `2·travel`, and that is true only at
## `blocks = 1`.
##
## Measured on the wave alone, twenty departures spread across a cycle, no traffic in it:
## **93% of arrivals green with the wave, 51% against it** — and 51% is chance, because the main
## green is 47% of the cycle.
##
## **A two-way wave is not available at any price here.** It needs `cycle = 2·travel` = 5.7s, and
## the side green plus its two ambers is 9.0s before the main road gets a second. Widening `travel`
## instead means a spine cruise under 100px/s, barely above a walk. Nor does another offset scheme
## do better on average: `θ = travel` buys one direction a perfect run and leaves the other at
## chance (72% overall), while `θ = cycle/2` puts *both* directions on a three-phase sweep at 47%
## each. **The asymmetric answer is the best one, not a compromise.**
##
## Three is what makes the cycle come out near a quarter of a minute: shorter and the side street's
## share stops being long enough to cross on, longer and a red is a wait a player will not spend.
const SIGNAL_PROGRESSION_BLOCKS := 3

## Calm **areas**, not calm blocks: an area may be a single block or a multi-block zone, and what
## these count is places to go rather than lots. The name is what `calm_blocks` returns — one entry
## per area — and renaming it would touch every guarantee stated over it without changing what any
## of them mean.
##
## **The floor is an act's worth plus one.** A day spoils every calm area she has used so far this
## act, so an act of four days burns four, and the plus one is what stops the last day of an act
## being unwinnable rather than merely hard. It is derived from the act lengths below rather than
## authored beside them, because the two would otherwise drift the first time either moved:
## `calm_areas_needed()`.
const MIN_CALM_BLOCKS := 5
const MAX_CALM_BLOCKS := 7
## Walking distance in tiles, not straight-line: the calm has to be earned.
const MIN_HOME_TO_PARK_TILES := 30

# ---------------------------------------------------- multi-block calm zones ---
# A calm area has to be big enough to have a *route* through it. Progress requires motion —
# standing still *drains* sleepiness — and a calm block is eight tiles across, which is jointly
# sufficient for a **lap**: the player circles inside it until the meter fills. That is not a
# balance problem and no balance pass removes it.
#
# A square zone is 2x2 blocks with the streets between them absorbed, so it is
# `2 * BLOCK_SIZE + STREET_WIDTH` = 22 tiles square — 704px, against a block's 256 — and a stretch
# of calm becomes a traverse of somewhere with sides to it. See docs/CITY.md, "Calm zones".

## Blocks per side of the **square** calm zone, which is the size every rate here is pitched
## against. Two. It is a constant rather than a literal because a great deal of arithmetic follows
## from it — the normalisation of the sleepiness curve above, and every test that states a
## relationship in terms of a full-sized zone — and a 2 buried in five different files is how the
## next person changing this discovers the sixth.
const CALM_ZONE_BLOCKS := 2

## The footprints a multi-block calm area may have.
##
## **A zone is a shape rather than a square**, and that is what the arithmetic has to respect:
## anything downstream of `CALM_ZONE_BLOCKS` written as that integer squared is the square's answer
## wearing a general one's clothes. What a footprint costs the lattice is stated over the rect — a
## `w x h` zone absorbs `w*(h-1) + h*(w-1)` streets, which is four for the square and **one** for a
## rectangle — so a 2x1 is a lot of two blocks with the single street between them painted over.
##
## Both orientations are here on purpose. A city whose rectangles all run the same way is a rule
## somebody learns once rather than a place, and the two are genuinely different to walk: a 22x8
## strip is a length with two ends, and which end you come in at is a route decision.
##
## The rate curve covers them without a case: `sleepiness_calm_multiplier` is `1 / sqrt` of the
## block count, so two blocks fill in 8.0s against the square's 11.3s and a 2x1 pays for about one
## traverse of its long side, exactly as a square pays for one diagonal.
const CALM_ZONE_SHAPES: Array[Vector2i] = [
	Vector2i(CALM_ZONE_BLOCKS, CALM_ZONE_BLOCKS),
	Vector2i(CALM_ZONE_BLOCKS, 1),
	Vector2i(1, CALM_ZONE_BLOCKS),
]

## How many of a city's calm areas are multi-block. At least one, because a city of nothing but
## single blocks is a city of laps; and the first one placed is always the **square**, so *"every
## city has a big park"* stays true word for word while the rest may be rectangles. The remainder of
## the calm stays single-block, which is what keeps *which* calm area to head for a real question —
## a small quiet square close by against a big park further out is the decision spoiling exists to
## make matter.
const MIN_CALM_ZONES := 1
const MAX_CALM_ZONES := 2

# ------------------------------------------------------------- hard blockers ---
# A hard blocker is a pruned edge the layout cannot traverse, permanent for the run: cul-de-sacs and
# big buildings. Soft blockers re-cut the map every morning; these hold still and are therefore the
# part of the city a player can **learn**. See docs/CITY.md, "Diversions — the design".

## How many streets in a city genuinely stop. A handful of a few hundred: enough that a run has a
## shape somebody could describe, few enough that the lattice is still a lattice — the number is
## what separates "this city has dead ends in it" from "this city is a maze", and a maze is the
## thing the reachability gate exists to prevent.
##
## Measured rather than derived, like every other count in this file.
const MIN_CUL_DE_SACS := 4
const MAX_CUL_DE_SACS := 8

## How deep the wall across a dead end is, in tiles. Two rather than one: a one-tile slab is a
## line rather than a building, and what has to read from the far end of the street is *this does
## not go through* rather than *something is painted here*.
const CUL_DE_SAC_WALL_TILES := 2

## Big buildings: two neighbouring blocks plus the one street between them, built as a single mass
## twenty-two tiles long. Every other street around the pair stays — it takes one road out of the
## lattice, not the ring. One or two per city, because this is a **landmark** — a thing a player
## says "past the big grey one" about — and a city with five of them has landmarks the way a forest
## has notable trees.
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
# A city that becomes a different city while you walk around in it. Every block is generated with an
# arc — the ordered purposes it may pass through — so the transitions are always coherent and the
# whole run can be checked at generation instead of rescued day by day. See docs/CITY.md, "Block
# purposes".

## Courtyards are cut into residential blocks rather than taking a block of their own.
const COURTYARD_CHANCE := 0.35
const MAX_COURTYARD_BLOCKS := 3
const COURTYARD_SIZE_TILES := 4

## The **apartment complex**: a courtyard lot four blocks across, with the streets between them
## built over and frontages all the way round.
##
## **It is a calm zone's mechanism with the opposite ground.** A zone absorbs the streets between
## four blocks and paints park over them; this absorbs them and builds over them, so what comes out
## is a mass 22 tiles square with a court in the middle and one archway in. That is what makes it calm
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
# The road network is pruned per day, so the route is a real decision — avoidable, but clearly "not
# that way". See docs/CITY.md, "Road closures".

## Streets closed per day, by act. Deliberately light, because closures are **not** the main source
## of route pressure: that is at the scale of a *block* — which side of the road to walk down, forty
## times a day — and a closure count tuned as though it were the only pressure would be far too
## heavy underneath it. Four closed streets of a few hundred is a city that has had a bad morning,
## not a city under siege.
const CLOSURES_PER_ACT: Array[int] = [1, 2, 3, 4]

## How much likelier a closure is to land on a turning off the day's corridor than on a street
## somewhere else entirely. **A closure never lands on the corridor at all** — that is a rule in
## `ClosurePlanner._shuffled_candidates` rather than a weight, because a wall across the route is
## not a worse wall, it is the opposite of one.
##
## **The same number pointing the other way is a different design**, and it is the easy mistake:
## aiming closures **at** the streets the player would have used treats a closure as an obstacle,
## and an obstacle nobody meets is scenery. A wall's job is to prune the ways that lead nowhere she
## should go. What survives from the obstacle reading is the reason for the rim: a wall nobody can
## see from the route prunes nothing, so the far corner of the map is what this weight exists to
## avoid.
const CLOSURE_WALL_BIAS := 5.0

## The day-level invariant, and the whole reason the planner is allowed to close anything:
## **at least this many calm areas are still reachable.** Two areas, because a choice of
## destination is what makes a choice of route mean anything — and because one of them may be the
## one she used yesterday, which the day has deliberately spoiled.
##
## **It does not demand two *distinct routes* to each of them.** Edge-disjointness is a **stand-in**
## for winnability, by Menger: two routes means no single street is a cut. That protection comes
## instead from where a wall is *placed* — off the day's tree, so it cannot cut the tree — and the
## second route is a niceness the day offers when the map allows one, measured by `RouteTree` (241
## areas of 241 that the map allowed one to) and gating nothing. Sealing off a section of the map is
## allowed, and it is the point.
##
## What is deliberately **not** weakened is the count. Dropping to one reachable area lets a day
## arrive where the only calm left is the one it spoiled this morning, which is the unwinnable day
## this constant exists to prevent.
const MIN_CALM_AREAS_REACHABLE := 2

## How deep the barrier across a closed street's mouth is, in pixels. Thin enough to read as
## a line drawn across the road, thick enough that nothing walks through it in one frame.
const CLOSURE_BARRIER_DEPTH := 24.0

## Streets closed on a given day.
func closures_for_day(day: int) -> int:
	return CLOSURES_PER_ACT[clampi(act_for_day(day) - 1, 0, CLOSURES_PER_ACT.size() - 1)]

# --------------------------------------------------------------- the crowd ---
# The crowd is why a street is loud and a park is quiet, and it is the base noise floor a day needs
# so that standing in one place cannot work. It is emergent rather than a city-wide constant,
# because a number nobody can see means nothing.

## People, then cars, on the streets in each act. The city empties as the acts turn, and
## this is the cruellest number in the game: from act III the streets are *quieter*, because
## there is nobody left going out on them. The city becomes an easier place to put a baby to
## sleep, and that is the horror. Act IV puts a little back, but it is not the same traffic.
##
## The emptiness has to be **the empty pavement**, not an ambient band on the arterials: a city that
## empties out invisibly is a difficulty change the player feels and cannot see.
##
## **These are populations of the *field*, not of the city.** The crowd lives in a
## `CROWD_FIELD_RADIUS` box that travels with the player, so the number here is what is on the
## streets *around her* rather than what is scattered over ten thousand tiles. A whole-city figure
## reads about a third as dense as it looks — a hundred cars over sixteen corridors is one every six
## seconds in your lane, which is a road you can ignore. **Measure these, never convert them by
## area**: `tests/test_crowd.gd`, "the road has to be waited for".
##
## **A junction is a place a car can be stopped, which is what gives the road a capacity.** Without
## it two cars on crossing arms drive through each other, the network's throughput is unbounded, and
## a car count means whatever it happens to look like. With the box rationed, a car waiting at a
## light beside you is louder for longer than one going past, so the same population puts the
## arterial floor over the ceiling `tests/test_crowd.gd` states — *"expensive to cross, not
## impossible"*.
##
## **The honest answer to "the main road is too quiet" has twice been something other than more
## cars.** The spine's share is decided by `CrowdLanes.busyness` and by the axis roll, not by the
## population: with the arterial weight spent on one axis rather than split across a phantom
## east-west one, the spine holds more of the same total and adding cars only puts junction
## contention over the rate the suite allows.
const CROWD_PEDESTRIANS_PER_ACT: Array[int] = [200, 150, 42, 70]
const CROWD_CARS_PER_ACT: Array[int] = [34, 26, 8, 16]

## Half-extent of the box the crowd lives in, in px. Everything inside it is simulated;
## anything that leaves it is recycled to the far edge and walks back in.
##
## The floor is the screen: an agent recycled at 800px from the camera is always off-screen when it
## appears, whichever way the player is facing. The ceiling is honesty — a box much larger than this
## spends frames on pavement nobody can see, which is the whole reason the crowd is a field.
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
## **The radius is tight because `falloff` has a shoulder on it.** Every source holds three quarters
## of its intensity at the midpoint of its band, which is right for an **event** — a thing on the map
## to route around — and wrong for a **body**, which is one of a couple of hundred and is supposed to
## be inaudible from across the pavement. At an event's kind of radius the same shoulder puts the
## arterial floor around 18/s against a walking decay of 3.5, which is a main road that fills the
## meter in six seconds.
##
## So the crowd pays the shape back in radius, and what that defends is the measured character of
## the street: **careless is expensive and careful is free.** A close pass costs 4.2/s, set by the
## intensity and the inner radius; two tiles away is 0/s. What the tight outer radius removes is a
## wide middle that would be worth a great deal for walking anywhere near anybody.
##
## **"Two tiles away" is true of one walker and is only reachable if the lanes are spread.** A
## footway is two tiles, so lanes on their tile centres are 32px apart — and the midline, the only
## line with no head-on contact on it, is then 16px from two lane centres and inside the
## **full-intensity core** of both. Measured that way the ambient floor is flat across a pavement
## (4.30 frontage / 4.96 midline / 4.76 kerb), the careful line for contacts is the careless one for
## noise, and *how close to pass* is not a choice at all.
##
## `CrowdLanes.SIDEWALK_LANE_SPREAD` is what makes it one: at 48px apart the midline is **24px from
## each lane and outside `PEDESTRIAN_INNER_RADIUS`**, worth 56 points per forty seconds against 74
## unspread. **That is the one change to make if this stops being true** — the intensity and the
## radii are pinned by the arterial floor and the shoulder, and the geometry is not.
const PEDESTRIAN_INTENSITY := 4.2
const PEDESTRIAN_INNER_RADIUS := 22.0
const PEDESTRIAN_OUTER_RADIUS := 55.0

## A car is louder than a person and passes much faster. No single car outruns the walking
## decay — the point is not that one car is dangerous, it is that on a main road there is
## always another one. The floor is the *street*, and it is emergent; the first pass at these
## numbers put the arterial at +15/s, which filled the meter in seven seconds and made the
## main road not expensive but impassable.
##
## The radius is tight for the same reason the pedestrian's is, and pinned the same way: the
## arterial has to stay between the walking decay and three times it, which is `tests/test_crowd.gd`
## and is the one place the noise floor is pinned to anything.
##
## **And 104 is still wider than the street it is on.** A corridor is six tiles — 192px — and a
## car's field is 208px across, so every tile of both footways is inside it, and the frontage lane,
## the furthest place from a carriageway there is, sits 64px from the nearer lane centre. Nowhere on
## an ordinary street is out of the traffic's earshot, which is most of why the noise floor measures
## flat across a pavement.
const CAR_INTENSITY := 5.4
const CAR_INNER_RADIUS := 38.0
const CAR_OUTER_RADIUS := 104.0

## Chance a walker turns a corner rather than carrying straight on, rolled once per
## junction. High enough that the crowd churns, low enough that streets still have flow.
const PEDESTRIAN_TURN_CHANCE := 0.35

# ------------------------------------------------------- bodies on the street ---
# A crowd you can walk through is a field with a picture attached: every pavement is identical, none
# of them can hurt you, and the route is not a decision. See docs/MECHANICS.md, "The street has
# physics".

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
## It has to be **under half a lane spacing**, and that is the whole of why it is 14 rather than a
## body's width. The only line with no contact on it is the midline between two lanes; at 18 there
## is no such line anywhere on a two-tile pavement, and walking the arterial costs eleven bumps in
## forty seconds however carefully it is done. At 14, holding that line takes the same walk down to
## two, which is the difference between a toll and a decision.
##
## **How *wide* that clear line is matters as much as whether it exists**, and it is the half that
## is easy to leave unchecked. With lanes a tile apart it is `32 - 2 × 14` — four pixels, something
## a player is occasionally on rather than something she can aim at, worth 15.3 contacts down an
## arterial lane centre against the midline's none. The fix belongs in
## `CrowdLanes.SIDEWALK_LANE_SPREAD`, which moves the lanes apart, and deliberately **not** here:
## this number is what makes a contact mean *walking into somebody*, and buying the line by
## shrinking it would make one require a near-perfect overlap.
const BUMP_RADIUS := 14.0

## How far apart a contact is pushed, and how far apart it has to get before it counts as over.
##
## **The two numbers that make a bump end**, and they have to be two.
##
## Resolving the separation to exactly `BUMP_RADIUS` — the distance at which `touching` flips back
## to false — parks a resolved contact precisely on its own release threshold, where it flickers
## across it and fires a fresh `BUMP_INTENSITY` jolt every couple of frames for as long as the pair
## are near each other. A contact that costs its jolt once is a decision; one that costs it ten
## times in two seconds is being stuck to somebody, and three of those in half a minute is a lost
## day.
##
## So it is a hysteresis band: pushed apart to `BUMP_CLEAR_RADIUS`, and `touching` is only released
## past it. A bump therefore ends the frame it is resolved, and it can never re-fire without a
## genuine second approach.
##
## Deliberately a small band. Widening it would widen the corridor she has to thread down a
## pavement, and the note on `BUMP_RADIUS` is what happens when that number grows.
const BUMP_CLEAR_RADIUS := 19.0

## How much of the separation the player takes; the pedestrian takes the rest. She is pushing
## a pram and they are not, and being shoved by strangers must never take the verb away.
const BUMP_PLAYER_SHARE := 0.3

## How far across their own pavement somebody she walked into steps, and for how long.
##
## **The half the hysteresis alone cannot fix.** A walker steers to its lane centre at
## `CrowdAgent.STEER_SPEED`; if she is standing on that centre, the walker resolves out of the
## contact and then immediately steers back into her, forever. The separation being positional is
## what stops them being *inside* each other and cannot stop them being *against* each other.
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
## **This is what keeps pedestrians from being the thing that kills every run.**
##
## The design is that the crowd is *expensive to be careless in and free to be careful in*, and the
## **ratio** between those is what makes a pavement a decision — eleven contacts in forty seconds
## down a lane centre against one holding the midline. Without a yield the ratio collapses to
## thirteen against fifteen on the arterial and eleven against nine on a back street: no careful
## line, so the crowd is a toll rather than a decision, and at ~30 points a contact it is a toll
## that ends the day.
##
## **A careful line cannot be defended by geometry alone**, because anything that gives walkers
## reason to be off their exact centre — junctions, recycling, the sidestep above — eats it. So the
## careful line is a **behaviour**: somebody who sees a pram coming moves over. It prices the right
## thing, a contact being what carelessness costs rather than what walking costs, and it stays
## honest three ways: they only move a lane, they cannot move into the carriageway
## (`CrowdAgent._pavement_band`), and at `RUN_SPEED` she covers the notice distance in 0.57s against
## the 0.36s they need to clear a lane, so **running still hits people**.
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

## A contact is not a write to `Baby.excitement` — it agitates the *person* she walked into, and
## the crowd sums them like any other body. Excitement stays a pure query; a bump startles the
## agent, never the meter — the invariant the **events** skill and `docs/MECHANICS.md` hold.
##
## **A contact is about eleven points of a hundred-point meter**, so four or five of them lose a day
## on the crowd alone. It is the single most expensive instant on a pavement and it must not be the
## only thing in the game with an opinion: at sixteen points the crowd supplies nearly all of the
## excitement in a lost day and the authored content is decoration.
##
## Read it with `CROWD_YIELD_DISTANCE`: people get out of her way, so a contact is what
## carelessness costs, and it costs less when it happens because it is not the whole game.
const BUMP_INTENSITY := 18.0
const BUMP_DURATION := 1.2
const BUMP_INNER_RADIUS := 30.0
## Tight, for the reason every crowd radius is tight: the jolt is a body's own source, so it takes
## the same shoulder from `falloff` as everything else, and a wide one charges a bump she is walking
## away from for most of its tail. The cost at the moment of contact is set by the intensity.
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
## Tight for the same reason as the rest of the crowd's radii, and still a good deal wider than the
## car itself: a horn is meant to be heard from further away than an engine.
const CAR_HORN_OUTER_RADIUS := 132.0
## How long the exclamation mark stays up over the player after the last horn. Long enough to
## survive the gap between two cars in the same lane.
const CAR_WARNING_HOLD := 1.4

## How near the end of the day, in seconds, the doubled mark means *now*.
##
## The mark over her head is the one cue in the game that gives an **instruction**, and its second
## level says *it is bad now and you are in it: one step left*. That is a claim about a moment, so it
## needs a clock rather than a radius: raised anywhere inside a lethal event's **outer** radius it
## covers more than thirty times the area that can end the day for a cyclist, and stays up while the
## bike rides away.
##
## Read it as the step: at `WALK_SPEED` it is 64px, which is two tiles, which is the width of the
## pavement she would have to leave. Long enough to be an instruction she can still obey and short
## enough that it is never up while the answer is "carry on walking".
const LETHAL_MARK_LEAD := 0.7

## Traffic that queues instead of driving through itself. A car keeps `CAR_HEADWAY_TIME` seconds of
## clear road in front of it and never closes to less than `CAR_GAP_MIN`, which is a car's own
## length plus a nose.
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
## **Giving way is aimed at a place, and this is the place.** Braking toward *zero speed* from
## wherever a car happens to notice leaves it wherever the curve runs out — and `CAR_ZEBRA_SIGHT`
## is nearly four times the distance it needs, so that is usually most of a block short — while
## saying nothing about not stopping on the paint. A car half a block back and a car parked on the
## crosswalk are the same missing thing.
##
## Why it matters more than it sounds: the painted carriageway is one of the two things standing
## in for a telegraph in the traffic fairness contract. A car halted on the zebra is scenery by
## `CAR_STRIKE_MIN_SPEED` and cannot hurt anybody — but it is *unreadable* scenery sitting on the
## one place the game has told the player is the safe way across.
const CAR_STOP_LINE_SETBACK := 34.0
## The deceleration a car *aims* at when it eases up to a stop line, as opposed to `CAR_BRAKE`,
## which is the hardest it can push. Giving way has to be **visible from the kerb**, which is why
## the looking starts at `CAR_ZEBRA_SIGHT` rather than at the line, and why the approach is shaped
## by a gentle rate with only the emergency using the hard one.
##
## The relationship, and the one `tests/test_crowd.gd` states:
## `sqrt(2 · CAR_ZEBRA_APPROACH_BRAKE · CAR_ZEBRA_SIGHT) >= CAR_SPEED.y` — the fastest car in the
## city begins easing at the moment the zebra comes into sight, rather than holding speed and
## then grabbing the brake at the last legal instant.
##
## **Getting this wrong in the obvious way makes no car ever stop**: shaping the approach with
## `CAR_BRAKE` itself puts the onset of braking and the commit point at the *same* moment, so a car
## glides up to the line at full speed, decides it can no longer stop, and drives through. The test
## that catches it is the one that says *where* a car stops rather than whether.
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

# ------------------------------------------------------- the world near you ---
# The world is populated around the player rather than authored across a map she mostly never
# visits: nothing is loaded upfront, and a thing whose whole content is a moment is sited in front
# of her while she walks. See docs/MECHANICS.md, "The world near you".

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

## Far enough from the player that nothing there can be seen, which is what *nothing vanishes while
## you are looking at it* is measured against.
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
## The camera sits on her at zoom 2 over a 1280x720 viewport, so the visible world is
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

# ------------------------------------------------------ one event per block ---
# The density target is one event per block, so the decision a player makes about an obstacle
# happens several times a day rather than once. The density itself lives in
# `EventScheduler.budget_for()` and the catalogue's `max_per_day`, both **measured** rather than
# derived.
#
# What lives here is what the density needs in order to be legible. Placement is a uniform random
# tile, so a low per-type cap is the only thing keeping two of the same event off one pavement —
# which is a coincidence, not a rule. At this density it has to be a rule.

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

# --------------------------------------------------------- placement by role ---
# docs/CITY.md, "The words for it" and "Diversions — the design". A day is planned against a
# **corridor** — the ways from the doorstep to the calm areas still worth reaching — and what each
# of these numbers does is pull one kind of thing toward one part of it.
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
## **It applies to the *costly* half of the wall band only.** A very costly row is what the rim is
## for — she has strayed one turning and it is expensive — and a lethal row wants the ground beyond
## it. See `EventScheduler._copies_of` and `WALL_DEEP_WEIGHT`.
const EVENT_WALL_RIM_WEIGHT := 4

## How many times over ground two or more turnings off the corridor is offered to a **lethal** wall,
## against the rim.
##
## The ground off the paths *"ranges from very costly to deadly"*, and the range is over distance
## from the routes — so its two ends pull in opposite directions and this is the far one.
## Deliberately the same strength as the rim weight it mirrors: the design is a gradient
## rather than a preference for one band, and giving deadly a stronger pull than very costly would
## make the rim the quiet part of the off-corridor city, which inverts the sentence.
const WALL_DEEP_WEIGHT := 4

## How many times over the street **between two adjacent strands of the day's corridor** is offered
## to a wall, against the rest of the band it is in.
##
## Two strands running down neighbouring streets with a free step between them are one wide region
## rather than two routes. `RouteTree.gaps()` is what a gap is; the placement is
## `EventScheduler._copies_of`, where this multiplies the band weight rather than replacing it.
##
## **Set to leave about half of them open, which is the instruction rather than a compromise.** What
## is asked for is *variety in what a gap is worth*, so a number that closed every gap would be as
## wrong as one that closed none: it would turn the corridor into a set of separate corridors, which
## is the star shape `RouteTree` deliberately does not grow.
##
## It is also the reason this is a weight and not the per-gap roll that reads more directly. A roll
## needs a phase, a stream, a budget of its own and a share of the caps; a weight rides on the day's
## existing budget, spacing and per-row caps unchanged, and *cannot place more than the day can
## afford*.
const EVENT_WALL_GAP_WEIGHT := 6

## How much likelier a closure is to land in a gap between two adjacent strands than on the rest of
## the rim it is already biased toward.
##
## The other half of *"wall or event"*, and it is the **impassable** half: an event in a gap makes
## switching strands expensive and a closure makes it impossible, which is why having both is
## variety rather than two names for the same thing. There is at most one closure a day in act I and
## four in act IV, so this can be strong without closing many gaps — the quota is the limit.
const CLOSURE_GAP_BIAS := 4.0

## Where the line between *friction* and a *very costly* wall falls, in points of the meter it costs
## to walk through the middle of a row.
##
## Below it a row is friction and is weighted **onto** the routes; at or above it the row is what
## closes the ground **off** them. Stated over `EventDef.walk_through_cost()` — the same integral
## the caret is ordered by — rather than over a field somebody sets per row, because a second answer
## to *how expensive is this* is how two tables of the same fact drift apart.
##
## **Setting it to `MARK_WORTH_A_DETOUR` is the mistake with the good argument.** That constant is
## where the game raises a caret — *this is worth going round* — so sharing it would make the cue
## and the placement say one sentence. What it does instead is empty the routes: at 25 points **two
## thirds of every day becomes a wall**, and day 1's corridor drops from 69.6 placements to 27.8 of
## 113. The ground off the paths is what was asked to be closed; nobody asked for the paths to be
## cleared.
##
## The line is set by one row instead, and by the right one. **`dog_walker` costs 36.5 and has to
## stay friction**: the dog-walker decision arriving twice on day one is the route decision this
## game is made of, and a dog walker that is never on her route is that decision deleted. So the
## line goes above it, and the first row above it is `loose_dog` at 43.3 — which is where *very
## costly* starts reading as a different thing from *costly*. Forty points is four tenths of the
## meter to walk through the middle of.
##
## What that leaves on the corridor is `cafe_tables`, `market_stall`, `homeless_yeller`,
## `delivery_van` and the dog walker — the ordinary expensive city — and what it puts off it is
## `loose_dog`, `leaf_blower`, `burning_building`, `protest`, `military_convoy`, `night_raid` and
## every lethal row. Re-measure with a probe if the cost table moves; do not re-derive it.
const WALL_WORTH_OF_COST := METER_MAX * 0.4

# ----------------------------------------------------- solid things are solid ---
# The rule is in `EventDef.obstructs_radius`: **anything that stands still is solid at the width it
# is drawn**, derived rather than set per row — a field only ever *reached for* leaves large,
# visibly solid objects with no body at all. What lives here is the one number that rule needs from
# outside itself.

## The widest body an event may have and still be allowed to stand on calm ground.
##
## A spoiler has to make the park loud rather than take the ground away. **Refusing *anything* with
## a body is the reading to avoid**: once every stationary row is solid, a person is 18px across and
## that rule empties the pool, so nothing can be put in a park at all.
##
## So it is stated as what it means. A body you can walk around does not close a 704px lot; one you
## have to route around does. Sized to sit above a person and well under `construction`, which is
## exactly the thing it is there to keep out.
const OBSTRUCTION_A_PARK_CAN_HOLD := 16.0

## The most things the day will put in the park she used yesterday.
##
## **One spoiler is three percent of a four-block calm zone** — see `EventScheduler._denial_radius`
## for the arithmetic — so a single event does not spoil a park, it stands in one. A cap rather than
## a target: the grid asks for as many as it takes to cover the ground and this is where it stops
## asking, because the events come from the day's own pool and a park with a dozen things in it is
## not a spoiled park, it is a different kind of city.
##
## Nine is a 3x3 grid, and it is measured: over twenty lots and five seeds it denies **99%** of a
## four-block calm zone and 91% of a one-block courtyard, against 8-12% for the same lot on an
## ordinary day. A 3x2 grid leaves 15% of the biggest zones standing, which is a hundred tiles of
## usable park — enough to settle in, so the spoiling would not have happened.
##
## A small lot never asks for nine: the grid is sized from what one of them actually denies, so a
## 46-tile courtyard takes one or two and this cap is never reached. What it costs is a day with
## nine more events in it, all of them inside the one lot she is being asked not to use.
const SPOILERS_TO_DENY_A_PARK := 9

# ------------------------------------------------------ running that matters ---
# Running is the wrong move against everything you route around, so there has to be one kind of
# thing it is the *only* answer to, or the run button is a trap. And the run is **taught** rather
# than merely permitted, on the day it starts to matter: day 1 is arrow keys and nothing else, and
# day 3 is the day something comes after the pram.

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
## **A notice stated as a duration is not a notice**, because it says nothing about where the
## pursuer spends it. Buying telegraph time alone gives a dog sited a couple of hundred pixels
## across her line that closes the gap in three quarters of a second and then stands inside its own
## lethal radius for the rest of a telegraph it is not allowed to kill her during. The instant it
## ends, it does — from a standing start, with nothing she could have done after the first second.
##
## So the telegraph is spent **closing to a stand-off and holding there**, which is
## `pursuit_standoff()` below, and this is the number that sets it: far enough out that the lunge
## itself can be answered rather than merely watched.
##
## **This number is the one thing about the day-3 dog a player has said is right** — *"it was enough
## time to react properly"* — so it is the wrong lever to reach for. The arithmetic that says the
## real window is two tenths of a second once her walking speed and the about-turn are counted is
## correct and answers a different complaint: *the dog kept following for too long* is the
## **break-off**. See `PURSUIT_SHAKEN_OFF`.
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
## **Stated over the player, not over the gap**, and the two are not the same rule in a real street.
## The same idea as geometry — *the gap has been opening for this long* — is unusable: a run opens
## the gap at 38px/s against the day-3 dog, a fifth of a pixel a frame, so anything that momentarily
## stops her gaining ground resets the timer to zero. A corner, a kerb, a pedestrian, the 0.37s the
## about-turn itself takes. The dog then goes on chasing somebody who is visibly sprinting, which is
## the one outcome that makes the mechanic unteachable.
##
## The contract it used to carry is unaffected, because it never rested here — it rests on the
## speed clauses in `validate_pursuit`. A pursuer is faster than a walk and slower than a run by
## `PURSUIT_MIN_MARGIN` on both sides, so **walking away still cannot end it** (she is never
## running, so this timer never starts) and **running away always can**.
##
## 0.35s is "almost immediately" and is about what the about-turn costs: the dog breaks off as she
## comes up to speed rather than after she has opened thirty pixels of daylight on it. That is most
## of what the whole answer costs her.
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
## **Both terms belong outside this function**, and folding them in is the tempting fix. The
## stand-off they produce is 70px wider, and the extra ground is spent *reversing away from her*
## through the telegraph, which reads as a dog that has changed its mind — a wider window bought on
## the one part of the encounter a player has said was already right. What the answer costs is
## priced by `PURSUIT_SHAKEN_OFF` instead.
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

## The signalled half of the traffic contract.
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
## **The shape has a shoulder on it**, because the meter has to go substantially up from some way
## off rather than waiting for contact.
##
## `1 − t²`: full strength at the inner edge, three quarters of it at the midpoint, and zero only at
## the outer edge, where the contract says it must be. **The whole catalogue gets its teeth from the
## shape rather than from its radii** — thirty rows of hand-widened radii would be thirty chances to
## break the fairness contract.
##
## **`(1−t)²` is the shape that looks equally reasonable and inverts the game.** It puts a quarter of
## the intensity at the midpoint of the band and six percent three quarters of the way out, so a café
## at 12/s sits under the 3.5/s walking decay across the whole outer 60% of its own field — and a
## `near` entry written at an event's outer radius reads `events 0.0`. An event you are not charged
## for until you touch it is not a thing to route around, it is a thing to bump into.
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
