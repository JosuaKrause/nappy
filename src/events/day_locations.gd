class_name DayLocations
extends RefCounted
## **Every street's locations for one day, laid out once at dawn and handed to whatever asks**
## (inbox #1185 in gentle-owl; `docs/EVENTS.md`, "The three views and the placement order"): each street's three
## sections and their sidewalk locations (`StreetLocations`), each told its view once
## (`Corridor.view_of()`), with the ground the city's fixed parts hold marked unavailable and what a
## phase has assigned taken for the day. The one object holding those answers, so nothing works
## them out again (inbox #1156 in gray-dolphin).
##
## **Laid out every day at dawn**, by the dawn's context (`DawnContext.locations()`) the first time
## `EventScheduler.build_day()` asks, after the routes are established and the day's holds are on
## the map. On day 13 the roadblock
## phase (`RoadblockPhase`) assigns its sections first; then every open location is drawn from its
## view's bag, a unit at a time (`UnitDraw`, `LocationDraw`; the units are grouped from `all()`).
## The day's planner hands the locations on to the walk
## (`DawnContext.locations()`, `DayPlanner.Plan.locations()`, `WalkEvents.locations()`), where day 13's
## task takes a section for its roadblock when none is close by (`nearest_section_in()`). Pure state:
## no node, nothing that runs.

var _streets := {}
## The ground beyond the streets: each alley's three locations, each open lot's grid of cells and
## each junction box, in the order the draw fills them.
var _grounds: Array[Location] = []

## The side of an open lot's cells, in tiles: about a section's ground (a section is 3 tiles by 6).
const OPEN_CELL := 4

## The day's locations on `map`, each street in the view `corridor` gives it. Every street the
## lattice has (`CityMap.street_segments()`), the ones a calm zone absorbed left out; then the
## ground beyond them (`Location.Kind`): each alley split along its length into three locations,
## each square or park into a grid of `OPEN_CELL`-tile cells, and each junction box its own
## location, each told the view of the nearest of its tiles to the routes (`Corridor.view_of_ground()`).
static func lay_out(map: CityMap, corridor: Corridor) -> DayLocations:
	var day := DayLocations.new()
	for segment in map.street_segments():
		day._streets[segment.key()] = StreetLocations.of(map, segment, corridor.view_of(segment))
	for alley: Rect2i in _lots(map, [GameEnums.TileType.ALLEY]):
		day._grounds.append_array(_split_in_three(map, corridor, alley))
	day._grounds.append_array(_cells_of(map, corridor, [GameEnums.TileType.PARK,
			GameEnums.TileType.SQUARE], Location.Kind.OPEN))
	day._grounds.append_array(_junction_boxes(map, corridor))
	return day

## **Every location**, open or not: street by street in the lattice's order, each street's sections
## and then its sidewalks, then the ground beyond the streets, as `open_locations()` walks them but
## unfiltered. What the day's units are grouped from (`DayUnits.of()`).
func all() -> Array[Location]:
	var found: Array[Location] = []
	for key: Vector3i in _streets:
		var street := _streets[key] as StreetLocations
		found.append_array(street.sections() + street.sidewalks())
	found.append_array(_grounds)
	return found

## **Records the draw's `plan` at `location`**, or nothing there for the empty event. An event drawn
## into a section (it spans the street or drives its carriageway) takes the section's sidewalk
## locations with it, as a roadblock assigned there does.
func record(location: Location, plan: EventPlan) -> void:
	if plan and location.kind() == Location.Kind.SECTION and location.segment():
		(_streets[location.segment().key()] as StreetLocations).take_section(location, plan)
	location.record(plan)

## **Every location still open to a phase**: available and neither taken nor drawn, street by
## street in the lattice's order (each street's sidewalk locations, then its sections), then the
## ground beyond the streets. Unshuffled, so a phase that draws among them draws on its own stream.
func open_locations() -> Array[Location]:
	var found: Array[Location] = []
	for key: Vector3i in _streets:
		var street := _streets[key] as StreetLocations
		for location in street.sidewalks() + street.sections():
			if location.is_available() and not location.is_taken() and not location.is_drawn():
				found.append(location)
	for location in _grounds:
		if location.is_available() and not location.is_taken() and not location.is_drawn():
			found.append(location)
	return found

