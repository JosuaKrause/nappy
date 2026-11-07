extends "res://tests/resistance_rig.gd"
## The task riding on a look-alike, the guarded targets and the handover traps: a robber or guard set on her from off screen, announced before he can catch her.

## Every test builds its city in a run of its own (`_build_city_in_a_new_run()`): a run with no
## step done, no alley used and no scar, the "no history, just this day" state `--day N` boots
## into, with what the day it asks about needs set on it.
func run(t) -> void:
	t.gives_back_observers()
	_test_a_perform_contact_is_never_relocated(t)
	await _test_the_contact_rides_onto_the_first_look_alike_she_reaches(t)
	await _test_the_step_completes_on_the_look_alike_she_hands_it_to(t)
	_test_a_task_that_rides_on_a_row_stands_unguarded_until_it_is_handed_over(t)
	_test_the_van_task_stands_unguarded_until_it_is_handed_over(t)
	_test_the_roadblock_keeps_a_waiting_guard(t)
	_test_every_guarded_target_sends_a_robber_from_off_screen(t)
	await _test_the_handover_sets_a_robber_on_her_from_off_screen(t)
	await _test_the_van_handover_sets_a_guard_on_her_from_off_screen(t)
	_test_a_trap_rechecks_the_camera_when_its_warning_expires(t)
	await _test_the_robber_after_her_is_announced_before_he_can_catch_her(t)
	await _test_the_van_guard_after_her_is_announced_before_he_can_catch_her(t)
	_test_the_robber_after_her_is_never_the_schedulers(t)
	_test_the_van_guard_after_her_is_never_the_schedulers(t)
	_free_city()

## Day 7's mark, started and touched — the van's own perform step, active. Mirrors
## `_director_on_the_yeller_perform()` for the one-place task the van's chasing guard rides on.
func _director_on_the_van_perform(t) -> ResistanceDirector:
	var director := _director(t)
	director.start_day(7, _rng(7, "resistance"), 300.0)
	_read_the_mark(director)
	return director

## Ground a look-alike of `step`'s rider stands on, drawn by `rng`: a tile of the kinds the step's
## own task is sited on (`ResistanceSteps.Step.placement`) that a contact may stand on
## (`SpawnSiting.CONTACT_GROUND`, the test city's siting), more than `apart` from every one of
## `others` — the ground the day's scheduler could equally have placed one on. `Vector2.INF` when
## the city has none.
func _look_alike_ground(step: ResistanceSteps.Step, rng: RandomNumberGenerator,
		others: Array[Vector2], apart: float) -> Vector2:
	var siting := _city.spawn_siting
	var ground := siting.ask_of_ground()
	var pool: Array[Vector2] = []
	for type in step.placement:
		for tile in _city.map.tiles_of_type(type as GameEnums.TileType):
			var at := _city.map.tile_to_world(tile)
			if not siting.allows_every(SpawnSiting.CONTACT_GROUND, ground, at):
				continue
			var clear := true
			for other in others:
				if other.distance_to(at) <= apart:
					clear = false
			if clear:
				pool.append(at)
	return pool[rng.randi_range(0, pool.size() - 1)] if not pool.is_empty() else Vector2.INF

func _test_a_perform_contact_is_never_relocated(t) -> void:
	_build_city_in_a_new_run(t)
	var director := _director_on_the_yeller_perform(t)
	t.check(director.current_step() != null and not director.current_step().is_pickup,
			"the yeller perform is active, riding on it rather than sitting on a mark")
	var at := director.contact_position()

	var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, at)
	var player := _rig_player(t, far_alley)
	director.use_player(player)

	director.tick(STEP)
	t.check(director.contact_position().distance_to(at) < 0.5,
			"a perform contact is never subject to the mark's own re-placement rule")

	player.free()
	director.free()

## Overturn, 2026-09-13 (`docs/NARRATIVE.md`, "The contact is whichever look-alike she reaches
## first"): a second live `homeless_yeller` — a look-alike the day's own scheduler could equally
## have placed, spawned directly here rather than through it — stands well clear of the seeded
## rider. She is put within reach of the *decoy* rather than the rider `_begin_step()` rolled, and
## the contact rides onto it instead of waiting for her to find the one it was seeded on.
func _test_the_contact_rides_onto_the_first_look_alike_she_reaches(t) -> void:
	_build_city_in_a_new_run(t)
	var director := _director_on_the_yeller_perform(t)
	var perform := director.current_step()
	t.check(perform != null and perform.index == 2, "the yeller perform is active")
	var seeded_at := director.contact_position()
	var seeded_rider := director.rider()

	var apart := ContactPoint.REACH * 4.0
	var seeded: Array[Vector2] = [seeded_at]
	var decoy_at := _look_alike_ground(perform, _rng(6, "decoy"), seeded, apart)
	t.check(decoy_at.distance_to(seeded_at) > apart,
			"the decoy lands well clear of the seeded rider, or this test checks nothing")
	var decoy := _city.events.spawn_extra(EventCatalogue.by_id("homeless_yeller"), decoy_at)

	var player := _rig_player(t, decoy_at)
	director.use_player(player)
	director.tick(STEP)
	t.check(director.contact_position().distance_to(decoy_at) < 0.5,
			"the contact rides onto the look-alike she actually reached, not the seeded one")
	t.check(director.rider() == decoy and director.rider() != seeded_rider,
			"and the director's own rider is now the decoy")

	var completed: Array[int] = []
	director.contact().completed.connect(func(index: int) -> void: completed.append(index))
	# Step 2's own `completes_at_inner_radius` (M205) still fires on the first frame she is
	# standing on the retargeted contact, exactly as an ordinary REACH-based step would.
	await _step_a_frame(t)
	t.check(completed == [2], "touching the retargeted contact completes step 2 itself")

	player.free()
	director.free()

