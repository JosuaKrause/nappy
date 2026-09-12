extends RefCounted
## The developer readout is furniture, and `main._process()` is the one place that draws it.
##
## *(2026-09-02, playtest of the deployed web build: "the debug info on the right side of the
## screen (fps, seed, etc.) is still showing.")* `main.gd` is never instantiated as a scene
## anywhere else in the suite — its `_ready()` boots a whole run, city and all — so this reaches
## past `_ready()` the way `tests/test_pause.gd` already reaches past it for `_unhandled_input()`:
## a script-only instance, its handful of world dependencies wired up by hand, and `_process()`
## called directly.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const DAY_SUMMARY_SCENE := preload("res://scenes/ui/day_summary.tscn")
const PAUSE_SCREEN_SCENE := preload("res://scenes/ui/pause_screen.tscn")
const MAIN_SCRIPT: GDScript = preload("res://src/main.gd")

const SEED := 4242

func run(t) -> void:
	_test_the_readout_is_not_assembled_outside_a_debug_build(t)
	_test_add_touch_controls_builds_the_one_control_reader(t)
	_test_on_title_start_sets_the_controls_mode(t)
	_test_the_summary_and_pause_restart_signals_are_both_connected(t)
	_test_no_interior_exists_outside_a_debug_build(t)
	_test_play_seconds_only_advances_while_the_world_moves(t)

## `main._debug` is read once from `DevFlags.enabled()` rather than asked of the OS inside
## `_process()`, precisely so this can set it directly and check the release shape — the same
## reason `hud._debug` exists. Checked both ways: nothing is drawn when it is off, and the
## ordinary debug readout still appears when it is on, so the gate is not just "always empty".
func _test_the_readout_is_not_assembled_outside_a_debug_build(t) -> void:
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	var stroller := Stroller.new()
	stroller.add_child(camera)
	t.add_child(stroller)
	stroller.set_physics_process(false)
	var baby := Baby.new()
	baby.name = "Baby"
	stroller.add_child(baby)
	baby.set_physics_process(false)

	var day := DayController.new()
	t.add_child(day)
	day.set_process(false)
	day.setup(city.map, stroller)

	var hud: CanvasLayer = HUD_SCENE.instantiate()
	t.add_child(hud)
	hud.set_process(false)

	# `_ready()` never runs on a script-only instance, so `@onready var _status` is never
	# populated — set by hand, the way every other member below is.
	var main: Node2D = MAIN_SCRIPT.new()
	main._status = Label.new()
	main._city = city
	main._player = stroller
	main._baby = baby
	main._day = day
	main._hud = hud
	main._in_the_title = false

	main._debug = false
	main._process(0.016)
	t.check(main._status.text == "",
			"the release shape never assembles the readout, not even into a hidden label")

	main._debug = true
	main._process(0.016)
	t.check("seed" in main._status.text and "fps" in main._status.text,
			"a debug build still builds the readout the rigs and tools/shot.sh read")

	# `_status` was never added under `main` as a child — it stands in for the `@onready` label
	# `_ready()` would otherwise have wired up — so freeing `main` does not reach it.
	main._status.free()
	main.free()
	hud.free()
	day.free()
	stroller.free()
	city.free()

