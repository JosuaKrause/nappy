extends RefCounted
## Protester pointing (M65): which of the eight `protester_point_*` poses a protest rank draws,
## and when it stays the plain `protester.svg` instead. See `docs/EVENTS.md`, the `protest` row,
## and `EventInstance._protester_texture()`.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242

var _city: City

func run(t) -> void:
	_test_bearing_sectors_pick_the_matching_pose(t)
	_test_a_bearing_off_centre_still_rounds_to_its_sector(t)
	_test_plain_pose_with_no_objective(t)
	_test_plain_pose_on_a_mark_step(t)
	_test_pointing_pose_on_a_perform_step(t)

# ---------------------------------------------------------------- bearing ---

## The exact inverse of `_protester_texture()`'s own `atan2(toward.x, -toward.y)`, so feeding a
## bearing in and reading it back out is round-trip rather than a second formula to disagree with
## the first.
func _at_bearing(degrees: float, distance: float) -> Vector2:
	var radians := deg_to_rad(degrees)
	return Vector2(sin(radians), -cos(radians)) * distance

## One sample squarely inside each of the eight 45° sectors, so a swapped table entry shows up as
## a specific wrong pose rather than a single "not plain" check any of the eight would pass.
func _test_bearing_sectors_pick_the_matching_pose(t) -> void:
	var from := Vector2(100.0, 100.0)
	var sectors := [
		[0.0, EventInstance.PROTESTER_POINT_N, "north"],
		[45.0, EventInstance.PROTESTER_POINT_NE, "north-east"],
		[90.0, EventInstance.PROTESTER_POINT_E, "east"],
		[135.0, EventInstance.PROTESTER_POINT_SE, "south-east"],
		[180.0, EventInstance.PROTESTER_POINT_S, "south"],
		[225.0, EventInstance.PROTESTER_POINT_SW, "south-west"],
		[270.0, EventInstance.PROTESTER_POINT_W, "west"],
		[315.0, EventInstance.PROTESTER_POINT_NW, "north-west"],
	]
	for sector in sectors:
		var objective: Vector2 = from + _at_bearing(sector[0], 200.0)
		t.check(EventInstance._protester_texture(from, objective) == sector[1],
				"bearing %.0f° points %s" % [sector[0], sector[2]])

## A bearing 20° either side of a sector's own centre is still well inside its 45°-wide band —
## the pose is picked by nearest, not by an exact match.
func _test_a_bearing_off_centre_still_rounds_to_its_sector(t) -> void:
	var from := Vector2.ZERO
	for offset in [-20.0, 20.0]:
		var objective := from + _at_bearing(90.0 + offset, 150.0)
		t.check(EventInstance._protester_texture(from, objective) == EventInstance.PROTESTER_POINT_E,
				"%.0f° off east still rounds to the east pose" % offset)

# ---------------------------------------------------------------- no objective ---

func _test_plain_pose_with_no_objective(t) -> void:
	t.check(EventInstance._protester_texture(Vector2.ZERO, Vector2.INF) == EventInstance.PROTESTER,
			"no objective at all draws the plain rank")
	t.check(EventInstance._protester_texture(Vector2(5.0, 5.0), Vector2(5.0, 5.0))
			== EventInstance.PROTESTER,
			"an objective on top of the protester draws the plain rank rather than dividing by zero")

# ---------------------------------------------------------------- the resistance's own steps ---
# The same city-and-director rig `test_resistance.gd` builds `ResistanceDirector` with, kept
# separate rather than shared so this file never writes to one the resistance suite also owns.

func _build_city(t) -> void:
	_city = CITY_SCENE.instantiate()
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))

func _director(t) -> ResistanceDirector:
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(_city, _city.map)
	return director

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:resistance" % [SEED, day])
	return rng

func _with_clean_run(action: Callable) -> void:
	var saved_completed := GameState.completed_resistance_steps.duplicate()
	var saved_failed := GameState.failed_resistance_steps.duplicate()
	var saved_progress := GameState.resistance_progress
	var saved_package := GameState.resistance_carrying_package
	var saved_brief := GameState.pending_resistance_brief
	GameState.completed_resistance_steps = []
	GameState.failed_resistance_steps = []
	GameState.resistance_progress = 0
	GameState.resistance_carrying_package = false
	GameState.pending_resistance_brief = ""
	action.call()
	GameState.completed_resistance_steps = saved_completed
	GameState.failed_resistance_steps = saved_failed
	GameState.resistance_progress = saved_progress
	GameState.resistance_carrying_package = saved_package
	GameState.pending_resistance_brief = saved_brief

## *(2026-09-11, the player: "the mark is findable now -- I don't think we need pointing for
## that.")* A pickup gives `ResistanceDirector.pointable_objective()` nothing to hand back.
func _test_plain_pose_on_a_mark_step(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(4, _rng(4), 300.0)
		var step := director.current_step()
		t.check(step != null and step.is_pickup, "day 4 offers the first chalk mark")
		t.check(director.pointable_objective() == Vector2.INF,
				"a mark step gives a protester nothing to point at")
		t.check(EventInstance._protester_texture(Vector2.ZERO, director.pointable_objective())
				== EventInstance.PROTESTER,
				"...so a protester anywhere in the city draws the plain rank")
	)

## *(2026-09-11, the player: "but the other tasks are not as easy and need pointing.")* A perform
## step's own contact — already placed by `ResistanceDirector._place()`, M78's rules untouched —
## is exactly what a protester points at.
func _test_pointing_pose_on_a_perform_step(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		GameState.completed_resistance_steps = [1]
		var director := _director(t)
		director.start_day(5, _rng(5), 300.0)
		var step := director.current_step()
		t.check(step != null and not step.is_pickup, "day 5 offers the first perform step")

		var objective := director.pointable_objective()
		t.check(objective != Vector2.INF, "a perform step gives a protester somewhere to point")
		t.check(objective == director.contact_position(),
				"exactly the step's own contact, never a placement or a move of its own")

		var texture := EventInstance._protester_texture(objective + Vector2(0.0, 300.0), objective)
		t.check(texture != EventInstance.PROTESTER,
				"a protester standing away from the objective points rather than standing plain")
	)
