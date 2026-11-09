class_name CityFronts
extends RefCounted
## **The building fronts the run's story changes**: day 3's burnt frontage, day 8's way in behind a
## sidewalk, day 11's market boarded up during the day, the neighbor's boarded window and her sealed
## street door. Built by the city once its buildings and her door stand, and handed to the
## resistance, which is what changes them, in place of the whole city.
##
## *(inbox #1156: "the objects a class depends on are injectable, so a test can mock them".)* It
## holds the city's buildings, which are fixed for the run (only their condition changes), and her
## door, and changes nothing until it is asked. The city's own dawn dressing asks it to burn the
## frontage too, so the burnt building is found the one way either way.
##
## **A fronts with nothing handed changes nothing**: `CityFronts.new()` holds no building and no
## door, so every question answers as a city with no fronts would, and a test hands a fake of its
## own (`tests/fake_city_fronts.gd`) where it needs to see what was asked.

## Every building the city built, fixed for the run: the city's own list, not a copy.
var _buildings: Array[Building] = []
## Her street door, or null where an authored scene shows no home.
var _home_door: City.HomeDoor = null
## The door's world-space x-span, `[min, max)`, the city's `_door_world_x_range()`: read before the
## door exists, so it is handed as a value rather than read off the door node.
var _door_x_range := Vector2.ZERO
var _map: CityMap = null
## The run whose scars say which front burnt (`attempt_spend.scars`).
var _run: RunState = null
## Where the boarded window is written down for the run log.
var _trace := RunTrace.new()

## The fronts over the city's `buildings` and her `home_door` (null for none), whose span is
## `door_x_range`, on `map`, in `run`, writing to `trace`.
static func over(buildings: Array[Building], home_door: City.HomeDoor, door_x_range: Vector2,
		map: CityMap, run: RunState, trace: RunTrace) -> CityFronts:
	var fronts := CityFronts.new()
	fronts._buildings = buildings
	fronts._home_door = home_door
	fronts._door_x_range = door_x_range
	fronts._map = map
	fronts._run = run
	fronts._trace = trace
	return fronts

## Forces the one `Building` behind day 3's fire to `Building.Condition.BURNT`, overriding
## whatever its own block's purpose just set above — *"the building is what needs to be burnt, not
## an object next to the building"*. The block's purpose is unmoved (this building's block may still
## be ordinary `RESIDENTIAL`, `COMMERCIAL` ground the arc never touches); only the one frontage the
## fire actually reached shows it, in the look `Building.Condition.BURNT` draws (windows black and
## broken under soot, the door boarded, the parapet charred) for the scheduled `BURNT_OUT` block
## purpose above too — the same look for a different, per-building reason.
##
## **The lookup is the shape of `board_neighbor_window()`/`_home_door_building()`**: a fixed fact
## about the run (`run.attempt_spend.scars`) answers which `Building` it is, once, rather than a field
## carried on the building itself. `burning_building` only ever catches on a wall the city actually
## draws (`EventDef.Pavement.AT_THE_FRONT`, `EventCatalogue._burning_building()`'s own doc), so the
## tile one step north of the scar (`Vector2i.UP`, the same direction `EventScheduler.
## _wants_this_side()`'s `AT_THE_FRONT` case checks, on the map and `BUILDING`) is always a real
## lot. `tests/test_acts.gd` checks that over every site the fire can be given.
##
## Idempotent, like every other per-day override of the city's: `Building.condition`'s own setter is
## a no-op once it already says `BURNT`, so the city calling this from every `_dress_blocks()` pass —
## the ordinary day and the finale's own dressing alike — costs nothing once the frontage is found,
## and finds nothing before day 4, when the scar does not exist yet. A run records one `burnt_shell`
## scar, and every one the list holds burns its own building all the same.
##
## **Also called live, once, by day 8's task on a run with no recorded scar**
## (`ResistanceDirector._burn_a_front_for_the_task()`): it records a scar at a front the fire could
## have caught on and asks for the building behind it to be burnt there and then, so *"Take what's
## in the stroller to the burnt building"* leads to a burnt building rather than bare sidewalk.
func mark_the_burnt_frontage() -> void:
	if _run == null:
		return
	for scar in _run.attempt_spend.scars:
		if String(scar["id"]) != City.BURNT_FRONTAGE_SCAR:
			continue
		var wall_tile := _map.world_to_tile(scar["position"] as Vector2) + Vector2i.UP
		for building in _buildings:
			if building.lot.has_point(wall_tile):
				building.condition = Building.Condition.BURNT
				break

