extends RefCounted
## What `main` boots and wires, the developer readout it hosts, the focus pause and the return
## window, and the ground a view is painted on.
##
## **`main` is booted for real.** Where a check is about what `main` builds or connects, the real
## `scenes/main.tscn` boots under the suite (`configure()` hands it its run configuration the way
## `RunConfig.at_boot()` does in play, `use_reload()` and `use_quit()` stand in for the two calls
## that would take the runner's own scene away), two real frames let its `_ready()` finish, and
## everything after that is what a player or the engine could do: a real touch pushed through the
## viewport onto the title's own button, the screens' signals, the engine's focus notifications on
## the `ReturnWindow` node, and real physics frames. Nodes are found by the names and classes the
## scene gives them. The readout, the return window and the screens are each driven alone through
## their own public setup where the check is theirs.
##
## A check that steps one step by hand with an injected delta says so where it does.

const UI := preload("res://tests/ui_screens.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const DAY_SUMMARY_SCENE := preload("res://scenes/ui/day_summary.tscn")
const PAUSE_SCREEN_SCENE := preload("res://scenes/ui/pause_screen.tscn")
const TITLE_SCREEN_SCENE := preload("res://scenes/ui/title_screen.tscn")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const DaySummaryScript := preload("res://src/ui/day_summary.gd")
const STROLLER_SCENE: PackedScene = preload("res://scenes/player/stroller.tscn")

const SEED := 4242

## A readout handed the world by hand: its label and layer, her, the baby and the day's clock, and
## the nodes to free. Built through the readout's own `setup()` and `watch()`, the way `main` does.
class ReadoutRig:
	var readout := DebugReadout.new()
	var label := Label.new()
	var layer := CanvasLayer.new()
	var stroller := Stroller.new()
	var baby := Baby.new()
	var day := DayController.new()

	func _init(t, config: RunConfig) -> void:
		t.add_child(layer)
		layer.add_child(label)
		var camera := Camera2D.new()
		camera.name = "Camera2D"
		camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
		stroller.add_child(camera)
		t.add_child(stroller)
		stroller.set_physics_process(false)
		baby.name = "Baby"
		stroller.add_child(baby)
		baby.set_physics_process(false)
		t.add_child(day)
		day.set_process(false)
		readout.setup(config, label, layer, GameState.header, null, Callable())
		readout.watch(stroller, baby, day)
		t.add_child(readout)

	## The frame graph the readout built on its layer, or null when it built none.
	func graph() -> FrameGraph:
		return layer.get_node_or_null("FrameGraph") as FrameGraph

	func free_all() -> void:
		readout.free()
		layer.free()
		day.free()
		stroller.free()

func run(t) -> void:
	t.gives_back_observers()
	await _test_a_placed_player_settles_with_her_lead_and_keeps_room_limits(t)
	await _test_the_readout_is_not_assembled_outside_a_debug_build(t)
	await _test_the_readout_flag_shows_it_on_a_release_build(t)
	_test_the_debug_mode_note_only_exists_when_requested(t)
	_test_the_frame_graph_only_exists_when_requested(t)
	_test_graph_starts_on_under_spikes_or_layers_six(t)
	_test_key_six_resolves_to_the_frame_graph_layer(t)
	_test_key_six_toggles_the_graph_independent_of_four(t)
	_test_the_run_configuration_starts_the_graph(t)
	await _test_key_six_twice_empties_the_ring(t)
	await _test_the_title_hides_the_graph_and_keeps_its_ring(t)
	await _test_the_title_joystick_buttons_carry_l_and_r(t)
	await _test_a_left_joystick_press_on_the_title_sets_the_controls_mode(t)
	await _test_a_right_joystick_press_on_the_title_sets_the_controls_mode(t)
	await _test_the_title_choice_survives_the_handover_to_the_escape(t)
	await _test_a_session_on_one_booted_game(t)
	_test_the_unclamped_view_at_every_corner_is_painted(t)
	_test_the_overview_is_landscape_to_every_edge(t)
	_test_no_focus_pause_from_args(t)
	_test_no_focus_pause_from_query(t)
	await _test_return_ignores_input_for_half_a_second(t)
	await _test_return_window_always_ends(t)
	_test_return_window_needs_a_departure(t)
	_test_return_window_is_off_under_the_override(t)
	_test_is_rig_from_args(t)
	_test_rig_quit_seconds_from(t)
	ControlsMode.forget()
	# The restart wiring the suite drove stamped the title's guard; give it back.
	TitleScreen._restarted_at_msec = -INF
	GameState.start_run(SEED)

# ------------------------------------------------------------------ finding and booting ---

## Every node under `root` that is a `type_name`: a script class by its `class_name` (the scene
## root of a screen is one), anything else by the engine's class.
func _all(root: Node, type_name: String) -> Array[Node]:
	var found: Array[Node] = []
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		pending.append_array(node.get_children())
		if node != root and _is_a(node, type_name):
			found.append(node)
	return found

func _is_a(node: Node, type_name: String) -> bool:
	var script: Script = node.get_script()
	while script:
		if script.get_global_name() == type_name \
				or script.resource_path.get_file().get_basename().to_pascal_case() == type_name:
			return true
		script = script.get_base_script()
	return node.is_class(type_name)

## The one node of `type_name` under `root`, or null.
func _one(root: Node, type_name: String) -> Node:
	var found := _all(root, type_name)
	return found[0] if found.size() == 1 else null

## What a boot is handed to count a reload or a quit that would otherwise take the runner's scene
## away: `reloads` and `quits` gain an entry each time `main` asks for one.
class Calls:
	var reloads: Array[int] = []
	var quits: Array[int] = []

	func reload() -> void:
		reloads.append(1)

	func quit() -> void:
		quits.append(1)

## The real `main.tscn`, configured on a debug build (so the flags in `words` answer), with the
## reload and the quit handed to `calls`, not yet in the tree.
func _instance(words: Array, calls: Calls) -> Node2D:
	var all := PackedStringArray(["--no-save", "--no-telemetry", "--seed", str(SEED)])
	all.append_array(PackedStringArray(words))
	var main: Node2D = MAIN_SCENE.instantiate()
	main.configure(RunConfig.parse(all, "", true))
	main.use_reload(calls.reload)
	main.use_quit(calls.quit)
	return main

## Puts a configured `main` in the tree and lets the two frames its `_ready()` awaits pass, so the
## run, the day and the title are built.
func _enter(t, main: Node2D) -> void:
	t.add_child(main)
	await t.get_tree().process_frame
	await t.get_tree().process_frame

func _boot(t, words: Array, calls: Calls) -> Node2D:
	var main := _instance(words, calls)
	await _enter(t, main)
	return main

func _shut(t, main: Node2D) -> void:
	t.get_tree().paused = false
	main.free()

## A press on the title's button `button_name` ("Left", "Right", "Tap"), pushed through the viewport
## where the layout really draws it, and the frames the tap's acknowledgement takes.
func _press_on_the_title(t, main: Node2D, button_name: String) -> void:
	var title := _one(main, "TitleScreen")
	await UI.frames(t)
	UI.push(title, UI.touch_at(UI.centre(UI.button(title, button_name)), true))
	await UI.frames(t)

## What a player's keys on the title end up as: a run started by a key, in tap mode.
func _start_by_key(t, main: Node2D) -> void:
	_one(main, "TitleScreen").start_requested.emit(
			ControlsMode.Mode.TAP, true, ControlsMode.Side.LEFT)
	await UI.frames(t)

func _key(code: Key, pressed := true, echo := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	return event

func _config(words: Array, debug_build := true, query := "") -> RunConfig:
	return RunConfig.parse(PackedStringArray(words), query, debug_build)

# ------------------------------------------------------------------------- the camera ---

## The camera the player carries, the way a booted `main` hands it over to her. The boot camera
## stands on the doorstep before she exists and is freed once hers stands where it stood; the
## viewport's current camera is then hers, on her, with her normal smoothing, before any frame has
## smoothed it.
func _check_boot_camera_handoff(t, main: Node2D, interpolated: bool) -> void:
	var player := _one(main, "Stroller") as Stroller
	var camera: Camera2D = player.get_node("Camera2D")
	print("CAMERA_HANDOFF interpolated=%s player=%s screen=%s target=%s" % [interpolated,
			player.global_position, camera.get_screen_center_position(),
			camera.get_target_position()])
	t.check(main.get_node_or_null("BootCamera") == null,
			"the boot camera is gone once her own stands (interpolation %s)" % interpolated)
	t.check(camera.is_current() and camera.get_screen_center_position().is_equal_approx(
			player.global_position),
			"boot handoff starts on the placed player before any smoothing frame (interpolation %s)"
			% interpolated)
	t.check(camera.position_smoothing_enabled, "boot handoff preserves normal follow smoothing")

func _test_a_placed_player_settles_with_her_lead_and_keeps_room_limits(t) -> void:
	var player: Stroller = STROLLER_SCENE.instantiate()
	t.add_child(player)
	player.set_physics_process(false)
	var camera: Camera2D = player.get_node("Camera2D")
	camera.make_current()
	var destination := Vector2(1800, 1400)
	player.reset_at(destination, Vector2.RIGHT)
	SceneRecipeRuntime.settle_camera_on(camera, player)
	print("CAMERA_SETTLED interpolation=%s screen=%s offset=%s" % [
			t.get_tree().physics_interpolation, camera.get_screen_center_position(), camera.offset])
	t.check(camera.get_screen_center_position().is_equal_approx(
			destination + Vector2(Stroller.CAMERA_LOOK_AHEAD, 0)),
			"a settled recipe starts at the actual player with its authored facing lead")
	player.set_camera_limits(Rect2(1000, 1000, 1600, 1200))
	player.reset_at(Vector2(1500, 1500))
	camera.force_update_scroll()
	t.check(camera.limit_left == 1000 and camera.limit_bottom == 2200,
			"a placed interior player keeps the room's camera limits")
	player.clear_camera_limits()
	t.check(camera.limit_left < 0 and camera.limit_right > 100000,
			"returning outdoors removes the interior's camera limits")
	player.free()
	await t.get_tree().process_frame

# ----------------------------------------------------------------------- the readout ---

## A release build never assembles the readout: not into the label, and not into a hidden one. A
## debug build still builds it, so the gate is not just "always empty". Real frames carry the
## readout's own `_process()`.
func _test_the_readout_is_not_assembled_outside_a_debug_build(t) -> void:
	var release := ReadoutRig.new(t, _config([], false))
	await UI.frames(t)
	t.check(release.label.text == "",
			"the release shape never assembles the readout, not even into a hidden label")
	t.check(not release.label.visible, "and the label it would have filled is hidden")
	release.free_all()

	var debug := ReadoutRig.new(t, _config([], true))
	await UI.frames(t)
	t.check("seed" in debug.label.text and "fps" in debug.label.text,
			"a debug build still builds the readout the rigs and tools/shot.sh read")
	debug.free_all()

## `?debug=1` (`--debug`) is read independently of the build, so a release build still assembles the
## readout the moment it holds. The text is re-set a few times a second, not every frame.
func _test_the_readout_flag_shows_it_on_a_release_build(t) -> void:
	var rig := ReadoutRig.new(t, _config(["--debug"], false))
	await UI.frames(t)
	t.check("seed" in rig.label.text and "fps" in rig.label.text,
			"?debug=1 on a release build assembles the same readout a debug build gets")

	# The interval's arithmetic: one step at a time with an injected delta, not real frames, because
	# a real frame's length is not the 16 ms the first check means and the readout's own frames
	# would move the interval under it. The readout's own processing is off for these steps.
	rig.readout.set_process(false)
	# The real frames above have been counting the interval down by their own lengths, so one full
	# interval is stepped first: it rebuilds the text and starts the interval over at exactly
	# `READOUT_INTERVAL`, which the 16 ms step then always lands inside of.
	rig.readout._process(DebugReadout.READOUT_INTERVAL)
	var first := rig.label.text
	GameState.header.run_seed += 1
	rig.readout._process(0.016)
	t.check(rig.label.text == first, "a frame inside the interval leaves the readout's text alone")
	rig.readout._process(DebugReadout.READOUT_INTERVAL)
	t.check(rig.label.text != first, "the interval's end rebuilds it")
	GameState.header.run_seed -= 1
	rig.free_all()

	# Switching the layer back on rebuilds it at once: key 4 answers on a debug build alone.
	var debug := ReadoutRig.new(t, _config(["--debug"], true))
	await UI.frames(t)
	UI.push(debug.readout, _key(KEY_4))
	await UI.frames(t)
	UI.push(debug.readout, _key(KEY_4))
	debug.label.text = ""
	await UI.frames(t)
	t.check(debug.label.text != "", "switching the layer back on rebuilds it at once")
	debug.free_all()

## The note `?debug=1` adds exists only when the flag holds; an ordinary debug build without it gets
## none.
func _test_the_debug_mode_note_only_exists_when_requested(t) -> void:
	var plain := ReadoutRig.new(t, _config([], true))
	t.check(plain.readout.get_node_or_null("DebugModeNote") == null,
			"no note is built at all when the flag was not asked for")
	plain.free_all()

	var flagged := ReadoutRig.new(t, _config(["--debug"], false))
	var note := flagged.readout.get_node_or_null("DebugModeNote")
	t.check(note != null and note.get_parent() == flagged.readout,
			"the flag builds the note and parents it under the readout")
	flagged.free_all()

## A release build carrying neither flag never builds the graph; one carrying `?debug=1` gets it
## parented under the readout's own layer, **off by default**, unlike the readout it sits under
## *(2026-09-15, the player: "spike view should be independent of debug layer 4 it should be its
## own debug layer and turned off by default unless --spikes is set".)*
func _test_the_frame_graph_only_exists_when_requested(t) -> void:
	var none := ReadoutRig.new(t, _config([], false))
	t.check(none.graph() == null, "no graph is built at all when neither flag was asked for")
	none.free_all()

	var flagged := ReadoutRig.new(t, _config(["--debug"], false))
	var graph := flagged.graph()
	t.check(graph != null and graph.get_parent() == flagged.layer,
			"the flag builds the graph and parents it under the readout's own CanvasLayer")
	t.check(not flagged.readout.graph_on() and not graph.visible,
			"but it starts off, unlike the readout it sits under — neither --spikes nor --layers 6 was given")
	flagged.free_all()

## The boot policy with the command line taken out of it: `--spikes` alone starts the graph on,
## `--layers` naming 6 does the same, and neither leaves it off. Driven through the configuration
## the readout is handed.
func _test_graph_starts_on_under_spikes_or_layers_six(t) -> void:
	var cases := [
		[["--spikes"], true, "--spikes alone starts the graph on"],
		[["--layers", "6"], true, "--layers naming 6 starts it on the same way, without --spikes"],
		[[], false, "neither flag given leaves it off, the default"],
		[["--layers", "1,5"], false, "--layers naming other layers does not turn this one on"],
	]
	for row: Array in cases:
		var rig := ReadoutRig.new(t, _config(row[0]))
		t.check(rig.readout.graph_on() == row[1], row[2])
		rig.free_all()

## What a player reaches: the key. `6` is the spike view; a release, not a press, does nothing; an
## echo does nothing, a held key being one request.
func _test_key_six_resolves_to_the_frame_graph_layer(t) -> void:
	var rig := ReadoutRig.new(t, _config([]))
	UI.push(rig.readout, _key(KEY_6, false))
	t.check(not rig.readout.graph_on(), "a release, not a press, does nothing")
	UI.push(rig.readout, _key(KEY_6, true, true))
	t.check(not rig.readout.graph_on(),
			"an echo does nothing — a held key is one request, not a flood of them")
	UI.push(rig.readout, _key(KEY_6))
	t.check(rig.readout.graph_on() and rig.graph().visible, "6 is the spike view")
	rig.free_all()

## `6` toggles the graph's own switch and visibility, independent of `4` — *(2026-09-15, the
## player: "spike view should be independent of debug layer 4".)* Pressing `4` first proves the two
## do not share a switch; pressing `6` then proves it has one of its own.
func _test_key_six_toggles_the_graph_independent_of_four(t) -> void:
	var rig := ReadoutRig.new(t, _config([]))
	var graph := rig.graph()
	t.check(not graph.visible, "the graph starts off")
	UI.push(rig.readout, _key(KEY_4))
	t.check(not rig.label.visible and not graph.visible,
			"4 turns the readout off and leaves the graph exactly where it was")
	UI.push(rig.readout, _key(KEY_6))
	t.check(graph.visible, "6 turns the graph on")
	UI.push(rig.readout, _key(KEY_4))
	t.check(rig.label.visible and graph.visible,
			"4 turns the readout back on and still leaves the graph alone")
	UI.push(rig.readout, _key(KEY_6))
	t.check(not graph.visible, "6 turns the graph back off")
	rig.free_all()

## A readout handed `--spikes` or `--layers 6` builds the graph already on; one handed neither
## builds it off.
func _test_the_run_configuration_starts_the_graph(t) -> void:
	for case in [[["--spikes"], true], [["--layers", "6"], true], [[], false]]:
		var rig := ReadoutRig.new(t, _config(case[0]))
		t.check(rig.graph().visible == case[1],
				"the graph starts %s for %s" % ["on" if case[1] else "off", str(case[0])])
		rig.free_all()

## Pressing `6` twice must leave the ring empty rather than merely hidden, so a graph turned back on
## fills from that moment instead of picking up a stale window. *(2026-09-15: "spike recording
## should only be on while the layer is on. that means toggling the layer twice will lead to a
## blank frame array".)* The ring is fed by the readout's own frames.
func _test_key_six_twice_empties_the_ring(t) -> void:
	var rig := ReadoutRig.new(t, _config([]))
	var graph := rig.graph()
	UI.push(rig.readout, _key(KEY_6))
	var frames := 10
	for i in frames:
		await rig.readout.get_tree().process_frame
	t.check(graph.frames().size() == frames,
			"the ring holds what the layer saw while it was on (%d of %d)" % [graph.frames().size(), frames])
	UI.push(rig.readout, _key(KEY_6))
	t.check(graph.frames().is_empty(), "turning the layer back off empties the ring")
	UI.push(rig.readout, _key(KEY_6))
	t.check(graph.frames().is_empty(),
			"and turning it back on again starts from empty, not from what the ring held before")
	rig.free_all()

## *(2026-09-15, the coordinator, relaying the player: "the graph must not draw over the title
## screen ... the independence the player asked for is from the 4 key, not from the title".)* The
## readout is told the title opens and closes (`open_the_title()`, `close_the_title()` and
## `show_for_the_walk()`, which `main` calls): the graph comes off with its ring kept, `4` does not
## move it while the title is open, and the walk brings it back with the ring as it was left.
func _test_the_title_hides_the_graph_and_keeps_its_ring(t) -> void:
	var rig := ReadoutRig.new(t, _config([]))
	var graph := rig.graph()
	UI.push(rig.readout, _key(KEY_6))
	for i in 2:
		graph.push(0.010)
	t.check(graph.visible and graph.frames().size() == 2,
			"the graph is on and holds two frames before the title opens")

	rig.readout.open_the_title()
	t.check(not graph.visible, "opening the title hides the graph")
	t.check(graph.frames().size() == 2,
			"but does not clear the ring — only a 6 toggle-off does that")

	UI.push(rig.readout, _key(KEY_4))
	t.check(not graph.visible, "4 does not move the graph while the title is open")

	rig.readout.close_the_title()
	rig.readout.show_for_the_walk()
	t.check(graph.visible, "closing the title shows the graph again")
	t.check(graph.frames().size() == 2, "with the ring exactly as it was left")

	UI.push(rig.readout, _key(KEY_4))
	t.check(graph.visible, "and 4 still does not move it once the title is closed again")
	rig.free_all()
	await t.get_tree().process_frame

# ---------------------------------------------------------------- the title and controls ---

## azure-puffin, #665: the title's two joystick buttons carry an "L" and an "R" so they read as
## different settings; the tap button carries no mark.
func _test_the_title_joystick_buttons_carry_l_and_r(t) -> void:
	var title: TitleScreen = TITLE_SCREEN_SCENE.instantiate()
	title.use_run(GameState)
	t.add_child(title)
	var left := title.get_node("Root/Choice/LeftColumn/Left") as ModeButton
	var right := title.get_node("Root/Choice/RightColumn/Right") as ModeButton
	var tap := title.get_node("Root/Choice/TapColumn/Tap") as ModeButton
	t.check((left.get_node("Letter") as Label).text == "L", "the left joystick button says L")
	t.check((right.get_node("Letter") as Label).text == "R", "the right joystick button says R")
	t.check(not tap.has_node("Letter"), "the tap button carries no letter")
	t.check((left.get_node("Letter") as Label).mouse_filter == Control.MOUSE_FILTER_IGNORE,
			"the letter never catches a press meant for its button")
	title.free()
	await t.get_tree().process_frame

## **A left joystick press on the title, on the boot the rig flags configure.** A real touch on the
## left joystick button, on a booted game, sets that mode on the one reader, the counter hears the
## choice, and the day begins. The boot is handed `--controls joystick-right`, which steers from the
## right with the joystick before any title answers; `--spikes`, under which the graph never draws
## over the title screen, so it is on and hidden behind it, `4` and `6` do not bring it out, and
## the walk shows it; and `--no-focus-pause` (which `--screenshot` implies), under which losing
## focus opens no pause. Also the boot's camera handoff, with interpolation on.
func _test_a_left_joystick_press_on_the_title_sets_the_controls_mode(t) -> void:
	var interpolated: bool = t.get_tree().physics_interpolation
	t.get_tree().physics_interpolation = true
	var calls := Calls.new()
	var main := await _boot(t, ["--controls", "joystick-right", "--spikes", "--no-focus-pause"], calls)
	_check_boot_camera_handoff(t, main, true)
	var controls := _one(main, "TouchControls") as TouchControls
	t.check(controls.controls_mode() == ControlsMode.Mode.JOYSTICK
			and controls.run_button_center() == TouchControls.FOCUS_LEFT,
			"`--controls joystick-right` steers from the right with the joystick before any title answers")
	var readout := main.get_node("DebugReadout") as DebugReadout
	var graph := _one(main, "FrameGraph") as FrameGraph
	t.check(readout.graph_on() and not graph.visible,
			"under --spikes the graph is on and the title keeps it off the screen")
	UI.push(readout, _key(KEY_4))
	t.check(not graph.visible, "4 does not move the graph while the title is open")
	UI.push(readout, _key(KEY_6))
	UI.push(readout, _key(KEY_6))
	t.check(readout.graph_on() and not graph.visible, "nor does 6 draw it over the title")
	var chosen: Array = []
	var record := func(joystick: bool, by_key: bool) -> void: chosen.append([joystick, by_key])
	EventBus.controls_chosen.connect(record)
	var title := _one(main, "TitleScreen") as TitleScreen
	t.check(title.is_open(), "the boot opens on the title")
	await _press_on_the_title(t, main, "Left")
	EventBus.controls_chosen.disconnect(record)
	t.check(controls.controls_mode() == ControlsMode.Mode.JOYSTICK,
			"pressing the joystick button on the title screen sets that mode on the one control reader")
	t.check(controls.run_button_center() == TouchControls.FOCUS_RIGHT,
			"the left joystick button steers from the left, with Run on the right")
	t.check(chosen == [[true, false]], "and the counter hears which input began the run")
	t.check(not title.is_open(), "and the title is closed, the day begun")
	t.check(graph.visible, "closing the title shows the graph again")
	UI.push(readout, _key(KEY_4))
	t.check(graph.visible, "and 4 still does not move it once the title is closed again")

	# `--no-focus-pause` reaches `main` through the configuration: a played day loses focus and
	# nothing opens.
	var pause := _one(main, "PauseScreen") as PauseScreen
	t.get_tree().paused = false
	main.get_node("ReturnWindow").notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not pause.is_open(), "--no-focus-pause turns off the notification's own pause")
	t.check(not t.get_tree().paused, "and the tree keeps running")
	t.get_tree().physics_interpolation = interpolated
	_shut(t, main)

func _test_a_right_joystick_press_on_the_title_sets_the_controls_mode(t) -> void:
	var interpolated: bool = t.get_tree().physics_interpolation
	t.get_tree().physics_interpolation = false
	var calls := Calls.new()
	var main := await _boot(t, [], calls)
	_check_boot_camera_handoff(t, main, false)
	await _press_on_the_title(t, main, "Right")
	var controls := _one(main, "TouchControls") as TouchControls
	t.check(controls.controls_mode() == ControlsMode.Mode.JOYSTICK,
			"the right joystick button sets the joystick too")
	t.check(controls.run_button_center() == TouchControls.FOCUS_LEFT,
			"and the right one steers from the right, with Run on the left")
	t.get_tree().physics_interpolation = interpolated
	_shut(t, main)

## **A joystick-right player reaches the escape still joystick-right.** *(2026-10-10, the player:
## "permanently for the sitting".)* The day-14 hand-over reloads the scene and the escape's boot
## opens no title, so its fresh controls take the title's answer this process remembers rather than
## the rig's default. The previous test's right joystick press is that answer.
func _test_the_title_choice_survives_the_handover_to_the_escape(t) -> void:
	t.check(ControlsMode.has_remembered() and ControlsMode.remembered_mode() == ControlsMode.Mode.JOYSTICK
			and ControlsMode.remembered_side() == ControlsMode.Side.RIGHT,
			"the title's answer is remembered for the sitting")
	GameState.start_run(SEED)
	GameState.header.day = Tuning.RUN_LENGTH_DAYS
	GameState.facts.escape_section = DaySpec.Section.CITY
	var calls := Calls.new()
	var main := await _boot(t, [], calls)
	var controls := _one(main, "TouchControls") as TouchControls
	t.check(controls.controls_mode() == ControlsMode.Mode.JOYSTICK
			and controls.run_button_center() == TouchControls.FOCUS_LEFT,
			"the escape's controls keep the joystick, steering from the right with Run on the left")
	# A section's brief stands in front of the walk, and the walk's tick does not count behind it
	# even with the tree running.
	var summary := _one(main, "DaySummary") as DaySummaryScript
	t.check(summary.is_showing(), "a section's brief is up over the escape")
	GameState.header.play_ticks = 0
	main.get_tree().paused = false
	for i in 4:
		await main.get_tree().physics_frame
	t.check(GameState.header.play_ticks == 0,
			"and a brief in front of the walk adds no tick, with the tree running behind it")
	GameState.facts.escape_section = DaySpec.Section.NONE
	_shut(t, main)
	GameState.start_run(SEED)

## **A session on one booted game, in the order a session meets the screens.** The title opens once
## per boot, so the checks that start from it share one boot: what the boot builds, the title with
## the tree running behind it, a run started by a key, a played day (the walk's tick), the focus
## notifications over each screen, day 14's hand-over, and the ending's restart and quit wiring.
## The run is fresh and seeded, so the same city is played on every run of the suite.
func _test_a_session_on_one_booted_game(t) -> void:
	var saved_paused: bool = t.get_tree().paused
	var baseline := GameState.save_snapshot()
	GameState.header.play_ticks = 42
	GameState.start_run(SEED)
	t.check(GameState.header.play_ticks == 0, "start_run() zeroes the clock with the rest of the run")
	var calls := Calls.new()
	var main := _instance([], calls)
	await _check_a_boot_builds_the_one_control_reader(t, main)
	await _check_the_title_then_a_key_starts_in_tap(t, main)
	await _check_play_seconds_only_advance_while_the_world_moves(t, main)
	await _check_focus_loss(t, main)
	await _check_a_won_day_fourteen_hands_over(t, main, calls)
	await _check_the_summary_and_pause_restart_signals_are_both_connected(t, main, calls)
	_shut(t, main)
	GameState.restore_snapshot(baseline)
	GameState.facts.escape_section = DaySpec.Section.NONE
	t.get_tree().paused = saved_paused
	GameState.start_run(SEED)

## **One node goes into the tree, not a choice between two.** `TouchControls` is the whole of the
## pointer scheme regardless of which aiming mode is chosen — the boot builds the one node either
## way and hands it a starting mode from the configured `--controls` word. A run with no word gets
## `TAP`, and a boot that opens its title starts from the rig's default even when an earlier title
## answered. A boot with no `--start-escape` opens on the title of a day in the city.
func _check_a_boot_builds_the_one_control_reader(t, main: Node2D) -> void:
	t.check(_all(main, "TouchControls").is_empty(), "nothing is built before _ready() runs")
	await _enter(t, main)
	var readers := _all(main, "TouchControls")
	t.check(readers.size() == 1, "and the boot builds exactly one control reader")
	t.check((_one(main, "TitleScreen") as TitleScreen).is_open()
			and not (_one(main, "DaySummary") as DaySummaryScript).is_showing()
			and _one(main, "City") != null and _one(main, "InteriorScene") == null,
			"a boot with no --start-escape opens on the title of a day in the city, never on a "
			+ "section's brief, and never builds the interior scene at all")
	var controls := readers[0] as TouchControls
	t.check(controls.get_parent() is CanvasLayer and controls.get_parent().get_parent() == main,
			"parented under the layer it builds alongside it")
	t.check(controls.controls_mode() == ControlsMode.Mode.TAP,
			"and gives it TAP, with no --controls word, as a starting mode; the title asks again")
	t.check(_one(main, "ResistanceDirector") != null
			and not _one(main, "ResistanceDirector").has_method("_process"),
			"the resistance has no frame hook of its own, so its clock cannot run on a drawn "
			+ "frame's length")

## The title has nothing behind it to pause (the same reason the `pause` action itself does not open
## over it) and the walk's tick does not count behind it with the tree running; a key then begins
## the run in tap mode and the counter hears it as a key.
func _check_the_title_then_a_key_starts_in_tap(t, main: Node2D) -> void:
	var title := _one(main, "TitleScreen") as TitleScreen
	var pause := _one(main, "PauseScreen") as PauseScreen
	var window := main.get_node("ReturnWindow") as ReturnWindow
	var tree: SceneTree = t.get_tree()
	tree.paused = false
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not pause.is_open(), "the title screen has nothing behind it to pause")
	t.check(not tree.paused, "so the tree keeps running")
	for i in 4:
		await tree.physics_frame
	t.check(title.is_open() and GameState.header.play_ticks == 0,
			"the title screen does not advance the clock, even with the tree unpaused behind it")
	var chosen: Array = []
	var record := func(joystick: bool, by_key: bool) -> void: chosen.append([joystick, by_key])
	EventBus.controls_chosen.connect(record)
	await _start_by_key(t, main)
	EventBus.controls_chosen.disconnect(record)
	var controls := _one(main, "TouchControls") as TouchControls
	t.check(controls.controls_mode() == ControlsMode.Mode.TAP, "a key begins the run in tap mode")
	t.check(chosen == [[false, true]],
			"and the counter hears which input began each run, a key as a key")
	t.check(not title.is_open(), "and the title is closed, the day begun")

