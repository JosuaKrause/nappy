extends RefCounted
## **What the resistance puts in the world, read the way the player meets it**, for the resistance
## suites: where the red arrow's tip stands (`ResistanceDirector.red_arrow_target()`, the one query
## the game's own HUD asks) and which instance of the world stands there, and what the day's
## obstruction leaves of the way home. A helper, not a suite: the runner loads only `test_*.gd`.
##
## The director keeps what the arrow has chosen, the fields it chooses from and the sweeps under way
## private, and offers no query of them; a test asks the arrow where it ends and the street what
## stands at that place.

## How many physics ticks `settle()` runs the director for. A choice is a lookup in two finished
## walking fields, and each field is swept a slice a tick (`ResistanceDirector.tick()`,
## `ARROW_SWEEP_TILES_PER_TICK`); a whole sweep of a test city is done in far fewer ticks than this
## (`tests/probes/plush_moose_arrow_cost.gd` measures it), so after this many the arrow is at rest.
const SETTLE_TICKS := 240

## Runs the arrow to rest the way the game does: the physics ticks `main` runs
## (`ResistanceDirector.tick()`) choose it and sweep the walking fields a slice at a time, choosing
## again as each finishes, for `SETTLE_TICKS` ticks. A choice made again after them (the arrow chooses
## every `ResistanceDirector.ARROW_RETARGET_SECONDS`) must leave the tip where it is, or the arrow had
## not settled and the assert fails loudly.
static func settle(director: ResistanceDirector, step_seconds: float) -> void:
	for i in SETTLE_TICKS:
		director.tick(step_seconds)
	var tip := director.red_arrow_target()
	for i in ceili(ResistanceDirector.ARROW_RETARGET_SECONDS / step_seconds) + 2:
		director.tick(step_seconds)
	assert(director.red_arrow_target() == tip, "the arrow had not settled after %d ticks" % SETTLE_TICKS)

## The live instances that answer a task several places answer (a man shouting, a roadblock): the
## city's instances of the task's row that are not finished, the places the arrow may point at.
static func answering(events: EventManager, step: ResistanceSteps.Step) -> Array[EventInstance]:
	var found: Array[EventInstance] = []
	if step == null:
		return found
	for instance in events.instances():
		if instance.def.id == step.task_event_id and not instance.is_finished:
			found.append(instance)
	return found

## The live instance of `candidates` the arrow's tip stands on, or null when it stands on none.
static func pointed_at(director: ResistanceDirector,
		candidates: Array[EventInstance]) -> EventInstance:
	var tip := director.red_arrow_target()
	for instance in candidates:
		if is_instance_valid(instance) and instance.global_position.distance_to(tip) < 1.0:
			return instance
	return null

## The id of the mast the arrow's tip stands on (the foot of a mast the city has), or "" when it
## stands on none: day 11's task rides the mast its arrow points at, so the tip is the contact.
static func mast_at(director: ResistanceDirector, events: EventManager) -> String:
	var tip := director.red_arrow_target()
	for plan in events.plans():
		if plan.mast_id != "" and events.mast_foot(plan.mast_id).distance_to(tip) < 1.0:
			return plan.mast_id
	return ""

## The day's reachability answer as `ResistanceDirector._reachable_from_home()` builds it
## (`EventScheduler.blocked_by()` over every placed, obstructing or hard-fail plan, flooded from
## home), built independently here so a sweep is not just asking the director to grade its own
## homework. A region door's own bodies are excluded, the same way the director excludes them: they
## are doors she walks through, not a block. The soft seals' bands (`CityMap.soft_sealed_tiles`) are
## blocked on top, as the director blocks them: the red arrow reads a band as ground she cannot walk,
## so a place reached only through one is not a place the arrow can lead her to. `[grid, blocked,
## reached]`, the shape `home_reach()` answers and `reaches_home()` takes. Plans standing within a
## tile and a half of a point in `except_near` are left out: a task's own body, placed after the day's
## first placement asked, does not shut its own tile.
static func day_reachability(city: City, except_near: Array[Vector2] = []) -> Array:
	var region_plan: RegionPlanner.RegionPlan = city.region_plan()
	var door_bodies: Array[EventScheduler.Planned] = region_plan.door_bodies if region_plan else []
	var blockers: Array[EventScheduler.Planned] = []
	for plan in city.events.plans():
		if not plan.is_placed() or plan in door_bodies:
			continue
		var excepted := false
		for point in except_near:
			excepted = excepted or plan.position.distance_to(point) < Tuning.TILE_SIZE * 1.5
		if excepted:
			continue
		if plan.def.obstructs_radius > 0.0 or plan.def.hard_fail:
			blockers.append(plan)
	var grid := ReachabilityGrid.build(city.map)
	var blocked := EventScheduler.blocked_by(city.map, blockers)
	blocked.merge(city.map.soft_sealed_tiles)
	return [grid, blocked, grid.flood([city.map.home_rect.position], blocked)]

## The tiles her paths reach from home under `blocked` (the day's obstruction), as
## `[grid, blocked, reached]` for `reaches_home()`: the same `ReachabilityGrid` flood from the home
## block that the director's placements are asked of.
static func home_reach(map: CityMap, blocked: Dictionary) -> Array:
	var grid := ReachabilityGrid.build(map)
	return [grid, blocked, grid.flood([map.home_rect.position], blocked)]

## Whether `tile` is reachable from home in a `home_reach()`.
static func reaches_home(reach: Array, tile: Vector2i) -> bool:
	var grid: ReachabilityGrid = reach[0]
	return grid.reaches(tile, reach[1], reach[2])
