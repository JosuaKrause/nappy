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
## Whichever roadblock she touches, the guard comes after her the moment she has done it *(the
## player: "as long as he starts pursuing when you hit the task it's fine")*: parked at another
## roadblock, kept there by her view, he is chasing her the moment she touches the one she
## approached, and, with her standing there, comes all the way to her, walking round the buildings
## between them; set on her with a building across his straight line, where a chase straight at her
## stalls, he walks round it to her while she stands; and a guard who already noticed her is left on her exactly as he was.
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
## What each day's streams are named after: this suite's own, or, empty, the day-13 probes' own
## (`tests/probes/calm_pelican_day13_guard_walk.gd`), so a day the probes measured is built again.
var _streams := "day13-guard:"

func run(t) -> void:
	# Each day here starts from no read mark's alley remembered (`_start_the_day()`).
	var saved_alleys := GameState.completed_resistance_alley_tiles.duplicate()
	_test_the_guard_follows_her_to_the_roadblock_she_approaches(t)
	_test_set_on_her_inside_his_stand_off_he_holds(t)
	_test_her_side_reads_the_soft_seals_and_bodies_the_fill_does(t)
	# The probes' days on which a guard drawn with no way asked stood on her only way.
	_streams = ""
	for seed_value in [1234567, 314159]:
		_test_the_guard_never_stands_on_her_only_way(t, seed_value)
	_streams = "day13-guard:"
	_test_the_done_task_sets_the_guard_on_her_wherever_he_stands(t, true)
	_test_the_done_task_sets_the_guard_on_her_wherever_he_stands(t, false)
	_test_the_guard_walks_round_a_building_to_her(t)
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

	# Only its band is in her view: he goes to the ring just past it, out of her view. The view
	# changes here with her neither moving nor turning, as the camera does easing on after she stops
	# or the joystick scheme's corners switching, so the search the step before found nothing for
	# stands until `TASK_GUARD_RETRY_SECONDS` have passed, and is then made again.
	t.check(director._task_guard_found_nothing_for.size() > 0,
			"the search that found him nowhere better is remembered")
	var cached_at := first.global_position
	_view = Rect2(around - Vector2.ONE * (robbery_edge_of(other) + 48.0),
			Vector2.ONE * (robbery_edge_of(other) + 48.0) * 2.0)
	director._move_the_task_guard_to_her_target()
	t.check(director._task_guard == first and first.global_position == cached_at,
			"a remembered failure is not searched again at once")
	director._task_guard_found_nothing_age = ResistanceDirector.TASK_GUARD_RETRY_SECONDS
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
	t.check(_a_way_past(director._map, guard.global_position, roadblock.body_position(),
			ContactPoint.body_reach(roadblock), player.global_position),
			"at %s she can still walk to it without coming within his notice" % what)

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

## Whether some walk from `from` reaches ground within `reach` of `body` without her centre coming
## within a guard at `guard`'s `pursues_within` along a clear line: a flood fill of the test's own over
## open, unobstructed walkable tiles, tile centres, never onto a tile his notice reaches.
static func _a_way_past(map: CityMap, guard: Vector2, body: Vector2, reach: float,
		from: Vector2) -> bool:
	var notice := EventCatalogue.by_id("alley_robbery").pursues_within
	var start := map.world_to_tile(from)
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		if map.tile_to_world(tile).distance_to(body) <= reach:
			return true
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + side
			if seen.has(next):
				continue
			seen[next] = true
			if not map.in_bounds(next) or not map.is_walkable(next) or map.is_closed(next) \
					or map.is_obstructed(next):
				continue
			var at := map.tile_to_world(next)
			if at.distance_to(guard) <= notice and _a_clear_line(map, guard, at):
				continue
			queue.append(next)
	return false

func robbery_edge_of(roadblock: EventInstance) -> float:
	return EventCatalogue.by_id("alley_robbery").pursues_within + ContactPoint.body_reach(roadblock)

