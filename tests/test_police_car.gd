extends RefCounted
## The police car is a solid body she walks round in every patrol state, and it ends the day only
## in front of it while it drives.
##
## The player's words *(2026-10-07, azure-koala: "police cars don't have a hitbox"; 2026-10-10,
## leafy-puffin, offered "solid in every state, lethal only in front while driving": "yes to the
## police car hitbox")*. Her real `CharacterBody2D` rig is swept against a real `police_patrol`
## instance's body with the synchronous `move_and_collide()` sweep `tests/test_bollards.gd` uses (the
## runner cannot advance `move_and_slide()`'s own delta), and the car is stepped by hand, a frame
## at a time, told where she and her pram are the way `EventManager` tells it.

const STEP := 1.0 / 60.0
const WALK := 2.0

func run(t) -> void:
	_test_the_patrol_is_a_car_at_every_heat(t)
	_test_her_walk_into_a_standing_car_stops_at_its_side(t)
	_test_the_body_is_its_drawn_ground_contact_along_its_heading(t)
	_test_a_driving_car_beside_her_is_solid_and_not_lethal(t)
	_test_a_driving_car_ahead_of_her_is_solid_and_not_lethal(t)
	_test_in_front_of_a_driving_car_is_lethal_after_its_warning(t)
	_test_a_car_that_is_not_driving_strikes_nobody(t)
	_test_off_the_carriageway_it_stops_for_her_pram(t)
	_test_the_car_never_drives_into_her(t)
	_test_an_investigating_car_never_pins_her_against_a_wall(t)

# ------------------------------------------------------------------ the rig ---

func _patrol() -> EventDef:
	return EventCatalogue.by_id("police_patrol")

## A live car of `def` on `route`, in the tree so its body exists, stepped by hand.
func _car(t, def: EventDef, route: PackedVector2Array, map: CityMap = null) -> EventInstance:
	var car := EventInstance.new()
	car.setup(def, route[0], route, (route[1] - route[0]).normalized(), map)
	t.add_child(car)
	car.set_process(false)
	return car

## Her real rig, facing `facing`, with the pram body on her circumference as `_physics_process()`
## puts it.
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

## What `EventManager._tell_them_where_she_is()` tells every instance once a frame.
func _tell(car: EventInstance, player: Stroller) -> void:
	car.player_at = player.global_position
	car.pram_at = player.global_position + player.facing * Tuning.PLAYER_BODY_RADIUS

## One frame of the car, its body's transform pushed to the physics server at once rather than at
## the tree's next flush, which a synchronous sweep never reaches.
func _drive(car: EventInstance, player: Stroller) -> void:
	_tell(car, player)
	car._process(STEP)
	if car._obstruction:
		car._obstruction.force_update_transform()
		for child in car._obstruction.get_children():
			(child as Node2D).force_update_transform()

## How far she gets walking `heading` for up to `distance`, stopping at the first contact.
func _walk(player: Stroller, heading: Vector2, distance: float) -> float:
	var walked := 0.0
	while walked < distance:
		if player.move_and_collide(heading * WALK) != null:
			break
		walked += WALK
	return walked

func _gap(car: EventInstance) -> float:
	return car._gap_to_her(car.position, car._heading)

## A chasing car stops a frame's step short of her at most: the step that would have touched her is
## the one refused.
func _one_step(def: EventDef) -> float:
	return def.pursue_speed * STEP + EventInstance.DRIVEN_CLEARANCE

# ----------------------------------------------------------------- the row ---

func _test_the_patrol_is_a_car_at_every_heat(t) -> void:
	var cold := _patrol()
	t.check(cold.drives, "police_patrol drives: solid in every state, lethal in front while driving")
	t.check(cold.shape != null and cold.shape.kind == GroundShape.Kind.SEGMENT,
			"its body is a capsule laid along its heading")
	t.check(cold.obstructs_radius == 0.0 and not cold.hard_fail,
			"it closes no ground and is no hard fail: it kills only as a car does")
	for level in EventCatalogue.heat_levels():
		var hot := EventCatalogue.heated(cold, level)
		t.check(hot.drives and hot.shape == cold.shape and not hot.hard_fail,
				"heat %d's patrol is the same car" % level)
	var copy: EventDef = cold.duplicate()
	t.check(copy.drives, "a duplicated patrol (the return's, a poster's, the raid's) still drives")