## `GameState.header.play_ticks` has exactly one owner, `main`'s physics tick, which counts a tick
## only once a day is actually running, walking or returning, with the tree unpaused — and counts
## ticks, never a drawn frame's length, so a long frame adds no play time (inbox #866 in
## minty-dolphin) — and the same tick runs the day's countdown. Played with real physics frames; a
## lag spike is a real stall of the frame.
func _check_play_seconds_only_advance_while_the_world_moves(t, main: Node2D) -> void:
	var tree: SceneTree = t.get_tree()
	var day := _one(main, "DayController") as DayController
	var summary := _one(main, "DaySummary") as DaySummaryScript
	var pause := _one(main, "PauseScreen") as PauseScreen
	var tick := 1.0 / Engine.physics_ticks_per_second
	var stepped := [0]
	var count := func() -> void: stepped[0] += 1
	tree.physics_frame.connect(count)

	await tree.physics_frame
	var ticks_before: int = GameState.header.play_ticks
	var time_before := day.time_remaining
	stepped[0] = 0
	for i in 5:
		await tree.physics_frame
	t.check(GameState.header.play_ticks - ticks_before == stepped[0] and stepped[0] >= 5,
			"a walking tick with the tree unpaused advances the clock by one tick (%d of %d)"
			% [GameState.header.play_ticks - ticks_before, stepped[0]])
	t.check(is_equal_approx(GameState.header.play_seconds() - ticks_before * tick,
			stepped[0] * tick),
			"play seconds are the ticks, one physics tick each")
	t.check(absf((time_before - day.time_remaining) - stepped[0] * tick) < 0.0001,
			"and the day's countdown by the same ticks (%.4f of %.4f)"
			% [time_before - day.time_remaining, stepped[0] * tick])

	# A drawn frame a quarter second long, the lag spike a slow machine draws: the frame's own
	# length adds nothing. Only the ticks the engine steps count.
	await tree.physics_frame
	ticks_before = GameState.header.play_ticks
	time_before = day.time_remaining
	stepped[0] = 0
	OS.delay_msec(250)
	await tree.physics_frame
	await tree.physics_frame
	t.check(GameState.header.play_ticks - ticks_before == stepped[0],
			"a long drawn frame adds no play time beyond the ticks that ran (%d of %d)"
			% [GameState.header.play_ticks - ticks_before, stepped[0]])
	t.check(absf((time_before - day.time_remaining) - stepped[0] * tick) < 0.0001,
			"and moves the day's countdown by those ticks alone (%.4f of %.4f)"
			% [time_before - day.time_remaining, stepped[0] * tick])

	# The escape's countdown: a day on a hundredths clock is told the drawn frame's position inside
	# the tick, never moved by it.
	var escape_day := DayController.new()
	main.add_child(escape_day)
	escape_day.setup((_one(main, "City") as City).map, _one(main, "Stroller"), GameState)
	escape_day.spec = DaySpec.for_section(DaySpec.Section.BUILDING, 180.0)
	escape_day.start(30.0)
	await tree.process_frame
	OS.delay_msec(250)
	await tree.process_frame
	await tree.process_frame
	t.check(is_equal_approx(escape_day.time_remaining, 30.0),
			"and a long drawn frame moves the escape's countdown not at all (%.4f)"
			% escape_day.time_remaining)
	escape_day.free()

	# The pause screen: phase stays WALKING (a day in progress, Esc pressed), the tree pauses.
	ticks_before = GameState.header.play_ticks
	time_before = day.time_remaining
	var esc := InputEventAction.new()
	esc.action = &"pause"
	esc.pressed = true
	UI.push(main, esc)
	t.check(pause.is_open() and tree.paused, "Esc opens the pause screen and pauses the tree")
	for i in 4:
		await tree.physics_frame
	t.check(GameState.header.play_ticks == ticks_before and day.time_remaining == time_before,
			"a paused tick does not, nor does the day's countdown run")
	pause.close()

	# The day summary: the day ends for real, a short one running out, so the summary arrives in the
	# shape a real day-end tick arrives in (phase OVER, the tree paused).
	day.start(0.1)
	for i in 30:
		await tree.physics_frame
		if day.phase == GameEnums.DayPhase.OVER:
			break
	t.check(day.phase == GameEnums.DayPhase.OVER and summary.is_showing(),
			"the day ran out and its summary is up")
	ticks_before = GameState.header.play_ticks
	for i in 4:
		await tree.physics_frame
	t.check(GameState.header.play_ticks == ticks_before,
			"the day summary (phase OVER, tree paused) does not advance it either")
	tree.paused = false
	for i in 4:
		await tree.physics_frame
	t.check(GameState.header.play_ticks == ticks_before,
			"nor with the tree running behind it: the flow, not the pause, holds the walk")

	# Its continue starts the next day, and a walking tick afterwards counts again rather than the
	# clock having latched off.
	UI.push(summary, UI.touch_at(UI.centre(UI.button(summary, "Continue")), true))
	await UI.frames(t)
	await tree.physics_frame
	ticks_before = GameState.header.play_ticks
	for i in 3:
		await tree.physics_frame
	t.check(GameState.header.play_ticks > ticks_before,
			"and a walking tick afterwards resumes rather than having latched off")
	tree.physics_frame.disconnect(count)

