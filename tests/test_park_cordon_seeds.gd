extends RefCounted
## Day 12's police cordon (`ParkCordon`) across a sweep of seeds, on every size of park the
## generator builds, with her standing where the task sent her, at the swing.
##
## What one seed's park cannot show and a sweep can: **the last gap never strands her** — the
## ground outside it reaches home and the day's other calm ground with the park's own ground
## blocked, under the director's own answer to what the day has blocked (`EventScheduler.
## blocked_by()`), and it stands clear of every body and every field a body carries; and **she
## sees them coming in time** — the first officer is in the camera's view of the swing at least the
## walk from the swing to the gap plus `Tuning.PARK_CLOSING_WARNING` before it closes, so setting
## off at a walk a second after first sight gets her out. Both are checked here against the map
## and the clock, not against what the cordon says of itself. `tests/probes/plush_marten_cordon.gd`
## prints the same measurements as a table. And **a person walked out stays out**: with her
## standing a little past the way out's end, the busker walked out of the park never walks back
## into it, nor across tape that is up, on the way on out of her sight, and **no tape goes up
## through him** while he stands in the park waiting for his escort, nor while he walks out. And
## **the officers walk
## round what stops her**: none steps onto ground a body takes on the map's record, and none stands
## at a solid with his walk still ahead of him, on every park and whatever the day put beside it —
## with nobody in the park, and with a busker in it, standing where the suite always puts him and
## in the park's edge rows, where his escort's walks and the tapers' meet; and with a busker in it
## the cordon still closes.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The sweep, and a seed whose swing park is one of the largest calm zones (704 by 704px).
const SEEDS_FROM := 1
const SEEDS_TO := 40
const LARGE_PARK_SEED := 90210
const STEP := 1.0 / 60.0
const PATIENCE := 60.0
## How long after first seeing an officer she sets off walking in the walking check: less than
## `Tuning.PARK_CLOSING_WARNING`, which is the time the cordon leaves her to see and decide.
const REACTION := 1.0
## When she sets off down the way out behind a walked-out busker, and how far past its end, along
## its last leg, she stops.
const SET_OFF := 4.0
const PAST_THE_END := 60.0
## Where in the park a busker stands for the walked-out runs, as a share of the park's size from its
## north-west corner, plus a pixel offset from there: the suite's own spot, and three in the park's
## edge rows — near the south edge (half way along, 94% down), and the middles of the east and north
## edge rows, half a tile in.
const PLACES: Array[Array] = [
	[Vector2(0.25, 0.3), Vector2.ZERO],
	[Vector2(0.5, 0.94), Vector2.ZERO],
	[Vector2(1.0, 0.5), Vector2(-Tuning.TILE_SIZE * 0.5, 0.0)],
	[Vector2(0.5, 0.0), Vector2(0.0, Tuning.TILE_SIZE * 0.5)],
]

func run(t) -> void:
	var seeds: Array[int] = []
	for seed_value in range(SEEDS_FROM, SEEDS_TO + 1):
		seeds.append(seed_value)
	seeds.append(LARGE_PARK_SEED)
	var measured := 0
	var walked_out := 0
	var largest := 0.0
	for seed_value in seeds:
		var m := measure(t, seed_value)
		if m.is_empty():
			continue
		measured += 1
		if m.person_placed and m.person_left:
			walked_out += 1
		largest = maxf(largest, (m.park_size as Vector2).x * (m.park_size as Vector2).y)
		_check(t, seed_value, m)
	t.check(measured >= 30, "the sweep measured a swing park on most seeds (%d of %d)"
			% [measured, seeds.size()])
	t.check(largest >= 704.0 * 704.0 - 1.0,
			"and the largest calm zone the generator builds among them (%.0f px²)" % largest)
	# On the rest she walks on out of his sight while he is still inside, and he is gone there.
	t.check(walked_out >= measured / 3,
			"a busker was walked out of the park on a third of them or more (%d of %d)"
			% [walked_out, measured])

