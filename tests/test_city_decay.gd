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

# ---------------------------------------------------------------------- the curve ---

func _test_the_curve(t) -> void:
	t.check(Tuning.degradation_for(1) == 0.0, "day 1 is before the curve starts")
	t.check(Tuning.degradation_for(Tuning.DEGRADATION_FIRST_DAY - 1) == 0.0,
			"the day before DEGRADATION_FIRST_DAY is still zero")
	t.check(Tuning.degradation_for(Tuning.DEGRADATION_FIRST_DAY) >= 0.0,
			"the curve's own first day does not go negative")
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
