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
const TITLE_SCREEN_SCENE := preload("res://scenes/ui/title_screen.tscn")
const MAIN_SCRIPT: GDScript = preload("res://src/main.gd")

const SEED := 4242

func run(t) -> void:
	_test_the_readout_is_not_assembled_outside_a_debug_build(t)
	_test_the_readout_flag_shows_it_on_a_release_build(t)
	_test_the_debug_mode_note_only_exists_when_requested(t)
	_test_the_frame_graph_only_exists_when_requested(t)
	_test_graph_starts_on_under_spikes_or_layers_six(t)
	_test_key_six_resolves_to_the_frame_graph_layer(t)
	_test_key_six_toggles_the_graph_independent_of_four(t)
	_test_key_six_twice_empties_the_ring(t)
	_test_add_touch_controls_builds_the_one_control_reader(t)
	_test_on_title_start_sets_the_controls_mode(t)
	_test_the_title_hides_the_graph_and_keeps_its_ring(t)
	_test_opening_the_title_reasserts_the_orientation_it_finds_stale(t)
	_test_the_summary_and_pause_restart_signals_are_both_connected(t)
	_test_no_interior_exists_outside_a_debug_build(t)
	_test_play_seconds_only_advances_while_the_world_moves(t)
	_test_the_border_reaches_the_window_from_every_corner(t)
	_test_no_focus_pause_from_args(t)
	_test_no_focus_pause_from_query(t)
	_test_focus_lost_opens_the_pause_during_a_played_day(t)
	_test_application_paused_also_opens_the_pause(t)
	_test_focus_lost_does_nothing_on_the_title(t)
	_test_focus_lost_does_nothing_over_the_day_summary(t)
	_test_focus_lost_does_nothing_over_the_ending(t)
	_test_focus_lost_does_nothing_when_the_pause_is_already_open(t)
	_test_focus_gained_does_not_resume(t)
	_test_focus_lost_does_nothing_under_the_override(t)
	_test_a_won_day_fourteen_with_every_task_hands_over_instead_of_ending(t)

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
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
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
	main._readout_requested = false
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

## `_readout_requested` (`DevFlags.readout_requested()`, the page's own `?debug=1` or `--debug`) is
## read independently of `_debug` — M133, "the readout on the live page" — so a release build
## (`_debug == false`) still assembles the readout the moment this holds. Same rig as the test
## above, with the two flags' roles swapped.
func _test_the_readout_flag_shows_it_on_a_release_build(t) -> void:
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
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

	var main: Node2D = MAIN_SCRIPT.new()
	main._status = Label.new()
	main._city = city
	main._player = stroller
	main._baby = baby
	main._day = day
	main._hud = hud
	main._in_the_title = false

	main._debug = false
	main._readout_requested = true
	main._process(0.016)
	t.check("seed" in main._status.text and "fps" in main._status.text,
			"?debug=1 on a release build assembles the same readout a debug build gets")

	main._status.free()
	main.free()
	hud.free()
	day.free()
	stroller.free()
	city.free()

