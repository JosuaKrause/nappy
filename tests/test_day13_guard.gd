extends RefCounted
## Day 13's waiting guard follows her to the roadblock she approaches *(inbox #650 in mossy-beaver:
## "move the task's waiting guard to the roadblock the player approaches"; inbox #651 in
## lilac-marmot: "We can move the guard around offscreen as much as we want. If we need to move
## multiple times so be it")*, and never while he or where he goes is in her view.
##
## Holds, on a real city through the real day order: the guard placed with the task stands over the
## roadblock the task rides; walked up to another live roadblock, so the red arrow points there, he
## stays where he is while he is in her view, and while the ground round the roadblock she approaches
## is; once both are out of it he is re-placed in that roadblock's band, out of her reach, and the
## guard he was is gone; and he follows her again to the next one she approaches.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const DAY := 13

## What the test's camera shows: a `Rect2` of world ground, or an empty one for nothing at all.
var _view := Rect2()

func run(t) -> void:
	_test_the_guard_follows_her_to_the_roadblock_she_approaches(t)

func _in_view(at: Vector2) -> bool:
	return _view.has_area() and _view.has_point(at)

func _test_the_guard_follows_her_to_the_roadblock_she_approaches(t) -> void:
	var saved_completed := GameState.completed_resistance_steps.duplicate()
	var saved_failed := GameState.failed_resistance_steps.duplicate()
	var saved_progress := GameState.resistance_progress
	var saved_scars := GameState.scars.duplicate()
	var saved_state := GameState.city_state
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	GameState.scars = []
	var director := _start_the_day(t, city)
	var player := _rig_player(t, director.contact_position())
	_view = Rect2(player.global_position - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
	var mark := director.current_step()
	t.check(mark != null and mark.is_pickup and mark.day == DAY, "day %d opens on its mark" % DAY)
	if mark:
		director._on_contact_completed(mark.index)
	var step := director.current_step()
	t.check(step != null and step.task_event_id == "roadblock", "reading it offers the roadblock")
	var first: EventInstance = director._task_guard
	t.check(first != null and director._rider != null
			and ResistanceDirector._same_key(director._task_guard_over,
					director._rider.get_instance_id()),
			"the task's guard stands over the roadblock the task rides")
	if step == null or first == null:
		_tear_down(player, director, city)
		_restore(saved_completed, saved_failed, saved_progress, saved_scars, saved_state)
		return
	director._settle_the_arrow()

	var other := _her_way_to_another_roadblock(director, player, step)
	t.check(other != null, "there is another live roadblock she can walk up to (%d live)"
			% director._arrow_candidates(step).size())
	if other == null:
		_tear_down(player, director, city)
		_restore(saved_completed, saved_failed, saved_progress, saved_scars, saved_state)
		return
	var where := first.global_position

	# He is in her view: he stays.
	_view = Rect2(where - Vector2(64.0, 64.0), Vector2(128.0, 128.0))
	director._move_the_task_guard_to_her_target()
	t.check(director._task_guard == first and first.global_position == where
			and not first.is_finished,
			"the guard does not move while he is in her view")

	# Where he would go is in her view: he stays.
	var around := other.body_position()
	_view = Rect2(around - Vector2(420.0, 420.0), Vector2(840.0, 840.0))
	t.check(not _view.has_point(where), "he stands out of that view himself")
	director._move_the_task_guard_to_her_target()
	t.check(director._task_guard == first and first.global_position == where,
			"the guard does not move while the ground round the roadblock she approaches is in view")

	# Both out of her view: on the arrow's next choice he is at the roadblock she approaches.
	_view = Rect2()
	director._arrow_clock = ResistanceDirector.ARROW_RETARGET_SECONDS
	director._process(0.0)
	_check_he_guards(t, director, other, player, first, "the roadblock she approaches")

	# And again, however often she changes target.
	var second: EventInstance = director._task_guard
	var next := _her_way_to_another_roadblock(director, player, step)
	if next != null:
		director._move_the_task_guard_to_her_target()
		_check_he_guards(t, director, next, player, second, "the next roadblock she approaches")

	_tear_down(player, director, city)
	_restore(saved_completed, saved_failed, saved_progress, saved_scars, saved_state)

func _check_he_guards(t, director: ResistanceDirector, roadblock: EventInstance, player: Stroller,
		before: EventInstance, what: String) -> void:
	var guard: EventInstance = director._task_guard
	t.check(guard != null and guard != before and before.is_finished,
			"the guard is re-placed at %s, and the one he was is gone" % what)
	if guard == null:
		return
	var robbery := EventCatalogue.by_id("alley_robbery")
	var reach := ContactPoint.body_reach(roadblock)
	var from_body := guard.global_position.distance_to(roadblock.body_position())
	t.check(from_body >= robbery.inner_radius + reach - 0.5
			and from_body <= robbery.pursues_within + reach + 0.5,
			"he stands in its band, %.0fpx from its body (%.0f-%.0fpx)"
			% [from_body, robbery.inner_radius + reach, robbery.pursues_within + reach])
	t.check(guard.global_position.distance_to(player.global_position) > robbery.pursues_within,
			"and out of his own trigger range of her (%.0fpx)"
			% guard.global_position.distance_to(player.global_position))
	t.check(ResistanceDirector._same_key(director._task_guard_over, roadblock.get_instance_id()),
			"and the director knows which roadblock he guards")

## Stands her beside a live roadblock other than the one the guard stands over, where the red arrow
## points at it, and answers it; null when no live roadblock has such a spot.
func _her_way_to_another_roadblock(director: ResistanceDirector, player: Stroller,
		step: ResistanceSteps.Step) -> EventInstance:
	var map := director._map
	for target: Dictionary in director._arrow_candidates(step):
		if ResistanceDirector._same_key(target["key"], director._task_guard_over):
			continue
		var roadblock := ResistanceDirector._live_instance(target["key"])
		if roadblock == null:
			continue
		var centre := map.world_to_tile(roadblock.body_position())
		# Far enough out that the band round it is mostly out of his trigger range of her, so a spot
		# for him is found at once when nothing is in view.
		for radius in [12, 10, 14, 8, 16, 6]:
			for offset: Vector2i in [Vector2i(radius, 0), Vector2i(-radius, 0), Vector2i(0, radius),
					Vector2i(0, -radius)]:
				var tile := centre + offset
				if not map.is_walkable(tile) or map.is_obstructed(tile) or map.is_closed(tile):
					continue
				player.global_position = map.tile_to_world(tile)
				director._settle_the_arrow()
				if ResistanceDirector._same_key(director._arrow_key, target["key"]):
					return roadblock
	return null

func _start_the_day(t, city: City) -> ResistanceDirector:
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if step.day < DAY:
			done.append(step.index)
	GameState.completed_resistance_steps = done
	GameState.failed_resistance_steps = []
	GameState.resistance_progress = 0
	var state := CityState.new()
	GameState.city_state = state
	state.begin_day(city.map.block_plans, DAY)
	city.start_day(state, DAY, _rng("closures"))
	city.events.start_day(DAY, _rng("events"), [], city.map.doorstep_world_position())
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(city, city.map)
	director.set_sight(_in_view, _in_view)
	director.start_day(DAY, _rng("resistance"), 300.0)
	return director

func _rig_player(t, at: Vector2) -> Stroller:
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	player.global_position = at
	return player

func _rng(stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("day13-guard:%d:%d:%s" % [SEED, DAY, stream])
	return rng

func _tear_down(player: Stroller, director: ResistanceDirector, city: City) -> void:
	player.free()
	director.free()
	city.free()

func _restore(completed: Array, failed: Array, progress: int, scars: Array,
		state: CityState) -> void:
	GameState.completed_resistance_steps.assign(completed)
	GameState.failed_resistance_steps.assign(failed)
	GameState.resistance_progress = progress
	GameState.scars.assign(scars)
	GameState.city_state = state
