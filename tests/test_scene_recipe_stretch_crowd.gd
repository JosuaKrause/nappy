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

## Short authored walks need not naturally exhaust a street, so entries are forced here, with a
## real camera for the view boundary at her camera's zoom. A visible actor asked to recycle turns
## where it stands. Then, for each stretch end in turn, the camera looks straight at it, and then
## from beside it on either side, just far enough that the end's middle is out of view
## (`CrowdAgent._beyond_every_view()`) while ground a pixel nearer, its near lanes, is in it; each
## actor is entered at an end under every one of those views, and no accepted entry may stand in
## the view it was made under. The end in view is what dropping the in-view ends keeps out, and
## the near lanes are what checking the final placement keeps out.
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
	camera.zoom = Vector2.ONE * HER_ZOOM
	t.add_child(camera)
	camera.make_current()
	var visible_stable := true
	var entries_safe := true
	var ends_seen := true
	var entries := 0
	var unsafe: Array[String] = []
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
		_look_at(camera, at)
		t.check(camera.get_screen_center_position().distance_to(at) < 1.0,
				"%s camera centers on actor: %s / %s" % [label, camera.get_screen_center_position(), at])
		agent._recycle()
		visible_stable = visible_stable and agent.position == at
		for end: Dictionary in field.stretch_ends:
			var middle := _middle_of(end)
			var across := Vector2.RIGHT if end.vertical else Vector2.DOWN
			# The least distance across at which the camera no longer sees the end's middle, by the
			# crowd's own rule, so whatever that rule's view and room are, the lanes a pixel nearer
			# the camera are in view.
			_look_at(camera, middle)
			var aside := 0.0
			while aside < 4096.0 and not agent._beyond_every_view(middle + across * aside):
				aside += 1.0
			for looking: Vector2 in [middle, middle + across * aside, middle - across * aside]:
				_look_at(camera, looking)
				ends_seen = ends_seen and aside < 4096.0 \
						and (looking != middle or not agent._beyond_every_view(middle))
				for _attempt in 4:
					var before := agent.position
					agent._enter_at_a_stretch_end()
					if agent.position == before:
						continue
					entries += 1
					var safe := agent._beyond_every_view(agent.position) and agent._stands_on_a_street()
					entries_safe = entries_safe and safe
					if not safe and unsafe.size() < 4:
						unsafe.append("%s entered at %s, camera on %s" % [spec.name, agent.position, looking])
		agent.free()
	t.check(visible_stable, "%s: every visible actor turns without teleporting" % label)
	t.check(ends_seen, "%s: the camera on a stretch end has that end in view" % label)
	t.check(entries > 0 and entries_safe,
			("%s: %d forced entries, each made with an end or its near lanes in view, stay on "
			+ "authored street out of that view: %s") % [label, entries, unsafe])
	camera.free()

## Her camera's zoom (`scenes/player/stroller.tscn`), so the view the entries keep out of is the
## size it is in play.
const HER_ZOOM := 2.0

## The middle of a stretch end's street, at the end's own tile along it: where
## `CrowdAgent._enter_at_a_stretch_end()` asks whether the end is in view.
func _middle_of(end: Dictionary) -> Vector2:
	var along := (float(end.along) + 0.5) * Tuning.TILE_SIZE
	var across := (float(end.corridor) * CityMap.period() + Tuning.STREET_WIDTH * 0.5) \
			* Tuning.TILE_SIZE
	return Vector2(across, along) if end.vertical else Vector2(along, across)

func _look_at(camera: Camera2D, at: Vector2) -> void:
	camera.position = at
	camera.reset_physics_interpolation()
	camera.reset_smoothing()
	camera.force_update_scroll()
