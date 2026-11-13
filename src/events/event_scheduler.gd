@warning_ignore_start("untyped_declaration", "unsafe_method_access")
class_name EventScheduler
extends RefCounted
## Builds one day's event set from the run seed and the day index. See docs/EVENTS.md.
##
## Deterministic: the same seed and day always produce the same plan, which is what lets a
## player learn a run. Nothing here touches the global RNG.

## The rate a source has to beat before it is counted as denying the calm ground near it —
## `EventScheduler._denial_radius`, and `EventCatalogue`'s own reasoning for the one ambient row
## that stands in a park.
##
## **Its own number rather than the calm ground's live decay, and the decoupling is the point.**
## Read off the decay, every rise in the walking rate would quietly admit louder rows beside parks:
## the pram settling faster is a statement about the pram, and *which events may stand next to a
## park* is a statement about the parks. Tying the two put the second decision inside the first,
## where nobody making it would see it.
const CALM_ZONE_DENIAL_RATE := 7.7
## The day the masts carry the curfew announcement instead of their ordinary broadcast — the day
## `_curfew_announce()` used to be `scripted_day` for, kept as a named day rather than re-read off
## the def so the two rows do not have to agree about which field means "when" any more.
const CURFEW_ANNOUNCE_DAY := 6
## How many times over a tile on the day's routes is offered to a **friction** placement.
##
## *"Benign blockers go on the route… to make it more challenging / force the player to think their
## route through better."* About a quarter of the lattice is on the tree, so at 4 rather better
## than half of the costly rows land on the corridor and the rest of the city keeps a scatter — a
## city where every street off the route is empty would read as a set rather than as a place, and
## nothing in the design asks for that.
const EVENT_CORRIDOR_WEIGHT := 4
## Candidate tiles tried per placement before taking the roomiest one that was offered. A
## fallback rather than a failure: a scripted event has to happen, and on a full map the honest
## answer is the best spot left, not no event.
const EVENT_PLACEMENT_TRIES := 24
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
## bags, spacing and per-row caps unchanged (a location's weight, `RuledLocationGround.scale()`), and
## *cannot place more than the view's empty marbles let it*.
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
## — `tests/test_events.gd` samples five days and counts both kinds. The line goes between them,
## same as it always has — what moved is where the two rows themselves sit.
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
## are placed"), so a day and the escape's city are one entry point and one judge (`_best_of()`). A
## day draws the catalogue (`DaySpec.Draw.CATALOGUE`, below); the escape's city fills each street of
## its walk from its marble bag (`DaySpec.Draw.BAG_PER_STREET`, `_draw_the_walk()`). Nothing here
## asks which day it is beyond `DawnContext.day()`, the day the catalogue's rows are read for.
##
## **Every input is the context's**, handed it by whoever made it (`DayPlanner`, or a suite's
## `GameDawn`): the walk and its calm areas, the heat, the doors, what stands, the run's scars and
## the one-shots it has spent, the mast sites, the trace and the roadblock phase's row. Nothing is
## read off the run, so a rig that plans day 9 twice gets the same day twice whatever a run
## happens to have done. Every def below arrives already in the shape that heat puts it in, see
## `EventCatalogue.heated()`, so nothing in this file tests for it.
##
## **Plans into the context and answers nothing**: the day's plan is `DawnContext.events()`, written
## only by the passes below, and the locations and the ground the dawn built are read beside it
## (`DawnContext.locations()`, `DawnContext.ground()`).
static func build_day(context: DawnContext) -> void:
	var spec := context.spec()
	if spec.draw == DaySpec.Draw.BAG_PER_STREET:
		_draw_the_walk(context, _street_bag(spec.bag, street_bag_seed(context.day_seed())))
		return
	_plan_the_dawn(context)
	_ensure_the_run_is_taught(context)

	# **A day whose target stands in a calm area owes her a second one** — day 12's swing, in
	# the park that is taken once she has reached it (PLAYTEST-122: "the day guarantees a second
	# open park she can reach from the swing"). Dawn keeps it by construction: the calm other than
	# `calm.besides()` is the ground the calm rule and `_calm_kept_clean()` keep clean, and the
	# day's routes, which no body the day plans closes (the route rules of `StreetInvalidation`,
	# and `RouteGroundRule` for the scars and the spoilers), run to it.
	_count_what_is_left_uncovered(context)

## `build_day` up to and including the dawn draw, added to the context's plan: the ambient rows,
## the scars, the masts, the roadblock phase (`DawnContext.roadblock_row()`, day 13's roadblock),
## the scripted rows, the one-shots, the spoilers in a park she used, the moments she is owed and
## the draw of every location from its view's bag (`_draw_the_locations()`), each phase on its own
## stream off the day's seed (`DawnContext.stream()`). The day's locations are laid out
## (`DawnContext.locations()`) and held by the fixed parts before the phases draw into them.
static func _plan_the_dawn(context: DawnContext) -> void:
	var map := context.map()
	var events := context.events()
	var locations := context.locations()

	# **The fixed parts' phases** (the design's "the city's fixed parts have phases of their own"):
	# the ambient rows and the masts stand where their planners put them, and each is recorded on
	# the location holding it, so the draw passes over it; so is each of the region wall's bodies
	# (standing, planned before the day: "a wall makes its location unavailable throughout"). A
	# seal's bodies stand at dawn as standing and the day's rules keep rows off them, but hold no
	# location: a soft seal is not held, its carriageway still walkable and a row standing on it the
	# price of that route (`docs/EVENTS.md`, the held streets), and a hard seal's street is held
	# already. The region doors' bodies are not standing: a street door's street is held, and an
	# alley door is kept clear by the doors' rule (`CHECKPOINT_EVENT_GAP`). A mast's
	# location on a day before the masts holds nothing and is drawn like any other.
	var fixed := _place_ambient(context)
	events.add_all(fixed)
	_place_scars(context)
	var masts := _place_masts(context)
	events.add_all(masts)
	fixed.append_array(masts)
	for part in events.standing():
		if part.is_in_the_wall() and part.is_placed():
			fixed.append(part)
	for part in fixed:
		var tile := map.world_to_tile(part.placed_at())
		locations.hold_fixed_part(part, tile, map.tile_at(tile))
	# **One calm area stays clean by construction**: where she has settled in every area this act,
	# the one the spoilers leave alone joins the calm ground nothing may reach. See
	# `_calm_kept_clean()`.
	if context.spec().keeps_unused_calm_clear:
		context.keep_clean(_calm_kept_clean(context.calm(), events))
	_place_the_roadblocks(context)
	# **The scripted rows' dawn phase**: each draws one of the day's open locations its ground
	# takes and is assigned it (`ScriptedPhase`), offered through the dawn draw's own path and
	# judged by the day's rules, so the draw after passes over it. The one-shots are owed to her
	# walk (`_place_one_shots()`).
	_place_scripted(context)
	_place_one_shots(context)
	_spoil_the_parks_she_used(context)
	_owe_the_moments(context)
	_draw_the_locations(context)

## **The roadblock phase at dawn** (inbox #1185 in gentle-owl: the day's routes first, then roadblocks next to
## them, then the ordinary placement): day 13's roadblocks, placed by `RoadblockPhase` in the day's
## route-adjacent sections, spread by a bias toward the section farthest from those already placed,
## until every route tile has one close by, no section still offered could bring one close by a
## route tile that has none, or `RoadblockPhase.MOST` stand (the orchestrator's reading, open to
## correction). The task's row is `DawnContext.roadblock_row()`, null on every other day, which this
## leaves exactly as it was.
##
## **The phase places into the day's locations** (`DawnContext.locations()`, laid out off the
## walk's corridor every day), before the dawn draw fills the rest (`_draw_the_locations()`).
##
## **What a section is offered, and what close by is, are the day's**: `RuledRoadblockGround`
## stands the roadblock where it fits in the section and asks today's placement rules of it
## (`StreetInvalidation`), never on the main road (inbox #1186 in gentle-owl); close by is the walk her paths take from
## the ground she touches it from without leaving the circle of `RuledRoadblockGround.TASK_ROW_CLOSE_BY` round it
## (`DayReach.paths_over()`), the widest the task searches (`ResistanceDirector.ROADBLOCK_WIDER_REACH`).
##
## **What it does not promise.** Close by is measured over the ground as it stands when this runs:
## the scripted rows, the one-shots, the spoilers and the dawn draw after it shut more.
## `_count_what_is_left_uncovered()` writes to the run log how many route tiles have
## none as the day finally stands.
##
## **Outside the bags and on a stream of its own** (`RoadblockPhase.SALT`): the dawn draw after it
## draws the day's other rows, the roadblock holding no marble in it, spaced against these as against
## anything already down, and never over one.
static func _place_the_roadblocks(context: DawnContext) -> void:
	var def := context.roadblock_row()
	if def == null:
		return
	var day := context.day()
	var map := context.map()
	def = def.for_day(day)
	var judged := RuledRoadblockGround.new(def, day, map, context.builder(), context.events(),
			context.ground(), context.corridor(), context.rules())
	var phase := RoadblockPhase.new(context.locations(), judged)
	var placed: Array[String] = []
	for plan in phase.place(context.stream(RoadblockPhase.SALT)):
		placed.append(RunTrace.tile(map.world_to_tile(plan.placed_at())))
	context.note("plan", ("%d %s placed beside the day's routes, at %s; %d route tiles left with " +
			"none close by, the phase done")
			% [placed.size(), def.id, " ".join(placed) if not placed.is_empty() else "none",
			phase.left_uncovered()])

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

## **How many of the day's route tiles have none of `def`'s rows close by as the day stands**,
## written to the run log: once every pass is done, each placed `def` the day stands
## (not a region door's body or the wall's own) is read as close by every route tile its paths
## reach within `RuledRoadblockGround.TASK_ROW_CLOSE_BY` over the day's whole obstruction (`DayReach.shut_by()`), and the
## route tiles it leaves are counted. The roadblock phase (`_place_the_roadblocks()`) aims at none,
## but a route tile no section within reach took one for and ground the later passes shut both
## leave some. A
## count and nothing more: nothing is placed or moved here. Nothing on a day with no `def`
## (`DawnContext.roadblock_row()`), none written to (`DawnContext.is_traced()`) or no corridor.
static func _count_what_is_left_uncovered(context: DawnContext) -> void:
	var def := context.roadblock_row()
	var corridor := context.corridor()
	if def == null or not context.is_traced() or corridor == null:
		return
	var map := context.map()
	var events := context.events()
	var down := events.placements().duplicate()
	down.append_array(events.standing())
	var shut := DayReach.shut_by(map, down)
	var covered := {}
	for plan in down:
		if plan.row_id() != def.id or not plan.is_placed() or plan.is_door() \
				or plan.is_in_the_wall():
			continue
		for reached: Vector2i in RuledRoadblockGround.close_by(map, shut, plan):
			covered[reached] = true
	var tiles := 0
	var left := 0
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if not corridor.carries_a_route(tile) or not map.is_walkable(tile) or shut.has(tile):
				continue
			tiles += 1
			if not covered.has(tile):
				left += 1
	context.note("plan", "%d of %d route tiles have no %s within %.0fpx along her paths as the day stands"
			% [left, tiles, def.id, RuledRoadblockGround.TASK_ROW_CLOSE_BY])

## **`plan`'s row, unplaced, for her walk to site** (`EventDirector.site_what_is_on_her_way()`):
## what a recurring row handed to her walk (`EventDef.is_handed_to_her_walk()`, the poster crew)
## becomes as a location draws it (`LocationDraw`), so no row drawn after it is spaced from a place
## it never stands at. A one-shot owed to her walk is planned unplaced by `_place_one_shots`.
static func owed_to_her_walk(plan: EventPlan) -> EventPlan:
	var owed := EventPlan.new(plan.def, Vector2.INF)
	owed.role = plan.role
	return owed

