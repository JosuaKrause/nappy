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
## Where the swing is, set by `_at_the_swing()` before it runs its `before_the_touch`.
var _swing_now := Vector2.ZERO

func run(t) -> void:
	_city = RunCity.of_the_run(CITY_SCENE)
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))
	_test_reaching_the_swing_sends_the_police_and_the_ground_stays_grass(t)
	_test_the_officers_come_from_out_of_her_sight_and_walk_into_it(t)
	_test_the_open_edge_shrinks_to_one_gap_nearest_her(t)
	_test_standing_at_the_swing_shuts_her_in_and_ends_the_day(t)
	_test_walking_out_from_the_swing_gets_her_out_in_time(t)
	_test_a_taped_stretch_is_solid_and_no_tape_goes_up_through_her(t)
	_test_no_tape_goes_up_through_the_pram(t)
	_test_the_parks_people_are_walked_out_through_the_gap(t)
	_test_a_person_walked_out_never_ends_in_her_view(t)
	_test_someone_already_leaving_is_walked_out_through_the_gap(t)
	_test_an_escort_sent_back_alone_holds_the_gap(t)
	_test_the_park_stays_taken_and_the_cordon_goes_with_the_day(t)
	_city.free()

# ------------------------------------------------------------------ fixture ---

## Day 12 on the suite's city with the mark read and the swing's task offered; `before_the_touch`
## runs before she reaches the swing. Answers the director, its happenings, the park, the swing and
## the city state, with the run's state put back by `_end()`.
func _at_the_swing(t, before_the_touch := Callable()) -> Dictionary:
	var saved := {
		"state": GameState.attempt_spend.city_state, "day": GameState.header.day,
		"completed": GameState.resistance.completed_steps.duplicate(),
		"failed": GameState.resistance.failed_steps.duplicate(),
		"progress": GameState.resistance.progress,
		"package": GameState.resistance.carrying_package,
	}
	GameState.resistance.completed_steps = []
	GameState.resistance.failed_steps = []
	GameState.resistance.progress = 0
	GameState.resistance.carrying_package = false
	var day := ResistanceSteps.swing_day()
	GameState.header.day = day
	var state := CityState.new()
	GameState.attempt_spend.city_state = state
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
	_swing_now = swing
	if before_the_touch.is_valid():
		before_the_touch.call()
	director._on_contact_completed(task.index if task else -1)
	return {"director": director, "happenings": director._happenings, "state": state,
			"park": CityGenerator.swing_park(_city.map), "swing": swing, "day": day,
			"saved": saved}

func _end(fixture: Dictionary) -> void:
	(fixture.director as ResistanceDirector).free()
	var saved: Dictionary = fixture.saved
	GameState.attempt_spend.city_state = saved.state
	GameState.header.day = saved.day
	GameState.resistance.completed_steps = saved.completed
	GameState.resistance.failed_steps = saved.failed
	GameState.resistance.progress = saved.progress
	GameState.resistance.carrying_package = saved.package

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
## is open of the edge is always one gap, and the last of it is taped nearest where she stood (on
## this seed's park every edge leads home, so the nearest of all).
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

