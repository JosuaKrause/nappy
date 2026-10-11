extends RefCounted
## Day 8's burnt-building task stands on the building's door, and the red arrow, the contact and the
## acceptance point agree on it (teal-moose, playtest azure-koala finding 1: "burnt building task is
## not at the door of the building"). The contact stands on the door unless no ground within its
## reach can be stood on; a street held for the day (a region door's, the one round her block) is
## ground she walks on like any other and so does not count against it. The facade behind the shell,
## which stands in when the door cannot be touched, is up to five columns from the drawn door.
##
## The rig is the real day order (`CityState.begin_day()`, `City.start_day()`,
## `EventManager.start_day()`, then the director), on a seed whose fronts include ones whose door
## frontage lies on a held segment.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 1
const DAY := 8

func run(t) -> void:
	var saved_scars := GameState.scars.duplicate(true)
	var saved_state := GameState.city_state
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	var fronts := EventScheduler._open_ground_for(EventCatalogue.by_id("burning_building"),
			city.map, {})
	t.check(not fronts.is_empty(), "the city has fronts a fire can catch on")
	var held_doors := 0
	var at_the_door := 0
	var checked := 0
	var step := maxi(1, fronts.size() / 10)
	for i in range(0, fronts.size(), step):
		var shell_at := city.map.tile_to_world(fronts[i])
		GameState.scars = [{"id": "burnt_shell", "position": shell_at, "since_day": 3}]
		var director := _task_on_offer(t, city)
		var door := city.way_in_behind(shell_at)
		if door == Vector2.INF or director.current_step() == null:
			director.free()
			continue
		checked += 1
		var frontage := city.map.world_to_tile(door) + Vector2i.DOWN
		if city.map.is_held_at(frontage):
			held_doors += 1
		var touchable := false
		for across in [-1, 0, 1]:
			var tile: Vector2i = frontage + Vector2i(across, 0)
			if city.map.is_walkable(tile) and not city.map.is_closed(tile) \
					and not city.map.is_on_home_block(tile) and not city.map.is_obstructed(tile) \
					and director._reachable_from_home(tile):
				touchable = true
		var tip := director.red_arrow_target()
		if touchable:
			at_the_door += 1
			t.check(tip.is_equal_approx(door),
					"front %s: the arrow %s ends on the door %s" % [fronts[i], tip, door])
			t.check(director.contact_position().is_equal_approx(door),
					"front %s: and the contact stands on it" % fronts[i])
			t.check(is_equal_approx(director._contact.reach, ResistanceDirector.DOOR_REACH),
					"front %s: touched under the door reach" % fronts[i])
			# Standing on the frontage tile straight below the door completes it.
			t.check(director._contact.would_complete_at(door + Vector2.DOWN * Tuning.TILE_SIZE),
					"front %s: and a touch from the tile in front of the door counts" % fronts[i])
		director.free()
	t.check(checked > 0 and at_the_door > 0, "the sweep reached doors (%d of %d)" % [at_the_door, checked])
	t.check(held_doors > 0, "and some of them front a street held for the day (%d)" % held_doors)

	# A run with no recorded scar burns a front for the task, and stands on that building's door too.
	GameState.scars = []
	var director := _task_on_offer(t, city)
	t.check(director.current_step() != null, "the fallback task is on offer")
	if director.current_step() != null and director._rider != null:
		var door := city.way_in_behind(director._rider.global_position)
		t.check(door != Vector2.INF and director.red_arrow_target().is_equal_approx(door),
				"with no recorded scar the arrow %s ends on the burnt building's door %s"
				% [director.red_arrow_target(), door])
	director.free()

	GameState.scars = saved_scars
	GameState.city_state = saved_state
	city.free()

## Day 8 started through the real order and its mark read, so the task is placed.
func _task_on_offer(t, city: City) -> ResistanceDirector:
	GameState.completed_resistance_steps = []
	GameState.failed_resistance_steps = []
	GameState.resistance_progress = 0
	var state := CityState.new()
	GameState.city_state = state
	state.begin_day(city.map.block_plans, DAY)
	city.start_day(state, DAY, _rng("closures"))
	var none: Array[String] = []
	city.events.start_day(DAY, _rng("events"), none, city.map.doorstep_world_position())
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(city, city.map)
	director.start_day(DAY, _rng("resistance"), 300.0)
	director._on_contact_completed(5)
	return director

func _rng(stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [SEED, DAY, stream])
	return rng
