extends RefCounted
## The escape's masked man and her body on the stairwell flights, on real physics ticks: the 45-degree
## walk of every flight, the lines onto the second flight that are caught and the ones that get
## through, the screen-edge badge from his run, and the next man up the shaft. Split from
## `test_interior.gd` for its wall time, and from `test_interior_masked_man_badge.gd` the same way:
## these walk thousands of real ticks, so the shard planner can put the pieces on different shards.
## The one case that is not a walk asks the building's events what the building's own walls do to
## the masked man's field and the explosion's (`CityMap.wall_between()`'s geometry is
## `test_wall_shield.gd`'s).

const BuildingEvents := preload("res://tests/building_events.gd")
const InteriorRig := preload("res://tests/interior_rig.gd")
const MaskedManMeeting := preload("res://tests/masked_man_meeting.gd")
const _SIZE := float(Tuning.TILE_SIZE)
## How much faster than real time a long stretch of real physics ticks runs (`Engine.time_scale`, put
## back by `PhysicsTicks`).
const FAST_SCALE := 8.0

var _rig := InteriorRig.new()
var _meeting := MaskedManMeeting.new(_rig)

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	await _test_her_body_walks_every_flight_at_45_degrees(t)
	await _test_she_has_to_run_to_the_first_floor_door(t)
	await _test_the_edge_badge_points_at_the_masked_man_from_his_run(t)
	await _test_another_masked_man_comes_up_the_same_shaft(t)
	await _test_the_building_inside_stops_it_at_its_own_walls(t)

## **Her body walks the flight's 45 degrees, not only her steering** *(inbox #783 in minty-lemur)*. A real carrying
## rig holds one sideways action from a landing tile's centre until she stands on the next landing,
## on every flight of both shafts, down and up. Her own `_physics_process()` runs on real physics
## ticks, redirecting and accelerating her velocity and moving her with `move_and_slide()` against the
## scene's registered blockers; the walk is read after each tick (her position, and
## `get_slide_collision_count()` for the walls she touched).
##
## Sampled every tenth of a second, her displacement while she is on flight tiles heads within
## `_STAIR_HEADING_TOLERANCE` of the flight's own 45 degrees. A landing leaves her press as it is,
## so her first step is level until she stands on the flight. From a landing tile level with the
## flight's end tread that step puts her on the flight's line, and she never touches a wall on it.
## From the row below the flight's end tread (`second_row`) she is a tile under the flight's line,
## and slides along the stair side onto it, so there the samples are pinned once she is two tiles
## along. With full-cell blockers beside the flight the same walks zigzag between flat and 80
## degrees, since the blockers' corners are closer together across the slope than her body is wide.
const _STAIR_HEADING_TOLERANCE := 2.0
const _STAIR_WALKS := [
	# [local start, the next landing's column, action, second_row]
	[Vector2i(1, 2), 8, "move_right", false], [Vector2i(1, 3), 8, "move_right", true],
	[Vector2i(8, 8), 1, "move_left", false],
	[Vector2i(8, 10), 1, "move_left", false], [Vector2i(8, 11), 1, "move_left", true],
	[Vector2i(1, 16), 8, "move_right", false],
	[Vector2i(1, 18), 8, "move_right", false], [Vector2i(1, 19), 8, "move_right", true],
	[Vector2i(8, 24), 1, "move_left", false], [Vector2i(8, 25), 1, "move_left", true],
]

