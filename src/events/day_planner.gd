class_name DayPlanner
extends RefCounted
## **What a walk places before she sets off, chosen by its spec**: the planning half of every walk
## `EventManager.start_day()` starts. One planner for the three kinds of walk the run is made of,
## each on the stream it is handed and in the order its streams have always been drawn:
##
## - **a day** (`_plan_a_day()`): the day's holds, its seals (`SealPlanner.plan_day()`), the
##   catalogue's rows (`EventScheduler.build_day()`) and the region's wall and doors, against the
##   route tree the city grew this morning;
## - **the escape's city** (`plan_the_escape_city()`), whose spec closes no streets of a tree
##   (`DaySpec.closes_streets`): its walk is the two chains `FinalePlanner.route()` grows, the seals
##   are the same `SealPlanner.plan_day()` off them and the events the same `build_day()` on them;
## - **the escape's building** (`DaySpec.World.BUILDING`): the building's own placements
##   (`BuildingPlan.plan()`), the one walk allowed its own way of placing (minty-lemur #785).
##
## **Which of the three is the spec's**, read off its settings rather than off a flag naming the
## escape: the building is the spec's world, and a city walk whose streets are not closed off a tree
## is planned on the walk handed in with it.
##
## Handed the world the walk is planned over (`EventWorld`: its map, the city and the city's map
## where the world is the city, the run its streams and scars come from, the trace a day's planning
## writes to); the spec, the stream and the one-shots already spent come with each plan.

## **One walk's plan**: what it places, the walk it was placed against, and what of it is kept
## past dawn.
class Plan extends RefCounted:
	## Everything the walk places, in the order it is handed to the streaming.
	var placements: Array[EventScheduler.Planned] = []
	## The walk the placements are stated against (`RouteSource`): the day's route tree, the
	## escape's two chains (`FinalePlanner.Plan`), or null in the building.
	var walk: RouteSource = null
	## Where today's region doors stand, for what the director sites after dawn: a day's only.
	var doors := PackedVector2Array()
	## Whether it is a day's plan: its bodies recorded for the crowd, and the director siting
	## after dawn what the day left for her walk. False for a walk planned whole before she sets
	## off (the escape's two sections), whose plans that come again come on their own clocks.
	var is_a_day := true

## The world the walk is planned over.
var world: EventWorld

func _init(the_world: EventWorld) -> void:
	world = the_world

## **`spec`'s plan**, on `rng`, with `consumed` the one-shots the run has already spent (appended to
## in place by a day's plan, as `EventScheduler.build_day()` spends them).
func plan(spec: DaySpec, rng: RandomNumberGenerator, consumed: Array[String]) -> Plan:
	assert(spec.closes_streets == (spec.section == DaySpec.Section.NONE),
			"DayPlanner.plan(): a spec that closes streets is a day's, and only a day's does")
	if spec.world == DaySpec.World.BUILDING:
		return _plan_the_building(rng)
	if not spec.closes_streets:
		return _plan_the_escape_city(spec, rng)
	return _plan_a_day(spec, rng, consumed)

# ------------------------------------------------------------------- a day ---

