class_name PlacementProbeDay
extends RefCounted
## **One day of one city planned as the game plans it, for the two placement probes**
## (`placement_rows.gd`, `placement_view_mix.gd`): the one place under `tests/probes/` that
## holds the planning block they share. A helper, not a probe: nothing here prints, and the
## runner loads only `test_*.gd`.
##
## `prepared()` makes the city `BASE + i * STEP` and plans its day's closures, holds, region
## wall and seals (`City.start_day()`, `DayPlanner._plan_a_day()`), the seals and the wall's
## bodies stood as the day's standing. `placements()` then plans the dawn with the day's
## guarded-band roadblock row through `EventCatalogue.heated()` as `DayPlanner` hands
## it, and refreshes the street trees (`City.refresh_street_trees()`) once the dawn has placed,
## where the game refreshes them (`DayDirector`, after `EventManager.start_day()`).
##
## **The dawn is planned at heat 0, a run with no resistance progress**: every baseline reading
## of the placement (`docs/evidence/minty-quail-baseline-2026-11-09/`) was taken at that heat,
## so a later reading compares with it count for count. At level 0 `heated()` returns the row
## itself. A reading at another heat is a reading of its own beside this one, as
## `downy_llama_route_roadblocks.gd` runs heats 0 and 4. The tree refresh only shows or hides
## tree pictures and cannot move a count. The dawn gets `GameDawn`'s default calm areas, where
## the game sets aside the day's narrow task spot (day 9's door, day 12's swing park, day 14's
## station door), as the baseline's probes do.

const BASE := 90210
const STEP := 31
const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The seed the city's run starts from: fixed, so every machine measures the same run.
const RUN_SEED := 2
## The resistance progress, and so the heat, every placement reading is taken at.
const HEAT := 0

var map: CityMap
var city: City
var _tree: RouteTree
var _spec: DaySpec
var corridor: Corridor
var _doors := PackedVector2Array()
var _seals: Array[EventPlan] = []
var _standing: Array[EventPlan] = []
var _sites: Array[MastSites.Site] = []
var _day := 0
var _i := 0

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
	_sites = MastSites.compute(Shipped.rows(), map)
	var state := CityState.new()
	state.begin_day(map.plans_by_block(), _day)
	map.repaint(state)
	_tree = RouteTree.for_day(map, _day, null)
	_spec = DaySpec.for_day(_day)
	# The day's own closures, holds, region wall and seals, planned as the game plans them
	# (`City.start_day()`, `DayPlanner._plan_a_day()`), so the seals and the wall's bodies
	# stand as the day's standing and hold their locations.
	var region_plan := RegionPlanner.plan_day(Shipped.rows(), map, _spec, _tree)
	var closure_rng := RandomNumberGenerator.new()
	closure_rng.seed = hash("%s closures:%d:%d" % [tag, _i, _day])
	var closures := ClosurePlanner.plan_day(Shipped.rows(), map, _spec, closure_rng,
			_tree, region_plan)
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
	_seals = SealPlanner.plan_day(Shipped.rows(), map, _spec, _tree, seal_rng,
			boundary, map.held_streets())
	for seal in _seals:
		seal.stand_as_a_seal()
	for body in region_plan.door_plans():
		_doors.append(body.placed_at())
	_standing.append_array(_seals)
	_standing.append_array(region_plan.wall_plans())
	for body in region_plan.wall_plans():
		body.stand_in_the_wall()
	corridor = Corridor.of(_tree)

## The dawn's placements, planned on the stream both probes use (`placement_view_mix:i:day`),
## the street trees refreshed once it has placed.
func placements() -> Array[EventPlan]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("placement_view_mix:%d:%d" % [_i, _day])
	var guarded := ResistanceSteps.guarded_row_on(_day)
	var beside: EventDef = Shipped.rows().heated(Shipped.rows()
			.by_id(guarded), HEAT) \
			if guarded != "" else null
	var consumed: Array[String] = []
	var placed := GameDawn.of(_spec, rng, map).masts(_sites).spent(consumed).heat(HEAT).on(_tree) \
			.doors(_doors).standing(_standing).roadblock(beside).plan().placements()
	city.refresh_street_trees()
	return placed
