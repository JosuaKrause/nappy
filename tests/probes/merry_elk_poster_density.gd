extends RefCounted
## merry-elk: how many posters she passes within view along the routes she actually walks, per day.
##
## For each seed and each day from `PosterWalls.FIRST_DAY` on it builds the city, runs the dawns,
## grows the day's route tree and walks every route of every branch cell by cell. At each cell
## the screen is the `Tuning.VIEW_HALF_EXTENT` box around it; the intact sheets inside it are the
## posters in view there. Reported per day, over all seeds:
##   city      sheets on all the walls (not route-based, for scale)
##   view      mean sheets in view over every route cell
##   empty     share of route cells with no sheet in view at all
##   route     mean distinct sheets a whole route passes in view
##   worst     fewest distinct sheets any route passes, over all seeds
##   bare      share of routes passing fewer than 3 sheets
## Run: tools/test.sh probes/merry_elk_poster_density.gd   (prints MERRY_ELK lines)

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS := [4242, 90210, 7, 31337, 555, 1234, 98765, 2024]
const BARE_BELOW := 3

func run(t) -> void:
	var saved_seed := GameState.run_seed
	var saved_posters := GameState.posters.to_data()
	var rows := {}
	for seed_value in SEEDS:
		var map := CityGenerator.generate(seed_value)
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		GameState.run_seed = seed_value
		GameState.posters.reset()
		var state := CityState.new()
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			state.begin_day(map.block_plans, day)
			GameState.posters.photograph()
			city.start_day(state, day, GameState.day_rng(day, "closures"))
			if day < PosterWalls.FIRST_DAY:
				continue
			_measure(city, map, day, rows)
		city.free()
	for day in range(PosterWalls.FIRST_DAY, Tuning.RUN_LENGTH_DAYS + 1):
		var r: Dictionary = rows[day]
		var routes: Array = r["route_counts"]
		var bare := 0
		var worst := 1 << 30
		var sum := 0.0
		for n: int in routes:
			bare += 1 if n < BARE_BELOW else 0
			worst = mini(worst, n)
			sum += n
		print("MERRY_ELK day %2d  city %6.1f  view %5.2f  empty %5.1f%%  route %5.1f  worst %3d  bare %5.1f%%"
				% [day, float(r["city"]) / SEEDS.size(), float(r["view_sum"]) / maxi(1, int(r["cells"])),
				100.0 * float(r["empty"]) / maxi(1, int(r["cells"])), sum / maxi(1, routes.size()),
				worst, 100.0 * bare / maxi(1, routes.size())])
	t.check(rows.size() > 0, "measured")
	GameState.run_seed = saved_seed
	GameState.posters.restore(saved_posters)

func _measure(city: City, map: CityMap, day: int, rows: Dictionary) -> void:
	if not rows.has(day):
		rows[day] = {"city": 0, "view_sum": 0, "cells": 0, "empty": 0, "route_counts": []}
	var r: Dictionary = rows[day]
	var sheets: Array[Vector2] = []
	for tile: Vector2i in GameState.posters.cells:
		if GameState.posters.has_intact_sheet(tile):
			sheets.append(map.tile_to_world(tile) + Vector2(0, -Tuning.TILE_SIZE * 0.5))
	r["city"] = int(r["city"]) + sheets.size()
	var tree := city.route_tree()
	if tree == null:
		return
	for branch in tree.branches:
		for route in branch.routes:
			var seen := {}
			for cell: Vector2i in route:
				var at := map.tile_to_world(cell * ReachabilityGrid.CELL + Vector2i.ONE)
				var here := 0
				for i in sheets.size():
					var d := (sheets[i] - at).abs()
					if d.x <= Tuning.VIEW_HALF_EXTENT.x and d.y <= Tuning.VIEW_HALF_EXTENT.y:
						here += 1
						seen[i] = true
				r["view_sum"] = int(r["view_sum"]) + here
				r["cells"] = int(r["cells"]) + 1
				r["empty"] = int(r["empty"]) + (1 if here == 0 else 0)
			(r["route_counts"] as Array).append(seen.size())
