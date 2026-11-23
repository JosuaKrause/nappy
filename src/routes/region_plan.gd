class_name RegionPlan
extends RefCounted
## One region growth's result for a day: which boundary crossings are wall today and which are
## doors, plus the bodies the wall and the doors stand as. Built by `RegionPlanner.plan_day()` (and
## a scene recipe's authored checkpoint through `RegionPlanner.stand_door()`), which add to it
## through the `add_*` methods; every other class asks it through the readers.
##
## The readers hand the plan's own arrays back for reading: a caller that wants to change a plan
## uses an `add_*` method.

## Boundary segments that are wall today: the whole day if before `Tuning.REGION_WALL_FIRST_DAY`,
## since nothing is drawn before then. Asked through `wall_segments()`.
var _walls: Array[StreetNetwork.Segment] = []
## Boundary segments the day's tree crosses: a hut on each pavement and a gate over the road, from
## `Tuning.REGION_WALL_FIRST_DAY`. Asked through `door_segments()`; see `_door_bodies`.
var _doors: Array[StreetNetwork.Segment] = []
## Through-alley rects that are **crossings** (`RegionPlanner.ground_region_of` differs at their two
## mouths) and wall today, both mouths walled: the alley equivalent of `_walls`. Asked through
## `walled_alleys()`.
var _alley_walls: Array[Rect2i] = []
## Crossing alley rects the day's tree uses: a single guard at each of its two mouths, from
## `Tuning.REGION_WALL_FIRST_DAY`. Asked through `door_alleys()`; see `_door_bodies`.
var _alley_doors: Array[Rect2i] = []
## The wall's own bodies, as `EventPlan`: hard seals of the roadblock row, one tile deep at a
## boundary segment's mouth or an alley's two mouths. Kept as its own list, appended to the day's
## plan (`EventManager.plans()`) by the caller, rather than merged anywhere: a caller that only
## wants to know where the wall runs never has to filter it back out of the day's whole plan.
## Asked through `wall_plans()`.
var _wall_bodies: Array[EventPlan] = []
## The door structure's own bodies: two `checkpoint_hut`s and a `checkpoint_gate` at every street
## door's mouth, one `checkpoint_post` at each mouth of every alley door. Kept apart from
## `_wall_bodies` for the same reason. Asked through `door_plans()`.
var _door_bodies: Array[EventPlan] = []
## One `GateState` per street door, in the same order as `_doors`: `Crowd` reads this to know where
## today's gates are and to raise and lower them; the `checkpoint_gate` `EventPlan` at the same
## crossing carries the identical object. Empty for an alley door, which has no gate. Asked
## through `gate_states()`.
var _gates: Array[GateState] = []

# ----------------------------------------------------------------------- readers ---

## The boundary segments that are wall today.
func wall_segments() -> Array[StreetNetwork.Segment]:
	return _walls

## The boundary segments the day's tree crosses, each a door.
func door_segments() -> Array[StreetNetwork.Segment]:
	return _doors

## The crossing alleys' rects that are wall today.
func walled_alleys() -> Array[Rect2i]:
	return _alley_walls

## The crossing alleys' rects the day's tree uses, each a door.
func door_alleys() -> Array[Rect2i]:
	return _alley_doors

## The plans the wall's bodies stand as.
func wall_plans() -> Array[EventPlan]:
	return _wall_bodies

## The plans the doors' bodies stand as.
func door_plans() -> Array[EventPlan]:
	return _door_bodies

## The gates of today's street doors, in the order of `door_segments()`.
func gate_states() -> Array[GateState]:
	return _gates

# ----------------------------------------------------------------------- builders ---

## Records `segment` as wall today.
func add_wall(segment: StreetNetwork.Segment) -> void:
	_walls.append(segment)

## Records `segment` as a door today.
func add_door(segment: StreetNetwork.Segment) -> void:
	_doors.append(segment)

## Records a crossing alley's `rect` as wall today.
func add_walled_alley(rect: Rect2i) -> void:
	_alley_walls.append(rect)

## Records a crossing alley's `rect` as a door today.
func add_door_alley(rect: Rect2i) -> void:
	_alley_doors.append(rect)

## Adds the plan one wall body stands as.
func add_wall_plan(body: EventPlan) -> void:
	_wall_bodies.append(body)

## Adds the plans a wall stands as.
func add_wall_plans(bodies: Array[EventPlan]) -> void:
	_wall_bodies.append_array(bodies)

## Adds the plan one door body stands as.
func add_door_plan(body: EventPlan) -> void:
	_door_bodies.append(body)

## Adds the gate of the street door just recorded.
func add_gate(gate: GateState) -> void:
	_gates.append(gate)
