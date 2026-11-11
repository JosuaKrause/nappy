@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## Real runtime installation rejects incomplete structures and refreshes a felled tree's source, and
## runs the scene's events under the one spec the run flow hands it.
##
## **Builds a real `City`: the runtime installs into one.** `SceneRecipeRuntime.install()` is handed the
## concrete `City` and reads its map, streets, events and poster walls, so its refusals and the state it leaves
## (a felled tree's pit emptied, a door's bodies stood) are only observable on a city the game made. Split
## off the city, the suite would test the runtime against a stand-in whose answers are a copy of this city's.


func run(t: TestRunner) -> void:
	# A run of its own, handed to the city and the scene as `main` hands them the game's.
	var own_run := RunState.new()
	own_run.start_run(11)
	own_run.header.day = 13
	var loaded := SceneRecipe.load_file("res://scene-recipes/trailer-trucks.json")
	var data: Dictionary = loaded.data.duplicate(true)
	data.setup = {"day": 13, "player": {"at": [16, 16]}}
	var built := RecipeCityBuilder.build(data)
	built.data = data
	var packed: PackedScene = load("res://scenes/world/city.tscn")
	var city: City = packed.instantiate()
	city.run = own_run
	t.add_child(city)
	city.build(built.map)
	var state := CityState.new()
	state.begin_day(city.map.block_plans, 13)
	city.start_recipe_day(state, 13, own_run.calendar.day_rng())
	var player_scene: PackedScene = load("res://scenes/player/stroller.tscn")
	var player: Stroller = player_scene.instantiate()
	t.add_child(player)
	var baby: Baby = player.get_node("Baby")
	var runtime := SceneRecipeRuntime.new()
	runtime.configure(built, RunConfig.parse(PackedStringArray(["--recipe", "test.json"]), "", true), own_run)
	var selected := Vector3i(-1, -1, -1)
	var day_spec := DaySpec.for_day(own_run.header.day, Tuning.DAY_LENGTH_SECONDS)
	for key: Vector3i in StreetTrees.segment_keys_with_trees(city.map):
		if SealPlanner.may_seal(city.map, day_spec, city.streets().route_tree(), city.map.network.by_key(key)):
			selected = key
			break
	t.check(selected.x >= 0, "tree regression has a real eligible off-route street")
	if selected.x >= 0:
		data.setup.seals = [{"segment": [selected.x, selected.y, selected.z], "candidate": "fallen_tree_seal"}]
		var errors := runtime.install(city, player, baby, DaySpec.for_day(own_run.header.day, Tuning.DAY_LENGTH_SECONDS))
		t.check(errors.is_empty(), "authored fallen tree installs through production siting: %s" % [errors])
		var emptied := _emptied_pits(city.map)
		t.check(emptied.size() == 1, "authored fallen tree empties exactly one source pit")
		for pit: StreetTrees.Planted in emptied:
			var tree := _street_tree_at(city, pit.position)
			t.check(tree != null and not tree.visible,
					"runtime hides the standing source tree after installing its fallen seal")
		data.setup.erase("seals")
		errors = runtime.install(city, player, baby, DaySpec.for_day(own_run.header.day, Tuning.DAY_LENGTH_SECONDS))
		t.check(errors.is_empty() and _emptied_pits(city.map).is_empty(), "reinstallation clears unselected fallen-tree state")
		for tree in _street_trees(city):
			t.check(tree.visible, "standing source trees return when no authored fallen tree selects them")
	var authored_bounds := city.map.recipe_bounds
	city.map.recipe_bounds = Rect2i(0, 0, 14, 14)
	for collection in ["gates", "barriers", "seals"]:
		var entry := {"segment": [7, 6, 0]} if collection == "gates" else {"segment": [3, 5, 0]}
		if collection == "barriers":
			entry.end = "b"
		elif collection == "seals":
			entry.candidate = "cafe_pair"
		data.setup[collection] = [entry]
		var errors := runtime.install(city, player, baby, DaySpec.for_day(own_run.header.day, Tuning.DAY_LENGTH_SECONDS))
		t.check("\n".join(errors).contains("leaves the authored extent"),
				"%s outside a bounded scene rejects instead of silently dropping bodies" % collection)
		data.setup.erase(collection)
	city.map.recipe_bounds = authored_bounds
	_test_an_authored_door_stands_as_the_days(t, runtime, city, player, baby, own_run, data)
	_test_an_authored_soft_seal_stands_as_the_days(t, runtime, city, player, baby, own_run, data)
	_test_the_scene_runs_under_the_spec_it_is_handed(t, runtime, city, player, baby, own_run)
	runtime.free()
	player.free()
	city.free()

