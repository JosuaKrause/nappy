extends RefCounted
## **Every hitbox a real day builds is drawn** (PLAYTEST-57: *"and make sure *all* hitboxes are
## actually drawn"*): `DebugLayers.collision_nodes_under()`, which the bounding-box layer draws every
## outline from, finds exactly the enabled collision shapes physics reads in a real city's day and in
## the player.
##
## **A combined suite, for a stated reason**: the guarantee spans modules. What the walk does on a tree
## of hand-made bodies is `tests/test_debug_layers.gd`'s; what this holds is that the bodies the game
## itself builds (the city's buildings and props, a checkpoint day's region wall and door, the
## events' bodies, her own) are all of a kind the walk reaches, which no hand-made tree can say, so
## the real city, its day's events and a real `Stroller` are built, the city from a cached map
## (`tests/city_map_cache.gd`).

const MapCache := preload("res://tests/city_map_cache.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")

func run(t: TestRunner) -> void:
	_test_the_bounding_box_layer_draws_every_enabled_body(t)

## PLAYTEST-57: *"and make sure *all* hitboxes are actually drawn"* — the bounding-box layer's own
## completeness. Builds one real day on a real `City` (a checkpoint day, so a region wall or door
## is in play, not only the ordinary catalogue) plus a real `Stroller`, then counts every enabled
## `CollisionShape2D`/`CollisionPolygon2D` under a `StaticBody2D`/`CharacterBody2D` in both trees by
## hand — independently of `DebugLayers.collision_nodes_under()`, which `_draw_bodies()` draws
## every outline from, so a bug in that walk cannot hide from this test — and checks it finds the
## same bodies in the two trees.
func _test_the_bounding_box_layer_draws_every_enabled_body(t: TestRunner) -> void:
	var city: City = RunCity.with_own_run(CITY_SCENE, 5551212)
	t.add_child(city)
	city.build(MapCache.of(5551212))

	var day := Tuning.REGION_WALL_FIRST_DAY
	var state := CityState.new()
	state.begin_day(city.map.block_plans, day)
	var closures_rng := RandomNumberGenerator.new()
	closures_rng.seed = hash("m100-debug-layers:closures:%d" % day)
	city.start_day(state, day, closures_rng)

	city.events.stream_radius = INF
	var consumed: Array[String] = []
	var events_rng := RandomNumberGenerator.new()
	events_rng.seed = hash("m100-debug-layers:events:%d" % day)
	city.events.start_day(DaySpec.for_day(day), events_rng, consumed)

	var scene: PackedScene = load("res://scenes/player/stroller.tscn")
	var stroller: Stroller = scene.instantiate()
	t.add_child(stroller)
	city.events.use_player(stroller)
	stroller.set_physics_process(false)

	var expected := _count_enabled_bodies(city) + _count_enabled_bodies(stroller)
	var drawn := DebugLayers.collision_nodes_under(city).size() \
			+ DebugLayers.collision_nodes_under(stroller).size()
	t.check(expected > 10,
			"the generated day actually has bodies worth counting (%d found)" % expected)
	t.check(drawn == expected,
			("the bounding-box layer draws exactly the enabled collision shapes physics reads "
			+ "(%d expected from an independent tree walk, %d from the layer's own walk)")
			% [expected, drawn])

	stroller.free()
	city.free()

## An oracle independent of `DebugLayers.collision_nodes_under()`: every enabled
## `CollisionShape2D` (with a shape) or `CollisionPolygon2D` under a `StaticBody2D` or
## `CharacterBody2D` anywhere in `root`'s own subtree, walked by hand so a bug in the layer's own
## seam cannot hide from this test.
func _count_enabled_bodies(root: Node) -> int:
	var count := 0
	if root is StaticBody2D or root is CharacterBody2D:
		for child in root.get_children():
			var shape := child as CollisionShape2D
			var polygon := child as CollisionPolygon2D
			if shape != null and not shape.disabled and shape.shape != null:
				count += 1
			elif polygon != null and not polygon.disabled:
				count += 1
	for child in root.get_children():
		count += _count_enabled_bodies(child)
	return count
