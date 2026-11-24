extends RefCounted
## The fire truck is a solid body, lethal only in front of it while it drives and harmless once it
## has parked at the fire.
##
## The player's words *(2026-10-04, calm-kestrel, inbox #558: "the fire truck has no collision at
## all -- I can walk through it without it being lethal"; asked what touching it should do: "Lethal
## driving, solid parked")*. The truck is built the way the patrol car is (sunny-finch,
## `EventDef.drives()`): lethal only in front of it, with a car's warning, while it drives its
## route. Her real `CharacterBody2D` rig is swept against a real `fire_truck` instance's body
## with the synchronous `move_and_collide()` sweep `tests/test_police_car.gd` uses, and the
## truck is stepped by hand, a frame at a time, told where she and her pram are the way
## `EventManager` tells it.

const RecordingEventDrawer := preload("res://tests/recording_event_drawer.gd")

const STEP := 1.0 / 60.0
const WALK := 2.0

func run(t: TestRunner) -> void:
	_test_the_row_is_a_car_with_the_engines_body(t)
	_test_the_body_is_solid_while_it_drives_and_lethal_only_ahead(t)
	_test_in_front_of_it_the_warning_comes_first(t)
	_test_where_it_is_created_she_is_warned_in_full(t)
	_test_nothing_reaches_past_its_kerb(t)
	_test_behind_and_beside_it_nothing_strikes(t)
	_test_parked_it_is_solid_and_harmless(t)
	_test_parked_its_field_is_a_points(t)
	await _test_its_picture_stands_over_its_body(t)

# ------------------------------------------------------------------ the rig ---

func _truck() -> EventDef:
	return EventCatalogue.by_id("fire_truck")

## A live truck on `route`, its warning spent (`spawn_warned()` hands it over with the telegraph
## used up), in the tree so its body exists, stepped by hand, drawn through `drawer` when one is
## handed in.
func _engine(t: TestRunner, route: PackedVector2Array, where: WhereSheIs,
		drawer: EventDrawer = null) -> EventInstance:
	var def := _truck()
	var engine := EventInstance.new()
	var surroundings := EventSurroundings.new().hearing(where)
	if drawer != null:
		surroundings.drawing_through(drawer)
	engine.setup(def, route[0], route, (route[1] - route[0]).normalized(), surroundings)
	engine.restore(EventSave.new(def.telegraphs_for(), 0.0))
	t.add_child(engine)
	engine.set_process(false)
	return engine

func _her(t: TestRunner, at: Vector2, facing: Vector2) -> Stroller:
	var packed: PackedScene = load("res://scenes/player/stroller.tscn")
	var player: Stroller = packed.instantiate()
	t.add_child(player)
	player.set_physics_process(false)
	player.global_position = at
	player.turn_to(facing)
	var pram := player.get_node("PramCollisionShape2D") as CollisionShape2D
	pram.position = facing * Tuning.PLAYER_BODY_RADIUS
	return player

func _step(engine: EventInstance, where: WhereSheIs, player: Stroller) -> void:
	where.tell(player.global_position,
			player.global_position + player.facing_direction() * Tuning.PLAYER_BODY_RADIUS)
	engine.step(STEP)
	var body := _body_of(engine)
	if body:
		body.force_update_transform()
		for child in body.get_children():
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
## The solid body the engine carries as a child (the one `StaticBody2D` that holds every piece).
func _body_of(engine: EventInstance) -> StaticBody2D:
	for child in engine.get_children():
		if child is StaticBody2D:
			return child
	return null

func _what_stops(player: Stroller, heading: Vector2) -> Object:
	var hit := player.move_and_collide(heading * WALK, true)
	return hit.get_collider() if hit else null

# ----------------------------------------------------------------- the row ---

