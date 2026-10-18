extends RefCounted
## Measurement probe for the stairwell guard's charge distance (inbox #782, inbox #764): where in
## the right shaft the masked man starts his run, by the way she comes down to the first floor, and
## whether she then gets out through the first floor's door. Not a suite: it prints rather than
## asserts. Run by name:
##
##     tools/test.sh probes/escape_stairwell_guard_trigger.gd
##     CHARGES_WITHIN=420 tools/test.sh probes/escape_stairwell_guard_trigger.gd
##
## The second tries another charge distance for his row on that run alone. Her real carrying body
## walks with the real stair steering and collision, and the real man is driven by
## `InteriorEvents._physics_process()`, which tells him where she is, and his own `_process()`. A
## line is `TRIGGER seed <s> <route> <pace> charged at (<local tile units>) <d>px from him,
## <outcome> at <t>s, <a>s after he ran, closest <c>px`. The routes all start on the second floor's
## door of his shaft, the way in from the second floor's hallway:
##
## - `turn-10`, `turn-11`: down the landing, then left onto the second flight from that row of it
##   (10 is level with the flight's head tread, 11 below it);
## - `turn-9`: down the landing, then down-left from the landing tile between the two flights;
## - `door`: in from the first floor's hallway instead, stepping down the landing from its door.
##
## Paces: `walk` the whole way, `run` the whole way, and `walk-run`, walking until he runs and
## running from then on. Once he runs she makes for the first floor's door: on along the flight to
## the landing, then up into the door.

const STEP := 1.0 / 60.0
## Three, since every run steps hundreds of frames with no frame between them to flush the redraws
## they queue, and about sixty runs fill the engine's message queue.
const SEEDS := [4242, 4216201080, 2026]
const ROUTES := {
	"turn-10": [10, ["move_left"]],
	"turn-11": [11, ["move_left"]],
	"turn-9": [9, ["move_left", "move_down"]],
}

func run(t) -> void:
	for s: int in SEEDS:
		for route in ["turn-10", "turn-11", "turn-9", "door"]:
			for pace in ["walk", "run", "walk-run"]:
				_once(t, s, route, pace)

func _once(t, s: int, route: String, pace: String) -> void:
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
	if OS.get_environment("CHARGES_WITHIN") != "":
		man.def.charges_within = float(OS.get_environment("CHARGES_WITHIN"))
	var origin: Vector2i = f.waypoints["stairwell_right"] - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
	var door_tile: Vector2i = (f.doors["stairwell_right:landing_first"] as InteriorMapPlan.Door).tile
	var second_door: Vector2i = (f.doors["stairwell_right:landing_second"] as InteriorMapPlan.Door).tile
	var packed: PackedScene = load("res://scenes/player/stroller.tscn")
	var player: Stroller = packed.instantiate()
	player.carrying = true
	player.slope_dir_at = scene.slope_dir_at
	scene.add_entity(player)
	player.set_physics_process(false)
	var start := door_tile if route == "door" else second_door
	player.global_position = scene.tile_to_world(start)
	player.velocity = Vector2.ZERO
	var running := pace == "run"
	_hold(["move_down"], running)
	var turned := route == "door"
	var charged_at := Vector2.INF
	var charged_range := 0.0
	var outcome := "neither"
	var closest := INF
	var elapsed := 0.0
	var charged_for := 0.0
	var left_the_door := false
	while elapsed < 20.0:
		player._physics_process(STEP)
		_move(player, player.velocity * STEP)
		var her := player.global_position
		var tile := scene.world_to_tile(her)
		events._physics_process(STEP)
		man.player_running = running
		man._process(STEP)
		elapsed += STEP
		if not turned and tile.y - origin.y >= int(ROUTES[route][0]) \
				and her.y >= scene.tile_to_world(tile).y:
			turned = true
			_hold(ROUTES[route][1], running)
		if charged_at == Vector2.INF and not man.is_waiting() and not man.is_telegraphing():
			charged_at = her
			charged_range = man.global_position.distance_to(her)
			if pace == "walk-run":
				running = true
				_hold(ROUTES[route][1] if route != "door" else ["move_up"], true)
			elif route == "door":
				_hold(["move_up"], running)
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
		var on_landing := tile.x == origin.x + 1 and tile.y - origin.y >= 16 \
				and scene.slope_dir_at(her) == 0
		if charged_at != Vector2.INF and on_landing:
			_hold(["move_up"], running)
	_hold([], false)
	var local := charged_at - scene.tile_to_world(origin) + Vector2.ONE * InteriorScene.TILE * 0.5
	print("TRIGGER seed %d %s %s charged at %s %.0fpx from him, %s at %.2fs, %.2fs after he ran, closest %.0fpx"
			% [s, route, pace, (local / InteriorScene.TILE).snapped(Vector2(0.01, 0.01)),
			charged_range, outcome, elapsed, charged_for, closest])
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
