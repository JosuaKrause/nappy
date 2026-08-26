class_name EventScheduler
extends RefCounted
## Builds one day's event set from the run seed and the day index. See docs/EVENTS.md.
##
## Deterministic: the same seed and day always produce the same plan, which is what lets a
## player learn a run. Nothing here touches the global RNG.

## What the manager needs to spawn one instance.
class Planned extends RefCounted:
	var def: EventDef
	var position: Vector2
	var path := PackedVector2Array()

	func _init(definition: EventDef, at: Vector2,
			route := PackedVector2Array()) -> void:
		def = definition
		position = at
		path = route

## Budget grows with the day, so late days are denser as well as nastier.
static func budget_for(day: int) -> int:
	return 3 + floori(day * 1.4)

## Plans a day. `consumed_one_shots` is read and appended to, so a one-shot fires once
## per run.
static func build_day(day: int, rng: RandomNumberGenerator, map: CityMap,
		consumed_one_shots: Array[String], scars: Array[Dictionary] = []) -> Array[Planned]:
	var planned: Array[Planned] = []

	planned.append_array(_place_ambient(day, map))
	planned.append_array(_place_scars(day, scars))
	planned.append_array(_place_scripted(day, rng, map))
	planned.append_array(_place_one_shots(day, rng, map, consumed_one_shots))
	planned.append_array(_fill_with_recurring(day, rng, map))

	_ensure_one_usable_park(map, planned)
	_ensure_the_city_is_still_walkable(map, planned)
	return planned

## Permanent marks left by earlier days, placed again exactly where they happened.
static func _place_scars(day: int, scars: Array[Dictionary]) -> Array[Planned]:
	var planned: Array[Planned] = []
	for scar in scars:
		if int(scar["since_day"]) >= day:
			continue
		var def := EventCatalogue.by_id(String(scar["id"]))
		if def:
			planned.append(Planned.new(def, scar["position"]))
	return planned

# ----------------------------------------------------------------- placement ---

static func _place_ambient(day: int, map: CityMap) -> Array[Planned]:
	var planned: Array[Planned] = []
	for def in EventCatalogue.of_kind(GameEnums.EventKind.AMBIENT, day):
		match def.ambient_source:
			EventDef.AmbientSource.PLAYGROUND:
				for rect in map.playgrounds:
					planned.append(Planned.new(def, map.tile_rect_to_world(rect).get_center()))
			_:
				pass
	return planned

static func _place_scripted(day: int, rng: RandomNumberGenerator, map: CityMap) -> Array[Planned]:
	var planned: Array[Planned] = []
	for def in EventCatalogue.of_kind(GameEnums.EventKind.SCRIPTED, day):
		var placement := _place_one(def, rng, map)
		if placement:
			planned.append(placement)
	return planned

static func _place_one_shots(day: int, rng: RandomNumberGenerator, map: CityMap,
		consumed: Array[String]) -> Array[Planned]:
	var planned: Array[Planned] = []
	for def in EventCatalogue.of_kind(GameEnums.EventKind.ONE_SHOT, day):
		if def.id in consumed:
			continue
		# Spread a one-shot over the days it is eligible for rather than always firing it
		# on the first: 1/n chance per remaining day makes it feel like an accident.
		var remaining := maxi(1, (def.last_day if def.last_day > 0 else def.first_day + 2) - day + 1)
		if rng.randf() > 1.0 / float(remaining):
			continue
		var placement := _place_one(def, rng, map)
		if placement:
			planned.append(placement)
			consumed.append(def.id)
	return planned

