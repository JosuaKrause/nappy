extends RefCounted
## **The sweep behind `test_park_cordon_seeds_a.gd`, `_b.gd` and `_c.gd`; not a suite itself.**
## Day 12's police cordon (`ParkCordon`) across a sweep of seeds, on every size of park the
## generator builds, with her standing where the task sent her, at the swing.
##
## What one seed's park cannot show and a sweep can: **the last gap never strands her** — the
## ground outside it reaches home and the day's other calm ground with the park's own ground
## blocked, under the director's own answer to what the day has blocked (`EventScheduler.
## blocked_by()`), and it stands clear of every body and every field a body carries; and **she
## sees them coming in time** — the first officer is in the camera's view of the swing at least the
## walk from the swing to the gap plus `ParkCordon.PARK_CLOSING_WARNING` before it closes, so setting
## off at a walk a second after first sight gets her out. Both are checked here against the map
## and the clock, not against what the cordon says of itself. `tests/probes/plush_marten_cordon.gd`
## prints the same measurements as a table. And **a person walked out stays out**: with her
## standing a little past the way out's end, the busker walked out of the park never walks back
## into it, nor across tape that is up, on the way on out of her sight, and **no tape goes up
## through him** while he stands in the park waiting for his escort, nor while he walks out. And
## **the officers walk
## round what stops her**: none steps onto ground a body takes on the map's record, on every park and
## whatever the day put beside it — with nobody in the park, and with a busker in it, standing where
## the suite always puts him and in the park's edge rows, where his escort's walks and the tapers'
## meet; and with a busker in it the cordon still closes. The officers are read off the world, the
## figures standing on the city's entity layer, and the tape off the static bodies it stands.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const CordonInTheWorld := preload("res://tests/cordon_in_the_world.gd")
## The sweep, and a seed whose swing park is one of the largest calm zones (704 by 704px).
const SEEDS_FROM := 1
const SEEDS_TO := 40
const LARGE_PARK_SEED := 90210
const STEP := 1.0 / 60.0
const PATIENCE := 60.0
## How long after first seeing an officer she sets off walking in the walking check: less than
## `ParkCordon.PARK_CLOSING_WARNING`, which is the time the cordon leaves her to see and decide.
const REACTION := 1.0
## How long after the busker is sent off down the way out she sets off down it behind him, and how far past its end, along
## its last leg, she stops.
const SET_OFF := 4.0
const PAST_THE_END := 60.0
## The frames of standing still a run may show before it is a stall: a taper's turn at a corner or
## his hand-over from approach to round costs a frame or two, a wait at a solid about thirty
## (`ParkCordon.STUCK_FRAMES`) before he walks straight.
const STALL_FRAMES_ALLOWED := 3
## How far from her a taper must be for a frame he stands still to count as a stall: tapers wait for
## her only beside a stretch she is within reach of.
const STALL_AWAY := Tuning.TILE_SIZE * 4.0
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

## The sweep over `seeds`: every seed measured and checked the same way, then the checks that hold
## over the seeds together. `tests/test_park_cordon_seeds_a.gd`, `_b.gd` and `_c.gd` each call it
## on a third of `SEEDS_FROM..SEEDS_TO` plus `LARGE_PARK_SEED`, so no suite runs two minutes serial;
## the three together make the checks one sweep over all 41 seeds makes. The together-checks scale
## with the seeds a part has (30 of 41 measured, rounded up so the three floors sum to at least 30; a third walked out); the largest calm zone is
## checked in the part that holds `LARGE_PARK_SEED`.
func sweep(t, seeds: Array[int]) -> void:
	# Finishing the swing's task the game's way makes the director's own happenings take the park
	# first, so the sweep's own `take_the_park()` would return false. The director therefore leaves
	# the task open in `VisitCounter._open_tasks`, and this is the runner's declared way to put it
	# back.
	t.gives_back_observers()
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
	t.check(measured >= ceili(seeds.size() * 30.0 / 41.0), "the sweep measured a swing park on most seeds (%d of %d)"
			% [measured, seeds.size()])
	if seeds.has(LARGE_PARK_SEED):
		t.check(largest >= 704.0 * 704.0 - 1.0,
				"and the largest calm zone the generator builds among them (%.0f px²)" % largest)
	# On the rest she walks on out of his sight while he is still inside, and he is gone there.
	t.check(walked_out >= measured / 3,
			"a busker was walked out of the park on a third of them or more (%d of %d)"
			% [walked_out, measured])

