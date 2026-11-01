extends RefCounted
## **The crowd gives way to the movers that keep their course** (inbox #884 in plaid-raven): a
## walker steps aside or is pushed, and a crowd car stands, while the event figure keeps its course.
## What a walker does about a figure standing still depends on what it is (inbox #905): it walks
## round an object or a vehicle and may walk through a person or an animal. A crowd car stands for a
## figure in its lane, moving or standing, never drives through one and never stands in a junction
## box for one, and turns round behind one that has parked (inbox #909).
##
## The rig is `test_crowd_bodies.gd`'s: a real generated city with no day planned on it, agents
## placed by hand on a straight stretch of street this seed's city has, and the crowd stepped as it
## is in the game (`Crowd.step()`, which gathers the map's separation pass first). The figure is a
## move put on the map's list by hand (`WorldMap.moves`), since what the crowd reads is the move and
## never the event behind it; the events' own half — a row's `stands_as` and `when_it_stops`
## reaching its move — is asked of real instances.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const RIG := preload("res://tests/test_crowd_bodies.gd")
const SEED := 4242
const STEP := 1.0 / 60.0

var _rig = RIG.new()

func run(t) -> void:
	_test_a_row_hands_what_it_stands_as_to_its_move(t)
	_test_a_row_hands_whether_it_has_parked_to_its_move(t)
	var map := CityGenerator.generate(SEED)
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.build(map)

	_test_a_walker_steps_round_a_standing_object(t, city, map)
	_test_a_walker_may_pass_through_a_standing_person(t, city, map)
	_test_a_car_stands_behind_a_stopped_figure_and_goes_on_when_it_goes(t, city, map)
	_test_a_car_turns_round_behind_a_parked_figure(t, city, map)
	_test_a_car_never_drives_through_a_figure_that_stops_in_front_of_it(t, city, map)
	_test_a_car_holds_at_the_line_for_a_figure_standing_past_the_box(t, city, map)

	city.free()

# ------------------------------------------------------------------- the rig ---

## A figure's move, standing at `at`, on `map`'s list: the radius an event figure walks at
## (`EventInstance.FIGURE_RADIUS`), keeping its course, a walker going round it while it stands
## when `stood_round`.
func _a_figure(map: CityMap, at: Vector2, stood_round: bool) -> MoveProposal:
	var move := MoveProposal.new()
	move.radius = EventInstance.FIGURE_RADIUS
	move.stood_round = stood_round
	map.moves.join(move, at)
	return move

## Walks one walker down its lane at a figure standing on that lane five tiles ahead, for six
## seconds, and reports the nearest its centre came to the figure's, how near the two bodies touch,
## and whether it got past. With `walked_first`, the figure walks a step into place once the walker
## has set off and then stands, so it is one that has moved; without, it was placed there and
## never moved.
func _walk_at_a_standing_figure(city: City, map: CityMap, stood_round: bool,
		walked_first: bool) -> Dictionary:
	var run: Vector2i = _rig._a_straight_run(map, Tuning.BLOCK_SIZE)
	if run.x < 0:
		return {}
	city.crowd.start_day(1, _rng(1), Vector2.ZERO)
	city.crowd.clear()
	var walker: CrowdAgent = _rig._agent_on(city, map, CrowdAgent.Kind.WALKER, run.x, 0,
			float(run.y) * Tuning.TILE_SIZE + 4.0, 1.0)
	var at := Vector2(walker.position.x, float(run.y + 5) * Tuning.TILE_SIZE)
	var figure := _a_figure(map, at - Vector2(0.0, 6.0) if walked_first else at, stood_round)
	var closest := INF
	var deepest := walker.position.y
	for frame in int(round(6.0 / STEP)):
		if walked_first and frame == 2:
			figure.place(at)
		city.crowd.set_focus(at)
		city.crowd.step(STEP)
		closest = minf(closest, walker.position.distance_to(at))
		deepest = maxf(deepest, walker.position.y)
	map.moves.leave(figure)
	return {"closest": closest, "touching": walker.shape.reach() + figure.radius,
			"past": deepest > at.y + float(Tuning.TILE_SIZE)}

