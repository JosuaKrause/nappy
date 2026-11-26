class_name WayOn
extends RefCounted
## **The next leg of a route that is worked out as it goes** *(inbox #1460 in silky-lemur: "the route only matters
## *after* it was spawned", "and then only if the player follows them around", "so the route can be
## ad-hoc")*: from where a row the director sent ahead of her stands, the way it goes on, or nothing
## where it has none.
##
## **A row of the road drives on from junction box to junction box** (`_down_the_road()`): straight
## through the next box where the street beyond it is a through road (`ThroughRoads`), and otherwise
## round the corner in that box onto the crossing street, the turn that leads away from her first.
## It never takes a street it could not go on from, so it never comes to a precinct's paving, a
## closed street, a street a calm zone absorbed or the map's edge, and it never turns round. **A row
## on foot walks straight on** down the street it is on (`_on_foot()`), and has no way on where it
## cannot.
##
## **One reading says how a car drives a stretch of road, or that it may not** (`driven()`), asked of
## every leg here and of the first leg the director lays (`EventDirector.leg_in_the_lane()`): round
## anything standing in its own lane by the street's other lane, where that lane is free past it,
## and then asked whole of the ground (`_drives_clear()`).
##
## No stream is drawn from: a leg is a function of where the row stands, where she is and the map.
## Made once a walk, over the walk's through roads, and handed to the director
## (`EventDirector.use_way_on()`), which tells it the day's rule.

## How far a row on foot walks on in one leg, in tiles: a street and the junction box at its end.
const LEG_TILES := Tuning.BLOCK_SIZE + Tuning.STREET_WIDTH
## The least a leg on foot may be, in tiles: under it the row has no way on.
const LEAST_TILES := 2
## **The radius a car rounds a corner at**, in px: a lane's centre from its own kerb, the radius the
## lattice gives the crowd's cars' near-side turn (the **crowd-traffic** skill's
## `references/turns.md`), which fits both arms of a box, since two lanes meet 80px or 112px inside
## it.
const TURN_RADIUS := Tuning.TILE_SIZE * 0.5
## How many straight pieces a quarter turn is driven as.
const TURN_PIECES := 3
## How finely `_drives_clear()` asks the ground along a leg, in px.
const ASKED_EVERY := Tuning.TILE_SIZE * 0.5
## **How far along its street a car takes to cross into the other lane, and back again**, in px,
## when it drives round something standing in its own (`driven()`): a tile, so the car is wholly in
## the other lane by the near edge of the first tile it could not drive and back in its own a tile
## past the last, and a crater a lane wide costs a car three tiles of the other lane.
const SWERVE := float(Tuning.TILE_SIZE)

var _map: CityMap
var _navigator: Navigator
var _roads: ThroughRoads
## `(leg: PackedVector2Array, row: EventDef) -> bool`: whether the day lets the row take the leg
## (`EventDirector.clear_to_go_on()`), or invalid for none to ask.
var _may_take := Callable()

## Handed the map, the navigator its rows move by, and the walk's through roads.
func _init(map: CityMap, navigator: Navigator, roads: ThroughRoads) -> void:
	_map = map
	_navigator = navigator
	_roads = roads

## Hands in what answers for the day's placed plans and doors (`EventDirector.clear_to_go_on()`).
func use_the_days_rule(may_take: Callable) -> void:
	_may_take = may_take

## **The next leg for `row` standing at `at` and going `heading`, with her at `her`**: its points from
## `at` on, or empty where it has no way on. Each leg is asked of the day's rule, since a row still
## going on is live.
func next_leg(row: EventDef, at: Vector2, heading: Vector2, her: Vector2) -> PackedVector2Array:
	if row.keeps_to_the_carriageway():
		return _down_the_road(row, at, heading, her, _may_take)
	return _on_foot(row, at, heading, _may_take)

## **The leg for `row` standing at `at` and going `heading` that leaves the next junction box it
## comes to by `out`** (a unit: straight on, or one of the two turns), with her at `her`: as
## `next_leg()` for a row of the road, with the way out of the box given rather than taken in order,
## so the director can send its convoy round a corner toward her
## (`EventDirector._round_the_corner_toward()`); empty where the box is not left that way.
func leg_out_by(row: EventDef, at: Vector2, heading: Vector2, out: Vector2,
		her: Vector2) -> PackedVector2Array:
	return _down_the_road(row, at, heading, her, _may_take,
			Vector2i(roundi(out.x), roundi(out.y)))

