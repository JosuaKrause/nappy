class_name PutOnHerRoute
extends RefCounted
## **Reads the run log for a place put on her route**, for a suite that holds the director's
## walk: `EventsAhead` writes "<row> is put on her route <n>px ahead of her at <tile>, ..." the
## moment a place a marble from her route's bag named is first sited, the one moment the
## director turns it into a place from her route. A helper, not a suite: the runner loads only
## `test_*.gd`. `told` is the list a `RecordingTrace` handed to the events' surroundings
## (`EventSurroundings.tracing_to()`) keeps.

## Whether `told` says `plan` was put on her route: its row's line at the tile it stands on.
static func says(told: Array[String], map: CityMap, plan: EventPlan) -> bool:
	var opening := "ahead %s is put on her route " % plan.row_id()
	var at := " ahead of her at %s, " % RunTrace.tile(map.world_to_tile(plan.placed_at()))
	for line in told:
		if line.begins_with(opening) and line.contains(at):
			return true
	return false
