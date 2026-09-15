extends RefCounted
## M151, the map's top-left corner shows for a moment when a run starts — PLAYTEST-76: "when
## starting the game I can briefly see the top left of the map." The world's origin is the map's
## top-left, so any frame drawn before a camera has taken her position shows that corner.
##
## **Only a real boot of `scenes/main.tscn` reaches the frame that matters.** No hand-built rig
## gets there: the gap is between `_city.build()` and `_player` existing at all, which is inside
## `main._ready()` itself, either side of `await _warm_the_pictures()`.
##
## `t.add_child(main)` runs `_ready()` synchronously up to its first suspension — the first
## `await get_tree().process_frame` inside `_warm_the_halo_shader()` — and hands control back
## here exactly at that point, which is the state a real first frame would draw from. Resuming by
## hand with `t.get_tree().process_frame.emit()`, the same way `tests/test_pause.gd` resumes a
## coroutine waiting on the same signal, finishes the boot without a real frame ever elapsing:
## `run_tests.gd` calls every suite synchronously, so an actual `await` here would return control
## before the rest of this test ran.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func run(t) -> void:
	_test_the_city_is_hidden_until_the_camera_is_on_her(t)

## Boots for real, checks the frame the bug lives on, then lets the boot finish and checks the two
## frames PLAYTEST-76's own entry named as candidates: the first with the run started, and the
## first after the title's disc is pressed. Both already hold once the city's own visibility is
## the only thing standing between a viewer and the world's default, camera-less transform.
func _test_the_city_is_hidden_until_the_camera_is_on_her(t) -> void:
	var saved := _save_game_state()
	var main: Node2D = MAIN_SCENE.instantiate()
	t.add_child(main)

	# The suspended point. `_player` is only built after `_warm_the_pictures()` returns, so no
	# `Camera2D` exists yet — confirming this is really the gap the doc above describes, not a
	# coincidence of timing.
	t.check(main._player == null,
			"no camera exists yet at the point the first frame would be drawn from")
	t.check(main._city != null and not main._city.visible,
			"so the city stays hidden rather than drawing from the world's default transform, "
			+ "which puts its own top-left corner on screen")

	# Resume both awaits by hand. Nothing later in `_ready()` awaits anything else, so the player,
	# the day and the title all finish booting inside this same call.
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()

	t.check(main._city.visible, "and is shown again the instant she is placed on it")
	var her_position: Vector2 = main._player.global_position
	t.check(main._player.camera_screen_center().distance_to(her_position) < Tuning.TILE_SIZE,
			"on the first drawn frame with the run started, the camera is already within a tile "
			+ "of her")

	# The title's own disc: `_on_title_start()` is exactly what pressing it calls.
	main._on_title_start(ControlsMode.Mode.TAP)
	t.check(main._player.camera_screen_center().distance_to(main._player.global_position)
				< Tuning.TILE_SIZE,
			"and the same holds on the first frame after the title's disc is pressed")

	t.get_tree().paused = false
	Telemetry.end_run()
	main.free()
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
