@warning_ignore_start("untyped_declaration")
extends "res://tests/resistance_rig.gd"
## The resistance director's re-placement: an unseen mark moving to an alley she comes near, and what a relocation may never do.

## Every test that needs a city builds its own, in a run of its own (`_build_city_in_a_new_run()`),
## and sets on that run what the day it asks about needs; none reads what another left. A mark is
## read off the street (`ResistanceDirector.contact_position()`), the neighbor and the raid off the
## street (the raid's instances among the live ones),
## and what the director did on a tick off the run's trace (`RunTrace.recording()`). Where a test asks
## a relocation of many tiles, each is her stroller set down and one tick (`_relocate_round()`), the
## mark and its guard read off the street.
func run(t: TestRunner) -> void:
	_test_an_unseen_mark_moves_to_the_nearest_alley_she_comes_near(t)
	_test_a_mark_within_notice_radius_does_not_move(t)
	_test_an_onscreen_but_far_mark_is_not_seen_and_still_relocates(t)
	_test_a_relocated_mark_never_lands_where_she_can_see_it_appear(t)
	_test_the_siting_reads_the_days_region_off_the_streets(t)
	_test_a_guard_never_lands_within_his_own_reach_of_her(t)
	_test_a_relocated_mark_and_its_guard_are_placed_off_screen(t)
	_test_a_mark_seen_for_the_dwell_time_within_range_never_moves_again(t)
	_test_a_mark_under_a_covered_corner_is_not_noticed(t)
	_test_nothing_appears_under_a_covered_corner(t)
	_test_the_neighbor_is_not_taken_under_a_covered_corner(t)
	_test_the_neighbor_waits_until_none_of_their_figure_shows(t)
	_test_the_raid_waits_until_none_of_it_would_be_drawn(t)
	_free_city()

## Day 6 in a city of a run of its own, its director started and the mark placed.
func _on_day_six(t: TestRunner) -> ResistanceDirector:
	_build_city_in_a_new_run(t)
	var director := _director(t)
	director.start_day(6, _rng(6, "resistance"), 300.0)
	return director

func _said(lines: Array[String], text: String) -> bool:
	for line in lines:
		if line.contains(text):
			return true
	return false

func _test_an_unseen_mark_moves_to_the_nearest_alley_she_comes_near(t: TestRunner) -> void:
	var director := _on_day_six(t)
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
	director.free()

## The mark is pinned (`ResistanceDirector.start_recipe_task()`, a scene's own mark) on a mark tile
## within `NOTICE_RADIUS` of another mark tile where she stands, so "there really is a nearer alley
## on offer" holds by construction rather than by the luck of which tile the day's RNG chose:
## she stands exactly on `nearer`, which is nearer to her than the mark is by definition, and
## still within `NOTICE_RADIUS` of it. A city with no such pair fails the test.
func _test_a_mark_within_notice_radius_does_not_move(t: TestRunner) -> void:
	_build_city_in_a_new_run(t)
	var map := _city.map
	var marks: Array[Vector2i] = []
	for tile in _through_alleys():
		if _is_one_in_from_a_mouth(map, tile):
			marks.append(tile)
	var director: ResistanceDirector = null
	var player_at := Vector2.INF
	var mark_at := Vector2.INF
	for other in marks:
		for nearer in marks:
			if other == nearer or map.tile_to_world(nearer).distance_to(map.tile_to_world(other)) \
					> ResistanceDirector.NOTICE_RADIUS:
				continue
			var attempt := _director(t)
			if attempt.start_recipe_task(6, _rng(6, "resistance"), 300.0,
					map.tile_to_world(other)).is_empty():
				director = attempt
				player_at = map.tile_to_world(nearer)
				mark_at = map.tile_to_world(other)
				break
			attempt.free()
		if director != null:
			break
	t.check(director != null, "the test city has two mark tiles close enough to test this")
	if director == null:
		return
	t.check(director.contact_position().distance_to(mark_at) < 0.5, "the mark stands where it was pinned")
	var player := _rig_player(t, player_at)
	director.use_player(player)

	director.tick(STEP)
	t.check(director.contact_position().distance_to(mark_at) < 0.5,
			"within NOTICE_RADIUS of her own mark, nothing moves — not even to a nearer alley")

	player.free()
	director.free()

