class_name GamePlanBuilder
extends RefCounted
## The plan builder the game makes, for a suite or a probe that builds plans the way a day does: a
## `PlanBuilder` over the map, handed the three questions the game hands it (what stops a moving
## row, where a body stands, the room among placed plans). A helper, not a suite.

## The game's builder over `map`.
static func over(map: CityMap) -> PlanBuilder:
	return PlanBuilder.new(map, EventInstance.mover_for, EventFootprints.stands_at,
			StreetInvalidation.room_around)
