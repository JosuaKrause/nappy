extends RefCounted
## M185's rule: a multi-story building's ground floor is shops or blank wall, never windows,
## except her own. The building decides in one place whether row 0 draws a window at all;
## `_build_windows()`/`_build_front()` still roll exactly the same streams they always have, so what changed is only which of their rolls get painted at the ground floor,
## never what the rolls are. `Building.blank_ground_floor_cells()` is the accessor a later poster
## slice pastes on. A multi-story front with no storefront and no portico has one entrance door,
## rolled from a stream of its own so no other roll moves.
##
## PLAYTEST-124's own finding is the one further exception: the ground-floor column(s) her front
## door's own footprint overlaps draw no window either, even on her own building —
## `Building.door_world_x_range` is the geometry fact `City._spawn_buildings()` hands the building
## for it, and a column the door's footprint overlaps is the one that draws none. A geometry fact, not a roll, so it moves
## no RNG stream — only which of the already-computed windows gets painted where.
##
## A covered column reaches the same columns for the opposite reason: where the tile directly
## south of a non-home front's own column is another building rather than walkable ground
## (`Building.covered_ground_cols`, another geometry fact `City._spawn_buildings()` hands over, read
## off `CityMap.is_walkable()`), that column draws no facade at all — no wall, no window at any
## floor, no storefront, no blank-wall plinth, no door, no portico, no fire escape. The building
## that covers it draws its own roof further north instead, up to exactly the covered building's
## own roof line (`Building.roof_extension_rows`, `City.assign_roof_extensions()`) — roof meets
## roof, so nothing is drawn on a wall nobody can stand in front of. Every roll runs as far on a
## covered front as on an open one (the storefront pair, the portico, the door's own covered filter,
## the fire escape's drop in `_build_front()`); coverage
## decides only which of the answers gets painted, or in the door's case which reachable column it
## lands on. `roof_extension_rows` itself is pure geometry, not a roll.
##
## **Every building here is set up by hand**, the way `City._spawn_buildings()` sets one up. What the
## real city hands its buildings (`is_home_building`, `door_world_x_range`, `covered_ground_cols` and
## the roof rows, off the generated map) is asked of generated cities in `tests/test_city_buildings.gd`.

const RoofReads := preload("res://tests/roof_reads.gd")
const UI := preload("res://tests/ui_screens.gd")
## What a building's front shows, read off the pictures it was drawn with (`tests/front_reads.gd`).
const FrontReads := preload("res://tests/front_reads.gd")

func run(t) -> void:
	await _test_no_ground_floor_window_on_a_multistory_non_home_building(t)
	await _test_commercial_storefronts_remain_and_the_odd_column_is_blank(t)
	await _test_her_own_building_keeps_ground_floor_windows(t)
	await _test_the_door_blanks_only_the_columns_it_covers(t)
	await _test_a_one_row_facade_is_unchanged(t)
	await _test_the_accessor_returns_ground_floor_non_window_non_entrance_cells(t)
	await _test_upper_floor_rolls_are_unchanged_for_a_fixed_seed(t)
	await _test_the_home_flag_changes_no_front_roll(t)
	await _test_a_front_with_no_other_way_in_has_one_door(t)
	await _test_the_door_keeps_clear_of_the_fire_escape(t)
	await _test_a_fire_escape_climbs_every_floor_from_the_first(t)
	await _test_a_home_building_never_carries_a_fire_escape(t)
	await _test_a_two_story_front_rolls_its_escape_and_carries_none(t)
	_test_the_ground_floor_carries_only_the_platform(t)
	await _test_the_front_rolls_replay_their_own_streams(t)
	await _test_a_wide_front_may_carry_a_second_escape_with_the_gap(t)
	await _test_no_second_escape_on_a_front_too_narrow_for_one(t)
	await _test_the_flower_pot_varies_within_one_escape(t)
	await _test_a_covered_column_draws_no_facade_and_an_uncovered_one_is_unchanged(t)
	await _test_the_roof_is_as_tall_as_its_extension_per_column(t)
	await _test_roof_cell_edges_on_both_sides_of_a_seamless_seam_and_an_ordinary_one(t)
	_test_setting_an_extension_late_rebuilds_the_roof_furniture(t)
	await _test_a_shallow_roof_carries_furniture_on_its_extension(t)
	await _test_the_furniture_pool_is_exactly_the_lip_free_interior(t)
	await _test_covered_columns_move_no_storefront_roll(t)
	await _test_the_door_only_lands_on_a_reachable_column(t)
	await _test_a_fully_covered_front_has_no_door(t)
	await _test_a_covered_fire_escape_column_is_dropped_but_the_roll_is_unchanged(t)
	await _test_a_covered_portico_column_drops_the_portico_and_the_front_gets_a_door_instead(t)

# ------------------------------------------------------------------- fixtures ---

## One `Building`, built the way `City._spawn_buildings()` builds one — the exports set, then
## `add_child()`, which is what fires `_ready()` and rolls `_build_windows()`/`_build_front()`.
## `covered` is `Building.covered_ground_cols`, empty by default — the same "nothing in
## front of it" a real front with clear sidewalk south of it reads as.
static func _new_building(t, district: int, footprint: Vector2, height: float, is_home := false,
		position := Vector2.ZERO, covered: Array[bool] = []) -> Building:
	var building := FrontReads.new_building()
	building.district = district
	building.footprint = footprint
	building.height = height
	building.position = position
	building.is_home_building = is_home
	building.covered_ground_cols = covered
	t.add_child(building)
	return building


# ------------------------------------------------------------------- the rule ---

func _test_no_ground_floor_window_on_a_multistory_non_home_building(t) -> void:
	var districts: Array[int] = [GameEnums.BlockPurpose.RESIDENTIAL, GameEnums.BlockPurpose.COMMERCIAL,
			GameEnums.BlockPurpose.INDUSTRIAL, GameEnums.BlockPurpose.CIVIC]
	var buildings: Array[Building] = []
	for district in districts:
		buildings.append(_new_building(t, district, Vector2(96.0, 96.0), 64.0))
	await UI.frames(t, 2)
	for i in districts.size():
		var building := buildings[i]
		var front = FrontReads.look(building)
		t.check(building.wall_tiles() >= 2,
				"the fixture is genuinely multi-story (%d wall rows)" % building.wall_tiles())
		for col in building.columns():
			t.check(front.window_at(col, 0) == &"",
					"district %d: a multi-story non-home building draws no ground-floor window (column %d)"
					% [districts[i], col])
			for row in range(1, building.wall_tiles()):
				t.check(front.window_at(col, row) != &"",
						"district %d: an upper floor still draws its own window (column %d, row %d)"
						% [districts[i], col, row])
		building.free()

func _test_commercial_storefronts_remain_and_the_odd_column_is_blank(t) -> void:
	var building := _new_building(t, GameEnums.BlockPurpose.COMMERCIAL, Vector2(96.0, 96.0), 64.0)
	var front = await _see(t, building)
	t.check(front.ground_floor_at(1) == &"",
			"a three-column facade has one complete storefront pair, whose second column its first holds")
	var storefront_texture: StringName = front.ground_floor_at(0)
	t.check(Building.STOREFRONT_TEXTURES.has(storefront_texture)
			or Building.STOREFRONT_AWNING_TEXTURES.has(storefront_texture),
			"the storefront pair's own ground-floor texture is still a storefront, not blank wall")
	t.check(front.ground_floor_at(2) == Building.WALL_BASE,
			"the odd final column is blank wall rather than a window")
	for col in building.columns():
		t.check(front.window_at(col, 0) == &"",
				"no window is drawn under the ground floor either way (column %d)" % col)
	building.free()

