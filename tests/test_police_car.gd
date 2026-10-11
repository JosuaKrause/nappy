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
	_test_an_investigating_car_never_leaves_the_carriageway(t)
	_test_the_raids_car_never_reverses_onto_her(t)
	_test_a_car_leaving_turns_away_and_never_vanishes_beside_her(t)
	_test_it_gives_way_at_a_zebra_she_waits_at(t)
	_test_it_stops_at_a_red_light(t)
	_test_its_caret_stands_over_its_picture(t)
	_test_a_far_zebra_holds_it_out_of_the_box(t)
	_test_the_log_names_the_patrol_for_its_mark(t)

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

## `car` as one already driving its route with her ahead of it, the state a car closing on her is
## in. A car is created standing (`EventInstance.setup()`) and would go on standing for her on its
## first frame, so a rig that asks about the warning over a driving car puts it in that state.
func _already_driving(car: EventInstance) -> void:
	car._standing = false

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
	t.check(car._body_anchor("side").y == shape.radius,
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
			held = held or car.is_standing()
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
## the investigating car, which stops where it notices her and stands for the man it lets out.
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
	t.check(deepest >= -0.01 and leaving.is_standing(),
			"it stops against her instead (closest %.2fpx)" % deepest)
	leaving.free()
	var hot := EventCatalogue.heated(_patrol(), Tuning.RESISTANCE_GOAL)
	var start := Vector2(-140.0, 0.0)
	var investigating := _car(t, hot, PackedVector2Array([start, Vector2(600.0, 0.0)]))
	struck = false
	var noticed := false
	var furthest := 0.0
	for i in int(4.0 / STEP):
		_drive(investigating, player)
		noticed = noticed or not investigating.is_waiting()
		struck = struck or investigating.is_lethal_at(player.global_position)
		furthest = maxf(furthest, investigating.global_position.distance_to(start))
	t.check(noticed, "the heated car noticed her, in its lane %.0fpx ahead" % start.length())
	t.check(not struck, "stopped to investigate, it never strikes her")
	t.check(furthest < 0.01, "it stopped where it noticed her and came no nearer (%.2fpx)" % furthest)
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
	t.check(car.is_standing() and deepest >= -0.01,
			"it stops for her pram in its lane instead (closest %.2fpx)" % deepest)
	# Standing for her, it stays harmless however she then steps into the road in front of it.
	var nose := car.global_position + along * (car.def.shape.reach() + Tuning.PLAYER_BODY_RADIUS
			+ 3.0)
	player.global_position = Vector2(nose.x, lane.y)
	player.facing = -along
	for i in int(3.0 / STEP):
		_drive(car, player)
		struck = struck or car.is_lethal_at(player.global_position)
	t.check(not struck and car.is_standing(),
			"a car standing for her never strikes her when she steps in front of it")
	# And it drives on once she is out of its way.
	player.global_position = on_the_sidewalk + outward * float(Tuning.TILE_SIZE)
	var stood_at := car.global_position
	for i in int(1.0 / STEP):
		_drive(car, player)
	t.check(not car.is_standing() and car.global_position.distance_to(stood_at) > 30.0,
			"and it drives on once she is out of its way")
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
				if car.is_standing():
					held += 1
				player.free()
				car.free()
	t.check(worst >= -0.01, "over %d stands round a turning car, its body never came into her "
			% cases + "(closest %.2fpx)" % worst)
	t.check(held > 0, "and some of them it stopped for (%d)" % held)

## **The investigating car stays on its route, here a lane.** *(merry-stork: "an investigating
## police car should not leave the street. it should stop if close to her".)* Driving along the
## street at her where she stands backed against a building, it notices her, stops in its lane —
## on the road every frame — and comes no nearer, and she walks away along the wall. It goes where
## its route goes and no further; a route drawn across a sidewalk would take it there.
func _test_an_investigating_car_never_leaves_the_carriageway(t) -> void:
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
	var lane := at - inward * 96.0
	# Along the lane toward her from the street's far side, ending just past her: the street the
	# sidewalk is found on runs out a few tiles the other way.
	var route := PackedVector2Array([lane - inward.orthogonal() * 260.0,
			lane + inward.orthogonal() * 60.0])
	var car := _car(t, hot, route, map)
	var player := _her(t, at, -inward)
	t.check(Tile.is_road(map.tile_type_at_world(route[0]))
			and Tile.is_road(map.tile_type_at_world(route[1])), "its route is on the carriageway")
	var off_the_road := 0
	var stopped_at := Vector2.INF
	var moved_after := 0.0
	for i in int(6.0 / STEP):
		_drive(car, player)
		if not Tile.is_road(map.tile_type_at_world(car.global_position)):
			off_the_road += 1
		if stopped_at == Vector2.INF and not car.is_waiting():
			stopped_at = car.global_position
		elif stopped_at != Vector2.INF:
			moved_after = maxf(moved_after, car.global_position.distance_to(stopped_at))
	t.check(stopped_at != Vector2.INF, "the heated car noticed her")
	t.check(off_the_road == 0, "and it was on the carriageway every frame (%d off it)" % off_the_road)
	t.check(stopped_at != Vector2.INF and stopped_at.distance_to(at) <= hot.pursues_within + 0.5,
			"it stopped once close to her (%.0fpx)" % stopped_at.distance_to(at))
	t.check(moved_after < 0.01, "and never came over to her (%.2fpx)" % moved_after)
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

# ------------------------------------------------------------- reversing ---

## **The raid's pacing car never reverses onto her.** The raid's patrol at her door paces a beat,
## turning round at each end. She steps into its lane behind it as it nears the end of its beat, at
## the distances a review measured a strike after 0.02 to 1.37s of warning: a turn that would put
## her in front of it within its warning is refused, and it stands for her instead. Far enough
## behind, it turns and comes back at her with its whole warning.
func _test_the_raids_car_never_reverses_onto_her(t) -> void:
	var raid: EventDef = _patrol().duplicate()
	raid.shape = _patrol().shape
	raid.paces = true
	var beat := PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0)])
	for behind in [41.0, 49.0, 61.0, 101.0, 141.0]:
		var car := _car(t, raid, beat)
		var player := _her(t, Vector2(0.0, 80.0), Vector2.UP)
		# Drive it to just short of the end of its beat, then step in behind it.
		while car.global_position.x < 396.0:
			_drive(car, player)
		player.global_position = Vector2(car.global_position.x - behind, 0.0)
		var struck := false
		var deepest := INF
		for i in int(6.0 / STEP):
			_drive(car, player)
			struck = struck or car.is_lethal_at(player.global_position)
			deepest = minf(deepest, _gap(car))
		t.check(not struck, "stepped in %.0fpx behind the raid's car at the end of its beat, it never "
				% behind + "strikes her")
		t.check(car.is_standing() and car._heading.is_equal_approx(Vector2.RIGHT),
				"%.0fpx behind: it stands, still facing away from her, rather than turning onto her"
				% behind)
		t.check(deepest >= -0.01, "%.0fpx behind: and its body never came into her" % behind)
		# Out of its lane, it turns and paces on.
		player.global_position = Vector2(player.global_position.x, 80.0)
		for i in int(1.0 / STEP):
			_drive(car, player)
		t.check(not car.is_standing() and car._heading.is_equal_approx(Vector2.LEFT),
				"%.0fpx behind: once she is out of its lane it turns and paces back" % behind)
		player.free()
		car.free()
	# Further behind than its warning reaches, it turns at once and drives back at her, warning her
	# its whole horn time before the strike.
	var car := _car(t, raid, beat)
	var player := _her(t, Vector2(0.0, 80.0), Vector2.RIGHT)
	while car.global_position.x < 396.0:
		_drive(car, player)
	player.global_position = Vector2(car.global_position.x - 260.0, 0.0)
	var warned_at := -1.0
	var struck_at := -1.0
	for i in int(8.0 / STEP):
		_drive(car, player)
		if warned_at < 0.0 and car.closes_on(player.global_position):
			warned_at = float(i) * STEP
		if car.is_lethal_at(player.global_position):
			struck_at = float(i) * STEP
			break
	t.check(struck_at > 0.0 and struck_at - warned_at >= Tuning.required_horn_time(),
			"260px behind, it turns, comes back and strikes her only after %.2fs of warning"
			% (struck_at - warned_at))
	player.free()
	car.free()