# ------------------------------------------------------ the walk's streets from a bag ---

## **One draw per street of the walk, from one marble bag** — `DaySpec.Draw.BAG_PER_STREET`, the
## escape city's draw. The walk knows exactly which streets she can take — everything else is sealed —
## so it draws them before she sets off rather than siting things round her as a day does; and which
## row a street gets, or whether it gets one at all, is a draw. *(Inbox #785 in minty-lemur: "nobody
## ever asked for all four events on *every* street. that doesn't make any sense and cannot feasibly
## work at all. that is why the density is so high that it's impossible to get anywhere. yes, a
## marble bag is absolutely needed with empty events (nothing happening) as well. we need a fair
## mix". Of how many a street holds, inbox #1185 in gentle-owl's board answer: "one per street. fill empty in if
## any segment or location in the street has an event".)*
##
## Each street of the walk (`RouteSource.streets_on_the_walk()`, in its own order) draws one marble
## from `bag`, one bag for the whole walk. A marble with a row (`DaySpec.bag_rows`) is offered at the
## street's locations in the street's own order (`StreetLocations.drawing_order()`), on the ground the
## row fits (`LocationFit`, never the ground she starts on) and left out where the walk's rules
## invalidate it (`StreetInvalidation`: every day's rules but the calm the spec does not keep, one
## waiting guard's notice at a time, and the walk kept open past everything standing on it,
## `WalkGround`); the first location it stands at takes it, and **the rest of the street stays
## empty**. A marble with no row leaves the street empty, and **a row's marble no location of the
## street takes is spent unmet**, so a refused row never moves its danger onto the next street (the
## builder's reading, open to correction: the escape's bag keeps the player's counts, and a refused
## row stays the empty street it is today rather than staying in the bag). A row past its
## `max_per_day` is spent unmet the same way where the spec keeps the caps. Every row is added to
## `events`, the walk's plan, whose `standing()` the seals are.
##
## `bag` is drawn on its own stream (`street_bag_seed()`, off the day's seed), so drawing it takes
## nothing from the stream the placements roll on, and a replan from the same seed — the escape's
## restart after a loss — draws the same walk again. The trace is told how many marbles the walk
## drew (`bag.drawn`), the plan's own account and the one count a reader of the plan cannot
## recompute.
##
## The walk's ground for a row is the context's (`DawnContext.ground()`, the day's own under the
## spec's home-street rule: **a tree and an event never share ground**, `docs/CITY.md`, "Street
## trees"), and so are its rules (`DawnContext.rules()`: the walk kept open past everything standing
## on it, one waiting guard's notice at a time).
static func _draw_the_walk(context: DawnContext, bag: MarbleBag) -> void:
	var spec := context.spec()
	var map := context.map()
	var route := context.walk()
	var events := context.events()
	var fit := LocationFit.new(context.day(), map, context.builder(), context.ground(),
			route.start())
	var offered := RuledLocationGround.new(context.day(), context.day_seed(), map, events,
			context.corridor(), fit, context.rules(), context.ground())
	var placed := {}
	for segment in route.streets_on_the_walk():
		var def: EventDef = spec.bag_rows.get(bag.draw())
		if def == null:
			continue
		if spec.caps_per_day and int(placed.get(def.id, 0)) >= def.max_per_day:
			continue
		var street := StreetLocations.of(map, segment, PlacementView.View.ON_THE_ROUTE)
		var order_rng := RandomNumberGenerator.new()
		order_rng.seed = hash("%d:%s:walk-street" % [context.day_seed(), segment.key()])
		for location in street.drawing_order(order_rng):
			var placement := offered.offer(def, location)
			if placement:
				offered.stand(placement)
				placed[def.id] = int(placed.get(def.id, 0)) + 1
				break
	context.note("plan", "the escape's bag drew %d marbles for %d rows"
			% [bag.drawn, events.size()])

## **A marble bag of `counts`**: `counts` marbles of each key, a row's marble or
## `DaySpec.EMPTY_MARBLE`, on its own stream off `seed_value`, filled again whenever it runs empty —
## one bag for the whole walk, so the mix is exact over each fill of it rather than over each street.
## See `_draw_the_walk()`.
static func _street_bag(counts: Dictionary, seed_value: int) -> MarbleBag:
	var marbles: Array = []
	for marble: String in counts:
		for _i in int(counts[marble]):
			marbles.append(marble)
	return MarbleBag.new([], marbles, seed_value)

## The street bag's own stream, off the day's seed rather than off a draw from a stream made with it,
## so drawing the bag takes nothing from the stream the placements roll on — the shape
## `EventDirector` seeds its route bag in.
static func street_bag_seed(day_seed: int) -> int:
	return hash("%d:escape-bag" % day_seed)

## The tiles of one street of the walk a given row may stand on: **the day's own ground for the row**
## (`RowGround.tiles_for()`, every refusal a day makes of a tile — a closed tile, a held street, the
## home block, a standing street tree's footprint, the side of the sidewalk the row wants, a corner
## for a row with a spread, the power station's front — and its precinct weight), on the street's
## own rect. *(Inbox #785 in minty-lemur, 2026-10-18: "does the escape use the same placement rules
## as the regular game? it doesn't seem like it does. it should, though.")* The walk names the
## streets that exist for it, so the rect takes the place of a day's corridor weighting.
## `ground` is the walk's ground (`row_ground()`), made under the spec's home-street rule
## (`DaySpec.holds_the_home_streets`): the escape keeps it off, since she never sets off from that
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
## spec's home-street rule (`DaySpec.holds_the_home_streets`), a day's where none is said.
##
## **One ground a walk**: the dawn's context makes the day's (`DawnContext.ground()`, with this
## function) and the day's planner hands it on with the plan (`DayPlanner.Plan.ground()`), so
## whoever is handed the walk's asks that one. A caller that makes its own is one with no walk's
## ground to be handed: a scene recipe's row, a check, a probe and, for a walk no dawn of a day
## planned, `EventsAhead._ground_of_the_walk()` and
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
## pavement band by `EventFootprints._centred_on_the_pavement_band()` when the instance is built, and
## the two lane centres sit `TILE_SIZE * 0.5` either side of that middle — so the ground a
## placement finally stands on is up to half a tile from the tile this loop is looking at, and the
## exclusion has to cover where it *ends up* rather than where it is rolled.
##
## **A lethal field is its whole `outer_radius`**, which is a different and much wider question.
## *(2026-09-19: "I still spawn with flashing !!! in the city.")* The doubled exclamation mark over
## her head means *this will end your day*, and `WarningBoard.warn_about_the_ground_she_is_on()`
## raises it for any `hard_fail` row still telegraphing — or still waiting to notice her — whose
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
	if def.obstructs_radius > 0.0:
		reach = def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS
	if def.hard_fail:
		reach = maxf(reach, def.outer_radius)
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
## like the cat — and `WALL` every day after, once it is `EventDef.from_day_after`'s `MAP`
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
	if def.spawn_mode_on(day) != EventDef.SpawnMode.MAP or def.kind == GameEnums.EventKind.AMBIENT:
		return GameEnums.BlockerRole.NONE
	if def.role == EventDef.Role.SCENERY:
		return GameEnums.BlockerRole.NONE
	if def.kind == GameEnums.EventKind.ONE_SHOT:
		return GameEnums.BlockerRole.SET_PIECE
	if def.hard_fail or def.walk_through_cost() >= WALL_WORTH_OF_COST \
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
	return def.hard_fail or def.walk_through_cost() >= WALL_WORTH_OF_COST \
			or def.reaches_the_far_lane()

## The day the run is taught cannot leave the lesson to a weighted roll.
##
## `EventDirector._teach_the_run` moves a pursuit to the head of the owed list on `RUN_TAUGHT_DAY`,
## and if the day happened to owe none there is nothing to teach. `charging_dog` is weight 1.4 of
## a day-3 pool, so whole day 3s with none of them exist — and a player can reach act II never
## having been shown the one control the game will later require.
##
## It is added **outside** the day's draws rather than competing in them, and that is the exception
## being made honestly: everywhere else in this file the density is the bags', and a lesson that only
## happens when the dice agree is not a lesson. One event on one day of fourteen.
static func _ensure_the_run_is_taught(context: DawnContext) -> void:
	var day := context.day()
	var events := context.events()
	if day != Tuning.RUN_TAUGHT_DAY or events.has_a_pursuit():
		return
	for def in EventCatalogue.available_on(day, context.heat()):
		if def.pursuit == null or def.spawn_mode != EventDef.SpawnMode.AHEAD_OF_PLAYER:
			continue
		events.add(EventPlan.new(def, Vector2.INF))
		context.note("plan", "day %d owes no pursuit, so the run lesson is added: %s"
				% [day, def.id])
		return

# ------------------------------------------------------- the city remembers ---

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
## - **One area is kept clean by construction** (`_calm_kept_clean()`): the spoilers pass over it and
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
static func _spoil_the_parks_she_used(context: DawnContext) -> void:
	var calm := context.calm()
	var rng := context.stream(3)
	var blocks := calm.blocks()
	var spoilable := blocks.size() - 1
	for block in calm.used():
		if spoilable <= 0:
			return
		if block.x >= 0 and block in blocks and block != context.kept_clean():
			spoilable -= 1
			_spoil_one_park(context, rng, block)

## **The calm area the day keeps clean, where only construction can keep one**: `NONE` while an area
## counted today (any but `calm.besides()`, day 12's swing park) is one she has not used this act,
## since the calm rule keeps every unused area clear (`CalmAreas.unused_ground()`); otherwise the
## counted area she used longest ago that nothing standing spoils yet, else the least spoiled. The
## spoilers pass over it and its ground joins what nothing may reach, so the day has clean calm
## ground by construction (`docs/CITY.md`, "Guarantees").
static func _calm_kept_clean(calm: CalmAreas, events: DayEvents) -> Vector2i:
	var used := calm.used()
	var counted: Array[Vector2i] = []
	for block in calm.blocks():
		if block == calm.besides():
			continue
		if not used.has(block):
			return CalmAreas.NONE
		counted.append(block)
	var oldest_first: Array[Vector2i] = []
	for i in range(used.size() - 1, -1, -1):
		if counted.has(used[i]):
			oldest_first.append(used[i])
	var least := CalmAreas.NONE
	for block in oldest_first:
		if not events.is_spoiled(block):
			return block
		if least == CalmAreas.NONE \
				or events.spoilers_of(block).size() < events.spoilers_of(least).size():
			least = block
	return least

static func _spoil_one_park(context: DawnContext, rng: RandomNumberGenerator,
		block: Vector2i) -> void:
	var map := context.map()
	var events := context.events()
	var calm := context.calm()
	var route_ground := context.route_ground()
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
		if not _keeps_the_routes(plan, map, route_ground):
			plan = _beside_the_routes(def, cell, cells, open, map, route_ground)
			if plan == null:
				continue
		events.add(plan)
		placed.append(def.id)
	if placed.is_empty():
		return
	context.note("roll", "%s in the park she used yesterday, %s"
			% [", ".join(placed), RunTrace.tile(block)])

## **`def` stood on the open tile of `cell`'s own ground nearest its centre that leaves the day's
## routes their ground** (`_keeps_the_routes()`), or null where every tile of the cell is refused.
## A spoiler whose first tile puts its body on a route stands beside the route rather than not at
## all, since a used park the day could not shut is shut by its spoilers alone (PLAYTEST-140 8:
## "a used park is shut by the events placed in it, as before"). The tiles are asked in order of
## distance from the cell's centre, so the body is checked before it is accepted and nothing is
## repaired after. A tile is the cell's own when no other cell of the grid (`cells`) has a centre
## nearer it, which keeps the spoilers spread as the grid spreads them. A route is a chain of
## two-tile cells and a grid cell is several times wider, so only a park the routes fill leaves a
## cell no such tile.
static func _beside_the_routes(def: EventDef, cell: Vector2, cells: Array[Vector2],
		open: Array[Vector2i], map: CityMap, route_ground: RouteGroundRule) -> EventPlan:
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
		if _keeps_the_routes(plan, map, route_ground):
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

