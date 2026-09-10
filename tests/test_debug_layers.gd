extends RefCounted
## `DebugLayers` (M104, "the debug view") and the two pieces of it that sit outside that one class:
## `GroundShape.shadow_outline()`, which `draw_shadow()` now draws from directly, and
## `DevFlags.parse_layers()`, the `--layers`/`?layers=` parsing.
##
## The tree-presence and key-toggle tests build `main` the way `tests/test_main.gd` already does
## for the readout — a script-only instance, `_ready()` never run, its handful of dependencies
## wired up by hand — because `main._ready()` boots a whole city and none of these questions need
## one.

const MAIN_SCRIPT: GDScript = preload("res://src/main.gd")

func run(t) -> void:
	_test_shadow_outline_matches_a_points_ellipse(t)
	_test_shadow_outline_matches_a_segments_hull(t)
	_test_shadow_outline_matches_a_rectangles_squashed_corners(t)
	_test_parse_layers_reads_a_comma_list(t)
	_test_parse_layers_drops_malformed_entries_without_crashing(t)
	_test_apply_initial_state_sets_only_the_listed_layers(t)
	_test_no_layer_node_exists_outside_a_debug_build(t)
	_test_a_debug_build_builds_the_layers_off_by_default(t)
	_test_the_layer_keys_resolve_to_their_own_index(t)
	_test_number_keys_toggle_their_own_layer(t)
	_test_layer_keys_do_nothing_outside_a_debug_build(t)

# ------------------------------------------------------------------ shadow_outline ---

func _bounds(points: PackedVector2Array) -> Rect2:
	var rect := Rect2(points[0], Vector2.ZERO)
	for point in points:
		rect = rect.expand(point)
	return rect

func _test_shadow_outline_matches_a_points_ellipse(t) -> void:
	var shape := GroundShape.point(10.0)
	var bounds := _bounds(shape.shadow_outline(Vector2(40.0, 20.0)))
	t.close_to(bounds.size.x, 20.0, "a point's shadow is as wide as its own diameter", 0.5)
	t.close_to(bounds.size.y, 20.0 * GroundShape.SHADOW_SQUASH,
			"and squashed on Y by SHADOW_SQUASH, the same foreshortening draw_shadow() always drew",
			0.5)
	t.close_to(bounds.get_center().x, 40.0, "centred on the position it was asked to draw at", 0.5)
	t.close_to(bounds.get_center().y, 20.0, "on both axes", 0.5)

func _test_shadow_outline_matches_a_segments_hull(t) -> void:
	var shape := GroundShape.segment(20.0, 6.0)
	var bounds := _bounds(shape.shadow_outline(Vector2.ZERO, Vector2.RIGHT))
	t.close_to(bounds.size.x, 2.0 * (20.0 + 6.0),
			"the hull reaches half_length + radius past centre on the spine's own axis", 1.0)
	t.close_to(bounds.size.y, 2.0 * 6.0,
			"and only the radius across it — unsquashed, since a segment's shadow carries no "
			+ "foreshortening at all (the ground plane is drawn 1:1)", 1.0)

	var vertical := shape.shadow_outline(Vector2.ZERO, Vector2.DOWN)
	var vertical_bounds := _bounds(vertical)
	t.close_to(vertical_bounds.size.y, 2.0 * (20.0 + 6.0),
			"rotating the axis rotates the hull with it, on the ground plane rather than the screen",
			1.0)
	t.close_to(vertical_bounds.size.x, 2.0 * 6.0, "and the across measurement follows", 1.0)

func _test_shadow_outline_matches_a_rectangles_squashed_corners(t) -> void:
	var shape := GroundShape.rect(Vector2(30.0, 10.0))
	var points := shape.shadow_outline(Vector2.ZERO, Vector2.RIGHT)
	t.check(points.size() == 4, "a rectangle's shadow outline is exactly its four corners")
	var bounds := _bounds(points)
	t.close_to(bounds.size.x, 60.0, "unrotated, the outline is as wide as the footprint", 0.5)
	t.close_to(bounds.size.y, 20.0 * GroundShape.SHADOW_SQUASH,
			"and squashed on Y by SHADOW_SQUASH, applied after the rotation", 0.5)

# ------------------------------------------------------------------ DevFlags.parse_layers ---

func _test_parse_layers_reads_a_comma_list(t) -> void:
	var result := DevFlags.parse_layers("1,3")
	t.check(result == [1, 3], "the two named layers, in the order given")
	t.check(DevFlags.parse_layers("") == [], "an empty value asks for nothing")

func _test_parse_layers_drops_malformed_entries_without_crashing(t) -> void:
	t.check(DevFlags.parse_layers("1,x,2") == [1, 2],
			"a non-numeric entry is dropped, not a crash or an empty result")
	t.check(DevFlags.parse_layers("1,9,0") == [1],
			"an out-of-range entry (there is no layer 9 or 0 to set) is dropped the same way")
	t.check(DevFlags.parse_layers("2,2") == [2], "a repeated entry is not added twice")