func _test_the_row_is_a_car_with_the_engines_body(t: TestRunner) -> void:
	var def := _truck()
	t.check(def.drives(), "fire_truck drives: solid in every state, lethal in front while driving")
	t.check(def.ground_shape() != null and def.ground_shape().is_segment(),
			"its body is a capsule laid along its heading")
	t.check(def.ground_shape().reach() < def.core_within(),
			"and the body lies inside the field's inner radius")

# ------------------------------------------------------------------ driving ---

## Walked at side-on, a parked or driving truck stops her at its flank; lethal only ahead.
func _test_the_body_is_solid_while_it_drives_and_lethal_only_ahead(t: TestRunner) -> void:
	var engine_where := WhereSheIs.nowhere()
	var engine := _engine(t, PackedVector2Array([Vector2(-300.0, 0.0), Vector2(900.0, 0.0)]),
			engine_where)
	var player := _her(t, Vector2(0.0, 70.0), Vector2.UP)
	var struck := false
	var pressed := false
	var stopped := false
	for i in int(5.0 / STEP):
		_step(engine, engine_where, player)
		struck = struck or engine.is_lethal_at(player.global_position)
		if not pressed and absf(engine.global_position.x) < 6.0:
			pressed = true
			stopped = _walk(player, Vector2.UP, 70.0) < 70.0 \
					and _what_stops(player, Vector2.UP) == _body_of(engine)
	t.check(pressed and stopped, "walking into a driving truck's flank, its body stops her")
	t.check(not struck, "and it never strikes her beside it")
	player.free()
	engine.free()

## In its lane, on the carriageway, a car's warning comes `CAR_HORN_TIME` of its travel before the
## strike, at least as long as walking off the carriageway takes, and the strike fires before the
## body would ever stop against her.
func _test_in_front_of_it_the_warning_comes_first(t: TestRunner) -> void:
	for facing: Vector2 in [Vector2.LEFT, Vector2.UP]:
		var engine_where := WhereSheIs.nowhere()
		var engine := _engine(t,
				PackedVector2Array([Vector2(-700.0, 0.0), Vector2(900.0, 0.0)]), engine_where)
		var player := _her(t, Vector2.ZERO, facing)
		var warned_at := -1.0
		var struck_at := -1.0
		var held := false
		for i in int(8.0 / STEP):
			var was_at := engine.global_position
			_step(engine, engine_where, player)
			var now := float(i) * STEP
			if warned_at < 0.0 and engine.closes_on(player.global_position):
				warned_at = now
			held = held or engine.global_position.is_equal_approx(was_at)
			if engine.is_lethal_at(player.global_position):
				struck_at = now
				break
		t.check(struck_at > 0.0, "facing %s in its lane, the driving truck strikes her" % facing)
		var warning := struck_at - warned_at
		t.check(warned_at >= 0.0 and warning >= Tuning.required_horn_time(),
				"facing %s, warned %.2fs before the strike, at least the %.2fs to walk off the road"
				% [facing, warning, Tuning.required_horn_time()])
		t.check(not held, "and it did not stop against her first")
		t.check(engine.source().will_be_lethal(player.global_position), "the doubled caret was up over it")
		player.free()
		engine.free()

