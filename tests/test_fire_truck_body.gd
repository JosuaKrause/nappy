extends RefCounted
## The fire truck is a solid body, lethal only in front of it while it drives and harmless once it
## has parked at the fire.
##
## The player's words *(2026-10-04, calm-kestrel, inbox #558: "the fire truck has no collision at
## all -- I can walk through it without it being lethal"; asked what touching it should do: "Lethal
## driving, solid parked")*. The truck is built the way the patrol car is (sunny-finch,
## `EventDef.vehicle`): lethal only in front of it, with a car's warning, while it drives its route.
## Her real `CharacterBody2D` rig is swept against a real `fire_truck` instance's body with the
## synchronous `move_and_collide()` sweep `tests/test_police_car.gd` uses, and the truck is stepped
## by hand, a frame at a time, told where she and her pram are the way `EventManager` tells it.

const STEP := 1.0 / 60.0
const WALK := 2.0

func run(t) -> void:
	_test_the_row_is_a_car_with_the_engines_body(t)
	_test_the_body_is_solid_while_it_drives_and_lethal_only_ahead(t)
	_test_in_front_of_it_the_warning_comes_first(t)
	_test_where_it_is_created_she_is_warned_in_full(t)
	_test_nothing_reaches_past_its_kerb(t)
	_test_behind_and_beside_it_nothing_strikes(t)
	_test_parked_it_is_solid_and_harmless(t)
	_test_parked_its_field_is_a_points(t)
	_test_a_parked_body_closes_no_street(t)
	_test_a_loss_to_it_names_its_own_cause(t)
	_test_its_picture_stands_over_its_body(t)

# ------------------------------------------------------------------ the rig ---

func _truck() -> EventDef:
	return EventCatalogue.by_id("fire_truck")

## A live truck on `route`, its warning spent (`spawn_warned()` hands it over with the telegraph
## used up), in the tree so its body exists, stepped by hand.
func _engine(t, route: PackedVector2Array) -> EventInstance:
	var def := _truck()
	var engine := EventInstance.new()
	engine.setup(def, route[0], route, (route[1] - route[0]).normalized(), null)
	engine.resume(def.telegraph_time, 0.0)
	t.add_child(engine)
	engine.set_process(false)
	return engine

func _her(t, at: Vector2, facing: Vector2) -> Stroller:
	var packed: PackedScene = load("res://scenes/player/stroller.tscn")
	var player: Stroller = packed.instantiate()
	t.add_child(player)
	player.set_physics_process(false)
	player.global_position = at
	player.facing = facing
	var pram := player.get_node("PramCollisionShape2D") as CollisionShape2D
	pram.position = facing * Tuning.PLAYER_BODY_RADIUS
	return player

func _step(engine: EventInstance, player: Stroller) -> void:
	engine.player_at = player.global_position
	engine.pram_at = player.global_position + player.facing * Tuning.PLAYER_BODY_RADIUS
	engine.step(STEP)
	if engine._obstruction:
		engine._obstruction.force_update_transform()
		for child in engine._obstruction.get_children():
			(child as Node2D).force_update_transform()

func _walk(player: Stroller, heading: Vector2, distance: float) -> float:
	var walked := 0.0
	while walked < distance:
		if player.move_and_collide(heading * WALK) != null:
			break
		walked += WALK
	return walked

## What stops `player` walking on along `heading` from where she stands: the collider a further
## step would meet, or null.
func _what_stops(player: Stroller, heading: Vector2) -> Object:
	var hit := player.move_and_collide(heading * WALK, true)
	return hit.get_collider() if hit else null

# ----------------------------------------------------------------- the row ---

