@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## The world's one answer to "can this mover stand here": the map's blocked record read through a
## `Mover` (`CityMap.passable()`, `CityMap.clear_line()`), a `Navigator` every mover moves by, and a
## `Footprint` both a solid's body and its record come from.
##
## The player: "I mean that happens with a lot of events (eg cat / bike just completely ignoring
## buildings; neighbor walking through barricades) we need to do a fix for this at some point but
## not now", and "those are examples not an exhaustive list" (minty-lemur #791). So besides the
## rules on small hand-built ground, a walker here runs every catalogue row that moves on a real
## city, its route laid straight through whatever stands there, and fails on any step that enters
## ground its mover may not.
##
## **Its cities come from the cache of generated cities** (`tests/city_map_cache.gd`): each
## seed's city is generated once in the test process and every case is handed a copy of its own,
## the same city `CityGenerator.generate()` builds for the seed.

const MapCache := preload("res://tests/city_map_cache.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
## The day the walker runs: one with the region wall, seals and bodies standing.
const WALK_DAY := 9
const TILE := float(Tuning.TILE_SIZE)

func run(t) -> void:
	_test_each_mover_is_stopped_by_its_own_layers(t)
	_test_is_walkable_is_the_lattice(t)
	_test_a_line_stops_at_a_body_and_sees_out_of_its_own(t)
	_test_a_step_is_swept_so_a_long_frame_cannot_tunnel(t)
	_test_a_step_keeps_the_body_clear(t)
	_test_a_mover_on_blocked_ground_may_walk_off_it(t)
	_test_a_route_is_cut_where_a_solid_stands(t)
	_test_a_walk_goes_round_what_was_put_down(t)
	_test_a_car_sees_her_off_street_ground(t)
	_test_a_cut_crossing_still_meets_her_line_on_time(t)
	_test_a_director_handed_only_the_map_sites_round_what_stands_there(t)
	for check: Callable in [_test_a_body_and_its_record_are_one_footprint,
			_test_a_closure_barrier_stands_on_closed_ground,
			_test_the_cat_crossing_never_ends_in_a_lot,
			_test_a_departure_leaves_round_a_building,
			_test_every_row_that_moves_stays_off_blocked_ground,
			_test_every_mover_on_a_map_shares_its_one_navigator]:
		_in_a_day(t, check)

## **One navigator per map** (`WorldMap.navigator()`): the city's and its event manager's are the
## map's one object. The crowd and the director take it when handed none; a crowd's is checked in
## `test_navigator_fallbacks.gd`. A director handed only the map is checked here by what it does (it
## sites a crossing round a body standing across it), which does not pin that it shares the map's one
## navigator: a director that builds its own `Navigator.new(map)` passes.
func _test_every_mover_on_a_map_shares_its_one_navigator(t, city: City) -> void:
	t.check(city.map.navigator() == city.navigator
			and city.events.world.navigator() == city.navigator,
			"the city and its events move by the map's one navigator")

# ---------------------------------------------------------------------- ground ---

## Twelve tiles square of open sidewalk, to put solids on by hand.
static func _yard(size := Vector2i(12, 12)) -> CityMap:
	var map := CityMap.new(size)
	map.fill_rect(Rect2i(Vector2i.ZERO, size), GameEnums.TileType.SIDEWALK)
	return map

## A yard big enough for the street lattice, with the vertical street at the origin walled in on
## its east side by a column of building and shut by `close_streets()`: the map's own closure, which
## closes the ground the street's two barriers cut off from the doorstep.
static func _yard_with_a_street_shut() -> CityMap:
	var map := _yard(Vector2i.ONE * CityMap.period() * 2)
	var street := map.network.by_key(Vector3i(0, 0, 1))
	var wall := street.tile_rect()
	map.fill_rect(Rect2i(Vector2i(Tuning.STREET_WIDTH, wall.position.y), Vector2i(1, wall.size.y)),
			GameEnums.TileType.BUILDING)
	var shut: Array[RoadClosure] = [RoadClosure.new(RoadClosure.Kind.ROADWORKS, street)]
	map.close_streets(shut)
	return map

static func _centre(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE

## One tile of each solid in a row, and a park beside them: what each mover is stopped by is the
## layers it names, and nothing else.
func _test_each_mover_is_stopped_by_its_own_layers(t) -> void:
	var map := _yard_with_a_street_shut()
	var building := Vector2i(1, 1)
	var post := Vector2i(2, 1)
	var closed := Vector2i(3, CityMap.period() / 2)
	var soft := Vector2i(4, 1)
	var body := Vector2i(5, 1)
	var open := Vector2i(6, 1)
	var park := Vector2i(7, 1)
	map.set_tile(building, GameEnums.TileType.BUILDING)
	map.set_tile(park, GameEnums.TileType.PARK)
	map.blocked.lay_posts([post] as Array[Vector2i])
	t.check(map.is_closed(closed), "fixture: the shut street holds the closed tile")
	map.seal_soft_tile(soft)
	var covered: Array[Vector2i] = [body]
	map.obstruct_tiles(1, covered)
	var on_foot := Mover.on_foot()
	for tile in [building, post, closed, soft, body]:
		t.check(not map.passable(tile, on_foot), "a figure on foot is stopped at %s" % tile)
	t.check(map.passable(open, on_foot) and map.passable(park, on_foot),
			"and walks open sidewalk and park")
	var car := Mover.vehicle()
	t.check(map.passable(soft, car), "a car drives past a soft seal, which takes only the pavement")
	t.check(not map.passable(park, car), "a car keeps to street ground")
	for tile in [building, post, closed, body]:
		t.check(not map.passable(tile, car), "a car is stopped at %s" % tile)
	var lattice := Mover.lattice()
	t.check(map.passable(closed, lattice) and map.passable(soft, lattice)
			and map.passable(body, lattice),
			"the city as built is not stopped by anything a day puts down")
	t.check(not map.passable(building, lattice) and not map.passable(post, lattice),
			"and is stopped by the ground and the posts")
	map.release_obstruction(1)
	t.check(map.passable(body, on_foot), "a body given back opens its ground")

## `CityMap.is_walkable()` is `passable()` for the lattice, spelt out for speed: they answer the same
## over a whole generated city.
func _test_is_walkable_is_the_lattice(t) -> void:
	var map := MapCache.of(SEED)
	var disagree := 0
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if map.is_walkable(tile) != map.passable(tile, Mover.lattice()):
				disagree += 1
	t.check(disagree == 0, "is_walkable() answers as passable() for the lattice (%d differ)" % disagree)

## A line through a body is no clear line for a figure on foot; one from inside a band it stands in
## sees out; and a body over her own tile does not hide her.
func _test_a_line_stops_at_a_body_and_sees_out_of_its_own(t) -> void:
	var map := _yard()
	var band: Array[Vector2i] = [Vector2i(5, 5), Vector2i(6, 5)]
	map.obstruct_tiles(1, band)
	var on_foot := Mover.on_foot()
	t.check(map.clear_line(_centre(Vector2i(3, 5)), _centre(Vector2i(8, 5))),
			"the lattice's line runs through a body")
	t.check(not map.clear_line(_centre(Vector2i(3, 5)), _centre(Vector2i(8, 5)), on_foot),
			"a figure's line does not")
	t.check(map.clear_line(_centre(Vector2i(5, 5)), _centre(Vector2i(9, 5)), on_foot),
			"a line from inside the band it stands in sees out of it")
	t.check(map.clear_line(_centre(Vector2i(2, 5)), _centre(Vector2i(5, 5)), on_foot),
			"a body covering her own tile does not hide her")
	t.check(not map.clear_line(_centre(Vector2i(2, 5)), _centre(Vector2i(6, 5)), on_foot),
			"one standing in front of her does")

## A wall a tile thick, and a step three tiles long across it, as a long frame gives a chaser: the
## tile it lands on is open, so only a swept step refuses it.
func _test_a_step_is_swept_so_a_long_frame_cannot_tunnel(t) -> void:
	var map := _yard()
	map.fill_rect(Rect2i(5, 0, 1, 12), GameEnums.TileType.BUILDING)
	var from := _centre(Vector2i(4, 5))
	var across := Vector2(3.0 * TILE, 0.0)
	t.check(map.is_walkable(map.world_to_tile(from + across)),
			"the step lands on open ground beyond the wall")
	var taken := Navigator.new(map).step(from, across, Mover.on_foot())
	t.check(taken == Vector2.ZERO, "and is refused, not taken through the wall (%s)" % taken)
	var diagonal := Vector2(3.0 * TILE, 2.0 * TILE)
	taken = Navigator.new(map).step(from, diagonal, Mover.on_foot())
	t.check(map.world_to_tile(from + taken).x < 5,
			"a slide along it never crosses it either (%s)" % taken)
	t.check(Navigator.new().step(from, across, Mover.on_foot()) == across,
			"open ground takes every step whole")

## A step keeps its body's reach clear in the way it is going: a man 9px wide stops short of a wall
## a point mover would walk up to.
func _test_a_step_keeps_the_body_clear(t) -> void:
	var map := _yard()
	map.fill_rect(Rect2i(5, 0, 1, 12), GameEnums.TileType.BUILDING)
	var navigator := Navigator.new(map)
	var from := Vector2(5.0 * TILE - 12.0, _centre(Vector2i(4, 5)).y)
	var toward := Vector2(10.0, 0.0)
	t.check(navigator.step(from, toward, Mover.on_foot()) == toward,
			"a point steps to within 2px of the wall")
	t.check(navigator.step(from, toward, Mover.on_foot(9.0)) == Vector2.ZERO,
			"a body 9px wide does not")
	t.check(navigator.step(from, Vector2(0.0, 10.0), Mover.on_foot(9.0)) == Vector2(0.0, 10.0),
			"and walks along the wall's face")

## A figure standing on a day's solid — put there before the solid was — walks off it; one on open
## ground does not walk onto it.
func _test_a_mover_on_blocked_ground_may_walk_off_it(t) -> void:
	var map := _yard()
	var band: Array[Vector2i] = [Vector2i(5, 5), Vector2i(6, 5)]
	map.obstruct_tiles(1, band)
	var navigator := Navigator.new(map)
	var on_foot := Mover.on_foot()
	var inside := _centre(Vector2i(5, 5))
	t.check(navigator.step(inside, Vector2(TILE, 0.0), on_foot) == Vector2(TILE, 0.0),
			"from inside the band he walks across the rest of it")
	t.check(navigator.step(_centre(Vector2i(4, 5)), Vector2(TILE, 0.0), on_foot) == Vector2.ZERO,
			"from beside it he does not walk in")
	map.set_tile(Vector2i(8, 8), GameEnums.TileType.BUILDING)
	t.check(navigator.step(_centre(Vector2i(8, 8)), Vector2(TILE, 0.0), on_foot)
			== Vector2(TILE, 0.0), "one inside a building walks out of it")

## A route is cut at the farthest point a mover reaches down it, never past a solid, and refused
## where its first point is not ground the mover may stand on.
func _test_a_route_is_cut_where_a_solid_stands(t) -> void:
	var map := _yard()
	var body: Array[Vector2i] = [Vector2i(6, 5)]
	map.obstruct_tiles(1, body)
	var navigator := Navigator.new(map)
	var cat := Mover.on_foot(7.0)
	var route := PackedVector2Array([_centre(Vector2i(1, 5)), _centre(Vector2i(10, 5))])
	var cut := navigator.trim(route, cat)
	t.check(cut.size() == 2 and cut[1].x < 6.0 * TILE - 7.0 + 0.01 and cut[1].x > 5.0 * TILE,
			"the route stops short of the body by the cat's reach (%s)" % cut)
	map.set_tile(Vector2i(1, 5), GameEnums.TileType.BUILDING)
	t.check(navigator.trim(route, cat).is_empty(), "a route starting inside a building is refused")

## A walk down points goes round a body put across it since: stopped whole, it asks for a way round
## to its next point and the way round never enters the body.
func _test_a_walk_goes_round_what_was_put_down(t) -> void:
	var map := _yard()
	var wall: Array[Vector2i] = [Vector2i(6, 4), Vector2i(6, 5), Vector2i(6, 6)]
	map.obstruct_tiles(1, wall)
	var navigator := Navigator.new(map)
	var on_foot := Mover.on_foot(9.0)
	var from := Vector2(6.0 * TILE - 10.0, _centre(Vector2i(5, 5)).y)
	var points := PackedVector2Array([_centre(Vector2i(9, 5))])
	var walked := navigator.walk(from, points, 4.0, on_foot)
	t.check(walked.stopped and walked.at == from, "the walk is stopped at the body")
	var round := navigator.path(from, points[0], on_foot)
	t.check(not round.is_empty() and round[round.size() - 1] == points[0],
			"a way round reaches the point")
	var entered := false
	for point in round:
		entered = entered or not map.passable(map.world_to_tile(point), on_foot)
	t.check(not entered, "and never steps onto the body")

## A car drives on street ground only, and sees her wherever she stands: an investigating patrol
## notices her one tile into an alley, a square or a park as it does on the sidewalk, along a line
## its own driving would never take.
func _test_a_car_sees_her_off_street_ground(t) -> void:
	var patrol := EventCatalogue.by_id("police_patrol")
	t.check(patrol.vehicle != null, "the patrol is a car that drives")
	for ground in [GameEnums.TileType.ALLEY, GameEnums.TileType.SQUARE, GameEnums.TileType.PARK,
			GameEnums.TileType.SIDEWALK]:
		var map := _yard(Vector2i(8, 8))
		map.fill_rect(Rect2i(0, 1, 8, 1), GameEnums.TileType.ROAD)
		map.fill_rect(Rect2i(3, 3, 2, 2), ground)
		var car := EventInstance.new()
		car.skip_draw = true
		car.setup(patrol, _centre(Vector2i(3, 1)), PackedVector2Array(), Vector2.RIGHT, map)
		t.add_child(car)
		var her := _centre(Vector2i(3, 3))
		t.check(car.clear_line_to(her), "a car sees her standing on %s" % ground)
		t.check(map.passable(map.world_to_tile(her), EventInstance.mover_for(patrol))
				== (ground == GameEnums.TileType.SIDEWALK),
				"and drives only where street ground is (%s)" % ground)
		car.free()

## A cat whose run a solid cut short crouches longer by the run it lost, so it reaches the middle of
## its crossing when a whole run would have: when she, walked up by its lead, gets there.
func _test_a_cut_crossing_still_meets_her_line_on_time(t) -> void:
	var cat := EventCatalogue.by_id("cat_dash")
	var whole := float(Tuning.STREET_WIDTH) * TILE
	var on_time := cat.telegraph_time + whole / cat.speed
	for run in [whole, whole * 0.5, TILE]:
		var instance := EventInstance.new()
		instance.skip_draw = true
		var path := PackedVector2Array([Vector2(-run, 0.0), Vector2(run, 0.0)])
		instance.setup(cat, path[0], path)
		t.add_child(instance)
		instance.set_process(false)
		instance.hold_still_longer(cat.crouch_for_a_run(run))
		var clock := 0.0
		while instance.global_position.x < 0.0 and clock < 10.0:
			instance.step(0.01)
			clock += 0.01
		t.close_to(clock, on_time, "a run of %.0fpx reaches the middle when a whole one does" % run,
				0.03)
		instance.free()
	t.check(cat.ahead_of_player_lead() >= on_time * Tuning.WALK_SPEED - 0.01,
			"which is when she, walking, reaches it")

## A director over `map` alone, handed no navigator, owing nothing but the cat every five seconds
## (`force()`, taken up by `start_day()`, as the manager hands the flag in).
func _a_director_owing_the_cat(map: CityMap) -> EventDirector:
	var director := EventDirector.new(map)
	director.force("cat_dash", 5.0)
	var no_plans: Array[EventScheduler.Planned] = []
	director.start_day(1, no_plans, _rng("director"))
	return director

## What the director hands out when she is at `her` walking `heading`, once its wait has passed: the
## row, its path, the seconds it crouches beyond its telegraph and the point on her line the run is
## sited to cross (`EventDirector.due()`, which the manager asks every tick); empty where it found
## nowhere to put one.
func _sited_ahead_of(director: EventDirector, her: Vector2, heading: Vector2) -> Array:
	return director.due(10.0, her, heading * Tuning.WALK_SPEED)

## A cat is sited across the line of a figure walking east on open sidewalk, with a body standing
## across the way it would run on one side: a director handed only the map (`EventDirector.new(map)`)
## moves by the map's navigator, so the run it sites never goes through the body, and on a map with
## nothing standing there the same director sites the whole run.
func _test_a_director_handed_only_the_map_sites_round_what_stands_there(t) -> void:
	var cat := EventCatalogue.by_id("cat_dash")
	var mover := EventInstance.mover_for(cat)
	var her := _centre(Vector2i(5, 20))
	var heading := Vector2.RIGHT
	var centre_tile := _yard(Vector2i(60, 40)).world_to_tile(her + heading * cat.ahead_of_player_lead())
	var open := _yard(Vector2i(60, 40))
	var whole := 0.0
	var director := _a_director_owing_the_cat(open)
	for _try in 6:
		var sited := _sited_ahead_of(director, her, heading)
		if not sited.is_empty():
			var run: PackedVector2Array = sited[1]
			whole = maxf(whole, run[0].distance_to(run[1]))
	t.check(whole >= float(Tuning.STREET_WIDTH) * TILE,
			"with nothing standing there the cat is sited a whole street's run (%.0fpx)" % whole)
	var walled := _yard(Vector2i(60, 40))
	var body: Array[Vector2i] = []
	for dy in range(3, Tuning.STREET_WIDTH + 2):
		body.append(centre_tile + Vector2i(0, dy))
	walled.obstruct_tiles(1, body)
	director = _a_director_owing_the_cat(walled)
	var runs := 0
	var through := 0
	var cut := 0
	for _try in 24:
		var sited := _sited_ahead_of(director, her, heading)
		if sited.is_empty():
			continue
		var run: PackedVector2Array = sited[1]
		runs += 1
		if not walled.clear_line(run[0], run[1], mover):
			through += 1
		if run[0].distance_to(run[1]) < whole - 0.01:
			cut += 1
	print("DIRECTOR on a walled yard: %d runs sited, %d cut short, %d through the body"
			% [runs, cut, through])
	t.check(runs > 0 and cut > 0, "a cat is sited and its run is cut short by the body (%d, %d)"
			% [runs, cut])
	t.check(through == 0, "and no run is sited through it (%d of %d)" % [through, runs])

# ---------------------------------------------------------------- a real city ---

## Seed 4242's day 9, its closures, seals and bodies put down, in a city and a run of its own, handed
## to `check` and freed after, so no check leans on what another left standing.
func _in_a_day(t, check: Callable) -> void:
	var run_state := RunState.new()
	run_state.start_run(SEED)
	var city: City = RunCity.in_run(CITY_SCENE, run_state)
	t.add_child(city)
	city.build(MapCache.of(SEED))
	var state := CityState.new()
	run_state.attempt_spend.city_state = state
	state.begin_day(city.map.block_plans, WALK_DAY)
	city.start_day(state, WALK_DAY, _rng("closures"))
	city.events.start_day(DaySpec.for_day(WALK_DAY), _rng("events"), [], city.map.doorstep_world_position())
	check.call(t, city)
	city.free()

static func _rng(stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("world-passability:%d:%s" % [SEED, stream])
	return rng

## Every planned body's record is the tiles of the footprint its instance builds its physics body
## from: the instance's own pieces, where it stands and the way it lies, rasterised, are the plan's
## recorded tiles.
func _test_a_body_and_its_record_are_one_footprint(t, city: City) -> void:
	var map := city.map
	var compared := 0
	var differ := 0
	for plan in city.events.plans():
		if not plan.is_placed() or plan.def.mobile or plan.def.detain_seconds > 0.0 \
				or plan.def.solid_when == EventDef.SolidWhen.WHILE_LOWERED or plan.def.obstructs_radius <= 0.0:
			continue
		var recorded := EventSpawner.obstructed_footprint(map, plan.def, plan.position,
				plan.facing)
		var instance := EventInstance.new()
		instance.skip_draw = true
		instance.setup(plan.def, plan.position, PackedVector2Array(), plan.facing, map)
		var built := Footprint.new()
		var centres := instance.solid_part_centres()
		var shapes := instance.solid_part_shapes()
		for i in shapes.size():
			built.add(shapes[i], centres[i] - instance.position, instance.solid_axis())
		var tiles := built.tiles(instance.position)
		tiles.sort()
		recorded.sort()
		compared += 1
		if tiles != recorded:
			differ += 1
		instance.free()
		if compared >= 60:
			break
	t.check(compared > 10, "there were planned bodies to compare (%d)" % compared)
	t.check(differ == 0, "each body's record is its own footprint's tiles (%d of %d differ)"
			% [differ, compared])

## A closure's barrier line stands on ground the closure took, so every mover is stopped by the same
## line that stops her. Read off the solid the city put in the world at each mouth: its collision box,
## laid down the tiles it covers, is on closed ground.
func _test_a_closure_barrier_stands_on_closed_ground(t, city: City) -> void:
	var map := city.map
	var lines := 0
	var stood := 0
	var outside := 0
	for closure in city.streets().closures():
		for mouth in closure.mouth_centres(map):
			lines += 1
			var body := _barrier_body_at(city, mouth)
			if body == null:
				continue
			stood += 1
			var box := (body.get_child(0) as CollisionShape2D).shape as RectangleShape2D
			for tile in Footprint.of(GroundShape.rect(box.size * 0.5)).tiles(mouth):
				if not map.is_closed(tile):
					outside += 1
	t.check(lines > 0, "the day has barrier lines to check (%d)" % lines)
	t.check(stood == lines, "and the city stands a solid at each of them (%d of %d)" % [stood, lines])
	t.check(outside == 0, "every barrier's tiles are closed ground (%d are not)" % outside)

## The solid body the city stands at `at`, one box, or null.
func _barrier_body_at(city: City, at: Vector2) -> StaticBody2D:
	for body in city.find_children("*", "StaticBody2D", false, false):
		if (body as StaticBody2D).position.is_equal_approx(at) and body.get_child_count() == 1 \
				and (body.get_child(0) as CollisionShape2D).shape is RectangleShape2D:
			return body
	return null

## The cat's crossing, sited ahead of her as she walks, starts and ends on ground a cat may stand on
## and runs clear between, never out of or into a lot; so does the scheduler's own crossing from any
## road tile a cat may stand on.
func _test_the_cat_crossing_never_ends_in_a_lot(t, city: City) -> void:
	var map := city.map
	var cat := EventCatalogue.by_id("cat_dash")
	var mover := EventInstance.mover_for(cat)
	var director := _a_director_owing_the_cat(map)
	var sited := 0
	var bad := 0
	var cut := 0
	var in_its_field := 0
	var sidewalks := map.tiles_of_type(GameEnums.TileType.SIDEWALK)
	for i in range(0, sidewalks.size(), maxi(1, sidewalks.size() / 300)):
		var her := map.tile_to_world(sidewalks[i])
		for heading: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN,
				Vector2(1.0, 1.0).normalized()]:
			var crossing := _sited_ahead_of(director, her, heading)
			if crossing.is_empty():
				continue
			var run: PackedVector2Array = crossing[1]
			sited += 1
			if not map.passable(map.world_to_tile(run[0]), mover) \
					or not map.passable(map.world_to_tile(run[1]), mover) \
					or not map.clear_line(run[0], run[1], mover):
				bad += 1
			# She walks on toward it while it crouches, its telegraph and its longer crouch both,
			# and is outside the crouching cat's field until it runs.
			var crouch: float = crossing[2]
			if crouch > 0.0:
				cut += 1
			var clock := 0.0
			while clock <= cat.telegraph_time + crouch:
				if (her + heading * Tuning.WALK_SPEED * clock).distance_to(run[0]) \
						<= cat.outer_radius:
					in_its_field += 1
					break
				clock += 0.02
	t.check(sited > 100, "crossings were sited (%d)" % sited)
	t.check(bad == 0, "every crossing starts and ends on open ground with a clear run (%d not)"
			% bad)
	t.check(cut > 10, "crossings were sited with a cut start (%d)" % cut)
	t.check(in_its_field == 0,
			"walking on, she is never inside the crouching cat's field before it runs (%d were)"
			% in_its_field)
	var ends := 0
	var in_a_lot := 0
	var none: Array[EventScheduler.Planned] = []
	# No catalogue row is planned as a crossing (`EventDef.PathMode.CROSS_STREET`: the cat is sited by
	# the director), so the row is the cat with the scheduler's crossing path laid for it.
	var scheduled := cat.duplicate() as EventDef
	scheduled.path_mode = EventDef.PathMode.CROSS_STREET
	for tile in map.tiles_of_type(GameEnums.TileType.ROAD):
		if tile.x % 7 != 0 or not map.passable(tile, Mover.on_foot()):
			continue
		var placed := EventScheduler.place_at(scheduled, map, tile, _rng("cross-street"), none)
		if placed == null:
			continue
		for end in placed.path:
			ends += 1
			if not map.passable(map.world_to_tile(end), Mover.on_foot()):
				in_a_lot += 1
	t.check(ends > 0 and in_a_lot == 0,
			"the scheduler's crossings end on open ground (%d of %d do not)" % [in_a_lot, ends])

## A dog that loses interest facing a building leaves round it: every frame of its departure is on
## ground it may stand on, and it gets away from her.
func _test_a_departure_leaves_round_a_building(t, city: City) -> void:
	var map := city.map
	var dog := EventCatalogue.by_id("loose_dog")
	var start := Vector2.INF
	var into := Vector2.ZERO
	for tile in map.tiles_of_type(GameEnums.TileType.SIDEWALK):
		var inward := map.pavement_inward(tile)
		if inward == Vector2i.ZERO or map.tile_at(tile + inward) != GameEnums.TileType.BUILDING \
				or not map.passable(tile, Mover.on_foot()):
			continue
		start = map.tile_to_world(tile)
		into = Vector2(inward)
		break
	t.check(start != Vector2.INF, "there is a pavement against a building to stand the dog on")
	if start == Vector2.INF:
		return
	var instance := city.events.spawn_extra(dog, start)
	instance.set_process(false)
	instance.excitement.set_player_at(start - into * 80.0)
	instance.give_up_the_chase()
	t.check(instance.is_leaving and instance.facing_now().is_equal_approx(into),
			"it starts leaving facing the building, away from her (%s)" % instance.facing_now())
	var mover := EventInstance.mover_for(dog)
	var off := 0
	var before := instance.global_position
	for _frame in 120:
		instance.departure.leave(0.05)
		if instance.is_finished:
			break
		if not map.step_is_clear(before, instance.global_position, Mover.of(mover.blocked_by)):
			off += 1
		before = instance.global_position
	t.check(off == 0, "its departure never enters a building (%d steps did)" % off)
	t.check(instance.is_finished or instance.global_position.distance_to(start) > 2.0 * TILE,
			"and it gets away rather than standing against the wall (%.0fpx)"
			% instance.global_position.distance_to(start))
	city.events.retire(instance)

## **The walker**: every catalogue row that moves, on seed 4242's day 9, started on its own ground
## nearest her doorstep, given a route straight north through whatever stands there — her own
## building, from her street — and her standing north of it across the same, for
## six seconds of its event and four of its departure. No step it takes, nor any step of a far
## guard it sends off, enters ground its mover may not.
func _test_every_row_that_moves_stays_off_blocked_ground(t, city: City) -> void:
	var map := city.map
	var walked := 0
	var steps := 0
	var bad: Array[String] = []
	var stalled: Array[String] = []
	var anchor := map.doorstep_world_position()
	for def in EventCatalogue.all():
		if not (def.mobile or def.pursuit != null or def.flock_size > 0):
			continue
		var mover := EventInstance.mover_for(def)
		var at := _a_start_for(map, def, mover, anchor)
		if at == Vector2.INF:
			continue
		var route := PackedVector2Array()
		if def.mobile and def.pursuit == null:
			route = PackedVector2Array([at, at + Vector2(0.0, -12.0 * TILE)])
		var instance := city.events.spawn_extra(def, at, route)
		instance.set_process(false)
		var her := at + Vector2(0.0, -6.0 * TILE)
		var asked := Mover.of(mover.blocked_by)
		var before := instance.global_position
		var guard_before := Vector2.INF
		var left_from := Vector2.INF
		walked += 1
		for frame in 200:
			instance.excitement.set_player_at(her)
			if frame == 120 and not instance.is_leaving:
				instance.give_up_the_chase()
			if instance.is_leaving:
				if left_from == Vector2.INF:
					left_from = instance.global_position
				instance.departure.leave(0.05)
			else:
				instance.step(0.05)
			if instance.is_finished:
				break
			var now := instance.global_position
			if map.passable(map.world_to_tile(before), asked):
				steps += 1
				if not map.step_is_clear(before, now, asked):
					bad.append("%s %s -> %s" % [def.id, before, now])
			before = now
			if instance.barrier_post and instance.barrier_post.where_the_far_guard_walks() != Vector2.INF:
				if guard_before != Vector2.INF \
						and map.passable(map.world_to_tile(guard_before), asked) \
						and not map.step_is_clear(guard_before, instance.barrier_post.where_the_far_guard_walks(), asked):
					bad.append("%s's far guard %s -> %s" % [def.id, guard_before,
							instance.barrier_post.where_the_far_guard_walks()])
				guard_before = instance.barrier_post.where_the_far_guard_walks()
		if left_from != Vector2.INF and not instance.is_finished \
				and instance.global_position.distance_to(left_from) < TILE:
			stalled.append(def.id)
		city.events.retire(instance)
	# What the remeasuring step reads: a departure that a solid holds within a tile of where it
	# began, which the contract that nothing vanishes in her view keeps standing there.
	print("WALKER day %d seed %d: %d rows, %d steps asked, departures held within a tile: %s"
			% [WALK_DAY, SEED, walked, steps, stalled])
	t.check(walked >= 10, "the walker ran the rows that move (%d)" % walked)
	t.check(steps > 1000, "and asked their steps (%d)" % steps)
	t.check(bad.is_empty(), "no step entered ground its mover may not (%d did: %s)"
			% [bad.size(), bad.slice(0, 5)])

## The nearest tile to `anchor` of a ground the row is placed on, that its mover may stand on.
static func _a_start_for(map: CityMap, def: EventDef, mover: Mover, anchor: Vector2) -> Vector2:
	var best := Vector2.INF
	var best_distance := INF
	for type in def.placement:
		for tile in map.tiles_of_type(type as GameEnums.TileType):
			var at := map.tile_to_world(tile)
			var distance := at.distance_squared_to(anchor)
			if distance < best_distance and distance > 0.0 and map.passable(tile, mover):
				best = at
				best_distance = distance
	return best
