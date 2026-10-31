class_name GiveWay
extends RefCounted
## **Where a car on a street gives way**: the junction box ahead of it, the red light that holds it
## at the box's entry line, the zebra she waits at that holds it short of the paint, and whether
## that zebra lies past the box. The street lattice's own rules, stateless and asked in plain
## values, so a crowd car (`CarStrategy`, `Crowd.give_way_at_junctions()`) and an event car
## (`EventCarDriving`) read one answer instead of keeping two copies in step by hand. Each keeps
## what is its own: the crowd car its braking curve, its commit rule and its queue at a box, the
## event car its refusal of a step past the line.
##
## Every function takes a position along the street's axis (`along`, `cross`: the coordinate the car
## travels along and the one across it), `vertical` (travelling along y) and `direction` (+1 or -1).
## **A line is a distance from the car's centre along its travel**, `INF` where there is none.
##
## **A main road does not give way** (`owes_her_way()`): its crossings are the light's to keep, so
## the paint there is a signal's business and not a courtesy, and taking the exemption away makes a
## signal decoration on top of a courtesy that was already enough (the **crowd-traffic** skill).

## **The junction box a body at `along` travelling `direction` is in or coming to**, as its index
## along the axis: inside a corridor the one it is in, in the block band between two the one that
## lies the way it is pointing.
static func box_index(along: float, direction: float) -> int:
	var along_tile := floori(along / float(Tuning.TILE_SIZE))
	var index := CityMap.junction_index(along_tile)
	if CityMap.corridor_offset(along_tile) < 0 and direction > 0.0:
		index += 1
	return index

## The world coordinate of box `index`'s near edge for a body travelling `direction`: its low edge
## going up the axis, its high edge going down.
static func box_near_edge(index: int, direction: float) -> float:
	var low := float(index * CityMap.period()) * float(Tuning.TILE_SIZE)
	return low if direction > 0.0 else low + float(Tuning.STREET_WIDTH) * float(Tuning.TILE_SIZE)

## How far from a nose `nose` ahead of its centre at `along` to the near edge of the box it comes
## to (`box_index()`): negative once the nose is inside.
static func distance_to_box(along: float, direction: float, nose: float) -> float:
	return (box_near_edge(box_index(along, direction), direction) - along) * direction - nose

## The junction a body in the corridor `corridor` (the street it drives along) comes to at box
## `index`, as `TrafficSignals` and the crowd's holds key it.
static func junction_at(index: int, corridor: int, vertical: bool) -> Vector2i:
	return Vector2i(corridor, index) if vertical else Vector2i(index, corridor)

## Whether the light at `junction` is red for a body travelling along `vertical`: a signalled
## junction whose arm is not green. **Amber is not green**, for a crowd car as for an event car.
## False with no signals at all.
static func is_red(signals: TrafficSignals, junction: Vector2i, vertical: bool) -> bool:
	return signals != null and signals.is_signalled(junction) \
			and not signals.green_for(junction, vertical)

## **The line a car holds at**, for something `distance` ahead of its centre it gives way at: a
## setback short of it (`Tuning.CAR_STOP_LINE_SETBACK`), so the car stops a little before the paint
## or the box rather than on it. Not clamped: one already inside the setback is a negative room.
static func stop_line(distance: float) -> float:
	return distance - Tuning.CAR_STOP_LINE_SETBACK

## **Whether a car at `at` owes her way**: she is somewhere (`her` is not `INF`), the street it
## drives along gives way (not the main road, whose crossings the light keeps), and she is within
## half a street of the car's line, so somebody in the next street over is not this street's
## problem. Not about distance: how near she must be to be seen is the caller's.
static func owes_her_way(map: WorldMap, vertical: bool, at: Vector2, her: Vector2) -> bool:
	if her == Vector2.INF:
		return false
	if map.street_kind_at(vertical, map.world_to_tile(at)) == GameEnums.StreetKind.MAIN:
		return false
	var cross := at.x if vertical else at.y
	var hers := her.x if vertical else her.y
	return absf(hers - cross) <= Tuning.STREET_WIDTH * float(Tuning.TILE_SIZE) * 0.5

