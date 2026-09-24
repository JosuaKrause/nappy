extends RefCounted
## The posters on the walls: where a sheet may go, how the walls fill day by day, the pasting-over
## rule, what a save and a lost day do to them.
##
## What a picture of a front can judge — whether the sheets read at walking distance — is the
## stills' job; this holds what a picture cannot: that no sheet is ever on a window, a door, a fire
## escape or her own block, that nothing is up before day 4 and each day's walls add to the last,
## that a kind never arrives before its day, and that the whole thing is the same from the same
## seed and given back whole by a lost day. And the tears: that a push tears and walking past does
## not, that the marble bag's shares are exact and its draws reproducible, and that a pursuit marble
## sends a patrol down her street without moving the day's own queue.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS := [4242, 90210]

var _saved_seed := 0
var _saved_posters: Dictionary = {}

func run(t) -> void:
	_saved_seed = GameState.run_seed
	_saved_posters = GameState.posters.to_data()
	_test_a_tear_is_the_poster_through_the_mask_then_the_overlay(t)
	_test_the_state_survives_a_round_trip_and_a_lost_day(t)
	_test_the_walls_fill_the_way_the_run_asks(t)
	_test_the_marble_bag_is_exact_and_reproducible(t)
	_test_a_push_tears_and_walking_past_does_not(t)
	_test_a_sent_patrol_comes_down_her_street_and_moves_nothing_else(t)
	GameState.run_seed = _saved_seed
	GameState.posters.restore(_saved_posters)

# ---------------------------------------------------------------- the tears ---

func _test_a_tear_is_the_poster_through_the_mask_then_the_overlay(t) -> void:
	var poster := Image.create(2, 1, false, Image.FORMAT_RGBA8)
	poster.fill(Color(0.8, 0.2, 0.1, 1.0))
	var mask := Image.create(2, 1, false, Image.FORMAT_RGBA8)
	mask.set_pixel(0, 0, Color(1, 1, 1, 1))
	mask.set_pixel(1, 0, Color(1, 1, 1, 0))
	var overlay := Image.create(2, 1, false, Image.FORMAT_RGBA8)
	overlay.set_pixel(1, 0, Color(0, 0, 0, 0.5))
	var torn := PosterArt.compose(poster, mask, overlay)
	var kept := torn.get_pixel(0, 0)
	t.check(absf(kept.r - 0.8) < 0.01 and absf(kept.g - 0.2) < 0.01 and is_equal_approx(kept.a, 1.0),
			"where the mask keeps the paper the poster is untouched")
	t.check(absf(torn.get_pixel(1, 0).a - 0.5) < 0.01,
			"where the mask tears it away only the overlay is left (%.2f)" % torn.get_pixel(1, 0).a)

# ----------------------------------------------------------------- the state ---

func _test_the_state_survives_a_round_trip_and_a_lost_day(t) -> void:
	var state := PosterState.new()
	state.paste(Vector2i(3, 4), PosterArt.Kind.RULES, false, 1)
	state.paste(Vector2i(3, 4), PosterArt.Kind.LEADER, true, -1)
	state.pasted_through = 5
	state.photograph()
	state.tear(Vector2i(3, 4), 2)
	state.paste(Vector2i(9, 4), PosterArt.Kind.CURFEW, false, 1)
	state.tears = 3
	var cell: Dictionary = state.cells[Vector2i(3, 4)]
	t.check(int(cell["under"]) == PosterArt.Kind.RULES and int(cell["kind"]) == PosterArt.Kind.LEADER,
			"a sheet pasted over with an offset keeps the old one beneath it")
	var data := JSON.parse_string(JSON.stringify(state.to_data())) as Dictionary
	var loaded := PosterState.new()
	loaded.restore(data)
	t.check(loaded.to_data() == state.to_data(), "the walls survive a trip through a save file")
	loaded.give_back()
	t.check(loaded.cells.size() == 1 and loaded.has_intact_sheet(Vector2i(3, 4)) \
			and loaded.tears == 0 and loaded.pasted_through == 5,
			"a lost day gives back the morning's walls: the tear, the crew's sheet and the count go")
	state.paste(Vector2i(3, 4), PosterArt.Kind.UNIFORM, false, 1)
	t.check(int(state.cells[Vector2i(3, 4)]["under"]) == PosterState.NONE \
			and not state.is_torn(Vector2i(3, 4)),
			"a sheet pasted exactly over a torn one replaces it")

# ----------------------------------------------------------------- the walls ---

