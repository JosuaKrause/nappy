extends RefCounted
## Exercise the actual runtime and argv readers. A tiny child scene isolates exit-status
## assertions without booting Main, constructing another city or quitting the suite's tree.

const EXAMPLE := "res://scene-recipes/power-station-hall.json"
const PROBE := """extends Node
class World extends Node2D:
	var frames := 0
	func _physics_process(_delta: float) -> void:
		frames += 1
		if Input.is_action_pressed("move_right"):
			position.x += 1
		if frames == 2 and position.x == 1:
			print("ONE_TICK_INPUT_COMPLETED")
func _ready() -> void:
	var scripted := DevFlags.recipe_mode() == "scripted"
	if DevFlags.is_rig() != scripted:
		get_tree().quit(12)
		return
	# The desktop policy is checked independently of headless's unconditional no-save gate.
	if GameSave._debug_run_uses_save(DevFlags.active_args(), false):
		get_tree().quit(13)
		return
	if GameSave.uses_save():
		get_tree().quit(14)
		return
	if "--probe-camera" in OS.get_cmdline_user_args():
		var runtime := SceneRecipeRuntime.new()
		runtime.configure({"data": {}, "manifest": {}, "anchors": {}}, true)
		add_child(runtime)
		var from := Camera2D.new()
		from.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
		from.position = Vector2(320, 240)
		from.position_smoothing_enabled = true
		add_child(from)
		from.make_current()
		var player := Stroller.new()
		player.facing = Vector2.RIGHT
		runtime._player = player
		runtime._settle_starting_camera()
		var settled_current := from.is_current()
		var settled_centre := from.get_screen_center_position()
		var frame_offset := Vector2(200, 0)
		runtime._install_fixed_camera(frame_offset)
		var fixed := runtime._fixed_camera
		from.position += Vector2(200, 100)
		player.free()
		runtime._player = null
		if not settled_current or from.offset != Vector2(Stroller.CAMERA_LOOK_AHEAD, 0) \
				or not fixed.is_current() or fixed.position != settled_centre + frame_offset \
				or fixed.zoom != from.zoom:
			get_tree().quit(18)
			return
		var zoom := ZoomOutCamera.new()
		runtime.add_child(zoom)
		runtime._zoom = zoom
		zoom.simulation_clock = runtime.elapsed
		zoom.setup(from, Rect2(0, 0, 4000, 4000), Vector2(1280, 720), 4, 0)
		runtime.tick = Engine.physics_ticks_per_second
		runtime.prepare_capture()
		var position_before := zoom._camera.position
		var zoom_before := zoom._camera.zoom
		zoom._process(100)
		if zoom.is_processing() or not get_tree().paused or zoom._elapsed != 1 \
				or zoom._camera.position != position_before or zoom._camera.zoom != zoom_before:
			get_tree().quit(17)
			return
		print("CAPTURE_CAMERA_FROZEN")
		get_tree().quit(0)
		return
	if "--probe-boundary" in OS.get_cmdline_user_args():
		var runtime := SceneRecipeRuntime.new()
		var seconds := 1.0 / Engine.physics_ticks_per_second
		var data := {"name": "one tick input", "playback": {"duration": seconds * 2,
			"walk": str(seconds) + "e1p", "observations": [
			{"tick": 1, "subject": "world", "condition": "near", "at": [1, 0], "distance": 0},
			{"tick": 2, "subject": "world", "condition": "near", "at": [1, 0], "distance": 0}]}}
		runtime.configure({"data": data, "anchors": {}, "manifest": {}}, true)
		var world := World.new()
		add_child(world)
		add_child(runtime)
		runtime.named.world = world
		runtime._active = true
		runtime._observe()
		runtime._apply_input()
		return
	if "--probe-observation" not in OS.get_cmdline_user_args():
		print("RECIPE_FLAGS_OK")
		get_tree().quit(0)
		return
	var runtime := SceneRecipeRuntime.new()
	var data := {"name": "failed observation", "playback": {"duration": 1.0 / 60.0,
		"observations": [{"tick": 1, "subject": "missing", "condition": "moving"}]}}
	runtime.configure({"data": data, "anchors": {}, "manifest": {}}, true)
	add_child(runtime)
	runtime.set_physics_process(false)
	runtime._active = true
	runtime._physics_process(1.0 / 60.0)
	if runtime._active or runtime.manifest.playback_complete:
		get_tree().quit(15)
		return
	if runtime.manifest.observations.size() != 1 or runtime.manifest.observations[0].passed:
		get_tree().quit(16)
		return
	print("OBSERVATION_STOPPED_BEFORE_SUCCESS")
	# Keep the runtime's own quit(1); this probe must not replace its failure status.
"""

