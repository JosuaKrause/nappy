@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## The cache of generated cities the rigs share (`tests/city_map_cache.gd`): that it hands out a
## seed's own city, a copy of its own to each caller, so nothing one caller does to its map reaches
## the next. Whether a copy is lossless is `tests/test_city_map.gd`'s.
##
## **A real generated city**, because the cache holds nothing else: it is the generator's map for a
## seed or it is nothing.

const MapCache := preload("res://tests/city_map_cache.gd")

const SEED := 4242

## A seed no other suite asks the cache for, so the first ask here is the process's first for it.
const _OWN_SEED := 6151

## Counts the generations the cache makes, handing back the generator's real map.
class CountingGenerator extends RefCounted:
	var calls := 0

	func generate(seed_value: int) -> CityMap:
		calls += 1
		return CityGenerator.generate(seed_value)

func run(t) -> void:
	_test_the_cache_hands_out_the_seeds_own_city(t)
	_test_each_caller_gets_a_map_of_its_own(t)
	_test_the_source_hands_the_cache(t)
	_test_a_seed_is_generated_once(t)

## What the cache hands out for a seed is that seed's city: the ground the generator lays for it.
func _test_the_cache_hands_out_the_seeds_own_city(t) -> void:
	var cached := MapCache.of(SEED)
	var generated := CityGenerator.generate(SEED)
	t.check(cached.walk_tiles() == generated.walk_tiles()
			and cached.home_world_position() == generated.home_world_position(),
			"the cache hands out the city seed %d generates" % SEED)

## Two asks hand two maps, and what the first caller paints on its map is not on the
## second's.
func _test_each_caller_gets_a_map_of_its_own(t) -> void:
	var first := MapCache.of(SEED)
	var tile := first.world_to_tile(first.doorstep_world_position())
	first.set_tile(tile, GameEnums.TileType.BUILDING)
	var second := MapCache.of(SEED)
	t.check(first != second, "each ask hands a map of its own")
	t.check(first.tile_at(tile) == GameEnums.TileType.BUILDING
			and second.tile_at(tile) != GameEnums.TileType.BUILDING,
			"what one caller paints on its map is not on the next caller's")

## The source a boot is handed answers a seed with that seed's city, a map of its own each call.
func _test_the_source_hands_the_cache(t) -> void:
	var source := MapCache.source()
	var first: CityMap = source.call(SEED)
	var second: CityMap = source.call(SEED)
	t.check(first != second and first.walk_tiles() == second.walk_tiles(),
			"the source hands a copy of the seed's city each time it is asked")

## The cache's one purpose: a seed is generated the first time it is asked for and never again, by
## `of()` or by the source, whoever asks. The generator is a counting wrapper of the real one, so the
## kept map is still the generator's own.
func _test_a_seed_is_generated_once(t) -> void:
	var counting := CountingGenerator.new()
	var first := MapCache.of(_OWN_SEED, counting.generate)
	var second := MapCache.of(_OWN_SEED, counting.generate)
	var third: CityMap = MapCache.source().call(_OWN_SEED)
	t.check(counting.calls == 1,
			"seed %d is generated once however often it is asked for (%d generations)"
			% [_OWN_SEED, counting.calls])
	t.check(first != second and second != third
			and first.walk_tiles() == CityGenerator.generate(_OWN_SEED).walk_tiles(),
			"each ask is a copy of the one real city")
