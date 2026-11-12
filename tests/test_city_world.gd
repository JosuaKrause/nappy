extends RefCounted
## The city as the world the baby stands in (`WorldContext`): what its bodies charge her at a spot,
## and how much faster the calm ground fills her sleepiness than the street does.
##
## **A real `City`, built over a map from the cache** (`tests/city_map_cache.gd`), because the
## guarantees are the city's own wiring: `City.build()` lists the events' bodies among what charges
## her (`excitement_sources = [events.sources, crowd.sources]`), and `City.sleepiness_multiplier()`
## maps a calm tile to the calm curve through the lot it lies in. Everything the baby asks of her
## world, a suite on `Baby` answers with a stand-in (`tests/test_baby_world.gd`); a stand-in cannot
## drop a line the city wires. What the meter does with the answers is `tests/test_meters.gd`'s.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4216201080
const MapCache := preload("res://tests/city_map_cache.gd")

func run(t: TestRunner) -> void:
	var city: City = RunCity.with_own_run(CITY_SCENE, SEED)
	city.skip_event_drawing = true
	city.skip_crowd_drawing = true
	t.add_child(city)
	city.build(MapCache.of(SEED))
	_test_a_live_event_charges_the_spot_it_stands_on(t, city)
	_test_calm_ground_fills_sleepiness_faster_than_the_street(t, city)
	city.free()

## An event placed in the city's own manager, whose field reaches the spot it stands on, is in what
## the city says charges her there: the events' set is among the city's.
func _test_a_live_event_charges_the_spot_it_stands_on(t: TestRunner, city: City) -> void:
	var spot := Vector2.ZERO
	t.check(city.excitement_sources_at(spot).is_empty(),
			"before any event is live nothing charges her at the spot")
	var def := EventCatalogue.by_id("cyclist")
	var instance := EventInstance.new()
	instance.setup(def, spot)
	city.events.world.instances.append(instance)
	var charged := 0.0
	for pair: Array in city.excitement_sources_at(spot):
		charged += pair[1]
	t.check(instance.excitement.contribution_at(spot) > 0.0,
			"the event's own field reaches the spot it stands on")
	t.check(charged > 0.0,
			"and the city lists it among what charges her there (%.2f/s)" % charged)
	city.events.world.instances.erase(instance)
	instance.free()

## On a calm tile the city answers the calm curve for the lot the tile lies in (more than the street's
## 1.0); on a walkable tile
## that is not calm it answers 1.0.
func _test_calm_ground_fills_sleepiness_faster_than_the_street(t: TestRunner, city: City) -> void:
	var map: CityMap = city.map
	var calm := Vector2i(-1, -1)
	var ordinary := Vector2i(-1, -1)
	for y in map.size.y:
		for x in map.size.x:
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
