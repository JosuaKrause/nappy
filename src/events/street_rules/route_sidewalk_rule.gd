class_name RouteSidewalkRule
extends StreetRule
## **The sidewalk a route walks keeps a line she can take at no cost, with room for her body,
## junction to junction** (`_leaves_the_routes_sidewalk_open()`): the far side of a
## street answers a van, and nothing answers a van on the side the route is drawn down. What
## stands round the street, seals included, is asked with it.

var _map: CityMap
var _corridor: Corridor

func _init(map: CityMap, corridor: Corridor) -> void:
	_map = map
	_corridor = corridor

## Overrides StreetRule.allows.
func allows(candidate: EventScheduler.Planned, _tile: Vector2i,
		_placed: Array[EventScheduler.Planned], around: Array[EventScheduler.Planned]) -> bool:
	return _leaves_the_routes_sidewalk_open(candidate, _map, _corridor, around)

## **Nothing takes the sidewalk a route is walked along.** *"All obstacles should be routable around
## by eg crossing to the other side of the street, which in turn means the other side of the street
## must be open enough so we can walk on it unimpeded"* (PLAYTEST-69), and *"on the side of the
## street where the path was chosen only obstacles that can be bypassed should be possible"*
## (PLAYTEST-77).
##
## **It reads the route's own sidewalk rather than the street.** A street is walkable frontage to
## frontage, so *some* pavement staying open is what a walk needs in general — but the route is
## drawn along one of the two, the kerb tint marks that one, and a row that closes it has taken the
## line the day was pointing at even though the street as a whole is still walkable. So the walk
## this asks for is from one junction to the other **along the band the tree runs down**, over that
## band's own tiles and no others.
##
## **Cumulatively with everything already down**, the way the junction rule reads and for the same
## reason: the street the probe names most often is closed by a pair rather than by one row, and a
## rule that only asked *does this row alone take the band* would accept both of them. Checked
## before the row is accepted and never repaired after — each row in turn is asked whether the day
## it is joining still has a line along every walked sidewalk.
##
## **Only a street has sidewalks.** Where a route's cells stand on an alley, a park cut or a square
## there is no band to walk along and no two ends to walk between, so the rule says nothing about
## that ground rather than inventing an answer for it — a row there is answered by the junction rule
## and by the walkability guarantee. A **precinct** is paved frontage to frontage with no
## carriageway, so a band of it is walkable like any other and the arithmetic is unchanged.
##
## **It subsumes the whole-street question it replaces**: the two bands of a street are not
## four-connected to each other (the carriageway between them is out), so *some pavement is open*
## was already *one band is open* — and this asks it of the band that matters, of every row rather
## than of one, which is strictly the stronger claim.
##
## **A pacing row is not one of the rows it asks about**, and that is the line between this rule and
## the two that govern a beat. This one is about a **width**: ground a standing body takes and
## leaves taken. A beat takes its ground in **time** — *"yeller is something you can time. it stays
## on the route"* — so what governs it is whether the loop leaves an opening
## (`PacingOpeningRule._leaves_a_pacing_beats_opening`) and whether it reaches a crossing she can leave by
## (`StreetInvalidation._a_pacing_beat_walls_a_sidewalk`, in `EventScheduler._place_one`'s loop). Counting his lens here as a width
## would refuse a man on the route's own sidewalk for the one reason the player has ruled out, and
## counting it against *another* row's placement would refuse a café a band a walk can already pass
## by waiting.
##
## **Two readings, either enough to refuse the candidate.** `closes_the_run` is the cost one, over
## `_cumulative_lane_reach_of` rather than `EventDef.line_reach()` alone —
## `EventScheduler._closes_the_band_by_its_own_placement`'s own role clause is asked of a row's own numbers before
## a tile is chosen, but `EventScheduler._copies_of` still offers a `WALL` a cell of the *same* lane that does not
## itself `carries_a_route` (a route need not use every cell of the block it is walked along), so a
## body legally rolled onto that cell can still physically close the lane the width rule is
## checking. `closes_a_walked_sidewalk_band` is the physical reading asked here for exactly that
## gap, over the same `standing` list.
static func _leaves_the_routes_sidewalk_open(candidate: EventScheduler.Planned, map: CityMap, corridor: Corridor,
		already: Array[EventScheduler.Planned]) -> bool:
	if not corridor or candidate.def.paces or not candidate.counts_against_the_line():
		return true
	var reach := _cumulative_lane_reach_of(candidate.def)
	for entry: Array in corridor.walked_sidewalks(map):
		var world: Rect2 = entry[2]
		if not candidate.reach_touches(world, reach):
			continue
		var standing: Array[EventScheduler.Planned] = [candidate]
		for plan in already:
			if plan == candidate or plan.def.paces or not plan.counts_against_the_line():
				continue
			if plan.reach_touches(world, _cumulative_lane_reach_of(plan.def)):
				standing.append(plan)
		var segment: StreetNetwork.Segment = entry[0]
		if closes_the_run(map, entry[1], segment.horizontal, standing):
			return false
		if closes_a_walked_sidewalk_band(map, entry[1], segment.horizontal,
				_physical_bodies_of(standing), map.closed_ground()):
			return false
	return true

