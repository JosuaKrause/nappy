extends RefCounted
## The escape's masked man and her body on the stairwell flights, on real physics ticks: the 45-degree
## walk of every flight, the lines onto the second flight that are caught and the ones that get
## through, the screen-edge badge from his run, and the next man up the shaft. Split from
## `test_interior.gd` for its wall time: these walk thousands of real ticks, so the shard planner
## can put the two halves on different shards.

const BuildingEvents := preload("res://tests/building_events.gd")
const InteriorRig := preload("res://tests/interior_rig.gd")

var _rig := InteriorRig.new()

func run(t) -> void:
	await PhysicsTicks.settle(t)
	await _test_her_body_walks_every_flight_at_45_degrees(t)
	await _test_she_has_to_run_to_the_first_floor_door(t)
	await _test_the_edge_badge_points_at_the_masked_man_from_his_run(t)
	await _test_the_edge_badge_does_not_depend_on_when_in_the_physics_tick_she_starts(t)
	await _test_another_masked_man_comes_up_the_same_shaft(t)
	_rig.free_all()

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

func _test_her_body_walks_every_flight_at_45_degrees(t: Node) -> void:
	# Six seconds of the game's 30Hz ticks, taken eight times as often as the engine would.
	const MAX_TICKS := 180
	const WALK_PACE := 8
	var f := InteriorMap.build()
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var packed: PackedScene = load("res://scenes/player/stroller.tscn")
	var player: Stroller = packed.instantiate()
	player.carrying = true
	player.set_map(scene.map)
	scene.add_entity(player)
	var body_collision := player.get_node("CollisionShape2D") as CollisionShape2D
	var body_circle := body_collision.shape as CircleShape2D
	t.check(not body_collision.disabled and body_circle != null
			and is_equal_approx(body_circle.radius, Tuning.PLAYER_BODY_RADIUS),
			"the walks use the enabled real 14px player circle")
	t.check((player.get_node("PramCollisionShape2D") as CollisionShape2D).disabled,
			"and the pram body is off while she carries the baby")
	for side in ["left", "right"]:
		var origin: Vector2i = f.waypoints["stairwell_%s" % side] - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
		for walk: Array in _STAIR_WALKS:
			var start: Vector2i = origin + (walk[0] as Vector2i)
			var column: int = origin.x + int(walk[1])
			var action: String = walk[2]
			var second_row: bool = walk[3]
			var label := "%s shaft from %s, %s" % [side, walk[0], action]
			t.check(f.tiles.get(start) == InteriorTile.Kind.STAIRWELL_FLOOR,
					"%s: starts on a landing tile" % label)
			for a in ["move_left", "move_right", "move_up", "move_down"]:
				Input.action_release(a)
			Input.action_press(action)
			player.global_position = scene.map.tile_to_world(start)
			player.velocity = Vector2.ZERO
			# Her own `_physics_process()` walks her on real ticks with the key held; what the walk
			# reads is sampled after each tick, where the tick left her.
			var walk_state := {"ticks": 0, "sampled": 0, "worst": 0.0, "flight_contacts": 0,
					"last": player.global_position}
			var read_the_walk := func(ticks: int) -> bool:
				# Whether she stood on the flight before this tick: the tick's contacts are the
				# flight's if she did.
				var was_on_flight := scene.map.slope_dir_at(walk_state["position"]) != 0
				walk_state["position"] = player.global_position
				if was_on_flight:
					walk_state["flight_contacts"] += player.get_slide_collision_count()
				walk_state["ticks"] = ticks
				if scene.map.world_to_tile(player.global_position).x == column \
						and scene.map.slope_dir_at(player.global_position) == 0:
					return true
				# Every tenth of a second: three ticks of the game's 30Hz.
				if ticks % 3 != 0:
					return false
				var last: Vector2 = walk_state["last"]
				var moved := player.global_position - last
				var along := absf(last.x - scene.map.tile_to_world(start).x)
				if scene.map.slope_dir_at(last) != 0 and scene.map.slope_dir_at(player.global_position) != 0 \
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
			t.check(scene.map.world_to_tile(player.global_position).x == column,
					"%s: she reaches the next landing (%d steps, ended on %s)"
					% [label, steps, scene.map.world_to_tile(player.global_position) - origin])
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
## door"; inbox #782 in minty-lemur, the player: the radius bigger, not him moved)*. He warns while she is in the
## stairwell and runs his line once she is within `masked_pursuer.notice.runs_within` of him
## (`EventNoticeRun`). Stepped at the game's own rhythm: the game's physics
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
## along or starts running the moment he does, with the keys she already holds. **The margins are
## thin:** on the tightest runner's line (walking until he runs, then running, turning plain left at
## row 11's centre) how near he comes to her centre on the tick, the only place he moves and the
## catch is checked, is pinned just outside his catch (`_TIGHTEST_RUNNER_CLOSEST` against
## `EventCatalogue.MASKED_PURSUER_CATCH`); **she is caught if she starts running 16 ticks (a little over half a second) after he
## does.**
func _test_she_has_to_run_to_the_first_floor_door(t: Node) -> void:
	for walk: Array in _SECOND_FLIGHT_TURNS:
		for pace: String in ["walk", "run", "walk-run", "run-late"]:
			if pace == "run-late" and walk[0] != 11:
				continue
			var met := await _meet_the_masked_man(t, walk, pace)
			var expected := "through" if pace != "walk" or not walk[2] else "caught"
			if pace == "run-late":
				expected = "caught"
			t.check(met["ran"], "%s at a %s: he runs" % [walk[3], pace])
			t.check(met["outcome"] == expected,
					"%s at a %s: %s (%s, %.0fpx from him at the closest)"
					% [walk[3], pace, expected, met["outcome"], met["closest"]])
			if walk[0] == 11 and pace == "walk-run":
				t.check(absf(met["closest"] - _TIGHTEST_RUNNER_CLOSEST) < 0.5
						and met["closest"] > EventCatalogue.MASKED_PURSUER_CATCH,
						"%s at a %s: he comes %.1fpx from her centre on the tick (%.1fpx pinned), %s"
						% [walk[3], pace, met["closest"], _TIGHTEST_RUNNER_CLOSEST,
						"outside his %.1fpx catch" % EventCatalogue.MASKED_PURSUER_CATCH])
			print("The masked man, %s at a %s: %s, %.0fpx from him at the closest"
					% [walk[3], pace, met["outcome"], met["closest"]])

