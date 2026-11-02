extends "res://tests/resistance_rig.gd"
## Where a mark and its guard stand in an alley: avoided alleys, the guard's place, walled alleys and the doorstep.

func run(t) -> void:
	_test_a_fresh_mark_avoids_an_alley_a_completed_step_used(t)
	_test_a_relocated_mark_avoids_an_alley_a_completed_step_used(t)
	_test_the_guard_moves_with_the_mark_into_its_new_alley(t)
	_test_a_relocation_never_retires_a_guard_in_view_or_awake(t)
	_test_the_guard_never_lands_inside_a_building(t)
	_test_a_guard_with_nowhere_walkable_is_no_guard_at_all(t)
	_test_a_mark_only_ever_stands_one_tile_in_from_an_alley_mouth(t)
	_test_the_chalk_mark_guard_stands_two_thirds_through_its_alley(t)
	_test_a_long_alleys_robber_stands_two_thirds_in_past_his_trigger(t)
	_test_reading_a_mark_never_lands_her_in_his_catch(t)
	_test_a_courtyard_marks_guard_stands_at_the_courtyards_inner_end(t)
	_test_no_alley_robbery_stands_near_the_doorstep(t)
	_test_playtest_55_seed_has_no_spawn_kill(t)
	_test_a_walled_alley_escapes_no_other_check(t)
	_test_a_walled_alley_never_gets_the_chalk_mark_or_its_guard(t)
	if _city != null:
		_city.free()

## The dawn placement (`_place()` -> `_pick_reachable()`) skips an alley `GameState.
## completed_resistance_alley_tiles` already names, as long as some other alley is reachable —
## which a full generated city always has plenty of for a pickup's placement.
func _test_a_fresh_mark_avoids_an_alley_a_completed_step_used(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var saved_tiles := GameState.facts.completed_resistance_alley_tiles.duplicate()
		GameState.facts.completed_resistance_alley_tiles.clear()

		var first := _director(t)
		first.start_day(6, _rng(6, "resistance"), 300.0)
		var used_tile := _city.map.world_to_tile(first.contact_position())
		first.free()

		GameState.facts.completed_resistance_alley_tiles.append(used_tile)
		GameState.resistance.completed_steps = _completed_through(2)
		var second := _director(t)
		second.start_day(7, _rng(7, "resistance"), 300.0)
		t.check(second.current_step() != null and second.current_step().index == 3,
				"day 7 offers the second mark")
		var second_tile := _city.map.world_to_tile(second.contact_position())
		t.check(second_tile != used_tile,
				"a fresh mark avoids the alley a completed step used, another being in reach")
		second.free()

		GameState.facts.completed_resistance_alley_tiles = saved_tiles)

## The relocation rule (`_nearest_alley_within()`) applies the same avoidance, with the same
## fallback: marking the nearest alley to a chosen spot as "used" sends an unseen, far-relocating
## mark to some other alley still in reach instead, rather than to `Vector2.INF`.
func _test_a_relocated_mark_avoids_an_alley_a_completed_step_used(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var pair := _two_nearby_alleys()
		if pair.is_empty():
			t.check(true, "skipped: the test city has no two alleys close enough to test this")
			return
		var player_at: Vector2 = pair[0]
		var nearer_tile: Vector2i = pair[1]

		var saved_tiles := GameState.facts.completed_resistance_alley_tiles.duplicate()
		GameState.facts.completed_resistance_alley_tiles.clear()
		GameState.facts.completed_resistance_alley_tiles.append(nearer_tile)

		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		# Force the mark far from the chosen pair, regardless of where day 6's own roll put it —
		# this test is about the avoidance, not about replaying a particular placement.
		director._contact.global_position = \
				player_at + Vector2(ResistanceDirector.NOTICE_RADIUS + 200.0, 0.0)

		var player := _rig_player(t, player_at)
		director.use_player(player)
		director.tick(STEP)
		var new_tile := _city.map.world_to_tile(director.contact_position())
		t.check(new_tile != nearer_tile,
				"a relocated mark avoids the alley a completed step used, another being in reach")

		player.free()
		director.free()
		GameState.facts.completed_resistance_alley_tiles = saved_tiles)

## M213, "the robber guarding a chalk mark always spawns at the alley's other end from the mark":
## a relocated mark's fresh guard follows the same rule as the dawn draw, standing at the far
## mouth of whichever alley the mark relocated to, or as near it as the alley allows, rather than
## in a band around the mark itself.
func _test_the_guard_moves_with_the_mark_into_its_new_alley(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var old_at := director.contact_position()
		var old_guard: EventInstance = director._guard

		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, old_at)
		var player := _rig_player(t, far_alley)
		director.use_player(player)

		director.tick(STEP)
		var new_at := director.contact_position()
		t.check(new_at.distance_to(old_at) > 0.5, "the mark actually moved")
		t.check(old_guard != null and old_guard.is_finished,
				"the old guard is retired, not left standing over the spot the mark left")

		var guards: Array[EventInstance] = []
		for instance in _city.events.instances():
			if instance.def.id == "alley_robbery" and not instance.is_finished:
				guards.append(instance)
		t.check(guards.size() == 1, "exactly one live guard exists once the mark has moved (%d)"
				% guards.size())

		var guard: EventInstance = guards[0]
		var spot := director._guard_spot(new_at)
		t.check(spot != Vector2.INF, "the relocated mark's own alley is found")
		t.check(guard.global_position.distance_to(spot) <= ResistanceDirector.FAR_END_REACH_IN + 0.5,
				"the new guard stands in that alley, two-thirds through it or at its courtyard's " +
				"inner end, not in a band around the mark")

		player.free()
		director.free())

