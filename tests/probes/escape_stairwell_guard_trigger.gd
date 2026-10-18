extends RefCounted
## Measurement probe for the stairwell guard's trigger (inbox #782): where in the right shaft the
## masked man starts his run, by the route she takes to the first floor, and whether she then gets
## out through the first floor's door. Not a suite: it prints rather than asserts. Run by name:
##
##     tools/test.sh probes/escape_stairwell_guard_trigger.gd
##
## Her real carrying body walks (or runs) the second flight with the real stair steering and
## collision, and the real man is driven by `InteriorEvents._physics_process()`, which tells him
## where she is and starts his run on the first-floor landing, and his own `_process()`. A line is
## `TRIGGER seed <s> <route> <pace> charged at <local px> (<tile>) <d>px from him, <outcome> ...`.
## The routes:
##
## - `flight-mid`: held left from the second-floor landing tile level with the flight's head, the
##   line most of a walk down it takes;
## - `flight-high`: down-left from the landing tile between the two flights, the band's upper edge;
## - `flight-low`: held left from the landing's last row, slid onto the band's lower edge;
## - `door`: in from the first floor's hallway, stepping down the landing from its door.
##
## Once he runs she makes for the first floor's door: down (or along) to the landing, then up into
## the door. `late <s>` instead walks on down the landing and onto his flight for that many seconds
## after he starts, as a player who has not yet looked would, and then runs back up to the door.

const STEP := 1.0 / 60.0
## Three, since every run steps hundreds of frames with no frame between them to flush the redraws
## they queue, and about sixty runs fill the engine's message queue.
const SEEDS := [4242, 4216201080, 2026]

func run(t) -> void:
	for s: int in SEEDS:
		for route in ["flight-mid", "flight-high", "flight-low", "door"]:
			for pace in ["walk", "run"]:
				_once(t, s, route, pace, -1.0)
		for late in [0.5, 1.0, 1.5, 2.0]:
			_once(t, s, "door", "walk", late)
			_once(t, s, "flight-mid", "walk", late)

func _once(t, s: int, route: String, pace: String, late: float) -> void:
	var f := InteriorMap.build()
	var scene := InteriorScene.new()
	t.add_child(scene)
	var events := InteriorEvents.new()
	t.add_child(events)
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	events.setup(scene, rng)
	var man: EventInstance = null
	for instance in events.instances():
		if instance.def.id == "masked_pursuer":
			man = instance
	# `TRIGGER_RADIUS=<px>` in the environment measures the alternative to the landing: no landing,
	# and his row's own charge distance set to that many pixels, on this run alone.
	if OS.get_environment("TRIGGER_RADIUS") != "":
		man.def.charges_within = float(OS.get_environment("TRIGGER_RADIUS"))
		events._first_floor_landing.clear()
	var origin: Vector2i = f.waypoints["stairwell_right"] - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
	var door_tile: Vector2i = (f.doors["stairwell_right:landing_first"] as InteriorMapPlan.Door).tile
	var packed: PackedScene = load("res://scenes/player/stroller.tscn")
	var player: Stroller = packed.instantiate()
	player.carrying = true
	player.slope_dir_at = scene.slope_dir_at
	scene.add_entity(player)
	player.set_physics_process(false)
	var start := {"flight-mid": Vector2i(8, 10), "flight-high": Vector2i(8, 9),
			"flight-low": Vector2i(8, 11), "door": Vector2i(1, 15)}[route] as Vector2i
	var keys := {"flight-mid": ["move_left"], "flight-high": ["move_left", "move_down"],
			"flight-low": ["move_left"], "door": ["move_down"]}[route] as Array
	player.global_position = scene.tile_to_world(origin + start)
	player.velocity = Vector2.ZERO
	_hold(keys, pace == "run")
	var charged_at := Vector2.INF
	var charged_range := 0.0
	var phase := "approach"
	var outcome := "neither"
	var closest := INF
	var elapsed := 0.0
	var charged_for := 0.0
	# The door route starts on the door it came in by, which counts only once she has left it.
	var left_the_door := route != "door"
	while elapsed < 20.0:
		player._physics_process(STEP)
		_move(player, player.velocity * STEP)
		var her := player.global_position
		var tile := scene.world_to_tile(her)
		# `InteriorEvents` hands him where she is and starts his run on the landing; his own
		# `_process()` is the frame the running game gives him.
		events._physics_process(STEP)
		man.player_running = pace == "run" or phase == "back"
		man._process(STEP)
		elapsed += STEP
		if charged_at == Vector2.INF and not man.is_waiting() and not man.is_telegraphing():
			charged_at = her
			charged_range = man.global_position.distance_to(her)
			phase = "down" if late >= 0.0 else "out"
		if charged_at != Vector2.INF:
			closest = minf(closest, man.global_position.distance_to(her))
			charged_for += STEP
		if man.is_lethal_at(her):
			outcome = "caught"
			break
		if tile != door_tile:
			left_the_door = true
		elif left_the_door:
			outcome = "through the door"
			break
		var on_landing := tile.x == origin.x + 1 and scene.slope_dir_at(her) == 0
		if phase == "out" and on_landing:
			_hold(["move_up"], true if pace == "run" else false)
		elif phase == "down":
			# On down: the second flight descends to the left, the landing straight down, his flight
			# to the right.
			if on_landing:
				_hold(["move_down"], false)
			elif tile.y - origin.y <= 16:
				_hold(["move_left"], false)
			else:
				_hold(["move_right"], false)
			if charged_for >= late:
				phase = "back"
				_hold(["move_left"], true)
		elif phase == "back" and on_landing:
			_hold(["move_up"], true)
	_hold([], false)
	var local := charged_at - scene.tile_to_world(origin) + Vector2.ONE * InteriorScene.TILE * 0.5
	print("TRIGGER seed %d %s %s%s charged at %s (%s) %.0fpx from him, %s at %.2fs, closest %.0fpx"
			% [s, route, pace, (" late %.1fs" % late) if late >= 0.0 else "",
			(local / InteriorScene.TILE).snapped(Vector2(0.01, 0.01)),
			scene.world_to_tile(charged_at) - origin, charged_range, outcome, elapsed, closest])
	player.free()
	events.free()
	scene.free()

func _hold(actions: Array, running: bool) -> void:
	for a in ["move_left", "move_right", "move_up", "move_down", "run"]:
		Input.action_release(a)
	for a: String in actions:
		Input.action_press(a)
	if running:
		Input.action_press("run")

func _move(player: CharacterBody2D, motion: Vector2) -> void:
	var collision := player.move_and_collide(motion)
	var slides := 0
	while collision != null and slides < player.max_slides:
		motion = collision.get_remainder().slide(collision.get_normal())
		if motion.is_zero_approx():
			return
		collision = player.move_and_collide(motion)
		slides += 1
