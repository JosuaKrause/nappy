extends RefCounted
## Real Main startup verifies the narrow scripted seam independently of construction data.

func run(t) -> void:
	for side in ["hall", "yard"]:
		var path := "res://scene-recipes/power-station-%s.json" % side
		var result := _launch(PackedStringArray(["--recipe", path, "--recipe-validate"]))
		t.check(result.status == 0 and result.output.contains("[SceneRecipe] manifest"),
				"%s join boots through real Main: %s" % [side, result.output])
		for mode in ["free", "unknown"]:
			var rejected := _launch(PackedStringArray(["--recipe", path, "--recipe-mode", mode]))
			t.check(rejected.status != 0 and rejected.output.contains("scripted launch only"),
					"unsupported %s mode fails clearly before construction" % mode)
	var missing := _launch(PackedStringArray(["--recipe", "user://absent-builder-scene.json"]))
	t.check(missing.status != 0, "a missing recipe exits unsuccessfully")
	t.check(not GameSave._debug_run_uses_save(PackedStringArray(["--recipe", "scene.json"]), false),
			"recipe launch cannot use the player's desktop save")
	var loaded := SceneRecipe.load_file("res://scene-recipes/power-station-hall.json")
	loaded.data.setup.tutorial_complete = true
	loaded.data.playback = {"walk": "0.5s", "duration": 0.5, "capture_at": 0.1}
	var path := "user://builder-scripted-input.json"
	var output := "user://builder-scripted-input-manifest.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(loaded.data))
	file.close()
	var walked := _launch(PackedStringArray(["--recipe", path, "--recipe-manifest", output]))
	t.check(walked.status == 0, "scripted Main finishes successfully: %s" % walked.output)
	var parser := JSON.new()
	var parsed := parser.parse(FileAccess.get_file_as_string(output))
	t.check(parsed == OK, "scripted launch writes its final manifest")
	if parsed == OK:
		var manifest: Dictionary = parser.data
		t.check(manifest.playback_complete and manifest.completed_tick == roundi(0.5 * Engine.physics_ticks_per_second),
				"completion names the intended physics tick")
		t.check(float(manifest.final_actors.player.position[1]) > float(manifest.initial_actors.player.position[1]) + 5,
				"the real player moves south through the shared input script")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(output)

func _launch(args: PackedStringArray) -> Dictionary:
	var output: Array = []
	var command := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"),
			"--fixed-fps", "60", "--quit-after", "300", "--", "--no-telemetry"])
	command.append_array(args)
	var status := OS.execute(OS.get_executable_path(), command, output, true)
	var body := "\n".join(output)
	if body.contains("ERROR:") or body.contains("SCRIPT ERROR"):
		status = 1
	return {"status": status, "output": body}
