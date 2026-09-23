extends RefCounted
## M185's rule: a multi-story building's ground floor is shops or blank wall, never windows,
## except her own. `Building._draws_window_at()` is the one place that decides whether row 0 draws
## a window at all; `_build_windows()`/`_build_front()` still roll exactly the same streams they
## always have, so what changed is only which of their rolls get painted at the ground floor,
## never what the rolls are.

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
