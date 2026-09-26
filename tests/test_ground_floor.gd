extends RefCounted
## M185's rule: a multi-story building's ground floor is shops or blank wall, never windows,
## except her own. `Building._draws_window_at()` is the one place that decides whether row 0 draws
## a window at all; `_build_windows()`/`_build_front()` still roll exactly the same streams they
## always have, so what changed is only which of their rolls get painted at the ground floor,
## never what the rolls are. `Building.blank_ground_floor_cells()` is the accessor a later poster
## slice pastes on. A multi-story front with no storefront and no portico has one entrance door
## (`Building.entrance_door_col()`), rolled from a stream of its own so no other roll moves.
##
## PLAYTEST-124's own finding is the one further exception: the ground-floor column(s) her front
## door's own footprint overlaps draw no window either, even on her own building —
## `Building.door_world_x_range` is the geometry fact `City._spawn_buildings()` hands the building
## for it, and `_column_under_door()` is the overlap test. A geometry fact, not a roll, so it moves
## no RNG stream — only which of `_draws_window_at()`'s already-computed answers gets painted where.
##
## M203's rule reaches the same columns for the opposite reason: where the tile directly south of a
## non-home front's own column is another building rather than walkable ground
## (`Building.covered_ground_cols`, another geometry fact `City._spawn_buildings()` hands over, read
## off `CityMap.is_walkable()`), that column draws no facade at all — no wall, no window at any
## floor, no storefront, no blank-wall plinth, no door, no portico, no fire escape. The building
## that covers it draws its own roof further north instead, up to exactly the covered building's
## own roof line (`Building.roof_extension_rows`, `City._assign_roof_extensions()`) — roof meets
## roof, replacing a row of windows the player turned down on the first pictures (PLAYTEST-138
## statement 3). Every roll still runs exactly as far as it always has (`_pair_is_storefront()`,
## `_portico_is_drawn()`, `_door_col_from()`'s own covered filter, the fire escape's drop in
## `_build_front()`); only which of the answers gets painted, or in the door's case which reachable
## column it re-places onto, changes. `roof_extension_rows` itself is pure geometry, not a roll.

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
	_test_the_door_blanks_only_the_columns_it_covers(t)
	_test_a_one_row_facade_is_unchanged(t)
	_test_the_accessor_returns_ground_floor_non_window_non_entrance_cells(t)
	_test_upper_floor_rolls_are_unchanged_for_a_fixed_seed(t)
	_test_the_home_flag_changes_no_front_roll(t)
	_test_a_front_with_no_other_way_in_has_one_door(t)
	_test_the_door_keeps_clear_of_the_fire_escape(t)
	_test_a_fire_escape_climbs_every_floor_from_the_first(t)
	_test_a_home_building_never_carries_a_fire_escape(t)
	_test_a_two_story_front_rolls_its_escape_and_carries_none(t)
	_test_the_ground_floor_carries_only_the_platform(t)
	_test_the_front_rolls_replay_their_own_streams(t)
	_test_a_wide_front_may_carry_a_second_escape_with_the_gap(t)
	_test_no_second_escape_on_a_front_too_narrow_for_one(t)
	_test_the_flower_pot_varies_within_one_escape(t)
	_test_a_covered_column_draws_no_facade_and_an_uncovered_one_is_unchanged(t)
	_test_roof_extension_rows_reads_back_per_column(t)
	_test_extension_is_seamless_reads_back_per_column(t)
	_test_covered_columns_move_no_storefront_roll(t)
	_test_the_door_only_lands_on_a_reachable_column(t)
	_test_a_fully_covered_front_has_no_door(t)
	_test_a_covered_fire_escape_column_is_dropped_but_the_roll_is_unchanged(t)
	_test_a_covered_portico_column_drops_the_portico_and_the_front_gets_a_door_instead(t)
	_test_the_real_sweep_wires_roof_extensions_to_reach_exactly_the_covered_roof(t)
	_test_the_real_sweep_marks_a_courtyard_seam_seamless_and_an_ordinary_one_not(t)
	_test_a_real_sweep_of_cities_never_shows_a_ground_floor_window(t)

# ------------------------------------------------------------------- fixtures ---

## One `Building`, built the way `City._spawn_buildings()` builds one — the exports set, then
## `add_child()`, which is what fires `_ready()` and rolls `_build_windows()`/`_build_front()`.
## `covered` is `Building.covered_ground_cols` (M203), empty by default — the same "nothing in
## front of it" a real front with clear sidewalk south of it reads as.
static func _new_building(t, district: int, footprint: Vector2, height: float, is_home := false,
		position := Vector2.ZERO, covered: Array[bool] = []) -> Building:
	var building := Building.new()
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
	t.check(building.door_world_x_range == Vector2.INF,
			"a building nobody told about a door keeps the empty Vector2.INF sentinel")
	for col in building.columns():
		t.check(building._draws_window_at(0, col),
				"her own building's ground floor still draws a window at every column (%d) with no door standing there"
				% col)
	building.free()

