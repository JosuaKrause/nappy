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
	_test_boot_camera_handoff_starts_at_the_player(t)
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
	_test_the_unclamped_view_at_every_corner_is_painted(t)
	_test_the_overview_is_landscape_to_every_edge(t)
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
	_test_return_ignores_input_for_half_a_second(t)
	_test_return_window_always_ends(t)
	_test_return_window_needs_a_departure(t)
	_test_return_window_is_off_under_the_override(t)
	_test_a_won_day_fourteen_with_every_task_hands_over_instead_of_ending(t)

## Read the camera's actual screen center before any process tick can hide a bad handoff.
func _test_boot_camera_handoff_starts_at_the_player(t) -> void:
	var interpolated: bool = t.get_tree().physics_interpolation
	for mode in [true, false]:
		t.get_tree().physics_interpolation = mode
		_check_boot_camera_handoff(t)
	t.get_tree().physics_interpolation = interpolated

func _check_boot_camera_handoff(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	var boot := Camera2D.new()
	boot.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	boot.position = Vector2(2400, 2600)
	t.add_child(boot)
	boot.make_current()
	main._boot_camera = boot
	var packed: PackedScene = load("res://scenes/player/stroller.tscn")
	var player: Stroller = packed.instantiate()
	t.add_child(player)
	player.set_physics_process(false)
	main._player = player
	var destination := Vector2(1800, 1400)
	player.reset_at(destination, Vector2.RIGHT)
	main._retire_the_boot_camera()
	var camera: Camera2D = player.get_node("Camera2D")
	print("CAMERA_HANDOFF player=%s screen=%s target=%s" % [player.global_position,
			camera.get_screen_center_position(), camera.get_target_position()])
	t.check(camera.is_current() and camera.get_screen_center_position().is_equal_approx(destination),
			"boot handoff starts on the placed player before any smoothing frame")
	t.check(camera.position_smoothing_enabled, "boot handoff preserves normal follow smoothing")
	var runtime := SceneRecipeRuntime.new()
	t.add_child(runtime)
	runtime._player = player
	runtime._settle_starting_camera()
	print("CAMERA_SETTLED interpolation=%s screen=%s offset=%s" % [
			t.get_tree().physics_interpolation, camera.get_screen_center_position(), camera.offset])
	t.check(camera.get_screen_center_position().is_equal_approx(
			destination + Vector2(Stroller.CAMERA_LOOK_AHEAD, 0)),
			"a settled recipe starts at the actual player with its authored facing lead")
	runtime.free()
	player.set_camera_limits(Rect2(1000, 1000, 1600, 1200))
	player.reset_at(Vector2(1500, 1500))
	camera.force_update_scroll()
	t.check(camera.limit_left == 1000 and camera.limit_bottom == 2200,
			"a placed interior player keeps the room's camera limits")
	player.clear_camera_limits()
	t.check(camera.limit_left < 0 and camera.limit_right > 100000,
			"returning outdoors removes the interior's camera limits")
	player.free()
	main.free()

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
## one node either way and hands it a starting mode through `set_mode()` with `ControlsMode.resolve()`,
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

	var chosen: Array = []
	var record := func(mode: int, by_key: bool) -> void: chosen.append([mode, by_key])
	EventBus.controls_chosen.connect(record)
	main._on_title_start(ControlsMode.Mode.JOYSTICK)
	t.check(main._touch_controls._mode == ControlsMode.Mode.JOYSTICK,
			"pressing the joystick button on the title screen sets that mode on the one control reader")
	t.check(main._touch_controls.run_button_center() == TouchControls.FOCUS_RIGHT,
			"the left joystick button steers from the left, with Run on the right")
	main._on_title_start(ControlsMode.Mode.JOYSTICK, false, ControlsMode.Side.RIGHT)
	t.check(main._touch_controls.run_button_center() == TouchControls.FOCUS_LEFT,
			"and the right one steers from the right, with Run on the left")
	main._on_title_start(ControlsMode.Mode.TAP, true)
	EventBus.controls_chosen.disconnect(record)
	t.check(main._touch_controls._mode == ControlsMode.Mode.TAP,
			"a key begins the run in tap mode")
	t.check(chosen == [[ControlsMode.Mode.JOYSTICK, false], [ControlsMode.Mode.JOYSTICK, false],
			[ControlsMode.Mode.TAP, true]],
			"and the counter hears which input began each run, a key as a key")

	# The last answer was a key's tap scheme; a joystick-right player's run is the one that matters
	# for the hand-over below.
	main._on_title_start(ControlsMode.Mode.JOYSTICK, false, ControlsMode.Side.RIGHT)
	_test_the_title_choice_survives_the_handover_to_the_escape(t)

	main._status.free()
	main._title.free()
	main._edge_layer.free()
	main._hud.free()
	main._city.free()
	main.free()
	stroller.free()

## **A joystick-right player reaches the escape still joystick-right.** *(2026-10-10, the player:
## "permanently for the sitting".)* The day-14 hand-over reloads the scene and the escape's boot
## opens no title, so its fresh controls take the title's answer this process remembers rather than
## the rig's default; an ordinary boot, whose title asks again, still starts from the rig's default.
## Called by `_test_on_title_start_sets_the_controls_mode` right after a joystick-right title press.
func _test_the_title_choice_survives_the_handover_to_the_escape(t) -> void:
	var escape: Node2D = MAIN_SCRIPT.new()
	escape._escape_from_a_run = true
	escape._add_touch_controls()
	t.check(escape._touch_controls.controls_mode() == ControlsMode.Mode.JOYSTICK
			and escape._touch_controls.run_button_center() == TouchControls.FOCUS_LEFT,
			"the escape's controls keep the joystick, steering from the right with Run on the left")
	escape.free()

	var fresh: Node2D = MAIN_SCRIPT.new()
	fresh._add_touch_controls()
	t.check(fresh._touch_controls.controls_mode() == ControlsMode.Mode.TAP,
			"a boot that opens its title starts from the rig's default, and the title asks again")
	fresh.free()

	# Process-wide state, not scoped to this test — reset for every later suite's own escape boot.
	ControlsMode._remembered = false
	ControlsMode._remembered_mode = ControlsMode.Mode.TAP
	ControlsMode._remembered_side = ControlsMode.Side.LEFT

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

## `_open_the_title()` asks `_apply_orientation()` again rather than trusting the answer the
## previous call left — a safeguard that finds nothing to change in the running game, where
## `_ready()`'s own call comes in the same stretch with no frame between, and that this test gives
## a stale answer to correct.
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
	main._player.set_screen_rotation(true)
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
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))

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
				City.OUTSIDE_DEPTH_TILES * float(Tuning.TILE_SIZE))
		beyond_the_band = beyond_the_band or not band.encloses(window)
		city.scenery.update(window, true)
		var lo := city.map.world_to_tile(window.position)
		var hi := city.map.world_to_tile(window.end - Vector2.ONE)
		var unpainted := 0
		for y in range(lo.y, hi.y + 1):
			for x in range(lo.x, hi.x + 1):
				var cell := Vector2i(x, y)
				if city._ground.get_cell_source_id(cell) < 0 \
						and not city._ground.has_water(cell):
					unpainted += 1
		t.check(unpainted == 0,
				"corner %s: every cell the window can show is painted (%d unpainted of %d)"
				% [name, unpainted, (hi.x - lo.x + 1) * (hi.y - lo.y + 1)])

	t.check(beyond_the_band, "a corner view reaches past the band, so the check is not vacuous")
	city.free()
	GameState.play_seconds = 0.0

