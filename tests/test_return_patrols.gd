extends RefCounted
## M98, pressure in the empty acts — "Patrols for acts III and IV, built around encounter cost."
## `EventDirector.owe_the_return()`'s own shape: what it owes per act, the pacing it switches to,
## that it never owes twice in a day, and the carriageway siting `due()` gives the row it owes.
## Every check asks the director what the game asks it (`start_day()`, `force()`, `owe_the_return()`,
## `owed()`, `due()`, `rig_her_route()`, `start_recipe_route()`) and reads what `due()` hands out
## as she walks, never the director's own members. See `tests/probes/m98_return_phase.gd` for the
## before/after measurement this milestone asked for; this suite is the contract, not the
## measurement.

const SEED := 4242
## The act IV day the walking checks play.
const RETURN_DAY := 13
## One `due()` call's slice of a walk, as `EventsAhead.place_what_is_owed_ahead()` asks it every
## physics tick (the director only counts seconds handed in, so this is a simulated walk).
const STEP := 0.1

func run(t) -> void:
	_test_no_double_batch_in_a_day(t)
	_test_forced_queue_is_untouched(t)
	_test_pacing_switches_after_the_return_is_owed(t)
	_test_each_patrol_comes_within_its_rigged_bag(t)
	_test_a_marble_spent_unmet_counts_against_the_patrols_bag(t)
	_test_sited_on_driveable_road_toward_her(t)
	_test_empty_in_a_park(t)

# ------------------------------------------------------------------------- rig ---

func _map() -> CityMap:
	return CityGenerator.generate(SEED)

## The plans a real dawn on `RETURN_DAY` buys on the suite's map, built once by the first walking
## check that asks and only read by every director started over them.
var _plans: Array[EventScheduler.Planned] = []

## A director over `map` on day 1 with nothing planned, its day stream seeded 17, handed the forced
## row `forced` first when one is given (`--force`, which `start_day()` takes up).
func _director(map: CityMap, forced := "") -> EventDirector:
	var director := EventDirector.new(map)
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	if forced != "":
		director.force(forced, 5.0)
	var no_plans: Array[EventScheduler.Planned] = []
	director.start_day(1, no_plans, rng)
	return director

## A director started on `RETURN_DAY` over the plans a real dawn buys on `map`, so its route is the
## dozens of events the day owes, with its stream seeded `seed_value`.
func _the_return_days_director(map: CityMap, seed_value: int) -> EventDirector:
	if _plans.is_empty():
		var state := CityState.new()
		state.begin_day(map.block_plans, RETURN_DAY)
		map.repaint(state)
		var plan_rng := RandomNumberGenerator.new()
		plan_rng.seed = 23
		_plans = EventScheduler.build_day(DaySpec.for_day(RETURN_DAY), plan_rng, map, [], [], [],
				RouteTree.for_day(map, RETURN_DAY), 0)
	var plans := _plans
	var director := EventDirector.new(map)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	director.start_day(RETURN_DAY, plans, rng)
	return director

## Her walking along the arterial's sidewalk, back and forth between the map's ends at
## `Tuning.WALK_SPEED`, and the seconds she has walked: what the director is asked every tick.
class Walk:
	extends RefCounted
	var director: EventDirector
	var at: Vector2
	var velocity := Vector2(0.0, -Tuning.WALK_SPEED)
	var clock := 0.0
	## Whether she is walking on the spot: the director is told her speed but her place stays put.
	var on_the_spot := false
	var _y_max: float

	func _init(the_director: EventDirector, map: CityMap, start: Vector2 = Vector2.INF) -> void:
		director = the_director
		_y_max = map.world_size().y
		if start == Vector2.INF:
			at = CrowdLanes.arterial_pavement(map)
			at.y = _y_max * 0.5
		else:
			at = start

	## One tick of her walk; what `EventDirector.due()` handed out, or empty.
	func tick(delta: float) -> Array:
		var due := director.due(delta, at, velocity)
		clock += delta
		if on_the_spot:
			return due
		at += velocity * delta
		if at.y < 0.0 or at.y > _y_max:
			velocity.y = -velocity.y
			at.y = clampf(at.y, 0.0, _y_max)
		return due

	## Walks `seconds` more and answers `[clock, def, path]` for each event handed out.
	func hand_outs(seconds: float) -> Array:
		var handed := []
		var until := clock + seconds
		while clock < until:
			var due := tick(STEP)
			if not due.is_empty():
				handed.append([clock, due[0], due[1]])
		return handed