func _test_her_own_building_keeps_ground_floor_windows(t) -> void:
	var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 96.0), 64.0, true)
	var front = await _see(t, building)
	t.check(building.is_home_building, "the fixture is flagged as her own building")
	t.check(building.wall_tiles() >= 2, "the fixture is genuinely multi-story")
	t.check(building.door_world_x_range == Vector2.INF,
			"a building nobody told about a door keeps the empty Vector2.INF sentinel")
	for col in building.columns():
		t.check(front.window_at(col, 0) != &"",
				"her own building's ground floor still draws a window at every column (%d) with no door standing there"
				% col)
	building.free()

## A door 26px wide against a 32px `Building.TILE` column may straddle two of them — set here dead
## on the boundary between columns 2 and 3, so both blank and every other column keeps its window.
func _test_the_door_blanks_only_the_columns_it_covers(t) -> void:
	var position := Vector2(500.0, 700.0)
	var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(160.0, 96.0), 64.0, true, position)
	var boundary := building.global_position.x - building.columns() * Building.TILE * 0.5 \
			+ 3 * Building.TILE
	building.door_world_x_range = Vector2(boundary - 3.0, boundary + 3.0)
	var front = await _see(t, building)
	for col in building.columns():
		var under_door := col == 2 or col == 3
		t.check((front.window_at(col, 0) != &"") != under_door,
				"column %d: a window is drawn iff the door does not stand there" % col)
	building.free()

func _test_a_one_row_facade_is_unchanged(t) -> void:
	var buildings: Array[Building] = []
	for is_home in [false, true]:
		buildings.append(_new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 32.0), 32.0, is_home))
	await UI.frames(t, 2)
	for building in buildings:
		var front = FrontReads.look(building)
		t.check(building.wall_tiles() == 1, "the fixture is genuinely one row tall (%d)" % building.wall_tiles())
		t.check(front.window_at(0, 0) != &"",
				"a one-row facade is not multi-story, so it keeps its window regardless of the home flag (home=%s)"
				% building.is_home_building)
		building.free()

# ---------------------------------------------------------------- the accessor ---

func _test_the_accessor_returns_ground_floor_non_window_non_entrance_cells(t) -> void:
	# CIVIC, an odd column count: the portico lands on exactly the one middle column.
	var civic_odd := _new_building(t, GameEnums.BlockPurpose.CIVIC, Vector2(96.0, 96.0), 64.0)
	var odd_entrance: Array[int] = (await _see(t, civic_odd)).portico_cols()
	t.check(odd_entrance.size() == 1, "an odd-width civic front's portico lands on one column (%d)" % odd_entrance.size())
	var odd_cells := civic_odd.blank_ground_floor_cells()
	t.check(odd_cells.size() == civic_odd.columns() - odd_entrance.size(),
			"a civic front's blank cells are every ground-floor column but the portico's (%d of %d)"
			% [odd_cells.size(), civic_odd.columns()])
	civic_odd.free()

	# CIVIC, an even column count: the portico straddles the two middle columns instead of landing
	# on one exactly.
	var civic_even := _new_building(t, GameEnums.BlockPurpose.CIVIC, Vector2(128.0, 96.0), 64.0)
	var even_entrance: Array[int] = (await _see(t, civic_even)).portico_cols()
	t.check(even_entrance.size() == 2,
			"an even-width civic front's portico straddles two columns (%d)" % even_entrance.size())
	var even_cells := civic_even.blank_ground_floor_cells()
	t.check(even_cells.size() == civic_even.columns() - even_entrance.size(),
			"an even-width civic front excludes both columns the portico straddles (%d of %d)"
			% [even_cells.size(), civic_even.columns()])
	civic_even.free()

	# COMMERCIAL: the storefront pair's own columns are never blank; the odd final column is.
	var commercial := _new_building(t, GameEnums.BlockPurpose.COMMERCIAL, Vector2(96.0, 96.0), 64.0)
	await UI.frames(t, 2)
	var commercial_cells := commercial.blank_ground_floor_cells()
	t.check(commercial_cells.size() == 1,
			"a three-column commercial front has exactly one blank cell, the odd final column (%d)"
			% commercial_cells.size())
	if not commercial_cells.is_empty():
		var odd_col_cell := GroundFloorChecks.ground_cell(commercial, 2)
		t.check(commercial_cells[0] == odd_col_cell, "the one blank cell is exactly the odd final column")
	commercial.free()

	# Every returned cell is ground-floor (row 0's own y) and exactly one tile, and neither the
	# door's column nor the one the fire escape stands against is among them.
	var residential := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 96.0), 64.0)
	var shown = await _see(t, residential)
	var residential_cells := residential.blank_ground_floor_cells()
	var excluded := {shown.door_col(): true}
	for escape_col in shown.escape_cols():
		excluded[escape_col] = true
	t.check(shown.door_col() >= 0, "the residential fixture has a door")
	t.check(residential_cells.size() == residential.columns() - excluded.size(),
			"a residential front is blank across every column but its door's and its fire escape's (%d of %d)"
			% [residential_cells.size(), residential.columns()])
	for cell in residential_cells:
		t.check(not excluded.has(GroundFloorChecks.col_of(residential, cell)),
				"no accessor cell is the door's column or the fire escape's")
	var ground_row_y := GroundFloorChecks.ground_cell(residential, 0).position.y
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

## Replays `_build_windows()`'s own RNG stream and the window style match, using only
## the public consts the windows are drawn with — never the private `_WindowStyle` enum —
## so this pins the *behaviour* `main` already has rather than an implementation detail of it. Run
## for both a home and a non-home building at the same seed, since the rule change reads
## `is_home_building` only in which cells draw a window and must not have touched this roll at all.
func _test_upper_floor_rolls_are_unchanged_for_a_fixed_seed(t) -> void:
	var buildings: Array[Building] = []
	for is_home in [false, true]:
		buildings.append(_new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 96.0), 64.0,
				is_home, Vector2(4321.0, 9876.0)))
	await UI.frames(t, 2)
	for building in buildings:
		var front = FrontReads.look(building)
		var is_home := building.is_home_building
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
		for row in building.wall_tiles():
			for col in building.columns():
				var index := row * building.columns() + col
				var expected: StringName = expected_lit_texture if expected_lit[index] else expected_dark
				if row == 0 and not is_home:
					expected = &""
				t.check(front.window_at(col, row) == expected,
						"home=%s index %d: the window roll and style match _build_windows()'s own stream"
						% [is_home, index])
		building.free()

