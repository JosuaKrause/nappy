extends RefCounted
## Real Main installs only authored subjects while keeping production crowd simulation.

const PROBE := """extends Node
func _ready() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var main := packed.instantiate()
	add_child(main)
	var runtime: SceneRecipeRuntime = main.get("_recipe")
	var city: City = main.get("_city")
	if not runtime or not city or runtime.manifest.get("setup_failed", false):
		return
	var act := Tuning.act_for_day(GameState.day)
	if city.crowd.agent_count() != Tuning.crowd_pedestrians(act) + Tuning.crowd_cars(act):
		fail("background population differs from ordinary day density")
		return
	if not city.events._recipe_plan:
		fail("authored scene enables ordinary event filling or director")
		return
	var expected: int = runtime.data.setup.get("events", []).size()
	expected += runtime.data.setup.get("seals", []).size() * 2
	expected += runtime.data.setup.get("gates", []).size() * 3
	expected += runtime.data.setup.get("barriers", []).size() * 3
	if city.events._plans.size() != expected:
		fail("an unselected event, seal or region body is installed")
		return
	for entry: Dictionary in runtime.data.setup.get("events", []):
		var matched := false
		for plan in city.events._plans:
			if plan.get_meta("recipe_name", "") == entry.name:
				var errors: Array[String] = []
				matched = plan.position.is_equal_approx(runtime.position_of(entry.at, errors))
		if not matched:
			fail("construction moved the pinned subject")
			return
	for roof: Dictionary in runtime.data.setup.get("roof_fixtures", []):
		var matched := false
		for building in city.buildings():
			if building.lot == SceneRecipe.rect(roof.lot):
				matched = building.recipe_roof_furniture != null \
						and building.recipe_roof_furniture.size() == roof.fixtures.size()
		if not matched:
			fail("authored fixtures did not reach the real production building")
			return
	if runtime.data.setup.has("seals"):
		for plan in city.events._plans:
			if plan.def.id == "cafe_tables" and not is_equal_approx(plan.position.x, 2576):
				fail("restaurant guests did not move exactly one block east")
				return
	if runtime.data.setup.has("barriers"):
		for plan in city.events._plans:
			if plan.def.id == "roadblock" and (not is_equal_approx(plan.position.x, 1552)
					or plan.position.y < 2240 or plan.position.y > 2432):
				fail("truck barrier is not a vertical band across the left street")
				return
	if runtime.data.setup.has("posters"):
		for entry: Dictionary in runtime.data.setup.posters:
			var tile := city.map.world_to_tile(Vector2(entry.at[0], entry.at[1]))
			if not city.poster_walls().fronts().has(tile) or GameState.posters.cells[tile].kind \
					!= PosterArt.Kind[str(entry.kind).to_upper()]:
				fail("authored poster is not a real eligible wall cell")
				return
	if runtime.built.anchors.has("gate"):
		var found := false
		for body in city.region_plan().door_bodies:
			if body.def.id == "checkpoint_gate" and body.position.is_equal_approx(
					runtime.built.anchors.gate + Vector2(0, 64)):
				found = not EventInstance.gate_runs_north_south(body.facing)
		if not found:
			fail("the father's horizontal approach does not meet the standard vertical gate")
			return
	print("RECIPE_ACTIVITY_OK")
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
	for name in ["choice", "blower", "dog", "trucks", "gatehouse", "title"]:
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
