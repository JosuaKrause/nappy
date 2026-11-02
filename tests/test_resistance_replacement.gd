extends "res://tests/resistance_rig.gd"
## The resistance director's re-placement: an unseen mark moving to an alley she comes near, and what a relocation may never do.

func run(t) -> void:
	_test_an_unseen_mark_moves_to_the_nearest_alley_she_comes_near(t)
	_test_a_mark_within_notice_radius_does_not_move(t)
	_test_an_onscreen_but_far_mark_is_not_seen_and_still_relocates(t)
	_test_a_relocated_mark_never_lands_where_she_can_see_it_appear(t)
	_test_the_siting_hands_the_same_region_until_the_plan_changes(t)
	_test_a_guard_never_lands_within_his_own_reach_of_her(t)
	_test_a_relocated_mark_and_its_guard_are_placed_off_screen(t)
	_test_a_mark_seen_for_the_dwell_time_within_range_never_moves_again(t)
	_test_a_mark_under_a_covered_corner_is_not_noticed(t)
	_test_nothing_appears_or_vanishes_under_a_covered_corner(t)
	_test_the_neighbor_and_the_raid_wait_until_nothing_of_them_shows(t)
	if _city != null:
		_city.free()

func _test_an_unseen_mark_moves_to_the_nearest_alley_she_comes_near(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var mark_at := director.contact_position()
		t.check(mark_at != Vector2.INF, "day 6 places the mark")

		# She stands exactly on a distant alley — the nearest reachable one to her is itself,
		# at distance 0, which is what makes the assertion below exact rather than approximate.
		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, mark_at)
		t.check(far_alley != Vector2.INF, "the test city has an alley far from the mark")
		var player := _rig_player(t, far_alley)
		director.use_player(player)

		var lines: Array[String] = []
		director.trace = RunTrace.recording(lines)
		director.tick(STEP)
		t.check(director.contact_position().distance_to(far_alley) < 0.5,
				"an unseen mark moves to the alley she has just come near")

		var moved := false
		for line in lines:
			if line.begins_with("contact ") and line.contains("moved to") \
					and line.contains("never seen"):
				moved = true
		t.check(moved, "and a contact telemetry line records the move")

		player.free()
		director.free())

## Built from `_two_nearby_alleys()` (a real pair, not wherever day 6's own roll happened to put
## the mark) so "there really is a nearer alley on offer" holds by construction rather than by
## the luck of which tile the day's RNG chose: the mark is forced onto `other`, and she stands
## exactly on `nearer_tile`, which is nearer to her than the mark is by definition, and still
## within `NOTICE_RADIUS` of it (`_two_nearby_alleys()`'s own doc).
func _test_a_mark_within_notice_radius_does_not_move(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var pair := _two_nearby_alleys()
		if pair.is_empty():
			t.check(true, "skipped: the test city has no two alleys close enough to test this")
			return
		var player_at: Vector2 = pair[0]
		var other_tile: Vector2i = pair[2]

		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		director._contact.global_position = _city.map.tile_to_world(other_tile)
		var mark_at := director.contact_position()
		var player := _rig_player(t, player_at)
		director.use_player(player)

		director.tick(STEP)
		t.check(director.contact_position().distance_to(mark_at) < 0.5,
				"within NOTICE_RADIUS of her own mark, nothing moves — not even to a nearer alley")

		player.free()
		director.free())

## M177, playtest 116's own day-6 shape: a mark on offer at (24,149), on screen from the doorstep
## at (80,84) — fifteen tiles away — moved to (65,83) two seconds in and was marked *seen* 0.4s
## later, so a fifteen-tile-distant alley froze it for the rest of the day. Both of the director's
## view (`_sight` for the notice, the siting's `DRAWING_OFF_THE_VIEW` for placing) answering true near `mark_at`
## alone reproduces "on screen" there without a viewport, while leaving
## `far_alley` — the relocation target, over `NOTICE_RADIUS` away — answering false, the ground
## `_nearest_alley_within()` needs to still offer a candidate (never a tile she can currently
## see, brisk-wombat's "the mark and its robber never appear in front of her"); standing
## at `far_alley` (beyond `NOTICE_RADIUS`, so certainly beyond the far narrower `SEEN_DISTANCE`)
## reproduces the distance. A single frame is enough to show the old bug is gone: the old rule
## pinned the mark on this exact frame, and the new one still relocates it.
func _test_an_onscreen_but_far_mark_is_not_seen_and_still_relocates(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var mark_at := director.contact_position()
		# The mark's own picture on screen and nothing else: its corners are 23px from its centre,
		# and its guard stands at least 62px from it, so a relocation is never held back for him.
		_look_at(Rect2(mark_at - Vector2(20.0, 20.0), Vector2(40.0, 40.0)))
		director.set_sight(_city.events.sees)

		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, mark_at)
		t.check(far_alley != Vector2.INF, "the test city has an alley far from the mark")
		var player := _rig_player(t, far_alley)
		director.use_player(player)

		director.tick(STEP)
		t.check(director.contact_position().distance_to(far_alley) < 0.5,
				"on screen but far outlasts nothing: it still relocates to the alley she has come near")

		player.free()
		director.free())

