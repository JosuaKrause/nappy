class_name MastSites
extends RefCounted
## Where the loudspeaker masts stand — junction corners, commercial squares and the main road,
## the sites the fiction puts them at (`docs/TODO.md`, M180, "posters she notices, and
## loudspeakers that are somewhere"). Chosen by farthest-point sampling so the six of them
## (`Tuning.MAST_COUNT`) spread across the city rather than clumping in one district.
##
## **Pure geometry over `CityMap`'s own layout, and nothing else.** No RNG stream and no caching:
## the same map always answers the same sites, which is what makes "at the same places every day"
## true without a day having to remember yesterday's roll. `EventScheduler.build_day()` calls
## `compute()` fresh every day it needs it.

## One chosen site: a stable id a later slice can name — M181's day-11 task silences a mast by
## reaching its foot, the way she touches a chalk mark — and the ground point everything about the
## mast is measured from: `EventScheduler.Planned.position`, the field's own centre, and the point
## that later task's touch radius would read.
class Site extends RefCounted:
	var id := ""
	var foot := Vector2.ZERO

	func _init(site_id: String, at: Vector2) -> void:
		id = site_id
		foot = at

## The chosen sites, in a stable order (`mast_0`, `mast_1`, …) so the id a plan or a save carries
## today is the same id tomorrow. Never on the home street, and never with a field that would reach
## the doorstep or a calm block's interior — checked here, before a site is ever offered, rather
## than repaired once six have already been chosen (`docs/DECISIONS.md`, the city and events
## non-choices: "closures and events are checked before they are accepted, never repaired
## afterwards").
static func compute(map: CityMap) -> Array[Site]:
	var candidates := _eligible_candidates(map)
	if candidates.is_empty():
		return []
	var chosen: Array[Vector2] = []
	# Farthest-point sampling. Seeded on the candidate farthest from the doorstep — every route
	# shares that one point, so starting away from it spreads the set rather than clustering it
	# near where she always starts — then each further pick is whichever remaining candidate is
	# farthest from its own nearest already-chosen site, which is what keeps the six spread rather
	# than bunched. Ties keep the earliest candidate in `candidates`' own order, so the result is
	# exactly reproducible rather than dependent on float equality.
	var doorstep := map.doorstep_world_position()
	var seed_index := 0
	var seed_distance := -1.0
	for i in candidates.size():
		var d := candidates[i].distance_to(doorstep)
		if d > seed_distance:
			seed_distance = d
			seed_index = i
	chosen.append(candidates[seed_index])
	candidates.remove_at(seed_index)
	while chosen.size() < Tuning.MAST_COUNT and not candidates.is_empty():
		var best_index := 0
		var best_distance := -1.0
		for i in candidates.size():
			var nearest := INF
			for site in chosen:
				nearest = minf(nearest, candidates[i].distance_to(site))
			if nearest > best_distance:
				best_distance = nearest
				best_index = i
		chosen.append(candidates[best_index])
		candidates.remove_at(best_index)
	var sites: Array[Site] = []
	for i in chosen.size():
		sites.append(Site.new("mast_%d" % i, chosen[i]))
	return sites

## Every site the fiction allows, de-duplicated and filtered, in a fixed order: junction corners,
## then commercial squares, then the main road.
static func _eligible_candidates(map: CityMap) -> Array[Vector2]:
	var found: Array[Vector2] = []
	var seen := {}
	for at in _junction_sites(map):
		_consider(found, seen, at, map)
	for at in _square_sites(map):
		_consider(found, seen, at, map)
	for at in _main_road_sites(map):
		_consider(found, seen, at, map)
	return found

static func _consider(found: Array[Vector2], seen: Dictionary, at: Vector2, map: CityMap) -> void:
	var key := Vector2i(roundi(at.x), roundi(at.y))
	if seen.has(key):
		return
	seen[key] = true
	if _is_eligible(at, map):
		found.append(at)

## A mast's own foot may stand on her own sidewalk or on a square's paving — never a road, a
## crosswalk or a junction box. *(2026-09-23, PLAYTEST-123, statement 23: "mast in 292 is weird.
## it's in the middle of the road".)*
const _VALID_FOOT_TILES := [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]

## How far the search below may look for real ground before giving up on a candidate.
const _SNAP_RADIUS := 8

## The nearest tile of `_VALID_FOOT_TILES` to `from`, by an expanding square ring so the answer is
## the closest ground rather than whichever the scan order reaches first, or `Vector2.INF` if
## nothing valid stands within `_SNAP_RADIUS` tiles. Every raw point the three site functions below
## compute is only *near* where the fiction puts a mast — a junction's own corner, a square's
## centre, the main road's carriageway — and this is what turns "near" into "actually standing on
## her own sidewalk or the square's paving".
static func _snap_to_ground(map: CityMap, from: Vector2) -> Vector2:
	var origin := map.world_to_tile(from)
	if map.in_bounds(origin) and map.tile_at(origin) in _VALID_FOOT_TILES:
		return map.tile_to_world(origin)
	for radius in range(1, _SNAP_RADIUS + 1):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				# Only the ring's own edge — the interior was already checked at a smaller radius.
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var tile := origin + Vector2i(dx, dy)
				if map.in_bounds(tile) and map.tile_at(tile) in _VALID_FOOT_TILES:
					return map.tile_to_world(tile)
	return Vector2.INF

