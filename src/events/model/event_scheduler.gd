class_name EventScheduler
extends RefCounted
## Plans one day's event set: `build_day()` runs the dawn's phases over the dawn's context.
## See docs/EVENTS.md.
##
## Deterministic: the same seed and day always produce the same plan, which is what lets a
## player learn a run. Nothing here touches the global RNG.

## How many times over a tile on the day's routes is offered to a **friction** placement.
##
## *"Benign blockers go on the route… to make it more challenging / force the player to think their
## route through better."* About a quarter of the lattice is on the tree, so at 4 rather better
## than half of the costly rows land on the corridor and the rest of the city keeps a scatter — a
## city where every street off the route is empty would read as a set rather than as a place, and
## nothing in the design asks for that.
const EVENT_CORRIDOR_WEIGHT := 4
## How many times over a precinct tile is offered to the event scheduler against an ordinary
## pavement tile. Weighting the candidates rather than adding a rule: a precinct is where the cafés
## and the market stalls and the buskers are, and the way to say that is to make the ground more
## likely rather than to give the catalogue a new field.
const EVENT_PRECINCT_WEIGHT := 4
## And nothing of any kind lands inside this of anything else, which is about two tiles: close
## enough that a café and a shouting man can share a corner, far enough that neither is drawn
## inside the other.
const EVENT_SPACING_ANY := 64.0
## Two events of the same kind never land closer than this. A block is 256px across, so this
## is "not on the same stretch of pavement" — the objection was never to seeing a second dog
## walker, it is to seeing it thirty pixels from the first, which reads as a duplicate rather
## than as a second incident.
const EVENT_SPACING_SAME := 256.0
## How many times over the street **between two adjacent strands of the day's corridor** is offered
## to a wall, against the rest of the band it is in.
##
## Two strands running down neighbouring streets with a free step between them are one wide region
## rather than two routes. `RouteTree.gaps()` is what a gap is; the placement is
## `RowGround._times_for_role()`, where this multiplies the band weight rather than replacing it.
##
## **Set to leave about half of them open, which is the instruction rather than a compromise.** What
## is asked for is *variety in what a gap is worth*, so a number that closed every gap would be as
## wrong as one that closed none: it would turn the corridor into a set of separate corridors, which
## is the star shape `RouteTree` deliberately does not grow.
##
## It is also the reason this is a weight and not the per-gap roll that reads more directly. A roll
## needs a phase, a stream, a count of its own and a share of the caps; a weight rides on the day's
## bags and spacing unchanged (a location's weight, `RuledLocationGround.scale()`), and *cannot
## place more than the declared table's events per hundred draw locations let it*
## (`PlacementDensity`, `UnitFills`).
const EVENT_WALL_GAP_WEIGHT := 6
## How many times over the **rim** is offered to a **wall** placement, against ground further out.
##
## A wall bounds the corridor, so it has to be somewhere the corridor can see; a lethal thing four
## streets away bounds nothing. That is the preference. What is not a preference is the exclusion
## beside it — the same reasoning as `ClosurePlanner.CLOSURE_WALL_BIAS`, which is this number's twin one system
## over and deliberately the same value.
##
## **The rim is two kinds of ground, not one.** A turning off the corridor is the first: one street
## out, seen from the junction where the wrong choice is made. The **far side of a route's own
## street** is the second, and it is the nearer of the two — she reads it without leaving her line,
## and a café or a stall standing there is what a street with a route down one side looks like.
## *(2026-09-19: asked whether a wall across the street should be rare or common, "often".)*
##
## **It applies to the *costly* half of the wall band only.** A very costly row is what the rim is
## for — she has strayed one turning and it is expensive — and a lethal row wants the ground beyond
## it. See `RowGround._times_for_role()` and `WALL_DEEP_WEIGHT`.
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
## Where the line between *friction* and a *very costly* wall falls, in points of the meter it costs
## to walk through the middle of a row.
##
## Below it a row is friction and is weighted **onto** the routes; at or above it the row is what
## closes the ground **off** them. Stated over `EventDef.walk_through_cost()` — the same integral
## the caret is ordered by — rather than over a field somebody sets per row, because a second answer
## to *how expensive is this* is how two tables of the same fact drift apart.
##
## **Setting it to a row's own `walk_through_cost()` line for the caret is the mistake with the
## good argument.** The caret's own threshold, `Tuning.EXPECTED_IMPACT_POINTS`, is a near neighbour of
## this one and is not the same question: the caret is read off a **projected position** and this
## is read off a row's own **static integral**, so the two move independently and have. It is where
## the game raises a caret — *this is worth going round* — so sharing the
## question, not merely the value, would make the cue and the placement say one sentence. What
## sharing the question did instead was empty the routes: at 25 points, the caret's line before
## this milestone raised it, **two thirds of every day becomes a wall**, and day 1's corridor drops
## from 69.6 placements to 27.8 of 113. The ground off the paths is what was asked to be closed;
## nobody asked for the paths to be cleared.
##
## The line is set by two rows instead, and by the right two. **`dog_walker` costs 42.7 and has to
## stay friction**: the dog-walker decision arriving twice on day one is the route decision this
## game is made of, and a dog walker that is never on her route is that decision deleted. **And
## `leaf_blower` at 52.9 has to stay a wall**, because without it the non-lethal half of the range
## is act III and later rows only, and *"very costly to deadly"* stops being a range anybody meets
## — `tests/test_events_placement.gd` samples five days and counts both kinds. The line goes
## between them, same as it always has — what moved is where the two rows themselves sit.
##
## **It is in points of the meter, so it moves when the meter's own arithmetic does, and it moved
## again for a different reason than the walking decay this time.** *(2026-09-20: "restore fully
## now, raising leaf_blower by what the decay took from it and moving the line to sit between the
## two again".)* `homeless_yeller` and `dog_walker` both lost the net gain a real pass past them
## used to land once M117 raised the walking decay from 3.5 to 6.0/s, and restoring either of them
## fully pushes its own `walk_through_cost()` past where the line used to sit — the intensity a
## full restoration needs costs more than a dog walker used to, on its own numbers, before this
## row is even touched. Raising the two rows without moving the line would have made one of them a
## wall; raising the line without also raising `leaf_blower` would have let the non-lethal half of
## the range go empty again. Both moved together, `leaf_blower`'s own core answering the same
## walking-decay loss the other two rows answer, at `Tuning.EXCITEMENT_DECAY_WALKING`'s current
## rate — this reading is not itself a re-derivation for the decay's own sake, only for the two
## rows either side of it.
##
## **Raising the walking decay still lowers every row's cost unevenly**, the netting-off-over-time
## effect this line's own history already carries: that is why `protest` (269px of 15/s) fell from
## 42.3 to 27.6 and crossed under `dog_walker`'s **old** number (105px of 26/s), which no threshold
## can undo — a protest now genuinely costs less to walk through than a dog walker's old field did,
## so it is on the routes with the rest of the ordinary expensive city regardless of where this
## line sits.
##
## What that leaves on the corridor is `cafe_tables`, `market_stall`, `homeless_yeller`,
## `delivery_van`, `protest` and the dog walker, and what it puts off it is `leaf_blower`,
## `burning_building`, `pigeon_flock`, `loose_dog`, `military_convoy`, `night_raid`, `fire_truck`
## and every lethal row — the same two lists as before this line moved, checked catalogue-wide
## rather than assumed: nothing else crosses it either way. Re-measure with
## `tests/probes/m117_decay.gd` if the cost table moves; do not re-derive it.
const WALL_WORTH_OF_COST := Tuning.METER_MAX * 0.48