## **One node goes into the tree, not a choice between two.** `TouchControls` is the whole of the
## pointer scheme regardless of which aiming mode is chosen — `_add_touch_controls()` builds the
## one node either way and hands it a starting mode through `set_mode(ControlsMode.resolve())`,
## which the title screen goes on to override once a player actually presses a button (see
## `main._on_title_start()`). `ControlsMode.resolve()` answers `TAP` here, with neither `--controls`
## nor a URL query present in this suite's own process.
func _test_add_touch_controls_builds_the_one_control_reader(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	t.check(main._touch_controls == null, "nothing is built before _ready() runs")

	main._add_touch_controls()
	t.check(main._touch_controls != null, "and _add_touch_controls() builds it")
	t.check(main._touch_controls.get_parent() == main._touch_layer,
			"parented under the layer it builds alongside it")
	t.check(main._touch_controls._mode == ControlsMode.Mode.TAP,
			"and gives it ControlsMode.resolve()'s own answer as a starting mode")

	main.free()

## `main._on_title_start()` is the one seam that lets the title screen's own button press reach the
## node `_add_touch_controls()` already built — nothing else in `main` ever calls `set_mode()`. The
## stroller is built the same way `_test_the_readout_is_not_assembled_outside_a_debug_build` above
## builds one: a real `Camera2D` child named `Camera2D`, added to the tree so `_ready()` wires up
## `Stroller._camera`, which `step_back_in()` needs.
func _test_on_title_start_sets_the_controls_mode(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	main._add_touch_controls()

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	var stroller := Stroller.new()
	stroller.add_child(camera)
	t.add_child(stroller)
	stroller.set_physics_process(false)

	main._player = stroller
	main._city = City.new()
	main._hud = CanvasLayer.new()
	main._edge_layer = CanvasLayer.new()
	main._status = Label.new()
	main._title = TitleScreen.new()

	main._on_title_start(ControlsMode.Mode.JOYSTICK)
	t.check(main._touch_controls._mode == ControlsMode.Mode.JOYSTICK,
			"pressing the joystick button on the title screen sets that mode on the one control reader")

	main._status.free()
	main._title.free()
	main._edge_layer.free()
	main._hud.free()
	main._city.free()
	main.free()
	stroller.free()

## **Caught only by asking the connection, not by pressing the button.** The day summary's own
## restart button held, filled its bar, fired `restart_requested`, and reached nobody — a green
## `check.sh` and a green suite both passed the whole time, because both screens' *own* tests only
## ever check that they emit the signal, never that anything downstream is listening. `main._ready()`
## is never run here — see this file's own class comment for why — so this calls
## `main._connect_summary_and_pause_signals()` directly against two real, hand-built screens rather
## than the whole world `_ready()` would otherwise build first.
func _test_the_summary_and_pause_restart_signals_are_both_connected(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	main._summary = DAY_SUMMARY_SCENE.instantiate()
	main._pause = PAUSE_SCREEN_SCENE.instantiate()
	main._connect_summary_and_pause_signals()

	t.check(main._summary.restart_requested.is_connected(main._restart_run),
			"the day summary's own restart button reaches main._restart_run()")
	t.check(main._pause.restart_requested.is_connected(main._restart_run),
			"and so does the pause screen's — the one that already worked")
	t.check(main._summary.continued.is_connected(main._on_summary_continued),
			"continuing from the summary still reaches the day loop")
	t.check(main._pause.quit_requested.is_connected(main._quit),
			"and the pause screen's quit still reaches somewhere")

	main._summary.queue_free()
	main._pause.queue_free()
	main.free()

## `--start-escape` is a debug-only entry, gated the same shape `_add_debug_layers()` gates
## `DebugLayers` on `_debug` — `main._escape_scene_requested` is read once from
## `DevFlags.start_escape()` into a member (this file's own class doc explains why: `main.gd` is
## never instantiated as a scene anywhere in the suite), so a test can set it directly and check
## the release shape without a real command line. `_ready_escape()` re-checks the same member at
## its own top, not only at the call site in `_ready()`, so calling it directly here exercises the
## same guard a release build would hit.
func _test_no_interior_exists_outside_a_debug_build(t: Node) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	main._escape_scene_requested = false
	main._ready_escape()
	t.check(main._interior == null,
			"a release build never builds the interior scene at all, not even off to one side")
	main.free()

## `GameState.play_seconds` has exactly one owner: the branch of this `_process()` reached only
## once a day is actually running, walking or returning, with the tree unpaused. Same rig as
## `_test_the_readout_is_not_assembled_outside_a_debug_build` above — city, stroller, baby, day
## controller and hud, all built by hand rather than through `_ready()`, since this file's own
## class doc explains why `main` is never added to the tree here either.
##
## `t.get_tree().paused` stands in for the pause screen and the day summary, the way
## `tests/test_pause.gd` already toggles it against real screens — `main._tree_is_paused()` reads
## `Engine.get_main_loop()` rather than `main.get_tree()` for exactly this reason: there is one
## `SceneTree` for the whole process, and `main` not being parented in this rig must not stop the
## question from being answerable.
func _test_play_seconds_only_advances_while_the_world_moves(t) -> void:
	var saved_paused: bool = t.get_tree().paused
	var saved_run_seed := GameState.run_seed
	var saved_day := GameState.day
	var saved_nerves := GameState.nerves
	var saved_progress := GameState.resistance_progress
	var saved_sabotage := GameState.sabotage_done

	GameState.play_seconds = 42.0
	GameState.start_run(SEED)
	t.check(is_zero_approx(GameState.play_seconds), "start_run() zeroes the clock with the rest of the run")

	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	var stroller := Stroller.new()
	stroller.add_child(camera)
	t.add_child(stroller)
	stroller.set_physics_process(false)
	var baby := Baby.new()
	baby.name = "Baby"
	stroller.add_child(baby)
	baby.set_physics_process(false)

	var day := DayController.new()
	t.add_child(day)
	day.set_process(false)
	day.setup(city.map, stroller)
	day.phase = GameEnums.DayPhase.WALKING

	var hud: CanvasLayer = HUD_SCENE.instantiate()
	t.add_child(hud)
	hud.set_process(false)

	var main: Node2D = MAIN_SCRIPT.new()
	main._status = Label.new()
	main._city = city
	main._player = stroller
	main._baby = baby
	main._day = day
	main._hud = hud
	main._in_the_title = false
	main._debug = false

	const DELTA := 0.1

	t.get_tree().paused = false
	main._process(DELTA)
	t.check(is_equal_approx(GameState.play_seconds, DELTA),
			"a walking frame with the tree unpaused advances the clock")

	# The pause screen: phase stays WALKING (a day in progress, Esc pressed), the tree pauses.
	t.get_tree().paused = true
	main._process(DELTA)
	t.check(is_equal_approx(GameState.play_seconds, DELTA), "a paused frame does not")

	# The day summary: `DayController._end()` sets `phase` to `OVER` before the summary ever
	# pauses the tree, so this is the shape a real day-end frame actually arrives in.
	day.phase = GameEnums.DayPhase.OVER
	main._process(DELTA)
	t.check(is_equal_approx(GameState.play_seconds, DELTA),
			"the day summary (phase OVER, tree still paused) does not advance it either")

	# The title screen: unpaused, so the phase/pause check alone could not explain a stopped
	# clock here — `_in_the_title`'s own early return in `_process()` is what has to.
	day.phase = GameEnums.DayPhase.WALKING
	t.get_tree().paused = false
	main._in_the_title = true
	main._process(DELTA)
	t.check(is_equal_approx(GameState.play_seconds, DELTA),
			"the title screen does not advance it, even with the tree unpaused behind it")

	main._in_the_title = false
	main._process(DELTA)
	t.check(is_equal_approx(GameState.play_seconds, DELTA * 2),
			"and a walking frame afterwards resumes rather than having latched off")

	main._status.free()
	main.free()
	hud.free()
	day.free()
	stroller.free()
	city.free()
	# Restored for the same reason `test_day_loop.gd`'s own `GameState.start_run()` caller
	# restores these five: the suite shares one `GameState` and `t.get_tree()`, so a value this
	# left behind outlives the function.
	t.get_tree().paused = saved_paused
	GameState.run_seed = saved_run_seed
	GameState.day = saved_day
	GameState.nerves = saved_nerves
	GameState.resistance_progress = saved_progress
	GameState.sabotage_done = saved_sabotage
	GameState.play_seconds = 0.0
