extends "res://tests/resistance_rig.gd"
## The four placement kinds a perform step may use, each task's own site, and the days built in order.

## Every test that needs a city builds its own, in a run of its own (`_build_city_in_a_new_run()`),
## and sets on that run what the day it asks about needs; none reads what another left. What the
## director put in the street is read from the street (`contact()`, `rider()`, `read_mark()`, the
## city's live instances), a touch is a real physics frame, and the happenings are the public ones
## (`raid_vans()`, `frontage_of()`, `spine_x()`, `tick()`). The ground a row is offered is asked of
## `EventScheduler.open_ground_for()`, the next day's masts of `EventScheduler.place_masts()`, the
## near mast of the director's `weighted_mast_index()`, and `_start_the_day()` hands the baby its
## stroller with `Baby.set_stroller()`.
func run(t) -> void:
	t.gives_back_observers()
	await _test_the_burnt_shell_task_rides_the_recorded_scar(t)
	await _test_the_burnt_shell_task_falls_back_with_no_recorded_scar(t)
	_test_every_front_the_fire_catches_on_has_a_door_on_a_sidewalk(t)
	_test_the_door_task_sits_at_a_region_door(t)
	_test_a_day_is_built_in_its_order(t)
	_test_a_completed_marks_own_contact_and_guard_survive_to_the_day_end(t)
	_test_a_read_mark_does_not_pile_up_across_several_ordinary_days(t)
	_test_the_door_task_never_borders_the_home_block(t)
	_test_the_swing_task_sits_at_an_open_playground(t)
	_test_day_twelves_park_is_forced_open_whatever_its_state(t)
	_test_the_mast_task_silences_one_mast_for_the_rest_of_the_run(t)
	_test_the_mast_task_favors_the_near_mast(t)
	_test_the_neighbor_leaves_for_work_until_the_raid(t)
	_test_day_ten_sends_her_to_the_neighbor_walking_home(t)
	_test_the_raid_waits_at_her_building_with_the_doorstep_open(t)
	_test_the_raid_seals_her_street_door(t)
	_test_the_sealed_door_stands_after_a_reload(t)
	_test_a_lost_day_ten_restores_the_ordinary_door(t)
	_test_the_neighbor_window_is_boarded_from_day_eleven(t)
	_test_the_market_is_found_gone(t)
	_test_the_column_comes_down_the_main_road(t)
	_free_city()

func _test_the_burnt_shell_task_rides_the_recorded_scar(t) -> void:
	_build_city_in_a_new_run(t)
	# On ground day 3's fire can actually catch on (`AT_THE_FRONT`, a building behind it), since a
	# real scar is only ever recorded there and the arrow ends on that building.
	var doorstep := _city.map.doorstep_world_position()
	var near_fronts: Array[Vector2i] = []
	var far_fronts: Array[Vector2i] = []
	for tile in EventScheduler.open_ground_for(EventCatalogue.by_id("burning_building"),
			_city.map, {}):
		var distance := _city.map.tile_to_world(tile).distance_to(doorstep)
		if distance < Tuning.EVENT_STREAM_RADIUS:
			near_fronts.append(tile)
		elif distance > Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS:
			far_fronts.append(tile)
	t.check(not near_fronts.is_empty(), "home has fronts within streaming range")
	t.check(not far_fronts.is_empty(), "and fronts beyond it")
	if near_fronts.is_empty() or far_fronts.is_empty():
		return
	await _ride_a_recorded_scar(t, near_fronts[near_fronts.size() / 2], "a scar near home")
	# The case a real run makes most: a dusk fire is sited at least `EVENT_STREAM_RADIUS` from
	# where she finished day 3, so its shell is not in the world when she reads day 8's mark.
	await _ride_a_recorded_scar(t, far_fronts[far_fronts.size() / 2], "a scar beyond streaming range")

## Records a day-3 scar at `site`, plans day 8 around the doorstep, reads day 8's mark there, and
## checks the task rides that scar: the one shell at it, put in the world even when the scar is
## farther than the streaming radius, kept there when she walks away, no second scar recorded, and
## the arrow and the contact on the door of the building behind it.
func _ride_a_recorded_scar(t, site: Vector2i, label: String) -> void:
	var run := _build_city_in_a_new_run(t)
	var doorstep := _city.map.doorstep_world_position()
	var scar_at := _city.map.tile_to_world(site)
	run.attempt_spend.scars = [{"id": "burnt_shell", "position": scar_at, "since_day": 3}]
	# `_place_scars()` plans a `burnt_shell` at `scar_at` for the day; it is in the world only
	# if `scar_at` is inside the streaming radius of the doorstep.
	_city.events.start_day(DaySpec.for_day(8), _rng(8, "events"), [], doorstep)

	var director := _director(t)
	director.start_day(8, _rng(8, "resistance"), 300.0)
	_read_the_mark(director)
	t.check(director.current_step() != null and director.current_step().index == 6,
			"%s: touching day 8's mark activates the burnt-shell perform" % label)
	var shell := director.rider()
	t.check(shell != null and shell.def.id == "burnt_shell",
			"%s: riding a burnt_shell instance" % label)
	if shell == null:
		director.free()
		return
	t.check(shell.global_position.distance_to(scar_at) < 1.0,
			"%s: the one standing at the run's own recorded scar" % label)
	t.check(run.attempt_spend.scars.size() == 1,
			"%s: and no second scar is recorded for the task (%s)" % [label, run.attempt_spend.scars])
	_check_the_task_is_at_the_burnt_buildings_door(t, director)

	# She walks off across the city: the shell stays under its contact.
	_city.events.stream_around(scar_at + Vector2(1.0, 1.0) * 4.0
			* (Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS))
	# `instances()` rather than `rider_alive()` alone: a streamed-out instance is only queued
	# for deletion, and still valid until the frame ends.
	t.check(director.contact().rider_alive() and _city.events.instances().has(shell),
			"%s: the shell stays in the world when she walks far away from it" % label)
	# And back: still one shell there, so its field is counted once.
	_city.events.stream_around(scar_at)
	var shells := 0
	for instance in _city.events.instances():
		if instance.def.id == "burnt_shell" \
				and instance.global_position.distance_to(scar_at) < 1.0:
			shells += 1
	t.check(shells == 1, "%s: one shell at the scar, not two (%d)" % [label, shells])
	await _check_a_touch_from_the_near_half_of_the_sidewalk(t, director)

	director.free()

## Day 8's red arrow ends on the burnt building's door, and the task's contact stands there too:
## *"or better to the door but the acceptance radius centered at the door should have a large
## enough radius for half the sidewalk to be covered"* (sandy-egret). The shell has no body and
## draws nothing, so its own position is bare sidewalk. The door is read off the building behind the
## shell (the lot `City` draws burnt) independently of `Building.way_in_local_x()`: its entrance
## door's column centre when it has one, half a tile up its ground floor.
func _check_the_task_is_at_the_burnt_buildings_door(t, director: ResistanceDirector) -> void:
	var tip := director.red_arrow_target()
	t.check(tip != Vector2.INF, "day 8's task earns the red arrow")
	var shell := director.rider()
	if tip == Vector2.INF or shell == null:
		return
	t.check(tip == director.contact_position(),
			"the arrow's tip %s is where the task's contact stands %s"
			% [tip, director.contact_position()])
	var shell_tile := _city.map.world_to_tile(shell.global_position)
	var behind: Building = null
	for building in _city.buildings():
		if building.lot.has_point(shell_tile + Vector2i.UP):
			behind = building
	t.check(behind != null, "the shell at %s has a building behind it" % shell_tile)
	if behind == null:
		return
	var lot := _city.map.tile_rect_to_world(behind.lot)
	var size := float(Tuning.TILE_SIZE)
	t.close_to(tip.y, lot.end.y - size * 0.5,
			"the tip is half a tile up that building's ground floor", 0.01)
	var door_col := behind.entrance_door_col()
	if door_col >= 0:
		t.close_to(tip.x, lot.position.x + (door_col + 0.5) * size,
				"and on its entrance door, column %d of %s" % [door_col, behind.lot], 0.01)
	else:
		t.check(tip.x >= lot.position.x and tip.x <= lot.end.x,
				"and on its own front, which has no entrance door (%s)" % behind.lot)

