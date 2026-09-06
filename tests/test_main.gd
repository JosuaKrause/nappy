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
const MAIN_SCRIPT: GDScript = preload("res://src/main.gd")

const SEED := 4242

func run(t) -> void:
	_test_the_readout_is_not_assembled_outside_a_debug_build(t)
	_test_add_touch_controls_picks_the_stick_or_the_tap_reader_by_controls_mode(t)
	_test_resolve_controls_mode_defers_until_something_answers(t)

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

## **Exactly one of the stick and the tap reader is ever in the tree**, and which one is
## `main._controls_mode`'s own choice, made once — the same shape `ScreenOrientation`'s tests hold
## `_screen_furniture_layers()` to. `_add_touch_controls()` parents whichever it builds under
## `main` itself, so freeing `main` here reaches it too.
func _test_add_touch_controls_picks_the_stick_or_the_tap_reader_by_controls_mode(t) -> void:
	var stick_main: Node2D = MAIN_SCRIPT.new()
	stick_main._controls_mode = ControlsMode.Mode.STICK
	stick_main._add_touch_controls()
	t.check(stick_main._touch_controls != null and stick_main._tap_controls == null,
			"stick mode builds the stick and not the tap reader")

	var tap_main: Node2D = MAIN_SCRIPT.new()
	tap_main._controls_mode = ControlsMode.Mode.TAP
	tap_main._add_touch_controls()
	t.check(tap_main._tap_controls != null and tap_main._touch_controls == null,
			"tap mode builds the tap reader and not the stick")

	stick_main.free()
	tap_main.free()

## **The title screen may answer after day 1 is already running behind it, and nothing may keep a
## stale copy of the answer.** *(2026-09-05, playtest 25 finding 3.)* `_resolve_controls_mode()` is
## the one place `main._controls_mode` is actually set and `_add_touch_controls()` is actually
## called from — guarded so an answer a `--controls` flag or a `?controls=` URL already built in
## `_ready()` is never rebuilt or silently replaced by whatever the title screen goes on to emit.
func _test_resolve_controls_mode_defers_until_something_answers(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	var hud: CanvasLayer = HUD_SCENE.instantiate()
	t.add_child(hud)
	hud.set_process(false)
	main._hud = hud

	t.check(main._touch_controls == null and main._tap_controls == null,
			"nothing is built before anything has answered the controls question")

	main._resolve_controls_mode(ControlsMode.Mode.TAP)
	t.check(main._tap_controls != null and main._touch_controls == null,
			"the title's own choice builds the tap reader")
	t.check(hud._controls_mode == ControlsMode.Mode.TAP, "and tells the HUD the same answer")

	# A forced flag already built one before the title ever had a chance to ask — a second call,
	# the way `_on_title_start()` would still make if the title happened to fire anyway, must not
	# replace it with a different mode.
	var already_built: TapControls = main._tap_controls
	main._resolve_controls_mode(ControlsMode.Mode.STICK)
	t.check(main._tap_controls == already_built and main._touch_controls == null,
			"an already-built answer is never rebuilt or replaced")

	main.free()
	hud.free()