# --------------------------------------------------------------- leaving ---

## **The investigating car drives on along its route once its man is back in, and never turns round
## in her view.** It stopped in its lane with her standing in it ahead; once the man it let out has
## given up and walked back in, it goes on standing while she is in its way — never pulling away
## into her, never striking her — and once she has stepped out of its lane it drives on the way it
## was going, past her, facing the same way every frame, and is gone only once out of her sight.
func _test_a_car_leaving_turns_away_and_never_vanishes_beside_her(t) -> void:
	var hot := EventCatalogue.heated(_patrol(), Tuning.RESISTANCE_GOAL)
	var car := _car(t, hot, PackedVector2Array([Vector2(-200.0, 0.0), Vector2(600.0, 0.0)]))
	var player := _her(t, Vector2.ZERO, Vector2.LEFT)
	var officer: EventInstance = null
	var stopped_at := Vector2.INF
	var struck := false
	var stood_for_her := 0.0
	var crept := 0.0
	var turned := false
	var vanished_near := false
	var aside := false
	var elapsed := 0.0
	while elapsed < 30.0:
		_drive(car, player)
		elapsed += STEP
		struck = struck or car.is_lethal_at(player.global_position)
		turned = turned or car.facing_now().dot(Vector2.RIGHT) < 0.999
		if car.officers_owed() > 0:
			officer = EventInstance.new()
			officer.setup(EventCatalogue.out_of_the_car(6), car.door_for_its_officer(
					EventCatalogue.out_of_the_car(6)))
			t.add_child(officer)
			officer.set_process(false)
			car.let_out(officer)
			stopped_at = car.global_position
			officer.give_up_the_chase()
		if officer and not officer.is_finished:
			officer.player_at = player.global_position
			officer._process(STEP)
		elif officer and not aside:
			# He is back in. She stays in its lane for two seconds, then steps out of it.
			stood_for_her += STEP
			if stood_for_her >= 2.0:
				player.global_position = Vector2(0.0, -60.0)
				aside = true
			else:
				crept = maxf(crept, car.global_position.distance_to(stopped_at))
		if car.is_finished:
			vanished_near = car.global_position.distance_to(player.global_position) \
					<= Tuning.OUT_OF_SIGHT
			break
	t.check(stopped_at != Vector2.INF
			and stopped_at.distance_to(Vector2.ZERO) <= hot.pursues_within + 0.5,
			"the investigating car stopped close to her (%.0fpx)" % stopped_at.length())
	t.check(stood_for_her >= 2.0 and crept < 0.01,
			"with her in its lane ahead once he was back in, it stood rather than pulling away into "
			+ "her (%.2fpx)" % crept)
	t.check(not struck, "it never struck her, standing or driving on")
	t.check(not turned, "it never turned round: it drove on the way it was going")
	t.check(car.is_finished and not vanished_near,
			"and it was gone only once out of her sight, never beside her (finished %s, at %.0fpx)"
			% [car.is_finished, car.global_position.distance_to(player.global_position)])
	if officer:
		officer.free()
	player.free()
	car.free()