# ------------------------------------------------------------- the reproduction ---

## **The reproduction**: walked at side-on, a standing patrol car stops her at its flank — with no
## body she walked straight through it and out of the far side.
func _test_her_walk_into_a_standing_car_stops_at_its_side(t) -> void:
	var car := _car(t, _patrol(), PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0)]))
	var shape := car.def.shape
	for approach in [Vector2.DOWN, Vector2.UP]:
		var start: Vector2 = -approach * 80.0
		var player := _her(t, start, approach)
		var walked := _walk(player, approach, 160.0)
		var stopped_at := player.global_position.distance_to(car.global_position)
		t.check(walked < 160.0, "walking %s into a standing patrol car, she is stopped (%.0fpx)"
				% [approach, walked])
		# Her pram leads, 14px out on her circumference with its own 8px: it is what touches.
		var touch := shape.radius + Tuning.PLAYER_BODY_RADIUS + Stroller.PRAM_BODY_RADIUS
		t.check(absf(stopped_at - touch) <= WALK + 0.5,
				"and stopped where its flank is: her centre %.1fpx from its middle, the touch %.1f"
				% [stopped_at, touch])
		player.free()
	car.free()

## The body is the car's drawn ground contact — the side view's 42px bumper to bumper and the end
## view's 24px flank to flank — and it turns with the car.
func _test_the_body_is_its_drawn_ground_contact_along_its_heading(t) -> void:
	var shape := _patrol().shape
	t.check(is_equal_approx(shape.reach() * 2.0, 42.0) and is_equal_approx(shape.radius * 2.0, 24.0),
			"the body is 42px long and 24px wide (%.0f by %.0f)" % [shape.reach() * 2.0,
			shape.radius * 2.0])
	var side := EventInstance._native_size(EventInstance.POLICE_CAR)
	t.check(shape.reach() * 2.0 <= side.x, "and no longer than the side view is drawn (%.0fpx)"
			% side.x)
	var route := PackedVector2Array([Vector2.ZERO, Vector2(0.0, 400.0)])
	var car := _car(t, _patrol(), route)
	var collision := car._obstruction.get_child(0) as CollisionShape2D
	var capsule := collision.shape as CapsuleShape2D
	t.check(capsule != null and is_equal_approx(capsule.radius, shape.radius)
			and is_equal_approx(capsule.height, shape.reach() * 2.0),
			"its collision is the same capsule its shadow is drawn from")
	var spine := Vector2.DOWN.rotated(collision.rotation)
	t.check(absf(spine.dot(Vector2.DOWN)) > 0.999,
			"driving south, the capsule lies north-south (%s)" % spine)
	car._heading = Vector2.RIGHT
	car._turn_the_body()
	spine = Vector2.DOWN.rotated(collision.rotation)
	t.check(absf(spine.dot(Vector2.RIGHT)) > 0.999, "and turned east, east-west (%s)" % spine)
	t.check(car._police_car_anchor("side").y == shape.radius,
			"its side picture's bottom lands on its body's southern edge, %.0fpx below the node"
			% shape.radius)
	car.free()

# ----------------------------------------------------------------- driving ---

## Beside a car driving past, she is never struck, the car never comes into her, and walking into
## its flank stops her against it.
func _test_a_driving_car_beside_her_is_solid_and_not_lethal(t) -> void:
	var car := _car(t, _patrol(), PackedVector2Array([Vector2(-200.0, 0.0), Vector2(400.0, 0.0)]))
	var player := _her(t, Vector2(0.0, 60.0), Vector2.UP)
	var struck := false
	var deepest := INF
	var pressed := false
	var stopped := false
	for i in int(6.0 / STEP):
		_drive(car, player)
		struck = struck or car.is_lethal_at(player.global_position)
		deepest = minf(deepest, _gap(car))
		# Level with its middle, she walks up into its flank and leans on it as it passes.
		if not pressed and absf(car.global_position.x) < 4.0:
			pressed = true
			stopped = _walk(player, Vector2.UP, 60.0) < 60.0
	t.check(pressed and stopped, "walking into a driving car's flank stops her against it")
	t.check(not struck, "a driving car never strikes her beside it")
	t.check(deepest >= -0.01, "and its body never came into her or her pram (closest %.2fpx)"
			% deepest)
	t.check(car.global_position.x > 100.0, "and it drove on past her (%.0f)" % car.global_position.x)
	player.free()
	car.free()