func run(t) -> void:
	_test_schema(t)
	_test_a_task_gone_after_the_read(t)
	_test_arguments(t)
	_test_inputs(t)
	_test_real_argv_and_failure(t)

func _test_schema(t) -> void:
	var valid := {"setup": {"day": 1, "parent": "mother"},
			"playback": {"duration": 2, "walk": "0.5s0.5E1p", "camera": {"fixed": true}}}
	t.check(SceneRecipeRuntime.validate_runtime(valid).is_empty(), "valid optional runtime defaults are accepted")
	var mixed := {"setup": {"background": {"crowd": true, "uniform_walkers": true},
			"actors": [{"name": "walker", "kind": "walker", "at": [0, 0], "direction": "north"}]}}
	t.check(SceneRecipeRuntime.validate_runtime(mixed).is_empty(), "uniform background admits explicit walkers")
	mixed.setup.actors[0].kind = "car"
	t.check(not SceneRecipeRuntime.validate_runtime(mixed).is_empty(), "background still refuses pinned cars")
	mixed.setup.actors[0].kind = "walker"
	mixed.setup.background.uniform_walkers = false
	t.check(not SceneRecipeRuntime.validate_runtime(mixed).is_empty(), "random background still refuses pinned actors")
	var invalid: Array[Dictionary] = [
		{"setup": {"day": 1.5}},
		{"setup": {"day": 13, "seals": [{"segment": [3, 5, 0], "candidate": "cafe_pair"}],
			"barriers": [{"segment": [3, 5, 0], "end": "b"}]}},
		{"kind": "escape", "setup": {"day": 14, "seals": [{"segment": [5, 4, 0], "candidate": "cafe_pair"}]}},
		{"kind": "escape", "setup": {"day": 14, "gates": [{"segment": [7, 6, 0]}]}},
		{"kind": "escape", "setup": {"day": 14, "barriers": [{"segment": [3, 5, 0], "end": "b"}]}},
		{"kind": "escape", "setup": {"day": 14}, "city": {"closures": [{"segment": [3, 5, 0], "kind": "cordon"}]}},
		{"setup": {"parent": "unknown"}},
		{"setup": {"player": []}},
		{"setup": {"player": {"facing": "northwest"}}},
		{"setup": {"player": {"at": [0]}}},
		{"setup": {"player": {"excitement": INF}}},
		{"setup": {"background": {"crowd": "false"}}},
		{"setup": {"background": {"crowd": true, "crowd_scope": "unknown"}}},
		{"setup": {"background": {"crowd": true, "crowd_scope": "city"}}, "extent": {"scope": "bounded"}},
		{"setup": {"background": {"crowd_scope": "city"}}, "extent": {"scope": "full"}},
		{"setup": {"background": {"events": true}}, "extent": {"scope": "bounded"}},
		{"setup": {"background": {"crowd": true}}, "extent": {"scope": "bounded"}},
		{"setup": {"posters": "not an array"}},
		{"setup": {"posters": [{"at": [0, 0], "kind": "unknown"}]}},
		{"setup": {"day": 1, "posters": [{"at": [0, 0], "kind": "wanted"}]}},
		{"setup": {"progression": {"escape_part": "city"}}},
		{"setup": {"events": "not an array"}},
		{"setup": {"events": [{"name": "event", "row": "unknown", "at": [0, 0]}]}},
		{"setup": {"actors": [{"name": "actor", "kind": "train", "at": [0, 0], "direction": "east"}]}},
		{"setup": {"actors": [{"name": "player", "kind": "walker", "at": [0, 0], "direction": "east"}]}},
		{"setup": {"actors": [{"name": "actor", "kind": "walker", "at": [0, 0], "direction": "diagonal"}]}},
		{"setup": {"unsupported": true}},
		{"playback": {"walk": "1q"}},
		{"playback": {"duration": "two"}},
		{"playback": {"camera": {"zoom": 0}}},
		{"playback": {"camera": {"fixed": "yes"}}},
		{"playback": {"camera": {"fixed_offset": [200, 0]}}},
		{"playback": {"camera": {"fixed": true, "fixed_offset": [200]}}},
		{"playback": {"caption": false}},
		{"playback": {"observations": [{"tick": -1, "subject": "player", "condition": "moving"}]}},
		{"playback": {"observations": [{"tick": 1, "subject": "unknown", "condition": "moving"}]}},
		{"playback": {"observations": [{"tick": 1, "subject": "player", "condition": "teleporting"}]}},
		{"playback": {"observations": [{"tick": 1, "subject": "player", "condition": "near_player",
			"distance": 32, "walkers": 1}]}},
		{"playback": {"unsupported": true}},
	]
	for recipe in invalid:
		t.check(not SceneRecipeRuntime.validate_runtime(recipe).is_empty(),
				"malformed runtime data is rejected: %s" % [recipe])

