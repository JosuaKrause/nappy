extends RefCounted
## The police car is a solid body she walks round in every patrol state, and it ends the day only
## in front of it while it drives.
##
## The player's words *(2026-10-07, azure-koala: "police cars don't have a hitbox"; 2026-10-10,
## leafy-puffin, offered "solid in every state, lethal only in front while driving": "yes to the
## police car hitbox")*. Her real `CharacterBody2D` rig is swept against a real `police_patrol`
## instance's body with the explicit `move_and_collide()` sweep `tests/test_bollards.gd` uses (one
## displacement per step, not `move_and_slide()`'s own), and the car is stepped by hand, a frame
## at a time, told where she and her pram are the way `EventManager` tells it.

const RecordingLog := preload("res://tests/recording_log.gd")
const STEP := 1.0 / 60.0
const WALK := 2.0

func run(t: TestRunner) -> void:
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
	_test_a_far_zebra_holds_it_out_of_the_box(t)
	await _test_the_log_names_the_patrol_for_its_mark(t)

# ------------------------------------------------------------------ the rig ---

func _patrol() -> EventDef:
	return EventCatalogue.by_id("police_patrol")

## A live car of `def` on `route`, in the tree so its body exists, stepped by hand.
func _car(t: TestRunner, def: EventDef, route: PackedVector2Array, map: CityMap,
		where: WhereSheIs) -> EventInstance:
	var car := EventInstance.new()
	car.setup(def, route[0], route, (route[1] - route[0]).normalized(), map, null, where)
	t.add_child(car)
	car.set_process(false)
	return car

## `car` as one already driving its route, the state a car closing on her is in. A car is created
## standing (`EventInstance.setup()`) and drives off on its first step when nobody has been told
## where she is, since there is nobody in its way, so a rig that asks about the warning over a
## driving car takes that step before it tells the car about her.
func _already_driving(car: EventInstance) -> void:
	car.step(STEP)

## Her real rig, facing `facing`, with the pram body on her circumference as `_physics_process()`
## puts it.
func _her(t: TestRunner, at: Vector2, facing: Vector2) -> Stroller:
	var packed: PackedScene = load("res://scenes/player/stroller.tscn")
	var player: Stroller = packed.instantiate()
	t.add_child(player)
	player.set_physics_process(false)
	player.global_position = at
	player.facing = facing
	var pram := player.get_node("PramCollisionShape2D") as CollisionShape2D
	pram.position = facing * Tuning.PLAYER_BODY_RADIUS
	return player

## What `EventManager` tells the one object every instance hears once a frame: where she is and
## where her pram is.
func _tell(where: WhereSheIs, player: Stroller) -> void:
	where.tell(player.global_position,
			player.global_position + player.facing * Tuning.PLAYER_BODY_RADIUS)

## One frame of the car, its body's transform (the car and everything under it) pushed to the physics
## server at once rather than at the tree's next flush, which a synchronous sweep never reaches.
func _drive(car: EventInstance, where: WhereSheIs, player: Stroller) -> void:
	_tell(where, player)
	car.step(STEP)
	car.propagate_call("force_update_transform", [], true)

## How far she gets walking `heading` for up to `distance`, stopping at the first contact.
func _walk(player: Stroller, heading: Vector2, distance: float) -> float:
	var walked := 0.0
	while walked < distance:
		if player.move_and_collide(heading * WALK) != null:
			break
		walked += WALK
	return walked

## Whether the car holds still for one more step with her where she is: it is held when the step it
## takes leaves it where it was, which is all a car standing for her shows.
func _stands(car: EventInstance, where: WhereSheIs, player: Stroller) -> bool:
	var was_at := car.global_position
	_drive(car, where, player)
	return car.global_position.is_equal_approx(was_at)

func _gap(car: EventInstance) -> float:
	return car.car.gap_to_her(car.position, car.facing_now())

# ------------------------------------------------------------- the reproduction ---

