extends RefCounted
## Whether day 11's rigged mast is put down on her route, and where on the day's route tree a mast
## could be put down at all. Printed rather than asserted. Not a suite: it lives under
## `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/bouncy_egret_day11_mast.gd
##     PROBE_SEEDS=4242,314159 tools/test.sh probes/bouncy_egret_day11_mast.gd
##
## Each city runs `tests/test_resistance.gd`'s own rig: day 11 planned in the real day order and its
## mark read, which rigs the mast onto her route (`ResistanceDirector._rig_her_route_for()`).
##
## Every mast is exempt from the two line rules (inbox #684), so the "junction" and "sidewalk" counts
## below stay empty; they are kept so a regression of the exemption shows here. First, before she walks, every tile of the mast's ground on the route tree that a mast site may
## take (`WalkSiting._a_mast_may_stand()`) is asked the acceptance rules `EventScheduler._best_of()`
## asks, in order, and counted by the first that refuses it: the route junctions and the route
## sidewalks with the mast standing alone, then with the day's plans, then the calm she has not
## used. "PASS" is a tile where a mast could be put down. Then 600s of walking the day's longest
## route back and forth (`_walk_until_the_route_mast()`), and whether the routed mast was put down,
## with why the walk's sitings waited (`EventScheduler.WalkSiting.waits`).

## Thirty cities: the ten the probe was written on, then twenty more.
const SEEDS: Array[int] = [4242, 90210, 1234567, 2295276695, 291862120, 314159, 555555, 777,
		31337, 8675309, 11, 22, 33, 44, 55, 66, 77, 88, 99, 101, 202, 303, 404, 505, 606, 707, 808,
		909, 1001, 2002]

func run(t) -> void:
	var suite: Variant = load("res://tests/test_resistance.gd").new()
	var saved_scars := GameState.scars.duplicate()
	var saved_state := GameState.city_state
	var seeds: Array[int] = SEEDS
	if OS.get_environment("PROBE_SEEDS") != "":
		seeds = []
		for part in OS.get_environment("PROBE_SEEDS").split(","):
			seeds.append(int(part))
	var put_down := 0
	print("\n== day 11's rigged mast, %d seeds ==" % seeds.size())
	for seed_value in seeds:
		suite._build_city(t, seed_value)
		var result := [""]
		suite._with_clean_run(func() -> void:
			GameState.scars = []
			var read: Array = suite._read_the_mark_on(t, 11, seed_value)
			var director: ResistanceDirector = read[0]
			var player: Stroller = read[2]
			var where := _where_a_mast_may_stand(suite._city)
			var at_the_mark := {}
			for plan in suite._city.events.plans():
				if plan.mast_id != "":
					at_the_mark[plan.mast_id] = true
			result[0] = suite._walk_until_the_route_mast(at_the_mark, player)
			var siting: EventScheduler.WalkSiting = suite._city.events._siting
			var waits: Dictionary = siting.waits if siting else {}
			print("  seed %10d  %-6s  tree tiles %s  passing %s" % [seed_value,
					"PUT" if result[0] != "" else "never", where[0], where[1]])
			print("      walked %.1fs before it was put down" % suite._seconds_walked_to_the_route_mast)
			print("      waits %s" % waits)
			player.free()
			director.free())
		if result[0] != "":
			put_down += 1
	print("  put down on %d of %d" % [put_down, seeds.size()])
	GameState.scars = saved_scars
	GameState.city_state = saved_state
	if suite._city:
		suite._city.free()

## `[counts by the first rule that refuses a tile, the tiles no rule refuses]`, over every tile of
## the routed mast's ground on the day's route tree. See the file's own doc.
static func _where_a_mast_may_stand(city: City) -> Array:
	var events: EventManager = city.events
	var siting: EventScheduler.WalkSiting = events._siting
	var def: EventDef = events._director.route_row(ResistanceDirector.MAST_ROW)
	var map: CityMap = city.map
	var plans: Array[EventScheduler.Planned] = events.plans()
	var none: Array[EventScheduler.Planned] = []
	var rng := RandomNumberGenerator.new()
	var counts := {}
	var passing: Array[Vector2i] = []
	for tile: Vector2i in siting._ground_as_a_set(def):
		if siting._tree.branches_on(tile).is_empty():
			continue
		var why := "PASS"
		var candidate := EventScheduler._build_placement(def, map, tile, rng)
		if not siting._a_mast_may_stand(tile):
			why = "not a mast site"
		elif not candidate:
			why = "no placement"
		elif not EventScheduler._leaves_the_route_junctions_open(candidate, map, siting._corridor,
				siting._ground, none):
			why = "junction, the mast alone"
		elif not EventScheduler._leaves_the_routes_sidewalk_open(candidate, map, siting._corridor,
				siting._ground, none):
			why = "sidewalk, the mast alone"
		elif not EventScheduler._leaves_the_route_junctions_open(candidate, map, siting._corridor,
				siting._ground, plans):
			why = "junction, with the day"
		elif not EventScheduler._leaves_the_routes_sidewalk_open(candidate, map, siting._corridor,
				siting._ground, plans):
			why = "sidewalk, with the day"
		elif EventScheduler._reaches_any(candidate, siting._leave_alone):
			why = "calm she has not used"
		else:
			passing.append(tile)
		counts[why] = int(counts.get(why, 0)) + 1
	return [counts, passing]