## A vehicle's move, a patrol car's size (the reach of `police_patrol`'s body), standing at `at`
## on `map`'s list, keeping its course, parked when `parked`.
func _a_vehicle(map: CityMap, at: Vector2, parked: bool) -> MoveProposal:
	var move := MoveProposal.new()
	move.radius = EventCatalogue.by_id("police_patrol").shape.reach()
	move.stood_round = true
	move.parked = parked
	map.moves.join(move, at)
	return move

## A vertical corridor of ordinary street holding a whole block's stretch, the junction box after it
## and three tiles past the box: the corridor and the first along tile of the stretch, or `(-1, -1)`.
func _a_block_before_a_box(map: CityMap) -> Vector2i:
	var length := 2 * CityMap.period() + Tuning.STREET_WIDTH
	var run: Vector2i = _rig._a_straight_run(map, length)
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
func _drive_at_a_vehicle(city: City, map: CityMap, corridor: int, car_along: float,
		figure_along: float, parked: bool, stand: float, after: float) -> Dictionary:
	city.crowd.start_day(1, _rng(1), Vector2.ZERO)
	city.crowd.clear()
	var lane: int = CrowdLanes.road_lane(true, 1.0)
	var car: CrowdAgent = _rig._agent_on(city, map, CrowdAgent.Kind.CAR, corridor, lane, car_along,
			1.0)
	var at := Vector2(CrowdLanes.lane_centre(corridor, lane), figure_along)
	var figure := _a_vehicle(map, at + Vector2(6.0, 0.0), parked)
	var overlapping := 0
	var in_the_box := false
	var speed_when_it_left := -1.0
	var deepest := car.position.y
	for frame in int(round((stand + after) / STEP)):
		if frame == 2:
			figure.place(at)
		if frame == int(round(stand / STEP)):
			speed_when_it_left = car.speed()
			map.moves.leave(figure)
		city.crowd.set_focus(at)
		city.crowd.step(STEP)
		if figure.on_the_list and _overlaps(car, figure):
			overlapping += 1
		in_the_box = in_the_box or car.junction_occupied().x >= 0
		if car._vertical and car._corridor == corridor and car._direction > 0.0:
			deepest = maxf(deepest, car.position.y)
	if figure.on_the_list:
		map.moves.leave(figure)
	var turned := car._corridor != corridor or not car._vertical or car._direction < 0.0
	return {"overlapping": overlapping, "in_the_box": in_the_box, "speed": speed_when_it_left,
			"turned": turned, "deepest": deepest, "at": at, "car": car}

## Whether a crowd car's capsule overlaps a figure's body: its centre nearer the car's spine than
## the two radii.
func _overlaps(car: CrowdAgent, figure: MoveProposal) -> bool:
	var spine := car.heading() * car.shape.half_length
	var nearest := Geometry2D.get_closest_point_to_segment(figure.from, car.position - spine,
			car.position + spine)
	return nearest.distance_to(figure.from) < car.shape.radius + figure.radius - 0.5

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("crowd-yields:%d:%d" % [SEED, day])
	return rng

# ------------------------------------------------------- what a figure is ---

## **Each row's `stands_as` reaches its move** (`EventInstance.setup()`): the patrol car and the
## fire engine, vehicles, are walked round while they stand; the charging dog and the policeman on
## foot, an animal and a person, are not, so the dog waiting on the map before its charge may be
## walked through, as the player allowed. And every row of the catalogue declares it, which
## `EventDef.validate()` also refuses to load without.
func _test_a_row_hands_what_it_stands_as_to_its_move(t) -> void:
	var expected := {"police_patrol": true, "fire_truck": true, "market_stall": true,
			"charging_dog": false, "policeman_giving_chase": false, "busker": false}
	for id: String in expected:
		var instance := EventInstance.new()
		instance.setup(EventCatalogue.by_id(id), Vector2(100.0, 100.0))
		t.check(instance._move.stood_round == expected[id],
				"%s's move says a walker goes round it while it stands: %s" % [id, expected[id]])
		instance.free()
	var undeclared: Array[String] = []
	for def in EventCatalogue.all():
		if def.stands_as == EventDef.StandsAs.UNDECLARED:
			undeclared.append(def.id)
	t.check(undeclared.is_empty(), "every row says what it stands as (undeclared: %s)" % [undeclared])