func _test_her_body_walks_every_flight_at_45_degrees(t: TestRunner) -> void:
	# Six seconds of the game's 30Hz ticks, taken eight times as often as the engine would.
	const MAX_TICKS := 180
	const WALK_PACE := 8
	var f := InteriorMap.build()
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var packed: PackedScene = load("res://scenes/player/stroller.tscn")
	var player: Stroller = packed.instantiate()
	player.use_carrying_rig()
	player.set_map(scene.map())
	scene.add_entity(player)
	var body_collision := player.get_node("CollisionShape2D") as CollisionShape2D
	var body_circle := body_collision.shape as CircleShape2D
	t.check(not body_collision.disabled and body_circle != null
			and is_equal_approx(body_circle.radius, Tuning.PLAYER_BODY_RADIUS),
			"the walks use the enabled real 14px player circle")
	t.check((player.get_node("PramCollisionShape2D") as CollisionShape2D).disabled,
			"and the pram body is off while she carries the baby")
	for side: String in ["left", "right"]:
		var origin: Vector2i = f.waypoint("stairwell_%s" % side) - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
		for walk: Array in _STAIR_WALKS:
			var start: Vector2i = origin + (walk[0] as Vector2i)
			var column: int = origin.x + int(walk[1])
			var action: String = walk[2]
			var second_row: bool = walk[3]
			var label := "%s shaft from %s, %s" % [side, walk[0], action]
			t.check(f.floor_kind_at(start) == InteriorTile.Kind.STAIRWELL_FLOOR,
					"%s: starts on a landing tile" % label)
			for a: String in ["move_left", "move_right", "move_up", "move_down"]:
				Input.action_release(a)
			Input.action_press(action)
			player.global_position = scene.map().tile_to_world(start)
			player.velocity = Vector2.ZERO
			# Her own `_physics_process()` walks her on real ticks with the key held; what the walk
			# reads is sampled after each tick, where the tick left her.
			var walk_state := {"ticks": 0, "sampled": 0, "worst": 0.0, "flight_contacts": 0,
					"last": player.global_position}
			var read_the_walk := func(ticks: int) -> bool:
				# Whether she stood on the flight before this tick: the tick's contacts are the
				# flight's if she did.
				var was_on_flight := scene.map().slope_dir_at(walk_state["position"]) != 0
				walk_state["position"] = player.global_position
				if was_on_flight:
					walk_state["flight_contacts"] += player.get_slide_collision_count()
				walk_state["ticks"] = ticks
				if scene.map().world_to_tile(player.global_position).x == column \
						and scene.map().slope_dir_at(player.global_position) == 0:
					return true
				# Every tenth of a second: three ticks of the game's 30Hz.
				if ticks % 3 != 0:
					return false
				var last: Vector2 = walk_state["last"]
				var moved := player.global_position - last
				var along := absf(last.x - scene.map().tile_to_world(start).x)
				if scene.map().slope_dir_at(last) != 0 and scene.map().slope_dir_at(player.global_position) != 0 \
						and moved.length() > 1.0 and (not second_row or along >= InteriorScene.TILE * 2.0):
					walk_state["sampled"] += 1
					# 45 degrees off the vertical, whichever of the four diagonals.
					var off_vertical := absf(absf(rad_to_deg(moved.angle())) - 90.0)
					walk_state["worst"] = maxf(walk_state["worst"], absf(off_vertical - 45.0))
				walk_state["last"] = player.global_position
				return false
			walk_state["position"] = player.global_position
			await PhysicsTicks.pass_ticks_faster(t, MAX_TICKS, WALK_PACE, read_the_walk)
			var steps: int = walk_state["ticks"]
			var sampled: int = walk_state["sampled"]
			var worst: float = walk_state["worst"]
			var flight_contacts: int = walk_state["flight_contacts"]
			Input.action_release(action)
			t.check(scene.map().world_to_tile(player.global_position).x == column,
					"%s: she reaches the next landing (%d steps, ended on %s)"
					% [label, steps, scene.map().world_to_tile(player.global_position) - origin])
			t.check(sampled >= 10, "%s: the walk had samples on the flight to read (%d)" % [label, sampled])
			t.check(worst <= _STAIR_HEADING_TOLERANCE,
					"%s: her body heads within %.0f degrees of 45 on the flight (worst %.1f)"
					% [label, _STAIR_HEADING_TOLERANCE, worst])
			if not second_row:
				t.check(flight_contacts == 0,
						"%s: and touches no wall on it (%d contacts)" % [label, flight_contacts])
	player.free()
	scene.free()

