class_name ParkClosure
extends RoadClosure
## One fenced run of a shut calm area's edge: the barriers `City` stands where the area's ground
## meets the ground she walks on. *(PLAYTEST-140: "a spent park should not be accesible and no route
## should go through it".)*
##
## **It is a `RoadClosure` so that it is drawn, and stands in her way, exactly as a closed street's
## barriers do.** `ClosurePlanner.plan_day` hands these to `City` beside the day's street closures,
## and `City._spawn_closure()` stands the same line of barrier panels — the same pictures, the
## `closed` sign on the middle one and one static body behind the line — at every point
## `mouth_centres()` answers, lying the way `barrier_runs_across()` says. The kind is `PARK`, which
## like `CORDON` leaves nothing lying anywhere. So a shut park reads the way a shut street reads,
## from the pavement beside it, before she has taken a step onto it.
##
## **Which ground is shut is not decided here**: `ClosurePlanner.calm_to_shut()` decides it at the
## repaint, checked before it is accepted, and `CityMap.shut_calm` records it. This is only the
## fence around what was decided.
##
## **The fence stands on the calm ground's own edge row, never on the pavement.** A barrier line is
## `Tuning.CLOSURE_BARRIER_DEPTH` deep and stands half of that inside the edge, so the pavement
## beside the park stays exactly as wide as it was and a route that runs along it is untouched.
## Each run is covered end to end: a line is `Tuning.STREET_WIDTH` tiles long (what `City` draws for
## one mouth), so a longer run gets several, overlapping where the length does not divide — and the
## lines at a corner overlap too, since each stands inside its own edge, so there is no gap at a
## corner for a pram to get through.
##
## **An entrance is any tile of the edge with walkable ground outside it.** An open park's lot is
## bordered by pavement all round, so every side is one run; a courtyard's court is walled but for
## the archway, so its one run is where the archway lands, and the line across it overhangs the
## court's walls either side the way it would a street's frontage.

## The strip of edge a fence stands on, dressed as the street a `RoadClosure` closes — so everything
## that reads a closure's `segment` (the day's holds, the run log, the telemetry map) reads this one
## without learning a second kind of closure.
##
## **Its key is never a real street's.** A lattice key's third component is 0 or 1 for the two
## orientations; this is 2 or 3, so holding it (`EventManager.start_day` holds every closure's
## segment) holds nothing a car, a walker or a catalogue row ever asks about, and
## `StreetNetwork.by_key()` answers null for it. `a` and `b` are the block that anchors the area,
## which is what a log line naming this closure should point at.
class Edge extends StreetNetwork.Segment:
	## The one-tile strip of the area's edge this fence stands on.
	var run: Rect2i

	func _init(anchor: Vector2i, strip: Rect2i, runs_horizontal: bool) -> void:
		super(anchor, runs_horizontal)
		b = anchor
		run = strip

	func key() -> Vector3i:
		return Vector3i(run.position.x, run.position.y, 2 if horizontal else 3)

	func tile_rect() -> Rect2i:
		return run

	## Both ends are the strip itself: the fence stands along the whole of it rather than at two
	## mouths.
	func mouth_rect(_at_a: bool) -> Rect2i:
		return run

## The calm area this fence belongs to, as the tile rect of its calm ground.
var area := Rect2i()
## Which way is out of the area from this run — the direction the pavement is in.
var outward := Vector2i.ZERO

func _init(anchor: Vector2i, calm_rect: Rect2i, strip: Rect2i, out: Vector2i) -> void:
	super(RoadClosure.Kind.PARK, Edge.new(anchor, strip, out.y != 0))
	area = calm_rect
	outward = out

## Every fence a shut calm area needs: one per run of its edge that has walkable ground outside it.
static func fence(map: CityMap, block: Vector2i) -> Array[ParkClosure]:
	var found: Array[ParkClosure] = []
	var rect := ClosurePlanner.calm_area_rect(map, block)
	for out: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		for strip in _entrance_runs(map, rect, out):
			found.append(ParkClosure.new(block, rect, strip, out))
	return found

## The runs of `rect`'s edge on the `out` side that open onto walkable ground outside it, each as a
## one-tile strip.
static func _entrance_runs(map: CityMap, rect: Rect2i, out: Vector2i) -> Array[Rect2i]:
	var runs: Array[Rect2i] = []
	var horizontal := out.y != 0
	var length: int = rect.size.x if horizontal else rect.size.y
	var start := -1
	for i in length + 1:
		var open := false
		if i < length:
			var tile := _edge_tile(rect, out, i)
			open = map.is_walkable(tile) and map.is_walkable(tile + out)
		if open and start < 0:
			start = i
		elif not open and start >= 0:
			var first := _edge_tile(rect, out, start)
			runs.append(Rect2i(first, Vector2i(i - start, 1) if horizontal
					else Vector2i(1, i - start)))
			start = -1
	return runs

## The `i`th tile of `rect`'s edge on the `out` side.
static func _edge_tile(rect: Rect2i, out: Vector2i, i: int) -> Vector2i:
	if out == Vector2i.UP:
		return Vector2i(rect.position.x + i, rect.position.y)
	if out == Vector2i.DOWN:
		return Vector2i(rect.position.x + i, rect.end.y - 1)
	if out == Vector2i.LEFT:
		return Vector2i(rect.position.x, rect.position.y + i)
	return Vector2i(rect.end.x - 1, rect.position.y + i)

## Where each line of barrier stands: along the strip, `Tuning.STREET_WIDTH` tiles apart from one
## end, with the last one pulled back to finish flush with the other end, so the lines cover the
## run end to end. Across it, half a barrier's depth inside the area's edge.
##
## **Every step between two lines is a whole even number of tiles**, on every run an open calm lot
## has (8 or 22 tiles, both even): `City` cuts each line into panels of two-thirds of a tile, so an
## even step puts an overlapping line's panels exactly on top of its neighbour's and the overlap
## draws as one fence rather than two.
func mouth_centres(_map: CityMap) -> Array[Vector2]:
	var found: Array[Vector2] = []
	var run: Rect2i = segment.tile_rect()
	var horizontal := outward.y != 0
	var length: int = run.size.x if horizontal else run.size.y
	var line := Tuning.STREET_WIDTH
	var offsets: Array[float] = []
	if length <= line:
		offsets.append(length * 0.5)
	else:
		var along := line * 0.5
		while along < length - line * 0.5:
			offsets.append(along)
			along += line
		offsets.append(length - line * 0.5)
	var tile := float(Tuning.TILE_SIZE)
	var inset := Tuning.CLOSURE_BARRIER_DEPTH * 0.5
	var across := run.end.x * tile - inset
	if outward == Vector2i.UP:
		across = run.position.y * tile + inset
	elif outward == Vector2i.DOWN:
		across = run.end.y * tile - inset
	elif outward == Vector2i.LEFT:
		across = run.position.x * tile + inset
	for offset in offsets:
		if horizontal:
			found.append(Vector2((run.position.x + offset) * tile, across))
		else:
			found.append(Vector2(across, (run.position.y + offset) * tile))
	return found

## The middle of the shut area — nothing is lying there, but `DevRig`'s `closure:<n>` spawn reads the
## line from here out through a fence to stand her on the pavement looking at it.
func cause_centre(map: CityMap) -> Vector2:
	return map.tile_rect_to_world(area).get_center()

## A fence along a north or south edge runs left to right across the screen; one along a west or
## east edge runs down it. The opposite of a street's, whose barrier lies across the street.
func barrier_runs_across() -> bool:
	return outward.y != 0
