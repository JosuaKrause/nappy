extends RefCounted
## Throwaway: finds seeds for the player's requested examples — a power station yard covering a
## neighbour (no extension), and a building whose front faces the map's southern edge (a blank,
## un-extended column). Not a suite: `tools/test.sh probes/m216_more_evidence.gd`.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const _VANTAGE_OFFSET := 4
const _SAFE_RUN_TILES := 6

func run(t) -> void:
	_find_power_station_yard_cover(t)
	_find_southern_edge(t)
	t.check(true, "m216 more-evidence probe ran")

# ------------------------------------------------------- power station yard covers a neighbour ---

func _find_power_station_yard_cover(t) -> void:
	for seed_value in range(1, 150):
		var map := CityGenerator.generate(seed_value)
		if not map.has_power_station():
			continue
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		var station: Building = null
		for building: Building in city.buildings():
			if building.power_station:
				station = building
				break
		if station == null:
			city.free()
			continue
		var station_rect: Rect2i = station.lot
		var hall := Vector2i(0, station.columns())
		# station_yard_cols is set on the instance; read the drawn hall the same way _draw() does.
		if station.station_yard_cols.y > 0:
			if station.station_yard_cols.x == 0:
				hall = Vector2i(station.station_yard_cols.y, station.columns())
			else:
				hall = Vector2i(0, station.station_yard_cols.x)
		# Yard columns are whichever of [0, hall.x) or [hall.y, columns()) is non-empty.
		var yard_cols: Array = []
		for c in range(0, hall.x):
			yard_cols.append(c)
		for c in range(hall.y, station.columns()):
			yard_cols.append(c)
		var found_back: Building = null
		var found_col := -1
		# For every building, if its own covered column's south tile falls in the station's own
		# yard columns, that is the example: the station's yard covers it, but yard columns never
		# receive a roof extension (`City._assign_roof_extensions()`'s own power-station guard).
		for building: Building in city.buildings():
			if building == station or building.covered_ground_cols.is_empty():
				continue
			for col in building.covered_ground_cols.size():
				if not building.covered_ground_cols[col]:
					continue
				var south := Vector2i(building.lot.position.x + col, building.lot.end.y)
				if not station_rect.has_point(south):
					continue
				var local_col := south.x - station_rect.position.x
				if local_col in yard_cols:
					found_back = building
					found_col = col
					break
			if found_back != null:
				break
		if found_back != null:
			print("\n== power station yard cover, seed %d: station lot %s, yard cols %s, back building lot %s col %d, extension there=%d =="
					% [seed_value, station_rect, yard_cols, found_back.lot, found_col,
					station._extension_rows(found_col + (found_back.lot.position.x - station_rect.position.x))])
			var vantage := Vector2i(station_rect.position.x + station_rect.size.x / 2,
					station_rect.end.y + _VANTAGE_OFFSET)
			var walk := M216Walk.walk_to(map, vantage, _SAFE_RUN_TILES)
			if not walk.is_empty():
				M216Walk.print_walk(walk, "power station yard")
			city.free()
			return
		city.free()
	print("\n== power station yard cover: none found in 150 seeds ==")

# --------------------------------------------------------------- southern map edge ---

func _find_southern_edge(t) -> void:
	for seed_value in range(1, 150):
		var map := CityGenerator.generate(seed_value)
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		var found: Building = null
		var found_col := -1
		for building: Building in city.buildings():
			if building.is_home_building or building.power_station:
				continue
			if building.lot.end.y != map.size.y:
				continue  # not on the map's own southern edge
			for col in building.covered_ground_cols.size():
				if not building.covered_ground_cols[col]:
					continue
				var south := Vector2i(building.lot.position.x + col, building.lot.end.y)
				if map.in_bounds(south):
					continue  # covered by a real building, not the map's own edge
				found = building
				found_col = col
				break
			if found != null:
				break
		if found != null:
			print("\n== southern map edge, seed %d: lot %s (map size %s), covered col %d, extension=%d =="
					% [seed_value, found.lot, map.size, found_col, found._extension_rows(found_col)])
			var vantage := Vector2i(found.lot.position.x + found.lot.size.x / 2,
					found.lot.position.y - _VANTAGE_OFFSET)
			var walk := M216Walk.walk_to(map, vantage, _SAFE_RUN_TILES)
			if not walk.is_empty():
				M216Walk.print_walk(walk, "southern edge")
			city.free()
			return
		city.free()
	print("\n== southern map edge: none found in 150 seeds ==")
