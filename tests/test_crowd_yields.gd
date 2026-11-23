extends RefCounted
## **The crowd gives way to the movers that keep their course** (inbox #884 in plaid-raven): a
## walker steps aside or is pushed, and a crowd car stands, while the event figure keeps its course.
## What a walker does about a figure standing still depends on what it is (inbox #905 in freckled-moose): it walks
## round an object or a vehicle and may walk through a person or an animal. A crowd car stands for a
## figure in its lane, moving or standing, never drives through one and never stands in a junction
## box for one, and turns round behind one that has parked (inbox #909 in freckled-moose).
##
## The rig is `test_crowd_bodies.gd`'s: a crowd on a real generated map (no city around it, no day
## planned on it), agents placed by hand on a straight stretch of street this seed's map has, and the crowd stepped as it
## is in the game (`Crowd.step()`, which gathers the map's separation pass first). The figure is a
## move put on the map's list by hand (`WorldMap.moves`), since what the crowd reads is the move and
## never the event behind it. **The events' own half** — a row's body's `is_walked_round()` and `parks()`
## reaching its move, an event leaving the list of moves where it goes, and a placement leaving the
## move where it was put — is `test_event_moves.gd`'s.

const MapCache := preload("res://tests/city_map_cache.gd")
const RIG := preload("res://tests/test_crowd_bodies.gd")
const SEED := 4242
const STEP := 1.0 / 60.0

var _rig: RIG = RIG.new()

func run(t: TestRunner) -> void:
	_test_a_placement_is_not_a_walk(t)
	var map := MapCache.of(SEED)
	var crowd := _rig.a_crowd(t, map)

	_test_a_walker_steps_round_a_standing_object(t, crowd, map)
	_test_a_walker_may_pass_through_a_standing_person(t, crowd, map)
	_test_a_car_stands_behind_a_stopped_figure_and_goes_on_when_it_goes(t, crowd, map)
	_test_a_car_turns_round_behind_a_parked_figure(t, crowd, map)
	_test_a_car_never_drives_through_a_figure_that_stops_in_front_of_it(t, crowd, map)
	_test_a_car_holds_at_the_line_for_a_figure_standing_past_the_box(t, crowd, map)

	_rig.free_crowd(crowd)

# ------------------------------------------------------------------- the rig ---

## A figure's move, standing at `at`, on `map`'s list: the radius an event figure walks at
## (`EventInstance.FIGURE_RADIUS`), keeping its course, a walker going round it while it stands
## when `stood_round`.
func _a_figure(map: WorldMap, at: Vector2, stood_round: bool) -> MoveProposal:
	var move := MoveProposal.new()
	move.use_body_radius(EventInstance.FIGURE_RADIUS)
	move.be_walked_round(stood_round)
	map.moves.join(move, at)
	return move

## Walks one walker down its lane at a figure standing on that lane five tiles ahead, for six
## seconds, and reports the nearest its centre came to the figure's, how near the two bodies touch,
## and whether it got past. With `walked_first`, the figure walks a step into place once the walker
## has set off and then stands, so it is one that has moved; without, it was placed there and
## never moved.
func _walk_at_a_standing_figure(crowd: Crowd, map: CityMap, stood_round: bool,
		walked_first: bool) -> Dictionary:
	var run: Vector2i = _rig.a_straight_run(map, Tuning.BLOCK_SIZE)
	if run.x < 0:
		return {}
	crowd.start_day(1, _rng(1), Vector2.ZERO)
	crowd.clear()
	var walker: CrowdAgent = _rig.place_on(crowd, map, CrowdAgent.Kind.WALKER, run.x, 0,
			float(run.y) * Tuning.TILE_SIZE + 4.0, 1.0)
	var at := Vector2(walker.position.x, float(run.y + 5) * Tuning.TILE_SIZE)
	var figure := _a_figure(map, at - Vector2(0.0, 6.0) if walked_first else at, stood_round)
	var closest := INF
	var deepest := walker.position.y
	crowd.use_focus(FakeCrowdFocus.new(at))
	for frame in int(round(6.0 / STEP)):
		if walked_first and frame == 2:
			figure.place(at)
		crowd.step(STEP)
		closest = minf(closest, walker.position.distance_to(at))
		deepest = maxf(deepest, walker.position.y)
	map.moves.leave(figure)
	return {"closest": closest,
			"touching": walker.lane().shape().reach() + figure.body_radius(),
			"past": deepest > at.y + float(Tuning.TILE_SIZE)}