## `_build_front()`'s own seed string never mentions `is_home_building`, so two otherwise-identical
## buildings — one flagged hers, one not — roll the exact same storefront bag, awning and
## ambient-shutter values (checked directly, since `tests/test_city_decay.gd` already pins what the
## stream itself produces), and the exact same fire-escape roll — whether one exists and its column
## — replayed by hand below the way `_test_a_two_story_front_rolls_its_escape_and_carries_none`
## replays it. What the flag changes (M100, `docs/TODO.md`: "the home block carries no fire
## escape") is only whether the rolled column is *kept*: her own building drops it — she has a
## stair inside instead — so its `_fire_escape_cols` stays empty and `_build_fire_escape_extras()`'s
## own `escape:` stream never runs, while a non-home front at the same seed keeps exactly what the
## replay below predicts.
func _test_the_home_flag_changes_no_front_roll(t) -> void:
	var shared_position := Vector2(1234.0, 5678.0)
	var plain := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 128.0), 96.0, false, shared_position)
	var home := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 128.0), 96.0, true, shared_position)
	await UI.frames(t, 2)
	var plain_front = FrontReads.look(plain)
	var home_front = FrontReads.look(home)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("front:%d:%d:%d" % [plain.variant, int(plain.global_position.x), int(plain.global_position.y)])
	var expected_cols: Array[int] = []
	if plain.wall_tiles() >= 2 and rng.randf() < Building.FIRE_ESCAPE_SHARE:
		var cols := plain.columns()
		var first_col := rng.randi_range(1, cols - 2) if cols >= 3 else rng.randi_range(0, cols - 1)
		if plain.wall_tiles() >= Building.FIRE_ESCAPE_MIN_WALL_ROWS:
			expected_cols.append(first_col)
	t.check(plain_front.escape_cols() == expected_cols,
			"a non-home front keeps exactly the column its own roll produced (%s, expected %s)"
			% [plain_front.escape_cols(), expected_cols])
	t.check(home_front.escape_cols().is_empty(),
			"her own building never keeps a fire escape, even though its roll runs the same way (%s)"
			% [home_front.escape_cols()])
	t.check(home_front.balcony_count() == 0,
			"her own building never rolls the escape's own pot/second-escape stream either, since its escape columns stay empty")
	plain.free()
	home.free()

	var commercial_plain := _new_building(t, GameEnums.BlockPurpose.COMMERCIAL, Vector2(96.0, 96.0), 64.0,
			false, shared_position)
	var commercial_home := _new_building(t, GameEnums.BlockPurpose.COMMERCIAL, Vector2(96.0, 96.0), 64.0,
			true, shared_position)
	var buildings: Array[Building] = [commercial_plain, commercial_home]
	var drawn := await _ground_floors_over_the_run(t, buildings)
	var drawn_plain: Array[StringName] = drawn[0]
	t.check(Building.STOREFRONT_TEXTURES.has(drawn_plain[0])
			or Building.STOREFRONT_AWNING_TEXTURES.has(drawn_plain[0]),
			"the commercial fixture draws a storefront to compare")
	t.check(drawn_plain == drawn[1],
			"the home flag changes nothing about the storefront bag, awning or ambient-shutter rolls: "
			+ "the same ground floor is drawn on every day of the run")
	commercial_plain.free()
	commercial_home.free()


## What the ground floor shows for `col` of a lived-in commercial front of `columns`
## columns on `day`, from the rolls its storefronts were replayed to: a pair's first column its
## storefront, plain or awning or, once the day's decay has passed its fixed severity, shuttered; the
## second column of a pair nothing; an odd last column plain wall.
static func _replayed_storefront(columns: int, col: int, variants: Array[int], awnings: Array[bool],
		severities: Array[float], day: int) -> StringName:
	if col % 2 == 1:
		return &""
	if col + 1 >= columns:
		return Building.WALL_BASE
	var store := col / 2
	if severities[store] < Tuning.degradation_for(day) * Building.AMBIENT_SHUTTER_SHARE:
		return Building.STOREFRONT_SHUTTERED_TEXTURES[variants[store]]
	return Building.STOREFRONT_AWNING_TEXTURES[variants[store]] if awnings[store] \
			else Building.STOREFRONT_TEXTURES[variants[store]]

## The ground floor each of `buildings` draws on each day of the run in turn, left at day 1: per
## building, the picture each column shows (`&""` where none), day after day, which is the whole of
## what the `front:` stream rolled for a shop (the storefront each pair shows, awning or not, and the
## day its fixed severity shutters it).
func _ground_floors_over_the_run(t, buildings: Array[Building]) -> Array[Array]:
	var drawn: Array[Array] = []
	for building in buildings:
		var none: Array[StringName] = []
		drawn.append(none)
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		for building in buildings:
			building.day = day
		await UI.frames(t, 2)
		for i in buildings.size():
			var front = FrontReads.look(buildings[i])
			for col in buildings[i].columns():
				drawn[i].append(front.ground_floor_at(col))
	for building in buildings:
		building.day = 1
	return drawn



## `{col: {row: has_pot}}` for every balcony `front` draws, over every column and floor line: the
## whole of it, so a balcony drawn for a column or a floor line it should not have shows too.
static func _pots_of(front) -> Dictionary:
	var pots := {}
	var balconies: Dictionary = front.balconies()
	for col: int in balconies:
		pots[col] = {}
		for row: int in balconies[col]:
			var picture: StringName = balconies[col][row]
			pots[col][row] = picture == Building.FIRE_ESCAPE_A or picture == Building.FIRE_ESCAPE_PLATFORM_A
	return pots



## The rows the roof is taller than the building's own at column `col`, as `City` sets them
## (`Building.roof_extension_rows`), 0 where it sets none.
static func _extension_of(building: Building, col: int) -> int:
	return building.roof_extension_rows[col] if col >= 0 and col < building.roof_extension_rows.size() else 0


## The reads of `building`'s front once it has been drawn: two frames pass first.
func _see(t, building: Building):
	await UI.frames(t, 2)
	return FrontReads.look(building)

# ------------------------------------------------------------------- the door ---

## One door on every multi-story front that has no other way in, and none anywhere else: a
## storefront is a commercial front's way in, the portico a civic front's, her own block keeps its
## windows and her own door, a one-row facade keeps its windows, and the power station draws its
## own. A one-column commercial front is too narrow for a storefront, so it is the one commercial
## front with a door.
func _test_a_front_with_no_other_way_in_has_one_door(t) -> void:
	var cases := [
		[GameEnums.BlockPurpose.RESIDENTIAL, Vector2(160.0, 96.0), 64.0, false, true, Building.ENTRANCE_DOOR],
		[GameEnums.BlockPurpose.INDUSTRIAL, Vector2(160.0, 96.0), 64.0, false, true, Building.ENTRANCE_DOOR_INDUSTRIAL],
		[GameEnums.BlockPurpose.COMMERCIAL, Vector2(32.0, 96.0), 64.0, false, true, Building.ENTRANCE_DOOR],
		[GameEnums.BlockPurpose.COMMERCIAL, Vector2(128.0, 96.0), 64.0, false, false, &""],
		[GameEnums.BlockPurpose.CIVIC, Vector2(160.0, 96.0), 64.0, false, false, &""],
		[GameEnums.BlockPurpose.RESIDENTIAL, Vector2(160.0, 96.0), 64.0, true, false, &""],
		[GameEnums.BlockPurpose.INDUSTRIAL, Vector2(160.0, 32.0), 32.0, false, false, &""],
	]
	var buildings: Array[Building] = []
	for case in cases:
		buildings.append(_new_building(t, case[0], case[1], case[2], case[3]))
	var station := _new_building(t, GameEnums.BlockPurpose.INDUSTRIAL, Vector2(160.0, 256.0), 64.0)
	station.power_station = true
	await UI.frames(t, 2)
	for i in cases.size():
		var case: Array = cases[i]
		var building := buildings[i]
		var front = FrontReads.look(building)
		var col: int = front.door_col()
		var label := "district %d, %d columns, %d wall rows, home=%s" % [case[0], building.columns(),
				building.wall_tiles(), case[3]]
		if case[4]:
			t.check(col >= 0 and col < building.columns(), "%s: has one door on its own front (%d)" % [label, col])
			t.check(front.door_picture() == case[5], "%s: draws the right door picture" % label)
		else:
			t.check(col == -1, "%s: has no entrance door (%d)" % [label, col])
		building.free()
	t.check(FrontReads.look(station).door_col() == -1, "the power station draws its own door, not this one")
	station.free()

