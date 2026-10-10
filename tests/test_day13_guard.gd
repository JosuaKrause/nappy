extends RefCounted
## Day 13's waiting guard follows her to the roadblock she approaches *(inbox #650 in mossy-beaver:
## "move the task's waiting guard to the roadblock the player approaches"; inbox #651 in
## lilac-marmot: "We can move the guard around offscreen as much as we want. If we need to move
## multiple times so be it")*, and never while he or where he goes is in her view.
##
## Holds, on a real city through the real day order: the guard placed with the task stands over the
## roadblock the task rides, in its band with a clear line to its body; walked up to another live
## roadblock, so the red arrow points there, he stays where he is while he is in her view, and while
## all the ground he may stand on round the roadblock she approaches is; while only its band is in
## her view he is re-placed on the ring past the band, with a clear line to it; once the band is out
## of her view he is re-placed in it, out of her reach, and each guard he was is gone; and he follows
## her again to the next one she approaches.
##
## And day 13's own roadblock is placed under the day's rules, close by *(inbox #650 in mossy-beaver:
## "let's place one properly and guide to that -- just make sure it's closeby")*: on several cities,
## reading the mark appends it to the day's plan, between the edge of the circle round her and the
## widest ring it may be offered (`ResistanceDirector.ROADBLOCK_WIDER_REACH`), wholly out of her view,
## and with it standing she can still walk home and to a calm area from where she read the mark.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const DAY := 13
## The cities day 13's own roadblock is placed on, each under the day's rules
## (`tests/probes/calm_pelican_day13_roadblock.gd` measures the share over more).
const PLACEMENT_SEEDS: Array[int] = [4242, 90210, 555, 271828]

## What the test's camera shows: a `Rect2` of world ground, or an empty one for nothing at all.
var _view := Rect2()

func run(t) -> void:
	# Each day here starts from no read mark's alley remembered (`_start_the_day()`).
	var saved_alleys := GameState.completed_resistance_alley_tiles.duplicate()
	_test_the_guard_follows_her_to_the_roadblock_she_approaches(t)
	for seed_value in PLACEMENT_SEEDS:
		_test_the_roadblock_is_placed_under_the_rules_close_by(t, seed_value)
	GameState.completed_resistance_alley_tiles.assign(saved_alleys)

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
	var director := _start_the_day(t, city, SEED)
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
	if first != null and director._rider != null:
		_check_he_guards(t, director, director._rider, player, null, "the task's own roadblock")
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

	# Everywhere he may stand round the roadblock she approaches is in her view: he stays.
	var around := other.body_position()
	var everywhere := Vector2.ONE * (ResistanceDirector.TASK_GUARD_FARTHEST + 64.0)
	_view = Rect2(around - everywhere, everywhere * 2.0)
	t.check(not _guard_in_view(where), "he stands out of that view himself")
	director._move_the_task_guard_to_her_target()
	t.check(director._task_guard == first and first.global_position == where,
			"the guard does not move while all the ground round the roadblock she approaches is in view")

	# Only its band is in her view: he goes to the ring just past it, out of her view.
	var robbery := EventCatalogue.by_id("alley_robbery")
	var band_edge := robbery.pursues_within + ContactPoint.body_reach(other)
	var band_seen := Vector2.ONE * (band_edge + 48.0)
	_view = Rect2(around - band_seen, band_seen * 2.0)
	t.check(not _guard_in_view(where), "he stands out of the band's view himself")
	director._move_the_task_guard_to_her_target()
	var ringed: EventInstance = director._task_guard
	var ring_at := ringed.global_position if ringed else Vector2.INF
	t.check(ringed != null and ringed != first and first.is_finished
			and ring_at.distance_to(around) > band_edge
			and ring_at.distance_to(around) <= ResistanceDirector.TASK_GUARD_FARTHEST
			and not _guard_in_view(ring_at) and _a_clear_line(director._map, ring_at, around),
			("while its band is in her view he goes past it, %.0fpx from its body, out of her view, " +
			"with a clear line to it") % ring_at.distance_to(around))
	t.check(ResistanceDirector._same_key(director._task_guard_over, other.get_instance_id())
			and not director._task_guard_in_band,
			"and the director knows he is over it, outside its band")

	# The band out of her view: on the arrow's next choice he is in it.
	_view = Rect2()
	director._arrow_clock = ResistanceDirector.ARROW_RETARGET_SECONDS
	director._process(0.0)
	_check_he_guards(t, director, other, player, ringed, "the roadblock she approaches")

	# And again, however often she changes target.
	var second: EventInstance = director._task_guard
	var next := _her_way_to_another_roadblock(director, player, step)
	if next != null:
		director._move_the_task_guard_to_her_target()
		_check_he_guards(t, director, next, player, second, "the next roadblock she approaches")

	_tear_down(player, director, city)
	_restore(saved_completed, saved_failed, saved_progress, saved_scars, saved_state)

## That the task's guard guards `roadblock`: in its band, with a clear line to its body, out of his
## trigger range of her, and known to the director as its guard. With `before` given, he is a new
## guard and `before` is gone.
func _check_he_guards(t, director: ResistanceDirector, roadblock: EventInstance, player: Stroller,
		before: EventInstance, what: String) -> void:
	var guard: EventInstance = director._task_guard
	if before != null:
		t.check(guard != null and guard != before and before.is_finished,
				"the guard is re-placed at %s, and the one he was is gone" % what)
	if guard == null:
		return
	var robbery := EventCatalogue.by_id("alley_robbery")
	var reach := ContactPoint.body_reach(roadblock)
	var from_body := guard.global_position.distance_to(roadblock.body_position())
	t.check(from_body >= robbery.inner_radius + reach - 0.5
			and from_body <= robbery.pursues_within + reach + 0.5,
			"at %s he stands in its band, %.0fpx from its body (%.0f-%.0fpx)"
			% [what, from_body, robbery.inner_radius + reach, robbery.pursues_within + reach])
	t.check(_a_clear_line(director._map, guard.global_position, roadblock.body_position()),
			"at %s he has a clear line to its body, so he can notice her there" % what)
	t.check(guard.global_position.distance_to(player.global_position) > robbery.pursues_within,
			"and out of his own trigger range of her (%.0fpx)"
			% guard.global_position.distance_to(player.global_position))
	t.check(ResistanceDirector._same_key(director._task_guard_over, roadblock.get_instance_id())
			and director._task_guard_in_band,
			"and the director knows which roadblock he guards")