## The contact at the door completes from the near half of the sidewalk in front of it — the whole
## tile below the door, out to its bottom corners — and not from its far half or past it. Called
## last, since the touch that completes it hands the task over. Her touch is a real physics frame
## with her standing where the test puts her; the two corner touches are asked of the contact itself
## (`ContactPoint.would_complete_at()`, the question a frame's touch asks), so they hand nothing over.
func _check_a_touch_from_the_near_half_of_the_sidewalk(t, director: ResistanceDirector) -> void:
	var contact := director.contact()
	var door := director.contact_position()
	if contact == null or door == Vector2.INF:
		t.check(false, "day 8's task has a contact to touch")
		return
	var foot := door + Vector2.DOWN * Tuning.TILE_SIZE * 0.5
	var sidewalk := float(Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE)
	var near := foot + Vector2.DOWN * (sidewalk * 0.5 - 4.0)
	var far := foot + Vector2.DOWN * (sidewalk * 0.5 + 4.0)
	var past := foot + Vector2.DOWN * (sidewalk + Tuning.TILE_SIZE * 0.5)
	t.check(_city.map.tile_at(_city.map.world_to_tile(near)) == GameEnums.TileType.SIDEWALK
			and _city.map.tile_at(_city.map.world_to_tile(far)) == GameEnums.TileType.SIDEWALK,
			"the two halves in front of the door at %s are sidewalk" % door)
	var player := _rig_player(t, past)
	director.use_player(player)
	await _step_a_frame(t)
	t.check(not contact.is_done, "a touch from past the sidewalk, %.0fpx from the door, does not"
			% door.distance_to(past))
	player.global_position = far
	await _step_a_frame(t)
	t.check(not contact.is_done, "nor one from the far half, %.0fpx from the door"
			% door.distance_to(far))
	for side in [-1.0, 1.0]:
		var corner := foot + Vector2(side * (Tuning.TILE_SIZE * 0.5 - 1.0),
				sidewalk * 0.5 - 1.0)
		t.check(contact.would_complete_at(corner),
				("a touch from a bottom corner of the tile below the door, %.1fpx from it, " +
				"completes it") % door.distance_to(corner))
	player.global_position = near
	await _step_a_frame(t)
	t.check(contact.is_done, "a touch from the near half, %.0fpx from the door, completes it"
			% door.distance_to(near))
	player.free()

## Every front day 3's fire can catch on, and so every place day 8's task can end, has a way in on
## the building behind it (`City.way_in_behind()`): its entrance door's column when it has one, and
## always ground the touch is measured over — a sidewalk tile straight below it, the near half
## `ResistanceDirector.DOOR_REACH` is sized to.
func _test_every_front_the_fire_catches_on_has_a_door_on_a_sidewalk(t) -> void:
	_build_city_in_a_new_run(t)
	var size := float(Tuning.TILE_SIZE)
	var fronts := EventScheduler.open_ground_for(EventCatalogue.by_id("burning_building"),
			_city.map, {})
	var on_a_door := 0
	var wrong: Array[Vector2i] = []
	for tile in fronts:
		var way := _city.way_in_behind(_city.map.tile_to_world(tile))
		var behind: Building = null
		for building in _city.buildings():
			if building.lot.has_point(tile + Vector2i.UP):
				behind = building
		if behind == null or way == Vector2.INF:
			wrong.append(tile)
			continue
		var lot := _city.map.tile_rect_to_world(behind.lot)
		var below := _city.map.world_to_tile(way) + Vector2i.DOWN
		var ok := absf(way.y - (lot.end.y - size * 0.5)) < 0.01 \
				and _city.map.tile_at(below) == GameEnums.TileType.SIDEWALK
		var door_col := behind.entrance_door_col()
		if door_col >= 0:
			on_a_door += 1
			ok = ok and absf(way.x - (lot.position.x + (door_col + 0.5) * size)) < 0.01
		if not ok:
			wrong.append(tile)
	t.check(on_a_door > fronts.size() / 2,
			"most fronts have an entrance door behind them (%d of %d)" % [on_a_door, fronts.size()])
	t.check(wrong.is_empty(),
			"every front's way in is on its building's door, over a sidewalk (%d are not, first %s)"
			% [wrong.size(), wrong.slice(0, 3)])

## A run with no recorded `burnt_shell` scar (a `--day 8` start, or a day 3 that never burned)
## still sends her to a burnt building: the shell stands on a front day 3's fire could have caught
## on, the scar is recorded there, and the building behind it is burnt at once — *"Take what's in
## the stroller to the burnt building"* never leads to bare sidewalk.
func _test_the_burnt_shell_task_falls_back_with_no_recorded_scar(t) -> void:
	var run := _build_city_in_a_new_run(t)
	var burnt_before := 0
	for building in _city.buildings():
		if building.condition == Building.Condition.BURNT:
			burnt_before += 1

	var director := _director(t)
	director.start_day(8, _rng(8, "resistance"), 300.0)
	t.check(run.attempt_spend.scars.is_empty(), "nothing is burnt for the task before her mark is read")
	_read_the_mark(director)
	t.check(director.current_step() != null and director.current_step().index == 6,
			"touching day 8's mark still activates the burnt-shell perform")
	var rider := director.rider()
	t.check(rider != null and rider.def.id == "burnt_shell",
			"riding a burnt_shell instance placed for the task")
	t.check(director.contact_position() != Vector2.INF, "somewhere reachable")
	if rider == null:
		director.free()
		return

	var shell := rider.global_position
	var shell_tile := _city.map.world_to_tile(shell)
	var fronts := EventScheduler.open_ground_for(EventCatalogue.by_id("burning_building"),
			_city.map, {})
	t.check(shell_tile in fronts,
			"the shell stands at %s, a front day 3's fire could have caught on" % shell_tile)
	var recorded := 0
	for scar: Dictionary in run.attempt_spend.scars:
		if String(scar["id"]) == "burnt_shell" \
				and (scar["position"] as Vector2).distance_to(shell) < 1.0:
			recorded += 1
	t.check(run.attempt_spend.scars.size() == 1 and recorded == 1,
			"the scar is recorded where the shell stands, and nothing else (%s)"
			% [run.attempt_spend.scars])
	var behind: Building = null
	var burnt_now := 0
	for building in _city.buildings():
		if building.lot.has_point(shell_tile + Vector2i.UP):
			behind = building
		if building.condition == Building.Condition.BURNT:
			burnt_now += 1
	t.check(behind != null and behind.condition == Building.Condition.BURNT,
			"the building behind the shell is burnt the moment the task is on offer")
	t.check(burnt_now == burnt_before + 1,
			"and no other building is (%d burnt, %d before)" % [burnt_now, burnt_before])
	_check_the_task_is_at_the_burnt_buildings_door(t, director)
	await _check_a_touch_from_the_near_half_of_the_sidewalk(t, director)

	director.free()

