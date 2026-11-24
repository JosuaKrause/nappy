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
##
## **The fields layer's cut is asked of a real street musician and of real generated cities, for the
## reason the layer has**: it draws an outline only where the meter would read it, which is the
## city map's wall answer (`CityMap.wall_between()`) laid along an event's own outline, so its cases
## stand a musician (`EventInstance`) on hand-built maps and the layer's cut over the generated
## city's buildings and its walls.

const MapCache := preload("res://tests/city_map_cache.gd")

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
	_test_the_layers_flag_accepts_seven(t)
	_test_the_escapes_second_world_hands_the_event_routes_its_events(t)
	_test_the_layer_keys_resolve_to_their_own_layer(t)
	_test_a_release_or_an_echo_toggles_nothing(t)
	_test_number_keys_toggle_their_own_layer(t)
	_test_layer_keys_do_nothing_outside_a_debug_build(t)
	await _test_no_redraw_is_asked_with_every_layer_off(t)
	await _test_a_switch_off_still_owes_one_redraw(t)
	_test_collision_nodes_under_finds_the_shape_and_the_polygon_at_every_depth(t)
	_test_the_fields_layer_is_cut_where_a_wall_stops_the_field(t)
	_test_the_fields_layer_cuts_a_blocked_line_whole_and_draws_an_open_one(t)
	_test_the_fields_layer_asks_no_wall_where_none_can_block(t)
	_test_the_fields_layer_follows_the_wall_along_the_whole_outline(t)
	_test_the_fields_layer_cuts_a_moved_source_again(t)
	_test_the_fields_layer_never_culls_an_outline_on_screen(t)

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
	return RunConfig.parse(PackedStringArray(["--layers", raw]), "", true).layers_override()


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

func _test_the_layers_flag_accepts_seven(t: TestRunner) -> void:
	t.check(_layers("5,7") == [5, 7], "7 is a layer the flag names, and 8 is not one")
	t.check(_layers("7,8") == [7], "an eighth entry is dropped the way any out-of-range one is")

## A manager that answers the instances it was given, for the hand-over below.
class StandInEvents extends EventManager:
	var live: Array[EventInstance] = []

	## Overrides EventManager.instances.
	func instances() -> Array[EventInstance]:
		return live

## The escape walks out of the service door and `main` calls `show_the_world()` again: the one
## `EventRouteLines` the readout built answers the new world's events, not the building's.
func _test_the_escapes_second_world_hands_the_event_routes_its_events(t: TestRunner) -> void:
	var rig := Rig.new(t, _config([], true))
	var route_a := PackedVector2Array([Vector2.ZERO, Vector2(50.0, 0.0)])
	var route_b := PackedVector2Array([Vector2(10.0, 10.0), Vector2(10.0, 90.0)])
	var building := StandInEvents.new()
	var instance_a := EventInstance.new()
	instance_a.setup(EventCatalogue.by_id("police_patrol"), route_a[0], route_a)
	building.live = [instance_a]
	var city := StandInEvents.new()
	var instance_b := EventInstance.new()
	instance_b.setup(EventCatalogue.by_id("police_patrol"), route_b[0], route_b)
	city.live = [instance_b]
	var event_routes := rig.readout.get_node("EventRouteLines") as EventRouteLines
	rig.readout.show_the_world(building, null, rig.world, Callable(), null, null)
	t.check(event_routes.routes() == [route_a], "the first world's events are the ones drawn")
	rig.readout.show_the_world(city, null, rig.world, Callable(), null, null)
	t.check(rig.readout.get_node("EventRouteLines") == event_routes
			and event_routes.routes() == [route_b],
			"the second world reuses the one node and draws only the new world's events")
	rig.free_all()
	instance_a.free()
	instance_b.free()
	building.free()
	city.free()

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
	var world := Node2D.new()
	var run := RunState.new()

	func _init(t: TestRunner, config: RunConfig) -> void:
		t.add_child(layer)
		layer.add_child(label)
		readout.setup(config, label, layer, run.header(), null, Callable())
		readout.watch(player, null, null)
		t.add_child(readout)
		readout.show_the_world(null, null, world, Callable(), null, null)

	## The layer node the readout built, or null where it built none.
	func layers() -> DebugLayers:
		return readout.get_node_or_null("DebugLayers") as DebugLayers

	func free_all() -> void:
		readout.free()
		layer.free()
		player.free()
		world.free()