## The masts: the run's sites (`mast_sites`, worked out once on the city as built,
## `EventWorld.mast_sites()`), planted from `Tuning.MAST_FIRST_DAY` and standing at the same places
## every day of the run. Bypasses the scripted rows' dawn phase (`_place_scripted`) entirely — a mast is not a
## tile the day's own roll chose, it is a fixture the city already carries, the same way
## `_place_ambient()` beside this hands out one plan per playground rather than rolling for one.
##
## **Except a day whose own closures, region wall or checkpoints need that exact tile.** `map`
## already carries today's holds and closures by the time `build_day` runs them — `EventManager.
## start_day()` populates both before calling this — so a site is skipped for the day rather than
## planted on top of a barricade or a hut: `tests/test_events.gd`,
## `_test_nothing_the_catalogue_places_stands_on_held_ground`, holds this for every row the
## catalogue places and a mast is no longer an exception to it. `MastSites` already keeps every
## site a full block off the home street and its own field off a calm interior, so this is rare —
## a closure or a wall is one street's own width, not the whole city — and it costs a day's worth
## of one mast rather than a guarantee.
##
## **And a day whose own doors it would reach.** `MastSites._reaches_a_possible_door()` already
## refuses a site near *any* boundary segment's own door position — the boundary and the wall's
## own end are fixed at generation (`RegionPlanner.assign()`), so that exclusion is as
## day-independent as the sites themselves, and it is `MastSites`' own count that shows how few
## sites it actually costs. `doors` is only today's *open* doors, narrower than every boundary
## segment could ever be, so this second check is a safety net for whatever the siting-time
## exclusion cannot see (an alley door among them) rather than the rule's main work — see
## `DoorClearanceRule.clear_of_the_doors()`, the same guarantee `tests/test_checkpoints.gd` holds for every row.
##
## On `CURFEW_ANNOUNCE_DAY` every standing site also gets a `curfew_announce` plan
## alongside its ordinary `loudspeaker` one — see that row's own doc for why a second, invisible
## plan is what "the masts carry the announcement" means rather than a second mast.
##
## **A mast she silenced on an earlier day stands silenced**: `scars` carries a `SILENCED_MAST`
## entry at its foot (`ResistanceDirector._silence_the_mast()`), and its plans are made with
## `EventPlan.silenced` already set — the pole and horns are there, the lamp is out and there is no
## field, for the rest of the run.
##
## **So does a mast queued for day 11's task** (`EventManager.queue_a_mast()`): a `SILENCED_MAST` scar
## no site's foot is within a tile of is that mast, and it is planned again at its own foot, silenced,
## under `added_mast_id()`, on every later day whose holds, closures and doors leave the tile alone
## — the same refusals a site is planned under. One that was never silenced left no scar and is not
## planned again (*"Only if silenced"*).
static func _place_masts(context: DawnContext) -> Array[EventPlan]:
	var day := context.day()
	var map := context.map()
	var heat := context.heat()
	var doors := context.doors()
	var scars := context.scars()
	var planned: Array[EventPlan] = []
	if day < Tuning.MAST_FIRST_DAY:
		return planned
	var loudspeaker := EventCatalogue.heated(EventCatalogue.mast(), heat)
	var curfew := EventCatalogue.heated(EventCatalogue.by_id("curfew_announce"), heat) \
			if day == CURFEW_ANNOUNCE_DAY else null
	var sites := context.mast_sites()
	for scar in scars:
		if String(scar["id"]) != SILENCED_MAST or int(scar["since_day"]) >= day:
			continue
		var foot: Vector2 = scar["position"]
		var at_a_site := false
		for site in sites:
			if site.foot.distance_to(foot) < Tuning.TILE_SIZE:
				at_a_site = true
				break
		var tile := map.world_to_tile(foot)
		if at_a_site or map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
			continue
		if not DoorClearanceRule.clear_of_the_doors(foot, PackedVector2Array(), doors, loudspeaker.field_reach()):
			continue
		var added := EventPlan.new(loudspeaker, foot)
		added.mast_id = added_mast_id(foot)
		added.silenced = true
		planned.append(added)
	for site in sites:
		var tile := map.world_to_tile(site.foot)
		if map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
			continue
		if not DoorClearanceRule.clear_of_the_doors(site.foot, PackedVector2Array(), doors,
				loudspeaker.field_reach()):
			continue
		var quiet := _was_silenced(site.foot, day, scars)
		var mast := EventPlan.new(loudspeaker, site.foot)
		mast.mast_id = site.id
		mast.silenced = quiet
		planned.append(mast)
		if curfew:
			var announcement := EventPlan.new(curfew, site.foot)
			announcement.mast_id = site.id
			announcement.silenced = quiet
			planned.append(announcement)
	return planned

## The id of a mast queued for day 11's task at `foot` (`EventManager.queue_a_mast()`), the same
## every day it is planned again from its scar, and never a `MastSites` site's own id.
static func added_mast_id(foot: Vector2) -> String:
	return "added-%d-%d" % [roundi(foot.x), roundi(foot.y)]

## The scar id a mast she silenced leaves at its foot. No catalogue row answers it, so
## `_place_scars` places nothing for it; `_place_masts` is its only reader.
const SILENCED_MAST := "silenced_mast"

## Whether a `SILENCED_MAST` scar from an earlier day stands at `foot` — within a tile, since the
## foot a scar records and the foot a site computes are the same point read twice.
static func _was_silenced(foot: Vector2, day: int, scars: Array[Dictionary]) -> bool:
	for scar in scars:
		if String(scar["id"]) == SILENCED_MAST and int(scar["since_day"]) < day \
				and (scar["position"] as Vector2).distance_to(foot) < Tuning.TILE_SIZE:
			return true
	return false

## Permanent marks left by earlier days, placed again exactly where they happened, each into
## `events`, unless a body of one would cover a tile a route runs along or the street she starts on
## (`route_ground`, the day's `RouteGroundRule` counting the streets): then it is not stood today, which is the day's routes
## kept open by construction rather than a repair taking it away afterwards.
static func _place_scars(context: DawnContext) -> void:
	var day := context.day()
	var map := context.map()
	var events := context.events()
	var route_ground := context.route_ground()
	var heat := context.heat()
	for scar in context.scars():
		if int(scar["since_day"]) >= day or String(scar["id"]) == SILENCED_MAST:
			continue
		var def := EventCatalogue.by_id(String(scar["id"]))
		if def:
			var plan := EventPlan.new(EventCatalogue.heated(def, heat), scar["position"])
			plan.permanent = true
			if _keeps_the_routes(plan, map, route_ground):
				events.add(plan)

## Whether `plan`, stood where it is, leaves the day's routes their ground: no body of it covers a
## tile a route runs along, on a street or off one (`route_ground`). Only that: a scar or a spoiler
## is not spaced, not given a role and asked no line rule, so a field of one stands on a route's
## line as it always did and only a body is kept off the route's tiles; it asks nothing of what the
## day holds or what stands.
static func _keeps_the_routes(plan: EventPlan, map: CityMap,
		route_ground: RouteGroundRule) -> bool:
	var none: Array[EventPlan] = []
	return route_ground.allows(plan, map.world_to_tile(plan.placed_at()), none, none)

# ----------------------------------------------------------------- placement ---

static func _place_ambient(context: DawnContext) -> Array[EventPlan]:
	var map := context.map()
	var planned: Array[EventPlan] = []
	for def in EventCatalogue.of_kind(GameEnums.EventKind.AMBIENT, context.day(), context.heat()):
		match def.ambient_source:
			EventDef.AmbientSource.PLAYGROUND:
				for rect in map.playgrounds:
					planned.append(EventPlan.new(def, map.tile_rect_to_world(rect).get_center()))
			_:
				pass
	return planned

static func _place_scripted(context: DawnContext) -> void:
	var day := context.day()
	var map := context.map()
	var events := context.events()
	var ground := context.ground()
	var phase_ground := RuledLocationGround.new(day, context.day_seed(), map, events,
			context.corridor(), LocationFit.new(day, map, context.builder(), ground),
			context.rules(), ground)
	var weigh := func(def: EventDef, location: Location) -> float:
		return _weight_in(def, location, day, map, ground)
	var phase := ScriptedPhase.new(context.locations(), phase_ground, weigh)
	var rng := context.stream(1)
	for def in EventCatalogue.of_kind(GameEnums.EventKind.SCRIPTED, day, context.heat()):
		# A row sited while she walks is owed here with no position, as every such row is.
		if def.spawn_mode_on(day) != EventDef.SpawnMode.MAP:
			events.add(EventPlan.new(def, Vector2.INF))
			continue
		phase.place(def.for_day(day), rng)

## How strongly `def`'s dawn phase draws `location`: how many times the day's ground offers the row,
## placed for its role, each tile of the location it may stand on
## (`RowGround.offers_for_role()`, whose role weights keep a wall off the route and draw friction
## onto it), summed; 0 where it may stand on none.
static func _weight_in(def: EventDef, location: Location, day: int, map: CityMap,
		ground: RowGround) -> float:
	var by_tile := ground.offers_for_role(def, role_for(def, day))
	var weight := 0
	var rect := location.tiles()
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var tile := Vector2i(x, y)
			if by_tile.has(tile) and location.takes(map.tile_at(tile)):
				weight += int(by_tile[tile])
	return float(weight)

static func _place_one_shots(context: DawnContext) -> void:
	var day := context.day()
	var events := context.events()
	var consumed := context.spent_one_shots()
	# **A one-shot is owed to her walk, never rolled for.** Every one-shot is sited from her walk
	# (`EventDef.validate()` refuses one that is not): it is the day's authored beat and has to
	# happen whichever way she goes, so the plan is made here, at dawn, and only its *position* is
	# left for `EventDirector.site_what_is_on_her_way()` to choose, the same split an
	# `AHEAD_OF_PLAYER` row is owed and sited under.
	for def in EventCatalogue.of_kind(GameEnums.EventKind.ONE_SHOT, day, context.heat()):
		if def.id in consumed:
			continue
		var owed := EventPlan.new(def, Vector2.INF)
		owed.role = role_for(def, day)
		events.add(owed)
		# **And it is not consumed here.** It has no position yet, so planning it promises nothing.
		# It is spent where it becomes real instead — `EventStreaming.stream_in()`. What that buys is
		# the retry: *"what the run has spent stays spent ... a fire that burnt a block down did
		# happen"* (`RunCalendar.finish_day`), and a fire that was never lit did not, so a lost day 3
		# is offered it again.
		context.note("roll", "one-shot %s: owed to her walk, sited when her heading is clear"
				% def.id)

# ------------------------------------------------- a placement made after dawn ---

