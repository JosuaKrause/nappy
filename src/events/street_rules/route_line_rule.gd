class_name RouteLineRule
extends StreetRule
## **Her line is followed from a route's junction box onto the sidewalks she walks to it and from
## it**, against the line reach of every row that counts against it (`EventDef.line_reach()`, a
## pacing row at the ground its beat never leaves free, `EventPlan.denies()`): the box and those
## sidewalks are flooded as one piece of ground, so rows that each leave a free tile at the box and
## a free row along the sidewalk, and between them leave the two unjoined, are refused
## (`_her_line_survives()`). *(inbox #1461: "sure", to a rule that follows her line the way the
## free-line probe does, from the crossing onto her sidewalk, for every row that lands near her
## route.)*
##
## It reads what stands round the piece, seals and the region wall included, so what another street
## holds within its reach invalidates here too. Every unit whose rows can deny a tile of a box or of
## a sidewalk's first columns touches every other such unit (the box, its four streets and the lots
## of its four corner blocks: the next box is nine tiles off, past the widest reach), so every pair
## that can close a seam between them is judged together, whichever draws first.
##
## **One case is left open, by the player's condition on it** (inbox #1461: leave it open and close
## it only if the free-line probe shows free lines lost): two rows in units at the two ends of one
## walked sidewalk, neither on that street, each reaching far into it from opposite sides, do not
## see each other, and each alone leaves the line. `tests/probes/m129_zero_cost_line.gd` measures
## it. Model: no node.

var _map: CityMap
var _corridor: Corridor
## The routes' junction boxes with the ground the rule floods round each (`_route_pieces()`),
## worked out when the rule is first asked and kept for its life.
var _pieces: Array[_Piece] = []
var _pieces_are_known := false

## **One route street meeting a box**, as the ground the flood takes of it: the open tiles of the
## sidewalk or sidewalks she walks along it, the open tiles of the other one, and each one's far
## end, the outermost open column away from the box.
class _Arm extends RefCounted:
	var street: StreetNetwork.Segment
	var walked: Array[Vector2i] = []
	var walked_end: Array[Vector2i] = []
	var across: Array[Vector2i] = []
	var across_end: Array[Vector2i] = []

	func _init(segment: StreetNetwork.Segment) -> void:
		street = segment

## **A route's junction box and what the flood joins through it**: the box's open tiles, the
## route streets meeting it, the off-street ground a route runs along next to the box or a walked
## sidewalk (each mouth a four-connected run of it), and the world rect all of it lies in.
class _Piece extends RefCounted:
	var box: Array[Vector2i] = []
	var arms: Array[_Arm] = []
	var mouths: Array[_Mouth] = []
	var world := Rect2()

## One off-street opening a route runs through next to a piece: an alley's mouth, a park cut.
class _Mouth extends RefCounted:
	var tiles: Array[Vector2i] = []

func _init(map: CityMap, corridor: Corridor) -> void:
	_map = map
	_corridor = corridor

## Overrides StreetRule.allows.
func allows(candidate: EventPlan, _tile: Vector2i,
		_placed: Array[EventPlan], around: Array[EventPlan]) -> bool:
	if not _corridor or not candidate.counts_against_the_line():
		return true
	var reach := candidate.row().line_reach()
	for piece in _route_pieces():
		if not candidate.reach_touches(piece.world, reach):
			continue
		if not _her_line_survives(piece, candidate, around):
			return false
	return true