## Whether any part of a waiting robber standing at `feet` (22 by 44px above his feet, a few px to
## spare) is in the test's view.
func _guard_in_view(feet: Vector2) -> bool:
	return _view.has_area() and _view.intersects(Rect2(feet + Vector2(-14.0, -48.0),
			Vector2(28.0, 52.0)))

## **The guard is never put on her only way to the roadblock** (`_roadblock_guard_spot()`): from
## her where she read the mark, and at open ground 8 to 14 tiles out in each of four directions,
## round every live roadblock of the day, wherever a move would put him, she can still walk to touch
## range without coming within his notice — asked by the test's own flood fill — and he stands on
## the far side of the roadblock from her far more often than on hers.
func _test_the_guard_never_stands_on_her_only_way(t, seed_value: int) -> void:
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
	_view = Rect2()
	var mark := director.current_step()
	if mark:
		director._on_contact_completed(mark.index)
	var map := city.map
	var rng := _rng(seed_value, "ways")
	var read_at := player.global_position
	var asked := 0
	var blocked: Array[String] = []
	var near_side := 0
	for target: Dictionary in director._arrow_candidates(director.current_step()):
		var roadblock := ResistanceDirector._live_instance(target["key"])
		if roadblock == null:
			continue
		var body := roadblock.body_position()
		var reach := ContactPoint.body_reach(roadblock)
		var places: Array[Vector2] = [read_at]
		for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			for out: int in [8, 11, 14]:
				var tile: Vector2i = map.world_to_tile(body) + direction * out
				if map.in_bounds(tile) and map.is_walkable(tile) and not map.is_obstructed(tile) \
						and not map.is_closed(tile):
					places.append(map.tile_to_world(tile))
		for her in places:
			var tile := map.world_to_tile(her)
			var spot := director._roadblock_guard_spot(rng, body, reach, her, false, false)
			if spot == Vector2.INF:
				continue
			asked += 1
			if not _a_way_past(map, spot, body, reach, her):
				blocked.append("%s from %s" % [map.world_to_tile(body), tile])
			if (spot - body).dot(her - body) > 0.0:
				near_side += 1
	t.check(asked > 20 and blocked.is_empty(),
			"seed %d: wherever he is put, she keeps a way to the roadblock past his notice (%d asked, blocked %s)"
			% [seed_value, asked, blocked.slice(0, 4)])
	t.check(near_side * 3 < asked,
			"seed %d: and he stands on the far side of it from her far more often than on hers (%d of %d on her side)"
			% [seed_value, near_side, asked])
	_tear_down(player, director, city)
	_restore(saved_completed, saved_failed, saved_progress, saved_scars, saved_state)