func _test_the_row_is_a_car_with_the_engines_body(t) -> void:
	var def := _truck()
	t.check(def.vehicle != null, "fire_truck drives: solid in every state, lethal in front while driving")
	t.check(def.shape != null and def.shape.kind == GroundShape.Kind.SEGMENT,
			"its body is a capsule laid along its heading")
	t.check(is_equal_approx(def.shape.reach() * 2.0, 58.0)
			and is_equal_approx(def.shape.radius * 2.0, 26.0),
			"58px bumper to bumper (fire_engine.svg, x 2 to 60) and 26px flank to flank "
			+ "(fire_engine_front.svg, x 4 to 30): %.0f by %.0f"
			% [def.shape.reach() * 2.0, def.shape.radius * 2.0])
	t.check(def.obstructs_radius == 0.0 and not def.hard_fail,
			"it closes no ground and is no hard fail: it kills only as a car does")
	t.check(def.shape.reach() < def.inner_radius,
			"and the body lies inside the field's inner radius")
	t.check(def.telegraph_time > 0.0 and def.warned_first,
			"it keeps its off-screen warning (M226, 'fire truck has heavy penalty')")

# ------------------------------------------------------------------ driving ---

## Walked at side-on, a parked or driving truck stops her at its flank; lethal only ahead.
func _test_the_body_is_solid_while_it_drives_and_lethal_only_ahead(t) -> void:
	var engine := _engine(t, PackedVector2Array([Vector2(-300.0, 0.0), Vector2(900.0, 0.0)]))
	var player := _her(t, Vector2(0.0, 70.0), Vector2.UP)
	var struck := false
	var pressed := false
	var stopped := false
	for i in int(5.0 / STEP):
		_step(engine, player)
		struck = struck or engine.is_lethal_at(player.global_position)
		if not pressed and absf(engine.global_position.x) < 6.0:
			pressed = true
			stopped = _walk(player, Vector2.UP, 70.0) < 70.0 \
					and _what_stops(player, Vector2.UP) == engine._obstruction
	t.check(pressed and stopped, "walking into a driving truck's flank, its body stops her")
	t.check(not struck, "and it never strikes her beside it")
	player.free()
	engine.free()

## In its lane, on the carriageway, a car's warning comes `CAR_HORN_TIME` of its travel before the
## strike, at least as long as walking off the carriageway takes, and the strike fires before the
## body would ever stop against her.
func _test_in_front_of_it_the_warning_comes_first(t) -> void:
	for facing in [Vector2.LEFT, Vector2.UP]:
		var engine := _engine(t, PackedVector2Array([Vector2(-700.0, 0.0), Vector2(900.0, 0.0)]))
		var player := _her(t, Vector2.ZERO, facing)
		var warned_at := -1.0
		var struck_at := -1.0
		var held := false
		for i in int(8.0 / STEP):
			_step(engine, player)
			var now := float(i) * STEP
			if warned_at < 0.0 and engine.car.closes_on(player.global_position):
				warned_at = now
			held = held or engine.car.is_standing()
			if engine.is_lethal_at(player.global_position):
				struck_at = now
				break
		t.check(struck_at > 0.0, "facing %s in its lane, the driving truck strikes her" % facing)
		var warning := struck_at - warned_at
		t.check(warned_at >= 0.0 and warning >= Tuning.required_horn_time(),
				"facing %s, warned %.2fs before the strike, at least the %.2fs to walk off the road"
				% [facing, warning, Tuning.required_horn_time()])
		t.check(not held, "and it did not stop against her first")
		t.check(engine.will_be_lethal(player.global_position), "the doubled caret was up over it")
		player.free()
		engine.free()

