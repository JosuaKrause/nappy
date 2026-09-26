class_name M216Walk
extends RefCounted
## Throwaway shared helper for the M216 evidence probes: builds a `--walk` script from the
## doorstep to a vantage tile, preferring one with no short "jog" run before a long one (see
## `m216_evidence.gd`'s own class doc for why). Not a suite, not referenced by any real gameplay
## code — deleted along with the probes once the evidence is captured.

## Nearest walkable tile to `target`, spiralling outward a ring at a time.
static func nearest_walkable(map: CityMap, target: Vector2i) -> Vector2i:
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
## last is at least `safe_run_tiles` tiles.
static func walk_to(map: CityMap, target: Vector2i, safe_run_tiles: int) -> Dictionary:
	var dest := nearest_walkable(map, target)
	var source := map.world_to_tile(map.doorstep_world_position())
	var field := map.walk_field(source)
	if not map.reaches(field, dest):
		return {}
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
	path.reverse()
	var runs: Array = []
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
		if i < runs.size() - 1 and run_dict["tiles"] < safe_run_tiles:
			safe = false
		var seconds := maxi(1, roundi(run_dict["tiles"] / tiles_per_second))
		script += "%d%s" % [seconds, run_dict["letter"]]
	return {"source": source, "dest": dest, "tiles": path.size() - 1, "runs": runs,
			"script": script, "safe": safe}

static func print_walk(walk: Dictionary, label: String) -> void:
	print("%s: vantage tile %s, doorstep %s, %d tiles, %d runs, safe=%s, script: %s"
			% [label, walk["dest"], walk["source"], walk["tiles"], walk["runs"].size(),
			walk["safe"], walk["script"]])