## A door 26px wide against a 32px `Building.TILE` column may straddle two of them — set here dead
## on the boundary between columns 2 and 3, so both blank and every other column keeps its window.
func _test_the_door_blanks_only_the_columns_it_covers(t) -> void:
	var position := Vector2(500.0, 700.0)
	var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(160.0, 96.0), 64.0, true, position)
	var boundary := building.global_position.x + building._cell(3, 0).x
	building.door_world_x_range = Vector2(boundary - 3.0, boundary + 3.0)
	for col in building.columns():
		var under_door := col == 2 or col == 3
		t.check(building._column_under_door(col) == under_door,
				"column %d: the overlap test agrees with which side of the boundary it is on" % col)
		t.check(building._draws_window_at(0, col) != under_door,
				"column %d: a window is drawn iff the door does not stand there" % col)
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

	# Every returned cell is ground-floor (row 0's own y) and exactly one tile, and neither the
	# door's column nor the one the fire escape stands against is among them.
	var residential := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 96.0), 64.0)
	var residential_cells := residential.blank_ground_floor_cells()
	var excluded := {residential.entrance_door_col(): true}
	for escape_col in residential._fire_escape_cols:
		excluded[escape_col] = true
	t.check(residential.entrance_door_col() >= 0, "the residential fixture has a door")
	t.check(residential_cells.size() == residential.columns() - excluded.size(),
			"a residential front is blank across every column but its door's and its fire escape's (%d of %d)"
			% [residential_cells.size(), residential.columns()])
	for cell in residential_cells:
		t.check(not excluded.has(_col_of(residential, cell)),
				"no accessor cell is the door's column or the fire escape's")
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
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("front:%d:%d:%d" % [plain.variant, int(plain.global_position.x), int(plain.global_position.y)])
	var expected_cols: Array[int] = []
	if plain.wall_tiles() >= 2 and rng.randf() < Building.FIRE_ESCAPE_SHARE:
		var cols := plain.columns()
		var first_col := rng.randi_range(1, cols - 2) if cols >= 3 else rng.randi_range(0, cols - 1)
		if plain.wall_tiles() >= Building.FIRE_ESCAPE_MIN_WALL_ROWS:
			expected_cols.append(first_col)
	t.check(plain._fire_escape_cols == expected_cols,
			"a non-home front keeps exactly the column its own roll produced (%s, expected %s)"
			% [plain._fire_escape_cols, expected_cols])
	t.check(home._fire_escape_cols.is_empty(),
			"her own building never keeps a fire escape, even though its roll runs the same way (%s)"
			% [home._fire_escape_cols])
	t.check(home._fire_escape_pots.is_empty(),
			"her own building never rolls the escape's own pot/second-escape stream either, since _fire_escape_cols stays empty")
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

## A replay of `_build_entrance()`'s own stream — `door:` plus the same variant and position every
## other stream in `Building` is keyed on — through the same tiering, `_door_col_from()`.
static func _replayed_door_col(building: Building) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("door:%d:%d:%d" % [building.variant, int(building.global_position.x),
			int(building.global_position.y)])
	return Building._door_col_from(building.columns(), building._fire_escape_cols,
			building.covered_ground_cols, rng)

static func _col_of(building: Building, cell: Rect2) -> int:
	return int(roundf((cell.position.x - building._cell(0, 0).x) / Building.TILE))

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
	for case in cases:
		var building := _new_building(t, case[0], case[1], case[2], case[3])
		var col := building.entrance_door_col()
		var label := "district %d, %d columns, %d wall rows, home=%s" % [case[0], building.columns(),
				building.wall_tiles(), case[3]]
		if case[4]:
			t.check(col >= 0 and col < building.columns(), "%s: has one door on its own front (%d)" % [label, col])
			t.check(building._entrance_door_texture() == case[5], "%s: draws the right door picture" % label)
		else:
			t.check(col == -1, "%s: has no entrance door (%d)" % [label, col])
		building.free()

	var station := _new_building(t, GameEnums.BlockPurpose.INDUSTRIAL, Vector2(160.0, 256.0), 64.0)
	station.power_station = true
	t.check(station.entrance_door_col() == -1, "the power station draws its own door, not this one")
	station.free()

## Every fire escape's landings reach into both neighbouring columns at the ground floor, so the
## door never stands on any escape's column or beside it where the front has any other column to
## offer — one escape or two.
func _test_the_door_keeps_clear_of_the_fire_escape(t) -> void:
	var with_escape := 0
	var with_two_escapes := 0
	for i in 400:
		var cols := 3 + i % 10
		var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL,
				Vector2(cols * Building.TILE, 128.0), 96.0, false, Vector2(i * 37.0, i * 53.0))
		var door := building.entrance_door_col()
		var escapes: Array[int] = building._fire_escape_cols
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

