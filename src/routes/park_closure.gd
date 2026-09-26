class_name ParkClosure
extends RoadClosure
## One fenced run of `CityMap.fenced_park`'s edge — the one calm area this run ever physically
## closes, at most once, in act III or later. *(PLAYTEST-140, statement 9: "doing it for one park,
## sure, more towards the later stages of the game once but not for regular".)* Every other used
## area is off the route tree the same way (`CityMap.shut_calm`) but carries no fence at all: this
## class only ever draws the one area `CityMap.fenced_park` names.
##
## **It is a `RoadClosure` so that it is drawn, and stands in her way, exactly as a closed street's
## barriers do.** `ClosurePlanner.plan_day` hands these to `City` beside the day's street closures,
## and `City._spawn_closure()` stands the same line of barrier panels — the same pictures, the
## `closed` sign on the middle one and one static body behind the line — at every point
## `mouth_centres()` answers, lying the way `barrier_runs_across()` says. The kind is `PARK`, which
## like `CORDON` leaves nothing lying anywhere. So the one fenced park reads the way a shut street
## reads, from the pavement beside it, before she has taken a step onto it.
##
## **Which park is fenced is not decided here**: `CityMap._shut_the_spent_calm()` decides it at the
## repaint, from `ClosurePlanner.calm_to_shut()`'s own candidates, and `CityMap.fenced_park` records
## it. This is only the fence around what was decided.
##
## **The fence stands on the calm ground's own edge row, never on the pavement.** A barrier line is
## `Tuning.CLOSURE_BARRIER_DEPTH` deep and stands half of that inside the edge, so the pavement
## beside the park stays exactly as wide as it was and a route that runs along it is untouched.
## **One line covers a whole run, end to end, and no two lines overlap or overshoot one another.**
## `barrier_width()` overrides `RoadClosure`'s own street-width answer with the run's real length, so
## `City._spawn_barrier()` tiles panels across exactly that length rather than a fixed one — a run
## far longer or shorter than a street's mouth still reads as one continuous rail, with no overhang
## past either end of its own ground.
##
## **Where two runs meet at a corner of the area they turn on one shared post.** A run covers its
## own tiles of the edge, corner tiles included, on every side; where the next side's run also
## reaches the same corner tile, each line stops exactly at the corner of the two fence lines
## (half a barrier's depth in from both edges) and one `barrier_post.svg` stands there. The
## broadside run's rails end at the post's middle and the end-on run's column covers the ground
## from that corner to the next, so its far end meets the post's foot and its near end runs in
## behind the next broadside run's end post: one fence turning the corner, with no gap between the
## two lines, no rail past the other and nothing overhanging the post. A run that ends anywhere
## else — against a wall, or at an archway's jamb — runs to the end of its own ground and ends on a
## post of its own, inset so the post stays on that ground. See `fence()` and `posts()`.
##
## **An entrance is any tile of the edge with walkable ground outside it.** An open park's lot is
## bordered by pavement all round, so every side is one run; a courtyard's court is walled but for
## the archway, so its one run is exactly where the archway lands, flush with its jambs rather than
## overhanging them.

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

## Half the width of `barrier_post.svg`'s post body (8px, and its outline): how far a post at a
## run's open end stands in from that end, so the post stays on the run's own ground.
const POST_HALF := 4.6

## The calm area this fence belongs to, as the tile rect of its calm ground.
var area := Rect2i()
## Which way is out of the area from this run — the direction the pavement is in.
var outward := Vector2i.ZERO
## Where the line starts and ends along its run, in world pixels on the run's own axis (x for a
## north or south edge, y for a west or east one). The run's own tiles, except at an end that turns
## a corner onto the next side's run, which stops at the corner of the two fence lines instead.
var from_along := 0.0
var to_along := 0.0
## Whether each end turns a corner onto the next side's run (`fence()`).
var joined_start := false
var joined_end := false

func _init(anchor: Vector2i, calm_rect: Rect2i, strip: Rect2i, out: Vector2i,
		start_turns := false, end_turns := false) -> void:
	super(RoadClosure.Kind.PARK, Edge.new(anchor, strip, out.y != 0))
	area = calm_rect
	outward = out
	joined_start = start_turns
	joined_end = end_turns
	var tile := float(Tuning.TILE_SIZE)
	var horizontal := out.y != 0
	from_along = (strip.position.x if horizontal else strip.position.y) * tile
	to_along = (strip.end.x if horizontal else strip.end.y) * tile
	if joined_start:
		from_along = _line(calm_rect, Vector2i.LEFT if horizontal else Vector2i.UP)
	if joined_end:
		to_along = _line(calm_rect, Vector2i.RIGHT if horizontal else Vector2i.DOWN)