static func _fill_with_recurring(day: int, rng: RandomNumberGenerator,
		map: CityMap) -> Array[Planned]:
	var planned: Array[Planned] = []
	var eligible := EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day)
	if eligible.is_empty():
		return planned

	var budget := budget_for(day)
	var counts := {}
	# Bounded rather than while-true: a catalogue where nothing affordable remains would
	# otherwise spin forever.
	for _attempt in budget * 4:
		if budget <= 0:
			break
		var affordable: Array[EventDef] = []
		for def in eligible:
			if def.cost <= budget and int(counts.get(def.id, 0)) < def.max_per_day:
				affordable.append(def)
		if affordable.is_empty():
			break
		var def := _pick_weighted(affordable, rng)
		var placement := _place_one(def, rng, map)
		if not placement:
			continue
		planned.append(placement)
		counts[def.id] = int(counts.get(def.id, 0)) + 1
		budget -= def.cost
	return planned

static func _pick_weighted(defs: Array[EventDef], rng: RandomNumberGenerator) -> EventDef:
	var total := 0.0
	for def in defs:
		total += def.weight
	var roll := rng.randf() * total
	for def in defs:
		roll -= def.weight
		if roll <= 0.0:
			return def
	return defs[defs.size() - 1]

## Picks a tile of an allowed type and builds the path, if the event moves.
static func _place_one(def: EventDef, rng: RandomNumberGenerator, map: CityMap) -> Planned:
	var candidates: Array[Vector2i] = []
	for type in def.placement:
		candidates.append_array(map.tiles_of_type(type as GameEnums.TileType))
	if candidates.is_empty():
		return null

	var tile: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
	var at := map.tile_to_world(tile)
	if not def.mobile:
		return Planned.new(def, at)

	match def.path_mode:
		EventDef.PathMode.CROSS_STREET:
			return Planned.new(def, at, _cross_street_path(map, tile))
		EventDef.PathMode.ALONG_STREET:
			var route := _along_street_path(map, tile, def, rng)
			# Nowhere to go from here; let the caller re-roll rather than placing a
			# "mobile" event that stands still.
			return null if route.is_empty() else Planned.new(def, at, route)
		_:
			return Planned.new(def, at)

## Distance in tiles from a tile to the edge of the map along a direction, less a
## one-block margin so a route always ends inside the city rather than against the wall.
static func _room_along(map: CityMap, tile: Vector2i, direction: Vector2i) -> int:
	var margin := CityMap.period()
	var room := 0
	if direction.x > 0:
		room = map.size.x - 1 - tile.x
	elif direction.x < 0:
		room = tile.x
	elif direction.y > 0:
		room = map.size.y - 1 - tile.y
	else:
		room = tile.y
	return maxi(0, room - margin)

## A route down the corridor the tile sits on, for traffic and for anyone walking a dog.
##
## Direction is a coin flip *between the directions that have room*, and the length is
## clamped to what actually fits. Clamping the endpoint to the map bounds instead — the
## first version — parked every long route hard against the city wall, which put the fire
## the engine leaves behind out on the boundary every single time.
static func _along_street_path(map: CityMap, tile: Vector2i, def: EventDef,
		rng: RandomNumberGenerator) -> PackedVector2Array:
	var vertical_corridor := CityMap.corridor_offset(tile.x) >= 0
	var forward := Vector2i.DOWN if vertical_corridor else Vector2i.RIGHT
	var backward := -forward

	var forward_room := _room_along(map, tile, forward)
	var backward_room := _room_along(map, tile, backward)
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
	if length <= 0:
		return PackedVector2Array()
	return PackedVector2Array([
		map.tile_to_world(tile), map.tile_to_world(tile + along * length)])

## A route straight across the street the tile sits on. A cat runs *across* traffic, so the
## path is perpendicular to the road it starts from.
static func _cross_street_path(map: CityMap, tile: Vector2i) -> PackedVector2Array:
	var vertical_road := CityMap.corridor_offset(tile.x) >= 0
	var across := Vector2i.RIGHT if vertical_road else Vector2i.DOWN
	var reach := Tuning.STREET_WIDTH
	var from := map.tile_to_world(tile - across * reach)
	var to := map.tile_to_world(tile + across * reach)
	return PackedVector2Array([from, to])

# ---------------------------------------------------------------- park rules ---