## Every fire escape's landings reach into both neighbouring columns at the ground floor, so the
## door never stands on any escape's column or beside it where the front has any other column to
## offer — one escape or two.
func _test_the_door_keeps_clear_of_the_fire_escape(t) -> void:
	var with_escape := 0
	var with_two_escapes := 0
	var buildings: Array[Building] = []
	for i in 400:
		var cols := 3 + i % 10
		buildings.append(_new_building(t, GameEnums.BlockPurpose.RESIDENTIAL,
				Vector2(cols * Building.TILE, 128.0), 96.0, false, Vector2(i * 37.0, i * 53.0)))
	await UI.frames(t, 2)
	for building in buildings:
		var front = FrontReads.look(building)
		var cols := building.columns()
		var door: int = front.door_col()
		var escapes: Array[int] = front.escape_cols()
		if not escapes.is_empty():
			with_escape += 1
			if escapes.size() >= 2:
				with_two_escapes += 1
			for escape in escapes:
				t.check(door != escape, "the door is never under a fire escape (%d columns)" % cols)
				if cols >= 4:
					t.check(absi(door - escape) > 1,
							"with room to spare, the door is not beside a fire escape either (%d columns, door %d, escape %d)"
							% [cols, door, escape])
		else:
			t.check(door >= 1 and door <= cols - 2,
					"with no fire escape to avoid, the door stays off the corner columns (%d of %d)" % [door, cols])
		building.free()
	t.check(with_escape > 20, "the sweep met enough fire escapes to mean something (%d)" % with_escape)
	t.check(with_two_escapes > 0, "the sweep met a front wide enough to also test a second escape (%d)" % with_two_escapes)

# ------------------------------------------------------------- the fire escape ---


## Fronts of every height the class can build, two to six wall rows, across a spread of lots: an
## escape reaches every floor of a front of three or more, and a front of two never has one.
func _test_a_fire_escape_climbs_every_floor_from_the_first(t) -> void:
	var escapes_by_rows := {}
	var buildings: Array[Building] = []
	var rows_of: Array[int] = []
	for i in 300:
		var wall_rows := 2 + i % 5
		rows_of.append(wall_rows)
		buildings.append(_new_building(t, GameEnums.BlockPurpose.RESIDENTIAL,
				Vector2((3 + i % 4) * Building.TILE, (wall_rows + 2) * Building.TILE), wall_rows * Building.TILE,
				false, Vector2(i * 41.0, i * 67.0)))
	await UI.frames(t, 2)
	for i in buildings.size():
		if GroundFloorChecks.check_fire_escape(t, FrontReads.look(buildings[i]), "fixture %d, %d wall rows" % [i, rows_of[i]]):
			escapes_by_rows[rows_of[i]] = int(escapes_by_rows.get(rows_of[i], 0)) + 1
		buildings[i].free()
	t.check(not escapes_by_rows.has(2), "a two-story front never carries a fire escape (%s)" % escapes_by_rows)
	for wall_rows in [3, 4, 5, 6]:
		t.check(int(escapes_by_rows.get(wall_rows, 0)) > 0,
				"the sweep met a fire escape on a front of %d wall rows (%s)" % [wall_rows, escapes_by_rows])

## M100 (`docs/TODO.md`, "the home block carries no fire escape"; the player, PLAYTEST-128.md: "the
## home building shouldn't have a fire escape (it has a double staircase inside)"): across a sweep
## of seeds wide enough to roll several escapes on a non-home front at the same position, her own
## building never keeps one, even on a front tall and wide enough for two.
func _test_a_home_building_never_carries_a_fire_escape(t) -> void:
	var plain_escapes := 0
	var plains: Array[Building] = []
	var homes: Array[Building] = []
	for i in 200:
		var wall_rows := 3 + i % 4
		var cols := 3 + i % 6
		var footprint := Vector2(cols * Building.TILE, (wall_rows + 2) * Building.TILE)
		var height := wall_rows * Building.TILE
		var at := Vector2(i * 71.0, i * 97.0)
		plains.append(_new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, footprint, height, false, at))
		homes.append(_new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, footprint, height, true, at))
	await UI.frames(t, 2)
	for i in plains.size():
		var plain_front = FrontReads.look(plains[i])
		var home_front = FrontReads.look(homes[i])
		if not plain_front.escape_cols().is_empty():
			plain_escapes += 1
		t.check(home_front.escape_cols().is_empty(),
				"seed %d: her own building carries no fire escape (%s wall rows, %s columns)"
				% [i, homes[i].wall_tiles(), homes[i].columns()])
		t.check(home_front.balcony_count() == 0,
				"seed %d: her own building draws no fire-escape balcony, and rolls no pot or second escape either" % i)
		plains[i].free()
		homes[i].free()
	t.check(plain_escapes > 20,
			"the sweep met enough fire escapes on non-home fronts to mean something (%d)" % plain_escapes)

## A two-row front still rolls `_build_front()`'s fire-escape roll where a taller one does, so the
## `front:` stream is consumed the same way on every front of two rows or more; the front then
## carries none, and rolls no pots or second escape either, since `_build_fire_escape_extras()` only
## ever runs once `_fire_escape_cols` already holds the first. Replayed the way
## `_test_the_front_rolls_replay_their_own_streams` replays it.
func _test_a_two_story_front_rolls_its_escape_and_carries_none(t) -> void:
	var rolled := 0
	var buildings: Array[Building] = []
	for i in 60:
		var at := Vector2(3000.0 + i * 96.0, 1000.0 + i * 64.0)
		buildings.append(_new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(160.0, 128.0), 64.0, false, at))
	await UI.frames(t, 2)
	for i in buildings.size():
		var building := buildings[i]
		var at := Vector2(3000.0 + i * 96.0, 1000.0 + i * 64.0)
		t.check(building.wall_tiles() == 2, "fixture %d is two stories (%d)" % [i, building.wall_tiles()])
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("front:%d:%d:%d" % [building.variant, int(at.x), int(at.y)])
		if rng.randf() < Building.FIRE_ESCAPE_SHARE:
			rolled += 1
			rng.randi_range(1, building.columns() - 2)
		t.check(FrontReads.look(building).balcony_count() == 0,
				"fixture %d: a two-story front carries no fire escape, nor rolls pots for one" % i)
		building.free()
	t.check(rolled > 0, "the replay met a two-story front that rolled an escape (%d)" % rolled)

