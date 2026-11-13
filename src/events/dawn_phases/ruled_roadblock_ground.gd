class_name RuledRoadblockGround
extends RoadblockGround
## **The day's ground as the roadblock phase asks it** (`RoadblockGround`): the route tiles, a
## section's roadblock left out where the day's rules invalidate it, and close by along her paths.
##
## - **The route tiles** are every walkable tile a route runs along (`Corridor.carries_a_route()`)
##   that nothing already standing shuts (`DayReach.shut_by()`).
## - **A section's roadblock** stands where it fits inside the section: on the tile of the row's own
##   ground for its role (`RowGround.offers_for_role()`: off every tile a route runs along, off a
##   held or closed street, the home block, a tree) nearest the section's middle that the day's rules
##   (`StreetInvalidation`) refuse nothing, asked against the day's plans and what stands
##   (`DayEvents.standing()`). A section with no such tile is offered none, and none is ever offered
##   on the main road (inbox #1186 in gentle-owl). **Every rule invalidates here, the spacing between two of a row
##   included**: a tile with
##   another roadblock within `EventScheduler.EVENT_SPACING_SAME` (256px), the one rule that bends elsewhere, is
##   not offered, so construction keeps the day's roadblocks apart and the phase's bias ranks what is
##   left. *Read as, the orchestrator's and open to correction:* which events make others invalid is
##   "what your current rules accomplish. the same applies still" (inbox #1185 in gentle-owl), and the spacing is
##   one of those rules.
## - **Close by** is the walk her paths take, without leaving the circle of `TASK_ROW_CLOSE_BY` round
##   it, from the ground she touches it from (`close_by()`), with its own body standing.
##
## Handed the task's row, the day, the map, the plan builder, the day's plan, the walk's ground,
## its corridor and the day's rules. Model: no node.

## The widest a task's row is searched for round where she read its mark: a block and a street past
## the 576px circle round it (`ResistanceDirector.ROADBLOCK_WIDER_REACH`'s last ring), 1,024px. What
## the roadblock phase aims to stand day 13's roadblocks within of every stretch of her routes
## (`EventScheduler._place_the_roadblocks()`).
const TASK_ROW_CLOSE_BY := (Tuning.BLOCK_SIZE * 2.5 + Tuning.STREET_WIDTH * 2.0) * Tuning.TILE_SIZE

var _def: EventDef
var _role := GameEnums.BlockerRole.NONE
var _map: CityMap
var _builder: PlanBuilder
var _events: DayEvents
var _corridor: Corridor
var _rules: StreetInvalidation
## The row's own ground for its role, as the day's ground answers it (`tile -> times offered`).
var _own := {}
var _shut := {}

## `ground` is the day's ground (`RowGround`), asked once for the row's own.
func _init(def: EventDef, day: int, map: CityMap, builder: PlanBuilder, events: DayEvents,
		ground: RowGround, corridor: Corridor, rules: StreetInvalidation) -> void:
	_def = def
	_role = EventScheduler.role_for(def, day)
	_map = map
	_builder = builder
	_events = events
	_corridor = corridor
	_rules = rules
	_own = ground.offers_for_role(def, _role)
	var down := events.placements().duplicate()
	down.append_array(events.standing())
	_shut = DayReach.shut_by(map, down)

## Two of the row's fields and a street: the farthest a rule asks of two rows together reaches.
##
## Overrides RoadblockGround.reoffer_within.
func reoffer_within() -> float:
	return 2.0 * maxf(_def.field_reach(), EventScheduler.EVENT_SPACING_ANY) \
			+ (Tuning.BLOCK_SIZE + Tuning.STREET_WIDTH) * Tuning.TILE_SIZE

## Overrides RoadblockGround.route_tiles.
func route_tiles() -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y in _map.size.y:
		for x in _map.size.x:
			var tile := Vector2i(x, y)
			if _corridor.carries_a_route(tile) and _map.is_walkable(tile) \
					and not _shut.has(tile):
				found.append(tile)
	return found

## Overrides RoadblockGround.offer.
func offer(section: Location) -> EventPlan:
	if EventScheduler.is_on_the_main_road(_map, section):
		return null
	var tiles := section.tiles()
	var middle := _map.world_to_tile(section.centre())
	var fits: Array[Vector2i] = []
	for y in range(tiles.position.y, tiles.end.y):
		for x in range(tiles.position.x, tiles.end.x):
			if _own.has(Vector2i(x, y)):
				fits.append(Vector2i(x, y))
	fits.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := (a - middle).length_squared()
		var db := (b - middle).length_squared()
		return da < db or (da == db and (a.y < b.y or (a.y == b.y and a.x < b.x))))
	var already := _events.placements()
	var reach_context := already.duplicate()
	reach_context.append_array(_events.standing())
	for tile in fits:
		var candidate := _builder.build(_def, tile, RandomNumberGenerator.new())
		# `INF` alone: room all round, so the spacing between two of a row
		# (`EVENT_SPACING_SAME`) leaves a tile invalid rather than merely cramped.
		if candidate and _rules.room(candidate, _role, tile, already, reach_context) == INF:
			return candidate
	return null

## Overrides RoadblockGround.covers.
func covers(plan: EventPlan) -> Array[Vector2i]:
	var shut := _shut.duplicate()
	EventScheduler.block_a_disc(_map, shut, plan.placed_at(), plan.blocking_radius())
	var found: Array[Vector2i] = []
	for tile: Vector2i in close_by(_map, shut, plan):
		found.append(tile)
	return found

## Overrides RoadblockGround.stand.
func stand(plan: EventPlan) -> void:
	_events.add(plan)
	EventScheduler.block_a_disc(_map, _shut, plan.placed_at(), plan.blocking_radius())

## **The ground close by `plan`** (`tile -> its distance from the plan`): the walk her paths take
## over the ground `shut` leaves open, from where she touches the plan (`_touched_from()`),
## without leaving the circle of `TASK_ROW_CLOSE_BY` round it (`DayReach.paths_over()`). The one
## measure of close by, which what a section's roadblock would cover (`covers()`) and the count of
## the route tiles the finished day leaves without one share.
static func close_by(map: CityMap, shut: Dictionary, plan: EventPlan) -> Dictionary:
	return DayReach.paths_over(map, shut, _touched_from(map, shut, plan), plan.placed_at(),
			TASK_ROW_CLOSE_BY)

## The walkable ground left open within a tile and a half of `plan`'s body: where she touches it
## from.
static func _touched_from(map: CityMap, shut: Dictionary, plan: EventPlan) -> Array[Vector2i]:
	var reach := plan.blocking_radius() + Tuning.TILE_SIZE * 1.5
	var centre := map.world_to_tile(plan.placed_at())
	var span := ceili(reach / Tuning.TILE_SIZE)
	var found: Array[Vector2i] = []
	for dy in range(-span, span + 1):
		for dx in range(-span, span + 1):
			var tile := centre + Vector2i(dx, dy)
			if map.in_bounds(tile) and map.is_walkable(tile) and not shut.has(tile) \
					and map.tile_to_world(tile).distance_to(plan.placed_at()) <= reach:
				found.append(tile)
	return found