## **The reproduction**: walked at side-on, a standing patrol car stops her at its flank — with no
## body she walked straight through it and out of the far side.
func _test_her_walk_into_a_standing_car_stops_at_its_side(t: TestRunner) -> void:
	var car_where := WhereSheIs.nowhere()
	var car := _car(t, _patrol(), PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0)]), null,
			car_where)
	var shape := car.def.shape
	for approach: Vector2 in [Vector2.DOWN, Vector2.UP]:
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

## The collision shape of the solid body the car carries, found by type among its children.
func _body_shape(car: EventInstance) -> CollisionShape2D:
	for child in car.get_children():
		if child is StaticBody2D:
			return child.get_child(0) as CollisionShape2D
	return null

## The body is the car's drawn ground contact — the side view's 42px bumper to bumper and the end
## view's 24px flank to flank — and it turns with the car.
func _test_the_body_is_its_drawn_ground_contact_along_its_heading(t: TestRunner) -> void:
	var shape := _patrol().shape
	t.check(is_equal_approx(shape.reach() * 2.0, 42.0) and is_equal_approx(shape.radius * 2.0, 24.0),
			"the body is 42px long and 24px wide (%.0f by %.0f)" % [shape.reach() * 2.0,
			shape.radius * 2.0])
	var side := EventPictures.native_size(EventPictures.POLICE_CAR)
	t.check(shape.reach() * 2.0 <= side.x, "and no longer than the side view is drawn (%.0fpx)"
			% side.x)
	var route := PackedVector2Array([Vector2.ZERO, Vector2(0.0, 80.0), Vector2(400.0, 80.0)])
	var car_where := WhereSheIs.nowhere()
	var car := _car(t, _patrol(), route, null, car_where)
	var collision := _body_shape(car)
	var capsule := collision.shape as CapsuleShape2D
	t.check(capsule != null and is_equal_approx(capsule.radius, shape.radius)
			and is_equal_approx(capsule.height, shape.reach() * 2.0),
			"its collision is the same capsule its shadow is drawn from")
	var spine := Vector2.DOWN.rotated(collision.rotation)
	t.check(absf(spine.dot(Vector2.DOWN)) > 0.999,
			"driving south, the capsule lies north-south (%s)" % spine)
	# Round the corner of its route, with nobody told where she is: the car turns east on its own.
	var frames := 0
	while not car.facing_now().is_equal_approx(Vector2.RIGHT) and frames < 600:
		car.step(STEP)
		frames += 1
	t.check(car.facing_now().is_equal_approx(Vector2.RIGHT), "the car turns east at the corner of its route")
	spine = Vector2.DOWN.rotated(collision.rotation)
	t.check(absf(spine.dot(Vector2.RIGHT)) > 0.999, "and turned east, east-west (%s)" % spine)
	t.check(car.look.body_anchor("side").y == shape.radius,
			"its side picture's bottom lands on its body's southern edge, %.0fpx below the node"
			% shape.radius)
	car.free()

# ----------------------------------------------------------------- driving ---