## The ground floor under an escape is the lower half of the platform picture and nothing else, so
## what the platform picture puts below its brackets is what an escape puts on the sidewalk: read
## off the baked page, the pixels the game draws. The stair picture's flight does reach that low,
## which is what makes the platform a picture of its own rather than the stair cut short.
func _test_the_ground_floor_carries_only_the_platform(t) -> void:
	var page := AtlasLibrary.new().page_image(&"buildings")
	t.check(page != null, "the baked buildings page reads back as an image")
	if page == null:
		return
	var pairs := [[Building.FIRE_ESCAPE_PLATFORM_A, Building.FIRE_ESCAPE_A],
			[Building.FIRE_ESCAPE_PLATFORM_B, Building.FIRE_ESCAPE_B]]
	for pair: Array in pairs:
		var platform := AtlasTable.baked().region_rect(pair[0])
		var stair := AtlasTable.baked().region_rect(pair[1])
		t.check(platform.size == stair.size and platform.size.y == 2 * int(Building.TILE),
				"%s registers with %s, two floors tall (%s, %s)" % [pair[0], pair[1], platform.size, stair.size])
		# The lower half of the ground floor: below the brackets, where the sidewalk's people stand.
		var from_row := platform.size.y - int(Building.TILE) / 2
		t.check(_opaque_rows(page, platform, from_row) == 0,
				"%s puts nothing on the lower half of the ground floor" % pair[0])
		t.check(_opaque_rows(page, stair, from_row) > 0,
				"%s's flight does reach that low, so the platform is what keeps it off the ground floor" % pair[1])

## How many of `rect`'s rows from `from_row` down hold a pixel that is not fully transparent.
static func _opaque_rows(page: Image, rect: Rect2i, from_row: int) -> int:
	var rows := 0
	for y in range(from_row, rect.size.y):
		for x in rect.size.x:
			if page.get_pixel(rect.position.x + x, rect.position.y + y).a > 0.0:
				rows += 1
				break
	return rows

## Every stream `Building` rolls, replayed from its own seed for fixed fixtures: the windows (lit and
## style, `_test_upper_floor_rolls_are_unchanged_for_a_fixed_seed` above), the fire escape and the
## storefronts from `_build_front()`'s `front:` seed, the escape's own extras (pots, second escape)
## from `_build_fire_escape_extras()`'s `escape:` seed, and the door from `_build_entrance()`'s
## `door:` seed. Each stream is keyed on its own prefix and read by nothing else, so the door and the
## escape's extras each add a roll without moving any other; a replay that still matches after both
## exist is the proof.
func _test_the_front_rolls_replay_their_own_streams(t) -> void:
	var escapes_seen := 0
	var buildings: Array[Building] = []
	for i in 40:
		var at := Vector2(1000.0 + i * 96.0, 2000.0 + i * 64.0)
		buildings.append(_new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(192.0, 128.0), 96.0, false, at))
	var shop_at := Vector2(4096.0, 3072.0)
	var shop := _new_building(t, GameEnums.BlockPurpose.COMMERCIAL, Vector2(256.0, 128.0), 96.0, false, shop_at)
	# The door's roll is unused while a storefront draws, so it is read on the same front with the
	# odd columns covered: no pair draws, and the front draws a door.
	var odd_covered: Array[bool] = []
	for col in 8:
		odd_covered.append(col % 2 == 1)
	var doored := _new_building(t, GameEnums.BlockPurpose.COMMERCIAL, Vector2(256.0, 128.0), 96.0, false, shop_at,
			odd_covered)
	await UI.frames(t, 2)
	for i in buildings.size():
		var building := buildings[i]
		var front = FrontReads.look(building)
		var at := Vector2(1000.0 + i * 96.0, 2000.0 + i * 64.0)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("front:%d:%d:%d" % [building.variant, int(at.x), int(at.y)])
		var expected_col := -1
		if rng.randf() < Building.FIRE_ESCAPE_SHARE:
			expected_col = rng.randi_range(1, building.columns() - 2)
			escapes_seen += 1
		# A wide enough front may also roll a second escape from its own `escape:` stream, which is not
		# what this comparison is about.
		t.check(front.escape_cols().has(expected_col) if expected_col >= 0 else front.escape_cols().is_empty(),
				"fixture %d: the fire-escape roll is its own stream" % i)
		t.check(front.door_col() >= 0, "fixture %d: the front draws a door" % i)
		building.free()
	t.check(escapes_seen > 0, "the replay met a fire escape (%d)" % escapes_seen)

	var shop_rng := RandomNumberGenerator.new()
	shop_rng.seed = hash("front:%d:%d:%d" % [shop.variant, int(shop_at.x), int(shop_at.y)])
	var bag: Array[int] = []
	var previous := -1
	var variants: Array[int] = []
	var awnings: Array[bool] = []
	var severities: Array[float] = []
	for col in range(0, shop.columns() - 1, 2):
		if bag.is_empty():
			for index in Building.STOREFRONT_TEXTURES.size():
				bag.append(index)
			for index in range(bag.size() - 1, 0, -1):
				var swap_index := shop_rng.randi_range(0, index)
				var swapped := bag[index]
				bag[index] = bag[swap_index]
				bag[swap_index] = swapped
			if previous >= 0 and bag.size() > 1 and bag[0] == previous:
				var swapped := bag[0]
				bag[0] = bag[1]
				bag[1] = swapped
		variants.append(bag.pop_front())
		previous = variants[-1]
		awnings.append(shop_rng.randf() < Building.STOREFRONT_AWNING_SHARE)
		severities.append(shop_rng.randf())
	var expected: Array[StringName] = []
	for d in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		for col in shop.columns():
			expected.append(_replayed_storefront(shop.columns(), col, variants, awnings, severities, d))
	t.check(Building.STOREFRONT_TEXTURES.has(expected[0]) or Building.STOREFRONT_AWNING_TEXTURES.has(expected[0]),
			"the replay has a storefront to compare")
	var shop_buildings: Array[Building] = [shop]
	var shop_drawn: Array[StringName] = (await _ground_floors_over_the_run(t, shop_buildings))[0]
	t.check(shop_drawn == expected,
			"the storefront bag, awning and ambient-shutter rolls are `_build_front()`'s own stream: "
			+ "the replayed ground floor is drawn on every day of the run")
	shop.free()
	var doored_front = FrontReads.look(doored)
	var shop_cols := 0
	for col in doored.columns():
		var picture: StringName = doored_front.ground_floor_at(col)
		shop_cols += int(picture != &"" and picture != Building.WALL_BASE)
	t.check(shop_cols == 0 and doored_front.door_col() >= 0,
			"a commercial front with no storefront drawn has a door of its own")
	doored.free()

## A front wide enough for two escapes (`Building.SECOND_FIRE_ESCAPE_MIN_COLUMNS`, 7 columns) may
## carry a second one, and every one the sweep meets keeps the minimum gap
## (`Building.FIRE_ESCAPE_GAP_COLUMNS`, 4 columns centre to centre) and stays off the corner columns
## — the same checks `GroundFloorChecks.check_fire_escape()` already runs, asked again with a sweep built to meet the
## case reliably.
func _test_a_wide_front_may_carry_a_second_escape_with_the_gap(t) -> void:
	var with_two := 0
	var buildings: Array[Building] = []
	for i in 500:
		var cols := 7 + i % 8
		buildings.append(_new_building(t, GameEnums.BlockPurpose.RESIDENTIAL,
				Vector2(cols * Building.TILE, 224.0), 160.0, false, Vector2(i * 71.0, i * 97.0)))
	await UI.frames(t, 2)
	for i in buildings.size():
		var cols := buildings[i].columns()
		var escapes: Array[int] = FrontReads.look(buildings[i]).escape_cols()
		if escapes.size() == 2:
			with_two += 1
			t.check(absi(escapes[0] - escapes[1]) >= Building.FIRE_ESCAPE_GAP_COLUMNS,
					"fixture %d: two escapes on a %d-column front keep the minimum gap (%s)" % [i, cols, escapes])
			for col in escapes:
				t.check(col > 0 and col < cols - 1,
						"fixture %d: escape at column %d of %d keeps off the corner columns" % [i, col, cols])
		buildings[i].free()
	t.check(with_two > 0, "the sweep met a front that carries two fire escapes (%d)" % with_two)