## Puts the screens a focus check leaves behind away: the pause closed, the summary dismissed, the
## tree running, and the window's own half second over.
func _reset_the_screens(t, main: Node2D) -> void:
	(_one(main, "PauseScreen") as PauseScreen).close()
	(_one(main, "DaySummary") as DaySummaryScript).dismiss()
	main.get_node("ReturnWindow").end(true)
	t.get_tree().paused = false

## Losing focus on a played day, the summary and the ending over it, the pause already open. The
## engine's own notification goes to the return window, which is what the OS sends.
func _check_focus_loss(t, main: Node2D) -> void:
	var window := main.get_node("ReturnWindow") as ReturnWindow
	var pause := _one(main, "PauseScreen") as PauseScreen
	var summary := _one(main, "DaySummary") as DaySummaryScript

	# The heart of the milestone: losing focus during a played day reaches the same
	# `PauseScreen.open()` the `pause` action does.
	t.get_tree().paused = false
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(pause.is_open(), "losing focus opens the same pause screen the pause action does")
	t.check(t.get_tree().paused, "and pauses the tree behind it, exactly as that action leaves it")

	# The pause already open stays exactly as it was.
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(pause.is_open(), "the pause stays exactly as it was — open, not toggled")

	# The decided detail this milestone leaves open to overturn: getting focus back does not
	# resume — the player continues when they are back.
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	t.check(pause.is_open() and t.get_tree().paused,
			"getting focus back does not resume — the player continues when they are back")
	_reset_the_screens(t, main)

	# A phone sending the app away reaches the same call through the other notification
	# `ReturnWindow._notification()` listens for.
	window.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	t.check(pause.is_open(), "a phone sending the app away pauses a played day the same way")
	_reset_the_screens(t, main)

	# **Unlike `Esc`, which opens the pause over the day summary on purpose**, losing focus does
	# not choose to open a second screen over one already asking for the player's attention.
	summary.show_summary(SummaryModel.day_over(GameState, UI.ended(GameEnums.DayResult.WON)),
			RunFlow.Mode.DAY_OVER)
	t.check(summary.is_showing(), "the day summary is up")
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not pause.is_open(),
			"focus loss does not open a second screen over the day summary, unlike the pause action")
	_reset_the_screens(t, main)

	# The ending is the same summary screen showing a different body, so the same `is_showing()`
	# guard covers it rather than a case of its own.
	summary.show_summary(SummaryModel.ending(GameState, GameEnums.Ending.GOOD), RunFlow.Mode.ENDING)
	t.check(summary.is_showing(), "the ending screen is up")
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not pause.is_open(), "focus loss does not open a second screen over the ending")
	_reset_the_screens(t, main)