## **Plans what stands on the walk the dawn's context describes** (`DawnContext`): which rows, how
## they are drawn, and which placement rules apply are all the spec's (`DaySpec`, "how its events
## are placed"), so a day and the escape's city are one entry point, one list of phases and one set
## of rules (`StreetInvalidation`). The escape's city is the same draw under three of the spec's
## settings (`DawnDraw`). Nothing here asks which day it is beyond `DawnContext.day()`, the day the
## catalogue's rows are read for.
##
## **Every input is the context's**, handed it by whoever made it (`DayPlanner`, or a suite's
## `GameDawn`): the walk and its calm areas, the heat, the doors, what stands, the run's scars and
## the one-shots it has spent, the mast sites, the trace and the roadblock phase's row. Nothing is
## read off the run, so a rig that plans day 9 twice gets the same day twice whatever a run
## happens to have done. Every def below arrives already in the shape that heat puts it in, see
## `EventCatalogue.heated()`, so nothing in this file tests for it.
##
## **Plans into the context and answers nothing**: the day's plan is `DawnContext.events()`, written
## only by the dawn's phases (`_phases()`), and the locations and the ground
## the dawn built are read beside it (`DawnContext.locations()`, `DawnContext.ground()`).
##
## **A day whose target stands in a calm area owes her a second one** — day 12's swing, in the
## park that is taken once she has reached it (PLAYTEST-122: "the day guarantees a second open
## park she can reach from the swing"). Dawn keeps it by construction: the calm other than
## `calm.besides()` is the ground the calm rule and `DawnCalmKeptClean` keep clean, and the day's
## routes, which no body the day plans closes (the route rules of `StreetInvalidation`, and
## `RouteGroundRule` for the scars and the spoilers), run to it.
static func build_day(context: DawnContext) -> void:
	for phase in _phases():
		phase.run(context)

