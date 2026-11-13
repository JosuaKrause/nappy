class_name DawnSpoilers
extends DawnPhase
## **The park spoilers' dawn phase.**
##
## Puts something on a calm area she has already settled in this act.
##
## Not because repetition is boring, but because **the game's only verb stops being a decision on
## day two**: a player who finds a good park on day 1 has no question left to answer, and route
## planning is the whole game. It is the same problem as a calm area being a lap rather than a
## route, one scale up: that one is about the destination, this is about *which* destination.
##
## **And the day's route tree plans around the same area** (`ClosurePlanner.calm_to_shut()`, checked
## before it is accepted the way a street closure is): the tree neither grows a branch to a used area
## it can spare nor routes through it, so a spoiler standing here is never somewhere the tree was
## going to send her regardless. *(PLAYTEST-140, statement 8: "a used park is shut by the events
## placed in it, as before... and no route of the day goes through it".)*
##
## **One used area, at most once a run, is fenced instead** — `CityMap.fenced_park`, the first used
## area whose exclusion the guarantees allow on a day in act III or later (`Tuning.ACT_START_DAYS`),
## fenced for the rest of that act and never chosen again. *(PLAYTEST-140: "doing it for one park,
## sure, more towards the later stages of the game once but not for regular".)* It is never in
## `map.calm_blocks`, so it is skipped here by the same test that skips anywhere no longer calm —
## its fence is the whole of what it shows, and a spoiler behind it would be noise on the pavement
## beside a park nobody can enter.
##
## Three things keep it from being a punishment for playing well, and all three are load-bearing:
##
## - **It spoils with events, not by taking the ground away.** The park is still there, still
##   calm ground, still walkable. Things are standing in it, and she can see that from
##   the street and decide. An event that could seal or end the day is never chosen for this.
## - **One area is kept clean by construction** (`DawnCalmKeptClean`): the spoilers pass over it and
##   its ground joins what nothing may reach, so the day it creates is still winnable and the
##   alternative is still real rather than nominal.
## - **They are ordinary events, placed like any other.** They have no count of their own
##   and are drawn from the same day's pool, so day 2 is not "day 1 plus a punishment", it is a day
##   whose noise happens to be somewhere she was counting on.
##
## **It has to cover the ground, not stand in it**, and one event does not.
##
## What denies calm ground is holding the meter above `EXCITEMENT_CALM_THRESHOLD` against
## `CALM_ZONE_DENIAL_RATE`, 7.7/s — so a busker at intensity 19.3 has a *useful* radius of
## 157px whatever his 190px reach says, in a lot 704px across. That is a small share of one, and a
## day that rolls one spoiler for the block she used is still a day she settles in that same block.
## **The rate is fixed and the intensity is not**, so raising a row's intensity is the one thing
## that widens this: the busker's own reach grew by half when it was raised to clear the ground it
## stands on.
##
## So a spoiler is a **crowd**: one thing per cell of a grid laid over the calm ground, sized from
## what each of them can actually deny, capped by `SPOILERS_TO_DENY_A_PARK`. Each cell rolls its own
## def rather than repeating one — the fiction is that a park which is busy today is busy with
## several different things, and nine copies of one sprite in a field read as a duplicate, which is
## exactly what the spacing rule at `StreetInvalidation.room_around` prevents everywhere else.
##
## **Every area she has used this act, not just last night.** One night's memory makes day 2 a fresh
## decision and day 3 the same decision as day 1; an act's memory is what turns *find a different
## park* into *find your way around the city*. The city forgets at the act boundary, which is the
## only good news a run ever gets.
##
## One is always left alone whatever the memory says: the guarantee that a day is winnable outranks
## the guarantee that it is a fresh decision, and `MIN_CALM_BLOCKS` is sized so that the two do not
## have to fight — an act's worth of days plus one in reserve.
##
## Silent for anywhere she did not settle, that is no longer calm, or that is `CityMap.fenced_park`
## today — the last because it is left out of `map.calm_blocks`, and said again here so the reason
## is next to the loop. A merely-`shut_calm` area is not skipped: it is still calm ground, and this
## is exactly what stands in it.
##
## Model: no node.

## The rate a source has to beat before it is counted as denying the calm ground near it —
## `_denial_radius()`, and `EventCatalogue`'s own reasoning for the one ambient row
## that stands in a park.
##
## **Its own number rather than the calm ground's live decay, and the decoupling is the point.**
## Read off the decay, every rise in the walking rate would quietly admit louder rows beside parks:
## the pram settling faster is a statement about the pram, and *which events may stand next to a
## park* is a statement about the parks. Tying the two put the second decision inside the first,
## where nobody making it would see it.
const CALM_ZONE_DENIAL_RATE := 7.7
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
## **One spoiler is three percent of a four-block calm zone** — see `_denial_radius()`
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
## The phase's stream salt off the day's seed (`DawnContext.stream()`).
const SALT := 3