## What `_draw_fire_escape()` puts on a front, asked of one: a balcony on every floor line from
## the first floor's up to the top floor's — none on the ground floor's own, so nothing stands on
## the sidewalk — the lowest the platform alone and every other the balcony with its flight, the
## potted-plant picture or the plain one per that balcony's own roll; and nothing on a front with
## no escape. A wide front's second escape (if any) keeps the minimum gap from the first. Answers
## whether the front had at least one escape, so a sweep can say it was not vacuous.
static func _check_fire_escape(t, building: Building, label: String) -> bool:
	var landings := building.fire_escape_landings()
	var escapes: Array[int] = building._fire_escape_cols
	if escapes.is_empty():
		t.check(landings.is_empty(), "%s: a front with no fire escape draws no piece of one" % label)
		return false
	t.check(building.district == GameEnums.BlockPurpose.RESIDENTIAL,
			"%s: only a residential front carries a fire escape" % label)
	t.check(building.wall_tiles() >= Building.FIRE_ESCAPE_MIN_WALL_ROWS,
			"%s: a front with a fire escape has three floors at least (%d)" % [label, building.wall_tiles()])
	if landings.is_empty():
		t.check(false, "%s: a front with a fire escape draws its balconies" % label)
		return true
	t.check(landings[0] == 1,
			"%s: the lowest balcony is the first floor's, on the ground floor's top edge (row %d)"
			% [label, landings[0]])
	t.check(landings[-1] == building.wall_tiles() - 1,
			"%s: the highest balcony is on the top floor's floor line, so the stack starts at the bottom of the top floor (row %d of %d)"
			% [label, landings[-1], building.wall_tiles()])
	for i in range(1, landings.size()):
		t.check(landings[i] == landings[i - 1] + 1,
				"%s: a balcony on every floor between, so each flight lands on the next (%s)" % [label, landings])
	t.check(escapes.size() <= 2, "%s: a front never carries more than two fire escapes (%d)" % [label, escapes.size()])
	if escapes.size() == 2:
		t.check(absi(escapes[0] - escapes[1]) >= Building.FIRE_ESCAPE_GAP_COLUMNS,
				"%s: two escapes on one front keep the minimum gap (%s, need %d)"
				% [label, escapes, Building.FIRE_ESCAPE_GAP_COLUMNS])
		t.check(building.columns() >= Building.SECOND_FIRE_ESCAPE_MIN_COLUMNS,
				"%s: a second escape only appears on a front wide enough for one (%d columns)"
				% [label, building.columns()])
	for col in escapes:
		t.check(building.columns() < 3 or (col > 0 and col < building.columns() - 1),
				"%s: escape at column %d keeps off the corner columns (%d columns)"
				% [label, col, building.columns()])
		for row in landings:
			var pot: bool = building._fire_escape_pots.get(col, {}).get(row, false)
			var expected: StringName
			if row == landings[0]:
				expected = Building.FIRE_ESCAPE_PLATFORM_A if pot else Building.FIRE_ESCAPE_PLATFORM_B
			else:
				expected = Building.FIRE_ESCAPE_A if pot else Building.FIRE_ESCAPE_B
			t.check(building.fire_escape_texture(col, row) == expected,
					"%s: column %d row %d draws %s — the platform alone at the bottom, the balcony and its flight above, the pot per its own roll"
					% [label, col, row, expected])
	return true

## Fronts of every height the class can build, two to six wall rows, across a spread of lots: an
## escape reaches every floor of a front of three or more, and a front of two never has one.
func _test_a_fire_escape_climbs_every_floor_from_the_first(t) -> void:
	var escapes_by_rows := {}
	for i in 300:
		var wall_rows := 2 + i % 5
		var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL,
				Vector2((3 + i % 4) * Building.TILE, (wall_rows + 2) * Building.TILE), wall_rows * Building.TILE,
				false, Vector2(i * 41.0, i * 67.0))
		if _check_fire_escape(t, building, "fixture %d, %d wall rows" % [i, wall_rows]):
			escapes_by_rows[wall_rows] = int(escapes_by_rows.get(wall_rows, 0)) + 1
		building.free()
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
	for i in 200:
		var wall_rows := 3 + i % 4
		var cols := 3 + i % 6
		var footprint := Vector2(cols * Building.TILE, (wall_rows + 2) * Building.TILE)
		var height := wall_rows * Building.TILE
		var at := Vector2(i * 71.0, i * 97.0)
		var plain := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, footprint, height, false, at)
		var home := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, footprint, height, true, at)
		if not plain._fire_escape_cols.is_empty():
			plain_escapes += 1
		t.check(home._fire_escape_cols.is_empty(),
				"seed %d: her own building carries no fire escape (%s wall rows, %s columns)"
				% [i, wall_rows, cols])
		t.check(home.fire_escape_landings().is_empty(),
				"seed %d: her own building draws no fire-escape balcony either" % i)
		t.check(home._fire_escape_pots.is_empty(),
				"seed %d: her own building rolls no fire-escape pot/second-escape extras either" % i)
		plain.free()
		home.free()
	t.check(plain_escapes > 20,
			"the sweep met enough fire escapes on non-home fronts to mean something (%d)" % plain_escapes)

## A two-row front still rolls `_build_front()`'s fire-escape roll where a taller one does, so the
## `front:` stream is consumed the same way on every front of two rows or more; the front then
## carries none, and rolls no pots or second escape either, since `_build_fire_escape_extras()` only
## ever runs once `_fire_escape_cols` already holds the first. Replayed the way
## `_test_the_front_rolls_replay_their_own_streams` replays it.
func _test_a_two_story_front_rolls_its_escape_and_carries_none(t) -> void:
	var rolled := 0
	for i in 60:
		var at := Vector2(3000.0 + i * 96.0, 1000.0 + i * 64.0)
		var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(160.0, 128.0), 64.0, false, at)
		t.check(building.wall_tiles() == 2, "fixture %d is two stories (%d)" % [i, building.wall_tiles()])
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("front:%d:%d:%d" % [building.variant, int(at.x), int(at.y)])
		if rng.randf() < Building.FIRE_ESCAPE_SHARE:
			rolled += 1
			rng.randi_range(1, building.columns() - 2)
		t.check(building._fire_escape_cols.is_empty() and building.fire_escape_landings().is_empty(),
				"fixture %d: a two-story front carries no fire escape" % i)
		t.check(building._fire_escape_pots.is_empty(),
				"fixture %d: a two-story front rolls no pots either, since it never had a first escape to roll extras for" % i)
		building.free()
	t.check(rolled > 0, "the replay met a two-story front that rolled an escape (%d)" % rolled)