## M177, playtest 116's own day-6 shape: a mark on offer at (24,149), on screen from the doorstep
## at (80,84) — fifteen tiles away — moved to (65,83) two seconds in and was marked *seen* 0.4s
## later, so a fifteen-tile-distant alley froze it for the rest of the day. Both of the director's
## view (`_sight` for the notice, the siting's `DRAWING_OFF_THE_VIEW` for placing) answering true near `mark_at`
## alone reproduces "on screen" there without a viewport, while leaving
## `far_alley` — the relocation target, over `NOTICE_RADIUS` away — answering false, the ground
## a relocation needs to still offer a candidate (never a tile she can currently
## see, brisk-wombat's "the mark and its robber never appear in front of her"); standing
## at `far_alley` (beyond `NOTICE_RADIUS`, so certainly beyond the far narrower `SEEN_DISTANCE`)
## reproduces the distance. A single frame is enough to show the old bug is gone: the old rule
## pinned the mark on this exact frame, and the new one still relocates it.
func _test_an_onscreen_but_far_mark_is_not_seen_and_still_relocates(t: TestRunner) -> void:
	var director := _on_day_six(t)
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
	director.free()

## **The siting the director relocates by reads today's region off the city's streets**: the city
## hands its spawn siting the region its `DayStreets` derives (`City.streets()`), and the director
## is handed that siting, so a relocation keeps clear of the day's wall and doors. How the region is
## built and handed again is `tests/test_day_streets.gd`'s.
func _test_the_siting_reads_the_days_region_off_the_streets(t: TestRunner) -> void:
	_build_city_in_a_new_run(t)
	var state := CityState.new()
	state.begin_day(_city.map.block_plans, 10)
	_city.start_day(state, 10, RandomNumberGenerator.new())
	var region := _city.streets().siting_region()
	t.check(region != null and region.centres.size() > 0, "day 10 has a region wall and doors")
	t.check(_city.spawn_siting.region() == region,
			"the city's spawn siting hands out the region its streets derive")

## brisk-wombat, "the mark and its robber never appear in front of her" — the mark's own half:
## *"I just had one appear out of nowhere while I was walking through an alley."* The search for
## the alley she has come near is, by construction, wherever she is standing or right beside it,
## which is on screen more often than not, so it has to actively refuse whatever the siting calls
## on screen rather than pick the plain nearest blind. A first city, with nothing on screen,
## relocates the mark to the plain-nearest alley — the one she stands on; hiding only that one
## tile, in a second city of the same seed, is what makes the assertion below discriminate the
## refusal: the search has to find some other candidate still in `NOTICE_RADIUS` rather than the
## one nearest tile it would otherwise answer.
func _test_a_relocated_mark_never_lands_where_she_can_see_it_appear(t: TestRunner) -> void:
	var probe := _on_day_six(t)
	var old_at := probe.contact_position()
	var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, old_at)
	t.check(far_alley != Vector2.INF, "the test city has an alley far from the mark")
	var probe_player := _rig_player(t, far_alley)
	probe.use_player(probe_player)
	probe.tick(STEP)
	var raw_nearest := probe.contact_position()
	t.check(raw_nearest.distance_to(far_alley) < 0.5,
			"with no screen test at all, the nearest reachable alley is the one she stands on")
	probe_player.free()
	probe.free()

	var director := _on_day_six(t)
	t.check(director.contact_position().distance_to(old_at) < 0.5,
			"the same seed puts the mark in the same place")
	var player := _rig_player(t, far_alley)
	director.use_player(player)
	_look_at(Rect2(raw_nearest - Vector2(0.5, 0.5), Vector2.ONE))
	director.set_sight(_city.events.sees)

	director.tick(STEP)
	var new_at := director.contact_position()
	t.check(new_at.distance_to(old_at) > 0.5, "the mark actually moved")
	t.check(new_at.distance_to(raw_nearest) > 0.5,
			"but never to the one tile she could see it appear on")

	player.free()
	director.free()

