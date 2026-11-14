class_name PlanBuilder
extends RefCounted
## Builds one event's plan (`EventPlan`) at one tile on the map it is handed: a standing row faced
## out of the wall it backs against, a moving row given its route down or across the street it
## stands on, a plan sited only where the plans already standing leave it room, and where a built
## plan's body stands.
##
## **It is handed everything it asks**, so a test builds one over a hand-drawn map with stand-ins
## and no scene tree: the map, and three questions another class answers, each as a function. Whoever
## makes a builder names them (the game's are `EventInstance.mover_for`, `EventFootprints.stands_at`
## and `StreetInvalidation.room_around`, `tests/game_plan_builder.gd` for a suite); this file names
## none of them. The row, the tile, the stream and the plans to keep room from are the question,
## handed per call. Every method is a function of what it is handed and the map, the one thing a
## call changes being the stream's position. Model: no node, and nothing held but what it is handed.

var _map: CityMap
## `(row: EventDef) -> Mover`: what stops the row as it moves.
var _walks_as: Callable
## `(map: WorldMap, row: EventDef, at: Vector2) -> Vector2`: where a body built at `at` stands.
var _stands_at: Callable
## `(candidate: EventPlan, already: Array[EventPlan]) -> float`: the candidate's room among the
## placed plans, `-INF` for none.
var _room_among: Callable
## Whether a route passes today's bodies (`without_todays_bodies()`).
var _passes_todays_bodies := false

## A builder over `map` that asks `walks_as` what stops a moving row, `stands_at` where a body
## stands and `room_among` the room a candidate has among placed plans.
func _init(map: CityMap, walks_as: Callable, stands_at: Callable, room_among: Callable) -> void:
	_map = map
	_walks_as = walks_as
	_stands_at = stands_at
	_room_among = room_among

## **A builder like this one whose routes are not stopped by today's bodies** (`Mover.BODIES`
## cleared from what stops a row, its body's reach kept): a route laid on the map as the dawn left
## it. At dawn no body is on the map, so it builds what this one does; while she walks it keeps
## what was sited or is live from changing a unit's draw (`DawnDraw`).
func without_todays_bodies() -> PlanBuilder:
	var builder := PlanBuilder.new(_map, _walks_as, _stands_at, _room_among)
	builder._passes_todays_bodies = true
	return builder

## One candidate placement on a given tile, with its route built if it moves. `within`, where it
## has area, bounds a route along the street: it stops at the last tile inside it, as at a closure.
func build(def: EventDef, tile: Vector2i, rng: RandomNumberGenerator,
		within := Rect2i()) -> EventPlan:
	var at := _map.tile_to_world(tile)
	if not def.mobile:
		var placed := EventPlan.new(def, at)
		if def.pavement_side == EventDef.Pavement.AGAINST_THE_BUILDING:
			# Backing in, so it faces *out* of the wall it is against: the box is the end that is
			# coming towards you and it has to be the end that is in the yard.
			placed.facing = -Vector2(_map.pavement_inward(tile))
		return placed
	match def.path_mode:
		EventDef.PathMode.CROSS_STREET:
			var crossing := _cross_street_path(tile)
			return null if crossing.is_empty() else EventPlan.new(def, at, crossing)
		EventDef.PathMode.ALONG_STREET:
			var route := _along_street_path(tile, def, rng, within)
			# Nowhere to go from here; a "mobile" event that stands still is worse than
			# another roll of the dice.
			return null if route.is_empty() else EventPlan.new(def, at, route)
		_:
			return EventPlan.new(def, at)

## The placement a recipe or a planner puts at one site, or null: the candidate `build()` sites on
## `tile` that the handed room among placed plans (the game's `StreetInvalidation.room_around()`)
## leaves room for among `already`. The one entry point a
## planner and `SceneRecipeRuntime` share: an authored scene's row keeps the day's spacing. The
## scheduler's own loop (`EventScheduler._best_of()`) does not call it: a day asks the day's rules
## (`StreetInvalidation`), which ask `StreetInvalidation.room_around()` among many more rules and set the candidate's
## role, so routing the loop through this would change what the day places.
func place_at(def: EventDef, tile: Vector2i, rng: RandomNumberGenerator,
		already: Array[EventPlan]) -> EventPlan:
	var candidate := build(def, tile, rng)
	if not candidate or float(_room_among.call(candidate, already)) == -INF:
		return null
	return candidate

## Where a placement's body stands once it is built: the first point of its path when it has one,
## recentred on the pavement band unless `pavement_side` pins it — the reading
## `EventInstance.setup()` makes of a stationary body, which is where a waiting guard's band stands
## and where he notices her from (`OneNoticeRule`).
func body_stands_at(plan: EventPlan) -> Vector2:
	return _stands_at.call(_map, plan.def,
			plan.path[0] if plan.path.size() > 0 else plan.position)