## The day's own placement context, kept past dawn so that a row the day left for her walk to site
## is placed against exactly the ground, corridor, doors and protected calm every other placement
## was stated against.
##
## **Why a placement can be made after dawn at all.** Every guarantee in this file is stated over a
## *day* and decided in `build_day` — and that is untouched here: the row is planned at dawn, its
## role is decided at dawn, and what it may stand on was decided at dawn. Only *which* of those
## tiles it takes waits, because on day 3 the fire has to be on the way she actually goes and
## nothing at dawn knows which way that is. See `EventDef.on_her_way`.
##
## **Nothing placed while she walks is asked whether she can still get away.** The day's safe routes
## are fixed before the day starts, and nothing placed during the walk may close one, so there is
## nothing to check live (inbox #1173: "there should be no live reachability check. that's a hard
## no"). What is sited here is what the day's own placement rules (`EventScheduler._best_of()`)
## accept and no more: the fire, which has no body (PLAYTEST-144 12), the poster crews, the places
## her route's bag hands her walk, and day 11's mast. Day 13's task roadblock is one the day placed
## (`ResistanceDirector._place_the_roadblock_near()`), never one sited here.
class WalkSiting extends RefCounted:
	var _day: int
	var _map: CityMap
	## Builds each candidate the siting judges (`PlanBuilder`), handed in by whoever builds the siting.
	var _builder: PlanBuilder
	## The day's routes themselves, not only the corridor made of them: a siting on the branch she
	## is walking needs the ordered chain of cells. See `_the_way_she_is_going()`.
	var _tree: RouteTree
	var _corridor: Corridor
	var _leave_alone: Array[Rect2]
	## The walk's events: its plans, its doors and its calm areas (`WalkEvents`).
	var _walk: WalkEvents
	## The walk's ground for a row (`RowGround`), handed in by whoever builds the siting: the day's
	## own, as dawn derived it, so what is sited while she walks stands on the ground the day was
	## planned on, under the same home-street rule, and scans nothing dawn already scanned.
	var _ground: RowGround
	## A row that pastes a front -> the tiles of its ground that are fronts
	## (`_ground_as_a_set()`), worked out once a row.
	var _front_ground := {}

	## Why attempts placed nothing, as `reason -> how many attempts ended that way`. Nothing in the
	## game reads it: it is what lets `tests/probes/m179_fire_on_her_way.gd` report *what* a long wait
	## was made of, which is the difference between a branch with no frontage on it and a day whose
	## every site breaks a placement rule.
	var waits := {}
	## How many sitings had to widen past the band to the end of her branch, for the same probe.
	var widened := 0
	## The sidewalk tiles in front of a blank ground-floor cell, as a set — `PosterWalls.fronts()`,
	## handed over by `EventManager` from the city it belongs to. What a row whose `OnHerWay.at_a_front` is set
	## may stand on; empty, and so nowhere, for a rig with no city.
	var fronts := {}

	## `tree` is the day's corridor tree and `walk` the walk's events (`WalkEvents`): its plans, which
	## every placement is spaced and checked against, where today's doors stand and the day's calm
	## areas, whose unused ground is the calm nothing is placed near (`CalmAreas.unused_ground()`).
	## The tree is taken rather than the finished `Corridor` so this stays the one place that turns
	## it into the other. **The tree itself is kept as well as the corridor it makes**: the corridor
	## answers *how far off the routes is this tile*, and what a siting on her own branch needs is the
	## ordered chain of cells a route actually runs along.
	##
	## `verdicts` is where its placements keep the verdicts of the candidates they judge
	## (`EventScheduler.Verdicts`), handed in by whoever builds the siting. Every owner in the game
	## hands each siting a store of its own: verdicts are kept under a candidate's key and judged
	## against one siting's plans and route tree, so a siting asked while another is in a look would
	## read verdicts judged for the other's plans and place wrongly, not only lose a cache. `builder`
	## builds each candidate at a tile.
	##
	## `ground` is the walk's ground for a row (`RowGround`): the day's, which dawn made and handed
	## on with the walk (`WalkEvents.ground()`). **Whether the home's streets are the walk's is the
	## ground's** (`DaySpec.holds_the_home_streets`): nothing sited after dawn stands on the street
	## her front door opens onto, as nothing at dawn does, because both ask the one ground.
	## **A null ground is allowed only for a caller that asks `cells_ahead()` and `cell_centre()`
	## alone**, where she is going and never which tiles a row may stand on (the happenings,
	## `ResistanceHappenings`, on a walk no dawn planned): the first row question (`ahead_of()`, `prepare()`,
	## `off_her_path()`) is a call on null.
	func _init(for_day: int, map: CityMap, tree: RouteTree, walk: WalkEvents,
			verdicts: EventScheduler.Verdicts, builder: PlanBuilder, ground: RowGround) -> void:
		_day = for_day
		_map = map
		_builder = builder
		_ground = ground
		_tree = tree if tree else RouteTree.for_day(map, for_day)
		_corridor = Corridor.of(_tree)
		_walk = walk
		_leave_alone = walk.calm().unused_ground() if walk.calm() else ([] as Array[Rect2])
		_verdicts = verdicts

	## A placement for `def` on a tile of its own ground **on the branch of the day's route tree she
	## is walking** — whatever `_ground_as_a_set()` offers the row: a building face for day 3's fire
	## and the poster crews, a sidewalk for a man shouting, a mast's site for a mast — between
	## `near` and `far` pixels ahead of her measured *along that route*, or `null` when there is
	## nothing legal there — which is a retry as she walks and never a placement made anyway.
	##
	## **The path is the day's route tree, and a place off it is never a site.** *(PLAYTEST-119:
	## "the fire needs to spawn on the current path the player is on — moving it around works but
	## valid spawn locations are only on the path".)* A straight line from her is the wrong measure
	## twice over: it offers tiles on streets her route never reaches, and it prices a tile round
	## the corner as nearer than it is to walk to. So the window is walked cell by cell down the
	## route, through its corners and its junctions, and only the tiles of the row's ground on those
	## cells are offered. A wall by its fit alone (day 7's route van) and a man shouting a bag hands
	## her (day 6's rigged one) are sited on the street she is walking instead, just out of her sight
	## (`ahead_on_her_street()`).
	##
	## **The far end is read along the route and the near end is a straight line**, and they are two
	## different questions rather than one measured twice. Far is how much more walking there is
	## before she sees it, which is what the route says. Near is whether it is in the world at all,
	## which is the streaming radius and therefore a distance across the block: a site 1200px along a
	## route that doubles back can be 500px from her, streamed in — and so real, and unmovable — on
	## the frame it was placed. A straight line is never longer than the route to the same place, so
	## clearing the streaming band clears the near end of the band along the route as well.
	##
	## **At a fork, either way out is a site.** Every route through the cell she is standing on is
	## walked, so before she commits both are on offer; once she has taken one, her own cell carries
	## only that one and `EventDirector._is_no_longer_on_her_way()` moves an unseen fire off the other.
	##
	## **A window with none of the row's ground in it widens along the same branch before anything
	## else is considered** — to the end of the route rather than off the tree — because "further
	## along the way she is going" is still the way she is going, and the alternative on a short
	## branch is a fire that waits all day. Nothing else about the candidate bends.
	##
	## `besides` is the plan being sited, if it is one of the walk's: everything else the walk has
	## planned is what the site is spaced and checked against (`WalkEvents.everything_but()`). **The
	## plan being sited is never among them** — a row being moved off a position it has not yet been
	## seen at must not be spaced against its own old body, or the second siting is refused the
	## street the first one was standing in.
	func ahead_of(def: EventDef, rng: RandomNumberGenerator, besides: EventPlan,
			at: Vector2, heading: Vector2, near: float, far: float) -> EventPlan:
		var role := EventScheduler.role_for(def, _day)
		# A wall by its fit alone is never put on a sidewalk a route runs along, so it is put on the
		# street she is walking instead, just out of her sight (`ahead_on_her_street()`).
		if (role == GameEnums.BlockerRole.WALL and not EventScheduler._is_a_wall_by_cost(def)) \
				or def.id == _MET_ON_HER_STREET:
			return ahead_on_her_street(def, rng, besides, at, heading)
		var offer := _offer_ahead(def, at, heading, near, far)
		match offer[0]:
			_OFF_THE_ROUTES:
				return _waited("she is off the day's routes")
			_NONE_ON_THE_BRANCH:
				return _waited("no tile of its ground on the branch ahead of her")
			_WIDENED:
				widened += 1
		var offered: Array[Vector2i] = offer[1]
		var already := _walk.everything_but(besides)
		var candidate := EventScheduler._best_of(def, rng, _map, _builder, offered, role, already,
				_leave_alone, _corridor, _walk.doors(), [], _verdicts_for_an_ask())
		if not candidate:
			return _waited("every tile of its ground on her branch broke a placement rule")
		# A crew faces the wall it pastes, its back to the street. `PlanBuilder.build()` turned it by
		# the dawn's own side, out of a wall it was never going to stand at.
		if def.on_her_way != null and def.on_her_way.at_a_front:
			candidate.facing = Vector2.UP
		return candidate

	## **Starts a look: from here every `ahead_of()` keeps its verdicts for the rest of the look**,
	## so a candidate judged for one copy is not judged again for the next. The director asks about
	## every copy still owed, from one place, against the same plans, and the day's rules
	## (`StreetInvalidation`) read only what of those plans is standing — every rule passes over
	## a plan that is not placed — so the same row, role, tile and path get the same verdict for
	## every copy, and every roll still happens. **The caller drops the verdicts the moment that
	## stops being true** (`forget_the_verdicts()`): when it places or moves a plan, and around asking
	## about a plan that is already placed, which is judged without its own body where every other
	## ask counts it. `end_look()` drops them too, so nothing is carried into the next look, by when
	## the world has moved on.
	func begin_look() -> void:
		_verdicts.forget()
		_in_a_look = true

	## The kept verdicts are no longer what a fresh judgement would say. See `begin_look()`.
	func forget_the_verdicts() -> void:
		if _in_a_look:
			_verdicts.forget()

	## Ends a look; `ahead_of()` keeps nothing past its own call again.
	func end_look() -> void:
		_verdicts.forget()
		_in_a_look = false

	## Where every placement this siting makes keeps its verdicts, handed in when it was built. See
	## `_init()`.
	var _verdicts: EventScheduler.Verdicts
	## Whether a look is under way, and so whether `ahead_of()` keeps its verdicts for the next ask.
	var _in_a_look := false

	## The verdicts an ask hands `EventScheduler._best_of()`: inside a look, the look's for an ask of
	## the look (`ahead_of()`); otherwise none kept from an earlier ask, as if the call kept its own.
	func _verdicts_for_an_ask(of_the_look := true) -> EventScheduler.Verdicts:
		if not (of_the_look and _in_a_look):
			_verdicts.forget()
		return _verdicts

	## What `ahead_of()` is offered, as `[how it was found, the tiles]`: the row's ground in the band
	## ahead of her on her branch, or, with none there, widened along the same branch — twice the
	## band first, then the whole of the route she is on. Stepped rather than straight to the end,
	## because the widening is for "a little further along the way she is going" and `_best_of`
	## takes the roomiest of what it is offered — handed the whole branch it picks the emptiest
	## street on it, which is the far end of a walk she has not decided to take yet.
	##
	## **Worked out once per look, not once per copy.** It draws nothing from any stream and reads
	## only the day's tree and the row's ground, so the answer for the same ground, the same place,
	## heading and band is the same answer: the director asks it of every crew still owed in one look,
	## from one place, and the last question asked is kept and given back.
	func _offer_ahead(def: EventDef, at: Vector2, heading: Vector2, near: float,
			far: float) -> Array:
		var at_a_front := def.on_her_way != null and def.on_her_way.at_a_front
		var side := EventDef.Pavement.AT_THE_FRONT if at_a_front else def.pavement_side
		var question := [def.placement, side, def.role == EventDef.Role.MAST, at, heading, near, far]
		if question == _last_offer_question:
			return _last_offer
		offers_worked_out += 1
		var nothing: Array[Vector2i] = []
		var answer := [_OFF_THE_ROUTES, nothing]
		var ahead := _the_way_she_is_going(at, heading, far)
		if not ahead.is_empty():
			var offered := _its_ground_on(def, ahead, at, near, far)
			answer = [_IN_THE_BAND, offered]
			if offered.is_empty():
				answer = [_NONE_ON_THE_BRANCH, offered]
				for wider in [far * 2.0, INF]:
					ahead = _the_way_she_is_going(at, heading, wider)
					offered = _its_ground_on(def, ahead, at, near, wider)
					if not offered.is_empty():
						answer = [_WIDENED, offered]
						break
		_last_offer_question = question
		_last_offer = answer
		return answer

	## How `_offer_ahead()` found what it offers.
	const _IN_THE_BAND := 0
	const _WIDENED := 1
	const _NONE_ON_THE_BRANCH := 2
	const _OFF_THE_ROUTES := 3
	## The last question `_offer_ahead()` answered, and its answer.
	var _last_offer_question := []
	var _last_offer := []
	## How many times `_offer_ahead()` has worked an offer out rather than given the last one back.
	## For `tests/test_siting_judges_once.gd`; nothing in the game reads it.
	var offers_worked_out := 0

	## **`ahead_of()` for a wall by its fit alone** — a row whose body leaves no line past it on the
	## sidewalk it stands on: day 7's second van (`ResistanceDirector._rig_her_route_for()`). Its
	## marble is drawn so she meets it *(olive-koala, statement 2: "that way we can control what the
	## player sees on their route")*, and a van is never put on a sidewalk a route runs along
	## (`RouteSidewalkRule._leaves_the_routes_sidewalk_open()`: "the far side of a street answers a van, and nothing
	## answers a van on the side the route is drawn down"), so the branch-and-band siting the other
	## places take would put it where her walk does not go: across a route she has often left, and a
	## band she rarely walks to the end of.
	##
	## **So it is put on the street she is walking, just out of her sight ahead of her**: the ground
	## it may stand on within `_STREET_HALF_WIDTH` either side of her line of travel, ahead of her
	## with the whole of what it draws past the edge of the camera's view, its lead included
	## (`could_be_in_her_view()`), and within `Tuning.EVENT_STREAM_RADIUS`, nearest first, under
	## every acceptance rule `ahead_of()` applies. Inside the streaming radius it is in the world at once, where she will see
	## it in a few seconds if she keeps walking that way, and like anything in the world it is not
	## moved again. `near` and `far`, the director's band for a place it may still move, are not read.
	## *(Proposed, not asked for: "on her route" read as the street she is walking.)*
	func ahead_on_her_street(def: EventDef, rng: RandomNumberGenerator, besides: EventPlan,
			at: Vector2, heading: Vector2) -> EventPlan:
		var role := EventScheduler.role_for(def, _day)
		if heading.length_squared() < 0.5:
			return _waited("she is not walking anywhere")
		var pool := _ground_as_a_set(def)
		var by_distance := {}
		var centre := _map.world_to_tile(at)
		var reach := ceili(Tuning.EVENT_STREAM_RADIUS / Tuning.TILE_SIZE)
		for dy in range(-reach, reach + 1):
			for dx in range(-reach, reach + 1):
				var tile := centre + Vector2i(dx, dy)
				if not pool.has(tile):
					continue
				var offset := _map.tile_to_world(tile) - at
				var along := offset.dot(heading)
				if along <= 0.0 or offset.length() > Tuning.EVENT_STREAM_RADIUS \
						or absf(offset.cross(heading)) > _STREET_HALF_WIDTH:
					continue
				# Out of her view, the whole of what it draws: a thing created at once is placed past
				# the view's own edge (`Offscreen.boundary()`'s rule).
				if could_be_in_her_view(def, _map.tile_to_world(tile), at):
					continue
				var band := int(along / Tuning.TILE_SIZE)
				if not by_distance.has(band):
					by_distance[band] = []
				(by_distance[band] as Array).append(tile)
		if by_distance.is_empty():
			return _waited("no ground ahead of her on the street she is walking")
		var bands := by_distance.keys()
		bands.sort()
		var already := _walk.everything_but(besides)
		# Nearest first: a few tiles of the street at a time, so she meets it as soon as she can.
		var offered: Array[Vector2i] = []
		for band: int in bands:
			offered.append_array(by_distance[band])
			if offered.size() < _NEAREST_FIRST:
				continue
			var candidate := _accepted(def, rng, already, offered, role)
			if candidate:
				return candidate
			offered.clear()
		if not offered.is_empty():
			var candidate := _accepted(def, rng, already, offered, role)
			if candidate:
				return candidate
		return _waited("every site ahead of her on her street broke a placement rule")

	## Whether any of what `def` draws, standing at `feet`, could be in the camera's view while she
	## stands at `her`: its footprint where it is drawn (`EventFootprints.footprint_of()`, a van's
	## reaching 56.5px up from its feet and 28.5px down) against the 640x360 view round her
	## (`Tuning.VIEW_HALF_EXTENT`), grown on every side by the camera's lead
	## (`Stroller.CAMERA_LOOK_AHEAD` along her facing, `Stroller.OBLIQUE_Y` of it up or down), since
	## the lead eases toward a new facing over a turn, and by a tile to spare.
	static func could_be_in_her_view(def: EventDef, feet: Vector2, her: Vector2) -> bool:
		var box := EventFootprints.footprint_of(def)
		var drawn := Rect2(feet + box.position, box.size) if box.has_area() \
				else Rect2(feet, Vector2.ZERO)
		var lead := Vector2(Stroller.CAMERA_LOOK_AHEAD,
				Stroller.CAMERA_LOOK_AHEAD * Stroller.OBLIQUE_Y) + Vector2.ONE * Tuning.TILE_SIZE
		var view := Rect2(her - Tuning.VIEW_HALF_EXTENT - lead,
				(Tuning.VIEW_HALF_EXTENT + lead) * 2.0)
		return view.intersects(drawn, true)

	## **Day 6's man shouting is sited the same way**, though he is no wall: the rigged bag draws his
	## marble so she meets him (olive-koala, statement 2: "guaranteed to encounter a yeller in the
	## next three events"), and the route band of the branch she is walking lies past her walk — a
	## branch she leaves, or 1,300px and more ahead — where the street she is on offers him within the
	## streaming radius, in the world at once.
	const _MET_ON_HER_STREET := "homeless_yeller"
	## How far either side of her line of travel `ahead_on_her_street()` looks: the street she is on,
	## from her sidewalk to the far kerb, and no further — a block's frontage is past it.
	const _STREET_HALF_WIDTH := 5.0 * Tuning.TILE_SIZE
	## How many tiles of ground `ahead_on_her_street()` offers `_best_of()` at a time, nearest first.
	const _NEAREST_FIRST := 8

	## `_best_of()` over `offered` with the day's own ground, corridor, protected calm and doors: the
	## acceptance `ahead_of()` gives a site.
	func _accepted(def: EventDef, rng: RandomNumberGenerator, already: Array[EventPlan],
			offered: Array[Vector2i], role: GameEnums.BlockerRole) -> EventPlan:
		return EventScheduler._best_of(def, rng, _map, _builder, offered, role, already,
				_leave_alone, _corridor, _walk.doors(), [], _verdicts_for_an_ask())

	## A placement for `def` among `offered`, by `EventScheduler._best_of()` against the walk's plans
	## with the day's own ground, corridor, protected calm and doors — the acceptance every row the day plans
	## gets, over a pool the caller chose: day 11's mast queued near her
	## (`EventManager.queue_a_mast()`). Null when nothing offered passes. `null` rather than the
	## roomiest of a refused pool: `_best_of()` already answers with nothing for a pool where every
	## tile is illegal, and with the roomiest only among legal ones.
	func among(def: EventDef, rng: RandomNumberGenerator, offered: Array[Vector2i]) -> EventPlan:
		if offered.is_empty():
			return null
		return EventScheduler._best_of(def, rng, _map, _builder, offered,
				EventScheduler.role_for(def, _day), _walk.everything_but(), _leave_alone, _corridor,
				_walk.doors(), [], _verdicts_for_an_ask(false))

	## How far from where she finished the day a dusk placement has to be: the streaming radius, so
	## the site is ground she was never near enough to have it exist in front of her.
	const DUSK_CLEAR_OF_HER := Tuning.EVENT_STREAM_RADIUS

	## A placement for `def` **away from her and off the day's routes**, for the one case a walk can
	## end without the guarantee having been met: a day 3 she wins on which every siting was refused.
	##
	## *"I agree with the fire fix"* (PLAYTEST-121). The row's only day is day 3 and it is spent when
	## it enters the world, so a day she wins while it waited would leave the run with no fire, no
	## scar and no burnt shell — and the shell is what day 8's task goes to, and what the city
	## remembering day 3 is made of. So the day lights it at dusk instead.
	##
	## **The same acceptance rules, chosen once, nothing repaired.** It is `_best_of` over the day's
	## own ground with the day's own corridor, doors and protected calm. It is lit and taken out of
	## the world again at once, so nothing it leaves stands in anybody's way.
	##
	## **Off her path** means both halves of what that can mean: not within `DUSK_CLEAR_OF_HER` of
	## where she finished, so nothing is lit where she could have seen it, and not on ground the
	## day's routes run along, so the street she actually walked is not the one that burns. The
	## second bends and the first does not — the fallback is a site merely away from her: a run that
	## owes a fire and has nowhere ideal to put it should still have its fire.
	func off_her_path(def: EventDef, rng: RandomNumberGenerator, besides: EventPlan,
			away_from: Vector2) -> EventPlan:
		var role := EventScheduler.role_for(def, _day)
		var clear_of_the_routes: Array[Vector2i] = []
		var merely_away: Array[Vector2i] = []
		for tile in _ground.tiles_for(def):
			if _map.tile_to_world(tile).distance_to(away_from) < DUSK_CLEAR_OF_HER:
				continue
			merely_away.append(tile)
			if not _corridor.carries_a_route(tile):
				clear_of_the_routes.append(tile)
		var already := _walk.everything_but(besides)
		for offered in [clear_of_the_routes, merely_away]:
			if offered.is_empty():
				continue
			var candidate := EventScheduler._best_of(def, rng, _map, _builder, offered, role,
					already, _leave_alone, _corridor, _walk.doors(), [], _verdicts_for_an_ask(false))
			if candidate:
				return candidate
		return null

	## Every cell of the day's route tree ahead of her along the branch she is walking, as
	## `cell -> how far she walks down the route to reach it`, out to `limit` pixels —
	## `_the_way_she_is_going()`, for a caller that sites something other than a catalogue row on her
	## way: day 11's market, gone before she gets there (`ResistanceHappenings`). `cell_centre()`
	## says where a cell is.
	func cells_ahead(at: Vector2, heading: Vector2, limit: float) -> Dictionary:
		return _the_way_she_is_going(at, heading, limit)

	## The world centre of a route cell `cells_ahead()` names.
	func cell_centre(cell: Vector2i) -> Vector2:
		return _cell_centre(_map, cell)

	## Records why an attempt placed nothing and answers with the nothing. See `waits`.
	func _waited(reason: String) -> EventPlan:
		waits[reason] = int(waits.get(reason, 0)) + 1
		return null

	## Whether `position` is still somewhere ahead of her along the branch she is walking — the
	## question `EventDirector._is_no_longer_on_her_way()` asks of a placement already made, once a
	## second, to find the fire she left behind on a fork she did not take.
	##
	## **Ahead by any distance, not inside the siting band.** She is walking toward it, so the
	## distance shrinks with every step; asking the band again would move a fire she is about to
	## reach.
	##
	## **True when the answer cannot be had.** Off the tree — a park cut, an alley, a thinned seal —
	## there is no branch to be ahead on, and the honest answer there is to leave the placement alone
	## rather than to re-site it for a corner she is cutting.
	func still_ahead_of(at: Vector2, heading: Vector2, position: Vector2) -> bool:
		var ahead := _the_way_she_is_going(at, heading, INF)
		if ahead.is_empty():
			return true
		return ahead.has(_cell_of(position))

	## Every cell of the day's route tree that lies ahead of `at` along the branch she is walking, as
	## `cell -> how far she walks down the route to reach it`, out to `limit` pixels.
	##
	## Empty when she is not standing on the tree at all, which is a real answer rather than a
	## failure: a route is the ground she is offered, and she is allowed to be off it.
	##
	## **Which way is "ahead" is read off her heading against the route itself**, not assumed to be
	## outbound. A route runs from the calm area to the doorstep (`RouteTree.Branch.routes`), so the
	## walk out is toward the head of the array and the walk home is toward its tail, and the one that
	## agrees with the direction she is actually travelling is the one taken. At a corner both
	## neighbours can be off her heading; the better of the two is still the way the route goes, which
	## is what puts the site round the corner she is about to turn.
	func _the_way_she_is_going(at: Vector2, heading: Vector2, limit: float) -> Dictionary:
		var found := {}
		if not _tree or not _tree.grid:
			return found
		var her_tile := _map.world_to_tile(at)
		if _tree.branches_on(her_tile).is_empty():
			return found
		var her_cell := _tree.grid.cell_of(_tree.grid.node_at(her_tile))
		for branch in _tree.branches:
			for route: Array in branch.routes:
				var index := route.find(her_cell)
				if index < 0:
					continue
				var step := _onward_from(route, index, heading)
				if step == 0:
					continue
				var travelled := 0.0
				var from := at
				var i := index + step
				while i >= 0 and i < route.size():
					var cell: Vector2i = route[i]
					var centre := _cell_centre(_map, cell)
					travelled += from.distance_to(centre)
					if travelled > limit:
						break
					from = centre
					if not found.has(cell) or travelled < float(found[cell]):
						found[cell] = travelled
					i += step
		return found

	## Which way along `route` from `index` agrees with the direction she is travelling: `-1` toward
	## the calm area, `+1` toward the doorstep, or `0` where the route has no neighbour to go to at
	## all (a route one cell long, which is a calm area on the doorstep's own street).
	##
	## **Asked over `_ONWARD_LOOKAHEAD` cells rather than the next one**, because a route is a
	## loop-erased walk and its next step is as often sideways as onward: a single-cell tangent flips
	## from one direction to the other at every wiggle, so a placement would read as ahead of her on
	## one frame and behind her on the next. Looking a block down each way asks the question the
	## walk is actually about — which end of this route is she heading for.
	const _ONWARD_LOOKAHEAD := 8

	func _onward_from(route: Array, index: int, heading: Vector2) -> int:
		var here := _cell_centre(_map, route[index])
		var step := 0
		var best := -INF
		for candidate in [-1, 1]:
			var i: int = clampi(index + candidate * _ONWARD_LOOKAHEAD, 0, route.size() - 1)
			if i == index or (i - index) * candidate < 0:
				continue
			var toward: Vector2 = _cell_centre(_map, route[i]) - here
			if toward.length_squared() < 1.0:
				continue
			var score := toward.normalized().dot(heading)
			if score > best:
				best = score
				step = candidate
		return step

	## The tiles `def` may stand on that are on one of `ahead`'s cells, no more than `far` down the
	## route from her and no less than `near` away across the block — see `ahead_of()` for why the
	## two ends of the band are measured differently.
	##
	## The cells are asked for their tiles rather than the ground pool being scanned for its cells,
	## which is what keeps a refused attempt off the frame budget: a window is a few dozen cells and
	## the pool is every sidewalk in the city.
	func _its_ground_on(def: EventDef, ahead: Dictionary, at: Vector2, near: float,
			far: float) -> Array[Vector2i]:
		var pool := _ground_as_a_set(def)
		var a_mast := def.role == EventDef.Role.MAST
		var offered: Array[Vector2i] = []
		for cell: Vector2i in ahead:
			if float(ahead[cell]) > far:
				continue
			for dy in ReachabilityGrid.CELL:
				for dx in ReachabilityGrid.CELL:
					var tile: Vector2i = cell * ReachabilityGrid.CELL + Vector2i(dx, dy)
					if not pool.has(tile):
						continue
					# **A cell is not always one piece.** `ReachabilityGrid` splits a cell into a
					# node per connected component of it, and a route carries nodes — so a cell the
					# route runs through can hold a second node, on the other side of a wall, that
					# the route never touches. The tree's own answer for the tile is what decides.
					if _tree.branches_on(tile).is_empty():
						continue
					if _map.tile_to_world(tile).distance_to(at) < near:
						continue
					if a_mast and not _a_mast_may_stand(tile):
						continue
					offered.append(tile)
		return offered

	## **A mast is offered only ground a mast site would be** (`MastSites.is_eligible()`: off the
	## home street, its field off a calm interior and off every place a region door could stand),
	## the same refusal day 11's mast near the mark is under — a mast is never on the home street
	## (M180, the masts), whichever way it is put down. Asked only of the tiles `_its_ground_on()`
	## offers, never of the whole ground: over every sidewalk and square in the city it is seconds
	## of work on the frame she reads day 11's mark. Each tile's answer is kept, and the door points
	## it measures against are computed once (`MastSites.possible_door_points()`).
	func _a_mast_may_stand(tile: Vector2i) -> bool:
		if not _mast_may_stand.has(tile):
			if _door_points.is_empty():
				_door_points = MastSites.possible_door_points(_map)
			mast_checks += 1
			_mast_may_stand[tile] = MastSites.is_eligible(_map.tile_to_world(tile), _map,
					_door_points)
		return _mast_may_stand[tile]

	## Tile -> whether a mast may stand there, for `_a_mast_may_stand()`.
	var _mast_may_stand := {}
	## Where a region door could ever stand, for `_a_mast_may_stand()`; empty until first asked.
	var _door_points := PackedVector2Array()
	## How many tiles `_a_mast_may_stand()` has asked `MastSites` about. For the test that holds the
	## cost of siting a mast on her route to the tiles it was offered.
	var mast_checks := 0

	## The row's ground as a set (`RowGround.offers_for()`, read for its tiles alone), so a cell can
	## ask whether one of its four tiles is in it.
	##
	## **The precinct weighting is dropped here and that is correct rather than a shortcut.** The
	## weighting offers a retail tile several times so the day's own roll lands there more often;
	## this roll is over the handful of tiles on one branch inside one window, where which street
	## she is walking has already decided everything the weight was for.
	##
	## **A row that pastes a front is offered the fronts, not its own side.** Its ground is the
	## `AT_THE_FRONT` lane with every rule the day's ground asks of any other row, narrowed to the
	## tiles in `fronts` — in front of a blank ground-floor cell, which only the city's buildings
	## know — and nothing at all where no city handed any over.
	func _ground_as_a_set(def: EventDef) -> Dictionary:
		if def.on_her_way == null or not def.on_her_way.at_a_front:
			return _ground.offers_for(def)
		if not _front_ground.has(def):
			var found := {}
			for tile: Vector2i in _ground.offers_for(def, EventDef.Pavement.AT_THE_FRONT):
				if fronts.has(tile):
					found[tile] = true
			_front_ground[def] = found
		return _front_ground[def]

	func _cell_of(position: Vector2) -> Vector2i:
		if not _tree or not _tree.grid:
			return Vector2i(-1, -1)
		var node := _tree.grid.node_at(_map.world_to_tile(position))
		if node < 0:
			return Vector2i(-1, -1)
		return _tree.grid.cell_of(node)

	## The centre of a `ReachabilityGrid` cell in world space. A cell is two tiles square and
	## `CityMap.tile_to_world` answers the centre of a tile, so the cell's centre is half a tile
	## further along both axes than its first tile's.
	static func _cell_centre(map: CityMap, cell: Vector2i) -> Vector2:
		return map.tile_to_world(cell * ReachabilityGrid.CELL) \
				+ Vector2.ONE * (Tuning.TILE_SIZE * 0.5)

	## Does at dawn the work the first `ahead_of()` would otherwise do in the middle of a walk: the
	## scan for ground `def` may stand on and the set a cell asks about. It is a scan of the whole
	## city, which at dawn is part of a load and mid-walk is a hitch on the one beat of the day she is
	## meant to be watching. Nothing here rolls, so the day is the same day whether or not this ran.
	func prepare(def: EventDef) -> void:
		_ground_as_a_set(def)