func _test_the_walls_fill_the_way_the_run_asks(t) -> void:
	for seed_value in SEEDS:
		var map := CityGenerator.generate(seed_value)
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		var walls := city.poster_walls()
		t.check(walls.wall_count() > 0, "seed %d: there are fronts to paste on (%d)"
				% [seed_value, walls.wall_count()])
		_check_every_front_is_blank_wall(t, city, map, seed_value)
		GameState.run_seed = seed_value
		GameState.posters.reset()
		var state := CityState.new()
		var before := 0
		var covered_on: Dictionary = {}
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			state.begin_day(map.block_plans, day)
			GameState.posters.photograph()
			city.start_day(state, day, GameState.day_rng(day, "closures"))
			var cells := GameState.posters.cells
			if day < PosterWalls.FIRST_DAY:
				t.check(cells.is_empty(), "seed %d: nothing is on a wall on day %d" % [seed_value, day])
			for tile: Vector2i in cells:
				var kind := int(cells[tile]["kind"])
				t.check(day >= int(PosterWalls.KIND_FIRST_DAY[kind]),
						"seed %d day %d: no %s sheet before day %d" % [seed_value, day,
						PosterArt.Kind.keys()[kind], PosterWalls.KIND_FIRST_DAY[kind]])
			t.check(cells.size() >= before, "seed %d day %d: the walls add to yesterday's (%d, %d)"
					% [seed_value, day, before, cells.size()])
			before = cells.size()
			covered_on[day] = before
			if day == 6:
				_check_a_retry_pastes_the_same_dawn(t, city, state, day, seed_value)
		t.check(int(covered_on[PosterWalls.FIRST_DAY]) > 0,
				"seed %d: some posters are already up on day 4's morning" % seed_value)
		t.check(int(covered_on[Tuning.RUN_LENGTH_DAYS]) > 3 * int(covered_on[PosterWalls.FIRST_DAY]),
				"seed %d: sparse at first and dense by the end (%d on day 4, %d on day %d)"
				% [seed_value, covered_on[PosterWalls.FIRST_DAY],
				covered_on[Tuning.RUN_LENGTH_DAYS], Tuning.RUN_LENGTH_DAYS])
		var offset := 0
		for tile: Vector2i in GameState.posters.cells:
			if int(GameState.posters.cells[tile]["under"]) != PosterState.NONE:
				offset += 1
		t.check(offset > 0 and offset * 2 < GameState.posters.cells.size(),
				"seed %d: some sheets show an older one beneath, and most do not (%d of %d)"
				% [seed_value, offset, GameState.posters.cells.size()])
		city.free()

## Every front tile is in front of a blank ground-floor cell of a building off her home block, and
## the cell is a real column of that building — so a sheet is never on a window, a door, a fire
## escape's column, a storefront or a portico.
func _check_every_front_is_blank_wall(t, city: City, map: CityMap, seed_value: int) -> void:
	var blank := {}
	for building in city.buildings():
		for rect in building.blank_ground_floor_cells():
			var front := map.world_to_tile(building.global_position
					+ Vector2(rect.get_center().x, Building.TILE * 0.5))
			blank[front] = building
	var fronts := city.poster_walls().fronts()
	var wrong: Array[String] = []
	for tile: Vector2i in fronts:
		var building: Building = blank.get(tile)
		if building == null or building.is_home_building or building.power_station:
			wrong.append(str(tile))
	t.check(wrong.is_empty(), "seed %d: every poster cell is blank wall off her block (%s)"
			% [seed_value, ", ".join(wrong.slice(0, 5))])

## A lost day gives the walls back and the retry's dawn pastes them again, identically.
func _check_a_retry_pastes_the_same_dawn(t, city: City, state: CityState, day: int,
		seed_value: int) -> void:
	var first := GameState.posters.to_data()
	GameState.posters.give_back()
	GameState.posters.pasted_through = mini(GameState.posters.pasted_through, day - 1)
	city.start_day(state, day, GameState.day_rng(day, "closures"))
	t.check(GameState.posters.to_data()["cells"] == first["cells"],
			"seed %d: a retried day %d pastes the same dawn" % [seed_value, day])

# ------------------------------------------------------------- the marble bag ---