## A task gone after she read the mark is one of two things. Placed and then gone, it expired as a
## played day's task can (day 10's neighbor home first): the manifest records the tick, `task`
## names nothing from then on, and the setup has not failed. Never placed, the director refused
## it: a failed setup, noticed and recorded in a scene played by hand as well.
func _test_a_task_gone_after_the_read(t) -> void:
	var director := ResistanceDirector.new()
	var mark := ContactPoint.new()
	director._read_mark = mark
	director._contact = null
	var placed := _task_runtime(director)
	var expired := ContactPoint.new()
	placed.named["task"] = expired
	placed.manifest.task["read_tick"] = 40
	placed.tick = 90
	placed._bind_task_names()
	placed.tick = 91
	placed._bind_task_names()
	t.check(placed.manifest.task.get("expired_tick") == 90 and not placed.named.has("task")
			and not placed.manifest.get("setup_failed", false),
			"a placed task that is gone expired at the tick it went: %s" % [placed.manifest.task])
	# Played by hand, the runtime's own tick is what notices the read, as it does in play.
	var refused := _task_runtime(director)
	t.add_child(refused)
	refused.set_physics_process(false)
	refused._hand_played = true
	director._scene_task_errors.append("setup.task: nowhere for it in this test")
	refused._physics_process(1.0 / Engine.physics_ticks_per_second)
	t.check(refused.tick == 1 and refused.manifest.get("setup_failed", false)
			and not refused.manifest.task.has("expired_tick"),
			"a task refused at the read fails the setup, noticed by a scene played by hand too")
	for node: Node in [placed, refused, expired, mark, director]:
		node.free()

## A runtime for `_bind_task_names()` alone, played by hand, its task's mark already started.
func _task_runtime(director: ResistanceDirector) -> SceneRecipeRuntime:
	var runtime := SceneRecipeRuntime.new()
	runtime.configure({"data": {"setup": {"task": {"mark": "mark"}}}, "manifest": {},
			"anchors": {}}, false)
	runtime._resistance = director
	runtime.manifest["task"] = {"mark": [0, 0]}
	return runtime

func _test_arguments(t) -> void:
	for args: PackedStringArray in [
		PackedStringArray(["--recipe-mode", "unknown"]),
		PackedStringArray(["--seed", "3"]),
		PackedStringArray(["--day", "3"]),
		PackedStringArray(["--walk", "1s"]),
		PackedStringArray(["--press", "pause", "0.1"]),
		PackedStringArray(["--tap", "1", "1"]),
		PackedStringArray(["--recipe-mode"]),
		PackedStringArray(["--screenshot", "out.png"]),
		PackedStringArray(["--recipe-mode", "free", "--after", "1"]),
	]:
		var loaded := SceneRecipeRuntime.load_recipe(EXAMPLE, args)
		t.check(not loaded.errors.is_empty(), "conflicting or unknown recipe arguments fail: %s" % [args])
	var output: Array = []
	var status := OS.execute("bash", PackedStringArray([
		ProjectSettings.globalize_path("res://tools/run.sh"), "--recipe", EXAMPLE,
		"--unknown-recipe-flag"]), output, true)
	t.check(status != 0 and str(output).contains("--unknown-recipe-flag"),
			"run.sh rejects an unknown flag before launching a game")