# ---------------------------------------------------------------------- owing ---

## The baby can wake and settle again inside one day — `EventBus.return_phase_started` firing
## twice must not owe a second batch on top of the first.
func _test_no_double_batch_in_a_day(t) -> void:
	var map := _map()
	var director := _director(map)
	var day := RETURN_DAY # act IV, the largest batch
	director.owe_the_return(day, 0)
	var once := director.owed()
	director.owe_the_return(day, 0)
	t.check(director.owed() == once,
			"a second 'return started' the same day owes nothing more (%d, then %d)"
			% [once, director.owed()])

## `--force <id>` replaces the day's own queue with nothing but the forced row — there is no
## ordinary queue left for the return to add to or re-pace, and the brief says leave it alone. The
## director is handed the flag as the manager hands it (`force()`, taken up by `start_day()`): the
## queue stays the one forced row, and the forced row keeps coming at the forced interval (5s, a
## fixed wait where the return's pacing would roll 9 to 16s) before and after the return.
func _test_forced_queue_is_untouched(t) -> void:
	var map := _map()
	var director := _director(map, "cyclist")
	t.check(director.owed() == 1, "the forced day owes the one forced row (%d)" % director.owed())
	var walk := Walk.new(director, map)
	var before := walk.hand_outs(40.0)
	director.owe_the_return(RETURN_DAY, 0) # act IV, which would otherwise owe three
	t.check(director.owed() == 1,
			"a forced day's queue is unchanged by the return (%d owed)" % director.owed())
	var after := walk.hand_outs(40.0)
	var cyclists_only := true
	for handed: Array in before + after:
		cyclists_only = cyclists_only and (handed[1] as EventDef).id == "cyclist"
	t.check(before.size() >= 6 and after.size() >= 6 and cyclists_only,
			"and only the forced row is handed out, before the return (%d) and after (%d)"
			% [before.size(), after.size()])
	var steady := true
	var all: Array = before + after
	for i in range(1, all.size()):
		steady = steady and absf(float(all[i][0]) - float(all[i - 1][0]) - 5.0) <= STEP * 1.5
	t.check(steady, "at the forced interval every time, never the return's re-rolled pacing")

# --------------------------------------------------------------------- pacing ---

## Before the return is owed the queue rolls `EventDirector.AHEAD_INTERVAL`; once it is owed, the rest of
## the day rolls the tighter `EventDirector.RETURN_PATROL_INTERVAL` instead, so the extra rows have a
## chance to land inside the leg rather than after she is home. Read as the seconds between the
## events `due()` hands out while she walks on: no gap under the interval's floor, and by the
## return none over the tighter ceiling, where the ordinary pacing leaves gaps the tight one cannot.
func _test_pacing_switches_after_the_return_is_owed(t) -> void:
	var map := _map()
	var ordinary := _a_route_of_cats_and_cyclists(map)
	var before := _gaps(Walk.new(ordinary, map).hand_outs(300.0))
	t.check(before.size() >= 12, "the ordinary day hands out %d events to measure" % before.size())
	t.check(before.min() >= EventDirector.AHEAD_INTERVAL.x - STEP,
			"before the return, no gap (%.2fs) is under AHEAD_INTERVAL %s"
			% [before.min(), EventDirector.AHEAD_INTERVAL])
	t.check(before.max() > EventDirector.RETURN_PATROL_INTERVAL.y + 2.0,
			"and the ordinary pacing does leave gaps over the return's ceiling (longest %.2fs)"
			% before.max())
	t.check(before.max() <= EventDirector.AHEAD_INTERVAL.y + 1.5,
			"and none is over AHEAD_INTERVAL's ceiling (longest %.2fs of %s)"
			% [before.max(), EventDirector.AHEAD_INTERVAL])

	var returning := _a_route_of_cats_and_cyclists(map)
	returning.owe_the_return(RETURN_DAY, 0)
	var after := _gaps(Walk.new(returning, map).hand_outs(300.0))
	t.check(after.size() >= 12, "the return hands out %d events to measure" % after.size())
	t.check(after.min() >= EventDirector.RETURN_PATROL_INTERVAL.x - STEP,
			"after the return, no gap (%.2fs) is under RETURN_PATROL_INTERVAL %s"
			% [after.min(), EventDirector.RETURN_PATROL_INTERVAL])
	t.check(after.max() <= EventDirector.RETURN_PATROL_INTERVAL.y + 1.5,
			"and none is over it (longest %.2fs of %s)"
			% [after.max(), EventDirector.RETURN_PATROL_INTERVAL])

