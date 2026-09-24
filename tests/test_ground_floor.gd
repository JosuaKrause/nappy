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
	_test_a_two_story_front_rolls_its_escape_and_carries_none(t)
	_test_the_ground_floor_carries_only_the_platform(t)
	_test_the_front_rolls_replay_their_own_streams(t)
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
	if residential._fire_escape_col >= 0:
		excluded[residential._fire_escape_col] = true
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
## buildings — one flagged hers, one not — must roll the exact same storefront bag, awning,
## ambient-shutter and fire-escape values. Checked directly rather than replaying the stream, since
## `tests/test_city_decay.gd` already pins what the stream itself produces.
func _test_the_home_flag_changes_no_front_roll(t) -> void:
	var shared_position := Vector2(1234.0, 5678.0)
	var plain := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 128.0), 96.0, false, shared_position)
	var home := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(96.0, 128.0), 96.0, true, shared_position)
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

## A replay of `_build_entrance()`'s own stream — `door:` plus the same variant and position every
## other stream in `Building` is keyed on — through the same tiering, `_door_col_from()`.
static func _replayed_door_col(building: Building) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("door:%d:%d:%d" % [building.variant, int(building.global_position.x),
			int(building.global_position.y)])
	return Building._door_col_from(building.columns(), building._fire_escape_col, rng)

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

## The fire escape's landings reach into both neighbouring columns at the ground floor, so the
## door never stands on its column or beside it where the front has any other column to offer.
func _test_the_door_keeps_clear_of_the_fire_escape(t) -> void:
	var with_escape := 0
	for i in 400:
		var cols := 3 + i % 6
		var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL,
				Vector2(cols * Building.TILE, 128.0), 96.0, false, Vector2(i * 37.0, i * 53.0))
		var door := building.entrance_door_col()
		var escape := building._fire_escape_col
		if escape >= 0:
			with_escape += 1
			t.check(door != escape, "the door is never under the fire escape (%d columns)" % cols)
			if cols >= 4:
				t.check(absi(door - escape) > 1,
						"with room to spare, the door is not beside the fire escape either (%d columns, door %d, escape %d)"
						% [cols, door, escape])
		else:
			t.check(door >= 1 and door <= cols - 2,
					"with no fire escape to avoid, the door stays off the corner columns (%d of %d)" % [door, cols])
		building.free()
	t.check(with_escape > 20, "the sweep met enough fire escapes to mean something (%d)" % with_escape)

# ------------------------------------------------------------- the fire escape ---

## What `_draw_fire_escape()` puts on a front, asked of one: a balcony on every floor line from
## the first floor's up to the top floor's — none on the ground floor's own, so nothing stands on
## the sidewalk — the lowest the platform alone and every other the balcony with its flight, all
## the one variant; and nothing on a front with no escape. Answers whether the front had one, so
## a sweep can say it was not vacuous.
static func _check_fire_escape(t, building: Building, label: String) -> bool:
	var landings := building.fire_escape_landings()
	if building._fire_escape_col < 0:
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
	var platform := Building.FIRE_ESCAPE_PLATFORM_B if building._fire_escape_variant_b else Building.FIRE_ESCAPE_PLATFORM_A
	var stair := Building.FIRE_ESCAPE_B if building._fire_escape_variant_b else Building.FIRE_ESCAPE_A
	for row in landings:
		var expected := platform if row == landings[0] else stair
		t.check(building.fire_escape_texture(row) == expected,
				"%s: row %d draws %s — the platform alone at the bottom, the balcony and its flight above, one variant throughout"
				% [label, row, expected])
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

## A two-row front still rolls `_build_front()`'s fire-escape roll where a taller one does, so the
## `front:` stream is consumed the same way on every front of two rows or more; the front then
## carries none. Replayed the way `_test_the_front_rolls_replay_their_own_streams` replays it.
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
			var expected_b := false
			rng.randi_range(1, building.columns() - 2)
			expected_b = rng.randf() < 0.5
			t.check(building._fire_escape_variant_b == expected_b,
					"fixture %d: the two-story front rolled the escape's column and variant from its own stream" % i)
		t.check(building._fire_escape_col == -1 and building.fire_escape_landings().is_empty(),
				"fixture %d: a two-story front carries no fire escape" % i)
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
## storefronts from `_build_front()`'s `front:` seed, and the door from `_build_entrance()`'s `door:`
## seed. Each stream is keyed on its own prefix and read by nothing else, so the door adds a roll
## without moving any other; a replay that still matches after the door exists is the proof.
func _test_the_front_rolls_replay_their_own_streams(t) -> void:
	var escapes_seen := 0
	for i in 40:
		var at := Vector2(1000.0 + i * 96.0, 2000.0 + i * 64.0)
		var building := _new_building(t, GameEnums.BlockPurpose.RESIDENTIAL, Vector2(192.0, 128.0), 96.0, false, at)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("front:%d:%d:%d" % [building.variant, int(at.x), int(at.y)])
		var expected_col := -1
		var expected_b := false
		if rng.randf() < Building.FIRE_ESCAPE_SHARE:
			expected_col = rng.randi_range(1, building.columns() - 2)
			expected_b = rng.randf() < 0.5
			escapes_seen += 1
		t.check(building._fire_escape_col == expected_col
				and (expected_col < 0 or building._fire_escape_variant_b == expected_b),
				"fixture %d: the fire-escape roll is `_build_front()`'s own stream" % i)
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
		t.check(col != building.entrance_door_col() and col != building._fire_escape_col,
				"seed %d: no accessor cell is the door's column or the fire escape's" % seed_used)

## Full `City` scenes across a spread of seeds — the only path that exercises
## `City._spawn_buildings()`'s own wiring of `is_home_building` and `door_world_x_range` off
## `CityMap.home_block` and `map.home_rect`, rather than a fixture set directly.
func _test_a_real_sweep_of_cities_never_shows_a_ground_floor_window(t) -> void:
	var checked_non_home := 0
	var checked_home := 0
	var checked_home_multistory := 0
	var checked_door_columns := 0
	var checked_commercial := 0
	var checked_doors := 0
	var checked_escapes := 0
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
			t.check(not building._draws_window_at(0),
					"seed %d: a multi-story building that is not her own draws no ground-floor window (district %d)"
					% [map.seed_used, building.district])
			var door := building.entrance_door_col()
			var has_other_way_in := building.district == GameEnums.BlockPurpose.CIVIC \
					or not building._storefront_variant.is_empty()
			if has_other_way_in:
				t.check(door == -1, "seed %d: a front with a storefront or a portico has no extra door" % map.seed_used)
			else:
				checked_doors += 1
				t.check(door >= 0 and door < building.columns() and door != building._fire_escape_col,
						"seed %d: a multi-story front with no other way in has one door, off the fire escape (district %d)"
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
	t.check(checked_home_multistory > 0,
			"the sweep built a multi-story home building at least once (%d)" % checked_home_multistory)
	t.check(checked_door_columns > 0,
			"the sweep met at least one ground-floor column standing behind the door (%d)" % checked_door_columns)
	t.check(checked_commercial > 0, "the sweep built a commercial storefront at least once (%d)" % checked_commercial)
	t.check(checked_doors > 0, "the sweep built a front with an entrance door (%d)" % checked_doors)
	t.check(checked_escapes > 0, "the sweep built a front with a fire escape (%d)" % checked_escapes)