## **She has to run to the door** *(inbox #764 in minty-lemur, the player: "player should have to run to the
## door"; inbox #782 in minty-lemur, the player: the radius bigger, not him moved)*. He is not in the
## world until she walks within the masked man's `EventDef.sets_off_within()` of the foot of his
## shaft, and then comes there on the same tick, running his line (`SetOffWatch`). Stepped at the
## game's own rhythm: the game's physics
## ticks at 30Hz (`common/physics_ticks_per_second` in `project.godot`), and on each tick her real
## carrying body moves with the real stair steering and collision, then the building's
## `EventManager._physics_process()` tells him where she is, steps him, and checks the catch. She comes in at his shaft's second-floor door and down the
## landing, and takes the second flight from each line a player turns onto it by. Once he runs she
## makes for the first floor's door, on along the flight and up the landing into it.
##
## **Which lines catch a walker is what is pinned, and not every line does:** a walker is caught
## from the rows level with and below the flight's head tread, and from the landing tile between
## the two flights holding down-left; **a walker who holds plain left from the landing tile between
## the two flights gets through**. A runner gets through on every line, whether she was running all
## along or starts running the moment he does, with the keys she already holds. **The margin is
## thin:** on the tightest runner's line (walking until he runs, then running, turning plain left at
## row 11's centre) how near he comes to her centre on the tick, the only place he moves and the
## catch is checked, stays outside his catch (`EventCatalogue.MASKED_PURSUER_CATCH`). A start
## running a little after he does is not pinned either way.
func _test_she_has_to_run_to_the_first_floor_door(t: TestRunner) -> void:
	for walk: Array in MaskedManMeeting.TURNS:
		for pace: String in ["walk", "run", "walk-run"]:
			var met := await _meeting.meet(t, walk, pace)
			var expected := "through" if pace != "walk" or not walk[2] else "caught"
			t.check(met["ran"], "%s at a %s: he runs" % [walk[3], pace])
			t.check(met["outcome"] == expected,
					"%s at a %s: %s (%s, %.0fpx from him at the closest)"
					% [walk[3], pace, expected, met["outcome"], met["closest"]])
			if walk[0] == 11 and pace == "walk-run":
				t.check(met["closest"] > EventCatalogue.MASKED_PURSUER_CATCH,
						"%s at a %s: he comes %.1fpx from her centre on the tick, outside his %.1fpx catch"
						% [walk[3], pace, met["closest"], EventCatalogue.MASKED_PURSUER_CATCH])
			print("The masked man, %s at a %s: %s, %.0fpx from him at the closest"
					% [walk[3], pace, met["outcome"], met["closest"]])

## **The screen-edge badge points at the masked man from the frame he starts running** *(inbox
## #788 in minty-lemur, the player, told that his only heads-up is the badge once he runs: "Let's show that at
## least"; minty-dolphin #852: "Anyway a badge shouldn't disappear before the entity is visible")*.
## His badge is his warning's, put up as she reaches his place, and kept by the man the warning
## created until she can see him (`BadgeModel`). On every way down onto the second flight and at
## each pace, with her real camera and a real `DangerEdge` (`_meeting.meet()` with `badge`): on
## every drawn frame from his run until he comes into her view, or she is through the door or caught,
## the badge for him is up. The badge is drawn at his own position (`DangerEdge._draw_arrow()`), so
## up is pointing at him.
func _test_the_edge_badge_points_at_the_masked_man_from_his_run(t: TestRunner) -> void:
	for walk: Array in MaskedManMeeting.TURNS:
		for pace: String in ["walk", "run", "walk-run"]:
			var met := await _meeting.meet(t, walk, pace, true)
			t.check(met["ran"] and int(met["unseen_frames"]) > 0,
					"%s at a %s: he runs while she cannot see him" % [walk[3], pace])
			t.check(int(met["badge_first"]) == 0 and int(met["badge_dropped"]) == 0,
					"%s at a %s: the edge badge points at him from the frame he runs, and stays up "
					% [walk[3], pace] + "until he is in view (first up %d frames in, down on %d of %d)"
					% [met["badge_first"], met["badge_dropped"], met["unseen_frames"]])