## **The near edge of the first zebra ahead that she waits at**, as a world coordinate along the
## axis, or `INF`: the whole run of paint the car meets, not the tile she stands on (a zebra is
## two tiles deep on an ordinary street and six where a road crosses a pedestrianised one), and the
## first tile of it within `Tuning.CAR_ZEBRA_WAIT_RADIUS` along of her. **The scan runs tile by
## tile from the car's own tile**, so a car stopped a few pixels from the paint, or already on it,
## still finds it; sampling points every 32px aliases, and the way it fails is a car that decides
## there is nothing to give way to and pulls away with somebody on the zebra.
##
## Callers ask `owes_her_way()` first, and cut the scan to what they can see: the crowd to the cars
## `Crowd` has told where she is, the event car to `Tuning.CAR_ZEBRA_SIGHT` from her. The distance
## to the edge is `(edge - along) * direction`, which is negative for a nose already past it — the
## commit rule's business, which is the caller's own.
static func zebra_edge_ahead(map: WorldMap, at: Vector2, vertical: bool, direction: float,
		her: Vector2) -> float:
	var tile := float(Tuning.TILE_SIZE)
	var waiting_along := her.y if vertical else her.x
	var step := Vector2i(0, signi(int(direction))) if vertical else Vector2i(signi(int(direction)), 0)
	var here := map.world_to_tile(at)
	# The first tile of the run of paint being walked, or -1 between runs.
	var run_start := -1
	for k in range(0, ceili(Tuning.CAR_ZEBRA_SIGHT / tile) + 1):
		var at_tile := here + step * k
		var along_index: int = at_tile.y if vertical else at_tile.x
		if not map.is_crossing(at_tile):
			run_start = -1
			continue
		if run_start < 0:
			run_start = along_index
		# Distance along the street, not straight-line: somebody at the far kerb of a six-tile
		# corridor is beside the crossing, not two tiles from it.
		if absf(waiting_along - float(along_index) * tile) > Tuning.CAR_ZEBRA_WAIT_RADIUS:
			continue
		# The near edge of the run: its lowest coordinate going one way and its highest going the
		# other, since the scan starts at the end nearest the car.
		return float(run_start + (0 if direction > 0.0 else 1)) * tile
	return INF

## **Whether a zebra edge lies past the box ahead**: further along than the box's near edge `near`
## by more than half a pixel, so a car stopped a setback short of that paint would stand inside the
## box. **Nothing enters a box it cannot leave** (the **crowd-traffic** skill): the car holds at the
## box's entry line instead, as at a red light.
static func lies_past_the_box(edge: float, near: float, direction: float) -> bool:
	return (edge - near) * direction > 0.5

## **Whether she waits at the zebra on the far side of box `index`** (travelling `direction`,
## in the street `cross` along): at either tile of the sidewalk-deep paint that side of the box,
## within `Tuning.CAR_ZEBRA_WAIT_RADIUS` along of it. Decided wherever she is along the paint, not
## within a sight circle of the zebra: any later the nose is already in the box.
static func waits_past_the_box(map: WorldMap, index: int, direction: float, cross: float,
		vertical: bool, her: Vector2) -> bool:
	var tile := float(Tuning.TILE_SIZE)
	var her_along := her.y if vertical else her.x
	var first := index * CityMap.period() \
			+ (Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH if direction > 0.0 else 0)
	var lane_index := floori(cross / tile)
	for k in Tuning.SIDEWALK_WIDTH:
		var zebra := Vector2i(lane_index, first + k) if vertical \
				else Vector2i(first + k, lane_index)
		if map.is_crossing(zebra) \
				and absf(her_along - float(first + k) * tile) <= Tuning.CAR_ZEBRA_WAIT_RADIUS:
			return true
	return false
