extends RefCounted
## `RouteLines` (M135, "the day's routes drawn as a debug layer") and the `--layers`/`?layers=`
## parsing that reaches its own key, `5`.
##
## The tree-presence and key-toggle tests build a `DebugReadout` the way `tests/test_debug_layers.gd`
## does — in a tree, handed the `RunConfig` that `RunConfig.parse()` makes from the words a player
## types, its label and layer, and the run's header — because `main._ready()` boots a whole city and
## none of these questions need one. What the readout built is read as the node `RouteLines` under
## it, whether the engine would draw it (`is_visible_in_tree()`), and the keys are real events pushed
## through the viewport.

const SEEDS := 6
const BASE_SEED := 5300
const DAYS := [1, 5, 9, 14]

const UI := preload("res://tests/ui_screens.gd")

func run(t) -> void:
	_test_parse_layers_accepts_five_and_still_rejects_four(t)
	_test_no_route_lines_node_exists_outside_a_debug_build(t)
	_test_the_readout_flag_alone_builds_the_node_off(t)
	_test_a_debug_build_builds_the_node_off_by_default(t)
	_test_the_layers_flag_starts_the_node_on(t)
	_test_key_five_is_the_route_lines_layer(t)
	_test_key_five_toggles_visibility(t)
	_test_key_five_does_nothing_in_a_release_build(t)
	_test_a_planned_day_yields_one_polyline_per_route_from_its_first_cell_to_calm(t)

# ------------------------------------------------------------------ --layers ---

## The layers a debug build given `--layers raw` starts on.
func _layers(raw: String) -> Array[int]:
	return RunConfig.parse(PackedStringArray(["--layers", raw]), "", true).layers_override


## Beside `test_debug_layers.gd`'s own `_test_parse_layers_*` cases, which stop at `1..3`: `5` is
## the one other layer `--layers`/`?layers=` may set, and `4` (the readout, toggled its own way)
## stays rejected even though it now sits inside the numeric range the other four span.
func _test_parse_layers_accepts_five_and_still_rejects_four(t) -> void:
	t.check(_layers("5") == [5], "5 (the day's routes) is accepted on its own")
	t.check(_layers("1,4,5") == [1, 5],
			"4 is still dropped — the readout is never set through this flag — while 1 and 5 pass")

# ------------------------------------------------------------------ the readout ---

## A readout in a tree, set up the way `main` sets it up: handed its configuration, its label and
## layer and the run's header, then asked to draw the routes over a map. What a check reads is the
## node the readout built (`routes()`, null where it built none) and what a pressed key changes in it.
class Rig:
	var readout := DebugReadout.new()
	var label := Label.new()
	var layer := CanvasLayer.new()
	var city := City.new()
	var run := RunState.new()

	func _init(t, config: RunConfig) -> void:
		t.add_child(layer)
		layer.add_child(label)
		readout.setup(config, label, layer, run.header, null, Callable())
		t.add_child(readout)
		readout.draw_routes(city.map)

	## The layer node the readout built under itself, or null where it built none.
	func routes() -> RouteLines:
		return readout.get_node_or_null("RouteLines") as RouteLines

	func free_all() -> void:
		readout.free()
		layer.free()
		city.free()

func _config(words: Array, debug_build: bool, query := "") -> RunConfig:
	return RunConfig.parse(PackedStringArray(words), query, debug_build)

func _test_no_route_lines_node_exists_outside_a_debug_build(t) -> void:
	var rig := Rig.new(t, _config([], false))
	t.check(rig.routes() == null,
			"a release build never builds the route-lines node, not merely leaves it invisible")
	rig.free_all()

## M193, "the live page's ?debug=1 reaches the debug flags": `?debug=1` alone builds the node —
## the same shape `test_debug_layers.gd`'s own readout-flag-alone case pins — since a release
## page's own `?debug=1&layers=5` needs somewhere to draw into, still off until `?layers=` names it.
func _test_the_readout_flag_alone_builds_the_node_off(t) -> void:
	var rig := Rig.new(t, _config([], false, "?debug=1"))
	t.check(rig.routes() != null,
			"?debug=1 builds the route-lines node so a release page's own ?layers=5 has somewhere "
			+ "to draw")
	t.check(rig.routes() != null and not rig.routes().visible,
			"and it starts off, since ?layers= itself named none")
	rig.free_all()

func _test_a_debug_build_builds_the_node_off_by_default(t) -> void:
	var rig := Rig.new(t, _config([], true))
	t.check(rig.routes() != null and rig.routes().get_parent() == rig.readout,
			"a debug build adds the one node, parented under the readout")
	t.check(rig.routes() != null and not rig.routes().visible,
			"and it starts off, so an unflagged debug run looks like today's")
	rig.free_all()

## `--layers 5` is the keypress-free request for the layer: the node starts on, drawn in the tree.
func _test_the_layers_flag_starts_the_node_on(t) -> void:
	var rig := Rig.new(t, _config(["--layers", "5"], true))
	t.check(rig.routes() != null and rig.routes().is_visible_in_tree(),
			"--layers 5 starts the route lines on")
	rig.free_all()
	var other := Rig.new(t, _config(["--layers", "1,3"], true))
	t.check(other.routes() != null and not other.routes().visible,
			"and --layers naming other layers leaves them off")
	other.free_all()

# ------------------------------------------------------------------ key toggle ---

