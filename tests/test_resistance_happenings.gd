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
## building, which only a generated map has (a home, its doorstep and the street in front of it). The
## cases that check the raid's view are handed a siting built over the map (`SpawnSiting.new()`) with
## a view they aim; the others are handed none, which the happenings read as none (`setup()`), so
## what holds the raid back there is her distance from her door alone. The real door's picture once
## sealed is the city's (`tests/test_home_block.gd`).

const SEED := 4242
## The seed of the suite's own run.
const RUN_SEED := 2
const STEP := 1.0 / 60.0

func run(t: TestRunner) -> void:
	_test_the_raid_seals_her_street_door(t)
	_test_the_raid_waits_at_her_building_with_the_doorstep_open(t)
	_test_the_raid_waits_for_the_patrol_cars_beat_to_be_out_of_her_view(t)
	_test_the_market_goes_where_the_route_tree_says_she_is_heading(t)
	_test_the_market_waits_while_she_can_see_it(t)
	_test_the_neighbors_window_is_boarded_from_day_eleven(t)

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
	state.begin_day(map.plans_by_block(), ResistanceHappenings.MARKET_DAY)
	var door := map.doorstep_world_position()
	var out_of_sight: Array[Vector2i] = []
	for y in Tuning.CITY_BLOCKS.y:
		for x in Tuning.CITY_BLOCKS.x:
			var block := Vector2i(x, y)
			if map.plans_by_block().has(block) \
					and state.purpose_of(map.plans_by_block(), block) == GameEnums.BlockPurpose.COMMERCIAL \
					and state.next_purpose(map.plans_by_block(), block) == GameEnums.BlockPurpose.BOARDED_UP \
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
	t.check(state.purpose_of(map.plans_by_block(), further) == GameEnums.BlockPurpose.BOARDED_UP,
			"the block the tree's cells reach is boarded up")
	t.check(state.purpose_of(map.plans_by_block(), nearer) == GameEnums.BlockPurpose.COMMERCIAL,
			"and the nearer block, which the happenings fall back to, is not")
	events.free()

## Day 10's raid: vans at her building and a patrol, arriving only once she is out of sight of her
## door, and never on her own sidewalk — the doorstep stays reachable along it. The siting the
## raid is held to is built over the map with a view the case aims (`SpawnSiting.new()`), as the
## game builds it over the city's.
func _test_the_raid_waits_at_her_building_with_the_doorstep_open(t: TestRunner) -> void:
	var map := CityGenerator.generate(SEED)
	var view := VisibleView.new()
	var siting := SpawnSiting.new(map, Navigator.new(map), func() -> VisibleView: return view)
	var events := FakeEventManager.new()
	var happenings := _raid_happenings(map, events, siting)
	var door := map.doorstep_world_position()
	var away := door + Vector2(0.0, Tuning.OUT_OF_SIGHT + 64.0)
	view.look(Rect2(), null)
	var before := events.instances()
	happenings.tick(STEP, door, Vector2.ZERO)
	t.check(_raid_since(events, before).is_empty(), "nothing arrives while she is at her door")
	view.look(Rect2(door - Vector2(400.0, 400.0), Vector2(800.0, 800.0)), null)
	happenings.tick(STEP, away, Vector2.ZERO)
	t.check(_raid_since(events, before).is_empty(), "or while any of it would be on screen")
	view.look(Rect2(), null)
	happenings.tick(STEP, away, Vector2.ZERO)
	var vans := 0
	var patrols := 0
	var door_tile := map.world_to_tile(door)
	var raid := _raid_since(events, before)
	for instance in raid:
		if instance.row_id() == "night_raid":
			vans += 1
			t.check(not instance.pursues(), "a van at her door does not hunt")
			for tile in EventSpawner.footprint_of(BodyStance.of(map, instance.row(),
					instance.global_position, Vector2.RIGHT)):
				t.check(tile.y > door_tile.y + Tuning.SIDEWALK_WIDTH - 1,
						"a van's body is off her own sidewalk (%s)" % tile)
		elif instance.row_id() == "police_patrol":
			patrols += 1
			t.check(instance.ground_shape() != null, "the patrol car keeps its shape")
	t.check(vans == 2 and patrols == 1, "two vans and a patrol at her building (%d, %d)"
			% [vans, patrols])
	for instance in raid:
		events.retire(instance)
	before = events.instances()
	happenings.start_day(ResistanceSteps.NEIGHBOR_DAY + 1)
	happenings.tick(STEP, away, Vector2.ZERO)
	t.check(_raid_since(events, before).is_empty(), "and only on day 10")
	events.free()

