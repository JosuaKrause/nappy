extends RefCounted
## The rotated presentation for a portrait touch window — see `ScreenOrientation`.
##
## The one thing that can break silently: the stick, the run button and the pause button all
## grab a touch by comparing its position to a fixed constant, so a rotation that draws the
## controls in the right place while the remap it needs is missing, wrong, or falls out of sync
## with the draw transform would pass every visual screenshot check and still put a thumb's press
## under the wrong control. This suite proves the remap by construction: a touch sent at the
## exact screen position `ScreenOrientation.to_presented_space()` says a design-space point ends
## up at, while rotated, must be read back by `TouchControls` as that same design-space point.
##
## **What none of that can prove is a sign error the world and the drawing share** — playtest 23's
## finding, on a build this suite's earlier checks all passed. A test can assert a transform;
## it cannot look at a picture. So alongside the transform checks below, `pin_to_design_box()` and
## `apply_to_layer()` — the two `ScreenOrientation` helpers every rotating `CanvasLayer` calls — are
## checked to compose correctly, and `main._screen_furniture_layers()` is checked to still name
## every layer it should, so a layer added later and forgotten there is a failing test rather than
## a picture nobody happened to take. The picture still has to be taken too — see
## `docs/evidence/` for the ones this milestone's report cites.

const TOUCH_CONTROLS := preload("res://scenes/ui/touch_controls.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const DAY_SUMMARY_SCENE := preload("res://scenes/ui/day_summary.tscn")
const PAUSE_SCREEN_SCENE := preload("res://scenes/ui/pause_screen.tscn")
const TITLE_SCREEN_SCENE := preload("res://scenes/ui/title_screen.tscn")
const MAIN_SCRIPT: GDScript = preload("res://src/main.gd")

func run(t) -> void:
	_test_wants_rotation_only_for_a_portrait_touch_window(t)
	_test_content_scale_size_matches_the_rotated_or_unrotated_design_box(t)
	_test_the_transform_sends_the_design_centre_to_the_rotated_centre(t)
	_test_the_transform_round_trips(t)
	_test_a_rotated_touch_still_grabs_the_stick(t)
	_test_a_rotated_touch_still_holds_the_run_button(t)
	_test_a_rotated_touch_still_fires_the_pause_button(t)
	_test_pin_to_design_box_gives_a_fixed_rect_regardless_of_any_parent(t)
	_test_apply_to_layer_is_identity_unrotated_and_the_rotation_when_rotated(t)
	_test_a_pinned_rotated_layer_puts_a_design_point_at_its_presented_position(t)
	_test_every_screen_furniture_layer_is_named_by_main(t)
	_release_actions()

func _controls(t) -> TouchControls:
	var controls: TouchControls = TOUCH_CONTROLS.instantiate()
	t.add_child(controls)
	controls.set_process(false)
	controls.visible = true
	return controls

## **Only a touch device in a portrait window rotates.** A narrow desktop window is portrait too,
## and `export_presets.cfg`'s own retired rotate overlay used to gate its message on
## `(hover: none) and (pointer: coarse)` alongside `(orientation: portrait)` for exactly the
## reason repeated here: nobody resizing a desktop window narrower than it is tall asked for a
## sideways game.
func _test_wants_rotation_only_for_a_portrait_touch_window(t: Node) -> void:
	t.check(not ScreenOrientation.wants_rotation(Vector2(1280.0, 720.0), true),
			"a landscape window does not rotate even on a touch device")
	t.check(not ScreenOrientation.wants_rotation(Vector2(400.0, 900.0), false),
			"a narrow window with no touch hardware is left alone")
	t.check(ScreenOrientation.wants_rotation(Vector2(400.0, 900.0), true),
			"a portrait window on a touch device rotates")

func _test_content_scale_size_matches_the_rotated_or_unrotated_design_box(t: Node) -> void:
	t.check(Vector2(ScreenOrientation.content_scale_size(false)) == ScreenOrientation.DESIGN_SIZE,
			"unrotated presents at the project's own 1280x720")
	t.check(Vector2(ScreenOrientation.content_scale_size(true)) == ScreenOrientation.ROTATED_SIZE,
			"rotated presents at the swapped 720x1280 -- the box a real touch then arrives in")

## Rotating about the centre of one box onto the centre of the other is the simplest thing that
## can be wrong in either direction (swapped axes, a stray translation) and still look plausible,
## so it is worth its own check before the round trip below is trusted.
func _test_the_transform_sends_the_design_centre_to_the_rotated_centre(t: Node) -> void:
	var mapped := ScreenOrientation.to_presented_space(ScreenOrientation.DESIGN_SIZE * 0.5, true)
	t.check(mapped.is_equal_approx(ScreenOrientation.ROTATED_SIZE * 0.5),
			"the centre of the 1280x720 box lands on the centre of the 720x1280 one")

## **A relationship, not a value**: whatever `rotation_transform()` actually is, going out and
## back must be the identity, for several points including ones outside the design box (where a
## touch on the letterboxed edge of a non-16:9 window would land).
func _test_the_transform_round_trips(t: Node) -> void:
	for point in [Vector2(130.0, 500.0), Vector2(1150.0, 500.0), Vector2(1250.0, 30.0),
			Vector2.ZERO, Vector2(-40.0, 800.0)]:
		var there := ScreenOrientation.to_presented_space(point, true)
		var back := ScreenOrientation.to_design_space(there, true)
		t.check(back.is_equal_approx(point),
				"round-tripping %s through the rotation lands back on itself" % point)

## **The test that proves the thing a screenshot cannot**: a touch at the screen position the
## stick is actually drawn at while rotated must still grab the stick, and must still read the
## deflection in the same direction a keyboard's `move_up` would.
func _test_a_rotated_touch_still_grabs_the_stick(t: Node) -> void:
	var controls := _controls(t)
	controls.rotated = true

	var design_touch := TouchControls.STICK_CENTRE + Vector2(0.0, -1.0)
	var screen_touch := ScreenOrientation.to_presented_space(design_touch, true)
	controls._input(_touch_event(0, screen_touch, true))
	t.check(Input.is_action_pressed("move_up"),
			"a rotated touch at the stick's own screen position still presses move_up")

	var design_drag := TouchControls.STICK_CENTRE + Vector2(0.0, -TouchControls.STICK_RADIUS)
	var screen_drag := ScreenOrientation.to_presented_space(design_drag, true)
	controls._input(_drag_event(0, screen_drag))
	t.close_to(Input.get_action_strength("move_up"), 1.0,
			"a full deflection at its own rotated screen position still reads full strength")

	controls._input(_touch_event(0, ScreenOrientation.to_presented_space(Vector2.ZERO, true),
			false))
	controls.queue_free()

func _test_a_rotated_touch_still_holds_the_run_button(t: Node) -> void:
	var controls := _controls(t)
	controls.rotated = true

	var screen_run := ScreenOrientation.to_presented_space(TouchControls.RUN_CENTRE, true)
	controls._input(_touch_event(0, screen_run, true))
	t.check(Input.is_action_pressed("run"),
			"a rotated touch at the run button's own screen position holds run")

	controls._input(_touch_event(0, screen_run, false))
	t.check(not Input.is_action_pressed("run"), "and releasing there lets go of it again")
	controls.queue_free()

func _test_a_rotated_touch_still_fires_the_pause_button(t: Node) -> void:
	var controls := _controls(t)
	controls.rotated = true

	var screen_pause := ScreenOrientation.to_presented_space(TouchControls.PAUSE_CENTRE, true)
	controls._input(_touch_event(0, screen_pause, true))
	t.check(controls._pause_touch == 0,
			"a rotated touch at the pause button's own screen position grabs its index")

	controls._input(_touch_event(0, screen_pause, false))
	t.check(controls._pause_touch == -1, "and releasing there lets the index go again")

	# The geometry the release itself asks is answered in design space (`_pause_fires` is a pure
	# function over the space `TouchControls` keeps everything else in) -- the remap above is
	# what has to hand it the right point, which is exactly what this whole suite is checking.
	t.check(TouchControls._pause_fires(TouchControls.PAUSE_CENTRE),
			"the pure geometry check underneath is untouched by rotation")

	controls.queue_free()
	Input.action_release(&"pause")

## `pin_to_design_box()` has to give the same fixed rect whatever it is asked to pin — that is the
## whole point of using fixed (rather than fractional) anchors: a `Control`'s own offsets then
## decide its rect independently of any parent's size. Checked by pinning one under a parent whose
## own size is nothing like 1280x720, which a fractional anchor would have picked up and a fixed
## one must not.
func _test_pin_to_design_box_gives_a_fixed_rect_regardless_of_any_parent(t: Node) -> void:
	var parent := Control.new()
	parent.size = Vector2(50.0, 4000.0)
	t.add_child(parent)
	var control := Control.new()
	parent.add_child(control)

	ScreenOrientation.pin_to_design_box(control)

	t.check(control.position.is_equal_approx(Vector2.ZERO),
			"pinned to the design box starts at the origin")
	t.check(control.size.is_equal_approx(ScreenOrientation.DESIGN_SIZE),
			"pinned to the design box is exactly 1280x720, not the parent's own 50x4000")

	control.free()
	parent.free()

## The not-rotated case is exactly identity — no rotation and no recentring — and the rotated case
## is exactly `rotation_transform()`, so `main._apply_orientation()` reads as the one call
## `apply_to_layer()` is for rather than an `if rotate: ... else: IDENTITY` at every layer.
func _test_apply_to_layer_is_identity_unrotated_and_the_rotation_when_rotated(t: Node) -> void:
	var layer := CanvasLayer.new()

	ScreenOrientation.apply_to_layer(layer, false)
	t.check(layer.transform == Transform2D.IDENTITY,
			"not rotated is exactly identity, nothing partial")

	ScreenOrientation.apply_to_layer(layer, true)
	t.check(layer.transform == ScreenOrientation.rotation_transform(),
			"rotated is exactly the one rotation every layer of screen furniture shares")

	layer.free()

## **The test a screenshot cannot be**: proves the two halves of the mechanism compose. A `Control`
## pinned to the design box and parented under a layer carrying the rotation must put a
## design-space point at exactly the screen position `ScreenOrientation.to_presented_space()` says
## that point belongs at — the same relationship `TouchControls`' own tests hold its input remap
## to, checked here for the drawing side every other layer of screen furniture relies on instead.
func _test_a_pinned_rotated_layer_puts_a_design_point_at_its_presented_position(t: Node) -> void:
	var layer := CanvasLayer.new()
	var control := Control.new()
	layer.add_child(control)
	ScreenOrientation.pin_to_design_box(control)
	ScreenOrientation.apply_to_layer(layer, true)

	for point in [Vector2(130.0, 500.0), Vector2(1150.0, 500.0), Vector2(640.0, 360.0)]:
		# The control's own transform is identity (fixed anchors, no rotation or scale of its
		# own), so a point local to it is a point in the layer's local space too -- what is left
		# to check is that the layer's transform alone carries it the rest of the way.
		var presented: Vector2 = layer.transform * (control.get_transform() * point)
		t.check(presented.is_equal_approx(ScreenOrientation.to_presented_space(point, true)),
				"design point %s lands where to_presented_space says it should" % point)

	control.free()
	layer.free()

## **So an eighth layer cannot be added and forgotten.** `main._screen_furniture_layers()` is the
## one list `_apply_orientation()` walks; this pins down exactly what it names today, so a name
## quietly dropped from it — the failure mode a screenshot of a *different* screen would never
## catch — is a red test rather than a rotation nobody happened to look at.
##
## `main.gd` is never instantiated as a scene in this suite — see `tests/test_main.gd`'s own doc
## for why — so this is the same script-only instance, its handful of dependencies wired by hand.
func _test_every_screen_furniture_layer_is_named_by_main(t: Node) -> void:
	var hud: CanvasLayer = HUD_SCENE.instantiate()
	t.add_child(hud)
	hud.set_process(false)
	var edge_layer := CanvasLayer.new()
	var touch_layer := CanvasLayer.new()
	var summary: CanvasLayer = DAY_SUMMARY_SCENE.instantiate()
	t.add_child(summary)
	var pause: CanvasLayer = PAUSE_SCREEN_SCENE.instantiate()
	t.add_child(pause)
	var title: CanvasLayer = TITLE_SCREEN_SCENE.instantiate()
	t.add_child(title)
	var status_layer := CanvasLayer.new()

	var main: Node2D = MAIN_SCRIPT.new()
	main._hud = hud
	main._edge_layer = edge_layer
	main._touch_layer = touch_layer
	main._summary = summary
	main._pause = pause
	main._title = title
	main._status_layer = status_layer

	var layers: Array[CanvasLayer] = main._screen_furniture_layers()
	t.check(layers.size() == 7, "every layer of screen furniture is named, and nothing extra")
	for layer: CanvasLayer in layers:
		t.check(layer != null, "no layer in the list is unset")
	for expected in [hud, edge_layer, touch_layer, summary, pause, title, status_layer]:
		t.check(expected in layers, "the list still names the layer main wires up for it")

	main.free()
	hud.free()
	edge_layer.free()
	touch_layer.free()
	summary.free()
	pause.free()
	title.free()
	status_layer.free()

func _touch_event(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event

func _drag_event(index: int, position: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	return event

## Global `Input` state, same reason `test_touch.gd` cleans it up: nothing here is scoped to this
## suite's own nodes.
func _release_actions() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")
	Input.action_release(&"run")
	Input.action_release(&"pause")
