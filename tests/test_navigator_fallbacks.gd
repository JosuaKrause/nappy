extends RefCounted
## **A crowd handed no navigator moves by its map's own** (`Crowd.setup()`, `WorldMap.navigator()`):
## the game's city hands its crowd the city's navigator, and a rig that hands none gets the map's,
## over which a walker she bumps into is pushed aside. The city here is built in a run of its
## own (`RunState.new()`), handed in as `main` hands the game's.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STROLLER_SCENE := preload("res://scenes/player/stroller.tscn")
const SEED := 4242
const DAY := 1
## Real physics frames the push is given: one is enough for the crowd's tick to meet her; a few more
## let a push that went nowhere show as a walker still on his lane.
const FRAMES := 6

func run(t) -> void:
	await _test_a_crowd_handed_no_navigator_pushes_a_walker_aside(t)

func _test_a_crowd_handed_no_navigator_pushes_a_walker_aside(t) -> void:
	var own_run := RunState.new()
	own_run.start_run(SEED)
	var city: City = CITY_SCENE.instantiate()
	city.run = own_run
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	var state := CityState.new()
	state.begin_day(city.map.block_plans, DAY)
	city.start_day(state, DAY, own_run.calendar.day_rng(DAY, "closures"))
	# The rig's shape: the crowd is handed its world, map, lights and streets and no navigator.
	city.crowd.setup(city, city.map, city.signals, city.streets())
	var her_tile := _open_sidewalk(city.map)
	t.check(her_tile != Vector2i(-1, -1), "the city has open sidewalk to stand her on")
	if her_tile == Vector2i(-1, -1):
		city.free()
		return
	var here := city.map.tile_to_world(her_tile)
	city.crowd.start_day(DAY, own_run.calendar.day_rng(DAY, "crowd"), here, false)
	var placed := _walker_on_a_lane_at(city, here)
	t.check(placed.get("error", "") == "", "a walker stands on a lane of her sidewalk: %s"
			% placed.get("error", ""))
	var player: Stroller = STROLLER_SCENE.instantiate()
	t.add_child(player)
	city.crowd.use_player(player)
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
			on_the_map = on_the_map and city.map.is_walkable(city.map.world_to_tile(walker.global_position))
		# He side-steps on his own too, but gradually (a few pixels a frame): what he has moved off
		# his lane by the end of the first frame is more than that only if the push moved him.
		t.check(first_frame > push * 0.5 and on_the_map,
				"the walker walking at her is pushed off his lane over the map's ground "
				+ "(%.1fpx aside on the first frame, a push of %.1fpx)" % [first_frame, push])
	player.free()
	city.free()

## A walker placed through the crowd's own entry (`Crowd.add_recipe_actor()`) on the lane centre
## nearest `here`, heading along either axis, at a pace drawn from his kind's (`-1.0`), which is the
## first the entry accepts.
func _walker_on_a_lane_at(city: City, here: Vector2) -> Dictionary:
	var placed := {"error": "no lane centre on the tile"}
	for heading: Vector2 in [Vector2.DOWN, Vector2.RIGHT]:
		var across := Vector2(heading.y, heading.x)
		for offset in range(-48, 49):
			placed = city.crowd.add_recipe_actor("pushed", CrowdAgent.Kind.WALKER,
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