## Beside a car driving past, she is never struck, the car never comes into her, and walking into
## its flank stops her against it.
func _test_a_driving_car_beside_her_is_solid_and_not_lethal(t: TestRunner) -> void:
	var car_where := WhereSheIs.nowhere()
	var car := _car(t, _patrol(),
			PackedVector2Array([Vector2(-200.0, 0.0), Vector2(400.0, 0.0)]), null, car_where)
	var player := _her(t, Vector2(0.0, 60.0), Vector2.UP)
	var struck := false
	var deepest := INF
	var pressed := false
	var stopped := false
	for i in int(6.0 / STEP):
		_drive(car, car_where, player)
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
func _test_a_driving_car_ahead_of_her_is_solid_and_not_lethal(t: TestRunner) -> void:
	var car_where := WhereSheIs.nowhere()
	var car := _car(t, _patrol(), PackedVector2Array([Vector2(40.0, 0.0), Vector2(800.0, 0.0)]),
			null, car_where)
	var player := _her(t, Vector2.ZERO, Vector2.RIGHT)
	var struck := false
	var touched := false
	for i in int(3.0 / STEP):
		_drive(car, car_where, player)
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
func _test_in_front_of_a_driving_car_is_lethal_after_its_warning(t: TestRunner) -> void:
	for facing: Vector2 in [Vector2.LEFT, Vector2.UP, Vector2.RIGHT]:
		var car_where := WhereSheIs.nowhere()
		var route := PackedVector2Array([Vector2(-300.0, 0.0), Vector2(600.0, 0.0)])
		var car := _car(t, _patrol(), route, null, car_where)
		var player := _her(t, Vector2.ZERO, facing)
		var warned_at := -1.0
		var struck_at := -1.0
		var held := false
		for i in int(6.0 / STEP):
			var was_at := car.global_position
			_drive(car, car_where, player)
			var now := float(i) * STEP
			if warned_at < 0.0 and car.car.closes_on(player.global_position):
				warned_at = now
			held = held or car.global_position.is_equal_approx(was_at)
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
		t.check(car.excitement.will_be_lethal(player.global_position),
				"and the doubled caret was up over the car")
		player.free()
		car.free()