## A robber never vanishes where she can see him or out of a chase: an unread mark's relocation,
## which retires the guard over the old spot, waits while any part of him is on her screen or he
## is awake, and goes ahead once neither holds. She stands on an alley past `NOTICE_RADIUS` of the
## mark, where the relocation would otherwise fire on the first frame.
func _test_a_relocation_never_retires_a_guard_in_view_or_awake(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var old_at := director.contact_position()
		var guard: EventInstance = director._guard
		t.check(guard != null, "day 6's mark is guarded")
		if guard == null:
			director.free()
			return
		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, old_at)
		var player := _rig_player(t, far_alley)
		director.use_player(player)

		var feet := guard.global_position
		_look_at(Rect2(feet - Vector2(40.0, 40.0), Vector2(80.0, 80.0)))
		director.set_sight(_city.events.sees)
		director.tick(STEP)
		t.check(director.contact_position().distance_to(old_at) < 0.5,
				"with him on her screen, the mark stays where it is")
		t.check(not guard.is_finished, "and he is not retired in front of her")

		_look_at(Rect2())
		guard._notice_her()
		director.tick(STEP)
		t.check(director.contact_position().distance_to(old_at) < 0.5,
				"off her screen but awake, the mark still stays where it is")
		t.check(not guard.is_finished, "and he is not retired out of his chase")

		guard._stop_warning()
		director.tick(STEP)
		t.check(director.contact_position().distance_to(old_at) > 0.5,
				"asleep and out of her sight, the mark moves")
		t.check(guard.is_finished, "and he is retired with it")
		player.free()
		director.free())

## `docs/DECISIONS.md`, M100, "The guard robber is placed inside a building, where he is stuck for ever":
## `ResistanceDirector._draw_guard_position` redraws a bearing until the point is walkable, never
## on a held segment or the home block, rejecting rather than repairing — checked directly, over
## many seeds and many marks, rather than through a live guard instance: the geometry is the same
## draw whichever mark it is asked from, and this reaches far more of it than the seeded-run tests
## above sample. No `_city` is needed for the draw itself, so the director here is never added to
## the scene tree and is freed by hand.
func _test_the_guard_never_lands_inside_a_building(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance: float = robbery.inner_radius + ContactPoint.REACH
	var max_distance: float = robbery.notice_within() + ContactPoint.REACH
	var checked := 0
	var unguarded := 0
	for seed_value in [4242, 90210, 2295276695, 314159, 271828, 555555]:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map, null, GameState)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("guard-sweep:%d" % seed_value)
		for tile in map.tiles_of_type(GameEnums.TileType.ALLEY):
			if map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
				continue
			var mark := map.tile_to_world(tile)
			for _attempt in 3:
				checked += 1
				var guard_at := director._draw_guard_position(rng, mark, Vector2.INF,
						min_distance, max_distance)
				if guard_at == Vector2.INF:
					unguarded += 1
					continue
				var guard_tile := map.world_to_tile(guard_at)
				t.check(map.is_walkable(guard_tile),
						"seed %d: the guard for the mark at %s stands on walkable ground"
						% [seed_value, tile])
				t.check(not map.is_held_at(guard_tile) and not map.is_on_home_block(guard_tile),
						"seed %d: the guard for the mark at %s is not on held or home-block ground"
						% [seed_value, tile])
				var inside_a_building := false
				for rect in map.building_rects:
					if rect.has_point(guard_tile):
						inside_a_building = true
						break
				t.check(not inside_a_building,
						"seed %d: the guard for the mark at %s never stands inside a footprint"
						% [seed_value, tile])
		director.free()
	t.check(checked > 0, "some mark was actually checked (%d draws, %d found no ground)"
			% [checked, unguarded])

## The stated fallback, exercised directly: a mark with nowhere walkable in its whole band draws
## `TRAP_DRAW_LIMIT` times and gives up rather than settling for a building — "no trap is better
## than a trap in a wall". Built from a real map's own tile grid, with every tile in the band
## forced to `BUILDING` first, so the draw genuinely has nowhere to land rather than merely being
## unlucky.
func _test_a_guard_with_nowhere_walkable_is_no_guard_at_all(t) -> void:
	var map := CityGenerator.generate(13)
	var director := ResistanceDirector.new()
	director.setup(null, map, null, GameState)
	var mark_tile := Vector2i(20, 20)
	var mark := map.tile_to_world(mark_tile)
	# 8 tiles (256px) comfortably clears the 176px band's own far edge on every side.
	for dy in range(-8, 9):
		for dx in range(-8, 9):
			map.set_tile(mark_tile + Vector2i(dx, dy), GameEnums.TileType.BUILDING)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var guard_at := director._draw_guard_position(rng, mark, Vector2.INF, 60.0, 176.0)
	t.check(guard_at == Vector2.INF,
			"a band with no walkable ground anywhere in it draws no guard at all")
	director.free()

