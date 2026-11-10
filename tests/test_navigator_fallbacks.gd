@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## **A crowd handed no navigator moves by its map's own** (`Crowd.setup()`, `WorldMap.navigator()`):
## the game's city hands its crowd the city's navigator, and a rig that hands none gets the map's,
## over which a walker she bumps into is pushed aside. No city: the crowd is handed a bare world, a
## map with nothing but its streets (`StreetMap.full()`), the lights over that map and today's
## streets with no day begun (`DayStreets.new()`), so no wall and no door holds anybody.

const STROLLER_SCENE := preload("res://scenes/player/stroller.tscn")
const SEED := 4242
const DAY := 1
## Real physics frames the push is given: one is enough for the crowd's tick to meet her; a few more
## let a push that went nowhere show as a walker still on his lane.
const FRAMES := 6

func run(t) -> void:
	await _test_a_crowd_handed_no_navigator_pushes_a_walker_aside(t)

func _test_a_crowd_handed_no_navigator_pushes_a_walker_aside(t) -> void:
	var world := WorldContext.new()
	t.add_child(world)
	var map := StreetMap.full()
	var crowd := Crowd.new()
	crowd.name = "Crowd"
	world.add_child(crowd)
	# The rig's shape: the crowd is handed its world, map, lights and streets and no navigator.
	crowd.setup(world, map, TrafficSignals.new(map), DayStreets.new())
	var her_tile := _open_sidewalk(map)
	t.check(her_tile != Vector2i(-1, -1), "the map has open sidewalk to stand her on")
	if her_tile == Vector2i(-1, -1):
		world.free()
		return
	var here := map.tile_to_world(her_tile)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	crowd.start_day(DAY, rng, here, false)
	var placed := _walker_on_a_lane_at(crowd, here)
	t.check(placed.get("error", "") == "", "a walker stands on a lane of her sidewalk: %s"
			% placed.get("error", ""))
	var player: Stroller = STROLLER_SCENE.instantiate()
	t.add_child(player)
	crowd.use_player(player)
	if placed.get("error", "") == "":
		var walker: CrowdAgent = placed.actor
		# She stands a few pixels off him and a little ahead on his way, inside the crowd's bump
		# radius, so he walks on toward her and is not walking clear of her himself.
		var heading := walker.heading()
		var sideways := Vector2(heading.y, heading.x)
		var start := walker.global_position
		player.global_position = start + heading * 3.0 + sideways * 3.0
		# The push the crowd gives him on the frame it meets her: the overlap to the radius it
		# clears him to, less her own share of the separation (`Crowd._bump()`).
		var push := (Tuning.BUMP_CLEAR_RADIUS - start.distance_to(player.global_position)) \
				* (1.0 - Crowd.BUMP_PLAYER_SHARE)
		var first_frame := 0.0
		var on_the_map := true
		for frame in FRAMES:
			await t.get_tree().physics_frame
			if frame == 0:
				first_frame = absf((walker.global_position - start).dot(sideways))
			on_the_map = on_the_map and map.is_walkable(map.world_to_tile(walker.global_position))
		# He side-steps on his own too, but gradually (a few pixels a frame): what he has moved off
		# his lane by the end of the first frame is more than that only if the push moved him.
		t.check(first_frame > push * 0.5 and on_the_map,
				"the walker walking at her is pushed off his lane over the map's ground "
				+ "(%.1fpx aside on the first frame, a push of %.1fpx)" % [first_frame, push])
	player.free()
	world.free()

## A walker placed through the crowd's own entry (`Crowd.add_recipe_actor()`) on the lane centre
## nearest `here`, heading along either axis, at a pace drawn from his kind's (`-1.0`), which is the
## first the entry accepts.
func _walker_on_a_lane_at(crowd: Crowd, here: Vector2) -> Dictionary:
	var placed := {"error": "no lane centre on the tile"}
	for heading: Vector2 in [Vector2.DOWN, Vector2.RIGHT]:
		var across := Vector2(heading.y, heading.x)
		for offset in range(-48, 49):
			placed = crowd.add_recipe_actor("pushed", CrowdAgent.Kind.WALKER,
					here + across * offset, heading, -1.0, 7)
			if placed.get("error", "") == "":
				return placed
	return placed

## A sidewalk tile clear of the map's edge with open sidewalk all round it, so a push has somewhere
## to go.
func _open_sidewalk(map: CityMap) -> Vector2i:
	for tile in map.tiles_of_type(GameEnums.TileType.SIDEWALK):
		if tile.x < 4 or tile.y < 4 or tile.x >= map.size.x - 4 or tile.y >= map.size.y - 4:
			continue
		var open := true
		for step: Vector2i in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var near := tile + step
			if map.tile_at(near) != GameEnums.TileType.SIDEWALK or not map.is_open(near) \
					or map.is_obstructed(near):
				open = false
				break
		if open:
			return tile
	return Vector2i(-1, -1)
