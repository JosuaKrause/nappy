extends RefCounted
## The city degrades: `Tuning.degradation_for()`, the cracked ground `GroundTiles` picks from it,
## the litter and garbage sacks it places, and the storefronts and windows a building shutters.
##
## None of this touches a walkable tile, a cost or a lane — it is presentation read off one curve
## — so what is checked here is the curve's own shape and that every downstream picker reads it
## the same way: deterministic per tile, non-decreasing with the day, and off entirely before the
## city has anything to show.

const RecordingFrontDrawer := preload("res://tests/recording_front_drawer.gd")
const UI := preload("res://tests/ui_screens.gd")
## What a building's front shows, read off the pictures it was drawn with.
const FrontReads := preload("res://tests/front_reads.gd")

const BASE_SEED := 40200
const SEEDS := 3

func run(t) -> void:
	_test_the_curve(t)
	_test_cracks_are_deterministic_and_grow(t)
	_test_pavement_cracks_before_road(t)
	_test_litter_stays_off_roads_and_calm_ground(t)
	_test_litter_grows_with_the_day(t)
	_test_sacks_wait_for_the_curve_then_alleys_before_fronts(t)
	_test_the_mouse_prefers_a_pile(t)
	await _test_boarded_storefronts_and_windows_shutter(t)
	await _test_a_burnt_building_shows_nothing_intact(t)
	await _test_ambient_shuttering_waits_for_the_curve(t)
	await _test_storefront_variants_use_seeded_bags(t)

# ---------------------------------------------------------------------- the curve ---

func _test_the_curve(t) -> void:
	t.check(Tuning.degradation_for(1) == 0.0, "day 1 is before the curve starts")
	t.check(Tuning.degradation_for(Tuning.DEGRADATION_FIRST_DAY - 1) == 0.0,
			"the day before DEGRADATION_FIRST_DAY is still zero")
	t.check(Tuning.degradation_for(Tuning.DEGRADATION_FIRST_DAY) > 0.0,
			"the curve's own first day already shows some decline, not the day after")
	t.check(Tuning.degradation_for(Tuning.RUN_LENGTH_DAYS) == 1.0,
			"the curve reaches its maximum on the run's last day")
	var last := -1.0
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var value := Tuning.degradation_for(day)
		t.check(value >= last, "the curve never drops from one day to the next (day %d)" % day)
		last = value

# ---------------------------------------------------------------------- cracks ---

## Every tile of `type` in the map, so the crack tests do not care which block purposes a seed
## happened to generate.
static func _tiles_of(map: CityMap, type: GameEnums.TileType) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if map.tile_at(tile) == type:
				found.append(tile)
	return found

static func _count_cracked(map: CityMap, tiles: Array[Vector2i], day: int) -> int:
	var count := 0
	for tile in tiles:
		if GroundTiles.source_for(map, tile, day) != GroundTiles.source_for(map, tile, 1):
			count += 1
	return count

func _test_cracks_are_deterministic_and_grow(t) -> void:
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i)
		var sidewalks := _tiles_of(map, GameEnums.TileType.SIDEWALK)
		var baseline := {}
		for tile in sidewalks:
			baseline[tile] = GroundTiles.source_for(map, tile, 1)

		var last_count := -1
		for day in [1, Tuning.DEGRADATION_FIRST_DAY, 8, 11, Tuning.RUN_LENGTH_DAYS]:
			var count := 0
			for tile in sidewalks:
				var source := GroundTiles.source_for(map, tile, day)
				t.check(source == GroundTiles.source_for(map, tile, day),
						"the same tile on the same day always answers the same source")
				if source != baseline[tile]:
					count += 1
			if last_count >= 0:
				t.check(count >= last_count,
						"the share of cracked sidewalk tiles never drops from day to day (seed %d, day %d)"
						% [BASE_SEED + i, day])
			last_count = count
		t.check(_count_cracked(map, sidewalks, 1) == 0, "day 1 has no cracked sidewalk tiles")

