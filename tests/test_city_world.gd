extends RefCounted
## The city as the world the baby stands in (`WorldContext`): what its bodies charge her at a spot,
## and how much faster the calm ground fills her sleepiness than the street does.
##
## **A real `City`, built over a map from the cache** (`tests/city_map_cache.gd`), because the
## guarantees are the city's own wiring: the city answers the baby from the sets its simulation was
## stood with (`SimulationBuilder.in_the_city()`, `WorldContext.use_excitement_sources()`), the
## events' among them, and `City.sleepiness_multiplier()` maps a calm tile to the calm curve
## through the lot it lies in. Everything the baby asks of her
## world, a suite on `Baby` answers with a stand-in (`tests/test_baby_world.gd`); a stand-in cannot
## drop a line the city wires. What the meter does with the answers is `tests/test_meters.gd`'s.
## The city's streets also decay at half speed while she carries the resistance's package
## (`City.decay_multiplier()`), which is the city's own answer to the baby and held nowhere else;
## the director's setting the flag is `tests/test_resistance_steps.gd`'s.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4216201080
const MapCache := preload("res://tests/city_map_cache.gd")

func run(t: TestRunner) -> void:
	var city: City = RunCity.with_own_run(CITY_SCENE, SEED)
	t.add_child(city)
	var builder := RunCity.new_builder()
	builder.leave_out(true, true, false)
	RunCity.build(city, MapCache.of(SEED), builder)
	_test_a_live_event_charges_the_spot_it_stands_on(t, city)
	_test_calm_ground_fills_sleepiness_faster_than_the_street(t, city)
	_test_the_camera_framing_is_less_the_look_ahead_it_is_handed(t, city)
	_test_carrying_the_package_halves_every_streets_decay(t, city)
	city.free()

## Carrying the resistance's package makes every street after it decay slower
## (`City.RESISTANCE_PACKAGE_DECAY_MULTIPLIER`): the city's answer to the baby at a spot, read before
## the run's flag is set and after. The flag is set on the run the city was handed; what sets it, the
## director's completing the package's task, is `tests/test_resistance_steps.gd`'s.
func _test_carrying_the_package_halves_every_streets_decay(t: TestRunner, city: City) -> void:
	var somewhere := city.map.tile_to_world(Vector2i(10, 10))
	var before := city.decay_multiplier(somewhere)
	city.run.resistance().pick_up_package()
	t.close_to(city.decay_multiplier(somewhere), before * City.RESISTANCE_PACKAGE_DECAY_MULTIPLIER,
			"every street decays slower once she carries the package", 0.001)
	city.run.resistance().put_down_package()
	t.close_to(city.decay_multiplier(somewhere), before,
			"and as before once she has put it down", 0.001)

## An event placed in the city's own manager, whose field reaches the spot it stands on, is in what
## the city says charges her there: the events' set is among the city's.
func _test_a_live_event_charges_the_spot_it_stands_on(t: TestRunner, city: City) -> void:
	var spot := Vector2.ZERO
	t.check(city.excitement_sources_at(spot).is_empty(),
			"before any event is live nothing charges her at the spot")
	var def := EventCatalogue.by_id("cyclist")
	var instance := EventInstance.new()
	instance.setup(def, spot)
	RunCity.events(city).world.take_in(instance)
	var charged := 0.0
	for pair: Array in city.excitement_sources_at(spot):
		charged += pair[1]
	t.check(instance.source().contribution_at(spot) > 0.0,
			"the event's own field reaches the spot it stands on")
	t.check(charged > 0.0,
			"and the city lists it among what charges her there (%.2f/s)" % charged)
	RunCity.events(city).world.let_go(instance)
	instance.free()

## On a calm tile the city answers the calm curve for the lot the tile lies in (more than the street's
## 1.0); on a walkable tile
## that is not calm it answers 1.0.
func _test_calm_ground_fills_sleepiness_faster_than_the_street(t: TestRunner, city: City) -> void:
	var map: CityMap = city.map
	var calm := Vector2i(-1, -1)
	var ordinary := Vector2i(-1, -1)
	for y in map.size_in_tiles().y:
		for x in map.size_in_tiles().x:
			var tile := Vector2i(x, y)
			if Tile.is_calm(map.tile_at(tile)):
				# The largest lot, so a gain read off the wrong block count is not equal by luck.
				if calm.x < 0 or lots(map, tile) > lots(map, calm):
					calm = tile
			elif map.tile_at(tile) == GameEnums.TileType.SIDEWALK and ordinary.x < 0:
				ordinary = tile
	t.check(calm.x >= 0 and ordinary.x >= 0, "the city has calm ground and ordinary ground")
	if calm.x < 0 or ordinary.x < 0:
		return
	var calm_at := map.tile_to_world(calm)
	var lot := lots(map, calm)
	t.check(lot > 1, "the calm ground chosen lies in a lot of several blocks (%d)" % lot)
	t.close_to(city.sleepiness_multiplier(calm_at), Tuning.sleepiness_calm_multiplier(lot),
			"on calm ground she gains at the calm curve for its lot of %d blocks" % lot, 0.0001)
	t.check(city.sleepiness_multiplier(calm_at) > 1.0, "which is more than the street's")
	t.check(city.sleepiness_multiplier(map.tile_to_world(ordinary)) == 1.0,
			"and on an ordinary sidewalk it is the plain 1.0")

## The blocks of the calm lot the tile lies in.
static func lots(map: CityMap, tile: Vector2i) -> int:
	return map.calm_lot_blocks(map.block_at(map.tile_to_world(tile)))

## The framing of the whole city is the map grown by the band painted outside it, less the reach of
## a glance the caller hands in: a longer look-ahead pulls each edge in by exactly the difference.
func _test_the_camera_framing_is_less_the_look_ahead_it_is_handed(t: TestRunner, city: City) -> void:
	var none := city.camera_bounds(0.0)
	var led := city.camera_bounds(46.0)
	t.check(none.size.is_equal_approx(city.map.world_size()
			+ Vector2.ONE * 2.0 * CityMap.OUTSIDE_DEPTH_TILES * float(Tuning.TILE_SIZE)),
			"with no look-ahead the framing is the map and its whole border band")
	t.check(led.position.is_equal_approx(none.position + Vector2.ONE * 46.0)
			and led.size.is_equal_approx(none.size - Vector2.ONE * 92.0),
			"each edge comes in by the look-ahead it is handed")