## A director on `RETURN_DAY` whose route is `start_recipe_route()`'s: sixty marbles alternating
## two rows that are always handed out when asked for (a cyclist down her street, a cat across it),
## with the ordinary roll for the first wait. Every marble is an event handed out, so the seconds
## between events are the pacing alone, with no place a marble names drawn between (those roll a
## wait of their own and hand nothing out).
func _a_route_of_cats_and_cyclists(map: CityMap) -> EventDirector:
	var director := _director(map)
	var marbles := []
	for i in 30:
		marbles.append_array(["cyclist", "cat_dash"])
	director.start_recipe_route(marbles, [], marbles.size(), -1.0, 0)
	return director

## The seconds between each pair of consecutive hand-outs of `hand_outs()`, from the first.
func _gaps(handed: Array) -> Array[float]:
	var gaps: Array[float] = []
	for i in range(1, handed.size()):
		gaps.append(float(handed[i][0]) - float(handed[i - 1][0]))
	if gaps.is_empty():
		gaps.append(0.0)
	return gaps

## *(inbox #561 in coral-bunny: "The return patrols in acts III and IV are added at the back of the route queue --
## the marble bag approach will properly fix this" · "they will need rigged bags".)* On a real act
## IV day, whose dawn bought dozens of route events, the return's patrols are not left behind them:
## each comes within `EventDirector.RETURN_PATROL_WITHIN_THE_NEXT` events of the return or of the patrol
## before it, so all of them are met within that many events each.
func _test_each_patrol_comes_within_its_rigged_bag(t) -> void:
	var map := _map()
	var director := _the_return_days_director(map, 29)
	var count: int = EventDirector.RETURN_PATROLS_PER_ACT[Tuning.act_for_day(RETURN_DAY) - 1]
	var x := EventDirector.RETURN_PATROL_WITHIN_THE_NEXT
	t.check(director.owed() > count * x, "the day owes more than the patrols' bags (%d)"
			% director.owed())
	var walk := Walk.new(director, map)
	# She walks a minute before the baby is asleep and the return is owed.
	walk.hand_outs(60.0)
	director.owe_the_return(RETURN_DAY, 0)
	var met: Array[String] = []
	while walk.clock < 400.0 and met.size() < count * x:
		var due := walk.tick(STEP)
		if not due.is_empty():
			met.append((due[0] as EventDef).id)
	var spaced := met.size() == count * x
	for i in count:
		spaced = spaced and met.slice(i * x, (i + 1) * x).count("police_patrol") == 1
	t.check(spaced, "each of the %d patrols is one of the %d events after the one before (%s)"
			% [count, x, met])

## A marble spent unmet because its row has had its `max_per_day` was one of a patrol's rigged bag
## all the same, so it counts against that bag and the next patrol is rigged when the bag is gone —
## or "within 2" would quietly become "within 3" for every such marble. Asked of a return whose
## ordinary bag holds only the day's most limited route row, already handed out all it may be today:
## each patrol's other marble is that row's, spent unmet, so the patrols are the only events handed
## out, one after another. Counted only when handed out, the first patrol's bag would never be
## spent and the others would never be rigged.
func _test_a_marble_spent_unmet_counts_against_the_patrols_bag(t) -> void:
	var map := _map()
	var limited: EventDef = null
	for def in EventDirector.route_rows_on(RETURN_DAY, 0):
		if limited == null or def.max_per_day < limited.max_per_day:
			limited = def
	var marbles := []
	for i in 80:
		marbles.append(limited.id)
	var director := _the_return_days_director(map, 31)
	# The row's whole day is owed first: exactly `max_per_day` of them, handed out as she walks.
	director.start_recipe_route(marbles, [], limited.max_per_day, 0.0, 0)
	var walk := Walk.new(director, map)
	var its_day: Array[String] = []
	while walk.clock < 600.0 and director.owed() > 0:
		var due := walk.tick(STEP)
		if not due.is_empty():
			its_day.append((due[0] as EventDef).id)
	t.check(its_day.size() == limited.max_per_day and director.owed() == 0,
			"'%s' has had its %d a day before the return (%d handed out, %d owed)"
			% [limited.id, limited.max_per_day, its_day.size(), director.owed()])
	director.owe_the_return(RETURN_DAY, 0)
	var count: int = EventDirector.RETURN_PATROLS_PER_ACT[Tuning.act_for_day(RETURN_DAY) - 1]
	var met: Array[String] = []
	var before := walk.clock
	while walk.clock - before < 300.0 and met.size() < count:
		var due := walk.tick(STEP)
		if not due.is_empty():
			met.append((due[0] as EventDef).id)
	t.check(met.size() == count and met.count("police_patrol") == count,
			"with the ordinary row capped, all %d patrols still come, one after another (%s)"
			% [count, met])

