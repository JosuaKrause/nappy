@warning_ignore_start("untyped_declaration")
extends RefCounted
## `DebugLayers` (M104, "the debug view") and the two pieces of it that sit outside that one class:
## `GroundShape.shadow_outline()`, which `draw_shadow()` now draws from directly, and
## `_layers()`, the `--layers`/`?layers=` parsing.
##
## The tree-presence and key-toggle tests build a `DebugReadout` the way `tests/test_main.gd` does
## for the readout — on its own, handed a `RunConfig`, a label and the run's header — because
## `main._ready()` boots a whole city and none of these questions need one. The layers are read by
## the node the readout names and the keys are real events pushed through the viewport; whether a
## layer asks to be redrawn is counted in the draws it gets over real frames.

func run(t: TestRunner) -> void:
	_test_shadow_outline_matches_a_points_ellipse(t)
	_test_shadow_outline_matches_a_segments_hull(t)
	_test_shadow_outline_matches_a_rectangles_squashed_corners(t)
	_test_field_outline_of_a_stationary_point_is_a_circle(t)
	_test_field_outline_of_a_stationary_segment_is_a_stadium(t)
	_test_field_outline_of_a_moving_point_is_the_eccentric_ellipse(t)
	_test_parse_layers_reads_a_comma_list(t)
	_test_parse_layers_drops_malformed_entries_without_crashing(t)
	_test_apply_initial_state_sets_only_the_listed_layers(t)
	_test_no_layer_node_exists_outside_a_debug_build(t)
	_test_the_readout_flag_alone_builds_the_node_with_every_layer_off(t)
	_test_a_debug_build_builds_the_layers_off_by_default(t)
	_test_the_layers_flag_starts_only_the_listed_layers_on(t)
	_test_the_layer_keys_resolve_to_their_own_layer(t)
	_test_a_release_or_an_echo_toggles_nothing(t)
	_test_number_keys_toggle_their_own_layer(t)
	_test_layer_keys_do_nothing_outside_a_debug_build(t)
	await _test_no_redraw_is_asked_with_every_layer_off(t)
	await _test_a_switch_off_still_owes_one_redraw(t)
	_test_collision_nodes_under_finds_the_shape_and_the_polygon_at_every_depth(t)

# ------------------------------------------------------------------ shadow_outline ---

func _bounds(points: PackedVector2Array) -> Rect2:
	var rect := Rect2(points[0], Vector2.ZERO)
	for point in points:
		rect = rect.expand(point)
	return rect

func _test_shadow_outline_matches_a_points_ellipse(t: TestRunner) -> void:
	var shape := GroundShape.point(10.0)
	var bounds := _bounds(shape.shadow_outline(Vector2(40.0, 20.0)))
	t.close_to(bounds.size.x, 20.0, "a point's shadow is as wide as its own diameter", 0.5)
	t.close_to(bounds.size.y, 20.0 * GroundShape.SHADOW_SQUASH,
			"and squashed on Y by SHADOW_SQUASH, the same foreshortening draw_shadow() always drew",
			0.5)
	t.close_to(bounds.get_center().x, 40.0, "centred on the position it was asked to draw at", 0.5)
	t.close_to(bounds.get_center().y, 20.0, "on both axes", 0.5)

func _test_shadow_outline_matches_a_segments_hull(t: TestRunner) -> void:
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

func _test_shadow_outline_matches_a_rectangles_squashed_corners(t: TestRunner) -> void:
	var shape := GroundShape.rect(Vector2(30.0, 10.0))
	var points := shape.shadow_outline(Vector2.ZERO, Vector2.RIGHT)
	t.check(points.size() == 4, "a rectangle's shadow outline is exactly its four corners")
	var bounds := _bounds(points)
	t.close_to(bounds.size.x, 60.0, "unrotated, the outline is as wide as the footprint", 0.5)
	t.close_to(bounds.size.y, 20.0 * GroundShape.SHADOW_SQUASH,
			"and squashed on Y by SHADOW_SQUASH, applied after the rotation", 0.5)