## **The region a siting reads is built once for a plan**: the relocation asks it for every candidate
## tile, so each ask handing out a freshly built copy of the wall's and the doors' discs was most of
## its cost. The same plan gives the same region; another plan, another region.
func _test_the_siting_hands_the_same_region_until_the_plan_changes(t) -> void:
	_build_city(t)
	var state := CityState.new()
	state.begin_day(_city.map.block_plans, 10)
	_city.start_day(state, 10, RandomNumberGenerator.new())
	var first := _city.siting_region()
	t.check(first != null and first.centres.size() > 0, "day 10 has a region wall and doors")
	t.check(_city.siting_region() == first and _city.spawn_siting.region() == first,
			"asked again, the siting is handed the same region")
	var plan := _city.region_plan()
	var other := RegionPlanner.RegionPlan.new()
	other.alley_walls.append(Rect2i(1, 1, 1, 1))
	_city.set_region_plan(other)
	var changed := _city.siting_region()
	t.check(changed != first and changed.centres.is_empty()
			and changed.walled_alleys == other.alley_walls and _city.siting_region() == changed,
			"another plan is another region, itself handed again")
	_city.set_region_plan(plan)
	t.check(_city.siting_region() != changed and _city.siting_region().centres.size() \
			== first.centres.size(), "and the first plan again is built afresh from it")

## brisk-wombat, "the mark and its robber never appear in front of her" — the mark's own half:
## *"I just had one appear out of nowhere while I was walking through an alley."* `_nearest_alley_
## within()`'s own nearest candidate to `here` is, by construction, wherever she is standing or
## right beside it, which is on screen more often than not, so the search has to actively refuse
## whatever `_drawing_shows()` calls on screen rather than pick the plain nearest blind. `raw_nearest`
## names exactly that plain-nearest tile (asked with neither of the director's view tests set, so
## nothing is ever on screen); hiding only that one tile from both, mocked, is what makes the
## assertion below discriminate the refusal — the search has to find some other candidate still in
## `NOTICE_RADIUS` rather than the one nearest tile it would otherwise answer.
func _test_a_relocated_mark_never_lands_where_she_can_see_it_appear(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var old_at := director.contact_position()

		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, old_at)
		t.check(far_alley != Vector2.INF, "the test city has an alley far from the mark")
		var player := _rig_player(t, far_alley)
		director.use_player(player)

		var raw_nearest := director._nearest_alley_within(far_alley)
		t.check(raw_nearest.distance_to(far_alley) < 0.5,
				"with no screen test at all, the nearest reachable alley is the one she stands on")
		_look_at(Rect2(raw_nearest - Vector2(0.5, 0.5), Vector2.ONE))
		director.set_sight(_city.events.sees)

		director.tick(STEP)
		var new_at := director.contact_position()
		t.check(new_at.distance_to(old_at) > 0.5, "the mark actually moved")
		t.check(new_at.distance_to(raw_nearest) > 0.5,
				"but never to the one tile she could see it appear on")

		player.free()
		director.free())