func _test_inputs(t) -> void:
	var runtime := SceneRecipeRuntime.new()
	runtime.configure({"data": {"playback": {"duration": 3, "walk": "1e1N1p"}},
			"anchors": {}, "manifest": {}}, true)
	runtime.tick = 0
	runtime._apply_input()
	t.check(Input.is_action_pressed("move_right") and not Input.is_action_pressed("run"),
			"walking script presses the real right input without running")
	runtime.tick = Engine.physics_ticks_per_second
	runtime._apply_input()
	t.check(Input.is_action_pressed("move_up") and Input.is_action_pressed("run")
			and not Input.is_action_pressed("move_right"), "turning releases the previous direction and presses real run input")
	runtime.tick = Engine.physics_ticks_per_second * 2
	runtime._apply_input()
	t.check(Input.get_vector("move_left", "move_right", "move_up", "move_down") == Vector2.ZERO
			and not Input.is_action_pressed("run"), "script pause releases movement and running")
	runtime.tick = 0
	runtime._apply_input()
	runtime._release_input()
	t.check(not Input.is_action_pressed("move_right"), "runtime cleanup releases its held input")
	runtime.free()

func _test_real_argv_and_failure(t) -> void:
	var stem := "user://scene_recipe_runtime_probe_%d" % OS.get_process_id()
	var script_path := stem + ".gd"
	var scene_path := stem + ".tscn"
	var script := FileAccess.open(script_path, FileAccess.WRITE)
	script.store_string(PROBE)
	script.close()
	var scene := FileAccess.open(scene_path, FileAccess.WRITE)
	scene.store_string("[gd_scene load_steps=2 format=3]\n[ext_resource type=\"Script\" path=\"%s\" id=\"1\"]\n[node name=\"Probe\" type=\"Node\"]\nscript = ExtResource(\"1\")\n" % script_path)
	scene.close()
	for mode in ["free", "scripted", "failure", "boundary", "camera"]:
		var args := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"),
				"--quit-after", "120", scene_path, "--", "--recipe", EXAMPLE,
				"--recipe-mode", "free" if mode == "free" else "scripted"])
		if mode == "failure":
			args.append("--probe-observation")
		elif mode == "boundary":
			args.append("--probe-boundary")
		elif mode == "camera":
			args.append("--probe-camera")
		var output: Array = []
		var status := OS.execute(OS.get_executable_path(), args, output, true)
		var text_output := "\n".join(output)
		t.check(not text_output.contains("SCRIPT ERROR") and not text_output.contains("ERROR:"),
				"%s child completes without engine errors: %s" % [mode, text_output])
		if mode == "failure":
			t.check(status == 1 and text_output.contains("OBSERVATION_STOPPED_BEFORE_SUCCESS"),
					"a failed observation at the final tick stops with failure instead of reporting playback success")
		elif mode == "boundary":
			t.check(status == 0 and text_output.contains("ONE_TICK_INPUT_COMPLETED"),
					"one-tick input moves once, observes after the world, and completes the final tick")
		elif mode == "camera":
			t.check(status == 0 and text_output.contains("CAPTURE_CAMERA_FROZEN"),
					"capture freezes camera at the shared physics tick even when idle time advances: %s"
					% text_output)
		else:
			t.check(status == 0 and text_output.contains("RECIPE_FLAGS_OK"),
					"%s recipe reads real argv, keeps the intended input mode and disables saves" % mode)
	DirAccess.remove_absolute(scene_path)
	DirAccess.remove_absolute(script_path)
	DirAccess.remove_absolute(script_path + ".uid")