## A vehicle's move, a patrol car's size (the reach of `police_patrol`'s body), standing at `at`
## on `map`'s list, keeping its course, parked when `parked`.
func _a_vehicle(map: CityMap, at: Vector2, parked: bool) -> MoveProposal:
	var move := MoveProposal.new()
	move.use_body_radius(EventCatalogue.by_id("police_patrol").ground_shape().reach())
	move.be_walked_round(true)
	move.be_parked(parked)
	map.moves.join(move, at)
	return move

## A vertical corridor of ordinary street holding a whole block's stretch, the junction box after it
## and three tiles past the box: the corridor and the first along tile of the stretch, or `(-1, -1)`.
func _a_block_before_a_box(map: CityMap) -> Vector2i:
	var length := 2 * CityMap.period() + Tuning.STREET_WIDTH
	var run: Vector2i = _rig.a_straight_run(map, length)
	if run.x < 0:
		return run
	for along in range(run.y, run.y + length):
		if posmod(along, CityMap.period()) == Tuning.STREET_WIDTH \
				and along + Tuning.BLOCK_SIZE + Tuning.STREET_WIDTH + 3 <= run.y + length:
			return Vector2i(run.x, along)
	return Vector2i(-1, -1)

## Drives one crowd car south down its lane, inside a block's stretch, at a vehicle
## standing in that lane at `figure_along`, which stepped into place from beside the lane on the
## second frame, so it is one that has moved. `car_along` is where the car starts, `stand` how many
## seconds the vehicle stands before it leaves the list, and `after` how long the car is watched
## after that. Reports the frames the car's body overlapped the vehicle's, whether the car ever had
## its nose in the box ahead, its speed when the vehicle left, whether it turned round or off the
## street, and the furthest south it got.
func _drive_at_a_vehicle(crowd: Crowd, map: CityMap, corridor: int, car_along: float,
		figure_along: float, parked: bool, stand: float, after: float) -> Dictionary:
	crowd.start_day(1, _rng(1), Vector2.ZERO)
	crowd.clear()
	var lane: int = CrowdLanes.road_lane(true, 1.0)
	var car: CrowdAgent = _rig.place_on(crowd, map, CrowdAgent.Kind.CAR, corridor, lane, car_along,
			1.0)
	var at := Vector2(CrowdLanes.lane_centre(corridor, lane), figure_along)
	var figure := _a_vehicle(map, at + Vector2(6.0, 0.0), parked)
	var overlapping := 0
	var in_the_box := false
	var speed_when_it_left := -1.0
	var deepest := car.position.y
	crowd.use_focus(FakeCrowdFocus.new(at))
	for frame in int(round((stand + after) / STEP)):
		if frame == 2:
			figure.place(at)
		if frame == int(round(stand / STEP)):
			speed_when_it_left = car.speed()
			map.moves.leave(figure)
		crowd.step(STEP)
		if figure.is_on_the_list() and _overlaps(car, figure):
			overlapping += 1
		in_the_box = in_the_box or car.junction_occupied().x >= 0
		if _rig.still_driving_down(car, corridor):
			deepest = maxf(deepest, car.position.y)
	if figure.is_on_the_list():
		map.moves.leave(figure)
	var turned: bool = not _rig.still_driving_down(car, corridor)
	return {"overlapping": overlapping, "in_the_box": in_the_box, "speed": speed_when_it_left,
			"turned": turned, "deepest": deepest, "at": at, "car": car}

