extends RefCounted
## The fire truck is a solid body, lethal only in front of it while it drives and harmless once it
## has parked at the fire.
##
## The player's words *(2026-10-04, calm-kestrel, inbox #558: "the fire truck has no collision at
## all -- I can walk through it without it being lethal"; asked what touching it should do: "Lethal
## driving, solid parked")*. The truck is built the way the patrol car is (sunny-finch,
## `EventDef.drives`): lethal only in front of it, with a car's warning, while it drives its route.
## Her real `CharacterBody2D` rig is swept against a real `fire_truck` instance's body with the
## synchronous `move_and_collide()` sweep `tests/test_police_car.gd` uses, and the truck is stepped
## by hand, a frame at a time, told where she and her pram are the way `EventManager` tells it.

const STEP := 1.0 / 60.0
const WALK := 2.0
const MAIN_SCRIPT: GDScript = preload("res://src/main.gd")

func run(t) -> void:
	_test_the_row_is_a_car_with_the_engines_body(t)
	_test_the_body_is_solid_while_it_drives_and_lethal_only_ahead(t)
	_test_in_front_of_it_the_warning_comes_first(t)
	_test_where_it_is_created_she_is_warned_in_full(t)
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
	engine._process(STEP)
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

# ----------------------------------------------------------------- the row ---

func _test_the_row_is_a_car_with_the_engines_body(t) -> void:
	var def := _truck()
	t.check(def.drives, "fire_truck drives: solid in every state, lethal in front while driving")
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
			stopped = _walk(player, Vector2.UP, 70.0) < 70.0
	t.check(pressed and stopped, "walking into a driving truck's flank stops her against it")
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
			if warned_at < 0.0 and engine.closes_on(player.global_position):
				warned_at = now
			held = held or engine.is_standing()
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
## from each of the four sides, with her standing in its lane facing it. On a north-south street
## that place is nearer her than its warning reaches (the view is 180px to either side of her
## that way, against 1.7s of its 190px/s), so a truck driving from its first frame strikes her
## well inside the time it takes to walk off the road. A car that drives is created standing
## (`_drive()`'s car that has stood): it waits there while she is in its lane within its warning,
## so every strike comes after the full warning, and drives on to the kerb once she is out of it.
func _test_where_it_is_created_she_is_warned_in_full(t) -> void:
	var def := _truck()
	var warning_reach := (Tuning.PATROL_STRIKE_LEAD + Tuning.CAR_HORN_TIME) * def.speed \
			+ def.shape.reach()
	var nearer_than_its_warning := 0
	var sides := {Vector2.DOWN: "the north", Vector2.UP: "the south", Vector2.RIGHT: "the west",
			Vector2.LEFT: "the east"}
	for travel: Vector2 in sides:
		var side: String = sides[travel]
		var her := Vector2.ZERO
		var stop := her + travel * 240.0
		var place := PendingWarning.on_its_route(def, her, stop, travel, 4000.0,
				VisibleView.around(her))
		t.check(place != Vector2.INF, "from %s, there is a place out of sight to create it" % side)
		if place == Vector2.INF:
			continue
		if place.distance_to(her) < warning_reach:
			nearer_than_its_warning += 1
		var engine := _engine(t, PackedVector2Array([place, stop]))
		var player := _her(t, her, -travel)
		var warned_at := -1.0
		var struck_at := -1.0
		for i in int(4.0 / STEP):
			_step(engine, player)
			var now := float(i) * STEP
			if warned_at < 0.0 and engine.closes_on(player.global_position):
				warned_at = now
			if engine.is_lethal_at(player.global_position):
				struck_at = now
				break
		t.check(struck_at < 0.0 or (warned_at >= 0.0
				and struck_at - warned_at >= Tuning.required_horn_time()),
				"from %s, created %.0fpx from her: %s" % [side, place.distance_to(her),
				"no strike while she stands in its lane" if struck_at < 0.0
				else "struck %.2fs after the mark, at least the %.2fs to walk off the road"
				% [struck_at - warned_at, Tuning.required_horn_time()]])
		# Out of its lane, it drives on and reaches the kerb.
		player.global_position = her + Vector2(travel.y, -travel.x) * 80.0
		for i in int(5.0 / STEP):
			_step(engine, player)
			if engine.is_parked:
				break
		t.check(engine.is_parked, "from %s, once she is out of its lane it drives on to the kerb"
				% side)
		player.free()
		engine.free()
	t.check(nearer_than_its_warning >= 2,
			"the north-south places are nearer her than its warning reaches (%d of 4)"
			% nearer_than_its_warning)

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
	t.check(engine.is_driving(), "and it was driving")
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
	t.check(not engine.is_driving() and not engine.will_be_lethal(Vector2(40.0, 0.0)),
			"and a parked truck is not driving")
	for place in [Vector2(40.0, 0.0), Vector2(-40.0, 0.0), Vector2(0.0, 30.0), Vector2(0.0, -30.0)]:
		t.check(not engine.is_lethal_at(place), "a parked truck strikes nobody at %s" % place)
	t.check(engine._obstruction != null, "and its body is still there")
	for approach in [Vector2.DOWN, Vector2.UP, Vector2.RIGHT]:
		var from: Vector2 = engine.global_position - approach * 90.0
		var walker := _her(t, from, approach)
		var walked := _walk(walker, approach, 180.0)
		t.check(walked < 180.0, "walking %s into the parked truck, she is stopped (%.0fpx)"
				% [approach, walked])
		var stood := walker.global_position.distance_to(engine.global_position)
		t.check(stood > Tuning.PLAYER_BODY_RADIUS, "and stopped outside it (%.0fpx)" % stood)
		t.check(not engine.is_lethal_at(walker.global_position),
				"and standing against it ends nothing")
		walker.free()
	player.free()
	engine.free()