func _test_pavement_cracks_before_road(t) -> void:
	var total_sidewalk := 0
	var total_road := 0
	var cracked_sidewalk := 0
	var cracked_road := 0
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i)
		var sidewalks := _tiles_of(map, GameEnums.TileType.SIDEWALK)
		var roads := _tiles_of(map, GameEnums.TileType.ROAD)
		total_sidewalk += sidewalks.size()
		total_road += roads.size()
		cracked_sidewalk += _count_cracked(map, sidewalks, Tuning.RUN_LENGTH_DAYS)
		cracked_road += _count_cracked(map, roads, Tuning.RUN_LENGTH_DAYS)
	var share_sidewalk := float(cracked_sidewalk) / float(maxi(1, total_sidewalk))
	var share_road := float(cracked_road) / float(maxi(1, total_road))
	t.check(share_sidewalk > share_road,
			"on the last day a larger share of pavement is cracked than of road (%.3f vs %.3f)"
			% [share_sidewalk, share_road])

# ---------------------------------------------------------------------- litter ---

func _test_litter_stays_off_roads_and_calm_ground(t) -> void:
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i)
		var placed := Litter.placed(map, Tuning.RUN_LENGTH_DAYS)
		t.check(not placed.is_empty(), "the last day places at least some litter (seed %d)" % [BASE_SEED + i])
		for entry in placed:
			var tile := map.world_to_tile(entry.position)
			var type := map.tile_at(tile)
			t.check(type != GameEnums.TileType.ROAD and type != GameEnums.TileType.CROSSING,
					"no litter decal lands on the road's own lanes")
			t.check(not Tile.is_calm(type), "no litter decal lands inside a calm area")

func _test_litter_grows_with_the_day(t) -> void:
	var map := CityGenerator.generate(BASE_SEED)
	t.check(Litter.placed(map, 1).is_empty(), "day 1 places no litter")
	var last := 0
	for day in [Tuning.DEGRADATION_FIRST_DAY, 8, 11, Tuning.RUN_LENGTH_DAYS]:
		var count := Litter.placed(map, day).size()
		t.check(count >= last, "litter count never drops from day to day")
		last = count

# ---------------------------------------------------------------------- sacks ---

func _test_sacks_wait_for_the_curve_then_alleys_before_fronts(t) -> void:
	var map := CityGenerator.generate(BASE_SEED)
	t.check(GarbageSacks.placed(map, Tuning.DEGRADATION_FIRST_DAY - 1).is_empty(),
			"no sack stands before the curve starts")
	var at_onset := GarbageSacks.placed(map, Tuning.DEGRADATION_FIRST_DAY)
	for entry in at_onset:
		var tile := map.world_to_tile(entry.position)
		t.check(map.tile_at(tile) == GameEnums.TileType.ALLEY,
				"on the curve's own first day, every sack stands in an alley")
	if GarbageSacks.FRONT_DAY <= Tuning.RUN_LENGTH_DAYS:
		var at_front_day := GarbageSacks.placed(map, GarbageSacks.FRONT_DAY)
		for entry in at_front_day:
			var tile := map.world_to_tile(entry.position)
			var type := map.tile_at(tile)
			t.check(type == GameEnums.TileType.ALLEY or type == GameEnums.TileType.SIDEWALK,
					"a sack only ever stands in an alley or on a sidewalk")