## **The leg a row that is leaving goes on by**: as `next_leg()`, with nothing asked of the day, since
## a row that is leaving is over and emits nothing.
func leg_to_leave_by(row: EventDef, at: Vector2, heading: Vector2,
		her: Vector2) -> PackedVector2Array:
	if row.keeps_to_the_carriageway():
		return _down_the_road(row, at, heading, her, Callable())
	return _on_foot(row, at, heading, Callable())

## **`path` as `row` drives it, or empty where it may not.** Each straight stretch of it goes round
## whatever stands in its lane by the street's other lane, where that lane is free from a tile
## before it to a tile past it (`_round_the_holes()`), and the path that gives is asked whole of the
## ground (`_drives_clear()`). *(minty-lemur #785: the trucks come first among what she meets in the
## escape, and craters are already there when she walks toward them.)* An explosion's crater takes
## one lane of a street and leaves the other (`EventCatalogue._lane_crater()`), so a truck sent
## down her street comes past it rather than being refused for as long as it lies between them;
## something across both lanes still stops it.
func driven(row: EventDef, path: PackedVector2Array) -> PackedVector2Array:
	if path.size() < 2:
		return PackedVector2Array()
	var swerved := _round_the_holes(row, path)
	return swerved if _drives_clear(row, swerved) else PackedVector2Array()

## **Whether `row` may drive `path`**: every point of it, asked every half tile, is carriageway
## (`CityMap.is_carriageway()`, so no street a calm zone absorbed) that is no precinct's paving
## (`CityMap.is_driveable_at()`), and nothing on it stops the row as it moves
## (`Navigator.trim()` keeps it whole: a solid, a closed street, the map's edge).
func _drives_clear(row: EventDef, path: PackedVector2Array) -> bool:
	if path.size() < 2:
		return false
	for i in range(1, path.size()):
		var piece := path[i] - path[i - 1]
		var asks := maxi(1, ceili(piece.length() / ASKED_EVERY))
		for k in asks + 1:
			var tile := _map.world_to_tile(path[i - 1] + piece * (float(k) / float(asks)))
			if not _map.in_bounds(tile) or not _map.is_carriageway(tile) \
					or not _map.is_driveable_at(true, tile):
				return false
	var kept := _navigator.trim(path, EventInstance.mover_for(row))
	return kept.size() == path.size() \
			and kept[kept.size() - 1].is_equal_approx(path[path.size() - 1])

## The leg of a row of the road: from `at` to where it leaves the next junction box it comes to,
## straight through it or round the corner in it, or only by `only` where that is given
## (`leg_out_by()`).
##
## Along its street, the box at or behind it is `floori(along / period)`. A car inside a box drives
## straight out of it, so the stretch it is on or entering runs from box `from` the way it drives:
## the box behind it, or, driving toward the low end and not inside a box, the next one up. Every leg
## ends where the car leaves a box, so the next leg starts at the start of the stretch this one
## chose. **Nothing is asked of that stretch but that the leg drives it clear**: the box it comes to
## is left by a through road, whose far box has another that is not the way back, so a car that has
## taken one never runs out of road, and asking that the stretch it is on be one too would only
## refuse a car driving off a stub into the through roads.
func _down_the_road(row: EventDef, at: Vector2, heading: Vector2,
		her: Vector2, may_take: Callable, only := Vector2i.ZERO) -> PackedVector2Array:
	var vertical := absf(heading.y) > absf(heading.x)
	var way := Vector2i(0, 1 if heading.y > 0.0 else -1) if vertical \
			else Vector2i(1 if heading.x > 0.0 else -1, 0)
	var period := float(CityMap.period() * Tuning.TILE_SIZE)
	var box_px := float(Tuning.STREET_WIDTH * Tuning.TILE_SIZE)
	var along := at.y if vertical else at.x
	var corridor := CrowdLanes.corridor_at(at.x if vertical else at.y)
	if corridor < 0:
		return PackedVector2Array()
	var behind := floori(along / period)
	var inside := along - behind * period <= box_px
	var forward := (way.y if vertical else way.x) > 0
	var from_index := behind if (forward or inside) else behind + 1
	var from := Vector2i(corridor, from_index) if vertical else Vector2i(from_index, corridor)
	var box := from + way
	# Straight on first, then the two turns, the one that leads away from her first.
	var outs: Array[Vector2i] = [way]
	var turns: Array[Vector2i] = [Vector2i(way.y, way.x), Vector2i(-way.y, -way.x)]
	if her != Vector2.INF:
		var centre := Vector2(box) * period + Vector2(box_px, box_px) * 0.5
		if Vector2(turns[0]).dot(her - centre) > Vector2(turns[1]).dot(her - centre):
			turns.reverse()
	outs.append_array(turns)
	if only != Vector2i.ZERO:
		outs = [only]
	for out in outs:
		if not _roads.goes_on(box, out):
			continue
		var leg := driven(row, _through(at, way, box, out))
		if not leg.is_empty() and (not may_take.is_valid() or bool(may_take.call(leg, row))):
			return leg
	return PackedVector2Array()

