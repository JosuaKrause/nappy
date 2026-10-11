extends RefCounted
## Whether day 11's rigged mast is put down on her route, over ten cities. Printed rather than
## asserted. Not a suite: it lives under `tests/probes/`, where the runner never discovers it, and
## runs only by name:
##
##     tools/test.sh probes/bouncy_egret_day11_mast.gd
##
## Each city runs `tests/test_resistance.gd`'s own rig: day 11 planned in the real day order, its
## mark read (which rigs the mast onto her route, `ResistanceDirector._rig_her_route_for()`), then
## 600s of walking the day's longest route back and forth (`_walk_until_the_route_mast()`). Per city
## it prints whether the routed mast was put down and why the walk's sitings waited
## (`EventScheduler.WalkSiting.waits`).

const SEEDS: Array[int] = [4242, 90210, 1234567, 2295276695, 291862120, 314159, 555555, 777,
		31337, 8675309]

func run(t) -> void:
	var suite: Variant = load("res://tests/test_resistance.gd").new()
	var saved_scars := GameState.scars.duplicate()
	var saved_state := GameState.city_state
	var put_down := 0
	print("\n== day 11's rigged mast, %d seeds ==" % SEEDS.size())
	for seed_value in SEEDS:
		suite._build_city(t, seed_value)
		var result := [""]
		suite._with_clean_run(func() -> void:
			GameState.scars = []
			var read: Array = suite._read_the_mark_on(t, 11, seed_value)
			var director: ResistanceDirector = read[0]
			var player: Stroller = read[2]
			var at_the_mark := {}
			for plan in suite._city.events.plans():
				if plan.mast_id != "":
					at_the_mark[plan.mast_id] = true
			result[0] = suite._walk_until_the_route_mast(at_the_mark, player)
			var siting: EventScheduler.WalkSiting = suite._city.events._siting
			var waits: Dictionary = siting.waits if siting else {}
			print("    rules ", EventScheduler.DBG)
			EventScheduler.DBG.clear()
			print("  seed %10d  %-6s  waits %s" % [seed_value,
					"PUT" if result[0] != "" else "never", waits])
			player.free()
			director.free())
		if result[0] != "":
			put_down += 1
	print("  put down on %d of %d" % [put_down, SEEDS.size()])
	GameState.scars = saved_scars
	GameState.city_state = saved_state
	if suite._city:
		suite._city.free()