## feathery-marmot, "a mark's alley is chosen by its mouth" — *"Mouth only"* (the player,
## 2026-10-03, quiet-yak, inbox #486, asked whether a mark may sit in the middle of its alley), and
## feathery-hare, the mark stands one tile in from it (azure-puffin, inbox #664: "let's move the
## chalk mark one tile into the alley so I actually have to enter the alley to activate it"). Over six cities, forty dawn
## draws each (`_place()`, the call `start_day()` makes) and a relocation asked from every
## twentieth alley tile and from a point 300px off it in four directions (`_nearest_alley_within()`,
## the call every move makes): every mark lands one tile in from a mouth, found here independently
## of the director — a through-alley's end tile along its long axis, or a passage tile beside ground
## that is neither alley nor courtyard — and never on the mouth itself.
func _test_a_mark_only_ever_stands_one_tile_in_from_an_alley_mouth(t) -> void:
	var saved_tiles := GameState.facts.completed_resistance_alley_tiles.duplicate()
	GameState.facts.completed_resistance_alley_tiles = []
	var mark_step := ResistanceSteps.by_index(1)
	var drawn := 0
	var drawn_at_a_mouth := 0
	var moved := 0
	var moved_to_a_mouth := 0
	for seed_value in [4242, 90210, 2295276695, 314159, 271828, 555555]:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map, null, GameState)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("mark-mouth:%d" % seed_value)
		for _draw in 40:
			var at := director._place(mark_step, rng)
			if at == Vector2.INF:
				continue
			drawn += 1
			if _is_one_in_from_a_mouth(map, map.world_to_tile(at)):
				drawn_at_a_mouth += 1
		var alleys := map.tiles_of_type(GameEnums.TileType.ALLEY)
		for i in range(0, alleys.size(), 20):
			var origin := map.tile_to_world(alleys[i])
			for offset: Vector2 in [Vector2.ZERO, Vector2(300, 0), Vector2(-300, 0),
					Vector2(0, 300), Vector2(0, -300)]:
				var to := director._nearest_alley_within(origin + offset)
				if to == Vector2.INF:
					continue
				moved += 1
				if _is_one_in_from_a_mouth(map, map.world_to_tile(to)):
					moved_to_a_mouth += 1
		director.free()
	GameState.facts.completed_resistance_alley_tiles = saved_tiles
	t.check(drawn > 0 and drawn_at_a_mouth == drawn,
			"every dawn mark is drawn one tile in from an alley's mouth (%d of %d)"
			% [drawn_at_a_mouth, drawn])
	t.check(moved > 0 and moved_to_a_mouth == moved,
			"and every relocation lands on one (%d of %d)" % [moved_to_a_mouth, moved])

## feathery-marmot, "the robber stands two-thirds through the alley" — *"the robber should be
## 2/3rds through the alley not pressed against the edge of it"* (minty-hedgehog, statement 3) and,
## for an alley too short for that and 176px from the mark both, *"Two-thirds wins"* (quiet-yak, inbox #471).
## Over every through-alley tile of six cities, the guard `_guard_position()` stands for a mark
## (the placement `_maybe_set_a_trap()` and every relocation make) is on the alley's own axis,
## two-thirds of its length from the edge nearer the mark — or, where that point is within 62px of
## the mark (his catch and the touch reach), 62px past the mark. Every alley here is one block
## long, so this is the short case on every mark: he stands two-thirds in although that is under
## 216px from the mark (his `EventDef.notice` and the touch reach), which the test counts so it is
## not vacuous. Before, he stood at the far end
## tile or up to three tiles in from it, at least 176px from the mark where the alley allowed.
func _test_the_chalk_mark_guard_stands_two_thirds_through_its_alley(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance: float = robbery.inner_radius + ContactPoint.REACH
	var max_distance: float = robbery.notice_within() + ContactPoint.REACH
	var checked := 0
	var under_the_trigger := 0
	var distances: Array[float] = []
	for seed_value in [4242, 90210, 2295276695, 314159, 271828, 555555]:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map, null, GameState)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("guard-two-thirds:%d" % seed_value)
		for tile in _through_alley_tiles(map):
			if map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
				continue
			var mark := map.tile_to_world(tile)
			# The alley's two end tiles in the mark's own row or column, nearer first; its edges
			# are half a tile beyond them.
			var ends := director._alley_ends(mark)
			t.check(ends.size() == 2, "seed %d: the mark at %s has its alley's two ends"
					% [seed_value, tile])
			if ends.size() != 2:
				continue
			var guard_at := director._guard_position(rng, mark, true, Vector2.INF, false)
			if guard_at == Vector2.INF:
				continue
			checked += 1
			var axis := (ends[1] - ends[0]).normalized()
			var near_edge := ends[0] - axis * Tuning.TILE_SIZE * 0.5
			var length := ends[0].distance_to(ends[1]) + Tuning.TILE_SIZE
			# A mark one tile in from its mouth's centre moves the guard in by that tile too.
			var tile_in := clampf((mark - near_edge).dot(axis) - Tuning.TILE_SIZE * 0.5, 0.0,
					Tuning.TILE_SIZE)
			var two_thirds := near_edge + axis * (length * 2.0 / 3.0 + tile_in)
			var catch_floor := mark + axis * min_distance
			var expected := two_thirds
			if (two_thirds - near_edge).dot(axis) < (catch_floor - near_edge).dot(axis):
				expected = catch_floor
			t.check(guard_at.distance_to(expected) < 0.5,
					("seed %d: the guard for the mark at %s stands two-thirds through its alley, " +
					"or 62px past the mark where that is nearer (%s, wanted %s)")
					% [seed_value, tile, guard_at, expected])
			t.check(guard_at.distance_to(mark) >= min_distance - 0.5,
					"seed %d: and never within %.0fpx of the mark at %s"
					% [seed_value, min_distance, tile])
			if guard_at.distance_to(mark) < max_distance:
				under_the_trigger += 1
			distances.append(mark.distance_to(guard_at))
		director.free()
	t.check(checked > 0, "some mark was actually checked (%d)" % checked)
	t.check(under_the_trigger > 0,
			("the short case is met: two-thirds wins under %.0fpx of the mark on %d of %d marks")
			% [max_distance, under_the_trigger, checked])
	var all_equal := true
	for distance in distances:
		if not is_equal_approx(distance, distances[0]):
			all_equal = false
	t.check(distances.size() >= 2 and not all_equal,
			"the guard's own distance from the mark still varies from mark to mark")