## Behind a car driving away from her, nothing strikes her; she follows it and walks into its rear,
## which stops her.
func _test_a_driving_car_ahead_of_her_is_solid_and_not_lethal(t) -> void:
	var car := _car(t, _patrol(), PackedVector2Array([Vector2(40.0, 0.0), Vector2(800.0, 0.0)]))
	var player := _her(t, Vector2.ZERO, Vector2.RIGHT)
	var struck := false
	var touched := false
	for i in int(3.0 / STEP):
		_drive(car, player)
		struck = struck or car.is_lethal_at(player.global_position)
		# She walks after it faster than it drives, so she catches its rear bumper.
		if player.move_and_collide(Vector2.RIGHT * Tuning.WALK_SPEED * STEP) != null:
			touched = true
	t.check(touched, "walking after a driving car, she catches up with its rear and is stopped")
	t.check(not struck, "and a car never strikes her behind it")
	player.free()
	car.free()

## In its lane in front of it, on the carriageway, a driving car warns her `CAR_HORN_TIME` of its
## travel before it strikes — longer than walking off the carriageway takes — and then strikes her
## before its body would ever stop against her.
func _test_in_front_of_a_driving_car_is_lethal_after_its_warning(t) -> void:
	for facing in [Vector2.LEFT, Vector2.UP, Vector2.RIGHT]:
		var car := _car(t, _patrol(), PackedVector2Array([Vector2(-300.0, 0.0), Vector2(600.0, 0.0)]))
		var player := _her(t, Vector2.ZERO, facing)
		var warned_at := -1.0
		var struck_at := -1.0
		var held := false
		for i in int(6.0 / STEP):
			_drive(car, player)
			var now := float(i) * STEP
			if warned_at < 0.0 and car.closes_on(player.global_position):
				warned_at = now
			held = held or car.is_held_by_her()
			if car.is_lethal_at(player.global_position):
				struck_at = now
				break
		t.check(struck_at > 0.0, "facing %s in its lane, a driving car strikes her" % facing)
		var warning := struck_at - warned_at
		t.check(warned_at >= 0.0 and warning >= Tuning.required_horn_time(),
				"facing %s, warned %.2fs before the strike, at least the %.2fs to walk off the road"
				% [facing, warning, Tuning.required_horn_time()])
		t.check(absf(warning - Tuning.CAR_HORN_TIME) <= 2.0 * STEP,
				"and the warning is the car's own horn time (%.2fs)" % warning)
		t.check(not held, "facing %s, the strike fires before the car would stop against her"
				% facing)
		t.check(car.will_be_lethal(player.global_position),
				"and the doubled caret was up over the car")
		player.free()
		car.free()

