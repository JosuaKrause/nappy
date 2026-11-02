class_name BuildingWalker
extends Node
## `--route` in the escape's building: presses the building's brief and walks her from where she
## starts to the service exit, so a run booted into the building follows on into the city
## (`RouteRig`, built once the city stands) with nobody touching it. Like `RouteRig` it is a dev
## tool behind the same debug-build gate and answers only to a dev flag, never a player control
## (docs/DECISIONS.md, M88): it presses the same movement actions a thumb does
## (`TouchControls._set_axis()`) and goes through the doors and the exit the way she does, so the
## fade, the events, the meter and the clock all run as they do for a player. It never moves her and
## never calls the win.
##
## **The route is the building's own** (`InteriorMapPlan.way_out()`): the fewest tiles walked, door
## to door, off the fire's cell (`BuildingPlan.fire_tile()`), which closes the flight from the
## second floor down in the left shaft and so sends the walk over to the right one. The building is
## the same every attempt, so the walk is planned once, when the section is planned.
##
## **A door is a jump.** A leg ends on a door's threshold, where the building carries her to the
## door's counterpart (`InteriorScene`); she is seen to have arrived when her position jumps by
## more than a tile, and the next leg is followed from there.
##
## It ends with the section: a won building leaves the walk to `RouteRig`, a lost one stops it where
## it is, and neither quits the process. A retry brief after a loss is a person's to press, and the
## walk is planned again from the start once the retry is planned.

## How close to a waypoint counts as having reached it, in pixels.
const _ARRIVE_RADIUS := 6.0
## How far off a waypoint along the row she must be to press sideways on a flight, in pixels.
const _SIDEWAYS_SLACK := 3.0
## A move longer than this in one physics frame is a door's carry, not her walking.
const _JUMP_DISTANCE := Tuning.TILE_SIZE * 2.0

var _player: Stroller
var _day: DayController
var _map: InteriorMapPlan
var _continue: Callable
var _pressed := false
## The legs of the walk, each a list of world points; the one being followed, and the point in it.
var _legs: Array[PackedVector2Array] = []
var _leg := 0
var _point := 0
## Every tile of the shaft the masked man runs.
var _pursued_shaft := {}
var _last_position := Vector2.INF
var _done := false

## Hands it what it walks: the building's `map`, the `player`, the section's `day`.
func setup(map: InteriorMapPlan, player: Stroller, day: DayController) -> void:
	_map = map
	_player = player
	_day = day
	_day.day_finished.connect(_on_day_finished)

## What a continue on a screen does (`main._on_summary_continued()`).
func use_continue(continue_from: Callable) -> void:
	_continue = continue_from

## The building's brief is up (`RunFlow.brief_opened`): answered with the continue a tap and a key
## both end in, a frame later, since `main` shows the screen right after the flow opens it. Only the
## first brief of the building is pressed; a retry brief after a loss waits for a person.
func press_the_brief(spec: DaySpec) -> void:
	if spec.section != DaySpec.Section.BUILDING or _continue.is_null() or _pressed:
		return
	_pressed = true
	await get_tree().process_frame
	_continue.call(RunFlow.Mode.BRIEF)

## The building section has been planned (`RunFlow.day_planned`): plans the walk out from where she
## stands.
func start_section(spec: DaySpec) -> void:
	if spec.section != DaySpec.Section.BUILDING:
		return
	_legs.clear()
	_pursued_shaft.clear()
	for tile in _map.stairwell_tiles("stairwell_%s" % BuildingPlan.PURSUED_SIDE):
		_pursued_shaft[tile] = true
	_leg = 0
	_point = 0
	_last_position = Vector2.INF
	var blocked := {}
	var fire := BuildingPlan.fire_tile(_map)
	if fire != InteriorMapPlan.NOWHERE:
		blocked[fire] = true
	for tile in BuildingPlan.pursuer_ground_below_the_first_floor(_map):
		blocked[tile] = true
	for leg in _map.way_out(_map.world_to_tile(_player.global_position), blocked):
		var points := PackedVector2Array()
		for tile: Vector2i in leg:
			points.append(_map.tile_to_world(tile))
		_legs.append(points)
	_done = _legs.is_empty()
	if _done:
		Telemetry.note("route", "building: no way out of the building from where she stands")
	else:
		Telemetry.note("route", "building: walking out in %d legs" % _legs.size())

func _physics_process(_delta: float) -> void:
	if _done or not _day or not _day.is_running():
		return
	var here := _player.global_position
	if _last_position != Vector2.INF and here.distance_to(_last_position) > _JUMP_DISTANCE:
		_leg += 1
		_point = 0
		if _leg >= _legs.size():
			_release()
			return
	_last_position = here
	var points := _legs[_leg]
	while _point < points.size() - 1 and _has_reached(here, points, _point):
		_point += 1
	var direction := (points[_point] - here)
	if direction.length() <= 1.0:
		_release()
		return
	direction = direction.normalized()
	# On a flight a sideways press is what walks it: the stroller turns it along the slope
	# (`Stroller._redirect_along_a_flight()`), down toward the side of its lower end and up toward the
	# other, and a press with no sideways part turns into a climb. So press the way along the row the
	# waypoint lies, or, directly above or below, the way that goes up or down the slope.
	var slope := _map.slope_dir_at(here)
	if slope != 0:
		var along := points[_point].x - here.x
		if absf(along) <= _SIDEWAYS_SLACK:
			along = float(slope) if points[_point].y > here.y else -float(slope)
		direction = Vector2(signf(along), 0.0)
	TouchControls._set_axis(&"move_left", &"move_right", direction.x)
	TouchControls._set_axis(&"move_up", &"move_down", direction.y)
	# The pursued shaft is run, not walked: the masked man comes up it faster than a walk, and a
	# walker is caught (`EventCatalogue._masked_pursuer()`).
	if _pursued_shaft.has(_map.world_to_tile(here)):
		Input.action_press(&"run")
	else:
		Input.action_release(&"run")

## Whether she has reached `points[at]`, which is not the last: within `_ARRIVE_RADIUS` of it, or past
## it toward the next one, within a tile, so a corner is not walked back to the centre of the tile
## she has already crossed; or, on a flight, anywhere in its tile. A press on a flight is turned along
## the slope, so she walks the flight's diagonal and the centre of a tile beside it may be a pixel off
## it and never come within the radius.
func _has_reached(here: Vector2, points: PackedVector2Array, at: int) -> bool:
	var point := points[at]
	if here.distance_to(point) <= _ARRIVE_RADIUS:
		return true
	if here.distance_to(point) < Tuning.TILE_SIZE \
			and (points[at + 1] - point).dot(here - point) > 0.0:
		return true
	return (_map.slope_dir_at(here) != 0 or _map.slope_dir_at(point) != 0) \
			and _map.world_to_tile(here) == _map.world_to_tile(point)

func _on_day_finished(result: GameEnums.DayResult) -> void:
	if _done:
		return
	_done = true
	_release()
	Telemetry.note("route", "building: section ended (%s)" % GameEnums.DayResult.keys()[result])

func _release() -> void:
	Input.action_release(&"run")
	TouchControls._set_axis(&"move_left", &"move_right", 0.0)
	TouchControls._set_axis(&"move_up", &"move_down", 0.0)