# --------------------------------------------------------------------- field_outline ---
# The fields layer's own geometry — the same `Field.falloff()` prices, so a screenshot of this
# layer cannot disagree with the meter. See docs/TODO.md, M61, "the field, the shadow and the body".

func _test_field_outline_of_a_stationary_point_is_a_circle(t: TestRunner) -> void:
	var shape := GroundShape.point(9.0)
	var points := shape.field_outline(Vector2(20.0, 5.0), Vector2.RIGHT, Vector2.ZERO, 50.0)
	var bounds := _bounds(points)
	t.close_to(bounds.size.x, 100.0, "a stationary point's field boundary is a circle of radius "
			+ "'level' — 50 wide however far its own radius (9) reaches", 1.0)
	t.close_to(bounds.size.y, 100.0, "and the same on the other axis, unsquashed — a field is not a "
			+ "shadow, so no oblique foreshortening applies", 1.0)
	t.close_to(bounds.get_center().x, 20.0, "centred on the emitter itself", 1.0)
	t.close_to(bounds.get_center().y, 5.0, "on both axes", 1.0)

func _test_field_outline_of_a_stationary_segment_is_a_stadium(t: TestRunner) -> void:
	var shape := GroundShape.segment(40.0, 24.0)
	var points := shape.field_outline(Vector2.ZERO, Vector2.RIGHT, Vector2.ZERO, 50.0)
	var bounds := _bounds(points)
	t.close_to(bounds.size.x, 2.0 * (40.0 + 50.0),
			"along the spine, the boundary reaches half_length + level past centre (a stadium, not "
			+ "a circle — the body's own half_length still offsets it)", 1.0)
	t.close_to(bounds.size.y, 2.0 * 50.0,
			"across it, only 'level' — no half_length added, which is the capsule's whole point",
			1.0)

## M114, the moving field grows forward: the drawn boundary holds `level` exactly abeam (theta =
## pi/2, sample `_ELLIPSE_SAMPLES / 4` of `_eccentric_field_outline`'s own even spacing) and reaches
## `level * Field.scale(e)` dead ahead (sample zero), further than `level` rather than equal
## to it — the picture `DebugLayers`' layer `1` draws has to agree with the same growth the meter
## prices.
func _test_field_outline_of_a_moving_point_is_the_eccentric_ellipse(t: TestRunner) -> void:
	var speed := 130.0
	var velocity := Vector2(speed, 0.0)
	var level := 100.0
	var scale := Field.scale(Field.eccentricity(speed))
	var points := GroundShape.field_outline_at(Vector2.ZERO, velocity, level)
	t.check(points.size() > 0, "the moving boundary actually samples some points")
	# Sample zero is theta=0 in `_eccentric_field_outline` — dead ahead, along `velocity` — where
	# the effective distance is `level * Field.scale(e)`, further than a disc's plain `level`.
	t.close_to(points[0].distance_to(Vector2.ZERO), level * scale,
			"the foremost sampled point sits at level * Field.scale(e) (%.1f) from the emitter — "
			% (level * scale) + "forward reach grew past the resting radius", 0.5)
	t.check(points[0].x > 0.0, "and it lies ahead, in the direction of travel")
	# A quarter of the way round the even spacing is theta = pi/2, abeam.
	var abeam_index := points.size() / 4
	t.close_to(points[abeam_index].distance_to(Vector2.ZERO), level,
			"the abeam sampled point sits at exactly 'level' — the resting disc's own width, kept "
			+ "whatever the speed", 0.5)
	var bounds := _bounds(points)
	t.check(bounds.position.x > -level,
			"the boundary's own rear edge sits closer than 'level' behind the emitter — the "
			+ "eccentricity actually pulled the field in")

# ------------------------------------------------------------------ --layers ---

## The layers a debug build given `--layers raw` starts on.
func _layers(raw: String) -> Array[int]:
	return RunConfig.parse(PackedStringArray(["--layers", raw]), "", true).layers_override


func _test_parse_layers_reads_a_comma_list(t: TestRunner) -> void:
	var result := _layers("1,3")
	t.check(result == [1, 3], "the two named layers, in the order given")
	t.check(_layers("") == [], "an empty value asks for nothing")