## A car that is not driving its route strikes nobody in front of it: leaving once it is over, and
## the investigating car coming over to her, which stops against her instead.
func _test_a_car_that_is_not_driving_strikes_nobody(t) -> void:
	var leaving := _car(t, _patrol(), PackedVector2Array([Vector2(-300.0, 0.0), Vector2(600.0, 0.0)]))
	var player := _her(t, Vector2(0.0, 0.0), Vector2.LEFT)
	leaving._be_done()
	t.check(leaving.is_leaving, "the car is leaving")
	var struck := false
	var deepest := INF
	for i in int(5.0 / STEP):
		_drive(leaving, player)
		struck = struck or leaving.is_lethal_at(player.global_position)
		deepest = minf(deepest, _gap(leaving))
	t.check(not struck, "a leaving car never strikes her in front of it")
	t.check(deepest >= -0.01 and leaving.is_held_by_her(),
			"it stops against her instead (closest %.2fpx)" % deepest)
	leaving.free()
	var hot := EventCatalogue.heated(_patrol(), Tuning.RESISTANCE_GOAL)
	var investigating := _car(t, hot, PackedVector2Array([Vector2(-140.0, 0.0), Vector2(600.0, 0.0)]))
	struck = false
	deepest = INF
	var noticed := false
	for i in int(4.0 / STEP):
		_drive(investigating, player)
		noticed = noticed or not investigating.is_waiting()
		struck = struck or investigating.is_lethal_at(player.global_position)
		deepest = minf(deepest, _gap(investigating))
	t.check(noticed, "the heated car noticed her and came over")
	t.check(not struck, "coming over to investigate, it never strikes her")
	t.check(deepest >= -0.01 and deepest < _one_step(hot),
			"it comes right up to her and stops against her (closest %.2fpx)" % deepest)
	investigating.free()
	player.free()

## Off the carriageway nothing strikes her: a pram poking over the kerb into its lane is a car that
## stops for her. On the carriageway beside the same kerb, it strikes.
func _test_off_the_carriageway_it_stops_for_her_pram(t) -> void:
	var map: CityMap = CityGenerator.generate(4242)
	var kerb := _a_kerb(map)
	t.check(kerb.size() == 3, "found a carriageway lane beside a sidewalk")
	if kerb.size() != 3:
		return
	var lane: Vector2 = kerb[0]
	var outward: Vector2 = kerb[1]
	var along: Vector2 = kerb[2]
	var edge := lane + outward * (Tuning.TILE_SIZE * 0.5)
	var route := PackedVector2Array([lane - along * 200.0, lane + along * 200.0])
	# Her centre a few pixels onto the sidewalk, her pram reaching into the lane toward the car.
	var on_the_sidewalk := edge + outward * 4.0
	var car := _car(t, _patrol(), route, map)
	var player := _her(t, on_the_sidewalk, -outward)
	var struck := false
	var deepest := INF
	for i in int(6.0 / STEP):
		_drive(car, player)
		struck = struck or car.is_lethal_at(player.global_position)
		deepest = minf(deepest, _gap(car))
	t.check(map.tile_at(map.world_to_tile(on_the_sidewalk)) == GameEnums.TileType.SIDEWALK,
			"she stands on the sidewalk")
	t.check(not struck, "with her on the sidewalk, a car never strikes her")
	t.check(car.is_held_by_her() and deepest >= -0.01,
			"it stops for her pram in its lane instead (closest %.2fpx)" % deepest)
	car.free()
	var in_the_road := edge - outward * 4.0
	player.global_position = in_the_road
	car = _car(t, _patrol(), route, map)
	struck = false
	for i in int(6.0 / STEP):
		_drive(car, player)
		if car.is_lethal_at(player.global_position):
			struck = true
			break
	t.check(struck, "a step into the road at the same kerb, it strikes her")
	car.free()
	player.free()

## `[lane centre, outward toward the sidewalk, along the street]` of the first east-west carriageway
## lane on `map` with a sidewalk tile on its north side, or empty.
func _a_kerb(map: CityMap) -> Array:
	for y in range(1, map.size.y - 1):
		for x in range(8, map.size.x - 8):
			var tile := Vector2i(x, y)
			if map.tile_at(tile) != GameEnums.TileType.ROAD:
				continue
			if map.tile_at(tile + Vector2i.UP) != GameEnums.TileType.SIDEWALK:
				continue
			var run := true
			for dx in range(-3, 4):
				run = run and map.tile_at(tile + Vector2i(dx, 0)) == GameEnums.TileType.ROAD \
						and map.tile_at(tile + Vector2i(dx, -1)) == GameEnums.TileType.SIDEWALK
			if run:
				return [map.tile_to_world(tile), Vector2.UP, Vector2.RIGHT]
	return []

# ------------------------------------------------------------------ pinning ---