## **The screen-edge badge points at the masked man from the frame he starts running** *(inbox
## #788 in minty-lemur, the player, told that his only heads-up is the badge once he runs: "Let's show that at
## least")*. On every way down onto the second flight and at each pace, with her real camera and a
## real `DangerEdge` (`_meet_the_masked_man()` with `badge`): on every drawn frame from his run until
## he comes into her view, or she is through the door or caught, the badge for him is up. The badge
## is drawn at his own position (`DangerEdge._draw_arrow()`), so up is pointing at him.
##
## **The one pin that does not hold with frames lengthened** (`--frame-delay`): `BadgeModel` reads
## how fast he closes as his step over the frame's own delta, so on a frame several ticks long the
## first running frame's closing speed is under the badge's threshold and the badge comes up a
## frame late. The run is therefore taken at the engine's own rate from just before he runs.
func _test_the_edge_badge_points_at_the_masked_man_from_his_run(t: Node) -> void:
	for walk: Array in _SECOND_FLIGHT_TURNS:
		for pace: String in ["walk", "run", "walk-run"]:
			var met := await _meet_the_masked_man(t, walk, pace, true)
			t.check(met["ran"] and int(met["unseen_frames"]) > 0,
					"%s at a %s: he runs while she cannot see him" % [walk[3], pace])
			t.check(int(met["badge_first"]) == 0 and int(met["badge_dropped"]) == 0,
					"%s at a %s: the edge badge points at him from the frame he runs, and stays up "
					% [walk[3], pace] + "until he is in view (first up %d frames in, down on %d of %d)"
					% [met["badge_first"], met["badge_dropped"], met["unseen_frames"]])