## The ground floor under an escape is the lower half of the platform picture and nothing else, so
## what the platform picture puts below its brackets is what an escape puts on the sidewalk: read
## off the baked page, the pixels the game draws. The stair picture's flight does reach that low,
## which is what makes the platform a picture of its own rather than the stair cut short.
func _test_the_ground_floor_carries_only_the_platform(t) -> void:
	var page := AtlasLibrary.page_image(&"buildings")
	t.check(page != null, "the baked buildings page reads back as an image")
	if page == null:
		return
	var pairs := [[Building.FIRE_ESCAPE_PLATFORM_A, Building.FIRE_ESCAPE_A],
			[Building.FIRE_ESCAPE_PLATFORM_B, Building.FIRE_ESCAPE_B]]
	for pair: Array in pairs:
		var platform := AtlasLibrary.region_rect(pair[0])
		var stair := AtlasLibrary.region_rect(pair[1])
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
	for i in 40:
		var at := Vector2(1000.0 + i * 96.0, 2000.0 + i * 64.0)
		var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(192.0, 128.0), 96.0, false, at)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("front:%d:%d:%d" % [building.variant, int(at.x), int(at.y)])
		var expected_col := -1
		if rng.randf() < Building.FIRE_ESCAPE_SHARE:
			expected_col = rng.randi_range(1, building.columns() - 2)
			escapes_seen += 1
		var expected_cols: Array = [] if expected_col < 0 else [expected_col]
		var expected_pots := {}
		if expected_col >= 0:
			var escape_rng := RandomNumberGenerator.new()
			escape_rng.seed = hash("escape:%d:%d:%d" % [building.variant, int(at.x), int(at.y)])
			var extras: Dictionary = Building._roll_fire_escape_extras(building.columns(), expected_col,
					building.fire_escape_landings(), escape_rng)
			expected_cols = extras["cols"]
			expected_pots = extras["pots"]
		t.check(building._fire_escape_cols == expected_cols,
				"fixture %d: the fire-escape roll (and its second escape, if any) is its own stream" % i)
		t.check(building._fire_escape_pots == expected_pots,
				"fixture %d: the fire-escape pot rolls are `_build_fire_escape_extras()`'s own stream" % i)
		t.check(building._door_col == _replayed_door_col(building),
				"fixture %d: the door's column is `_build_entrance()`'s own stream" % i)
		building.free()
	t.check(escapes_seen > 0, "the replay met a fire escape (%d)" % escapes_seen)

	var at := Vector2(4096.0, 3072.0)
	var shop := _new_building(t, GameEnums.BlockPurpose.COMMERCIAL, Vector2(256.0, 128.0), 96.0, false, at)
	var shop_rng := RandomNumberGenerator.new()
	shop_rng.seed = hash("front:%d:%d:%d" % [shop.variant, int(at.x), int(at.y)])
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
	t.check(shop._storefront_variant == variants and shop._storefront_awning == awnings
			and shop._storefront_shutter_severity == severities,
			"the storefront bag, awning and ambient-shutter rolls are `_build_front()`'s own stream")
	t.check(shop._door_col == _replayed_door_col(shop),
			"a commercial front still rolls its door's column, unused while it has storefronts")
	shop.free()

## A front wide enough for two escapes (`Building.SECOND_FIRE_ESCAPE_MIN_COLUMNS`, 7 columns) may
## carry a second one, and every one the sweep meets keeps the minimum gap
## (`Building.FIRE_ESCAPE_GAP_COLUMNS`, 4 columns centre to centre) and stays off the corner columns
## — the same checks `_check_fire_escape()` already runs, asked again with a sweep built to meet the
## case reliably.
func _test_a_wide_front_may_carry_a_second_escape_with_the_gap(t) -> void:
	var with_two := 0
	for i in 500:
		var cols := 7 + i % 8
		var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL,
				Vector2(cols * Building.TILE, 224.0), 160.0, false, Vector2(i * 71.0, i * 97.0))
		if building._fire_escape_cols.size() == 2:
			with_two += 1
			var escapes: Array[int] = building._fire_escape_cols
			t.check(absi(escapes[0] - escapes[1]) >= Building.FIRE_ESCAPE_GAP_COLUMNS,
					"fixture %d: two escapes on a %d-column front keep the minimum gap (%s)" % [i, cols, escapes])
			for col in escapes:
				t.check(col > 0 and col < cols - 1,
						"fixture %d: escape at column %d of %d keeps off the corner columns" % [i, col, cols])
		building.free()
	t.check(with_two > 0, "the sweep met a front that carries two fire escapes (%d)" % with_two)