## The trailer overview grows the finite city by one authored landscape margin. Its added east and
## west columns are forest, while the north and south bands own their corners and the bridge's
## road carries on to any depth.
func _test_the_overview_is_landscape_to_every_edge(t) -> void:
	var city: City = CITY_SCENE.instantiate()
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
	var keys := city._ground.keys_in(view)

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
	for depth in [City.OUTSIDE_DEPTH_TILES, City.OUTSIDE_DEPTH_TILES * 4]:
		t.check(city.scenery_ground_source(Vector2i(south_spine_x,
				city.map.size.y + depth)) != GroundTiles.WATER,
				"the southern bridge's road carries on %d tiles out, to the edge of any view" % depth)
	t.check(city.scenery_ground_source(Vector2i(south_spine_x - 2,
			city.map.size.y + City.OUTSIDE_DEPTH_TILES * 4)) == GroundTiles.WATER,
			"the water either side of the bridge goes on too")

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
	main._summary.show_day(GameEnums.DayResult.WON, "", 3)
	t.check(main._summary.is_showing(), "the day summary is up")
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not main._pause.is_open(),
			"focus loss does not open a second screen over the day summary, unlike the pause action")
	_teardown_focus_pause_main(t, main)

## The ending is the same `_summary` screen showing a different body — see `DaySummary.
## show_ending()` — so it is covered by the same `is_showing()` guard rather than a case of its own.
func _test_focus_lost_does_nothing_over_the_ending(t) -> void:
	var main := _build_focus_pause_main(t)
	main._summary.show_ending(GameEnums.Ending.GOOD, GameState.day)
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