## brisk-wombat's other half: *"a robber also appeared out of nowhere and instakilled me."* A
## guard's own spot is worked out from the mark alone, with no idea where she is standing, so a mark
## relocating right up to where she stands could put him inside his own `EventDef.notice`, or worse
## `inner_radius` (a `hard_fail` with no warning), of wherever she actually is unless his placement
## also refuses that. Read off the street over every mark tile of `SWEEP_SEEDS`' cities, each
## relocated onto with her standing on it (`_relocations_over_the_marks()`) — the closest a real
## guard's own spot ever gets to her.
func _test_a_guard_never_lands_within_his_own_reach_of_her(t: TestRunner) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var checked := 0
	for seed_value in SWEEP_SEEDS:
		for entry in _relocations_over_the_marks(t, seed_value, _on_the_tile):
			var guard_at: Vector2 = entry.guard
			var her: Vector2 = entry.her
			if entry.mark == Vector2.INF or guard_at == Vector2.INF:
				continue
			checked += 1
			t.check(guard_at.distance_to(her) > robbery.notice_within(),
					"seed %d: the guard for the mark at %s never lands within his own reach of her"
					% [seed_value, entry.tile])
	t.check(checked > 0, "some guarded mark was actually checked (%d)" % checked)

## brisk-wombat, both halves: *"I just had one appear out of nowhere while I was walking through an
## alley and then a robber also appeared out of nowhere and instakilled me."* She stands on every
## other through-alley tile of two cities; the screen is the unrotated 640x360 world px around her
## (`Tuning.VIEW_HALF_EXTENT`), the day's view looked there. Wherever the tick relocates the mark
## (`_relocate_round()`), no part of its 32px picture is on that screen, and the guard it stands for
## it, read off the street, exists and shows no part of his 22x44px body on it either. (The guard
## the roadblock's task sets when she reads its mark, out of her view too, is
## `tests/test_day13_guard.gd`'s, on the real day 13.)
## Every box is measured here from the screen's own edges rather than through the director's
## siting, so the test does not ask the code whether the code is right.
func _test_a_relocated_mark_and_its_guard_are_placed_off_screen(t: TestRunner) -> void:
	var relocations := 0
	for seed_value in [4242, 555555]:
		var run := _build_city_in_a_new_run(t, seed_value)
		run.resistance.completed_steps = _completed_through(2)
		var map := _city.map
		var director := _director(t)
		director.start_day(7, _rng(7, "off-screen", seed_value), 300.0)
		var player := _rig_player(t, director.contact_position())
		director.use_player(player)
		var away: Array[Vector2] = []
		for tile in _mark_tiles():
			away.append(map.tile_to_world(tile))
		var through := _through_alley_tiles(map)
		for i in range(0, through.size(), 2):
			var her := map.tile_to_world(through[i])
			_look_at(Rect2(her - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0))
			var guards_before := _live(EventCatalogue.mark_guard().id)
			var mark := _relocate_round(director, player, her, away)
			if mark == Vector2.INF:
				continue
			relocations += 1
			t.check(not _box_on_screen(mark, Vector2(16.0, 16.0), her),
					"seed %d: from %s, no part of the relocated mark at %s is on screen"
					% [seed_value, through[i], map.world_to_tile(mark)])
			var guard := _new_one(EventCatalogue.mark_guard().id, guards_before)
			t.check(guard != null, "seed %d: the mark relocated to %s is guarded"
					% [seed_value, map.world_to_tile(mark)])
			if guard != null:
				t.check(not _box_on_screen(guard.global_position + Vector2(0.0, -22.0),
						Vector2(11.0, 22.0), her),
						"seed %d: from %s, no part of the relocated mark's guard at %s is on screen"
						% [seed_value, through[i], map.world_to_tile(guard.global_position)])
		_look_at(Rect2())
		player.free()
		director.free()
	t.check(relocations > 0, "marks were relocated (%d)" % relocations)