## Nothing under `Building.SECOND_FIRE_ESCAPE_MIN_COLUMNS` (7 columns) ever carries a second escape:
## the interior range `[1, cols - 2]` a narrower front rolls from is not wide enough to fit two
## columns `Building.FIRE_ESCAPE_GAP_COLUMNS` apart.
func _test_no_second_escape_on_a_front_too_narrow_for_one(t) -> void:
	var with_escape := 0
	for i in 400:
		var cols := 3 + i % (Building.SECOND_FIRE_ESCAPE_MIN_COLUMNS - 3)
		t.check(cols < Building.SECOND_FIRE_ESCAPE_MIN_COLUMNS,
				"fixture %d: the fixture itself stays under the width a second escape needs (%d)" % [i, cols])
		var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL,
				Vector2(cols * Building.TILE, 224.0), 160.0, false, Vector2(i * 83.0, i * 101.0))
		if not building._fire_escape_cols.is_empty():
			with_escape += 1
		t.check(building._fire_escape_cols.size() <= 1,
				"fixture %d: a %d-column front never carries two fire escapes" % [i, cols])
		building.free()
	t.check(with_escape > 20, "the sweep met enough narrow fronts with a fire escape to mean something (%d)" % with_escape)

## The potted-plant picture is rolled balcony by balcony (`Building.FIRE_ESCAPE_POT_SHARE`), so a
## tall enough escape mixes both pictures across its own landings rather than showing the same one
## on every floor. Swept rather than asserted of one fixture, since which building shows the mix is
## itself a roll.
func _test_the_flower_pot_varies_within_one_escape(t) -> void:
	var mixed_seen := 0
	for i in 300:
		var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 256.0), 192.0,
				false, Vector2(i * 59.0, i * 131.0))
		for col in building._fire_escape_cols:
			var pots: Dictionary = building._fire_escape_pots.get(col, {})
			var values := pots.values()
			if values.has(true) and values.has(false):
				mixed_seen += 1
		building.free()
	t.check(mixed_seen > 0, "the sweep met an escape whose balconies do not all show the same pot roll (%d)" % mixed_seen)

# ------------------------------------------------------------------- M203: covered columns ---

## The rule stated directly: a covered column draws no facade at all — not even the window row
## the first, superseded pass drew there — and an uncovered column of the same front is unaffected
## either way, since this fixture is `RESIDENTIAL` with no door rolled onto either uncovered column
## (checked below). `_draws_window_at()` no longer reads `covered_ground_cols` at all: `_draw()`'s
## own wall loop skips a covered column's whole cell before this is ever asked about it, so the
## function's own answer for a covered column is identical to an ordinary blank-wall one.
func _test_a_covered_column_draws_no_facade_and_an_uncovered_one_is_unchanged(t) -> void:
	var covered: Array[bool] = [true, false, true, false]
	var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(4 * Building.TILE, 96.0),
			64.0, false, Vector2(5555.0, 6666.0), covered)
	t.check(building.wall_tiles() >= 2, "the fixture is genuinely multi-story")
	for col in building.columns():
		t.check(not building._draws_window_at(0, col),
				"column %d: no ground-floor window is drawn, covered or not (M203 moved this to the roof instead)" % col)
		for row in range(1, building.wall_tiles()):
			t.check(building._draws_window_at(row, col),
					"column %d row %d: an upper floor still draws its own window regardless of coverage" % [col, row])
	for col in [0, 2]:
		t.check(building._is_covered(col), "column %d: the fixture covers it" % col)
		t.check(building._ground_floor_texture(col) == &"",
				"column %d: a covered column has no storefront and no blank-wall plinth either" % col)
	for col in [1, 3]:
		t.check(not building._is_covered(col), "column %d: the fixture leaves it reachable" % col)
		if col != building.entrance_door_col():
			t.check(building._ground_floor_texture(col) == Building.WALL_BASE,
					"column %d: an uncovered column of the same front keeps its plain-wall ground floor" % col)
	building.free()

## `roof_extension_rows` is a fixture-settable geometry fact, the same shape `covered_ground_cols`
## already is: `_extension_rows()` reads it back per column, and an index past the end — or a
## building nobody ever told about one — reads as 0, the same "nobody told this building about
## one" convention `_is_covered()` and `_windows`' own out-of-range reads already use.
func _test_roof_extension_rows_reads_back_per_column(t) -> void:
	var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(4 * Building.TILE, 96.0), 64.0)
	t.check(building._extension_rows(0) == 0, "a building nobody told about an extension reads 0")
	building.roof_extension_rows = [0, 3, 0, 5]
	for col in [0, 1, 2, 3]:
		t.check(building._extension_rows(col) == building.roof_extension_rows[col],
				"column %d: _extension_rows() reads roof_extension_rows back exactly" % col)
	t.check(building._extension_rows(4) == 0, "an index past the end reads as 0")
	t.check(building._extension_rows(-1) == 0, "a negative index reads as 0 too")
	building.free()

