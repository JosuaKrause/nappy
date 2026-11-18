extends RefCounted
## `ResistanceHappenings`, what the resistance's story puts in the street besides the task, checked
## with no city: the happenings are handed a stand-in for the day's events (`FakeEventManager`) and
## for the fronts the story changes (`FakeCityFronts`), as `ResistanceDirector.setup()` hands them
## the city's, and a run of the suite's own.
##
## Day 11's market goes where the day's route tree says she is heading: the suite hands the happenings a
## `FakeRouteTree` that names the cells ahead of her, so what is checked is that the happenings ask
## the tree and board up the block whose frontage those cells reach, not the nearer block they would
## fall back to.
##
## The map is a generated one (`CityGenerator.generate()`), handed as data: the raid stands at her
## building, which only a generated map has (a home, its doorstep and the street in front of it). No
## siting is handed, which the happenings read as none (`setup()`), so what holds the raid back here
## is her distance from her door alone; the view's own refusal is checked with the city's siting in
## `tests/test_resistance_placement_kinds.gd`, as is the real door's picture once sealed.

const SEED := 4242
## The seed of the suite's own run.
const RUN_SEED := 2
const STEP := 1.0 / 60.0

func run(t: TestRunner) -> void:
	_test_the_raid_seals_her_street_door(t)
	_test_the_market_goes_where_the_route_tree_says_she_is_heading(t)

## Her street door: ordinary at day 10's start, sealed the moment the raid actually arrives, out
## of her sight (PLAYTEST-131), and the scar it leaves is what every later day and a reloaded save
## read it from (`City._sync_home_door()`).
func _test_the_raid_seals_her_street_door(t: TestRunner) -> void:
	var map := CityGenerator.generate(SEED)
	var run_state := RunState.new()
	run_state.start_run(RUN_SEED)
	run_state.header().set_day(ResistanceSteps.NEIGHBOR_DAY)
	var events := FakeEventManager.new()
	var fronts := FakeCityFronts.new()
	var happenings := ResistanceHappenings.new()
	happenings.setup(map, run_state, events, DayStreets.new(), fronts, null, null)
	happenings.start_day(ResistanceSteps.NEIGHBOR_DAY)
	t.check(fronts.seals() == 0, "the door is ordinary at day 10's start")
	var door := map.doorstep_world_position()
	happenings.tick(STEP, door + Vector2(0.0, Tuning.OUT_OF_SIGHT + 64.0), Vector2.ZERO)
	t.check(fronts.seals() == 1, "and sealed the moment the raid arrives, out of her sight")
	var sealed := false
	for scar in run_state.attempt_spend().scars():
		if String(scar["id"]) == City.SEALED_DOOR_SCAR:
			sealed = true
	t.check(sealed, "which leaves a scar for every later day to read")
	events.free()

## Day 11: **the market is boarded up where the route tree says she is going.** Two blocks wait to
## board up, both out of her sight; the tree names a cell of the one further from her, so that is the
## one that goes, and the nearer one, which the happenings fall back to when the tree says nothing
## (`ResistanceHappenings._market_out_of_her_sight()`), stays as it is.
func _test_the_market_goes_where_the_route_tree_says_she_is_heading(t: TestRunner) -> void:
	var map := CityGenerator.generate(SEED)
	var run_state := RunState.new()
	run_state.start_run(RUN_SEED)
	run_state.header().set_day(ResistanceHappenings.MARKET_DAY)
	var state := run_state.attempt_spend().block_arcs()
	state.reset()
	state.begin_day(map.block_plans, ResistanceHappenings.MARKET_DAY)
	var door := map.doorstep_world_position()
	var out_of_sight: Array[Vector2i] = []
	for y in Tuning.CITY_BLOCKS.y:
		for x in Tuning.CITY_BLOCKS.x:
			var block := Vector2i(x, y)
			if map.block_plans.has(block) \
					and state.purpose_of(map.block_plans, block) == GameEnums.BlockPurpose.COMMERCIAL \
					and state.next_purpose(map.block_plans, block) == GameEnums.BlockPurpose.BOARDED_UP \
					and _distance_to_rect(door, _frontage_of(map, block)) >= Tuning.OUT_OF_SIGHT:
				out_of_sight.append(block)
	t.check(out_of_sight.size() >= 2,
			"the test city has two blocks waiting to board up out of her sight, or this test checks nothing (%d)"
			% out_of_sight.size())
	if out_of_sight.size() < 2:
		return
	out_of_sight.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _distance_to_rect(door, _frontage_of(map, a)) < _distance_to_rect(door, _frontage_of(map, b)))
	var nearer: Vector2i = out_of_sight[0]
	var further: Vector2i = out_of_sight[out_of_sight.size() - 1]
	var frontage := _frontage_of(map, further)
	var cell := map.world_to_tile(frontage.get_center()) / ReachabilityGrid.CELL
	var tree := FakeRouteTree.new(map).set_cells_ahead({cell: 100.0})
	t.check(frontage.has_point(tree.cell_centre(cell)),
			"the cell the tree names lies in the further block's frontage")
	var streets := DayStreets.new()
	var no_closures: Array[RoadClosure] = []
	streets.begin_day(tree, null, no_closures)
	var events := FakeEventManager.new()
	var happenings := ResistanceHappenings.new()
	happenings.setup(map, run_state, events, streets, FakeCityFronts.new(), null, null)
	happenings.start_day(ResistanceHappenings.MARKET_DAY)
	happenings.tick(EventDirector.ON_HER_WAY_AFTER, door, Vector2.RIGHT * Tuning.WALK_SPEED)
	t.check(state.purpose_of(map.block_plans, further) == GameEnums.BlockPurpose.BOARDED_UP,
			"the block the tree's cells reach is boarded up")
	t.check(state.purpose_of(map.block_plans, nearer) == GameEnums.BlockPurpose.COMMERCIAL,
			"and the nearer block, which the happenings fall back to, is not")
	events.free()

## A block's lot and the sidewalk round it, in world space: what a market on it stands in.
func _frontage_of(map: CityMap, block: Vector2i) -> Rect2:
	return map.tile_rect_to_world(map.lot_rect(block).grow(Tuning.SIDEWALK_WIDTH))

## How far `point` is from `rect`, zero inside it.
func _distance_to_rect(point: Vector2, rect: Rect2) -> float:
	var nearest := Vector2(clampf(point.x, rect.position.x, rect.end.x),
			clampf(point.y, rect.position.y, rect.end.y))
	return point.distance_to(nearest)