## **Each row's `when_it_stops` reaches its move as whether it has parked** (`EventInstance`, inbox
## #909): a stall, which never moves, has parked from the start; the fire engine has not while it
## drives and has once it stops at its fire, and not once it leaves; the patrol car and the charging
## dog go on, so never. And every row of the catalogue declares it, which `EventDef.validate()` also
## refuses to load without.
func _test_a_row_hands_whether_it_has_parked_to_its_move(t) -> void:
	var stall := EventInstance.new()
	stall.setup(EventCatalogue.by_id("market_stall"), Vector2(100.0, 100.0))
	t.check(stall._move.parked, "a stall, which never moves, has parked from the start")
	stall.free()
	var engine := EventInstance.new()
	engine.setup(EventCatalogue.by_id("fire_truck"), Vector2(100.0, 100.0))
	t.check(not engine._move.parked, "the fire engine has not parked while it drives")
	engine.transition(EventInstance.Phase.PARKED)
	t.check(engine._move.parked, "and has once it stops at its fire")
	engine.transition(EventInstance.Phase.LEAVING)
	t.check(not engine._move.parked, "and nothing leaving has parked")
	engine.free()
	for id: String in ["police_patrol", "charging_dog"]:
		var instance := EventInstance.new()
		instance.setup(EventCatalogue.by_id(id), Vector2(100.0, 100.0))
		instance.transition(EventInstance.Phase.PARKED)
		t.check(not instance._move.parked, "%s goes on, so it never reads as parked" % id)
		instance.free()
	var undeclared: Array[String] = []
	for def in EventCatalogue.all():
		if def.when_it_stops == EventDef.WhenItStops.UNDECLARED:
			undeclared.append(def.id)
	t.check(undeclared.is_empty(), "every row says whether it parks (undeclared: %s)" % [undeclared])

# ------------------------------------------------------ a walker meets one ---

## **A walker walks round an object or a vehicle standing in its way** (inbox #905): placed on its
## lane and never moved, like a parked van, its body is never entered, and the walker gets past it.
func _test_a_walker_steps_round_a_standing_object(t, city: City, map: CityMap) -> void:
	var got := _walk_at_a_standing_figure(city, map, true, false)
	t.check(not got.is_empty(), "this city has a straight stretch of street to stand a figure on")
	if got.is_empty():
		return
	t.check(got["closest"] >= got["touching"] - 0.5,
			"a walker never walks into a standing object (came to %.1fpx, the bodies touch at %.1fpx)"
			% [got["closest"], got["touching"]])
	t.check(got["past"], "and it gets past the object rather than stopping at it")

## **A walker may walk through a person or an animal standing still** (inbox #905): one that walked
## into place and has stood there since, like a dog crouched before its charge, is not stood round,
## and the walker keeps to its lane through it.
func _test_a_walker_may_pass_through_a_standing_person(t, city: City, map: CityMap) -> void:
	var got := _walk_at_a_standing_figure(city, map, false, true)
	if got.is_empty():
		return
	t.check(got["closest"] < got["touching"] - 1.0,
			"a walker keeps its lane through a standing person (came to %.1fpx, the bodies touch at %.1fpx)"
			% [got["closest"], got["touching"]])
	t.check(got["past"], "and it walks on past")

# --------------------------------------------------------- a crowd car meets one ---

