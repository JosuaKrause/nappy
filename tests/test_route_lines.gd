extends RefCounted
## `RouteLines` (M135, "the day's routes drawn as a debug layer") and the `--layers`/`?layers=`
## parsing that reaches its own key, `5`.
##
## The tree-presence and key-toggle tests build `main` the way `tests/test_debug_layers.gd` and
## `tests/test_main.gd` already do — a script-only instance, `_ready()` never run, its handful of
## dependencies wired up by hand — because `main._ready()` boots a whole city and none of these
## questions need one.

const MAIN_SCRIPT: GDScript = preload("res://src/main.gd")

const SEEDS := 6
const BASE_SEED := 5300
const DAYS := [1, 5, 9, 14]

func run(t) -> void:
	_test_parse_layers_accepts_five_and_still_rejects_four(t)
	_test_no_route_lines_node_exists_outside_a_debug_build(t)
	_test_a_debug_build_builds_the_node_off_by_default(t)
	_test_key_five_resolves_to_the_route_lines_layer(t)
	_test_key_five_toggles_visibility(t)
	_test_a_planned_day_yields_one_polyline_per_route_from_doorstep_to_calm(t)

# ------------------------------------------------------------------ DevFlags.parse_layers ---

## Beside `test_debug_layers.gd`'s own `_test_parse_layers_*` cases, which stop at `1..3`: `5` is
## the one other layer `--layers`/`?layers=` may set, and `4` (the readout, toggled its own way)
## stays rejected even though it now sits inside the numeric range the other four span.
func _test_parse_layers_accepts_five_and_still_rejects_four(t) -> void:
	t.check(DevFlags.parse_layers("5") == [5], "5 (the day's routes) is accepted on its own")
	t.check(DevFlags.parse_layers("1,4,5") == [1, 5],
			"4 is still dropped — the readout is never set through this flag — while 1 and 5 pass")
	t.check(DevFlags.parse_layers("1,9,0") == [1],
			"still-invalid entries (there is no layer 9 or 0) are dropped the same way as before")

# ------------------------------------------------------------------ tree presence ---

func _test_no_route_lines_node_exists_outside_a_debug_build(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	main._debug = false
	main._city = City.new()
	main._add_route_lines()
	t.check(main._route_lines == null,
			"a release build never builds the route-lines node, not merely leaves it invisible")
	main._city.free()
	main.free()

func _test_a_debug_build_builds_the_node_off_by_default(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	main._debug = true
	main._city = City.new()
	main._add_route_lines()
	t.check(main._route_lines != null and main._route_lines.get_parent() == main,
			"a debug build adds the one node, parented under main")
	t.check(not main._route_lines.visible,
			"and it starts off, so an unflagged debug run looks like today's")
	main._route_lines.free()
	main._city.free()
	main.free()

# ------------------------------------------------------------------ key toggle ---

func _key(code: Key, pressed := true, echo := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	return event

func _test_key_five_resolves_to_the_route_lines_layer(t) -> void:
	t.check(MAIN_SCRIPT._debug_layer_key(_key(KEY_5)) == 5, "5 is the day's routes")
	t.check(MAIN_SCRIPT._debug_layer_key(_key(KEY_5, false)) == 0, "a release, not a press, does nothing")
	t.check(MAIN_SCRIPT._debug_layer_key(_key(KEY_5, true, true)) == 0,
			"an echo does nothing — a held key is one request, not a flood of them")

func _test_key_five_toggles_visibility(t) -> void:
	var main: Node2D = MAIN_SCRIPT.new()
	main._debug = true
	main._city = City.new()
	main._add_route_lines()

	t.check(not main._route_lines.visible, "the layer starts off")
	main._toggle_debug_layer(5)
	t.check(main._route_lines.visible, "5 turns it on")
	main._toggle_debug_layer(5)
	t.check(not main._route_lines.visible, "and back off again")

	main._route_lines.free()
	main._city.free()
	main.free()

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

## The four invariants the milestone's own `TODO.md` entry states: one polyline per route; the
## first point is the doorstep tile's own centre; the last is a calm tile's own centre; and every
## consecutive pair is one step apart — a reachability-cell step (`ReachabilityGrid.CELL` = 2
## tiles) for the interior of a route, since that is the grain `RouteTree` actually stores it in
## (see `RouteLines`'s own class doc), and a fixed, provably exact distance for the one calm-side
## connector this class adds beyond the tree — **except the doorstep connector**, which the class
## doc explains is not one step at all: a route can rejoin the home street anywhere along its own
## frontage, not necessarily beside the fixed tile every day starts on. It is two axis-aligned
## legs through a corner (index 1), so the check on it is that each leg is axis-aligned — never a
## diagonal across a carriageway.
func _test_a_planned_day_yields_one_polyline_per_route_from_doorstep_to_calm(t) -> void:
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
			var doorstep := built.map.tile_to_world(
					built.map.world_to_tile(built.map.doorstep_world_position()))
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
				t.close_to(route[0].distance_to(doorstep), 0.0,
						"seed %d day %d: the first point is the doorstep tile's own centre"
						% [built.map.seed_used, day], 0.5)
				var last_tile := built.map.world_to_tile(route[route.size() - 1])
				t.check(Tile.is_calm(built.map.tile_at(last_tile)),
						"seed %d day %d: the last point sits on a calm tile" % [built.map.seed_used, day])
				# The doorstep connector's two legs (0->1->2) are each axis-aligned: a corner that
				# shares x or y with the doorstep, and x or y with the first cell.
				if route.size() >= 3:
					var corner := route[1]
					t.check(is_equal_approx(corner.x, route[0].x) or is_equal_approx(corner.y, route[0].y),
							"seed %d day %d: the connector's first leg is axis-aligned" % [built.map.seed_used, day])
					t.check(is_equal_approx(corner.x, route[2].x) or is_equal_approx(corner.y, route[2].y),
							"seed %d day %d: and so is its second leg" % [built.map.seed_used, day])
				# Interior cell-to-cell steps, skipping the doorstep connector (indices 0->1->2, checked
				# above) and the calm connector (the last pair, checked on its own fixed distance below).
				for i2 in range(2, route.size() - 2):
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