## **The alley mouse lands beside a garbage-sack pile more often than the ground alone would put it
## there.** The last day is planned through `build_day()` on pinned maps, each from several rolls,
## and every mouse it stands is asked whether it is within a tile of a pile
## (`GarbageSacks.alley_pile_tiles()`). Without the preference a mouse is a uniform pick of the
## alley ground it may stand on (`EventScheduler.open_ground_for()`), so each lands near a pile with
## the probability of that ground's share of such tiles, and the count near is a sum of those
## chances: its mean is the sum of the shares and its variance the sum of share * (1 - share). With
## the preference an alley location beside a pile draws the mouse five times as often (itself and
## `_MOUSE_PILE_EXTRA_COPIES` more, `RuledLocationGround.scale()`) and the mouse it draws is offered
## the tiles beside the pile first. The bar is the mean plus five standard deviations of the
## no-preference count, far enough above chance that no pinned roll passes by luck; dropping the
## preference puts the count near the mean and fails it.
func _test_the_mouse_prefers_a_pile(t) -> void:
	var day := Tuning.RUN_LENGTH_DAYS
	var mouse := EventCatalogue.by_id("alley_mouse")
	var mice := 0
	var near := 0
	var expected := 0.0
	var variance := 0.0
	for i in 12:
		var map := CityGenerator.generate(BASE_SEED + i * 173)
		var piles := GarbageSacks.alley_pile_tiles(map, day)
		if piles.is_empty():
			continue
		var candidates := EventScheduler.open_ground_for(mouse, map, {})
		var beside := {}
		for tile in candidates:
			for pile in piles:
				if maxi(absi(tile.x - pile.x), absi(tile.y - pile.y)) <= 1:
					beside[tile] = true
					break
		var share := float(beside.size()) / float(candidates.size())
		for roll in 8:
			var rng := RandomNumberGenerator.new()
			rng.seed = 1000 + roll
			for plan in EventScheduler.build_day(DaySpec.for_day(day), rng, map,
					CalmAreas.of(map)).placements():
				if plan.def.id != mouse.id:
					continue
				mice += 1
				expected += share
				variance += share * (1.0 - share)
				if beside.has(map.world_to_tile(plan.position)):
					near += 1
	t.check(mice > 100, "the pinned last days stand enough mice to count (%d)" % mice)
	var bar := expected + 5.0 * sqrt(variance)
	t.check(float(near) > bar,
			"mice land beside a sack pile more often than their ground alone would put them (%d of %d, chance %.0f, bar %.0f)"
			% [near, mice, expected, bar])

# ---------------------------------------------------------------------- buildings ---

func _test_boarded_storefronts_and_windows_shutter(t) -> void:
	var building := FrontReads.new_building()
	building.district = GameEnums.BlockPurpose.COMMERCIAL
	building.footprint = Vector2(96.0, 96.0)
	building.height = 64.0
	t.add_child(building)
	building.condition = Building.Condition.BOARDED
	building.day = Tuning.RUN_LENGTH_DAYS
	await UI.frames(t, 2)
	var front = FrontReads.look(building)
	t.check(_variants(front).size() == building.columns() / 2,
			"a three-column facade has one storefront variant per complete pair")
	t.check(front.ground_floor_at(1) == &"",
			"the second column of a storefront pair draws no duplicate texture")
	t.check(front.ground_floor_at(2) == Building.WALL_BASE,
			"an odd final commercial column keeps the ordinary wall base")
	for col in range(0, building.columns() - 1, 2):
		var texture: StringName = front.ground_floor_at(col)
		t.check(Building.STOREFRONT_SHUTTERED_TEXTURES.has(texture),
				"a boarded commercial ground floor shows a shuttered storefront")
	var windows := 0
	for cell: Vector2i in front.window_cells():
		windows += 1
		t.check(front.window_at(cell.x, cell.y) == Building.WINDOW_SHUTTERED_DARK,
				"a boarded building's windows are shuttered and dark, never lit")
	t.check(windows == building.columns() * (building.wall_tiles() - 1),
			"and every upper floor's cell draws one (%d)" % windows)
	building.free()