## The day begun, its day 14 set up as `kept_the_last_night` and `hard` say, and the day's end
## announced by the day itself: the day's signal, as its clock or its goal would send it.
func _end_day_fourteen(main: Node2D, hard: bool, sabotage_done: bool) -> void:
	GameState.facts.escape_section = DaySpec.Section.NONE
	GameState.start_run(SEED)
	if hard:
		GameState.calendar.choose_mode(true)
	GameState.header.day = Tuning.RUN_LENGTH_DAYS
	GameState.resistance.progress = Tuning.RESISTANCE_GOAL
	GameState.resistance.sabotage_done = sabotage_done
	# Below the cap (`Tuning.STARTING_NERVES`, 5) so a missing or doubled
	# `GameState.calendar.regain_a_nerve()` call in the hand-over branch would show up as a wrong
	# count rather than being masked by the cap `GameState.start_run()` already sets `nerves` to.
	GameState.header.nerves = 3
	(_one(main, "DayController") as DayController).day_finished.emit(GameEnums.DayResult.WON)

## **The last day ends by handing over, not by ending the run.** *(PLAYTEST-113: "the escape the
## building starts when the player has completed all tasks by the end of day 14".)* The escape is
## the good ending played rather than announced, so a won day 14 with every task complete must
## leave `GameState` exactly where it is — no `ending`, no cleared save, day 14 still — and only
## record which section the run is now in. A run whose ending were set here could write no save at
## all (`GameSave.write()` refuses one), and the section checkpoints would have nothing to
## come back to.
##
## Driven through the day's own end signal on the booted game against its real city, day and
## summary, because the thing that has to hold is an *omission* — that
## `GameState.calendar.finish_day()` is not called — and an omission is only visible where the call
## would have been.
func _check_a_won_day_fourteen_hands_over(t, main: Node2D, calls: Calls) -> void:
	var reloads_before := calls.reloads.size()
	_end_day_fourteen(main, false, true)
	t.check(GameState.header.ending == GameEnums.Ending.NONE,
			"a won day 14 with every task complete does not end the run")
	t.check(GameState.facts.escape_section == DaySpec.Section.BUILDING,
			"it puts the run in the building, which is where the escape starts")
	t.check(GameState.header.day == Tuning.RUN_LENGTH_DAYS, "and leaves the calendar alone")
	var summary := _one(main, "DaySummary") as DaySummaryScript
	t.check(calls.reloads.size() == reloads_before, "nothing has reloaded yet")
	await UI.frames(t)
	UI.push(summary, UI.touch_at(UI.centre(UI.button(summary, "Continue")), true))
	await UI.frames(t)
	t.check(calls.reloads.size() == reloads_before + 1,
			"so its continue reloads into the escape rather than ending the run")
	t.check(GameState.header.nerves == 4,
			"day 14's win still gives a nerve back, and exactly once, through the direct call")

	# The same hand-over in a hard run gives nothing back.
	_end_day_fourteen(main, true, true)
	t.check(GameState.facts.escape_section == DaySpec.Section.BUILDING,
			"a hard run's day 14 also hands over to the escape")
	t.check(GameState.header.nerves == 3, "and its win gives a hard run no nerve back")

	# The other side of the same day: the legwork done and the last night skipped is still the
	# neutral ending it has always been, and must not reach the escape.
	GameState.facts.escape_section = DaySpec.Section.NONE
	_end_day_fourteen(main, false, false)
	t.check(GameState.header.ending == GameEnums.Ending.NEUTRAL,
			"a won day 14 without the last night still ends the run on the neutral ending")
	t.check(GameState.facts.escape_section == DaySpec.Section.NONE, "and never reaches the escape")
	t.check(GameState.header.nerves == 4,
			"and this path's win gains a nerve too, through the ordinary GameState.calendar.finish_day()")