## *(2026-09-13, PLAYTEST-71: "not the first yeller she reaches but the first yeller she interacts
## with. so the task is always solved by going to any yeller she notices.")* Coming within the
## director's reach of one look-alike moves the contact onto him, and walking on again leaves him
## behind: the step completes on whichever one she then hands the note to. Two look-alikes besides
## the seeded rider, so the first one she comes near is a retarget rather than the rider the step
## already had — a walk that only ever touched the seeded one could pass with the rule deleted.
func _test_the_step_completes_on_the_look_alike_she_hands_it_to(t) -> void:
	_build_city_in_a_new_run(t)
	var director := _director_on_the_yeller_perform(t)
	var perform := director.current_step()
	t.check(perform != null and perform.index == 2, "the yeller perform is active")
	var seeded := director.rider()
	var yeller := EventCatalogue.by_id("homeless_yeller")
	var apart := ContactPoint.REACH * 4.0
	var placed: Array[Vector2] = [seeded.global_position]
	var first_at := _look_alike_ground(perform, _rng(6, "first look-alike"), placed, apart)
	placed.append(first_at)
	var second_at := _look_alike_ground(perform, _rng(6, "second look-alike"), placed, apart)
	t.check(first_at.distance_to(seeded.global_position) > apart
			and second_at.distance_to(seeded.global_position) > apart
			and first_at.distance_to(second_at) > apart,
			"the three look-alikes stand well clear of each other, or this walk checks nothing")
	var first := _city.events.spawn_extra(yeller, first_at)
	var second := _city.events.spawn_extra(yeller, second_at)
	var completed: Array[int] = []
	director.contact().completed.connect(func(index: int) -> void: completed.append(index))

	# Near the first — inside the director's reach of him, outside `ContactPoint.REACH` of the
	# note — so she has come near him without handing it over.
	# A figure with no body is touched from her own body's radius and `ContactPoint.REACH` past it.
	var near := Tuning.PLAYER_BODY_RADIUS + ContactPoint.REACH - 4.0
	t.check(near > ContactPoint.REACH, "there is ground near him that is not the handover")
	var player := _rig_player(t, first_at + Vector2(near, 0.0))
	director.use_player(player)
	director.tick(STEP)
	await _step_a_frame(t)
	t.check(director.rider() == first, "coming near the first look-alike moves the contact onto him")
	t.check(completed.is_empty(), "and nothing is handed over from where she stands")

	# Out again, well clear of all three.
	player.global_position = first_at + Vector2(ResistanceDirector.NOTICE_RADIUS, 0.0)
	director.tick(STEP)
	await _step_a_frame(t)
	t.check(completed.is_empty(), "walking on from him hands nothing over")

	# And onto the second, whom she hands it to.
	player.global_position = second_at
	director.tick(STEP)
	await _step_a_frame(t)
	t.check(completed == [2], "the step completes on the second look-alike, the one she hands it to")
	t.check(director.rider() == second, "whose contact it is")
	# He does not leave the instant she hands it over (M205): he keeps shouting, and charging
	# her, for `NOTE_HANDOVER_LINGER_SECONDS` first.
	t.check(not second.is_leaving and not first.is_leaving and not seeded.is_leaving,
			"nobody leaves the instant she hands it over — he keeps shouting first")
	director.tick(ResistanceDirector.NOTE_HANDOVER_LINGER_SECONDS + STEP)
	t.check(second.is_leaving and not first.is_leaving and not seeded.is_leaving,
			"and once he has lingered that long, he is the one who leaves; the one she walked " +
			"past keeps shouting")

	player.free()
	director.free()

## The man shouting's task is not guarded where it waits: activating the yeller perform stands
## no robber anywhere — the chalk mark's own guard is the only one on the street — and no robber is
## sent after her until she hands it over.
func _test_a_task_that_rides_on_a_row_stands_unguarded_until_it_is_handed_over(t) -> void:
	_check_a_task_stands_unguarded_until_it_is_handed_over(t, 6, "the yeller perform", "robber",
			"the chalk mark is still guarded", "the task")

## The van's task is not guarded where it waits either — the same contract as the man shouting's,
## on a one-place task rather than an any-instance one.
func _test_the_van_task_stands_unguarded_until_it_is_handed_over(t) -> void:
	_check_a_task_stands_unguarded_until_it_is_handed_over(t, 7, "the van perform", "guard",
			"day 7's mark is still guarded", "the van")

## Day `day`'s mark started, its guard read off the street, the mark read: the task it unlocks is
## on offer and sets its trap on her, no robber is added to the street, the one guard is still the
## mark's own and no task guard stands anywhere, and nobody is sent after her — no trap of the
## step's row is warned of or in the street.
func _check_a_task_stands_unguarded_until_it_is_handed_over(t, day: int, perform: String,
		who: String, mark_guarded: String, at: String) -> void:
	_build_city_in_a_new_run(t)
	var director := _director(t)
	var mark_guards := _live(EventCatalogue.mark_guard().id)
	director.start_day(day, _rng(day, "resistance"), 300.0)
	var mark_guard := _new_one(EventCatalogue.mark_guard().id, mark_guards)
	t.check(mark_guard != null, mark_guarded)
	var robbers_before := _robbers_on_the_street()
	var task_guards := _live(EventCatalogue.task_guard().id)
	_read_the_mark(director)
	var task := director.current_step()
	t.check(task != null and task.index == 2 * (day - 6) + 2, "%s is active" % perform)
	t.check(_robbers_on_the_street() == robbers_before,
			"activating it stands no %s at %s (%d before, %d after)"
			% [who, at, robbers_before, _robbers_on_the_street()])
	t.check(mark_guard != null and not mark_guard.is_finished
			and _new_one(EventCatalogue.task_guard().id, task_guards) == null,
			"the only guard is still the mark's own")
	var trap_row := task.trap_row if task else "robber_giving_chase"
	t.check(_live(trap_row).is_empty() and _warning_for(_city.events, trap_row) == null,
			"and nobody is sent after her before the handover")
	director.free()