## Overrides DawnPhase.run.
func run(context: DawnContext) -> void:
	var calm := context.calm()
	var rng := context.stream(SALT)
	var blocks := calm.blocks()
	var spoilable := blocks.size() - 1
	for block in calm.used():
		if spoilable <= 0:
			return
		if block.x >= 0 and block in blocks and block != context.kept_clean():
			spoilable -= 1
			_spoil_one_park(context, rng, block)

## Spoils the calm area `block`: one spoiler a cell of its grid, each rolled on `rng`.
static func _spoil_one_park(context: DawnContext, rng: RandomNumberGenerator,
		block: Vector2i) -> void:
	var map := context.map()
	var events := context.events()
	var calm := context.calm()
	var lot := calm.rect_of(block)
	var open: Array[Vector2i] = []
	for tile in map.rect_tiles(lot):
		if not map.is_closed(tile):
			open.append(tile)
	if open.is_empty():
		return

	var ground := calm.ground_of(block)
	var pool := _things_to_put_in_a_park(context.day(), ground, context.heat())
	if pool.is_empty():
		return

	var placed: Array[String] = []
	var cells := _spoiling_grid(ground, pool)
	for cell in cells:
		var def := _pick_by_what_it_denies(pool, rng)
		# Snapped to the nearest open tile of the lot, so nothing lands on a closed street or
		# outside the calm ground the cell was measured from.
		var at := map.tile_to_world(_nearest_of(open, map.world_to_tile(cell)))
		var plan := EventPlan.new(def, at)
		# A body on a tile a route runs along stands beside the route instead, in its own cell:
		# the park is shut by what is placed in it (PLAYTEST-140 8), so a cell keeps its spoiler.
		if not context.keeps_the_routes(plan):
			plan = _beside_the_routes(def, cell, cells, open, context)
			if plan == null:
				continue
		events.add(plan)
		placed.append(def.id)
	if placed.is_empty():
		return
	context.note("roll", "%s in the park she used yesterday, %s"
			% [", ".join(placed), RunTrace.tile(block)])

## **`def` stood on the open tile of `cell`'s own ground nearest its centre that leaves the day's
## routes their ground** (`DawnContext.keeps_the_routes()`), or null where every tile of the cell
## is refused. A spoiler whose first tile puts its body on a route stands beside the route rather
## than not at all, since a used park the day could not shut is shut by its spoilers alone
## (PLAYTEST-140 8: "a used park is shut by the events placed in it, as before"). The tiles are
## asked in order of distance from the cell's centre, so the body is checked before it is
## accepted and nothing is repaired after. A tile is the cell's own when no other cell of the grid
## (`cells`) has a centre nearer it, which keeps the spoilers spread as the grid spreads them. A
## route is a chain of two-tile cells and a grid cell is several times wider, so only a park the
## routes fill leaves a cell no such tile.
static func _beside_the_routes(def: EventDef, cell: Vector2, cells: Array[Vector2],
		open: Array[Vector2i], context: DawnContext) -> EventPlan:
	var map := context.map()
	var centre := map.world_to_tile(cell)
	var order := open.duplicate()
	# Nearest first, and the same order on every run: ties go by row, then column.
	order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var to_a := (a - centre).length_squared()
		var to_b := (b - centre).length_squared()
		if to_a != to_b:
			return to_a < to_b
		return a.y < b.y if a.y != b.y else a.x < b.x)
	for tile: Vector2i in order:
		var at := map.tile_to_world(tile)
		if not _is_nearest_to(cell, at, cells):
			continue
		var plan := EventPlan.new(def, at)
		if context.keeps_the_routes(plan):
			return plan
	return null

## Whether no point of `cells` is nearer `at` than `cell` is.
static func _is_nearest_to(cell: Vector2, at: Vector2, cells: Array[Vector2]) -> bool:
	var own := at.distance_squared_to(cell)
	for other in cells:
		if at.distance_squared_to(other) < own:
			return false
	return true

## Rolls one of the pool, weighted by how much ground it can actually take.
##
## Everywhere else in the scheduler a def's `weight` is how *common* it is, which is a statement
## about a city. Here the job is covering a lot, and what a row denies goes as the square of its
## reach — a busker covers several times the ground a market stall does — so the roll is by area
## as well as by weight, and the quiet rows become the garnish on a spoiled park rather than half
## of it. It stays a roll rather than becoming "always the
## loudest" for the reason the mix exists at all: a park that is busy today is busy with several
## different things, and one repeated sprite reads as a duplicated sprite.
static func _pick_by_what_it_denies(defs: Array[EventDef], rng: RandomNumberGenerator) -> EventDef:
	var weights: Array[float] = []
	var total := 0.0
	for def in defs:
		var reach := _denial_radius(def)
		var weight := def.weight * reach * reach
		weights.append(weight)
		total += weight
	var roll := rng.randf() * total
	for i in defs.size():
		roll -= weights[i]
		if roll <= 0.0:
			return defs[i]
	return defs[defs.size() - 1]