## brisk-wombat's other half: *"a robber also appeared out of nowhere and instakilled me."* A
## guard's own band is drawn relative to the mark alone, with no idea where she is standing, so a
## mark relocating right up to where she stands (or a dawn placement near a wandering player)
## could put him inside his own `EventDef.notice`, or worse `inner_radius` (a `hard_fail` with no
## warning), of wherever she actually is unless the draw is also asked to refuse that. Checked
## directly against `_draw_guard_position()`, the draw the roadblock's guard uses, with
## `her` forced onto the mark itself — the closest a real guard's own band ever gets to her.
func _test_a_guard_never_lands_within_his_own_reach_of_her(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance: float = robbery.inner_radius + ContactPoint.REACH
	var max_distance: float = robbery.notice_within() + ContactPoint.REACH
	var checked := 0
	for seed_value in [4242, 90210, 2295276695, 314159, 271828, 555555]:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map, null, GameState)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("guard-keeps-off-her:%d" % seed_value)
		for tile in map.tiles_of_type(GameEnums.TileType.ALLEY):
			if map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
				continue
			var mark := map.tile_to_world(tile)
			for _attempt in 3:
				checked += 1
				var guard_at := director._draw_guard_position(rng, mark, Vector2.INF,
						min_distance, max_distance, mark, robbery.notice_within())
				if guard_at == Vector2.INF:
					continue
				t.check(guard_at.distance_to(mark) > robbery.notice_within(),
						"seed %d: the guard for the mark at %s never lands within his own reach of her"
						% [seed_value, tile])
		director.free()
	t.check(checked > 0, "some mark was actually checked (%d draws)" % checked)

## brisk-wombat, both halves: *"I just had one appear out of nowhere while I was walking through an
## alley and then a robber also appeared out of nowhere and instakilled me."* She stands on every
## other through-alley tile of two cities; the screen is the unrotated 640x360 world px around her
## (`Tuning.VIEW_HALF_EXTENT`). Wherever `_nearest_alley_within()` relocates the mark, no part of
## its 32px picture is on that screen, and the guard `_move_the_mark()` stands for it
## (`_guard_position()`, as `_maybe_set_a_trap()` calls it for a relocation) exists and shows no
## part of his 22x44px body on it either. The guard the roadblock's task sets at its contact when
## she reads the mark (`for_mark` false), asked of a contact just past the edge of her screen,
## never shows either.
## Every box is measured here from the screen's own edges rather than through the director's
## the siting, so the test does not ask the code whether the code is right.
func _test_a_relocated_mark_and_its_guard_are_placed_off_screen(t) -> void:
	var saved_tiles := GameState.facts.completed_resistance_alley_tiles.duplicate()
	GameState.facts.completed_resistance_alley_tiles = []
	var relocations := 0
	var tasks := 0
	for seed_value in [4242, 555555]:
		var map := CityGenerator.generate(seed_value)
		var screen := VisibleView.new()
		var director := ResistanceDirector.new()
		director.setup(null, map, null, GameState, SpawnSiting.new(map, map.navigator(),
				func() -> VisibleView: return screen))
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("off-screen:%d" % seed_value)
		var through := _through_alley_tiles(map)
		for i in range(0, through.size(), 2):
			var her := map.tile_to_world(through[i])
			screen.look(Rect2(her - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0), null)
			director.set_sight(screen.sees)
			var mark := director._nearest_alley_within(her)
			if mark != Vector2.INF:
				relocations += 1
				t.check(not _box_on_screen(mark, Vector2(16.0, 16.0), her),
						"seed %d: from %s, no part of the relocated mark at %s is on screen"
						% [seed_value, through[i], map.world_to_tile(mark)])
				var guard_at := director._guard_position(rng, mark, true, her, true)
				t.check(guard_at != Vector2.INF,
						"seed %d: the mark relocated to %s is guarded"
						% [seed_value, map.world_to_tile(mark)])
				if guard_at != Vector2.INF:
					t.check(not _box_on_screen(guard_at + Vector2(0.0, -22.0),
							Vector2(11.0, 22.0), her),
							"seed %d: from %s, no part of the relocated mark's guard at %s is on screen"
							% [seed_value, through[i], map.world_to_tile(guard_at)])
			var contact := her + Vector2(Tuning.VIEW_HALF_EXTENT.x + 40.0, 0.0)
			var task_guard := director._guard_position(rng, contact, false, her, true)
			if task_guard != Vector2.INF:
				tasks += 1
				t.check(not _box_on_screen(task_guard + Vector2(0.0, -22.0), Vector2(11.0, 22.0),
						her), "seed %d: a task's guard at %s is not on screen from %s"
						% [seed_value, map.world_to_tile(task_guard), through[i]])
		director.free()
	GameState.facts.completed_resistance_alley_tiles = saved_tiles
	t.check(relocations > 0 and tasks > 0,
			"marks were relocated (%d) and task guards drawn (%d)" % [relocations, tasks])

## Whether a box `half` either side of `centre` overlaps the unrotated screen around `her`.
func _box_on_screen(centre: Vector2, half: Vector2, her: Vector2) -> bool:
	return absf(centre.x - her.x) <= Tuning.VIEW_HALF_EXTENT.x + half.x \
			and absf(centre.y - her.y) <= Tuning.VIEW_HALF_EXTENT.y + half.y