func _key(code: Key, pressed := true, echo := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	return event

## A press of `5` turns the layer on; a release, an echo (a held key is one request, not a flood of
## them) and every other digit that is not a layer of this node leave it as it is.
func _test_key_five_is_the_route_lines_layer(t) -> void:
	var rig := Rig.new(t, _config([], true))
	var routes := rig.routes()
	UI.push(rig.readout, _key(KEY_5, false))
	t.check(not routes.visible, "a release, not a press, does nothing")
	UI.push(rig.readout, _key(KEY_5, true, true))
	t.check(not routes.visible,
			"an echo does nothing — a held key is one request, not a flood of them")
	for code in [KEY_1, KEY_2, KEY_3, KEY_4, KEY_6, KEY_7]:
		UI.push(rig.readout, _key(code))
		t.check(not routes.visible, "key %s is not the day's routes" % OS.get_keycode_string(code))
	UI.push(rig.readout, _key(KEY_5))
	t.check(routes.is_visible_in_tree(), "5 is the day's routes")
	rig.free_all()

func _test_key_five_toggles_visibility(t) -> void:
	var rig := Rig.new(t, _config([], true))
	var routes := rig.routes()
	t.check(not routes.visible, "the layer starts off")
	UI.push(rig.readout, _key(KEY_5))
	t.check(routes.is_visible_in_tree(), "5 turns it on")
	UI.push(rig.readout, _key(KEY_5))
	t.check(not routes.visible, "and back off again")
	rig.free_all()

## The number keys answer a debug build alone: a release page can ask for the picture, never
## toggle it by hand.
func _test_key_five_does_nothing_in_a_release_build(t) -> void:
	var rig := Rig.new(t, _config([], false, "?debug=1"))
	var routes := rig.routes()
	UI.push(rig.readout, _key(KEY_5))
	t.check(not routes.visible, "5 on a release page with ?debug=1 does not toggle the routes on")
	rig.free_all()

# ------------------------------------------------------------------ the picture ---

## One planned day's tree, and the `RouteLines` node built from it against the same map.
class _Built extends RefCounted:
	var map: CityMap
	var tree: RouteTree
	var lines: RouteLines

func _plan(seed: int, day: int) -> _Built:
	var built := _Built.new()
	built.map = CityGenerator.generate(seed)
	var state := CityState.new()
	state.begin_day(built.map.block_plans, day)
	built.map.repaint(state)
	built.tree = RouteTree.for_day(built.map, day)
	built.lines = RouteLines.new()
	built.lines.setup(built.map)
	built.lines.refresh(built.tree)
	return built

## The invariants: one polyline per route; the first point is the route's own first cell's centre
## (the doorstep is not on the tree, so nothing is drawn before it — see `RouteLines`'s own class
## doc); the last is a calm tile's own centre; and every consecutive pair is one step apart — a
## reachability-cell step (`ReachabilityGrid.CELL` = 2 tiles) for the interior, since that is the
## grain `RouteTree` stores it in, and a fixed, provably exact distance for the one calm-side
## connector this class adds beyond the tree.
func _test_a_planned_day_yields_one_polyline_per_route_from_its_first_cell_to_calm(t) -> void:
	var cell_step := float(ReachabilityGrid.CELL) * Tuning.TILE_SIZE
	# The exact distance from a two-tile cell's own centre to the centre of a tile one 4-neighbour
	# step beyond one of its four corners: (0.5, 0.5) - corner - delta, and only the two deltas
	# that actually leave the cell (its other two stay inside the same cell and are never a real
	# neighbour) ever pass the "inside the area" check — both give the same (1.5, 0.5) tile
	# offset by symmetry, so this is a single fixed number rather than a bound.
	var calm_step := sqrt(1.5 * 1.5 + 0.5 * 0.5) * Tuning.TILE_SIZE
	var routes_checked := 0
	var days_with_routes := 0
	for i in SEEDS:
		for day in DAYS:
			var built := _plan(BASE_SEED + i * 31, day)
			var expected_routes := 0
			for branch in built.tree.branches:
				expected_routes += branch.routes.size()
			var drawn := built.lines.routes()
			t.check(drawn.size() == expected_routes,
					"seed %d day %d: one polyline per route (%d), not %d"
					% [built.map.seed_used, day, expected_routes, drawn.size()])
			if expected_routes > 0:
				days_with_routes += 1
			for route in drawn:
				routes_checked += 1
				t.check(route.size() >= 2, "seed %d day %d: a drawn route has at least two points"
						% [built.map.seed_used, day])
				t.check(route[0] == route[0].snapped(Vector2.ONE * Tuning.TILE_SIZE),
						"seed %d day %d: the first point is a cell's own centre (a whole-tile corner "
						% [built.map.seed_used, day] + "of a two-tile cell), not the doorstep tile")
				var last_tile := built.map.world_to_tile(route[route.size() - 1])
				t.check(Tile.is_calm(built.map.tile_at(last_tile)),
						"seed %d day %d: the last point sits on a calm tile" % [built.map.seed_used, day])
				# Interior cell-to-cell steps from the very first point, and the calm connector (the
				# last pair, checked on its own fixed distance below).
				for i2 in range(0, route.size() - 2):
					t.close_to(route[i2].distance_to(route[i2 + 1]), cell_step,
							"seed %d day %d: consecutive route cells are one reachability-cell step "
							% [built.map.seed_used, day] + "(%.0fpx) apart" % cell_step, 0.5)
				if route.size() >= 3:
					var last_two_distance := route[route.size() - 2].distance_to(route[route.size() - 1])
					t.close_to(last_two_distance, calm_step,
							"seed %d day %d: the calm connector is exactly one cell-to-tile step "
							% [built.map.seed_used, day] + "(%.1fpx)" % calm_step, 0.5)
			built.lines.free()
	t.check(routes_checked > 0, "the sweep actually built some routes to check")
	t.check(days_with_routes > 0, "and at least one planned day had a route on it")