## **Created where the game creates it**, just out of sight up its street
## (`PendingWarning.on_its_route()`, the place `EventSpawner._summon_the_sighted_row()` asks for),
## from each of the four sides, with her standing in its lane facing it. On any street that place is
## nearer her than its warning reaches her (1.7s of its 190px/s past the touch, the touch counting
## its body and hers): up a north-south street the view is 180px to either side of her, and across
## an east-west one 320px. A truck driving from its first frame would strike her inside the time it
## takes to walk off the road. A car that drives is created standing (`EventCarDriving`'s car that has
## stood): it waits there while she is in its lane within its warning, and nothing strikes her.
## Once she is further along its lane than its warning reaches, it drives on, and the strike comes
## after the full warning.
func _test_where_it_is_created_she_is_warned_in_full(t: TestRunner) -> void:
	var def := _truck()
	var warning_reach := (EventCarDriving.PATROL_STRIKE_LEAD + Tuning.CAR_HORN_TIME) * def.speed() \
			+ def.ground_shape().spine_half_length() + def.ground_shape().rounding_radius() + Tuning.PLAYER_BODY_RADIUS
	var nearer_than_its_warning := 0
	var sides := {Vector2.DOWN: "the north", Vector2.UP: "the south", Vector2.RIGHT: "the west",
			Vector2.LEFT: "the east"}
	for travel: Vector2 in sides:
		var side: String = sides[travel]
		var her := Vector2.ZERO
		var stop := her + travel * 600.0
		var place := PendingWarning.on_its_route(def, her, stop, travel, 4000.0,
				VisibleView.around(her, null))
		t.check(place != Vector2.INF, "from %s, there is a place out of sight to create it" % side)
		if place == Vector2.INF:
			continue
		if place.distance_to(her) < warning_reach:
			nearer_than_its_warning += 1
		var engine_where := WhereSheIs.nowhere()
		var engine := _engine(t, PackedVector2Array([place, stop]), engine_where)
		var player := _her(t, her, -travel)
		var struck := false
		var moved := false
		for i in int(3.0 / STEP):
			_step(engine, engine_where, player)
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
			_step(engine, engine_where, player)
			var now := float(i) * STEP
			if warned_at < 0.0 and engine.closes_on(player.global_position):
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
## (its route parks where it arrives): past it, in its lane, she gets no mark and no doubled caret,
## is never struck by an engine that parks short of her, and does not hold it off screen.
func _test_nothing_reaches_past_its_kerb(t: TestRunner) -> void:
	# 120px past the kerb, the truck already driving: no warning that cannot come true.
	var engine_where := WhereSheIs.nowhere()
	var engine := _engine(t, PackedVector2Array([Vector2(-600.0, 0.0), Vector2.ZERO]),
			engine_where)
	var player := _her(t, Vector2(120.0, 0.0), Vector2.LEFT)
	var warned := false
	var lethal := false
	for i in int(5.0 / STEP):
		_step(engine, engine_where, player)
		warned = warned or engine.closes_on(player.global_position)
		lethal = lethal or engine.source().will_be_lethal(player.global_position) \
				or engine.is_lethal_at(player.global_position)
		if engine.has_parked():
			break
	t.check(engine.has_parked() and not warned and not lethal,
			"120px past its kerb, no mark and no doubled caret over a truck that parks short of her")
	player.free()
	engine.free()
	# 50-60px past it, her pram on the far side: it parks short of her and ends nothing.
	for past: float in [50.0, 55.0, 60.0]:
		engine = _engine(t, PackedVector2Array([Vector2(-600.0, 0.0), Vector2.ZERO]),
				engine_where)
		player = _her(t, Vector2(past, 0.0), Vector2.RIGHT)
		lethal = false
		for i in int(5.0 / STEP):
			_step(engine, engine_where, player)
			lethal = lethal or engine.is_lethal_at(player.global_position)
			if engine.has_parked():
				break
		var gap := GapToHer.between(engine, player)
		t.check(engine.has_parked() and gap > 0.0 and not lethal,
				"%.0fpx past its kerb, it parks %.0fpx short of her and the day goes on"
				% [past, gap])
		player.free()
		engine.free()
	# Past it when it is created, clear of where its body parks: it does not wait for her, it
	# drives on and parks. (Nearer than 43px its parked body would overlap hers, and it stands
	# against her there rather than driving into her.)
	for past: float in [60.0, 120.0, 250.0]:
		engine = _engine(t, PackedVector2Array([Vector2(-200.0, 0.0), Vector2.ZERO]),
				engine_where)
		player = _her(t, Vector2(past, 0.0), Vector2.RIGHT)
		for i in int(3.0 / STEP):
			_step(engine, engine_where, player)
			if engine.has_parked():
				break
		t.check(engine.has_parked(), "%.0fpx past its kerb when it is created, it drives on and parks"
				% past)
		player.free()
		engine.free()
	# And between it and its kerb she is still warned in full and struck.
	engine = _engine(t, PackedVector2Array([Vector2(-700.0, 0.0), Vector2.ZERO]), engine_where)
	player = _her(t, Vector2(-100.0, 0.0), Vector2.LEFT)
	var warned_at := -1.0
	var struck_at := -1.0
	for i in int(5.0 / STEP):
		_step(engine, engine_where, player)
		var now := float(i) * STEP
		if warned_at < 0.0 and engine.closes_on(player.global_position):
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
func _test_behind_and_beside_it_nothing_strikes(t: TestRunner) -> void:
	var engine_where := WhereSheIs.nowhere()
	var engine := _engine(t, PackedVector2Array([Vector2(40.0, 0.0), Vector2(1200.0, 0.0)]),
			engine_where)
	var player := _her(t, Vector2.ZERO, Vector2.RIGHT)
	var struck := false
	var touched := false
	for i in int(2.5 / STEP):
		_step(engine, engine_where, player)
		struck = struck or engine.is_lethal_at(player.global_position)
		if player.move_and_collide(Vector2.RIGHT * Tuning.WALK_SPEED * STEP) != null:
			touched = true
	t.check(not struck, "a truck driving away from her never strikes her behind it")
	t.check(engine.global_position.x > 41.0, "and it was driving (%.0fpx along)"
			% engine.global_position.x)
	player.free()
	engine.free()
	# Standing beside its line, it passes her without a strike.
	engine = _engine(t, PackedVector2Array([Vector2(-300.0, 0.0), Vector2(600.0, 0.0)]),
			engine_where)
	player = _her(t, Vector2(0.0, 45.0), Vector2.LEFT)
	struck = false
	for i in int(5.0 / STEP):
		_step(engine, engine_where, player)
		struck = struck or engine.is_lethal_at(player.global_position)
	t.check(not struck and engine.global_position.x > 100.0,
			"and one driving past her on the next lane never strikes her (%.0f)"
			% engine.global_position.x)
	player.free()
	engine.free()

