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
		var manifest_path := "user://stretch_crowd_%d_%s" % [OS.get_process_id(), filename]
		var output: Array = []
		var status := OS.execute(OS.get_executable_path(), PackedStringArray([
			"--headless", "--path", ProjectSettings.globalize_path("res://"), "--fixed-fps", "60",
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
		t.check(status == 0 and manifest.get("playback_complete", false) and unmet.is_empty(),
				"%s plays to its end with every observation met: %s" % [filename, unmet])
		var jumps: Array = manifest.get("seen_to_jump", [])
		t.check(jumps.is_empty(), "%s: nobody appears or vanishes in her view: %s" % [filename, jumps])
		var asks_an_event := (data.playback.observations as Array).any(
				func(check: Dictionary) -> bool: return check.condition == "appeared")
		t.check(asks_an_event, "%s asks that she sees a route event" % filename)
		played += 1
	t.check(played >= 10, "every stretch scene is played (%d)" % played)
