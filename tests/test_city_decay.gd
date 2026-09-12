extends RefCounted
## The city degrades: `Tuning.degradation_for()`, the cracked ground `GroundTiles` picks from it,
## the litter and garbage sacks it places, and the storefronts and windows a building shutters.
##
## None of this touches a walkable tile, a cost or a lane — it is presentation read off one curve
## — so what is checked here is the curve's own shape and that every downstream picker reads it
## the same way: deterministic per tile, non-decreasing with the day, and off entirely before the
## city has anything to show.

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
	_test_boarded_storefronts_and_windows_shutter(t)
	_test_ambient_shuttering_waits_for_the_curve(t)
	_test_storefront_variants_use_seeded_bags(t)

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

func _test_the_mouse_prefers_a_pile(t) -> void:
	# Search a few seeds for one that actually placed an alley pile by the last day — the roll is
	# real, not guaranteed on any one seed, and this only tests the weighting once it exists.
	for i in range(0, 12):
		var map := CityGenerator.generate(BASE_SEED + i)
		var day := Tuning.RUN_LENGTH_DAYS
		var piles := GarbageSacks.alley_pile_tiles(map, day)
		if piles.is_empty():
			continue
		var candidates := _tiles_of(map, GameEnums.TileType.ALLEY)
		var weighted := EventScheduler._prefer_beside_a_sack_pile(candidates, map, day)
		t.check(weighted.size() > candidates.size(),
				"a candidate list gains extra copies once an alley pile exists")
		var candidate_set := {}
		for tile in candidates:
			candidate_set[tile] = true
		var weighted_set := {}
		for tile in weighted:
			weighted_set[tile] = true
		t.check(candidate_set.size() == weighted_set.size(),
				"the preference adds copies, never a tile that was not already a candidate")
		return
	t.check(true, "no seed in range rolled an alley pile by the last day — nothing to weight")

# ---------------------------------------------------------------------- buildings ---

func _test_boarded_storefronts_and_windows_shutter(t) -> void:
	var building := Building.new()
	building.district = GameEnums.BlockPurpose.COMMERCIAL
	building.footprint = Vector2(96.0, 96.0)
	building.height = 64.0
	t.add_child(building)
	building.condition = Building.Condition.BOARDED
	building.day = Tuning.RUN_LENGTH_DAYS
	for col in range(0, building.columns() - 1, 2):
		var texture := building._ground_floor_texture(col)
		t.check(Building.STOREFRONT_SHUTTERED_TEXTURES.has(texture),
				"a boarded commercial ground floor shows a shuttered storefront")
	for index in building.columns() * building.wall_tiles():
		var texture := building._window_texture(index)
		t.check(texture == Building.WINDOW_SHUTTERED_DARK,
				"a boarded building's windows are shuttered and dark, never lit")
	building.free()

func _test_ambient_shuttering_waits_for_the_curve(t) -> void:
	var any_shuttered_late := false
	var any_shuttered_early := false
	for i in range(0, 24):
		var building := Building.new()
		building.district = GameEnums.BlockPurpose.COMMERCIAL
		building.footprint = Vector2(96.0, 96.0)
		building.height = 64.0
		building.position = Vector2(i * 200.0, i * 137.0)
		t.add_child(building)
		building.condition = Building.Condition.LIVED_IN
		building.day = 1
		for col in building.columns():
			if Building.STOREFRONT_SHUTTERED_TEXTURES.has(building._ground_floor_texture(col)):
				any_shuttered_early = true
		building.day = Tuning.RUN_LENGTH_DAYS
		for col in building.columns():
			if Building.STOREFRONT_SHUTTERED_TEXTURES.has(building._ground_floor_texture(col)):
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
		var building := Building.new()
		building.district = GameEnums.BlockPurpose.COMMERCIAL
		building.footprint = Vector2(512.0, 96.0)
		building.height = 64.0
		building.position = Vector2(7000.0 + i * 137.0, 7100.0 + i * 89.0)
		t.add_child(building)
		sampled.append(building)
		for storefront_index in building._storefront_variant.size():
			if storefront_index > 0:
				t.check(building._storefront_variant[storefront_index] != building._storefront_variant[storefront_index - 1],
						"neighboring storefronts use different variants")
			if storefront_index % bag_width != 0 \
					or storefront_index + bag_width > building._storefront_variant.size():
				continue
			var bag := building._storefront_variant.slice(storefront_index, storefront_index + bag_width)
			var unique_bag := {}
			for storefront_variant in bag:
				unique_bag[storefront_variant] = true
			t.check(unique_bag.size() == bag_width,
					"each complete storefront bag uses every available variant once")
		var order_key := ""
		for storefront_variant in building._storefront_variant.slice(0, bag_width):
			order_key += "%d," % storefront_variant
		first_orders[order_key] = true
	t.check(first_orders.size() > 1,
			"different building seeds produce more than one storefront bag order")

	var same_seed := Building.new()
	same_seed.district = GameEnums.BlockPurpose.COMMERCIAL
	same_seed.footprint = Vector2(512.0, 96.0)
	same_seed.height = 64.0
	same_seed.position = sampled[0].position
	t.add_child(same_seed)
	t.check(sampled[0]._storefront_variant == same_seed._storefront_variant,
			"a storefront variant bag is reproducible from the building seed")
	var variants_before_state_changes := sampled[0]._storefront_variant.duplicate()
	sampled[0].height = 96.0
	sampled[0].height = 64.0
	sampled[0].day = Tuning.RUN_LENGTH_DAYS
	sampled[0].condition = Building.Condition.BOARDED
	t.check(sampled[0]._storefront_variant == variants_before_state_changes,
			"day and condition changes preserve storefront variants")

	var odd := Building.new()
	odd.district = GameEnums.BlockPurpose.COMMERCIAL
	odd.footprint = Vector2(160.0, 96.0)
	odd.height = 64.0
	t.add_child(odd)
	t.check(odd._storefront_variant.size() == 2,
			"an odd-width facade leaves its final wall column without a storefront")
	var shallow := Building.new()
	shallow.district = GameEnums.BlockPurpose.COMMERCIAL
	shallow.footprint = Vector2(160.0, 32.0)
	shallow.height = 32.0
	t.add_child(shallow)
	t.check(shallow._storefront_variant.is_empty(),
			"a one-row commercial facade keeps its ordinary wall base")
	for building in sampled:
		building.free()
	same_seed.free()
	odd.free()
	shallow.free()