# ------------------------------------------------- the day's locations, from the bags ---

## **Every open location of the day drawn from its view's bag** (`LocationDraw`, inbox #1185 in gentle-owl): the
## bags (`_view_bags()`) hold every recurring row the catalogue places on the map today, each as many
## times as its weight in the view (`view_weight()`), and the empty event; the day's ground answers
## which row is valid where and how much each location weighs it (`RuledLocationGround`). The rows
## other phases place have no marble: the moments she is owed (`_owe_the_moments()`), and on the day
## of the roadblock phase its row (`DawnContext.roadblock_row()`), the phase's alone. The draw
## places into the context's plan.
static func _draw_the_locations(context: DawnContext) -> void:
	var day := context.day()
	var spec := context.spec()
	var base := context.day_seed()
	var map := context.map()
	var beside_the_routes := context.roadblock_row()
	var rows := {}
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day, context.heat()):
		if def.spawn_mode_on(day) != EventDef.SpawnMode.MAP:
			continue
		if beside_the_routes != null and def.id == beside_the_routes.id:
			continue
		rows[def.id] = def.for_day(day)
	var bags := _view_bags(rows, day, spec, base)
	var judged := RuledLocationGround.new(day, base, map, context.events(), context.corridor(),
			LocationFit.new(day, map, context.builder(), context.ground()), context.rules(),
			context.ground())
	var caps := _caps_of(rows, day, spec, context.stream(CAPS_SALT)) if spec.caps_per_day else {}
	LocationDraw.new(context.locations(), bags, rows, judged, caps).draw_all(
			context.stream(LOCATIONS_SALT))

