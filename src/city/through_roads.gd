class_name ThroughRoads
extends RefCounted
## **The streets a car can drive into and go on from, without turning round**: of the stretches of
## carriageway between two junction boxes, the ones that are a car's from the middle of one box to
## the middle of the next, and whose two boxes each keep a second such stretch to leave by once
## every box with fewer than two has been dropped, with its stretches, until none is left to drop
## (the 2-core of the graph of boxes and stretches). A car that leaves every box it comes to by one
## of these, never by the way it came in, always has a stretch to leave by, so it never comes to a
## precinct's paving, a closed street, a street a calm zone absorbed or the map's edge, and never
## turns round. `WayOn` drives a row sent ahead of her by it.
##
## Worked out once for a walk (`over()`), from the map as it stands then: its ground, a precinct's
## paving and posts, today's closures and the bodies standing on it, as the mover it is handed is
## stopped by them. Nothing it answers changes afterwards: a body put down later in the walk is asked
## of the ground itself, leg by leg (`WayOn.drives_clear()`).
##
## Model: a function of the map, no node.

## The open stretches: `Vector3i(box.x, box.y, 0)` for the one east of box `(x, y)` and
## `Vector3i(box.x, box.y, 1)` for the one south of it, boxes numbered by their corridors.
var _stretches: Dictionary[Vector3i, bool] = {}

## The through roads of `map` as `as_it_drives` may stand on it now.
static func over(map: CityMap, as_it_drives: Mover) -> ThroughRoads:
	var roads := ThroughRoads.new()
	roads._survey(map, as_it_drives)
	return roads

## **Whether a car at junction box `box`** (its corridors' indices) **may take the street leaving it
## `toward`** (one step along one axis): that stretch is a car's to the next box, and from the next
## box there is a way on that is not the way back.
func goes_on(box: Vector2i, toward: Vector2i) -> bool:
	return _stretches.has(_key(box, toward))

static func _key(box: Vector2i, toward: Vector2i) -> Vector3i:
	var from := box if toward.x + toward.y > 0 else box + toward
	return Vector3i(from.x, from.y, 0 if toward.x != 0 else 1)

## Finds every stretch a car may drive, then drops, until none is left to drop, each box with fewer
## than two of them and its stretches with it: what is left is where a car always has a way on.
func _survey(map: CityMap, as_it_drives: Mover) -> void:
	var period := CityMap.period()
	var size := map.size_in_tiles()
	var boxes := Vector2i((size.x - Tuning.STREET_WIDTH) / period + 1,
			(size.y - Tuning.STREET_WIDTH) / period + 1)
	var ways: Dictionary[Vector2i, Array] = {}
	for y in boxes.y:
		for x in boxes.x:
			var box := Vector2i(x, y)
			for toward: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
				var next := box + toward
				if next.x >= boxes.x or next.y >= boxes.y:
					continue
				if not _is_a_cars(map, as_it_drives, box, toward):
					continue
				if not ways.has(box):
					ways[box] = []
				if not ways.has(next):
					ways[next] = []
				ways[box].append(next)
				ways[next].append(box)
	var dead: Array[Vector2i] = []
	for box: Vector2i in ways:
		if ways[box].size() < 2:
			dead.append(box)
	while not dead.is_empty():
		var box: Vector2i = dead.pop_back()
		if not ways.has(box):
			continue
		for other: Vector2i in ways[box]:
			ways[other].erase(box)
			if ways[other].size() < 2 and not dead.has(other):
				dead.append(other)
		ways.erase(box)
	for box: Vector2i in ways:
		for other: Vector2i in ways[box]:
			_stretches[_key(box, other - box)] = true

## Whether both lanes from the middle of `box` to the middle of the next box `toward` are a car's:
## carriageway (`CityMap.is_carriageway()`, so not a street a calm zone absorbed), no precinct's
## paving (`CityMap.is_driveable_at()`), on the map, and ground `as_it_drives` may stand on.
static func _is_a_cars(map: CityMap, as_it_drives: Mover, box: Vector2i,
		toward: Vector2i) -> bool:
	var period := CityMap.period()
	var vertical := toward.y != 0
	var first: int = CrowdLanes.ROAD_OFFSETS[0]
	var last: int = CrowdLanes.ROAD_OFFSETS[CrowdLanes.ROAD_OFFSETS.size() - 1]
	var along_from := (box.y if vertical else box.x) * period + first
	var along_to := along_from + period + (last - first)
	var across := (box.x if vertical else box.y) * period
	for lane: int in CrowdLanes.ROAD_OFFSETS:
		for along in range(along_from, along_to + 1):
			var tile := Vector2i(across + lane, along) if vertical \
					else Vector2i(along, across + lane)
			if not map.in_bounds(tile) or not map.is_carriageway(tile) \
					or not map.is_driveable_at(vertical, tile) \
					or not map.passable(tile, as_it_drives):
				return false
	return true