## Parked, its field is priced from its centre as it was before it had a body
## (`EventDef.field_from_its_centre`): along its street it reaches as far as abeam, so the 340px
## the fire's siting check closes about its kerb is the whole of it and a pass costs what
## `docs/COSTS.md` says.
func _test_parked_its_field_is_a_points(t) -> void:
	var def := _truck()
	t.check(def.field_from_its_centre, "fire_truck's field is priced from its centre")
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

## The route-redundancy guarantee with it parked. The engine parks on the carriageway's near tile
## across from the fire (`EventManager.where_the_summoned_row_stops()`), its body a capsule along
## the street: its tiles are blocked on a real city, for every such kerb on it, and what could be
## reached before is still reached, bar the tiles under the body. The scheduler's own check, the
## day's guarantee, closes the engine's whole 340px field and the body lies inside it.
func _test_a_parked_body_closes_no_street(t) -> void:
	var def := _truck()
	var map := CityGenerator.generate(4242)
	var home := map.home_rect.position
	var baseline := map.walk_field(home)
	var checked := 0
	var cut := 0
	var outside_field := 0
	var tile_count := map.size.x * map.size.y
	var step := maxi(1, tile_count / 160)
	for index in range(0, tile_count, step):
		var tile := Vector2i(index % map.size.x, index / map.size.x)
		var inward := map.pavement_inward(tile)
		if inward == Vector2i.ZERO:
			continue
		var fire_side := map.tile_to_world(tile)
		var park := EventManager.where_the_summoned_row_stops(map, fire_side)
		if park == Vector2.INF or not Tile.is_road(map.tile_type_at_world(park)):
			continue
		var along := Vector2(inward.y, inward.x)
		var blocked := {}
		var reach := ceili((def.shape.reach() + def.shape.radius) / float(Tuning.TILE_SIZE)) + 1
		var centre := map.world_to_tile(park)
		for dy in range(-reach, reach + 1):
			for dx in range(-reach, reach + 1):
				var at := centre + Vector2i(dx, dy)
				var local := (map.tile_to_world(at) - park)
				var across := absf(local.dot(Vector2(-along.y, along.x)))
				var down := absf(local.dot(along))
				var spine := maxf(down - def.shape.half_length, 0.0)
				if Vector2(spine, across).length() <= def.shape.radius:
					blocked[at] = true
					if local.length() > def.outer_radius:
						outside_field += 1
		checked += 1
		var after := map.walk_field(home, blocked)
		for y in map.size.y:
			for x in map.size.x:
				var at := Vector2i(x, y)
				if blocked.has(at):
					continue
				if baseline[y * map.size.x + x] >= 0 and after[y * map.size.x + x] < 0:
					cut += 1
	t.check(checked >= 20, "enough kerbs were tried (%d)" % checked)
	t.check(cut == 0, "no tile outside the parked body is cut off from the home by it (%d cut)"
			% cut)
	t.check(outside_field == 0, "and the body lies inside the field the day already closes")

# -------------------------------------------------------------------- loss ---

func _test_a_loss_to_it_names_its_own_cause(t) -> void:
	var line: String = DayController._HARD_FAIL_TEXT.get("fire_truck", "")
	t.check(line != "" and "fire engine" in line,
			"a loss to it reads its own line: '%s'" % line)
	t.check(line != DayController._HARD_FAIL_TEXT.get("police_patrol", "")
			and line != DayController._HARD_FAIL_TEXT.get("car_strike", ""),
			"and not the patrol car's or a crowd car's")
	t.check(MAIN_SCRIPT._hard_fail_cause_suffix("fire_truck", "fire_truck") == "fire-truck",
			"the run log and the page's counter name the cause 'fire-truck'")

# ----------------------------------------------------------------- picture ---

func _test_its_picture_stands_over_its_body(t) -> void:
	var engine := _engine(t, PackedVector2Array([Vector2.ZERO, Vector2(0.0, 600.0)]))
	var shape := _truck().shape
	t.check(is_equal_approx(engine._body_anchor("side").y,
			shape.half_length * absf(engine._solid_axis().y) + shape.radius
			+ float(EventInstance.FIRE_ENGINE_CANVAS_BOTTOM_MARGIN["side"])),
			"the side view's bottom lands on the body's southern edge")
	t.check(EventInstance._picture_drop_of(_truck()) > shape.reach(),
			"and the drawn box allows for the lowered picture")
	engine.free()
