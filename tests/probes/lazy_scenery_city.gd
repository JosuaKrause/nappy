extends City
## Timed production stages for the lazy-scenery investigation; no production behavior changes.

var spans: Dictionary = {}

## Overrides City._paint_ground.
func _paint_ground() -> void:
	var started := Time.get_ticks_usec()
	super._paint_ground()
	spans["paint_ms"] = (Time.get_ticks_usec() - started) / 1000.0

## Overrides City._composed_ground_tile_set.
func _composed_ground_tile_set() -> TileSet:
	var started := Time.get_ticks_usec()
	var result := super._composed_ground_tile_set()
	spans["composition_ms"] = (Time.get_ticks_usec() - started) / 1000.0
	return result

## Overrides City._spawn_buildings.
func _spawn_buildings() -> void:
	var started := Time.get_ticks_usec()
	super._spawn_buildings()
	spans["buildings_ms"] = (Time.get_ticks_usec() - started) / 1000.0

## Overrides City._dress_blocks.
func _dress_blocks(state: CityState) -> void:
	var started := Time.get_ticks_usec()
	super._dress_blocks(state)
	spans["dressing_ms"] = (Time.get_ticks_usec() - started) / 1000.0

## Overrides City._close_streets.
func _close_streets(spec: DaySpec, rng: RandomNumberGenerator) -> void:
	var started := Time.get_ticks_usec()
	super._close_streets(spec, rng)
	spans["closures_ms"] = (Time.get_ticks_usec() - started) / 1000.0