## *(grassy-goose, inbox #556, asked which tasks switch to a robber arriving off screen: "Every
## guarded target (Recommended)", the option that keeps the roadblock's own guard.)* The roadblock
## is guarded exactly where it waits, like a chalk mark, and touching it sends nobody after her.
func _test_the_roadblock_keeps_a_waiting_guard(t) -> void:
	_build_city_in_a_new_run(t)
	var mark_row := EventCatalogue.mark_guard().id
	var task_row := EventCatalogue.task_guard().id
	var director := _director(t)
	var mark_guards := _live(mark_row)
	director.start_day(13, _rng(13, "resistance"), 300.0)
	var mark_guard := _new_one(mark_row, mark_guards)
	var task_guards := _live(task_row)
	_read_the_mark(director)
	var task_guard := _new_one(task_row, task_guards)
	var step := director.current_step()
	t.check(step != null and step.index == 16, "the roadblock perform is active")
	# feathery-marmot: a roadblock is touched from any side of its band, so its guard's band is
	# measured from the band's own centre with the whole of that touch — never nearer it than his
	# catch past the furthest point she can touch it from.
	var robbery := EventCatalogue.by_id("alley_robbery")
	var rider := director.rider()
	if rider and task_guard:
		var touched_within := rider.def.solid_reach() + Tuning.PLAYER_BODY_RADIUS \
				+ ContactPoint.REACH
		var from_body := task_guard.global_position.distance_to(rider.body_position())
		t.check(from_body >= robbery.inner_radius + touched_within - 0.5,
				("the roadblock's guard stands %.0fpx from its band's centre, outside his catch " +
				"of everywhere it is touched from (%.0fpx)")
				% [from_body, robbery.inner_radius + touched_within])
	t.check(task_guard != null and is_instance_valid(task_guard),
			"it is guarded where it waits, like a mark, with its own fresh guard")
	if mark_guard:
		t.check(mark_guard in _live(mark_row) and not mark_guard.is_finished,
				"and the mark's own guard stays untouched, not retired for it")
		t.check(task_guard != mark_guard,
				"the perform's own guard is a distinct instance from the mark's")
	director.contact().complete_now()
	t.check(_live(step.trap_row).is_empty() and _warning_for(_city.events, step.trap_row) == null,
			"and touching it sends nobody after her")
	director.free()

## *(grassy-goose, inbox #556: "the robber should spawn in off-screen already pursuing when I touch
## the goal"; asked which tasks: "Every guarded target (Recommended)".)* The burnt building's door
## (day 8), the district door (day 9), a mast's foot (day 11), the swing (day 12) and the last
## night's front door: no robber waits at any of them — activating the task, or offering the last
## night's at dawn, adds none to the street — and doing it sends `robber_giving_chase` from off
## screen on the same terms as the man shouting's note, checked on each target's own ground (a
## door on a facade, a crossing in a region wall, a mast's foot, a swing in a park, the station's
## door): warned first, then just off screen, on legal ground, with a way at her that
## never runs through a district door, awake from his first frame, and catching her where she stands
## if she does nothing. Day 9's is measured from where the inspection lets her out, 54px past the
## door's line beside the gatehouse that held her, on each side in turn
## (`CheckpointController._release_finished_holds()`), since that is where she stands when it
## sends him. Planned through the real day order (`City.start_day()`, then the events), since the
## door, the mast and the station's door are today's own plans.
func _test_every_guarded_target_sends_a_robber_from_off_screen(t) -> void:
	for day: int in [8, 9, 11, 12, Tuning.RUN_LENGTH_DAYS]:
		var started := _start_a_guarded_target_day(t, day)
		var director: ResistanceDirector = started[0]
		var before: int = started[1]
		var mark_guard: EventInstance = started[2]
		var task := director.current_step()
		t.check(task != null and not task.is_pickup,
				"day %d: the task is on offer" % day)
		if task == null:
			director.free()
			continue
		var marks_guard := 1 if mark_guard else 0
		t.check(_live(EventCatalogue.task_guard().id).is_empty()
				and _robbers_on_the_street() == before + marks_guard,
				"day %d: no robber waits at the task (%d before dawn, %d now, the mark's %d)"
				% [day, before, _robbers_on_the_street(), marks_guard])
		t.check(_live(task.trap_row).is_empty(), "day %d: nobody is sent before she does it" % day)

		var front_door := task.target_kind == ResistanceSteps.TargetKind.STATION_DOOR \
				or task.at_a_front_door
		if day == 9:
			_check_day_nines_trap_from_where_she_is_let_out(t, director)
			continue
		# A door on a facade (the burnt building's, the station's) stands on the building's own
		# ground-floor tile, which nobody can stand on: she touches it from the sidewalk tile
		# straight below, inside its `DOOR_REACH`.
		var her := director.contact_position()
		if not _city.map.is_walkable(_city.map.world_to_tile(her)):
			her += Vector2(0.0, Tuning.TILE_SIZE)
		t.check(_city.map.is_walkable(_city.map.world_to_tile(her))
				and her.distance_to(director.contact_position()) <= director.contact().reach,
				"day %d: she stands on open ground within the touch's reach" % day)
		_watch_the_screen_round(director, her)
		var player := _rig_player(t, her)
		director.use_player(player)
		director.contact().complete_now()
		_check_the_trap_comes_from_off_screen(t, her, "robber_giving_chase",
				"day %d" % day, front_door)
		player.free()
		director.free()

