extends RefCounted
## M185's fixing half — the home block has fixed visuals: every building on it draws the same on
## every seed (window style, which windows are lit, height, front and roof furniture), and her own
## building — the one lot the door's own world-space span stands in front of — always has a third
## floor, where she lives and the escape begins (PLAYTEST-131), so it never depends on a height
## roll (PLAYTEST-134: "the home building shouldn't depend on the seed. I thought we fixed
## that?"). The neighbor's boarded window (`Building.neighbor_window_row()`) boards that same
## floor, the top one, down the hall from her own door — off the top of the screen at the normal
## camera on her doorstep, since she starts facing away down the street and the camera leads the
## view with her facing, but in frame once she turns to face the building (PLAYTEST-134, statement
## 4 revisited).
##
## **The home block's own lot geometry was already seed-independent before this change** —
## `CityGenerator` carves it from `Tuning.BLOCK_SIZE`, `CityGenerator.HOME_SIZE_TILES` and the fixed
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
const UI := preload("res://tests/ui_screens.gd")
## What a building's front shows, read off the pictures it was drawn with.
const FrontReads := preload("res://tests/front_reads.gd")
## Her street door and the building it stands in front of, read off the city's nodes.
const HomeDoorReads := preload("res://tests/home_door_reads.gd")
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

func run(t: TestRunner) -> void:
	_test_the_home_block_lot_geometry_is_already_seed_independent(t)
	await _test_every_home_block_building_is_the_same_across_two_seeds(t)
	_test_the_home_block_lot_is_deep_enough_for_four_wall_rows_on_a_spread_of_seeds(t)
	_test_her_building_has_at_least_four_wall_rows_on_a_spread_of_seeds(t)
	_test_non_home_buildings_still_roll_the_seed(t)
	_test_non_home_rolls_are_a_function_of_the_seed_and_the_lot(t)

# ------------------------------------------------------------------- fixtures ---

static func _city_for(t: TestRunner, seed_value: int) -> City:
	var map := CityGenerator.generate(seed_value)
	var city: City = RunCity.with_own_run(CITY_SCENE, seed_value)
	t.add_child(city)
	city.build(map)
	return city

## The window picture drawn on each wall cell of `building`, row by row: the building's window style
## and which cells are lit, in one list. Read off what the building was drawn with, so it has been
## handed a recording drawer (`FrontReads.watch()`) and drawn.
static func _window_pictures(building: Building) -> Array[StringName]:
	return FrontReads.look(building).window_pictures_in_order()

## Every home-block building rect, sorted so two independently-collected lists compare directly.
static func _home_block_rects(map: CityMap) -> Array[Rect2i]:
	var rects: Array[Rect2i] = []
	for rect in map.building_rects:
		if City.block_of(rect) == map.home_block:
			rects.append(rect)
	rects.sort_custom(func(a: Rect2i, b: Rect2i) -> bool: return a.position < b.position)
	return rects

## The deepest of the home block's own rects — the one the door notch's world span stands in front
## of, since a wider, shallower notch never outgrows it on any lot `CityGenerator` carves.
static func _deepest_home_block_rect(map: CityMap) -> Rect2i:
	var deepest := Rect2i()
	for rect in map.building_rects:
		if City.block_of(rect) == map.home_block and rect.size.y > deepest.size.y:
			deepest = rect
	return deepest

## Every home-block `Building`, keyed by its own lot.
static func _home_buildings_by_lot(city: City) -> Dictionary:
	var result := {}
	for building: Building in city.buildings():
		if building.is_on_home_block():
			result[building.lot_rect()] = building
	return result

## The roof units standing on `building`'s roof, as the city's entity layer holds them (the layer a
## live city parents `Building.RoofObject` to): each a node at its feet, so a unit belongs to the
## building whose lot its feet are on (a cell's feet are at its bottom edge, so they are below the
## lot's north edge and at most on its south one, which keeps two lots that meet from sharing one).
## Each is `[where, picture]`, `where` taken from the building's own origin so the same roof on two
## cities compares directly, in the layer's own order.
static func _roof_units_on(city: City, building: Building) -> Array:
	var lot := city.map.tile_rect_to_world(building.lot_rect())
	var units: Array = []
	for node in city.get_node("Entities").get_children():
		var unit := node as Building.RoofObject
		if unit == null:
			continue
		var feet := unit.position
		if feet.x >= lot.position.x and feet.x < lot.end.x \
				and feet.y > lot.position.y and feet.y <= lot.end.y:
			units.append([feet - building.position, unit.texture_key])
	return units

## Every roof unit in the city's entity layer, which the lots between them account for.
static func _roof_units_in(city: City) -> int:
	var count := 0
	for node in city.get_node("Entities").get_children():
		if node is Building.RoofObject:
			count += 1
	return count