## **A mark under a corner the joystick's controls cover is not in sight**, so its dwell does not run
## (dappled-swan, inbox #581: "use that everywhere where visibility is concerned -- for the other
## mode those rectangles *do* count"). She stands within `SEEN_DISTANCE` of the mark with it down and
## to her left, under the left corner, for longer than `SEEN_DWELL_SECONDS`, asked through the day's
## own visible area as `main` wires it: in the joystick scheme it is not noticed, in the tap scheme it
## is.
func _test_a_mark_under_a_covered_corner_is_not_noticed(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		for joystick: bool in [true, false]:
			var director := _director(t)
			director.start_day(6, _rng(6, "resistance"), 300.0)
			var mark_at := director.contact_position()
			# Camera look-ahead puts this nearby mark beneath the narrower focal-disc corner.
			# Keep her within the 150px notice distance independently of the camera centre.
			var her := mark_at + Vector2(135.0, -50.0)
			var view := VisibleView.around(her + Vector2(45.0, 0.0), TouchControls.covered_screen() if joystick else null)
			t.check(view.sees(mark_at) != joystick,
					"the actual camera view covers the mark only in joystick mode")
			_city.events.visible_view().look(view.view, TouchControls.covered_screen() if joystick else null)
			director.set_sight(_city.events.sees)
			var player := _rig_player(t, her)
			director.use_player(player)
			for i in ceili((ResistanceDirector.SEEN_DWELL_SECONDS + 0.5) / STEP):
				director.tick(STEP)
			t.check(mark_at.distance_to(her) <= ResistanceDirector.SEEN_DISTANCE
					and director._seen != joystick,
					"%s scheme: a mark %.0fpx off under the left corner is %s"
					% ["joystick" if joystick else "tap", mark_at.distance_to(her),
					"not noticed" if joystick else "noticed"])
			player.free()
			director.free())