## **How many of each row the day's draw may stand** (`id -> count`): its `EventDef.max_per_day`,
## and a wall-role row's times `DaySpec.wall_row_share`, so the gatehouse day holds that share of a
## wall whose cap binds as well as of one whose weight does (`view_weight()` scales the weight). A
## share of a cap that is not whole is rounded up or down on `rng`, by its fraction, so the day
## holds the share on average.
static func _caps_of(rows: Dictionary, day: int, spec: DaySpec,
		rng: RandomNumberGenerator) -> Dictionary:
	var caps := {}
	var ids := rows.keys()
	ids.sort()
	for id: String in ids:
		var def: EventDef = rows[id]
		var most := float(def.most_in_a_day())
		if role_for(def, day) == GameEnums.BlockerRole.WALL:
			most *= spec.wall_row_share
		caps[id] = floori(most) + (1 if rng.randf() < most - floorf(most) else 0)
	return caps

## The phase salt the dawn draw shuffles each street's locations on, and the bags' streams start
## from: apart from every other phase's.
const LOCATIONS_SALT := 6
## The phase salt the moments she is owed are drawn on.
const MOMENTS_SALT := 7
## The phase salt a share of a wall's cap is rounded on (`_caps_of()`).
const CAPS_SALT := 8

## **A row's weight in a view's bag**: its own `EventDef.weight` times what the view is to its role,
## the offers today's placement made per tile of the view's ground (`RowGround._times_for_role()`'s gradient),
## stated per view (inbox #1185 in gentle-owl: "all possible events for that view multiplied by their
## probability/weight"):
##
## - **friction** is aimed at the routes: four times over on the route, once elsewhere
##   (`EVENT_CORRIDOR_WEIGHT`);
## - **a wall by cost, not lethal**, is pulled to the rim, four times over route-adjacent and on the
##   route, where it stands only on the sidewalk across from the route (its own ground refuses the
##   route's cells), once off the route (`EVENT_WALL_RIM_WEIGHT`);
## - **a lethal wall** is pulled past the rim: four times over off the route, once nearer
##   (`WALL_DEEP_WEIGHT`);
## - **a wall by its fit alone** reads like friction;
## - **anything else** (scenery) once everywhere;
## - a row refused an alley the routes run down (`EventDef.stands_only_in_alleys()`) has no marble on the
##   route.
##
## **Every wall-role row's weight is scaled by `wall_share`** (`DaySpec.wall_row_share`), so there
## are fewer of them once the region wall stands (azure-puffin 4: "let's loosen the density of the
## hard blocking events in that case", and "fewer of all three" to a question that listed the
## wall-type events; the record bouncy-egret). `_view_bags()` counts the empty marbles against every
## wall weighed in full, so the share takes walls away rather than giving their place to the other
## rows.
##
## **Then each role is weighed per view and act**: a wall by `WALL_VIEW_SCALES`, friction by
## `FRICTION_VIEW_SCALES`, fitted so each view holds today's walls and friction.
static func view_weight(def: EventDef, view: int, day: int, wall_share: float) -> float:
	var on := view == PlacementView.View.ON_THE_ROUTE
	var off := view == PlacementView.View.OFF_THE_ROUTE
	if on and def.stands_only_in_alleys():
		return 0.0
	var times := 1.0
	var act := Tuning.act_for_day(day) - 1
	match role_for(def, day):
		GameEnums.BlockerRole.FRICTION:
			times = float(EVENT_CORRIDOR_WEIGHT) if on else 1.0
			times *= float(FRICTION_VIEW_SCALES[view][act])
		GameEnums.BlockerRole.WALL:
			if not _is_a_wall_by_cost(def):
				times = float(EVENT_CORRIDOR_WEIGHT) if on else 1.0
			elif def.hard_fail:
				times = float(WALL_DEEP_WEIGHT) if off else 1.0
			else:
				times = 1.0 if off else float(EVENT_WALL_RIM_WEIGHT)
			times *= wall_share * float(WALL_VIEW_SCALES[view][act])
		_:
			times = 1.0
	return def.drawn_as_often() * times