## The seeds of part `index` (0 to 2) of `parts`: every `parts`th seed of the sweep from the
## `index`th, so the parks are dealt out rather than cut in runs; the last part also holds
## `LARGE_PARK_SEED`. The sizes are not even across the parts: the 704 by 704 parks are seeds 10, 13,
## 34, 37 and 40 (part 1) and `LARGE_PARK_SEED` (part 3), and part 2 builds only 256 by 256 ones.
static func part(index: int, parts: int) -> Array[int]:
	var seeds: Array[int] = []
	for seed_value in range(SEEDS_FROM + index, SEEDS_TO + 1, parts):
		seeds.append(seed_value)
	if index == parts - 1:
		seeds.append(LARGE_PARK_SEED)
	return seeds

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
			>= m.walk / Tuning.WALK_SPEED + ParkCordon.PARK_CLOSING_WARNING - 2.0 * STEP,
			"%s: the first officer is in her view %.1fs before the gap closes, " % [what,
			m.closed_at - m.first_seen] + "the walk to it (%.0fpx, %.1fs) plus %.0fs"
			% [m.walk, m.walk / Tuning.WALK_SPEED, ParkCordon.PARK_CLOSING_WARNING])
	t.check(m.walked_out, "%s: setting off at a walk %.0fs after first sight gets her out"
			% [what, REACTION])
	t.check(m.onto_bodies == 0, "%s: no officer steps onto ground a body takes (%d steps)"
			% [what, m.onto_bodies])
	t.check(m.stalled <= STALL_FRAMES_ALLOWED and m.walking_stalled <= STALL_FRAMES_ALLOWED,
			"%s: and no taper stands still on his round with nobody near him (%d, %d frames)"
			% [what, m.stalled, m.walking_stalled])
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
		t.check(run.closed_at >= 0.0, "%s: the cordon closes (at %.1fs)" % [who, run.closed_at])
		t.check(run.onto_bodies == 0, "%s: no officer steps onto ground a body takes (%d steps)"
				% [who, run.onto_bodies])

## Day 12 on `seed_value`'s city, played twice from the swing's touch: once standing at the swing,
## and once walking out through the last gap `REACTION` after an officer first comes into view.
## Answers what was measured, or `{}` when the day has no swing park.
func measure(t, seed_value: int) -> Dictionary:
	var run := RunState.new()
	run.start_run(seed_value)
	var city: City = RunCity.in_run(CITY_SCENE, run)
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	run.resistance.completed_steps = []
	run.resistance.failed_steps = []
	run.resistance.progress = 0
	run.resistance.carrying_package = false
	var day := ResistanceSteps.swing_day()
	run.header.day = day
	var state := CityState.new()
	run.attempt_spend.city_state = state
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
	director.contact().complete_now()
	var task := director.current_step()
	if task and task.target_kind == ResistanceSteps.TargetKind.PARK_SWING:
		var swing := director.contact_position()
		# The park is taken by happenings of the sweep's own, handed what the director hands its
		# own when the swing is reached (`take_the_park()` with `reach_obstruction()`), so the
		# cordon is the happenings' public one and no director tick stands between it and the sweep.
		var happenings := ResistanceHappenings.new()
		happenings.setup(city, city.map)
		happenings.start_day(day, false)
		happenings.take_the_park(director.reach_obstruction())
		result = _measure_the_day(city, director, happenings, swing)
		happenings.start_day(day + 1)
	director.free()
	city.free()
	run.free()
	return result

## How many of the park's people the cordon has taken on just after its first tick: an escort each,
## and each other person it sends off on their own, who is leaving by then. Counts only the kind
## the cordon walks out (a person in the park who is not ambient, a pursuer, a vehicle, warned
## first or arriving chasing: `ParkCordon._walks_out()`'s question, asked of the public event).
func _people_taken_on(city: City, cordon: ParkCordon) -> int:
	# The two tapers are the first two officers in the world; every other is an escort.
	var people := maxi(0, CordonInTheWorld.officers(city).size() - 2)
	var area := CordonInTheWorld.park_ground(city.map, cordon.park)
	for live in city.events.instances():
		var def := live.def
		if live.is_finished or not live.is_leaving or not area.has_point(live.global_position):
			continue
		if def.kind != GameEnums.EventKind.AMBIENT and def.pursuit == null and def.vehicle == null \
				and not def.warned_first and not def.starts_by(PursuitSpec.Start.ARRIVES_CHASING):
			people += 1
	return people