## The reach `_leaves_the_routes_sidewalk_open` filters candidates by: the greater of
## `EventDef.line_reach()`'s cost-based reach and the physical standoff a solid body needs
## (`obstructs_radius + PLAYER_BODY_RADIUS`). A silent, cheap body — `delivery_van`'s own numbers —
## can close a lane by presence alone while charging nothing to walk past, so the filter that
## decides which rows are even worth asking `closes_a_walked_sidewalk_band` about has to see the
## wider of the two rather than only the one `EventDef.line_reach()` already answers.
static func _cumulative_lane_reach_of(def: EventDef) -> float:
	if def.obstructs_within() <= 0.0:
		return def.line_reach()
	return maxf(def.line_reach(), def.obstructs_within() + Tuning.PLAYER_BODY_RADIUS)

## `rows` reduced to `[position.x, position.y, obstructs_radius]` triples, the shape
## `closes_a_walked_sidewalk_band` asks for — a row with no body contributes nothing to a physical
## reading, however loud it is.
static func _physical_bodies_of(rows: Array[EventScheduler.Planned]) -> Array:
	var found: Array = []
	for plan in rows:
		if plan.def.obstructs_within() > 0.0:
			found.append(Vector3(plan.position.x, plan.position.y, plan.def.obstructs_within()))
	return found

## The same question over an arbitrary run of a street's ground, which is what lets the width rule
## ask it of one sidewalk band and the pacing rule of the whole street. `horizontal` is the
## direction the walk has to get from one end of `rect` to the other along.
static func closes_the_run(map: CityMap, rect: Rect2i, horizontal: bool,
		rows: Array[EventScheduler.Planned]) -> bool:
	var free := {}
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var tile := Vector2i(x, y)
			if not map.is_open(tile) or _is_a_carriageway_tile(map, tile, horizontal):
				continue
			var at := map.tile_to_world(tile)
			var taken := false
			for plan in rows:
				if plan.denies(at, plan.def.line_reach()):
					taken = true
					break
			if not taken:
				free[tile] = true

	var last := (rect.end.x - 1) if horizontal else (rect.end.y - 1)
	var queue: Array[Vector2i] = []
	var seen := {}
	for tile: Vector2i in free:
		var at_the_start := tile.x == rect.position.x if horizontal \
				else tile.y == rect.position.y
		if at_the_start:
			seen[tile] = true
			queue.append(tile)
	var head := 0
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		if (at.x if horizontal else at.y) == last:
			return false
		for step in StreetRule.NEIGHBOUR_STEPS:
			var next: Vector2i = at + step
			if free.has(next) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	return true