func _config(words: Array, debug_build: bool, query := "") -> RunConfig:
	return RunConfig.parse(PackedStringArray(words), query, debug_build)

func _all_off(layers: DebugLayers) -> bool:
	return not layers.layer_on(1) and not layers.layer_on(2) and not layers.layer_on(3)

func _test_no_layer_node_exists_outside_a_debug_build(t: TestRunner) -> void:
	var rig := Rig.new(t, _config([], false))
	t.check(rig.layers() == null,
			"a release build never builds the layer node at all, not merely leaves it invisible")
	rig.free_all()

## M193, "the live page's ?debug=1 reaches the debug flags": `?debug=1` alone
## (`asks_for_the_readout()`, with no `?layers=` in the same query) builds the node the same way
## a debug build does, since a release page's own `?debug=1&layers=1,3` needs somewhere to draw
## into — but every geometry layer still starts off, exactly as an unflagged debug run's own
## default, because `layers_override()` itself is empty without `?layers=` named.
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
## graph, `7` the events' own routes, and nothing else is a layer key. Each key is pressed alone from a state with everything
## off, and what it turned on is the one thing that changed.
func _test_the_layer_keys_resolve_to_their_own_layer(t: TestRunner) -> void:
	var rig := Rig.new(t, _config([], true))
	rig.readout.draw_routes(null)
	var routes := rig.readout.get_node("RouteLines") as RouteLines
	var event_routes := rig.readout.get_node("EventRouteLines") as EventRouteLines
	var layers := rig.layers()
	rig.readout.close_the_title()
	for number: int in [1, 2, 3]:
		UI.push(rig.readout, _key(KEY_1 + number - 1))
		for other: int in [1, 2, 3]:
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
	UI.push(rig.readout, _key(KEY_7))
	t.check(event_routes.visible and routes.visible, "7 is the events' own routes, beside 5")
	UI.push(rig.readout, _key(KEY_7))
	t.check(not event_routes.visible and routes.visible, "and a second 7 turns only them off")
	var before := [layers.layer_on(1), layers.layer_on(2), layers.layer_on(3),
			rig.readout.readout_on(), routes.visible, event_routes.visible,
			rig.readout.graph_on()]
	UI.push(rig.readout, _key(KEY_8))
	t.check([layers.layer_on(1), layers.layer_on(2), layers.layer_on(3),
			rig.readout.readout_on(), routes.visible, event_routes.visible,
			rig.readout.graph_on()] == before, "an eighth key answers nothing")
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
	for code: Key in [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7]:
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

	for number: int in [2, 3]:
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

# ----------------------------------------------------------------- the fields layer's cut ---

## A `width`×`height` map of sidewalk with the given tiles built on.
func _map_with(buildings: Array[Vector2i], width := 12, height := 12) -> CityMap:
	var map := CityMap.new(Vector2i(width, height))
	map.fill_rect(Rect2i(0, 0, width, height), GameEnums.TileType.SIDEWALK)
	for tile in buildings:
		map.set_tile(tile, GameEnums.TileType.BUILDING)
	return map

func _rect_tiles(rect: Rect2i) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			found.append(Vector2i(x, y))
	return found

## A row's instance standing at `at` past its telegraph, asking `map` about the ground — handed to
## `setup()` as the spawner hands it the world's, so both copies stand exactly where they were put.
func _musician(def: EventDef, at: Vector2, map: CityMap) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at, PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().on(map))
	instance.restore(EventSave.aged(def.telegraphs_for() + 1.0))
	return instance

