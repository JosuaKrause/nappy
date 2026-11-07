class_name DayStreets
extends RefCounted
## **Today's streets as dawn left them**: the day's route tree, its region wall and doors, the
## streets it closed, and the region a siting reads off the wall. Grown once at dawn and handed to
## whoever asks, so nothing grows them a second time.
##
## *(inbox #1156: "have an object that contains the derived information -- don't rederive over and
## over again -- then pass that object around".)* `City` makes one with itself and is its only
## writer: `begin_day()` from `City._close_streets()` and `City.start_recipe_day()`, and
## `replace_region_plan()` for a rig or a scene recipe that authors the day's wall and doors. Every
## reader asks `city.streets`, and the city's own dawn reads it too.
##
## **A day whose spec closes no streets does not begin a day here**, so every answer stays what the
## last day that did left. The escape's city is a city of its own that never begins one, so there
## `route_tree()` and `region_plan()` answer null and `closures()` is empty.
##
## **It derives nothing but the siting's region**, so a test builds one with `DayStreets.new()` and
## `begin_day()` with what its case needs, a null tree included, and no city.

## Today's corridor: the ways from the doorstep to the calm areas still worth reaching, grown
## before anything is placed. Everything the day sites is sited against **this** tree — the
## closures as walls off it, the events by role, the telemetry picture that says whether any of
## it points anywhere — so it is grown once at dawn rather than three times from the same seed.
var _tree: RouteTree = null
## Today's region wall and doors, grown from `_tree` — permanent partition, per-day split. See
## `RegionPlanner.plan_day` and `region_plan()`.
var _region_plan: RegionPlanner.RegionPlan = null
## The region a siting reads (`siting_region()`) and what it was built from, to hand it again while
## the plan is unchanged.
var _sited_region: SpawnSiting.Region = null
var _sited_from: RegionPlanner.RegionPlan = null
## Today's closed streets. The barriers and wreckage that say so are the city's.
var _closures: Array[RoadClosure] = []

# ------------------------------------------------------------------- writes ---

## Today's streets, as dawn grew them: the tree, the region plan grown from it and the closures
## placed off both. The plan is not edited once handed over (`siting_region()`).
func begin_day(tree: RouteTree, plan: RegionPlanner.RegionPlan,
		closures: Array[RoadClosure]) -> void:
	_tree = tree
	_region_plan = plan
	_closures = closures

## Replaces today's region plan with another one (a rig that authors the day's wall and doors). The
## plan handed over is today's from then on and is not edited: the siting's region is built from
## it once (`siting_region()`).
func replace_region_plan(plan: RegionPlanner.RegionPlan) -> void:
	_region_plan = plan

# ---------------------------------------------------------------- questions ---

## Today's corridor. Grown at dawn, so it is null before the first day that closes streets.
func route_tree() -> RouteTree:
	return _tree

## Today's region wall and doors. Grown at dawn from `route_tree()`, so it is null until then — the
## same contract as `route_tree()`.
func region_plan() -> RegionPlanner.RegionPlan:
	return _region_plan

## Today's closed streets; empty until a day closes some.
func closures() -> Array[RoadClosure]:
	return _closures

## Today's region as a siting reads it (`SpawnSiting.Region`): the crossing alleys the wall closes,
## and each body of the wall and of the district doors as a disc, its centre and its
## `obstructs_radius`; null before a day has grown a region plan.
##
## **Built once for the plan and handed again until the plan is another plan**: the resistance asks
## for it for every candidate tile of a relocation (`ResistanceDirector._nearest_alley_within()`,
## "cheap enough for every frame"), and a hundred-odd discs rebuilt on each ask were most of that
## cost. A plan is never edited once handed over; whoever changes a day's wall, doors or alleys
## builds another plan and hands it over (`begin_day()` or `replace_region_plan()`).
func siting_region() -> SpawnSiting.Region:
	if not _region_plan:
		_sited_region = null
		_sited_from = null
		return null
	if _sited_region != null and _sited_from == _region_plan:
		return _sited_region
	var region := SpawnSiting.Region.new()
	region.walled_alleys = _region_plan.alley_walls
	for body: EventScheduler.Planned in _region_plan.wall_bodies + _region_plan.door_bodies:
		region.centres.append(body.position)
		region.radii.append(body.def.obstructs_radius)
	_sited_region = region
	_sited_from = _region_plan
	return region
