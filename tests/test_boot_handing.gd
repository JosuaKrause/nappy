extends RefCounted
## What `main` hands the worlds it builds, played through the real `main.tscn`: the crowd is handed
## the player only from when the old lookup by the `player` group would first have found her (not
## behind the title, where `Stroller.stand_aside()` has taken her out of every way the world can
## touch her), and every world's events are handed the cover of the on-screen controls (the day's
## city, the escape's city), so the joystick scheme's covered corners are out of sight in each.

## **Booted and driven as a player drives it** (`tests/booted_main.gd`): the title's button pressed
## through the viewport, real frames let pass behind it, and the booted parts found in the tree.

const Boot := preload("res://tests/booted_main.gd")
## The save every boot is handed, so nothing here reaches `user://save.json`.
const _SCRATCH_SAVE := "user://test_boot_handing_scratch.json"
## Real frames let pass behind the title, for the crowd to tick in.
const BEHIND_THE_TITLE_FRAMES := 5

func run(t) -> void:
	t.gives_back_observers()
	await _test_the_crowd_does_not_meet_her_behind_the_title(t)
	await _test_the_escapes_city_is_handed_the_controls_cover(t)

func _test_the_crowd_does_not_meet_her_behind_the_title(t) -> void:
	GameState.start_run(4242)
	var booted: Boot.Booted = await Boot.boot(t, _SCRATCH_SAVE, Boot.config([]))
	var main := booted.main
	var city := Boot.city(main)
	var player := Boot.player(main)
	t.check(Boot.title(main).is_open(), "the boot opens on the title")
	t.check(city.crowd._player == null,
			"behind the title the crowd has not been handed her")
	var before: Vector2 = player.global_position
	for _i in BEHIND_THE_TITLE_FRAMES:
		await t.get_tree().physics_frame
	t.check(city.crowd._player == null and player.global_position == before,
			"and its ticks do not touch her")
	await Boot.press_title(t, main, "Tap")
	t.check(city.crowd._player == player, "the day's start hands the crowd her")
	booted.free_all()

func _test_the_escapes_city_is_handed_the_controls_cover(t) -> void:
	var saved: int = GameState.facts.escape_section
	GameState.start_run(4242)
	GameState.header.day = Tuning.RUN_LENGTH_DAYS
	GameState.facts.escape_section = DaySpec.Section.CITY
	var booted: Boot.Booted = await Boot.boot(t, _SCRATCH_SAVE, Boot.config([]))
	var main := booted.main
	var city := Boot.city(main)
	t.check(city != null and Boot.interior(main) == null,
			"the escape's city is built")
	var controls := Boot.touch_controls(main)
	var visible: VisibleView = city.events.world.visible
	t.check(visible.controls == controls.covering,
			"and its events hold the controls' cover")
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	visible.look_through(Boot.player(main))
	var corner := visible.view.position + TouchControls.covered_left().get_center() \
			* (visible.view.size / ScreenOrientation.DESIGN_SIZE)
	t.check(visible.joystick and not visible.sees(corner),
			"in the joystick scheme its covered corner is not in sight")
	controls.set_mode(ControlsMode.Mode.TAP)
	visible.look_through(Boot.player(main))
	t.check(not visible.joystick and visible.sees(corner),
			"and in the tap scheme it is")
	booted.free_all()
	GameState.facts.escape_section = saved
	GameState.start_run(4242)