func _test_parse_layers_drops_malformed_entries_without_crashing(t: TestRunner) -> void:
	t.check(_layers("1,x,2") == [1, 2],
			"a non-numeric entry is dropped, not a crash or an empty result")
	t.check(_layers("1,9,0") == [1],
			"an out-of-range entry (there is no layer 9 or 0 to set) is dropped the same way")
	t.check(_layers("2,2") == [2], "a repeated entry is not added twice")

func _test_apply_initial_state_sets_only_the_listed_layers(t: TestRunner) -> void:
	var layers := DebugLayers.new()
	layers.apply_initial_state([1, 3])
	t.check(layers.layer_on(1) and not layers.layer_on(2) and layers.layer_on(3),
			"only the flagged layers start on")
	layers.apply_initial_state([])
	t.check(not layers.layer_on(1) and not layers.layer_on(2) and not layers.layer_on(3),
			"and an empty list turns every geometry layer back off")
	layers.free()


# ------------------------------------------------------------------ tree presence ---

const UI := preload("res://tests/ui_screens.gd")

## A readout in a tree, set up the way `main` sets it up: handed its configuration, its label and
## layer, the run's header and her, then the world. Everything a check reads is what the readout
## builds (its node `DebugLayers`, its label, `readout_on()`, `graph_on()`) or what a pressed key
## changes in them.
class Rig:
	var readout := DebugReadout.new()
	var label := Label.new()
	var layer := CanvasLayer.new()
	var player := Stroller.new()
	var city := City.new()
	var run := RunState.new()

	func _init(t: TestRunner, config: RunConfig) -> void:
		t.add_child(layer)
		layer.add_child(label)
		readout.setup(config, label, layer, run.header, null, Callable())
		readout.watch(player, null, null)
		t.add_child(readout)
		readout.show_the_world(city.events, city.crowd, city, city.map, city)

	## The layer node the readout built, or null where it built none.
	func layers() -> DebugLayers:
		return readout.get_node_or_null("DebugLayers") as DebugLayers

	func free_all() -> void:
		readout.free()
		layer.free()
		player.free()
		city.free()

func _config(words: Array, debug_build: bool, query := "") -> RunConfig:
	return RunConfig.parse(PackedStringArray(words), query, debug_build)

func _all_off(layers: DebugLayers) -> bool:
	return not layers.layer_on(1) and not layers.layer_on(2) and not layers.layer_on(3)

func _test_no_layer_node_exists_outside_a_debug_build(t: TestRunner) -> void:
	var rig := Rig.new(t, _config([], false))
	t.check(rig.layers() == null,
			"a release build never builds the layer node at all, not merely leaves it invisible")
	rig.free_all()

## M193, "the live page's ?debug=1 reaches the debug flags": `?debug=1` alone (`readout_requested`,
## with no `?layers=` in the same query) builds the node the same way a debug build does, since a
## release page's own `?debug=1&layers=1,3` needs somewhere to draw into — but every geometry layer
## still starts off, exactly as an unflagged debug run's own default, because `layers_override`
## itself is empty without `?layers=` named.
func _test_the_readout_flag_alone_builds_the_node_with_every_layer_off(t: TestRunner) -> void:
	var rig := Rig.new(t, _config([], false, "?debug=1"))
	t.check(rig.layers() != null,
			"?debug=1 builds the layer node so a release page's own ?layers= has somewhere to draw")
	t.check(rig.layers() != null and _all_off(rig.layers()),
			"and every geometry layer starts off, since ?layers= itself named none")
	rig.free_all()

func _test_a_debug_build_builds_the_layers_off_by_default(t: TestRunner) -> void:
	var rig := Rig.new(t, _config([], true))
	var layers := rig.layers()
	t.check(layers != null and layers.get_parent() == rig.readout,
			"a debug build adds the one node, parented under the readout")
	t.check(layers != null and _all_off(layers),
			"and the three geometry layers start off, so an unflagged debug run looks like today's")
	rig.free_all()

