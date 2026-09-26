extends RefCounted
## Throwaway: finds a seed for M203 case 1 (a small back building fully covered) and for M216 (a
## small courtyard block), then prints a `--walk` script from the doorstep to a vantage tile in
## front of each, computed from `CityMap.walk_field()`'s own downhill descent rather than by hand.
## Not a suite: `tools/test.sh probes/m216_evidence.gd`.
##
## **Prefers a script with no short "jog" run.** `--walk`'s own script format only ever takes
## whole seconds (`AutoScreenshot._parse_script()`), so a real BFS run of a handful of tiles still
## costs a whole second (`WALK_SPEED` 92px/s over `TILE_SIZE` 32px is 2.875 tiles/s) held in that
## direction — a two-tile jog rounds up to a 2.875-tile press, and the *next* run then starts
## almost a tile off the corridor it needs, which a long press down a straight street turns into
## landing in an entirely different block. So a script is only accepted if every one of its runs
## is either the last one or at least `_SAFE_RUN_TILES` real tiles, which keeps the rounding error
## small next to the run it is about to feed into.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const _SAFE_RUN_TILES := 6
## Small: close enough to frame without a long walk, but past the home block's own notch, which
## sits right against a neighbour on some seeds and reads as her own doorstep rather than a
## generic front (`City._block_of()`'s own comment: "every lot on the home block is hers").
const _VANTAGE_OFFSET := 6

func _block_of(rect: Rect2i) -> Vector2i:
	return (rect.position - Vector2i.ONE * Tuning.STREET_WIDTH) / CityMap.period()

func run(t) -> void:
	_find_fully_covered(t)
	_find_courtyard(t)
	t.check(true, "m216 evidence probe ran")

# ------------------------------------------------------------- case 1: fully covered ---

func _find_fully_covered(t) -> void:
	var best: Dictionary = {}
	var best_distance := 999999.0
	var best_unsafe: Dictionary = {}
	var best_unsafe_distance := 999999.0
	for seed_value in range(1, 150):
		var map := CityGenerator.generate(seed_value)
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		var courtyard_lots: Array[Rect2i] = []
		for block in map.block_layouts.keys():
			if map.starting_purpose(block) == GameEnums.BlockPurpose.COURTYARD:
				courtyard_lots.append(map.lot_rect(block))
		var found: Building = null
		for building: Building in city.buildings():
			if building.is_home_building or building.power_station:
				continue
			var cols := building.covered_ground_cols
			if cols.is_empty() or building.columns() > 2:
				continue
			var in_a_courtyard := false
			for cl in courtyard_lots:
				if cl.encloses(building.lot):
					in_a_courtyard = true
					break
			if in_a_courtyard:
				continue  # a courtyard sliver, not the plain "..X / XXX" case
			var all_covered := true
			for c in cols:
				if not c:
					all_covered = false
					break
			if all_covered:
				found = building
				break
		if found != null:
			var south := Vector2i(found.lot.position.x, found.lot.end.y)
			var front_lot := Rect2i()
			for rect: Rect2i in map.building_rects:
				if rect.has_point(south):
					front_lot = rect
					break
			var home_block := CityGenerator.home_block()
			if _block_of(found.lot) == home_block or _block_of(front_lot) == home_block:
				city.free()
				continue  # too close to her own doorstep to read as a generic front
			var vantage := Vector2i(front_lot.position.x + front_lot.size.x / 2,
					front_lot.end.y + _VANTAGE_OFFSET)
			var walk := _walk_to(map, vantage)
			if not walk.is_empty():
				var d: float = (found.lot.position - walk["source"]).length()
				if walk["safe"] and d < best_distance:
					best_distance = d
					best = {"seed": seed_value, "lot": found.lot, "front_lot": front_lot,
							"walk": walk}
				elif not walk["safe"] and d < best_unsafe_distance:
					best_unsafe_distance = d
					best_unsafe = {"seed": seed_value, "lot": found.lot, "front_lot": front_lot,
							"walk": walk}
		city.free()
	var chosen := best if not best.is_empty() else best_unsafe
	if chosen.is_empty():
		t.check(false, "no fully covered small building found in 150 seeds")
		return
	print("\n== case 1, seed %d: fully covered building at lot %s, front lot %s (safe=%s) =="
			% [chosen["seed"], chosen["lot"], chosen["front_lot"], not best.is_empty()])
	_print_walk(chosen["walk"], "case 1")

# --------------------------------------------------------------- case 3: courtyard ---

func _find_courtyard(t) -> void:
	var best: Dictionary = {}
	var best_distance := 999999.0
	var best_unsafe: Dictionary = {}
	var best_unsafe_distance := 999999.0
	for seed_value in range(1, 150):
		var map := CityGenerator.generate(seed_value)
		for block in map.block_layouts.keys():
			if map.starting_purpose(block) != GameEnums.BlockPurpose.COURTYARD:
				continue
			if map.zone_rects.has(block):
				continue
			if block == CityGenerator.home_block():
				continue
			var lot := map.lot_rect(block)
			var vantage := Vector2i(lot.position.x + lot.size.x / 2, lot.end.y + _VANTAGE_OFFSET)
			var walk := _walk_to(map, vantage)
			if walk.is_empty():
				continue
			var d: float = (lot.position - walk["source"]).length()
			if walk["safe"] and d < best_distance:
				best_distance = d
				best = {"seed": seed_value, "block": block, "lot": lot, "walk": walk}
			elif not walk["safe"] and d < best_unsafe_distance:
				best_unsafe_distance = d
				best_unsafe = {"seed": seed_value, "block": block, "lot": lot, "walk": walk}
	var chosen := best if not best.is_empty() else best_unsafe
	if chosen.is_empty():
		t.check(false, "no small courtyard found in 150 seeds")
		return
	print("\n== case 3, seed %d: courtyard block %s, lot %s (safe=%s) =="
			% [chosen["seed"], chosen["block"], chosen["lot"], not best.is_empty()])
	_print_walk(chosen["walk"], "case 3")

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

## Builds the `--walk` script from the doorstep to the nearest walkable tile to `target`, by
## descending `CityMap.walk_field()` from the doorstep. Returns `{}` if unreachable, else
## `{"source", "dest", "tiles", "runs", "script", "safe"}` — `safe` is whether every run but the
## last is at least `_SAFE_RUN_TILES` tiles (see the class doc).
func _walk_to(map: CityMap, target: Vector2i) -> Dictionary:
	var dest := _nearest_walkable(map, target)
	var source := map.world_to_tile(map.doorstep_world_position())
	var field := map.walk_field(source)
	if not map.reaches(field, dest):
		return {}
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
			return {}
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
	var safe := true
	for i in runs.size():
		var run_dict = runs[i]
		if i < runs.size() - 1 and run_dict["tiles"] < _SAFE_RUN_TILES:
			safe = false
		var seconds := maxi(1, roundi(run_dict["tiles"] / tiles_per_second))
		script += "%d%s" % [seconds, run_dict["letter"]]
	return {"source": source, "dest": dest, "tiles": path.size() - 1, "runs": runs,
			"script": script, "safe": safe}

func _print_walk(walk: Dictionary, label: String) -> void:
	print("%s: vantage tile %s, doorstep %s, %d tiles, %d runs, script: %s"
			% [label, walk["dest"], walk["source"], walk["tiles"], walk["runs"].size(),
			walk["script"]])