## **Created where the game creates it**, just out of sight up its street
## (`PendingWarning.on_its_route()`, the place `EventManager._summon_the_sighted_row()` asks for),
## from each of the four sides, with her standing in its lane facing it. On any street that place is
## nearer her than its warning reaches her (1.7s of its 190px/s past the touch, the touch counting
## its body and hers): up a north-south street the view is 180px to either side of her, and across
## an east-west one 320px. A truck driving from its first frame would strike her inside the time it
## takes to walk off the road. A car that drives is created standing (`EventCarDriving`'s car that has
## stood): it waits there while she is in its lane within its warning, and nothing strikes her.
## Once she is further along its lane than its warning reaches, it drives on, and the strike comes
## after the full warning.
func _test_where_it_is_created_she_is_warned_in_full(t) -> void:
	var def := _truck()
	var warning_reach := (Tuning.PATROL_STRIKE_LEAD + Tuning.CAR_HORN_TIME) * def.speed \
			+ def.shape.half_length + def.shape.radius + Tuning.PLAYER_BODY_RADIUS
	var nearer_than_its_warning := 0
	var sides := {Vector2.DOWN: "the north", Vector2.UP: "the south", Vector2.RIGHT: "the west",
			Vector2.LEFT: "the east"}
	for travel: Vector2 in sides:
		var side: String = sides[travel]
		var her := Vector2.ZERO
		var stop := her + travel * 600.0
		var place := PendingWarning.on_its_route(def, her, stop, travel, 4000.0,
				VisibleView.around(her))
		t.check(place != Vector2.INF, "from %s, there is a place out of sight to create it" % side)
		if place == Vector2.INF:
			continue
		if place.distance_to(her) < warning_reach:
			nearer_than_its_warning += 1
		var engine := _engine(t, PackedVector2Array([place, stop]))
		var player := _her(t, her, -travel)
		var struck := false
		var moved := false
		for i in int(3.0 / STEP):
			_step(engine, player)
			struck = struck or engine.is_lethal_at(player.global_position)
			moved = moved or engine.global_position.distance_to(place) > 1.0
		t.check(not struck and not moved,
				"from %s, created %.0fpx from her, it waits while she stands in its lane"
				% [side, place.distance_to(her)])
		# Further along its lane than its warning reaches her: it drives, and warns in full.
		player.global_position = place + travel * (warning_reach + 40.0)
		var warned_at := -1.0
		var struck_at := -1.0
		for i in int(5.0 / STEP):
			_step(engine, player)
			var now := float(i) * STEP
			if warned_at < 0.0 and engine.car.closes_on(player.global_position):
				warned_at = now
			if engine.is_lethal_at(player.global_position):
				struck_at = now
				break
		t.check(struck_at > 0.0 and warned_at >= 0.0
				and struck_at - warned_at >= Tuning.required_horn_time(),
				"from %s, once she is beyond its warning it drives on and strikes her %.2fs after "
				% [side, struck_at - warned_at] + "the mark, at least the %.2fs to walk off the road"
				% Tuning.required_horn_time())
		player.free()
		engine.free()
	t.check(nearer_than_its_warning == 4,
			"every side's place is nearer her than its warning reaches (%d of 4)"
			% nearer_than_its_warning)

# ------------------------------------------------------------ at its kerb ---

