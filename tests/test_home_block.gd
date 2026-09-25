extends RefCounted
## M185's fixing half — the home block has fixed visuals: every building on it draws the same on
## every seed (window style, which windows are lit, height, front and roof furniture), and her own
## building — the one lot the door's own world-space span stands in front of — always has a third
## floor, so `Building.neighbor_window_row()` (row index 3, the third floor) never has to fall back
## to a shorter front's topmost row (PLAYTEST-134: "the home building shouldn't depend on the
## seed. I thought we fixed that?").
##
## **The home block's own lot geometry was already seed-independent before this change** —
## `CityGenerator` carves it from `Tuning.BLOCK_SIZE`, `Tuning.HOME_SIZE_TILES` and the fixed
## middle block alone, never from `map.seed_used` — which is what makes `City._variant_for()` and
## `City._height_for()` cheap to fix: each takes an early return for a home-block rect to a fixed
## choice (a hash of the rect's own position alone, or one of two fixed wall-row counts) and
## otherwise runs exactly the code it always has, so a non-home building's own roll is untouched.
##
## Roof furniture needed no code of its own: `Building._build_roof_furniture()` already refuses to
## place anything on a roof under three interior rows, and every home-block building's own fixed
## height leaves `roof_tiles()` at two or fewer on the one lot depth `CityGenerator` ever carves
## for the block (checked below), so it was always empty there and stays that way with nothing
## added to guard it.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The seed PLAYTEST-134 found with only two wall rows on her own building, before this fix.
const SHORT_SEED := 4242
## A second seed with nothing else in common with the first, for the cross-seed comparisons.
const OTHER_SEED := 90210
## How many seeds the cheap, data-only sweeps check — wide enough to mean something without
## building a full `City` scene that many times over.
const WIDE_SWEEP_SEEDS := 60
## How many seeds the full-`City` sweep checks — the same order as `tests/test_ground_floor.gd`'s
## own real-city sweep, which is the expensive part of this suite.
const CITY_SWEEP_SEEDS := 6

func run(t) -> void:
	_test_the_home_block_lot_geometry_is_already_seed_independent(t)
	_test_her_building_is_the_same_across_two_seeds(t)
	_test_every_home_block_building_is_the_same_across_two_seeds(t)
	_test_the_home_block_lot_is_deep_enough_for_four_wall_rows_on_a_spread_of_seeds(t)
	_test_her_building_has_at_least_four_wall_rows_on_a_spread_of_seeds(t)
	_test_non_home_buildings_still_roll_the_seed(t)
	_test_non_home_rolls_replay_the_unchanged_formula(t)

# ------------------------------------------------------------------- fixtures ---

static func _city_for(t, seed_value: int) -> City:
	var map := CityGenerator.generate(seed_value)
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(map)
	return city

## Every home-block building rect, sorted so two independently-collected lists compare directly.
static func _home_block_rects(map: CityMap) -> Array[Rect2i]:
	var rects: Array[Rect2i] = []
	for rect in map.building_rects:
		if _block_of(rect) == map.home_block:
			rects.append(rect)
	rects.sort_custom(func(a, b): return a.position < b.position)
	return rects

## The deepest of the home block's own rects — the one the door notch's world span stands in front
## of, since a wider, shallower notch never outgrows it on any lot `CityGenerator` carves.
static func _deepest_home_block_rect(map: CityMap) -> Rect2i:
	var deepest := Rect2i()
	for rect in map.building_rects:
		if _block_of(rect) == map.home_block and rect.size.y > deepest.size.y:
			deepest = rect
	return deepest

## Every home-block `Building`, keyed by its own lot — `City._block_of()`'s own formula, repeated
## here since it is a private instance method with no static twin to call.
static func _home_buildings_by_lot(city: City) -> Dictionary:
	var result := {}
	for building: Building in city.buildings():
		if building.is_home_building:
			result[building.lot] = building
	return result

static func _block_of(rect: Rect2i) -> Vector2i:
	return (rect.position - Vector2i.ONE * Tuning.STREET_WIDTH) / CityMap.period()

# ------------------------------------------------------------- the lot geometry ---

## The premise the rest of this suite leans on: the home block's own three lots — the door's own
## and the two flanking the notch — are the same rects on every seed, because `CityGenerator`
## derives them from `Tuning` constants and the fixed middle block alone.
func _test_the_home_block_lot_geometry_is_already_seed_independent(t) -> void:
	var short := CityGenerator.generate(SHORT_SEED)
	var other := CityGenerator.generate(OTHER_SEED)
	var short_rects := _home_block_rects(short)
	var other_rects := _home_block_rects(other)
	t.check(short_rects.size() == 3,
			"the home block carves into exactly three lots — the door's own and the two flanking the notch (%d)"
			% short_rects.size())
	t.check(short_rects == other_rects,
			"the home block's own lot rects are identical on every seed (seed %d: %s, seed %d: %s)"
			% [SHORT_SEED, short_rects, OTHER_SEED, other_rects])