# ------------------------------------------------------------------- parked ---

## Once it has stopped at the fire it is a body she walks round and nothing that can end the day,
## from in front of it, behind it or beside it.
func _test_parked_it_is_solid_and_harmless(t: TestRunner) -> void:
	var engine_where := WhereSheIs.nowhere()
	var engine := _engine(t, PackedVector2Array([Vector2(-200.0, 0.0), Vector2(0.0, 0.0)]),
			engine_where)
	var player := _her(t, Vector2(300.0, 300.0), Vector2.UP)
	for i in int(4.0 / STEP):
		_step(engine, engine_where, player)
		if engine.has_parked():
			break
	t.check(engine.has_parked(), "the truck parks where its route ends")
	t.check(not engine.source().will_be_lethal(Vector2(40.0, 0.0)),
			"and a parked truck is not lethal ahead of it")
	for place: Vector2 in [Vector2(40.0, 0.0), Vector2(-40.0, 0.0), Vector2(0.0, 30.0), Vector2(0.0, -30.0)]:
		t.check(not engine.is_lethal_at(place), "a parked truck strikes nobody at %s" % place)
	t.check(engine.is_solid() and _body_of(engine) != null, "and its body is still there")
	# Her first rig goes before the walks: placed with no frame run, the physics server still has
	# its body at the origin, under the truck, where it would stop a walker instead of the truck.
	player.free()
	for approach: Vector2 in [Vector2.DOWN, Vector2.UP, Vector2.RIGHT]:
		var from: Vector2 = engine.global_position - approach * 90.0
		var walker := _her(t, from, approach)
		var walked := _walk(walker, approach, 180.0)
		t.check(walked < 180.0 and _what_stops(walker, approach) == _body_of(engine),
				"walking %s into the parked truck, its own body stops her (%.0fpx)"
				% [approach, walked])
		var stood := walker.global_position.distance_to(engine.global_position)
		t.check(stood > Tuning.PLAYER_BODY_RADIUS, "and stopped outside it (%.0fpx)" % stood)
		t.check(not engine.is_lethal_at(walker.global_position),
				"and standing against it ends nothing")
		walker.free()
	engine.free()