## Whether a box `half` either side of `centre` overlaps the unrotated screen around `her`.
func _box_on_screen(centre: Vector2, half: Vector2, her: Vector2) -> bool:
	return absf(centre.x - her.x) <= Tuning.VIEW_HALF_EXTENT.x + half.x \
			and absf(centre.y - her.y) <= Tuning.VIEW_HALF_EXTENT.y + half.y

## **A mark under a corner the joystick's controls cover is not in sight**, so its dwell does not run
## (dappled-swan, inbox #581: "use that everywhere where visibility is concerned -- for the other
## mode those rectangles *do* count"). She stands within `SEEN_DISTANCE` of the mark with it down and
## to her left, under the left corner, for longer than `SEEN_DWELL_SECONDS`, asked through the day's
## own visible area as `main` wires it. Whether the dwell ran is read from what it decides: a mark
## that was seen never moves again, however far she then walks, and one that was not follows her to
## the alley she comes near. In the joystick scheme it is not noticed and moves; in the tap scheme
## it is and stays.
func _test_a_mark_under_a_covered_corner_is_not_noticed(t: TestRunner) -> void:
	for joystick: bool in [true, false]:
		var scheme := "joystick" if joystick else "tap"
		var director := _on_day_six(t)
		var mark_at := director.contact_position()
		# Camera look-ahead puts this nearby mark beneath the narrower focal-disc corner.
		# Keep her within the 150px notice distance independently of the camera centre.
		var her := mark_at + Vector2(135.0, -50.0)
		var view := VisibleView.around(her + Vector2(45.0, 0.0), TouchCover.joystick() if joystick else null)
		t.check(view.sees(mark_at) != joystick,
				"the actual camera view covers the mark only in joystick mode")
		_city.events.visible_view().look(view.view, TouchCover.joystick() if joystick else null)
		director.set_sight(_city.events.sees)
		var player := _rig_player(t, her)
		director.use_player(player)
		for i in ceili((ResistanceDirector.SEEN_DWELL_SECONDS + 0.5) / STEP):
			director.tick(STEP)
		t.check(mark_at.distance_to(her) <= ResistanceDirector.SEEN_DISTANCE,
				"%s scheme: a mark %.0fpx off under the left corner" % [scheme, mark_at.distance_to(her)])
		t.check(director.contact_position().distance_to(mark_at) < 0.5,
				"%s scheme: she has not left it, so it has not moved" % scheme)
		# She walks to a far alley with the camera off the old mark.
		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, mark_at)
		t.check(far_alley != Vector2.INF, "%s scheme: the test city has an alley far from the mark" % scheme)
		_look_at(Rect2(Vector2(-4000.0, -4000.0), Tuning.VIEW_HALF_EXTENT * 2.0))
		player.global_position = far_alley
		director.tick(STEP)
		var moved := director.contact_position().distance_to(mark_at) > 0.5
		t.check(moved == joystick,
				"%s scheme: a mark %.0fpx off under the left corner is %s"
				% [scheme, mark_at.distance_to(her),
				"not noticed (it follows her)" if joystick else "noticed (it stays)"])
		player.free()
		director.free()

