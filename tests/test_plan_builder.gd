extends RefCounted
## `PlanBuilder`, the entry a recipe sites an authored row by (`place_at()`): the day's spacing,
## asked of the builder the game makes (`GamePlanBuilder.over()`) over the cached generated map of a
## seed with no city round it, since the spacing reads the candidate, the plans standing and the map
## alone.

const MapCache := preload("res://tests/city_map_cache.gd")
const SEED := 4242

func run(t: TestRunner) -> void:
	_test_place_at_sites_a_row_only_where_the_days_spacing_leaves_room(t)

## `PlanBuilder.place_at()`, the entry a recipe sites an authored row by, keeps the day's spacing:
## on a tile the same row already holds (the day's spacing refuses it: a body inside another's
## `EVENT_SPACING_ANY`) it answers null, and with the tile free of every other plan it answers the
## placement. The mast row stands for any catalogue row here; the spacing asks the candidate and the
## plans standing, not which row it is.
func _test_place_at_sites_a_row_only_where_the_days_spacing_leaves_room(t: TestRunner) -> void:
	var map := MapCache.of(SEED)
	var def := EventCatalogue.shipped().mast()
	var walled: Array[Rect2i] = []
	var tile := Vector2i(-1, -1)
	for candidate_tile in map.tiles_of_type(GameEnums.TileType.SIDEWALK):
		if SpawnSiting.is_legal_ground(map, candidate_tile, walled) \
				and not map.is_obstructed(candidate_tile):
			tile = candidate_tile
			break
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var none: Array[EventPlan] = []
	var builder := GamePlanBuilder.over(map)
	var first := builder.place_at(def, tile, rng, none)
	t.check(first != null and first.is_placed(),
			"with no plan standing, `place_at()` sites the row on a free sidewalk tile")
	if not first:
		return
	var crowded: Array[EventPlan] = [first]
	t.check(builder.place_at(def, tile, rng, crowded) == null,
			"on the tile a placed plan already holds, `place_at()` answers null")
	var far := Vector2i(-1, -1)
	for candidate_tile in map.tiles_of_type(GameEnums.TileType.SIDEWALK):
		if SpawnSiting.is_legal_ground(map, candidate_tile, walled) \
				and not map.is_obstructed(candidate_tile) and map.tile_to_world(candidate_tile) \
				.distance_to(first.placed_at()) > EventScheduler.EVENT_SPACING_ANY + 600.0:
			far = candidate_tile
			break
	var elsewhere := builder.place_at(def, far, rng, crowded)
	t.check(far != Vector2i(-1, -1) and elsewhere != null,
			"on a tile well clear of it, `place_at()` sites the row")