## The pre-bag's one marble is the run's first tear and it is safe; every bag after it holds exactly
## one pursuit in ten, whatever order the draws come out in; the same seed draws the same marbles;
## and a bag brought forward by `skip()` draws on exactly as the one that was drawn from.
func _test_the_marble_bag_is_exact_and_reproducible(t) -> void:
	var bags := 20
	var a := MarbleBag.new(PosterWalls.TEAR_PRE_BAG, PosterWalls.TEAR_BAG, 4242)
	var first: Array[bool] = []
	for i in PosterWalls.TEAR_PRE_BAG.size() + bags * PosterWalls.TEAR_BAG.size():
		first.append(a.draw())
	t.check(not first[0], "the run's first tear never brings a pursuer")
	var per_bag := PosterWalls.TEAR_BAG.count(true)
	var uneven: Array[String] = []
	var positions := {}
	for b in bags:
		var start := PosterWalls.TEAR_PRE_BAG.size() + b * PosterWalls.TEAR_BAG.size()
		var bag := first.slice(start, start + PosterWalls.TEAR_BAG.size())
		if bag.count(true) != per_bag:
			uneven.append("bag %d: %d" % [b, bag.count(true)])
		positions[bag.find(true)] = true
	t.check(uneven.is_empty(), "every bag after the pre-bag holds exactly %d pursuit(s) (%s)"
			% [per_bag, ", ".join(uneven)])
	t.check(positions.size() > 3, "and where in its bag the pursuit comes is drawn, not fixed (%d places)"
			% positions.size())
	var again := MarbleBag.new(PosterWalls.TEAR_PRE_BAG, PosterWalls.TEAR_BAG, 4242)
	var same := true
	for drawn in first:
		same = same and again.draw() == drawn
	t.check(same, "the same seed draws the same marbles")
	var skipped := MarbleBag.new(PosterWalls.TEAR_PRE_BAG, PosterWalls.TEAR_BAG, 4242)
	skipped.skip(17)
	var resumed := true
	for i in range(17, first.size()):
		resumed = resumed and skipped.draw() == first[i]
	t.check(resumed, "a bag skipped forward draws on exactly where the drawn one does")

# ---------------------------------------------------------------- the push ---

## The push, on a real front of a built city with no player: `_push_to_tear()` is what the node
## runs every physics frame with her position and her steering. Pressing into the wall at its face
## tears after `PRESS_TO_TEAR`, a diagonal included; walking along it, standing back from it, or
## letting go before the time is up does not. Then the tears' marbles: the run's first is safe,
## one in each ten after it sends a patrol, and a lost day gives the tears back so the retry draws
## the same marbles again.
func _test_a_push_tears_and_walking_past_does_not(t) -> void:
	var map := CityGenerator.generate(SEEDS[0])
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(map)
	GameState.run_seed = SEEDS[0]
	GameState.posters.reset()
	var walls := city.poster_walls()
	var tiles: Array = walls.fronts().keys()
	tiles.sort()
	t.check(tiles.size() > 25, "there are fronts to push against (%d)" % tiles.size())
	if tiles.size() <= 25:
		city.free()
		return
	var tile: Vector2i = tiles[0]
	var face := map.tile_rect_to_world(Rect2i(tile, Vector2i.ONE)).position.y
	var at := Vector2(map.tile_rect_to_world(Rect2i(tile, Vector2i.ONE)).get_center().x,
			face + Tuning.PLAYER_BODY_RADIUS + Stroller.PRAM_BODY_RADIUS)
	var step := 1.0 / 60.0
	var hold := func(steering: Vector2, from: Vector2, seconds: float) -> void:
		for i in ceili(seconds / step):
			walls._push_to_tear(step, from, steering)
	walls._day_running = true

	GameState.posters.paste(tile, PosterArt.Kind.RULES, false, 1)
	hold.call(Vector2.RIGHT, at, 2.0)
	hold.call(Vector2(1.0, -0.2).normalized(), at, 2.0)
	t.check(GameState.posters.has_intact_sheet(tile), "walking along the wall, even drifting into it, tears nothing")
	hold.call(Vector2.UP, at + Vector2(0.0, 8.0), 2.0)
	t.check(GameState.posters.has_intact_sheet(tile), "a heading into the wall from back on the sidewalk tears nothing")
	hold.call(Vector2.UP, at, PosterWalls.PRESS_TO_TEAR * 0.75)
	hold.call(Vector2.ZERO, at, 0.1)
	hold.call(Vector2.UP, at, PosterWalls.PRESS_TO_TEAR * 0.75)
	t.check(GameState.posters.has_intact_sheet(tile), "letting go before the time is up starts it again")
	hold.call(Vector2.UP, at, PosterWalls.PRESS_TO_TEAR * 0.5)
	t.check(GameState.posters.is_torn(tile), "a push held for the time tears the sheet")
	t.check(GameState.posters.tears == 1, "and counts one tear")

	GameState.posters.paste(tile, PosterArt.Kind.LEADER, false, 1)
	hold.call(Vector2(-1.0, -1.0).normalized(), at, PosterWalls.PRESS_TO_TEAR + 0.05)
	t.check(GameState.posters.is_torn(tile), "a diagonal into the wall is a push too")
	GameState.posters.paste(tile, PosterArt.Kind.CURFEW, false, 1)
	t.check(GameState.posters.has_intact_sheet(tile), "a torn sheet pasted again is whole")

	# The marbles, tear by tear, on fresh sheets: the pre-bag and two whole bags after it.
	GameState.posters.reset()
	var tears := PosterWalls.TEAR_PRE_BAG.size() + 2 * PosterWalls.TEAR_BAG.size()
	var sent: Array[bool] = []
	GameState.posters.photograph()
	for i in tears:
		var cell: Vector2i = tiles[i]
		var spot := Vector2(map.tile_rect_to_world(Rect2i(cell, Vector2i.ONE)).get_center().x,
				map.tile_rect_to_world(Rect2i(cell, Vector2i.ONE)).position.y + 20.0)
		GameState.posters.paste(cell, PosterArt.Kind.RULES, false, 1)
		city.events._director._sent = null
		hold.call(Vector2.UP, spot, PosterWalls.PRESS_TO_TEAR + 0.05)
		sent.append(city.events.has_a_sent_patrol())
	t.check(GameState.posters.tears == tears, "every push tore its sheet (%d of %d)"
			% [GameState.posters.tears, tears])
	t.check(not sent[0], "the run's first tear sends nobody")
	t.check(sent.count(true) == 2, "two whole bags of tears send exactly two patrols (%d)"
			% sent.count(true))
	var first_marbles := sent.duplicate()
	GameState.posters.give_back()
	sent.clear()
	for i in tears:
		var cell: Vector2i = tiles[i]
		var spot := Vector2(map.tile_rect_to_world(Rect2i(cell, Vector2i.ONE)).get_center().x,
				map.tile_rect_to_world(Rect2i(cell, Vector2i.ONE)).position.y + 20.0)
		GameState.posters.paste(cell, PosterArt.Kind.RULES, false, 1)
		city.events._director._sent = null
		hold.call(Vector2.UP, spot, PosterWalls.PRESS_TO_TEAR + 0.05)
		sent.append(city.events.has_a_sent_patrol())
	t.check(sent == first_marbles, "a lost day gives the tears back and the retry draws the same marbles")
	city.events._director._sent = null
	city.free()