## The way in of the building directly north of the sidewalk point `sidewalk` — the same lot
## `mark_the_burnt_frontage()` burns behind a scar — as a world point half a tile up its ground
## floor, on the door (`Building.way_in_local_x()`, the one nearest `sidewalk` on a front with
## several storefronts). `Vector2.INF` with no building there. Day 8's red arrow and its task's
## contact end here: *"or better to the door"* (sandy-egret).
func way_in_behind(sidewalk: Vector2) -> Vector2:
	if _map == null:
		return Vector2.INF
	var wall_tile := _map.world_to_tile(sidewalk) + Vector2i.UP
	for building in _buildings:
		if building.lot.has_point(wall_tile):
			var x := building.way_in_local_x(sidewalk.x - building.position.x)
			return building.position + Vector2(x, -Tuning.TILE_SIZE * 0.5)
	return Vector2.INF

## **One block's buildings, shown as what the block is now**, during the day rather than at dawn —
## day 11's market, boarded up ahead of her while she cannot see it (`ResistanceHappenings`). The
## same `City.condition_for()` the city's dawn dressing reads, for the buildings of `block` alone,
## and the same `mark_the_burnt_frontage()` after it, so a block boarded up around the building day
## 3's fire burned never boards up the burnt building itself.
func present_block(block: Vector2i, state: CityState) -> void:
	if _map == null:
		return
	var condition := City.condition_for(state.purpose_of(_map.plans_by_block(), block))
	for building in _buildings:
		if City.block_of(building.lot) == block:
			building.condition = condition
	mark_the_burnt_frontage()

## Boards the neighbor's window for the rest of the run: the third-floor window cell — row index
## 3, ground floor is row 0 — nearest above her own door, on the one home-block `Building` the
## door notch actually stands in front of (`_home_door_building()`). Her own floor, the top one at
## this height, down the hall from her own door. It stands above the top of the screen at the
## normal camera on her doorstep, facing away down the street — turning to face the building
## brings it into frame (PLAYTEST-134, statement 4 revisited). Idempotent, so
## `ResistanceHappenings.start_day()` calling it every day from day 11 on costs nothing once it is
## set. That building always has at least four wall rows (`City.HOME_BUILDING_WALL_ROWS`), fixed
## rather than rolled, so there is no shorter front here for a topmost row to stand in for it.
func board_neighbor_window() -> void:
	var building := _home_door_building()
	if not building or building.neighbor_window_col >= 0:
		return
	var door_centre_x := (_door_x_range.x + _door_x_range.y) * 0.5
	var best_col := 0
	var best_distance := INF
	for col in building.columns():
		var distance := absf(building.column_centre_x(col) - door_centre_x)
		if distance < best_distance:
			best_distance = distance
			best_col = col
	building.neighbor_window_col = best_col
	_trace.note("contact",
			"the neighbor's window is boarded at column %d, row %d (the third floor)"
			% [best_col, building.neighbor_window_row()])

## The one home-block `Building` the door's own world-space span actually stands in front of —
## every lot on the home block carries `is_home_building`, but the door notch's columns are cut
## out of every other one (`City._spawn_buildings()`'s own doc), so only this lot's world footprint
## overlaps the door's span.
func _home_door_building() -> Building:
	for building in _buildings:
		if not building.is_home_building:
			continue
		var world := _map.tile_rect_to_world(building.lot)
		if world.position.x < _door_x_range.y and world.end.x > _door_x_range.x:
			return building
	return null

## Swaps her street door to the sealed picture, live, the moment day 10's raid actually arrives
## (`ResistanceHappenings._maybe_raid()`, while she is out of sight of it) — the one day the city's
## own dawn read of the scars (`City._sync_home_door()`) is too early for, since the raid has not
## happened yet when it runs.
func seal_home_door() -> void:
	if _home_door:
		_home_door.picture = City.SEALED_DOOR_TEXTURE