## Whether a tile between two junctions is carriageway a line may not cross there.
##
## **The tile's own type decides, not its offset across the corridor.** A four-block calm zone is
## painted over the streets between its blocks, so those tiles sit at a road offset and are grass
## somebody walks on — *"an absorbed street is calm ground, not a closure"*. A precinct is paving
## frontage to frontage with no carriageway at all, and its middle tiles are not `ROAD` either, so
## the same test covers it without naming it.
static func _is_a_carriageway_tile(map: CityMap, tile: Vector2i, horizontal: bool) -> bool:
	if not CityMap.is_road_offset(CityMap.corridor_offset(tile.y if horizontal else tile.x)):
		return false
	var type := map.tile_at(tile)
	return type == GameEnums.TileType.ROAD or type == GameEnums.TileType.CROSSING

## The line a stroller needs, stated as a width rather than a reach: an edge-to-edge gap has to be
## at least this wide for her whole body to fit inside it, once a row's own edge and the sidewalk's
## true boundary — the kerb, or the frontage wall — are both hard edges neither of them may cross.
## The same number as the far-lane distance `EventDef` compares a reach to (`EventDef._THE_FAR_LANE`, one tile of 32px; `EventDef.reaches_the_far_lane()` asks it), read as a
## width because this clause measures one directly rather than comparing a reach to a fixed tile.
const HER_LANE_CLEARANCE := 2.0 * Tuning.PLAYER_BODY_RADIUS

## **Whether a set of physical bodies, ignoring cost, leave no lane of `HER_LANE_CLEARANCE`
## anywhere along a walked-sidewalk band** — the shared question
## `tests/probes/m129_walked_sidewalk_walls.gd` and `tests/test_events.gd`'s
## `_test_no_body_closes_a_walked_sidewalk` both ask, moved here rather than kept as two copies, so
## the probe's printed number and the suite's asserted one can never quietly disagree about what
## *closed* means. `bodies` is `[position.x, position.y, radius]` per body rather than a `EventScheduler.Planned`,
## because a suite sampling seals and region bodies alongside catalogue rows has no single class to
## hand this that all three already share.
##
## Tile-grained like `closes_the_run`, substituting a body's own physical
## `radius + PLAYER_BODY_RADIUS` for that rule's cost-based `EventDef.line_reach()` — see
## `EventScheduler._closes_the_band_by_its_own_placement`'s doc for why a reach and a gap are the same question
## read two ways.
##
## **The walk only has to connect the band's own genuinely open ends, not its raw tile-rect
## corners.** A street a big building has built over at one end (`CityMap.built_over`, a fixed,
## whole-run fact rather than anything a day places) has a shorter *real* sidewalk than its
## nominal rect — asking the walk to reach a tile that has been a building since generation would
## read every day of that street as closed by the ground alone, which is not a body and is not a
## defect in one. So the required span is between the outermost tiles that are still actually
## `SIDEWALK`, and a band with none at all — every tile built over or absorbed into a calm zone's
## park — has nothing to close and answers `false`.
static func closes_a_walked_sidewalk_band(map: CityMap, band: Rect2i, horizontal: bool,
		bodies: Array, closed_tiles: Dictionary) -> bool:
	var free := {}
	var first := -1
	var last := -1
	for y in range(band.position.y, band.end.y):
		for x in range(band.position.x, band.end.x):
			var tile := Vector2i(x, y)
			if map.tile_at(tile) != GameEnums.TileType.SIDEWALK:
				continue
			var along := x if horizontal else y
			first = along if first < 0 else mini(first, along)
			last = maxi(last, along)
			if closed_tiles.has(tile):
				continue
			var at := map.tile_to_world(tile)
			var taken := false
			for body: Vector3 in bodies:
				var reach: float = body.z
				if reach > 0.0 and at.distance_to(Vector2(body.x, body.y)) \
						<= reach + Tuning.PLAYER_BODY_RADIUS:
					taken = true
					break
			if not taken:
				free[tile] = true
	if first < 0:
		return false

	var queue: Array[Vector2i] = []
	var seen := {}
	for tile: Vector2i in free:
		var at_the_start := (tile.x if horizontal else tile.y) == first
		if at_the_start:
			seen[tile] = true
			queue.append(tile)
	var head := 0
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		if (at.x if horizontal else at.y) == last:
			return false
		for step in StreetRule.NEIGHBOUR_STEPS:
			var next: Vector2i = at + step
			if free.has(next) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	return true