## **Its kerb is where it stops, so nothing of it reaches past.** A car's warning, strike and stand
## reach 1.7s of its travel past the touch, but the engine's route ends at the kerb it parks at
## (`stops_where_it_arrives`): past it, in its lane, she gets no mark and no doubled caret, is never
## struck by an engine that parks short of her, and does not hold it off screen.
func _test_nothing_reaches_past_its_kerb(t) -> void:
	# 120px past the kerb, the truck already driving: no warning that cannot come true.
	var engine := _engine(t, PackedVector2Array([Vector2(-600.0, 0.0), Vector2.ZERO]))
	var player := _her(t, Vector2(120.0, 0.0), Vector2.LEFT)
	var warned := false
	var lethal := false
	for i in int(5.0 / STEP):
		_step(engine, player)
		warned = warned or engine.car.closes_on(player.global_position)
		lethal = lethal or engine.will_be_lethal(player.global_position) \
				or engine.is_lethal_at(player.global_position)
		if engine.is_parked:
			break
	t.check(engine.is_parked and not warned and not lethal,
			"120px past its kerb, no mark and no doubled caret over a truck that parks short of her")
	player.free()
	engine.free()
	# 50-60px past it, her pram on the far side: it parks short of her and ends nothing.
	for past: float in [50.0, 55.0, 60.0]:
		engine = _engine(t, PackedVector2Array([Vector2(-600.0, 0.0), Vector2.ZERO]))
		player = _her(t, Vector2(past, 0.0), Vector2.RIGHT)
		lethal = false
		for i in int(5.0 / STEP):
			_step(engine, player)
			lethal = lethal or engine.is_lethal_at(player.global_position)
			if engine.is_parked:
				break
		var gap := engine.car.gap_to_her(engine.global_position, engine._heading)
		t.check(engine.is_parked and gap > 0.0 and not lethal,
				"%.0fpx past its kerb, it parks %.0fpx short of her and the day goes on"
				% [past, gap])
		player.free()
		engine.free()
	# Past it when it is created, clear of where its body parks: it does not wait for her, it
	# drives on and parks. (Nearer than 43px its parked body would overlap hers, and it stands
	# against her there rather than driving into her.)
	for past: float in [60.0, 120.0, 250.0]:
		engine = _engine(t, PackedVector2Array([Vector2(-200.0, 0.0), Vector2.ZERO]))
		player = _her(t, Vector2(past, 0.0), Vector2.RIGHT)
		for i in int(3.0 / STEP):
			_step(engine, player)
			if engine.is_parked:
				break
		t.check(engine.is_parked, "%.0fpx past its kerb when it is created, it drives on and parks"
				% past)
		player.free()
		engine.free()
	# And between it and its kerb she is still warned in full and struck.
	engine = _engine(t, PackedVector2Array([Vector2(-700.0, 0.0), Vector2.ZERO]))
	player = _her(t, Vector2(-100.0, 0.0), Vector2.LEFT)
	var warned_at := -1.0
	var struck_at := -1.0
	for i in int(5.0 / STEP):
		_step(engine, player)
		var now := float(i) * STEP
		if warned_at < 0.0 and engine.car.closes_on(player.global_position):
			warned_at = now
		if engine.is_lethal_at(player.global_position):
			struck_at = now
			break
	t.check(struck_at > 0.0 and warned_at >= 0.0
			and struck_at - warned_at >= Tuning.required_horn_time(),
			"between it and its kerb she is warned %.2fs before the strike" % (struck_at - warned_at))
	player.free()
	engine.free()

## Behind it and beside it, driving, nothing strikes her.
func _test_behind_and_beside_it_nothing_strikes(t) -> void:
	var engine := _engine(t, PackedVector2Array([Vector2(40.0, 0.0), Vector2(1200.0, 0.0)]))
	var player := _her(t, Vector2.ZERO, Vector2.RIGHT)
	var struck := false
	var touched := false
	for i in int(2.5 / STEP):
		_step(engine, player)
		struck = struck or engine.is_lethal_at(player.global_position)
		if player.move_and_collide(Vector2.RIGHT * Tuning.WALK_SPEED * STEP) != null:
			touched = true
	t.check(not struck, "a truck driving away from her never strikes her behind it")
	t.check(engine.car.is_driving(), "and it was driving")
	player.free()
	engine.free()
	# Standing beside its line, it passes her without a strike.
	engine = _engine(t, PackedVector2Array([Vector2(-300.0, 0.0), Vector2(600.0, 0.0)]))
	player = _her(t, Vector2(0.0, 45.0), Vector2.LEFT)
	struck = false
	for i in int(5.0 / STEP):
		_step(engine, player)
		struck = struck or engine.is_lethal_at(player.global_position)
	t.check(not struck and engine.global_position.x > 100.0,
			"and one driving past her on the next lane never strikes her (%.0f)"
			% engine.global_position.x)
	player.free()
	engine.free()

# ------------------------------------------------------------------- parked ---