## **The location holding `tile`, of ground `type`**: the one whose tiles hold it and whose kind takes
## that ground (`Location.takes()`), so a sidewalk tile names its sidewalk location and a carriageway
## tile its section; null where none does (a building, a corner a junction box leaves). What a fixed
## part's phase records on, and what an authored scene's tile names (`EventScheduler.recipe_placement()`).
func holding(tile: Vector2i, type: int) -> Location:
	for key: Vector3i in _streets:
		var street := _streets[key] as StreetLocations
		for location in street.sidewalks() + street.sections():
			if location.tiles().has_point(tile) and location.takes(type):
				return location
	for location in _grounds:
		if location.tiles().has_point(tile) and location.takes(type):
			return location
	return null

## **Records a fixed part on the location holding where it stands**, so no draw happens there (the
## design's fixed parts' phases: "a wall makes its location unavailable throughout"; a mast's
## location holds its mast on a day with one). `type` is the ground under it. A part standing where
## no location is records nothing.
func hold_fixed_part(plan: EventPlan, tile: Vector2i, type: int) -> void:
	var location := holding(tile, type)
	if location:
		assign_to(location, plan)

## Assigns `plan`, which a dawn phase placed in `location`, for the day, so no draw happens there:
## a section takes its two sidewalk locations with it, and a sidewalk closes its section to a draw
## (`StreetLocations.close_the_section_of()`).
func assign_to(location: Location, plan: EventPlan) -> void:
	if location.kind() == Location.Kind.SECTION and location.segment():
		(_streets[location.segment().key()] as StreetLocations).take_section(location, plan)
	else:
		location.take(plan)
		if location.kind() == Location.Kind.SIDEWALK and location.segment():
			(_streets[location.segment().key()] as StreetLocations).close_the_section_of(location)

## **The lots of `map` made of `types`**, each the rect of its connected tiles of those types
## (`rect -> {tile -> true}`, its tiles), in the order `CityMap.tiles_of_type()` meets their
## first tiles, type by type: the alleys for `ALLEY`, the parks and squares for `PARK` and `SQUARE`.
static func _lots(map: CityMap, types: Array) -> Dictionary:
	var seen := {}
	var found := {}
	var of_type := {}
	for type: int in types:
		of_type[type] = true
	var starts: Array[Vector2i] = []
	for type: int in types:
		starts.append_array(map.tiles_of_type(type as GameEnums.TileType))
	for start in starts:
		if seen.has(start):
			continue
		var rect := Rect2i(start, Vector2i.ONE)
		var tiles := {start: true}
		var queue: Array[Vector2i] = [start]
		seen[start] = true
		while not queue.is_empty():
			var at: Vector2i = queue.pop_back()
			rect = rect.expand(at).expand(at + Vector2i.ONE)
			for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next := at + step
				if not seen.has(next) and map.in_bounds(next) and of_type.has(map.tile_at(next)):
					seen[next] = true
					tiles[next] = true
					queue.append(next)
		found[rect] = tiles
	return found

## An alley's three locations, split along its longer side.
static func _split_in_three(map: CityMap, corridor: Corridor, alley: Rect2i) -> Array[Location]:
	var along := Vector2i.RIGHT if alley.size.x >= alley.size.y else Vector2i.DOWN
	var length := alley.size.x if along == Vector2i.RIGHT else alley.size.y
	var found: Array[Location] = []
	var start := 0
	for index in StreetLocations.SECTION_ENDS.size():
		var end := roundi(length * StreetLocations.SECTION_ENDS[index])
		if end > start:
			var size := Vector2i(end - start, alley.size.y) if along == Vector2i.RIGHT \
					else Vector2i(alley.size.x, end - start)
			found.append(_ground_location(map, corridor, Rect2i(alley.position + along * start, size),
					index, Location.Kind.ALLEY, alley))
		start = end
	return found

## The `OPEN_CELL`-tile cells holding any tile of `types`, in the map's order, each told the lot
## it is part of: the lot (`_lots()`) of its first tile of `types` in the map's order.
static func _cells_of(map: CityMap, corridor: Corridor, types: Array, kind: int) -> Array[Location]:
	var lot_of := {}
	var lots := _lots(map, types)
	for lot: Rect2i in lots:
		for tile: Vector2i in lots[lot]:
			lot_of[tile] = lot
	var cells := {}
	for type: int in types:
		for tile in map.tiles_of_type(type as GameEnums.TileType):
			cells[Vector2i(floori(tile.x / float(OPEN_CELL)), floori(tile.y / float(OPEN_CELL)))] = true
	var keys := cells.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	var found: Array[Location] = []
	for cell: Vector2i in keys:
		var rect := Rect2i(cell * OPEN_CELL, Vector2i.ONE * OPEN_CELL)
		found.append(_ground_location(map, corridor, rect, 0, kind, _first_lot_in(rect, lot_of)))
	return found

