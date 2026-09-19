class_name CrowdPockets
extends RefCounted
## The carriageway today's seals have left a car able to drive into and not out of.
##
## A **pocket** is a connected piece of the roadway that no street leads out of — a junction with
## all four of its arms held, and whatever stub of lane is sealed in with it. A car put there has
## nowhere to go and no way of finding out: a turn is an arc that needs a junction box to fit in and
## there is no reverse gear, so it drives to one seal, cannot turn round against it, and stands
## nose-on for the rest of the day with the queue behind it. *(2026-09-12: "pedestrians with nowhere
## to go (all four sides of the intersection are blocked off) should just despawn (or never spawn in
## the first place) right now they're accumulating in one place and move back and forth or worth
## flicker … the same with cars".)*
##
## **It is a car's record and there is no walker half, which is the point of the record.**
## *(2026-09-19: "the pacing back and forth I complained about was because walkers never actually
## tried walking to the edge. they saw that a road section was closed of and never entered it. this
## shouldn't happen. they should still go into the section until they cannot continue.")* A walker
## turns round in a stride wherever it stands, so sealed-in ground is ground it can walk the whole
## of: it goes down each stub to the barrier at the end of it, about-faces there, and walks the next
## one — which is a person exploring a blocked-off block and not a person with nowhere to go. What
## produced the pacing was the lookahead giving a street up from a junction away, and
## `CrowdAgent._acts_on_a_barrier_within()` is where that was fixed; emptying the ground of walkers
## was answering the symptom.
##
## **It is a property of the day's map rather than a search an agent runs.** The inputs are the ones
## the crowd already reads — `CityMap.held_segments`, `closed_tiles` and which ground is driveable —
## and they are fixed for the day, so one flood answers for every car for the whole of it. A
## per-agent version of the same question is a flood fill per placement, six times over per recycle,
## several times a second.
##
## **The test for "no street leads out" is how many junctions the piece reaches.** A segment is
## precisely what carries an agent from one junction to the next, so a piece of lane that touches two
## of them has a street out of it by construction and a piece that touches at most one has none. That
## is deliberately the conservative reading: a longer stretch of city that today's seals have cut off
## whole — two junctions or more of it — is somewhere a car can still drive about, and emptying it
## would be taking the traffic off streets the player can see nothing wrong with.

## Per-tile answers, `1` where the tile is in a pocket, indexed `y * size.x + x` the way
## `CityMap.walk_field` indexes its own sweep and for the same reason: this is asked once per car
## per frame and a `Vector2i` key hashes a Variant to answer what an index answers.
var _cars := PackedByteArray()
var _size := Vector2i.ZERO
## The day-record version the answer above was built from, so `refresh()` is a single integer
## comparison on the frames — which is all of them but a handful — where nothing has moved. `-1` is
## "never built", which no version ever is.
var _built_from := -1

## Rebuilds the answer if the day's holds or closures have moved since the last one, and does
## nothing at all otherwise. Called from `Crowd.start_day()` once the day's seals are planned, and
## once a frame after that, so that a seal placed under a crowd that is already standing there
## reaches the agents without anybody having to remember to ask.
##
## `crossable_segments` is the crowd's own carve-out from `held_segments` — the region's door
## segments and the streets around the home block, which are held so that no catalogue row lands on
## them rather than because anything stands across them. See `Crowd._door_segments` and
## `Crowd._home_segments`.
func refresh(map: CityMap, crossable_segments: Dictionary) -> void:
	if map == null:
		return
	if map.day_record_version == _built_from and map.size == _size:
		return
	_built_from = map.day_record_version
	_size = map.size
	_cars = _flood(map, crossable_segments)

## Whether a tile is in a pocket. False for anything that is not carriageway a car travels at all —
## a pavement, a tile off the map — because "there is nowhere to go from here" is a statement about
## ground a car could have been placed on, and everywhere else already has an answer of its own.
func holds(tile: Vector2i) -> bool:
	if tile.x < 0 or tile.y < 0 or tile.x >= _size.x or tile.y >= _size.y:
		return false
	if _cars.is_empty():
		return false
	return _cars[tile.y * _size.x + tile.x] == 1