## **Caught only by asking the connection, not by pressing the button.** The day summary's own
## restart button held, filled its bar, fired `restart_requested`, and reached nobody — a green
## `check.sh` and a green suite both passed the whole time, because both screens' *own* tests only
## ever check that they emit the signal, never that anything downstream is listening. The neutral
## ending day 14 just put on screen gets each screen's output signal emitted, and the reload and
## the quit it would take are counted: each reaches the one thing that means it.
func _check_the_summary_and_pause_restart_signals_are_both_connected(t, main: Node2D,
		calls: Calls) -> void:
	var summary := _one(main, "DaySummary") as DaySummaryScript
	var pause := _one(main, "PauseScreen") as PauseScreen
	var reloads := calls.reloads.size()
	t.check(summary.is_showing(), "the run's end is on screen")
	# The neutral day's own screen says the run is over; its continue puts the ending itself up.
	UI.push(summary, UI.touch_at(UI.centre(UI.button(summary, "Continue")), true))
	await UI.frames(t)
	t.check(summary.is_showing(), "and its continue shows the ending")

	# Nothing of the walk counts behind the ending, with the tree running (the walk's tick,
	# `_check_play_seconds_only_advance_while_the_world_moves`).
	GameState.header.play_ticks = 0
	main.get_tree().paused = false
	for i in 3:
		await main.get_tree().physics_frame
	t.check(GameState.header.play_ticks == 0, "the ending screen adds no tick, with the tree running")

	summary.continued.emit(RunFlow.Mode.ENDING)
	t.check(calls.reloads.size() == reloads + 1,
			"continuing from the summary still reaches the run loop, and an ended run starts over")
	for i in 3:
		await main.get_tree().physics_frame
	t.check(GameState.header.play_ticks == 0, "a scene on its way out adds no tick either")
	summary.restart_requested.emit()
	t.check(calls.reloads.size() == reloads + 2,
			"the day summary's own restart button reaches the restart")
	pause.restart_requested.emit()
	t.check(calls.reloads.size() == reloads + 3,
			"and so does the pause screen's — the one that already worked")
	t.check(calls.quits.is_empty(), "no quit has been asked yet")
	pause.quit_requested.emit()
	t.check(calls.quits.size() == 1, "and the pause screen's quit still reaches somewhere")