## `roof_extension_seamless` (M216) is a fixture-settable geometry fact, the same shape
## `roof_extension_rows` already is: empty by default (an ordinary front, no courtyard sibling to
## be seamless with), `_extension_is_seamless()` reads it back per column, and an index past the
## end reads false, the same "nobody told this building about one" convention every other
## per-column accessor here already follows.
func _test_extension_is_seamless_reads_back_per_column(t) -> void:
	var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(4 * Building.TILE, 96.0), 64.0)
	t.check(not building._extension_is_seamless(0), "a building nobody told about one reads false")
	building.roof_extension_seamless = [false, true, false, true]
	for col in [0, 1, 2, 3]:
		t.check(building._extension_is_seamless(col) == building.roof_extension_seamless[col],
				"column %d: _extension_is_seamless() reads roof_extension_seamless back exactly" % col)
	t.check(not building._extension_is_seamless(4), "an index past the end reads false")
	t.check(not building._extension_is_seamless(-1), "a negative index reads false too")
	building.free()

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
	t.check(plain._storefront_variant == fully_covered._storefront_variant
			and plain._storefront_awning == fully_covered._storefront_awning
			and plain._storefront_shutter_severity == fully_covered._storefront_shutter_severity,
			"coverage changes nothing about the storefront bag, awning or ambient-shutter rolls")
	for col in plain.columns():
		t.check(fully_covered._ground_floor_texture(col) == &"",
				"column %d: a fully covered commercial front shows no storefront anywhere" % col)
	t.check(not fully_covered._has_visible_storefront(), "a fully covered commercial front has no visible storefront")
	t.check(fully_covered.entrance_door_col() == -1,
			"a fully covered commercial front still has no door — nobody can reach any column")
	plain.free()
	fully_covered.free()

## The door is re-placed onto whichever column is still reachable, through the same tiered pick
## that already keeps it off a fire escape — `INDUSTRIAL` rolls no fire escape and no storefront or
## portico, so this isolates the covered-column filter alone.
func _test_the_door_only_lands_on_a_reachable_column(t) -> void:
	for keep in range(0, 5):
		var covered: Array[bool] = [true, true, true, true, true]
		covered[keep] = false
		var building := _new_building(t, GameEnums.BlockPurpose.INDUSTRIAL, Vector2(5 * Building.TILE, 96.0),
				64.0, false, Vector2(keep * 401.0, keep * 293.0), covered)
		t.check(building.entrance_door_col() == keep,
				"keep=%d: the door lands on the one column left reachable (%d)" % [keep, building.entrance_door_col()])
		t.check(building._entrance_door_texture() == Building.ENTRANCE_DOOR_INDUSTRIAL,
				"keep=%d: the industrial front still draws its own steel door" % keep)
		building.free()

func _test_a_fully_covered_front_has_no_door(t) -> void:
	var covered: Array[bool] = [true, true, true, true]
	var building := _new_building(t, GameEnums.BlockPurpose.INDUSTRIAL, Vector2(4 * Building.TILE, 96.0),
			64.0, false, Vector2(9001.0, 4002.0), covered)
	t.check(building.entrance_door_col() == -1, "a fully covered front has no door")
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
	for i in 200:
		var cols := 3 + i % 5
		var footprint := Vector2(cols * Building.TILE, 224.0)
		var at := Vector2(i * 61.0, i * 83.0)
		var covered: Array[bool] = []
		for c in cols:
			covered.append(true)
		var plain := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, footprint, 160.0, false, at)
		var fully_covered := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, footprint, 160.0, false, at,
				covered)
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
			t.check(plain._fire_escape_cols.has(expected_col),
					"fixture %d: an uncovered front keeps the escape column its own roll produced" % i)
			t.check(fully_covered._fire_escape_cols.is_empty(),
					"fixture %d: the identical roll on a fully covered front drops it instead of keeping it" % i)
			rolled_and_dropped += 1
		fully_covered.free()
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
	var entrance_cols := civic._civic_entrance_cols()
	t.check(entrance_cols.size() == 1, "fixture: an odd-width civic front's portico lands on one column")
	civic.free()
	var covered: Array[bool] = []
	for col in roundi(footprint.x / Building.TILE):
		covered.append(col == entrance_cols[0])
	var covered_civic := _new_building(t, GameEnums.BlockPurpose.CIVIC, footprint, 64.0, false, at, covered)
	t.check(not covered_civic._portico_is_drawn(),
			"the portico does not draw once its own column is covered")
	t.check(covered_civic.entrance_door_col() >= 0,
			"once the portico's column is covered and dropped, the front gets its own door instead (M203)")
	t.check(covered_civic.entrance_door_col() != entrance_cols[0],
			"the door does not land on the covered portico column")
	covered_civic.free()

## `City._assign_roof_extensions()`'s own wiring, asked of whatever the generator actually builds:
## every covered column's own south-neighbour tile that is still on the map belongs to some
## building's lot, and that building's own `roof_extension_rows` at the matching column is exactly
## the covered building's own `wall_tiles()` — enough roof to reach exactly the world row the
## covered building's own roof already starts at, never more and never less. `has_point()` over
## every building's own `lot` rather than a spatial index, since the whole set is small and this
## only runs once per seed. A south tile past the map's own edge is covered too
## (`_covered_ground_cols()`'s own out-of-bounds default) but belongs to no lot — the map's own
## boundary, not a building — so those columns are skipped rather than checked, the same tolerance
## `_assign_roof_extensions()` itself already has.
func _test_the_real_sweep_wires_roof_extensions_to_reach_exactly_the_covered_roof(t) -> void:
	var checked := 0
	for i in SWEEP_SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 977)
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		var buildings := city.buildings()
		for building: Building in buildings:
			if building.power_station or building.covered_ground_cols.is_empty():
				continue
			for col in building.covered_ground_cols.size():
				if not building.covered_ground_cols[col]:
					continue
				var south := Vector2i(building.lot.position.x + col,
						building.lot.position.y + building.lot.size.y)
				if not map.in_bounds(south):
					# `_covered_ground_cols()`'s own out-of-bounds default (`CityMap.tile_at()`
					# reads a tile past the map's own edge as `BUILDING`) marks this column covered
					# too, with no lot on the other side to extend a roof from — the map's own
					# boundary, not a building. `_assign_roof_extensions()` tolerates exactly this
					# (`tile_to_index.get(south, -1)`, `if front_index < 0: continue`), so nothing
					# more is asked of this column here either.
					continue
				var front: Building = null
				for candidate: Building in buildings:
					if candidate.lot.has_point(south):
						front = candidate
						break
				t.check(front != null,
						"seed %d: a covered column's own south tile, in bounds, belongs to some building's lot"
						% map.seed_used)
				if front == null:
					continue
				var local_col := south.x - front.lot.position.x
				var extension := front._extension_rows(local_col)
				t.check(extension == building.wall_tiles(),
						"seed %d: the covering front's own roof reaches exactly the covered front's own roof line (%d rows expected, got %d)"
						% [map.seed_used, building.wall_tiles(), extension])
				checked += 1
		city.free()
	t.check(checked > 0, "the sweep met at least one real covered column to check the extension's own wiring on (%d)" % checked)