## **The same checks with the camera interpolated, as the game runs it, from many places in the
## physics tick.** The case starts after a pause of a different length each time (seeded, so the
## list is the same every run) and a process frame, which fixes the interpolation fraction the
## camera's view is shifted by: the fraction the game's frames take every value of, and the one a
## slower machine took when the stairwell checks failed once on identical code. The badge must not
## depend on it. **A probabilistic extra, not the regression check** (that is `test_badge_model`'s
## deterministic case of this shape; the interior guard's own sensitivity is probabilistic: with the
## charger reset taken out, at an earlier head with the old 0.8 s timer, it failed in 2 of 3 review runs):
## it exercises the game's own interpolated camera. Walk pace is the case that failed (the masked man sets off while she is still
## walking, from inside the out-of-sight margin band).
func _test_the_edge_badge_does_not_depend_on_when_in_the_physics_tick_she_starts(t: Node) -> void:
	var pauses_ms := [0, 7, 13, 19, 29, 37, 43, 53, 61, 71, 83]
	var worst := 0
	var failures := 0
	var seen_fractions := {}
	for walk: Array in _SECOND_FLIGHT_TURNS:
		for pause: int in pauses_ms:
			OS.delay_msec(pause)
			await t.get_tree().process_frame
			seen_fractions[snappedf(Engine.get_physics_interpolation_fraction(), 0.1)] = true
			var met := await _meet_the_masked_man(t, walk, "walk", true, true)
			var ok: bool = int(met["badge_first"]) == 0 and int(met["badge_dropped"]) == 0 \
					and int(met["unseen_frames"]) > 0
			if not ok:
				failures += 1
				worst = maxi(worst, int(met["badge_dropped"]))
	t.check(failures == 0,
			"interpolated, from %d starts spread over the tick, the edge badge is up from the frame he runs until he is in view (%d failed, up to %d frames down)"
			% [pauses_ms.size() * _SECOND_FLIGHT_TURNS.size(), failures, worst])
	t.check(seen_fractions.size() >= 3,
			"and those starts really took different interpolation fractions (%d distinct tenths)"
			% seen_fractions.size())

## How near the masked man comes to her centre, on the tick, on the tightest runner's line (row 11,
## walking until he runs, then running): the margin `_test_she_has_to_run_to_the_first_floor_door`
## pins outside his catch (`EventCatalogue.MASKED_PURSUER_CATCH`), measured on the escape as built.
## It is 36.4 on her real `move_and_slide()`, which slides her velocity along the walls she
## touches; the rig that stepped her by hand applied the unslid velocity, and measured 24.6.
const _TIGHTEST_RUNNER_CLOSEST := 36.4

## The lines onto the second flight, local to the grammar: the row of her turn, what she holds
## there, whether a walker is caught, and what to call it.
const _SECOND_FLIGHT_TURNS := [
	[10, ["move_left"], true, "plain left from row 10 (level with the flight's head tread)"],
	[11, ["move_left"], true, "plain left from row 11 (the row below it)"],
	[9, ["move_left", "move_down"], true, "down-left from row 9 (the landing tile between the two flights)"],
	[9, ["move_left"], false, "plain left from row 9 (the landing tile between the two flights)"],
]

