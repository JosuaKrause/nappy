extends RefCounted
## Measurement probe for the escape's stairs (inbox #783): every walkable tile of both stairwells,
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
	player.slope_dir_at = scene.slope_dir_at
	scene.add_entity(player)
	player.set_physics_process(false)
	for side in ["left", "right"]:
		for tile: Vector2i in scene.stairwell_tiles("stairwell_%s" % side):
			var kind: InteriorTile.Kind = f.tiles[tile]
			if not InteriorTile.is_walkable(kind) or kind == InteriorTile.Kind.DOOR:
				continue
			for name: String in INPUTS:
				var v: Array = INPUTS[name]
				var heading := _walk(scene, player, tile, Vector2(v[0], v[1]))
				print("STAIRS %s %s %s %s steer %s moved %s" % [
						side, InteriorTile.Kind.keys()[kind], tile, name,
						_deg(heading[0]), _deg(heading[1])])
	player.free()
	scene.free()

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
	player.global_position = scene.tile_to_world(tile)
	player.velocity = Vector2.ZERO
	var steer := Vector2.ZERO
	for i in STEPS:
		player._physics_process(STEP)
		if i == 0:
			steer = player.steering
		_move(player, player.velocity * STEP)
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	return [steer, player.global_position - scene.tile_to_world(tile)]

func _move(player: CharacterBody2D, motion: Vector2) -> void:
	var collision := player.move_and_collide(motion)
	var slides := 0
	while collision != null and slides < player.max_slides:
		motion = collision.get_remainder().slide(collision.get_normal())
		if motion.is_zero_approx():
			return
		collision = player.move_and_collide(motion)
		slides += 1
