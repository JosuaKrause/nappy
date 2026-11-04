extends RefCounted
## Measurement probe for the escape's stairs (inbox #783 in minty-lemur): every walkable tile of both stairwells,
## each of eight directions and an analog diagonal pressed through the real `Stroller` physics step,
## and the heading she steers and the way she actually moves in a tenth of a second. Not a suite: it
## prints rather than asserts. Run by name:
##
##     tools/test.sh probes/escape_stairs_heading.gd      (prints STAIRS lines)
##
## A line is `STAIRS <side> <role> <tile> <input> steer <degrees> moved <degrees>`; a heading is in
## degrees clockwise from east with screen-down positive, so 45 is down-right and -135 is up-left.
## `tests/test_interior.gd` pins what this prints.

const STEP := 1.0 / 60.0
const STEPS := 6
const INPUTS := {
	"right": [1.0, 0.0], "left": [-1.0, 0.0], "up": [0.0, -1.0], "down": [0.0, 1.0],
	"up-right": [1.0, -1.0], "down-right": [1.0, 1.0], "up-left": [-1.0, -1.0],
	"down-left": [-1.0, 1.0], "analog right-up": [0.9, -0.3],
}

func run(t) -> void:
	var scene := InteriorScene.new()
	t.add_child(scene)
	scene.build()
	var f := InteriorMap.build()
	var packed: PackedScene = load("res://scenes/player/stroller.tscn")
	var player: Stroller = packed.instantiate()
	player.carrying = true
	player.set_map(scene.map)
	scene.add_entity(player)
	player.set_physics_process(false)
	for side in ["left", "right"]:
		for tile: Vector2i in scene.map.stairwell_tiles("stairwell_%s" % side):
			var kind: InteriorTile.Kind = f.tiles[tile]
			if not InteriorTile.is_walkable(kind) or kind == InteriorTile.Kind.DOOR:
				continue
			for name: String in INPUTS:
				var v: Array = INPUTS[name]
				var heading := _walk(scene, player, tile, Vector2(v[0], v[1]))
				print("STAIRS %s %s %s %s steer %s moved %s" % [
						side, InteriorTile.Kind.keys()[kind], tile, name,
						_deg(heading[0]), _deg(heading[1])])
	_walk_flights(scene, player)
	player.free()
	scene.free()

## Every flight of both shafts, down and up, held from one landing's approach until she stands on
## the next: the body's heading over each tenth of a second of the walk, and the largest departure
## from the flight's 45 degrees while she is on a flight tile. A line is `WALK <side> <flight>
## <down|up|down-2nd|up-2nd> <from> -> <to> (ended <tile>) steps <n> worst <degrees> headings
## <list>`; `-2nd` starts on the landing's next row down. The left shaft's first flight walked down
## from the top landing also prints `TRACE <step> <x> <y>`, her centre each frame in pixels from
## the landing tile's centre.
const FLIGHTS := [
	# [name, local start (the landing approach above), local end (the one below), down action]
	["first", Vector2i(1, 2), Vector2i(8, 8), "move_right"],
	["second", Vector2i(8, 10), Vector2i(1, 16), "move_left"],
	["third", Vector2i(1, 18), Vector2i(8, 24), "move_right"],
]

func _walk_flights(scene: InteriorScene, player: Stroller) -> void:
	var f := InteriorMap.build()
	for side in ["left", "right"]:
		var origin: Vector2i = f.waypoints["stairwell_%s" % side] - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
		for flight: Array in FLIGHTS:
			var down: String = flight[3]
			var up := "move_left" if down == "move_right" else "move_right"
			_walk_one(scene, player, side, flight[0], "down", origin + flight[1], origin + flight[2], down)
			_walk_one(scene, player, side, flight[0], "up", origin + flight[2], origin + flight[1], up)
			# And from each landing's second row, a tile below the flight's first or last tread.
			_walk_one(scene, player, side, flight[0], "down-2nd", origin + flight[1] + Vector2i.DOWN,
					origin + flight[2], down)
			_walk_one(scene, player, side, flight[0], "up-2nd", origin + flight[2] + Vector2i.DOWN,
					origin + flight[1], up)

func _walk_one(scene: InteriorScene, player: Stroller, side: String, flight: String, way: String,
		from: Vector2i, to: Vector2i, action: String) -> void:
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)
	Input.action_press(action)
	player.global_position = scene.map.tile_to_world(from)
	player.velocity = Vector2.ZERO
	var headings: Array[String] = []
	var worst := 0.0
	var last := player.global_position
	var steps := 0
	# Arrived once she stands on the next landing's column, whichever of its rows.
	while steps < 900 and not (scene.map.world_to_tile(player.global_position).x == to.x
			and scene.map.slope_dir_at(player.global_position) == 0):
		player._physics_process(STEP)
		_move(player, player.velocity * STEP)
		steps += 1
		# Her centre every frame on one walk, for a picture of the path rather than its headings.
		if side == "left" and flight == "first" and way == "down":
			var at := player.global_position - scene.map.tile_to_world(from)
			print("TRACE %d %.2f %.2f" % [steps, at.x, at.y])
		if steps % 6 == 0:
			var moved := player.global_position - last
			headings.append(_deg(moved))
			var on_flight := scene.map.slope_dir_at(last) != 0 and scene.map.slope_dir_at(player.global_position) != 0
			if on_flight and moved.length() > 0.5:
				var off := absf(rad_to_deg(absf(moved.angle())) - 90.0)
				worst = maxf(worst, absf(off - 45.0))
			last = player.global_position
	Input.action_release(action)
	print("WALK %s %s %s %s -> %s (ended %s) steps %d worst %.1f headings %s" % [side, flight, way,
			from, to, scene.map.world_to_tile(player.global_position), steps, worst, " ".join(headings)])

func _deg(v: Vector2) -> String:
	if v.length() < 0.001:
		return "none"
	return str(snappedf(rad_to_deg(v.angle()), 1.0))

## Steering and displacement after a tenth of a second from rest at `tile`'s centre.
func _walk(scene: InteriorScene, player: Stroller, tile: Vector2i, press: Vector2) -> Array:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	if press.x < 0.0:
		Input.action_press("move_left", absf(press.x))
	elif press.x > 0.0:
		Input.action_press("move_right", absf(press.x))
	if press.y < 0.0:
		Input.action_press("move_up", absf(press.y))
	elif press.y > 0.0:
		Input.action_press("move_down", absf(press.y))
	player.global_position = scene.map.tile_to_world(tile)
	player.velocity = Vector2.ZERO
	var steer := Vector2.ZERO
	for i in STEPS:
		player._physics_process(STEP)
		if i == 0:
			steer = player.steering
		_move(player, player.velocity * STEP)
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	return [steer, player.global_position - scene.map.tile_to_world(tile)]

func _move(player: CharacterBody2D, motion: Vector2) -> void:
	var collision := player.move_and_collide(motion)
	var slides := 0
	while collision != null and slides < player.max_slides:
		motion = collision.get_remainder().slide(collision.get_normal())
		if motion.is_zero_approx():
			return
		collision = player.move_and_collide(motion)
		slides += 1
