extends RefCounted
## Real Main planning keeps authored subjects inside an ordinary day's population and budget.

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
	if city.events._recipe_plan or city.events._plans.size() < 20:
		fail("ordinary event planning or director is absent")
		return
	for plan in city.events._plans:
		if plan.has_meta("recipe_reservation"):
			fail("a reservation was installed as a duplicate actor")
			return
	if runtime.named.has("blower"):
		var counts := {}
		var cost := 0
		for plan in city.events._plans:
			if plan.has_meta("recipe_catalogue") and plan.def.kind == GameEnums.EventKind.RECURRING:
				counts[plan.def.id] = int(counts.get(plan.def.id, 0)) + 1
				cost += plan.def.cost
		if cost > EventScheduler.budget_for(GameState.day) \
				or counts.get("leaf_blower", 0) > EventCatalogue.by_id("leaf_blower").max_per_day:
			fail("pinned recurring event was added beyond the ordinary budget or cap")
			return
		var matched := false
		for plan in city.events._plans:
			if plan.get_meta("recipe_name", "") == "blower":
				matched = plan.position.is_equal_approx(runtime.built.anchors.blower)
		if not matched:
			fail("ordinary planning moved the pinned subject")
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
					runtime.built.anchors.gate + Vector2(64, 0)):
				found = EventInstance.gate_runs_north_south(body.facing)
		if not found:
			fail("the approached production gate does not have a horizontal boom")
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
	for name in ["blower", "trucks", "gatehouse", "title"]:
		var output: Array = []
		var status := OS.execute(OS.get_executable_path(), PackedStringArray([
			"--headless", "--path", ProjectSettings.globalize_path("res://"),
			stem + ".tscn", "--", "--recipe", "res://scene-recipes/trailer-%s.json" % name,
			"--recipe-mode", "scripted", "--recipe-validate", "--no-telemetry"
		]), output, true)
		var body := "\n".join(output)
		t.check(status == 0 and body.contains("RECIPE_ACTIVITY_OK")
				and not body.contains("ERROR"), "%s real background/subject setup: %s" % [name, body])
	for suffix in [".gd", ".gd.uid", ".tscn"]:
		DirAccess.remove_absolute(stem + suffix)
