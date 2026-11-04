extends RefCounted
## Real Main installs only authored subjects while keeping production crowd simulation.

const PROBE := """extends Node
const BootedMain := preload("res://tests/booted_main.gd")
func _ready() -> void:
	# The recipe the boot plays, loaded as `main` loads it (`SceneRecipeRuntime.load_recipe()`): its
	# data and the places it names. The booted game's parts are read off its scene tree.
	var config := RunConfig.at_boot()
	var loaded := SceneRecipeRuntime.load_recipe(config.recipe_path, config.active_args)
	var packed: PackedScene = load("res://scenes/main.tscn")
	var main := packed.instantiate()
	add_child(main)
	var city := BootedMain.city(main)
	if not loaded.errors.is_empty() or not city:
		return
	var setup: Dictionary = loaded.data.setup
	var run := run_of(main)
	var act := Tuning.act_for_day(run.header.day)
	var multiplier: float = setup.get("background", {}).get("walker_multiplier", 1)
	var pins: Array = setup.get("actors", [])
	if city.crowd.agent_count() != roundi(Tuning.crowd_pedestrians(act) * multiplier) + Tuning.crowd_cars(act) + pins.size():
		fail("background population differs from ordinary day density")
		return
	for pin: Dictionary in pins:
		var actor := city.find_child(pin.name, true, false) as CrowdAgent
		if not actor or not actor.position.is_equal_approx(position_of(pin.at, loaded.anchors, city)):
			fail("background population dropped or moved an explicit walker")
			return
	var expected: int = setup.get("events", []).size()
	expected += setup.get("seals", []).size() * 2
	expected += setup.get("gates", []).size() * 3
	expected += setup.get("barriers", []).size() * 3
	if city.events.plans().size() != expected:
		fail("an unselected event, seal or region body is installed")
		return
	# No ordinary filling above, and the director owes nothing more on the walk: the baby falling
	# asleep turns the day to its return, which a played day answers with patrols owed on the way
	# back (acts III and IV), and a scene's day owes none beyond what its own events are.
	var owed_before: int = city.events.owed_ahead()
	BootedMain.baby(main).force_sleep()
	if city.events.owed_ahead() != owed_before:
		fail("authored scene enables ordinary event filling or director")
		return
	for entry: Dictionary in setup.get("events", []):
		var matched := false
		for plan in city.events.plans():
			if plan.get_meta("recipe_name", "") == entry.name:
				matched = plan.position.is_equal_approx(position_of(entry.at, loaded.anchors, city))
		if not matched:
			fail("construction moved the pinned subject")
			return
	for roof: Dictionary in setup.get("roof_fixtures", []):
		var matched := false
		for building in city.buildings():
			if building.lot == SceneRecipe.rect(roof.lot):
				matched = roof_matches(building, roof.fixtures)
		if not matched:
			fail("authored fixtures did not reach the real production building")
			return
	if setup.has("seals"):
		for plan in city.events.plans():
			if plan.def.id == "cafe_tables" and not is_equal_approx(plan.position.x, 2576):
				fail("restaurant guests did not move exactly one block east")
				return
	if setup.has("barriers"):
		for plan in city.events.plans():
			if plan.def.id == "roadblock" and (not is_equal_approx(plan.position.x, 1552)
					or plan.position.y < 2240 or plan.position.y > 2432):
				fail("truck barrier is not a vertical band across the left street")
				return
	if setup.has("posters"):
		for entry: Dictionary in setup.posters:
			var tile := city.map.world_to_tile(Vector2(entry.at[0], entry.at[1]))
			if not city.poster_walls().fronts().has(tile) or run.posters.cells[tile].kind \
					!= PosterArt.Kind[str(entry.kind).to_upper()]:
				fail("authored poster is not a real eligible wall cell")
				return
	if loaded.anchors.has("gate"):
		var found := false
		for body in city.region_plan().door_bodies:
			if body.def.id == "checkpoint_gate" and body.position.is_equal_approx(
					loaded.anchors.gate + Vector2(0, 64)):
				found = not EventPictures.gate_runs_north_south(body.facing)
		if not found:
			fail("the father's horizontal approach does not meet the standard vertical gate")
			return
	print("RECIPE_ACTIVITY_OK")
## Where the recipe puts `value`: a point, one of its named places, or the doorstep.
func position_of(value: Variant, anchors: Dictionary, city: City) -> Vector2:
	if value is Array:
		return Vector2(float(value[0]), float(value[1]))
	if anchors.has(value):
		return anchors[value]
	return city.map.doorstep_world_position()
## The run the booted `main` plays, off its sitting: its own child on a first boot, parked at the
## tree's root across a reload.
func run_of(main: Node) -> RunState:
	var sitting := main.get_node_or_null(NodePath(Sitting.NODE_NAME)) as Sitting
	if not sitting:
		sitting = get_tree().root.get_node_or_null(NodePath(Sitting.NODE_NAME)) as Sitting
	return sitting.run
func roof_matches(building: Building, fixtures: Array) -> bool:
	if building.recipe_roof_furniture == null:
		return false
	var expected := {}
	for fixture: Dictionary in fixtures:
		var cell := Vector2i(fixture.cell[0], fixture.cell[1])
		var kind := str(fixture.kind).to_upper()
		if kind in ["DUCT_STRAIGHT", "DUCT_CORNER"]:
			expected[cell] = Building._Furniture.DUCT_RUN
			if kind == "DUCT_STRAIGHT":
				expected[cell + Vector2i.RIGHT] = Building._Furniture.DUCT_RUN
		else:
			expected[cell] = Building._Furniture[kind]
	if expected.size() != building.recipe_roof_furniture.size():
		return false
	for entry: Dictionary in building.recipe_roof_furniture:
		if expected.get(entry.cell, -1) != entry.kind:
			return false
	return true
func fail(message: String) -> void:
	print("RECIPE_ACTIVITY_FAILED " + message)
	get_tree().quit(1)
"""

func run(t) -> void:
	var stem := "user://recipe_activity_%d" % OS.get_process_id()
	var script := FileAccess.open(stem + ".gd", FileAccess.WRITE)
	script.store_string(PROBE)
	script.close()
	var scene := FileAccess.open(stem + ".tscn", FileAccess.WRITE)
	scene.store_string("[gd_scene load_steps=2 format=3]\n[ext_resource type=\"Script\" path=\"%s.gd\" id=\"1\"]\n[node name=\"Probe\" type=\"Node\"]\nscript = ExtResource(\"1\")\n" % stem)
	scene.close()
	for name in ["choice", "birds", "dog", "trucks", "gatehouse", "title"]:
		var output: Array = []
		var status := OS.execute(OS.get_executable_path(), PackedStringArray([
			"--headless", "--quit-after", "120", "--path", ProjectSettings.globalize_path("res://"),
			stem + ".tscn", "--", "--recipe", "res://scene-recipes/trailer-%s.json" % name,
			"--recipe-mode", "scripted", "--recipe-validate", "--no-telemetry"
		]), output, true)
		var body := "\n".join(output)
		t.check(status == 0 and body.contains("RECIPE_ACTIVITY_OK")
				and not body.contains("ERROR"), "%s real background/subject setup: %s" % [name, body])
	for suffix in [".gd", ".gd.uid", ".tscn"]:
		DirAccess.remove_absolute(stem + suffix)