## *"Then the pursuing guy should respawn forcing to switch the side again."*
##
## Driven by the building's `EventManager` on real physics ticks, with her standing on the first
## floor's door of his shaft for the whole run — off his line, clear of his reach, out of sight of
## the foot of the shaft and inside the masked man's `EventDef.sets_off_within()` of it, so every
## man that may come is set off with her already inside his place.
##
## Three contracts, and the second is what keeps the first fair:
##
## - **More than one of him over a section**, or "switch the side again" has nothing behind it.
## - **Every one of them is warned of before he exists**: with her inside his place already when he
##   may come, his badge is up alone for his row's warning (`EventDef.warned_for()`,
##   `Tuning.WARNING_ALONE_MAX`) before he is in the world, and he never comes while his warning
##   is not up (`SetOffWatch`). Nor does he come at a walk's pace or later in his run: each takes
##   his first step from the foot of the shaft.
## - **The gap is the stated one**, measured from him leaving the top of the shaft to the next one's
##   warning going up, rather than read off the constant.
func _test_another_masked_man_comes_up_the_same_shaft(t: TestRunner) -> void:
	const STEP := 1.0 / 30.0
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var events := BuildingEvents.events_in(t, scene, rng, _rig.fresh_run())
	var part := "stairwell_%s" % ("right" if BuildingPlan.BURNING_SIDE == "left" else "left")
	var plan := InteriorMap.build()
	var her := scene.map().tile_to_world((plan.door("%s:landing_first" % part) as InteriorMapPlan.Door).tile)
	# A stand-in for her: the manager is handed where she stands and tells every instance each tick.
	var player := Node2D.new()
	player.add_to_group("player")
	t.add_child(player)
	player.global_position = her
	events.use_player(player)
	var foot := scene.map().tile_to_world(plan.stairwell_walk(part)[0])
	t.check(foot.distance_to(her) <= Shipped.rows().by_id("masked_pursuer")
			.sets_off_within(),
			"the first floor's door is inside his place (%.0fpx from the foot)" % foot.distance_to(her))

	var warned: Array[float] = []
	var appeared: Array[float] = []
	var left: Array[float] = []
	var known := {}
	var came_unwarned := 0
	var first_steps_off_the_foot := 0
	var state := {"warning": false}
	var was_leaving_by_id := {}
	var after_the_tick := func(ticks: int) -> bool:
		var at := (ticks - 1) * STEP
		var warning_up := false
		for warning in events.pending_warnings():
			warning_up = warning_up or warning.row().id() == "masked_pursuer"
		if warning_up and not state["warning"]:
			warned.append(at)
		state["warning"] = warning_up
		for instance in events.instances():
			if instance.row_id() != "masked_pursuer":
				continue
			var id := instance.get_instance_id()
			if not known.has(id):
				known[id] = true
				appeared.append(at)
				# The warning that brought him went up on an earlier tick and ran out on this one.
				if warned.size() < appeared.size():
					came_unwarned += 1
				# On the tick he comes he has taken one step of his line from the foot.
				if instance.global_position.distance_to(foot) > Shipped.rows().by_id(
						"masked_pursuer").speed() * STEP + 1.0:
					first_steps_off_the_foot += 1
			var was_leaving: bool = was_leaving_by_id.get(id, false)
			if instance.is_on_its_way_out() and not was_leaving:
				left.append(at)
		was_leaving_by_id.clear()
		for instance in events.instances():
			was_leaving_by_id[instance.get_instance_id()] = instance.is_on_its_way_out()
		# Ends once the run has shown what the checks below ask for with room to spare (they need
		# three men and one gap): four men come and three have left the top. The whole section holds
		# more, and a longer watch only repeats the same men over again.
		return appeared.size() >= 4 and left.size() >= 3
	await PhysicsTicks.pass_ticks_faster(t, ceili(RunConfig.FINALE_LENGTH_SECONDS / STEP), 8,
			after_the_tick)
	player.free()
	t.check(appeared.size() >= 3,
			"more than one masked man comes up the shaft over a section (%d)" % appeared.size())
	t.check(came_unwarned == 0 and first_steps_off_the_foot == 0,
			"and every one is warned of before he exists and comes at the foot of the shaft "
			+ "(%d unwarned, %d elsewhere)" % [came_unwarned, first_steps_off_the_foot])
	for i in appeared.size():
		if i >= warned.size():
			break
		var alone: float = appeared[i] - warned[i]
		t.check(alone >= Tuning.WARNING_ALONE_MAX - STEP,
				"man %d comes %.2fs after his warning went up, after the second it owes" % [i, alone])
	var gaps := 0
	for i in range(1, warned.size()):
		if i - 1 >= left.size():
			break
		gaps += 1
		var gap: float = warned[i] - left[i - 1]
		t.check(absf(gap - EventCatalogue.FINALE_PURSUER_RESPAWN_SECONDS) <= STEP * 3.0,
				"the next man's warning goes up %.2fs after the last one ran out of the top, against %.2fs"
				% [gap, EventCatalogue.FINALE_PURSUER_RESPAWN_SECONDS])
	t.check(gaps > 0, "there were gaps between his runs to measure (%d)" % gaps)
	print("The masked man came %d times before the watch ended; gaps measured: %d"
			% [appeared.size(), gaps])
	events.free()
	scene.free()