## The long case of the same rule: where an alley is long enough for its two-thirds point to be
## 216px or more from the mark (his 180px `EventDef.notice` and `ContactPoint.REACH`), he stands
## there, and walking in from the mark's own end to read it and back out never wakes him. No city
## has an alley that long — every one is a block, 8 tiles — so the test carves one, 16 tiles, into a
## generated map's own grid and registers it as a through-alley, and reads a mark on its first
## tile.
func _test_a_long_alleys_robber_stands_two_thirds_in_past_his_trigger(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var max_distance: float = robbery.notice_within() + ContactPoint.REACH
	var map := CityGenerator.generate(13)
	var rect := Rect2i()
	for x in range(4, map.size.x - 6):
		var candidate := Rect2i(Vector2i(x, 4), Vector2i(Tuning.ALLEY_WIDTH_TILES, 16))
		var clear := true
		for alley in map.alley_rects:
			if alley.intersects(candidate.grow(1)):
				clear = false
		for tile in map.rect_tiles(candidate.grow(1)):
			if map.is_on_home_block(tile) or map.is_held_at(tile) or map.is_closed(tile):
				clear = false
				break
		if clear:
			rect = candidate
			break
	t.check(rect.has_area(), "there is ground on the test map to carve a long alley into")
	if not rect.has_area():
		return
	for tile in map.rect_tiles(rect):
		map.set_tile(tile, GameEnums.TileType.ALLEY)
	map.alley_rects.append(rect)
	var director := ResistanceDirector.new()
	director.setup(null, map, null, GameState)
	var mark := map.tile_to_world(rect.position)
	var length := float(rect.size.y * Tuning.TILE_SIZE)
	var near_edge := mark - Vector2(0.0, Tuning.TILE_SIZE * 0.5)
	var guard_at := director._guard_position(RandomNumberGenerator.new(), mark, true,
			Vector2.INF, false)
	t.check(guard_at.distance_to(near_edge + Vector2.DOWN * length * 2.0 / 3.0) < 0.5,
			"in a %.0fpx alley he stands two-thirds through it (%s)" % [length, guard_at])
	t.check(guard_at.distance_to(mark) >= max_distance,
			"which is %.0fpx from the mark, past his own trigger and the touch reach (%.0fpx)"
			% [guard_at.distance_to(mark), max_distance])
	var outside := near_edge + Vector2.UP * Tuning.TILE_SIZE
	var touch := mark + Vector2.UP * (ContactPoint.REACH - 2.0)
	t.check(_stays_asleep_walking_in_and_out(robbery, guard_at, outside, touch),
			"and walking in from the mark's own end to read it and back out never wakes him")
	director.free()

## The floor the player's "Two-thirds wins" left standing: reading a mark never lands her inside
## his catch (`EventDef.lethal_reach()`). Over every through-alley tile of six cities, she walks in
## from a tile and a half outside the alley's near end to `ContactPoint.REACH` less two pixels short
## of the mark and back out, past a still robber where `_guard_position()` stands him, and is never
## within his catch of him. Whether he wakes on the way is counted and not held: in a one-block alley
## reading the mark may wake him, and that is the player's choice.
func _test_reading_a_mark_never_lands_her_in_his_catch(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var checked := 0
	var asleep := 0
	for seed_value in [4242, 90210, 2295276695, 314159, 271828, 555555]:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map, null, GameState)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("mark-catch:%d" % seed_value)
		for tile in _through_alley_tiles(map):
			if map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
				continue
			var mark := map.tile_to_world(tile)
			var ends := director._alley_ends(mark)
			var guard_at := director._guard_position(rng, mark, true, Vector2.INF, false)
			if ends.is_empty() or guard_at == Vector2.INF:
				continue
			checked += 1
			var axis := (ends[1] - ends[0]).normalized()
			var outside := ends[0] - axis * Tuning.TILE_SIZE * 1.5
			var touch := mark - axis * (ContactPoint.REACH - 2.0)
			var nearest := INF
			var steps := ceili(outside.distance_to(touch) / 4.0)
			for s in steps + 1:
				nearest = minf(nearest, outside.lerp(touch, float(s) / float(steps)).distance_to(guard_at))
			t.check(nearest > robbery.lethal_reach(),
					("seed %d: reading the mark at %s from its own end comes no nearer than %.0fpx " +
					"to him, outside his %.0fpx catch") % [seed_value, tile, nearest,
					robbery.lethal_reach()])
			if _stays_asleep_walking_in_and_out(robbery, guard_at, outside, touch):
				asleep += 1
		director.free()
	t.check(checked > 0, "some guarded mark was actually checked (%d, %d left him asleep)"
			% [checked, asleep])

## A mark in a courtyard's passage — the `ALLEY` ground with no far end of its own — has its robber
## at the courtyard's inner end. *(2026-09-27, the player: "robber at inner end of the courtyard is
## fine. I encountered it in game and it worked well for me. you just have to lure the robber out
## first.")* Over six cities, for every passage tile: `_far_alley_mouth()` is the courtyard tile
## farthest from the mark, found here independently from `CityMap.courtyard_rects`; the guard the
## director draws stands inside that courtyard, within `FAR_END_REACH_IN` of that tile; and he is
## never within his catch (`EventDef.lethal_reach()`) of any point she can touch the mark from,
## `ContactPoint.REACH` around it. He may still wake as she reads it. Both the dawn draw and the
## relocation reach passage tiles, so the sweep is not vacuous.
func _test_a_courtyard_marks_guard_stands_at_the_courtyards_inner_end(t) -> void:
	var saved_tiles := GameState.facts.completed_resistance_alley_tiles.duplicate()
	GameState.facts.completed_resistance_alley_tiles = []
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance: float = robbery.inner_radius + ContactPoint.REACH
	var max_distance: float = robbery.notice_within() + ContactPoint.REACH
	var passages := 0
	var guarded := 0
	var drawn_in_a_passage := 0
	var relocated_to_a_passage := 0
	var mark_step := ResistanceSteps.by_index(1)
	for seed_value in [4242, 90210, 2295276695, 314159, 271828, 555555]:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map, null, GameState)
		var through := _through_alley_tiles(map)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("courtyard-inner-end:%d" % seed_value)
		for tile in map.tiles_of_type(GameEnums.TileType.ALLEY):
			if tile in through:
				continue
			passages += 1
			var mark := map.tile_to_world(tile)
			var court := Rect2i()
			for rect in map.courtyard_rects:
				if _passage_leads_into(map, tile, rect):
					court = rect
			t.check(court.has_area(), "seed %d: the passage at %s leads into a courtyard"
					% [seed_value, tile])
			var farthest := -1.0
			for y in range(court.position.y, court.end.y):
				for x in range(court.position.x, court.end.x):
					farthest = maxf(farthest, mark.distance_to(map.tile_to_world(Vector2i(x, y))))
			var far := director._far_alley_mouth(mark)
			t.check(far != Vector2.INF and absf(mark.distance_to(far) - farthest) < 0.5
					and court.has_point(map.world_to_tile(far)),
					"seed %d: the mark at %s has the courtyard's farthest tile as its inner end"
					% [seed_value, tile])
			var guard_at := director._draw_guard_position_near_far_mouth(rng, mark, far,
					min_distance, max_distance, Vector2.INF, 0.0, false)
			if guard_at == Vector2.INF:
				continue
			guarded += 1
			t.check(court.has_point(map.world_to_tile(guard_at))
					and guard_at.distance_to(far) <= ResistanceDirector.FAR_END_REACH_IN + 0.5,
					"seed %d: the guard for the mark at %s stands at the courtyard's inner end"
					% [seed_value, tile])
			t.check(guard_at.distance_to(mark) - ContactPoint.REACH > robbery.lethal_reach(),
					"seed %d: and no touch of the mark at %s lands her inside his %.0fpx catch"
					% [seed_value, tile, robbery.lethal_reach()])
			var nearest := director._nearest_alley_within(mark)
			if nearest != Vector2.INF and map.world_to_tile(nearest) not in through:
				relocated_to_a_passage += 1
		for _draw in 40:
			var at := director._place(mark_step, rng)
			if at != Vector2.INF and map.world_to_tile(at) not in through:
				drawn_in_a_passage += 1
		director.free()
	GameState.facts.completed_resistance_alley_tiles = saved_tiles
	t.check(passages > 0 and guarded == passages,
			"every courtyard passage mark is guarded (%d of %d)" % [guarded, passages])
	t.check(drawn_in_a_passage > 0 and relocated_to_a_passage > 0,
			"marks are drawn (%d) and relocated (%d) into courtyard passages"
			% [drawn_in_a_passage, relocated_to_a_passage])