## **Nothing the resistance places appears under a covered corner** *(olive-hedgehog, inbox #598, the
## player: "off screen is not the same as visible -- the corners get removed for visible not for
## off screen" · "I don't want any pop in")*. Joystick scheme, asked through the day's own view as
## `main` wires it (`EventManager.sees()` for the notice, `EventManager.on_screen()` for placing):
## **a relocation to a mouth under the bottom-left corner is refused.** For each mark tile of the
## test city, its mark's picture laid at several places inside the corner, she stands where the view
## would put it there; a case is kept where, with the view nowhere near, her tick moves the mark onto
## that tile (`_relocate_round()`: it is the nearest legal tile within `NOTICE_RADIUS`), and where
## the visible area alone would not refuse it (its guard's spot is under the corner or out of the
## view too) — the case `main`'s wiring has to refuse: with the view looked there, her tick never
## moves the mark onto that tile.
func _test_nothing_appears_under_a_covered_corner(t: TestRunner) -> void:
	var director := _on_day_six(t)
	var events := _city.events
	var player := _rig_player(t, director.contact_position())
	director.use_player(player)
	director.set_sight(events.sees)
	var scale := Tuning.VIEW_HALF_EXTENT * 2.0 / ScreenOrientation.DESIGN_SIZE
	var corner := TouchCover.joystick().left
	var corner_at := corner.position * scale
	var corner_size := corner.size * scale
	var away: Array[Vector2] = []
	for tile in _mark_tiles():
		away.append(_city.map.tile_to_world(tile))
	var nowhere := Rect2(Vector2(-4000.0, -4000.0), Tuning.VIEW_HALF_EXTENT * 2.0)
	var refused := 0
	for tile: Vector2i in _mark_tiles():
		var mark := _city.map.tile_to_world(tile)
		# The mark's centre at these shares of the corner, its whole picture inside it.
		for share: Vector2 in [Vector2(0.2, 0.8), Vector2(0.5, 0.5), Vector2(0.8, 0.8),
				Vector2(0.2, 0.2), Vector2(0.8, 0.2)]:
			var view_at := mark - corner_at - share * corner_size
			var her := view_at + Tuning.VIEW_HALF_EXTENT
			# With the view nowhere near, the mark moves onto this tile.
			events.visible_view().look(nowhere, TouchCover.joystick())
			if _relocate_round(director, player, her, away).distance_to(mark) > 0.5:
				continue
			events.visible_view().look(Rect2(view_at, Tuning.VIEW_HALF_EXTENT * 2.0), TouchCover.joystick())
			# Only a mouth the visible area alone would not refuse (its picture and its
			# guard's body, each laid at its centre and four corners, all unseen under the
			# covered corner or out of the view) is a case the whole view has to refuse.
			var seen_by_the_visible_area := false
			for box_at: Array in [[ResistanceDirector.MARK_BOX, mark],
					[ResistanceDirector.GUARD_BOX, _guard_spot_of(_city.map, mark)]]:
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
			var moved := _relocate_round(director, player, her, away)
			t.check(moved.distance_to(mark) > 0.5,
					"the alley mouth %s under the covered corner is refused (%s of it)"
					% [tile, share])
	t.check(refused > 0, "relocations under the covered corner were asked (%d)" % refused)
	events.visible_view().look(Rect2(), null)
	player.free()
	director.free()

## **The neighbor taken with the raid stays while they stand under the covered corner**, and is taken
## once the camera is off them (olive-hedgehog, inbox #598). Read off the run's trace: the neighbor
## reaching the door first is expired, and taken only once the whole of their drawing is out of the
## view, covered corner included.
func _test_the_neighbor_is_not_taken_under_a_covered_corner(t: TestRunner) -> void:
	_build_city_in_a_new_run(t)
	var events := _city.events
	var scale := Tuning.VIEW_HALF_EXTENT * 2.0 / ScreenOrientation.DESIGN_SIZE
	var corner := TouchCover.joystick().left
	var corner_at := corner.position * scale
	var corner_size := corner.size * scale
	var late := _director_on_the_neighbor(t)
	var lines: Array[String] = []
	late.trace = RunTrace.recording(lines)
	var walker := late.rider()
	t.check(walker != null, "the neighbor is walking home")
	if walker:
		walker.transition(EventInstance.Phase.PARKED)
		late.tick(STEP)
		t.check(_said(lines, "the neighbor walked home into the vans"),
				"reaching the door first, they are to be taken")
		var at := walker.global_position
		var view_at := at - corner_at - corner_size * 0.5
		events.visible_view().look(Rect2(view_at, Tuning.VIEW_HALF_EXTENT * 2.0), TouchCover.joystick())
		t.check(events.on_screen(at) and not events.sees(at),
				"the neighbor stands in the view, under the covered corner")
		late.set_sight(events.sees)
		late.tick(STEP)
		t.check(not _said(lines, "taken with the raid") and is_instance_valid(walker)
				and not walker.is_finished,
				"under the covered corner, the neighbor is not taken where they are drawn")
		events.visible_view().look(Rect2(at + Vector2(Tuning.VIEW_HALF_EXTENT.x * 4.0, 0.0),
				Tuning.VIEW_HALF_EXTENT * 2.0), TouchCover.joystick())
		late.tick(STEP)
		t.check(_said(lines, "the neighbor is taken with the raid") and walker.is_finished,
				"once the camera is off them, they are taken")
	late.free()