## **The patrol car's beat is held to the view on its own**, apart from the vans. The beat
## runs `RAID_PATROL_REACH_TILES` either side of her door, further than the vans'
## `RAID_VAN_OFFSET_TILES`, so a view that holds one end of the beat and neither van is one only
## the patrol car's own check can refuse (`ResistanceHappenings._maybe_raid()`): the view is the
## car's own drawing box standing at the beat's far end, and the raid holds back; with the view
## looking at nothing the same tick brings it. The two premises are checked first, or the test
## would pass on the vans' check alone: neither van would be drawn in that view, and the car would.
func _test_the_raid_waits_for_the_patrol_cars_beat_to_be_out_of_her_view(t: TestRunner) -> void:
	var map := CityGenerator.generate(SEED)
	var view := VisibleView.new()
	var siting := SpawnSiting.new(map, Navigator.new(map), func() -> VisibleView: return view)
	var events := FakeEventManager.new()
	var happenings := _raid_happenings(map, events, siting)
	var door := map.doorstep_world_position()
	var door_tile := map.world_to_tile(door)
	var corridor := door_tile.y - CityMap.corridor_offset(door_tile.y)
	var far_side := corridor + Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH
	var lane := corridor + Tuning.SIDEWALK_WIDTH
	var beat_end := map.tile_to_world(
			Vector2i(door_tile.x + ResistanceHappenings.RAID_PATROL_REACH_TILES, lane))
	var van_box := EventFootprints.footprint_of(EventCatalogue.shipped().by_id("night_raid"))
	var car_box := EventFootprints.footprint_of(EventCatalogue.shipped().by_id("police_patrol"))
	view.look(Rect2(beat_end + car_box.position, car_box.size), null)
	var van_in_view := false
	for side: int in [-1, 1]:
		var van_at := map.tile_to_world(
				Vector2i(door_tile.x + side * ResistanceHappenings.RAID_VAN_OFFSET_TILES, far_side))
		van_in_view = van_in_view or _would_show(siting, van_box, van_at)
	t.check(not van_in_view and _would_show(siting, car_box, beat_end),
			"the view holds the patrol car's far end and neither van, or this test checks the vans alone")
	var before := events.instances()
	var away := door + Vector2(0.0, Tuning.OUT_OF_SIGHT + 64.0)
	happenings.tick(STEP, away, Vector2.ZERO)
	t.check(_raid_since(events, before).is_empty(),
			"the raid waits while the patrol car's beat would be drawn in her view, the vans out of it")
	view.look(Rect2(), null)
	happenings.tick(STEP, away, Vector2.ZERO)
	t.check(_raid_since(events, before).size() == 3, "and arrives the moment none of it would be")
	events.free()

## Happenings on day 10 over `map`, handed `events` and `siting`, with its own run and the fronts
## stand-in, started.
func _raid_happenings(map: CityMap, events: FakeEventManager, siting: SpawnSiting) -> ResistanceHappenings:
	var run_state := RunState.new()
	run_state.start_run(RUN_SEED)
	run_state.header().set_day(ResistanceSteps.NEIGHBOR_DAY)
	var happenings := ResistanceHappenings.new()
	happenings.setup(map, run_state, events, DayStreets.new(), FakeCityFronts.new(), null, null, null,
			siting)
	happenings.start_day(ResistanceSteps.NEIGHBOR_DAY)
	return happenings

## Whether a drawing of `box` about its feet, standing at `at`, would be drawn in `siting`'s view.
func _would_show(siting: SpawnSiting, box: Rect2, at: Vector2) -> bool:
	return not siting.allows(SpawnSiting.Rule.DRAWING_OFF_THE_VIEW, siting.ask_of_drawing(box), at)

## Day 10's raid as `events` holds it: the night raid's vans and the patrol car pacing between
## them, among the live instances that were not in `before` (an earlier `instances()`).
func _raid_since(events: FakeEventManager, before: Array[EventInstance]) -> Array[EventInstance]:
	var found: Array[EventInstance] = []
	for instance in events.instances():
		if instance in before or instance.is_gone():
			continue
		if instance.row_id() == "night_raid" or (instance.row_id() == "police_patrol"
				and instance.row().paces_a_beat()):
			found.append(instance)
	return found