## Every fence a shut calm area needs: one per run of its edge that has walkable ground outside it,
## each told which of its ends turns a corner onto the next side's run. The two runs at a corner
## are joined when both reach its corner tile, which is the same question asked from either side.
static func fence(map: CityMap, block: Vector2i) -> Array[ParkClosure]:
	var found: Array[ParkClosure] = []
	var rect := ClosurePlanner.calm_area_rect(map, block)
	var runs := {}
	for out: Vector2i in SIDES:
		runs[out] = _entrance_runs(map, rect, out)
	var first := rect.position
	var last := rect.end - Vector2i.ONE
	for out: Vector2i in SIDES:
		var horizontal := out.y != 0
		var row: int = first.y if out == Vector2i.UP else last.y
		var column: int = first.x if out == Vector2i.LEFT else last.x
		for strip: Rect2i in runs[out]:
			var start_corner := Vector2i(first.x, row) if horizontal else Vector2i(column, first.y)
			var end_corner := Vector2i(last.x, row) if horizontal else Vector2i(column, last.y)
			var start_side := Vector2i.LEFT if horizontal else Vector2i.UP
			var end_side := Vector2i.RIGHT if horizontal else Vector2i.DOWN
			var start_turns := strip.has_point(start_corner) \
					and _any_covers(runs[start_side], start_corner)
			var end_turns := strip.has_point(end_corner) and _any_covers(runs[end_side], end_corner)
			found.append(ParkClosure.new(block, rect, strip, out, start_turns, end_turns))
	return found

## The four sides, the west and east first. **The order is load-bearing for the drawing**: `City`
## spawns closures in this order, and y-sorting breaks a tie by the order nodes were added, so an
## end-on column's nearest panel, whose feet share the south run's y, is drawn behind that run's
## rails and its corner post rather than over them.
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

## How far above its feet `barrier_across.svg`'s lower rail runs (its foot edge is at 16.6 of 24):
## an end-on run is drawn this far up the screen (`end_on_rise()`), so its far end meets the north
## run's rails where they end on the corner post and its near end runs in behind the south run's.
const RAIL_RISE := 7.4

static func _any_covers(strips: Array[Rect2i], tile: Vector2i) -> bool:
	for strip in strips:
		if strip.has_point(tile):
			return true
	return false

## The world coordinate of the fence line on `rect`'s `out` side, across that side: half a
## barrier's depth inside the area's edge. A y for a north or south side, an x for a west or east.
static func _line(rect: Rect2i, out: Vector2i) -> float:
	var world := Rect2(Vector2(rect.position) * Tuning.TILE_SIZE,
			Vector2(rect.size) * Tuning.TILE_SIZE)
	var inset := Tuning.CLOSURE_BARRIER_DEPTH * 0.5
	if out == Vector2i.UP:
		return world.position.y + inset
	if out == Vector2i.DOWN:
		return world.end.y - inset
	if out == Vector2i.LEFT:
		return world.position.x + inset
	return world.end.x - inset

## The runs of `rect`'s edge on the `out` side that open onto walkable ground outside it, each as a
## one-tile strip. Every side is scanned whole, corner tiles included: a corner tile belongs to both
## of its sides' runs, and `fence()` is what makes the two meet there rather than cross.
static func _entrance_runs(map: CityMap, rect: Rect2i, out: Vector2i) -> Array[Rect2i]:
	var runs: Array[Rect2i] = []
	var horizontal := out.y != 0
	var length: int = rect.size.x if horizontal else rect.size.y
	var start := -1
	for i in range(0, length + 1):
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

## How long this fence's one line is: from `from_along` to `to_along`, in pixels — never a
## street's width. Overrides `RoadClosure.barrier_width()`, which `City._spawn_barrier()` reads
## instead of assuming `Tuning.STREET_WIDTH`; see the class doc.
func barrier_width() -> float:
	return to_along - from_along

## Where the one line of barrier stands: the middle of its span, across it half a barrier's depth
## inside the area's edge. One point is the whole of it — `barrier_width()` already says how wide
## `City._spawn_barrier()` draws it, so nothing here has to split a long run into several.
func mouth_centres(_map: CityMap) -> Array[Vector2]:
	var found: Array[Vector2] = [_point((from_along + to_along) * 0.5)]
	return found

## The posts this run ends on (`RoadClosure.posts()`). A corner two runs turn on has one post, and
## the north or south run owns it, so the west or east run only stands posts at ends that turn no
## corner. An open end's post stands `POST_HALF` in from the end, on the run's own ground.
func posts(_map: CityMap) -> Array[Vector2]:
	var found: Array[Vector2] = []
	var horizontal := outward.y != 0
	if horizontal or not joined_start:
		found.append(_point(from_along if joined_start else from_along + POST_HALF))
	if horizontal or not joined_end:
		found.append(_point(to_along if joined_end else to_along - POST_HALF))
	return found

func end_on_rise() -> float:
	return RAIL_RISE

## The point `along` pixels down this run's axis, on its fence line.
func _point(along: float) -> Vector2:
	var across := _line(area, outward)
	return Vector2(along, across) if outward.y != 0 else Vector2(across, along)

## The middle of the shut area — nothing is lying there, but `DevRig`'s `closure:<n>` spawn reads the
## line from here out through a fence to stand her on the pavement looking at it.
func cause_centre(map: CityMap) -> Vector2:
	return map.tile_rect_to_world(area).get_center()

## A fence along a north or south edge runs left to right across the screen; one along a west or
## east edge runs down it. The opposite of a street's, whose barrier lies across the street.
func barrier_runs_across() -> bool:
	return outward.y != 0
