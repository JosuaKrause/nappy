extends "res://tests/resistance_rig.gd"
## Where a mark and its guard stand in an alley: avoided alleys, the guard's place, walled alleys and the doorstep.
##
## **Every test builds what it asks about and leaves nothing for the next** (minty-quail, tests through
## public seams). A test builds its city in a run of its own (`_build_city_in_a_new_run()`) and sets
## the steps done and the alleys used on that run. What the director puts in the street is read from
## the street (`contact_position()`, `_live()`), and a robber is woken and put back to sleep the way the
## event manager does it, by where she stands when he takes his step (`EventInstance.step()`). A mark
## is placed the two ways a day places one: at dawn (`start_day()`), and by a relocation, her stroller
## set down far from an unseen mark and one tick (`_relocate_round()`), which costs a tick where a
## dawn costs the day's reachability built afresh, so the sweeps over every mark tile of a city are
## relocations and the dawn draws are a few. Where a mark's alley ends and where its guard should
## stand are worked out from the map alone (`AlleyMarks`).

func run(t) -> void:
	_test_a_fresh_mark_avoids_an_alley_a_completed_step_used(t)
	_test_a_relocated_mark_avoids_an_alley_a_completed_step_used(t)
	_test_the_guard_moves_with_the_mark_into_its_new_alley(t)
	_test_a_relocation_never_retires_a_guard_in_view_or_awake(t)
	_test_the_guard_never_lands_inside_a_building(t)
	_test_a_guard_with_nowhere_walkable_is_no_guard_at_all(t)
	_test_a_mark_only_ever_stands_one_tile_in_from_an_alley_mouth(t)
	_test_the_chalk_mark_guard_stands_two_thirds_through_its_alley(t)
	_test_reading_a_mark_never_lands_her_in_his_catch(t)
	_test_a_courtyard_marks_guard_stands_at_the_courtyards_inner_end(t)
	_test_no_alley_robbery_stands_near_the_doorstep(t)
	_test_playtest_55_seed_has_no_spawn_kill(t)
	_test_a_walled_alley_escapes_no_other_check(t)
	_test_a_walled_alley_never_gets_the_chalk_mark_or_its_guard(t)
	_free_city()

## The dawn placement (`start_day()`) skips an alley the run's
## `completed_resistance_alley_tiles` already names, as long as some other alley is reachable —
## which a full generated city always has plenty of for a pickup's placement.
func _test_a_fresh_mark_avoids_an_alley_a_completed_step_used(t) -> void:
	var run := _build_city_in_a_new_run(t)
	var first := _director(t)
	first.start_day(6, _rng(6, "resistance"), 300.0)
	var used_tile := _city.map.world_to_tile(first.contact_position())
	first.free()

	run.facts.completed_resistance_alley_tiles.append(used_tile)
	run.resistance.completed_steps = _completed_through(2)
	var second := _director(t)
	second.start_day(7, _rng(7, "resistance"), 300.0)
	t.check(second.current_step() != null and second.current_step().index == 3,
			"day 7 offers the second mark")
	var second_tile := _city.map.world_to_tile(second.contact_position())
	t.check(second_tile != used_tile,
			"a fresh mark avoids the alley a completed step used, another being in reach")
	second.free()