## **Set on her already inside his stand-off, he holds it** (`EventInstance.notice_her_at()`; the
## events skill: "the chase starts at the stand-off however she came"). A waiting robber with her
## 60px off along a clear line — inside his stand-off, outside his catch — is set on her: while she
## stands there he neither lunges nor can end her day, however long; when she walks away he lunges
## only once she is back at the full stand-off. Without the hold he would lunge from 60px on his
## first tick.
func _test_set_on_her_inside_his_stand_off_he_holds(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var guard := EventInstance.new()
	guard.setup(robbery, Vector2.ZERO, PackedVector2Array())
	t.add_child(guard)
	guard.set_process(false)
	var standoff := Tuning.pursuit_standoff(robbery.pursue_speed, robbery.standoff_reach())
	var her := Vector2(60.0, 0.0)
	t.check(her.length() < standoff and her.length() > robbery.lethal_reach(),
			"she stands inside his %.0fpx stand-off and outside his catch" % standoff)
	guard.notice_her_at(her)
	t.check(not guard.is_waiting(), "set on her, he has noticed her")
	var lunged_standing := false
	var lethal_standing := false
	for i in 60:
		guard.player_at = her
		guard._process(0.1)
		lunged_standing = lunged_standing or guard._lunged
		lethal_standing = lethal_standing or guard.is_lethal_at(her)
	t.check(not lunged_standing and not lethal_standing,
			"while she stands 60px off for 6s he holds: no lunge, and he cannot end her day")
	var lunged_at := -1.0
	for i in 60:
		her += Vector2(Tuning.WALK_SPEED * 0.1, 0.0)
		guard.player_at = her
		guard._process(0.1)
		if guard._lunged:
			lunged_at = guard.global_position.distance_to(her)
			break
	t.check(lunged_at >= standoff - Tuning.WALK_SPEED * 0.1,
			"walking away, he lunges only once she is back at his stand-off (%.0fpx, stand-off %.0fpx)"
			% [lunged_at, standoff])
	guard.free()

## **`_on_her_side()` shuts what `_open_to_her()` shuts**: a soft-sealed tile or a tile with a body
## on it, added after the director's reachability first ran, is not her side, as it is not open to
## the fill.
func _test_her_side_reads_the_soft_seals_and_bodies_the_fill_does(t) -> void:
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
	var map := director._map
	var body := director.contact_position()
	var reach := ResistanceDirector._guard_notice_reach()
	director._ensure_reachability()
	var tile := Vector2i(-1, -1)
	var her := Vector2.INF
	var centre := map.world_to_tile(body)
	var span := ceili((reach + 3.0 * Tuning.TILE_SIZE) / Tuning.TILE_SIZE)
	for radius in range(span, span + 12):
		for dx in range(-radius, radius + 1):
			var cand := centre + Vector2i(dx, radius)
			var at := map.tile_to_world(cand)
			if not director._open_to_her(cand) or not director._open_to_her(cand + Vector2i.RIGHT) \
					or at.distance_to(body) < reach + 2.0 * Tuning.TILE_SIZE:
				continue
			var side := ResistanceDirector.HerSide.new(body, at)
			if director._on_her_side(side, cand + Vector2i.RIGHT):
				tile = cand + Vector2i.RIGHT
				her = at
				break
		if her != Vector2.INF:
			break
	t.check(her != Vector2.INF, "there is open ground on her side of a roadblock to test with")
	if her != Vector2.INF:
		map.seal_soft_tile(tile)
		t.check(not director._open_to_her(tile)
				and not director._on_her_side(ResistanceDirector.HerSide.new(body, her), tile),
				"a tile soft-sealed after the reachability was built is not her side")
		map.soft_sealed_tiles.erase(tile)
		var other := tile + Vector2i.RIGHT
		if director._on_her_side(ResistanceDirector.HerSide.new(body, her), other):
			map.obstructed_tiles[other] = 1
			t.check(not director._open_to_her(other)
					and not director._on_her_side(ResistanceDirector.HerSide.new(body, her), other),
					"a tile with a body on it is not her side")
			map.obstructed_tiles.erase(other)
	_tear_down(player, director, city)
	_restore(saved_completed, saved_failed, saved_progress, saved_scars, saved_state)

## **The done task sets the guard on her, wherever he stands.** With `parked`, she touches another
## live roadblock while the guard is held at the task's own by her view on him; without, he has
## already noticed her at the task's own before she touches it.
func _test_the_done_task_sets_the_guard_on_her_wherever_he_stands(t, parked: bool) -> void:
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
	_view = Rect2()
	var mark := director.current_step()
	if mark:
		director._on_contact_completed(mark.index)
	var step := director.current_step()
	var guard: EventInstance = director._task_guard
	var what := "parked at another roadblock" if parked else "already after her"
	t.check(step != null and guard != null and guard.is_waiting(),
			"(%s) the task offers a roadblock, guarded by a waiting guard" % what)
	if step == null or guard == null:
		_tear_down(player, director, city)
		_restore(saved_completed, saved_failed, saved_progress, saved_scars, saved_state)
		return
	var map := city.map
	var touched: EventInstance = director._rider
	if parked:
		director._settle_the_arrow()
		# Her view on him from here on, so he cannot be moved to the one she approaches.
		var held := guard.global_position
		_view = Rect2(held - Vector2(64.0, 64.0), Vector2(128.0, 128.0))
		touched = _her_way_to_another_roadblock(director, player, step)
		t.check(touched != null, "(%s) there is another live roadblock to touch" % what)
		if touched == null:
			_tear_down(player, director, city)
			_restore(saved_completed, saved_failed, saved_progress, saved_scars, saved_state)
			return
		director._move_the_task_guard_to_her_target()
		t.check(director._task_guard == guard and guard.global_position == held
				and guard.is_waiting()
				and guard.global_position.distance_to(touched.body_position())
				> EventCatalogue.by_id("alley_robbery").pursues_within
				+ ContactPoint.body_reach(touched),
				"(%s) the guard is still at the task's own roadblock, out of the band of the one she touches (%.0fpx from it)"
				% [what, guard.global_position.distance_to(touched.body_position())])
	var at := _beside(map, touched.body_position(), ContactPoint.body_reach(touched))
	t.check(at != Vector2.INF, "(%s) there is ground to touch the roadblock from" % what)
	player.global_position = at
	var noticed_before := INF
	if not parked:
		# He notices her the ordinary way: she comes within his reach along a clear line, here a
		# step from him on his own tile.
		guard.player_at = guard.global_position + Vector2(4.0, 0.0)
		guard._process(0.1)
		noticed_before = guard.noticed_at()
		t.check(not guard.is_waiting(), "(%s) he noticed her the ordinary way" % what)
	director._on_contact_completed(step.index)
	t.check(not guard.is_finished and not guard.is_waiting(),
			"(%s) the moment she has done the task, he is after her" % what)
	if not parked:
		t.check(guard.noticed_at() == noticed_before,
				"(%s) a guard already after her is left as he was" % what)
		_tear_down(player, director, city)
		_restore(saved_completed, saved_failed, saved_progress, saved_scars, saved_state)
		return
	var start := guard.global_position.distance_to(at)
	var standoff := Tuning.pursuit_standoff(guard.def.pursue_speed, guard.def.standoff_reach())
	var nearest := start
	var walked := 0.0
	var lethal := false
	while walked < 30.0 and not lethal and not guard.is_finished:
		guard.player_at = at
		guard._process(0.1)
		walked += 0.1
		nearest = minf(nearest, guard.global_position.distance_to(at))
		lethal = guard.is_lethal_at(at)
	# He walks round the buildings between them (`EventInstance._paths_to_her`), so he comes all
	# the way to her stand-off however many blocks stood between them.
	t.check(lethal or nearest <= standoff + 1.0,
			"(%s) he comes from %.0fpx away to her (nearest %.0fpx, stand-off %.0fpx, caught %s, %.1fs)"
			% [what, start, nearest, standoff, lethal, walked])
	_tear_down(player, director, city)
	_restore(saved_completed, saved_failed, saved_progress, saved_scars, saved_state)

## **With a building between them, he walks round it to her.** On seed 4242's day 13, the task's
## own guard is set on her where she stands a few blocks off with a building across his straight
## line — a spot from which a chase straight at her, sliding along walls
## (`EventInstance.walkable_step_on()`), never comes within his stand-off of her, and which she
## could walk to from him — and he reaches her stand-off within the time his walk to her takes
## at his speed, his notice and a margin on top.
func _test_the_guard_walks_round_a_building_to_her(t) -> void:
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
	_view = Rect2()
	var mark := director.current_step()
	if mark:
		director._on_contact_completed(mark.index)
	var guard: EventInstance = director._task_guard
	t.check(guard != null and guard.is_waiting(), "(round a building) the task's guard is waiting")
	if guard == null:
		_tear_down(player, director, city)
		_restore(saved_completed, saved_failed, saved_progress, saved_scars, saved_state)
		return
	var map := city.map
	# The red arrow shares `ArrowField.ground_for()` with the guard's walk; what is left to guard is
	# the director's cache of it, which must equal a fresh layout of what blocks her now.
	t.check(director._ground_for_the_arrow() == ArrowField.ground_for(map),
			"(round a building) the red arrow's cached ground is the guard's walk's ground")
	var standoff := Tuning.pursuit_standoff(guard.def.pursue_speed, guard.def.standoff_reach())
	var from := guard.global_position
	var walk := map.walk_field(map.world_to_tile(from))
	var at := Vector2.INF
	var tiles_to_her := -1
	for radius in range(5, 16):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if at != Vector2.INF or maxi(absi(dx), absi(dy)) != radius:
					continue
				var tile := map.world_to_tile(from) + Vector2i(dx, dy)
				if not map.is_walkable(tile) or map.is_closed(tile) or map.is_obstructed(tile) \
						or map.soft_sealed_tiles.has(tile) or not map.reaches(walk, tile):
					continue
				var spot := map.tile_to_world(tile)
				if map.clear_line(from, spot) \
						or _a_straight_chase_reaches(map, from, spot, standoff,
								guard.def.pursue_speed):
					continue
				at = spot
				tiles_to_her = map.distance_at(walk, tile)
	t.check(at != Vector2.INF,
			"(round a building) there is a spot she can walk to with a building across his straight line, where a straight chase stalls")
	if at == Vector2.INF:
		_tear_down(player, director, city)
		_restore(saved_completed, saved_failed, saved_progress, saved_scars, saved_state)
		return
	player.global_position = at
	guard.notice_her_at(at)
	var allowed := guard.def.telegraph_time + tiles_to_her * Tuning.TILE_SIZE \
			/ guard.def.pursue_speed * 1.5 + 2.0
	var start := from.distance_to(at)
	var nearest := start
	var walked := 0.0
	var lethal := false
	while walked < allowed and not lethal and not guard.is_finished:
		guard.player_at = at
		guard._process(0.1)
		walked += 0.1
		nearest = minf(nearest, guard.global_position.distance_to(at))
		lethal = guard.is_lethal_at(at)
	t.check(lethal or nearest <= standoff + 1.0,
			("(round a building) he walks round it from %.0fpx away to her stand-off within %.1fs " +
			"(a walk of %d tiles; nearest %.0fpx, stand-off %.0fpx, caught %s, %.1fs)")
			% [start, allowed, tiles_to_her, nearest, standoff, lethal, walked])
	_tear_down(player, director, city)
	_restore(saved_completed, saved_failed, saved_progress, saved_scars, saved_state)

## Whether a chase straight at `to` from `from`, sliding along walls as every pursuer's step does
## (`EventInstance.walkable_step_on()`), ever comes within `standoff` of it in 30s at `speed`, in
## steps of a tenth of a second.
static func _a_straight_chase_reaches(map: CityMap, from: Vector2, to: Vector2,
		standoff: float, speed: float) -> bool:
	var at := from
	for i in 300:
		var toward := to - at
		if toward.length() <= standoff:
			return true
		var step := toward.normalized() * minf(speed * 0.1, toward.length())
		at += EventInstance.walkable_step_on(map, at, step)
	return false

## Walkable, open, unobstructed ground within `reach` of `body`, nearest the reach's edge first —
## where she stands to touch it — or `Vector2.INF`.
static func _beside(map: CityMap, body: Vector2, reach: float) -> Vector2:
	var centre := map.world_to_tile(body)
	var best := Vector2.INF
	var best_distance := -1.0
	for dy in range(-5, 6):
		for dx in range(-5, 6):
			var tile := centre + Vector2i(dx, dy)
			var spot := map.tile_to_world(tile)
			var distance := spot.distance_to(body)
			if distance > reach - 4.0 or distance <= best_distance or not map.is_walkable(tile) \
					or map.is_closed(tile) or map.is_obstructed(tile):
				continue
			best = spot
			best_distance = distance
	return best

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
	rng.seed = hash("%s%d:%d:%s" % [_streams, seed_value, DAY, stream])
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