## Starts day `day` through the real `DayDirector` — the order a played day is built in (the
## city, the events, the resistance's mark, the crowd, the player and the baby) — on the test city's
## own run, restarted on `SEED`, whose streams are the ones `_rng()` draws. Returns the scratch nodes
## `_end_the_day()` frees.
func _start_the_day(t, day: int, resistance: ResistanceDirector,
		prepare := Callable()) -> Array[Node]:
	# The whole run, not only the snapshot's state parts: `start_run()` also resets the riders
	# (`facts`: the escape section, used alleys, fenced park), the checkpoint and the mode.
	var run: RunState = _city.run
	run.start_run(SEED)
	run.header.day = day
	if prepare.is_valid():
		prepare.call()
	var config := RunConfig.parse(PackedStringArray(), "", true)
	var player := Stroller.new()
	var baby := Baby.new()
	baby.name = "Baby"
	player.add_child(baby)
	baby.set_stroller(player)
	var clock := DayController.new()
	clock.set_process(false)
	t.add_child(clock)
	var days := DayDirector.new(run.calendar, run.facts, run.attempt_spend, config)
	days.use_the_world(_city, _city.events, resistance, player, baby, clock)
	_clock = clock
	days.start_day(MAIN_SCRIPT.day_spec(config, day))
	return [player, clock]

func _end_the_day(nodes: Array[Node]) -> void:
	for node in nodes:
		node.free()

var _clock: DayController

## A resistance director that notes what the city had planned when its day began.
class OrderRecordingResistance extends ResistanceDirector:
	var planned_when_started := -1
	var watched: City

	func start_day(day: int, rng: RandomNumberGenerator, day_length: float) -> void:
		planned_when_started = watched.events.planned_count()
		super.start_day(day, rng, day_length)

## **The order `DayDirector.start_day()` builds a day in**, on the light real world this suite builds,
## through what each step can observe: `day_started` is announced after the dawn photograph and before
## anything is placed, so a listener finds the photograph taken and no mark offered; the events are
## planned before the resistance places its mark; and `day_planned` comes last, with the clock
## running, the crowd placed and the mark on offer. A reordering of those calls fails here.
func _test_a_day_is_built_in_its_order(t) -> void:
	var run := _build_city_in_a_new_run(t)
	var director := OrderRecordingResistance.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(_city, _city.map)
	director.watched = _city
	var seen := {}
	var on_started := func(_day: int) -> void:
		# A photograph taken after the progress was set: nothing differs from the dawn.
		seen["dawn_photographed"] = not run.resistance.differs_from_dawn()
		seen["no_mark_yet"] = director.contact_position() == Vector2.INF
		seen["no_events_yet"] = _city.events.planned_count() == 0
	var on_planned := func(_day: int) -> void:
		seen["clock_running"] = _clock.is_running()
		seen["crowd_placed"] = _city.crowd.agent_count() > 0
		seen["mark_on_offer"] = director.contact_position() != Vector2.INF
	EventBus.day_started.connect(on_started)
	EventBus.day_planned.connect(on_planned)
	var the_day := _start_the_day(t, 9, director,
			func() -> void: run.resistance.progress = 2)
	EventBus.day_started.disconnect(on_started)
	EventBus.day_planned.disconnect(on_planned)

	t.check(seen.get("dawn_photographed", false),
			"day_started is announced after the dawn photograph")
	t.check(seen.get("no_mark_yet", false) and seen.get("no_events_yet", false),
			"and before the events are planned or the mark is placed")
	t.check(director.planned_when_started > 0,
			"the events are planned before the resistance places its mark (%d planned)"
			% director.planned_when_started)
	t.check(seen.get("clock_running", false) and seen.get("crowd_placed", false)
			and seen.get("mark_on_offer", false),
			"day_planned comes last: the clock running, the crowd placed, the mark on offer")
	director.free()
	_end_the_day(the_day)

## Runs the real day order (`DayDirector.start_day()`: city, events, resistance) rather than
## skipping the middle step. `EventManager.start_day()` is what holds every door segment for the
## day (`CityMap.held_segments`, filled from `region_plan.doors` among other things) — with it
## never run, a bare `_pick_reachable()` call would find the door tile reachable whether or not
## `_place_at_a_door()`'s `allow_held` carve-out (`docs/DECISIONS.md`, M181) actually does
## anything, so this test would pass whether the carve-out worked or was deleted. Also asserts
## the chosen tile's segment reads held, so the test states it is exercising that case rather
## than one where the held set happens to be empty.
func _test_the_door_task_sits_at_a_region_door(t) -> void:
	_build_city_in_a_new_run(t)
	var director := _director(t)
	var the_day := _start_the_day(t, 9, director)
	var doors := _city.region_plan().doors
	t.check(not doors.is_empty(),
			"day 9 (Tuning.REGION_WALL_FIRST_DAY) has at least one door, or this test "
			+ "checks nothing")
	_read_the_mark(director)
	t.check(director.current_step() != null and director.current_step().index == 8,
			"touching day 9's mark activates the crossing perform")
	t.check(director.rider() == null, "the crossing sits on a bare point, not a rider")

	var at := director.contact_position()
	t.check(at != Vector2.INF, "somewhere in the city")
	t.check(_city.map.is_held_at(_city.map.world_to_tile(at)),
			"the chosen tile's own segment is ground the day already holds — the case " +
			"`allow_held` exists for")
	var on_a_door := false
	for body in _city.region_plan().door_bodies:
		if body.def.redetains and body.position.distance_to(at) < 0.5:
			on_a_door = true
			break
	t.check(on_a_door, "exactly on a gatehouse of one of today's own region doors")

	director.free()
	_end_the_day(the_day)

## A copy of `step` to give a deadline without changing the calendar's own row, every public
## field of `ResistanceSteps.Step` written by name in the source (a field added to `Step` is
## copied here by adding its line).
static func _copy_of_step(step: ResistanceSteps.Step) -> ResistanceSteps.Step:
	var copy := ResistanceSteps.Step.new()
	copy.index = step.index
	copy.title = step.title
	copy.day = step.day
	copy.is_pickup = step.is_pickup
	copy.grants_progress = step.grants_progress
	copy.placement = step.placement
	copy.task_event_id = step.task_event_id
	copy.target_kind = step.target_kind
	copy.is_one_place = step.is_one_place
	copy.deadline_fraction = step.deadline_fraction
	copy.needs_goal = step.needs_goal
	copy.brief = step.brief
	copy.header = step.header
	copy.applies_package_weight = step.applies_package_weight
	copy.completes_at_inner_radius = step.completes_at_inner_radius
	copy.is_a_guarded_band = step.is_a_guarded_band
	copy.trap_row = step.trap_row
	copy.trap_noun = step.trap_noun
	copy.at_a_front_door = step.at_a_front_door
	copy.lingers_after_handover = step.lingers_after_handover
	copy.rigs_within = step.rigs_within
	return copy