## **A burnt building is drawn burnt, not only dark**: *"the *building* is what needs to be burnt"*
## (olive-koala, statement 4). On a burnt front of any district, no window, door, storefront or
## front parapet is one of the pictures an intact front draws. Each front is handed a drawer that
## records what it paints, as the city hands it the real one, and what is asked is what the front
## was drawn with: every picture against the intact ones, and a burnt parapet over each column, a
## burnt window in each window cell and a burnt door on a door column.
func _test_a_burnt_building_shows_nothing_intact(t) -> void:
	var intact: Array[StringName] = [
		Building.WINDOW_DARK, Building.WINDOW_LIT, Building.WINDOW_TALL_DARK,
		Building.WINDOW_TALL_LIT, Building.WINDOW_SHUTTERED_DARK, Building.WINDOW_SHUTTERED_LIT,
		Building.ENTRANCE_DOOR, Building.ENTRANCE_DOOR_INDUSTRIAL, Building.ROOF_EDGE_S,
	]
	intact.append_array(Building.STOREFRONT_TEXTURES)
	intact.append_array(Building.STOREFRONT_AWNING_TEXTURES)
	intact.append_array(Building.STOREFRONT_SHUTTERED_TEXTURES)
	var shops := 0
	var doors := 0
	var windows := 0
	var buildings: Array[Building] = []
	var fronts: Array[RecordingFrontDrawer] = []
	for i in 12:
		var building := Building.new()
		var front := RecordingFrontDrawer.new()
		building.front_drawer = front
		building.district = [GameEnums.BlockPurpose.COMMERCIAL, GameEnums.BlockPurpose.RESIDENTIAL,
				GameEnums.BlockPurpose.INDUSTRIAL][i % 3]
		building.footprint = Vector2(128.0, 128.0)
		building.height = 96.0
		building.position = Vector2(9000.0 + i * 173.0, 9100.0 + i * 61.0)
		t.add_child(building)
		building.condition = Building.Condition.BURNT
		building.day = Tuning.RUN_LENGTH_DAYS
		buildings.append(building)
		fronts.append(front)
	await UI.frames(t, 2)
	for i in buildings.size():
		var building := buildings[i]
		var drawn := fronts[i].pictures()
		var parapets := 0
		for picture in drawn:
			if picture == Building.ROOF_EDGE_S or Building.ROOF_EDGE_S_BURNT.has(picture):
				parapets += 1
		t.check(parapets == building.columns(),
				"a burnt front is drawn with a front parapet over each of its %d columns (%d)"
				% [building.columns(), parapets])
		# What was drawn is asked alone: how many cells and whether a door column are the front's
		# layout, and the mock says what each was drawn with.
		# Every cell above the ground floor, on a front that is not hers.
		var window_cells := (building.wall_tiles() - 1) * building.columns()
		var burnt_windows := drawn.count(Building.WINDOW_BURNT)
		t.check(window_cells > 0 and burnt_windows == window_cells,
				"a burnt front is drawn with a burnt window in each of its %d window cells (%d)"
				% [window_cells, burnt_windows])
		var door_drawn := drawn.count(Building.ENTRANCE_DOOR_BURNT)
		# A shop is a commercial front's way in, so only it has no door of its own.
		t.check(door_drawn == int(building.district != GameEnums.BlockPurpose.COMMERCIAL),
				"a burnt front with a door column is drawn with its burnt door, once (%d)" % door_drawn)
		windows += burnt_windows
		shops += drawn.count(Building.STOREFRONT_BURNT)
		doors += door_drawn
		for texture in drawn:
			t.check(not intact.has(texture),
					"a burnt %s front draws nothing intact (%s)"
					% [GameEnums.BlockPurpose.keys()[building.district], texture])
		building.free()
	t.check(windows > 0 and shops > 0 and doors > 0,
			"burnt windows, shops and doors were drawn to ask about (%d, %d, %d)"
			% [windows, shops, doors])

func _test_ambient_shuttering_waits_for_the_curve(t) -> void:
	var any_shuttered_late := false
	var any_shuttered_early := false
	var buildings: Array[Building] = []
	for i in range(0, 24):
		var building := FrontReads.new_building()
		building.district = GameEnums.BlockPurpose.COMMERCIAL
		building.footprint = Vector2(96.0, 96.0)
		building.height = 64.0
		building.position = Vector2(i * 200.0, i * 137.0)
		t.add_child(building)
		building.condition = Building.Condition.LIVED_IN
		building.day = 1
		buildings.append(building)
	await UI.frames(t, 2)
	for building in buildings:
		var front = FrontReads.look(building)
		for col in building.columns():
			if Building.STOREFRONT_SHUTTERED_TEXTURES.has(front.ground_floor_at(col)):
				any_shuttered_early = true
		building.day = Tuning.RUN_LENGTH_DAYS
	await UI.frames(t, 2)
	for building in buildings:
		var front = FrontReads.look(building)
		for col in building.columns():
			if Building.STOREFRONT_SHUTTERED_TEXTURES.has(front.ground_floor_at(col)):
				any_shuttered_late = true
		building.free()
	t.check(not any_shuttered_early, "a lived-in block shows no shuttered storefront on day 1")
	t.check(any_shuttered_late,
			"by the last day some lived-in commercial storefronts have shuttered ahead of any block turning")