## The flag the player types reaches the node: `--layers 1,3` on a debug build starts exactly those
## on.
func _test_the_layers_flag_starts_only_the_listed_layers_on(t: TestRunner) -> void:
	var rig := Rig.new(t, _config(["--layers", "1,3"], true))
	var layers := rig.layers()
	t.check(layers != null and layers.layer_on(1) and not layers.layer_on(2) and layers.layer_on(3),
			"--layers 1,3 starts fields and bounding boxes on and leaves shadows off")
	rig.free_all()

# ------------------------------------------------------------------ key toggles ---

func _key(code: Key, pressed := true, echo := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	return event

## Every key a player presses reaches its own layer through the viewport, the route a real key takes:
## `1` fields, `2` shadows, `3` bounding boxes, `4` the readout, `5` the routes and `6` the frame
## graph, and nothing else is a layer key. Each key is pressed alone from a state with everything
## off, and what it turned on is the one thing that changed.
func _test_the_layer_keys_resolve_to_their_own_layer(t: TestRunner) -> void:
	var rig := Rig.new(t, _config([], true))
	rig.readout.draw_routes(rig.city.map)
	var routes := rig.readout.get_node("RouteLines") as RouteLines
	var layers := rig.layers()
	rig.readout.close_the_title()
	for number in [1, 2, 3]:
		UI.push(rig.readout, _key(KEY_1 + number - 1))
		for other in [1, 2, 3]:
			t.check(layers.layer_on(other) == (other == number),
					"%d turns on layer %d and no other geometry layer" % [number, other])
		UI.push(rig.readout, _key(KEY_1 + number - 1))
	t.check(_all_off(layers), "a second press of each leaves every geometry layer off")
	UI.push(rig.readout, _key(KEY_4))
	t.check(not rig.readout.readout_on(), "4 is the readout")
	UI.push(rig.readout, _key(KEY_5))
	t.check(routes.visible and not rig.readout.graph_on(), "5 is the route lines")
	UI.push(rig.readout, _key(KEY_6))
	t.check(rig.readout.graph_on(), "6 is the frame graph")
	var before := [layers.layer_on(1), layers.layer_on(2), layers.layer_on(3),
			rig.readout.readout_on(), routes.visible, rig.readout.graph_on()]
	UI.push(rig.readout, _key(KEY_7))
	t.check([layers.layer_on(1), layers.layer_on(2), layers.layer_on(3),
			rig.readout.readout_on(), routes.visible, rig.readout.graph_on()] == before,
			"a seventh key answers nothing")
	rig.free_all()

func _test_a_release_or_an_echo_toggles_nothing(t: TestRunner) -> void:
	var rig := Rig.new(t, _config([], true))
	var layers := rig.layers()
	UI.push(rig.readout, _key(KEY_1, false))
	t.check(not layers.layer_on(1), "a release, not a press, does nothing")
	UI.push(rig.readout, _key(KEY_1, true, true))
	t.check(not layers.layer_on(1),
			"an echo does nothing — a held key is one request, not a flood of them")
	UI.push(rig.readout, _key(KEY_1))
	t.check(layers.layer_on(1), "and the press itself still does")
	rig.free_all()

func _test_number_keys_toggle_their_own_layer(t: TestRunner) -> void:
	var rig := Rig.new(t, _config([], true))
	var layers := rig.layers()

	t.check(not layers.layer_on(1), "fields starts off")
	UI.push(rig.readout, _key(KEY_1))
	t.check(layers.layer_on(1), "1 turns fields on")
	UI.push(rig.readout, _key(KEY_1))
	t.check(not layers.layer_on(1), "and back off again")

	UI.push(rig.readout, _key(KEY_2))
	UI.push(rig.readout, _key(KEY_3))
	t.check(layers.layer_on(2) and layers.layer_on(3),
			"2 and 3 toggle shadows and bounding boxes independently of fields")

	t.check(rig.readout.readout_on() and rig.label.visible, "the readout starts on, as today")
	UI.push(rig.readout, _key(KEY_4))
	t.check(not rig.readout.readout_on() and not rig.label.visible,
			"4 turns the readout off and hides the label — not merely leaves it assembled and hidden")
	UI.push(rig.readout, _key(KEY_4))
	t.check(rig.readout.readout_on() and rig.label.visible, "and 4 again turns it back on")
	rig.free_all()

func _test_layer_keys_do_nothing_outside_a_debug_build(t: TestRunner) -> void:
	var rig := Rig.new(t, _config([], false))
	t.check(rig.layers() == null, "no layer node in a release build")
	var readout_before := rig.readout.readout_on()
	for code in [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]:
		UI.push(rig.readout, _key(code))
	t.check(rig.layers() == null and rig.readout.readout_on() == readout_before
			and not rig.readout.graph_on(),
			"and pressing every layer key still builds or turns on nothing")
	rig.free_all()

# ---------------------------------------------------------- the per-frame audit ---
# `docs/TODO.md`, M124: `_process()` used to call `queue_redraw()` unconditionally, even with
# every layer off, and `collision_nodes_under()` allocated a fresh `Array[Node]` at every level of
# recursion rather than accumulating into one the caller already owns.

## The layer node with its picture counted: a retained `_draw()` runs only when a redraw was
## queued, so how often it runs over real frames is how many redraws the layer asked for.
class DrawCount extends DebugLayers:
	var draws := 0

	## Overrides DebugLayers._draw.
	func _draw() -> void:
		draws += 1

func _test_no_redraw_is_asked_with_every_layer_off(t: TestRunner) -> void:
	var layers := DrawCount.new()
	t.add_child(layers)
	await UI.frames(t, 3)
	var settled := layers.draws
	await UI.frames(t, 5)
	t.check(layers.draws == settled,
			"fresh layers start with all three off, so five frames ask for no redraw (%d, then %d)"
			% [settled, layers.draws])
	layers.set_layer(1, true)
	await UI.frames(t, 5)
	t.check(layers.draws >= settled + 5,
			"one layer on redraws every frame (%d draws, %d before)" % [layers.draws, settled])
	layers.free()

	for number in [2, 3]:
		var other := DrawCount.new()
		t.add_child(other)
		await UI.frames(t, 3)
		var other_settled := other.draws
		other.set_layer(number, true)
		await UI.frames(t, 5)
		t.check(other.draws >= other_settled + 5,
				"layer %d alone redraws every frame as well, not only the first" % number)
		other.free()

## M142: a retained `_draw()` keeps its last picture until something calls `queue_redraw()` again,
## so the toggle that turns the last layer off still owes exactly one redraw — the empty one that
## erases what was on screen.
func _test_a_switch_off_still_owes_one_redraw(t: TestRunner) -> void:
	var layers := DrawCount.new()
	t.add_child(layers)
	await UI.frames(t, 3)
	layers.set_layer(2, true)
	await UI.frames(t, 3)
	layers.set_layer(2, false)
	var at_switch_off := layers.draws
	await UI.frames(t, 5)
	t.check(layers.draws == at_switch_off + 1,
			("switching the last layer off still owes one redraw, so the last picture does not "
			+ "stay on screen forever, and only one (%d draws after, %d at the switch)")
			% [layers.draws, at_switch_off])
	layers.free()

func _test_collision_nodes_under_finds_the_shape_and_the_polygon_at_every_depth(t: TestRunner) -> void:
	var root := StaticBody2D.new()
	t.add_child(root)
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	root.add_child(shape)
	var polygon := CollisionPolygon2D.new()
	polygon.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1.0, 0.0), Vector2(0.0, 1.0)])
	root.add_child(polygon)
	var disabled := CollisionShape2D.new()
	disabled.shape = RectangleShape2D.new()
	disabled.disabled = true
	root.add_child(disabled)

	t.check(DebugLayers.collision_nodes_under(root).size() == 2,
			"the walk finds both the enabled shape and the enabled polygon, and not the disabled one")

	var deeper := CharacterBody2D.new()
	var deeper_shape := CollisionShape2D.new()
	deeper_shape.shape = CircleShape2D.new()
	deeper.add_child(deeper_shape)
	var holder := Node2D.new()
	holder.add_child(deeper)
	root.add_child(holder)
	var found := DebugLayers.collision_nodes_under(root)
	t.check(found.size() == 3 and deeper_shape in found,
			"and a body two levels down is found with them")

	root.free()