## The relocation rule applies the same avoidance, with the same fallback: marking the nearest alley
## to a chosen spot as "used" sends an unseen mark she walks away from to some other alley still in
## reach instead, rather than to `Vector2.INF`. She stands on a mark tile that is its own nearest
## with nothing used — a mark she walks onto with nothing used moves onto it (`_relocate_round()`) —
## and has another such tile within `NOTICE_RADIUS` of it, more than `NOTICE_RADIUS` from the day's
## mark, and the tick that follows moves the mark off her tile.
func _test_a_relocated_mark_avoids_an_alley_a_completed_step_used(t) -> void:
	var run := _build_city_in_a_new_run(t)
	var scout := _director(t)
	scout.start_day(6, _rng(6, "resistance"), 300.0)
	var scout_player := _rig_player(t, scout.contact_position())
	scout.use_player(scout_player)
	var away: Array[Vector2] = []
	for tile in _mark_tiles():
		away.append(_city.map.tile_to_world(tile))
	# Chosen without the avoidance: tiles a mark moves onto when she stands on them with nothing
	# used, and that have another such tile within `NOTICE_RADIUS`, so that using one leaves another
	# in reach.
	var eligible: Array[Vector2i] = []
	for tile in _mark_tiles():
		var at := _city.map.tile_to_world(tile)
		if _relocate_round(scout, scout_player, at, away).distance_to(at) <= 0.5:
			eligible.append(tile)
	var candidates: Array[Vector2i] = []
	for tile in eligible:
		var at := _city.map.tile_to_world(tile)
		for other in eligible:
			if other != tile and _city.map.tile_to_world(other).distance_to(at) < ResistanceDirector.NOTICE_RADIUS:
				candidates.append(tile)
				break
	scout_player.free()
	scout.free()
	t.check(not candidates.is_empty(), "the test city has a mark tile that is its own nearest " +
			"with another such tile in reach")

	var tried := 0
	for nearer_tile in candidates:
		var player_at := _city.map.tile_to_world(nearer_tile)
		run.facts.completed_resistance_alley_tiles.assign([nearer_tile])
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var old_at := director.contact_position()
		if old_at.distance_to(player_at) <= ResistanceDirector.NOTICE_RADIUS:
			director.free()
			continue
		tried += 1
		var player := _rig_player(t, player_at)
		director.use_player(player)
		director.tick(STEP)
		var new_at := director.contact_position()
		t.check(new_at.distance_to(old_at) > 0.5, "the mark moved to an alley she came near")
		t.check(_city.map.world_to_tile(new_at) != nearer_tile,
				"a relocated mark avoids the alley a completed step used, another being in reach")
		player.free()
		director.free()
		break
	t.check(tried == 1, "a mark tile far from the day's mark was tried (%d)" % tried)

## M213, "the robber guarding a chalk mark always spawns at the alley's other end from the mark":
## a relocated mark's fresh guard follows the same rule as the dawn draw, standing at the far
## mouth of whichever alley the mark relocated to, or as near it as the alley allows, rather than
## in a band around the mark itself.
func _test_the_guard_moves_with_the_mark_into_its_new_alley(t) -> void:
	_build_city_in_a_new_run(t)
	var director := _director(t)
	director.start_day(6, _rng(6, "resistance"), 300.0)
	var old_at := director.contact_position()
	var old_guards := _live("alley_robbery")
	var old_guard: EventInstance = old_guards[0] if old_guards.size() == 1 else null

	var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, old_at)
	var player := _rig_player(t, far_alley)
	director.use_player(player)

	director.tick(STEP)
	var new_at := director.contact_position()
	t.check(new_at.distance_to(old_at) > 0.5, "the mark actually moved")
	t.check(old_guard != null and old_guard.is_finished,
			"the old guard is retired, not left standing over the spot the mark left")

	var guards := _live("alley_robbery")
	t.check(guards.size() == 1, "exactly one live guard exists once the mark has moved (%d)"
			% guards.size())

	var guard: EventInstance = guards[0]
	var spot := _guard_spot_of(_city.map, new_at)
	t.check(spot != Vector2.INF, "the relocated mark's own alley is found")
	t.check(guard.global_position.distance_to(spot) <= ResistanceDirector.FAR_END_REACH_IN + 0.5,
			"the new guard stands in that alley, two-thirds through it or at its courtyard's " +
			"inner end, not in a band around the mark")

	player.free()
	director.free()

## A robber never vanishes where she can see him or out of a chase: an unread mark's relocation,
## which retires the guard over the old spot, waits while any part of him is on her screen or he
## is awake, and goes ahead once neither holds. She stands on an alley past `NOTICE_RADIUS` of the
## mark, where the relocation would otherwise fire on the first frame. He wakes when she stands
## within his notice as he takes his step, and sleeps again when she has stood out of it and he
## has taken another (`EventInstance.warns_by_radius()`), the way the event manager runs him: she
## stands 60px from him along the line to the mark, in his alley with a clear line to him.
func _test_a_relocation_never_retires_a_guard_in_view_or_awake(t) -> void:
	_build_city_in_a_new_run(t)
	var director := _director(t)
	director.start_day(6, _rng(6, "resistance"), 300.0)
	var old_at := director.contact_position()
	var guards := _live("alley_robbery")
	var guard: EventInstance = guards[0] if guards.size() == 1 else null
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
	guard.player_at = feet + (old_at - feet).normalized() * 60.0
	guard.step(STEP)
	t.check(not guard.is_waiting(), "she stood within his notice as he stepped, and he is awake")
	director.tick(STEP)
	t.check(director.contact_position().distance_to(old_at) < 0.5,
			"off her screen but awake, the mark still stays where it is")
	t.check(not guard.is_finished, "and he is not retired out of his chase")

	guard.player_at = far_alley
	guard.step(STEP)
	t.check(guard.is_waiting(), "she has stood out of his notice as he stepped, and he waits again")
	director.tick(STEP)
	t.check(director.contact_position().distance_to(old_at) > 0.5,
			"asleep and out of her sight, the mark moves")
	t.check(guard.is_finished, "and he is retired with it")
	player.free()
	director.free()