func _check(t, seed_value: int, m: Dictionary) -> void:
	var size: Vector2 = m.park_size
	var what := "seed %d (%.0fx%.0f park)" % [seed_value, size.x, size.y]
	t.check(m.gap_reaches_home, "%s: the ground outside the last gap reaches home with the park "
			% what + "blocked")
	t.check(m.other_calm_reached, "%s: and the day's other calm ground" % what)
	t.check(m.gap_clear, "%s: the last gap stands clear of every body and field (%s)"
			% [what, m.gap_blocker])
	t.check(m.trapped_standing, "%s: standing at the swing, she is shut in (closed at %.1fs)"
			% [what, m.closed_at])
	t.check(m.first_seen >= 0.0 and m.closed_at - m.first_seen
			>= m.walk / Tuning.WALK_SPEED + Tuning.PARK_CLOSING_WARNING - 2.0 * STEP,
			"%s: the first officer is in her view %.1fs before the gap closes, " % [what,
			m.closed_at - m.first_seen] + "the walk to it (%.0fpx, %.1fs) plus %.0fs"
			% [m.walk, m.walk / Tuning.WALK_SPEED, Tuning.PARK_CLOSING_WARNING])
	t.check(m.walked_out, "%s: setting off at a walk %.0fs after first sight gets her out"
			% [what, REACTION])
	# What the cordon says of itself is what happens: the close it logs and paces to, unless the
	# park's people hold the gap, and when it expects an officer in her view.
	t.check(m.people > 0 or absf(m.closed_at - m.deadline) <= 0.25,
			"%s: the gap closes when the cordon said it would (%.1fs, said %.1fs)"
			% [what, m.closed_at, m.deadline])
	t.check(absf(m.first_seen - m.first_in_view) <= 0.25,
			"%s: and an officer is first in view when it said (%.1fs, said %.1fs)"
			% [what, m.first_seen, m.first_in_view])
	t.check(m.onto_bodies == 0, "%s: no officer steps onto ground a body takes (%d steps)"
			% [what, m.onto_bodies])
	t.check(m.stalled == 0 and m.relaid == 0,
			"%s: and none stands at a solid with his walk ahead of him (%d frames, %d relaid)"
			% [what, m.stalled, m.relaid])
	for run: Dictionary in m.people_runs:
		if not run.person_placed:
			continue
		var who := "%s, a busker at %s" % [what, run.place]
		t.check(run.back_in == 0,
				"%s walked out, with her stopped %.0fpx past the way's end, " % [who,
				PAST_THE_END] + "never walks back into the park (%d frames back in)" % run.back_in)
		t.check(run.person_through_tape == 0, "%s: nor across tape that is up (%d steps)"
				% [who, run.person_through_tape])
		t.check(run.taped_over_him == 0, "%s: and no tape goes up through him (%d stretches)"
				% [who, run.taped_over_him])
		t.check(run.closed_at >= 0.0, "%s: the cordon closes (at %.1fs, deadline %.1fs)"
				% [who, run.closed_at, run.deadline])
		t.check(run.onto_bodies == 0, "%s: no officer steps onto ground a body takes (%d steps)"
				% [who, run.onto_bodies])
		t.check(run.stalled == 0 and run.relaid == 0,
				"%s: and none stands at a solid with his walk ahead of him (%d frames, %d relaid)"
				% [who, run.stalled, run.relaid])

## Day 12 on `seed_value`'s city, played twice from the swing's touch: once standing at the swing,
## and once walking out through the last gap `REACTION` after an officer first comes into view.
## Answers what was measured, or `{}` when the day has no swing park.
func measure(t, seed_value: int) -> Dictionary:
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
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
	state.begin_day(city.map.block_plans, day)
	city.start_day(state, day, _rng(seed_value, day, "closures"))
	city.events.start_day(DaySpec.for_day(day), _rng(seed_value, day, "events"), [],
			city.map.doorstep_world_position())
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(city, city.map)
	director.start_day(day, _rng(seed_value, day, "resistance"), 300.0)
	var result := {}
	var mark := director.current_step()
	director._on_contact_completed(mark.index if mark else -1)
	var task := director.current_step()
	if task and task.target_kind == ResistanceSteps.TargetKind.PARK_SWING:
		var swing := director.contact_position()
		director._on_contact_completed(task.index)
		var happenings: ResistanceHappenings = director._happenings
		result = _measure_the_day(city, director, happenings, swing)
		happenings.start_day(day + 1)
	director.free()
	city.free()
	GameState.attempt_spend.city_state = saved.state
	GameState.header.day = saved.day
	GameState.resistance.completed_steps = saved.completed
	GameState.resistance.failed_steps = saved.failed
	GameState.resistance.progress = saved.progress
	GameState.resistance.carrying_package = saved.package
	return result

