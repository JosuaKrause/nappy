extends RefCounted
## The baby is handed the world she stands in, and is handed it again when the world changes.
##
## **What this pins.** `Baby` answers every meter question from a `WorldContext` it holds
## (`Baby._world`): the excitement bodies at her feet, the calm ground's sleepiness gain, the
## alley trickle and the ground's decay. The escape builds the escape building first and the city
## when she walks out of the service door, with the same stroller rig (and so the same `Baby`)
## reparented between them, so a baby that found her world once, when she first entered the tree,
## would go on asking the building -- whose events are stood down and whose basement rows give no
## decay -- about a street it knows nothing of. `main` therefore calls `Baby.set_world()` at every
## place it puts her in a world.
##
## **Driven through the real `main.tscn`** (`tests/booted_main.gd`), booted on the building at the
## player's seed (4216201080, `--start-escape`), its briefs pressed through the viewport and walked
## out through the building's `exit_requested`, the way `tests/test_escape_invisible_wall.gd` does.
## Every boot plays a run of the test's own, parked in a sitting it hands the boot
## (`Boot.home_playing()`, `main.use_sitting_home()`), and freed after it (`_run_on()`).
## A data-level `Baby.new()` with no world is also checked: it answers the neutral values rather
## than failing.

const Boot := preload("res://tests/booted_main.gd")
const SEED := 4216201080
const DAY := 1
## A save of the suite's own, handed to every boot, so nothing here reaches `user://save.json`.
const _SCRATCH_SAVE := "user://test_baby_world_scratch.json"

func run(t) -> void:
	t.gives_back_observers()
	_test_a_baby_with_no_world_is_neutral(t)
	_test_a_baby_answers_for_the_world_she_is_handed(t)
	await _test_the_escape_hands_her_the_building_then_the_city(t)
	await _test_a_boot_straight_onto_the_street_hands_her_the_city(t)
	await _test_an_ordinary_boot_hands_her_the_city(t)

func _test_a_baby_with_no_world_is_neutral(t) -> void:
	var baby := Baby.new()
	t.check(baby.decay_rate() == 0.0, "a baby never placed in a world has no decay rate")
	baby.free()

func _test_a_baby_answers_for_the_world_she_is_handed(t) -> void:
	var world := WorldContext.new()
	var baby := Baby.new()
	baby.set_world(world)
	t.check(baby.world() == world, "set_world() is the world she then reads")
	baby.set_world(null)
	t.check(baby.world() == null, "and a null world is a world taken away")
	baby.free()
	world.free()

func _test_the_escape_hands_her_the_building_then_the_city(t) -> void:
	var run := _run_on(DaySpec.Section.BUILDING)
	var home := Boot.home_playing(t, run)
	var booted: Boot.Booted = await Boot.boot(t, _SCRATCH_SAVE, null,
			func(main: Node) -> void: main.use_sitting_home(home))
	var main := booted.main
	var interior := Boot.interior(main)
	t.check(interior != null, "the boot stands in the building")
	var baby := Boot.baby(main)
	t.check(baby != null and interior != null and baby.world() == interior,
			"in the building she reads the building")
	await Boot.press_continue(t, main)
	if interior:
		interior.exit_requested.emit()
	await Boot.press_continue(t, main)
	var city := Boot.city(main)
	t.check(city != null, "the service door has put her in the city")
	if city != null:
		t.check(Boot.baby(main) == baby, "and it is the same baby")
		t.check(baby.world() == city, "who now reads the city, not the building (%s)"
				% baby.world())
		await _test_a_city_event_reaches_her_meter(t, main)
		_test_the_city_ground_gains_sleepiness(t, main)
	Telemetry.end_run()
	booted.free_all()
	home.free()
	run.free()

## A fresh run on the player's seed, on `DAY`, in the escape's `section` (`DaySpec.Section.NONE`
## for an ordinary day): what a boot is handed to play.
static func _run_on(section: int) -> RunState:
	var run := RunState.new()
	run.start_run(SEED)
	run.header.day = DAY
	run.facts.escape_section = section
	return run

## Stands her on a city event that charges the ground under it, lets one physics tick pass, on which
## the baby's own frame runs her meter, and reads what the meter was fed -- the city's own answer,
## not the building's.
func _test_a_city_event_reaches_her_meter(t, main: Node2D) -> void:
	var city := Boot.city(main)
	var baby := Boot.baby(main)
	var player := Boot.player(main)
	var spot := Vector2.INF
	for instance in city.events.world.instances:
		var at: Vector2 = instance.global_position
		if instance.excitement.contribution_at(at) > 0.0 and not city.excitement_sources_at(at).is_empty():
			spot = at
			break
	t.check(spot != Vector2.INF, "the city has an event whose field can be stood in (%d live)"
			% city.events.world.instances.size())
	if spot == Vector2.INF:
		return
	player.global_position = spot
	var want: float = 0.0
	for pair in city.excitement_sources_at(spot):
		want += pair[1]
	t.check(want > 0.0, "the city charges %.2f/s at that spot" % want)
	baby.excitement = 0.0
	# What the meter was fed is written by her own tick, so a tick that did not run reads nothing.
	baby.last_incoming = 0.0
	await main.get_tree().physics_frame
	await main.get_tree().process_frame
	t.check(baby.last_incoming > 0.0,
			"and it reaches her meter (incoming %.2f/s, the city's %.2f/s)" % [baby.last_incoming, want])

## The calm ground's sleepiness gain is the city's: a park tile gains more than the building's 1.0.
func _test_the_city_ground_gains_sleepiness(t, main: Node2D) -> void:
	var city := Boot.city(main)
	var baby := Boot.baby(main)
	var found := Vector2.INF
	var map: CityMap = city.map
	for y in range(0, 200):
		for x in range(0, 200):
			var tile := Vector2i(x, y)
			if map.is_walkable(tile) and city.sleepiness_multiplier(map.tile_to_world(tile)) > 1.0:
				found = map.tile_to_world(tile)
				break
		if found != Vector2.INF:
			break
	t.check(found != Vector2.INF, "the city has calm ground to stand on")
	if found == Vector2.INF:
		return
	t.check(baby.world().sleepiness_multiplier(found) == city.sleepiness_multiplier(found)
			and baby.world().sleepiness_multiplier(found) > 1.0,
			"and she gains sleepiness on it at the city's %.2fx" % city.sleepiness_multiplier(found))

## A boot straight into the escape's city (`--start-escape city`) never builds the building.
func _test_a_boot_straight_onto_the_street_hands_her_the_city(t) -> void:
	await _boot_and_check(t, DaySpec.Section.CITY, "a boot straight onto the escape's street")

## An ordinary run's boot: the day's city, no escape.
func _test_an_ordinary_boot_hands_her_the_city(t) -> void:
	await _boot_and_check(t, DaySpec.Section.NONE, "an ordinary day's boot")

func _boot_and_check(t, section: int, what: String) -> void:
	var run := _run_on(section)
	var home := Boot.home_playing(t, run)
	var booted: Boot.Booted = await Boot.boot(t, _SCRATCH_SAVE, null,
			func(main: Node) -> void: main.use_sitting_home(home))
	var city := Boot.city(booted.main)
	var baby := Boot.baby(booted.main)
	t.check(city != null and baby != null and baby.world() == city,
			"%s hands the baby the city" % what)
	Telemetry.end_run()
	booted.free_all()
	home.free()
	run.free()
