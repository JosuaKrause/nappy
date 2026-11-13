class_name DawnRoadblockCount
extends DawnPhase
## **The roadblock count, the dawn's last phase**: how many of the day's route tiles have none of
## `def`'s rows close by as the day stands, written to the run log: once every pass is done, each
## placed `def` the day stands (not a region door's body or the wall's own) is read as close by
## every route tile its paths reach within `RuledRoadblockGround.TASK_ROW_CLOSE_BY` over the day's
## whole obstruction (`DayReach.shut_by()`), and the route tiles it leaves are counted. The
## roadblock phase (`DawnRoadblocks`) aims at none, but a route tile no section within reach took
## one for and ground the later passes shut both leave some. A count and nothing more: nothing is
## placed or moved here. Nothing on a day with no `def` (`DawnContext.roadblock_row()`), none
## written to (`DawnContext.is_traced()`) or no corridor.
##
## Model: no node.

## Overrides DawnPhase.run.
func run(context: DawnContext) -> void:
	var def := context.roadblock_row()
	var corridor := context.corridor()
	if def == null or not context.is_traced() or corridor == null:
		return
	var map := context.map()
	var events := context.events()
	var down := events.placements().duplicate()
	down.append_array(events.standing())
	var shut := DayReach.shut_by(map, down)
	var covered := {}
	for plan: EventPlan in down:
		if plan.row_id() != def.id or not plan.is_placed() or plan.is_door() \
				or plan.is_in_the_wall():
			continue
		for reached: Vector2i in RuledRoadblockGround.close_by(map, shut, plan):
			covered[reached] = true
	var tiles := 0
	var left := 0
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if not corridor.carries_a_route(tile) or not map.is_walkable(tile) or shut.has(tile):
				continue
			tiles += 1
			if not covered.has(tile):
				left += 1
	context.note("plan", "%d of %d route tiles have no %s within %.0fpx along her paths as the day stands"
			% [left, tiles, def.id, RuledRoadblockGround.TASK_ROW_CLOSE_BY])