func _measure_the_day(city: City, director: ResistanceDirector,
		happenings: ResistanceHappenings, swing: Vector2) -> Dictionary:
	var her := [swing]
	var shows := _camera_on(her)
	_look(city, her[0])
	happenings.tick(STEP, her[0], Vector2.ZERO)
	var cordon := happenings.cordon
	var result := {"park_size": cordon.area.size, "walk": swing.distance_to(cordon.last_gap)}
	_measure_the_gap(city, director, cordon, result)
	var standing := _play(city, cordon, her, shows, false)
	result.first_seen = standing.first_seen
	result.closed_at = standing.closed_at
	result.trapped_standing = standing.trapped
	result.deadline = cordon.deadline
	result.first_in_view = cordon.first_in_view
	result.onto_bodies = standing.onto_bodies
	result.stalled = standing.stalled
	result.relaid = cordon.relaid
	var people := cordon._leaving.size()
	for officer in cordon.officers:
		if officer.job == ParkCordon.Officer.Job.ESCORT:
			people += 1
	result.people = people
	cordon.clear()
	var again := ParkCordon.new(city.map, city.navigator, city, cordon.park,
			city.spawn_siting, director._reach_blocked)
	her[0] = swing
	_tick(city, again, her[0])
	var walking := _play(city, again, her, shows, true)
	result.walked_out = walking.closed_at >= 0.0 and not walking.trapped
	again.clear()
	var runs: Array[Dictionary] = []
	for place in PLACES:
		runs.append(_walk_a_person_out(city, director, cordon.park, swing, place))
	result.merge(runs[0])
	result.people_runs = runs
	return result

## A busker standing in the park at `place` (one of `PLACES`) as a fresh cordon starts, walked out
## by his escort, with her walking the same way out from `SET_OFF` after the start and stopping
## `PAST_THE_END` beyond its end, played until he is gone and the cordon has closed. Answers whether
## he was placed, whether he left the tape's line, the frames he spent back inside it after leaving
## it, the steps he took across tape that was up, the stretches taped with any part of him within
## reach of them (`ParkCordon.WALKER_REACH`) and when each stretch went up, by its index, when the
## cordon closed and what it said it would, and the officers' steps onto a body's ground, stalls and
## walks laid again (`_count_the_step()`).
func _walk_a_person_out(city: City, director: ResistanceDirector, park: Vector2i,
		swing: Vector2, place: Array) -> Dictionary:
	var area := city.map.tile_rect_to_world(ClosurePlanner.calm_area_rect(city.map, park))
	var spot: Vector2 = area.position + area.size * (place[0] as Vector2) + (place[1] as Vector2)
	var busker := city.events.spawn_extra(EventCatalogue.by_id("busker"), spot)
	if not busker:
		return {"person_placed": false, "place": place[0]}
	var cordon := ParkCordon.new(city.map, city.navigator, city, park,
			city.spawn_siting, director._reach_blocked)
	var her := [swing]
	var shows := _camera_on(her)
	_tick(city, cordon, her[0])
	var way := PackedVector2Array(cordon._exit)
	if way.size() >= 2:
		var last_leg := (way[way.size() - 1] - way[way.size() - 2]).normalized()
		way.append(way[way.size() - 1] + last_leg * PAST_THE_END)
	var clock := STEP
	var last := busker.global_position
	var left := false
	var back_in := 0
	var through_tape := 0
	var taped_over_him := 0
	var taped_at := {}
	var counts := {"onto_bodies": 0, "stalled": 0}
	while clock < PATIENCE * 2.0 and not (_gone(busker) and cordon.is_closed()):
		if clock >= SET_OFF and not way.is_empty():
			her[0] = (her[0] as Vector2).move_toward(way[0], Tuning.WALK_SPEED * STEP)
			if (her[0] as Vector2).distance_to(way[0]) < 0.5:
				way.remove_at(0)
		var before := {}
		for officer in cordon.officers:
			before[officer] = [officer.at, officer.phase]
		if not _gone(busker):
			busker.player_at = her[0]
			busker.step(STEP)
		_tick(city, cordon, her[0])
		clock += STEP
		for officer in cordon.officers:
			if before.has(officer):
				_count_the_step(cordon, officer, before[officer][0], before[officer][1], counts)
		for i in cordon.stretches.size():
			var stretch := cordon.stretches[i]
			if not stretch.taped or taped_at.has(i):
				continue
			taped_at[i] = clock
			if not _gone(busker) and ParkCordon._body_on(stretch, busker.global_position,
					ParkCordon.WALKER_REACH):
				taped_over_him += 1
		if _gone(busker):
			continue
		var now := busker.global_position
		for stretch in cordon.stretches:
			if stretch.taped and Geometry2D.segment_intersects_segment(last, now, stretch.a,
					stretch.b) != null:
				through_tape += 1
		if not cordon.line.has_point(now):
			left = true
		elif left:
			back_in += 1
		last = now
	var result := {"person_placed": true, "place": place[0], "person_left": left,
			"back_in": back_in, "person_through_tape": through_tape,
			"taped_over_him": taped_over_him, "taped_at": taped_at,
			"closed_at": cordon.closed_at, "deadline": cordon.deadline,
			"onto_bodies": counts.onto_bodies, "stalled": counts.stalled, "relaid": cordon.relaid,
			"walked_straight": cordon.walked_straight}
	cordon.clear()
	# Gone from the world the way the day's own frame retires him, his body's tiles given back
	# (`EventStreaming.retire_finished()`, which nothing here ticks): left on the record, the
	# ground he stood on would be solid for the next spot's run.
	if not _gone(busker):
		city.events.retire(busker)
	city.events.streaming.retire_finished()
	return result