## The lot of the first tile of `rect`, in the map's order, that `lot_of` (`tile -> its lot`)
## names.
static func _first_lot_in(rect: Rect2i, lot_of: Dictionary) -> Rect2i:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var tile := Vector2i(x, y)
			if lot_of.has(tile):
				var lot: Rect2i = lot_of[tile]
				return lot
	return rect

## **Each junction box a street of the day meets, one location each** (`Location.Kind.JUNCTION`):
## the whole box, its sidewalk corners, its carriageway and its crossings, the one location the
## streets meeting there share. A box no street meets, inside a calm area that absorbed its streets,
## is that area's ground and not a junction's.
static func _junction_boxes(map: CityMap, corridor: Corridor) -> Array[Location]:
	var boxes := {}
	for segment in map.street_segments():
		var key := segment.key()
		var a := Vector2i(key.x, key.y)
		boxes[a] = true
		boxes[a + (Vector2i.RIGHT if key.z == 0 else Vector2i.DOWN)] = true
	var keys := boxes.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	var found: Array[Location] = []
	for junction: Vector2i in keys:
		var box := Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)
		found.append(_ground_location(map, corridor, box, 0, Location.Kind.JUNCTION, box))
	return found

## A location of no street over `tiles`, part of `whole` (`Location.part_of()`).
static func _ground_location(map: CityMap, corridor: Corridor, tiles: Rect2i, index: int,
		kind: int, whole: Rect2i) -> Location:
	var available := true
	for y in range(tiles.position.y, tiles.end.y):
		for x in range(tiles.position.x, tiles.end.x):
			if map.is_closed(Vector2i(x, y)):
				available = false
	return Location.new(null, index, tiles, map.tile_rect_to_world(tiles).get_center(),
			corridor.view_of_ground(tiles), available, kind, whole)

## The sections in `view` (`PlacementView.View`) that are available and not yet taken, street by
## street in the lattice's order and along each street in order.
func sections_in(view: int) -> Array[Location]:
	var found: Array[Location] = []
	for key: Vector3i in _streets:
		for section in (_streets[key] as StreetLocations).sections():
			if section.view() == view and section.is_available() and not section.is_taken():
				found.append(section)
	return found

## Assigns `plan`, an event that spans the street (`EventDef.spans_the_street()`), to `section` for
## the day: the section and its two sidewalk locations are taken, so no draw happens for them.
func assign(section: Location, plan: EventPlan) -> void:
	assert(plan.row().spans_the_street(),
			"DayLocations.assign(): only an event that spans the street takes a section")
	(_streets[section.segment().key()] as StreetLocations).take_section(section, plan)

## **The open section in `view` nearest along her paths**, for day 13's task when no roadblock is
## close by (inbox #1185 in gentle-owl: "if we don't find one closeby we swap one off screen route adjacent event
## with a roadblock"). `paths` is her paths from where she stands (`tile -> its distance along them`);
## a section is as near as the nearest of its own tiles they reach that `may_touch` (a tile) answers
## true for, and is passed over where `may_take` (the section) answers false: the caller's answer for
## her view and for what may be replaced. Null where no open section of `view` qualifies. *Read as, the orchestrator's and
## open to correction:* nearest along her paths (fork 7 of the placement proposal), with no cap on the
## distance, and a section whose locations are not yet drawn qualifying like any other.
func nearest_section_in(view: int, paths: Dictionary, may_touch: Callable,
		may_take: Callable) -> Location:
	var ranked: Array = []
	for section in sections_in(view):
		var nearest := INF
		var tiles := section.tiles()
		for y in range(tiles.position.y, tiles.end.y):
			for x in range(tiles.position.x, tiles.end.x):
				var tile := Vector2i(x, y)
				if paths.has(tile) and float(paths[tile]) < nearest and may_touch.call(tile):
					nearest = float(paths[tile])
		if nearest < INF:
			ranked.append([nearest, section])
	ranked.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for entry: Array in ranked:
		if may_take.call(entry[1]):
			return entry[1]
	return null