## The sidewalk corner nearest each of a junction box's own four corners — a corner of the
## sidewalk beside the crossing, never the crossing or the carriageway between them, which the
## flat box centre this used to read was.
static func _junction_sites(map: CityMap) -> Array[Vector2]:
	var found: Array[Vector2] = []
	var count := StreetNetwork.junction_count()
	var period := CityMap.period()
	var corners: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(Tuning.STREET_WIDTH, -1),
			Vector2i(-1, Tuning.STREET_WIDTH), Vector2i(Tuning.STREET_WIDTH, Tuning.STREET_WIDTH)]
	for jy in count.y:
		for jx in count.x:
			var junction := Vector2i(jx, jy)
			if not StreetNetwork.in_bounds(junction):
				continue
			var box_origin := junction * period
			for corner in corners:
				var snapped := _snap_to_ground(map, map.tile_to_world(box_origin + corner))
				if snapped != Vector2.INF:
					found.append(snapped)
	return found

## Every square's own centre, snapped the same way every other candidate is — a square's own
## paving is already `SQUARE` ground, so this only matters when the centre itself is not walkable
## (an obstruction, an edge case in an irregular zone shape), where it finds the paving beside it
## rather than offering a point nothing can stand on.
static func _square_sites(map: CityMap) -> Array[Vector2]:
	var found: Array[Vector2] = []
	for rect in map.square_rects:
		var snapped := _snap_to_ground(map, map.tile_rect_to_world(rect).get_center())
		if snapped != Vector2.INF:
			found.append(snapped)
	return found

## One candidate per block along `map.main_road`'s own corridor — the spine every other siting
## rule in the game reads off `CityMap.main_road` for, `SealPlanner._is_the_main_road()` included.
## Sited at the **middle of a block**, never at a junction row, so the snap lands on an ordinary
## stretch of sidewalk rather than a crossing.
static func _main_road_sites(map: CityMap) -> Array[Vector2]:
	var found: Array[Vector2] = []
	if map.main_road < 0:
		return found
	var period := CityMap.period()
	var x := map.main_road * period + Tuning.STREET_WIDTH / 2
	var count := StreetNetwork.junction_count()
	for jy in maxi(count.y - 1, 0):
		var y := jy * period + Tuning.STREET_WIDTH + Tuning.BLOCK_SIZE / 2
		var snapped := _snap_to_ground(map, map.tile_to_world(Vector2i(x, y)))
		if snapped != Vector2.INF:
			found.append(snapped)
	return found

## Refuses the home street and a field reaching the doorstep or a calm interior. Both margins are
## generous on purpose — a site excluded here is simply not offered to the farthest-point sampling
## above, so refusing a little too much costs variety and refusing too little costs the guarantee.
static func _is_eligible(at: Vector2, map: CityMap) -> bool:
	return not _too_close_to_home(at, map) and not _reaches_a_calm_interior(at, map)

static func _too_close_to_home(at: Vector2, map: CityMap) -> bool:
	var margin := Tuning.MAST_HOME_STREET_MARGIN * float(CityMap.period()) * Tuning.TILE_SIZE
	return at.distance_to(map.doorstep_world_position()) < margin \
			or at.distance_to(map.home_world_position()) < margin

## Whether a mast's own field, planted here, would reach inside a calm block's interior — the lot
## rect shrunk in by `Tuning.MAST_CALM_INTERIOR_MARGIN` on every side, so a field may still brush
## the block's own pavement edge without counting as reaching its interior. Read off the
## `loudspeaker` row's own `outer_radius` rather than a second copy of the number, so a balance
## pass that moves the field moves this refusal with it.
static func _reaches_a_calm_interior(at: Vector2, map: CityMap) -> bool:
	var reach := EventCatalogue.by_id("loudspeaker").outer_radius
	var seen := {}
	for block in map.calm_blocks:
		var anchor := map.anchor_of(block)
		if seen.has(anchor):
			continue
		seen[anchor] = true
		var interior := map.tile_rect_to_world(map.lot_rect(block)).grow(
				-Tuning.MAST_CALM_INTERIOR_MARGIN)
		if interior.has_area() and _circle_touches_rect(at, reach, interior):
			return true
	return false

static func _circle_touches_rect(at: Vector2, radius: float, rect: Rect2) -> bool:
	var closest := Vector2(clampf(at.x, rect.position.x, rect.end.x),
			clampf(at.y, rect.position.y, rect.end.y))
	return at.distance_to(closest) <= radius