## docs/CITY.md: at least one calm zone stays usable every day, or the day has no safe
## ground and the player has no move. Whichever one is least disturbed keeps its quiet.
##
## Since M14 this is the difference between a hard day and an impossible one, and since M15
## the set of calm zones is whatever the arcs have left — a requisitioned park is not a
## candidate, because it is not calm any more.
##
## Ambient events do not count as spoiling. A playground is a permanent feature of the map,
## not something that went wrong today — it makes a park *contested*, which is the point,
## and it leaves the far side of the block calm. Counting it here would mean stripping a
## playground out of one park every single day.
static func _ensure_one_usable_park(map: CityMap, planned: Array[Planned]) -> void:
	if map.calm_blocks.is_empty():
		return

	var spoilers := {}   # calm block -> Array[Planned]
	var clean := false
	for block in map.calm_blocks:
		# The calm *ground*, not the whole block. A courtyard's calm is a four-tile court
		# inside a residential block; protecting the block would strip every event off a
		# street the player was never going to settle on anyway.
		var lot := map.tile_rect_to_world(_calm_rect(map, block))
		var found: Array[Planned] = []
		for plan in planned:
			if plan.def.kind == GameEnums.EventKind.AMBIENT:
				continue
			if _reaches_rect(plan, lot):
				found.append(plan)
		if found.is_empty():
			clean = true
		spoilers[block] = found
	if clean:
		return

	var least: Vector2i = map.calm_blocks[0]
	for block in map.calm_blocks:
		if spoilers[block].size() < spoilers[least].size():
			least = block
	for plan in spoilers[least]:
		planned.erase(plan)

## The rect of a calm block's actual calm ground, falling back to the whole lot.
static func _calm_rect(map: CityMap, block: Vector2i) -> Rect2i:
	var layout: BlockLayout = map.block_layouts.get(block)
	if layout and BlockLayout.has(layout.open_rect):
		return layout.open_rect
	return CityMap.block_rect(block)

## Checkpoints, barricades and roadblocks physically close streets, and from Act IV several
## can land on the same day. Any combination that seals the home off from every park makes
## the day unwinnable in a way the player cannot see coming, so obstructions are dropped —
## widest first — until a route exists again.
##
## Hard-fail events count as walls here too: an abduction in progress is not something you
## walk through to reach the park behind it.
static func _ensure_the_city_is_still_walkable(map: CityMap, planned: Array[Planned]) -> void:
	var blockers: Array[Planned] = []
	for plan in planned:
		if plan.def.obstructs_radius > 0.0 or plan.def.hard_fail:
			blockers.append(plan)
	if blockers.is_empty():
		return

	blockers.sort_custom(func(a: Planned, b: Planned) -> bool:
		return _blocking_radius(a) > _blocking_radius(b))

	while not blockers.is_empty() and not _park_is_reachable(map, blockers):
		planned.erase(blockers.pop_front())

static func _blocking_radius(plan: Planned) -> float:
	return maxf(plan.def.obstructs_radius, plan.def.inner_radius if plan.def.hard_fail else 0.0)

static func _park_is_reachable(map: CityMap, blockers: Array[Planned]) -> bool:
	var blocked := {}
	for plan in blockers:
		var radius := _blocking_radius(plan)
		var reach := ceili(radius / float(Tuning.TILE_SIZE))
		var centre := map.world_to_tile(plan.position)
		for dy in range(-reach, reach + 1):
			for dx in range(-reach, reach + 1):
				var tile := centre + Vector2i(dx, dy)
				if map.tile_to_world(tile).distance_to(plan.position) <= radius:
					blocked[tile] = true

	var reachable := map.walk_distances(map.home_rect.position, blocked)
	if reachable.is_empty():
		return false
	for tile in map.calm_tiles():
		if reachable.has(tile):
			return true
	return false

## Whether an event's outer radius touches a rect at all.
static func _reaches_rect(plan: Planned, rect: Rect2) -> bool:
	var grown := rect.grow(plan.def.outer_radius)
	if grown.has_point(plan.position):
		return true
	for point in plan.path:
		if grown.has_point(point):
			return true
	return false
