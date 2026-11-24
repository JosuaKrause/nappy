class_name PlacementProbeDay
extends RefCounted
## **One day of one city planned as the game plans it, for the two placement probes**
## (`placement_rows.gd`, `placement_view_mix.gd`): the one place under `tests/probes/` that
## holds the planning block they share. A helper, not a probe: nothing here prints, and the
## runner loads only `test_*.gd`.
##
## `prepared()` makes the city `BASE + i * STEP` and plans its day's closures, holds, region
## wall and seals (`City.start_day()`, `DayPlanner._plan_a_day()`), the seals and the wall's
## bodies stood as the day's standing, then refreshes the street trees the seals' pits emptied
## (`City.refresh_street_trees()`), as the game's own path does once the seals are planned.
## `placements()` then plans the dawn: the day's guarded-band roadblock row heated to the run's
## progress (`EventCatalogue.heated()`) as `DayPlanner` hands it, and the dawn told the same
## progress. The run is the one that completes every task the calendar has offered before the
## day (`progress_on()`), so the heat each day sees is the heat a run that does them all sees.

const BASE := 90210
const STEP := 31
const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The seed the city's run starts from: fixed, so every machine measures the same run.
const RUN_SEED := 2

var map: CityMap
var city: City
var tree: RouteTree
var spec: DaySpec
var corridor: Corridor
var doors := PackedVector2Array()
var seals: Array[EventPlan] = []
var standing: Array[EventPlan] = []
var _sites: Array[MastSites.Site] = []
var _day := 0
var _i := 0

## The resistance progress of a run that completes every task offered before `day`: the finale's
## day sees the goal, a day before the tasks begin none.
static func progress_on(day: int) -> int:
	if day >= Tuning.RUN_LENGTH_DAYS:
		return Tuning.RESISTANCE_GOAL
	var progress := 0
	for step in ResistanceSteps.all():
		if step.grants_progress and step.index <= 2 * (day - 6):
			progress += 1
	return mini(progress, Tuning.RESISTANCE_GOAL)

## Day `day` of the `i`th city, planned up to the dawn. `tag` names the probe whose streams the
## closures and the seals draw from, `parent` is where the city stands while it is asked: the
## caller frees `city` when it is done with the day.
static func prepared(day: int, i: int, tag: String, parent: Node) -> PlacementProbeDay:
	var the_day := PlacementProbeDay.new()
	the_day._day = day
	the_day._i = i
	the_day._prepare(tag, parent)
	return the_day

func _prepare(tag: String, parent: Node) -> void:
	map = CityGenerator.generate(BASE + _i * STEP)
	city = RunCity.new_city(CITY_SCENE)
	parent.add_child(city)
	RunCity.build(city, RunCity.started_run(RUN_SEED), map)
	# The run's mast sites, worked out once on the city as built, as the game does.
	_sites = MastSites.compute(map)
	var state := CityState.new()
	state.begin_day(map.plans_by_block(), _day)
	map.repaint(state)
	tree = RouteTree.for_day(map, _day)
	spec = DaySpec.for_day(_day)
	# The day's own closures, holds, region wall and seals, planned as the game plans them
	# (`City.start_day()`, `DayPlanner._plan_a_day()`), so the seals and the wall's bodies
	# stand as the day's standing and hold their locations.
	var region_plan := RegionPlanner.plan_day(map, spec, tree)
	var closure_rng := RandomNumberGenerator.new()
	closure_rng.seed = hash("%s closures:%d:%d" % [tag, _i, _day])
	var closures := ClosurePlanner.plan_day(map, spec, closure_rng, tree, region_plan)
	map.close_streets(closures)
	map.clear_day_holds()
	for closure: RoadClosure in closures:
		map.hold_segment(closure.street_key(), HeldStreets.Why.CLOSURE)
	for segment: StreetNetwork.Segment in region_plan.wall_segments():
		map.hold_segment(segment.key(), HeldStreets.Why.WALL)
	for segment: StreetNetwork.Segment in region_plan.door_segments():
		map.hold_segment(segment.key(), HeldStreets.Why.DOOR)
	for segment: StreetNetwork.Segment in map.street_network().around_blocks(
			Rect2i(map.home_block_coordinate(), Vector2i.ONE)):
		map.hold_segment(segment.key(), HeldStreets.Why.HOME)
	var boundary := {}
	for segment in region_plan.wall_segments():
		boundary[segment.key()] = true
	for segment in region_plan.door_segments():
		boundary[segment.key()] = true
	for rect in region_plan.walled_alleys():
		boundary[rect.position] = true
	for rect in region_plan.door_alleys():
		boundary[rect.position] = true
	var seal_rng := RandomNumberGenerator.new()
	seal_rng.seed = hash("%s seals:%d:%d" % [tag, _i, _day])
	seals = SealPlanner.plan_day(map, spec, tree, seal_rng, boundary, map.held_streets())
	for seal in seals:
		seal.stand_as_a_seal()
	# A fallen-tree seal empties a pit of its own; the day's start shows the trees that way.
	city.refresh_street_trees()
	for body in region_plan.door_plans():
		doors.append(body.placed_at())
	standing.append_array(seals)
	standing.append_array(region_plan.wall_plans())
	for body in region_plan.wall_plans():
		body.stand_in_the_wall()
	corridor = Corridor.of(tree)

## The dawn's placements, planned on the stream both probes use (`placement_view_mix:i:day`).
func placements() -> Array[EventPlan]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("placement_view_mix:%d:%d" % [_i, _day])
	var progress := progress_on(_day)
	var guarded := ResistanceSteps.guarded_row_on(_day)
	var beside: EventDef = EventCatalogue.heated(EventCatalogue.by_id(guarded), progress) \
			if guarded != "" else null
	var consumed: Array[String] = []
	return GameDawn.of(spec, rng, map).masts(_sites).spent(consumed).heat(progress).on(tree) \
			.doors(doors).standing(standing).roadblock(beside).plan().placements()