## One meeting with the right shaft's masked man: her real body from the shaft's second-floor door
## down the landing to `walk`'s row, then holding its keys, walking (`pace` "walk"), running all the
## way ("run"), walking until he runs and running from then on with the keys she already holds, the
## turn coming at its row ("walk-run"), or starting to run 16 ticks after he does ("run-late"); once he runs she
## makes for the first floor's door. Answers whether he ran, the outcome ("through", "caught" or
## "neither") and how near he came.
func _meet_the_masked_man(t: Node, walk: Array, pace: String, badge := false,
		interpolated := false) -> Dictionary:
	# The game's own 30Hz ticks, taken eight times as often as the engine would (`pass_ticks_faster()`),
	# a tick's step the same.
	const MAX_TICKS := 600
	const WALK_PACE := 8
	# She starts running this many ticks after he does ("run-late"), a little over half a second.
	# On real ticks the line is caught from 13 ticks on, every start to 30 ticks tried; at 11 she
	# is caught, at 12 she gets through by 1.4px, and below that she gets through. Three ticks past
	# the first start from which every later one is caught keeps the pin off that ragged edge.
	const RUN_LATE_TICKS := 16
	# How far outside the distance he runs from the fast stretch of a badge case ends, px: a few
	# ticks of the two closing on each other.
	const BADGE_LEAD := 60.0
	var f := InteriorMap.build()
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var events := BuildingEvents.events_in(t, scene, rng, _rig.fresh_run())
	var man: EventInstance = null
	for instance in events.instances():
		if instance.def.id == "masked_pursuer":
			man = instance
	var origin: Vector2i = f.waypoints["stairwell_right"] - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
	var door: Vector2i = (f.doors["stairwell_right:landing_first"] as InteriorMapPlan.Door).tile
	var packed: PackedScene = load("res://scenes/player/stroller.tscn")
	var player: Stroller = packed.instantiate()
	player.carrying = true
	player.set_map(scene.map)
	scene.add_entity(player)
	events.use_player(player)
	player.global_position = scene.map.tile_to_world(
			(f.doors["stairwell_right:landing_second"] as InteriorMapPlan.Door).tile)
	if badge:
		# The badge cases start a row on, past the door: he is already warning, and the walk
		# from the door to here says nothing about the badge.
		player.global_position += Vector2(0, InteriorScene.TILE)
	player.velocity = Vector2.ZERO
	# **With `badge`, the screen-edge badge as the game raises it**: a real `DangerEdge` reading
	# these events and her, processing on the frames the engine gives it, and her real camera made
	# current and smoothing on the physics ticks, so the view it asks is the one the stairwell is
	# drawn from.
	var edge: DangerEdge = null
	var atlas: AtlasLibrary = null
	var camera: Camera2D = null
	if badge:
		camera = player.get_node("Camera2D") as Camera2D
		camera.make_current()
		# **Not interpolated, unless the case asks for the game's own.** With physics interpolation on
		# (`project.godot`) the camera's view centre is shifted by `Engine.get_physics_interpolation_fraction()`,
		# a wall-clock value fixed by when in a tick a frame happens to fall - up to a camera step,
		# tens of px - and where the stairwell lies against the view's edge decided the badge. Off,
		# the view is a function of the walk alone.
		if not interpolated:
			camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		camera.reset_smoothing()
		atlas = AtlasLibrary.new()
		atlas.acquire(&"events")
		edge = DangerEdge.new()
		edge.atlas = atlas
		edge.size = Vector2(1280.0, 720.0)
		t.add_child(edge)
		edge.setup(events, player)
	var badge_log := {"first": -1, "dropped": 0, "unseen": 0}
	var running := pace == "run"
	_hold_keys(["move_down"], running)
	var met := {"ran": false, "outcome": "neither", "closest": INF}
	var state := {"turned": false, "ran_at": 0, "running": running, "before": {}, "ticks": 0}
	# After each tick her step, the building's manager (which tells him where she is, steps him and
	# checks the catch) and her camera have run, in the tree's order; the edge has processed every
	# frame up to the one before this.
	var after_the_tick := func(_ticks: int) -> bool:
		state["ticks"] += 1
		var ticks: int = state["ticks"]
		var her := player.global_position
		var tile := scene.map.world_to_tile(her)
		# The catch is the tick's: where his step put him when the tick ran.
		var caught := man.is_lethal_at(her)
		if met["ran"]:
			met["closest"] = minf(met["closest"], man.global_position.distance_to(her))
		if edge:
			# The edge's last frame measured the previous tick's state, so that is what it is
			# counted against.
			if not (state["before"] as Dictionary).is_empty():
				_count_the_badge(edge, state["before"], badge_log)
			state["before"] = {"quiet": man.is_waiting() or man.is_telegraphing(),
					"shown": _in_sight(edge, man)}
		if not state["turned"] and tile.y - origin.y >= int(walk[0]) and her.y >= scene.map.tile_to_world(tile).y:
			state["turned"] = true
			_hold_keys(walk[1], state["running"])
		if not met["ran"] and not man.is_waiting() and not man.is_telegraphing():
			met["ran"] = true
			state["ran_at"] = ticks
			if pace == "walk-run":
				# Runs with the keys she already holds; the turn comes at its row.
				state["running"] = true
				_hold_keys(walk[1] if state["turned"] else ["move_down"], true)
		if pace == "run-late" and met["ran"] and not state["running"] \
				and ticks - state["ran_at"] >= RUN_LATE_TICKS:
			state["running"] = true
			_hold_keys(walk[1] if state["turned"] else ["move_down"], true)
		if caught:
			met["outcome"] = "caught"
			return true
		if tile == door:
			met["outcome"] = "through"
			return true
		# On the first floor's landing, up into its door.
		if met["ran"] and tile.x == origin.x + 1 and tile.y - origin.y >= 16:
			_hold_keys(["move_up"], state["running"])
		# **The badge is measured on frames of the game's own length.** Its model reads how fast he
		# closes from his step over the frame's delta, which `Engine.time_scale` stretches, so the
		# walk up to his warning is taken fast and the run itself at the engine's own rate, where a
		# frame is shorter than a tick. It ends when his badge has done its job.
		if badge and state["fast"] and (met["ran"] or man.global_position.distance_to(her)
				<= man.def.notice.runs_within + BADGE_LEAD):
			state["fast"] = false
			return true
		return badge and badge_log.get("done", false)
	if man != null:
		state["fast"] = badge
		if badge:
			await PhysicsTicks.pass_ticks_faster(t, MAX_TICKS, WALK_PACE, after_the_tick)
			if state["fast"] == false and met["outcome"] == "neither" and not badge_log.get("done", false):
				await PhysicsTicks.pass_ticks(t, MAX_TICKS - int(state["ticks"]), after_the_tick)
		else:
			await PhysicsTicks.pass_ticks_faster(t, MAX_TICKS, WALK_PACE, after_the_tick)
	_hold_keys([], false)
	met["badge_first"] = badge_log["first"]
	met["badge_dropped"] = badge_log["dropped"]
	met["unseen_frames"] = badge_log["unseen"]
	if edge:
		edge.free()
		atlas.release(&"events")
	player.free()
	events.free()
	scene.free()
	return met