# --------------------------------------------------------------- fixed visuals ---

## Her own building, end to end through `City.build()`: the same floor count, colour variant,
## window style, lit-window pattern and roof furniture (always empty — see the class doc) on two
## seeds with nothing else in common, including the one PLAYTEST-134 found short.
func _test_her_building_is_the_same_across_two_seeds(t) -> void:
	var short := _city_for(t, SHORT_SEED)
	var other := _city_for(t, OTHER_SEED)
	var a: Building = short._home_door_building()
	var b: Building = other._home_door_building()
	t.check(a != null and b != null, "both seeds carve a door building on the home block")
	if a != null and b != null:
		t.check(a.wall_tiles() == b.wall_tiles(),
				"her building's own floor count matches across seeds (%d vs %d)"
				% [a.wall_tiles(), b.wall_tiles()])
		t.check(a.columns() == b.columns(),
				"her building's own width matches across seeds (%d vs %d)" % [a.columns(), b.columns()])
		t.check(a.variant == b.variant,
				"her building's own colour variant matches across seeds (%d vs %d)" % [a.variant, b.variant])
		t.check(a._window_style == b._window_style, "her building's own window style matches across seeds")
		t.check(a._windows == b._windows, "her building's own lit-window pattern matches across seeds")
		t.check(a._roof_furniture.is_empty() and b._roof_furniture.is_empty(),
				"her building's own roof is too shallow to carry furniture on either seed (%s vs %s)"
				% [a._roof_furniture, b._roof_furniture])
	short.free()
	other.free()

## The same comparison as above, for all three of the home block's own buildings — hers and the
## two flanking the door notch — matched up by lot, since the lots themselves are already identical
## across seeds.
func _test_every_home_block_building_is_the_same_across_two_seeds(t) -> void:
	var short := _city_for(t, SHORT_SEED)
	var other := _city_for(t, OTHER_SEED)
	var short_by_lot := _home_buildings_by_lot(short)
	var other_by_lot := _home_buildings_by_lot(other)
	t.check(short_by_lot.size() == 3 and other_by_lot.size() == 3,
			"both seeds build all three home-block buildings (%d vs %d)"
			% [short_by_lot.size(), other_by_lot.size()])
	for lot: Rect2i in short_by_lot:
		t.check(other_by_lot.has(lot), "lot %s exists on both seeds" % lot)
		if not other_by_lot.has(lot):
			continue
		var a: Building = short_by_lot[lot]
		var b: Building = other_by_lot[lot]
		t.check(a.wall_tiles() == b.wall_tiles(), "lot %s: floor count matches across seeds" % lot)
		t.check(a.variant == b.variant, "lot %s: colour variant matches across seeds" % lot)
		t.check(a._window_style == b._window_style, "lot %s: window style matches across seeds" % lot)
		t.check(a._windows == b._windows, "lot %s: lit-window pattern matches across seeds" % lot)
		t.check(a._roof_furniture == b._roof_furniture, "lot %s: roof furniture matches across seeds" % lot)
	short.free()
	other.free()

# --------------------------------------------------------------------- height ---

## `City._home_building_height()` needs the door building's own lot at least
## `City.HOME_BUILDING_WALL_ROWS + 1` tiles deep for four wall rows to leave a roof at all
## (`Building.wall_tiles()`'s own hard clamp to `rows() - 1`) — checked directly against
## `CityGenerator`'s own output, cheaply, across a wide spread of seeds, rather than building a
## full `City` scene sixty times over. Never found short: see
## `_test_the_home_block_lot_geometry_is_already_seed_independent` for why not — the door
## building's own lot does not move.
func _test_the_home_block_lot_is_deep_enough_for_four_wall_rows_on_a_spread_of_seeds(t) -> void:
	var checked := 0
	for i in WIDE_SWEEP_SEEDS:
		var seed_value := 1000 + i * 8191
		var map := CityGenerator.generate(seed_value)
		var door_rect := _deepest_home_block_rect(map)
		t.check(door_rect.size.y - 1 >= City.HOME_BUILDING_WALL_ROWS,
				"seed %d: the door building's own lot (%s) is deep enough for %d wall rows and a roof"
				% [seed_value, door_rect, City.HOME_BUILDING_WALL_ROWS])
		checked += 1
	t.check(checked == WIDE_SWEEP_SEEDS, "the sweep checked every seed it asked for (%d)" % checked)