## Day `day` of a guarded target, in a city of a run of its own, through the real day order
## (`City.start_day()`, then the events): the steps before it done (every one but the finale's on
## the last night, with the goal met), the director started, and a mark, when the day offers one,
## read with nobody in the world. `[director, the robbers in the street before it started, the
## guard the mark set or null]`.
func _start_a_guarded_target_day(t, day: int) -> Array:
	var run := _build_city_in_a_new_run(t)
	run.header.day = day
	var finale := day == Tuning.RUN_LENGTH_DAYS
	run.resistance.completed_steps = _all_but_the_finale() if finale \
			else _completed_through(2 * (day - 6))
	run.resistance.progress = Tuning.RESISTANCE_GOAL if finale else 0
	var state := CityState.new()
	run.attempt_spend.city_state = state
	state.begin_day(_city.map.block_plans, day)
	_city.start_day(state, day, _rng(day, "closures"))
	_city.events.start_day(DaySpec.for_day(day), _rng(day, "events"), [], _city.map.doorstep_world_position())
	var before := _robbers_on_the_street()
	var director := _director(t)
	var mark_guards := _live(EventCatalogue.mark_guard().id)
	director.start_day(day, _rng(day, "resistance"), 300.0)
	var mark_guard := _new_one(EventCatalogue.mark_guard().id, mark_guards)
	var offered := director.current_step()
	if offered and offered.is_pickup:
		_read_the_mark(director)
	return [director, before, mark_guard]

## Day 9 let through the named door: she stands where the inspection sets her down — the gatehouse
## the arrow names, `obstructs_radius + PLAYER_BODY_RADIUS + CHECKPOINT_RELEASE_MARGIN` (54px) along
## the street past the door's line — on one side on `director`'s day, and on the other on a second
## attempt at the same day, since a task is done once — and the door announces that inspected
## crossing (`EventManager.door_crossed`, as `CheckpointController` announces a release: the
## gatehouse's own position and facing) for the director to answer. From each, the trap owes
## everything `_check_the_trap_comes_from_off_screen()` asks, his run at her through the door's line
## included. Frees `director`.
func _check_day_nines_trap_from_where_she_is_let_out(t, first: ResistanceDirector) -> void:
	for side: float in [1.0, -1.0]:
		var director: ResistanceDirector = first if side > 0.0 \
				else _start_a_guarded_target_day(t, 9)[0]
		var hut: EventScheduler.Planned = null
		for body in _city.region_plan().door_bodies:
			if body.def.redetains and body.position.distance_to(director.red_arrow_target()) < 0.5:
				hut = body
		if side > 0.0:
			t.check(hut != null, "day 9: the arrow names a gatehouse of the named door")
		if hut == null:
			director.free()
			return
		var out := hut.def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS \
				+ CheckpointController.CHECKPOINT_RELEASE_MARGIN
		var her := hut.position + hut.facing * side * out
		t.check(_city.map.is_walkable(_city.map.world_to_tile(her)),
				"day 9: the ground she is let out onto is open (%s)" % _city.map.world_to_tile(her))
		var player := _rig_player(t, her)
		director.use_player(player)
		_watch_the_screen_round(director, her)
		_city.events.door_crossed.emit(hut.position, hut.facing, true)
		t.check(director.contact().is_done, "day 9: an inspected crossing completes the task")
		var label := "day 9, let out %.0fpx along the street from the gatehouse" % (side * out)
		if _warning_for(_city.events, "robber_giving_chase") == null:
			_check_no_start_was_passed_over(t, her, label)
		else:
			_check_the_trap_comes_from_off_screen(t, her, "robber_giving_chase", label)
		player.free()
		director.free()

## When a done task sends nobody (the director found no start for him), none of the fixed starts
## — just out of sight straight above, straight below, and either side along her street
## (`_fixed_starts()`) — was legal ground whose run at her keeps out of the region's wall and doors,
## so the director passed over none it could have taken.
func _check_no_start_was_passed_over(t, her: Vector2, label: String) -> void:
	var def := EventCatalogue.by_id("robber_giving_chase")
	var siting := _city.spawn_siting
	var asked := siting.ask(EventFootprints.footprint_of(def), Mover.on_foot(EventInstance.FIGURE_RADIUS), her)
	for candidate in _fixed_starts(def, her):
		t.check(not (siting.allows(SpawnSiting.Rule.LEGAL_GROUND, asked, candidate)
				and siting.allows(SpawnSiting.Rule.CLEAR_OF_THE_BOUNDARY, asked, candidate)),
				"%s: nobody is sent, and no start %v off her was passed over" % [label, candidate - her])

## The four starts `_draw_arrival_position()` tries before any drawn bearing: just out of sight
## straight above and below her and either side along her street, with the camera on her.
static func _fixed_starts(def: EventDef, her: Vector2) -> Array[Vector2]:
	var view := VisibleView.around(her, null)
	var starts: Array[Vector2] = []
	for way: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		starts.append(SpawnSiting.just_out_of_sight(view, EventFootprints.footprint_of(def), her,
				way))
	return starts

