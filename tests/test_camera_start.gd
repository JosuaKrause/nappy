extends RefCounted
## The map's top-left corner must never show for a moment when a run starts — PLAYTEST-76: "when
## starting the game I can briefly see the top left of the map." The world's origin is the map's
## top-left, so any frame drawn before a camera has taken her position would show that corner
## unless something else is already current and looking at the doorstep by then.
##
## **Only a real boot of `scenes/main.tscn` reaches the frame that matters.** No hand-built rig
## gets there: the gap is between `_city.build()` and `_player` existing at all, which is inside
## `main._ready()` itself, either side of `await _warm_the_pictures()`.
##
## `t.add_child(main)` runs `_ready()` synchronously up to its first suspension — the first
## `await get_tree().process_frame` inside `_warm_the_canvas_shaders()` — and hands control back
## here exactly at that point, which is the state a real first frame would draw from. Resuming by
## hand with `t.get_tree().process_frame.emit()`, the same way `tests/test_pause.gd` resumes a
## coroutine waiting on the same signal, finishes the boot without a real frame ever elapsing:
## `run_tests.gd` calls every suite synchronously, so an actual `await` here would return control
## before the rest of this test ran.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func run(t) -> void:
	_test_a_boot_camera_stands_on_the_doorstep_before_she_exists(t)
	_test_a_boot_camera_is_turned_for_a_portrait_phone_before_the_first_frame(t)

## Boots for real, checks the frame the bug lived on, then lets the boot finish and checks the two
## frames PLAYTEST-76's own entry named as candidates: the first with the run started, and the
## first after the title's disc is pressed.
func _test_a_boot_camera_stands_on_the_doorstep_before_she_exists(t) -> void:
	var saved := _save_game_state()
	var main: Node2D = MAIN_SCENE.instantiate()
	t.add_child(main)

	# The suspended point. `_player` is only built after `_warm_the_pictures()` returns, so no
	# camera of *hers* exists yet — confirming this is really the gap the doc above describes, not
	# a coincidence of timing. `_new_boot_camera()` stands in for her: the viewport's own current
	# camera should already be on the doorstep, the same ground the title screen will show.
	t.check(main._player == null,
			"no player camera exists yet at the point the first frame would be drawn from")
	var boot_camera := main.get_viewport().get_camera_2d()
	t.check(boot_camera != null, "a camera is already current before she exists")
	t.check(boot_camera.get_screen_center_position().distance_to(
				main._city.map.doorstep_world_position()) < Tuning.TILE_SIZE,
			"and it is already looking at the doorstep rather than the world's default transform, "
			+ "which puts its own top-left corner on screen")

	# Resume both awaits by hand. Nothing later in `_ready()` awaits anything else, so the player,
	# the day and the title all finish booting inside this same call.
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()

	var her_position: Vector2 = main._player.global_position
	t.check(main._player.camera_screen_center().distance_to(her_position) < Tuning.TILE_SIZE,
			"on the first drawn frame with the run started, the camera is already within a tile "
			+ "of her")

	# The title's own disc: `_on_title_start()` is exactly what pressing it calls.
	main._on_title_start(ControlsMode.Mode.TAP)
	t.check(main._player.camera_screen_center().distance_to(main._player.global_position)
				< Tuning.TILE_SIZE,
			"and the same holds on the first frame after the title's disc is pressed")
	# A dawn after finishing far away must prepare home before the next process callback.
	var city: City = main._city
	var far := Rect2(Vector2(64, 64), Tuning.VIEW_HALF_EXTENT * 2)
	city.scenery.update(far, true)
	main._player.reset_at(far.get_center())
	main._first_day = false
	main._start_day()
	var home_view := city._home_scenery_view()
	for key in city._ground.keys_in(home_view):
		t.check(city._ground.chunks.has(key),
				"real day reset prepares the home viewport before its first frame")

	t.get_tree().paused = false
	Telemetry.end_run()
	main.free()
	_restore_game_state(saved)

## PLAYTEST-140, statement 5: "when you lose with game over the title screen is sideways", and
## PLAYTEST-144's still after a held restart, "This is the screen when resetting" — both on a
## portrait phone, both right after a scene reload. The frames `_warm_the_canvas_shaders()` draws
## before she exists are the boot camera's, and they stay on screen through the rest of `_ready()`
## until the title is drawn, so the boot camera and the window's box have to be turned for the
## phone before the first of them, not only once she and the HUD exist.
##
## The window is made portrait and the boot told it is on a touch screen, which is the one shape
## that wants rotation; the box is left at the unrotated 1280x720 a first boot starts in, so both
## halves — the box and the camera — have something to correct. After a reload the box would
## already be the rotated one, which leaves only the camera wrong; the camera's assertion is that
## case.
func _test_a_boot_camera_is_turned_for_a_portrait_phone_before_the_first_frame(t) -> void:
	var saved := _save_game_state()
	var window: Window = t.get_tree().root
	var saved_size := window.size
	var saved_box := window.content_scale_size
	window.size = Vector2i(ScreenOrientation.ROTATED_SIZE)
	window.content_scale_size = Vector2i(ScreenOrientation.DESIGN_SIZE)
	t.check(ScreenOrientation.wants_rotation(window.size, true),
			"the window this test boots into is one that wants rotation on a touch screen")

	var main: Node2D = MAIN_SCENE.instantiate()
	main._touch_available = true
	t.add_child(main)

	# The suspended point, before her camera exists: the frame the boot camera draws.
	t.check(main._player == null, "suspended before she exists, where the boot camera draws")
	t.check(window.content_scale_size == ScreenOrientation.content_scale_size(true),
			"the window already presents in the rotated box before the first frame")
	var boot_camera := main.get_viewport().get_camera_2d()
	t.check(boot_camera != null and not boot_camera.ignore_rotation
				and is_equal_approx(boot_camera.rotation, -deg_to_rad(90.0)),
			"and the boot camera is turned with it, so the city it shows is not drawn upright")

	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	t.check(main._rotated, "the finished boot has turned the whole presentation")
	t.check(main._title.transform == ScreenOrientation.rotation_transform(),
			"including the title it opens on")

	t.get_tree().paused = false
	Telemetry.end_run()
	main.free()
	window.size = saved_size
	window.content_scale_size = saved_box
	_restore_game_state(saved)

## Mirrors `tests/test_full_run.gd`'s own save/restore: a real boot calls `GameState.start_run()`,
## which every other suite is entitled to assume left the state it found, not this one's seed and
## day.
func _save_game_state() -> Dictionary:
	return {
		"seed": GameState.run_seed, "day": GameState.day, "nerves": GameState.nerves,
		"progress": GameState.resistance_progress, "ending": GameState.ending,
		"one_shots": GameState.consumed_one_shots.duplicate(),
		"completed": GameState.completed_resistance_steps.duplicate(),
		"failed": GameState.failed_resistance_steps.duplicate(),
		"scars": GameState.scars.duplicate(true), "sabotage": GameState.sabotage_done,
	}

func _restore_game_state(saved: Dictionary) -> void:
	GameState.run_seed = saved["seed"]
	GameState.day = saved["day"]
	GameState.nerves = saved["nerves"]
	GameState.resistance_progress = saved["progress"]
	GameState.ending = saved["ending"]
	GameState.consumed_one_shots.assign(saved["one_shots"])
	GameState.completed_resistance_steps.assign(saved["completed"])
	GameState.failed_resistance_steps.assign(saved["failed"])
	GameState.scars.assign(saved["scars"])
	GameState.sabotage_done = saved["sabotage"]