## `docs/DECISIONS.md`, M100, "The guard robber is placed inside a building, where he is stuck for ever":
## the director stands a mark's guard only on walkable ground, never on a held segment or the home
## block, rejecting rather than repairing. Read off the street over every mark tile of
## `SWEEP_SEEDS`' cities, each relocated onto in turn with her standing on it
## (`_relocations_over_the_marks()`): the spot two-thirds in is within his notice of her there, so
## each guard is the one the director stands at the nearest acceptable point along the alley
## instead, the refusal and the search after it that this rule is about. Each mark and its guard
## are also held off the doorstep's lethal reach, the spawn kill
## `_test_no_alley_robbery_stands_near_the_doorstep()` asks of the dawn, here over every mark tile.
func _test_the_guard_never_lands_inside_a_building(t) -> void:
	var robbery := EventCatalogue.mark_guard()
	var doorstep_reach := 2.0 * robbery.inner_radius + ContactPoint.REACH
	var checked := 0
	for seed_value in SWEEP_SEEDS:
		for entry in _relocations_over_the_marks(t, seed_value, _on_the_tile):
			var guard_at: Vector2 = entry.guard
			var map := _city.map
			var tile: Vector2i = entry.tile
			var doorstep := map.doorstep_world_position()
			if entry.mark != Vector2.INF:
				# PLAYTEST-55's spawn kill (`_test_no_alley_robbery_stands_near_the_doorstep()`),
				# over every mark the relocation stands and its guard.
				t.check(entry.mark.distance_to(doorstep) > doorstep_reach,
						"seed %d: the mark relocated to %s is not within lethal reach of the doorstep"
						% [seed_value, map.world_to_tile(entry.mark)])
			if entry.mark == Vector2.INF or guard_at == Vector2.INF:
				continue
			checked += 1
			t.check(guard_at.distance_to(doorstep) > doorstep_reach,
					"seed %d: the guard for the mark at %s is not within lethal reach of the doorstep"
					% [seed_value, tile])
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
	t.check(checked > 0, "some guarded mark was actually checked (%d)" % checked)

## The stated fallback: a mark with nowhere walkable for its guard gets no guard rather than one in
## a wall — "no trap is better than a trap in a wall". A through-alley's mark tile of the test city
## has bodies standing on every tile of its alley further in than the mark's own row, where the
## director looks for his spot (`ResistanceDirector.TRAP_DRAW_LIMIT` draws, or the alley's axis), and
## a relocation onto it from outside its mouth moves the mark there with no robber in the street,
## and says so in the run's trace.
func _test_a_guard_with_nowhere_walkable_is_no_guard_at_all(t) -> void:
	var run := _build_city_in_a_new_run(t)
	run.resistance.completed_steps = _completed_through(2)
	_look_at(Rect2())
	var map := _city.map
	var director := _director(t)
	director.start_day(7, _rng(7, "resistance"), 300.0)
	var player := _rig_player(t, director.contact_position())
	director.use_player(player)
	var away: Array[Vector2] = []
	var target := Vector2i(-1, -1)
	var beyond: Array[Vector2i] = []
	for tile in _mark_tiles():
		away.append(map.tile_to_world(tile))
		if target != Vector2i(-1, -1) or map.is_on_home_block(tile):
			continue
		for rect in map.alley_rects:
			if not rect.has_point(tile):
				continue
			var vertical := rect.size.y >= rect.size.x
			var along := tile.y - rect.position.y if vertical else tile.x - rect.position.x
			var inward := 1 if along == 1 else -1
			for other in map.rect_tiles(rect):
				var other_along := other.y - rect.position.y if vertical else other.x - rect.position.x
				if (other_along - along) * inward > 0:
					beyond.append(other)
			target = tile
	t.check(target != Vector2i(-1, -1), "the test city has a through-alley mark tile")
	var body := 1
	map.obstruct_tiles(body, beyond)
	var lines: Array[String] = []
	director.trace = RunTrace.recording(lines)
	var moved := _relocate_round(director, player, _outside_its_mouth(map, target), away)
	t.check(moved != Vector2.INF and map.world_to_tile(moved) == target,
			"the mark moves onto %s, reached through its mouth" % target)
	t.check(_live(EventCatalogue.mark_guard().id).is_empty(),
			"with bodies on all the ground further in, no guard stands in the street")
	var said := false
	for line in lines:
		said = said or line.contains("unguarded: no walkable ground")
	t.check(said, "and the run's trace says the mark is unguarded for want of ground")
	map.release_obstruction(body)
	player.free()
	director.free()