## **A car stands behind a vehicle stopped in its lane for as long as it stands, and goes on when it
## goes** (inbox #909): the patrol car at a red light or while its man is out is waited for, well past
## a moment's pause, and the car never turns round for it.
func _test_a_car_stands_behind_a_stopped_figure_and_goes_on_when_it_goes(t, city: City,
		map: CityMap) -> void:
	var block := _a_block_before_a_box(map)
	t.check(block.x >= 0, "this city has a block's stretch before a junction box to drive down")
	if block.x < 0:
		return
	var tile := float(Tuning.TILE_SIZE)
	var got := _drive_at_a_vehicle(city, map, block.x, (float(block.y) + 1.5) * tile,
			(float(block.y + Tuning.BLOCK_SIZE) - 0.5) * tile, false, 4.0, 3.0)
	t.check(got["speed"] >= 0.0 and got["speed"] < Tuning.CAR_STOPPED_SPEED,
			"a car stands behind a stopped vehicle for four seconds (%.1fpx/s when it left)"
			% got["speed"])
	t.check(not got["turned"], "and waits for it rather than turning round")
	t.check(got["overlapping"] == 0, "and never drives into it (%d frames it did)"
			% got["overlapping"])
	t.check(got["deepest"] > (got["at"] as Vector2).y,
			"and drives on past where it stood once it goes")

## **A car behind a parked vehicle in its lane turns round** (inbox #909), as it does at a blocked
## street, rather than standing behind it for the rest of the day.
func _test_a_car_turns_round_behind_a_parked_figure(t, city: City, map: CityMap) -> void:
	var block := _a_block_before_a_box(map)
	if block.x < 0:
		return
	var tile := float(Tuning.TILE_SIZE)
	var got := _drive_at_a_vehicle(city, map, block.x, (float(block.y) + 1.5) * tile,
			(float(block.y + Tuning.BLOCK_SIZE) - 0.5) * tile, true, 8.0, 0.0)
	t.check(got["turned"], "a car behind a parked vehicle turns round or off the street")
	t.check(got["overlapping"] == 0, "without ever driving into it (%d frames it did)"
			% got["overlapping"])

## **A car never drives through a figure standing in its lane** (inbox #909): one that steps into
## the lane closer than the car can brake for and stands is held off by the car's step, every frame
## it stands, however long that is.
func _test_a_car_never_drives_through_a_figure_that_stops_in_front_of_it(t, city: City,
		map: CityMap) -> void:
	var block := _a_block_before_a_box(map)
	if block.x < 0:
		return
	var tile := float(Tuning.TILE_SIZE)
	var car_along := (float(block.y) + 1.5) * tile
	var got := _drive_at_a_vehicle(city, map, block.x, car_along, car_along + 3.0 * tile, false,
			5.0, 0.0)
	t.check(got["overlapping"] == 0,
			"a car never drives through a vehicle that stops right in front of it (%d frames it did)"
			% got["overlapping"])

## **A car never stands in a junction box for a figure standing past it** (inbox #909, the box rule
## of the **crowd-traffic** skill): it holds at the stop line, since a car standing in the box would
## hold the crossing street too.
func _test_a_car_holds_at_the_line_for_a_figure_standing_past_the_box(t, city: City,
		map: CityMap) -> void:
	var block := _a_block_before_a_box(map)
	if block.x < 0:
		return
	var tile := float(Tuning.TILE_SIZE)
	var far_side := float(block.y + Tuning.BLOCK_SIZE + Tuning.STREET_WIDTH) * tile
	var reach := EventCatalogue.by_id("police_patrol").shape.reach()
	var got := _drive_at_a_vehicle(city, map, block.x, (float(block.y) + 1.5) * tile,
			far_side + reach + 8.0, false, 6.0, 0.0)
	t.check(not got["in_the_box"], "a car holds at the line for a vehicle standing just past the box")
	t.check(got["overlapping"] == 0, "and never drives into it (%d frames it did)"
			% got["overlapping"])