## Whether the helper above can see a roof unit at all: some building that is not the home block's
## carries one, and every unit in the city stands on exactly one lot.
func _check_the_units_are_seen(t: TestRunner, city: City, label: String) -> void:
	var seen := 0
	var with_units := 0
	for building: Building in city.buildings():
		var units := _roof_units_on(city, building)
		seen += units.size()
		if not building.is_on_home_block() and not units.is_empty():
			with_units += 1
	t.check(with_units > 0, "%s: some building off the home block carries roof units (%d)" % [label, with_units])
	t.check(seen == _roof_units_in(city),
			"%s: every roof unit in the city stands on one lot (%d of %d)" % [label, seen, _roof_units_in(city)])

# ------------------------------------------------------------- the lot geometry ---

## The premise the rest of this suite leans on: the home block's own three lots — the door's own
## and the two flanking the notch — are the same rects on every seed, because `CityGenerator`
## derives them from `Tuning` constants and the fixed middle block alone.
func _test_the_home_block_lot_geometry_is_already_seed_independent(t: TestRunner) -> void:
	var short := CityGenerator.generate(SHORT_SEED)
	var other := CityGenerator.generate(OTHER_SEED)
	var short_rects := _home_block_rects(short)
	var other_rects := _home_block_rects(other)
	t.check(short_rects == other_rects,
			"the home block's own lot rects are identical on every seed (seed %d: %s, seed %d: %s)"
			% [SHORT_SEED, short_rects, OTHER_SEED, other_rects])

# --------------------------------------------------------------- fixed visuals ---

## Her own building, end to end through `City.build()`, and the two flanking the door notch: the
## same floor count, colour variant, window style, lit-window pattern and roof furniture (always
## empty — see the class doc) on two seeds with nothing else in common, including the one
## PLAYTEST-134 found short. The buildings are matched up by lot, since the lots themselves are
## already identical across seeds.
func _test_every_home_block_building_is_the_same_across_two_seeds(t: TestRunner) -> void:
	var short := _city_for(t, SHORT_SEED)
	var other := _city_for(t, OTHER_SEED)
	var short_by_lot := _home_buildings_by_lot(short)
	var other_by_lot := _home_buildings_by_lot(other)
	for by_lot: Dictionary in [short_by_lot, other_by_lot]:
		for lot: Rect2i in by_lot:
			FrontReads.watch(by_lot[lot])
	await UI.frames(t, 2)
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
		t.check(a.look_variant() == b.look_variant(), "lot %s: colour variant matches across seeds" % lot)
		t.check(not _window_pictures(a).is_empty() and _window_pictures(a) == _window_pictures(b),
				"lot %s: window style and lit-window pattern match across seeds" % lot)
		t.check(a.scenery_resident and b.scenery_resident,
				"lot %s: the scenery is built on both seeds, so the roof is drawn" % lot)
		# Every home-block roof is empty (see the class doc), so comparing the two seeds' lists would
		# compare empty with empty; each is asked to be empty instead.
		t.check(_roof_units_on(short, a).is_empty() and _roof_units_on(other, b).is_empty(),
				"lot %s: no roof furniture on either seed" % lot)
	_check_the_units_are_seen(t, short, "seed %d" % SHORT_SEED)
	_check_the_units_are_seen(t, other, "seed %d" % OTHER_SEED)
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
func _test_the_home_block_lot_is_deep_enough_for_four_wall_rows_on_a_spread_of_seeds(t: TestRunner) -> void:
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
func _test_her_building_has_at_least_four_wall_rows_on_a_spread_of_seeds(t: TestRunner) -> void:
	var checked := 0
	for i in CITY_SWEEP_SEEDS:
		var seed_value := 500_000 + i * 104_729
		var city := _city_for(t, seed_value)
		var building: Building = HomeDoorReads.building(city)
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
func _test_non_home_buildings_still_roll_the_seed(t: TestRunner) -> void:
	var short := _city_for(t, SHORT_SEED)
	var other := _city_for(t, OTHER_SEED)
	var short_by_lot := {}
	for building: Building in short.buildings():
		if not building.is_on_home_block():
			short_by_lot[building.lot_rect()] = building
	var compared := 0
	var differing := 0
	var variants_differing := 0
	var same_ground := 0
	var heights_differing := 0
	for building: Building in other.buildings():
		if building.is_on_home_block() or not short_by_lot.has(building.lot_rect()):
			continue
		compared += 1
		var partner: Building = short_by_lot[building.lot_rect()]
		if partner.look_variant() != building.look_variant():
			variants_differing += 1
		if partner.look_variant() != building.look_variant() or partner.wall_tiles() != building.wall_tiles():
			differing += 1
		# The height rolls within the range its block's purpose allows, so it is the lots whose
		# block has the same purpose on both seeds that show the roll itself.
		if partner.district == building.district and not building.power_station:
			same_ground += 1
			if not is_equal_approx(partner.height, building.height):
				heights_differing += 1
	t.check(compared > 20, "the sweep found enough shared non-home lots to compare (%d)" % compared)
	t.check(differing > 0,
			"at least one non-home building still rolls differently across seeds (%d of %d differ)"
			% [differing, compared])
	t.check(variants_differing > 0,
			"at least one non-home building's colour variant still rolls with the seed (%d of %d)"
			% [variants_differing, compared])
	t.check(heights_differing > 0,
			"at least one non-home building's height still rolls with the seed on a block of the "
			+ "same purpose (%d of %d)" % [heights_differing, same_ground])
	short.free()
	other.free()