## A car that is not driving its route strikes nobody in front of it: leaving once it is over, and
## the investigating car, which stops where it notices her and stands for the man it lets out.
func _test_a_car_that_is_not_driving_strikes_nobody(t: TestRunner) -> void:
	# Its route runs out short of her, and it leaves the way it was going: at her.
	var leaving_where := WhereSheIs.nowhere()
	var leaving_route := PackedVector2Array([Vector2(-300.0, 0.0), Vector2(-100.0, 0.0)])
	var leaving := _car(t, _patrol(), leaving_route, null, leaving_where)
	var player := _her(t, Vector2(0.0, 0.0), Vector2.LEFT)
	var frames := 0
	while not leaving.is_leaving and frames < int(10.0 / STEP):
		leaving.step(STEP)
		frames += 1
	t.check(leaving.is_leaving, "the car is leaving once its route has run out")
	var struck := false
	var deepest := INF
	for i in int(5.0 / STEP):
		_drive(leaving, leaving_where, player)
		struck = struck or leaving.is_lethal_at(player.global_position)
		deepest = minf(deepest, _gap(leaving))
	t.check(not struck, "a leaving car never strikes her in front of it")
	t.check(deepest >= -0.01 and _stands(leaving, leaving_where, player),
			"it stops against her instead (closest %.2fpx)" % deepest)
	leaving.free()
	var hot := EventCatalogue.heated(_patrol(), Tuning.RESISTANCE_GOAL)
	var start := Vector2(-140.0, 0.0)
	var investigating_where := WhereSheIs.nowhere()
	var investigating := _car(t, hot, PackedVector2Array([start, Vector2(600.0, 0.0)]), null,
			investigating_where)
	struck = false
	var noticed := false
	var furthest := 0.0
	for i in int(4.0 / STEP):
		_drive(investigating, investigating_where, player)
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
func _test_off_the_carriageway_it_stops_for_her_pram(t: TestRunner) -> void:
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
	var car_where := WhereSheIs.nowhere()
	var car := _car(t, _patrol(), route, map, car_where)
	var player := _her(t, on_the_sidewalk, -outward)
	var struck := false
	var deepest := INF
	for i in int(6.0 / STEP):
		_drive(car, car_where, player)
		struck = struck or car.is_lethal_at(player.global_position)
		deepest = minf(deepest, _gap(car))
	t.check(map.tile_at(map.world_to_tile(on_the_sidewalk)) == GameEnums.TileType.SIDEWALK,
			"she stands on the sidewalk")
	t.check(not struck, "with her on the sidewalk, a car never strikes her")
	t.check(_stands(car, car_where, player) and deepest >= -0.01,
			"it stops for her pram in its lane instead (closest %.2fpx)" % deepest)
	# Standing for her, it stays harmless however she then steps into the road in front of it.
	var nose := car.global_position + along * (car.def.shape.reach() + Tuning.PLAYER_BODY_RADIUS
			+ 3.0)
	player.global_position = Vector2(nose.x, lane.y)
	player.facing = -along
	for i in int(3.0 / STEP):
		_drive(car, car_where, player)
		struck = struck or car.is_lethal_at(player.global_position)
	t.check(not struck and _stands(car, car_where, player),
			"a car standing for her never strikes her when she steps in front of it")
	# And it drives on once she is out of its way.
	player.global_position = on_the_sidewalk + outward * float(Tuning.TILE_SIZE)
	var stood_at := car.global_position
	for i in int(1.0 / STEP):
		_drive(car, car_where, player)
	t.check(car.global_position.distance_to(stood_at) > 30.0,
			"and it drives on once she is out of its way")
	car.free()
	var in_the_road := edge - outward * 4.0
	player.global_position = in_the_road
	car = _car(t, _patrol(), route, map, car_where)
	struck = false
	for i in int(6.0 / STEP):
		_drive(car, car_where, player)
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
func _test_the_car_never_drives_into_her(t: TestRunner) -> void:
	var route := PackedVector2Array([Vector2(-160.0, 0.0), Vector2(0.0, 0.0), Vector2(0.0, 160.0)])
	var worst := INF
	var held := 0
	var cases := 0
	for x in range(-48, 49, 12):
		for y in range(-48, 49, 12):
			var at := Vector2(float(x), float(y))
			if at.length() < 30.0:
				continue
			for facing: Vector2 in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
				cases += 1
				var car_where := WhereSheIs.nowhere()
				var car := _car(t, _patrol(), route, null, car_where)
				var player := _her(t, at, facing)
				for i in int(5.0 / STEP):
					_drive(car, car_where, player)
					if car.is_lethal_at(player.global_position):
						break
					worst = minf(worst, _gap(car))
				if _stands(car, car_where, player):
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
func _test_an_investigating_car_never_leaves_the_carriageway(t: TestRunner) -> void:
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
	var car_where := WhereSheIs.nowhere()
	var car := _car(t, hot, route, map, car_where)
	var player := _her(t, at, -inward)
	t.check(Tile.is_road(map.tile_type_at_world(route[0]))
			and Tile.is_road(map.tile_type_at_world(route[1])), "its route is on the carriageway")
	var off_the_road := 0
	var stopped_at := Vector2.INF
	var moved_after := 0.0
	for i in int(6.0 / STEP):
		_drive(car, car_where, player)
		if not Tile.is_road(map.tile_type_at_world(car.global_position)):
			off_the_road += 1
		if stopped_at == Vector2.INF and not car.is_waiting():
			stopped_at = car.global_position
		elif stopped_at != Vector2.INF:
			moved_after = maxf(moved_after, car.global_position.distance_to(stopped_at))
	t.check(stopped_at != Vector2.INF, "the heated car noticed her")
	t.check(off_the_road == 0, "and it was on the carriageway every frame (%d off it)" % off_the_road)
	t.check(stopped_at != Vector2.INF and stopped_at.distance_to(at) <= hot.notice_within() + 0.5,
			"it stopped once close to her (%.0fpx)" % stopped_at.distance_to(at))
	t.check(moved_after < 0.01, "and never came over to her (%.2fpx)" % moved_after)
	var freest := 0.0
	for way: Vector2 in [inward.orthogonal(), -inward.orthogonal()]:
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
func _test_the_raids_car_never_reverses_onto_her(t: TestRunner) -> void:
	var raid: EventDef = _patrol().duplicate()
	raid.shape = _patrol().shape
	raid.paces = true
	var beat := PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0)])
	for behind: float in [41.0, 49.0, 61.0, 101.0, 141.0]:
		var car_where := WhereSheIs.nowhere()
		var car := _car(t, raid, beat, null, car_where)
		var player := _her(t, Vector2(0.0, 80.0), Vector2.UP)
		# Drive it to just short of the end of its beat, then step in behind it.
		while car.global_position.x < 396.0:
			_drive(car, car_where, player)
		player.global_position = Vector2(car.global_position.x - behind, 0.0)
		var struck := false
		var deepest := INF
		for i in int(6.0 / STEP):
			_drive(car, car_where, player)
			struck = struck or car.is_lethal_at(player.global_position)
			deepest = minf(deepest, _gap(car))
		t.check(not struck, "stepped in %.0fpx behind the raid's car at the end of its beat, it never "
				% behind + "strikes her")
		t.check(_stands(car, car_where, player)
				and car.facing_now().is_equal_approx(Vector2.RIGHT),
				"%.0fpx behind: it stands, still facing away from her, rather than turning onto her"
				% behind)
		t.check(deepest >= -0.01, "%.0fpx behind: and its body never came into her" % behind)
		# Out of its lane, it turns and paces on.
		player.global_position = Vector2(player.global_position.x, 80.0)
		for i in int(1.0 / STEP):
			_drive(car, car_where, player)
		t.check(not _stands(car, car_where, player)
				and car.facing_now().is_equal_approx(Vector2.LEFT),
				"%.0fpx behind: once she is out of its lane it turns and paces back" % behind)
		player.free()
		car.free()
	# Further behind than its warning reaches, it turns at once and drives back at her, warning her
	# its whole horn time before the strike.
	var car_where := WhereSheIs.nowhere()
	var car := _car(t, raid, beat, null, car_where)
	var player := _her(t, Vector2(0.0, 80.0), Vector2.RIGHT)
	while car.global_position.x < 396.0:
		_drive(car, car_where, player)
	player.global_position = Vector2(car.global_position.x - 260.0, 0.0)
	var warned_at := -1.0
	var struck_at := -1.0
	for i in int(8.0 / STEP):
		_drive(car, car_where, player)
		if warned_at < 0.0 and car.car.closes_on(player.global_position):
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
func _test_a_car_leaving_turns_away_and_never_vanishes_beside_her(t: TestRunner) -> void:
	var hot := EventCatalogue.heated(_patrol(), Tuning.RESISTANCE_GOAL)
	var car_where := WhereSheIs.nowhere()
	var car := _car(t, hot, PackedVector2Array([Vector2(-200.0, 0.0), Vector2(600.0, 0.0)]),
			null, car_where)
	var player := _her(t, Vector2.ZERO, Vector2.LEFT)
	var officer: EventInstance = null
	var officer_where := WhereSheIs.nowhere()
	var stopped_at := Vector2.INF
	var struck := false
	var stood_for_her := 0.0
	var crept := 0.0
	var turned := false
	var vanished_near := false
	var aside := false
	var elapsed := 0.0
	while elapsed < 30.0:
		_drive(car, car_where, player)
		elapsed += STEP
		struck = struck or car.is_lethal_at(player.global_position)
		turned = turned or car.facing_now().dot(Vector2.RIGHT) < 0.999
		if car.officers_owed() > 0:
			officer = EventInstance.new()
			officer.setup(EventCatalogue.out_of_the_car(DaySpec.for_day(6)), car.door_for_its_officer(
					EventCatalogue.out_of_the_car(DaySpec.for_day(6))), PackedVector2Array(),
					Vector2.RIGHT, null, null, officer_where)
			t.add_child(officer)
			officer.set_process(false)
			car.let_out(officer)
			stopped_at = car.global_position
			officer.give_up_the_chase()
		if officer and not officer.is_finished:
			officer_where.tell(player.global_position)
			officer.step(STEP)
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
			and stopped_at.distance_to(Vector2.ZERO) <= hot.notice_within() + 0.5,
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
func _test_it_gives_way_at_a_zebra_she_waits_at(t: TestRunner) -> void:
	var map: CityMap = CityGenerator.generate(4242)
	var zebra := _a_zebra(map)
	t.check(zebra != Vector2.INF, "found a zebra on an east-west carriageway off the main road")
	if zebra == Vector2.INF:
		return
	var route := PackedVector2Array([zebra - Vector2(160.0, 0.0), zebra + Vector2(400.0, 0.0)])
	var car_where := WhereSheIs.nowhere()
	var car := _car(t, _patrol(), route, map, car_where)
	var player := _her(t, zebra, Vector2.UP)
	var struck := false
	var warned := false
	for i in int(5.0 / STEP):
		_drive(car, car_where, player)
		struck = struck or car.is_lethal_at(player.global_position)
		warned = warned or car.car.closes_on(player.global_position)
	var nose := car.global_position.x + car.def.shape.reach()
	var paint := floorf(zebra.x / Tuning.TILE_SIZE) * Tuning.TILE_SIZE
	t.check(not struck and not warned, "on the zebra she is never warned or struck")
	t.check(_stands(car, car_where, player) and nose <= paint,
			"it stands short of the paint (nose %.0f, paint %.0f)" % [nose, paint])
	player.global_position = zebra + Vector2(0.0, -float(Tuning.TILE_SIZE) * 5.0)
	var stood_at := car.global_position
	for i in int(2.0 / STEP):
		_drive(car, car_where, player)
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
func _test_it_stops_at_a_red_light(t: TestRunner) -> void:
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
	while not signals.green_for(junction, true):
		signals.elapsed += 0.25
	t.check(not signals.green_for(junction, false), "the east-west arm is red")
	var route := PackedVector2Array([Vector2(box_x - 260.0, lane), Vector2(box_x + 400.0, lane)])
	var car_where := WhereSheIs.nowhere()
	var car := _car(t, _patrol(), route, map, car_where)
	car.signals = signals
	var was_at := car.global_position
	for i in int(5.0 / STEP):
		was_at = car.global_position
		car.step(STEP)
	var nose := car.global_position.x + car.def.shape.reach()
	t.check(car.global_position.is_equal_approx(was_at) and nose <= box_x - Tuning.CAR_STOP_LINE_SETBACK + 0.5,
			"on red it stands at the stop line (nose %.0f, box %.0f)" % [nose, box_x])
	while not signals.green_for(junction, false):
		signals.elapsed += 0.25
	for i in int(2.0 / STEP):
		car.step(STEP)
	t.check(car.global_position.x > box_x, "and on green it drives through (%.0f)"
			% car.global_position.x)
	car.free()