## **The taken neighbor stays while any of their figure is in view** *(olive-hedgehog, inbox #598:
## "I don't want any pop in")*, in either scheme and through the day's own view as `main` wires it.
## Their feet just below the view's bottom edge leave their picture, which stands above them, on
## screen; they are taken once the camera is off them.
func _test_the_neighbor_waits_until_none_of_their_figure_shows(t: TestRunner) -> void:
	for joystick: bool in [false, true]:
		var scheme := "joystick" if joystick else "tap"
		_build_city_in_a_new_run(t)
		var events := _city.events
		var covered: Variant = TouchCover.joystick() if joystick else null
		var late := _director_on_the_neighbor(t)
		var lines: Array[String] = []
		late.trace = RunTrace.recording(lines)
		late.set_sight(events.sees)
		var walker := late.rider()
		t.check(walker != null, "%s scheme: the neighbor is walking home" % scheme)
		if walker:
			walker.transition(EventInstance.Phase.PARKED)
			events.visible_view().look(Rect2(Vector2(-4000.0, -4000.0),
					Tuning.VIEW_HALF_EXTENT * 2.0), covered)
			late.tick(STEP)
			t.check(_said(lines, "the neighbor walked home into the vans"),
					"%s scheme: reaching the door first, they are to be taken" % scheme)
			var feet := walker.global_position
			var view_at := feet - Vector2(Tuning.VIEW_HALF_EXTENT.x,
					Tuning.VIEW_HALF_EXTENT.y * 2.0 + 2.0)
			events.visible_view().look(Rect2(view_at, Tuning.VIEW_HALF_EXTENT * 2.0), covered)
			var box := EventFootprints.box_of(walker.def)
			t.check(not events.on_screen(feet)
					and events.sees(feet + Vector2(0.0, box.position.y * 0.5)),
					"%s scheme: their feet are just below the view, their figure in it" % scheme)
			late.tick(STEP)
			t.check(not _said(lines, "taken with the raid") and not walker.is_finished,
					"%s scheme: with their figure on screen, the neighbor is not taken" % scheme)
			events.visible_view().look(Rect2(Vector2(-4000.0, -4000.0),
					Tuning.VIEW_HALF_EXTENT * 2.0), covered)
			late.tick(STEP)
			t.check(_said(lines, "the neighbor is taken with the raid") and walker.is_finished,
					"%s scheme: once the camera is off them, they are taken" % scheme)
		late.free()