# ------------------------------------------------------------- giving way ---

## On a street whose traffic gives way, it stops short of the zebra she is on, never warns her and
## never strikes her there, and drives over once she has crossed.
func _test_it_gives_way_at_a_zebra_she_waits_at(t) -> void:
	var map: CityMap = CityGenerator.generate(4242)
	var zebra := _a_zebra(map)
	t.check(zebra != Vector2.INF, "found a zebra on an east-west carriageway off the main road")
	if zebra == Vector2.INF:
		return
	var route := PackedVector2Array([zebra - Vector2(160.0, 0.0), zebra + Vector2(400.0, 0.0)])
	var car := _car(t, _patrol(), route, map)
	var player := _her(t, zebra, Vector2.UP)
	var struck := false
	var warned := false
	for i in int(5.0 / STEP):
		_drive(car, player)
		struck = struck or car.is_lethal_at(player.global_position)
		warned = warned or car.closes_on(player.global_position)
	var nose := car.global_position.x + car.def.shape.reach()
	var paint := floorf(zebra.x / Tuning.TILE_SIZE) * Tuning.TILE_SIZE
	t.check(not struck and not warned, "on the zebra she is never warned or struck")
	t.check(car.is_standing() and nose <= paint,
			"it stands short of the paint (nose %.0f, paint %.0f)" % [nose, paint])
	player.global_position = zebra + Vector2(0.0, -float(Tuning.TILE_SIZE) * 5.0)
	var stood_at := car.global_position
	for i in int(2.0 / STEP):
		_drive(car, player)
	t.check(car.global_position.x > stood_at.x + 60.0, "and drives over once she has crossed")
	player.free()
	car.free()