## Day 11: **a market in her sight is not boarded up.** She stands in the middle of a candidate
## block's frontage and walks as long as the market waits for a way to be chosen, and then past it;
## the route tree names a cell of that very block, so the block is the one the happenings would
## choose were it out of her sight, and it stays commercial, whatever the day does with the others.
## Checked on each of the first two candidates, a block-arcs record of its own for each.
func _test_the_market_waits_while_she_can_see_it(t: TestRunner) -> void:
	var map := CityGenerator.generate(SEED)
	var seen := 0
	for which in 2:
		var run_state := RunState.new()
		run_state.start_run(RUN_SEED)
		run_state.header().set_day(ResistanceHappenings.MARKET_DAY)
		var state := run_state.attempt_spend().block_arcs()
		state.reset()
		state.begin_day(map.plans_by_block(), ResistanceHappenings.MARKET_DAY)
		var candidates: Array[Vector2i] = []
		for y in Tuning.CITY_BLOCKS.y:
			for x in Tuning.CITY_BLOCKS.x:
				var candidate := Vector2i(x, y)
				if map.plans_by_block().has(candidate) \
						and state.purpose_of(map.plans_by_block(), candidate) == GameEnums.BlockPurpose.COMMERCIAL \
						and state.next_purpose(map.plans_by_block(), candidate) == GameEnums.BlockPurpose.BOARDED_UP:
					candidates.append(candidate)
		if candidates.size() <= which:
			break
		var block := candidates[which]
		var her := _frontage_of(map, block).get_center()
		var cell := map.world_to_tile(her) / ReachabilityGrid.CELL
		var tree := FakeRouteTree.new(map).set_cells_ahead({cell: 100.0})
		t.check(_frontage_of(map, block).has_point(tree.cell_centre(cell)),
				"the cell the tree names lies in the block's frontage")
		var streets := DayStreets.new()
		var no_closures: Array[RoadClosure] = []
		streets.begin_day(tree, null, no_closures)
		var events := FakeEventManager.new()
		var happenings := ResistanceHappenings.new()
		happenings.setup(map, run_state, events, streets, FakeCityFronts.new(), null, null)
		happenings.start_day(ResistanceHappenings.MARKET_DAY)
		happenings.tick(ResistanceHappenings.MARKET_GONE_BY, her, Vector2.RIGHT * Tuning.WALK_SPEED)
		happenings.tick(ResistanceHappenings.MARKET_GONE_BY, her, Vector2.RIGHT * Tuning.WALK_SPEED)
		seen += 1
		t.check(state.purpose_of(map.plans_by_block(), block) == GameEnums.BlockPurpose.COMMERCIAL,
				"the market in block %s is not boarded up with her standing in front of it" % block)
		events.free()
	t.check(seen > 0, "the test city has a block to stand in front of, or this test checks nothing")

## Day 11: **the neighbor's window is boarded from this morning on, and not before.** The happenings
## ask the fronts to board it on the day's start from day 11 and not on the day before; the fronts'
## own boarding, its cell and its being the same on every later day and a fresh load, is
## `tests/test_home_block.gd`'s.
func _test_the_neighbors_window_is_boarded_from_day_eleven(t: TestRunner) -> void:
	var map := CityGenerator.generate(SEED)
	var run_state := RunState.new()
	run_state.start_run(RUN_SEED)
	var fronts := FakeCityFronts.new()
	var happenings := ResistanceHappenings.new()
	var events := FakeEventManager.new()
	happenings.setup(map, run_state, events, DayStreets.new(), fronts, null, null)
	happenings.start_day(ResistanceHappenings.MARKET_DAY - 1)
	t.check(fronts.boardings() == 0, "unboarded the day before")
	happenings.start_day(ResistanceHappenings.MARKET_DAY)
	t.check(fronts.boardings() == 1, "boarded from day 11's morning on")
	happenings.start_day(ResistanceHappenings.MARKET_DAY + 3)
	t.check(fronts.boardings() == 2, "and asked again on every later day, which the fronts answer once")
	events.free()

## A block's lot and the sidewalk round it, in world space: what a market on it stands in.
func _frontage_of(map: CityMap, block: Vector2i) -> Rect2:
	return map.tile_rect_to_world(map.lot_rect(block).grow(Tuning.SIDEWALK_WIDTH))

## How far `point` is from `rect`, zero inside it.
func _distance_to_rect(point: Vector2, rect: Rect2) -> float:
	var nearest := Vector2(clampf(point.x, rect.position.x, rect.end.x),
			clampf(point.y, rect.position.y, rect.end.y))
	return point.distance_to(nearest)
