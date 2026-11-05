extends RefCounted
## One meeting with the escape's masked man, shared by the suites that walk her down the right shaft
## to meet him: `test_interior_masked_man.gd` and `test_interior_masked_man_badge.gd`.

const InteriorRig := preload("res://tests/interior_rig.gd")
const BuildingEvents := preload("res://tests/building_events.gd")

var _rig: InteriorRig

func _init(rig: InteriorRig) -> void:
	_rig = rig

## The lines onto the second flight, local to the grammar: the row of her turn, what she holds
## there, whether a walker is caught, and what to call it.
const TURNS := [
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
func meet(t: Node, walk: Array, pace: String, badge := false,
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

## One drawn frame of the edge watching him (`meet()` with `badge`), counted against
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
