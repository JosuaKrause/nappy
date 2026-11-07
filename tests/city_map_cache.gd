extends RefCounted
## **The cities a test process has generated, each built once and handed out as a copy.** A helper,
## not a suite: the runner loads only `test_*.gd`.
##
## Generating a city (`CityGenerator.generate()`) is the slow part of most rigs' setup, a few
## hundred milliseconds a seed, and the rigs that build a real city build the same few seeds over and
## over. Here each seed is generated the first time a suite asks for it, kept for the rest of the
## process, and every caller is handed its own `CityMap.copy()` of it, so what one suite paints,
## closes or stands on its map reaches no other suite and no later caller. The kept map itself is
## never handed out.
##
## **The key is the seed and nothing else**, because the generator reads nothing else:
## `CityGenerator.generate()` is a function of its seed and of constants (`Tuning`, the generator's
## own), and no run, flag or autoload reaches it. A map the generator built with other choices
## (`CityGenerator._attempt()` with a choice forced) is not a generated city of that seed, and is not
## asked for here.
##
## **It holds only real generated maps** (writing-tests, "Which map a test uses"): a booted day and
## every measurement run on a city the generator can produce, and this is one, built the same way.
## A hand-drawn map for an edge case is built by its own suite.

## Seed -> the `CityMap` `CityGenerator.generate()` returned for it, never handed out itself.
static var _generated := {}

## A copy of the city `seed_value` generates, generated on the first ask in this process. `generate`
## is what makes the map on that first ask, `CityGenerator.generate()` itself unless a suite hands a
## wrapper of it that counts its calls (`tests/test_city_map_cache.gd`); it must return the
## generator's real map for the seed, since the kept map is handed to every later caller.
static func of(seed_value: int, generate: Callable = CityGenerator.generate) -> CityMap:
	var kept: CityMap = _generated.get(seed_value)
	if kept == null:
		kept = generate.call(seed_value)
		_generated[seed_value] = kept
	return kept.copy()

## The source a booted `main` is handed (`main.use_city_maps()`): asked for the run's seed each time
## `main` builds a city, it hands back a copy of that seed's city from this cache.
static func source() -> Callable:
	return of
