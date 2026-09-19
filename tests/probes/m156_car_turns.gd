extends RefCounted
## Printing rig for "a car is turned only by what blocks its roadway": which of a car's shut
## conditions each row of a real day actually reaches, and whether the body behind it stands on the
## carriageway at all. Not a suite — it prints and asserts nothing — so it lives under
## `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m156_car_turns.gd
##
## **The question is attribution, not counting.** `CrowdAgent._look_ahead()` records only *how far*
## the way is shut; which of `_cannot_go_on`'s clauses said so, and which placed body stands behind
## that clause, is nowhere in the agent. So the walk below re-asks the clauses in their own order
## at the tile the scan stopped on — read off the agent's own cached scan origin
## (`_scan_at`/`_scan_vertical`/`_scan_direction`), never off where the body has since steered to —
## and names the first clause that answers yes, then looks the tile up in a map of the day's own
## placements.
##
## **A body's footprint is measured with the day's holds lifted**, because
## `EventManager.obstructed_footprint()` returns nothing for a body on a held segment — the record
## leaves those out while the hold speaks for them. Lifting the holds for the measurement and
## putting them straight back is what lets the table answer *does this body cover the roadway* for
## a hard seal as well as for a café.
##
## Two tables. **The causes** are how many car-frames each clause of `_cannot_go_on` turned a car
## for. **The rows** are what stands behind them, one line per catalogue row, split three ways:
##
## - **spill** — the body stands on a *sidewalk* of the car's own street and a tile of its
##   footprint reaches the carriageway anyway. This is the defect the milestone is looking for.
## - **road** — the body genuinely stands on the tile of carriageway the car stopped at.
## - **held** — nothing stands on that tile at all; the car stopped because the whole segment is
##   held for a seal somewhere else along it. The distance to that seal's own nearest body tile is
##   printed with it, because a hold standing in for a body ten tiles away is the other half of
##   "only what physically stops it".

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STEP := 1.0 / 60.0
const SEEDS := [4242, 24757, 91117]
const DAYS := [1, 5, 9]
const SECONDS := 20.0

## cause -> { "frames": int, "first": String }
var _causes := {}
## row id -> { "frames", "spill", "road", "held", "far": float, "first": String }
var _rows := {}

func run(t) -> void:
	for city_seed: int in SEEDS:
		var map := CityGenerator.generate(city_seed)
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		for day: int in DAYS:
			_one_day(city, map, city_seed, day)
		city.free()
	_report()
	t.check(true, "probe finished")

func _one_day(city: City, map: CityMap, city_seed: int, day: int) -> void:
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	var closures := RandomNumberGenerator.new()
	closures.seed = hash("m156-closures:%d:%d" % [city_seed, day])
	city.start_day(state, day, closures)
	var events := RandomNumberGenerator.new()
	events.seed = hash("m156-events:%d:%d" % [city_seed, day])
	var consumed: Array[String] = []
	city.events.start_day(day, events, consumed)

	var bodies := _bodies(map, city.events.plans())
	var owner_of := {}
	for index in bodies.size():
		var body: Dictionary = bodies[index]
		for tile: Vector2i in body["tiles"]:
			owner_of[tile] = index
	var segment_owner := {}
	for index in bodies.size():
		var body: Dictionary = bodies[index]
		var segment := StreetNetwork.segment_containing(body["at"])
		if segment != null and map.is_held(segment):
			segment_owner[segment.key()] = index

	var at := map.doorstep_world_position()
	var crowd_rng := RandomNumberGenerator.new()
	crowd_rng.seed = hash("m156-crowd:%d:%d" % [city_seed, day])
	city.crowd.start_day(day, crowd_rng, at)
	city.crowd.set_gates(city.region_plan().gates)

	for frame in int(round(SECONDS / STEP)):
		city.crowd.set_focus(at)
		city.crowd.step(STEP)
		for agent: CrowdAgent in city.crowd.agents():
			if agent.kind != CrowdAgent.Kind.CAR:
				continue
			if agent._blocked_in > CrowdAgent.LOOKAHEAD_TILES:
				continue
			# A recycled car carries its old `_blocked_in` until its first scan in the new lane,
			# and its scan origin is the sentinel until then. There is no tile to attribute.
			if agent._scan_at.x < 0:
				continue
			_classify(map, agent, city_seed, day, owner_of, segment_owner, bodies)