## Once it has stopped at the fire it is a body she walks round and nothing that can end the day,
## from in front of it, behind it or beside it.
func _test_parked_it_is_solid_and_harmless(t) -> void:
	var engine := _engine(t, PackedVector2Array([Vector2(-200.0, 0.0), Vector2(0.0, 0.0)]))
	var player := _her(t, Vector2(300.0, 300.0), Vector2.UP)
	for i in int(4.0 / STEP):
		_step(engine, player)
		if engine.is_parked:
			break
	t.check(engine.is_parked, "the truck parks where its route ends")
	t.check(not engine.car.is_driving() and not engine.will_be_lethal(Vector2(40.0, 0.0)),
			"and a parked truck is not driving")
	for place in [Vector2(40.0, 0.0), Vector2(-40.0, 0.0), Vector2(0.0, 30.0), Vector2(0.0, -30.0)]:
		t.check(not engine.is_lethal_at(place), "a parked truck strikes nobody at %s" % place)
	t.check(engine._obstruction != null, "and its body is still there")
	# Her first rig goes before the walks: placed with no frame run, the physics server still has
	# its body at the origin, under the truck, where it would stop a walker instead of the truck.
	player.free()
	for approach in [Vector2.DOWN, Vector2.UP, Vector2.RIGHT]:
		var from: Vector2 = engine.global_position - approach * 90.0
		var walker := _her(t, from, approach)
		var walked := _walk(walker, approach, 180.0)
		t.check(walked < 180.0 and _what_stops(walker, approach) == engine._obstruction,
				"walking %s into the parked truck, its own body stops her (%.0fpx)"
				% [approach, walked])
		var stood := walker.global_position.distance_to(engine.global_position)
		t.check(stood > Tuning.PLAYER_BODY_RADIUS, "and stopped outside it (%.0fpx)" % stood)
		t.check(not engine.is_lethal_at(walker.global_position),
				"and standing against it ends nothing")
		walker.free()
	engine.free()

## Parked, its field is priced from its centre as it was before it had a body
## (`VehicleSpec.field_from_its_centre`): along its street it reaches as far as abeam, so the 340px
## the fire's siting check closes about its kerb is the whole of it and a pass costs what
## `docs/COSTS.md` says.
func _test_parked_its_field_is_a_points(t) -> void:
	var def := _truck()
	t.check(def.vehicle.field_from_its_centre, "fire_truck's field is priced from its centre")
	var moving := def.outer_radius * Tuning.field_scale(Tuning.field_eccentricity(def.speed))
	t.check(is_equal_approx(def.field_reach(), moving),
			"and its field's reach is a moving point's, %.0fpx, not its body's (%.0fpx)"
			% [moving, def.field_reach()])
	var engine := _engine(t, PackedVector2Array([Vector2(-200.0, 0.0), Vector2(0.0, 0.0)]))
	var player := _her(t, Vector2(300.0, 300.0), Vector2.UP)
	for i in int(4.0 / STEP):
		_step(engine, player)
		if engine.is_parked:
			break
	t.check(engine.is_parked and engine.travel_velocity().is_zero_approx(),
			"the truck has parked and stands still")
	var same := true
	for d: float in [40.0, 100.0, 250.0, def.outer_radius - 5.0]:
		var along := engine.contribution_at(Vector2(d, 0.0), -1.0, Vector2.ZERO)
		var abeam := engine.contribution_at(Vector2(0.0, d), -1.0, Vector2.ZERO)
		same = same and absf(along - abeam) < 0.0001 and along > 0.0
	t.check(same, "along its street its field is what it is abeam, at every distance")
	t.check(engine.contribution_at(Vector2(def.outer_radius + 5.0, 0.0), -1.0, Vector2.ZERO) == 0.0,
			"and it ends at its 340px along the street, not past its body's end")
	player.free()
	engine.free()

