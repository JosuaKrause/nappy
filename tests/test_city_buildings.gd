extends RefCounted
## **What a real `City` hands its buildings**: `City._spawn_buildings()`'s own wiring of
## `is_on_home_block()`, `mark_door_span()` and `covered_ground_cols()` off `CityMap.home_block_coordinate()`,
## `map.home_rect` and `map.is_walkable()`, and `City.assign_roof_extensions()`'s of the roof rows,
## asked of whatever the generator actually builds across a spread of seeds, and that a dawn
## (`City.start_day()`) leaves every building and its collision shape as they were. What a building does with
## those facts once it has them (which window, door, escape or roof unit it draws) is
## `tests/test_ground_floor.gd`'s, on buildings set up by hand.
##
## **This is a direct test of the city**: the wiring is the city's and no fixture reaches it, so a
## full city is built for every seed (buildings, street trees, crowd, events), from the cached maps
## of `tests/city_map_cache.gd`. Each check also reads what its building drew (`tests/front_reads.gd`)
## and what its roof stood (`tests/roof_reads.gd`), the real `Building` over the real wiring.
##
## The fire's own flames are asked of the same buildings: they burn along the whole facade of the one
## a street fire stands before, and the dawn after it shows that building burnt.

const MapCache := preload("res://tests/city_map_cache.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const RoofReads := preload("res://tests/roof_reads.gd")
const UI := preload("res://tests/ui_screens.gd")
const FrontReads := preload("res://tests/front_reads.gd")
const DrawnEvent := preload("res://tests/drawn_event.gd")
const RecordingEventDrawer := preload("res://tests/recording_event_drawer.gd")
## The seed of the run the city is handed (`RunCity.with_own_run()`).
const RUN_SEED := 2
## A spread of cities, built in full.
const SWEEP_SEEDS := 5
const BASE_SEED := 61_400
## The seed of the city the burning building's fronts are asked of.
const FIRE_SEED := 4242

func run(t: TestRunner) -> void:
	_test_a_roof_with_nothing_to_cover_lands_its_furniture_where_main_does(t)
	await _test_the_real_sweep_wires_roof_extensions_to_reach_exactly_the_covered_roof(t)
	await _test_a_wall_beside_the_power_station_is_covered_only_over_its_hall(t)
	await _test_the_real_sweep_marks_a_courtyard_seam_seamless_and_an_ordinary_one_not(t)
	await _test_the_real_sweep_keeps_roof_furniture_off_every_lip(t)
	await _test_a_real_sweep_of_cities_never_shows_a_ground_floor_window(t)
	_test_a_dawn_replaces_no_building_and_no_collision(t)
	await _test_the_scarred_building_shows_burnt(t)

## A dawn re-dresses the city's ground and closures and rebuilds no building: every building the
## city holds after `start_day()` is the same node with the same physics shape it had before, the
## persistent collision her route is walked against.
func _test_a_dawn_replaces_no_building_and_no_collision(t: TestRunner) -> void:
	var map := MapCache.of(4242)
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	t.add_child(city)
	RunCity.build(city, map)
	var before: Array[Building] = city.buildings().duplicate()
	var shapes: Dictionary = {}
	for building in before:
		shapes[building] = _collision_shape_of(building)
	t.check(not before.is_empty() and not shapes.values().has(null),
			"every building holds a collision shape before the dawn (%d buildings)" % before.size())
	var state := CityState.new()
	state.begin_day(map.plans_by_block(), 8)
	city.start_day(state, 8, city.run.calendar().day_rng(8, "closures"))
	var after: Array[Building] = city.buildings()
	t.check(after == before, "a dawn leaves the city the same buildings, the same nodes")
	var replaced := 0
	for building in before:
		if not is_instance_valid(building) or _collision_shape_of(building) != shapes.get(building):
			replaced += 1
	t.check(replaced == 0, "a dawn replaces no building's collision shape (%d replaced)" % replaced)
	city.free()

## The physics shape the building keeps for its complete collision, found among its children.
func _collision_shape_of(building: Building) -> Shape2D:
	for child in building.get_children():
		if child is CollisionShape2D:
			return (child as CollisionShape2D).shape
	return null

## A roof with nothing to cover lands its units on exactly the cells `main` rolls for it: its pool
## is the interior in row-major order, the order the shuffle has always permuted, so an extension
## elsewhere in the city moves no other roof's furniture. Every unextended roof of the sweep
## stands its units only on its interior, and two roofs of seed 61400 are pinned to the layout
## `main` rolls for them (cell, then the unit's picture), which a pool built in any other order
## breaks.
func _test_a_roof_with_nothing_to_cover_lands_its_furniture_where_main_does(t: TestRunner) -> void:
	var main_layouts := {
		Vector2i(6, 6): [[Vector2i(5, 2), Building.WATER_TANK], [Vector2i(2, 2), Building.SERVICE_BULKHEAD],
				[Vector2i(2, 1), Building.SERVICE_BULKHEAD]],
		Vector2i(34, 6): [[Vector2i(2, 2), Building.WATER_TANK], [Vector2i(1, 2), Building.EXHAUST_FAN],
				[Vector2i(4, 1), Building.WATER_TANK], [Vector2i(6, 1), Building.EXHAUST_FAN]],
	}
	var pinned := 0
	var ordered := 0
	for i in SWEEP_SEEDS:
		var map := MapCache.of(BASE_SEED + i * 977)
		var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
		t.add_child(city)
		RunCity.build(city, map)
		for building: Building in city.buildings():
			if building.roof_extension_rows.any(func(e: int) -> bool: return e > 0):
				continue
			var expected: Array[Vector2i] = []
			if building.roof_tiles() >= 3 and building.columns() >= 3:
				for row in range(1, building.roof_tiles() - 1):
					for col in range(1, building.columns() - 1):
						expected.append(Vector2i(col, row))
			building.residence().set_resident(true)
			var inside := true
			for unit: Dictionary in RoofReads.units_of(building):
				for cell: Vector2i in unit["cells"]:
					inside = inside and expected.has(cell)
			t.check(inside, "seed %d: the unextended roof at %s stands its units on its interior"
					% [map.city_seed(), building.lot_rect().position])
			ordered += 1
			if map.city_seed() == BASE_SEED and main_layouts.has(building.lot_rect().position):
				var layout: Array = []
				for unit: Dictionary in RoofReads.units_of(building):
					layout.append([unit["cell"], unit["texture"]])
				t.check(layout == main_layouts[building.lot_rect().position],
						"seed %d: the roof at %s carries main's layout %s (got %s)"
						% [map.city_seed(), building.lot_rect().position,
						main_layouts[building.lot_rect().position], layout])
				pinned += 1
		city.free()
	t.check(ordered > 0, "the sweep met unextended roofs to ask (%d)" % ordered)
	t.check(pinned == 2, "both pinned roofs of seed %d were found (%d)" % [BASE_SEED, pinned])

## `City.assign_roof_extensions()`'s own wiring, asked of whatever the generator actually builds:
## every covered column's own south-neighbour tile that is still on the map belongs to some
## building's lot, and that building's own `roof_extension_rows` at the matching column is exactly
## the covered building's own `wall_tiles()` — enough roof to reach exactly the world row the
## covered building's own roof already starts at, never more and never less. `has_point()` over
## every building's own `lot` rather than a spatial index, since the whole set is small and this
## only runs once per seed. **No column anywhere is left with neither a facade nor a covering
## roof:** every covered column's south tile belongs to a lot whose roof reaches it, so a front
## facing the map's own edge, where no lot stands, keeps its facade.
func _test_the_real_sweep_wires_roof_extensions_to_reach_exactly_the_covered_roof(t: TestRunner) -> void:
	var checked := 0
	var edge_fronts := 0
	for i in SWEEP_SEEDS:
		var map := MapCache.of(BASE_SEED + i * 977)
		var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
		t.add_child(city)
		RunCity.build(city, map)
		var fronts := await _watch_the_fronts(t, city)
		var buildings := city.buildings()
		for building: Building in buildings:
			if building.covered_ground_cols().is_empty():
				continue
			if building.lot_rect().end.y >= map.size.y:
				edge_fronts += 1
				t.check(not building.covered_ground_cols().has(true),
						"seed %d: a front facing the map's edge at %s keeps its facade"
						% [map.city_seed(), building.lot_rect().position])
			for col in building.covered_ground_cols().size():
				if not building.covered_ground_cols()[col]:
					continue
				var south := Vector2i(building.lot_rect().position.x + col,
						building.lot_rect().position.y + building.lot_rect().size.y)
				t.check(map.in_bounds(south),
						"seed %d: a covered column's south tile is on the map" % map.city_seed())
				if not map.in_bounds(south):
					continue
				var front: Building = null
				for candidate: Building in buildings:
					if candidate.lot_rect().has_point(south):
						front = candidate
						break
				t.check(front != null,
						"seed %d: a column with no facade has a lot south of it to cover it"
						% map.city_seed())
				if front == null:
					continue
				var local_col := south.x - front.lot_rect().position.x
				var extension: int = _front_of(fronts, front).roof_rows_at(local_col) - front.roof_tiles()
				t.check(extension == building.wall_tiles(),
						"seed %d: no column is left with neither a facade nor a covering roof (%d rows expected, got %d)"
						% [map.city_seed(), building.wall_tiles(), extension])
				checked += 1
		city.free()
	t.check(checked > 0, "the sweep met at least one real covered column to check the extension's own wiring on (%d)" % checked)
	t.check(edge_fronts > 0, "the sweep met a front facing the map's edge (%d)" % edge_fronts)

## A cul-de-sac wall (`CityGenerator._wall_off_one_end()`, a 2-tile lot) can stand directly north
## of the power station. Over the station's yard no roof stands to extend, so the wall keeps its
## facade and the station draws no roof there; over its hall the wall is covered and the hall's roof
## is drawn as many rows taller as the wall is high. Seeds 823576 (a wall over the yard) and 966118
## (a wall over the hall) are cities that have each.
func _test_a_wall_beside_the_power_station_is_covered_only_over_its_hall(t: TestRunner) -> void:
	var over_yard := 0
	var over_hall := 0
	for seed_value: int in [823576, 966118]:
		var map := CityGenerator.generate(seed_value)
		var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
		t.add_child(city)
		RunCity.build(city, map)
		var fronts := await _watch_the_fronts(t, city)
		var station: Building = null
		for building: Building in city.buildings():
			if building.is_power_station():
				station = building
		t.check(station != null, "seed %d: the city has its power station" % seed_value)
		if station == null:
			city.free()
			continue
		var hall := station.hall_cols()
		for wall: Building in city.buildings():
			if wall.is_power_station() or wall.lot_rect().end.y != station.lot_rect().position.y:
				continue
			for col in wall.columns():
				var local := wall.lot_rect().position.x + col - station.lot_rect().position.x
				if local < 0 or local >= station.columns():
					continue
				var covered: bool = col < wall.covered_ground_cols().size() and wall.covered_ground_cols()[col]
				var station_rows: int = _front_of(fronts, station).roof_rows_at(local)
				if local >= hall.x and local < hall.y:
					over_hall += 1
					t.check(covered and not _front_of(fronts, wall).facade_drawn_in(col),
							"seed %d: a wall over the hall (column %d) is covered and draws no facade" % [seed_value, col])
					t.check(station_rows == station.roof_tiles() + wall.wall_tiles(),
							"seed %d: the hall's roof is drawn %d rows taller over that wall (%d rows)"
							% [seed_value, wall.wall_tiles(), station_rows])
				else:
					over_yard += 1
					t.check(not covered and _front_of(fronts, wall).facade_drawn_in(col),
							"seed %d: a wall over the yard (column %d) keeps its facade" % [seed_value, col])
					t.check(station_rows == 0,
							"seed %d: the station draws no roof over its yard (%d rows)" % [seed_value, station_rows])
		city.free()
	t.check(over_yard > 0, "the seeds have a wall over the station's yard (%d)" % over_yard)
	t.check(over_hall > 0, "the seeds have a wall over the station's hall (%d)" % over_hall)

## `City.assign_roof_extensions()`'s own courtyard wiring: a covered column's extension is
## seamless exactly when the covered building and the covering building were both cut from the same
## courtyard lot — a single-block courtyard's own `map.lot_rect(block)`, or an apartment complex's
## (`_build_block()`'s shared `COURTYARD` branch cuts both the same way, `_subtract_all()` around
## the hole). Recomputes the courtyard-lot membership independently here, the same way the roof-
## extension sweep above recomputes "front" independently rather than trusting `_assign_roof_
## extensions()`'s own bookkeeping — so this only passes if the wiring is actually right, not merely
## self-consistent. Every OTHER covered column (an ordinary front and back, two genuinely
## separate buildings) must NOT be seamless, or a real parapet step would silently vanish there too.
## A covered piece with no roof of its own is the one courtyard seam that still caps, since nothing
## of its own carries on above the extension. Each seam is asked what it *draws*
## on both sides: no lip on either side of a seamless one, a lip on
## both sides of an ordinary one — and both pieces of a courtyard seam carry the same roof tint.
func _test_the_real_sweep_marks_a_courtyard_seam_seamless_and_an_ordinary_one_not(t: TestRunner) -> void:
	var checked_courtyard := 0
	var checked_ordinary := 0
	for i in SWEEP_SEEDS:
		var map := MapCache.of(BASE_SEED + i * 977)
		var courtyard_lots: Array[Rect2i] = []
		for block: Vector2i in map.blocks_with_layouts():
			if map.starting_purpose(block) == GameEnums.BlockPurpose.COURTYARD:
				courtyard_lots.append(map.lot_rect(block))
		var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
		t.add_child(city)
		RunCity.build(city, map)
		var fronts := await _watch_the_fronts(t, city)
		var buildings := city.buildings()
		for building: Building in buildings:
			if building.is_power_station() or building.covered_ground_cols().is_empty():
				continue
			for col in building.covered_ground_cols().size():
				if not building.covered_ground_cols()[col]:
					continue
				var south := Vector2i(building.lot_rect().position.x + col,
						building.lot_rect().position.y + building.lot_rect().size.y)
				if not map.in_bounds(south):
					continue
				var front: Building = null
				for candidate: Building in buildings:
					if candidate.lot_rect().has_point(south):
						front = candidate
						break
				if front == null:
					continue
				var back_lot := -1
				var front_lot := -1
				for lot_index in courtyard_lots.size():
					if courtyard_lots[lot_index].encloses(building.lot_rect()):
						back_lot = lot_index
					if courtyard_lots[lot_index].encloses(front.lot_rect()):
						front_lot = lot_index
				var same_courtyard := back_lot >= 0 and back_lot == front_lot
				var expect_seamless := same_courtyard and building.roof_tiles() > 0
				var local_col := south.x - front.lot_rect().position.x
				if same_courtyard:
					t.check(front.tint_variant >= 0 and front.tint_variant == building.tint_variant,
							"seed %d: two pieces of one courtyard lot share one tint (%d, %d)"
							% [map.city_seed(), front.tint_variant, building.tint_variant])
				var extension: int = _front_of(fronts, front).roof_rows_at(local_col) - front.roof_tiles()
				if extension <= 0 or building.roof_tiles() <= 0:
					continue
				var top := front.roof_tiles() + extension - 1
				var cap_drawn: bool = (_front_of(fronts, front).roof_edges_at(local_col, top) & Building.ROOF_EDGE_BIT_N) != 0
				var lip_drawn: bool = (_front_of(fronts, building).roof_edges_at(col, 0) & Building.ROOF_EDGE_BIT_S) != 0
				t.check(cap_drawn != expect_seamless,
						"seed %d: the covering piece's extension top draws a north lip exactly off a seamless seam"
						% map.city_seed())
				t.check(lip_drawn != expect_seamless,
						"seed %d: the covered piece's first roof row draws a front lip exactly off a seamless seam"
						% map.city_seed())
				if expect_seamless:
					checked_courtyard += 1
				else:
					checked_ordinary += 1
		city.free()
	t.check(checked_ordinary > 0,
			"the sweep met at least one ordinary (non-courtyard) covered column to check (%d)" % checked_ordinary)
	t.check(checked_courtyard > 0,
			"the sweep met at least one courtyard seam to check seamlessness on (%d)" % checked_courtyard)

## No roof unit on any real building sits on a cell whose own lips are drawn, extended or not — the
## rule every roof keeps, asked of the extension too, where a taller column steps down beside a
## shorter one. The power station's hall is left out: its own yard edge is a lip the ordinary
## interior bound was never measured against.
func _test_the_real_sweep_keeps_roof_furniture_off_every_lip(t: TestRunner) -> void:
	var checked := 0
	var on_extension := 0
	var on_shallow_extension := 0
	for i in SWEEP_SEEDS:
		var map := MapCache.of(BASE_SEED + i * 977)
		var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
		t.add_child(city)
		RunCity.build(city, map)
		var fronts := await _watch_the_fronts(t, city)
		for building: Building in city.buildings():
			if building.is_power_station():
				continue
			for unit: Dictionary in RoofReads.units_of(building):
				var cell: Vector2i = unit["cell"]
				for step in int(unit["span"]):
					var at := cell + Vector2i(step, 0)
					t.check(_front_of(fronts, building).roof_edges_at(at.x, at.y) == 0,
							"seed %d: a roof unit at %s sits on a cell with no lip" % [map.city_seed(), at])
					checked += 1
					if at.y >= building.roof_tiles():
						on_extension += 1
						if building.roof_tiles() < 3:
							on_shallow_extension += 1
		city.free()
	t.check(checked > 0, "the sweep met roof units to check (%d)" % checked)
	t.check(on_extension > 0, "the sweep met at least one roof unit on an extension (%d)" % on_extension)
	t.check(on_shallow_extension > 0,
			"the sweep met a unit on the extension of a roof too shallow on its own (%d)"
			% on_shallow_extension)

## Full `City` scenes across a spread of seeds — the only path that exercises
## `City._spawn_buildings()`'s own wiring of `is_on_home_block()`, `mark_door_span()` and
## `covered_ground_cols()` off `CityMap.home_block_coordinate()`, `map.home_rect` and `map.is_walkable()`,
## rather than a fixture set directly.
func _test_a_real_sweep_of_cities_never_shows_a_ground_floor_window(t: TestRunner) -> void:
	var checked_non_home := 0
	var checked_home := 0
	var checked_home_multistory := 0
	var checked_door_columns := 0
	var checked_commercial := 0
	var checked_doors := 0
	var checked_escapes := 0
	var checked_covered_columns := 0
	var checked_fully_covered_fronts := 0
	for i in SWEEP_SEEDS:
		var map := MapCache.of(BASE_SEED + i * 977)
		var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
		t.add_child(city)
		RunCity.build(city, map)
		var fronts := await _watch_the_fronts(t, city)
		for building: Building in city.buildings():
			var front := _front_of(fronts, building)
			_check_accessor_invariant(t, building, front, map.city_seed())
			if GroundFloorChecks.check_fire_escape(t, front, "seed %d" % map.city_seed()):
				checked_escapes += 1
			if building.is_power_station():
				continue
			if building.is_on_home_block():
				checked_home += 1
				t.check(building.covered_ground_cols().is_empty(),
						"seed %d: her own building is never told about a covered column" % map.city_seed())
				t.check(front.escape_cols().is_empty(),
						"seed %d: her own building never carries a fire escape, wired the real way through the city's building spawn"
						% map.city_seed())
				if building.wall_tiles() >= 2:
					checked_home_multistory += 1
					var saw_a_window := false
					for col in building.columns():
						var under_door := _under_door(building, col, map)
						if under_door:
							checked_door_columns += 1
						t.check((front.window_at(col, 0) != &"") != under_door,
								"seed %d: her own building draws a ground-floor window at column %d iff the door does not stand there"
								% [map.city_seed(), col])
						saw_a_window = saw_a_window or not under_door
					t.check(saw_a_window,
							"seed %d: her own building still shows a ground-floor window somewhere the door does not stand"
							% map.city_seed())
				continue
			checked_non_home += 1
			if building.wall_tiles() < 2:
				continue
			var any_covered := false
			for col in building.columns():
				# Never a window, covered or not: a covered column draws nothing on the wall at all,
				# since the roof in front of it reaches up to meet this building's own roof.
				t.check(front.window_at(col, 0) == &"",
						"seed %d: no ground-floor column of a building that is not her own draws a window, covered or not (district %d)"
						% [map.city_seed(), building.district()])
				if col < building.covered_ground_cols().size() and building.covered_ground_cols()[col]:
					any_covered = true
					checked_covered_columns += 1
					t.check(not front.facade_drawn_in(col),
							"seed %d: a covered column (%d) draws no facade at all, no storefront and no blank-wall plinth (district %d)"
							% [map.city_seed(), col, building.district()])
			var fully_covered := any_covered and building.covered_ground_cols().count(true) == building.columns()
			if fully_covered:
				checked_fully_covered_fronts += 1
				t.check(front.door_col() == -1,
						"seed %d: a fully covered front has no door (district %d)" % [map.city_seed(), building.district()])
			var door: int = front.door_col()
			var shop_col := -1
			for probe_col in building.columns():
				var picture: StringName = front.ground_floor_at(probe_col)
				if picture != Building.WALL_BASE and picture != &"":
					shop_col = probe_col
					break
			var has_other_way_in: bool = (building.district() == GameEnums.BlockPurpose.CIVIC and front.portico_drawn()) \
					or (building.district() == GameEnums.BlockPurpose.COMMERCIAL and shop_col >= 0)
			if has_other_way_in:
				t.check(door == -1, "seed %d: a front with a drawn storefront or portico has no extra door" % map.city_seed())
			elif fully_covered:
				t.check(door == -1, "seed %d: a fully covered front with no other way in still has no door" % map.city_seed())
			else:
				checked_doors += 1
				t.check(door >= 0 and door < building.columns() and not front.escape_cols().has(door)
						and not (door < building.covered_ground_cols().size() and building.covered_ground_cols()[door]),
						"seed %d: a multi-story front with no other way in has one door, off every fire escape and every covered column (district %d)"
						% [map.city_seed(), building.district()])
			if building.district() == GameEnums.BlockPurpose.COMMERCIAL and shop_col >= 0:
				checked_commercial += 1
				var texture: StringName = front.ground_floor_at(shop_col)
				t.check(Building.STOREFRONT_TEXTURES.has(texture) or Building.STOREFRONT_AWNING_TEXTURES.has(texture)
						or Building.STOREFRONT_SHUTTERED_TEXTURES.has(texture),
						"seed %d: a real commercial building's storefront is still drawn" % map.city_seed())
		city.free()
	t.check(checked_non_home > 0, "the sweep built non-home buildings to check (%d)" % checked_non_home)
	t.check(checked_home > 0, "the sweep built her own building at least once (%d)" % checked_home)
	t.check(checked_home_multistory > 0,
			"the sweep built a multi-story home building at least once (%d)" % checked_home_multistory)
	t.check(checked_door_columns > 0,
			"the sweep met at least one ground-floor column standing behind the door (%d)" % checked_door_columns)
	t.check(checked_commercial > 0, "the sweep built a commercial storefront at least once (%d)" % checked_commercial)
	t.check(checked_doors > 0, "the sweep built a front with an entrance door (%d)" % checked_doors)
	t.check(checked_escapes > 0, "the sweep built a front with a fire escape (%d)" % checked_escapes)
	t.check(checked_covered_columns > 0,
			"the sweep met at least one real covered ground-floor column (%d)" % checked_covered_columns)
	t.check(checked_fully_covered_fronts > 0,
			"the sweep met at least one real fully covered front (%d)" % checked_fully_covered_fronts)

## Every accessor cell a real building offers is plain wall (the ground floor shows
## `WALL_BASE` there) and never one of the portico's own columns while the portico actually
## draws (a portico dropped for a covered column frees the other one it straddled) — the same two contracts
## `_test_the_accessor_returns_ground_floor_non_window_non_entrance_cells` pins on fixtures, asked
## again of whatever the generator actually builds.
func _check_accessor_invariant(t: TestRunner, building: Building, front: FrontReads, seed_used: int) -> void:
	var entrance_cols: Array[int] = []
	if front.portico_drawn():
		entrance_cols = front.portico_cols()
	var ground_row_y := GroundFloorChecks.ground_cell(building, 0).position.y
	for cell in building.blank_ground_floor_cells():
		var col := GroundFloorChecks.col_of(building, cell)
		t.check(is_equal_approx(cell.position.y, ground_row_y),
				"seed %d: every accessor cell sits on the ground row" % seed_used)
		t.check(front.ground_floor_at(col) == Building.WALL_BASE,
				"seed %d: every accessor cell is plain wall, not a window or a storefront" % seed_used)
		t.check(not entrance_cols.has(col),
				"seed %d: no accessor cell is a drawn civic entrance's own column" % seed_used)
		t.check(col != front.door_col() and not front.escape_cols().has(col),
				"seed %d: no accessor cell is the door's column or a fire escape's" % seed_used)
		t.check(not building.covered_ground_cols()[col] if col < building.covered_ground_cols().size() else true,
				"seed %d: no accessor cell is a covered column — those draw no facade at all, never blank wall" % seed_used)

## Hands every building of `city` a drawer that records, has it drawn, and answers each building's
## reads of its front once two frames have passed.
func _watch_the_fronts(t: TestRunner, city: City) -> Dictionary:
	for building in city.buildings():
		FrontReads.watch(building)
	await UI.frames(t, 2)
	var fronts := {}
	for building in city.buildings():
		fronts[building] = FrontReads.look(building)
	return fronts

## What `building`'s front shows, out of `_watch_the_fronts()`'s record.
static func _front_of(fronts: Dictionary, building: Building) -> FrontReads:
	return fronts[building] as FrontReads

## Whether ground-floor column `col` of `building` stands under the door of `map`'s home, worked out
## from first principles: the door stands at the centre of the home's tile rect and covers half its
## picture's baked width either side, so the column's own world span overlaps the door's.
static func _under_door(building: Building, col: int, map: CityMap) -> bool:
	var centre_x := map.tile_rect_to_world(map.home_tile_rect()).get_center().x
	var half_width := AtlasTable.baked().native_size(City.DOOR_TEXTURE).x * 0.5
	var min_x := building.global_position.x - building.columns() * Building.TILE * 0.5 + col * Building.TILE
	return min_x < centre_x + half_width and min_x + Building.TILE > centre_x - half_width

## **The fire only catches where there is a building to burn, and burns on that building alone.**
## Every tile `burning_building`'s own placement (`AT_THE_FRONT`) offers has one of the city's
## `Building`s directly north of it — never the edge of the world, which `CityMap.tile_at()` reads
## as `BUILDING` — and the flames a fire sited there draws, read off the pictures its look tells
## its drawer to stand (`tests/recording_event_drawer.gd`) on real frames, burn along the
## whole of that building's own facade and stay inside it, including at a site on the first or last
## column of its lot: every column the city draws a facade on carries a flame, and no column another
## building's roof covers does. *"the fire should be on the whole building not only the door"*
## (sandy-egret).
##
## **Then the dawn after it shows that building burnt** — *"the building is what needs to be burnt,
## not an object next to the building"* — through `City.start_day()`, the way a real morning
## reaches `CityFronts.mark_the_burnt_frontage()`, from a scar recorded where a real fire sites.
func _test_the_scarred_building_shows_burnt(t: TestRunner) -> void:
	var city: City = RunCity.with_own_run(CITY_SCENE, FIRE_SEED)
	city.run.header().set_day(4)
	t.add_child(city)
	RunCity.build(city, CityGenerator.generate(FIRE_SEED))

	var sites := {}
	for tile in EventScheduler.row_ground(city.map).tiles_for(
			EventCatalogue.by_id("burning_building")):
		sites[tile] = true
	t.check(sites.size() > 100,
			"seed %d: there are fronts for the fire to catch on (%d)" % [FIRE_SEED, sites.size()])
	# Every site holds a street fire of its own on the city's map, found and drawn as the game does,
	# all drawn by the same three frames.
	var def := EventCatalogue.by_id("burning_building")
	var fires := {}
	for tile: Vector2i in sites:
		if _building_at(city, tile + Vector2i.UP):
			fires[tile] = DrawnEvent.build(t, def, false, null, city.map, city.map.tile_to_world(tile))
	await DrawnEvent.frames(t)
	var nothing_behind: Array[Vector2i] = []
	var spilled: Array[Vector2i] = []
	var bare: Array[Vector2i] = []
	var on_a_roof: Array[Vector2i] = []
	var at_a_lot_end := 0
	var wider_than_five := 0
	var size := float(Tuning.TILE_SIZE)
	for tile: Vector2i in sites:
		var behind := _building_at(city, tile + Vector2i.UP)
		if not behind:
			nothing_behind.append(tile)
			continue
		if tile.x == behind.lot_rect().position.x or tile.x == behind.lot_rect().end.x - 1:
			at_a_lot_end += 1
		var fire: EventInstance = fires[tile]
		var facade := city.map.tile_rect_to_world(behind.lot_rect())
		if facade.size.x > 80.0:
			wider_than_five += 1
		# Each flame as the span of x it covers in the world.
		var flames: Array[Vector2] = []
		for entry in DrawnEvent.shown(fire):
			if entry.picture == EventPictures.FLAME:
				var rect := RecordingEventDrawer.rect_about(entry, fire)
				flames.append(Vector2(fire.global_position.x + rect.position.x,
						fire.global_position.x + rect.end.x))
		for flame in flames:
			if flame.x < facade.position.x - 0.01 or flame.y > facade.end.x + 0.01:
				spilled.append(tile)
				break
		# Each column, at its middle and a pixel in from both its edges, against every flame's own
		# span: a column the building draws is burning end to end (so a flame dropped at the end of a
		# stretch leaves a bare edge), one another building's roof covers (`Building.covered_ground_cols()`)
		# is not.
		for col in behind.lot_rect().size.x:
			var left_edge := facade.position.x + col * size
			var drawn := not (col < behind.covered_ground_cols().size() and behind.covered_ground_cols()[col])
			var burning_all := true
			var burning_any := false
			for point: float in [left_edge + 1.0, left_edge + size * 0.5, left_edge + size - 1.0]:
				var burning := false
				for flame in flames:
					if flame.x <= point and point <= flame.y:
						burning = true
				burning_all = burning_all and burning
				burning_any = burning_any or burning
			if drawn and not burning_all:
				bare.append(tile)
				break
			if burning_any and not drawn:
				on_a_roof.append(tile)
				break
	for fire: EventInstance in fires.values():
		fire.free()
	t.check(nothing_behind.is_empty(),
			"every front the fire can catch on has a building behind it (%d do not, first %s)"
			% [nothing_behind.size(), nothing_behind.slice(0, 3)])
	t.check(at_a_lot_end > 0,
			"and some of them stand at a lot's end, where flames could spill over (%d)" % at_a_lot_end)
	t.check(spilled.is_empty(),
			"the flames stay on the burning building's own facade (%d spill over, first %s)"
			% [spilled.size(), spilled.slice(0, 3)])
	t.check(wider_than_five > 0,
			"and some fronts are wider than five flames could cover (%d)" % wider_than_five)
	t.check(bare.is_empty(),
			"the whole facade burns, every column it draws (%d leave one bare, first %s)"
			% [bare.size(), bare.slice(0, 3)])
	t.check(on_a_roof.is_empty(),
			"and never a column another building's roof covers (%d do, first %s)"
			% [on_a_roof.size(), on_a_roof.slice(0, 3)])

	# **Never the power station's front**: its facade is drawn whole whatever its condition says,
	# and its transformer yard has no wall for day 8's arrow to end on. Guarded against vacuity by
	# the station's own fronts, which the same lane offers any row that does not burn.
	var station := CityMap.blocks_tile_rect(city.map.power_station)
	t.check(city.map.has_power_station(), "seed %d has a power station" % FIRE_SEED)
	var station_fronts := 0
	var lane_of_fronts := EventScheduler.row_ground(city.map).tiles_for(
			EventCatalogue.by_id("cafe_tables"), EventDef.Pavement.AT_THE_FRONT)
	for tile in lane_of_fronts:
		if station.has_point(tile + Vector2i.UP):
			station_fronts += 1
	t.check(station_fronts > 0,
			"seed %d: the power station has fronts on the lane (%d)" % [FIRE_SEED, station_fronts])
	var on_the_station: Array[Vector2i] = []
	for tile: Vector2i in sites:
		if station.has_point(tile + Vector2i.UP):
			on_the_station.append(tile)
	t.check(on_the_station.is_empty(),
			"the fire never catches on the power station (%d fronts do, first %s)"
			% [on_the_station.size(), on_the_station.slice(0, 3)])

	var site: Vector2i = sites.keys()[sites.size() / 2]
	var scarred := _building_at(city, site + Vector2i.UP)
	t.check(scarred != null, "the fire's site has a building behind it")
	if not scarred:
		city.free()
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = FIRE_SEED
	city.start_day(CityState.new(), 4, rng)
	t.check(_burnt_count(city) == 0, "no building is burnt before any fire has left a scar")

	city.run.add_scar("burnt_shell", city.map.tile_to_world(site))
	city.start_day(CityState.new(), 4, rng)
	t.check(scarred.condition() == Building.Condition.BURNT,
			"the dawn after the fire, the building behind its scar is drawn burnt")
	t.check(_burnt_count(city) == 1, "and no other building is (%d are)" % _burnt_count(city))
	city.start_day(CityState.new(), 5, rng)
	t.check(scarred.condition() == Building.Condition.BURNT and _burnt_count(city) == 1,
			"and every dawn after that, the same one")
	# Day 11's market boards its block up during the day (`present_block()`), and the burnt
	# building is never boarded up with it.
	city.fronts().present_block(
			city.map.block_at(city.map.tile_rect_to_world(scarred.lot_rect()).get_center()),
			CityState.new())
	t.check(scarred.condition() == Building.Condition.BURNT,
			"its block shown anew during the day leaves the burnt building burnt")

	city.free()

## The one `Building` whose lot holds `tile`, or null.
func _building_at(city: City, tile: Vector2i) -> Building:
	for building in city.buildings():
		if building.lot_rect().has_point(tile):
			return building
	return null

func _burnt_count(city: City) -> int:
	var burnt := 0
	for building in city.buildings():
		if building.condition() == Building.Condition.BURNT:
			burnt += 1
	return burnt