## feathery-marmot, "a mark's alley is chosen by its mouth" — *"Mouth only"* (the player,
## 2026-10-03, quiet-yak, inbox #486, asked whether a mark may sit in the middle of its alley), and
## feathery-hare, the mark stands one tile in from it (azure-puffin, inbox #664: "let's move the
## chalk mark one tile into the alley so I actually have to enter the alley to activate it"). On two
## cities, a few dawn draws each (`start_day()`, each a day of its own stream) and a relocation asked
## from every twentieth alley tile and from a point 300px off it in four directions (`tick()` with
## her standing there, `_relocate_round()`): every mark lands one tile in from a mouth, found here
## independently of the director — a through-alley's end tile along its long axis, or a passage tile
## beside ground that is neither alley nor courtyard — and never on the mouth itself. The dawn draws
## are few because each starts a day, which builds the day's reachability afresh; the relocations,
## a tick each, are where the sweep is wide.
func _test_a_mark_only_ever_stands_one_tile_in_from_an_alley_mouth(t) -> void:
	var drawn := 0
	var drawn_at_a_mouth := 0
	var moved := 0
	var moved_to_a_mouth := 0
	for seed_value: int in SWEEP_SEEDS.slice(0, 2):
		var run := _build_city_in_a_new_run(t, seed_value)
		run.resistance.completed_steps = _completed_through(2)
		var map := _city.map
		var director := _director(t)
		for draw in 4:
			director.start_day(7, _rng(7, "mark-mouth:%d" % draw, seed_value), 300.0)
			var at := director.contact_position()
			if at == Vector2.INF:
				continue
			drawn += 1
			if _is_one_in_from_a_mouth(map, map.world_to_tile(at)):
				drawn_at_a_mouth += 1
		var player := _rig_player(t, director.contact_position())
		director.use_player(player)
		var away: Array[Vector2] = []
		for tile in _mark_tiles():
			away.append(map.tile_to_world(tile))
		var alleys := map.tiles_of_type(GameEnums.TileType.ALLEY)
		for i in range(0, alleys.size(), 20):
			var origin := map.tile_to_world(alleys[i])
			for offset: Vector2 in [Vector2.ZERO, Vector2(300, 0), Vector2(-300, 0),
					Vector2(0, 300), Vector2(0, -300)]:
				var to := _relocate_round(director, player, origin + offset, away)
				if to == Vector2.INF:
					continue
				moved += 1
				if _is_one_in_from_a_mouth(map, map.world_to_tile(to)):
					moved_to_a_mouth += 1
		player.free()
		director.free()
	t.check(drawn > 0 and drawn_at_a_mouth == drawn,
			"every dawn mark is drawn one tile in from an alley's mouth (%d of %d)"
			% [drawn_at_a_mouth, drawn])
	t.check(moved > 0 and moved_to_a_mouth == moved,
			"and every relocation lands on one (%d of %d)" % [moved_to_a_mouth, moved])

