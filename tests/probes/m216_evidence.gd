extends RefCounted
## Throwaway: finds a seed for M203 case 1 (a small back building fully covered) and for M216 (a
## small courtyard block), then prints a `--walk` script from the doorstep to a vantage tile in
## front of each, computed from `CityMap.walk_field()` rather than by hand. Not a suite:
## `tools/test.sh probes/m216_evidence.gd`.

const CITY_SCENE := preload("res://scenes/world/city.tscn")

func run(t) -> void:
	_find_fully_covered(t)
	_find_courtyard(t)
	t.check(true, "m216 evidence probe ran")

# ------------------------------------------------------------- case 1: fully covered ---

func _find_fully_covered(t) -> void:
	var best_seed := -1
	var best_lot := Rect2i()
	var best_distance := 999999
	for seed_value in range(1, 60):
		var map := CityGenerator.generate(seed_value)
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		var found: Building = null
		for building: Building in city.buildings():
			if building.is_home_building or building.power_station:
				continue
			var cols := building.covered_ground_cols
			if cols.is_empty() or building.columns() > 2:
				continue
			var all_covered := true
			for c in cols:
				if not c:
					all_covered = false
					break
			if all_covered:
				found = building
				break
		if found != null:
			var source := map.world_to_tile(map.doorstep_world_position())
			var d := (found.lot.position - source).length()
			if d < best_distance:
				best_distance = d
				best_seed = seed_value
				best_lot = found.lot
		city.free()
	if best_seed == -1:
		t.check(false, "no fully covered small building found in 300 seeds")
		return
	var map := CityGenerator.generate(best_seed)
	# Vantage south of the COVERING (front) building's own lot, never the covered (back) one's —
	# the tile south of the back building's lot is the front building's own footprint, not a
	# street, so `_nearest_walkable` would have to escape the whole front building first.
	var south := Vector2i(best_lot.position.x, best_lot.end.y)
	var front_lot := Rect2i()
	for rect: Rect2i in map.building_rects:
		if rect.has_point(south):
			front_lot = rect
			break
	print("\n== seed %d: fully covered building at lot %s, front lot %s ==" \
			% [best_seed, best_lot, front_lot])
	var vantage := Vector2i(front_lot.position.x + front_lot.size.x / 2, front_lot.end.y + 3)
	_print_walk_to(map, vantage, "case 1")

# --------------------------------------------------------------- case 3: courtyard ---

func _find_courtyard(t) -> void:
	var best_seed := -1
	var best_block := Vector2i()
	var best_lot := Rect2i()
	var best_distance := 999999
	for seed_value in range(1, 150):
		var map := CityGenerator.generate(seed_value)
		var source := map.world_to_tile(map.doorstep_world_position())
		for block in map.block_layouts.keys():
			if map.starting_purpose(block) != GameEnums.BlockPurpose.COURTYARD:
				continue
			if map.zone_rects.has(block):
				continue
			var lot := map.lot_rect(block)
			var d := (lot.position - source).length()
			if d < best_distance:
				best_distance = d
				best_seed = seed_value
				best_block = block
				best_lot = lot
	if best_seed == -1:
		t.check(false, "no small courtyard found in 300 seeds")
		return
	print("\n== seed %d: courtyard block %s, lot %s ==" % [best_seed, best_block, best_lot])
	var map := CityGenerator.generate(best_seed)
	var vantage := Vector2i(best_lot.position.x + best_lot.size.x / 2, best_lot.end.y + 3)
	_print_walk_to(map, vantage, "case 3")

# --------------------------------------------------------------------- pathing ---

## Nearest walkable tile to `target`, spiralling outward a ring at a time.
func _nearest_walkable(map: CityMap, target: Vector2i) -> Vector2i:
	if map.in_bounds(target) and map.is_walkable(target):
		return target
	for radius in range(1, 12):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var t2 := target + Vector2i(dx, dy)
				if map.in_bounds(t2) and map.is_walkable(t2):
					return t2
	return target

## Prints a `--walk` script (integer seconds per cardinal run) from the doorstep to the nearest
## walkable tile to `target`, by descending `CityMap.walk_field()` from the doorstep.
func _print_walk_to(map: CityMap, target: Vector2i, label: String) -> void:
	var dest := _nearest_walkable(map, target)
	var source := map.world_to_tile(map.doorstep_world_position())
	var field := map.walk_field(source)
	if not map.reaches(field, dest):
		print("%s: doorstep cannot reach vantage tile %s" % [label, dest])
		return
	# Walk downhill from dest back to source, one step at a time.
	var path: Array[Vector2i] = [dest]
	var cur := dest
	while cur != source:
		var here := map.distance_at(field, cur)
		var stepped := false
		for delta: Vector2i in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var nxt: Vector2i = cur + delta
			if map.in_bounds(nxt) and map.reaches(field, nxt) \
					and map.distance_at(field, nxt) == here - 1:
				cur = nxt
				path.append(cur)
				stepped = true
				break
		if not stepped:
			print("%s: path reconstruction stuck at %s" % [label, cur])
			return
	path.reverse()  # source .. dest
	# Collapse consecutive same-direction tile steps into whole-second runs.
	var runs: Array = []  # [{"letter": "n"/"s"/"e"/"w", "tiles": int}]
	for i in range(1, path.size()):
		var delta: Vector2i = path[i] - path[i - 1]
		var letter := ""
		if delta == Vector2i(0, -1):
			letter = "n"
		elif delta == Vector2i(0, 1):
			letter = "s"
		elif delta == Vector2i(-1, 0):
			letter = "w"
		elif delta == Vector2i(1, 0):
			letter = "e"
		if not runs.is_empty() and runs[-1]["letter"] == letter:
			runs[-1]["tiles"] += 1
		else:
			runs.append({"letter": letter, "tiles": 1})
	var tiles_per_second := Tuning.WALK_SPEED / float(Tuning.TILE_SIZE)
	var script := ""
	for run_dict in runs:
		var seconds := maxi(1, roundi(run_dict["tiles"] / tiles_per_second))
		script += "%d%s" % [seconds, run_dict["letter"]]
	print("%s: vantage tile %s, doorstep %s, %d tiles, script: %s"
			% [label, dest, source, path.size() - 1, script])