## **She is never inside it.** Stood anywhere round a car's route — beside it, behind it, in front
## of it, at a corner it turns — and facing any way, the car's body never overlaps her or her pram
## on any frame before it strikes her, so a car can stop against her but never push into her.
func _test_the_car_never_drives_into_her(t) -> void:
	var route := PackedVector2Array([Vector2(-160.0, 0.0), Vector2(0.0, 0.0), Vector2(0.0, 160.0)])
	var worst := INF
	var held := 0
	var cases := 0
	for x in range(-48, 49, 12):
		for y in range(-48, 49, 12):
			var at := Vector2(float(x), float(y))
			if at.length() < 30.0:
				continue
			for facing in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
				cases += 1
				var car := _car(t, _patrol(), route)
				var player := _her(t, at, facing)
				for i in int(5.0 / STEP):
					_drive(car, player)
					if car.is_lethal_at(player.global_position):
						break
					worst = minf(worst, _gap(car))
				if car.is_held_by_her():
					held += 1
				player.free()
				car.free()
	t.check(worst >= -0.01, "over %d stands round a turning car, its body never came into her "
			% cases + "(closest %.2fpx)" % worst)
	t.check(held > 0, "and some of them it stopped for (%d)" % held)

## The investigating car comes over to her backed against a building and stops against her, and
## she can always walk away from it — along the wall, the way the car is not.
func _test_an_investigating_car_never_pins_her_against_a_wall(t) -> void:
	var map: CityMap = CityGenerator.generate(4242)
	var wall := _a_wall(map)
	t.check(wall.size() == 2, "found a sidewalk against a building")
	if wall.size() != 2:
		return
	var against: Vector2 = wall[0]
	var inward: Vector2 = wall[1]
	# Her back to the building, her pram toward the street.
	var at := against + inward * (Tuning.TILE_SIZE * 0.5 - Tuning.PLAYER_BODY_RADIUS - 1.0)
	var hot := EventCatalogue.heated(_patrol(), Tuning.RESISTANCE_GOAL)
	# Driving along the street toward her, so it notices her outside its stand-off and comes over.
	var lane := at - inward * 96.0
	var route := PackedVector2Array([lane + inward.orthogonal() * 260.0,
			lane - inward.orthogonal() * 400.0])
	var car := _car(t, hot, route, map)
	var player := _her(t, at, -inward)
	var deepest := INF
	for i in int(6.0 / STEP):
		_drive(car, player)
		deepest = minf(deepest, _gap(car))
	t.check(not car.is_waiting(), "the heated car noticed her and came over")
	t.check(deepest >= -0.01 and deepest < _one_step(hot),
			"it came up to her and stopped against her, never into her (closest %.2fpx)" % deepest)
	var freest := 0.0
	for way in [inward.orthogonal(), -inward.orthogonal()]:
		player.global_position = at
		var walked := 0.0
		while walked < 64.0:
			var next: Vector2 = player.global_position + way * WALK
			if not map.is_walkable(map.world_to_tile(next)):
				break
			if player.move_and_collide(way * WALK) != null:
				break
			walked += WALK
		freest = maxf(freest, walked)
	t.check(freest >= 64.0, "she walks away along the wall (%.0fpx)" % freest)
	player.free()
	car.free()

## `[centre of a sidewalk tile with a building on its far side, the way into the building]` on
## `map`, along an east-west street, or empty.
func _a_wall(map: CityMap) -> Array:
	for y in range(1, map.size.y - 1):
		for x in range(8, map.size.x - 8):
			var tile := Vector2i(x, y)
			if map.tile_at(tile) != GameEnums.TileType.SIDEWALK:
				continue
			if map.tile_at(tile + Vector2i.UP) != GameEnums.TileType.BUILDING:
				continue
			var run := true
			for dx in range(-3, 4):
				run = run and map.tile_at(tile + Vector2i(dx, 0)) == GameEnums.TileType.SIDEWALK
			if run and map.tile_at(tile + Vector2i(0, 2)) == GameEnums.TileType.ROAD:
				return [map.tile_to_world(tile), Vector2.UP]
	return []