## M221, "a failed day leaves no chalk mark behind", on a mark whose next step is placed by
## `_begin_step()` running a second time in the same `_on_contact_completed()` call (day 9's door,
## which every task day shares). The player,
## asked whether a read mark should vanish at once or stay: "Stays crossed, until the day ends" —
## so the mark's own touched `ContactPoint` and its guard both stay standing through the rest of
## the attempt, the task expiring included, and both are let go — the contact freed outright, the
## guard's own tracking reference dropped — the moment the day is retried or a new one starts,
## which is what stops either from piling up.
func _test_a_completed_marks_own_contact_and_guard_survive_to_the_day_end(t) -> void:
	_build_city_in_a_new_run(t)
	# No task carries a deadline, so the director is handed a calendar whose door task does
	# (`use_steps()`): the same step, copied, that must be done by half the day.
	var mark := ResistanceSteps.by_index(7)
	var timed := _copy_of_step(ResistanceSteps.by_index(8))
	timed.deadline_fraction = 0.5
	var calendar: Array[ResistanceSteps.Step] = [mark, timed]
	var director := _director(t)
	director.use_steps(calendar)
	var the_day := _start_the_day(t, 9, director)
	var mark_contact := director.contact()
	var guards := _live("alley_robbery")
	var mark_guard := director.mark_guard()
	t.check(mark_contact != null, "day 9's mark has its own contact before it is touched")

	# The same signal a real touch fires (`ContactPoint._complete()`, already connected to
	# `_on_contact_completed()` by `_begin_step()`), so `is_done` is set the way play sets it.
	mark_contact.complete_now()
	t.check(director.current_step() == timed,
			"touching it activates the door perform the same day")

	t.check(not mark_contact.is_queued_for_deletion() and is_instance_valid(mark_contact),
			"the mark's own touched ContactPoint stays standing, crossed through")
	t.check(mark_contact.is_done, "showing chalk_mark_touched.svg")
	t.check(director.read_mark() == mark_contact, "tracked as the day's own read mark")
	t.check(director.contact() != mark_contact, "the perform's own contact is a fresh one")

	for guard in guards:
		t.check(not guard.is_finished and is_instance_valid(guard),
				"the mark's own guard stays too, not retired for the door")
	if mark_guard != null:
		t.check(director.mark_guard() == mark_guard, "still tracked as the mark's own")
	t.check(_live(EventCatalogue.task_guard().id).is_empty(),
			"the door stands no guard of its own: its trap comes to her once she crosses")

	# The door's task expiring (its deadline, or its rider gone) ends the task, not the day:
	# the read mark stays standing.
	director.tick(300.0)
	t.check(director.current_step() == null, "the door's task has expired")
	t.check(is_instance_valid(mark_contact) and not mark_contact.is_queued_for_deletion(),
			"the read mark still stands once the task it unlocked has expired")

	# The day is retried (the same shape a new day takes): the read mark is freed outright. The day
	# is not given back, so it offers no mark and no new guard: the old guard, still standing in the
	# street (`EventManager.clear()` retires it in the real game), is no longer tracked as today's.
	director.start_day(9, _rng(9, "resistance"), 300.0)
	t.check(mark_contact.is_queued_for_deletion(), "the read mark is freed at the day's end")
	t.check(director.read_mark() == null, "and no mark is tracked as read")
	if mark_guard != null:
		t.check(director.mark_guard() == null, "and the old guard is no longer tracked as today's")

	# The same day given back with the lost day places its own mark, with a guard of its own: a
	# fresh one, once the old one is retired as the real game's clear does.
	for guard in guards:
		_city.events.retire(guard)
	_city.run.resistance.give_back()
	var before := _live("alley_robbery")
	director.start_day(9, _rng(9, "resistance"), 300.0)
	t.check(_new_one("alley_robbery", before) != null,
			"and the retried day's mark is guarded afresh, not by the old guard")

	director.free()
	_end_the_day(the_day)

## velvet-plover, "a mark she has read is gone from every alley" — *"the mark now shows in all
## alleys -- once it is checked it shouldn't appear anywhere else."* A read mark stays, crossed
## through, until the day ends (*"Stays crossed, until the day ends"*), so this asks what answers
## the report: exactly one mark's touched picture is standing once she has read it, across several
## ordinary days in a row, none of them failed or retried.
func _test_a_read_mark_does_not_pile_up_across_several_ordinary_days(t) -> void:
	_build_city_in_a_new_run(t)
	var director := _director(t)
	# Day 6's mark is index 1, day 7's is 3, day 8's is 5 (`_test_step_selection`'s own
	# numbering) — each is a pickup, activated and then completed in turn.
	for day in [6, 7, 8]:
		director.start_day(day, _rng(day, "resistance"), 300.0)
		var before := _live_chalk_marks()
		t.check(before == 1, "day %d: exactly one mark stands before it is read (%d)"
				% [day, before])
		_read_the_mark(director)
		var after := _live_chalk_marks()
		t.check(after == 1,
				"day %d: reading it leaves it standing, crossed through, alone (%d)"
				% [day, after])
	director.free()

## Every live, not-yet-freed `ContactPoint` under `_city` whose own step is a pickup — the chalk
## mark's own shape, since a perform's contact rides invisibly on its rider and draws nothing
## (`ContactPoint._draw()`) and so is never "a mark shown in an alley" in the player's sense.
func _live_chalk_marks() -> int:
	var count := 0
	for child in _city.find_children("*", "", true, false):
		if child is ContactPoint and child.step != null and child.step.is_pickup \
				and not child.is_queued_for_deletion():
			count += 1
	return count

## `allow_held` (`docs/DECISIONS.md`, M181) skips `is_held_at()` outright, and `is_held_at()` is
## the half of "nothing on the home block" that covers the streets around it, not just the lot
## `is_on_home_block()` covers — so without `_place_at_a_door()`'s own home-border filter, a door
## on one of those streets would sit through the held carve-out along with the rest. Sweeps the
## same seed set `_test_no_alley_robbery_stands_near_the_doorstep` does; several draws per city
## (`_pick_reachable()` picks uniformly among every reachable door) rather than one, because a
## single draw could miss the one candidate that borders the home block even with the filter
## deleted. Seed 2295276695 is where a home-bordering door actually exists on day 9 — measure
## again with `tools/test.sh probes/<name>.gd` naming that seed and printing `RegionPlanner.
## plan_day`'s own doors against `StreetNetwork.around_blocks` if this ever needs re-checking.
func _test_the_door_task_never_borders_the_home_block(t) -> void:
	var seeds: Array[int] = [4242, 90210, 2295276695, 291862120, 314159, 555555]
	var day := 9
	var draws := 20
	var checked := 0
	for seed_value: int in seeds.slice(0, RULE_SEEDS):
		var run := _build_city_in_a_new_run(t, seed_value)
		var city := _city
		var closure_state := CityState.new()
		run.attempt_spend.city_state = closure_state
		closure_state.begin_day(city.map.block_plans, day)
		var closure_rng := RandomNumberGenerator.new()
		closure_rng.seed = hash("%d:closures:%d" % [seed_value, day])
		city.start_day(closure_state, day, closure_rng)
		var events_rng := RandomNumberGenerator.new()
		events_rng.seed = hash("%d:events:%d" % [seed_value, day])
		city.events.start_day(DaySpec.for_day(day), events_rng, [], city.map.doorstep_world_position())

		var home_border := city.map.network.around_blocks(
				Rect2i(city.map.home_block, Vector2i.ONE))
		var home_border_keys := {}
		for segment in home_border:
			home_border_keys[segment.key()] = true

		var director := _director(t)
		for draw in draws:
			var door_rng := RandomNumberGenerator.new()
			door_rng.seed = hash("%d:door:%d:%d" % [seed_value, day, draw])
			# The day's own draws, from the door stream: the mark, then the door its touch sends her
			# to — each draw a day of its own, as a retried day is, with the run as the dawn left it.
			run.resistance.completed_steps.clear()
			run.facts.completed_resistance_alley_tiles = []
			director.start_day(day, door_rng, 300.0)
			_read_the_mark(director)
			for guard in _live("alley_robbery"):
				city.events.retire(guard)
			var step := director.current_step()
			if step == null or step.target_kind != ResistanceSteps.TargetKind.DOOR:
				continue
			var at := director.contact_position()
			if at == Vector2.INF:
				continue
			checked += 1
			var segment := city.map.network.segment_containing(city.map.world_to_tile(at))
			var bordering := segment != null and home_border_keys.has(segment.key())
			t.check(not bordering,
					("seed %d day %d draw %d: the door task never sits on a segment bordering " +
					"the home block") % [seed_value, day, draw])
		director.free()
	t.check(checked > 0, "some (seed, draw) actually placed a door contact to check (%d)" % checked)