## **The dawn's phases, in the order they run** (`DawnPhase`, one class each under
## `dawn_phases/`), each handed the day's context and each on its own stream off the day's seed
## (`DawnContext.stream()`). The order is the order rows enter the day's plan.
##
## The city's fixed parts come first (the design's "the city's fixed parts have phases of their
## own"): the ambient rows, the masts and the region wall's bodies stand where their planners put
## them and each holds its location, so the draw passes over it; the run's scars stand between
## them. Then the calm area the day keeps clean is decided, before the first judge asks the
## day's rules; then day 13's roadblocks; then day 1's lessons on the tutorial route, its other
## locations drawn empty. Then the rows the day places for a reason of its own (the scripted rows), the one-shots owed to her walk, the spoilers in the parks she used, the moments
## she is owed and the draw of every open location, a unit at a time from the bag of the unit's
## most permissive view; the run lesson is added
## after the draw, where the day owes no pursuit, and the last phase counts for the run log what
## day 13's roadblocks leave uncovered.
static func _phases() -> Array[DawnPhase]:
	return [
		DawnAmbient.new(),
		DawnScars.new(),
		DawnMasts.new(),
		DawnWallBodies.new(),
		DawnCalmKeptClean.new(),
		DawnRoadblocks.new(),
		DawnTutorial.new(),
		DawnScripted.new(),
		DawnOneShots.new(),
		DawnSpoilers.new(),
		DawnMoments.new(),
		DawnDraw.new(),
		DawnLesson.new(),
		DawnRoadblockCount.new(),
	]

## **Whether `section` is on the main road**, where nothing that closes a street stands outside the
## escape (inbox #1186 in gentle-owl): neither a roadblock the phase places nor one day 13's task swaps in.
static func is_on_the_main_road(map: CityMap, section: Location) -> bool:
	var segment := section.segment()
	return map.is_main_road(not segment.horizontal, segment.a.x)

## **`def`, an event that spans the street, standing across `section`**: on the carriageway tile of
## the section nearest its middle, built as any placement is (`builder`, `PlanBuilder.build()`), or
## null where the section is on the main road (`is_on_the_main_road()`) or has no carriageway. Nothing is judged:
## day 13's task replaces the section's whole content with it, a route-adjacent section being valid
## ground under the route-adjacent rules already (inbox #1185 in gentle-owl); what the section held is spent by
## the caller (`EventStreaming.swap_section()`).
static func across_the_section(def: EventDef, builder: PlanBuilder, map: CityMap,
		section: Location, rng: RandomNumberGenerator) -> EventPlan:
	if is_on_the_main_road(map, section):
		return null
	var tiles := section.tiles()
	var middle := map.world_to_tile(section.centre())
	var best := Vector2i(-1, -1)
	for y in range(tiles.position.y, tiles.end.y):
		for x in range(tiles.position.x, tiles.end.x):
			var tile := Vector2i(x, y)
			if map.tile_at(tile) != GameEnums.TileType.ROAD:
				continue
			if best == Vector2i(-1, -1) \
					or (tile - middle).length_squared() < (best - middle).length_squared():
				best = tile
	if best == Vector2i(-1, -1):
		return null
	return builder.build(def, best, rng)