## Whether the passage `tile` is on runs straight into `court` — the courtyard it opens onto.
func _passage_leads_into(map: CityMap, tile: Vector2i, court: Rect2i) -> bool:
	for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var at := tile
		while map.tile_at(at) == GameEnums.TileType.ALLEY:
			at += step
		if court.has_point(at):
			return true
	return false

## Walks her from `near` to `mark` and back out, in 8px steps, past a bare `alley_robbery` at
## `guard_at`, and answers whether he stayed asleep the whole way — the question
## `_test_the_mark_is_reachable_from_its_own_end` asks of both draws, over the same walk.
func _stays_asleep_walking_in_and_out(robbery: EventDef, guard_at: Vector2, near: Vector2,
		mark: Vector2) -> bool:
	var robber := EventInstance.new()
	robber.setup(robbery, guard_at)
	var woke := false
	var froms: Array[Vector2] = [near, mark]
	var tos: Array[Vector2] = [mark, near]
	for leg_index in froms.size():
		var from: Vector2 = froms[leg_index]
		var to: Vector2 = tos[leg_index]
		var steps := ceili(from.distance_to(to) / 8.0)
		for s in steps + 1:
			var at := from.lerp(to, float(s) / float(maxi(steps, 1)))
			robber.player_at = at
			robber.step(STEP)
			if not robber.is_waiting():
				woke = true
	robber.free()
	return not woke