# ------------------------------------------------------------------- the ground painted ---

func _ground_of(city: City) -> SceneryGround:
	return city.get_node("Ground") as SceneryGround

## The player's camera has no limits, so at each map corner the view is centered on her, the
## look-ahead is added toward the corner, and the ground has to be painted under all of it through
## the view-driven residency. Fails if residency were clipped back to the border band, since the
## view then reaches past the band on the east and west sides (the view is wider than the band).
##
## Computed rather than driven through a real windowed `Camera2D`: engine-internal smoothing runs
## once a frame through the rendering server, which nothing in this synchronous headless suite
## steps. The check reads the actual static `TileMapLayer` cells plus the independently drawn
## south-water cells rather than re-deriving what should be there.
func _test_the_unclamped_view_at_every_corner_is_painted(t) -> void:
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	var ground := _ground_of(city)

	var half := Tuning.VIEW_HALF_EXTENT
	var lead := Stroller.CAMERA_LOOK_AHEAD
	var size := city.map.world_size()
	var corners := {
		"nw": Vector2(0.0, 0.0), "ne": Vector2(size.x, 0.0),
		"sw": Vector2(0.0, size.y), "se": Vector2(size.x, size.y),
	}
	var beyond_the_band := false
	for name in corners:
		var toward: Vector2 = corners[name]
		var glance := Vector2(
				lead if toward.x > size.x * 0.5 else -lead,
				lead if toward.y > size.y * 0.5 else -lead)
		var window := Rect2(toward + glance - half, half * 2.0)
		var band := Rect2(Vector2.ZERO, size).grow(
				CityMap.OUTSIDE_DEPTH_TILES * float(Tuning.TILE_SIZE))
		beyond_the_band = beyond_the_band or not band.encloses(window)
		city.scenery.update(window, true)
		var lo := city.map.world_to_tile(window.position)
		var hi := city.map.world_to_tile(window.end - Vector2.ONE)
		var unpainted := 0
		for y in range(lo.y, hi.y + 1):
			for x in range(lo.x, hi.x + 1):
				var cell := Vector2i(x, y)
				if ground.get_cell_source_id(cell) < 0 and not ground.has_water(cell):
					unpainted += 1
		t.check(unpainted == 0,
				"corner %s: every cell the window can show is painted (%d unpainted of %d)"
				% [name, unpainted, (hi.x - lo.x + 1) * (hi.y - lo.y + 1)])

	t.check(beyond_the_band, "a corner view reaches past the band, so the check is not vacuous")
	city.free()
	GameState.header.play_ticks = 0