## **`plan`'s row, unplaced, for her walk to site** (`EventDirector.site_what_is_on_her_way()`):
## what a recurring row handed to her walk (`EventDef.is_handed_to_her_walk()`, the poster crew)
## becomes as a unit draws it (`MarbleDraw`), so no row drawn after it is spaced from a place
## it never stands at. A one-shot owed to her walk is planned unplaced by `DawnOneShots`.
static func owed_to_her_walk(plan: EventPlan) -> EventPlan:
	var owed := EventPlan.new(plan.row(), Vector2.INF)
	owed.give_role(plan.role())
	return owed

## The tiles of one street of the walk a given row may stand on: **the day's own ground for the row**
## (`RowGround.tiles_for()`, every refusal a day makes of a tile — a closed tile, a held street, the
## home block, a standing street tree's footprint, the side of the sidewalk the row wants, a corner
## for a row with a spread, the power station's front — and its precinct weight), on the street's
## own rect. *(Inbox #785 in minty-lemur, 2026-10-18: "does the escape use the same placement rules
## as the regular game? it doesn't seem like it does. it should, though.")* The walk names the
## streets that exist for it, so the rect takes the place of a day's corridor weighting.
## `ground` is the walk's ground (`row_ground()`), made under the spec's home-street rule
## (`DaySpec.keeps_the_home_streets_clear()`): the escape keeps it off, since she never sets off from that
## door there. It refuses a street tree's ground *(2026-09-12, the player: "trees read like
## obstacles (they add noise) so it makes detecting actual obstacles harder")*.
##
## `standing_at` is where she starts the walk (`RouteSource.start()`), and ground within a body's
## reach of it is refused the same way a tree's is. *(2026-09-19: "the spawning shouldn't be a
## check. the pathing should start from the position. then obstacles can never happen".)* **Refused
## here rather than cleared up afterwards**, which is the whole difference the player is drawing: a
## pass that placed a van on her and a later one that moved it would leave the guarantee resting on
## the repair, and a check that moved *her* instead is the option they named and rejected. Ground she
## is standing on is not ground this is ever offered.
static func street_ground(map: CityMap, ground: RowGround, segment: StreetNetwork.Segment,
		def: EventDef, standing_at: Vector2) -> Array[Vector2i]:
	var copies := ground.offers_for(def)
	var found: Array[Vector2i] = []
	var rect := segment.tile_rect()
	var clear_of_her := clearance_around_her(def)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var tile := Vector2i(x, y)
			if not copies.has(tile):
				continue
			if map.tile_to_world(tile).distance_to(standing_at) <= clear_of_her:
				continue
			for _copy in int(copies[tile]):
				found.append(tile)
	return found

## **The ground of a walk on `map` routed by `corridor`** (`RowGround`: which tiles a row may stand
## on, and how many times over each is offered), made with what is this file's: how many times over
## a precinct, the routes' streets, the rim, a gap and the ground past the rim are offered
## (`EVENT_PRECINCT_WEIGHT`, `EVENT_CORRIDOR_WEIGHT`, `EVENT_WALL_RIM_WEIGHT`,
## `EVENT_WALL_GAP_WEIGHT`, `WALL_DEEP_WEIGHT`), and which wall is one by its cost
## (`_is_a_wall_by_cost()`). `corridor` is null for a walk with no routes; `from_the_door` is the
## spec's home-street rule (`DaySpec.keeps_the_home_streets_clear()`), a day's where none is said.
##
## **One ground a walk**: the dawn's context makes the day's (`DawnContext.ground()`, with this
## function) and the day's planner hands it on with the plan (`DayPlanner.Plan.ground()`), so
## whoever is handed the walk's asks that one. A caller that makes its own is one with no walk's
## ground to be handed: a check, a probe, a scene recipe's runtime (which makes one for its
## whole scene and hands it to every row it places and to its walk) and, for a walk no dawn of a
## day planned and no ground was handed to, `EventsAhead._ground_of_the_walk()` and
## `ResistanceDirector._fronts_a_fire_catches_on()`.
static func row_ground(map: CityMap, corridor: Corridor = null,
		from_the_door := true) -> RowGround:
	return RowGround.new(map, corridor, from_the_door,
			RowGround.Weights.of(EVENT_PRECINCT_WEIGHT, EVENT_CORRIDOR_WEIGHT,
					EVENT_WALL_RIM_WEIGHT, EVENT_WALL_GAP_WEIGHT, WALL_DEEP_WEIGHT),
			EventScheduler._is_a_wall_by_cost)