## Names the first clause of `CrowdAgent._cannot_go_on` that shuts the tile this car's scan stopped
## on, and charges it to the body standing there where there is one.
func _classify(map: CityMap, agent: CrowdAgent, city_seed: int, day: int,
		owner_of: Dictionary, segment_owner: Dictionary, bodies: Array) -> void:
	var step := (Vector2i.DOWN if agent._scan_vertical else Vector2i.RIGHT) \
			* int(signf(agent._scan_direction))
	var tile: Vector2i = agent._scan_at + step * agent._blocked_in
	var where := "seed %d day %d tile %s" % [city_seed, day, tile]
	var cause := ""
	var index := -1
	var how := ""
	if map.is_closed(tile):
		cause = "closed tile"
	elif agent._segment_is_shut(tile):
		cause = "held segment"
		var segment := StreetNetwork.segment_containing(tile)
		index = int(segment_owner.get(segment.key(), -1)) if segment else -1
		how = "held"
	elif map.is_obstructed(tile):
		cause = "a body on the lane"
		index = int(owner_of.get(tile, -1))
		how = "road"
		if index >= 0 and _is_a_sidewalk_placement(bodies[index]):
			how = "spill"
	elif not map.in_bounds(tile):
		cause = "the map edge"
	elif not map.is_driveable_at(agent._scan_vertical, tile):
		cause = "a precinct"
	elif not map.is_street(tile):
		cause = "not a street"
	else:
		cause = "nothing (the scan and the clauses disagree)"
	_count(_causes, cause, where)
	if index < 0:
		return
	var body: Dictionary = bodies[index]
	var entry: Dictionary = _count(_rows, String(body["id"]),
			"%s, its body standing on %s" % [where, body["at"]])
	entry[how] = int(entry[how]) + 1
	if how == "held":
		entry["far"] = maxf(float(entry["far"]), _distance_to(body["tiles"], tile))

static func _count(into: Dictionary, key: String, where: String) -> Dictionary:
	if not into.has(key):
		into[key] = {"frames": 0, "spill": 0, "road": 0, "held": 0, "far": 0.0, "first": where}
	var entry: Dictionary = into[key]
	entry["frames"] = int(entry["frames"]) + 1
	return entry

## Whether a body's own placement tile is a pavement tile rather than a carriageway one: the
## offset across whichever corridor it stands in is a sidewalk offset. A placement inside a
## junction box, where both coordinates are corridor offsets, is not one — it is on ground a car
## drives over whichever street it belongs to.
static func _is_a_sidewalk_placement(body: Dictionary) -> bool:
	var tile: Vector2i = body["at"]
	var across_x := CityMap.corridor_offset(tile.x)
	var across_y := CityMap.corridor_offset(tile.y)
	if across_x >= 0 and across_y >= 0:
		return false
	var offset := across_x if across_x >= 0 else across_y
	return offset >= 0 and not CityMap.is_road_offset(offset)

## Chebyshev distance in tiles from a tile to the nearest tile of a body, or -1 for a body with no
## recorded ground at all.
static func _distance_to(tiles: Array, tile: Vector2i) -> float:
	var best := -1.0
	for covered: Vector2i in tiles:
		var away := float(maxi(absi(covered.x - tile.x), absi(covered.y - tile.y)))
		if best < 0.0 or away < best:
			best = away
	return best

## Every placed plan's own solid footprint, one entry per body, measured with today's holds lifted
## so that a hard seal and a region wall report the ground they actually stand on rather than the
## empty list `CityMap.obstructed_tiles` keeps for them. The holds go straight back.
func _bodies(map: CityMap, plans: Array[EventScheduler.Planned]) -> Array:
	var keys: Array = map.held_segments.keys()
	map.clear_day_holds()
	var found: Array = []
	for plan in plans:
		if not plan.is_placed():
			continue
		var covered := EventManager.obstructed_footprint(map, plan.def, plan.position, plan.facing)
		if covered.is_empty():
			continue
		found.append({
			"id": plan.def.id,
			"at": map.world_to_tile(plan.position),
			"tiles": covered,
		})
	for key: Vector3i in keys:
		map.hold_segment(key)
	return found

func _report() -> void:
	print("")
	print("what stops a car, over %d seeds x %d days x %.0fs:" % [SEEDS.size(), DAYS.size(),
			SECONDS])
	for cause: String in _causes:
		var entry: Dictionary = _causes[cause]
		print("  %-38s %7d car-frames   first at %s" % [cause, entry["frames"], entry["first"]])
	print("")
	print("the rows behind them — spill: a sidewalk body reaching the carriageway; road: a body on "
			+ "the car's own lane tile; held: no body on that tile at all")
	if _rows.is_empty():
		print("  (none — nothing a placed row stands on turned a car)")
	for row: String in _rows:
		var entry: Dictionary = _rows[row]
		print("  %-20s %6d car-frames   spill %6d   road %6d   held %6d (up to %.0f tiles from "
				% [row, entry["frames"], entry["spill"], entry["road"], entry["held"],
				entry["far"]] + "its own body)   first at %s" % entry["first"])