## **Nothing the resistance places or removes appears or vanishes under a covered corner** *(olive-
## hedgehog, inbox #598, the player: "off screen is not the same as visible -- the corners get
## removed for visible not for off screen" · "I don't want any pop in")*. Joystick scheme, asked
## through the day's own view as `main` wires it (`EventManager.sees()` for the notice,
## `EventManager.on_screen()` for placing and removing):
##
## - **A relocation whose only candidate lies under the bottom-left corner is refused.** Each alley
##   mouth of the test city in turn is made the only candidate, its mark's picture laid at several
##   places inside the corner, and every case kept where it is the answer both with no screen test
##   at all (legal ground, within `NOTICE_RADIUS`) and with the visible area alone (its guard's spot
##   is under the corner or out of the view too) — the case `main`'s wiring has to refuse.
## - **The neighbor taken with the raid stays while they stand under that corner**, and is taken
##   once the camera is off them.
func _test_nothing_appears_or_vanishes_under_a_covered_corner(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var events := _city.events
		var scale := Tuning.VIEW_HALF_EXTENT * 2.0 / ScreenOrientation.DESIGN_SIZE
		var corner := TouchControls.covered_left()
		var corner_at := corner.position * scale
		var corner_size := corner.size * scale
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var refused := 0
		var all_marks := director._mark_tiles().duplicate()
		for tile: Vector2i in all_marks:
			var mark := _city.map.tile_to_world(tile)
			var only: Array[Vector2i] = [tile]
			director._mouths = only
			director._mark_tiles_of_mouths = only
			director._mouths_of = _city.map
			# The mark's centre at these shares of the corner, its whole picture inside it.
			for share: Vector2 in [Vector2(0.2, 0.8), Vector2(0.5, 0.5), Vector2(0.8, 0.8),
					Vector2(0.2, 0.2), Vector2(0.8, 0.2)]:
				var view_at := mark - corner_at - share * corner_size
				var her := view_at + Tuning.VIEW_HALF_EXTENT
				# With the view nowhere near, the only mouth is the answer.
				events.visible_view().look(Rect2(Vector2(-4000.0, -4000.0),
						Tuning.VIEW_HALF_EXTENT * 2.0), TouchControls.covered_screen())
				if director._nearest_alley_within(her).distance_to(mark) > 0.5:
					continue
				events.visible_view().look(Rect2(view_at, Tuning.VIEW_HALF_EXTENT * 2.0), TouchControls.covered_screen())
				# Only a mouth the visible area alone would not refuse (its picture and its
				# guard's body, each laid at its centre and four corners, all unseen under the
				# covered corner or out of the view) is a case the whole view has to refuse.
				var seen_by_the_visible_area := false
				for box_at: Array in [[ResistanceDirector.MARK_BOX, mark],
						[ResistanceDirector.GUARD_BOX, director._guard_spot(mark)]]:
					var drawn: Rect2 = box_at[0]
					var drawn_at: Vector2 = box_at[1]
					var middle := drawn_at + drawn.get_center()
					var half := drawn.size * 0.5
					for point: Vector2 in [middle, middle + half, middle - half,
							middle + Vector2(half.x, -half.y), middle + Vector2(-half.x, half.y)]:
						seen_by_the_visible_area = seen_by_the_visible_area or events.sees(point)
				if seen_by_the_visible_area:
					continue
				refused += 1
				director.set_sight(events.sees)
				t.check(director._nearest_alley_within(her) == Vector2.INF,
						"the only alley mouth, %s, under the covered corner is refused (%s of it)"
						% [tile, share])
		var none: Array[Vector2i] = []
		director._mouths = none
		director._mark_tiles_of_mouths = none
		t.check(refused > 0, "relocations under the covered corner were asked (%d)" % refused)
		director.free()

		var late := _director_on_the_neighbor(t)
		var walker := late._rider
		t.check(walker != null, "the neighbor is walking home")
		if walker:
			walker.transition(EventInstance.Phase.PARKED)
			late.tick(STEP)
			t.check(late._taken_neighbor == walker, "reaching the door first, they are to be taken")
			var at := walker.global_position
			var view_at := at - corner_at - corner_size * 0.5
			events.visible_view().look(Rect2(view_at, Tuning.VIEW_HALF_EXTENT * 2.0), TouchControls.covered_screen())
			t.check(events.on_screen(at) and not events.sees(at),
					"the neighbor stands in the view, under the covered corner")
			late.set_sight(events.sees)
			late.tick(STEP)
			t.check(late._taken_neighbor == walker and is_instance_valid(walker)
					and not walker.is_finished,
					"under the covered corner, the neighbor is not taken where they are drawn")
			events.visible_view().look(Rect2(at + Vector2(Tuning.VIEW_HALF_EXTENT.x * 4.0, 0.0),
					Tuning.VIEW_HALF_EXTENT * 2.0), TouchControls.covered_screen())
			late.tick(STEP)
			t.check(late._taken_neighbor == null, "once the camera is off them, they are taken")
		late.free())