## Nothing under `Building.SECOND_FIRE_ESCAPE_MIN_COLUMNS` (7 columns) ever carries a second escape:
## the interior range `[1, cols - 2]` a narrower front rolls from is not wide enough to fit two
## columns `Building.FIRE_ESCAPE_GAP_COLUMNS` apart.
func _test_no_second_escape_on_a_front_too_narrow_for_one(t) -> void:
	var with_escape := 0
	var buildings: Array[Building] = []
	for i in 400:
		var cols := 3 + i % (Building.SECOND_FIRE_ESCAPE_MIN_COLUMNS - 3)
		t.check(cols < Building.SECOND_FIRE_ESCAPE_MIN_COLUMNS,
				"fixture %d: the fixture itself stays under the width a second escape needs (%d)" % [i, cols])
		buildings.append(_new_building(t, GameEnums.BlockPurpose.RESIDENTIAL,
				Vector2(cols * Building.TILE, 224.0), 160.0, false, Vector2(i * 83.0, i * 101.0)))
	await UI.frames(t, 2)
	for i in buildings.size():
		var escapes: Array[int] = FrontReads.look(buildings[i]).escape_cols()
		if not escapes.is_empty():
			with_escape += 1
		t.check(escapes.size() <= 1,
				"fixture %d: a %d-column front never carries two fire escapes" % [i, buildings[i].columns()])
		buildings[i].free()
	t.check(with_escape > 20, "the sweep met enough narrow fronts with a fire escape to mean something (%d)" % with_escape)

## The potted-plant picture is rolled balcony by balcony (`Building.FIRE_ESCAPE_POT_SHARE`), so a
## tall enough escape mixes both pictures across its own landings rather than showing the same one
## on every floor. Swept rather than asserted of one fixture, since which building shows the mix is
## itself a roll.
func _test_the_flower_pot_varies_within_one_escape(t) -> void:
	var mixed_seen := 0
	var buildings: Array[Building] = []
	for i in 300:
		buildings.append(_new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 256.0), 192.0,
				false, Vector2(i * 59.0, i * 131.0)))
	await UI.frames(t, 2)
	for building in buildings:
		var front = FrontReads.look(building)
		var pots := _pots_of(front)
		for col in front.escape_cols():
			var values: Array = (pots[col] as Dictionary).values()
			if values.has(true) and values.has(false):
				mixed_seen += 1
		building.free()
	t.check(mixed_seen > 0, "the sweep met an escape whose balconies do not all show the same pot roll (%d)" % mixed_seen)

# ------------------------------------------------------------------------ covered columns ---

## The rule stated directly: a covered column draws no facade at all, not even a window row, and
## an uncovered column of the same front keeps its ground floor, since this fixture is
## `RESIDENTIAL` with no door rolled onto either uncovered column (checked below).
## `_draw()`'s own wall loop skips a
## covered column's whole cell, so a covered column shows no window at any floor.
func _test_a_covered_column_draws_no_facade_and_an_uncovered_one_is_unchanged(t) -> void:
	var covered: Array[bool] = [true, false, true, false]
	var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(4 * Building.TILE, 96.0),
			64.0, false, Vector2(5555.0, 6666.0), covered)
	var front = await _see(t, building)
	t.check(building.wall_tiles() >= 2, "the fixture is genuinely multi-story")
	for col in building.columns():
		t.check(front.window_at(col, 0) == &"",
				"column %d: no ground-floor window is drawn, covered or not" % col)
	for col in [0, 2]:
		t.check(not front.facade_drawn_in(col),
				"column %d: a covered column draws no facade at all, wall, window, shop or door" % col)
	for col in [1, 3]:
		for row in range(1, building.wall_tiles()):
			t.check(front.window_at(col, row) != &"",
					"column %d row %d: an uncovered column still draws its upper floor's window" % [col, row])
		if col != front.door_col():
			t.check(front.ground_floor_at(col) == Building.WALL_BASE,
					"column %d: an uncovered column of the same front keeps its plain-wall ground floor" % col)
	building.free()

## `roof_extension_rows` is a geometry fact the city hands each building, per column: a column's
## roof is drawn that many rows taller than the building's own, and a building nobody told about one
## draws only its own roof.
func _test_the_roof_is_as_tall_as_its_extension_per_column(t) -> void:
	var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(4 * Building.TILE, 96.0), 64.0)
	var plain = await _see(t, building)
	for col in building.columns():
		t.check(plain.roof_rows_at(col) == building.roof_tiles(),
				"column %d: a building nobody told about an extension draws only its own roof" % col)
	var extension: Array[int] = [0, 3, 0, 5]
	building.roof_extension_rows = extension
	var extended = await _see(t, building)
	for col in building.columns():
		t.check(extended.roof_rows_at(col) == building.roof_tiles() + extension[col],
				"column %d: the roof is drawn as many rows taller as its extension says" % col)
	building.free()


## The lips a roof cell is drawn with, read off the pictures. A front
## five rows deep with two wall rows has three roof rows of its own; columns 1 and 2 extend two rows
## further north, column 1 seamlessly (into another piece of its own courtyard) and column 2 into a
## separate building. The covered piece's first roof row is asked on both kinds of seam as well.
func _test_roof_cell_edges_on_both_sides_of_a_seamless_seam_and_an_ordinary_one(t) -> void:
	var front_building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL,
			Vector2(4 * Building.TILE, 5 * Building.TILE), 64.0)
	t.check(front_building.roof_tiles() == 3, "the fixture front has three roof rows of its own")
	front_building.roof_extension_rows = [0, 2, 2, 0]
	front_building.roof_extension_seamless = [false, true, false, false]
	var covered: Array[bool] = [true, true]
	var back_building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL,
			Vector2(2 * Building.TILE, 4 * Building.TILE), 64.0, false, Vector2.ZERO, covered)
	back_building.seamless_cover_cols = [true, false]
	await UI.frames(t, 2)
	var front = FrontReads.look(front_building)
	var back = FrontReads.look(back_building)
	var roof := front_building.roof_tiles()
	var top := roof + 2 - 1
	var n := Building.ROOF_EDGE_BIT_N
	var s := Building.ROOF_EDGE_BIT_S
	var w := Building.ROOF_EDGE_BIT_W
	var e := Building.ROOF_EDGE_BIT_E
	t.check((front.roof_edges_at(1, top) & n) == 0,
			"the covering side of a seamless seam draws no north lip at the extension's top")
	t.check((front.roof_edges_at(2, top) & n) != 0,
			"the covering side of an ordinary seam still caps its extension with a north lip")
	t.check((front.roof_edges_at(0, roof - 1) & n) != 0,
			"an unextended column still caps its own roof")
	t.check((front.roof_edges_at(1, roof) & w) != 0,
			"an extended column steps down beside a shorter neighbour with a side lip")
	t.check((front.roof_edges_at(1, roof) & e) == 0,
			"two equally extended columns side by side draw no lip between them")
	t.check((front.roof_edges_at(2, roof) & e) != 0,
			"the other end of the extension steps down too")
	for col in front_building.columns():
		t.check((front.roof_edges_at(col, 0) & s) != 0,
				"column %d: a front covering something keeps its own front lip" % col)
	t.check(not front.roof_cell_drawn(0, roof), "no roof is drawn past a column's roof")
	t.check((back.roof_edges_at(0, 0) & s) == 0,
			"the covered side of a seamless seam draws no front lip: its roof carries on south")
	t.check((back.roof_edges_at(1, 0) & s) != 0,
			"the covered side of an ordinary seam keeps its front lip over the roof in front")
	front_building.free()
	back_building.free()