## **An authored checkpoint stands as the day's own door does**: the recipe selects one of the day's
## street doors (`RegionPlanner.plan_day()`), and the plan it installs holds that door, its three
## bodies where the day's stand, as the same rows, and its gate — the one entry both stand a door
## through (`RegionPlanner.stand_door()`).
func _test_an_authored_door_stands_as_the_days(t: TestRunner, runtime: SceneRecipeRuntime, city: City,
		player: Stroller, baby: Baby, own_run: RunState, data: Dictionary) -> void:
	var days := RegionPlanner.plan_day(city.map, DaySpec.for_day(own_run.header.day), city.streets().route_tree())
	t.check(not days.doors.is_empty(), "the day has a street door to author")
	if days.doors.is_empty():
		return
	var door: StreetNetwork.Segment = days.doors[0]
	var bodies := days.door_bodies.slice(0, 3)
	city.streets().replace_region_plan(days)
	var key := door.key()
	data.setup.gates = [{"segment": [key.x, key.y, key.z]}]
	var errors := runtime.install(city, player, baby, DaySpec.for_day(own_run.header.day, Tuning.DAY_LENGTH_SECONDS))
	var authored := city.streets().region_plan()
	t.check(errors.is_empty() and authored.doors.size() == 1 and authored.doors[0].key() == key
			and authored.gates.size() == 1 and authored.door_bodies.size() == bodies.size(),
			"the authored door is the day's street, with its gate and its bodies: %s" % [errors])
	var same := authored.door_bodies.size() == bodies.size()
	for i in mini(authored.door_bodies.size(), bodies.size()):
		var mine: EventPlan = authored.door_bodies[i]
		var theirs: EventPlan = bodies[i]
		same = same and mine.position == theirs.position and mine.def.id == theirs.def.id \
				and mine.facing == theirs.facing
	t.check(same, "and each body stands where the day's does, as the same row")
	data.setup.erase("gates")

## **An authored soft seal stands as the day's own would**: on an off-walk street the day may seal
## (`SealPlanner.may_seal()`), its two bodies stand where the day's pass sites the same picture
## (`SealPlanner.seal_street()`), and both of the street's sidewalks are shut to walkers there.
func _test_an_authored_soft_seal_stands_as_the_days(t: TestRunner, runtime: SceneRecipeRuntime, city: City,
		player: Stroller, baby: Baby, own_run: RunState, data: Dictionary) -> void:
	var spec := DaySpec.for_day(own_run.header.day, Tuning.DAY_LENGTH_SECONDS)
	var cafe: SealPlanner.Candidate = null
	for candidate in SealPlanner.candidates():
		if candidate.id == "cafe_pair":
			cafe = candidate
	var street: StreetNetwork.Segment = null
	for segment in city.map.network.segments():
		if SealPlanner.may_seal(city.map, spec, city.streets().route_tree(), segment) \
				and city.map.has_street(segment.key()) \
				and not RegionPlanner.boundary_segments(city.map).has(segment):
			street = segment
			break
	t.check(cafe != null and street != null, "the day has a street a café pair may seal")
	if cafe == null or street == null:
		return
	var expected := SealPlanner.seal_street(city.map, street, cafe, city.streets().route_tree(),
			StreetTrees.footprint_tiles(city.map), [] as Array[Vector2i])
	var key := street.key()
	data.setup.seals = [{"segment": [key.x, key.y, key.z], "candidate": "cafe_pair"}]
	var errors := runtime.install(city, player, baby, spec)
	t.check(errors.is_empty(), "the café pair installs: %s" % [errors])
	# Compared at the grain the placement decides — how far along the street, and which sidewalk —
	# since a body on a sidewalk is centred on its band as it is set up, in a recipe as on a day.
	var centre := city.map.tile_rect_to_world(street.tile_rect()).get_center()
	var stood: Array[Vector2] = []
	for instance in city.events.instances():
		if instance.def.id == "cafe_tables":
			stood.append(_along_and_side(street, centre, instance.position))
	var where: Array[Vector2] = []
	for body in expected.bodies:
		where.append(_along_and_side(street, centre, body.position))
	stood.sort()
	where.sort()
	t.check(stood == where, "its bodies stand where the day's pass sites the same picture, one on"
			+ " each sidewalk (along, side): %s, %s" % [stood, where])
	var tiles := city.map.rect_tiles(street.tile_rect())
	var shut := 0
	for tile in tiles:
		if not city.map.passable(tile, Mover.of(Mover.SOFT_SEALS)):
			shut += 1
	t.check(shut == 2 * Tuning.SIDEWALK_WIDTH,
			"and both its sidewalks are shut to walkers there (%d tiles)" % shut)
	data.setup.erase("seals")