## Inbox #534: for `RETURN_INPUT_IGNORED_MSEC` after `FOCUS_IN` or `RESUMED` the viewport delivers
## nothing (`_arm_the_return_window()` calls `set_disable_input(true)`), so the press that brings
## the page back cannot resume the pause screen or start the day brief. Real events are pushed
## through the suite's own viewport; the window's end is moved into the past rather than waited out
## (`run_tests.gd` is synchronous, so the real 500ms timer cannot fire inside a test).
func _press_accept(t) -> void:
	var press := InputEventAction.new()
	press.action = &"ui_accept"
	press.pressed = true
	t.get_viewport().push_input(press)

func _test_return_ignores_input_for_half_a_second(t) -> void:
	t.check(MAIN_SCRIPT.RETURN_INPUT_IGNORED_MSEC == 500, "the window is 500ms")
	for what in [Node.NOTIFICATION_APPLICATION_FOCUS_IN, Node.NOTIFICATION_APPLICATION_RESUMED]:
		# The pause screen.
		var main := _build_focus_pause_main(t)
		main._return_viewport = t.get_viewport()
		t.get_tree().paused = false
		main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		main.notification(what)
		t.check(t.get_viewport().is_input_disabled(), "a return switches the viewport's input off")
		_press_accept(t)
		t.check(main._pause.is_open(), "a press inside the window does not resume the pause (%d)" % what)
		main._input_ignored_until_msec = Time.get_ticks_msec() - 1
		main._end_the_return_window()
		t.check(not t.get_viewport().is_input_disabled(), "the window's end switches it back on")
		_press_accept(t)
		t.check(not main._pause.is_open(), "the same press after the window resumes")
		# The day brief.
		var starts := [0]
		main._summary.continued.connect(func(): starts[0] += 1)
		main._summary.show_day_brief(3, 3)
		main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		main.notification(what)
		_press_accept(t)
		t.check(starts[0] == 0, "a press inside the window does not start the day from the brief")
		main._input_ignored_until_msec = Time.get_ticks_msec() - 1
		main._end_the_return_window()
		_press_accept(t)
		t.check(starts[0] == 1, "the same press after the window starts it")
		t.get_viewport().set_disable_input(false)
		_teardown_focus_pause_main(t, main)

## Nothing can leave input off. A second trigger (the web's page events beside the engine's own)
## moves the end rather than stacking; an end read early (a frame landing inside the window, which
## is what a `SceneTreeTimer` firing early looked like) changes nothing and a later frame still
## puts input back; and a scene reload inside the window (`_exit_tree()`) puts it back at once,
## because the root viewport outlives the scene.
func _test_return_window_always_ends(t) -> void:
	var main := _build_focus_pause_main(t)
	main._return_viewport = t.get_viewport()
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	main._arm_the_return_window()
	main._process(0.0)
	t.check(t.get_viewport().is_input_disabled(), "a frame inside the window leaves it running")
	main._input_ignored_until_msec = Time.get_ticks_msec() - 1
	main._process(0.0)
	t.check(not t.get_viewport().is_input_disabled(), "the first frame after it puts input back")
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	main._exit_tree()
	t.check(not t.get_viewport().is_input_disabled(),
			"a scene reload inside the window does not leave the new scene deaf")
	_teardown_focus_pause_main(t, main)