## **Indoors too.** *(plaid-wombat, inbox #554: "Excitement should not go through **any** wall".)*
## Every source in the escape's building stands on the building's map (`InteriorMapPlan`), open
## where she may stand, and its walls stop a field at the depths a city's buildings do
## (`WorldMap.wall_between()`). The masked man is stood on every tile
## of his own shaft's walk and asked at every walkable point of it within his reach: nothing where
## the grid walls the line, the field itself everywhere else; the guard counts the points a field
## reached and a wall stopped, which is what the solid between two flights does to him. The
## explosion is the exception: it stands for a bang outside that has already come through the walls,
## so a wall between where its instance stands and her keeps none of it from her.
func _test_the_building_inside_stops_it_at_its_own_walls(t: TestRunner) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var run := RunState.new()
	run.start_run(4242)
	var events := BuildingEvents.events_in(t, scene, rng, run)
	var grid := scene.map()

	var man := BuildingEvents.masked_man(events)
	t.check(man != null, "the masked man is planned on the stairs")
	if man:
		man.restore(EventSave.new(man.telegraphs_for(), 0.0, INF))
		var shaft: Array[Vector2] = []
		for tile in scene.map().stairwell_tiles("stairwell_right"):
			if not scene.map().is_walkable(tile):
				continue
			for sy in 4:
				for sx in 4:
					shaft.append(Vector2(tile) * _SIZE + Vector2(4.0 + 8.0 * sx, 4.0 + 8.0 * sy))
		var reached := 0
		var stopped := 0
		var wrong := 0
		for tile in scene.map().stairwell_walk("stairwell_right"):
			# Moved as the manager moves an event it stands elsewhere (`EventInstance.move_to()`).
			man.move_to(scene.map().tile_to_world(tile))
			for her in shaft:
				var field := man.field_at(her, -1.0, Vector2.INF)
				if field <= 0.0:
					continue
				var landed := man.source().contribution_at(her)
				var walled := grid.wall_between(man.global_position, her)
				if walled:
					stopped += 1
				else:
					reached += 1
				if landed != (0.0 if walled else field):
					wrong += 1
		t.check(stopped > 0, "a wall in his shaft stands between him and her (%d points)" % stopped)
		t.check(reached > stopped, "while most of his reach is open stairs (%d points)" % reached)
		t.check(wrong == 0, "and his field reaches her exactly where no wall stops it (%d did not)"
				% wrong)

	# Somewhere on the stairs with open stair behind a wall from it, well inside the bang's reach.
	var stands := Vector2.INF
	var behind := Vector2.INF
	for from in scene.map().stairwell_walk("stairwell_right"):
		for tile in scene.map().stairwell_tiles("stairwell_right"):
			var at := scene.map().tile_to_world(tile)
			if scene.map().is_walkable(tile) and at.distance_to(scene.map().tile_to_world(from)) < 200.0 \
					and grid.wall_between(scene.map().tile_to_world(from), at):
				stands = scene.map().tile_to_world(from)
				behind = at
				break
		if behind != Vector2.INF:
			break
	t.check(behind != Vector2.INF, "there is open stair behind a wall from a step of the shaft")
	var player := Node2D.new()
	player.add_to_group("player")
	events.use_player(player)
	t.add_child(player)
	player.global_position = stands
	# The manager's own physics ticks, one a frame (`PhysicsTicks`), at `FAST_SCALE` times real time
	# so the interval does not take its length of the suite, until the next bang comes: a tick count,
	# not a clock, bounds the wait, and the bang is judged on the tick it appears.
	var burst: EventInstance = null
	var ticks_left: int = PhysicsTicks.ticks_for(EventCatalogue.FINALE_EXPLOSION_INTERVAL + 1.0,
			FAST_SCALE)
	while burst == null and ticks_left > 0:
		await PhysicsTicks.pass_ticks(t, 1, Callable(), FAST_SCALE)
		ticks_left -= 1
		for instance in events.instances():
			if instance.row_id() == "finale_explosion":
				burst = instance
	t.check(burst != null and burst.global_position == stands,
			"an explosion goes off where she stands")
	if burst and behind != Vector2.INF:
		t.check(burst.source().contribution_at(behind) > 0.0,
				"and the bang reaches her behind the wall: it came through the walls from outside"
				+ " (%.1f)" % burst.source().contribution_at(behind))
		t.check(not burst.source().wall_grid().wall_between(burst.global_position, behind),
				"and the debug view's fields layer cuts it at no wall either, as the meter does")
		var outline := GroundShape.field_outline_at(burst.global_position, Vector2.ZERO,
				burst.heard_within())
		var runs := DebugLayers.open_runs(outline, burst.global_position, burst.source().wall_grid())
		t.check(runs.size() == 1 and runs[0].size() == outline.size() + 1,
				"so its outline is drawn whole, in one closed run (%d runs)" % runs.size())
	player.free()
	events.free()
	scene.free()