## How far from the tile she is put down on a row of this kind may not be offered ground — the
## wider of the two things she can arrive *inside* of: a body, and a lethal field.
##
## **A body is her body plus its body.** The half tile on top of it is not a margin of taste: a
## stationary, unpinned body is moved from the lane tile the scheduler chose to the middle of the
## pavement band by `BodyStance._centred_on_the_pavement_band()` when the instance is built, and
## the two lane centres sit `TILE_SIZE * 0.5` either side of that middle — so the ground a
## placement finally stands on is up to half a tile from the tile this loop is looking at, and the
## exclusion has to cover where it *ends up* rather than where it is rolled.
##
## **A lethal field is its whole `outer radius`**, which is a different and much wider question.
## *(2026-09-19: "I still spawn with flashing !!! in the city.")* The doubled exclamation mark over
## her head means *this will end your day*, and `WarningBoard.warn_about_the_ground_she_is_on()`
## raises it for any lethal row still telegraphing — or still waiting to notice her — whose
## **outer** radius covers her, because that radius is exactly what the fairness contract promises
## her time to walk out of. A row placed inside it has therefore already spent her notice before
## she has taken a step, which is the same defect as a body on her spawn read one field wider: on
## the seed the player walked, an `abduction` van stood 143px away with a 250px field.
##
## So the ground she is put down on is not ground a lethal row is ever offered either. Refused here
## rather than cleared up afterwards, for the reason `street_ground()` gives: a pass that placed a
## van on her and a later one that moved it would leave the guarantee resting on the repair. The
## half tile is carried for a lethal row too, since the same recentring moves it.
##
## A row with neither a body nor a lethal field needs none of this: nothing about it can be stood
## inside, and nothing about it raises the mark.
static func clearance_around_her(def: EventDef) -> float:
	var reach := 0.0
	if def.obstructs_within() > 0.0:
		reach = def.obstructs_within() + Tuning.PLAYER_BODY_RADIUS
	if def.ends_the_day():
		reach = maxf(reach, def.heard_within())
	if reach <= 0.0:
		return 0.0
	return reach + Tuning.TILE_SIZE * 0.5

