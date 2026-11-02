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
## **Driven through the real `main.tscn`**, booted on the building at the player's seed
## (4216201080, `--start-escape`) and walked out through `exit_requested`, the way
## `tests/test_escape_invisible_wall.gd` does. A data-level `Baby.new()` with no world is also
## checked: it answers the neutral values rather than failing.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SEED := 4216201080
const DAY := 1

func run(t) -> void:
	t.gives_back_observers()
	_test_a_baby_with_no_world_is_neutral(t)
	_test_a_baby_answers_for_the_world_she_is_handed(t)
	_test_the_escape_hands_her_the_building_then_the_city(t)
	_test_a_boot_straight_onto_the_street_hands_her_the_city(t)
	_test_an_ordinary_boot_hands_her_the_city(t)

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
	var saved_section := GameState.facts.escape_section
	GameState.start_run(SEED)
	GameState.header.day = DAY
	GameState.facts.escape_section = DaySpec.Section.BUILDING
	var main: Node2D = MAIN_SCENE.instantiate()
	t.add_child(main)
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	t.check(main._interior != null, "the boot stands in the building")
	var baby: Baby = main._baby
	t.check(baby.world() == main._interior, "in the building she reads the building")
	main._on_summary_continued(main._flow.mode)
	main._interior.exit_requested.emit()
	main._on_summary_continued(main._flow.mode)
	t.check(main._city != null, "the service door has put her in the city")
	if main._city != null:
		t.check(main._baby == baby, "and it is the same baby")
		t.check(baby.world() == main._city, "who now reads the city, not the building (%s)"
				% baby.world())
		_test_a_city_event_reaches_her_meter(t, main)
		_test_the_city_ground_gains_sleepiness(t, main)
	t.get_tree().paused = false
	Telemetry.end_run()
	main.free()
	GameState.facts.escape_section = saved_section

## Stands her on a city event that charges the ground under it, steps her meter once, and reads
## what the meter was fed -- the city's own answer, not the building's.
func _test_a_city_event_reaches_her_meter(t, main: Node2D) -> void:
	var city: City = main._city
	var baby: Baby = main._baby
	var player: Stroller = main._player
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
	baby._update_excitement(0.1, spot, false)
	t.check(baby.last_incoming > 0.0,
			"and it reaches her meter (incoming %.2f/s, the city's %.2f/s)" % [baby.last_incoming, want])

## The calm ground's sleepiness gain is the city's: a park tile gains more than the building's 1.0.
func _test_the_city_ground_gains_sleepiness(t, main: Node2D) -> void:
	var city: City = main._city
	var baby: Baby = main._baby
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
	_boot_and_check(t, DaySpec.Section.CITY, "a boot straight onto the escape's street")

## An ordinary run's boot: the day's city, no escape.
func _test_an_ordinary_boot_hands_her_the_city(t) -> void:
	_boot_and_check(t, DaySpec.Section.NONE, "an ordinary day's boot")

func _boot_and_check(t, section: int, what: String) -> void:
	var saved_section := GameState.facts.escape_section
	GameState.start_run(SEED)
	GameState.header.day = DAY
	GameState.facts.escape_section = section
	var main: Node2D = MAIN_SCENE.instantiate()
	t.add_child(main)
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	t.check(main._city != null and main._baby != null and main._baby.world() == main._city,
			"%s hands the baby the city" % what)
	t.get_tree().paused = false
	Telemetry.end_run()
	main.free()
	GameState.facts.escape_section = saved_section