## Camera smoothing can move the view while she stands still through a badge. The actual
## warning callback must place the entire drawing outside that new view in either input scheme.
func _test_a_trap_rechecks_the_camera_when_its_warning_expires(t) -> void:
	for joystick: bool in [false, true]:
		_build_city_in_a_new_run(t)
		var director := _director_on_the_yeller_perform(t)
		var her := director.contact_position()
		var player := Node2D.new()
		t.add_child(player)
		player.position = her
		player.add_to_group("player")
		_city.events.use_player(player)
		var view := _city.events.visible_view()
		view.look(Rect2(her - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0), TouchCover.joystick() if joystick else null)
		director.set_sight(_city.events.sees)
		# The note handed over where the contact stands: its trap is sent at her from there.
		director.contact().complete_now()
		var warning := _warning_for(_city.events, "robber_giving_chase")
		t.check(warning != null and _live("robber_giving_chase").is_empty(),
				"camera-only movement starts with a real warning and no trap")
		if warning != null:
			var initial := warning.place
			var bearing := (initial - her).normalized()
			view.look(Rect2(her + bearing * 30.0 - Tuning.VIEW_HALF_EXTENT,
					Tuning.VIEW_HALF_EXTENT * 2.0), TouchCover.joystick() if joystick else null)
			_city.events.warnings.run(warning.left * 0.5, her)
			t.check(warning.place == initial and _live("robber_giving_chase").is_empty(),
					"camera movement neither moves the badge nor creates its trap early")
			_city.events.warnings.run(warning.left + STEP, her)
			var sent := _live("robber_giving_chase")
			var trap: EventInstance = sent[0] if sent.size() == 1 else null
			t.check(trap != null, "the shifted camera still leaves legal ground for the trap")
			if trap != null:
				trap.player_at = her
				var drawing := trap.look.drawn_rect_now()
				t.check(view.view.intersects(Rect2(initial + drawing.position, drawing.size)),
						"the camera moved far enough to expose a trap at the initial badge position")
				t.check(not view.view.intersects(Rect2(trap.position + drawing.position, drawing.size)),
						"warning expiry keeps the actual drawing outside the moved WHOLE camera")
				t.check((trap.position - her).normalized().is_equal_approx(bearing),
						"the trap keeps the badge's bearing when the camera moves")
		player.free()
		director.free()

## What every trap owes from the moment it is sent, on the real city. **Warned first**: the moment she
## does it a warning for `row_id` is up with nothing in the world, and stays up alone for the row's own
## `EventDef.warned_for()`, at most `Tuning.WARNING_ALONE_MAX`; run out with her standing where she
## did it, the one `row_id` in the street is then started **just off screen** (everything he draws
## outside the camera's view about her) — above or below her, or beside her along her street, or at a
## front door from across the street, below her — on legal ground, never waiting, already chasing
## (amendment 7: "the proximity rule is only for standing robbers"), and coming at her from his first
## frame. **His run at her never crosses a
## district door's line**, asked here of each door body the way
## `CheckpointController.watch_the_door_lines()` asks it of her own steps
## (`CheckpointController._where_she_crossed()`), not through the director's own refusal. **A
## straight walkable run at her is a preference, not a guarantee** (`_draw_arrival_position()`'s
## own doc: with none from any start, the first legal one stands in): so with one — or from
## across the street, with his own walk at her (`SpawnSiting.Rule.REACHES_HER`) — he catches her
## where she stands, and without one none of the fixed starts (`_fixed_starts()`) had one on
## legal ground either, so the director passed over no clear start it could have taken. Measured
## per target by `tests/probes/grassy_goose_target_traps.gd`. Returns where he started, or `INF`.
func _check_the_trap_comes_from_off_screen(t, her: Vector2, row_id: String, label: String,
		front_door := false) -> Vector2:
	var warning := _warning_for(_city.events, row_id)
	t.check(warning != null and _live(row_id).is_empty(),
			"%s: the moment she does it, %s's warning is up with nothing in the world" % [label, row_id])
	if warning == null:
		return Vector2.INF
	t.check(warning.left <= Tuning.WARNING_ALONE_MAX + 0.001,
			"%s: for %.2fs alone, at most a second" % [label, warning.left])
	var shown := _run_the_traps_warning(row_id, her)
	var sent := _live(row_id)
	var chaser: EventInstance = sent[0] if sent.size() == 1 else null
	t.check(chaser != null and chaser.def.id == row_id,
			"%s: %s is sent after her once it is over (%.2fs)" % [label, row_id, shown])
	if chaser == null:
		return Vector2.INF
	var start := chaser.global_position
	var view := VisibleView.around(her, null)
	var siting := _city.spawn_siting
	var asked := siting.ask(EventFootprints.footprint_of(chaser.def), Mover.on_foot(EventInstance.FIGURE_RADIUS),
			her)
	var beside := asked.beside
	var dist := start.distance_to(her)
	var sideways := absf(start.y - her.y) < 0.5
	var across := front_door and start.y > her.y and dist <= beside + 0.5 \
			and siting.allows(SpawnSiting.Rule.REACHES_HER, asked, start)
	var cone := absf(absf((start - her).angle()) - PI / 2.0) <= ResistanceDirector.ARRIVAL_CONE + 0.01
	t.check(cone or sideways or across,
			"%s: above or below her within the cone, beside her, or across the street (%.1fpx, at %v)"
			% [label, dist, start - her])
	t.check(not chaser.is_telegraphing(), "%s: already chasing, with no closing-in first" % label)
	t.check(SpawnSiting.is_out_of_sight(view, EventFootprints.footprint_of(chaser.def), her, start),
			"%s: wholly out of sight the frame he exists" % label)
	var through_a_door := false
	var plan := _city.region_plan()
	for body: EventScheduler.Planned in plan.door_bodies if plan else []:
		if DoorLine.crossed_by(body.position, body.facing, body.def.obstructs_radius,
				start, her):
			through_a_door = true
	t.check(not through_a_door,
			"%s: his run at her from %s never crosses a district door's line"
			% [label, _city.map.world_to_tile(start)])
	t.check(siting.allows(SpawnSiting.Rule.LEGAL_GROUND, asked, start),
			"%s: on walkable ground nothing refuses" % label)
	var clear := siting.allows(SpawnSiting.Rule.CLEAR_RUN, asked, start)
	if not clear and not across:
		for candidate in _fixed_starts(chaser.def, her):
			t.check(not (siting.allows(SpawnSiting.Rule.LEGAL_GROUND, asked, candidate)
					and siting.allows(SpawnSiting.Rule.CLEAR_RUN, asked, candidate)
					and siting.allows(SpawnSiting.Rule.CLEAR_OF_THE_BOUNDARY, asked, candidate)),
					"%s: with no clear run from %s, none from %v off her either"
					% [label, _city.map.world_to_tile(start), candidate - her])
	t.check(not chaser.is_waiting(), "%s: never waiting, even before his first frame" % label)
	chaser.player_at = her
	chaser.step(STEP)
	var closed := start.distance_to(her) - chaser.global_position.distance_to(her)
	t.check(closed > chaser.def.chase_speed() * STEP * 0.9 or (across and closed > 0.0),
			"%s: and coming at her%s from his first frame" % [label,
			"" if across else " at his own speed"])
	if not clear and not across:
		return start
	var caught := false
	var elapsed := 0.0
	while elapsed < chaser.def.telegraph_time + chaser.def.duration \
			and not chaser.is_finished and not caught:
		chaser.player_at = her
		chaser.step(STEP)
		elapsed += STEP
		caught = chaser.is_lethal_at(her)
	t.check(caught, "%s: and, with a %s, reaches her where she stands (%.1fs)"
			% [label, "walk from across the street" if across and not clear else "clear run",
			elapsed])
	return start