## The debug view's fields layer draws an outline only where the meter would read it: a musician
## beside a building two tiles thick has the part of his outline past the building's middle cut
## away, every point left on it is one his field reaches by his own wall answer, every open corner of
## the outline is still drawn, each cut ends within a pixel of where that answer turns, and on open
## ground the same outline is the whole closed loop.
func _test_the_fields_layer_is_cut_where_a_wall_stops_the_field(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("busker")
	# A map wide enough that the outline stays on it: ground off the map counts as building.
	var at := Vector2(304.0, 384.0)
	var behind := _musician(def, at, _map_with(_rect_tiles(Rect2i(11, 0, 2, 24)), 24, 24))
	var beside := _musician(def, at, _map_with([], 24, 24))
	var outline := GroundShape.field_outline_at(at, Vector2.ZERO, def.heard_within())
	var whole := DebugLayers.open_runs(outline, at, beside.source().wall_grid())
	t.check(whole.size() == 1 and whole[0].size() == outline.size() + 1
			and whole[0][0] == whole[0][whole[0].size() - 1],
			"on open ground the outline is drawn whole, closed")
	var runs := DebugLayers.open_runs(outline, at, behind.source().wall_grid())
	var kept := 0
	for point in outline:
		if not behind.source().wall_grid().wall_between(at, point):
			kept += 1
	t.check(kept > 0 and kept < outline.size(),
			"the musician's outline runs both sides of the building (%d of %d points open)"
			% [kept, outline.size()])
	var corners := 0
	for run in runs:
		for point in run:
			if outline.has(point):
				corners += 1
	var through := 0
	var loose := 0
	for run in runs:
		for i in run.size() - 1:
			for step in 5:
				if behind.source().wall_grid().wall_between(at, run[i].lerp(run[i + 1], float(step) / 4.0)):
					through += 1
		var past_end := run[run.size() - 1] \
				+ (run[run.size() - 1] - run[run.size() - 2]).normalized()
		var past_start := run[0] + (run[0] - run[1]).normalized()
		var grid := behind.source().wall_grid()
		if not grid.wall_between(at, past_end) or not grid.wall_between(at, past_start):
			loose += 1
	t.check(runs.size() == 1, "behind one building it is one open stretch (%d)" % runs.size())
	t.check(corners == kept, "carrying every open corner of the outline (%d of %d)" % [corners, kept])
	t.check(through == 0, "nothing drawn is behind the wall (%d samples were)" % through)
	t.check(loose == 0, "and each cut stops within a pixel of the wall's answer turning")
	behind.free()
	beside.free()

## `DebugLayers.open_runs()` cuts an outline from a source by the grid's walls, and a line a wall blocks
## must leave nothing of the outline open. Asked of seeded lines from open ground, up to the widest
## field's reach, on a real city and on hand-built maps of scattered buildings, where one-tile walls,
## bends and corners open only diagonally are common: the outline is the one point the line ends at,
## so a blocked line leaves no run and an open one exactly one. The guards count both that some were
## blocked and that some were open.
func _test_the_fields_layer_cuts_a_blocked_line_whole_and_draws_an_open_one(t: TestRunner) -> void:
	var maps: Array[CityMap] = [MapCache.of(4242)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1004
	for i in 6:
		var scattered: Array[Vector2i] = []
		for tile in _rect_tiles(Rect2i(0, 0, 16, 16)):
			if rng.randf() < 0.45:
				scattered.append(tile)
		maps.append(_map_with(scattered, 16, 16))
	for map in maps:
		var open: Array[Vector2i] = []
		for tile in _rect_tiles(Rect2i(Vector2i.ZERO, map.size)):
			if map.is_walkable(tile):
				open.append(tile)
		var reach := 260.0 if map.size.x > 16 else 120.0
		var blocked := 0
		var open_lines := 0
		var missed := 0
		for i in 1500:
			var from := map.tile_to_world(open[rng.randi_range(0, open.size() - 1)]) \
					+ Vector2(rng.randf_range(-15.0, 15.0), rng.randf_range(-15.0, 15.0))
			var to := from + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10.0, reach)
			# The line as the layer is asked it: the outline is the one point `to`, cut from `from`.
			# A line a wall blocks leaves nothing of it open; a skip taken for it draws the point.
			var runs := DebugLayers.open_runs(PackedVector2Array([to, to]), from, map)
			if map.wall_between(from, to):
				blocked += 1
				if not runs.is_empty():
					missed += 1
			else:
				open_lines += 1
				if runs.size() != 1:
					missed += 1
		t.check(blocked > 50 and open_lines > 20 and missed == 0,
				"on a %dx%d map a line a wall blocks is cut away whole and one it does not is drawn (%d of %d blocked, %d open, %d wrong)"
				% [map.size.x, map.size.y, blocked, blocked + open_lines, open_lines, missed])

## **The layer asks the grid nothing where no wall can block**: a source on open ground, or a building
## too far from the outline to wall a line, costs no wall question, which is what keeps most of a
## day's outlines cheap. The grid is handed to `open_runs()` as the game hands it (the emitter's
## `wall_grid()`), one that counts the questions it is asked; beside a thick building the same
## outline does ask, so the count is not zero for want of looking.
func _test_the_fields_layer_asks_no_wall_where_none_can_block(t: TestRunner) -> void:
	var source := Vector2(304.0, 384.0)
	var outline := GroundShape.field_outline_at(source, Vector2.ZERO, 90.0)
	var open := _CountingMap.of(_map_with([], 24, 24))
	DebugLayers.open_runs(outline, source, open)
	t.check(open.asked == 0, "on open ground the outline is cut with no wall question (%d)" % open.asked)
	var far := _CountingMap.of(_map_with(_rect_tiles(Rect2i(21, 0, 2, 24)), 24, 24))
	DebugLayers.open_runs(outline, source, far)
	t.check(far.asked == 0,
			"nor with a building too far away to reach a line of it (%d)" % far.asked)
	var near := _CountingMap.of(_map_with(_rect_tiles(Rect2i(11, 0, 2, 24)), 24, 24))
	DebugLayers.open_runs(outline, source, near)
	t.check(near.asked > 0, "while beside a thick building the same outline asks (%d)" % near.asked)

## A map that counts the wall questions it is asked.
class _CountingMap extends CityMap:
	var asked := 0

	static func of(map: CityMap) -> _CountingMap:
		var counting := _CountingMap.new(map.size)
		counting.fill_rect(Rect2i(Vector2i.ZERO, map.size), GameEnums.TileType.SIDEWALK)
		for y in map.size.y:
			for x in map.size.x:
				if not map.is_walkable(Vector2i(x, y)):
					counting.set_tile(Vector2i(x, y), GameEnums.TileType.BUILDING)
		return counting

	## Overrides WorldMap.wall_between.
	func wall_between(from: Vector2, to: Vector2, depth := Tuning.WALL_SHIELD_DEPTH,
			thin_depth := Tuning.THIN_WALL_SHIELD_DEPTH) -> bool:
		asked += 1
		return super(from, to, depth, thin_depth)

## **The whole outline, not only its corners.** A wall can fall between two corners of an outline —
## the widest rows' outlines have edges of a hundred pixels and more — so on a real city, at the
## radii of the busiest and the widest fields, every outline is walked a pixel at a time and each
## point is asked against `wall_between()` from the source. What the layer draws through a wall, and
## what it leaves out where the field reaches, are each never longer than `_MISDRAWN_AT_MOST`, a
## third of a tile — stated here rather than read off the layer's own piece length, so a layer that
## asked in longer pieces fails it. The guard counts outlines a wall actually cut, so a sweep that met
## no buildings cannot pass.
const _MISDRAWN_AT_MOST := 10.0

func _test_the_fields_layer_follows_the_wall_along_the_whole_outline(t: TestRunner) -> void:
	var map := MapCache.of(4242)
	var walkable := map.tiles_of_type(GameEnums.TileType.SIDEWALK)
	var rng := RandomNumberGenerator.new()
	rng.seed = 642
	var allowed := _MISDRAWN_AT_MOST
	for radius: float in [120.0, 260.0, 340.0]:
		var cut := 0
		var worst_through := 0.0
		var worst_missing := 0.0
		for n in 60:
			var source := map.tile_to_world(walkable[rng.randi_range(0, walkable.size() - 1)])
			var outline := GroundShape.field_outline_at(source, Vector2.ZERO, radius)
			var runs := DebugLayers.open_runs(outline, source, map)
			var buckets := _run_buckets(runs)
			var through := 0.0
			var missing := 0.0
			var walled_any := false
			for i in outline.size():
				var from := outline[i]
				var to := outline[(i + 1) % outline.size()]
				var steps := ceili(from.distance_to(to))
				var step := from.distance_to(to) / float(steps)
				for k in steps:
					var at := from.lerp(to, float(k) / float(steps))
					var walled := map.wall_between(source, at)
					var drawn := _on_a_run(buckets, at)
					walled_any = walled_any or walled
					through = through + step if walled and drawn else 0.0
					missing = missing + step if not walled and not drawn else 0.0
					worst_through = maxf(worst_through, through)
					worst_missing = maxf(worst_missing, missing)
			if walled_any:
				cut += 1
		t.check(cut > 5, "at %.0fpx walls cut some of the outlines (%d of 60)" % [radius, cut])
		t.check(worst_through <= allowed,
				"and nothing drawn runs through a wall further than a third of a tile (%.1fpx at most)"
				% worst_through)
		t.check(worst_missing <= allowed,
				"nor is an open stretch left out for longer (%.1fpx at most)" % worst_missing)

## Every segment of every run, by the 16px cell each of its points every 4px falls in, so a point
## can ask only the segments near it whether it is on one.
func _run_buckets(runs: Array[PackedVector2Array]) -> Dictionary:
	var buckets := {}
	for run in runs:
		for i in run.size() - 1:
			var segment := [run[i], run[i + 1]]
			var steps := maxi(1, ceili(run[i].distance_to(run[i + 1]) / 4.0))
			for k in steps + 1:
				var cell := Vector2i((run[i].lerp(run[i + 1], float(k) / float(steps)) / 16.0).floor())
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var key := cell + Vector2i(dx, dy)
						if not buckets.has(key):
							buckets[key] = []
						var bucket: Array = buckets[key]
						bucket.append(segment)
	return buckets

func _on_a_run(buckets: Dictionary, at: Vector2) -> bool:
	for segment: Array in buckets.get(Vector2i((at / 16.0).floor()), []):
		var a: Vector2 = segment[0]
		var b: Vector2 = segment[1]
		if Geometry2D.get_closest_point_to_segment(at, a, b).distance_to(at) < 0.3:
			return true
	return false

## Event source for the layer's own loop: the instances it is handed, under the name it reads.
class _Source extends FakeEventManager:
	var live: Array[EventInstance] = []

	## Overrides FakeEventManager.instances.
	func instances() -> Array[EventInstance]:
		return live

## **A source that moves is cut again where it now stands.** The layer keeps last frame's cut while
## an outline is unchanged; a musician moved a tile closer to the building between two frames has an
## outline the building cuts differently, and the second frame draws that cut, not the first.
func _test_the_fields_layer_cuts_a_moved_source_again(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("busker")
	var map := _map_with(_rect_tiles(Rect2i(11, 0, 2, 24)), 24, 24)
	var musician := _musician(def, Vector2(272.0, 384.0), map)
	var source := _Source.new()
	source.live.append(musician)
	var layers := DebugLayers.new()
	layers.setup(source, null, null, Callable(), null)
	var everywhere := Rect2(-1e5, -1e5, 2e5, 2e5)
	var first: Array = layers.field_runs(everywhere)
	var again: Array = layers.field_runs(everywhere)
	t.check(first.size() == 2 and str(again) == str(first),
			"standing still, the musician's two outlines are cut the same way twice")
	musician.position = Vector2(320.0, 384.0)
	var moved: Array = layers.field_runs(everywhere)
	var expected: Array = []
	for level: float in [def.core_within(), def.heard_within()]:
		expected.append(DebugLayers.open_runs(def.ground_shape().field_outline(musician.position,
				musician.solid_axis(), Vector2.ZERO, level) if def.ground_shape() != null
				else GroundShape.field_outline_at(musician.position, Vector2.ZERO, level),
				musician.position, map))
	t.check(moved.size() == 2 and str(moved[1][0]) != str(first[1][0]),
			"moved a tile and a half nearer the building, its outer outline is cut anew")
	t.check(moved.size() == 2 and str(moved[0][0]) == str(expected[0])
			and str(moved[1][0]) == str(expected[1]),
			"exactly as a fresh cut where it now stands")
	layers.free()
	source.free()
	musician.free()

## An emitter of a chosen shape, level and velocity, standing where it is put: what the layer asks
## an event instance (`travel_velocity()`, `field_shape()`, `solid_axis()`), answered with what the
## test chose, so a speed no event row reaches can be handed to the layer. Moved by `position`.
class _Emitter extends EventInstance:
	var chosen_shape: GroundShape
	var chosen_axis := Vector2.RIGHT
	var chosen_velocity := Vector2.ZERO
	## Overrides EventInstance.travel_velocity.
	func travel_velocity() -> Vector2:
		return chosen_velocity
	## Overrides EventInstance.field_shape.
	func field_shape() -> GroundShape:
		return chosen_shape
	## Overrides EventInstance.solid_axis.
	func solid_axis() -> Vector2:
		return chosen_axis

## **No outline that reaches the screen is culled.** The layer decides from the emitter's own point
## and the level, before it builds the outline; over seeded emitters handed to the layer as its
## events — standing points and stadiums, and moving ones at every speed up to past the eccentricity
## cap, which no event row reaches — and a screen-sized view round the origin, every outline whose
## own bounds (computed here over the outline) meet the view comes back from `field_runs()`, and
## nothing that does not. One emitter is on the ground at a time, so each call answers for it alone.
## The guards count both kinds, so the sweep is not vacuous.
func _test_the_fields_layer_never_culls_an_outline_on_screen(t: TestRunner) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6420
	var busker := EventCatalogue.by_id("busker")
	var source := _Source.new()
	var layers := DebugLayers.new()
	layers.setup(source, null, null, Callable(), null)
	var view := Rect2(Vector2(-320.0, -180.0), Vector2(640.0, 360.0))
	var seen := 0
	var unseen := 0
	var culled_on_screen := 0
	var drawn_off_screen := 0
	for i in 4000:
		var spine := rng.randf_range(0.0, 60.0) if rng.randf() < 0.5 else 0.0
		var shape := GroundShape.segment(spine, 6.0) if spine > 0.0 else GroundShape.point(6.0)
		var axis := Vector2.from_angle(rng.randf() * TAU)
		var velocity := Vector2.ZERO if rng.randf() < 0.4 \
				else Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(1.0, 600.0)
		var at := Vector2(rng.randf_range(-1500.0, 1500.0), rng.randf_range(-1500.0, 1500.0))
		var inner := rng.randf_range(10.0, 200.0)
		# A row is never changed, so each field width is a row of its own on its own emitter.
		var widening := busker.redraft()
		widening.field(busker.field().holding_to(inner).reaching(inner + rng.randf_range(0.0, 320.0)))
		var def := widening.build()
		var emitter := _Emitter.new()
		emitter.setup(def, Vector2.ZERO)
		emitter.chosen_shape = shape
		emitter.chosen_axis = axis
		emitter.chosen_velocity = velocity
		emitter.position = at
		source.live.clear()
		source.live.append(emitter)
		var on_screen := 0
		for level: float in [def.core_within(), def.heard_within()]:
			var outline := emitter.chosen_shape.field_outline(emitter.position,
					emitter.chosen_axis, emitter.chosen_velocity, level)
			var bounds := Rect2(outline[0], Vector2.ZERO)
			for point in outline:
				bounds = bounds.expand(point)
			if view.intersects(bounds):
				on_screen += 1
		var drawn: Array = layers.field_runs(view)
		if on_screen > 0:
			seen += 1
		else:
			unseen += 1
		if drawn.size() < on_screen:
			culled_on_screen += 1
		elif drawn.size() > on_screen:
			drawn_off_screen += 1
		emitter.free()
	t.check(seen > 200 and unseen > 200,
			"the sweep met outlines on screen (%d emitters) and off it (%d)" % [seen, unseen])
	t.check(culled_on_screen == 0, "and culled none that reach the screen (%d emitters lost one)"
			% culled_on_screen)
	t.check(drawn_off_screen == 0, "and drew none that does not (%d emitters drew one)"
			% drawn_off_screen)
	layers.free()
	source.free()