## The centre of the first `CROSSING` tile on an east-west carriageway lane, at a junction off the
## main road, on `map`, or `INF`.
func _a_zebra(map: CityMap) -> Vector2:
	for y in range(1, map.size.y - 1):
		if CityMap.corridor_offset(y) < 0 or not CityMap.is_road_offset(CityMap.corridor_offset(y)):
			continue
		for x in range(12, map.size.x - 16):
			var tile := Vector2i(x, y)
			if map.tile_at(tile) != GameEnums.TileType.CROSSING:
				continue
			if map.tile_at(tile - Vector2i(5, 0)) != GameEnums.TileType.ROAD:
				continue
			if map.is_main_road(true, CityMap.junction_index(x + 2)):
				continue
			return map.tile_to_world(tile)
	return Vector2.INF

## Driving east at the main road, it stops short of the junction on a red light and goes on green.
func _test_it_stops_at_a_red_light(t) -> void:
	var map: CityMap = CityGenerator.generate(4242)
	var signals := TrafficSignals.new(map)
	var lane_y := -1
	for y in range(1, map.size.y - 1):
		if CityMap.corridor_offset(y) == Tuning.SIDEWALK_WIDTH \
				and map.tile_at(Vector2i(map.main_road * CityMap.period() - 4, y)) \
						== GameEnums.TileType.ROAD:
			lane_y = y
			break
	t.check(lane_y >= 0, "found an east-west lane coming to the main road")
	if lane_y < 0:
		return
	var box_x := float(map.main_road * CityMap.period() * Tuning.TILE_SIZE)
	var lane := float(lane_y) * Tuning.TILE_SIZE + Tuning.TILE_SIZE * 0.5
	var junction := Vector2i(map.main_road, CityMap.junction_index(lane_y))
	# The main road's green, which is the side street's red.
	signals.elapsed = 0.0
	while signals.phase_of(junction) != TrafficSignals.Phase.MAIN_GREEN:
		signals.elapsed += 0.25
	t.check(not signals.green_for(junction, false), "the east-west arm is red")
	var route := PackedVector2Array([Vector2(box_x - 260.0, lane), Vector2(box_x + 400.0, lane)])
	var car := _car(t, _patrol(), route, map)
	car.signals = signals
	for i in int(5.0 / STEP):
		car._process(STEP)
	var nose := car.global_position.x + car.def.shape.reach()
	t.check(car.is_standing() and nose <= box_x - Tuning.CAR_STOP_LINE_SETBACK + 0.5,
			"on red it stands at the stop line (nose %.0f, box %.0f)" % [nose, box_x])
	while not signals.green_for(junction, false):
		signals.elapsed += 0.25
	for i in int(2.0 / STEP):
		car._process(STEP)
	t.check(car.global_position.x > box_x, "and on green it drives through (%.0f)"
			% car.global_position.x)
	car.free()

# ----------------------------------------------------------------- the caret ---

## The caret over a police car stands as high above its picture as it does over anything else: it
## is lowered with the picture.
func _test_its_caret_stands_over_its_picture(t) -> void:
	var car := _car(t, _patrol(), PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0)]))
	var player := _her(t, Vector2(200.0, 0.0), Vector2.LEFT)
	_tell(car, player)
	_already_driving(car)
	var rect := car.mark_rect()
	var anchor := car._body_anchor("side")
	t.check(rect.has_area(), "the car in front of her is marked")
	var above := anchor.y - (rect.position.y + rect.size.y)
	# What any other row's caret clears its picture's bottom (its node) by, at the same swell.
	var swell := car.mark_swell()
	var width := EventInstance.MARK_WIDTH * (0.55 + 0.45 * swell)
	var usual := EventInstance.MARK_HEIGHT + 10.0 * swell - width * 0.5 - 1.0
	t.check(absf(above - usual) < 0.01,
			"its caret clears the picture's bottom by %.1fpx, as on any row (%.1fpx)" % [above, usual])
	player.free()
	car.free()

# ------------------------------------------------------------------ the box ---