## What the day is placing a row **for**, which is the only thing that makes *wall* and *friction*
## mean anything. See `docs/CITY.md`, "The words for it".
##
## Three of the four answers come straight off the design: lethal and expensive rows are the
## **walls** that bound the corridor, benign rows are **friction** on the route, and a one-shot is a
## **set piece** placed so that she actually meets it. The fourth is the interesting one.
##
## **`NONE` is not a leftover bin, it is the honest answer for anything the day did not site
## against the corridor at all.** An `AHEAD_OF_PLAYER` row is the case that proves it: `cat_dash` is
## sited by `EventDirector` in front of wherever she turns out to be walking, and the scheduler
## never chooses a tile for it. Calling it a wall would put a mark on the telemetry map claiming a
## placement that nothing made — which is the exact failure the picture exists to catch, arriving
## through the legend. `TOWARD_PLAYER` is sited by the same director for the same reason and gets
## the same answer. `spawn_mode_on(day)` is what this asks rather than `spawn_mode` alone, since a
## row like `charging_dog` answers `NONE` on `Tuning.RUN_TAUGHT_DAY` — a director moment, exactly
## like the cat — and `WALL` every day after, once it is `EventDef.spawn_mode_on()`'s `MAP`
## placement and the scheduler has chosen it a tile like any other lethal row.
##
## **A wall is not only the lethal rows.** The ground off the routes *ranges from very costly to
## deadly*, so an expensive row is a wall too and `WALL_WORTH_OF_COST` is where the line
## falls. Cheap rows stay friction and stay on the corridor, which is what keeps the routes worth
## walking rather than merely survivable.
##
## It is stated over `walk_through_cost()` — the same integral `tests/test_danger.gd` orders the
## caret by — rather than over a new field, because *how expensive a row is* is a question the
## catalogue already answers, and a second answer to it is how two tables of one fact drift apart.
##
## **And a wall is also what cannot be walked past.** *(PLAYTEST-77: "a wall is also when you
## physically cannot walk through".)* Cost and passability are different questions and the cheap
## answer to the second one is not the first: a market stall costs 8.5 points to walk through, well
## under `WALL_WORTH_OF_COST`, and denies 58px of a 64px sidewalk, so there is no line past it on
## the sidewalk it stands on at any price. `_takes_a_whole_sidewalk` is that reading, taken from the
## row's own numbers exactly as the cost one is. What it buys is the placement: friction is aimed at
## the route, and a row aimed at the route she is meant to walk has to be one she can get past
## there.
##
## **`EventDef.Role.SCENERY` is checked before the cost is, and it answers `NONE` rather than a fifth
## role.** *"Flocks are basically free already — don't count it as block, just count is
## scenery."* `pigeon_flock`'s 42-over-168px field crosses `WALL_WORTH_OF_COST` on the plain
## reading, so without the exemption it would be a wall pulled off every route the way any other
## expensive row is — which is exactly the placement the player overturned. `NONE` already means
## "placed for a reason that is not about the corridor at all," which is the flock's own case: it
## is still sited on a tile like everything else, just never weighted toward or away from one.
static func role_for(def: EventDef, day: int = 0) -> GameEnums.BlockerRole:
	if def.spawn_mode_on(day) != EventDef.SpawnMode.MAP or def.is_ambient():
		return GameEnums.BlockerRole.NONE
	if def.is_scenery():
		return GameEnums.BlockerRole.NONE
	if def.is_a_one_shot():
		return GameEnums.BlockerRole.SET_PIECE
	if def.ends_the_day() or def.walk_through_cost() >= WALL_WORTH_OF_COST \
			or _takes_a_whole_sidewalk(def):
		return GameEnums.BlockerRole.WALL
	return GameEnums.BlockerRole.FRICTION

## **Whether a `WALL` earns the pull toward junction rims, as opposed to keeping only the one
## consequence every wall gets** (zero copies on a route-carrying cell, `RowGround._times_for_role()`).
## *(2026-09-19, the player, asked whether `delivery_van` should also be weighted toward junctions
## once it became a wall: "A. No (my recommendation). -- do that")* `EVENT_WALL_RIM_WEIGHT`
## is for the rows meant to be seen from a distance before she commits to a street — lethal, or
## costly enough to cross `WALL_WORTH_OF_COST` — and `delivery_van` is neither: silent, and a wall
## only because its own body leaves no lane (`_closes_the_band_by_its_own_placement`), which the
## cost clause (`EventDef.reaches_the_far_lane()`) never sees. A row that is a wall by fit alone is
## spread along streets the way friction is instead: the day's ground is handed this question
## (`row_ground()`) and asks it before deciding which
## weight a `WALL` gets.
static func _is_a_wall_by_cost(def: EventDef) -> bool:
	return def.ends_the_day() or def.walk_through_cost() >= WALL_WORTH_OF_COST \
			or def.reaches_the_far_lane()

# ------------------------------------------------ an authored scene's row at its place ---