func _test_the_swing_task_sits_at_an_open_playground(t) -> void:
	_build_city_in_a_new_run(t)
	var state := CityState.new()
	state.begin_day(_city.map.block_plans, 12)
	_city.map.repaint(state)
	t.check(not _city.map.playgrounds.is_empty(),
			"the test city has at least one open playground, or this test checks nothing")

	var director := _director(t)
	director.start_day(12, _rng(12, "resistance"), 300.0)
	_read_the_mark(director)
	t.check(director.current_step() != null
			and director.current_step().index == _perform_on(12).index,
			"touching day 12's mark activates the swing perform")
	t.check(director.rider() == null, "the swing sits on a bare point, not a rider")

	var at := director.contact_position()
	var on_a_swing := false
	for rect in _city.map.playgrounds:
		if _city.map.world_to_tile(_city.map.swing_position(rect)) \
				== _city.map.world_to_tile(at):
			on_a_swing = true
			break
	t.check(on_a_swing, "exactly at one open park's own swing")
	var park := CityGenerator.swing_park(_city.map)
	var layout: BlockLayout = _city.map.block_layouts.get(park)
	t.check(layout != null and _city.map.world_to_tile(_city.map.swing_position(
			layout.playground)) == _city.map.world_to_tile(at),
			"and it is the park the city chose for day 12")

	director.free()

## **Day 12's park is forced open whatever its state** (PLAYTEST-119): every city has one park
## chosen for the swing, whose arc ends requisitioned; on day 12 it is a park — calm, with its
## playground, the only swing the task may go to — even when its arc took it days before, and on
## the days either side it is whatever its arc says. Once she has reached the swing it is taken,
## and it stays taken.
func _test_day_twelves_park_is_forced_open_whatever_its_state(t) -> void:
	var day := ResistanceSteps.swing_day()
	t.check(day == 12, "the swing is day 12's task")
	var forced := 0
	for seed_value in [SEED, 181000, 283947, 299785, 307704]:
		var map := CityGenerator.generate(seed_value)
		var park := CityGenerator.swing_park(map)
		t.check(park.x >= 0, "seed %d: the city chose a park for the swing" % seed_value)
		if park.x < 0:
			continue
		var plan: BlockPlan = map.block_plans[park]
		t.check(plan.starting_purpose() == GameEnums.BlockPurpose.PARK
				and plan.steps[plan.steps.size() - 1].purpose == GameEnums.BlockPurpose.REQUISITIONED,
				"seed %d: a park whose arc ends requisitioned" % seed_value)
		var state := CityState.new()
		state.begin_day(map.block_plans, day - 1)
		var before := state.purpose_of(map.block_plans, park)
		state.begin_day(map.block_plans, day)
		map.repaint(state)
		if before != GameEnums.BlockPurpose.PARK:
			forced += 1
		t.check(state.purpose_of(map.block_plans, park) == GameEnums.BlockPurpose.PARK
				and park in map.calm_blocks,
				"seed %d: on day 12 it is an open park (it was %s the day before)"
				% [seed_value, GameEnums.BlockPurpose.keys()[before]])
		var step := _perform_on(day)
		var pool := ResistanceSteps.target_candidates(step, map, null)
		var layout: BlockLayout = map.block_layouts[park]
		t.check(pool.size() == 1 and pool[0] == map.world_to_tile(map.swing_position(
				layout.playground)), "seed %d: its swing is the task's only place" % seed_value)
		t.check(state.take(map.block_plans, park, day)
				and state.purpose_of(map.block_plans, park) == GameEnums.BlockPurpose.REQUISITIONED,
				"seed %d: reaching the swing takes it" % seed_value)
		state.begin_day(map.block_plans, day + 1)
		t.check(state.purpose_of(map.block_plans, park) == GameEnums.BlockPurpose.REQUISITIONED,
				"seed %d: and it stays taken" % seed_value)
		var untaken := CityState.new()
		untaken.begin_day(map.block_plans, day + 1)
		t.check(not untaken.is_forced_open(park), "seed %d: open only on its own day" % seed_value)
	t.check(forced > 0, "some city's park was requisitioned before day 12 and forced open (%d)"
			% forced)

## Day 11: touching the mark sends her, by the red arrow, to the foot of one live mast; reaching it
## silences that mast now and on every later day, through the scar it leaves — planned through the
## real day order, since the masts are the day's own plans.
func _test_the_mast_task_silences_one_mast_for_the_rest_of_the_run(t) -> void:
	var run := _build_city_in_a_new_run(t)
	var day := 11
	run.header.day = day
	var state := CityState.new()
	run.attempt_spend.city_state = state
	state.begin_day(_city.map.block_plans, day)
	_city.start_day(state, day, _rng(day, "closures"))
	_city.events.start_day(DaySpec.for_day(day), _rng(day, "events"), [], _city.map.doorstep_world_position())
	var director := _director(t)
	director.start_day(day, _rng(day, "resistance"), 300.0)
	var mark := director.current_step()
	t.check(mark != null and mark.is_pickup, "day 11 offers a mark")
	_read_the_mark(director)
	var task := director.current_step()
	t.check(task != null and task.target_kind == ResistanceSteps.TargetKind.MAST,
			"touching it sends her to a mast")
	# The mast the contact stands at the foot of, read off the day's plans.
	var mast_id := ""
	for plan in _city.events.plans():
		var foot := _city.events.mast_foot(plan.mast_id) if plan.mast_id != "" else Vector2.INF
		if foot != Vector2.INF and director.contact_position().distance_to(foot) < 0.5:
			mast_id = plan.mast_id
	t.check(mast_id != "", "the contact stands on the foot of a live mast")
	t.check(director.red_arrow_target() == director.contact_position(),
			"and the red arrow points at it")

	director.contact().complete_now()
	var silenced_today := true
	for plan in _city.events.plans():
		if plan.mast_id == mast_id and not plan.silenced:
			silenced_today = false
	t.check(silenced_today, "reaching it silences that mast today")
	var others_live := false
	for plan in _city.events.plans():
		if plan.mast_id != "" and plan.mast_id != mast_id and not plan.silenced:
			others_live = true
	t.check(others_live, "and only that mast")

	# The next morning, planned from the run's own scars.
	var tomorrow := EventScheduler.place_masts(day + 1, _city.map, 0,
			PackedVector2Array(), run.attempt_spend.scars)
	var quiet_tomorrow := false
	var live_tomorrow := false
	for plan in tomorrow:
		if plan.mast_id == mast_id:
			quiet_tomorrow = plan.silenced
		elif not plan.silenced:
			live_tomorrow = true
	t.check(quiet_tomorrow, "it is still silenced the next day")
	t.check(live_tomorrow, "while the others speak")
	director.free()

## `weighted_mast_index()` is the draw `_place_at_a_mast()` makes among the masts already found
## reachable, so this reaches the weighting rule directly, over two tiles at fixed, known
## distances from her, rather than through a live day 11 — whose own reachable masts a small test
## city can offer as few as one of (`docs/DECISIONS.md`, M181, day 11's mast in the map's corner),
## too few to compare a near draw against a far one. No `_city` is needed for the draw itself, the
## same bare-map rig `_test_the_guard_never_lands_inside_a_building()` uses.
##
## Two tiles 2 and 10 tiles from her (64px, 320px): weight is `1/d^2`, so the near tile outweighs
## the far one 25 to 1, drawn clearly more often over many rolls and still, sometimes, not drawn.
func _test_the_mast_task_favors_the_near_mast(t) -> void:
	var map := CityGenerator.generate(SEED)
	var run := RunState.new()
	run.start_run(RUN_SEED)
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.setup(null, map, null, run)
	var doorstep_tile := map.world_to_tile(map.doorstep_world_position())
	var near_tile := doorstep_tile + Vector2i(2, 0)
	var far_tile := doorstep_tile + Vector2i(10, 0)
	var beside: Array[Vector2i] = [near_tile, far_tile]
	var player := _rig_player(t, map.tile_to_world(doorstep_tile))
	director.use_player(player)

	var draws := 300
	var near_drawn := 0
	var far_drawn := 0
	for i in draws:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("mast weight test %d" % i)
		var index := director.weighted_mast_index(beside, rng)
		if index == 0:
			near_drawn += 1
		elif index == 1:
			far_drawn += 1
	t.check(near_drawn > far_drawn * 3,
			("the 2-tile mast is drawn clearly more often than the 10-tile one (%d vs %d of %d " +
			"draws)") % [near_drawn, far_drawn, draws])
	t.check(far_drawn > 0, "and the 10-tile mast can still be drawn (%d of %d draws)"
			% [far_drawn, draws])

	# The same draw with nobody in the tree falls back to the doorstep, exactly where she is
	# standing above — so it favors the near tile exactly as strongly.
	player.free()
	var fallback_near := 0
	var fallback_far := 0
	for i in draws:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("mast weight fallback test %d" % i)
		var index := director.weighted_mast_index(beside, rng)
		if index == 0:
			fallback_near += 1
		elif index == 1:
			fallback_far += 1
	t.check(fallback_near > fallback_far * 3,
			("with no player in the tree, the doorstep fallback favors the near tile just as " +
			"clearly (%d vs %d of %d draws)") % [fallback_near, fallback_far, draws])

	director.free()
	run.free()

