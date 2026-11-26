class_name RigStreets
extends RefCounted
## **Today's streets for a rig that starts the event manager's day with no dawn before it.** The
## manager plans a day against the streets it was handed (`EventManager.setup()`,
## `DayStreets`), which in the game the city's dawn begins (`City.start_day()`). A rig that calls
## `EventManager.start_day()` on its own begins them here first: on a built city the city's own
## (`City.streets()`), and with no city a `DayStreets.new()` it handed the manager.

## **Begins `spec`'s day on `streets` as dawn grows it with no street closed**: the day's route tree
## (`RouteTree.for_day()`), the region wall and doors grown from that tree
## (`RegionPlanner.plan_day()`) and no closures.
static func begin(streets: DayStreets, map: CityMap, spec: DaySpec) -> void:
	# A rig that starts a day without its dawn is not about the tutorial route: day 1 here
	# grows the ordinary tree, deliberately (test_seals holds the tutorial's).
	var tree := RouteTree.for_day(map, spec.day_number(), null)
	streets.begin_day(tree, RegionPlanner.plan_day(EventCatalogue.shipped(), map, spec, tree), [] as Array[RoadClosure])