## **An authored scene's row at the location its tile names**, or null with the reason appended to
## `why`. A recipe keeps its data: `at` names the tile, and so the location holding it
## (`DayLocations.holding()`, of the ground under it), which is asked once, as a dawn phase asks a
## location: the tile is one the location takes for the row (`LocationFit`), the candidate built
## there on a private stream (`route_seed`, so unrelated actors cannot move a required path), a
## recurring row's route kept on its location's run as the day's unit draw keeps it
## (`Location.run()`), and the day's rules allow it (`StreetInvalidation`, the calm `calm` says
## she has not used left alone). No tries and no fallback: a location that does not take the row
## fails the recipe loudly, with the reason, rather than placing it somewhere else (the
## orchestrator's reading, open to the player's overturn). `locations` is the day's, laid out once
## for the whole recipe; laid out here for a caller that hands none. `builder` builds the candidate.
## `ground` is the scene's one ground for a row (`row_ground()`), made once and handed to every
## row it places: the tile has to be one it offers, and a placement makes no ground of its own.
static func recipe_placement(def: EventDef, day: int, map: CityMap, builder: PlanBuilder,
		at: Vector2, route_seed: int, already: Array[EventPlan], corridor: Corridor,
		ground: RowGround, doors: PackedVector2Array, calm: CalmAreas,
		standing: Array[EventPlan] = [], locations: DayLocations = null,
		why: Array[String] = []) -> EventPlan:
	if not def.available_on(day) or def.spawn_mode_on(day) != EventDef.SpawnMode.MAP:
		why.append("%s is not placed on the map on day %d" % [def.id(), day])
		return null
	def = def.for_day(day)
	var tile := map.world_to_tile(at)
	if not map.tile_to_world(tile).is_equal_approx(at):
		why.append("%s is not at the middle of a tile" % def.id())
		return null
	if locations == null:
		locations = DayLocations.lay_out(map, corridor if corridor else Corridor.of(null))
	var location := locations.holding(tile, map.tile_at(tile))
	if location == null:
		why.append("no location holds tile %s" % tile)
		return null
	var fit := LocationFit.new(day, map, builder, ground)
	if not tile in fit.tiles(def, location):
		why.append("the location holding tile %s does not take %s there" % [tile, def.id()])
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = route_seed
	var run := Rect2i()
	var beside := ResistanceSteps.guarded_row_on(day)
	if def.is_drawn_by_units(day, beside) and DawnDraw.ROUTES_STAY_ON_THE_RUN:
		run = location.run()
	var candidate := fit.build(def, tile, rng, run)
	if not candidate:
		why.append("%s cannot be built on tile %s" % [def.id(), tile])
		return null
	var around := already.duplicate()
	around.append_array(standing)
	var rules := StreetInvalidation.new(map, corridor, calm.unused_ground(), doors, null)
	if rules.room(candidate, role_for(def, day), tile, already, around) == -INF:
		why.append("the day's rules refuse %s on tile %s" % [def.id(), tile])
		return null
	return candidate

# ------------------------------------------------- a path never has to cost (M129) ---

## **Whether a row's own numbers leave no way past it along a sidewalk it may stand on** — the
## passability reading of a wall, beside the cost one. *(PLAYTEST-77: "how is market stall a
## friction? you can't walk through it"; "a wall is also when you physically cannot walk through".)*
##
## A sidewalk is two lanes of tile, and a row stands in one of them, so the only line past it is the
## other lane — one tile across, which `EventPlan.denies()` reads as free while the row's reach is under it.
## What the reach is, is the whole point: **the body plus the ground it charges for**
## (`EventDef.line_reach()`), not the body alone. A café whose tables are 24px across but which bills
## anybody within 56px of them is a café nobody walks past on that sidewalk for free, and *free* is
## what the guarantee is about.
##
## **It is asked of the def and nothing else**, because a role is decided before a tile is chosen —
## so the question is *a* sidewalk rather than *this* sidewalk, and a row that may stand on one is
## judged on the narrowest ground it may be rolled onto. A row the placement rolls onto a square or
## a park instead is still the same row with the same field, and being a wall costs it nothing
## there: the role only ever decides which ground it is offered.
##
## The five rows outside the line reading entirely — a pursuer, a door, a city-wide row, scenery, a
## mobile row that does not pace — are outside this too, by asking `EventDef.has_a_line_to_avoid()` rather
## than repeating the list.
static func leaves_no_line_along_a_sidewalk(def: EventDef) -> bool:
	if not def.stands_on(GameEnums.TileType.SIDEWALK):
		return false
	if not def.has_a_line_to_avoid():
		return false
	if def.reaches_the_far_lane():
		return true
	return _closes_the_band_by_its_own_placement(def)