# --------------------------------------------------------------------- siting ---

## The road-aware sibling of the sidewalk siting every other `TOWARD_PLAYER` row gets: sited on the
## carriageway lane of her own street, driving opposite her own heading so it meets her rather than
## following her, on real driveable road tiles of a generated map. Asked as the game asks: the path
## `due()` hands out with the patrol.
func _test_sited_on_driveable_road_toward_her(t) -> void:
	var map := _map()
	var director := _the_return_days_director(map, 29)
	director.owe_the_return(RETURN_DAY, 0)
	director.rig_her_route(["police_patrol"], 1)
	# The arterial is a real north-south (vertical) street by construction.
	var walk := Walk.new(director, map)
	var heading := walk.velocity.normalized() # walking north
	var handed := []
	while walk.clock < 120.0 and handed.is_empty():
		var due := walk.tick(STEP)
		if not due.is_empty() and (due[0] as EventDef).id == "police_patrol":
			handed = due
	t.check(not handed.is_empty(), "the patrol is handed out on her street")
	if handed.is_empty():
		return
	var path: PackedVector2Array = handed[1]
	t.check(path.size() == 2, "the row is given a two-point route down the carriageway")
	if path.size() != 2:
		return

	for point in [path[0], path[1]]:
		t.check(map.is_driveable_at(true, map.world_to_tile(point)),
				"%s lies on a driveable road tile of her (vertical) street" % point)

	var travel := (path[1] - path[0]).normalized()
	t.check(travel.dot(heading) < 0.0,
			"it travels opposite her heading, so it meets her rather than follows her")

	# It stays on one lane of the carriageway rather than drifting across it: both ends share the
	# same across-corridor (x) coordinate.
	t.close_to(path[0].x, path[1].x, "both ends of the route sit on the same lane", 0.5)

## `pavement_inward()` answers `Vector2i.ZERO` off a plain sidewalk edge, which is exactly what a
## park, a square or a precinct pavement is for this purpose — nothing there has a carriageway to
## drive on, or (for a precinct) a carriageway at all, so the siting must retry later rather than
## invent a road. The patrol is the next event owed, she walks on the spot in a park and is handed
## nothing for a long while, and it is still owed, not spent: it is handed out as soon as she
## stands on a street.
func _test_empty_in_a_park(t) -> void:
	var map := _map()
	var calm := map.calm_tiles()
	t.check(not calm.is_empty(), "the generated map has calm ground to test against")
	if calm.is_empty():
		return
	var director := _the_return_days_director(map, 29)
	director.owe_the_return(RETURN_DAY, 0)
	director.rig_her_route(["police_patrol"], 1)
	var in_the_park := Walk.new(director, map, map.tile_to_world(calm[0]))
	in_the_park.on_the_spot = true
	var handed := in_the_park.hand_outs(150.0)
	t.check(handed.is_empty(),
			"no carriageway to drive on in a park, so the patrol is handed out nowhere (%d events)"
			% handed.size())
	var on_the_street := Walk.new(director, map)
	var found := false
	while on_the_street.clock < 60.0 and not found:
		var due := on_the_street.tick(STEP)
		found = not due.is_empty() and (due[0] as EventDef).id == "police_patrol"
	t.check(found, "and it was kept, not spent: it comes down her street as soon as she is on one")