## Whether a crowd car's capsule overlaps a figure's body: its centre nearer the car's spine than
## the two radii.
func _overlaps(car: CrowdAgent, figure: MoveProposal) -> bool:
	var spine := car.heading() * car.lane().shape().spine_half_length()
	var nearest := Geometry2D.get_closest_point_to_segment(figure.stands_at(), car.position - spine,
			car.position + spine)
	return nearest.distance_to(figure.stands_at()) < car.lane().shape().rounding_radius() + figure.body_radius() - 0.5

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("crowd-yields:%d:%d" % [SEED, day])
	return rng

const PLACEMENT_WALK := 8.0

## **A resting figure stood on other ground by hand is placed, not walked there**
## (`MoveProposal.place()`): the separation pass reads no velocity off a step longer than
## `SeparationPass.PLACEMENT_STEP`, and the figure does not count as under way. A step under that
## limit is still a walk, so the pass does read steps at all. Both figures are moves put on a bare
## map's list by hand, since the pass reads the move and never the event behind it.
func _test_a_placement_is_not_a_walk(t: TestRunner) -> void:
	var at := Vector2(5000.0, 5000.0)
	var map := WorldMap.open_ground()
	var placed := _a_figure(map, at, false)
	var pass_over := SeparationPass.new(map.moves)
	pass_over.gather()
	placed.place(at + Vector2(400.0, 0.0))
	pass_over.gather()
	t.check(pass_over.walker_keepers().is_empty() and not pass_over.has_keepers_for_cars(),
			"a 400px placement is no walk: no walker and no car gives way to the person put there")
	var walker := _a_figure(map, at, false)
	pass_over.gather()
	walker.place(at + Vector2(PLACEMENT_WALK, 0.0))
	pass_over.gather()
	var kept: Array[SeparationPass.Keeper] = []
	for keeper in pass_over.walker_keepers():
		if keeper.move == walker:
			kept.append(keeper)
	t.check(kept.size() == 1, "a step under the placement limit puts the figure among the keepers")
	if kept.size() == 1:
		t.check(kept[0].step == Vector2(PLACEMENT_WALK, 0.0) and kept[0].ticks_still == 0,
				"a step under the placement limit is still a walk")

# ------------------------------------------------------ a walker meets one ---

## **A walker walks round an object or a vehicle standing in its way** (inbox #905 in freckled-moose): placed on its
## lane and never moved, like a parked van, its body is never entered, and the walker gets past it.
func _test_a_walker_steps_round_a_standing_object(t: TestRunner, crowd: Crowd, map: CityMap) -> void:
	var got := _walk_at_a_standing_figure(crowd, map, true, false)
	t.check(not got.is_empty(), "this city has a straight stretch of street to stand a figure on")
	if got.is_empty():
		return
	t.check(got["closest"] >= got["touching"] - 0.5,
			"a walker never walks into a standing object (came to %.1fpx, the bodies touch at %.1fpx)"
			% [got["closest"], got["touching"]])
	t.check(got["past"], "and it gets past the object rather than stopping at it")

## **A walker may walk through a person or an animal standing still** (inbox #905 in freckled-moose): one that walked
## into place and has stood there since, like a dog crouched before its charge, is not stood round,
## and the walker keeps to its lane through it.
func _test_a_walker_may_pass_through_a_standing_person(t: TestRunner, crowd: Crowd, map: CityMap) -> void:
	var got := _walk_at_a_standing_figure(crowd, map, false, true)
	if got.is_empty():
		return
	t.check(got["closest"] < got["touching"] - 1.0,
			"a walker keeps its lane through a standing person (came to %.1fpx, the bodies touch at %.1fpx)"
			% [got["closest"], got["touching"]])
	t.check(got["past"], "and it walks on past")

# --------------------------------------------------------- a crowd car meets one ---