## **The route-redundancy guarantee with it parked** (the **city** skill: a day leaves distinct
## routes from home to its calm areas, counted as a max flow, `StreetNetwork.route_count()`). The
## engine parks on the carriageway's near tile across from the fire
## (`EventManager.where_the_summoned_row_stops()`), its body a capsule along the street. On a real
## city, at every such kerb tried, every tile the body overlaps at all is blocked; the street it
## stands in counts as closed unless a way along it past the body is left inside its own corridor;
## and every calm area must keep as many distinct routes from home, up to two, as it had without
## it. The same check run with a body the street's whole width finds the street closed, which is
## what shows it can fail; the lattice leaves every calm area its routes past most single closed
## streets, so the count of routes lost is reported for it rather than required.
func _test_a_parked_body_closes_no_street(t) -> void:
	var map := CityGenerator.generate(4242)
	var kerbs := _kerbs(map)
	t.check(kerbs.size() >= 20, "enough kerbs were tried (%d)" % kerbs.size())
	var truck := _truck().shape
	var lost := _routes_lost(map, kerbs, truck)
	t.check(lost.x == 0 and lost.y == 0,
			"with the parked engine's tiles blocked, no street is closed (%d) and no calm area "
			% lost.x + "loses a route from home (%d)" % lost.y)
	var street := float(Tuning.STREET_WIDTH * Tuning.TILE_SIZE)
	var wide := _routes_lost(map, kerbs, GroundShape.segment(truck.half_length, street))
	t.check(wide.x > 0,
			"and a body the street's whole width closes the street it stands in (%d of %d kerbs; "
			% [wide.x, kerbs.size()] + "%d calm areas then lose a route)" % wide.y)

## The kerbs a summoned engine can park at on `map`, as `[park, along]`: the near carriageway tile
## across from every sidewalk tile beside a carriageway, sampled across the map, and the street's
## own axis there.
func _kerbs(map: CityMap) -> Array[Array]:
	var kerbs: Array[Array] = []
	var tile_count := map.size.x * map.size.y
	var step := maxi(1, tile_count / 160)
	for index in range(0, tile_count, step):
		var tile := Vector2i(index % map.size.x, index / map.size.x)
		var inward := map.pavement_inward(tile)
		if inward == Vector2i.ZERO:
			continue
		var park := EventManager.where_the_summoned_row_stops(map, map.tile_to_world(tile))
		if park == Vector2.INF or not Tile.is_road(map.tile_type_at_world(park)):
			continue
		kerbs.append([park, Vector2(absf(float(inward.y)), absf(float(inward.x)))])
	return kerbs

## With `body` parked at each of `kerbs`: how many times the street it stands in is closed, as
## `x`, and how many calm areas have fewer distinct routes from home than without it, as `y`.
func _routes_lost(map: CityMap, kerbs: Array[Array], body: GroundShape) -> Vector2i:
	var home := ClosurePlanner.home_street(map)
	var areas := ClosurePlanner.calm_areas(map)
	var open := map.blocked_segments()
	var before: Array[int] = []
	for area in areas:
		before.append(StreetNetwork.route_count(home, area.access, open, 2))
	var lost := Vector2i.ZERO
	for kerb: Array in kerbs:
		var park: Vector2 = kerb[0]
		var along: Vector2 = kerb[1]
		var blocked := _tiles_touched(body, park, along)
		var segment := StreetNetwork.segment_containing(map.world_to_tile(park))
		if segment == null or _passes(map, park, along, body, blocked):
			continue
		lost.x += 1
		var closed := open.duplicate()
		closed[segment.key()] = true
		for i in areas.size():
			if StreetNetwork.route_count(home, areas[i].access, closed, 2) < before[i]:
				lost.y += 1
	return lost

