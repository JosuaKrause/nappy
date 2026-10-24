extends RefCounted
## How far a planned body, or the ground its picture is drawn over, reaches into a building tile.
## Shared by `tests/test_seals.gd` and `tests/test_finale.gd`, which hold that no seal reaches one
## on a day or in the escape, and `tests/probes/seal_overhang.gd`, which prints the depths.
##
## **The body** is each solid piece where it stands (`WalkGround.solids_of()`),
## without her body radius: its spine, laid along the piece's own axis, grown by its rounding. The
## depth is how far that reaches past a building tile's edge, measured between the spine's box and
## the tile's box, which is exact for a spine laid along a street's axis, the only way a seal lies.
##
## **The drawing** is the ground its picture is drawn over, the run of a spread or the width of a
## picture at its feet: a spread (`EventDef.has_a_spread`) covers `-half` to `half` of its run
## (`EventInstance._draw_spread()`), and end-on that run goes up the screen with the picture's own
## width across it; anything else stands its picture's width at its feet. What rises above the feet
## is a picture standing in front of whatever is behind it, as every figure in the street does, and
## is not ground.

## The deepest any solid piece of `plan` reaches into a building tile, in px; 0 when none does.
static func body_overhang(map: CityMap, ground: WalkGround,
		plan: EventScheduler.Planned) -> float:
	var worst := 0.0
	for solid in ground.solids_of(plan):
		var rounding := solid.shape.radius if solid.shape.kind != GroundShape.Kind.RECT else 0.0
		worst = maxf(worst, _box_overhang(map, _spine_box(solid), rounding))
	return worst

## How far the ground `plan`'s picture is drawn over reaches into a building tile, in px.
static func drawing_overhang(map: CityMap, plan: EventScheduler.Planned) -> float:
	var def := plan.def
	var box := EventInstance.box_of(def)
	if not box.has_area():
		return 0.0
	var at: Vector2 = plan.path[0] if plan.path.size() > 0 else plan.position
	if not def.mobile and def.obstructs_radius > 0.0 and def.pavement_side == EventDef.Pavement.ANY:
		at = EventInstance._centred_on_the_pavement_band(map, at)
	var ground := Rect2(at.x - box.size.x * 0.5, at.y, box.size.x, 0.0)
	if def.has_a_spread:
		var half := maxf(11.0, def.obstructs_radius)
		if EventInstance._spread_is_vertical(map, at):
			ground = Rect2(at.x - box.size.x * 0.5, at.y - half, box.size.x, half * 2.0)
		else:
			ground = Rect2(at.x - half, at.y, half * 2.0, 0.0)
	return _box_overhang(map, ground, 0.0)

## The piece's spine as a box: a point, or a segment along an axis, or a rectangle's own extent.
## A piece turned off the street's axes is taken at the whole disc of its reach, which can only
## overstate.
static func _spine_box(solid: WalkGround.Solid) -> Rect2:
	var shape := solid.shape
	var along_x := absf(solid.axis.y) < 0.001
	var along_y := absf(solid.axis.x) < 0.001
	if not (along_x or along_y):
		var reach := shape.reach()
		return Rect2(solid.centre - Vector2(reach, reach), Vector2(reach, reach) * 2.0)
	var half := Vector2.ZERO
	match shape.kind:
		GroundShape.Kind.RECT:
			half = shape.half_extents if along_x else Vector2(shape.half_extents.y,
					shape.half_extents.x)
		GroundShape.Kind.SEGMENT:
			half = Vector2(shape.half_length, 0.0) if along_x else Vector2(0.0, shape.half_length)
	return Rect2(solid.centre - half, half * 2.0)

## How far `box`, grown by `rounding`, reaches past the edge of any building tile it meets: the
## lesser of the two overlaps across the tile's edges, so a box that only runs along a building's
## face, touching it, reaches nothing.
static func _box_overhang(map: CityMap, box: Rect2, rounding: float) -> float:
	var grown := box.grow(rounding)
	var tile_size := float(Tuning.TILE_SIZE)
	var low := Vector2i(floori(grown.position.x / tile_size), floori(grown.position.y / tile_size))
	var high := Vector2i(floori(grown.end.x / tile_size), floori(grown.end.y / tile_size))
	var worst := 0.0
	for y in range(low.y, high.y + 1):
		for x in range(low.x, high.x + 1):
			var tile := Vector2i(x, y)
			if not map.in_bounds(tile) or map.tile_at(tile) != GameEnums.TileType.BUILDING:
				continue
			var cell := map.tile_rect_to_world(Rect2i(tile, Vector2i.ONE))
			# The gap between the two boxes on each axis, negative where they overlap on it.
			var gap_x := maxf(cell.position.x - box.end.x, box.position.x - cell.end.x)
			var gap_y := maxf(cell.position.y - box.end.y, box.position.y - cell.end.y)
			var gap := 0.0
			if gap_x > 0.0 and gap_y > 0.0:
				gap = Vector2(gap_x, gap_y).length()
			else:
				gap = maxf(gap_x, gap_y)
			var depth := rounding - gap
			if box.size.y == 0.0 and rounding == 0.0:
				# A line at the feet: it reaches a tile only where it runs inside it.
				if box.position.y <= cell.position.y or box.position.y >= cell.end.y:
					continue
				depth = -gap_x
			worst = maxf(worst, depth)
	return worst