## The same guarantee end to end through a real `City` and `Building.wall_tiles()`, on a smaller
## spread since this one pays for a full city build each time.
func _test_her_building_has_at_least_four_wall_rows_on_a_spread_of_seeds(t) -> void:
	var checked := 0
	for i in CITY_SWEEP_SEEDS:
		var seed_value := 500_000 + i * 104_729
		var city := _city_for(t, seed_value)
		var building: Building = city._home_door_building()
		t.check(building != null,
				"seed %d: the door notch stands in front of a home-block building" % seed_value)
		if building:
			t.check(building.wall_tiles() >= City.HOME_BUILDING_WALL_ROWS,
					"seed %d: her own building has at least %d wall rows (%d)"
					% [seed_value, City.HOME_BUILDING_WALL_ROWS, building.wall_tiles()])
			t.check(building.neighbor_window_row() == 3,
					"seed %d: the neighbor's window row is always the third floor" % seed_value)
			checked += 1
		city.free()
	t.check(checked == CITY_SWEEP_SEEDS, "the sweep built every seed it asked for (%d)" % checked)

# ----------------------------------------------------------- other blocks unchanged ---

## Proof that a non-home building still rolls with the seed: matched by lot across two seeds, at
## least one still differs in colour variant or floor count — if this ever reads zero, the fix
## has stopped being a home-block-only fix.
func _test_non_home_buildings_still_roll_the_seed(t) -> void:
	var short := _city_for(t, SHORT_SEED)
	var other := _city_for(t, OTHER_SEED)
	var short_by_lot := {}
	for building: Building in short.buildings():
		if not building.is_home_building:
			short_by_lot[building.lot] = building
	var compared := 0
	var differing := 0
	for building: Building in other.buildings():
		if building.is_home_building or not short_by_lot.has(building.lot):
			continue
		compared += 1
		var partner: Building = short_by_lot[building.lot]
		if partner.variant != building.variant or partner.wall_tiles() != building.wall_tiles():
			differing += 1
	t.check(compared > 20, "the sweep found enough shared non-home lots to compare (%d)" % compared)
	t.check(differing > 0,
			"at least one non-home building still rolls differently across seeds (%d of %d differ)"
			% [differing, compared])
	short.free()
	other.free()

## The strongest form of "other blocks' rolls do not change": `City._variant_for()` and
## `City._height_for()` still produce exactly what their own pre-existing formula would, replayed
## here by hand, for every non-home building on two seeds — proof the home-block branch is an
## early return rather than a change to the shared code beneath it.
func _test_non_home_rolls_replay_the_unchanged_formula(t) -> void:
	for seed_value in [SHORT_SEED, OTHER_SEED]:
		var city := _city_for(t, seed_value)
		var checked := 0
		for building: Building in city.buildings():
			if building.is_home_building or building.power_station:
				continue
			var rect := building.lot
			var expected_variant := absi(hash("%d:%d:%d"
					% [city.map.seed_used, rect.position.x, rect.position.y]))
			t.check(building.variant == expected_variant,
					"seed %d, lot %s: a non-home building's own colour variant still comes from City._variant_for()'s original stream"
					% [seed_value, rect])
			var expected_height := _replayed_height(city.map, rect)
			t.close_to(building.height, expected_height,
					"seed %d, lot %s: a non-home building's own height still comes from City._height_for()'s original stream"
					% [seed_value, rect], 0.01)
			checked += 1
		t.check(checked > 0, "seed %d: the replay found a non-home building to check" % seed_value)
		city.free()

## Replays `City._height_for()`'s own pre-existing RNG stream for a non-home rect: the same formula
## the function still runs unchanged, asked directly here since the function itself is a private
## instance method with no static twin to call.
static func _replayed_height(map: CityMap, rect: Rect2i) -> float:
	var range_tiles: Vector2i = City._HEIGHT_TILES[map.starting_purpose(_block_of(rect))]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("h:%d:%d:%d" % [map.seed_used, rect.position.x, rect.position.y])
	var tiles := rng.randi_range(range_tiles.x, range_tiles.y)
	var lot_depth_tiles := rect.size.y
	var cap := maxi(1, mini(lot_depth_tiles - 1, floori(lot_depth_tiles * City.MAX_HEIGHT_FRACTION)))
	return mini(tiles, cap) * float(Tuning.TILE_SIZE)
