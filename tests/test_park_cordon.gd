extends RefCounted
## Day 12's park closed by a police cordon (`ParkCordon`) once she has reached its swing.
##
## The player's words *(azure-puffin, inbox #666: "the park "closing down" is not diegetic -- the
## material changes in front of the player"; "(B) for the park with the added danger that you can
## get trapped inside (which would end the day). the policemen must come from offscreen"; and
## "Cordon closes round the edge (Recommended)")*. A real `City` stands under every check, with the
## day planned and the swing's task reached through the director, as play reaches it.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const STEP := 1.0 / 60.0
## How long a check waits for the cordon to close before calling it stuck.
const PATIENCE := 40.0
## How long she stands at the swing before she walks out in the walking check: time to see the
## officers and decide, on top of the walk itself.
const REACTION := 2.0

var _city: City

func run(t) -> void:
	_city = CITY_SCENE.instantiate()
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))
	_test_reaching_the_swing_sends_the_police_and_the_ground_stays_grass(t)
	_test_the_officers_come_from_out_of_her_sight_and_walk_into_it(t)
	_test_the_open_edge_shrinks_to_one_gap_nearest_her(t)
	_test_standing_at_the_swing_shuts_her_in_and_ends_the_day(t)
	_test_walking_out_from_the_swing_gets_her_out_in_time(t)
	_test_a_taped_stretch_is_solid_and_no_tape_goes_up_through_her(t)
	_test_the_parks_people_are_walked_out(t)
	_test_the_park_stays_taken_and_the_cordon_goes_with_the_day(t)
	_city.free()

# ------------------------------------------------------------------ fixture ---

## Day 12 on the suite's city with the mark read and the swing's task offered; `before_the_touch`
## runs before she reaches the swing. Answers the director, its happenings, the park, the swing and
## the city state, with the run's state put back by `_end()`.
func _at_the_swing(t, before_the_touch := Callable()) -> Dictionary:
	var saved := {
		"state": GameState.city_state, "day": GameState.day,
		"completed": GameState.completed_resistance_steps.duplicate(),
		"failed": GameState.failed_resistance_steps.duplicate(),
		"progress": GameState.resistance_progress,
		"package": GameState.resistance_carrying_package,
	}
	GameState.completed_resistance_steps = []
	GameState.failed_resistance_steps = []
	GameState.resistance_progress = 0
	GameState.resistance_carrying_package = false
	var day := ResistanceSteps.swing_day()
	GameState.day = day
	var state := CityState.new()
	GameState.city_state = state
	state.begin_day(_city.map.block_plans, day)
	_city.start_day(state, day, _rng(day, "closures"))
	_city.events.start_day(day, _rng(day, "events"), [], _city.map.doorstep_world_position())
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(_city, _city.map)
	director.start_day(day, _rng(day, "resistance"), 300.0)
	var mark := director.current_step()
	director._on_contact_completed(mark.index if mark else -1)
	var task := director.current_step()
	t.check(task != null and task.target_kind == ResistanceSteps.TargetKind.PARK_SWING,
			"day 12 sends her to the swing")
	var swing := director.contact_position()
	if before_the_touch.is_valid():
		before_the_touch.call()
	director._on_contact_completed(task.index if task else -1)
	return {"director": director, "happenings": director._happenings, "state": state,
			"park": CityGenerator.swing_park(_city.map), "swing": swing, "day": day,
			"saved": saved}

func _end(fixture: Dictionary) -> void:
	(fixture.director as ResistanceDirector).free()
	var saved: Dictionary = fixture.saved
	GameState.city_state = saved.state
	GameState.day = saved.day
	GameState.completed_resistance_steps = saved.completed
	GameState.failed_resistance_steps = saved.failed
	GameState.resistance_progress = saved.progress
	GameState.resistance_carrying_package = saved.package

func _rng(day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [SEED, day, stream])
	return rng