## Checks the chosen gap against the map: the tile beyond each of its stretches' edge tiles reached
## from home with the park's ground blocked under the director's `_reach_blocked`, some other calm
## tile reached the same way, and the point a tile out from each stretch farther from every placed
## body than its obstruction and her whole shape, and outside the field of any body that carries
## one and the lethal reach of anything that ends the day.
func _measure_the_gap(city: City, director: ResistanceDirector, cordon: ParkCordon,
		result: Dictionary) -> void:
	var map := city.map
	var rect := ClosurePlanner.calm_area_rect(map, cordon.park)
	var blocked: Dictionary = director._reach_blocked.duplicate()
	for tile in map.rect_tiles(rect):
		blocked[tile] = true
	var field := map.walk_field(map.home_rect.position, blocked)
	var reaches := not cordon.gap.is_empty()
	var clear := true
	var blocker := "none"
	for stretch in cordon.gap:
		var out := false
		for tile in stretch.tiles:
			out = out or map.reaches(field, tile + stretch.outward)
		reaches = reaches and out
		var point := (stretch.a + stretch.b) * 0.5 + Vector2(stretch.outward) * Tuning.TILE_SIZE
		for plan in city.events.plans():
			if plan.spent or not plan.is_placed() or cordon.area.has_point(plan.position):
				continue
			var def := plan.def
			if def.obstructs_radius <= 0.0 and not def.hard_fail:
				continue
			var reach := def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS \
					+ Stroller.PRAM_BODY_RADIUS
			if def.intensity > 0.0:
				reach = maxf(reach, def.field_reach())
			if def.hard_fail:
				reach = maxf(reach, def.lethal_reach() + Tuning.PLAYER_BODY_RADIUS)
			if point.distance_to(plan.position) < reach:
				clear = false
				blocker = "%s %.0fpx away, reach %.0fpx" % [def.id, point.distance_to(plan.position),
						reach]
	var other := false
	for tile in map.calm_tiles():
		if not rect.has_point(tile) and map.reaches(field, tile):
			other = true
			break
	result.gap_reaches_home = reaches
	result.gap_clear = clear
	result.gap_blocker = blocker
	result.other_calm_reached = other