## Every robber or guard standing or running in the test city: the alley robber and the two the
## director can send after her.
func _robbers_on_the_street() -> int:
	var count := 0
	var ids := ["alley_robbery", "robber_giving_chase", "van_guard_giving_chase"]
	for instance in _city.events.instances():
		if instance.def.id in ids and not instance.is_finished:
			count += 1
	return count

## Whether `at` would actually be in sight with the camera on `her` and led toward `at` the way
## `Stroller` leads it when she faces what she is walking toward — the worst-case lead, since a
## start behind her would only pull the camera the other way. Asked of the tap scheme's
## `VisibleView`, whose whole view is what `EventManager.on_screen()` answers in either scheme — the
## test the director places against (`SpawnSiting.Rule.DRAWING_OFF_THE_VIEW`, over the same view): the
## joystick's covered corners only ever take ground out of sight, so a point out of the whole view
## is out of both.
func _is_really_on_screen(_t, her: Vector2, at: Vector2) -> bool:
	var bearing := at - her
	var lead := Vector2.ZERO
	if bearing.length() > 0.001:
		var dir := bearing.normalized()
		lead = Vector2(dir.x, dir.y * Stroller.OBLIQUE_Y) * Stroller.CAMERA_LOOK_AHEAD
	return VisibleView.around(her + lead, null).sees(at)

## *(PLAYTEST-71: "maybe spawn the robber in pursuing mode offscreen when she interacts with the
## yeller so it runs towards her from offscreen"; "we need a version of the robber that is not
## frozen when spawned"; M226: warned first, "1s warning should be enough".)* Handing the note over
## puts up one `robber_giving_chase`'s warning with nothing in the world, and once it is over sets
## him on her just out of sight, on legal ground, never waiting, and coming at her from the first
## frame he is stepped — everything `_check_the_trap_comes_from_off_screen()` asks.
##
## **Swept over `RULE_SEEDS` cities rather than trusted on one.** Every seed's handover replays to
## the same place, and the man she handed it to keeps shouting rather than leaving at once (M205).
func _test_the_handover_sets_a_robber_on_her_from_off_screen(t) -> void:
	var seeds: Array[int] = [4242, 90210, 2295276695, 291862120, 314159, 555555]
	for seed_value: int in seeds.slice(0, RULE_SEEDS):
		# Each attempt is the same day of a fresh run: the mark's own alley is recorded as used when
		# it is touched, and a used alley is avoided on the next draw, so a second attempt in the
		# same run would be a different day.
		var starts: Array[Vector2] = []
		for attempt in 2:
			_build_city_in_a_new_run(t, seed_value)
			var director := _director_on_the_yeller_perform(t, seed_value)
			var rider := director.rider()
			var her := director.contact_position()
			_watch_the_screen_round(director, her)
			var player := _rig_player(t, her)
			director.use_player(player)
			await _step_a_frame(t)
			t.check(director.contact().is_done, "seed %d: she hands the note over" % seed_value)
			var start := _check_the_trap_comes_from_off_screen(t, her,
					"robber_giving_chase", "seed %d" % seed_value)
			if start != Vector2.INF:
				if not starts.is_empty():
					t.close_to(start.distance_to(starts[0]), 0.0,
							"seed %d: the same handover sends him from the same place"
							% seed_value, 0.01)
				starts.append(start)
			# He does not leave the instant she hands it over (M205): he keeps shouting, and
			# charging her, for `NOTE_HANDOVER_LINGER_SECONDS` first — unaffected by the
			# robber's own clock, which is all this loop has advanced.
			t.check(not rider.is_leaving,
					"seed %d: the man she handed it to keeps shouting, not leaving instantly"
					% seed_value)
			player.free()
			director.free()

## Mirrors `_test_the_handover_sets_a_robber_on_her_from_off_screen` for the van: handing the
## package over puts up one `van_guard_giving_chase`'s warning and then sets him on her, on the same
## terms as the robber. The van itself is a one-place task's own rider and never leaves when the
## package is picked up — the director only sends the man shouting's own rider away by name.
func _test_the_van_handover_sets_a_guard_on_her_from_off_screen(t) -> void:
	var starts: Array[Vector2] = []
	for attempt in 2:
		_build_city_in_a_new_run(t)
		var director := _director_on_the_van_perform(t)
		var her := director.contact_position()
		_watch_the_screen_round(director, her)
		var player := _rig_player(t, her)
		director.use_player(player)
		await _step_a_frame(t)
		t.check(director.contact().is_done, "she hands the package over")
		var start := _check_the_trap_comes_from_off_screen(t, her,
				"van_guard_giving_chase", "the van")
		if start != Vector2.INF:
			if not starts.is_empty():
				t.close_to(start.distance_to(starts[0]), 0.0,
						"the same handover sends him from the same place", 0.01)
			starts.append(start)
		player.free()
		director.free()

