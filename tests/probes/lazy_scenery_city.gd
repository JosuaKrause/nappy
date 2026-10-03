extends City
## Timed production stages for the lazy-scenery investigation; no production behavior changes.

var spans: Dictionary = {}

func _paint_ground() -> void:
	var started := Time.get_ticks_usec()
	super._paint_ground()
	spans["paint_ms"] = (Time.get_ticks_usec() - started) / 1000.0

func _composed_ground_tile_set() -> TileSet:
	var started := Time.get_ticks_usec()
	var result := super._composed_ground_tile_set()
	spans["composition_ms"] = (Time.get_ticks_usec() - started) / 1000.0
	return result

func _spawn_buildings() -> void:
	var started := Time.get_ticks_usec()
	super._spawn_buildings()
	spans["buildings_ms"] = (Time.get_ticks_usec() - started) / 1000.0

func _dress_blocks(state: CityState) -> void:
	var started := Time.get_ticks_usec()
	super._dress_blocks(state)
	spans["dressing_ms"] = (Time.get_ticks_usec() - started) / 1000.0

func _close_streets(day: int, rng: RandomNumberGenerator) -> void:
	var started := Time.get_ticks_usec()
	super._close_streets(day, rng)
	spans["closures_ms"] = (Time.get_ticks_usec() - started) / 1000.0
