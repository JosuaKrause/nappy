extends RefCounted
## What `main` hands the worlds it builds, played through the real `main.tscn`: the crowd is handed
## the player only from when the old lookup by the `player` group would first have found her (not
## behind the title, where `Stroller.stand_aside()` has taken her out of every way the world can
## touch her), and every world's events are handed the cover of the on-screen controls (the day's
## city, the escape's city), so the joystick scheme's covered corners are out of sight in each.
##
## **Combined by composition, for this reason:** the guarantee is what `main` hands the worlds it builds
## (the crowd her, the events the controls' cover), and `main` is the composition root that does the
## handing: the crowd, the events and the screens are the real ones so that what the crowd does with
## her can be read off the crowd itself.

## **Booted and driven as a player drives it** (`tests/booted_main.gd`): the title's button pressed
## through the viewport, real frames let pass behind it, and the booted parts found in the tree. Each
## boot plays a run made fresh for it, parked in a sitting home of the test's own
## (`Boot.home_playing()`).
##
## **That the crowd has been handed her is read off what the crowd does with her.** Each of its
## ticks centres the patch of city it simulates on her (`Crowd._meet_the_player()`) when it has her,
## and leaves it where the day's start put it when it has not; a body the patch leaves behind is
## recycled into it, so every body stands within a patch's reach of wherever the patch stands. She is
## carried away from the doorstep to tell the two apart, since the patch stands on her at the
## doorstep either way.

const Boot := preload("res://tests/booted_main.gd")
const MapCache := preload("res://tests/city_map_cache.gd")
const Seat := preload("res://tests/seat.gd")
## The save every boot is handed, so nothing here reaches `user://save.json`.
const _SCRATCH_SAVE := "user://test_boot_handing_scratch.json"
## Real frames let pass behind the title, for the crowd to tick in.
const BEHIND_THE_TITLE_TICKS := 5
## How far from the doorstep she is carried: well beyond the patch the crowd simulates round her.
const CARRIED_AWAY := Vector2(600.0, 0.0)
## The run every boot here plays: the seed handed to its configuration.
const SEED := 4242

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	await _test_the_crowd_does_not_meet_her_behind_the_title(t)
	await _test_the_escapes_city_is_handed_the_controls_cover(t)

## A boot of a run made for it (`tests/seat.gd`): the seat holds the run the game plays and the node
## its sitting is parked in, and `booted` is the boot over it. Freed by `end()`.
class Played:
	var seat: Seat
	var booted: Boot.Booted

	func end() -> void:
		booted.free_all()
		seat.end()

func _boot(t: TestRunner, run_for_it: Callable, words: Array) -> Played:
	var played := Played.new()
	played.seat = Seat.new(t, run_for_it)
	played.booted = await played.seat.boot(t, _SCRATCH_SAVE, words, null, true, MapCache.source())
	return played

func _test_the_crowd_does_not_meet_her_behind_the_title(t: TestRunner) -> void:
	var played := await _boot(t, Callable(), ["--seed", str(SEED)])
	var main := played.booted.main
	var city := Boot.city(main)
	var player := Boot.player(main)
	t.check(Boot.title(main).is_open(), "the boot opens on the title")
	var doorstep: Vector2 = player.global_position
	# Behind the title she is carried off, and the crowd, if it had her, would follow her there.
	var carried := doorstep + CARRIED_AWAY
	player.global_position = carried
	await PhysicsTicks.pass_ticks(t, BEHIND_THE_TITLE_TICKS)
	t.check(_all_round(city, doorstep),
			"behind the title the crowd's patch has not followed her: its bodies all stand round the "
			+ "doorstep")
	t.check(player.global_position == carried,
			"and its ticks do not touch her")
	await Boot.press_title(t, main, "Tap")
	await PhysicsTicks.pass_ticks(t, BEHIND_THE_TITLE_TICKS)
	t.check(_all_round(city, player.global_position),
			"the day's start hands the crowd her: its patch stands on her wherever she is, its bodies "
			+ "all round her")
	played.end()

## Whether every body of the city's crowd stands within a patch's reach of `at`: the half extent a
## patch over the city's map has there (`CrowdField.half_extent()`), plus the depth of the band bodies
## enter it through, plus a tile of slack, as `tests/crowd_rig.gd` measures the patch she walks.
static func _all_round(city: City, at: Vector2) -> bool:
	var reach := CrowdField.new(city.map, at).half_extent() + CrowdAgent.ENTRY_SPREAD \
			+ Tuning.TILE_SIZE
	for agent in city.crowd.agents():
		var away := agent.global_position - at
		if maxf(absf(away.x), absf(away.y)) > reach:
			return false
	return not city.crowd.agents().is_empty()

func _test_the_escapes_city_is_handed_the_controls_cover(t: TestRunner) -> void:
	var played := await _boot(t, func(run: RunState) -> void:
				run.start_run(SEED)
				run.header.day = Tuning.RUN_LENGTH_DAYS
				run.facts.escape_section = DaySpec.Section.CITY, [])
	var main := played.booted.main
	var city := Boot.city(main)
	t.check(city != null and city.is_ancestor_of(Boot.player(main)),
			"the escape's city is built, and she stands in it")
	var controls := Boot.touch_controls(main)
	var visible: VisibleView = city.events.world.visible
	t.check(visible.controls == controls.covering,
			"and its events hold the controls' cover")
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	visible.look_through(Boot.player(main))
	var corner := visible.view.position + TouchCover.joystick().left.get_center() \
			* (visible.view.size / ScreenOrientation.DESIGN_SIZE)
	t.check(visible.joystick and not visible.sees(corner),
			"in the joystick scheme its covered corner is not in sight")
	controls.set_mode(ControlsMode.Mode.TAP)
	visible.look_through(Boot.player(main))
	t.check(not visible.joystick and visible.sees(corner),
			"and in the tap scheme it is")
	played.end()
