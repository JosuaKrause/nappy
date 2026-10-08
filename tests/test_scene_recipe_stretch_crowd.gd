extends RefCounted
## **Every stretch scene, played through: nothing in its crowd appears or vanishes where she can see
## it, and she sees the event its rigged bag sends** *(the player's rule, PR #597; polite-dolphin,
## inbox #555: "right now it's just empty", "that's not a good test")*. Each scene under
## `scene-recipes/` with a stretch scope is played in its own headless process, scripted, to its end;
## the runtime records a walker or car that left or entered within reach of either view
## (`SceneRecipeRuntime._watch_the_crowd()`, the manifest's `seen_to_jump`), and every observation the
## recipe asks, its `appeared` of the route event and its `crowd` among them, must hold.

func run(t) -> void:
	var played := 0
	for filename in DirAccess.get_files_at("res://scene-recipes"):
		if not filename.ends_with(".json"):
			continue
		var path := "res://scene-recipes/" + filename
		var data: Dictionary = SceneRecipe.load_file(path).data
		if data.get("extent", {}).get("scope") != "stretch":
			continue
		_force_recycles(t, data, filename)
		var manifest_path := "user://stretch_crowd_%d_%s" % [OS.get_process_id(), filename]
		var output: Array = []
		var status := OS.execute(OS.get_executable_path(), PackedStringArray([
			"--headless", "--path", ProjectSettings.globalize_path("res://"), "--fixed-fps", "60",
			"--quit-after", str(ceili(float(data.playback.duration) * 60.0) + 600),
			"--", "--recipe", path, "--recipe-mode", "scripted", "--no-save", "--no-telemetry",
			"--recipe-manifest", ProjectSettings.globalize_path(manifest_path)]), output, true)
		var parser := JSON.new()
		var read := FileAccess.get_file_as_string(manifest_path)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(manifest_path))
		if parser.parse(read) != OK or not parser.data is Dictionary:
			t.check(false, "%s wrote a manifest: %s" % [filename, "\n".join(output)])
			continue
		var manifest: Dictionary = parser.data
		var unmet: Array = (manifest.get("observations", []) as Array).filter(
				func(record: Dictionary) -> bool: return not record.passed)
		var engine_failed := "\n".join(output).contains("ERROR:")
		t.check(status == 0 and not engine_failed and manifest.get("playback_complete", false) and unmet.is_empty(),
				"%s plays to its end with every observation met: %s\n%s" % [filename, unmet,
					"\n".join(output) if status != 0 else str(manifest.get("playback_error", ""))])
		var jumps: Array = manifest.get("seen_to_jump", [])
		t.check(jumps.is_empty(), "%s: nobody appears or vanishes in her view: %s" % [filename, jumps])
		t.check(manifest.get("in_the_void", []).is_empty(),
				"%s: no waiting body is left outside authored ground" % filename)
		var asks_an_event := (data.playback.observations as Array).any(
				func(check: Dictionary) -> bool: return check.condition == "appeared")
		t.check(asks_an_event, "%s asks that she sees a route event" % filename)
		played += 1
	t.check(played >= 10, "every stretch scene is played (%d)" % played)

## Short authored walks need not naturally exhaust a street. Exercise actual departures and
## accepted entries as well as the playback observer, with a real camera for its view boundary.
func _force_recycles(t, data: Dictionary, label: String) -> void:
	var built := RecipeCityBuilder.build(data)
	if not built.errors.is_empty():
		t.check(false, "%s loads for forced crowd entries" % label)
		return
	var map: CityMap = built.map
	var field := CrowdField.new(map, Vector2.ZERO)
	field.use_stretch()
	var camera := Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	t.add_child(camera)
	camera.make_current()
	var visible_stable := true
	var entries_safe := true
	var entries := 0
	var headings := {"north": Vector2.UP, "south": Vector2.DOWN,
			"east": Vector2.RIGHT, "west": Vector2.LEFT}
	for spec: Dictionary in data.setup.actors:
		var agent := CrowdAgent.new()
		var kind := CrowdAgent.Kind.CAR if spec.kind == "car" else CrowdAgent.Kind.WALKER
		var at := Vector2(float(spec.at[0]), float(spec.at[1]))
		var problem := agent.setup_at(kind, map, field, 11, at, headings[spec.direction], spec.speed)
		if not problem.is_empty():
			t.check(false, "%s/%s starts: %s" % [label, spec.name, problem])
			agent.free()
			continue
		t.add_child(agent)
		camera.position = at
		camera.reset_physics_interpolation()
		camera.reset_smoothing()
		camera.force_update_scroll()
		t.check(camera.get_screen_center_position().distance_to(at) < 1.0,
				"%s camera centers on actor: %s / %s" % [label, camera.get_screen_center_position(), at])
		agent._recycle()
		visible_stable = visible_stable and agent.position == at
		camera.position = Vector2(-10000, -10000)
		camera.reset_physics_interpolation()
		camera.reset_smoothing()
		camera.force_update_scroll()
		for attempt in 8:
			var before := agent.position
			agent._recycle()
			if agent.position != before:
				entries += 1
				entries_safe = entries_safe and agent._beyond_every_view(agent.position) \
						and agent._stands_on_a_street()
		agent.free()
	t.check(visible_stable, "%s: every visible actor turns without teleporting" % label)
	t.check(entries > 0 and entries_safe,
			"%s: %d forced entries stay on authored street outside the whole camera" % [label, entries])
	camera.free()
