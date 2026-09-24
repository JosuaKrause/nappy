extends RefCounted
## The posters on the walls: where a sheet may go, how the walls fill day by day, the pasting-over
## rule, what a save and a lost day do to them.
##
## What a picture of a front can judge — whether the sheets read at walking distance — is the
## stills' job; this holds what a picture cannot: that no sheet is ever on a window, a door, a fire
## escape or her own block, that nothing is up before day 4 and each day's walls add to the last,
## that a kind never arrives before its day, and that the whole thing is the same from the same
## seed and given back whole by a lost day.

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