## **Whether her line still runs through one piece**, with the candidate standing and everything
## round it standing too, checked before a row is accepted and never repaired after.
##
## 1. **The ground** is the box's open tiles; for each route street meeting it, the open tiles of
##    the sidewalk she walks along it; **that street's far sidewalk too while a pacing row stands on
##    the street**, the candidate included, since the man shouting is passed on the far side
##    (PLAYTEST-71: "time pass, don't route around them"); and the off-street tiles a route runs
##    along next to the box or a walked sidewalk.
## 2. **Free** is a tile no standing row denies at its line reach, a pacing row at its lens.
## 3. **Each route street's far end** is the free tiles of its outermost open column away from the
##    box, on each of its sidewalks in the ground. A street with no open ground there (built over,
##    or absorbed into a park) asks nothing.
## 4. **One flood from the first far end**, four ways over free tiles, has to reach a tile of the
##    box, every other far end and a tile of every off-street mouth. With nothing to start from,
##    the box keeps a free tile.
##
## A pacing row may lean on the far sidewalk only on his own street: whoever closes that far
## sidewalk stands in a unit touching his, so the two are always judged together. A man on another
## street leaning on a far sidewalk a third unit could close is refused for closing the seam,
## whatever stands across.
func _her_line_survives(piece: _Piece, candidate: EventPlan, around: Array[EventPlan]) -> bool:
	var standing: Array[EventPlan] = [candidate]
	for plan in around:
		if plan == candidate or not plan.counts_against_the_line():
			continue
		if plan.reach_touches(piece.world, plan.row().line_reach()):
			standing.append(plan)

	var ground: Array[Vector2i] = piece.box.duplicate()
	var ends: Array[_Mouth] = []
	for arm in piece.arms:
		var end := _Mouth.new()
		ground.append_array(arm.walked)
		end.tiles.append_array(arm.walked_end)
		if _a_beat_stands_on(arm.street, standing):
			ground.append_array(arm.across)
			end.tiles.append_array(arm.across_end)
		if not end.tiles.is_empty():
			ends.append(end)
	for mouth in piece.mouths:
		ground.append_array(mouth.tiles)
		ends.append(mouth)

	var free := {}
	for tile in ground:
		var at := _map.tile_to_world(tile)
		var taken := false
		for plan in standing:
			if plan.denies(at, plan.row().line_reach()):
				taken = true
				break
		if not taken:
			free[tile] = true
	if ends.is_empty():
		return piece.box.any(func(tile: Vector2i) -> bool: return free.has(tile))

	var reached := {}
	var queue: Array[Vector2i] = []
	for tile in ends[0].tiles:
		if free.has(tile) and not reached.has(tile):
			reached[tile] = true
			queue.append(tile)
	var head := 0
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		for step in StreetRule.NEIGHBOUR_STEPS:
			var next: Vector2i = at + step
			if free.has(next) and not reached.has(next):
				reached[next] = true
				queue.append(next)
	if not piece.box.any(func(tile: Vector2i) -> bool: return reached.has(tile)):
		return false
	for i in range(1, ends.size()):
		if not ends[i].tiles.any(func(tile: Vector2i) -> bool: return reached.has(tile)):
			return false
	return true

## Whether a pacing row among `standing` stands on `street`: where it was placed or a corner of its
## beat lies on the street's own tiles. A beat that runs from a side street into the box stands on
## the side street, not on this one.
func _a_beat_stands_on(street: StreetNetwork.Segment, standing: Array[EventPlan]) -> bool:
	for plan in standing:
		if not plan.walks_a_beat():
			continue
		var points := plan.walks().duplicate()
		points.append(plan.placed_at())
		for point in points:
			var on := _map.street_network().segment_containing(_map.world_to_tile(point))
			if on and on.key() == street.key():
				return true
	return false

# ---------------------------------------------------------------- the pieces ---

## The routes' junction boxes with the ground the rule floods round each, worked out once a rule:
## a few dozen boxes, the rule's own facts about the routes.
func _route_pieces() -> Array[_Piece]:
	if not _pieces_are_known:
		var walked := {}
		for entry: Array in _corridor.walked_sidewalks(_map):
			var segment: StreetNetwork.Segment = entry[0]
			var band: Rect2i = entry[1]
			if not walked.has(segment.key()):
				walked[segment.key()] = [] as Array[Rect2i]
			var bands: Array[Rect2i] = walked[segment.key()]
			bands.append(band)
		for junction in _corridor.route_junctions():
			_pieces.append(_piece_at(junction, walked))
		_pieces_are_known = true
	return _pieces