## **`path` with each straight stretch of it taken round what stands in its lane**: a stretch is the
## points that run on along one axis, and where one or more tiles of its lane stop `row`, it leaves
## its lane `SWERVE` before the first, runs past them in the street's other lane and comes back
## `SWERVE` past the last (`_swerves_on()`). Points of the stretch inside a swerve go; every other
## point stays. A stretch with nothing in its lane, and every piece that turns, is kept as it is.
func _round_the_holes(row: EventDef, path: PackedVector2Array) -> PackedVector2Array:
	var mover := EventInstance.mover_for(row)
	var out := PackedVector2Array([path[0]])
	var start := 0
	while start < path.size() - 1:
		var way := _axis_of(path[start + 1] - path[start])
		var end := start + 1
		if way != Vector2.ZERO:
			while end < path.size() - 1 and _axis_of(path[end + 1] - path[end]) == way:
				end += 1
			out.append_array(_stretch_round(path, start, end, way, mover))
		out.append(path[end])
		start = end
	return out

## The points strictly between `path[start]` and `path[end]`, a straight stretch driving `way`, as it
## is driven round what stands in its lane: its own points outside every swerve, and each swerve's
## four, in the order the stretch reaches them.
func _stretch_round(path: PackedVector2Array, start: int, end: int, way: Vector2,
		mover: Mover) -> PackedVector2Array:
	var from := path[start]
	var swerves := _swerves_on(from, path[end], way, mover)
	var along: Array[float] = []
	var points: Array[Vector2] = []
	for i in range(start + 1, end):
		var t := (path[i] - from).dot(way)
		var inside := false
		for swerve in swerves:
			inside = inside or (t > swerve.x - SWERVE and t < swerve.y + SWERVE)
		if not inside:
			along.append(t)
			points.append(path[i])
	for swerve in swerves:
		var aside := Vector2(-way.y, way.x) * swerve.z * float(Tuning.TILE_SIZE)
		for t: float in [swerve.x - SWERVE, swerve.x, swerve.y, swerve.y + SWERVE]:
			along.append(t)
		points.append_array([from + way * (swerve.x - SWERVE), from + way * swerve.x + aside,
				from + way * swerve.y + aside, from + way * (swerve.y + SWERVE)])
	var order: Array[int] = []
	for i in along.size():
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool: return along[a] < along[b])
	var laid := PackedVector2Array()
	for i in order:
		laid.append(points[i])
	return laid

## **Where the straight stretch from `from` to `to`, driving `way`, leaves its lane**: one entry for
## each run of its lane's tiles that stop `mover`, runs closer than two swerves taken as one, as the
## distance along the stretch to the run's near edge (`x`) and far edge (`y`) and the side of the
## street it passes on (`z`, +1 or -1 times `way` turned a quarter clockwise). A run is passed only
## where the stretch has `SWERVE` of its own before and after it and the street's other lane, beside
## the run and both swerves, is carriageway `mover` may stand on; any other run is left in the
## stretch, which `_drives_clear()` then refuses.
func _swerves_on(from: Vector2, to: Vector2, way: Vector2, mover: Mover) -> Array[Vector3]:
	var tile := float(Tuning.TILE_SIZE)
	var step := Vector2i(roundi(way.x), roundi(way.y))
	var first := _map.world_to_tile(from)
	var span := _map.world_to_tile(to) - first
	var tiles := absi(span.x * step.x + span.y * step.y)
	var runs: Array[Vector2] = []
	for k in tiles + 1:
		var here := first + step * k
		if not _map.in_bounds(here) or _map.passable(here, mover):
			continue
		var middle := (_map.tile_to_world(here) - from).dot(way)
		if not runs.is_empty() and middle - tile * 0.5 - runs[runs.size() - 1].y < 2.0 * SWERVE:
			runs[runs.size() - 1] = Vector2(runs[runs.size() - 1].x, middle + tile * 0.5)
		else:
			runs.append(Vector2(middle - tile * 0.5, middle + tile * 0.5))
	var length := from.distance_to(to)
	var swerves: Array[Vector3] = []
	for run in runs:
		if run.x - SWERVE < 0.0 or run.y + SWERVE > length:
			continue
		for side: float in [1.0, -1.0]:
			if _lane_free_beside(from, way, Vector2(-way.y, way.x) * side * tile,
					run.x - SWERVE, run.y + SWERVE, mover):
				swerves.append(Vector3(run.x, run.y, side))
				break
	return swerves