## **He is warned of before he exists, the warning is short, and he arrives chasing.** *(Amendment 7
## of M226, the player: "why would the robber walk towards her when it spawns as pursuing robber? the
## proximity rule is only for standing robbers.")* A bare robber walked from each start the director
## draws — just off screen straight above and below her and at the edges of
## `ResistanceDirector.ARRIVAL_CONE`, and the along-her-street start beside her — the moment he is
## created there, his badge already spent and his telegraph with it:
##
## - **standing where she did it**, she is caught;
## - **walking into him**, she is caught, and turning to run `PursuitSpec.PURSUIT_REACTION` after his badge
##   rises gets her away;
## - **walking away** is caught from every start, beside her included — no pursuer gives up on a
##   walker (amendment 8: `Tuning.PURSUIT_TIME` is a long cap), so walking has to lose;
## - **running** shakes him off while still unseen, before its cost can make an awake baby cry.
##
## The tall-osprey floor (standing still, a robber lunges no sooner than `Tuning.PURSUIT_MIN_NOTICE`
## after he appears) is a standing robber's, a mark's guard waiting in his alley, whom this build does
## not touch; a sent one has no closing-in for it to bound.
func _test_the_robber_after_her_is_announced_before_he_can_catch_her(t) -> void:
	await _assert_a_trap_row_is_announced_before_it_can_catch_her(t, "robber_giving_chase")

## The same contract for the van's own guard: walks the guard's own row and asserts the same
## relationships rather than assuming the robber's numbers carry over unchecked.
func _test_the_van_guard_after_her_is_announced_before_he_can_catch_her(t) -> void:
	await _assert_a_trap_row_is_announced_before_it_can_catch_her(t, "van_guard_giving_chase")

## Shared between the man shouting's row and the van's: each of this suite's two callers passes
## its own catalogue id, since the contract this checks is the same row-independent relationship
## for both.
func _assert_a_trap_row_is_announced_before_it_can_catch_her(t, id: String) -> void:
	# No city of an earlier test stands in the tree while the walks tick the engine faster.
	_free_city()
	var def := EventCatalogue.by_id(id)
	t.check(def.warns_before_it_exists() and def.warned_for() <= Tuning.WARNING_ALONE_MAX
			and def.starts_by(PursuitSpec.Start.ARRIVES_CHASING),
			"he is warned of before he exists, for %.2fs alone, and arrives chasing" % def.warned_for())
	var her := Vector2.ZERO
	var view_on_her := VisibleView.around(her, null)
	var edge_of_cone := ResistanceDirector.ARRIVAL_CONE - 0.001
	var box := EventFootprints.footprint_of(def)
	var starts: Array[Vector2] = [
			SpawnSiting.just_out_of_sight(view_on_her, box, her, Vector2.DOWN),
			SpawnSiting.just_out_of_sight(view_on_her, box, her, Vector2.UP),
			SpawnSiting.just_out_of_sight(view_on_her, box, her,
					Vector2.DOWN.rotated(edge_of_cone)),
			SpawnSiting.just_out_of_sight(view_on_her, box, her,
					Vector2.UP.rotated(-edge_of_cone)),
			SpawnSiting.just_out_of_sight(view_on_her, box, her, Vector2.RIGHT)]
	for start in starts:
		t.check(SpawnSiting.is_out_of_sight(view_on_her, box, her, start),
				"from %v: wholly off screen the frame he exists" % start)
		var stood: Dictionary = await _walk_the_trap(t, def, start, 0.0)
		t.check(stood["caught_at"] < INF,
				"from %v: standing still is caught (%.2fs)" % [start, stood["caught_at"]])
		var into: Dictionary = await _walk_the_trap(t, def, start, Tuning.WALK_SPEED)
		t.check(into["caught_at"] < INF, "from %v: walking into him is caught" % start)
		# The badge went up `warned_for()` before he exists, so a turn `PURSUIT_REACTION` after the
		# badge is that much less after he appears.
		var turned: Dictionary = await _walk_the_trap(t, def, start, Tuning.WALK_SPEED,
				maxf(0.0, PursuitSpec.PURSUIT_REACTION - def.warned_for()))
		t.check(turned["caught_at"] == INF and turned["gave_up"],
				"from %v: walking into him and turning to run %.1fs after the badge gets away"
				% [start, PursuitSpec.PURSUIT_REACTION])
		var away: Dictionary = await _walk_the_trap(t, def, start, -Tuning.WALK_SPEED)
		t.check(away["caught_at"] < INF,
				"from %v (%.0fpx): walking straight away is caught (%.2fs)"
				% [start, start.length(), away["caught_at"]])
		var ran: Dictionary = await _walk_the_trap(t, def, start, -Tuning.RUN_SPEED)
		t.check(ran["caught_at"] == INF and ran["gave_up"] and not ran["cried"],
				"from %v: running shakes him off before either catch or crying" % start)
		if is_zero_approx(start.x):
			t.check(ran["first_seen"] == INF,
					"from %v: the immediate run escapes while he remains offscreen" % start)
		t.check(ran["excitement"] > 0.0 and ran["excitement"] < Tuning.METER_MAX * 0.3,
				"from %v: the actual awake Baby pays an affordable %.2f points for running"
				% [start, ran["excitement"]])