## Plays the cordon out with the camera on `her[0]`, watching for the first frame any taper's
## figure is in its view. Walking, she sets off `REACTION` after that toward the last gap and on
## out past it. Counts, as well, every officer's step onto a tile a body takes on the map's record
## (the one he stands on left out, since anyone may walk off a solid he stands in), and every frame
## an officer already walking in or round the edge, waiting for nobody, did not move with his walk
## ahead of him.
func _play(city: City, cordon: ParkCordon, her: Array, shows: Callable, walks: bool) -> Dictionary:
	var row := EventCatalogue.by_id(ParkCordon.OFFICER_ROW)
	var first_seen := -1.0
	var clock := STEP
	var gap := cordon.last_gap
	var out := gap + Vector2(cordon.gap[0].outward) * (ParkCordon.HER_REACH + Tuning.TILE_SIZE)
	var counts := {"onto_bodies": 0, "stalled": 0}
	while not cordon.is_closed() and clock < PATIENCE:
		var before := {}
		for officer in cordon.officers:
			before[officer] = [officer.at, officer.phase]
		if first_seen < 0.0:
			for officer in cordon.officers:
				if officer.job == ParkCordon.Officer.Job.TAPE \
						and officer.phase != ParkCordon.Officer.Phase.GONE \
						and shows.call(row, officer.at):
					first_seen = clock
		if walks and first_seen >= 0.0 and clock >= first_seen + REACTION:
			var target := gap if (her[0] as Vector2).distance_to(gap) > 1.0 \
					and cordon.line.has_point(her[0]) else out
			her[0] = (her[0] as Vector2).move_toward(target, Tuning.WALK_SPEED * STEP)
		_tick(city, cordon, her[0])
		clock += STEP
		for officer in cordon.officers:
			if before.has(officer):
				_count_the_step(cordon, officer, before[officer][0], before[officer][1], counts)
	return {"first_seen": first_seen, "closed_at": cordon.closed_at, "trapped": cordon.trapped,
			"onto_bodies": counts.onto_bodies, "stalled": counts.stalled}

## Whether a walked-out person has gone from the world.
static func _gone(person: EventInstance) -> bool:
	return not is_instance_valid(person) or person.is_finished

## Adds one officer's step from `from`, in `phase` before it, to `counts`: onto a body's ground,
## or stalled.
func _count_the_step(cordon: ParkCordon, officer: ParkCordon.Officer, from: Vector2,
		phase: ParkCordon.Officer.Phase, counts: Dictionary) -> void:
	var map: CityMap = cordon._map
	var start := map.world_to_tile(from)
	var steps := maxi(1, ceili(from.distance_to(officer.at) / 2.0))
	for i in range(1, steps + 1):
		var tile := map.world_to_tile(from.lerp(officer.at, float(i) / steps))
		if tile != start and map.is_obstructed(tile):
			counts.onto_bodies += 1
			break
	var walking := phase == officer.phase and (phase == ParkCordon.Officer.Phase.APPROACH
			or phase == ParkCordon.Officer.Phase.TAPING)
	if walking and not officer.holding and not officer.path.is_empty() \
			and officer.at.is_equal_approx(from):
		counts.stalled += 1

## What the camera sees with her at `her[0]`: the game's own view box round her, against the whole
## of what `row` draws standing at `feet` — `SpawnSiting.Rule.DRAWING_OFF_THE_VIEW`'s question.
func _camera_on(her: Array) -> Callable:
	return func(row: EventDef, feet: Vector2) -> bool:
		var centre: Vector2 = her[0]
		var view := Rect2(centre - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
		var box := EventFootprints.footprint_of(row)
		if not box.has_area():
			return view.has_point(feet)
		return view.intersects(Rect2(feet + box.position, box.size))

## The city's own view looked through about `at`, as the game's camera does, then one tick of
## the cordon: what its officers are placed out of sight of is that view (`SpawnSiting`'s).
func _tick(city: City, cordon: ParkCordon, at: Vector2) -> void:
	_look(city, at)
	cordon.tick(STEP, at)

func _look(city: City, at: Vector2) -> void:
	city.events.visible_view().look(
			Rect2(at - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0), null)

func _rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng
