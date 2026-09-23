extends RefCounted
## M185's rule: a multi-story building's ground floor is shops or blank wall, never windows,
## except her own. `Building._draws_window_at()` is the one place that decides whether row 0 draws
## a window at all; `_build_windows()`/`_build_front()` still roll exactly the same streams they
## always have, so what changed is only which of their rolls get painted at the ground floor,
## never what the rolls are. `Building.blank_ground_floor_cells()` is the new accessor a later
## poster slice pastes on.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
## A spread of cities, built in full (buildings, street trees, crowd, events) so the sweep exercises
## `City._spawn_buildings()`'s own wiring of `is_home_building`, not only the isolated fixtures the
## rest of this suite uses for the fast, per-district checks.
const SWEEP_SEEDS := 5
const BASE_SEED := 61_400

func run(t) -> void:
	_test_no_ground_floor_window_on_a_multistory_non_home_building(t)
	_test_commercial_storefronts_remain_and_the_odd_column_is_blank(t)
	_test_her_own_building_keeps_ground_floor_windows(t)
	_test_a_one_row_facade_is_unchanged(t)
	_test_the_accessor_returns_ground_floor_non_window_non_entrance_cells(t)
	_test_upper_floor_rolls_are_unchanged_for_a_fixed_seed(t)
	_test_the_home_flag_changes_no_front_roll(t)
	_test_a_real_sweep_of_cities_never_shows_a_ground_floor_window(t)

# ------------------------------------------------------------------- fixtures ---

## One `Building`, built the way `City._spawn_buildings()` builds one — the exports set, then
## `add_child()`, which is what fires `_ready()` and rolls `_build_windows()`/`_build_front()`.
static func _new_building(t, district: int, footprint: Vector2, height: float, is_home := false,
		position := Vector2.ZERO) -> Building:
	var building := Building.new()
	building.district = district
	building.footprint = footprint
	building.height = height
	building.position = position
	building.is_home_building = is_home
	t.add_child(building)
	return building

# ------------------------------------------------------------------- the rule ---

func _test_no_ground_floor_window_on_a_multistory_non_home_building(t) -> void:
	var districts: Array[int] = [GameEnums.BlockPurpose.RESIDENTIAL, GameEnums.BlockPurpose.COMMERCIAL,
			GameEnums.BlockPurpose.INDUSTRIAL, GameEnums.BlockPurpose.CIVIC]
	for district in districts:
		var building := _new_building(t, district, Vector2(96.0, 96.0), 64.0)
		t.check(building.wall_tiles() >= 2,
				"the fixture is genuinely multi-story (%d wall rows)" % building.wall_tiles())
		t.check(not building._draws_window_at(0),
				"district %d: a multi-story non-home building draws no ground-floor window" % district)
		for row in range(1, building.wall_tiles()):
			t.check(building._draws_window_at(row),
					"district %d: an upper floor still draws its own window (row %d)" % [district, row])
		building.free()

func _test_commercial_storefronts_remain_and_the_odd_column_is_blank(t) -> void:
	var building := _new_building(t, GameEnums.BlockPurpose.COMMERCIAL, Vector2(96.0, 96.0), 64.0)
	t.check(building._storefront_variant.size() == 1,
			"a three-column facade has one complete storefront pair")
	var storefront_texture := building._ground_floor_texture(0)
	t.check(Building.STOREFRONT_TEXTURES.has(storefront_texture)
			or Building.STOREFRONT_AWNING_TEXTURES.has(storefront_texture),
			"the storefront pair's own ground-floor texture is still a storefront, not blank wall")
	t.check(building._ground_floor_texture(2) == Building.WALL_BASE,
			"the odd final column is blank wall rather than a window")
	t.check(not building._draws_window_at(0),
			"no window is drawn under the ground floor either way — the odd column just shows the plinth")
	building.free()

func _test_her_own_building_keeps_ground_floor_windows(t) -> void:
	var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 96.0), 64.0, true)
	t.check(building.is_home_building, "the fixture is flagged as her own building")
	t.check(building.wall_tiles() >= 2, "the fixture is genuinely multi-story")
	t.check(building._draws_window_at(0), "her own building's ground floor still draws a window")
	building.free()

func _test_a_one_row_facade_is_unchanged(t) -> void:
	for is_home in [false, true]:
		var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 32.0), 32.0, is_home)
		t.check(building.wall_tiles() == 1, "the fixture is genuinely one row tall (%d)" % building.wall_tiles())
		t.check(building._draws_window_at(0),
				"a one-row facade is not multi-story, so it keeps its window regardless of the home flag (home=%s)"
				% is_home)
		building.free()

# ---------------------------------------------------------------- the accessor ---

func _test_the_accessor_returns_ground_floor_non_window_non_entrance_cells(t) -> void:
	# CIVIC, an odd column count: the portico lands on exactly the one middle column.
	var civic_odd := _new_building(t, GameEnums.BlockPurpose.CIVIC, Vector2(96.0, 96.0), 64.0)
	var odd_entrance := civic_odd._civic_entrance_cols()
	t.check(odd_entrance.size() == 1, "an odd-width civic front's portico lands on one column (%d)" % odd_entrance.size())
	var odd_cells := civic_odd.blank_ground_floor_cells()
	t.check(odd_cells.size() == civic_odd.columns() - odd_entrance.size(),
			"a civic front's blank cells are every ground-floor column but the portico's (%d of %d)"
			% [odd_cells.size(), civic_odd.columns()])
	civic_odd.free()

	# CIVIC, an even column count: the portico straddles the two middle columns instead of landing
	# on one exactly.
	var civic_even := _new_building(t, GameEnums.BlockPurpose.CIVIC, Vector2(128.0, 96.0), 64.0)
	var even_entrance := civic_even._civic_entrance_cols()
	t.check(even_entrance.size() == 2,
			"an even-width civic front's portico straddles two columns (%d)" % even_entrance.size())
	var even_cells := civic_even.blank_ground_floor_cells()
	t.check(even_cells.size() == civic_even.columns() - even_entrance.size(),
			"an even-width civic front excludes both columns the portico straddles (%d of %d)"
			% [even_cells.size(), civic_even.columns()])
	civic_even.free()

	# COMMERCIAL: the storefront pair's own columns are never blank; the odd final column is.
	var commercial := _new_building(t, GameEnums.BlockPurpose.COMMERCIAL, Vector2(96.0, 96.0), 64.0)
	var commercial_cells := commercial.blank_ground_floor_cells()
	t.check(commercial_cells.size() == 1,
			"a three-column commercial front has exactly one blank cell, the odd final column (%d)"
			% commercial_cells.size())
	if not commercial_cells.is_empty():
		var odd_col_cell := Rect2(commercial._cell(2, 0), Vector2(Building.TILE, Building.TILE))
		t.check(commercial_cells[0] == odd_col_cell, "the one blank cell is exactly the odd final column")
	commercial.free()

	# Every returned cell is ground-floor (row 0's own y) and exactly one tile.
	var residential := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 96.0), 64.0)
	var residential_cells := residential.blank_ground_floor_cells()
	t.check(residential_cells.size() == residential.columns(),
			"a residential front with no entrance to exclude is blank across every column (%d of %d)"
			% [residential_cells.size(), residential.columns()])
	var ground_row_y := residential._cell(0, 0).y
	for cell in residential_cells:
		t.check(is_equal_approx(cell.position.y, ground_row_y), "every accessor cell sits on the ground row")
		t.check(cell.size == Vector2(Building.TILE, Building.TILE), "every accessor cell is exactly one tile")
	residential.free()

	# The three guards: the power station, her own building and a one-row facade offer nothing.
	var station := _new_building(t, GameEnums.BlockPurpose.INDUSTRIAL, Vector2(96.0, 256.0), 64.0)
	station.power_station = true
	t.check(station.blank_ground_floor_cells().is_empty(),
			"the power station draws its own front, so the accessor has nothing to offer")
	station.free()

	var home := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 96.0), 64.0, true)
	t.check(home.blank_ground_floor_cells().is_empty(),
			"her own building keeps its windows, so the accessor has nothing to offer")
	home.free()

	var shallow := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 32.0), 32.0)
	t.check(shallow.blank_ground_floor_cells().is_empty(),
			"a one-row facade is not multi-story, so the accessor has nothing to offer")
	shallow.free()

# ------------------------------------------------------------------- RNG streams ---

## Replays `_build_windows()`'s own RNG stream and `_window_texture()`'s own style match, using only
## the public consts `_window_texture()` already returns — never the private `_WindowStyle` enum —
## so this pins the *behaviour* `main` already has rather than an implementation detail of it. Run
## for both a home and a non-home building at the same seed, since the rule change reads
## `is_home_building` only in `_draws_window_at()` and must not have touched this roll at all.
func _test_upper_floor_rolls_are_unchanged_for_a_fixed_seed(t) -> void:
	for is_home in [false, true]:
		var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 96.0), 64.0,
				is_home, Vector2(4321.0, 9876.0))
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%d:%d:%d" % [building.variant, int(building.global_position.x), int(building.global_position.y)])
		var expected_lit: Array[bool] = []
		for i in building.columns() * building.wall_tiles():
			expected_lit.append(rng.randf() < Building.LIT_WINDOW_CHANCE)
		var style_roll := rng.randf()
		var expected_dark: StringName
		if style_roll < Building.SHUTTERED_WINDOW_CHANCE:
			expected_dark = Building.WINDOW_SHUTTERED_DARK
		elif style_roll < Building.SHUTTERED_WINDOW_CHANCE + Building.TALL_WINDOW_CHANCE:
			expected_dark = Building.WINDOW_TALL_DARK
		else:
			expected_dark = Building.WINDOW_DARK
		var expected_lit_texture: StringName = {
			Building.WINDOW_SHUTTERED_DARK: Building.WINDOW_SHUTTERED_LIT,
			Building.WINDOW_TALL_DARK: Building.WINDOW_TALL_LIT,
			Building.WINDOW_DARK: Building.WINDOW_LIT,
		}[expected_dark]
		for index in building.columns() * building.wall_tiles():
			var texture := building._window_texture(index)
			var expected: StringName = expected_lit_texture if expected_lit[index] else expected_dark
			t.check(texture == expected,
					"home=%s index %d: the window roll and style match _build_windows()'s own stream"
					% [is_home, index])
		building.free()

## `_build_front()`'s own seed string never mentions `is_home_building`, so two otherwise-identical
## buildings — one flagged hers, one not — must roll the exact same storefront bag, awning,
## ambient-shutter and fire-escape values. Checked directly rather than replaying the stream, since
## `tests/test_city_decay.gd` already pins what the stream itself produces.
func _test_the_home_flag_changes_no_front_roll(t) -> void:
	var shared_position := Vector2(1234.0, 5678.0)
	var plain := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 96.0), 64.0, false, shared_position)
	var home := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 96.0), 64.0, true, shared_position)
	t.check(plain._fire_escape_col == home._fire_escape_col
			and plain._fire_escape_variant_b == home._fire_escape_variant_b,
			"the home flag changes nothing about the fire-escape roll")
	plain.free()
	home.free()

	var commercial_plain := _new_building(t, GameEnums.BlockPurpose.COMMERCIAL, Vector2(96.0, 96.0), 64.0,
			false, shared_position)
	var commercial_home := _new_building(t, GameEnums.BlockPurpose.COMMERCIAL, Vector2(96.0, 96.0), 64.0,
			true, shared_position)
	t.check(commercial_plain._storefront_variant == commercial_home._storefront_variant
			and commercial_plain._storefront_awning == commercial_home._storefront_awning
			and commercial_plain._storefront_shutter_severity == commercial_home._storefront_shutter_severity,
			"the home flag changes nothing about the storefront bag, awning or ambient-shutter rolls")
	commercial_plain.free()
	commercial_home.free()

# --------------------------------------------------------------------- the sweep ---

## Every accessor cell a real building offers is plain wall (`_ground_floor_texture()` says
## `WALL_BASE`) and never one of `_civic_entrance_cols()`'s own columns — the same two contracts
## `_test_the_accessor_returns_ground_floor_non_window_non_entrance_cells` pins on fixtures, asked
## again of whatever the generator actually builds.
func _check_accessor_invariant(t, building: Building, seed_used: int) -> void:
	var entrance_cols := building._civic_entrance_cols()
	var ground_row_y := building._cell(0, 0).y
	for cell in building.blank_ground_floor_cells():
		var col := int(roundf((cell.position.x - building._cell(0, 0).x) / Building.TILE))
		t.check(is_equal_approx(cell.position.y, ground_row_y),
				"seed %d: every accessor cell sits on the ground row" % seed_used)
		t.check(building._ground_floor_texture(col) == Building.WALL_BASE,
				"seed %d: every accessor cell is plain wall, not a window or a storefront" % seed_used)
		t.check(not entrance_cols.has(col),
				"seed %d: no accessor cell is the civic entrance's own column" % seed_used)

## Full `City` scenes across a spread of seeds — the only path that exercises
## `City._spawn_buildings()`'s own wiring of `is_home_building` off `CityMap.home_block`, rather
## than a fixture set directly.
func _test_a_real_sweep_of_cities_never_shows_a_ground_floor_window(t) -> void:
	var checked_non_home := 0
	var checked_home := 0
	var checked_commercial := 0
	for i in SWEEP_SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 977)
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		for building: Building in city.buildings():
			_check_accessor_invariant(t, building, map.seed_used)
			if building.power_station:
				continue
			if building.is_home_building:
				checked_home += 1
				if building.wall_tiles() >= 2:
					t.check(building._draws_window_at(0),
							"seed %d: her own building keeps its ground-floor window" % map.seed_used)
				continue
			checked_non_home += 1
			if building.wall_tiles() < 2:
				continue
			t.check(not building._draws_window_at(0),
					"seed %d: a multi-story building that is not her own draws no ground-floor window (district %d)"
					% [map.seed_used, building.district])
			if building.district == GameEnums.BlockPurpose.COMMERCIAL and not building._storefront_variant.is_empty():
				checked_commercial += 1
				var texture := building._ground_floor_texture(0)
				t.check(Building.STOREFRONT_TEXTURES.has(texture) or Building.STOREFRONT_AWNING_TEXTURES.has(texture)
						or Building.STOREFRONT_SHUTTERED_TEXTURES.has(texture),
						"seed %d: a real commercial building's storefront is still drawn" % map.seed_used)
		city.free()
	t.check(checked_non_home > 0, "the sweep built non-home buildings to check (%d)" % checked_non_home)
	t.check(checked_home > 0, "the sweep built her own building at least once (%d)" % checked_home)
	t.check(checked_commercial > 0, "the sweep built a commercial storefront at least once (%d)" % checked_commercial)