## Whether every point of the straight line from `from` to `to`, a pixel apart, is on walkable
## ground: the line a waiting guard notices her along, asked here by sampling rather than through
## the director's own tile walk.
static func _a_clear_line(map: CityMap, from: Vector2, to: Vector2) -> bool:
	var steps := ceili(from.distance_to(to))
	for i in steps + 1:
		var point := from.lerp(to, float(i) / float(maxi(steps, 1)))
		if not map.is_walkable(map.world_to_tile(point)):
			return false
	return true

## Whether any part of a waiting robber standing at `feet` (22 by 44px above his feet, a few px to
## spare) is in the test's view.
func _guard_in_view(feet: Vector2) -> bool:
	return _view.has_area() and _view.intersects(Rect2(feet + Vector2(-14.0, -48.0),
			Vector2(28.0, 52.0)))

## **Day 13's own roadblock is placed under the day's rules, close by.** She reads the mark where it
## stands, with the 640x360 view round her answering what is on screen.
func _test_the_roadblock_is_placed_under_the_rules_close_by(t, seed_value: int) -> void:
	var saved_completed := GameState.completed_resistance_steps.duplicate()
	var saved_failed := GameState.failed_resistance_steps.duplicate()
	var saved_progress := GameState.resistance_progress
	var saved_scars := GameState.scars.duplicate()
	var saved_state := GameState.city_state
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	GameState.scars = []
	var director := _start_the_day(t, city, seed_value)
	var player := _rig_player(t, director.contact_position())
	var her := player.global_position
	_view = Rect2(her - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
	var map := city.map
	var mark := director.current_step()
	var plans_before := city.events.plans().size()
	if mark:
		director._on_contact_completed(mark.index)
	var roadblock: EventInstance = director._rider
	t.check(roadblock != null and roadblock.def.id == "roadblock",
			"seed %d: reading the mark offers a roadblock" % seed_value)
	if roadblock == null:
		_tear_down(player, director, city)
		_restore(saved_completed, saved_failed, saved_progress, saved_scars, saved_state)
		return
	var plans := city.events.plans()
	t.check(plans.size() == plans_before + 1 and plans.back().live == roadblock,
			"seed %d: it is placed the way the day places one, joining the day's plan" % seed_value)
	var away := roadblock.global_position.distance_to(her)
	var widest: float = ResistanceDirector.ROADBLOCK_WIDER_REACH.back()
	t.check(away >= ResistanceDirector.NEAR_THE_MARK - Tuning.TILE_SIZE
			and away <= widest + Tuning.TILE_SIZE,
			"seed %d: close by, %.0fpx from where she read the mark (%.0f-%.0fpx)"
			% [seed_value, away, ResistanceDirector.NEAR_THE_MARK, widest])
	var box := EventInstance.footprint_of(roadblock.def)
	t.check(not _view.intersects(Rect2(roadblock.global_position + box.position, box.size)),
			"seed %d: no part of it is in her view when it is put there" % seed_value)
	t.check(map.is_obstructed(map.world_to_tile(roadblock.body_position())),
			"seed %d: its body stands in the way of a walker" % seed_value)
	var reached := _walkable_from(map, her)
	t.check(reached.has(map.world_to_tile(map.doorstep_world_position())),
			"seed %d: with it standing she can still walk home from where she read the mark"
			% seed_value)
	var calm_reached := false
	for tile in map.calm_tiles():
		if reached.has(tile):
			calm_reached = true
			break
	t.check(calm_reached, "seed %d: and to a calm area" % seed_value)
	_tear_down(player, director, city)
	_restore(saved_completed, saved_failed, saved_progress, saved_scars, saved_state)

## Every tile she can walk to from `from` today, around every closure, sealed way and standing body.
static func _walkable_from(map: CityMap, from: Vector2) -> Dictionary:
	var start := map.world_to_tile(from)
	var reached := {start: true}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + side
			if reached.has(next) or not map.in_bounds(next) or not map.is_walkable(next) \
					or map.is_closed(next) or map.soft_sealed_tiles.has(next) \
					or map.is_obstructed(next):
				continue
			reached[next] = true
			queue.append(next)
	return reached

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

func _start_the_day(t, city: City, seed_value: int) -> ResistanceDirector:
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if step.day < DAY:
			done.append(step.index)
	GameState.completed_resistance_steps = done
	GameState.failed_resistance_steps = []
	GameState.resistance_progress = 0
	GameState.completed_resistance_alley_tiles.assign([])
	var state := CityState.new()
	GameState.city_state = state
	state.begin_day(city.map.block_plans, DAY)
	city.start_day(state, DAY, _rng(seed_value, "closures"))
	city.events.start_day(DAY, _rng(seed_value, "events"), [], city.map.doorstep_world_position())
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(city, city.map)
	director.set_sight(_in_view, _in_view)
	director.start_day(DAY, _rng(seed_value, "resistance"), 300.0)
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

func _rng(seed_value: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("day13-guard:%d:%d:%s" % [seed_value, DAY, stream])
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