## What the camera sees with her at `her[0]`: the game's own view box round her, against the whole
## of what `row` draws standing at `feet` — `ResistanceDirector._drawing_shows()`'s question.
func _camera_on(her: Array) -> Callable:
	return func(row: EventDef, feet: Vector2) -> bool:
		var centre: Vector2 = her[0]
		var view := Rect2(centre - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
		var box := EventInstance.footprint_of(row)
		if not box.has_area():
			return view.has_point(feet)
		return view.intersects(Rect2(feet + box.position, box.size))

## Ticks the day's happenings with her at `her[0]`, `step_her` moving her first each frame, until
## the cordon closes or `PATIENCE` runs out.
func _run_until_closed(happenings: ResistanceHappenings, her: Array, shows: Callable,
		step_her := Callable(), each_frame := Callable()) -> void:
	var waited := 0.0
	while happenings.is_closing() and waited < PATIENCE:
		if step_her.is_valid():
			step_her.call(STEP)
		happenings.tick(STEP, her[0], Vector2.ZERO, shows)
		if each_frame.is_valid():
			each_frame.call()
		waited += STEP

func _listen_for_hard_fails() -> Array:
	var fails: Array[String] = []
	var listen := func(reason: String) -> void:
		fails.append(reason)
	EventBus.hard_fail_triggered.connect(listen)
	return [fails, listen]

func _stop_listening(listener: Array) -> void:
	EventBus.hard_fail_triggered.disconnect(listener[1])

# ------------------------------------------------------------------- checks ---

## Reaching the swing takes the park, as before — requisitioned and no longer calm — and starts the
## cordon rather than mud: no tile of its ground changes, during the closing or after it.
func _test_reaching_the_swing_sends_the_police_and_the_ground_stays_grass(t) -> void:
	var fixture := _at_the_swing(t)
	var state: CityState = fixture.state
	var park: Vector2i = fixture.park
	var happenings: ResistanceHappenings = fixture.happenings
	t.check(state.purpose_of(_city.map.block_plans, park) == GameEnums.BlockPurpose.REQUISITIONED,
			"reaching the swing takes the park")
	t.check(not (park in _city.map.calm_blocks), "and the city stops counting it as calm")
	t.check(happenings.cordon != null and happenings.is_closing(),
			"and the police are sent to cordon it")
	var rect := ClosurePlanner.calm_area_rect(_city.map, park)
	var before := {}
	for tile in _city.map.rect_tiles(rect):
		before[tile] = _city.map.tile_at(tile)
	var outside := happenings.cordon.area.get_center() + Vector2(happenings.cordon.area.size.x, 0.0)
	_run_until_closed(happenings, [outside], Callable())
	t.check(not happenings.is_closing(), "the cordon closes")
	var changed := 0
	for tile: Vector2i in before:
		if _city.map.tile_at(tile) != before[tile]:
			changed += 1
	t.check(changed == 0, "and not one tile of the park's ground changed (%d of %d)"
			% [changed, before.size()])
	_end(fixture)

## Nothing of an officer is in the camera's view where he is placed; each then walks into it, so
## his arrival is what she sees of the cordon coming.
func _test_the_officers_come_from_out_of_her_sight_and_walk_into_it(t) -> void:
	var fixture := _at_the_swing(t)
	var happenings: ResistanceHappenings = fixture.happenings
	var her := [fixture.swing]
	var shows := _camera_on(her)
	var row := EventCatalogue.by_id(ParkCordon.OFFICER_ROW)
	happenings.tick(STEP, her[0], Vector2.ZERO, shows)
	var cordon := happenings.cordon
	var tapers := 0
	var unseen := 0
	for officer in cordon.officers:
		if officer.job == ParkCordon.Officer.Job.TAPE:
			tapers += 1
		if not shows.call(row, officer.at):
			unseen += 1
	t.check(tapers == 2, "two officers come to tape it (%d)" % tapers)
	t.check(unseen == cordon.officers.size(),
			"and every officer is placed with none of him in the camera's view (%d of %d)"
			% [unseen, cordon.officers.size()])
	var seen := {}
	var each_frame := func() -> void:
		for officer in cordon.officers:
			if officer.phase != ParkCordon.Officer.Phase.GONE and shows.call(row, officer.at):
				seen[officer] = true
	_run_until_closed(happenings, her, shows, Callable(), each_frame)
	t.check(seen.size() == cordon.officers.size(),
			"and each walks into her view on his way to the edge (%d of %d)"
			% [seen.size(), cordon.officers.size()])
	_end(fixture)

## The tape goes up a stretch at a time from where the officers arrived, both ways round, so what
## is open of the edge is always one gap, and the last of it is taped nearest where she stood.
func _test_the_open_edge_shrinks_to_one_gap_nearest_her(t) -> void:
	var fixture := _at_the_swing(t)
	var happenings: ResistanceHappenings = fixture.happenings
	var swing: Vector2 = fixture.swing
	# She is outside the park, on the side of it the swing is nearest, so she is not shut in and the
	# gap is still decided by where she stood at the touch.
	var her := [swing]
	happenings.tick(STEP, her[0], Vector2.ZERO, Callable())
	var cordon := happenings.cordon
	var gap := cordon.last_gap
	her[0] = gap + (gap - cordon.area.get_center()).normalized() * Tuning.TILE_SIZE * 3.0
	# Lambdas capture locals by value, so what they count lives in a dictionary.
	var seen := {"most_gaps": 0, "last": null, "taped": {}}
	var watch := func() -> void:
		for stretch in cordon.stretches:
			if stretch.taped and not (seen.taped as Dictionary).has(stretch):
				(seen.taped as Dictionary)[stretch] = true
				seen.last = stretch
		seen.most_gaps = maxi(seen.most_gaps, _gaps_in(cordon))
	_run_until_closed(happenings, her, Callable(), Callable(), watch)
	t.check(not happenings.is_closing(), "the cordon closes")
	t.check(seen.most_gaps == 1, "and the open edge is one gap the whole time (at most %d)"
			% seen.most_gaps)
	var last: ParkCordon.Stretch = seen.last
	var nearest := INF
	for stretch in cordon.stretches:
		nearest = minf(nearest, Geometry2D.get_closest_point_to_segment(swing, stretch.a,
				stretch.b).distance_to(swing))
	var last_distance := Geometry2D.get_closest_point_to_segment(swing, last.a, last.b) \
			.distance_to(swing) if last else INF
	t.check(last_distance <= nearest + Tuning.TILE_SIZE * 1.5,
			"the last stretch taped is beside the edge nearest the swing (%.0fpx, nearest %.0fpx)"
			% [last_distance, nearest])
	_end(fixture)

## How many separate runs of open stretches the edge has, going round it.
func _gaps_in(cordon: ParkCordon) -> int:
	var open: Array[bool] = []
	for stretch in cordon.stretches:
		if stretch.needed:
			open.append(not stretch.taped)
	var runs := 0
	for i in open.size():
		if open[i] and not open[(i - 1 + open.size()) % open.size()]:
			runs += 1
	if runs == 0 and not open.is_empty() and open[0]:
		runs = 1
	return runs

## Standing at the swing: the last gap is taped with her inside, `Tuning.PARK_CLOSING_SECONDS`
## after the touch, and that ends the day with the cordon's own reason, which has a sentence.
func _test_standing_at_the_swing_shuts_her_in_and_ends_the_day(t) -> void:
	var listener := _listen_for_hard_fails()
	var fixture := _at_the_swing(t)
	var happenings: ResistanceHappenings = fixture.happenings
	var her := [fixture.swing]
	_run_until_closed(happenings, her, _camera_on(her))
	var cordon := happenings.cordon
	t.check(cordon.is_closed() and cordon.trapped, "standing at the swing, she is shut in")
	t.check(cordon.closed_at >= Tuning.PARK_CLOSING_SECONDS - 0.05
			and cordon.closed_at <= Tuning.PARK_CLOSING_SECONDS + 0.5,
			"the last gap is taped about %.0fs after the touch (%.1fs)"
			% [Tuning.PARK_CLOSING_SECONDS, cordon.closed_at])
	var fails: Array[String] = listener[0]
	t.check(fails.size() == 1 and fails[0] == ParkCordon.TRAPPED,
			"and it ends the day as the cordon's own hard fail (%s)" % [fails])
	t.check(DayController._HARD_FAIL_TEXT.has(ParkCordon.TRAPPED),
			"which the day's end has a sentence for")
	_stop_listening(listener)
	_end(fixture)

## Walking, not running, from the swing to the nearest edge after `REACTION` gets her out through
## the gap before it closes, and the gap she walks through is open when she crosses the tape's line.
func _test_walking_out_from_the_swing_gets_her_out_in_time(t) -> void:
	var listener := _listen_for_hard_fails()
	var fixture := _at_the_swing(t)
	var happenings: ResistanceHappenings = fixture.happenings
	var swing: Vector2 = fixture.swing
	var her := [swing]
	happenings.tick(STEP, her[0], Vector2.ZERO, _camera_on(her))
	var cordon := happenings.cordon
	var exit := cordon.last_gap
	var out := exit + (exit - swing).normalized() * (Tuning.CLOSURE_BARRIER_DEPTH + Tuning.TILE_SIZE)
	var clock := [STEP]
	var crossed := [-1.0, false]
	var step_her := func(delta: float) -> void:
		clock[0] += delta
		if clock[0] < REACTION:
			return
		var was_inside := cordon.line.has_point(her[0])
		var next: Vector2 = (her[0] as Vector2).move_toward(out, Tuning.WALK_SPEED * delta)
		her[0] = next
		if was_inside and not cordon.line.has_point(next) and crossed[0] < 0.0:
			crossed[0] = clock[0]
			for stretch in cordon.stretches:
				if stretch.taped and ParkCordon._body_on(stretch, next):
					crossed[1] = true
	_run_until_closed(happenings, her, _camera_on(her), step_her)
	t.check(cordon.is_closed() and not cordon.trapped,
			"walking out from the swing after %.0fs, she is outside when the last gap closes" % REACTION)
	t.check(crossed[0] > 0.0 and crossed[0] < cordon.closed_at,
			"she crossed the line at %.1fs, before it closed at %.1fs (the walk: %.0fpx)"
			% [crossed[0], cordon.closed_at, swing.distance_to(exit)])
	t.check(not crossed[1], "through a gap with no tape in it")
	var fails: Array[String] = listener[0]
	t.check(fails.is_empty(), "and nothing ends the day (%s)" % [fails])
	_stop_listening(listener)
	_end(fixture)

## Each taped stretch stands a static body the length of the stretch on its line, and its edge
## tiles are recorded as obstructed. An officer whose stretch she is standing in waits until she
## has stepped off it.
func _test_a_taped_stretch_is_solid_and_no_tape_goes_up_through_her(t) -> void:
	var fixture := _at_the_swing(t)
	var happenings: ResistanceHappenings = fixture.happenings
	var her := [fixture.swing]
	happenings.tick(STEP, her[0], Vector2.ZERO, Callable())
	var cordon := happenings.cordon
	her[0] = cordon.last_gap
	var waited := 0.0
	while waited < PATIENCE:
		happenings.tick(STEP, her[0], Vector2.ZERO, Callable())
		waited += STEP
	t.check(happenings.is_closing(), "while she stands in the last gap, it stays open (%.0fs)"
			% PATIENCE)
	var holding := 0
	for officer in cordon.officers:
		if officer.holding:
			holding += 1
	t.check(holding >= 1, "an officer waits beside her (%d)" % holding)
	her[0] = cordon.last_gap + (cordon.last_gap - cordon.area.get_center()).normalized() \
			* Tuning.TILE_SIZE * 2.0
	_run_until_closed(happenings, her, Callable())
	t.check(cordon.is_closed() and not cordon.trapped,
			"once she steps out of it, it is taped with her outside")
	var bodies := 0
	var covered := 0
	var obstructed := 0
	var needed := 0
	for stretch in cordon.stretches:
		if not stretch.needed:
			continue
		needed += 1
		var tape := stretch.node
		if not tape:
			continue
		var has_body := false
		for child in tape.get_children():
			if child is StaticBody2D:
				has_body = true
		if has_body:
			bodies += 1
		var box := tape.body_rect().grow(0.5)
		if box.has_point(stretch.a) and box.has_point(stretch.b):
			covered += 1
		var all_obstructed := true
		for tile in stretch.tiles:
			all_obstructed = all_obstructed and _city.map.is_obstructed(tile)
		if all_obstructed:
			obstructed += 1
	t.check(needed > 0 and bodies == needed, "every taped stretch is solid (%d of %d)"
			% [bodies, needed])
	t.check(covered == needed, "along the whole of its stretch (%d of %d)" % [covered, needed])
	t.check(obstructed == needed, "and its edge tiles are obstructed (%d of %d)"
			% [obstructed, needed])
	_end(fixture)

## Someone standing in the park when the cordon starts is walked out: an officer goes to them and
## they leave.
func _test_the_parks_people_are_walked_out(t) -> void:
	var person: Array = [null]
	var fixture := _at_the_swing(t, func() -> void:
		var park := CityGenerator.swing_park(_city.map)
		var area := _city.map.tile_rect_to_world(ClosurePlanner.calm_area_rect(_city.map, park))
		person[0] = _city.events.spawn_extra(EventCatalogue.by_id("busker"),
				area.position + area.size * Vector2(0.25, 0.3)))
	var happenings: ResistanceHappenings = fixture.happenings
	var her := [fixture.swing]
	var busker: EventInstance = person[0]
	t.check(busker != null and not busker.is_leaving, "a busker stands in the park")
	var shows := _camera_on(her)
	happenings.tick(STEP, her[0], Vector2.ZERO, shows)
	var escorts := 0
	for officer in happenings.cordon.officers:
		if officer.job == ParkCordon.Officer.Job.ESCORT and officer.person == busker:
			escorts += 1
	t.check(escorts == 1, "an officer is sent for him (%d)" % escorts)
	var waited := 0.0
	while waited < PATIENCE and is_instance_valid(busker) and not busker.is_leaving:
		happenings.tick(STEP, her[0], Vector2.ZERO, shows)
		waited += STEP
	t.check(is_instance_valid(busker) and busker.is_leaving,
			"who reaches him and walks him out (%.1fs)" % waited)
	_end(fixture)

## The park stays requisitioned the next morning, and the cordon's nodes and obstructed tiles go
## with the day.
func _test_the_park_stays_taken_and_the_cordon_goes_with_the_day(t) -> void:
	var fixture := _at_the_swing(t)
	var happenings: ResistanceHappenings = fixture.happenings
	var her := [Vector2.INF]
	_run_until_closed(happenings, her, Callable())
	var cordon := happenings.cordon
	var tapes: Array[CordonTape] = []
	var tiles: Array[Vector2i] = []
	for stretch in cordon.stretches:
		if stretch.node:
			tapes.append(stretch.node)
		tiles.append_array(stretch.tiles)
	t.check(not tapes.is_empty(), "the cordon stands in the city")
	var day: int = fixture.day
	var state: CityState = fixture.state
	state.begin_day(_city.map.block_plans, day + 1)
	t.check(state.purpose_of(_city.map.block_plans, fixture.park)
			== GameEnums.BlockPurpose.REQUISITIONED, "the park stays taken")
	happenings.start_day(day + 1)
	var standing := 0
	for tape in tapes:
		if is_instance_valid(tape) and not tape.is_queued_for_deletion():
			standing += 1
	var still_obstructed := 0
	for tile in tiles:
		if _city.map.is_obstructed(tile):
			still_obstructed += 1
	t.check(standing == 0 and happenings.cordon == null,
			"and the next morning the cordon's tape is gone with the day (%d left)" % standing)
	t.check(still_obstructed == 0, "with every tile it obstructed given back (%d left)"
			% still_obstructed)
	_end(fixture)