## **A car stands behind a vehicle stopped in its lane for as long as it stands, and goes on when it
## goes** (inbox #909 in freckled-moose): the patrol car at a red light or while its man is out is waited for, well past
## a moment's pause, and the car never turns round for it.
func _test_a_car_stands_behind_a_stopped_figure_and_goes_on_when_it_goes(t: TestRunner, crowd: Crowd,
		map: CityMap) -> void:
	var block := _a_block_before_a_box(map)
	t.check(block.x >= 0, "this city has a block's stretch before a junction box to drive down")
	if block.x < 0:
		return
	var tile := float(Tuning.TILE_SIZE)
	var got := _drive_at_a_vehicle(crowd, map, block.x, (float(block.y) + 1.5) * tile,
			(float(block.y + Tuning.BLOCK_SIZE) - 0.5) * tile, false, 4.0, 3.0)
	t.check(got["speed"] >= 0.0 and got["speed"] < Tuning.CAR_STOPPED_SPEED,
			"a car stands behind a stopped vehicle for four seconds (%.1fpx/s when it left)"
			% got["speed"])
	t.check(not got["turned"], "and waits for it rather than turning round")
	t.check(got["overlapping"] == 0, "and never drives into it (%d frames it did)"
			% got["overlapping"])
	t.check(got["deepest"] > (got["at"] as Vector2).y,
			"and drives on past where it stood once it goes")

## **A car behind a parked vehicle in its lane turns round** (inbox #909 in freckled-moose), as it does at a blocked
## street, rather than standing behind it for the rest of the day.
func _test_a_car_turns_round_behind_a_parked_figure(t: TestRunner, crowd: Crowd, map: CityMap) -> void:
	var block := _a_block_before_a_box(map)
	if block.x < 0:
		return
	var tile := float(Tuning.TILE_SIZE)
	var got := _drive_at_a_vehicle(crowd, map, block.x, (float(block.y) + 1.5) * tile,
			(float(block.y + Tuning.BLOCK_SIZE) - 0.5) * tile, true, 8.0, 0.0)
	t.check(got["turned"], "a car behind a parked vehicle turns round or off the street")
	t.check(got["overlapping"] == 0, "without ever driving into it (%d frames it did)"
			% got["overlapping"])

## **A car never drives through a figure standing in its lane** (inbox #909 in freckled-moose): one that steps into
## the lane closer than the car can brake for and stands is held off by the car's step, every frame
## it stands, however long that is. The figure stands two tiles ahead of a car at full speed, inside
## its braking distance from the moment it appears, so the brake alone leaves the car in it and only
## the step hold (`CarStrategy.give_way_on_the_step()`) keeps the overlap at 0: with that hold removed
## this check fails.
func _test_a_car_never_drives_through_a_figure_that_stops_in_front_of_it(t: TestRunner, crowd: Crowd,
		map: CityMap) -> void:
	var block := _a_block_before_a_box(map)
	if block.x < 0:
		return
	var tile := float(Tuning.TILE_SIZE)
	var car_along := (float(block.y) + 1.5) * tile
	var got := _drive_at_a_vehicle(crowd, map, block.x, car_along, car_along + 2.0 * tile, false,
			5.0, 0.0)
	t.check(got["overlapping"] == 0,
			"a car never drives through a vehicle that stops right in front of it (%d frames it did)"
			% got["overlapping"])

## **A car never stands in a junction box for a figure standing past it** (inbox #909 in freckled-moose, the box rule
## of the **crowd-traffic** skill): it holds at the stop line, since a car standing in the box would
## hold the crossing street too.
func _test_a_car_holds_at_the_line_for_a_figure_standing_past_the_box(t: TestRunner, crowd: Crowd,
		map: CityMap) -> void:
	var block := _a_block_before_a_box(map)
	if block.x < 0:
		return
	var tile := float(Tuning.TILE_SIZE)
	var far_side := float(block.y + Tuning.BLOCK_SIZE + Tuning.STREET_WIDTH) * tile
	var reach := EventCatalogue.by_id("police_patrol").ground_shape().reach()
	var got := _drive_at_a_vehicle(crowd, map, block.x, (float(block.y) + 1.5) * tile,
			far_side + reach + 8.0, false, 6.0, 0.0)
	t.check(not got["in_the_box"], "a car holds at the line for a vehicle standing just past the box")
	t.check(got["overlapping"] == 0, "and never drives into it (%d frames it did)"
			% got["overlapping"])