## On the mornings before day 10 the neighbor walks out of her building beside her and off along
## her street, away from her, with nothing pointing at them; from day 10 on there is no morning
## figure — on day 10 they are out in the city, and after it they are gone.
func _test_the_neighbor_leaves_for_work_until_the_raid(t) -> void:
	_build_city_in_a_new_run(t)
	var door := _city.map.doorstep_world_position()
	for day in [1, 5, ResistanceHappenings.NEIGHBOR_DAY - 1]:
		var director := _director(t)
		var before := _live("neighbor")
		director.start_day(day, _rng(day, "resistance"), 300.0)
		var neighbor := _new_one("neighbor", before)
		t.check(neighbor != null,
				"day %d: the neighbor leaves her building in the morning" % day)
		if neighbor:
			t.check(neighbor.global_position.distance_to(door) < 2.0 * Tuning.TILE_SIZE,
					"day %d: out of her own door, beside her" % day)
			t.check(neighbor.path.size() >= 2 and neighbor.path[neighbor.path.size() - 1]
					.distance_to(door) > 4.0 * Tuning.TILE_SIZE,
					"day %d: and walking off along her street" % day)
			t.check(director.red_arrow_target() == Vector2.INF,
					"day %d: and nothing points at them" % day)
			_city.events.retire(neighbor)
		director.free()
	for day in [ResistanceHappenings.NEIGHBOR_DAY, ResistanceHappenings.NEIGHBOR_DAY + 1, 13]:
		var director := _director(t)
		var before := _live("neighbor")
		director.start_day(day, _rng(day, "resistance"), 300.0)
		t.check(_new_one("neighbor", before) == null,
				"day %d: no neighbor leaves for work" % day)
		director.free()

## Day 10: the red arrow points at the neighbor, out in the city and walking home along a real walk
## that ends at her doorstep, about `ResistanceDirector.NEIGHBOR_WALK_HOME_SECONDS` of their walk away. Reached
## first, the neighbor runs and the task counts; reaching the door first, they are taken — the task
## is failed, and from the next day the wanted notice crosses their face out.
func _test_day_ten_sends_her_to_the_neighbor_walking_home(t) -> void:
	var run := _build_city_in_a_new_run(t)
	run.header.day = ResistanceHappenings.NEIGHBOR_DAY
	var director := _director_on_the_neighbor(t)
	var task := director.current_step()
	t.check(task != null and task.target_kind == ResistanceSteps.TargetKind.NEIGHBOR,
			"touching it sends her to the neighbor")
	var neighbor := director.rider()
	t.check(neighbor != null and neighbor.def.id == "neighbor" and neighbor.def.mobile,
			"who is out in the city, walking")
	t.check(neighbor != null and neighbor.def.shape != null,
			"with the row's own shape, which a copy has to carry by hand")
	if neighbor:
		var door := _city.map.doorstep_world_position()
		t.check(neighbor.path[neighbor.path.size() - 1].distance_to(door) < 1.0,
				"home, to her own door")
		var length := 0.0
		for i in range(1, neighbor.path.size()):
			length += neighbor.path[i - 1].distance_to(neighbor.path[i])
		var seconds := length / neighbor.def.speed
		t.check(absf(seconds - ResistanceDirector.NEIGHBOR_WALK_HOME_SECONDS)
				<= (ResistanceDirector.NEIGHBOR_WALK_BAND_TILES + 2) * Tuning.TILE_SIZE
				/ neighbor.def.speed,
				"a walk of about %.0fs (%.0fs)" % [ResistanceDirector.NEIGHBOR_WALK_HOME_SECONDS, seconds])
		t.check(director.red_arrow_target() == director.contact_position(),
				"and the red arrow points at them")
	director.contact().complete_now()
	t.check(neighbor != null and neighbor.is_leaving, "warned, the neighbor runs")
	t.check(task != null and task.index in run.resistance.completed_steps,
			"and the task counts")
	run.header.day = ResistanceHappenings.NEIGHBOR_DAY + 1
	t.check(not run.neighbor_was_taken(), "a warned neighbor is not taken")
	director.free()

	# The retry, in a run and a city of their own: the warning not given in time.
	var retry_run := _build_city_in_a_new_run(t)
	retry_run.header.day = ResistanceHappenings.NEIGHBOR_DAY
	var late := _director_on_the_neighbor(t)
	var walker := late.rider()
	t.check(walker != null, "the neighbor is walking home again on the retry")
	if walker:
		walker.transition(EventInstance.Phase.PARKED)
	late.tick(STEP)
	var warning := ResistanceSteps.warning_step()
	t.check(warning.index in retry_run.resistance.failed_steps,
			"reaching the door first, the neighbor is taken and the task is lost")
	t.check(late.current_step() == null and late.red_arrow_target() == Vector2.INF,
			"and nothing points anywhere any more")
	retry_run.header.day = ResistanceHappenings.NEIGHBOR_DAY + 1
	t.check(retry_run.neighbor_was_taken(), "from the next day the neighbor is taken")
	late.free()

## Day 10's raid: vans at her building and a patrol, arriving only once she is out of sight of her
## door, and never on her own sidewalk — the doorstep stays reachable along it.
func _test_the_raid_waits_at_her_building_with_the_doorstep_open(t) -> void:
	_build_city_in_a_new_run(t)
	var happenings := ResistanceHappenings.new()
	happenings.setup(_city, _city.map)
	happenings.start_day(ResistanceHappenings.NEIGHBOR_DAY)
	var door := _city.map.doorstep_world_position()
	happenings.tick(STEP, door, Vector2.ZERO)
	t.check(happenings.raid.is_empty(), "nothing arrives while she is at her door")
	_look_at(Rect2(door - Vector2(400.0, 400.0), Vector2(800.0, 800.0)))
	happenings.tick(STEP, door + Vector2(0.0, Tuning.OUT_OF_SIGHT + 64.0), Vector2.ZERO)
	t.check(happenings.raid.is_empty(), "or while any of it would be on screen")
	_look_at(Rect2())
	happenings.tick(STEP, door + Vector2(0.0, Tuning.OUT_OF_SIGHT + 64.0), Vector2.ZERO)
	var vans := 0
	var patrols := 0
	var door_tile := _city.map.world_to_tile(door)
	for instance in happenings.raid:
		if instance.def.id == "night_raid":
			vans += 1
			t.check(instance.def.pursuit == null, "a van at her door does not hunt")
			for tile in EventSpawner.obstructed_footprint(_city.map, instance.def,
					instance.global_position, Vector2.RIGHT):
				t.check(tile.y > door_tile.y + Tuning.SIDEWALK_WIDTH - 1,
						"a van's body is off her own sidewalk (%s)" % tile)
		elif instance.def.id == "police_patrol":
			patrols += 1
			t.check(instance.def.shape != null, "the patrol car keeps its shape")
	t.check(vans == 2 and patrols == 1, "two vans and a patrol at her building (%d, %d)"
			% [vans, patrols])
	for instance in happenings.raid:
		_city.events.retire(instance)
	happenings.start_day(ResistanceHappenings.NEIGHBOR_DAY + 1)
	happenings.tick(STEP, door + Vector2(0.0, Tuning.OUT_OF_SIGHT + 64.0), Vector2.ZERO)
	t.check(happenings.raid.is_empty(), "and only on day 10")