## **What the raid brings and takes away is asked by its whole drawing, not its feet** *(olive-
## hedgehog, inbox #598: "I don't want any pop in")*, in either scheme and through the day's own
## view as `main` wires it:
##
## - **The taken neighbor stays while any of their figure is in view.** Their feet just below the
##   view's bottom edge leave their picture, which stands above them, on screen; they are taken
##   once the camera is off them.
## - **Day 10's raid waits while any of it would be drawn in view.** With the view's bottom edge
##   just above the patrol car's lane every van's and every beat point's feet are out of it, but
##   the car's picture at the start of its beat reaches up into it, so the raid does not arrive yet;
##   it arrives once the camera is off all of it.
func _test_the_neighbor_and_the_raid_wait_until_nothing_of_them_shows(t) -> void:
	var saved_scars := GameState.attempt_spend.scars.duplicate(true)
	for joystick: bool in [false, true]:
		var scheme := "joystick" if joystick else "tap"
		GameState.attempt_spend.scars.clear()
		_build_city(t)
		_with_clean_run(func() -> void:
			var events := _city.events
			var away := func() -> void:
				events.visible_view().look(Rect2(Vector2(-4000.0, -4000.0),
						Tuning.VIEW_HALF_EXTENT * 2.0), TouchControls.covered_screen() if joystick else null)

			var late := _director_on_the_neighbor(t)
			late.set_sight(events.sees)
			var walker := late._rider
			t.check(walker != null, "%s scheme: the neighbor is walking home" % scheme)
			if walker:
				walker.transition(EventInstance.Phase.PARKED)
				away.call()
				late.tick(STEP)
				t.check(late._taken_neighbor == walker,
						"%s scheme: reaching the door first, they are to be taken" % scheme)
				var feet := walker.global_position
				var view_at := feet - Vector2(Tuning.VIEW_HALF_EXTENT.x,
						Tuning.VIEW_HALF_EXTENT.y * 2.0 + 2.0)
				events.visible_view().look(Rect2(view_at, Tuning.VIEW_HALF_EXTENT * 2.0), TouchControls.covered_screen() if joystick else null)
				var box := EventFootprints.box_of(walker.def)
				t.check(not events.on_screen(feet)
						and events.sees(feet + Vector2(0.0, box.position.y * 0.5)),
						"%s scheme: their feet are just below the view, their figure in it" % scheme)
				late.tick(STEP)
				t.check(late._taken_neighbor == walker and not walker.is_finished,
						"%s scheme: with their figure on screen, the neighbor is not taken" % scheme)
				away.call()
				late.tick(STEP)
				t.check(late._taken_neighbor == null,
						"%s scheme: once the camera is off them, they are taken" % scheme)
			late.free()

			GameState.resistance.completed_steps = []
			GameState.resistance.failed_steps = []
			var director := _director_on_the_neighbor(t)
			director.set_sight(events.sees)
			var happenings := director._happenings
			var door := _city.map.doorstep_world_position()
			var player := _rig_player(t, door + Vector2(0.0, Tuning.OUT_OF_SIGHT + 64.0))
			director.use_player(player)
			player.add_to_group("player")
			t.check(happenings._raid_beat.size() == 2 and happenings._raid_vans.size() == 2,
					"%s scheme: the raid has its vans and a beat at her building" % scheme)
			if happenings._raid_beat.size() == 2:
				var top := INF
				for at: Vector2 in Array(happenings._raid_vans) + Array(happenings._raid_beat):
					top = minf(top, at.y)
				var view := Rect2(Vector2(door.x - Tuning.VIEW_HALF_EXTENT.x,
						top - 2.0 - Tuning.VIEW_HALF_EXTENT.y * 2.0), Tuning.VIEW_HALF_EXTENT * 2.0)
				events.visible_view().look(view, TouchControls.covered_screen() if joystick else null)
				var car := EventFootprints.box_of(EventCatalogue.by_id("police_patrol"))
				var start: Vector2 = happenings._raid_beat[0]
				var any_feet := false
				for at: Vector2 in Array(happenings._raid_vans) + Array(happenings._raid_beat):
					any_feet = any_feet or events.on_screen(at)
				t.check(not any_feet and view.intersects(Rect2(start + car.position, car.size)),
						"%s scheme: no feet of the raid are in view, the car's picture is" % scheme)
				director.tick(STEP)
				t.check(happenings.raid.is_empty(),
						"%s scheme: the raid waits while the car would be drawn in view" % scheme)
				away.call()
				director.tick(STEP)
				t.check(happenings.raid.size() == 3,
						"%s scheme: off camera, the raid arrives (%d)" % [scheme, happenings.raid.size()])
				for instance in happenings.raid:
					_city.events.retire(instance)
			player.free()
			director.free())
	GameState.attempt_spend.scars = saved_scars

## The other half of the same rule: near enough, for long enough, that walking away is a choice.
func _test_a_mark_seen_for_the_dwell_time_within_range_never_moves_again(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var mark_at := director.contact_position()
		_look_at(Rect2(-1.0e6, -1.0e6, 2.0e6, 2.0e6))
		director.set_sight(_city.events.sees)

		# Within SEEN_DISTANCE the whole time, never merely "on screen".
		var near_at := mark_at + Vector2(ResistanceDirector.SEEN_DISTANCE - 20.0, 0.0)
		var player := _rig_player(t, near_at)
		director.use_player(player)

		# One frame short of the dwell window: not seen yet.
		director.tick(ResistanceDirector.SEEN_DWELL_SECONDS - STEP)
		t.check(director.contact_position().distance_to(mark_at) < 0.5,
				"within SEEN_DISTANCE the whole time, so it has not moved regardless of being seen yet")

		# The dwell completes on this frame.
		director.tick(STEP)

		# Walk her far away — seen does not chase, but it also does not relocate any more.
		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, mark_at)
		t.check(far_alley != Vector2.INF, "the test city has an alley far from the mark")
		player.global_position = far_alley
		director.tick(STEP)
		t.check(director.contact_position().distance_to(mark_at) < 0.5,
				"seen after the dwell window completes, so it stays put however far she walks after")

		player.free()
		director.free())

# M177: "a mark does not return to an alley a step was already taken from while another is
# within reach." Day 6 of playtest 116's own run put step 3's mark back on the exact alley step 1
# had been completed at on day 4 — the same rule, exercised here over the new day numbering.
