extends RefCounted
## **What day 12's police cordon shows in the world**, read the way the rest of the game meets it,
## for a suite that plays the day through the director (`ResistanceDirector.tick()`) and so holds
## no `ParkCordon` of its own: not a suite, a helper.
##
## The cordon is the happenings' own, and nothing in the game asks the director for it, so a suite
## that plays the day through the director reads it off what it puts in the world: its officers,
## each a figure on the city's entity layer (`CordonOfficer`), and the ground, where every taped
## stretch is recorded as obstructed (`WorldMap.obstructed_tiles`), which is what shuts the park to
## anyone walking (`is_shut()`).

## The park's calm ground in world space: what the cordon is closing, read off the map as the
## ground it is.
static func park_ground(map: CityMap, park: Vector2i) -> Rect2:
	return map.tile_rect_to_world(ClosurePlanner.calm_area_rect(map, park))

## The rectangle the tape stands on: the park's ground, half a barrier's depth in, where the tape's
## bodies lie (the suites that read the tape's bodies hold it to them). She is shut in when she is
## inside it as the last gap is taped.
static func tape_line(map: CityMap, park: Vector2i) -> Rect2:
	return park_ground(map, park).grow(-Tuning.CLOSURE_BARRIER_DEPTH * 0.5)

## The cordon's officers standing in the city now.
static func officers(city: City) -> Array[CordonOfficer]:
	var found: Array[CordonOfficer] = []
	for figure in city.get_node("Entities").get_children():
		if figure is CordonOfficer and not figure.is_queued_for_deletion():
			found.append(figure)
	return found

## What shuts ground to someone on foot today: the closures and every solid body, the tape included.
static func shut_tiles(map: CityMap) -> Dictionary:
	var shut := map.closed_tiles.duplicate()
	shut.merge(map.obstructed_tiles)
	return shut

## Whether nobody on foot can get from `inside`, a point in the park, to the home: the park is
## taped shut. Open ground reaches the home by way of the park's edge until the last gap is taped.
static func is_shut(map: CityMap, inside: Vector2) -> bool:
	var field := map.walk_field(map.world_to_tile(inside), shut_tiles(map))
	return not map.reaches(field, map.home_rect.position)

## The tape standing in the city now: one `CordonTape` per taped stretch of the edge, each a static
## body the physics world blocks her with. The posts the officers plant at the stretches' ends are
## not tape, and a piece the cordon has let go (queued to be freed) is not standing.
static func tapes(city: City) -> Array[CordonTape]:
	var found: Array[CordonTape] = []
	for piece in city.get_node("Entities").get_children():
		if piece is CordonTape and piece.piece == CordonTape.Piece.TAPE \
				and not piece.is_queued_for_deletion():
			found.append(piece)
	return found

## The world rect a tape's static body covers, read off its collision shape in the tree (what the
## physics world blocks her with), or an empty rect when it has none.
static func body_rect(tape: CordonTape) -> Rect2:
	for child in tape.get_children():
		if child is StaticBody2D:
			for part in child.get_children():
				if part is CollisionShape2D and part.shape is RectangleShape2D:
					var size: Vector2 = part.shape.size
					return Rect2(part.global_position - size * 0.5, size)
	return Rect2()

## The two ends of the line a tape's body runs along, read off the body: the tape's length, centred.
static func ends(tape: CordonTape) -> PackedVector2Array:
	var centre := body_rect(tape).get_center()
	var half := Vector2(tape.length * 0.5, 0.0) if tape.across else Vector2(0.0, tape.length * 0.5)
	return PackedVector2Array([centre - half, centre + half])

## Whether a body centred at `at` stands within `reach` of tape that is up.
static func is_beside_tape(city: City, at: Vector2, reach: float) -> bool:
	for tape in tapes(city):
		var line := ends(tape)
		if Geometry2D.get_closest_point_to_segment(at, line[0], line[1]).distance_to(at) < reach:
			return true
	return false

## Whether a step from `from` to `to` crosses tape that is up.
static func is_across_tape(city: City, from: Vector2, to: Vector2) -> bool:
	for tape in tapes(city):
		var line := ends(tape)
		if Geometry2D.segment_intersects_segment(from, to, line[0], line[1]) != null:
			return true
	return false

## The tiles of the park's edge row that open onto walkable ground, so need tape to shut the park, each
## with the side of the park it is on, going round clockwise from the north-west corner (a corner
## tile once for each side it is on). What `ParkClosure.fence()` plans the park's fence over.
static func edge_tiles_to_tape(map: CityMap, park: Vector2i) -> Array:
	var rect := ClosurePlanner.calm_area_rect(map, park)
	var runs: Array[ParkClosure] = ParkClosure.fence(map, park)
	var ring: Array = []
	for x in range(rect.position.x, rect.end.x):
		ring.append([Vector2i(x, rect.position.y), Vector2i.UP])
	for y in range(rect.position.y, rect.end.y):
		ring.append([Vector2i(rect.end.x - 1, y), Vector2i.RIGHT])
	for x in range(rect.end.x - 1, rect.position.x - 1, -1):
		ring.append([Vector2i(x, rect.end.y - 1), Vector2i.DOWN])
	for y in range(rect.end.y - 1, rect.position.y - 1, -1):
		ring.append([Vector2i(rect.position.x, y), Vector2i.LEFT])
	var needed: Array = []
	for entry: Array in ring:
		for run in runs:
			if run.outward == entry[1] and run.segment.tile_rect().has_point(entry[0]):
				needed.append(entry)
				break
	return needed

## How many separate runs of the park's edge that need tape are still open (not yet obstructed), going
## round it: one until the last gap is taped, then none.
static func open_gaps(map: CityMap, park: Vector2i) -> int:
	var ring := edge_tiles_to_tape(map, park)
	var open: Array[bool] = []
	for entry: Array in ring:
		open.append(not map.is_obstructed(entry[0]))
	var runs := 0
	for i in open.size():
		if open[i] and not open[(i - 1 + open.size()) % open.size()]:
			runs += 1
	if runs == 0 and not open.is_empty() and open[0]:
		runs = 1
	return runs

## Whether every edge tile that needs tape is obstructed except those of `gap`'s tiles: the tapers
## have taped all of the edge but the last gap.
static func is_only_the_gap_open(map: CityMap, park: Vector2i, gap_tiles: Array[Vector2i]) -> bool:
	for entry: Array in edge_tiles_to_tape(map, park):
		if not map.is_obstructed(entry[0]) and not gap_tiles.has(entry[0]):
			return false
	return true