## Distance in tiles from a tile to the edge of the map along a direction, less a
## one-block margin so a route always ends inside the city rather than against the wall.
func room_along(tile: Vector2i, direction: Vector2i) -> int:
	var margin := CityMap.period()
	var room := 0
	if direction.x > 0:
		room = _map.size.x - 1 - tile.x
	elif direction.x < 0:
		room = tile.x
	elif direction.y > 0:
		room = _map.size.y - 1 - tile.y
	else:
		room = tile.y
	return maxi(0, room - margin)

## A route down the corridor the tile sits on, for traffic and for anyone walking a dog.
##
## Direction is a coin flip *between the directions that have room*, and the length is
## clamped to what actually fits. Clamping the endpoint to the map bounds instead — the
## first version — parked every long route hard against the city wall, which put the fire
## the engine leaves behind out on the boundary every single time.
func _along_street_path(tile: Vector2i, def: EventDef,
		rng: RandomNumberGenerator, within := Rect2i()) -> PackedVector2Array:
	var vertical_corridor := CityMap.corridor_offset(tile.x) >= 0
	var forward := Vector2i.DOWN if vertical_corridor else Vector2i.RIGHT
	var backward := -forward

	var forward_room := room_along(tile, forward)
	var backward_room := room_along(tile, backward)
	var along := forward
	var room := forward_room
	# Prefer whichever way fits the whole route; if both do, or neither, flip a coin.
	if backward_room > forward_room and backward_room >= def.path_length_tiles:
		along = backward
		room = backward_room
	elif forward_room >= def.path_length_tiles and backward_room >= def.path_length_tiles:
		if rng.randf() < 0.5:
			along = backward
			room = backward_room
	elif backward_room > forward_room:
		along = backward
		room = backward_room

	var length := mini(def.path_length_tiles, room)
	# Stop short of anything that stops the row (`CityMap.passable()`, as it moves: a closure's
	# barrier, a seal, a body standing today) rather than walking or driving through it — and short
	# of a calm zone's absorbed corridor as well. A corridor that ends in a park is not a corridor a
	# delivery van can drive down, and unlike a closure there is nothing there to hit: the route
	# would simply cross the grass. And short of the edge of `within`, where one is handed.
	var from_a_street := _map.is_street(tile)
	var walks_as: Mover = _walks_as.call(def)
	var mover := _as_it_stops(walks_as)
	var bounded := within.has_area()
	for step in range(1, length + 1):
		var next := tile + along * step
		if not _map.passable(next, mover) or (from_a_street and not _map.is_street(next)) \
				or (bounded and not within.has_point(next)):
			length = step - 1
			break
	if length <= 0:
		return PackedVector2Array()

	# And never *finish* jammed against the city wall. `room_along` keeps a period's margin from
	# the boundary, which is enough on its own — but the truncation above can cut a route down to
	# almost nothing, and a route that starts near the edge and is cut short finishes there. What
	# that costs is stated on the loop below: a fire engine leaves its fire wherever it stops, and
	# a fire on the boundary was the bug that put this margin here in the first place. Refusing is
	# a re-roll; `tests/test_events_scheduler.gd`'s `_test_along_street_paths_stay_in_bounds`
	# checks it over all fourteen days.
	var finish := tile + along * length
	var edge := CityMap.period()
	var at_end: int = finish.x if along.x != 0 else finish.y
	var limit: int = _map.size.x if along.x != 0 else _map.size.y
	if at_end < edge or at_end > limit - edge:
		return PackedVector2Array()

	return PackedVector2Array([_map.tile_to_world(tile), _map.tile_to_world(finish)])

## A route straight across the street the tile sits on. A cat runs *across* traffic, so the
## path is perpendicular to the road it starts from: out from the tile each way, at most a street's
## width, as far as a figure on foot may stand (`CityMap.passable()`), so it comes out of one kerb
## and goes into the other and never starts or ends inside a lot. Empty, so the candidate is
## refused, where the tile is not one a figure on foot may stand on or nothing either side of it is.
func _cross_street_path(tile: Vector2i) -> PackedVector2Array:
	var vertical_road := CityMap.corridor_offset(tile.x) >= 0
	var across := Vector2i.RIGHT if vertical_road else Vector2i.DOWN
	var reach := Tuning.STREET_WIDTH
	var mover := _as_it_stops(Mover.on_foot())
	var ends: Array[Vector2i] = []
	for way: Vector2i in [-across, across]:
		var end := tile
		for step in range(1, reach + 1):
			if not _map.passable(tile + way * step, mover):
				break
			end = tile + way * step
		ends.append(end)
	if ends[0] == ends[1] or not _map.passable(tile, mover):
		return PackedVector2Array()
	return PackedVector2Array([_map.tile_to_world(ends[0]), _map.tile_to_world(ends[1])])

## `mover` as this builder's routes are stopped: as it is, or with today's bodies left out where
## the builder passes them (`without_todays_bodies()`).
func _as_it_stops(mover: Mover) -> Mover:
	if not _passes_todays_bodies or not mover.is_blocked_by(Mover.BODIES):
		return mover
	var layers := mover.layers_blocked() & ~Mover.BODIES
	if is_zero_approx(mover.body_reach()):
		return Mover.of(layers)
	return Mover.new(layers, mover.body_reach())