## How many tiles are pocketed. The guard a test needs against a sweep that found nothing: an
## assertion that no car stands in a pocket passes on its own when there is no pocket.
func tile_count() -> int:
	var total := 0
	for value in _cars:
		total += value
	return total

# ------------------------------------------------------------------- the flood ---

## Paint the carriageway, take away what today has shut, and label every connected piece that
## reaches at most one junction.
func _flood(map: CityMap, crossable_segments: Dictionary) -> PackedByteArray:
	var width := map.size.x
	var cells := width * map.size.y
	var ground := PackedByteArray()
	ground.resize(cells)
	for y in map.size.y:
		var row := y * width
		for x in map.size.x:
			ground[row + x] = 1 if _is_a_lane(map, Vector2i(x, y)) else 0
	_shut_the_held_segments(map, crossable_segments, ground, width)
	for tile: Vector2i in map.closed_tiles:
		if map.in_bounds(tile):
			ground[tile.y * width + tile.x] = 0

	var pockets := PackedByteArray()
	pockets.resize(cells)
	var queue := PackedInt32Array()
	queue.resize(cells)
	for start in cells:
		if ground[start] != 1:
			continue
		var tail := 0
		var head := 0
		queue[tail] = start
		tail += 1
		ground[start] = 2
		var first := Vector2i(-1, -1)
		var leads_out := false
		while head < tail:
			var index := queue[head]
			head += 1
			# Floored through a float rather than integer-divided: `int / int` is a warning here and
			# a warning is an error in this project's parse.
			var y := floori(float(index) / float(width))
			var x := index - y * width
			var junction := CityMap.junction_at(Vector2i(x, y))
			if junction.x >= 0:
				if first.x < 0:
					first = junction
				elif junction != first:
					leads_out = true
			# The row's own ends for left and right, the same fencepost `CityMap.walk_field` keeps:
			# the grid is one array, so a step off the left edge lands on the row above.
			if x > 0 and ground[index - 1] == 1:
				ground[index - 1] = 2
				queue[tail] = index - 1
				tail += 1
			if x < width - 1 and ground[index + 1] == 1:
				ground[index + 1] = 2
				queue[tail] = index + 1
				tail += 1
			if index >= width and ground[index - width] == 1:
				ground[index - width] = 2
				queue[tail] = index - width
				tail += 1
			if index + width < cells and ground[index + width] == 1:
				ground[index + width] = 2
				queue[tail] = index + width
				tail += 1
		if leads_out:
			continue
		for i in tail:
			pockets[queue[i]] = 1
	return pockets

## Whether a tile is a piece of the roadway a car actually travels: the carriageway, and a junction
## box, since that is where one corridor's lanes meet the next one's.
##
## **Stated over the lane rather than over "a street tile"**, because a flood over all of a
## corridor's tiles would read the pavements as road a sealed-in car could drive away down, which is
## the one place on a street a car never goes. A precinct is paved end to end and is a wall to a car,
## so it is not lane either.
func _is_a_lane(map: CityMap, tile: Vector2i) -> bool:
	if not map.is_street(tile):
		return false
	if not map.is_driveable_at(true, tile):
		return false
	var across_x := CityMap.corridor_offset(tile.x)
	var across_y := CityMap.corridor_offset(tile.y)
	if across_x >= 0 and across_y >= 0:
		return true
	if across_x < 0 and across_y < 0:
		return false
	var offset := across_x if across_x >= 0 else across_y
	return CityMap.is_road_offset(offset)

## Takes today's held segments out of the open ground — a hard seal's street, a region wall's, a
## closure's — except the ones the crowd is carved out of. Painted from the segments themselves
## rather than asked per tile: `held_segments` holds a handful of keys and each one knows its own
## tile rect, where the per-tile question is a `StreetNetwork` lookup twenty-five thousand times over.
func _shut_the_held_segments(map: CityMap, crossable_segments: Dictionary, ground: PackedByteArray,
		width: int) -> void:
	for key: Vector3i in map.held_segments:
		if crossable_segments.has(key):
			continue
		var segment := StreetNetwork.by_key(key)
		if segment == null:
			continue
		var rect := segment.tile_rect()
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				if map.in_bounds(Vector2i(x, y)):
					ground[y * width + x] = 0