## The trailer overview grows the finite city by one authored landscape margin. Its added east and
## west columns are forest, while the north and south bands own their corners and the bridge's
## road carries on to any depth.
func _test_the_overview_is_landscape_to_every_edge(t) -> void:
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))

	var bounds := city.map.tile_rect_to_world(Rect2i(Vector2i.ZERO, city.map.size)).grow(512.0)
	var viewport := Vector2(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"))
	var zoom := ZoomOutCamera.overview_zoom(bounds, viewport)
	var size := viewport / zoom
	var view := Rect2(bounds.get_center() - size / 2.0, size)
	var lo := city.map.world_to_tile(view.position)
	var hi := city.map.world_to_tile(view.end - Vector2.ONE)
	var middle_y := city.map.size.y / 2
	var south_spine_x := city.map.main_road * CityMap.period() + Tuning.SIDEWALK_WIDTH
	var keys := _ground_of(city).keys_in(view)

	t.check(keys.has(SceneryGround.key_for(lo)) and keys.has(SceneryGround.key_for(hi)),
			"overview residency covers both far landscape corners")
	t.check(city.scenery_ground_source(Vector2i(lo.x, middle_y)) == GroundTiles.FOREST \
			and city.scenery_ground_source(Vector2i(hi.x, middle_y)) == GroundTiles.FOREST,
			"overview's wide east and west columns remain forest")
	t.check(city.scenery_ground_source(lo) == GroundTiles.MOUNTAIN \
			and city.scenery_ground_source(Vector2i(hi.x, lo.y)) == GroundTiles.MOUNTAIN,
			"north owns both overview corners as mountain")
	t.check(city.scenery_ground_source(Vector2i(lo.x, hi.y)) == GroundTiles.WATER \
			and city.scenery_ground_source(hi) == GroundTiles.WATER,
			"south owns both overview corners as water")
	for depth in [CityMap.OUTSIDE_DEPTH_TILES, CityMap.OUTSIDE_DEPTH_TILES * 4]:
		t.check(city.scenery_ground_source(Vector2i(south_spine_x,
				city.map.size.y + depth)) != GroundTiles.WATER,
				"the southern bridge's road carries on %d tiles out, to the edge of any view" % depth)
	t.check(city.scenery_ground_source(Vector2i(south_spine_x - 2,
			city.map.size.y + CityMap.OUTSIDE_DEPTH_TILES * 4)) == GroundTiles.WATER,
			"the water either side of the bridge goes on too")

	city.free()
	GameState.header.play_ticks = 0

# ------------------------------------------------------------- focus pause ---

## `--no-focus-pause` is parsed from the command line and the page's query into the run's
## configuration, which is what `main` reads.
func _test_no_focus_pause_from_args(t) -> void:
	t.check(not _config([]).no_focus_pause,
			"no command-line modifier leaves focus loss pausing the game")
	t.check(_config(["--no-focus-pause"]).no_focus_pause, "--no-focus-pause turns it off directly")
	t.check(_config(["--screenshot", "out.png"]).no_focus_pause,
			"--screenshot implies it without being told to, since a rig's window opens unfocused")
	t.check(not _config(["--seed", "1"]).no_focus_pause, "an unrelated flag does not imply it")

func _test_no_focus_pause_from_query(t) -> void:
	t.check(not _config([], true, "").no_focus_pause,
			"an absent URL parameter leaves focus loss pausing the game")
	t.check(not _config([], true, "?nofocuspause=0").no_focus_pause,
			"nofocuspause=0 leaves it pausing")
	t.check(_config([], true, "?nofocuspause=1").no_focus_pause, "?nofocuspause=1 turns it off")
	t.check(_config([], true, "?seed=1&nofocuspause=1&day=2").no_focus_pause,
			"the parameter is found among other URL parameters")

# ---------------------------------------------------------------------- the return window ---

## A return window on the suite's viewport, measured on `clock`, in the tree.
func _window(t, clock, no_focus_pause := false, rig := false) -> ReturnWindow:
	var window := ReturnWindow.new()
	window.use_clock(clock.read)
	t.add_child(window)
	window.setup(t.get_viewport(), no_focus_pause, rig)
	return window

func _press_accept(t) -> void:
	var press := InputEventAction.new()
	press.action = &"ui_accept"
	press.pressed = true
	t.get_viewport().push_input(press)

## Inbox #534: for `ReturnWindow.IGNORED_MSEC` after `FOCUS_IN` or `RESUMED` the viewport delivers
## nothing, so the press that brings the page back cannot resume the pause screen or start the day
## brief. Real events are pushed through the suite's own viewport; the window is measured on a clock
## moved past its end rather than waited out.
func _test_return_ignores_input_for_half_a_second(t) -> void:
	t.check(ReturnWindow.IGNORED_MSEC == 500, "the window is 500ms")
	for what in [Node.NOTIFICATION_APPLICATION_FOCUS_IN, Node.NOTIFICATION_APPLICATION_RESUMED]:
		var clock := UI.FakeClock.new()
		var window := _window(t, clock)
		var pause: PauseScreen = PAUSE_SCREEN_SCENE.instantiate()
		pause.use_run(GameState)
		t.add_child(pause)
		var summary: DaySummaryScript = DAY_SUMMARY_SCENE.instantiate()
		t.add_child(summary)
		var paused_before: bool = t.get_tree().paused
		# The pause screen.
		pause.open()
		window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		window.notification(what)
		t.check(t.get_viewport().is_input_disabled(), "a return switches the viewport's input off")
		_press_accept(t)
		t.check(pause.is_open(), "a press inside the window does not resume the pause (%d)" % what)
		clock.now = float(ReturnWindow.IGNORED_MSEC) + 1.0
		window.end()
		t.check(not t.get_viewport().is_input_disabled(), "the window's end switches it back on")
		_press_accept(t)
		t.check(not pause.is_open(), "the same press after the window resumes")
		# The day brief.
		var starts := [0]
		summary.continued.connect(func(_raised_in: int): starts[0] += 1)
		summary.show_summary(SummaryModel.brief_for(GameState), RunFlow.Mode.BRIEF)
		window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		window.notification(what)
		_press_accept(t)
		t.check(starts[0] == 0, "a press inside the window does not start the day from the brief")
		clock.now += float(ReturnWindow.IGNORED_MSEC) + 1.0
		window.end()
		_press_accept(t)
		t.check(starts[0] == 1, "the same press after the window starts it")
		t.get_viewport().set_disable_input(false)
		t.get_tree().paused = paused_before
		summary.free()
		pause.free()
		window.free()
		await t.get_tree().process_frame

## Nothing can leave input off. A second trigger (the web's page events beside the engine's own)
## moves nothing; a frame landing inside the window leaves it running and a later frame still puts
## input back, read off the clock each frame; and a scene reload inside the window (leaving the
## tree) puts it back at once, because the root viewport outlives the scene.
func _test_return_window_always_ends(t) -> void:
	var clock := UI.FakeClock.new()
	var window := _window(t, clock)
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	window.on_web_event("focus", "visible")
	await t.get_tree().process_frame
	await t.get_tree().process_frame
	t.check(t.get_viewport().is_input_disabled(), "a frame inside the window leaves it running")
	clock.now = float(ReturnWindow.IGNORED_MSEC) + 1.0
	await t.get_tree().process_frame
	await t.get_tree().process_frame
	t.check(not t.get_viewport().is_input_disabled(), "the first frame after it puts input back")
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	t.check(t.get_viewport().is_input_disabled(), "a second return after a departure arms again")
	t.remove_child(window)
	t.check(not t.get_viewport().is_input_disabled(),
			"a scene reload inside the window does not leave the new scene deaf")
	window.free()

## The window opens on a return, not on the first focus at load: a focus-in with no loss before it
## does not arm (the v0.25.0 browser check's Space arrived inside it and was dropped), a loss then a
## focus-in does, and the web's `blur`/`visibilitychange`/`focus` decide the same way.
func _test_return_window_needs_a_departure(t) -> void:
	var clock := UI.FakeClock.new()
	var window := _window(t, clock)
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	t.check(not t.get_viewport().is_input_disabled() and not window.ignoring_input(),
			"a focus-in with no loss before it (the page's own focus at load) does not arm")
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	t.check(t.get_viewport().is_input_disabled(), "a loss then a focus-in arms")
	window.end(true)
	window.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	t.check(not t.get_viewport().is_input_disabled(), "the departure is spent: a second focus-in does not arm")
	# The web path.
	window.on_web_event("focus", "visible")
	t.check(not t.get_viewport().is_input_disabled(), "web: a focus with no blur before it does not arm")
	window.on_web_event("blur", "visible")
	window.on_web_event("focus", "visible")
	t.check(t.get_viewport().is_input_disabled(), "web: a blur then a focus arms")
	window.end(true)
	window.on_web_event("visibilitychange", "hidden")
	t.check(not t.get_viewport().is_input_disabled(), "web: the page going hidden does not arm")
	window.on_web_event("visibilitychange", "visible")
	t.check(t.get_viewport().is_input_disabled(), "web: hidden then visible arms")
	t.get_viewport().set_disable_input(false)
	window.free()

## A rig (`--no-focus-pause`, `--screenshot`) is never slowed by the window.
func _test_return_window_is_off_under_the_override(t) -> void:
	var clock := UI.FakeClock.new()
	var override := _window(t, clock, true, false)
	override.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	override.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	t.check(not t.get_viewport().is_input_disabled(),
			"under the override a return does not start the window")
	override.free()
	var rig := _window(t, clock, false, true)
	rig.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	rig.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	t.check(not t.get_viewport().is_input_disabled(), "nor does a rig run (--walk, --press ...)")
	rig.free()

# ------------------------------------------------------------------ a rig's own lockdown ---
## M195: the rig list, through the run's configuration — the same place `RigLock` and `main` read it.
## This is also the exact set `RigLock._input()`'s own gate (`locked_out`) and `RigLock.setup()`'s
## window-flag/`InputMap`-erasure both key off, so a case proven here holds for all three without a
## live window to check them against.
func _test_is_rig_from_args(t) -> void:
	t.check(not _config([]).is_rig, "no flags at all is a person, not a rig")
	t.check(not _config(["--seed", "1", "--day", "9"]).is_rig,
			"flags that only choose what she is looking at do not make it a rig")
	for flag in ["--screenshot", "--walk", "--flee", "--press", "--tap", "--route"]:
		t.check(_config([flag, "x"]).is_rig, "%s alone marks the run a rig" % flag)
	t.check(_config(["--seed", "1", "--walk", "north"]).is_rig,
			"a rig flag among others still counts")

## `rig_quit_seconds_from(after, day_length)` — the pure formula both `RigLock._process()`'s own
## timer and `tools/lib_dev_flags.sh`'s `rig_kill_after_seconds()` are built on (that one mirrors
## this exact arithmetic against the same `RIG_QUIT_SECONDS` marker block this file's constants
## come from — see `tests/test_cli_help.sh` for the shell side).
func _test_rig_quit_seconds_from(t) -> void:
	var margin := DevFlags.RIG_QUIT_MARGIN_SECONDS
	var ceiling := DevFlags.RIG_QUIT_CEILING_SECONDS
	t.check(is_equal_approx(DevFlags.rig_quit_seconds_from(25.0, 210.0), 25.0 + margin),
			"an --after value is the script length the margin is added to")
	t.check(is_equal_approx(DevFlags.rig_quit_seconds_from(-1.0, 210.0), 210.0 + margin),
			"no --after falls back to the day's own length")
	t.check(is_equal_approx(DevFlags.rig_quit_seconds_from(-1.0, 0.0), margin),
			"a day with no length still gets at least the margin, never less")
	t.check(is_equal_approx(DevFlags.rig_quit_seconds_from(-1.0, 5.0), 5.0 + margin),
			"and a very short day the margin on top of it")
	t.check(is_equal_approx(DevFlags.rig_quit_seconds_from(5000.0, 210.0), ceiling),
			"an outsized --after is clamped to the fixed ceiling rather than honoured outright")
	t.check(ceiling > 210.0 + margin,
			"the ceiling comfortably fits a whole ordinary day plus its own margin")