## Whether she can see any of `man`: the point he stands at, or any of what he draws, asked of the
## edge's own view (`DangerEdge.sees()`, and `VisibleView.sees_any()` on the drawn box
## `EventInstance.drawn_box()`).
func _in_sight(edge: DangerEdge, man: EventInstance) -> bool:
	if edge.sees(man.global_position):
		return true
	var box := man.drawn_box()
	return box.has_area() and edge.view().sees_any(Rect2(man.global_position + box.position, box.size))

## One drawn frame of the edge watching him (`_meet_the_masked_man()` with `badge`), counted against
## `then`, what the tick the frame measured held (`quiet`: he is still waiting or warning; `shown`:
## she can see him): on every frame from the one he is first running on while she cannot see him,
## whether his badge is up, the first such frame it is, and the frames it is down after it first
## went up.
func _count_the_badge(edge: DangerEdge, then: Dictionary, log: Dictionary) -> void:
	if then["quiet"]:
		return
	if then["shown"]:
		# His badge has done its job the first time he is in sight after it went up; if he leaves
		# sight again it is raised anew, past the margin band, and that is not this check.
		if int(log["first"]) >= 0:
			log["done"] = true
		return
	if log.get("done", false):
		return
	var up := false
	for b: Dictionary in edge.announcing():
		up = up or b["id"] == "masked_pursuer"
	if up and int(log["first"]) < 0:
		log["first"] = log["unseen"]
	elif not up and int(log["first"]) >= 0:
		log["dropped"] = int(log["dropped"]) + 1
	log["unseen"] = int(log["unseen"]) + 1

func _hold_keys(actions: Array, running: bool) -> void:
	for a in ["move_left", "move_right", "move_up", "move_down", "run"]:
		Input.action_release(a)
	for a: String in actions:
		Input.action_press(a)
	if running:
		Input.action_press("run")