## Item 4: the spawn kill named at the top of M100's queue has no fix of its own — items 1
## through 3 are supposed to make it impossible by construction, and this is what proves it.
## Nothing named `alley_robbery` — the catalogue's own placement, from `first_day` 8, or the
## resistance's guard trap, from `TRAP_FIRST_DAY` (6) — ever stands within lethal reach of the
## doorstep, over `RULE_SEEDS` seeds and every day either kind can appear.
##
## `reach` is computed from the row's own `inner_radius` (26px, the always-lethal zone around
## whichever one of them it is) and the trap's own `min_distance` (62px, how close a guard is
## ever placed to its mark) rather than a literal — the two named constants this bug was always
## about, added together as a generous rather than exact bound.
##
## **M125: six seeds cut to `RULE_SEEDS` (3).** Measured, this loop alone was 55.5s of the suite's
## ~65s: `EventScheduler.build_day()` schedules the whole city to answer a question about one row,
## once per (seed, day). The exclusion this checks is enforced at placement time the same way on
## every city — "impossible by construction" is a property of the construction, not of any one
## city's shape — so it is a rule sweep, not a layout sweep, and keeps the full day range (4..14,
## every day either kind can appear) while halving the seeds.
func _test_no_alley_robbery_stands_near_the_doorstep(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance: float = robbery.inner_radius + ContactPoint.REACH
	var max_distance: float = robbery.notice_within() + ContactPoint.REACH
	var reach: float = robbery.inner_radius + min_distance
	var checked := 0
	var seeds: Array[int] = [4242, 90210, 2295276695, 291862120, 314159, 555555]
	for seed_value: int in seeds.slice(0, RULE_SEEDS):
		var map := CityGenerator.generate(seed_value)
		var doorstep := map.doorstep_world_position()
		var consumed: Array[String] = []
		for day in range(4, 15):
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var events_rng := RandomNumberGenerator.new()
			events_rng.seed = hash("%d:events:%d" % [seed_value, day])
			for plan in EventScheduler.build_day(DaySpec.for_day(day), events_rng, map, consumed, [], [], tree):
				if plan.def.id != "alley_robbery" or not plan.is_placed():
					continue
				checked += 1
				t.check(plan.position.distance_to(doorstep) > reach,
						("seed %d day %d: no scheduled alley_robbery stands within lethal reach " +
						"of the doorstep") % [seed_value, day])

			var director := ResistanceDirector.new()
			director.setup(null, map, null, GameState)
			var mark_rng := RandomNumberGenerator.new()
			mark_rng.seed = hash("%d:mark:%d" % [seed_value, day])
			var mark_at := director._place(ResistanceSteps.by_index(1), mark_rng)
			if mark_at != Vector2.INF:
				checked += 1
				t.check(mark_at.distance_to(doorstep) > reach,
						"seed %d day %d: the chalk mark is not within lethal reach of the doorstep"
						% [seed_value, day])
				var guard_rng := RandomNumberGenerator.new()
				guard_rng.seed = hash("%d:guard:%d" % [seed_value, day])
				var guard_at := director._draw_guard_position(guard_rng, mark_at, Vector2.INF,
						min_distance, max_distance)
				if guard_at != Vector2.INF:
					checked += 1
					t.check(guard_at.distance_to(doorstep) > reach,
							"seed %d day %d: the guard trap is not within lethal reach of the doorstep"
							% [seed_value, day])
				# The real placement a chalk mark's own guard actually uses (`_maybe_set_a_trap()`,
				# `for_mark`) is `_guard_position()`'s alley placement — two-thirds through a
				# through-alley, the courtyard's inner end past a passage — not the check above:
				# checked here too, since standing him in the alley rather than in a band around
				# the mark is a different placement with no guarantee it inherits this one's.
				var mark_guard_rng := RandomNumberGenerator.new()
				mark_guard_rng.seed = hash("%d:far-guard:%d" % [seed_value, day])
				var mark_guard_at := director._guard_position(mark_guard_rng, mark_at, true,
						Vector2.INF, false)
				if mark_guard_at != Vector2.INF:
					checked += 1
					t.check(mark_guard_at.distance_to(doorstep) > reach,
							("seed %d day %d: the guard standing in the mark's own alley is " +
							"not within lethal reach of the doorstep either") % [seed_value, day])
			director.free()
	t.check(checked > 0, "some (seed, day) actually placed something to check (%d)" % checked)

## The reported run, replayed at the same seed and day — no longer byte-for-byte, since the
## calendar this test's own day sits in has moved (`Tuning.REGION_WALL_FIRST_DAY` 7 → 9, and the
## mark on offer at day 7 with nothing touched yet is now the second one, index 3, the van's own
## mark, rather than the first). What is still checked is the general shape the bug was: seed
## 291862120, day 7, the M78 "never-seen mark follows her" rule (`_track_sight_and_reposition`)
## relocating a mark she starts the day standing near, and the guard redrawn for the new mark
## landing nowhere lethal. Built through the real pipeline — `City.start_day`, then
## `EventManager.start_day`, then `ResistanceDirector.start_day` — rather than the data-level
## sweep above, so the M78 relocation actually runs the way it does in a played day.
func _test_playtest_55_seed_has_no_spawn_kill(t) -> void:
	_with_clean_run(func() -> void:
		var seed_value := 291862120
		var day := 7
		var city: City = RunCity.of_the_run(CITY_SCENE)
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		city.events.stream_radius = INF

		var closure_state := CityState.new()
		closure_state.begin_day(city.map.block_plans, day)
		var closure_rng := RandomNumberGenerator.new()
		closure_rng.seed = hash("%d:closures:%d" % [seed_value, day])
		city.start_day(closure_state, day, closure_rng)

		var doorstep := city.map.doorstep_world_position()
		var events_rng := RandomNumberGenerator.new()
		events_rng.seed = hash("%d:events:%d" % [seed_value, day])
		var consumed: Array[String] = []
		city.events.start_day(DaySpec.for_day(day), events_rng, consumed, doorstep)

		var director := ResistanceDirector.new()
		t.add_child(director)
		director.set_process(false)
		director.setup(city, city.map)
		var resistance_rng := RandomNumberGenerator.new()
		resistance_rng.seed = hash("%d:resistance:%d" % [seed_value, day])
		# No steps completed yet, which is what actually offers day 7's own chalk mark (index 3)
		# — a player who has not yet been near it, exactly the reported run's own shape.
		director.start_day(day, resistance_rng, 300.0)
		t.check(director.current_step() != null and director.current_step().index == 3,
				"seed %d day %d: day 7's chalk mark is still on offer, as in the reported run"
				% [seed_value, day])

		var player := _rig_player(t, doorstep)
		director.use_player(player)
		director.tick(STEP)

		var robbery := EventCatalogue.by_id("alley_robbery")
		var min_distance: float = robbery.inner_radius + ContactPoint.REACH
		var reach: float = robbery.inner_radius + min_distance

		var mark_at := director.contact_position()
		if mark_at != Vector2.INF:
			t.check(mark_at.distance_to(doorstep) > reach,
					("seed %d day %d: the (possibly relocated) chalk mark is not within lethal " +
					"reach of the doorstep") % [seed_value, day])

		var robbers_checked := 0
		for instance in city.events.instances():
			if instance.def.id != "alley_robbery":
				continue
			robbers_checked += 1
			t.check(instance.global_position.distance_to(doorstep) > reach,
					("seed %d day %d: no alley_robbery instance (guard or scheduled) stands " +
					"within lethal reach of the doorstep") % [seed_value, day])
		t.check(robbers_checked > 0,
				"seed %d day %d: the reported run's guard exists to check (%d found)"
				% [seed_value, day, robbers_checked])

		player.free()
		director.free()
		city.free())

## PLAYTEST-57, "a chalk mark behind a barrier": `144s-attempt1-asked-1.png` shows the
## resistance's mark on an alley's paving behind a roadblock band across its mouth. Reproduced at
## `Tuning.REGION_WALL_FIRST_DAY` — the first day a wall can stand at all — rather than the
## reported run's own day 7, which predates the wall now that the doors arrive three task days
## later (day 9 rather than day 7). `RegionPlanner.plan_day` walls several crossing alleys on this
## day, off today's tree, and **every one of their tiles passed all three checks
## `_pick_reachable()` had before this fix** — `is_closed()` (about a `RoadClosure`, which this is
## not), `is_held_at()` (about a `StreetNetwork` segment, which an alley is never on) and
## `is_on_home_block()`. None of the three ever looks at a region wall, which is the whole of the
## escape. `CityMap.is_in_walled_alley()` is the fourth check that closes it.
func _test_a_walled_alley_escapes_no_other_check(t) -> void:
	var seed_value := 2199579682
	var day := Tuning.REGION_WALL_FIRST_DAY
	var map := CityGenerator.generate(seed_value)
	var tree := RouteTree.for_day(map, day)
	var region_plan := RegionPlanner.plan_day(map, day, tree)
	t.check(not region_plan.alley_walls.is_empty(),
			"seed %d day %d walls at least one crossing alley, or this test checks nothing"
			% [seed_value, day])

	var checked := 0
	for rect in region_plan.alley_walls:
		for tile in map.rect_tiles(rect):
			checked += 1
			t.check(not map.is_closed(tile) and not map.is_held_at(tile) \
					and not map.is_on_home_block(tile),
					("seed %d day %d: %s is inside a walled alley, and none of is_closed(), " +
					"is_held_at() or is_on_home_block() catches it — that gap is the reported bug")
					% [seed_value, day, tile])
			t.check(map.is_in_walled_alley(tile, region_plan.alley_walls),
					"seed %d day %d: %s is refused by the check that closes the gap"
					% [seed_value, day, tile])
	t.check(checked > 0, "some walled-alley tile was actually checked (%d)" % checked)

## The same reported seed, through the real pipeline `_test_playtest_55_seed_has_no_spawn_kill`
## uses — `City.start_day`, then `ResistanceDirector.start_day` — swept over many RNG draws per
## step rather than trusting the one draw the reported run happened to make, at
## `Tuning.REGION_WALL_FIRST_DAY` for the same reason `_test_a_walled_alley_escapes_no_other_check`
## moved off day 7: neither the mark nor its guard, from `TRAP_FIRST_DAY`, may ever land inside a
## walled-off crossing alley, on any draw.
func _test_a_walled_alley_never_gets_the_chalk_mark_or_its_guard(t) -> void:
	_with_clean_run(func() -> void:
		var seed_value := 2199579682
		var day := Tuning.REGION_WALL_FIRST_DAY
		var city: City = RunCity.of_the_run(CITY_SCENE)
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))

		var closure_state := CityState.new()
		closure_state.begin_day(city.map.block_plans, day)
		var closure_rng := RandomNumberGenerator.new()
		closure_rng.seed = hash("%d:closures:%d" % [seed_value, day])
		city.start_day(closure_state, day, closure_rng)
		var walled_alleys := city.region_plan().alley_walls
		t.check(not walled_alleys.is_empty(),
				"seed %d day %d walls at least one crossing alley, or this test checks nothing"
				% [seed_value, day])

		var director := ResistanceDirector.new()
		t.add_child(director)
		director.set_process(false)
		director.setup(city, city.map)

		var robbery := EventCatalogue.by_id("alley_robbery")
		var min_distance: float = robbery.inner_radius + ContactPoint.REACH
		var max_distance: float = robbery.notice_within() + ContactPoint.REACH

		var attempts := 0
		for step in ResistanceSteps.all():
			if step.needs_goal or not step.is_pickup:
				continue   # the finale sits at the station's door, and only a mark sits in an alley
			for trial in 20:
				attempts += 1
				var mark_rng := RandomNumberGenerator.new()
				mark_rng.seed = hash("%d:mark:%d:%d:%d" % [seed_value, day, step.index, trial])
				var at := director._place(step, mark_rng)
				if at == Vector2.INF:
					continue
				var tile := city.map.world_to_tile(at)
				t.check(not city.map.is_in_walled_alley(tile, walled_alleys),
						"seed %d day %d step %d trial %d: the mark is not inside a walled alley"
						% [seed_value, day, step.index, trial])

				var guard_rng := RandomNumberGenerator.new()
				guard_rng.seed = hash("%d:guard:%d:%d:%d" % [seed_value, day, step.index, trial])
				var guard_at := director._draw_guard_position(guard_rng, at, Vector2.INF,
						min_distance, max_distance)
				if guard_at != Vector2.INF:
					var guard_tile := city.map.world_to_tile(guard_at)
					t.check(not city.map.is_in_walled_alley(guard_tile, walled_alleys),
							("seed %d day %d step %d trial %d: the guard is not inside a walled " +
							"alley either") % [seed_value, day, step.index, trial])
				# The real placement a chalk mark's own guard uses (`_maybe_set_a_trap()`'s
				# `for_mark`) is `_guard_position()`'s alley placement instead — two-thirds
				# through a through-alley, the courtyard's inner end past a passage — checked here
				# too, since it is a different placement with no guarantee it inherits this one's
				# own walled-alley refusal.
				if step.is_pickup:
					var mark_guard_rng := RandomNumberGenerator.new()
					mark_guard_rng.seed = hash("%d:far-guard:%d:%d:%d"
							% [seed_value, day, step.index, trial])
					var mark_guard_at := director._guard_position(mark_guard_rng, at, true,
							Vector2.INF, false)
					if mark_guard_at != Vector2.INF:
						var mark_guard_tile := city.map.world_to_tile(mark_guard_at)
						t.check(not city.map.is_in_walled_alley(mark_guard_tile, walled_alleys),
								("seed %d day %d step %d trial %d: the guard standing in the " +
								"mark's own alley is not inside a walled alley either")
								% [seed_value, day, step.index, trial])
		t.check(attempts > 0, "some (step, trial) actually placed something to check (%d)" % attempts)

		director.free()
		city.free())