## Whether the lane `aside` from a stretch starting at `from` and driving `way` is carriageway
## `mover` may stand on, every tile of it from `low` to `high` along the stretch.
func _lane_free_beside(from: Vector2, way: Vector2, aside: Vector2, low: float, high: float,
		mover: Mover) -> bool:
	var t := low
	while t <= high:
		var here := _map.world_to_tile(from + way * t + aside)
		if not _map.in_bounds(here) or not _map.is_carriageway(here) or not _map.passable(here, mover):
			return false
		t += float(Tuning.TILE_SIZE) * 0.5
	return true

## The unit axis `piece` runs along, or zero where it runs along neither or is no length at all.
static func _axis_of(piece: Vector2) -> Vector2:
	if is_zero_approx(piece.x) == is_zero_approx(piece.y):
		return Vector2.ZERO
	return piece.normalized()

## The points from `at`, driving `way`, to where a car leaves `box` by `out`: straight to the box's
## far edge in its own lane, or down its lane to `TURN_RADIUS` short of where its lane meets the lane
## that drives `out`, a quarter turn of that radius in `TURN_PIECES` straight pieces, and on in the new
## lane to the box's edge on that side. Empty where the corner is already behind it.
static func _through(at: Vector2, way: Vector2i, box: Vector2i,
		out: Vector2i) -> PackedVector2Array:
	var period := float(CityMap.period() * Tuning.TILE_SIZE)
	var box_px := float(Tuning.STREET_WIDTH * Tuning.TILE_SIZE)
	var corner := Vector2(box) * period
	var vertical := way.y != 0
	if out == way:
		var edge := (corner.y if vertical else corner.x) \
				+ (box_px if (way.x + way.y) > 0 else 0.0)
		return PackedVector2Array([at, Vector2(at.x, edge) if vertical else Vector2(edge, at.y)])
	var out_vertical := out.y != 0
	var lane := CrowdLanes.lane_centre(box.x if out_vertical else box.y,
			CrowdLanes.road_lane(out_vertical, float(out.x + out.y)))
	var meet := Vector2(at.x, lane) if vertical else Vector2(lane, at.y)
	var d := Vector2(way)
	var o := Vector2(out)
	var begins := meet - d * TURN_RADIUS
	if (begins - at).dot(d) < 0.0:
		return PackedVector2Array()
	var centre := begins + o * TURN_RADIUS
	var leg := PackedVector2Array([at, begins])
	for i in range(1, TURN_PIECES):
		var turned := (PI * 0.5) * float(i) / float(TURN_PIECES)
		leg.append(centre - o * TURN_RADIUS * cos(turned) + d * TURN_RADIUS * sin(turned))
	leg.append(meet + o * TURN_RADIUS)
	var edge_out := (corner.y if out_vertical else corner.x) \
			+ (box_px if (out.x + out.y) > 0 else 0.0)
	leg.append(Vector2(lane, edge_out) if out_vertical else Vector2(edge_out, lane))
	return leg

## The leg of a row on foot: straight on down the street it is on, as far as it may walk
## (`CityMap.passable()` as it walks, `CityMap.is_street()`, the map's edge), at most `LEG_TILES`,
## cut by the navigator; none under `LEAST_TILES`. It never turns: a walker with no way on leaves,
## and may turn round as it does.
func _on_foot(row: EventDef, at: Vector2, heading: Vector2,
		may_take: Callable) -> PackedVector2Array:
	var way := Vector2i(0, 1 if heading.y > 0.0 else -1) if absf(heading.y) > absf(heading.x) \
			else Vector2i(1 if heading.x > 0.0 else -1, 0)
	var mover := EventInstance.mover_for(row)
	var tile := _map.world_to_tile(at)
	var tiles := 0
	for step in range(1, LEG_TILES + 1):
		var next := tile + way * step
		if not _map.in_bounds(next) or not _map.is_street(next) or not _map.passable(next, mover):
			break
		tiles = step
	if tiles < LEAST_TILES:
		return PackedVector2Array()
	var leg := _navigator.trim(PackedVector2Array([at,
			at + Vector2(way) * float(tiles * Tuning.TILE_SIZE)]), mover)
	if leg.size() < 2 or leg[0].distance_to(leg[1]) < float(LEAST_TILES * Tuning.TILE_SIZE):
		return PackedVector2Array()
	if may_take.is_valid() and not bool(may_take.call(leg, row)):
		return PackedVector2Array()
	return leg