func _measure_the_day(city: City, director: ResistanceDirector,
		happenings: ResistanceHappenings, swing: Vector2) -> Dictionary:
	var her := [swing]
	var shows := _camera_on(her)
	_look(city, her[0])
	happenings.tick(STEP, her[0], Vector2.ZERO)
	var cordon := happenings.cordon
	var result := {"park_size": CordonInTheWorld.park_ground(city.map, cordon.park).size,
			"walk": swing.distance_to(cordon.last_gap)}
	result.people = _people_taken_on(city, cordon)
	_measure_the_gap(city, director, cordon, result)
	var standing := _play(city, cordon, her, shows, false, result.people == 0)
	result.first_seen = standing.first_seen
	result.closed_at = standing.closed_at
	result.trapped_standing = standing.trapped
	result.onto_bodies = standing.onto_bodies
	result.stalled = standing.stalled
	cordon.clear()
	var again := ParkCordon.new(city.map, city.navigator, city, cordon.park,
			city.spawn_siting, director.reach_obstruction())
	her[0] = swing
	_tick(city, again, her[0])
	var walking := _play(city, again, her, shows, true, result.people == 0)
	result.walked_out = walking.closed_at >= 0.0 and not walking.trapped
	result.walking_stalled = walking.stalled
	again.clear()
	var runs: Array[Dictionary] = []
	for place in PLACES:
		runs.append(_walk_a_person_out(city, director, cordon.park, swing, place))
	result.merge(runs[0])
	result.people_runs = runs
	return result

## A busker standing in the park at `place` (one of `PLACES`) as a fresh cordon starts, walked out
## by his escort, with her walking the same way out from `SET_OFF` after he is sent off and stopping
## `PAST_THE_END` beyond its end, played until he is gone and the cordon has closed. Answers whether
## he was placed, whether he left the tape's line, the frames he spent back inside it after leaving
## it, the steps he took across tape that was up, the tape put up with any part of him within reach
## of it (`ParkCordon.WALKER_REACH`) and when each piece went up (by the piece), when the cordon
## closed, and the officers' steps onto a body's ground (`_count_the_step()`).
func _walk_a_person_out(city: City, director: ResistanceDirector, park: Vector2i,
		swing: Vector2, place: Array) -> Dictionary:
	var area := CordonInTheWorld.park_ground(city.map, park)
	var line := CordonInTheWorld.tape_line(city.map, park)
	var spot: Vector2 = area.position + area.size * (place[0] as Vector2) + (place[1] as Vector2)
	var busker := city.events.spawn_extra(EventCatalogue.by_id("busker"), spot)
	if not busker:
		return {"person_placed": false, "place": place[0]}
	var cordon := ParkCordon.new(city.map, city.navigator, city, park,
			city.spawn_siting, director.reach_obstruction())
	var her := [swing]
	var shows := _camera_on(her)
	_tick(city, cordon, her[0])
	# The way out is read off the busker once his escort has sent him down it
	# (`EventInstance.way_left()`, which the escort reads too), so she sets off `SET_OFF` after he
	# does, not after the start.
	var way := PackedVector2Array()
	var sent_off_at := -1.0
	var clock := STEP
	var last := busker.global_position
	var left := false
	var back_in := 0
	var through_tape := 0
	var taped_over_him := 0
	var taped_at := {}
	var closed_at := -1.0
	var counts := {"onto_bodies": 0}
	while clock < PATIENCE * 2.0 and not (_gone(busker) and cordon.is_closed()):
		if sent_off_at < 0.0 and not _gone(busker) and busker.way_left().size() >= 2:
			# A copy: the packed array it answers is the departure's own, shared, and her walk drops its points.
			way = busker.way_left().duplicate()
			var last_leg := (way[way.size() - 1] - way[way.size() - 2]).normalized()
			way.append(way[way.size() - 1] + last_leg * PAST_THE_END)
			sent_off_at = clock
		if sent_off_at >= 0.0 and clock >= sent_off_at + SET_OFF and not way.is_empty():
			her[0] = (her[0] as Vector2).move_toward(way[0], Tuning.WALK_SPEED * STEP)
			if (her[0] as Vector2).distance_to(way[0]) < 0.5:
				way.remove_at(0)
		var before := _where_the_officers_stand(city)
		if not _gone(busker):
			busker.player_at = her[0]
			busker.step(STEP)
		_tick(city, cordon, her[0])
		clock += STEP
		if closed_at < 0.0 and cordon.is_closed():
			closed_at = clock
		_count_the_steps(city.map, before, counts)
		for tape in CordonInTheWorld.tapes(city):
			if taped_at.has(tape.get_instance_id()):
				continue
			taped_at[tape.get_instance_id()] = clock
			var ends := CordonInTheWorld.ends(tape)
			if not _gone(busker) and Geometry2D.get_closest_point_to_segment(
					busker.global_position, ends[0], ends[1]).distance_to(busker.global_position) \
					< ParkCordon.WALKER_REACH:
				taped_over_him += 1
		if _gone(busker):
			continue
		var now := busker.global_position
		if CordonInTheWorld.is_across_tape(city, last, now):
			through_tape += 1
		if not line.has_point(now):
			left = true
		elif left:
			back_in += 1
		last = now
	var result := {"person_placed": true, "place": place[0], "person_left": left,
			"back_in": back_in, "person_through_tape": through_tape,
			"taped_over_him": taped_over_him, "taped_at": taped_at,
			"closed_at": closed_at, "onto_bodies": counts.onto_bodies}
	cordon.clear()
	# Gone from the world the way the day's own frame retires him, his body's tiles given back
	# (`EventStreaming.retire_finished()`, which nothing here ticks): left on the record, the
	# ground he stood on would be solid for the next spot's run.
	if not _gone(busker):
		city.events.retire(busker)
	city.events.streaming.retire_finished()
	return result