## The piece round one route junction. **The arms are the on-corridor streets and nothing else**: a
## turning off the corridor is not ground the guarantee is about. `walked` is each route street's
## walked bands, by its key (`Corridor.walked_sidewalks()`).
func _piece_at(junction: Vector2i, walked: Dictionary) -> _Piece:
	var piece := _Piece.new()
	var box := Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)
	var extent := box
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			if _map.is_open(Vector2i(x, y)):
				piece.box.append(Vector2i(x, y))
	for segment in _map.street_network().at_junction(junction):
		if _corridor.depth(segment.tile_rect().position) != 0 or not walked.has(segment.key()):
			continue
		var bands: Array[Rect2i] = walked[segment.key()]
		var arm := _Arm.new(segment)
		var away := segment.other_end(junction) - junction
		for band in bands:
			_take_band(band, segment.horizontal, away, arm.walked, arm.walked_end)
		for band in Corridor.sidewalk_bands(segment.tile_rect(), segment.horizontal):
			if not bands.has(band):
				_take_band(band, segment.horizontal, away, arm.across, arm.across_end)
		piece.arms.append(arm)
		extent = extent.merge(segment.tile_rect())
	piece.mouths = _mouths_of(piece)
	for mouth in piece.mouths:
		for tile in mouth.tiles:
			extent = extent.expand(tile).expand(tile + Vector2i.ONE)
	piece.world = _map.tile_rect_to_world(extent)
	return piece

## Adds a band's open tiles to `tiles` and those of its outermost open column away from the box
## (`away`, a step along the street) to `end`. Open is walkable today and not a carriageway tile,
## so a street built over at its far end ends where its sidewalk does.
func _take_band(band: Rect2i, horizontal: bool, away: Vector2i,
		tiles: Array[Vector2i], end: Array[Vector2i]) -> void:
	var outward := away.x + away.y
	var open: Array[Vector2i] = []
	var furthest := 0
	for y in range(band.position.y, band.end.y):
		for x in range(band.position.x, band.end.x):
			var tile := Vector2i(x, y)
			if not _map.is_open(tile) \
					or RouteSidewalkRule.is_a_carriageway_tile(_map, tile, horizontal):
				continue
			var along: int = (x if horizontal else y) * outward
			furthest = along if open.is_empty() else maxi(furthest, along)
			open.append(tile)
	for tile in open:
		tiles.append(tile)
		var along: int = (tile.x if horizontal else tile.y) * outward
		if along == furthest:
			end.append(tile)

## The off-street tiles a route runs along next to the box or a walked sidewalk of `piece`
## (`Corridor.carries_a_route()`, `RouteGroundRule.is_ground_off_the_street()`), grouped into
## four-connected mouths.
func _mouths_of(piece: _Piece) -> Array[_Mouth]:
	var near := {}
	for tile in piece.box:
		near[tile] = true
	for arm in piece.arms:
		for tile in arm.walked:
			near[tile] = true
	var opening := {}
	for tile: Vector2i in near:
		for step in StreetRule.NEIGHBOUR_STEPS:
			var next: Vector2i = tile + step
			if not near.has(next) and _corridor.carries_a_route(next) \
					and RouteGroundRule.is_ground_off_the_street(_map, next):
				opening[next] = true
	var mouths: Array[_Mouth] = []
	var seen := {}
	for tile: Vector2i in opening:
		if seen.has(tile):
			continue
		var mouth := _Mouth.new()
		seen[tile] = true
		mouth.tiles.append(tile)
		var head := 0
		while head < mouth.tiles.size():
			var at: Vector2i = mouth.tiles[head]
			head += 1
			for step in StreetRule.NEIGHBOUR_STEPS:
				var next: Vector2i = at + step
				if opening.has(next) and not seen.has(next):
					seen[next] = true
					mouth.tiles.append(next)
		mouths.append(mouth)
	return mouths
