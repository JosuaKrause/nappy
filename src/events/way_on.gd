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
## **One check says whether a stretch of road is a car's to drive** (`drives_clear()`), asked of
## every leg here and of the first leg the director lays (`EventDirector.leg_in_the_lane()`).
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
## How finely `drives_clear()` asks the ground along a leg, in px.
const ASKED_EVERY := Tuning.TILE_SIZE * 0.5

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

## **The leg a row that is leaving goes on by**: as `next_leg()`, with nothing asked of the day, since
## a row that is leaving is over and emits nothing.
func leg_to_leave_by(row: EventDef, at: Vector2, heading: Vector2,
		her: Vector2) -> PackedVector2Array:
	if row.keeps_to_the_carriageway():
		return _down_the_road(row, at, heading, her, Callable())
	return _on_foot(row, at, heading, Callable())

## **Whether `row` may drive `path`**: every point of it, asked every half tile, is carriageway
## (`CityMap.is_carriageway()`, so no street a calm zone absorbed) that is no precinct's paving
## (`CityMap.is_driveable_at()`), and nothing on it stops the row as it moves
## (`Navigator.trim()` keeps it whole: a solid, a closed street, the map's edge).
func drives_clear(row: EventDef, path: PackedVector2Array) -> bool:
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
## straight through it or round the corner in it.
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
		her: Vector2, may_take: Callable) -> PackedVector2Array:
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
	for out in outs:
		if not _roads.goes_on(box, out):
			continue
		var leg := _through(at, way, box, out)
		if leg.size() > 1 and drives_clear(row, leg) \
				and (not may_take.is_valid() or bool(may_take.call(leg, row))):
			return leg
	return PackedVector2Array()

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