## Standing at the swing: the last gap is taped with her inside — on this seed's small park, where
## an officer is in her view almost at once, `Tuning.PARK_CLOSING_SECONDS` after the touch — and
## that ends the day with the cordon's own reason, which has a sentence.
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
	t.check(Texts.HARD_FAIL_TEXT.has(ParkCordon.TRAPPED),
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

## **No tape goes up through the pram.** She stands facing the line just short of the last gap,
## from outside nosing in and from inside about to leave, at 20 to 26px, where her body clears the
## tape and the pram's circle (`Stroller.PRAM_BODY_RADIUS`, 8px, centred 14px out along her
## facing) does not: no stretch is taped while any of her collision shape would overlap its body,
## so the gap waits for her.
func _test_no_tape_goes_up_through_the_pram(t) -> void:
	var fixture := _at_the_swing(t)
	var happenings: ResistanceHappenings = fixture.happenings
	var director: ResistanceDirector = fixture.director
	happenings.tick(STEP, fixture.swing, Vector2.ZERO, Callable())
	var first := happenings.cordon
	var stretch: ParkCordon.Stretch = first.gap[0]
	var middle := (stretch.a + stretch.b) * 0.5
	var outward := Vector2(stretch.outward)
	first.clear()
	var cases := 0
	var through := 0
	var held := 0
	for distance: float in [20.0, 22.0, 24.0, 26.0]:
		for side: float in [1.0, -1.0]:
			# Outside she faces in; inside she faces out: the pram toward the line either way.
			var her: Vector2 = middle + outward * distance * side
			var facing := -outward * side
			var cordon := ParkCordon.new(_city.map, _city.navigator, _city, fixture.park,
					director._reach_blocked)
			var waited := 0.0
			while not cordon.is_closed() and waited < PATIENCE:
				cordon.tick(STEP, her, Callable())
				waited += STEP
			cases += 1
			for each in cordon.stretches:
				if each.node and _overlaps_her(each.node.body_rect(), her, facing):
					through += 1
			if not cordon.is_closed():
				held += 1
			cordon.clear()
	t.check(cases == 8, "she stood at 20 to 26px from the line, both sides of it (%d)" % cases)
	t.check(through == 0, "and no stretch's tape went up through her body or the pram (%d)"
			% through)
	t.check(held == cases, "the gap she stands at stays open while she is there (%d of %d)"
			% [held, cases])
	_end(fixture)

## Whether a tape body's rect overlaps her body's circle or the pram's, with her facing `facing`.
func _overlaps_her(box: Rect2, her: Vector2, facing: Vector2) -> bool:
	var pram := her + facing * Tuning.PLAYER_BODY_RADIUS
	return _circle_meets(box, her, Tuning.PLAYER_BODY_RADIUS) \
			or _circle_meets(box, pram, Stroller.PRAM_BODY_RADIUS)

func _circle_meets(box: Rect2, centre: Vector2, radius: float) -> bool:
	var nearest := Vector2(clampf(centre.x, box.position.x, box.end.x),
			clampf(centre.y, box.position.y, box.end.y))
	return nearest.distance_to(centre) < radius

## **The park's people are walked out through the open edge** *(the entry: "the crowd inside
## leaves through the open edge")*. A busker standing in the park when the cordon starts: an
## officer comes in from out of her sight along the way out, reaches him and walks out behind him.
## Neither steps across tape that is up or onto ground nobody walks (a building), the busker
## crosses the line within the last gap, the gap closes only once both are through it, and the
## officer is gone where she cannot see him, not a fixed walk away.
func _test_the_parks_people_are_walked_out_through_the_gap(t) -> void:
	var person: Array = [null]
	var fixture := _at_the_swing(t, func() -> void:
		var park := CityGenerator.swing_park(_city.map)
		var area := _city.map.tile_rect_to_world(ClosurePlanner.calm_area_rect(_city.map, park))
		person[0] = _city.events.spawn_extra(EventCatalogue.by_id("busker"),
				area.position + area.size * Vector2(0.25, 0.3)))
	var happenings: ResistanceHappenings = fixture.happenings
	var busker: EventInstance = person[0]
	t.check(busker != null and not busker.is_leaving, "a busker stands in the park")
	# She stays at the swing, where the way out was planned from.
	var her := [fixture.swing]
	var shows := _camera_on(her)
	happenings.tick(STEP, her[0], Vector2.ZERO, shows)
	var cordon := happenings.cordon
	var escort: ParkCordon.Officer = null
	for officer in cordon.officers:
		if officer.job == ParkCordon.Officer.Job.ESCORT and officer.person == busker:
			escort = officer
	t.check(escort != null, "an officer is sent for him")
	if escort == null:
		_end(fixture)
		return
	t.check(not shows.call(EventCatalogue.by_id(ParkCordon.OFFICER_ROW), escort.at),
			"from out of her sight")
	var seen := {"through_tape": 0, "off_ground": 0, "crossed_at": Vector2.INF, "steps": 0,
			"busker_left": false, "closed_with_them_inside": false, "gone_seen": false,
			"escort_ahead": 0}
	var last := {"busker": busker.global_position, "escort": escort.at}
	var waited := 0.0
	while waited < PATIENCE and escort.phase != ParkCordon.Officer.Phase.GONE:
		if is_instance_valid(busker) and not busker.is_finished:
			busker.player_at = her[0]
			busker.step(STEP)
		var was_closed := cordon.is_closed()
		happenings.tick(STEP, her[0], Vector2.ZERO, shows)
		waited += STEP
		var walkers := {"escort": escort.at}
		if is_instance_valid(busker) and not busker.is_finished:
			walkers.busker = busker.global_position
		else:
			seen.busker_left = true
		for who: String in walkers:
			var now: Vector2 = walkers[who]
			var before: Vector2 = last[who]
			seen.steps += 1
			if not _city.map.is_walkable(_city.map.world_to_tile(now)):
				seen.off_ground += 1
			for stretch in cordon.stretches:
				if stretch.taped and Geometry2D.segment_intersects_segment(before, now,
						stretch.a, stretch.b) != null:
					seen.through_tape += 1
			if who == "busker" and cordon.line.has_point(before) \
					and not cordon.line.has_point(now):
				seen.crossed_at = now
			last[who] = now
		if walkers.has("busker") and busker.is_leaving and cordon.line.has_point(walkers.busker) \
				and not cordon.line.has_point(escort.at):
			seen.escort_ahead += 1
		if not was_closed and cordon.is_closed():
			seen.closed_with_them_inside = cordon.line.has_point(escort.at) \
					or (walkers.has("busker") and cordon.line.has_point(walkers.busker))
		if escort.phase == ParkCordon.Officer.Phase.GONE:
			seen.gone_seen = shows.call(EventCatalogue.by_id(ParkCordon.OFFICER_ROW), escort.at)
	t.check(seen.steps > 0 and seen.through_tape == 0,
			"neither the busker nor his escort steps across tape that is up (%d of %d steps)"
			% [seen.through_tape, seen.steps])
	t.check(seen.off_ground == 0, "or onto ground nobody walks (%d)" % seen.off_ground)
	t.check(seen.escort_ahead == 0,
			"the officer walks out behind the busker, never out of the park ahead of him (%d frames)"
			% seen.escort_ahead)
	var crossed: Vector2 = seen.crossed_at
	t.check(crossed != Vector2.INF
			and crossed.distance_to(cordon.last_gap) <= Tuning.TILE_SIZE * 1.5,
			"the busker leaves the park through the last gap (%.0fpx from it)"
			% crossed.distance_to(cordon.last_gap))
	t.check(seen.busker_left, "and is gone")
	t.check(cordon.is_closed() and not seen.closed_with_them_inside,
			"the gap closes only once they are both out of it")
	t.check(escort.phase == ParkCordon.Officer.Phase.GONE and not seen.gone_seen,
			"and the officer is gone where she cannot see him (%.1fs)" % waited)
	_end(fixture)

## The suite's busker, standing in the park's north-west when the cordon starts.
func _busker_in_the_park() -> EventInstance:
	var park := CityGenerator.swing_park(_city.map)
	var area := _city.map.tile_rect_to_world(ClosurePlanner.calm_area_rect(_city.map, park))
	return _city.events.spawn_extra(EventCatalogue.by_id("busker"),
			area.position + area.size * Vector2(0.25, 0.3))

## **A person walked out never ends in her view** *("Nothing vanishes while you are looking at
## it": the end of an event is a departure, not a deletion)*. The way out ends out of sight of where
## she stood at the touch, and it is her way out too: she walks it at `Tuning.WALK_SPEED`, setting
## off 4s and then 8s after the touch, and stops where it ends. The busker walked out down it is
## seen to go on past her, and is gone only where the camera on her cannot see him. **And he walks
## on at his pace while she can see him**, never standing at a wall or the city's edge: once the
## way is walked he is in her view no longer than walking out of the view box square to its sides
## takes at `Tuning.PARK_CLOSING_LEAVE_SPEED`, never slower than half that pace in it, and never
## across tape that is up.
func _test_a_person_walked_out_never_ends_in_her_view(t) -> void:
	for set_off: float in [4.0, 8.0]:
		var person: Array = [null]
		var fixture := _at_the_swing(t, func() -> void: person[0] = _busker_in_the_park())
		var happenings: ResistanceHappenings = fixture.happenings
		var busker: EventInstance = person[0]
		var her := [fixture.swing]
		var shows := _camera_on(her)
		happenings.tick(STEP, her[0], Vector2.ZERO, shows)
		var way := PackedVector2Array(happenings.cordon._exit)
		var clock := STEP
		var last := busker.global_position
		var ended_in_view := false
		var walked := false
		var in_view_after := 0.0
		var slow_in_view := 0.0
		var through_tape := 0
		var was_leaving := false
		while clock < PATIENCE * 2.0 and not busker.is_finished:
			if clock >= set_off and not way.is_empty():
				her[0] = (her[0] as Vector2).move_toward(way[0], Tuning.WALK_SPEED * STEP)
				if (her[0] as Vector2).distance_to(way[0]) < 0.5:
					way.remove_at(0)
			busker.player_at = her[0]
			busker.step(STEP)
			happenings.tick(STEP, her[0], Vector2.ZERO, shows)
			clock += STEP
			for stretch in happenings.cordon.stretches:
				if stretch.taped and Geometry2D.segment_intersects_segment(last,
						busker.global_position, stretch.a, stretch.b) != null:
					through_tape += 1
			if busker.is_finished:
				ended_in_view = shows.call(busker.def, last)
			elif walked and shows.call(busker.def, busker.global_position):
				in_view_after += STEP
				if last.distance_to(busker.global_position) \
						< Tuning.PARK_CLOSING_LEAVE_SPEED * STEP * 0.5:
					slow_in_view += STEP
			walked = walked or (busker.is_leaving and busker.way_left().is_empty())
			was_leaving = was_leaving or busker.is_leaving
			last = busker.global_position
		t.check(was_leaving and busker.is_finished,
				"setting off %.0fs after the touch down the way out: the busker walked out "
				% set_off + "ahead of her is gone in the end (%.1fs)" % clock)
		t.check(not ended_in_view, "and not where she can see him (%.0fpx from her)"
				% last.distance_to(her[0]))
		var out_of_view := (Tuning.VIEW_HALF_EXTENT.x + Tuning.VIEW_HALF_EXTENT.y) \
				/ Tuning.PARK_CLOSING_LEAVE_SPEED
		t.check(in_view_after <= out_of_view,
				"once the way is walked he is in her view %.1fs, " % in_view_after
				+ "no longer than walking out of it takes (%.1fs)" % out_of_view)
		t.check(slow_in_view < 0.25,
				"and walks at his pace while in it, never standing at a wall (%.1fs slow)"
				% slow_in_view)
		t.check(through_tape == 0, "and never steps across tape that is up (%d steps)"
				% through_tape)
		_end(fixture)

## **Someone already leaving on their own is walked out through the gap too**, rather than straight
## away from her through the tape: once when they set off before the swing is touched, and once
## when they set off after it, before their escort has reached them.
func _test_someone_already_leaving_is_walked_out_through_the_gap(t) -> void:
	for after_the_touch: float in [-1.0, 0.5]:
		var person: Array = [null]
		var fixture := _at_the_swing(t, func() -> void:
			person[0] = _busker_in_the_park()
			if after_the_touch < 0.0:
				_set_off_on_their_own(person[0], _swing_now))
		var happenings: ResistanceHappenings = fixture.happenings
		var busker: EventInstance = person[0]
		var her := [fixture.swing]
		var shows := _camera_on(her)
		var clock := 0.0
		var crossed_at := Vector2.INF
		var through_tape := 0
		var last := busker.global_position
		var cordon: ParkCordon = null
		while clock < PATIENCE and is_instance_valid(busker) and not busker.is_finished:
			if after_the_touch >= 0.0 and clock >= after_the_touch and not busker.is_leaving:
				_set_off_on_their_own(busker, her[0])
			busker.player_at = her[0]
			busker.step(STEP)
			happenings.tick(STEP, her[0], Vector2.ZERO, shows)
			cordon = happenings.cordon
			clock += STEP
			var now := busker.global_position
			for stretch in cordon.stretches:
				if stretch.taped and Geometry2D.segment_intersects_segment(last, now, stretch.a,
						stretch.b) != null:
					through_tape += 1
			if cordon.line.has_point(last) and not cordon.line.has_point(now):
				crossed_at = now
			last = now
		var when := "already leaving at the touch" if after_the_touch < 0.0 \
				else "setting off %.1fs after it" % after_the_touch
		t.check(crossed_at != Vector2.INF
				and crossed_at.distance_to(cordon.last_gap) <= Tuning.TILE_SIZE * 1.5,
				"a busker %s leaves the park through the last gap (%.0fpx from it)"
				% [when, crossed_at.distance_to(cordon.last_gap)])
		t.check(through_tape == 0, "without walking through tape (%d)" % through_tape)
		_end(fixture)

## Sends `person` off on a departure of their own, straight away from `her`: a copy of their row
## with a walking pace, since a busker has none.
func _set_off_on_their_own(person: EventInstance, her: Vector2) -> void:
	var walking: EventDef = person.def.duplicate()
	walking.shape = person.def.shape
	walking.solid_parts = person.def.solid_parts
	walking.departs_at = Tuning.PARK_CLOSING_LEAVE_SPEED
	person.def = walking
	person.player_at = her
	person.leave_for_a_completed_task()

## **An escort sent back out alone still holds the gap.** His person goes before he reaches them,
## so he turns back from inside the park; until he is out, the last gap is not taped behind him, and
## he never walks through tape.
func _test_an_escort_sent_back_alone_holds_the_gap(t) -> void:
	var person: Array = [null]
	var fixture := _at_the_swing(t, func() -> void: person[0] = _busker_in_the_park())
	var happenings: ResistanceHappenings = fixture.happenings
	var busker: EventInstance = person[0]
	var her := [fixture.swing]
	var shows := _camera_on(her)
	happenings.tick(STEP, her[0], Vector2.ZERO, shows)
	var cordon := happenings.cordon
	var escort: ParkCordon.Officer = null
	for officer in cordon.officers:
		if officer.job == ParkCordon.Officer.Job.ESCORT:
			escort = officer
	var waited := 0.0
	while waited < PATIENCE and escort and not (escort.phase == ParkCordon.Officer.Phase.APPROACH
			and cordon.line.grow(-Tuning.TILE_SIZE).has_point(escort.at)):
		happenings.tick(STEP, her[0], Vector2.ZERO, shows)
		waited += STEP
	t.check(escort != null and cordon.line.has_point(escort.at),
			"an escort is inside the park on his way to the busker (%.1fs)" % waited)
	_city.events.retire(busker)
	happenings.tick(STEP, her[0], Vector2.ZERO, shows)
	t.check(escort.phase == ParkCordon.Officer.Phase.LEAVING and cordon._still_to_come_out(),
			"with the busker gone, he turns back, and the gap waits for him")
	var last := escort.at
	var through_tape := 0
	var inside_at_the_close := false
	while waited < PATIENCE * 2.0 and not cordon.is_closed():
		var was_closed := cordon.is_closed()
		happenings.tick(STEP, her[0], Vector2.ZERO, shows)
		waited += STEP
		for stretch in cordon.stretches:
			if stretch.taped and Geometry2D.segment_intersects_segment(last, escort.at, stretch.a,
					stretch.b) != null:
				through_tape += 1
		if not was_closed and cordon.is_closed():
			inside_at_the_close = cordon.line.has_point(escort.at)
		last = escort.at
	t.check(cordon.is_closed() and not inside_at_the_close,
			"the gap closes only once he is out of it")
	t.check(through_tape == 0, "and he never walks through tape (%d)" % through_tape)
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