## The points a spoiler goes at: a grid over the calm ground, spaced by what one of them denies.
##
## The spacing is the **average** denial radius of the pool rather than any one row's, because which
## def lands in which cell is a roll and the grid has to be laid out before the rolls happen.
static func _spoiling_grid(ground: Rect2, pool: Array[EventDef]) -> Array[Vector2]:
	var reach := 0.0
	for def in pool:
		reach += _denial_radius(def)
	reach = maxf(reach / float(pool.size()), float(Tuning.TILE_SIZE))

	# Cells wide enough that two neighbours' fields just meet, then thinned until the cap is met:
	# a lot too big to be covered by `SPOILERS_TO_DENY_A_PARK` things is covered as evenly as that
	# many can manage rather than densely in one corner.
	var columns := maxi(1, ceili(ground.size.x / (reach * 2.0)))
	var rows := maxi(1, ceili(ground.size.y / (reach * 2.0)))
	while columns * rows > SPOILERS_TO_DENY_A_PARK:
		if columns >= rows:
			columns -= 1
		else:
			rows -= 1

	var points: Array[Vector2] = []
	for row in rows:
		for column in columns:
			points.append(ground.position + Vector2(
					ground.size.x * (column + 0.5) / float(columns),
					ground.size.y * (row + 0.5) / float(rows)))
	return points

## How far from a source calm ground stops being usable.
##
## **Not the outer radius**, which is where it stops reaching at all. Anywhere a source emits less
## than `CALM_ZONE_DENIAL_RATE` (7.7/s) is somewhere she can still settle — and for every
## act I row that is most of its own field. Getting this wrong is how one busker was ever thought
## to spoil a park.
##
## **The rate is its own constant rather than the calm ground's live decay**, because *which rows
## may stand beside a park* is a decision about the parks and not about how fast the pram settles.
## Read off the decay, every rise in the walking rate would admit louder rows here as a side
## effect of a change nobody made about parks.
##
## **The zero case is not the line rules' zero case.** `EventDef.reach_above()` answers nothing at all for a
## row quieter than the rate it is asked about, which is right there — ground a walk nets the meter
## down in is not denied — and wrong here: a source she is standing on top of keeps her awake
## whatever its rate does further out, so the floor is its own `inner_radius`.
static func _denial_radius(def: EventDef) -> float:
	return maxf(def.inner_radius, def.reach_above(CALM_ZONE_DENIAL_RATE))

## The tile of `tiles` nearest `to`.
static func _nearest_of(tiles: Array[Vector2i], to: Vector2i) -> Vector2i:
	var best := tiles[0]
	var best_distance := INF
	for tile in tiles:
		var distance := Vector2(tile - to).length_squared()
		if distance < best_distance:
			best_distance = distance
			best = tile
	return best

## The things that may be put in the park she used yesterday.
##
## Deliberately narrow: nothing lethal, nothing that closes the ground, nothing mobile. A spoiled
## park has to be a park she can *see* is spoiled and walk away from — an abduction sitting in it
## would be a punishment for having settled there, and a barricade would be the ground taken
## away rather than made noisy, which is the thing this rule promises not to do.
##
## **The body test is a width, not `obstructs_radius > 0`.** Once everything that stands still has a
## body the two stop meaning the same thing: a busker is 18px across in a lot 704px wide, so he is
## loud and he is walked around, which is the whole job. `OBSTRUCTION_A_PARK_CAN_HOLD` is where that
## stops being true.
##
## **And the allowance depends on the ground.** A body that is nothing in a four-block calm zone is
## a wall across a four-tile courtyard, and a fixed number cannot be both — so it is a sixteenth of
## the shortest side of the calm ground, floored at that constant. That is what lets a market take
## over a whole park and keeps it out of a back yard.
##
## **And it has to stay where it was put.** A row handed to her walk
## (`EventDef.is_handed_to_her_walk()`, the sidewalk `poster_crew`) stands where her walk sites it,
## never where the dawn would put it, so a park it was meant to spoil would stand empty, against
## PLAYTEST-140 8 (a used park is shut by the events placed in it). None is offered.
static func _things_to_put_in_a_park(day: int, ground: Rect2, heat: int = 0) -> Array[EventDef]:
	var allowed := maxf(OBSTRUCTION_A_PARK_CAN_HOLD,
			minf(ground.size.x, ground.size.y) / 16.0)
	var suitable: Array[EventDef] = []
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day, heat):
		if def.hard_fail or def.mobile:
			continue
		if def.obstructs_radius > allowed:
			continue
		if def.spawn_mode != EventDef.SpawnMode.MAP:
			continue
		if def.is_handed_to_her_walk():
			continue
		suitable.append(def)
	return suitable