## Her street door: ordinary at day 10's start, sealed live the moment the raid actually arrives
## (PLAYTEST-131), and the scar it leaves is what every later day and a reloaded save read it
## from (`City._sync_home_door()`, `_test_the_sealed_door_stands_after_a_reload()` below).
func _test_the_raid_seals_her_street_door(t) -> void:
	# A run with no scar, as a fresh one has: `City.build()` reads the scars once, at boot, exactly
	# as a resumed run's own boot does (`_door_texture_for_today()`'s own doc).
	var run := _build_city_in_a_new_run(t)
	run.header.day = ResistanceHappenings.NEIGHBOR_DAY
	var happenings := ResistanceHappenings.new()
	happenings.setup(_city, _city.map)
	happenings.start_day(ResistanceHappenings.NEIGHBOR_DAY)
	var door := _city.map.doorstep_world_position()
	t.check(not _city.home_door_is_sealed(), "the door is ordinary at day 10's start")
	happenings.tick(STEP, door + Vector2(0.0, Tuning.OUT_OF_SIGHT + 64.0), Vector2.ZERO)
	t.check(_city.home_door_is_sealed(), "and sealed the moment the raid arrives, out of her sight")
	var sealed := false
	for scar in run.attempt_spend.scars:
		if String(scar["id"]) == City.SEALED_DOOR_SCAR:
			sealed = true
	t.check(sealed, "which leaves a scar for every later day to read")
	for instance in happenings.raid:
		_city.events.retire(instance)

## Sealed on day 11 and after a save/load: `City.build()` reads the run's scars once, at boot,
## which is what a resumed or reloaded run's own boot does — see `main.gd`'s two `_city.build()`
## call sites, both after the run has already loaded.
func _test_the_sealed_door_stands_after_a_reload(t) -> void:
	var run := RunState.new()
	run.start_run(RUN_SEED)
	run.attempt_spend.scars = [{"id": City.SEALED_DOOR_SCAR, "position": Vector2.ZERO, "since_day": 10}]
	var city: City = CITY_SCENE.instantiate()
	city.run = run
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	t.check(city.home_door_is_sealed(),
			"a boot whose scars already carry the seal starts the door sealed")
	city.free()
	run.free()

## A lost day 10 gives the scar back (the run's `run_parts.give_back()`) and the
## next dawn's own `_sync_home_door()` puts the ordinary door back, exactly the restore every
## other scar already gets.
func _test_a_lost_day_ten_restores_the_ordinary_door(t) -> void:
	var run := _build_city_in_a_new_run(t)
	run.header.day = ResistanceHappenings.NEIGHBOR_DAY
	var happenings := ResistanceHappenings.new()
	happenings.setup(_city, _city.map)
	happenings.start_day(ResistanceHappenings.NEIGHBOR_DAY)
	var door := _city.map.doorstep_world_position()
	happenings.tick(STEP, door + Vector2(0.0, Tuning.OUT_OF_SIGHT + 64.0), Vector2.ZERO)
	t.check(_city.home_door_is_sealed(), "sealed once the raid arrives")
	for instance in happenings.raid:
		_city.events.retire(instance)
	# The loss: the attempt's own scar is given back, the same way
	# the run's `run_parts.give_back()` restores every scar a lost day left.
	run.attempt_spend.scars.clear()
	var state := CityState.new()
	state.begin_day(_city.map.block_plans, ResistanceHappenings.NEIGHBOR_DAY)
	_city.start_day(state, ResistanceHappenings.NEIGHBOR_DAY,
			_rng(ResistanceHappenings.NEIGHBOR_DAY, "closures"))
	t.check(not _city.home_door_is_sealed(), "a lost day 10 restores the ordinary door")

## The neighbor's boarded window: absent before day 11, set on the one home-block building the
## door notch stands in front of from day 11's morning on — the third floor nearest the door,
## down the hall from her own door (PLAYTEST-131), always there since M185 fixes that building's
## own height at `City.HOME_BUILDING_WALL_ROWS` (4) wall rows or more — the same cell every later
## day and on a fresh load of the same seed. `SEED` (4242) is the seed PLAYTEST-134 found with
## only two wall rows before the fix.
func _test_the_neighbor_window_is_boarded_from_day_eleven(t) -> void:
	_build_city_in_a_new_run(t)
	var happenings := ResistanceHappenings.new()
	happenings.setup(_city, _city.map)
	var building := _city.home_door_building()
	t.check(building != null, "the door notch stands in front of exactly one home-block building")
	t.check(building.wall_tiles() >= 4,
			"seed %d: her own building has at least four wall rows (%d)" % [SEED, building.wall_tiles()])

	happenings.start_day(ResistanceHappenings.MARKET_DAY - 1)
	t.check(building.neighbor_window_col == -1, "unboarded the day before")

	happenings.start_day(ResistanceHappenings.MARKET_DAY)
	var col := building.neighbor_window_col
	t.check(col >= 0, "boarded from day 11's morning on")
	t.check(building.neighbor_window_row() == 3,
			"seed %d: on the third floor" % SEED)

	happenings.start_day(ResistanceHappenings.MARKET_DAY + 3)
	t.check(building.neighbor_window_col == col, "the same cell on every later day")

	var run := RunState.new()
	run.start_run(RUN_SEED)
	var reloaded: City = CITY_SCENE.instantiate()
	reloaded.run = run
	t.add_child(reloaded)
	reloaded.build(CityGenerator.generate(SEED))
	reloaded.board_neighbor_window()
	var reloaded_building := reloaded.home_door_building()
	t.check(reloaded_building.neighbor_window_col == col, "and the same cell on a fresh load")
	reloaded.free()
	run.free()

## Plans `day` on the test city through the real day order (the closures and the events) with
## `state` as the run's own city state, which the happenings read, and hands back the happenings of
## that day, started.
func _happenings_on_day(day: int, state: CityState) -> ResistanceHappenings:
	var run: RunState = _city.run
	run.header.day = day
	run.attempt_spend.city_state = state
	state.begin_day(_city.map.block_plans, day)
	_city.start_day(state, day, _rng(day, "closures"))
	_city.events.start_day(DaySpec.for_day(day), _rng(day, "events"), [], _city.map.doorstep_world_position())
	var happenings := ResistanceHappenings.new()
	happenings.setup(_city, _city.map)
	happenings.start_day(day)
	return happenings

## How far `point` is from `rect`, zero inside it.
func _distance_to_rect(point: Vector2, rect: Rect2) -> float:
	var nearest := Vector2(clampf(point.x, rect.position.x, rect.end.x),
			clampf(point.y, rect.position.y, rect.end.y))
	return point.distance_to(nearest)