## What the game hands out for a non-home building is a pure function of the seed and the lot, and
## still a roll: built twice on one seed every non-home building has the same colour variant and
## height; the height is a whole number of tiles, at least one and no more than the lot leaves a roof
## for (`City.MAX_HEIGHT_FRACTION` of its depth, and always at least a tile of roof unless the lot is
## one tile deep); and the heights of a city are not all one value, so the roll is not a constant.
## Which stream the roll comes from is the game's own business, so it is not copied here.
func _test_non_home_rolls_are_a_function_of_the_seed_and_the_lot(t: TestRunner) -> void:
	for seed_value: int in [SHORT_SEED, OTHER_SEED]:
		var city := _city_for(t, seed_value)
		var again := _city_for(t, seed_value)
		var twin := {}
		for building: Building in again.buildings():
			twin[building.lot_rect()] = building
		var checked := 0
		var heights := {}
		for building: Building in city.buildings():
			if building.is_on_home_block() or building.power_station:
				continue
			var rect := building.lot_rect()
			var partner: Building = twin.get(rect)
			t.check(partner != null and partner.look_variant() == building.look_variant(),
					"seed %d, lot %s: a non-home building's colour variant is the same on a rebuilt city"
					% [seed_value, rect])
			t.check(partner != null and is_equal_approx(partner.height, building.height),
					"seed %d, lot %s: and so is its height" % [seed_value, rect])
			var tiles := building.height / float(Tuning.TILE_SIZE)
			var cap := maxi(1, mini(rect.size.y - 1, floori(rect.size.y * City.MAX_HEIGHT_FRACTION)))
			t.check(is_equal_approx(tiles, roundf(tiles)) and tiles >= 1.0 and tiles <= cap,
					"seed %d, lot %s: its height (%.2f tiles) is whole, at least one and at most %d"
					% [seed_value, rect, tiles, cap])
			heights[roundi(tiles)] = true
			checked += 1
		t.check(checked > 0, "seed %d: the rebuild found a non-home building to check" % seed_value)
		# Within one block the lots roll separately: among those of one block (and one depth, whose
		# cap would otherwise tell them apart) there are at least two heights, in at least one group
		# in eight; and among those of one block at least two variants, in at least half the blocks.
		var by_block := {}
		var by_block_and_depth := {}
		for building: Building in city.buildings():
			if building.is_on_home_block() or building.power_station:
				continue
			var block := City.block_of(building.lot_rect())
			by_block[block] = by_block.get(block, []) + [building]
			var key := [block, building.lot_rect().size.y]
			by_block_and_depth[key] = by_block_and_depth.get(key, []) + [building]
		var varied_heights := 0
		var height_groups := 0
		for group: Array in by_block_and_depth.values():
			if group.size() < 2:
				continue
			height_groups += 1
			var seen := {}
			for building: Building in group:
				seen[roundi(building.height)] = true
			if seen.size() >= 2:
				varied_heights += 1
		var varied_variants := 0
		var variant_groups := 0
		for group: Array in by_block.values():
			if group.size() < 2:
				continue
			variant_groups += 1
			var seen := {}
			for building: Building in group:
				seen[building.look_variant()] = true
			if seen.size() >= 2:
				varied_variants += 1
		t.check(height_groups > 0 and varied_heights * 8 >= height_groups,
				"seed %d: at least one block in eight rolls different heights for lots of one depth (%d of %d)"
				% [seed_value, varied_heights, height_groups])
		t.check(variant_groups > 0 and varied_variants * 2 >= variant_groups,
				"seed %d: at least half the blocks roll different colour variants for their lots (%d of %d)"
				% [seed_value, varied_variants, variant_groups])
		t.check(heights.size() >= 2, "seed %d: the non-home heights take more than one value (%s)"
				% [seed_value, heights.keys()])
		city.free()
		again.free()