## feathery-marmot, "the robber stands two-thirds through the alley" — *"the robber should be
## 2/3rds through the alley not pressed against the edge of it"* (minty-hedgehog, statement 3) and,
## for an alley too short for that and 176px from the mark both, *"Two-thirds wins"* (quiet-yak, inbox #471).
## Over every through-alley mark tile of `SWEEP_SEEDS`' cities, the guard the director stands for a
## mark relocated onto it, read off the street with her outside its mouth
## (`_relocations_over_the_marks()`), is on the alley's own axis two-thirds of its length from the
## edge nearer the mark, plus the tile the mark stands in from its mouth (`AlleyMarks`), and never
## within 62px of the mark (his catch and the touch reach). Marks one tile in from either end are
## both met, so "nearer" is asked both ways. Every alley is one block long, so this is the short case
## on every mark: he stands two-thirds in although that is under 216px from the mark (his
## `EventDef.notice` and the touch reach), which the test counts so it is not vacuous. For the same
## reason his distance from the mark is the same on every mark tile, and the 62px floor past the
## mark binds on none of them (two-thirds in is far past it); the oracle keeps the floor for a point
## no mark stands on. Before, he stood at the far end tile or up to three tiles in from it, at least
## 176px from the mark where the alley allowed.
func _test_the_chalk_mark_guard_stands_two_thirds_through_its_alley(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance: float = robbery.inner_radius + ContactPoint.REACH
	var max_distance: float = robbery.notice_within() + ContactPoint.REACH
	var checked := 0
	var under_the_trigger := 0
	var from_each_end := {}
	for seed_value in SWEEP_SEEDS:
		for entry in _relocations_over_the_marks(t, seed_value, _outside_its_mouth):
			var map := _city.map
			var tile: Vector2i = entry.tile
			var mark: Vector2 = entry.mark
			var guard_at: Vector2 = entry.guard
			# The alley's two end tiles in the mark's own row or column, nearer first.
			var ends := AlleyMarks.through_ends(map, tile, map.tile_to_world(tile))
			if ends.size() != 2:
				continue
			t.check(mark != Vector2.INF and map.world_to_tile(mark) == tile,
					"seed %d: a mark moves onto %s with her outside its mouth" % [seed_value, tile])
			t.check(guard_at != Vector2.INF, "seed %d: and the mark at %s is guarded"
					% [seed_value, tile])
			if mark == Vector2.INF or map.world_to_tile(mark) != tile or guard_at == Vector2.INF:
				continue
			checked += 1
			var axis := (ends[1] - ends[0]).normalized()
			# Which end of its alley the mark is nearer: the top or left end, or the bottom or right.
			from_each_end[axis.x + axis.y > 0.0] = true
			var expected := AlleyMarks.expected_guard_spot(map, tile, mark, min_distance)
			t.check(guard_at.distance_to(expected) < 0.5,
					("seed %d: the guard for the mark at %s stands two-thirds through its alley " +
					"(%s, wanted %s)") % [seed_value, tile, guard_at, expected])
			t.check(guard_at.distance_to(mark) >= min_distance - 0.5,
					"seed %d: and never within %.0fpx of the mark at %s"
					% [seed_value, min_distance, tile])
			if guard_at.distance_to(mark) < max_distance:
				under_the_trigger += 1
	t.check(checked > 0, "some mark was actually checked (%d)" % checked)
	t.check(from_each_end.size() == 2,
			"marks one tile in from both ends of an alley were met (%d of 2)" % from_each_end.size())
	t.check(under_the_trigger > 0,
			("the short case is met: two-thirds wins under %.0fpx of the mark on %d of %d marks")
			% [max_distance, under_the_trigger, checked])

## The floor the player's "Two-thirds wins" left standing: reading a mark never lands her inside
## his catch (`EventDef.lethal_reach()`). Over every through-alley mark tile of `SWEEP_SEEDS`'
## cities, relocated onto in turn with her outside its mouth (`_relocations_over_the_marks()`), she
## walks in from a tile and a half outside the alley's near end to `ContactPoint.REACH` less two
## pixels short of the mark and back out, past a still robber where the street has him, and is never
## within his catch of him. Whether he wakes on the way is counted and not held: in a one-block alley
## reading the mark may wake him, and that is the player's choice.
func _test_reading_a_mark_never_lands_her_in_his_catch(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var checked := 0
	var asleep := 0
	for seed_value in SWEEP_SEEDS:
		for entry in _relocations_over_the_marks(t, seed_value, _outside_its_mouth):
			var map := _city.map
			var tile: Vector2i = entry.tile
			var mark: Vector2 = entry.mark
			var guard_at: Vector2 = entry.guard
			if mark == Vector2.INF or guard_at == Vector2.INF:
				continue
			var ends := AlleyMarks.through_ends(map, map.world_to_tile(mark), mark)
			if ends.is_empty():
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
	t.check(checked > 0, "some guarded mark was actually checked (%d, %d left him asleep)"
			% [checked, asleep])

## A mark in a courtyard's passage — the `ALLEY` ground with no far end of its own — has its robber
## at the courtyard's inner end. *(2026-09-27, the player: "robber at inner end of the courtyard is
## fine. I encountered it in game and it worked well for me. you just have to lure the robber out
## first.")* Over the passage mark tiles of `SWEEP_SEEDS`' cities, each relocated onto with her
## outside its mouth (`_relocations_over_the_marks()`): the courtyard's inner end is the tile
## farthest from the mark, found here independently from `CityMap.courtyard_rects`; the guard the
## street has stands inside that courtyard, within `FAR_END_REACH_IN` of that tile; and he is never
## within his catch (`EventDef.lethal_reach()`) of any point she can touch the mark from,
## `ContactPoint.REACH` around it. He may still wake as she reads it. The sweep says it met both kinds
## of passage: a one-tile passage, whose mark stands on the courtyard's first tile, and one into an
## apartment complex's court, wider than `CityGenerator.COURTYARD_SIZE_TILES`. The dawn draw reaches a passage
## too: with every through-alley mark tile used by a completed step, the day's mark is drawn in one,
## and its guard, stood at dawn with nothing about her refusing him, is at that courtyard's inner end.
func _test_a_courtyard_marks_guard_stands_at_the_courtyards_inner_end(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var passages := 0
	var guarded := 0
	var one_tile_passages := 0
	var apartment_courts := 0
	var drawn_in_a_passage := 0
	for seed_value in SWEEP_SEEDS:
		for entry in _relocations_over_the_marks(t, seed_value, _outside_its_mouth):
			var map := _city.map
			var tile: Vector2i = entry.tile
			if not AlleyMarks.through_ends(map, tile, map.tile_to_world(tile)).is_empty():
				continue
			passages += 1
			var mark: Vector2 = entry.mark
			var guard_at: Vector2 = entry.guard
			t.check(mark != Vector2.INF and map.world_to_tile(mark) == tile,
					"seed %d: a mark moves onto the passage's %s with her outside its mouth"
					% [seed_value, tile])
			if mark == Vector2.INF or guard_at == Vector2.INF:
				continue
			guarded += 1
			if map.tile_at(tile) == GameEnums.TileType.COURTYARD:
				one_tile_passages += 1
			var court := AlleyMarks.courtyard_of(map, tile)
			if maxi(court.size.x, court.size.y) > CityGenerator.COURTYARD_SIZE_TILES:
				apartment_courts += 1
			_check_the_courtyard_guard(t, robbery, map, tile, mark, guard_at,
					"seed %d: the mark at %s" % [seed_value, tile])
		# At dawn: every through-alley mark tile used, so the draw has only the passages.
		var city_map := _city.map
		var run: RunState = _city.run
		for tile in _mark_tiles():
			if not AlleyMarks.through_ends(city_map, tile, city_map.tile_to_world(tile)).is_empty():
				run.facts.completed_resistance_alley_tiles.append(tile)
		var guards_before := _live(EventCatalogue.mark_guard().id)
		var director := _director(t)
		director.start_day(7, _rng(7, "courtyard-dawn", seed_value), 300.0)
		var at := director.contact_position()
		var at_tile := city_map.world_to_tile(at)
		if at != Vector2.INF and AlleyMarks.through_ends(city_map, at_tile, at).is_empty():
			drawn_in_a_passage += 1
			var dawn_robber := _new_one(EventCatalogue.mark_guard().id, guards_before)
			var dawn_guard := dawn_robber.global_position if dawn_robber else Vector2.INF
			t.check(dawn_guard != Vector2.INF, "seed %d: the dawn mark in the passage's %s is guarded"
					% [seed_value, at_tile])
			if dawn_guard != Vector2.INF:
				_check_the_courtyard_guard(t, robbery, city_map, at_tile, at, dawn_guard,
						"seed %d: the dawn mark at %s" % [seed_value, at_tile])
		director.free()
	t.check(passages > 0 and guarded == passages,
			"every courtyard passage mark is guarded (%d of %d)" % [guarded, passages])
	t.check(one_tile_passages > 0 and apartment_courts > 0,
			("the sweep met a one-tile passage, its mark on the courtyard's first tile (%d), and a " +
			"passage into an apartment complex's wider court (%d)") % [one_tile_passages,
			apartment_courts])
	t.check(drawn_in_a_passage == SWEEP_SEEDS.size(),
			"with the through-alleys used, each city's dawn mark is drawn in a passage (%d of %d)"
			% [drawn_in_a_passage, SWEEP_SEEDS.size()])

## That the guard at `guard_at` of the mark at `mark` (on `tile`, in a courtyard's passage) stands at
## the courtyard's inner end and no touch of the mark lands her in his catch.
func _check_the_courtyard_guard(t, robbery: EventDef, map: CityMap, tile: Vector2i, mark: Vector2,
		guard_at: Vector2, what: String) -> void:
	var court := AlleyMarks.courtyard_of(map, tile)
	t.check(court.has_area(), "%s leads into a courtyard" % what)
	var far := AlleyMarks.courtyard_inner_end(map, court, mark)
	t.check(court.has_point(map.world_to_tile(guard_at))
			and guard_at.distance_to(far) <= ResistanceDirector.FAR_END_REACH_IN + 0.5,
			"%s has its guard at the courtyard's inner end" % what)
	t.check(guard_at.distance_to(mark) - ContactPoint.REACH > robbery.lethal_reach(),
			"%s: and no touch of it lands her inside his %.0fpx catch" % [what, robbery.lethal_reach()])

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

## The mark days whose dawn mark and guard `_test_no_alley_robbery_stands_near_the_doorstep()` reads,
## from `TRAP_FIRST_DAY` on: every other one, since each dawn builds the day's reachability afresh and
## the rule it checks is the placement's own on every day (a mark's guard is kept off the doorstep
## at dawn), so more days ask the same rule of more draws rather than of another case.
const GUARD_DOORSTEP_DAYS: Array[int] = [6, 8, 10, 12]

## Item 4: the spawn kill named at the top of M100's queue has no fix of its own — items 1
## through 3 are supposed to make it impossible by construction, and this is what proves it.
## Nothing named `alley_robbery` — the catalogue's own placement, from `first_day` 8, or the
## resistance's guard trap, from `TRAP_FIRST_DAY` (6) — ever stands within lethal reach of the
## doorstep, over `RULE_SEEDS` seeds: the catalogue's over every day it can appear, from its day's
## schedule; the mark's and its guard's from the dawns of `GUARD_DOORSTEP_DAYS` in a city of the same
## seed (`start_day()`, the mark and the guard it stands read off the street). Every mark tile a
## relocation stands a mark and its guard on is held off the doorstep too, in
## `_test_the_guard_never_lands_inside_a_building()`'s sweep.
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
## city's shape — so it is a rule sweep, not a layout sweep, and its schedules keep the full day
## range (4..14, every day the catalogue's robbery can appear) while halving the seeds.
func _test_no_alley_robbery_stands_near_the_doorstep(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance: float = robbery.inner_radius + ContactPoint.REACH
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

		# The mark each mark day offers at dawn, and the guard it stands: two-thirds through a
		# through-alley, the courtyard's inner end past a passage (`_maybe_set_a_trap()`).
		var run := _build_city_in_a_new_run(t, seed_value)
		for day: int in GUARD_DOORSTEP_DAYS:
			run.resistance.completed_steps = _completed_through(2 * (day - 6))
			var guards_before := _live(EventCatalogue.mark_guard().id)
			var director := _director(t)
			director.start_day(day, _rng(day, "mark", seed_value), 300.0)
			var mark_at := director.contact_position()
			var mark_step := director.current_step()
			if mark_step != null and mark_step.is_pickup and mark_at != Vector2.INF:
				checked += 1
				t.check(mark_at.distance_to(doorstep) > reach,
						"seed %d day %d: the chalk mark is not within lethal reach of the doorstep"
						% [seed_value, day])
				var guard := _new_one(EventCatalogue.mark_guard().id, guards_before)
				if guard:
					checked += 1
					t.check(guard.global_position.distance_to(doorstep) > reach,
							("seed %d day %d: the guard standing in the mark's own alley is " +
							"not within lethal reach of the doorstep either") % [seed_value, day])
			director.free()
		_free_city()
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
	var seed_value := 291862120
	var day := 7
	_build_city_in_a_new_run(t, seed_value)
	var city := _city
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

	var director := _director(t)
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
## uses — `City.start_day`, then `ResistanceDirector.start_day` — at
## `Tuning.REGION_WALL_FIRST_DAY` for the same reason `_test_a_walled_alley_escapes_no_other_check`
## moved off day 7: neither the mark nor its guard, from `TRAP_FIRST_DAY`, may ever land inside a
## walled-off crossing alley. Asked of several dawn draws of the day's mark (each a day of its own
## stream, every pickup drawing from the one pool of mark tiles) and of a relocation with her
## standing on each tile of each walled alley (`_relocate_round()`), the alley nearest her being
## the one the wall shuts: the mark and the guard it stands are read off the street.
func _test_a_walled_alley_never_gets_the_chalk_mark_or_its_guard(t) -> void:
	var seed_value := 2199579682
	var day := Tuning.REGION_WALL_FIRST_DAY
	var run := _build_city_in_a_new_run(t, seed_value)
	run.resistance.completed_steps = _completed_through(2 * (day - 6))
	var city := _city
	var map := city.map

	var closure_state := CityState.new()
	closure_state.begin_day(map.block_plans, day)
	var closure_rng := RandomNumberGenerator.new()
	closure_rng.seed = hash("%d:closures:%d" % [seed_value, day])
	city.start_day(closure_state, day, closure_rng)
	var walled_alleys := city.region_plan().alley_walls
	t.check(not walled_alleys.is_empty(),
			"seed %d day %d walls at least one crossing alley, or this test checks nothing"
			% [seed_value, day])
	_look_at(Rect2())

	var director := _director(t)
	var placed := 0
	for trial in 6:
		var guards_before := _live(EventCatalogue.mark_guard().id)
		director.start_day(day, _rng(day, "walled-mark:%d" % trial, seed_value), 300.0)
		var at := director.contact_position()
		if at == Vector2.INF or not director.current_step().is_pickup:
			continue
		placed += 1
		_check_off_the_walled_alleys(t, map, walled_alleys, at,
				_new_one(EventCatalogue.mark_guard().id, guards_before),
				"seed %d day %d trial %d" % [seed_value, day, trial])
	t.check(placed > 0, "some dawn draw actually placed a mark to check (%d)" % placed)

	var player := _rig_player(t, director.contact_position())
	director.use_player(player)
	var away: Array[Vector2] = []
	for tile in _mark_tiles():
		away.append(map.tile_to_world(tile))
	var relocated := 0
	for rect in walled_alleys:
		for tile in map.rect_tiles(rect):
			var guards_before := _live(EventCatalogue.mark_guard().id)
			var to := _relocate_round(director, player, map.tile_to_world(tile), away)
			if to == Vector2.INF:
				continue
			relocated += 1
			_check_off_the_walled_alleys(t, map, walled_alleys, to,
					_new_one(EventCatalogue.mark_guard().id, guards_before),
					"seed %d day %d, relocated from %s" % [seed_value, day, tile])
	t.check(relocated > 0, "some relocation from a walled alley actually moved the mark (%d)"
			% relocated)
	player.free()
	director.free()

## That a mark at `at` and its guard (`guard`, null when unguarded) stand outside every one of
## `walled_alleys`.
func _check_off_the_walled_alleys(t, map: CityMap, walled_alleys: Array[Rect2i], at: Vector2,
		guard: EventInstance, what: String) -> void:
	t.check(not map.is_in_walled_alley(map.world_to_tile(at), walled_alleys),
			"%s: the mark is not inside a walled alley" % what)
	if guard:
		t.check(not map.is_in_walled_alley(map.world_to_tile(guard.global_position), walled_alleys),
				"%s: the guard standing in the mark's own alley is not inside a walled alley either"
				% what)