## `City._assign_roof_extensions()`'s own courtyard wiring (M216): a covered column's extension is
## seamless exactly when the covered building and the covering building were both cut from the same
## courtyard lot — a single-block courtyard's own `map.lot_rect(block)`, or an apartment complex's
## (`_build_block()`'s shared `COURTYARD` branch cuts both the same way, `_subtract_all()` around
## the hole). Recomputes the courtyard-lot membership independently here, the same way the roof-
## extension sweep above recomputes "front" independently rather than trusting `_assign_roof_
## extensions()`'s own bookkeeping — so this only passes if the wiring is actually right, not merely
## self-consistent. Every OTHER covered column (M203's ordinary front-and-back case, two genuinely
## separate buildings) must NOT be seamless, or a real parapet step would silently vanish there too.
func _test_the_real_sweep_marks_a_courtyard_seam_seamless_and_an_ordinary_one_not(t) -> void:
	var checked_courtyard := 0
	var checked_ordinary := 0
	for i in SWEEP_SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 977)
		var courtyard_lots: Array[Rect2i] = []
		for block in map.block_layouts.keys():
			if map.starting_purpose(block) == GameEnums.BlockPurpose.COURTYARD:
				courtyard_lots.append(map.lot_rect(block))
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		var buildings := city.buildings()
		for building: Building in buildings:
			if building.power_station or building.covered_ground_cols.is_empty():
				continue
			for col in building.covered_ground_cols.size():
				if not building.covered_ground_cols[col]:
					continue
				var south := Vector2i(building.lot.position.x + col,
						building.lot.position.y + building.lot.size.y)
				if not map.in_bounds(south):
					continue
				var front: Building = null
				for candidate: Building in buildings:
					if candidate.lot.has_point(south):
						front = candidate
						break
				if front == null:
					continue
				var back_lot := -1
				var front_lot := -1
				for lot_index in courtyard_lots.size():
					if courtyard_lots[lot_index].encloses(building.lot):
						back_lot = lot_index
					if courtyard_lots[lot_index].encloses(front.lot):
						front_lot = lot_index
				var same_courtyard := back_lot >= 0 and back_lot == front_lot
				var local_col := south.x - front.lot.position.x
				var seamless := front._extension_is_seamless(local_col)
				t.check(seamless == same_courtyard,
						("seed %d: a covering front's extension is seamless exactly when it shares " +
						"a courtyard lot with the column it covers (expected %s, got %s)")
						% [map.seed_used, same_courtyard, seamless])
				if same_courtyard:
					checked_courtyard += 1
				else:
					checked_ordinary += 1
		city.free()
	t.check(checked_ordinary > 0,
			"the sweep met at least one ordinary (non-courtyard) covered column to check (%d)" % checked_ordinary)
	t.check(checked_courtyard > 0,
			"the sweep met at least one courtyard seam to check seamlessness on (%d)" % checked_courtyard)

# --------------------------------------------------------------------- the sweep ---

## Every accessor cell a real building offers is plain wall (`_ground_floor_texture()` says
## `WALL_BASE`) and never one of `_civic_entrance_cols()`'s own columns while the portico actually
## draws (M203: a portico dropped for a covered column frees the other one it straddled, which
## `_portico_is_drawn()` says) — the same two contracts
## `_test_the_accessor_returns_ground_floor_non_window_non_entrance_cells` pins on fixtures, asked
## again of whatever the generator actually builds.
func _check_accessor_invariant(t, building: Building, seed_used: int) -> void:
	var entrance_cols: Array[int] = []
	if building._portico_is_drawn():
		entrance_cols = building._civic_entrance_cols()
	var ground_row_y := building._cell(0, 0).y
	for cell in building.blank_ground_floor_cells():
		var col := int(roundf((cell.position.x - building._cell(0, 0).x) / Building.TILE))
		t.check(is_equal_approx(cell.position.y, ground_row_y),
				"seed %d: every accessor cell sits on the ground row" % seed_used)
		t.check(building._ground_floor_texture(col) == Building.WALL_BASE,
				"seed %d: every accessor cell is plain wall, not a window or a storefront" % seed_used)
		t.check(not entrance_cols.has(col),
				"seed %d: no accessor cell is a drawn civic entrance's own column" % seed_used)
		t.check(col != building.entrance_door_col() and not building._fire_escape_cols.has(col),
				"seed %d: no accessor cell is the door's column or a fire escape's" % seed_used)
		t.check(not building._is_covered(col),
				"seed %d: no accessor cell is a covered column — those draw no facade at all, never blank wall" % seed_used)