## *"Then the pursuing guy should respawn forcing to switch the side again."*
##
## Driven by the building's `EventManager` on real physics ticks, with her standing on the lobby's door at the shaft's
## foot for the whole run — off his line, clear of his reach, and inside
## `masked_pursuer.notice.runs_within` of where each man appears, so every man that appears
## notices her, warns her and runs rather than waiting at the bottom for ever.
##
## Three contracts, and the second is what keeps the first fair:
##
## - **More than one of him over a section**, or "switch the side again" has nothing behind it.
## - **Every one of them warns her standing still before he runs.** Appearing with her already
##   inside his charge distance, he warns for `Tuning.WARNING_ALONE_MAX` first
##   (`EventNoticeRun`); a respawned pursuer that inherited an old instance's
##   state would arrive at speed, which is the exact thing `still_while_telegraphing` exists to
##   prevent, and no screenshot could ever catch it.
## - **The gap is the stated one**, measured from him leaving the top of the shaft to the next one
##   appearing at the foot, rather than read off the constant.
func _test_another_masked_man_comes_up_the_same_shaft(t: Node) -> void:
	const STEP := 1.0 / 30.0
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var events := BuildingEvents.events_in(t, scene, rng, _rig.fresh_run())
	var part := "stairwell_%s" % ("right" if BuildingPlan.BURNING_SIDE == "left" else "left")
	var plan := InteriorMap.build()
	var her := scene.map.tile_to_world((plan.doors["%s:landing_lobby" % part] as InteriorMapPlan.Door).tile)
	# A stand-in for her: the manager is handed where she stands and tells every instance each tick.
	var player := Node2D.new()
	player.add_to_group("player")
	t.add_child(player)
	player.global_position = her
	events.use_player(player)

	var appeared: Array[float] = []
	var left: Array[float] = []
	var known := {}
	var moved_while_telegraphing := 0
	var first_step_age: Array[float] = []
	# The age each man stopped waiting at: his warning's own start, since his notice clock is held.
	var warned_at: Array[float] = []
	# After each real tick of the manager (the game's 30Hz, taken eight times as often as the
	# engine would): where each stood going in is where it stood when the last tick ended.
	var stood := {}
	var was_leaving_by_id := {}
	var after_the_tick := func(ticks: int) -> bool:
		var at := (ticks - 1) * STEP
		for instance in events.instances():
			if instance.def.id != "masked_pursuer":
				continue
			var id := instance.get_instance_id()
			if not known.has(id):
				known[id] = appeared.size()
				appeared.append(at)
				first_step_age.append(-1.0)
				warned_at.append(INF)
			# One his row's repeat made on this tick, ahead of the step, has taken his first step
			# from the foot of his line.
			var before: Vector2 = stood.get(id, instance.path[0])
			var was_leaving: bool = was_leaving_by_id.get(id, false)
			var which: int = known[id]
			if warned_at[which] == INF and not instance.is_waiting():
				warned_at[which] = instance.age
			if not before.is_equal_approx(instance.global_position):
				if instance.is_telegraphing():
					moved_while_telegraphing += 1
				if first_step_age[which] < 0.0:
					first_step_age[which] = instance.age - warned_at[which]
			if instance.is_leaving and not was_leaving:
				left.append(at)
		stood.clear()
		was_leaving_by_id.clear()
		for instance in events.instances():
			stood[instance.get_instance_id()] = instance.global_position
			was_leaving_by_id[instance.get_instance_id()] = instance.is_leaving
		return false
	await PhysicsTicks.pass_ticks_faster(t, ceili(RunConfig.FINALE_LENGTH_SECONDS / STEP), 8,
			after_the_tick)
	player.free()
	t.check(appeared.size() >= 3,
			"more than one masked man comes up the shaft over a section (%d)" % appeared.size())
	t.check(moved_while_telegraphing == 0,
			"and none of them moves while he is giving notice (%d frames)" % moved_while_telegraphing)
	var notices := 0
	for i in first_step_age.size():
		if first_step_age[i] < 0.0:
			continue
		notices += 1
		t.check(first_step_age[i] >= Tuning.WARNING_ALONE_MAX - STEP,
				"man %d took his first step %.2fs into his warning, after the second it owes"
				% [i, first_step_age[i]])
	t.check(notices >= 2, "at least two of them actually ran (%d)" % notices)
	var gaps := 0
	for i in range(1, appeared.size()):
		if i - 1 >= left.size():
			break
		gaps += 1
		var gap: float = appeared[i] - left[i - 1]
		t.check(absf(gap - EventCatalogue.FINALE_PURSUER_RESPAWN_SECONDS) <= STEP * 3.0,
				"the next man comes %.2fs after the last one ran out of the top, against %.2fs"
				% [gap, EventCatalogue.FINALE_PURSUER_RESPAWN_SECONDS])
	t.check(gaps > 0, "there were gaps between his runs to measure (%d)" % gaps)
	print("The masked man came %d times in %.0fs; gaps measured: %d"
			% [appeared.size(), RunConfig.FINALE_LENGTH_SECONDS, gaps])
	events.free()
	scene.free()