## Walks her at `speed` along the line to `start` — positive toward him, negative away — against a
## bare instance of `def` (`robber_giving_chase` or `van_guard_giving_chase`) created at `start`
## from her, the moment his warning is over, as `EventManager.spawn_warned()` creates him: already
## chasing. A walk is under way when he appears (the handover does not stop her); a run
## gets up to speed at `Tuning.ACCELERATION`. `turn_to_run_after`, if given, reverses her into a run
## away from him that many seconds after he appears. The real Baby charges this run, awake at zero
## excitement with no world noise or recovery; crying ends the attempt rather than counting as escape.
##
## **Her meter runs on the engine's own ticks**: the baby rides a real `Stroller` in the tree and her
## `_physics_process()` takes each tick. The walk is driven tick by tick on the engine's
## `physics_frame`, which is sent before the nodes take that tick: her state for a tick is set, the
## next `physics_frame` comes once the baby has stepped on it, and the robber then takes the same
## tick's step, however many ticks a frame runs. The ticks are `STEP` of game time each
## (`_walk_ticks()`).
func _walk_the_trap(t, def: EventDef, start: Vector2, speed: float,
		turn_to_run_after := INF) -> Dictionary:
	var bearing := start.normalized()
	var robber := EventInstance.new()
	robber.setup(def, start)
	robber.came_under_a_warning = true
	if def.starts_by(PursuitSpec.Start.ARRIVES_CHASING):
		robber.resume(EventSpawner.age_when_warned(def), 0.0)
	var stroller := _rig_player(t, Vector2.ZERO)
	var baby := Baby.new()
	baby.name = "Baby"
	stroller.add_child(baby)
	var held := _walk_ticks()
	var tree := t.get_tree() as SceneTree
	# The tick the walk starts on: the baby takes its step after this, with what is set below.
	await tree.physics_frame
	var result := {"caught_at": INF, "at_the_lunge": INF, "lunged_at": INF, "gave_up": false,
			"ended": false, "first_seen": INF, "cried": false, "excitement": 0.0}
	var her := Vector2.ZERO
	var velocity := speed if absf(speed) <= Tuning.WALK_SPEED else 0.0
	var elapsed := 0.0
	var was_telegraphing := true
	while elapsed < def.telegraph_time + def.duration + 1.0:
		var wanted := speed
		if elapsed >= turn_to_run_after:
			wanted = -Tuning.RUN_SPEED
		velocity = move_toward(velocity, wanted, Tuning.ACCELERATION * STEP)
		her += bearing * velocity * STEP
		stroller.position = her
		stroller.velocity = bearing * velocity
		await tree.physics_frame
		robber.player_at = her
		robber.player_running = absf(velocity) > Tuning.WALK_SPEED
		var box := robber.drawn_box()
		var in_sight := VisibleView.around(her, null).sees_any(
				Rect2(robber.global_position + box.position, box.size))
		if in_sight and result["first_seen"] == INF:
			result["first_seen"] = elapsed
		robber.step(STEP)
		elapsed += STEP
		var offset := robber.global_position - her
		if was_telegraphing and not robber.is_telegraphing():
			result["at_the_lunge"] = offset.length()
			result["lunged_at"] = elapsed
			was_telegraphing = false
		if robber.is_lethal_at(her):
			result["caught_at"] = elapsed
			break
		if baby.state == GameEnums.BabyState.CRYING:
			result["cried"] = true
			break
		if robber.gave_up or robber.is_finished or robber.is_leaving:
			result["gave_up"] = robber.gave_up
			result["ended"] = true
			break
	result["excitement"] = baby.excitement
	_give_the_ticks_back(held)
	stroller.free()
	robber.free()
	return result

## How many times faster than the wall clock a trap walk runs its ticks (`_walk_ticks()`), at most:
## a slow frame runs no more than `Engine.max_physics_steps_per_frame` of them, which only slows the
## walk, never changes it.
const WALK_SPEED_UP := 60.0

## Sets the engine's ticks to `STEP` of game time each, `WALK_SPEED_UP` times as many a second:
## `Engine.time_scale` times the tick's length is the delta every `_physics_process()` is handed.
## Answers what it changed, for `_give_the_ticks_back()`.
func _walk_ticks() -> Array:
	var held := [Engine.physics_ticks_per_second, Engine.time_scale]
	Engine.physics_ticks_per_second = int(round(WALK_SPEED_UP / STEP))
	Engine.time_scale = WALK_SPEED_UP
	return held

## Puts back the ticks `_walk_ticks()` changed.
func _give_the_ticks_back(held: Array) -> void:
	Engine.physics_ticks_per_second = held[0]
	Engine.time_scale = held[1]

## Spawned only by the director: no day of the run, at any heat, offers the row to the scheduler's
## roll, its stream or its budget — `EventCatalogue.available_on()` is the pool all three draw from —
## and a day the scheduler actually plans, on the first day a task can be handed over, carries none.
func _test_the_robber_after_her_is_never_the_schedulers(t) -> void:
	_assert_a_trap_row_is_never_the_schedulers(t, "robber_giving_chase")

## The same guarantee for the van's own guard: a second `SCRIPTED`/`scripted_day 0` row director-
## spawned at the handover, so it needs the same "the roll, the stream and the budget never reach
## it" check the robber's own row gets, rather than assuming a second row of the same shape is
## automatically exempt.
func _test_the_van_guard_after_her_is_never_the_schedulers(t) -> void:
	_assert_a_trap_row_is_never_the_schedulers(t, "van_guard_giving_chase")

func _assert_a_trap_row_is_never_the_schedulers(t, id: String) -> void:
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		for heat in EventCatalogue.heat_levels():
			for def in EventCatalogue.available_on(day, heat):
				t.check(def.id != id,
						"day %d at heat %d does not offer '%s'" % [day, heat, id])
	var map := CityGenerator.generate(SEED)
	var consumed: Array[String] = []
	var plans := EventScheduler.build_day(DaySpec.for_day(ResistanceDirector.TRAP_FIRST_DAY),
			_rng(ResistanceDirector.TRAP_FIRST_DAY, "events"), map, CalmAreas.of(map),
			consumed).placements()
	t.check(not plans.is_empty(), "the day planned something to look through (%d)" % plans.size())
	for plan in plans:
		t.check(plan.def.id != id,
				"day %d's own plan places no '%s'" % [ResistanceDirector.TRAP_FIRST_DAY, id])