## Day 11: the market is found gone — a commercial block whose arc was waiting to board up is
## boarded now, out of her sight, with the market stalls at its frontage gone from the day's plan,
## and it stays boarded. Nothing happens before she has walked a while; with nothing on her way by
## `ResistanceHappenings.MARKET_GONE_BY`, the nearest block she cannot see goes.
func _test_the_market_is_found_gone(t) -> void:
	_build_city_in_a_new_run(t)
	var state := CityState.new()
	var happenings := _happenings_on_day(ResistanceHappenings.MARKET_DAY, state)
	var door := _city.map.doorstep_world_position()
	var candidates := ResistanceHappenings.market_candidates(_city.map, state)
	t.check(not candidates.is_empty(),
			"the test city has a block waiting to board up, or this test checks nothing")
	happenings.tick(STEP, door, Vector2.ZERO)
	t.check(happenings.market_block.x < 0, "nothing is gone before she has walked anywhere")
	# She walks for as long as the market waits for a way to be chosen, and it has been that long.
	happenings.tick(ResistanceHappenings.MARKET_GONE_BY, door, Vector2.RIGHT * Tuning.WALK_SPEED)
	var block := happenings.market_block
	t.check(block in candidates, "by then a block waiting to board up is gone (%s)" % block)
	if block.x >= 0:
		var frontage := happenings.frontage_of(block)
		t.check(_distance_to_rect(door, frontage) >= Tuning.OUT_OF_SIGHT,
				"out of her sight")
		t.check(state.purpose_of(_city.map.block_plans, block)
				== GameEnums.BlockPurpose.BOARDED_UP, "boarded up now")
		var shuttered := 0
		for building in _city.buildings():
			if _city.map.lot_rect(block).has_point(building.lot.position):
				t.check(building.condition == Building.Condition.BOARDED,
						"every building of it shuttered")
				shuttered += 1
		t.check(shuttered > 0, "and it has buildings to shutter")
		for plan in _city.events.plans():
			if plan.def.id == "market_stall" and frontage.has_point(plan.position):
				t.check(plan.spent or (plan.live and plan.live.is_finished),
						"no market stall of it is left in the day")
		state.begin_day(_city.map.block_plans, ResistanceHappenings.MARKET_DAY + 1)
		t.check(state.purpose_of(_city.map.block_plans, block)
				== GameEnums.BlockPurpose.BOARDED_UP, "and it stays boarded")
	happenings.tick(STEP, door, Vector2.ZERO)
	t.check(happenings.market_block == block, "and the market is gone once")

## Day 13: the column. The convoys start that morning; the column is `Tuning.COLUMN_TRUCKS` trucks
## in one lane of the main road, warned of first: its badge goes up with no truck in the world, its
## place in the lane just off screen level with her, and the trucks arrive there once the row's
## telegraph is over, coming toward the point level with her. The rear one stops out of her sight —
## beyond her, or short of her where nothing beyond will do — on a street rather than a junction,
## where its barricade still leaves her a way home; the trucks ahead of it leave nothing. It comes
## once she nears the main road, or at `ResistanceHappenings.COLUMN_BY` wherever she is, and once.
func _test_the_column_comes_down_the_main_road(t) -> void:
	var convoy := EventCatalogue.by_id("military_convoy")
	_build_city_in_a_new_run(t)
	var state := CityState.new()
	var happenings := _happenings_on_day(ResistanceHappenings.COLUMN_DAY, state)
	var map := _city.map
	var door := map.doorstep_world_position()
	var spine := happenings.spine_x()
	var far_from_it := Vector2(spine + ResistanceHappenings.COLUMN_WITHIN * 2.0, door.y)
	# She has walked as long as a way takes to be chosen, far from the road.
	happenings.tick(EventDirector.ON_HER_WAY_AFTER, far_from_it, Vector2.RIGHT * Tuning.WALK_SPEED)
	t.check(happenings.column.is_empty(), "nothing comes while she is far from the main road")
	var her := Vector2(spine - Tuning.STREET_WIDTH * 0.5 * Tuning.TILE_SIZE + Tuning.TILE_SIZE,
			map.size.y * Tuning.TILE_SIZE * 0.5)
	happenings.tick(STEP, her, Vector2.ZERO)
	t.check(happenings.column.is_empty(),
			"near it, the column's warning goes up with no truck in the world yet")
	var warning := _warning_for(_city.events, "military_convoy")
	t.check(warning != null, "and its badge has somewhere to point")
	var lead := SpawnSiting.least_distance()
	if warning:
		t.check(CrowdLanes.corridor_at(warning.place.x) == _city.map.main_road,
				"pointing up the main road")
		t.check(warning.left <= Tuning.WARNING_ALONE_MAX,
				"for at most a second alone (%.2fs)" % warning.left)
		# She walks along the road while it is coming: the badge keeps its offset from her.
		var was := warning.place - her
		her.y += Tuning.WALK_SPEED * 0.5
		_city.events.warnings.run(STEP, her)
		t.check((warning.place - her).is_equal_approx(was),
				"and it holds still against her rather than coming sooner or jumping")
	# The rest of the warning, frame by frame, the way `EventManager._physics_process` runs it.
	while warning and _city.events.pending_warnings().has(warning) \
			and warning.shown < Tuning.WARNING_ALONE_MAX + 5.0:
		_city.events.warnings.run(STEP, her)
	var trucks := happenings.column
	t.check(trucks.size() == Tuning.COLUMN_TRUCKS,
			"once the warning is over, a column of %d trucks comes (%d)"
			% [Tuning.COLUMN_TRUCKS, trucks.size()])
	var edge := minf(her.y, map.size.y * Tuning.TILE_SIZE - her.y) - Tuning.TILE_SIZE
	var leaving := 0
	for i in trucks.size():
		var truck := trucks[i]
		t.check(truck.def.id == "military_convoy" and truck.path.size() == 2,
				"each is the catalogue's own truck on a path")
		t.check(CrowdLanes.corridor_at(truck.path[0].x) == map.main_road
				and is_equal_approx(truck.path[0].x, truck.path[1].x),
				"in one lane of the main road")
		t.check(truck.path[0].distance_to(her) >= minf(lead, edge) - 1.0,
				"far enough up the road (%.0fpx)" % truck.path[0].distance_to(her))
		if truck.def.aftermath.on_finish != "":
			leaving += 1
			var stop := truck.path[1]
			t.check(i == trucks.size() - 1, "only the rear truck leaves anything")
			t.check(stop.distance_to(her) >= Tuning.OUT_OF_SIGHT,
					"and it stops out of her sight")
			t.check(map.network.segment_containing(map.world_to_tile(stop)) != null,
					"on a street, not a junction")
	t.check(leaving == 1, "one barricade's worth, from the rear truck (%d)" % leaving)
	# **Where the front truck is created and how long after the badge it can reach her, on the
	# real siting.** Its forward reach (395px) is deeper than the view is from her, so standing
	# by its road she may be inside its field from its first frame: what she is owed is the
	# warning before it existed, at least the row's own minimum (`EventDef.minimum_telegraph()`),
	# from the badge to the first frame its field reaches her.
	if warning and not trucks.is_empty():
		var front := trucks[0]
		t.check(SpawnSiting.is_out_of_sight(VisibleView.around(her, null),
				EventFootprints.footprint_of(front.def), her, front.global_position)
				and absf(front.global_position.x - warning.place.x) < 1.0
				and signf(front.global_position.y - her.y) == signf(warning.place.y - her.y),
				"its front truck is created just out of sight, up the lane the badge pointed")
		var to_reach := 0.0
		while front.excitement.contribution_at(her) <= 0.0 and to_reach < 10.0:
			front.player_at = her
			front.step(STEP)
			to_reach += STEP
		t.check(warning.shown + to_reach + 0.001 >= warning.def.minimum_telegraph(),
				("and from the badge to the earliest its field reaches her is %.2fs, at least "
				% (warning.shown + to_reach))
				+ "the %.2fs it is owed" % warning.def.minimum_telegraph())
	happenings.tick(STEP, her, Vector2.ZERO)
	t.check(happenings.column.size() == Tuning.COLUMN_TRUCKS, "and it comes once")
	for truck in trucks:
		_city.events.retire(truck)

	happenings.start_day(ResistanceHappenings.COLUMN_DAY)
	happenings.tick(ResistanceHappenings.COLUMN_BY, far_from_it, Vector2.ZERO)
	_city.events.warnings.run(convoy.telegraph_time + STEP, far_from_it)
	t.check(happenings.column.size() == Tuning.COLUMN_TRUCKS,
			"at COLUMN_BY it comes wherever she is")
	for truck in happenings.column:
		_city.events.retire(truck)
