extends RefCounted
## What `main` hands the worlds it builds, played through the real `main.tscn`: the crowd is handed
## the player only from when the old lookup by the `player` group would first have found her (not
## behind the title, where `Stroller.stand_aside()` has taken her out of every way the world can
## touch her), and every world's events are handed the cover of the on-screen controls (the day's
## city, the escape's city), so the joystick scheme's covered corners are out of sight in each.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func run(t) -> void:
	_test_the_crowd_does_not_meet_her_behind_the_title(t)
	_test_the_escapes_city_is_handed_the_controls_cover(t)

func _boot(t, args: Array) -> Node2D:
	var main: Node2D = MAIN_SCENE.instantiate()
	var words := PackedStringArray(["--no-save", "--no-telemetry"])
	words.append_array(PackedStringArray(args))
	main.configure(RunConfig.parse(words, "", true))
	t.add_child(main)
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	return main

func _test_the_crowd_does_not_meet_her_behind_the_title(t) -> void:
	GameState.start_run(4242)
	var main := _boot(t, [])
	t.check(main._title.is_open(), "the boot opens on the title")
	t.check(main._city.crowd._player == null,
			"behind the title the crowd has not been handed her")
	var before: Vector2 = main._player.global_position
	for _i in 5:
		main._city.crowd._physics_process(1.0 / 30.0)
	t.check(main._city.crowd._player == null and main._player.global_position == before,
			"and its ticks do not touch her")
	main._on_title_start(ControlsMode.Mode.TAP)
	t.check(main._city.crowd._player == main._player, "the day's start hands the crowd her")
	t.get_tree().paused = false
	main.free()

func _test_the_escapes_city_is_handed_the_controls_cover(t) -> void:
	var saved: int = GameState.facts.escape_section
	GameState.start_run(4242)
	GameState.header.day = Tuning.RUN_LENGTH_DAYS
	GameState.facts.escape_section = DaySpec.Section.CITY
	var main := _boot(t, [])
	t.check(main._city != null and main._flow.spec.section == DaySpec.Section.CITY,
			"the escape's city is built")
	var visible: VisibleView = main._city.events.world.visible
	t.check(visible.controls == main._touch_controls.covering,
			"and its events hold the controls' cover")
	main._touch_controls.set_mode(ControlsMode.Mode.JOYSTICK)
	visible.look_through(main._player)
	var corner := visible.view.position + TouchControls.covered_left().get_center() \
			* (visible.view.size / ScreenOrientation.DESIGN_SIZE)
	t.check(visible.joystick and not visible.sees(corner),
			"in the joystick scheme its covered corner is not in sight")
	main._touch_controls.set_mode(ControlsMode.Mode.TAP)
	visible.look_through(main._player)
	t.check(not visible.joystick and visible.sees(corner),
			"and in the tap scheme it is")
	t.get_tree().paused = false
	main.free()
	GameState.facts.escape_section = saved
	GameState.start_run(4242)
