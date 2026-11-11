extends RefCounted
## **Today's streets as dawn left them** (`DayStreets`), with no city: what each of its two writes
## replaces and what it leaves, and the one fact it derives, the region a siting reads off the
## day's wall and doors, built once for a plan and handed again until the plan is another plan.
##
## Everything it is handed is plain data built as it is: region plans whose bodies, alley walls and
## rows are written here, closures over a street segment, and empty route trees that stand only for
## the tree a dawn grew, since `DayStreets` never asks its tree anything. It is read only through its
## methods. The region it hands is a `SpawnSiting.Region`, a record with no methods, so its discs
## are read off its fields.

const TILE := float(Tuning.TILE_SIZE)

func run(t: TestRunner) -> void:
	_test_before_any_day_there_are_no_streets(t)
	_test_each_write_replaces_what_it_says(t)
	_test_the_siting_region_is_built_once_for_a_plan(t)

## A row whose body reaches `radius` from its centre, the one thing of its row the region reads.
func _row(radius: float) -> EventDef:
	var def := EventDef.new()
	def.obstructs_radius = radius
	return def

## A day's wall and doors as data: one wall body, two door bodies and one walled alley.
func _a_walled_plan() -> RegionPlanner.RegionPlan:
	var plan := RegionPlanner.RegionPlan.new()
	plan.wall_bodies.append(EventScheduler.Planned.new(_row(40.0), Vector2(10.5, 3.5) * TILE))
	plan.door_bodies.append(EventScheduler.Planned.new(_row(18.0), Vector2(20.5, 9.5) * TILE))
	plan.door_bodies.append(EventScheduler.Planned.new(_row(24.0), Vector2(22.5, 9.5) * TILE))
	plan.alley_walls.append(Rect2i(30, 12, 1, 4))
	return plan

func _closures_on(junction: Vector2i) -> Array[RoadClosure]:
	var closures: Array[RoadClosure] = [
		RoadClosure.new(RoadClosure.Kind.ROADWORKS, StreetNetwork.Segment.new(junction, true))]
	return closures

## The escape's city never begins a day, and a city's first dawn has not yet run: no tree, no plan,
## no closures and no region for a siting to read.
func _test_before_any_day_there_are_no_streets(t: TestRunner) -> void:
	var streets := DayStreets.new()
	t.check(streets.route_tree() == null and streets.region_plan() == null,
			"before any day, there is no tree and no region plan")
	t.check(streets.closures().is_empty(), "and no street is closed")
	t.check(streets.closure_summary() == "none", "so its summary says none")
	t.check(streets.siting_region() == null, "and a siting reads no region")

## A dawn replaces all three of the day's answers; a rig's or a scene recipe's authored plan
## replaces the plan alone, and the next dawn replaces that plan as well.
func _test_each_write_replaces_what_it_says(t: TestRunner) -> void:
	var streets := DayStreets.new()
	var first_tree := RouteTree.new()
	var first_plan := _a_walled_plan()
	var first_closures := _closures_on(Vector2i(2, 3))
	streets.begin_day(first_tree, first_plan, first_closures)

	var authored := RegionPlanner.RegionPlan.new()
	streets.replace_region_plan(authored)
	t.check(streets.region_plan() == authored, "an authored plan replaces the day's plan")
	t.check(streets.route_tree() == first_tree and streets.closures() == first_closures,
			"and leaves the day's tree and its closures as dawn left them")

	var next_tree := RouteTree.new()
	var next_plan := _a_walled_plan()
	var next_closures := _closures_on(Vector2i(5, 6))
	streets.begin_day(next_tree, next_plan, next_closures)
	t.check(streets.route_tree() == next_tree and streets.region_plan() == next_plan
			and streets.closures() == next_closures,
			"the next dawn replaces the tree, the plan (the authored one too) and the closures")

## **The region a siting reads is built once for a plan**: a relocation of the resistance's mark asks
## it for every candidate tile, so building the wall's and the doors' discs afresh on each ask was
## most of that cost. The same plan gives the same region; another plan gives another region, built
## from that plan.
func _test_the_siting_region_is_built_once_for_a_plan(t: TestRunner) -> void:
	var streets := DayStreets.new()
	var walled := _a_walled_plan()
	var no_closures: Array[RoadClosure] = []
	streets.begin_day(null, walled, no_closures)

	var first := streets.siting_region()
	t.check(first != null, "a day with a wall gives a siting a region")
	t.check(streets.siting_region() == first, "asked again, it is handed the same region")
	t.check(first.centres == PackedVector2Array([Vector2(10.5, 3.5) * TILE,
			Vector2(20.5, 9.5) * TILE, Vector2(22.5, 9.5) * TILE]),
			"its discs stand where the wall's body and then the doors' bodies stand (%s)"
			% first.centres)
	t.check(first.radii == PackedFloat64Array([40.0, 18.0, 24.0]),
			"each as far as its own row's body reaches (%s)" % first.radii)
	var walled_alley: Array[Rect2i] = [Rect2i(30, 12, 1, 4)]
	t.check(first.walled_alleys == walled_alley, "and it shuts the plan's walled alley")

	var other := RegionPlanner.RegionPlan.new()
	other.alley_walls.append(Rect2i(8, 2, 1, 3))
	streets.replace_region_plan(other)
	var changed := streets.siting_region()
	var other_alley: Array[Rect2i] = [Rect2i(8, 2, 1, 3)]
	t.check(changed != first and changed.centres.is_empty() and changed.walled_alleys == other_alley,
			"another plan is another region, built from that plan")
	t.check(streets.siting_region() == changed, "itself handed again")

	streets.replace_region_plan(walled)
	var again := streets.siting_region()
	t.check(again != first and again != changed and again.centres == first.centres,
			"the first plan handed over again is built afresh from it")
	streets.begin_day(null, walled, no_closures)
	t.check(streets.siting_region() == again,
			"and a dawn that hands over the same plan keeps the region built for it")

	streets.begin_day(null, null, no_closures)
	t.check(streets.siting_region() == null, "a day with no plan gives a siting no region")
