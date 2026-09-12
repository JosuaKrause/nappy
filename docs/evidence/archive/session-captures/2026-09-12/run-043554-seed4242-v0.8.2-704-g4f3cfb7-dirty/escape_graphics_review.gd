extends Node
## A bounded visual inspection of the live apartment at its normal camera scale.

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("A display is required for the apartment review.")
		get_tree().quit(1)
		return
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var interior: Node = main.get("_interior")
	var player: Node2D = main.get("_player")
	if interior == null or player == null:
		push_error("The apartment review requires --start-escape.")
		get_tree().quit(1)
		return
	player.set_physics_process(false)
	main.set_process(false)
	var output := "/private/tmp/escape-graphics-review"
	DirAccess.make_dir_recursive_absolute(output)
	var parts: Array[String] = ["hallway_third", "hallway_second", "hallway_first",
		"stairwell_left", "stairwell_right", "lobby", "basement"]
	for part in parts:
		var at: Vector2 = interior.call("part_world_position", part)
		await _capture(player, at, output.path_join(part + ".png"))
	for side in ["left", "right"]:
		var at: Vector2 = interior.call("part_world_position", "stairwell_" + side)
		await _capture(player, at + Vector2(96, 96), output.path_join(side + "-east-flight.png"))
		await _capture(player, at + Vector2(64, 192), output.path_join(side + "-west-flight.png"))
		await _capture(player, at + Vector2(0, 256), output.path_join(side + "-second-landing.png"))
		await _capture(player, at + Vector2(0, 768), output.path_join(side + "-bottom-landing.png"))
	var basement: Vector2 = interior.call("part_world_position", "basement")
	await _capture(player, basement + Vector2(64, -192), output.path_join("basement-middle.png"))
	await _capture(player, basement + Vector2(-32, -384), output.path_join("basement-exit.png"))
	main.set_process(true)
	player.set_physics_process(true)
	for side in ["left", "right"]:
		var top: Vector2 = interior.call("part_world_position", "stairwell_" + side)
		player.call("reset_at", top + Vector2(32, 32), Vector2(1, 1).normalized())
		await get_tree().create_timer(0.15).timeout
		main.call("_start_burst")
		var targets: Array[Vector2] = [Vector2(64, 64), Vector2(96, 96), Vector2(128, 128),
			Vector2(96, 160), Vector2(64, 192), Vector2(32, 224), Vector2(0, 256)]
		for target in targets:
			if not await _walk_to(player, top + target):
				get_tree().quit(1)
				return
		_release_walk()
		print("Physical stair walk reached ", side, " second landing at ", player.global_position)
		await get_tree().create_timer(0.5).timeout
	print("Apartment runtime review: ", output)
	get_tree().quit()

func _release_walk() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)

func _walk_to(player: Node2D, target: Vector2) -> bool:
	var deadline := Time.get_ticks_msec() + 2500
	while player.global_position.distance_to(target) > 4.0:
		if Time.get_ticks_msec() > deadline:
			_release_walk()
			push_error("Physical stair walk stalled at %s before %s" % [player.global_position, target])
			return false
		var direction := player.global_position.direction_to(target)
		_release_walk()
		Input.action_press("move_right" if direction.x > 0.0 else "move_left", absf(direction.x))
		Input.action_press("move_down" if direction.y > 0.0 else "move_up", absf(direction.y))
		await get_tree().physics_frame
	return true

func _capture(player: Node2D, at: Vector2, destination: String) -> void:
	player.call("reset_at", at, Vector2.DOWN)
	await get_tree().create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var rendered := get_viewport().get_texture().get_image()
	var result := rendered.save_png(destination)
	if result != OK:
		push_error("Could not save " + destination)
		get_tree().quit(1)
	print("Captured ", destination)