## Parked, its field is priced from its centre as it was before it had a body
## (`VehicleSpec.prices_its_field_from_its_centre()`): along its street it reaches as far as abeam, so the 340px
## the fire's siting check closes about its kerb is the whole of it and a pass costs what
## `docs/COSTS.md` says.
func _test_parked_its_field_is_a_points(t: TestRunner) -> void:
	var def := _truck()
	t.check(def.field().is_priced_from_its_centre(), "fire_truck's field is priced from its centre")
	var moving := def.heard_within() * Field.scale(Field.eccentricity(def.speed()))
	t.check(is_equal_approx(def.field_reach(), moving),
			"and its field's reach is a moving point's, %.0fpx, not its body's (%.0fpx)"
			% [moving, def.field_reach()])
	var engine_where := WhereSheIs.nowhere()
	var engine := _engine(t, PackedVector2Array([Vector2(-200.0, 0.0), Vector2(0.0, 0.0)]),
			engine_where)
	var player := _her(t, Vector2(300.0, 300.0), Vector2.UP)
	for i in int(4.0 / STEP):
		_step(engine, engine_where, player)
		if engine.has_parked():
			break
	t.check(engine.has_parked() and engine.travel_velocity().is_zero_approx(),
			"the truck has parked and stands still")
	var same := true
	for d: float in [40.0, 100.0, 250.0, def.heard_within() - 5.0]:
		var along := engine.field_at(Vector2(d, 0.0), -1.0, Vector2.ZERO)
		var abeam := engine.field_at(Vector2(0.0, d), -1.0, Vector2.ZERO)
		same = same and absf(along - abeam) < 0.0001 and along > 0.0
	t.check(same, "along its street its field is what it is abeam, at every distance")
	t.check(engine.field_at(Vector2(def.heard_within() + 5.0, 0.0), -1.0, Vector2.ZERO) == 0.0,
			"and it ends at its 340px along the street, not past its body's end")
	player.free()
	engine.free()

# ----------------------------------------------------------------- picture ---

## Its picture's bottom lands on its body's southern edge: the spine's reach down the screen, its
## rounding and the view's own canvas margin below the node. Drawn on real frames facing south (its
## front view, where the spine's half length counts) and facing east (its side view), the foot it
## tells its drawer to stand the picture at is where that bottom lands.
func _test_its_picture_stands_over_its_body(t: TestRunner) -> void:
	var shape := _truck().ground_shape()
	var views := {"front": Vector2(0.0, 600.0), "side": Vector2(600.0, 0.0)}
	for view: String in views:
		var engine_where := WhereSheIs.nowhere()
		var recording := RecordingEventDrawer.new()
		var engine := _engine(t, PackedVector2Array([Vector2.ZERO, views[view]]), engine_where,
				recording)
		engine.set_process(true)
		for i in 2:
			await engine.get_tree().process_frame
		var drawn: Array[Dictionary] = []
		for entry in recording.shown_on(engine):
			if entry.kind == &"stand" and entry.picture == EventPictures.FIRE_ENGINE_BY_VIEW[view]:
				drawn.append(entry)
		t.check(drawn.size() == 1, "the %s view of it is drawn once (%d)" % [view, drawn.size()])
		t.check(not drawn.is_empty() and is_equal_approx(drawn[0].foot.y,
				shape.spine_half_length() * absf(engine.solid_axis().y) + shape.rounding_radius()
				+ float(EventPictures.FIRE_ENGINE_CANVAS_BOTTOM_MARGIN[view])),
				"the %s view's bottom lands on the body's southern edge" % view)
		engine.free()
	t.check(EventFootprints.footprint_of(_truck()).end.y > shape.reach(),
			"and the drawn box allows for the lowered picture")
