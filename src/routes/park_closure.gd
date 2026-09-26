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
## **A north-south edge (`UP`/`DOWN`) keeps the whole side, corner tiles included; an east-west edge
## (`LEFT`/`RIGHT`) stops one tile short of each end.** The two would otherwise both reach the same
## corner tile and cross there instead of meeting — see `_entrance_runs()`. Letting one axis own
## every corner and trimming the other is what turns that cross into a clean joint, with no gap a
## pram could use: the horizontal line's own barrier depth already covers the corner tile's outer
## edge, and the vertical line picks up flush against it.
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
##
## **`UP`/`DOWN` scan the whole side; `LEFT`/`RIGHT` stop one tile short of each end**, unless the
## side is too short to spare them (`length <= 2`, where there is no room for the ambiguity the trim
## exists to resolve). The two corner tiles of a rectangle belong to exactly one edge each — the
## horizontal one, arbitrarily but consistently — so the vertical scan simply never offers them, and
## a fence never reaches into a corner two ways at once. See the class doc for what that buys.
static func _entrance_runs(map: CityMap, rect: Rect2i, out: Vector2i) -> Array[Rect2i]:
	var runs: Array[Rect2i] = []
	var horizontal := out.y != 0
	var length: int = rect.size.x if horizontal else rect.size.y
	var trim := not horizontal and length > 2
	var first_index := 1 if trim else 0
	var last_index := length - 1 if trim else length
	var start := -1
	for i in range(first_index, last_index + 1):
		var open := false
		if i < last_index:
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

## How wide this fence's one line is: the run's own length, in pixels — never a street's width.
## Overrides `RoadClosure.barrier_width()`, which `City._spawn_barrier()` reads instead of assuming
## `Tuning.STREET_WIDTH`; see the class doc.
func barrier_width() -> float:
	var run: Rect2i = segment.tile_rect()
	var horizontal := outward.y != 0
	return float(run.size.x if horizontal else run.size.y) * Tuning.TILE_SIZE

## Where the one line of barrier stands: the middle of the run, across it half a barrier's depth
## inside the area's edge. One point is the whole of it — `barrier_width()` already says how wide
## `City._spawn_barrier()` draws it, so nothing here has to split a long run into several.
func mouth_centres(_map: CityMap) -> Array[Vector2]:
	var run: Rect2i = segment.tile_rect()
	var horizontal := outward.y != 0
	var tile := float(Tuning.TILE_SIZE)
	var inset := Tuning.CLOSURE_BARRIER_DEPTH * 0.5
	var across := run.end.x * tile - inset
	if outward == Vector2i.UP:
		across = run.position.y * tile + inset
	elif outward == Vector2i.DOWN:
		across = run.end.y * tile - inset
	elif outward == Vector2i.LEFT:
		across = run.position.x * tile + inset
	var along := (run.position.x + run.size.x * 0.5) * tile if horizontal \
			else (run.position.y + run.size.y * 0.5) * tile
	var found: Array[Vector2] = [Vector2(along, across) if horizontal else Vector2(across, along)]
	return found

## The middle of the shut area — nothing is lying there, but `DevRig`'s `closure:<n>` spawn reads the
## line from here out through a fence to stand her on the pavement looking at it.
func cause_centre(map: CityMap) -> Vector2:
	return map.tile_rect_to_world(area).get_center()

## A fence along a north or south edge runs left to right across the screen; one along a west or
## east edge runs down it. The opposite of a street's, whose barrier lies across the street.
func barrier_runs_across() -> bool:
	return outward.y != 0