## Checks the chosen gap against the map: the tile beyond each of its stretches' edge tiles reached
## from home with the park's ground blocked under the director's `reach_obstruction()`, some other calm
## tile reached the same way, and the point a tile out from each stretch farther from every placed
## body than its obstruction and her whole shape, and outside the field of any body that carries
## one and the lethal reach of anything that ends the day.
func _measure_the_gap(city: City, director: ResistanceDirector, cordon: ParkCordon,
		result: Dictionary) -> void:
	var map := city.map
	var rect := ClosurePlanner.calm_area_rect(map, cordon.park)
	var area := CordonInTheWorld.park_ground(map, cordon.park)
	var blocked: Dictionary = director.reach_obstruction()
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
			if plan.spent or not plan.is_placed() or area.has_point(plan.position):
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
## (the one he stands on left out, since anyone may walk off a solid he stands in), and, when
## `watch_stalls` (nobody in the park, so no taper waits for a person), every frame a taper's figure
## stood where it stood a frame before, after it had first moved and with the cordon open, while she
## was farther than `STALL_AWAY` from him: tapers never wait for each other, so he is held up by
## something he cannot get round.
func _play(city: City, cordon: ParkCordon, her: Array, shows: Callable, walks: bool,
		watch_stalls: bool) -> Dictionary:
	var row := EventCatalogue.by_id(ParkCordon.OFFICER_ROW)
	var line := CordonInTheWorld.tape_line(city.map, cordon.park)
	var first_seen := -1.0
	var clock := STEP
	var gap := cordon.last_gap
	var out := gap + Vector2(cordon.gap[0].outward) * (ParkCordon.HER_REACH + Tuning.TILE_SIZE)
	var counts := {"onto_bodies": 0}
	var stalled := 0
	var started := {}
	var fails: Array[String] = []
	var listen := func(reason: String) -> void:
		fails.append(reason)
	EventBus.hard_fail_triggered.connect(listen)
	while not cordon.is_closed() and clock < PATIENCE:
		var before := _where_the_officers_stand(city)
		if first_seen < 0.0:
			for officer in CordonInTheWorld.officers(city):
				if shows.call(row, officer.global_position):
					first_seen = clock
		if walks and first_seen >= 0.0 and clock >= first_seen + REACTION:
			var target := gap if (her[0] as Vector2).distance_to(gap) > 1.0 \
					and line.has_point(her[0]) else out
			her[0] = (her[0] as Vector2).move_toward(target, Tuning.WALK_SPEED * STEP)
		_tick(city, cordon, her[0])
		clock += STEP
		_count_the_steps(city.map, before, counts)
		if watch_stalls and not cordon.is_closed():
			for officer: CordonOfficer in before:
				if not is_instance_valid(officer) or officer.is_queued_for_deletion():
					continue
				if not officer.global_position.is_equal_approx(before[officer]):
					started[officer] = true
				elif started.has(officer) and officer.global_position.distance_to(her[0]) > STALL_AWAY:
					stalled += 1
	EventBus.hard_fail_triggered.disconnect(listen)
	return {"first_seen": first_seen, "closed_at": clock if cordon.is_closed() else -1.0,
			"trapped": fails == [ParkCordon.TRAPPED], "onto_bodies": counts.onto_bodies,
			"stalled": stalled}

## Whether a walked-out person has gone from the world.
static func _gone(person: EventInstance) -> bool:
	return not is_instance_valid(person) or person.is_finished

## Where each of the cordon's officers stands now, by his figure in the world.
func _where_the_officers_stand(city: City) -> Dictionary:
	var standing := {}
	for officer in CordonInTheWorld.officers(city):
		standing[officer] = officer.global_position
	return standing

## Adds to `counts` every officer's step since `before` (`_where_the_officers_stand()`) that went
## onto a body's ground: a tile the map has obstructed, the one he started on left out.
func _count_the_steps(map: CityMap, before: Dictionary, counts: Dictionary) -> void:
	for officer: CordonOfficer in before:
		if not is_instance_valid(officer):
			continue
		var from: Vector2 = before[officer]
		var start := map.world_to_tile(from)
		var steps := maxi(1, ceili(from.distance_to(officer.global_position) / 2.0))
		for i in range(1, steps + 1):
			var tile := map.world_to_tile(from.lerp(officer.global_position, float(i) / steps))
			if tile != start and map.is_obstructed(tile):
				counts.onto_bodies += 1
				break

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