## A day's plan, the day being `spec.number`.
func _plan_a_day(spec: DaySpec, rng: RandomNumberGenerator, consumed: Array[String]) -> Plan:
	var day := spec.number
	var city_map := world.city_map
	# The corridor the city grew this morning, before it placed its closures off it. Passed rather
	# than grown again so that the walls, the friction and the picture are all stated against one
	# tree; `RouteTree.for_day` would give the same answer, and two places agreeing by arithmetic
	# is a thing that stops being true the first time one of them takes an argument. Kept as a local
	# rather than re-read from `world.city` below, for the same reason — `SealPlanner` needs the same
	# tree the catalogue's own placements were just stated against.
	#
	# **`world.city.route_tree()` can itself be null even when `world.city` is not** — a live
	# `world.city` whose own `start_day` was never called for this day, which is the whole rig
	# `tests/test_event_manager.gd` and `tests/test_balance.gd` drive: `EventManager.start_day` on its
	# own, with no `City.start_day` first. The explicit null check grows one the same way
	# `City._close_streets` does, from the same `RouteTree.for_day(map, day)`, so the fallback and the
	# real thing can never disagree.
	var tree: RouteTree = world.city.route_tree() if world.city else null
	if not tree:
		tree = RouteTree.for_day(city_map, day)
	# Grown the same way `tree` was, so the two never answer for two different days — see
	# `City._close_streets`. `world.city.region_plan()` can itself be null for the same reason as
	# `tree` above, and the explicit null check here falls through to growing one the same way.
	var region_plan: RegionPlanner.RegionPlan = world.city.region_plan() if world.city else null
	if not region_plan:
		region_plan = RegionPlanner.plan_day(city_map, day, tree)

	# Held ground, before `EventScheduler.build_day` rolls a single candidate — see
	# `CityMap.held_segments`. Closures, the region's own wall and door segments, and the
	# streets around the home block are all known already; the hard seals are not, which is
	# why `SealPlanner.plan_day` is planned ahead of `build_day` below (see that call's own note).
	#
	# A rig driving `EventManager` off a `City` that has not run its own `start_day` yet still
	# gets no closures held: `world.city.closures()` reads `City`'s own `_closures`, which only
	# `City.start_day()` ever populates, and there is no fallback for it the way `tree` and
	# `region_plan` grow their own just above — closures are `ClosurePlanner`'s to plan, not this
	# planner's, so a rig that wants them run has to run `City.start_day()` first. The wall, the
	# doors and the home block are still held, because all three come from `region_plan` and the
	# map alone.
	city_map.clear_day_holds()
	if world.city:
		for closure in world.city.closures():
			city_map.hold_segment(closure.segment.key())
	for segment in region_plan.walls:
		city_map.hold_segment(segment.key())
	for segment in region_plan.doors:
		city_map.hold_segment(segment.key())
	if spec.holds_the_home_streets:
		for segment in StreetNetwork.around_blocks(Rect2i(city_map.home_block, Vector2i.ONE)):
			city_map.hold_segment(segment.key())

	# Off the catalogue's own budget on purpose — see `SealPlanner`'s own doc. It seals everything
	# `EventScheduler` was not permitted to touch: every street off `tree` (a share of them from
	# `Tuning.REGION_WALL_FIRST_DAY` on, see `SealPlanner._seals_this_street`), hard or soft, plus the
	# mouths of any through-alley that never reaches it — except today's region boundary, wall or
	# door, and any crossing alley, both skipped here: the wall already carries its own hard seal
	# below, and a door or a crossing alley's own door is meant to stay open for the structure the
	# milestone's second half places there. Segment keys (`Vector3i`) and alley rect positions
	# (`Vector2i`) share one `Dictionary` without colliding — see `SealPlanner.plan_day`'s own doc.
	var boundary := {}
	for segment in region_plan.walls:
		boundary[segment.key()] = true
	for segment in region_plan.doors:
		boundary[segment.key()] = true
	for rect in region_plan.alley_walls:
		boundary[rect.position] = true
	for rect in region_plan.alley_doors:
		boundary[rect.position] = true
	# **Planned before `build_day`.** `SealPlanner.plan_day` is a pure function of the map, the day,
	# `tree` and its own RNG stream (`world.run.calendar.day_rng(day, "seals")`, never shared
	# with the catalogue's), so planning it first changes which seals a day gets not at all —
	# only how soon `build_day` can see where they landed. `held` is `city_map.held_segments`
	# itself: a hard seal's segment is marked there as it is placed, so the catalogue never
	# offers a candidate row that same ground (`docs/DECISIONS.md`, M100, "Events spawn inside a
	# fully blocked street").
	var seals := SealPlanner.plan_day(city_map, spec, tree,
			world.run.calendar.day_rng(day, "seals"), boundary, city_map.held_segments)
	# Where today's doors stand, before a single candidate is rolled. `build_day` keeps
	# `Tuning.CHECKPOINT_EVENT_GAP` of clear ground around each of them — the ground she is let out
	# onto, on either side — by refusing a candidate whose field or beat reaches inside it, which is
	# the same "checked before it is accepted, never repaired afterwards" every closure is placed
	# under. The wall's own bodies are deliberately not in this list: a wall is structure and stands
	# where the boundary is.
	var doors := PackedVector2Array()
	for body in region_plan.door_bodies:
		doors.append(body.position)
	# The day's narrow resistance target — day 9's door, day 12's swing, the station's front door —
	# as the tiles its contact may stand on today, and what obstructs the day whatever the
	# catalogue does: the seals just planned and the region wall's own bodies. `build_day` keeps a
	# route from home to one of those tiles among the day's own bodies, the way it keeps one to the
	# calm (`docs/CITY.md`, "Guarantees"). Here rather than in `build_day` because only here is every
	# hold the director refuses already on the map — the closures, the wall and doors, the home's
	# streets and the hard seals — so the tiles protected are tiles the contact may actually take.
	var standing: Array[EventScheduler.Planned] = []
	standing.append_array(seals)
	standing.append_array(region_plan.wall_bodies)
	var placements := EventScheduler.build_day(spec, rng, city_map, consumed,
			world.run.attempt_spend.scars, world.run.calendar.settled_this_act(), tree,
			world.run.resistance.progress, doors,
			ResistanceDirector.target_ground(city_map, day, region_plan), standing, world.trace)
	placements.append_array(seals)
	# The wall's own bodies — hard seals of the roadblock row, one region boundary at a time. Kept
	# as `RegionPlanner`'s own returned list rather than folded into `SealPlanner`'s: a caller that
	# wants to know where the wall stands reads `region_plan.wall_bodies` directly rather than
	# filtering it back out of the whole day's plan.
	placements.append_array(region_plan.wall_bodies)
	# The door structure — a hut on each pavement and a gate over the road at a street door, a
	# guard at each mouth of an alley door. Same reasoning as `wall_bodies` just above: kept as
	# its own list on `region_plan` and appended here rather than merged into `SealPlanner`'s, so
	# `region_plan.door_bodies` stays the one place that answers "where do today's doors stand"
	# without filtering.
	placements.append_array(region_plan.door_bodies)
	var result := Plan.new()
	result.placements = placements
	result.walk = tree
	result.doors = doors
	return result