# ---------------------------------------------------------------- the patrol ---

## A pursuit marble's patrol: nothing while she stands at the wall, then — once she walks along the
## street — a `police_patrol` sited toward her on the carriageway, off screen; and neither the
## day's owed queue, its clock nor its stream has moved.
func _test_a_sent_patrol_comes_down_her_street_and_moves_nothing_else(t) -> void:
	var map := CityGenerator.generate(SEEDS[0])
	var director := EventDirector.new(map)
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var no_plans: Array[EventScheduler.Planned] = []
	director.start_day(6, no_plans, rng)
	var owed := director.owed()
	var next_in: float = director._next_in
	var state := rng.state
	director.send_a_patrol(0)
	director.send_a_patrol(0)
	t.check(director.has_a_sent_patrol(), "a pursuit marble sends a patrol")
	# The arterial's sidewalk is a real north-south street by construction.
	var at := CrowdLanes.arterial_pavement(map)
	at.y = map.world_size().y * 0.5
	var standing := director.due(5.0, at, Vector2.ZERO)
	t.check(standing.is_empty() and director.has_a_sent_patrol(),
			"it is not sited while she stands pushing at the wall")
	var walking := Vector2(0.0, -Tuning.WALK_SPEED)
	var handed: Array = []
	for i in 120:
		handed = director.due(1.0 / 60.0, at, walking)
		if not handed.is_empty():
			break
	t.check(handed.size() == 2, "once she walks, it is sited")
	if handed.size() == 2:
		var def := handed[0] as EventDef
		var path := handed[1] as PackedVector2Array
		t.check(def.id == "police_patrol" and def.spawn_mode == EventDef.SpawnMode.TOWARD_PLAYER,
				"it is a police patrol coming toward her")
		t.check(absf(path[0].y - at.y) > Tuning.VIEW_HALF_EXTENT.y and path[0].y < at.y,
				"ahead of her and off screen (%.0fpx)" % absf(path[0].y - at.y))
		t.check((path[1] - path[0]).dot(walking) < 0.0, "and driving toward her")
	t.check(not director.has_a_sent_patrol(), "one pursuit marble is one patrol, however often drawn")
	t.check(director.owed() == owed and rng.state == state,
			"the day's own queue and stream are untouched")
	t.check(director._next_in <= next_in and director._next_in > next_in - 3.0,
			"and its clock ran only while she walked (%.2f, then %.2f)" % [next_in, director._next_in])