## The roof furniture reads `roof_extension_rows`, so a value set after the building is in the tree
## rolls the same roof as one set before it — the setter rebuilds rather than only redrawing.
func _test_setting_an_extension_late_rebuilds_the_roof_furniture(t) -> void:
	var footprint := Vector2(6 * Building.TILE, 7 * Building.TILE)
	var at := Vector2(4321.0, 8765.0)
	var early := Building.new()
	early.district = GameEnums.BlockPurpose.INDUSTRIAL
	early.footprint = footprint
	early.height = 64.0
	early.position = at
	early.roof_extension_rows = [0, 4, 4, 4, 4, 0]
	t.add_child(early)
	var late := _new_building(t, GameEnums.BlockPurpose.INDUSTRIAL, footprint, 64.0, false, at)
	late.roof_extension_rows = [0, 4, 4, 4, 4, 0]
	t.check(not RoofReads.units_of(early).is_empty() and RoofReads.units_of(late) == RoofReads.units_of(early),
			"an extension set after entering the tree rolls the same furniture as one set before")
	var on_extension := 0
	for unit: Dictionary in RoofReads.units_of(early):
		if (unit["cell"] as Vector2i).y >= early.roof_tiles():
			on_extension += 1
	t.check(on_extension > 0, "the fixture's furniture reaches onto the extension (%d)" % on_extension)
	early.free()
	late.free()

## A roof too shallow for an interior cell of its own carries units once its extension gives it
## one: the furniture gate reads the tallest column, extension included, rather than the
## building's own roof depth. The same building with nothing to cover stays bare.
func _test_a_shallow_roof_carries_furniture_on_its_extension(t) -> void:
	var footprint := Vector2(6 * Building.TILE, 4 * Building.TILE)
	var at := Vector2(2468.0, 1357.0)
	var bare := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, footprint, 64.0, false, at)
	t.check(bare.roof_tiles() < 3,
			"the fixture's own roof is too shallow for an interior cell (%d rows)" % bare.roof_tiles())
	t.check(RoofReads.units_of(bare).is_empty(),
			"with nothing to cover, the shallow roof has no pool and carries nothing")
	var covering := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, footprint, 64.0, false, at)
	covering.roof_extension_rows = [0, 2, 4, 4, 2, 0]
	var front = await _see(t, covering)
	t.check(RoofReads.tallest_of(covering) >= 3,
			"the extended shallow roof is deep enough, at its tallest column, for interior cells")
	t.check(not RoofReads.units_of(covering).is_empty(),
			"the extended shallow roof carries at least one unit (%d)" % RoofReads.units_of(covering).size())
	for unit: Dictionary in RoofReads.units_of(covering):
		var cell: Vector2i = unit["cell"]
		t.check(front.roof_edges_at(cell.x, cell.y) == 0,
				"a unit on the extended shallow roof sits on a cell with no lip (%s)" % cell)
	bare.free()
	covering.free()

## The furniture pool is exactly the lip-free interior, row by row: every cell from row 1 up to one
## short of its column's own top, on every column but the two ends, whose drawn lips are none
## (the fixture's tallest extension is 4 rows). Asked
## of a stepped extension on a shallow roof and a deep one, so each has step cells beside a
## shorter column to leave out, and every unit rolled lands inside the pool.
func _test_the_furniture_pool_is_exactly_the_lip_free_interior(t) -> void:
	var extension: Array[int] = [0, 2, 4, 4, 2, 0]
	var found_units := 0
	for lot_rows: int in [4, 5, 6]:
		var building := _new_building(t, GameEnums.BlockPurpose.INDUSTRIAL,
				Vector2(6 * Building.TILE, lot_rows * Building.TILE), 64.0, false,
				Vector2(1111.0 * lot_rows, 2222.0))
		building.roof_extension_rows = extension
		var front = await _see(t, building)
		var expected: Array[Vector2i] = []
		var lipped := 0
		for row in range(1, building.roof_tiles() + 4 - 1):
			for col in range(1, building.columns() - 1):
				if row >= building.roof_tiles() + _extension_of(building, col) - 1:
					continue
				if front.roof_edges_at(col, row) == 0:
					expected.append(Vector2i(col, row))
				else:
					lipped += 1
		var roof := building.roof_tiles()
		t.check(lipped > 0, "roof of %d rows: there were step cells to leave out (%d)" % [roof, lipped])
		# The pool is read off where units stand: across many seeds, none stands outside the
		# lip-free interior and every cell of it is stood on by some seed.
		var reached := {}
		for variant in 120:
			building.variant = variant
			for unit: Dictionary in RoofReads.units_of(building):
				for cell: Vector2i in unit["cells"]:
					reached[cell] = true
		t.check(expected.all(func(cell: Vector2i) -> bool: return reached.has(cell))
				and reached.keys().all(func(cell: Vector2i) -> bool: return expected.has(cell)),
				"roof of %d rows: the pool is exactly the lip-free interior" % roof)
		var drawn := 0
		for child in building.get_children():
			drawn += 1 if child is Building.RoofObject else 0
		t.check(RoofReads.units_of(building).size() == drawn,
				"roof of %d rows: every roof object the building stands is read back as a unit" % roof)
		found_units += drawn
		for unit: Dictionary in RoofReads.units_of(building):
			var cell: Vector2i = unit["cell"]
			for step in int(unit["span"]):
				t.check(expected.has(cell + Vector2i(step, 0)),
						"roof of %d rows: a unit at %s stands inside the pool" % [roof, cell])
		building.free()
	t.check(found_units > 0, "the sweep met roof units to check (%d)" % found_units)