## The window opens on a return, not on the first focus at load: a focus-in with no loss before it
## does not arm (the v0.25.0 browser check's Space arrived inside it and was dropped), a loss then a
## focus-in does, and the web's `blur`/`visibilitychange`/`focus` decide the same way.
func _test_return_window_needs_a_departure(t) -> void:
	var main := _build_focus_pause_main(t)
	main._return_viewport = t.get_viewport()
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	t.check(not t.get_viewport().is_input_disabled() and main._input_ignored_until_msec == 0,
			"a focus-in with no loss before it (the page's own focus at load) does not arm")
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	t.check(t.get_viewport().is_input_disabled(), "a loss then a focus-in arms")
	main._end_the_return_window(true)
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	t.check(not t.get_viewport().is_input_disabled(), "the departure is spent: a second focus-in does not arm")
	# The web path.
	main._on_web_event("focus", "visible")
	t.check(not t.get_viewport().is_input_disabled(), "web: a focus with no blur before it does not arm")
	main._on_web_event("blur", "visible")
	main._on_web_event("focus", "visible")
	t.check(t.get_viewport().is_input_disabled(), "web: a blur then a focus arms")
	main._end_the_return_window(true)
	main._on_web_event("visibilitychange", "hidden")
	t.check(not t.get_viewport().is_input_disabled(), "web: the page going hidden does not arm")
	main._on_web_event("visibilitychange", "visible")
	t.check(t.get_viewport().is_input_disabled(), "web: hidden then visible arms")
	t.get_viewport().set_disable_input(false)
	_teardown_focus_pause_main(t, main)

## A rig (`--no-focus-pause`, `--screenshot`) is never slowed by the window.
func _test_return_window_is_off_under_the_override(t) -> void:
	var main := _build_focus_pause_main(t)
	main._return_viewport = t.get_viewport()
	main._no_focus_pause = true
	main._has_left_the_game = true
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	t.check(not t.get_viewport().is_input_disabled(),
			"under the override a return does not start the window")
	main._no_focus_pause = false
	main._rig_locked_out = true
	main._has_left_the_game = true
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	t.check(not t.get_viewport().is_input_disabled(), "nor does a rig run (--walk, --press ...)")
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
	# Below the cap (`Tuning.STARTING_NERVES`, 5) so a missing or doubled
	# `GameState.regain_a_nerve()` call in the hand-over branch (`main.gd`'s
	# `_hands_over_to_the_escape()` path) would show up as a wrong count rather than being masked
	# by the cap `GameState.start_run()` already sets `nerves` to.
	GameState.nerves = 3
	main._on_day_finished(GameEnums.DayResult.WON)
	t.check(GameState.ending == GameEnums.Ending.NONE,
			"a won day 14 with every task complete does not end the run")
	t.check(GameState.escape_section == FinaleController.Section.BUILDING,
			"it puts the run in the building, which is where the escape starts")
	t.check(GameState.day == Tuning.RUN_LENGTH_DAYS, "and leaves the calendar alone")
	t.check(not main._run_over, "so nothing downstream thinks the run is over")
	t.check(GameState.nerves == 4,
			"day 14's win still gives a nerve back, and exactly once, through the direct call")

	# The other side of the same day: the legwork done and the last night skipped is still the
	# neutral ending it has always been, and must not reach the escape.
	GameState.start_run(SEED)
	GameState.day = Tuning.RUN_LENGTH_DAYS
	GameState.resistance_progress = Tuning.RESISTANCE_GOAL
	GameState.sabotage_done = false
	GameState.nerves = 3
	main._on_day_finished(GameEnums.DayResult.WON)
	t.check(GameState.ending == GameEnums.Ending.NEUTRAL,
			"a won day 14 without the last night still ends the run on the neutral ending")
	t.check(GameState.escape_section == FinaleController.Section.NONE,
			"and never reaches the escape")
	t.check(GameState.nerves == 4,
			"and this path's win gains a nerve too, through the ordinary GameState.finish_day()")

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