## **How each role weighs in each view, act by act** (`[view][act - 1]`), on top of the role's offers
## above: fitted so the walls and the friction each view holds on each act are today's
## (`tests/probes/placement_rows.gd` against main, each placed plan counted under its row's role).
## One location draws one marble, and today's rules refuse a wall on her route more often than they
## refused today's per-tile offers, so without it the walls leave her route for the ground off it:
## what her route holds is what the route decision faces. Measured, not derived, and fitted again with
## the view scales and `GROUND_WEIGHTS` whenever the draw's rules change.
const WALL_VIEW_SCALES := [
	[1.07, 1.08, 1.15, 1.14],
	[1.04, 1.01, 1.01, 1.01],
	[0.96, 0.95, 0.88, 0.89],
]
const FRICTION_VIEW_SCALES := [
	[0.96, 0.98, 1.02, 1.02],
	[1.15, 1.07, 1.11, 1.04],
	[1.03, 1.06, 1.03, 1.03],
]

## **The day's three bags** (`view -> ViewBag`): each view's rows as many times as their weight in it
## (`view_weight()`, `BAG_MARBLES_PER_WEIGHT` marbles per unit, at least one of a row the view holds),
## and empty marbles enough that the view's share of locations holding an event is the share today's
## placement gave it (`VIEW_SHARES`, measured, times `VIEW_SHARE_SCALES`, fitted; the orchestrator's
## reading of fork 5(a), open to correction). The empty marbles are counted against every wall
## weighed in full, so a spec weighing its walls by a share (`DaySpec.wall_row_share`) draws that
## share of them and the rest of the day as it was; the scales are fitted on the days as they are
## played, the gatehouse day's share included. Each on its own stream off `base`.
static func _view_bags(rows: Dictionary, day: int, spec: DaySpec, base: int) -> Dictionary:
	var bags := {}
	for view: int in [PlacementView.View.ON_THE_ROUTE, PlacementView.View.ROUTE_ADJACENT,
			PlacementView.View.OFF_THE_ROUTE]:
		var fill := {}
		var weight := 0.0
		var whole := 0.0
		for id: String in rows:
			var w := view_weight(rows[id], view, day, spec.wall_row_share)
			whole += view_weight(rows[id], view, day, 1.0)
			if w <= 0.0:
				continue
			fill[id] = maxi(1, roundi(w * BAG_MARBLES_PER_WEIGHT))
			weight += w
		var share := clampf(float(VIEW_SHARES[view][clampi(day, 1, 14) - 1])
				* float(VIEW_SHARE_SCALES[view][clampi(day, 1, 14) - 1]), 0.001, 0.95)
		fill[ViewBag.EMPTY] = maxi(1, roundi((whole / share - weight) * BAG_MARBLES_PER_WEIGHT))
		bags[view] = ViewBag.new(fill, hash("%d:%d:view-bag:%d" % [base, LOCATIONS_SALT, view]))
	return bags

## Marbles per unit of a row's weight in a view's bag: ten, so the lightest row (the square's poster
## crew, 0.03) comes in at a marble where the others keep their proportions.
const BAG_MARBLES_PER_WEIGHT := 10.0

## **Each view's share of locations holding an event, per day** (`[view][day - 1]`), as today's
## placement gave it before the bags: `tests/probes/placement_view_mix.gd`'s per-view lines on its
## eighteen cities, main's events per view over the locations the probe counts (the orchestrator's
## reading of fork 5(a): the empty marble's weight is set from today's measured count).
const ON_SHARES: Array[float] = [0.0334, 0.0313, 0.0298, 0.0353, 0.0382, 0.0387, 0.0452, 0.0464, 0.0375, 0.0417, 0.0437, 0.0422, 0.0461, 0.0461]
const ADJACENT_SHARES: Array[float] = [0.0512, 0.0537, 0.0517, 0.0566, 0.0583, 0.0631, 0.0642, 0.0618, 0.0433, 0.0420, 0.0451, 0.0463, 0.0707, 0.0485]
const OFF_SHARES: Array[float] = [0.0373, 0.0393, 0.0425, 0.0486, 0.0594, 0.0677, 0.0610, 0.0694, 0.0563, 0.0578, 0.0568, 0.0628, 0.0626, 0.0636]
const VIEW_SHARES := [
	ON_SHARES,
	ADJACENT_SHARES,
	OFF_SHARES,
]
## What each view's bag's empty marbles are set for against `VIEW_SHARES` (`[view][day - 1]`): above
## one by how many draws the view's ground or the day's rules leave without the row drawn, so the
## share placed comes out as today's. Highest on the route, where the rules keeping a route open
## refuse the most. **Per day**, since how much the rules refuse changes with the day's rows and its
## routes, and one scale for every day left the later days' routes light; what is on her route is
## what the route decision is about, so it is held at today's on each day. Fitted, not derived:
## each day's scale stepped toward today's share by `tests/probes/placement_rows.gd`, with
## `GROUND_WEIGHTS` and the walls' and friction's scales.
const ON_SHARE_SCALES: Array[float] = [4.64, 5.07, 4.91, 5.07, 5.33, 5.70, 5.12, 4.95, 6.21, 6.37, 6.54, 6.59, 7.20, 7.22]
const ADJACENT_SHARE_SCALES: Array[float] = [2.12, 2.10, 2.06, 2.07, 2.08, 2.21, 2.27, 2.26, 3.36, 3.73, 3.91, 4.03, 3.03, 4.60]
const OFF_SHARE_SCALES: Array[float] = [1.77, 1.66, 1.78, 2.06, 1.76, 1.71, 1.87, 2.08, 2.85, 2.90, 3.05, 2.91, 3.18, 3.25]
const VIEW_SHARE_SCALES := [
	ON_SHARE_SCALES,
	ADJACENT_SHARE_SCALES,
	OFF_SHARE_SCALES,
]

## **How often a row is drawn on each kind of ground** (`row id -> {Location.Kind -> weight}`),
## a weight a location of that kind scales the row's share of its view's bag by
## (`RuledLocationGround.scale()`; the player's "yes" to a group of locations per kind of ground
## and a weight per location scaling its view's bag, inbox #1185 in gentle-owl). **Why it is needed:** each
## location draws one marble, so a row whose own ground is rare (a square's few cells, an alley's
## three locations, the junction boxes) would be drawn only as often as its share of the bag times
## the few locations that take it, where today's placement picked the row by weight against the
## whole day and then found it any tile of its ground. So each row's weight on each kind of ground
## is fitted until its daily count there is today's (`tests/probes/placement_rows.gd` against main,
## eighteen seeds), the way the view scales are; a row or a kind not listed weighs one. Measured, not
## derived, and fitted again with the view scales whenever the draw's rules change.
const GROUND_WEIGHTS := {
	"abduction": {Location.Kind.SIDEWALK: 0.14, Location.Kind.JUNCTION: 91.19},
	"alley_mouse": {Location.Kind.ALLEY: 14.67},
	"alley_robbery": {Location.Kind.ALLEY: 4.46},
	"busker": {Location.Kind.OPEN: 150},
	"cafe_tables": {Location.Kind.SIDEWALK: 0.43},
	"charging_dog": {Location.Kind.SIDEWALK: 0.21, Location.Kind.OPEN: 0.78, Location.Kind.JUNCTION: 319},
	"chatting_mother": {Location.Kind.SIDEWALK: 0.25, Location.Kind.JUNCTION: 400},
	"construction": {Location.Kind.SIDEWALK: 0.49},
	"delivery_van": {Location.Kind.SIDEWALK: 1.48},
	"dog_walker": {Location.Kind.SIDEWALK: 0.82, Location.Kind.JUNCTION: 2.27},
	"homeless_yeller": {Location.Kind.SIDEWALK: 0.87, Location.Kind.OPEN: 0.57, Location.Kind.JUNCTION: 2.27},
	"ice_cream_van": {Location.Kind.SIDEWALK: 0.83},
	"leaf_blower": {Location.Kind.SIDEWALK: 0.59, Location.Kind.OPEN: 0.38, Location.Kind.JUNCTION: 1.21},
	"market_stall": {Location.Kind.SIDEWALK: 0.44, Location.Kind.OPEN: 0.34},
	"military_convoy": {Location.Kind.SECTION: 0.77, Location.Kind.JUNCTION: 1.43},
	"pigeon_flock": {Location.Kind.SIDEWALK: 0.7, Location.Kind.OPEN: 1.56, Location.Kind.JUNCTION: 6.95},
	"police_patrol": {Location.Kind.SECTION: 1.33, Location.Kind.JUNCTION: 5.54},
	"poster_crew_square": {Location.Kind.OPEN: 27.86},
	"protest": {Location.Kind.OPEN: 8.88, Location.Kind.JUNCTION: 16.89},
	"reversing_lorry": {Location.Kind.SIDEWALK: 1.46},
	"roadblock": {Location.Kind.SECTION: 2.69},
}

## A row's weight on a location of `kind` (`Location.Kind`): `GROUND_WEIGHTS`', one where it lists
## none.
static func ground_weight(def: EventDef, kind: int) -> float:
	var weights: Dictionary = GROUND_WEIGHTS.get(def.id, {})
	return float(weights.get(kind, 1.0))

## **The moments the day owes her** (`AHEAD_OF_PLAYER` and `TOWARD_PLAYER` rows, the cat that bolts
## across, the cyclist, the loose dog): sited in front of her by the director, on its own clock and
## from its own bag (`EventDirector`; the orchestrator's reading of fork 9: a moment is not a place),
## so the day only says how many. `MOMENTS_PER_DAY` of them, as today's placement bought on that day,
## each a row drawn by weight among today's, at most its `max_per_day` where the spec keeps the caps.
static func _owe_the_moments(context: DawnContext) -> void:
	var day := context.day()
	var events := context.events()
	var caps := context.spec().caps_per_day
	var rng := context.stream(MOMENTS_SALT)
	var rows: Array[EventDef] = []
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day, context.heat()):
		var mode := def.spawn_mode_on(day)
		if mode == EventDef.SpawnMode.AHEAD_OF_PLAYER or mode == EventDef.SpawnMode.TOWARD_PLAYER:
			rows.append(def)
	var owed := {}
	for _i in int(MOMENTS_PER_DAY[clampi(day, 1, 14) - 1]):
		var open: Array[EventDef] = []
		var total := 0.0
		for def in rows:
			if not caps or int(owed.get(def.id, 0)) < def.most_in_a_day():
				open.append(def)
				total += def.drawn_as_often()
		if open.is_empty():
			return
		var roll := rng.randf() * total
		var chosen: EventDef = open.back()
		for def in open:
			roll -= def.drawn_as_often()
			if roll <= 0.0:
				chosen = def
				break
		owed[chosen.id] = int(owed.get(chosen.id, 0)) + 1
		events.add(EventPlan.new(chosen, Vector2.INF))