## `_build_front()`'s own `front:` stream — the storefront bag, the awning and ambient-shutter
## rolls — reads nothing about `covered_ground_cols`, so two otherwise-identical fronts, one fully
## covered and one not, roll it identically; only whether a pair actually draws
## (`_pair_is_storefront()`) differs. A fully covered commercial front shows no storefront on any
## column and, since nothing is visible, still has no door of its own — nobody can reach any of it.
func _test_covered_columns_move_no_storefront_roll(t) -> void:
	var at := Vector2(7777.0, 8888.0)
	var footprint := Vector2(6 * Building.TILE, 96.0)
	var plain := _new_building(t, GameEnums.BlockPurpose.COMMERCIAL, footprint, 64.0, false, at)
	var covered: Array[bool] = [true, true, true, true, true, true]
	var fully_covered := _new_building(t, GameEnums.BlockPurpose.COMMERCIAL, footprint, 64.0, false, at, covered)
	# The first pair covered, the others not: the bag is drawn from once per pair, so a roll that a
	# covered pair skipped would move every storefront after it, and those still draw.
	var first_pair_covered: Array[bool] = [true, true, false, false, false, false]
	var partly_covered := _new_building(t, GameEnums.BlockPurpose.COMMERCIAL, footprint, 64.0, false, at,
			first_pair_covered)
	var buildings: Array[Building] = [plain, partly_covered]
	var drawn := await _ground_floors_over_the_run(t, buildings)
	var drawn_plain: Array[StringName] = drawn[0]
	var drawn_partly: Array[StringName] = drawn[1]
	var compared := 0
	for i in drawn_plain.size():
		if i % plain.columns() < 2:
			t.check(drawn_partly[i] == &"", "the covered first pair draws nothing (index %d)" % i)
			continue
		t.check(drawn_partly[i] == drawn_plain[i],
				"coverage changes nothing about the storefronts after the covered pair (index %d)" % i)
		compared += 1
	t.check(compared > 0 and (Building.STOREFRONT_TEXTURES.has(drawn_plain[2])
			or Building.STOREFRONT_AWNING_TEXTURES.has(drawn_plain[2])),
			"and there were storefronts after the covered pair to compare (%d)" % compared)
	var covered_front = await _see(t, fully_covered)
	for col in plain.columns():
		t.check(covered_front.ground_floor_at(col) == &"",
				"column %d: a fully covered commercial front shows no storefront anywhere" % col)
	t.check(covered_front.door_col() == -1,
			"a fully covered commercial front still has no door — nobody can reach any column")
	plain.free()
	fully_covered.free()
	partly_covered.free()

## The door is re-placed onto whichever column is still reachable, through the same tiered pick
## that already keeps it off a fire escape — `INDUSTRIAL` rolls no fire escape and no storefront or
## portico, so this isolates the covered-column filter alone.
func _test_the_door_only_lands_on_a_reachable_column(t) -> void:
	var buildings: Array[Building] = []
	for keep in range(0, 5):
		var covered: Array[bool] = [true, true, true, true, true]
		covered[keep] = false
		buildings.append(_new_building(t, GameEnums.BlockPurpose.INDUSTRIAL, Vector2(5 * Building.TILE, 96.0),
				64.0, false, Vector2(keep * 401.0, keep * 293.0), covered))
	await UI.frames(t, 2)
	for keep in buildings.size():
		var front = FrontReads.look(buildings[keep])
		t.check(front.door_col() == keep,
				"keep=%d: the door lands on the one column left reachable (%d)" % [keep, front.door_col()])
		t.check(front.door_picture() == Building.ENTRANCE_DOOR_INDUSTRIAL,
				"keep=%d: the industrial front still draws its own steel door" % keep)
		buildings[keep].free()

func _test_a_fully_covered_front_has_no_door(t) -> void:
	var covered: Array[bool] = [true, true, true, true]
	var building := _new_building(t, GameEnums.BlockPurpose.INDUSTRIAL, Vector2(4 * Building.TILE, 96.0),
			64.0, false, Vector2(9001.0, 4002.0), covered)
	var front = await _see(t, building)
	t.check(front.door_col() == -1, "a fully covered front has no door")
	t.check(building.blank_ground_floor_cells().is_empty(),
			"a fully covered front offers no blank cell either, since every column draws no facade at all")
	building.free()

## The same `front:`-stream comparison `_test_the_home_flag_changes_no_front_roll` already makes for
## the home flag, made for coverage instead: an uncovered front and an otherwise-identical fully
## covered one roll the exact same fire escape (replayed by hand, the way that test replays it);
## only whether the result survives into `_fire_escape_cols` differs — no platform or brackets can
## ever reach a column nobody can stand in front of.
func _test_a_covered_fire_escape_column_is_dropped_but_the_roll_is_unchanged(t) -> void:
	var rolled_plain := 0
	var rolled_and_dropped := 0
	var plains: Array[Building] = []
	var coverings: Array[Building] = []
	for i in 200:
		var cols := 3 + i % 5
		var footprint := Vector2(cols * Building.TILE, 224.0)
		var at := Vector2(i * 61.0, i * 83.0)
		var covered: Array[bool] = []
		for c in cols:
			covered.append(true)
		plains.append(_new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, footprint, 160.0, false, at))
		coverings.append(_new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, footprint, 160.0, false, at,
				covered))
	await UI.frames(t, 2)
	for i in plains.size():
		var plain := plains[i]
		var at := Vector2(i * 61.0, i * 83.0)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("front:%d:%d:%d" % [plain.variant, int(at.x), int(at.y)])
		var expected_col := -1
		if plain.wall_tiles() >= 2 and rng.randf() < Building.FIRE_ESCAPE_SHARE:
			var roll_cols := plain.columns()
			expected_col = rng.randi_range(1, roll_cols - 2) if roll_cols >= 3 else rng.randi_range(0, roll_cols - 1)
		var expects_one := expected_col >= 0 and plain.wall_tiles() >= Building.FIRE_ESCAPE_MIN_WALL_ROWS
		if expects_one:
			rolled_plain += 1
			# `.has(expected_col)` rather than `== [expected_col]`: a front wide enough
			# (`SECOND_FIRE_ESCAPE_MIN_COLUMNS`) may also roll a second escape from its own
			# `escape:` stream, which is not what this comparison is about.
			t.check(FrontReads.look(plain).escape_cols().has(expected_col),
					"fixture %d: an uncovered front keeps the escape column its own roll produced" % i)
			t.check(FrontReads.look(coverings[i]).escape_cols().is_empty(),
					"fixture %d: the identical roll on a fully covered front drops it instead of keeping it" % i)
			rolled_and_dropped += 1
		coverings[i].free()
		plain.free()
	t.check(rolled_plain > 0, "the sweep met a front that rolled a fire escape (%d)" % rolled_plain)
	t.check(rolled_and_dropped > 0,
			"the sweep confirmed the drop on a covered front at least once (%d)" % rolled_and_dropped)

## A portico is one picture across one or two columns, so covering either drops the whole thing
## rather than half of it — and once it is gone, this front needs its own door the way any other
## front with no other way in does, on whichever column is not the covered one.
func _test_a_covered_portico_column_drops_the_portico_and_the_front_gets_a_door_instead(t) -> void:
	var at := Vector2(3333.0, 2222.0)
	var footprint := Vector2(96.0, 96.0)
	var civic := _new_building(t, GameEnums.BlockPurpose.CIVIC, footprint, 64.0, false, at)
	var entrance_cols: Array[int] = (await _see(t, civic)).portico_cols()
	t.check(entrance_cols.size() == 1, "fixture: an odd-width civic front's portico lands on one column")
	civic.free()
	var covered: Array[bool] = []
	for col in roundi(footprint.x / Building.TILE):
		covered.append(col == entrance_cols[0])
	var covered_civic := _new_building(t, GameEnums.BlockPurpose.CIVIC, footprint, 64.0, false, at, covered)
	var front = await _see(t, covered_civic)
	t.check(not front.portico_drawn(),
			"the portico does not draw once its own column is covered")
	t.check(front.door_col() >= 0,
			"once the portico's column is covered and dropped, the front gets its own door instead")
	t.check(front.door_col() != entrance_cols[0],
			"the door does not land on the covered portico column")
	covered_civic.free()





# --------------------------------------------------------------------- the sweep ---