func _test_apply_initial_state_sets_only_the_listed_layers(t) -> void:
	var layers := DebugLayers.new()
	layers.apply_initial_state([1, 3])
	t.check(layers.layer_on(1) and not layers.layer_on(2) and layers.layer_on(3),
			"only the flagged layers start on")
	layers.apply_initial_state([])
	t.check(not layers.layer_on(1) and not layers.layer_on(2) and not layers.layer_on(3),
			"and an empty list turns every geometry layer back off")
	layers.free()

# ------------------------------------------------------------------ tree presence ---

func _test_no_layer_node_exists_outside_a_debug_build(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	main._debug = false
	main._city = City.new()
	main._player = Stroller.new()
	main._add_debug_layers()
	t.check(main._debug_layers == null,
			"a release build never builds the layer node at all, not merely leaves it invisible")
	main._city.free()
	main._player.free()
	main.free()

func _test_a_debug_build_builds_the_layers_off_by_default(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	main._debug = true
	main._city = City.new()
	main._player = Stroller.new()
	main._add_debug_layers()
	t.check(main._debug_layers != null and main._debug_layers.get_parent() == main,
			"a debug build adds the one node, parented under main")
	t.check(not main._debug_layers.layer_on(1) and not main._debug_layers.layer_on(2)
			and not main._debug_layers.layer_on(3),
			"and the three geometry layers start off, so an unflagged debug run looks like today's")
	main._debug_layers.free()
	main._city.free()
	main._player.free()
	main.free()

# ------------------------------------------------------------------ key toggles ---

func _key(code: Key, pressed := true, echo := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	return event

## `_debug_layer_key()` resolved directly, the way `test_burst_capture.gd` already drives
## `_debug_snapshot_action()` — both are pulled out to a pure function of the event for exactly
## this reason, since `main._unhandled_input()` itself reaches `get_viewport()`, which is null on
## the script-only instance this whole suite uses (see this file's own class doc).
func _test_the_layer_keys_resolve_to_their_own_index(t) -> void:
	t.check(MAIN_SCRIPT._debug_layer_key(_key(KEY_1)) == 1, "1 is fields")
	t.check(MAIN_SCRIPT._debug_layer_key(_key(KEY_2)) == 2, "2 is shadows")
	t.check(MAIN_SCRIPT._debug_layer_key(_key(KEY_3)) == 3, "3 is bounding boxes")
	t.check(MAIN_SCRIPT._debug_layer_key(_key(KEY_4)) == 4, "4 is the readout")
	t.check(MAIN_SCRIPT._debug_layer_key(_key(KEY_5)) == 0, "a fifth key answers nothing")
	t.check(MAIN_SCRIPT._debug_layer_key(_key(KEY_1, false)) == 0, "a release, not a press, does nothing")
	t.check(MAIN_SCRIPT._debug_layer_key(_key(KEY_1, true, true)) == 0,
			"an echo does nothing — a held key is one request, not a flood of them")

func _test_number_keys_toggle_their_own_layer(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	main._debug = true
	main._status = Label.new()
	main._city = City.new()
	main._player = Stroller.new()
	main._add_debug_layers()

	t.check(not main._debug_layers.layer_on(1), "fields starts off")
	main._toggle_debug_layer(1)
	t.check(main._debug_layers.layer_on(1), "1 turns fields on")
	main._toggle_debug_layer(1)
	t.check(not main._debug_layers.layer_on(1), "and back off again")

	main._toggle_debug_layer(2)
	main._toggle_debug_layer(3)
	t.check(main._debug_layers.layer_on(2) and main._debug_layers.layer_on(3),
			"2 and 3 toggle shadows and bounding boxes independently of fields")

	t.check(main._layer_readout_on and main._status.visible, "the readout starts on, as today")
	main._toggle_debug_layer(4)
	t.check(not main._layer_readout_on and not main._status.visible,
			"4 turns the readout off and hides the label — not merely leaves it assembled and hidden")
	main._toggle_debug_layer(4)
	t.check(main._layer_readout_on and main._status.visible, "and 4 again turns it back on")

	main._status.free()
	main._debug_layers.free()
	main._city.free()
	main._player.free()
	main.free()

func _test_layer_keys_do_nothing_outside_a_debug_build(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	main._debug = false
	main._status = Label.new()
	main._city = City.new()
	main._player = Stroller.new()
	main._add_debug_layers()
	t.check(main._debug_layers == null, "no layer node in a release build")

	# `main._unhandled_input()` itself never reaches `_toggle_debug_layer()` at all here: the whole
	# branch is behind `if _debug`, so a release build's `_debug_layers` stays null without this
	# suite needing a live viewport to prove it — see `_test_the_layer_keys_resolve_to_their_own_index`
	# for the part of the gate that *is* driven through a real event.
	main._toggle_debug_layer(1)
	t.check(main._debug_layers == null, "and calling the toggle by hand still builds nothing")

	main._status.free()
	main._city.free()
	main._player.free()
	main.free()