## How many moments she is owed on each day (`[day - 1]`), as today's placement bought them before the
## bags (`tests/probes/placement_rows.gd` on main, eighteen seeds, rounded). Measured, not derived: a
## fixed count each day, where the fill's rolls made it vary from one city to the next.
const MOMENTS_PER_DAY: Array[int] = [23, 26, 29, 25, 26, 28, 29, 28, 28, 30, 31, 32, 32, 32]

## **An authored scene's row at the location its tile names**, or null with the reason appended to
## `why`. A recipe keeps its data: `at` names the tile, and so the location holding it
## (`DayLocations.holding()`, of the ground under it), which is asked once, as a dawn phase asks a
## location: the tile is one the location takes for the row (`LocationFit`), the candidate built
## there on a private stream (`route_seed`, so unrelated actors cannot move a required path), and the
## day's rules allow it (`StreetInvalidation`, the calm `calm` says she has not used left alone). No
## tries and no fallback: a location that does not take the row fails the recipe loudly, with the
## reason, rather than placing it somewhere else (the orchestrator's reading, open to the player's
## overturn). `locations` is the day's, laid out once for the whole recipe; laid out here for a
## caller that hands none. `builder` builds the candidate.
static func recipe_placement(def: EventDef, day: int, map: CityMap, builder: PlanBuilder,
		at: Vector2, route_seed: int, already: Array[EventPlan], corridor: Corridor,
		doors: PackedVector2Array, calm: CalmAreas, standing: Array[EventPlan] = [],
		locations: DayLocations = null, why: Array[String] = []) -> EventPlan:
	if not def.available_on(day) or def.spawn_mode_on(day) != EventDef.SpawnMode.MAP:
		why.append("%s is not placed on the map on day %d" % [def.id, day])
		return null
	def = def.for_day(day)
	var tile := map.world_to_tile(at)
	if not map.tile_to_world(tile).is_equal_approx(at):
		why.append("%s is not at the middle of a tile" % def.id)
		return null
	if locations == null:
		locations = DayLocations.lay_out(map, corridor if corridor else Corridor.of(null))
	var location := locations.holding(tile, map.tile_at(tile))
	if location == null:
		why.append("no location holds tile %s" % tile)
		return null
	var fit := LocationFit.new(day, map, builder, row_ground(map, corridor))
	if not tile in fit.tiles(def, location):
		why.append("the location holding tile %s does not take %s there" % [tile, def.id])
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = route_seed
	var candidate := fit.build(def, tile, rng)
	if not candidate:
		why.append("%s cannot be built on tile %s" % [def.id, tile])
		return null
	var around := already.duplicate()
	around.append_array(standing)
	var rules := StreetInvalidation.new(map, corridor, calm.unused_ground(), doors, null)
	if rules.room(candidate, role_for(def, day), tile, already, around) == -INF:
		why.append("the day's rules refuse %s on tile %s" % [def.id, tile])
		return null
	return candidate

## The acceptance half of a placement: roll `EVENT_PLACEMENT_TRIES` candidates out of
## `open_candidates`, refuse the ones that break a rule that cannot bend, and answer with the first
## perfect one or the roomiest of the rest.
##
## Its one caller is the walk's sitings (`WalkSiting`): a placement made **after** dawn asks the
## dawn's questions of a narrower pool — `WalkSiting.ahead_of()` offers only the tiles of the row's own
## ground on the branch of the day's route tree she is walking — and a second copy of this list of
## rules is a second copy that would agree with it right up to the first time one of them gained a
## rule.
##
## **`standing` is what the seals and the region wall's own bodies stand as, asked only by the
## three questions below and never by the spacing.** `SealPlanner.plan_day` and `RegionPlanner.
## plan_day` both run before `build_day`, so their bodies are never in `already` — the day's own
## catalogue accumulator — and the three placement rules were therefore refusing a *second*
## catalogue row that would close a crossing, a sidewalk or a pacing beat's opening only against
## *other catalogue rows*, blind to a seal or a wall already reaching in from one street out or
## the far pavement (`docs/DECISIONS.md`, M129, "the four rules": *"the seals `SealPlanner`
## places before the scheduler runs reach crossings the rules never see, the same question one
## step out"*). This does not change what a seal or the wall stands as — neither is in
## `standing` for any reason but these three checks — so a street already sealed by design is
## unmoved; what changes is that the catalogue now declines to stack a second body onto ground a
## seal or the wall has already spent. `StreetInvalidation.room_around`'s own spacing stays asked of `already`
## alone: density is a question about today's catalogue rows, not about the day's fixed
## furniture. **A `WalkSiting` passes none** — it is spaced and checked against the walk's whole plan
## (`WalkEvents.everything_but()`), seals and the wall included, as its own `already`, so it
## already asks every question `standing` exists to add here.
##
## **Each candidate is asked of the day's rules** (`StreetInvalidation`), the same ones the dawn draw
## asks, so they are stated once; the tries and the roomiest fallback are this function's own, kept
## for its one caller, the walk's sitings (`WalkSiting`), until the walk's draws move it to the
## locations (the orchestrator's choice in placement step 3b).
static func _best_of(def: EventDef, rng: RandomNumberGenerator, map: CityMap,
		builder: PlanBuilder, open_candidates: Array[Vector2i], role: GameEnums.BlockerRole,
		already: Array[EventPlan], leave_alone: Array[Rect2],
		corridor: Corridor, doors: PackedVector2Array,
		standing: Array[EventPlan] = [], kept: Verdicts = null) -> EventPlan:
	var best: EventPlan = null
	var best_room := -INF
	# Built once per call rather than per try: neither `already` nor `standing` changes across the
	# tries below, only which tile and which candidate is asked about.
	var reach_context: Array[EventPlan] = already
	if not standing.is_empty():
		reach_context = already.duplicate()
		reach_context.append_array(standing)
	# **Each candidate is judged once per call, and every try still rolls.** A pool of a few tiles
	# — `WalkSiting.ahead_of()` often offers one — is rolled `EVENT_PLACEMENT_TRIES` times, and the
	# rule chain against every plan of the day is the same question each time the same tile and
	# path come up, so its verdict is kept here, keyed by both. The roll and `PlanBuilder.build()`'s
	# own draws still happen on every try, in the same order, so the stream, and with it every
	# placement, is what it would be if each try asked again.
	#
	# `kept`, when a caller hands one in, is where the verdicts are kept, and it may outlive the
	# call: `WalkSiting`'s keeps them for one look, shared by every copy the look asks about. It is
	# that caller's to drop whenever what a verdict reads changes — see `WalkSiting.begin_look()`.
	var verdicts: Verdicts = kept if kept else Verdicts.new()
	# The day's rules, the same ones the dawn draw asks (`StreetInvalidation`), so they are stated once.
	var judge := StreetInvalidation.new(map, corridor, leave_alone, doors, null)
	for _attempt in EVENT_PLACEMENT_TRIES:
		var tile: Vector2i = open_candidates[rng.randi_range(0, open_candidates.size() - 1)]
		var candidate := builder.build(def, tile, rng)
		if not candidate:
			continue
		# The row, its role, the tile and the path built on it are the whole of what a candidate
		# is: its position and facing are the tile's own.
		var key := [def.get_instance_id(), role, tile, candidate.path]
		var verdict := verdicts.of(key)
		if verdict.is_empty():
			var room := judge.room(candidate, role, tile, already, reach_context)
			verdict = [candidate.role, room]
			verdicts.keep(key, verdict)
		candidate.role = verdict[0]
		var judged: float = verdict[1]
		if judged == INF:
			return candidate
		if judged > best_room:
			best_room = judged
			best = candidate
	# Nothing comes back when every candidate broke a rule that does not bend — a lethal event
	# with no clear ground, or a full pavement. The caller re-rolls; a scripted event that
	# cannot be placed simply does not happen, which is the right failure direction.
	return best

## **Where `_best_of()` keeps the verdicts of the candidates it judges**: for each, what the day's
## rules (`StreetInvalidation.room()`) answered, as `[the role it set, the room it answered]`, under the key
## `_best_of()` asks by (the row, its role, the tile and the path built on it). `_best_of()` asks
## it for a candidate's verdict before judging the candidate, and gives it each verdict it judges.
## A call keeps its own unless it is handed one; a `WalkSiting` hands every call it makes the store
## it was built with, which keeps verdicts for one ask, or for one look (`WalkSiting.begin_look()`).
## A kept verdict is the answer only while what it read stands, so whoever holds the store drops
## them (`forget()`) the moment that stops being true.
class Verdicts extends RefCounted:
	var _kept := {}

	## The verdict kept for `key`, or an empty array when there is none and the candidate is to
	## be judged.
	func of(key: Array) -> Array:
		return _kept.get(key, [])

	## Keeps `verdict`, just judged, for `key`.
	func keep(key: Array, verdict: Array) -> void:
		_kept[key] = verdict

	## Drops every verdict kept.
	func forget() -> void:
		_kept.clear()

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
	if not def.placement.has(GameEnums.TileType.SIDEWALK):
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
## is silent and its 22px `obstructs_radius` stays under the far-lane distance (`EventDef._THE_FAR_LANE`, one tile, 32px), so the cost clause
## reads it as friction — but pinned `AT_THE_KERB`, 16px in from the kerb edge, it leaves only
## `(SIDEWALK_WIDTH * TILE_SIZE - TILE_SIZE * 0.5) - 22 = 26px` to the frontage, narrower than the
## 28px she needs, which `tests/test_events.gd`'s `_test_a_kerbed_body_still_pins_the_frontage`
## already measures by hand for this one row. Read off `obstructs_radius` and `pavement_side` rather
## than off an id, so the next row this narrow is caught the same way without anybody adding it to a
## list — and a row whose reach already clears the far-lane distance (`EventDef.reaches_the_far_lane()`) never reaches this, so nothing already a wall
## is asked twice.
static func _closes_the_band_by_its_own_placement(def: EventDef) -> bool:
	var reach := def.obstructs_radius
	if reach <= 0.0:
		return false
	var band := float(Tuning.SIDEWALK_WIDTH) * Tuning.TILE_SIZE
	var pos := _band_offset_of(def.pavement_side, band)
	var near_gap := pos - reach
	var far_gap := band - (pos + reach)
	return maxf(near_gap, far_gap) < RouteSidewalkRule.HER_LANE_CLEARANCE

## Where `pavement_side` stands a body across a sidewalk band, as an offset from the kerb edge —
## the same geometry `EventFootprints._centred_on_the_pavement_band()` and its kerb/frontage
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
	return not def.paces and leaves_no_line_along_a_sidewalk(def)

# ---------------------------------------------------------------- park rules ---

## The rect of a calm block's actual calm ground, falling back to the whole lot. The same question
## `ClosurePlanner.CalmArea.rect` answers, and the same function now — a courtyard's calm is its
## court alone, and there is exactly one place that says so.
static func _calm_rect(map: CityMap, block: Vector2i) -> Rect2i:
	return ClosurePlanner.calm_area_rect(map, block)

## Today's closures plus every blocker's own obstruction circle, as the `blocked` set
## `ReachabilityGrid.flood()` takes. Public because `WalkSiting` builds the same set and then adds
## two fields to it, and a second copy of this loop would be a second answer to the same question.
static func blocked_by(map: CityMap, blockers: Array[EventPlan]) -> Dictionary:
	var blocked := map.closed_tiles.duplicate()
	for plan in blockers:
		block_a_disc(map, blocked, plan.position, plan.blocking_radius())
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