# ------------------------------------------------------------------ the box ---

## **Nothing enters a box it cannot leave.** With her at the zebra on the far side of a junction,
## the car holds at the box's entry line rather than standing inside the box short of that zebra —
## at an ordinary junction, and at the main road on the side street's green, where the main road's
## traffic would otherwise drive through it; driving east and driving west; with her on either tile
## of that zebra, in its lane or out beside it on the sidewalk (0, 64 and 96px out), which is
## further than the zebra's own 200px sight circle reaches from the box's entry line.
func _test_a_far_zebra_holds_it_out_of_the_box(t: TestRunner) -> void:
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
		for x: int in [c * period, c * period + 1, c * period + Tuning.STREET_WIDTH - 2,
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
	for c: int in [ordinary, map.main_road]:
		if c < 0:
			continue
		var what := "the main road" if c == map.main_road else "an ordinary junction"
		var low: float = float(c * period) * tile
		for direction: float in [1.0, -1.0]:
			var near: float = low if direction > 0.0 else low + float(Tuning.STREET_WIDTH) * tile
			var first: int = c * period + (Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH
					if direction > 0.0 else 0)
			var start: Vector2 = Vector2(near - direction * 220.0, lane)
			var route := PackedVector2Array([start, start + Vector2(direction * 820.0, 0.0)])
			for k in Tuning.SIDEWALK_WIDTH:
				for out: float in [0.0, 64.0, 96.0]:
					var her: Vector2 = Vector2((float(first + k) + 0.5) * tile, lane - out)
					var car_where := WhereSheIs.nowhere()
					var car := _car(t, _patrol(), route, map, car_where)
					car.signals = signals
					var player := _her(t, her, Vector2.UP)
					var furthest := -INF
					for i in int(6.0 / STEP):
						_drive(car, car_where, player)
						var nose: float = (car.global_position.x - near) * direction \
								+ car.def.shape.reach()
						furthest = maxf(furthest, nose)
					cases += 1
					worst = maxf(worst, furthest)
					t.check(furthest <= -Tuning.CAR_STOP_LINE_SETBACK + 0.5
							and _stands(car, car_where, player),
							("at %s, driving %s, her at the far zebra's tile %d, %.0fpx out: it holds "
							% [what, "east" if direction > 0.0 else "west", k + 1, out])
							+ "at the box's entry line (nose %.1fpx from the box)" % furthest)
					player.free()
					car.free()
	t.check(cases == 24, "every case ran (%d of 24; the furthest nose %.1fpx from the box)"
			% [cases, worst])

# ------------------------------------------------------------------ the log ---

## The run log names the patrol for the mark it raises over her, not a crowd car's horn. The
## observer is handed what `main` hands it (the run, the city, her, the baby, the day's clock); the
## patrol drives a carriageway lane of a city in a run of its own, the mark is raised over her head
## as the game raises it (`Stroller.warn()`), and real frames let the observer write the cue.
func _test_the_log_names_the_patrol_for_its_mark(t: TestRunner) -> void:
	var city := RunCity.with_own_run(preload("res://scenes/world/city.tscn"), 4242)
	t.add_child(city)
	city.build(CityGenerator.generate(4242))
	var kerb := _a_kerb(city.map)
	t.check(kerb.size() == 3, "found a carriageway lane beside a sidewalk")
	if kerb.size() != 3:
		city.free()
		return
	var lane: Vector2 = kerb[0]
	var outward: Vector2 = kerb[1]
	var along: Vector2 = kerb[2]
	var car := city.events.spawn_extra(_patrol(), lane - along * 150.0,
			PackedVector2Array([lane - along * 150.0, lane + along * 650.0]))
	_already_driving(car)
	var player := _her(t, lane, -along)
	_tell(city.events.world.where_she_is(), player)
	var baby := Baby.new()
	baby.use_bus(EventBus)
	var clock := DayController.new()
	var run_log := RecordingLog.new()
	var observer := TelemetryObserver.new(run_log)
	observer.setup(city.run, clock, null, false)
	observer.watch(city.map, city.events, player, baby, city.map, city.streets(),
			city.crowd.sources, "")
	t.add_child(observer)
	clock.start(180.0)
	t.check(car.car.closes_on(player.global_position), "the car is closing on her in its lane")
	run_log.begin_run(1, false)
	run_log.begin_day(1, 1, 1, 1, 180.0)
	await t.get_tree().process_frame
	var in_lane := await _the_mark_cue(t, player, run_log)
	t.check(in_lane.contains("| police_patrol "),
			"the log names the patrol for the mark (%s)" % in_lane)
	player.global_position = lane + outward * float(Tuning.TILE_SIZE * 2)
	_tell(city.events.world.where_she_is(), player)
	var out_of_lane := await _the_mark_cue(t, player, run_log)
	t.check(out_of_lane != "" and not out_of_lane.contains("| police_patrol"),
			"and out of its lane it names nothing of it (%s)" % out_of_lane)
	observer.free()
	run_log.free()
	clock.free()
	baby.free()
	player.free()
	city.free()

## Raises the mark over her head, lets a frame pass for the observer to see it go up, takes it down
## and lets another pass for it to write the cue in `run_log`; returns the cue line the log gained,
## or "".
func _the_mark_cue(t: TestRunner, player: Stroller, run_log: RecordingLog) -> String:
	var before := run_log.lines.size()
	player.warn(Stroller.Alert.SOON, 5.0)
	await t.get_tree().process_frame
	player.stand_down(&"")
	await t.get_tree().process_frame
	var lines: Array = run_log.lines
	for i in range(before, lines.size()):
		if String(lines[i]).contains("the mark over her head"):
			return String(lines[i])
	return ""