## `_add_debug_mode_note()` gates itself on `_readout_requested` the same shape
## `_add_debug_layers()` gates itself on `_debug` — see that function's own doc — so the note built
## for a release build carrying `?debug=1` exists only when the flag actually holds, and an
## ordinary debug build without it (`_readout_requested == false`) gets none.
func _test_the_debug_mode_note_only_exists_when_requested(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	main._readout_requested = false
	main._add_debug_mode_note()
	t.check(main._debug_mode_note == null,
			"no note is built at all when the flag was not asked for")
	main.free()

	main = MAIN_SCRIPT.new()
	main._readout_requested = true
	main._add_debug_mode_note()
	t.check(main._debug_mode_note != null and main._debug_mode_note.get_parent() == main,
			"the flag builds the note and parents it under main")
	main._debug_mode_note.free()
	main.free()

## `_add_frame_graph()` gates itself on `_debug or _readout_requested`, the same shape
## `_add_debug_mode_note()` gates itself on `_readout_requested` alone — see that function's own
## doc — so a release build carrying neither flag never builds the graph either, and one carrying
## `?debug=1` gets it parented under `_status`'s own `CanvasLayer`. **Off by default**, unlike
## `_status.visible` itself: *(2026-09-15, the player: "spike view should be independent of debug
## layer 4 it should be its own debug layer and turned off by default unless --spikes is set".)*
## its own switch, `_layer_graph_on`, starts `false` and nothing in this suite's own command line
## sets `--spikes` or names `6` in `--layers`, so a debug build that asked for the readout still
## gets a graph nobody has turned on yet.
func _test_the_frame_graph_only_exists_when_requested(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	main._status = Label.new()
	main._status_layer = CanvasLayer.new()
	main._debug = false
	main._readout_requested = false
	main._add_frame_graph()
	t.check(main._frame_graph == null,
			"no graph is built at all when neither flag was asked for")
	main._status.free()
	main._status_layer.free()
	main.free()

	main = MAIN_SCRIPT.new()
	main._status = Label.new()
	main._status_layer = CanvasLayer.new()
	main._debug = false
	main._readout_requested = true
	main._add_frame_graph()
	t.check(main._frame_graph != null and main._frame_graph.get_parent() == main._status_layer,
			"the flag builds the graph and parents it under the readout's own CanvasLayer")
	t.check(not main._layer_graph_on and not main._frame_graph.visible,
			"but it starts off, unlike the readout it sits under — neither --spikes nor --layers 6 was given")
	main._frame_graph.free()
	main._status.free()
	main._status_layer.free()
	main.free()

## `MAIN_SCRIPT._graph_starts_on()` is the boot policy with the command line taken out of it, the
## same split `escape_part_for()` makes for `DevFlags.start_escape_at()` — this drives it directly
## rather than through a real `--spikes` or `--layers 6` on this process's own argv, neither of
## which this suite's own command line carries.
func _test_graph_starts_on_under_spikes_or_layers_six(t) -> void:
	var none: Array[int] = []
	var six: Array[int] = [6]
	var others: Array[int] = [1, 5]
	t.check(MAIN_SCRIPT._graph_starts_on(true, none), "--spikes alone starts the graph on")
	t.check(MAIN_SCRIPT._graph_starts_on(false, six),
			"--layers naming 6 starts it on the same way, without --spikes")
	t.check(not MAIN_SCRIPT._graph_starts_on(false, none),
			"neither flag given leaves it off, the default")
	t.check(not MAIN_SCRIPT._graph_starts_on(false, others),
			"--layers naming other layers does not turn this one on")

## `DevFlags.spikes_requested()` is a live read of `OS.get_cmdline_user_args()`, which this suite's
## own process does not carry, so `_add_frame_graph()` cannot be asked to start the graph on that
## path here — the case above already covers "neither flag was given". What this suite *can* drive
## is `--layers` naming `6`, through the same seam `tests/test_route_lines.gd` uses for `5`:
## `DevFlags.layers_override()` reads the real command line too, so this exercises
## `_toggle_debug_layer()` and the key directly instead, which is the surface a rig or a player
## actually reaches.
func _test_key_six_resolves_to_the_frame_graph_layer(t) -> void:
	t.check(MAIN_SCRIPT._debug_layer_key(_key(KEY_6)) == 6, "6 is the spike view")
	t.check(MAIN_SCRIPT._debug_layer_key(_key(KEY_6, false)) == 0, "a release, not a press, does nothing")
	t.check(MAIN_SCRIPT._debug_layer_key(_key(KEY_6, true, true)) == 0,
			"an echo does nothing — a held key is one request, not a flood of them")

func _key(code: Key, pressed := true, echo := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	return event

## `6` toggles `_layer_graph_on` and the graph's own visibility, independent of `4` — the whole
## point of M153: *(2026-09-15, the player: "spike view should be independent of debug layer 4".)*
## Pressing `4` first proves the two do not share a switch; pressing `6` then proves it has one of
## its own.
func _test_key_six_toggles_the_graph_independent_of_four(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	main._status = Label.new()
	main._status_layer = CanvasLayer.new()
	main._debug = true
	main._readout_requested = false
	main._add_frame_graph()

	t.check(not main._frame_graph.visible, "the graph starts off")
	# `_status` is a fresh `Label` (default `visible == true`) and `_layer_readout_on` starts
	# `true`, so this first toggle is the readout's `4`-key answer to "turn off what started on".
	main._toggle_debug_layer(4)
	t.check(not main._status.visible and not main._frame_graph.visible,
			"4 turns the readout off and leaves the graph exactly where it was")
	main._toggle_debug_layer(6)
	t.check(main._frame_graph.visible, "6 turns the graph on")
	main._toggle_debug_layer(4)
	t.check(main._status.visible and main._frame_graph.visible,
			"4 turns the readout back on and still leaves the graph alone")
	main._toggle_debug_layer(6)
	t.check(not main._frame_graph.visible, "6 turns the graph back off")

	main._frame_graph.free()
	main._status.free()
	main._status_layer.free()
	main.free()

## The player's own follow-on, said a minute after the first ask: pressing `6` twice must leave the
## ring empty rather than merely hidden, so a graph turned back on fills from that moment instead of
## picking up a stale window. *(2026-09-15: "spike recording should only be on while the layer is
## on. that means toggling the layer twice will lead to a blank frame array".)*
func _test_key_six_twice_empties_the_ring(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	main._status = Label.new()
	main._status_layer = CanvasLayer.new()
	main._debug = true
	main._readout_requested = false
	main._add_frame_graph()

	main._toggle_debug_layer(6)
	for i in range(10):
		main._frame_graph.push(0.010)
	t.check(main._frame_graph.frames().size() == 10, "the ring holds what was pushed while the layer was on")
	main._toggle_debug_layer(6)
	t.check(main._frame_graph.frames().is_empty(), "turning the layer back off empties the ring")
	main._toggle_debug_layer(6)
	t.check(main._frame_graph.frames().is_empty(),
			"and turning it back on again starts from empty, not from what the ring held before")

	main._frame_graph.free()
	main._status.free()
	main._status_layer.free()
	main.free()

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
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
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

## The correction to M153 the same evening: the graph's independence is from `4`, not from the
## title screen, which still hides everything about a player who is not there — this graph
## included. *(2026-09-15, the coordinator, relaying the player: "the graph must not draw over the
## title screen ... the independence the player asked for is from the 4 key, not from the
## title".)* Built the same lightweight, off-tree way `_test_on_title_start_sets_the_controls_mode`
## above is — `_open_the_title()`'s own `get_tree().paused = true` is guarded with
## `is_inside_tree()` for exactly this reason, the same shape `_on_title_start()`'s own last line
## already uses.
func _test_the_title_hides_the_graph_and_keeps_its_ring(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	main._add_touch_controls()

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	var stroller := Stroller.new()
	stroller.add_child(camera)
	t.add_child(stroller)
	stroller.set_physics_process(false)

	main._player = stroller
	main._city = City.new()
	# A real scene instance rather than a bare `CanvasLayer.new()` — `_open_the_title()` now calls
	# `_apply_orientation()` too (see that function's own doc), which reaches `_hud.set_rotated()`,
	# a method a bare layer does not have. Added to the tree for the same reason `_title` below is:
	# its own `@onready` children have to exist before anything reads them.
	var hud: CanvasLayer = HUD_SCENE.instantiate()
	t.add_child(hud)
	hud.set_process(false)
	main._hud = hud
	main._edge_layer = CanvasLayer.new()
	main._status = Label.new()
	main._status_layer = CanvasLayer.new()
	# A real scene instance, added to the tree so its own `@onready` labels populate —
	# `_test_on_title_start_sets_the_controls_mode` above gets away with a bare `TitleScreen.new()`
	# because it only reaches `close()`; `open()` (`_open_the_title()`'s own call) writes `_name.text`
	# and needs the scene's children to exist.
	main._title = TITLE_SCREEN_SCENE.instantiate()
	t.add_child(main._title)
	main._debug = true
	main._readout_requested = false
	main._add_frame_graph()

	main._toggle_debug_layer(6)
	main._frame_graph.push(0.010)
	main._frame_graph.push(0.020)
	t.check(main._frame_graph.visible and main._frame_graph.frames().size() == 2,
			"the graph is on and holds two frames before the title opens")

	main._open_the_title()
	t.check(not main._frame_graph.visible, "opening the title hides the graph")
	t.check(main._frame_graph.frames().size() == 2,
			"but does not clear the ring — only a 6 toggle-off does that")

	main._toggle_debug_layer(4)
	t.check(not main._frame_graph.visible, "4 does not move the graph while the title is open")

	main._on_title_start(ControlsMode.Mode.TAP)
	t.check(main._frame_graph.visible, "closing the title shows the graph again")
	t.check(main._frame_graph.frames().size() == 2, "with the ring exactly as it was left")

	main._toggle_debug_layer(4)
	t.check(main._frame_graph.visible, "and 4 still does not move it once the title is closed again")

	main._frame_graph.free()
	main._status.free()
	main._status_layer.free()
	main._title.free()
	main._edge_layer.free()
	main._hud.free()
	main._city.free()
	main.free()
	stroller.free()

## PLAYTEST-140, statement 5: "when you lose with game over the title screen is sideways" — seen
## on the phone only. `_ready()`'s own `_apply_orientation()` call happens before `_start_day()`,
## and `main.gd`'s own boot log times that at hundreds of milliseconds (planning a day's closures
## and every event on it); a real phone's browser chrome can still be settling into its own real
## shape somewhere in that gap, most plausibly on the very tap that just dismissed the ending
## screen and asked for this restart. Nothing re-read the window between the two, until
## `_open_the_title()` started asking again — see that function's own doc.
##
## `main` itself is never added to this suite's own tree — same reason as the test above, its own
## `_ready()` boots a whole run — so `_apply_orientation()`'s own `Engine.get_main_loop()` is what
## resolves the window here, exactly the substitution that function's own doc explains. That window
## is this suite's real one: landscape and untouched, which is this test's ground truth for "the
## way up this screen actually belongs" — a portrait window is not needed to prove the reassertion
## runs, only a wrong answer for it to correct. `_touch_controls`, the title's own `CanvasLayer` and
## the player's camera are all set to the rotated shape *before* `_open_the_title()` runs, standing
## in for whatever left the previous screen mid-turn; asserting they are back to the unrotated truth
## afterwards is what fails on the code before `_open_the_title()` called `_apply_orientation()` at
## all, and passes once it does.
func _test_opening_the_title_reasserts_the_orientation_it_finds_stale(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	main._add_touch_controls()

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	var stroller := Stroller.new()
	stroller.add_child(camera)
	t.add_child(stroller)
	stroller.set_physics_process(false)

	main._player = stroller
	main._city = City.new()
	var hud: CanvasLayer = HUD_SCENE.instantiate()
	t.add_child(hud)
	hud.set_process(false)
	main._hud = hud
	main._edge_layer = CanvasLayer.new()
	main._status = Label.new()
	main._status_layer = CanvasLayer.new()
	main._title = TITLE_SCREEN_SCENE.instantiate()
	t.add_child(main._title)

	# Standing in for whatever the previous screen left behind: rotated, exactly as if
	# `_apply_orientation()` had last been asked while the window was portrait and touch.
	main._rotated = true
	main._touch_controls.rotated = true
	main._player.set_screen_rotation(deg_to_rad(90.0))
	ScreenOrientation.apply_to_layer(main._title, true)
	t.check(main._touch_controls.rotated and not camera.ignore_rotation,
			"set up rotated, to prove the assertions below actually move something")

	main._open_the_title()

	t.check(not main._rotated,
			"opening the title re-reads the window rather than trusting the stale rotated flag")
	t.check(not main._touch_controls.rotated,
			"and hands the touch controls the corrected answer, not the stale one")
	t.check(camera.ignore_rotation and is_zero_approx(camera.rotation),
			"and puts the player's own camera back to the window's real, unrotated shape")
	t.check(main._title.transform == Transform2D.IDENTITY,
			"and the title's own layer, the screen this whole test is about, matches too")

	main._status.free()
	main._status_layer.free()
	main._title.free()
	main._edge_layer.free()
	hud.free()
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
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
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

## M120: the border band the camera may see (`City.camera_bounds()`) has to reach exactly as far
## as `_paint_outside_the_map()` painted it, in every direction a look-ahead glance can push the
## drawn view — not only wherever `Camera2D.limit_*` alone would stop it.
##
## Computed rather than driven through a real windowed `Camera2D`: engine-internal clamping and
## smoothing run once a frame through the rendering server, which nothing in this synchronous
## headless suite steps. The check instead does the same arithmetic Godot's own clamp does —
## `position` held inside `limit_left..limit_right` less half the visible view, `Stroller.
## CAMERA_LOOK_AHEAD` added on top the way `_camera.offset` is, unclamped — for the worst-case
## glance at each of the four corners, and reads the real painted `TileMapLayer` cell by cell
## rather than re-deriving what should be there.
func _test_the_border_reaches_the_window_from_every_corner(t) -> void:
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))

	var bounds := city.camera_bounds()
	var half := Tuning.VIEW_HALF_EXTENT
	var lead := Stroller.CAMERA_LOOK_AHEAD
	var size := city.map.world_size()
	var corners := {
		"nw": Vector2(0.0, 0.0), "ne": Vector2(size.x, 0.0),
		"sw": Vector2(0.0, size.y), "se": Vector2(size.x, size.y),
	}
	for name in corners:
		var toward: Vector2 = corners[name]
		# Where `Camera2D.limit_*` alone would hold `position`: as close to the corner as the
		# clamp allows, which `City.camera_bounds()` already keeps flush with the painted band on
		# the two sides a square viewport does not out-reach.
		var clamped := Vector2(
				clampf(toward.x, bounds.position.x + half.x, bounds.end.x - half.x),
				clampf(toward.y, bounds.position.y + half.y, bounds.end.y - half.y))
		# The look-ahead lead a glance straight at this corner adds on top, unclamped — the whole
		# reach on whichever axis a facing may point purely along.
		var glance := Vector2(
				lead if toward.x > size.x * 0.5 else -lead,
				lead if toward.y > size.y * 0.5 else -lead)
		var window := Rect2(clamped + glance - half, half * 2.0)
		var lo := city.map.world_to_tile(window.position)
		var hi := city.map.world_to_tile(window.end - Vector2.ONE)
		var unpainted := 0
		for y in range(lo.y, hi.y + 1):
			for x in range(lo.x, hi.x + 1):
				if city._ground.get_cell_source_id(Vector2i(x, y)) < 0:
					unpainted += 1
		t.check(unpainted == 0,
				"corner %s: every cell the window can show is painted (%d unpainted of %d)"
				% [name, unpainted, (hi.x - lo.x + 1) * (hi.y - lo.y + 1)])

	city.free()
	GameState.play_seconds = 0.0

# ------------------------------------------------------------- focus pause ---

## `DevFlags.no_focus_pause()` reads the real command line, so a test drives the two private
## parsing helpers directly instead — the same seam `tests/test_invincible.gd` uses for
## `_invincible_from_args()`/`_invincible_from_query()`.
func _test_no_focus_pause_from_args(t) -> void:
	t.check(not DevFlags._no_focus_pause_from_args(PackedStringArray()),
			"no command-line modifier leaves focus loss pausing the game")
	t.check(DevFlags._no_focus_pause_from_args(PackedStringArray(["--no-focus-pause"])),
			"--no-focus-pause turns it off directly")
	t.check(DevFlags._no_focus_pause_from_args(PackedStringArray(["--screenshot", "out.png"])),
			"--screenshot implies it without being told to, since a rig's window opens unfocused")
	t.check(not DevFlags._no_focus_pause_from_args(PackedStringArray(["--seed", "1"])),
			"an unrelated flag does not imply it")

func _test_no_focus_pause_from_query(t) -> void:
	t.check(not DevFlags._no_focus_pause_from_query(""),
			"an absent URL parameter leaves focus loss pausing the game")
	t.check(not DevFlags._no_focus_pause_from_query("?nofocuspause=0"),
			"nofocuspause=0 leaves it pausing")
	t.check(DevFlags._no_focus_pause_from_query("?nofocuspause=1"),
			"?nofocuspause=1 turns it off")
	t.check(DevFlags._no_focus_pause_from_query("?seed=1&nofocuspause=1&day=2"),
			"the parameter is found among other URL parameters")

## A script-only `main`, the same shape `_test_the_summary_and_pause_restart_signals_are_both_
## connected()` above builds, with the three real screens `_pause_on_focus_lost()` asks about
## added to the live tree so `is_open()`/`is_showing()` and `get_tree().paused` answer for real.
## `_no_focus_pause` starts `false` — a played day, no override — the release shape each test
## changes only what it means to check.
func _build_focus_pause_main(t) -> Node2D:
	var main: Node2D = MAIN_SCRIPT.new()
	main._summary = DAY_SUMMARY_SCENE.instantiate()
	t.add_child(main._summary)
	main._pause = PAUSE_SCREEN_SCENE.instantiate()
	t.add_child(main._pause)
	main._title = TITLE_SCREEN_SCENE.instantiate()
	t.add_child(main._title)
	main._no_focus_pause = false
	return main

func _teardown_focus_pause_main(t, main: Node2D) -> void:
	t.get_tree().paused = false
	main._summary.queue_free()
	main._pause.queue_free()
	main._title.queue_free()
	main.free()

## The heart of the milestone: losing focus during a played day reaches the same
## `PauseScreen.open()` the `pause` action does, driven by calling `notification()` directly
## rather than by real window focus — a sandboxed rig's window is not guaranteed to ever hold or
## lose real OS focus, so the engine's own dispatch is what a suite can rely on.
func _test_focus_lost_opens_the_pause_during_a_played_day(t) -> void:
	var main := _build_focus_pause_main(t)
	t.get_tree().paused = false
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(main._pause.is_open(),
			"losing focus opens the same pause screen the pause action does")
	t.check(t.get_tree().paused, "and pauses the tree behind it, exactly as that action leaves it")
	_teardown_focus_pause_main(t, main)

## A phone sending the app away reaches the same call through the other notification
## `main._notification()` listens for.
func _test_application_paused_also_opens_the_pause(t) -> void:
	var main := _build_focus_pause_main(t)
	t.get_tree().paused = false
	main.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	t.check(main._pause.is_open(), "a phone sending the app away pauses a played day the same way")
	_teardown_focus_pause_main(t, main)

## The title has nothing behind it to pause — the same reason the `pause` action itself does not
## open over it, in `_unhandled_input()` above.
func _test_focus_lost_does_nothing_on_the_title(t) -> void:
	var main := _build_focus_pause_main(t)
	main._title.open(false)
	t.get_tree().paused = false
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not main._pause.is_open(), "the title screen has nothing behind it to pause")
	t.check(not t.get_tree().paused, "so the tree keeps running")
	_teardown_focus_pause_main(t, main)

## **Unlike `Esc`, which opens the pause over the day summary on purpose** (see
## `_unhandled_input()`'s own doc), losing focus does not choose to open a second screen over one
## already asking for the player's attention.
func _test_focus_lost_does_nothing_over_the_day_summary(t) -> void:
	var main := _build_focus_pause_main(t)
	main._summary.show_day(3, GameEnums.DayResult.WON, "", 3)
	t.check(main._summary.is_showing(), "the day summary is up")
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not main._pause.is_open(),
			"focus loss does not open a second screen over the day summary, unlike the pause action")
	_teardown_focus_pause_main(t, main)

## The ending is the same `_summary` screen showing a different body — see `DaySummary.
## show_ending()` — so it is covered by the same `is_showing()` guard rather than a case of its own.
func _test_focus_lost_does_nothing_over_the_ending(t) -> void:
	var main := _build_focus_pause_main(t)
	main._summary.show_ending(GameEnums.Ending.GOOD)
	t.check(main._summary.is_showing(), "the ending screen is up")
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not main._pause.is_open(), "focus loss does not open a second screen over the ending")
	_teardown_focus_pause_main(t, main)

func _test_focus_lost_does_nothing_when_the_pause_is_already_open(t) -> void:
	var main := _build_focus_pause_main(t)
	main._pause.open()
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(main._pause.is_open(), "the pause stays exactly as it was — open, not toggled")
	_teardown_focus_pause_main(t, main)

## The decided detail this milestone leaves open to overturn: getting focus back does not resume —
## the player continues when they are back, the pause screen stays up until they do.
func _test_focus_gained_does_not_resume(t) -> void:
	var main := _build_focus_pause_main(t)
	t.get_tree().paused = false
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(main._pause.is_open() and t.get_tree().paused, "focus loss opened and paused it")
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	t.check(main._pause.is_open() and t.get_tree().paused,
			"getting focus back does not resume — the player continues when they are back")
	_teardown_focus_pause_main(t, main)

## `--no-focus-pause` and `--screenshot` (see `_test_no_focus_pause_from_args()` above for the
## implication itself) both reach `main` as the one member the notification reads — this is the
## behaviour half of that flag, driven the same way `_debug`/`_readout_requested` are throughout
## this file.
func _test_focus_lost_does_nothing_under_the_override(t) -> void:
	var main := _build_focus_pause_main(t)
	main._no_focus_pause = true
	t.get_tree().paused = false
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not main._pause.is_open(), "--no-focus-pause turns off the notification's own pause")
	t.check(not t.get_tree().paused, "and the tree keeps running")
	_teardown_focus_pause_main(t, main)

# ------------------------------------------------------- day 14 hands over ---

## **The last day ends by handing over, not by ending the run.** *(PLAYTEST-113: "the escape the
## building starts when the player has completed all tasks by the end of day 14".)* The escape is
## the good ending played rather than announced, so a won day 14 with every task complete must
## leave `GameState` exactly where it is — no `ending`, no cleared save, day 14 still — and only
## record which section the run is now in. A run whose ending were set here could write no save at
## all (`GameSave._write_now()` refuses one), and the section checkpoints would have nothing to
## come back to.
##
## Driven through `main._on_day_finished()` itself against a real city, day and summary, because
## the thing that has to hold is an *omission* — that `GameState.finish_day()` is not called — and
## an omission is only visible where the call would have been.
func _test_a_won_day_fourteen_with_every_task_hands_over_instead_of_ending(t) -> void:
	var baseline := GameState.save_snapshot()
	var saved_paused: bool = t.get_tree().paused

	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	# The camera and the baby are named by hand for the reason the **verify** skill names: a
	# hand-built `Stroller` looks them up by node path, and `Camera2D.new()` is not called
	# `Camera2D`, so a rig without them passes vacuously or throws on the first lookup.
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
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
	var summary: CanvasLayer = DAY_SUMMARY_SCENE.instantiate()
	t.add_child(summary)

	var main: Node2D = MAIN_SCRIPT.new()
	main._city = city
	main._player = stroller
	main._day = day
	main._summary = summary

	GameState.start_run(SEED)
	GameState.day = Tuning.RUN_LENGTH_DAYS
	GameState.resistance_progress = Tuning.RESISTANCE_GOAL
	GameState.sabotage_done = true
	main._on_day_finished(GameEnums.DayResult.WON)
	t.check(GameState.ending == GameEnums.Ending.NONE,
			"a won day 14 with every task complete does not end the run")
	t.check(GameState.escape_section == FinaleController.Section.BUILDING,
			"it puts the run in the building, which is where the escape starts")
	t.check(GameState.day == Tuning.RUN_LENGTH_DAYS, "and leaves the calendar alone")
	t.check(not main._run_over, "so nothing downstream thinks the run is over")

	# The other side of the same day: the legwork done and the last night skipped is still the
	# neutral ending it has always been, and must not reach the escape.
	GameState.start_run(SEED)
	GameState.day = Tuning.RUN_LENGTH_DAYS
	GameState.resistance_progress = Tuning.RESISTANCE_GOAL
	GameState.sabotage_done = false
	main._on_day_finished(GameEnums.DayResult.WON)
	t.check(GameState.ending == GameEnums.Ending.NEUTRAL,
			"a won day 14 without the last night still ends the run on the neutral ending")
	t.check(GameState.escape_section == FinaleController.Section.NONE,
			"and never reaches the escape")

	summary.free()
	day.free()
	stroller.free()
	city.free()
	main.free()
	GameState.restore_snapshot(baseline)
	GameState.escape_section = FinaleController.Section.NONE
	t.get_tree().paused = saved_paused

# ------------------------------------------------------------------ a rig's own lockdown ---
## M195: `DevFlags.is_rig()` reads the real command line, so a test drives its own pure inner
## function directly — the same seam `_no_focus_pause_from_args()` above already is for its flag.
## This is also the exact set `main._input()`'s own gate (`_rig_locked_out`) and
## `_lock_out_a_rig()`'s window-flag/`InputMap`-erasure both key off, so a case proven here holds
## for all three without a live window to check them against.
func _test_is_rig_from_args(t) -> void:
	t.check(not DevFlags._is_rig_from_args(PackedStringArray()),
			"no flags at all is a person, not a rig")
	t.check(not DevFlags._is_rig_from_args(PackedStringArray(["--seed", "1", "--day", "9"])),
			"flags that only choose what she is looking at do not make it a rig")
	for flag in ["--screenshot", "--walk", "--flee", "--press", "--tap", "--route"]:
		t.check(DevFlags._is_rig_from_args(PackedStringArray([flag, "x"])),
				"%s alone marks the run a rig" % flag)
	t.check(DevFlags._is_rig_from_args(PackedStringArray(["--seed", "1", "--walk", "north"])),
			"a rig flag among others still counts")

## `rig_quit_seconds_from(after, day_length)` — the pure formula both `main._process()`'s own
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
	t.check(is_equal_approx(DevFlags.rig_quit_seconds_from(-1.0, 5.0), margin),
			"a very short day still gets at least the margin, never less")
	t.check(is_equal_approx(DevFlags.rig_quit_seconds_from(5000.0, 210.0), ceiling),
			"an outsized --after is clamped to the fixed ceiling rather than honoured outright")
	t.check(ceiling > 210.0 + margin,
			"the ceiling comfortably fits a whole ordinary day plus its own margin")