## **Day 10's raid waits while any of it would be drawn in view** *(olive-hedgehog, inbox #598)*,
## in either scheme and through the day's own view as `main` wires it. With the view's bottom edge
## just above the patrol car's lane every van's and every beat point's feet are out of it, but the
## car's picture at the start of its beat reaches up into it, so the raid does not arrive yet; it
## arrives once the camera is off all of it. The happenings are the day's own
## (`ResistanceHappenings.start_day()`), ticked with her far from her door.
func _test_the_raid_waits_until_none_of_it_would_be_drawn(t: TestRunner) -> void:
	for joystick: bool in [false, true]:
		var scheme := "joystick" if joystick else "tap"
		_build_city_in_a_new_run(t)
		var events := _city.events
		var covered: Variant = TouchCover.joystick() if joystick else null
		var day := ResistanceHappenings.NEIGHBOR_DAY
		var state := CityState.new()
		state.begin_day(_city.map.block_plans, day)
		_city.start_day(state, day, _rng(day, "closures"))
		events.start_day(DaySpec.for_day(day), _rng(day, "events"), [], _city.map.doorstep_world_position())
		var door := _city.map.doorstep_world_position()
		var her := door + Vector2(0.0, Tuning.OUT_OF_SIGHT + 64.0)
		# Where the raid stands is read off a first arrival with the camera nowhere near: the
		# vans' feet and the patrol car's beat (`EventInstance.path`), which are put in the
		# street and then taken out again before the raid this test waits for.
		var scout := ResistanceHappenings.new()
		scout.setup(_city.map, _city.run, _city.events, _city.streets(), _city.fronts(), _city,
				_city.atlas, null, _city.spawn_siting)
		scout.start_day(day)
		events.visible_view().look(Rect2(Vector2(-4000.0, -4000.0),
				Tuning.VIEW_HALF_EXTENT * 2.0), covered)
		var before := _street()
		scout.tick(STEP, her, Vector2.ZERO)
		var vans := PackedVector2Array()
		var beat := PackedVector2Array()
		for arrived in _raid_since(before):
			if arrived.def.paces:
				beat = arrived.path
			else:
				vans.append(arrived.global_position)
			events.retire(arrived)
		var happenings := ResistanceHappenings.new()
		happenings.setup(_city.map, _city.run, _city.events, _city.streets(), _city.fronts(), _city,
				_city.atlas, null, _city.spawn_siting)
		happenings.start_day(day)
		t.check(beat.size() == 2 and vans.size() == 2,
				"%s scheme: the raid has its vans and a beat at her building" % scheme)
		if beat.size() != 2 or vans.size() != 2:
			continue
		var top := INF
		for at: Vector2 in Array(vans) + Array(beat):
			top = minf(top, at.y)
		var view := Rect2(Vector2(door.x - Tuning.VIEW_HALF_EXTENT.x,
				top - 2.0 - Tuning.VIEW_HALF_EXTENT.y * 2.0), Tuning.VIEW_HALF_EXTENT * 2.0)
		events.visible_view().look(view, covered)
		var car := EventFootprints.box_of(EventCatalogue.by_id("police_patrol"))
		var start: Vector2 = beat[0]
		var any_feet := false
		for at: Vector2 in Array(vans) + Array(beat):
			any_feet = any_feet or events.on_screen(at)
		t.check(not any_feet and view.intersects(Rect2(start + car.position, car.size)),
				"%s scheme: no feet of the raid are in view, the car's picture is" % scheme)
		before = _street()
		happenings.tick(STEP, her, Vector2.ZERO)
		t.check(_raid_since(before).is_empty(),
				"%s scheme: the raid waits while the car would be drawn in view" % scheme)
		events.visible_view().look(Rect2(Vector2(-4000.0, -4000.0),
				Tuning.VIEW_HALF_EXTENT * 2.0), covered)
		happenings.tick(STEP, her, Vector2.ZERO)
		var raid := _raid_since(before)
		t.check(raid.size() == 3,
				"%s scheme: off camera, the raid arrives (%d)" % [scheme, raid.size()])

## The other half of the same rule: near enough, for long enough, that walking away is a choice.
func _test_a_mark_seen_for_the_dwell_time_within_range_never_moves_again(t: TestRunner) -> void:
	var director := _on_day_six(t)
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
	director.free()

# M177: "a mark does not return to an alley a step was already taken from while another is
# within reach." Day 6 of playtest 116's own run put step 3's mark back on the exact alley step 1
# had been completed at on day 4 — the same rule, exercised here over the new day numbering.