## **Whether the row's own body, stood exactly where `pavement_side` puts it, leaves no edge-to-edge
## gap of `RouteSidewalkRule.HER_LANE_CLEARANCE` anywhere across the sidewalk band** — a second, physical reading of
## "leaves no way past it" beside `EventDef.line_reach()`'s cost-based one above. *(PLAYTEST-94, 2026-09-19:
## "I still get hard walls on the side of the sidewalk that is on the path -- how can this be so hard
## to do correctly?")* The cost clause asks what a row bills a passer-by for being near it; this asks
## whether a passer-by has anywhere left to stand at all, and the two can disagree: `delivery_van`
## is silent and its 22px `obstructs_within()` stays under the far-lane distance (`EventDef._THE_FAR_LANE`, one tile, 32px), so the cost clause
## reads it as friction — but pinned `AT_THE_KERB`, 16px in from the kerb edge, it leaves only
## `(SIDEWALK_WIDTH * TILE_SIZE - TILE_SIZE * 0.5) - 22 = 26px` to the frontage, narrower than the
## 28px she needs, which `tests/test_events_catalogue.gd`'s
## `_test_a_kerbed_body_still_pins_the_frontage` already measures by hand for this one row. Read
## off `obstructs_within()` and `pavement_side` rather than off an id, so the next row this
## narrow is caught the same way without anybody adding it to a list — and a row whose reach
## already clears the far-lane distance (`EventDef.reaches_the_far_lane()`) never reaches this,
## so nothing already a wall is asked twice.
static func _closes_the_band_by_its_own_placement(def: EventDef) -> bool:
	var reach := def.obstructs_within()
	if reach <= 0.0:
		return false
	var band := float(Tuning.SIDEWALK_WIDTH) * Tuning.TILE_SIZE
	var pos := _band_offset_of(def.sidewalk_lane(), band)
	var near_gap := pos - reach
	var far_gap := band - (pos + reach)
	return maxf(near_gap, far_gap) < RouteSidewalkRule.HER_LANE_CLEARANCE

## Where `pavement_side` stands a body across a sidewalk band, as an offset from the kerb edge —
## the same geometry `BodyStance._centred_on_the_pavement_band()` and its kerb/frontage
## exemptions produce, read here off the def alone because a role is decided before any tile exists
## to ask the map about. `pavement_side` is typed `int` rather than `EventDef.Pavement`: a
## cross-script enum parameter does not always match the type Godot infers for a value read off
## another script's property, so the wider type is the one that always parses.
static func _band_offset_of(pavement_side: int, band: float) -> float:
	match pavement_side:
		EventDef.Pavement.AT_THE_KERB:
			return Tuning.TILE_SIZE * 0.5
		EventDef.Pavement.AGAINST_THE_BUILDING:
			return band - Tuning.TILE_SIZE * 0.5
		_:
			return band * 0.5

## The clause as the **role** asks it, which is of a def with no tile yet — so a pacing row is not
## answered here at all.
##
## *(PLAYTEST-77, 2026-09-19: "yeller is something you can time. it stays on the route"; "if the
## yeller paces across a crosswalk then there is a way to avoid them. if they stay on the segment
## for the whole time with no side route then there is no way to avoid them. distinguish those
## cases when deciding whether the yeller is a wall".)* Whether a man walking a beat can be got
## past is a fact about **where his beat runs**, not about his field: the same numbers are a wall in
## the middle of a segment and a thing to time at a junction. `StreetInvalidation._a_pacing_beat_walls_a_sidewalk`
## asks it of the candidate, as a placement judges it, where the beat actually exists.
static func _takes_a_whole_sidewalk(def: EventDef) -> bool:
	return not def.paces_a_beat() and leaves_no_line_along_a_sidewalk(def)

# ---------------------------------------------------------------- park rules ---

## Today's closures plus every blocker's own obstruction circle, each where its body stands
## (`EventPlan.body_at()`: a roadblock's band on the kerb beside its lane), as the `blocked` set
## `ReachabilityGrid.flood()` takes. Public because the probes that measure what a day closes paint
## the same set, and a second copy of this loop would be a second answer to the same question.
static func blocked_by(map: CityMap, blockers: Array[EventPlan]) -> Dictionary:
	var blocked := map.closed_tile_set().duplicate()
	for plan in blockers:
		block_a_disc(map, blocked, plan.body_at(), plan.blocking_radius())
	return blocked

## Paints one disc of ground into a `blocked` set — a body's obstruction, or a field treated as
## ground she will not walk through.
static func block_a_disc(map: CityMap, blocked: Dictionary, at: Vector2, radius: float) -> void:
	if radius <= 0.0:
		return
	var reach := ceili(radius / float(Tuning.TILE_SIZE))
	var centre := map.world_to_tile(at)
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var tile := centre + Vector2i(dx, dy)
			if map.tile_to_world(tile).distance_to(at) <= radius:
				blocked[tile] = true
