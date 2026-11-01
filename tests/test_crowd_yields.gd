extends RefCounted
## **The crowd gives way to the movers that keep their course** (inbox #884 in plaid-raven): a
## walker steps aside or is pushed, and a crowd car stands, while the event figure keeps its course.
## What a walker does about a figure standing still depends on what it is (inbox #905): it walks
## round an object or a vehicle and may walk through a person or an animal.
##
## The rig is `test_crowd_bodies.gd`'s: a real generated city with no day planned on it, agents
## placed by hand on a straight stretch of street this seed's city has, and the crowd stepped as it
## is in the game (`Crowd.step()`, which gathers the map's separation pass first). The figure is a
## move put on the map's list by hand (`WorldMap.moves`), since what the crowd reads is the move and
## never the event behind it; the events' own half — a row's `stands_as` reaching its move — is
## asked of real instances.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const RIG := preload("res://tests/test_crowd_bodies.gd")
const SEED := 4242
const STEP := 1.0 / 60.0

var _rig = RIG.new()

func run(t) -> void:
	_test_a_row_hands_what_it_stands_as_to_its_move(t)
	var map := CityGenerator.generate(SEED)
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.build(map)

	_test_a_walker_steps_round_a_standing_object(t, city, map)
	_test_a_walker_may_pass_through_a_standing_person(t, city, map)

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