## Full `City` scenes across a spread of seeds — the only path that exercises
## `City._spawn_buildings()`'s own wiring of `is_home_building`, `door_world_x_range` and
## `covered_ground_cols` (M203) off `CityMap.home_block`, `map.home_rect` and `map.is_walkable()`,
## rather than a fixture set directly.
func _test_a_real_sweep_of_cities_never_shows_a_ground_floor_window(t) -> void:
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
		var map := CityGenerator.generate(BASE_SEED + i * 977)
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		for building: Building in city.buildings():
			_check_accessor_invariant(t, building, map.seed_used)
			if _check_fire_escape(t, building, "seed %d" % map.seed_used):
				checked_escapes += 1
			if building.power_station:
				continue
			if building.is_home_building:
				checked_home += 1
				t.check(building.covered_ground_cols.is_empty(),
						"seed %d: her own building is never told about a covered column (M203)" % map.seed_used)
				t.check(building._fire_escape_cols.is_empty(),
						"seed %d: her own building never carries a fire escape, wired the real way through City._spawn_buildings()"
						% map.seed_used)
				if building.wall_tiles() >= 2:
					checked_home_multistory += 1
					var saw_a_window := false
					for col in building.columns():
						var under_door := building._column_under_door(col)
						if under_door:
							checked_door_columns += 1
						t.check(building._draws_window_at(0, col) != under_door,
								"seed %d: her own building draws a ground-floor window at column %d iff the door does not stand there"
								% [map.seed_used, col])
						saw_a_window = saw_a_window or not under_door
					t.check(saw_a_window,
							"seed %d: her own building still shows a ground-floor window somewhere the door does not stand"
							% map.seed_used)
				continue
			checked_non_home += 1
			if building.wall_tiles() < 2:
				continue
			var any_covered := false
			for col in building.columns():
				# Never a window, covered or not: the row-of-windows pass this replaced is what used to
				# draw one on a covered column; the roof extension that replaces it draws nothing on the
				# wall at all (M203, `docs/DECISIONS.md`, "A front nobody can stand at is covered by the
				# roof in front of it").
				t.check(not building._draws_window_at(0, col),
						"seed %d: no ground-floor column of a building that is not her own draws a window, covered or not (district %d)"
						% [map.seed_used, building.district])
				if building._is_covered(col):
					any_covered = true
					checked_covered_columns += 1
					t.check(building._ground_floor_texture(col) == &"",
							"seed %d: a covered column (%d) has no storefront and no blank-wall plinth (district %d)"
							% [map.seed_used, col, building.district])
					t.check(col != building.entrance_door_col(),
							"seed %d: a covered column (%d) never carries the entrance door (district %d)"
							% [map.seed_used, col, building.district])
					t.check(not building._fire_escape_cols.has(col),
							"seed %d: a covered column (%d) never carries a fire escape (district %d)"
							% [map.seed_used, col, building.district])
			var fully_covered := any_covered and building.covered_ground_cols.count(true) == building.columns()
			if fully_covered:
				checked_fully_covered_fronts += 1
				t.check(building.entrance_door_col() == -1,
						"seed %d: a fully covered front has no door (district %d)" % [map.seed_used, building.district])
			var door := building.entrance_door_col()
			var has_other_way_in := (building.district == GameEnums.BlockPurpose.CIVIC and building._portico_is_drawn()) \
					or (building.district == GameEnums.BlockPurpose.COMMERCIAL and building._has_visible_storefront())
			if has_other_way_in:
				t.check(door == -1, "seed %d: a front with a drawn storefront or portico has no extra door" % map.seed_used)
			elif fully_covered:
				t.check(door == -1, "seed %d: a fully covered front with no other way in still has no door" % map.seed_used)
			else:
				checked_doors += 1
				t.check(door >= 0 and door < building.columns() and not building._fire_escape_cols.has(door)
						and not building._is_covered(door),
						"seed %d: a multi-story front with no other way in has one door, off every fire escape and every covered column (district %d)"
						% [map.seed_used, building.district])
			if building.district == GameEnums.BlockPurpose.COMMERCIAL and building._has_visible_storefront():
				checked_commercial += 1
				var storefront_col := -1
				for probe_col in building.columns():
					var texture := building._ground_floor_texture(probe_col)
					if texture != Building.WALL_BASE and texture != &"":
						storefront_col = probe_col
						break
				t.check(storefront_col >= 0, "seed %d: a real commercial building's storefront is still drawn" % map.seed_used)
				if storefront_col >= 0:
					var texture := building._ground_floor_texture(storefront_col)
					t.check(Building.STOREFRONT_TEXTURES.has(texture) or Building.STOREFRONT_AWNING_TEXTURES.has(texture)
							or Building.STOREFRONT_SHUTTERED_TEXTURES.has(texture),
							"seed %d: a real commercial building's storefront is still drawn" % map.seed_used)
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
			"the sweep met at least one real covered ground-floor column (%d, M203)" % checked_covered_columns)
	t.check(checked_fully_covered_fronts > 0,
			"the sweep met at least one real fully covered front (%d, M203)" % checked_fully_covered_fronts)