func _test_storefront_variants_use_seeded_bags(t) -> void:
	var sampled: Array[Building] = []
	var first_orders := {}
	var bag_width := Building.STOREFRONT_TEXTURES.size()
	for i in 16:
		var building := FrontReads.new_building()
		building.district = GameEnums.BlockPurpose.COMMERCIAL
		building.footprint = Vector2(512.0, 96.0)
		building.height = 64.0
		building.position = Vector2(7000.0 + i * 137.0, 7100.0 + i * 89.0)
		t.add_child(building)
		sampled.append(building)
	var same_seed := FrontReads.new_building()
	same_seed.district = GameEnums.BlockPurpose.COMMERCIAL
	same_seed.footprint = Vector2(512.0, 96.0)
	same_seed.height = 64.0
	same_seed.position = sampled[0].position
	t.add_child(same_seed)
	var odd := FrontReads.new_building()
	odd.district = GameEnums.BlockPurpose.COMMERCIAL
	odd.footprint = Vector2(160.0, 96.0)
	odd.height = 64.0
	t.add_child(odd)
	var shallow := FrontReads.new_building()
	shallow.district = GameEnums.BlockPurpose.COMMERCIAL
	shallow.footprint = Vector2(160.0, 32.0)
	shallow.height = 32.0
	t.add_child(shallow)
	await UI.frames(t, 2)
	for building in sampled:
		var variants := _variants(FrontReads.look(building))
		for storefront_index in variants.size():
			if storefront_index > 0:
				t.check(variants[storefront_index] != variants[storefront_index - 1],
						"neighboring storefronts use different variants")
			if storefront_index % bag_width != 0 \
					or storefront_index + bag_width > variants.size():
				continue
			var bag := variants.slice(storefront_index, storefront_index + bag_width)
			var unique_bag := {}
			for storefront_variant in bag:
				unique_bag[storefront_variant] = true
			t.check(unique_bag.size() == bag_width,
					"each complete storefront bag uses every available variant once")
		var order_key := ""
		for storefront_variant in variants.slice(0, bag_width):
			order_key += "%d," % storefront_variant
		first_orders[order_key] = true
	t.check(first_orders.size() > 1,
			"different building seeds produce more than one storefront bag order")

	t.check(_variants(FrontReads.look(sampled[0])) == _variants(FrontReads.look(same_seed)),
			"a storefront variant bag is reproducible from the building seed")
	var variants_before_state_changes := _variants(FrontReads.look(sampled[0])).duplicate()
	sampled[0].height = 96.0
	sampled[0].height = 64.0
	sampled[0].day = Tuning.RUN_LENGTH_DAYS
	sampled[0].condition = Building.Condition.BOARDED
	await UI.frames(t, 2)
	t.check(_variants(FrontReads.look(sampled[0])) == variants_before_state_changes,
			"day and condition changes preserve storefront variants")

	t.check(_variants(FrontReads.look(odd)).size() == 2,
			"an odd-width facade leaves its final wall column without a storefront")
	t.check(_variants(FrontReads.look(shallow)).is_empty(),
			"a one-row commercial facade keeps its ordinary wall base")
	t.check(FrontReads.look(shallow).ground_floor_at(0) == Building.WALL_BASE,
			"a one-row commercial facade draws its ordinary wall base")
	for building in sampled:
		building.free()
	same_seed.free()
	odd.free()
	shallow.free()

## The storefront variant behind each drawn storefront of the front `front` reads, left to right: the
## index of the picture the ground floor shows in the first column of each storefront pair, in
## whichever of the plain, awning or shuttered sets it comes from.
func _variants(front) -> Array[int]:
	var found: Array[int] = []
	for col in range(0, front.building.columns(), 2):
		var texture: StringName = front.ground_floor_at(col)
		for set: Array in [Building.STOREFRONT_TEXTURES, Building.STOREFRONT_AWNING_TEXTURES,
				Building.STOREFRONT_SHUTTERED_TEXTURES]:
			if set.has(texture):
				found.append(set.find(texture))
				break
	return found
