extends RefCounted
## `OpeningShot`: day 1's camera on the park, then back along the tutorial route to her door. The
## route's line is pure geometry over a hand-laid `TutorialRoute` (no city: its questions the line
## asks need none); the timing, the skip and the hand-back are watched through real physics frames
## on a bare `Camera2D` standing for hers (the viewport's current camera), so the camera the shot
## makes current, the one it hands back and what it says when it ends are what the game sees.

func run(t: TestRunner) -> void:
	_test_the_line_runs_from_the_park_back_along_the_route_to_the_door(t)
	await _test_the_shot_rests_then_moves_at_one_pace_and_hands_the_view_back(t)
	await _test_a_press_skips_it_and_an_echo_does_not(t)

## A route of two lesson streets: the doorstep's street ends at junction (2, 2), the first lesson
## street runs down to (2, 3), the second right to (3, 3), and the park is block (3, 3).
func _route() -> TutorialRoute:
	var home := StreetNetwork.Segment.new(Vector2i(1, 2), true)
	var down := StreetNetwork.Segment.new(Vector2i(2, 2), false)
	var across := StreetNetwork.Segment.new(Vector2i(2, 3), true)
	var streets: Array[StreetNetwork.Segment] = [down, across]
	var junctions: Array[Vector2i] = [Vector2i(2, 2), Vector2i(2, 3), Vector2i(3, 3)]
	return TutorialRoute.new(null, home, streets, junctions, Vector2i(3, 3), Rect2i())

func _centre(junction: Vector2i) -> Vector2:
	return (Vector2(junction * CityMap.period()) + Vector2.ONE * (Tuning.STREET_WIDTH * 0.5)) \
			* Tuning.TILE_SIZE

func _test_the_line_runs_from_the_park_back_along_the_route_to_the_door(t: TestRunner) -> void:
	var door := Vector2(70.0, 90.0)
	var line := OpeningShot.line_for(_route(), door)
	t.check(line.size() == 5, "the park, three junctions and the door (%d)" % line.size())
	var park := Rect2(CityMap.block_rect(Vector2i(3, 3))).get_center() * Tuning.TILE_SIZE
	t.check(line[0] == park, "it starts on the park's block")
	t.check(line[1] == _centre(Vector2i(3, 3)) and line[2] == _centre(Vector2i(2, 3))
			and line[3] == _centre(Vector2i(2, 2)),
			"then the junctions from the route's far end back to where it leaves the doorstep's street")
	t.check(line[4] == door, "and ends at her door")

## A camera standing for hers, in the tree and current, looking at `at`.
func _her_camera(t: TestRunner, at: Vector2) -> Camera2D:
	var camera := Camera2D.new()
	camera.name = "HerCamera"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.zoom = Vector2(2.0, 2.0)
	t.add_child(camera)
	camera.global_position = at
	camera.make_current()
	return camera

func _shot(t: TestRunner) -> OpeningShot:
	var shot := OpeningShot.new()
	shot.name = "OpeningShot"
	t.add_child(shot)
	return shot

func _ticks(seconds: float) -> int:
	return int(ceil(seconds * float(Engine.physics_ticks_per_second)))

func _test_the_shot_rests_then_moves_at_one_pace_and_hands_the_view_back(t: TestRunner) -> void:
	var hers := _her_camera(t, Vector2(900.0, 900.0))
	var shot := _shot(t)
	var line: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(600.0, 0.0), Vector2(600.0, 400.0)]
	var ended: Array[bool] = []
	shot.finished.connect(func() -> void: ended.append(true))
	shot.begin(hers, line)
	var view := t.get_viewport().get_camera_2d()
	t.check(view != hers and view.global_position == line[0],
			"the view is cut to the park, on a camera of its own")
	t.check(view.zoom == hers.zoom, "at her own zoom")
	t.check(shot.focus().where() == view.get_screen_center_position(),
			"the crowd's box is handed the shot's view")
	for _tick in _ticks(OpeningShot.REST_SECONDS * 0.9):
		await t.get_tree().physics_frame
	t.check(view.global_position == line[0], "it rests on the park before it moves")
	# Halfway through the way: half of the 1000 px line, 500 px along its first leg.
	for _tick in _ticks(OpeningShot.REST_SECONDS * 0.1 + OpeningShot.TRAVEL_SECONDS * 0.5):
		await t.get_tree().physics_frame
	var halfway := view.global_position
	t.check(absf(halfway.x - 500.0) < 20.0 and absf(halfway.y) < 0.01,
			"halfway through the way it is halfway along the line (%s)" % halfway)
	t.check(ended.is_empty() and shot.is_running(), "and the shot is still running")
	for _tick in _ticks(OpeningShot.TRAVEL_SECONDS * 0.5 + 0.2):
		await t.get_tree().physics_frame
	t.check(ended.size() == 1 and not shot.is_running(), "it ends once, at the line's end")
	t.check(t.get_viewport().get_camera_2d() == hers, "and her own camera has the view back")
	t.check(shot.focus().where().distance_to(line[2]) < 20.0,
			"the focus keeps where the view ended (%s)" % shot.focus().where())
	shot.free()
	hers.free()

func _press_key() -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	return key

func _test_a_press_skips_it_and_an_echo_does_not(t: TestRunner) -> void:
	var hers := _her_camera(t, Vector2(900.0, 900.0))
	var shot := _shot(t)
	var line: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(600.0, 0.0)]
	var ended: Array[bool] = []
	shot.finished.connect(func() -> void: ended.append(true))
	shot.begin(hers, line)
	var held := _press_key()
	held.echo = true
	t.get_viewport().push_input(held)
	t.check(ended.is_empty(), "a held key's echo is not a skip")
	t.get_viewport().push_input(_press_key())
	t.check(ended.size() == 1 and not shot.is_running(), "a press ends it at once")
	t.check(t.get_viewport().get_camera_2d() == hers, "and her camera has the view back")
	shot.free()
	hers.free()