# ------------------------------------------------------------ the escape's city ---

## The escape city's plan: its walk (`FinalePlanner.route()`) and what stands on and off it
## (`plan_the_escape_city()`), on `rng`. **Nothing is held**: a hold keeps the catalogue's own roll
## off ground something else has taken, and the escape's seals keep their own record instead, so
## the day's holds are cleared once the walk is placed rather than left for a rig that ran a day
## on the same map.
func _plan_the_escape_city(spec: DaySpec, rng: RandomNumberGenerator) -> Plan:
	var result := Plan.new()
	var walk := FinalePlanner.route(world.city_map)
	result.walk = walk
	result.placements = plan_the_escape_city(world.city_map, walk, rng, spec)
	result.is_a_day = false
	world.city_map.clear_day_holds()
	return result

## **What the escape puts in the city, on its walk `walk`**: each placed by the day's own code under
## `spec`, the city section's (`DaySpec.for_section()`), on `rng` — the seals off the walk first
## (`SealPlanner.plan_day()`), then the events on it (`EventScheduler.build_day()`) on what is left
## of the same stream. A recipe asks for the seals alone (`populate_events` false) and validates its
## own actors on the streets.
##
## **Every pass is handed the tile she is put down on.** *(2026-09-19: "the spawning shouldn't be a
## check. the pathing should start from the position. then obstacles can never happen.")* The chains
## already start there (`FinalePlanner.route()` enters the grid at her own cell), and the walk hands
## its start to both passes that place things: the sealing spares the street she is standing in
## rather than the one the front door opens onto (`RouteSource.street_it_starts_in()`), and the
## events are never offered the ground she is on. Neither is a check on the spawn and neither moves
## anything afterwards. The events are handed the seals too, because what they may not close is the
## walk from where she stands to either exit with the seals already down.
static func plan_the_escape_city(map: CityMap, walk: FinalePlanner.Plan,
		rng: RandomNumberGenerator, spec: DaySpec,
		populate_events := true) -> Array[EventScheduler.Planned]:
	var placements: Array[EventScheduler.Planned] = []
	var seals := SealPlanner.plan_day(map, spec, walk, rng)
	placements.append_array(seals)
	if populate_events:
		placements.append_array(EventScheduler.build_day(spec, rng, map, [], [], [], walk, 0,
				PackedVector2Array(), [], seals))
	return placements

# --------------------------------------------------------------- the building ---

## The building's own placements on its map, from `rng` (`BuildingPlan.plan()`). Its world is not
## the city, so there is nothing to hold.
func _plan_the_building(rng: RandomNumberGenerator) -> Plan:
	var result := Plan.new()
	result.placements = BuildingPlan.plan(world.map as InteriorMapPlan, rng)
	result.is_a_day = false
	return result