## Where `at` stands on `street`: how far along it, and which side of its centre line (-1 or 1).
func _along_and_side(street: StreetNetwork.Segment, centre: Vector2, at: Vector2) -> Vector2:
	if street.horizontal:
		return Vector2(at.x, signf(at.y - centre.y))
	return Vector2(at.y, signf(at.x - centre.x))

## **One spec for an authored scene**: the walk the run flow started — the one its clock and HUD run
## on (`DayDirector.start()`, a day's or the escape boot's section) — is the spec the scene's events run
## under, handed through `install()`, with no second spec built beside it. An escape scene's events
## owe no return and a torn poster sends nobody there; a day scene's walk is the day as configured,
## `--day-length` included (`RunConfig.day_length_for()`), and its events run with a day's settings, a torn
## poster sending its pursuer.
func _test_the_scene_runs_under_the_spec_it_is_handed(t: TestRunner, runtime: SceneRecipeRuntime, city: City,
		player: Stroller, baby: Baby, own_run: RunState) -> void:
	player.global_position = city.map.tile_to_world(Vector2i(16, 16))
	city.events.use_player(player)
	var escape := DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS)
	var errors := runtime.install(city, player, baby, escape)
	t.check(errors.is_empty() and not city.events.ahead.holds_the_home_streets,
			"an escape scene is installed into the spec it is handed, whose siting keeps off no home street: %s"
			% [errors])
	t.check(not city.events.ahead.sends_poster_pursuits,
			"and its events send no poster pursuer")
	city.events.send_a_pursuer()
	t.check(city.events.pending_warnings().is_empty(), "so a torn poster there sends nobody")

	var configured := RunConfig.parse(PackedStringArray(["--day-length", "77"]), "", true)
	var day := DaySpec.for_day(own_run.header.day, configured.day_length_for(own_run.header.day))
	t.check(is_equal_approx(day.length, 77.0),
			"a day scene's walk is the configured day's length (%.1fs)" % day.length)
	errors = runtime.install(city, player, baby, day)
	t.check(errors.is_empty() and city.events.ahead.holds_the_home_streets
			and city.events.ahead.sends_poster_pursuits,
			"and the same spec, with a day's settings, is the one its events run under: %s" % [errors])
	city.events.send_a_pursuer()
	t.check(city.events.pending_warnings().size() == 1,
			"so a torn poster on a day scene sends its pursuer (%d warnings)"
			% city.events.pending_warnings().size())
	city.events.warnings.clear()

## The street trees' pits the day has emptied (`CityMap.is_tree_pit_emptied()`, what the city reads
## to hide a tree).
func _emptied_pits(map: CityMap) -> Array[StreetTrees.Planted]:
	var emptied: Array[StreetTrees.Planted] = []
	for pit in StreetTrees.planted(map):
		if map.is_tree_pit_emptied(pit.tile):
			emptied.append(pit)
	return emptied

## The street trees the city draws (`City.props()`).
func _street_trees(city: City) -> Array[Prop]:
	var trees: Array[Prop] = []
	for node in city.props():
		if node is Prop and (node as Prop).kind == Prop.Kind.STREET_TREE:
			trees.append(node)
	return trees

## The street tree the city draws standing at `at`, or null.
func _street_tree_at(city: City, at: Vector2) -> Prop:
	for tree in _street_trees(city):
		if tree.position == at:
			return tree
	return null