## Every tile `body`, parked at `at` along `along`, overlaps at all — not only the tiles whose
## centres it covers, which for a 26px body is one tile in six across the street.
func _tiles_touched(body: GroundShape, at: Vector2, along: Vector2) -> Dictionary:
	var size := float(Tuning.TILE_SIZE)
	var spine := Rect2(at - along * body.half_length, Vector2.ZERO).expand(at + along * body.half_length)
	var reach := ceili((body.half_length + body.radius) / size) + 1
	var centre := Vector2i(floori(at.x / size), floori(at.y / size))
	var touched := {}
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var tile := centre + Vector2i(dx, dy)
			var box := Rect2(Vector2(tile) * size, Vector2.ONE * size)
			var gap := Vector2(
					maxf(0.0, maxf(box.position.x - spine.end.x, spine.position.x - box.end.x)),
					maxf(0.0, maxf(box.position.y - spine.end.y, spine.position.y - box.end.y)))
			if gap.length() < body.radius:
				touched[tile] = true
	return touched

## Whether, with `blocked` closed, she can still walk along the street at `at` past `body`, inside
## the street's own corridor: from the walkable tiles across it a few tiles before the body to
## those a few tiles after it.
func _passes(map: CityMap, at: Vector2, along: Vector2, body: GroundShape,
		blocked: Dictionary) -> bool:
	var vertical := along.y > 0.5
	var tile := map.world_to_tile(at)
	var cross := tile.x if vertical else tile.y
	var first := cross - CityMap.corridor_offset(cross)
	var down := tile.y if vertical else tile.x
	var span := ceili((body.half_length + body.radius) / float(Tuning.TILE_SIZE)) + 2
	var make := func(a: int, c: int) -> Vector2i:
		return Vector2i(c, a) if vertical else Vector2i(a, c)
	var open := func(at_tile: Vector2i) -> bool:
		return map.in_bounds(at_tile) and map.is_walkable(at_tile) and not blocked.has(at_tile)
	var seen := {}
	var queue: Array[Vector2i] = []
	for c in range(first, first + Tuning.STREET_WIDTH):
		var start: Vector2i = make.call(down - span, c)
		if open.call(start):
			seen[start] = true
			queue.append(start)
	var head := 0
	while head < queue.size():
		var here := queue[head]
		head += 1
		var a := here.y if vertical else here.x
		if a == down + span:
			return true
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := here + step
			var a_next := next.y if vertical else next.x
			var c_next := next.x if vertical else next.y
			if a_next < down - span or a_next > down + span or c_next < first \
					or c_next >= first + Tuning.STREET_WIDTH:
				continue
			if seen.has(next) or not open.call(next):
				continue
			seen[next] = true
			queue.append(next)
	return false

# -------------------------------------------------------------------- loss ---

func _test_a_loss_to_it_names_its_own_cause(t) -> void:
	var line: String = Texts.HARD_FAIL_TEXT.get("fire_truck", "")
	t.check(line != "" and "fire engine" in line,
			"a loss to it reads its own line: '%s'" % line)
	t.check(line != Texts.HARD_FAIL_TEXT.get("police_patrol", "")
			and line != Texts.HARD_FAIL_TEXT.get("car_strike", ""),
			"and not the patrol car's or a crowd car's")
	t.check(LossCause.hard_fail_suffix("fire_truck", "fire_truck") == "fire-truck",
			"the run log and the page's counter name the cause 'fire-truck'")

# ----------------------------------------------------------------- picture ---

func _test_its_picture_stands_over_its_body(t) -> void:
	var engine := _engine(t, PackedVector2Array([Vector2.ZERO, Vector2(0.0, 600.0)]))
	var shape := _truck().shape
	t.check(is_equal_approx(engine.look._body_anchor("side").y,
			shape.half_length * absf(engine._solid_axis().y) + shape.radius
			+ float(EventPictures.FIRE_ENGINE_CANVAS_BOTTOM_MARGIN["side"])),
			"the side view's bottom lands on the body's southern edge")
	t.check(EventInstance._picture_drop_of(_truck()) > shape.reach(),
			"and the drawn box allows for the lowered picture")
	engine.free()