## **Nothing enters a box it cannot leave.** With her at the zebra on the far side of a junction,
## the car holds at the box's entry line rather than standing inside the box short of that zebra —
## at an ordinary junction, and at the main road on the side street's green, where the main road's
## traffic would otherwise drive through it; driving east and driving west; with her on either tile
## of that zebra, in its lane or out beside it on the sidewalk (0, 64 and 96px out), which is
## further than the zebra's own 200px sight circle reaches from the box's entry line.
func _test_a_far_zebra_holds_it_out_of_the_box(t) -> void:
	var map: CityMap = CityGenerator.generate(4242)
	var lane_y := -1
	for y in range(1, map.size.y - 1):
		if CityMap.corridor_offset(y) == Tuning.SIDEWALK_WIDTH \
				and map.tile_at(Vector2i(map.main_road * CityMap.period() - 4, y)) \
						== GameEnums.TileType.ROAD:
			lane_y = y
			break
	t.check(lane_y >= 0, "found an east-west lane coming to the main road")
	if lane_y < 0:
		return
	var period := CityMap.period()
	var zebras := func(c: int) -> bool:
		for x in [c * period, c * period + 1, c * period + Tuning.STREET_WIDTH - 2,
				c * period + Tuning.STREET_WIDTH - 1]:
			if map.tile_at(Vector2i(x, lane_y)) != GameEnums.TileType.CROSSING:
				return false
		return map.tile_at(Vector2i(c * period - 4, lane_y)) == GameEnums.TileType.ROAD \
				and map.tile_at(Vector2i(c * period + Tuning.STREET_WIDTH + 4, lane_y)) \
						== GameEnums.TileType.ROAD
	var ordinary := -1
	for c in range(1, map.main_road):
		if zebras.call(c):
			ordinary = c
			break
	t.check(ordinary >= 0, "found an ordinary junction on that lane with zebras either side")
	var lane := float(lane_y) * Tuning.TILE_SIZE + Tuning.TILE_SIZE * 0.5
	var signals := TrafficSignals.new(map)
	var green := Vector2i(map.main_road, CityMap.junction_index(lane_y))
	signals.elapsed = 0.0
	while not signals.green_for(green, false):
		signals.elapsed += 0.25
	var tile := float(Tuning.TILE_SIZE)
	var worst := -INF
	var cases := 0
	for c in [ordinary, map.main_road]:
		if c < 0:
			continue
		var what := "the main road" if c == map.main_road else "an ordinary junction"
		var low: float = float(c * period) * tile
		for direction in [1.0, -1.0]:
			var near: float = low if direction > 0.0 else low + float(Tuning.STREET_WIDTH) * tile
			var first: int = c * period + (Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH
					if direction > 0.0 else 0)
			var start: Vector2 = Vector2(near - direction * 220.0, lane)
			var route := PackedVector2Array([start, start + Vector2(direction * 820.0, 0.0)])
			for k in Tuning.SIDEWALK_WIDTH:
				for out in [0.0, 64.0, 96.0]:
					var her: Vector2 = Vector2((float(first + k) + 0.5) * tile, lane - out)
					var car := _car(t, _patrol(), route, map)
					car.signals = signals
					var player := _her(t, her, Vector2.UP)
					var furthest := -INF
					for i in int(6.0 / STEP):
						_drive(car, player)
						var nose: float = (car.global_position.x - near) * direction \
								+ car.def.shape.reach()
						furthest = maxf(furthest, nose)
					cases += 1
					worst = maxf(worst, furthest)
					t.check(furthest <= -Tuning.CAR_STOP_LINE_SETBACK + 0.5 and car.is_standing(),
							("at %s, driving %s, her at the far zebra's tile %d, %.0fpx out: it holds "
							% [what, "east" if direction > 0.0 else "west", k + 1, out])
							+ "at the box's entry line (nose %.1fpx from the box)" % furthest)
					player.free()
					car.free()
	t.check(cases == 24, "every case ran (%d of 24; the furthest nose %.1fpx from the box)"
			% [cases, worst])

# ------------------------------------------------------------------ the log ---

## The run log names the patrol for the mark it raises over her, not a crowd car's horn.
func _test_the_log_names_the_patrol_for_its_mark(t) -> void:
	var car := _car(t, _patrol(), PackedVector2Array([Vector2.ZERO, Vector2(800.0, 0.0)]))
	var player := _her(t, Vector2(150.0, 0.0), Vector2.LEFT)
	_tell(car, player)
	_already_driving(car)
	var source := GDScript.new()
	source.source_code = "extends Node\nvar list: Array[EventInstance] = []\n" \
			+ "func instances() -> Array[EventInstance]:\n\treturn list\n"
	source.reload()
	var events: Node = source.new()
	events.list.append(car)
	var observer := TelemetryObserver.new()
	observer._events = events
	observer._player = player
	t.check(car.closes_on(player.global_position), "the car is closing on her in its lane")
	t.check(observer._what_raised_the_mark().begins_with("police_patrol "),
			"the log names the patrol for the mark (%s)" % observer._what_raised_the_mark())
	player.global_position = Vector2(150.0, 80.0)
	_tell(car, player)
	t.check(not observer._what_raised_the_mark().begins_with("police_patrol"),
			"and out of its lane it names nothing of it (%s)" % observer._what_raised_the_mark())
	observer.free()
	events.free()
	player.free()
	car.free()
