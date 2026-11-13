class_name DawnRoadblocks
extends DawnPhase
## **The roadblock phase at dawn** (inbox #1185 in gentle-owl: the day's routes first, then
## roadblocks next to them, then the ordinary placement): day 13's roadblocks, placed by
## `RoadblockPhase` in the day's route-adjacent sections, spread by a bias toward the section
## farthest from those already placed, until every route tile has one close by, no section still
## offered could bring one close by a route tile that has none, or `RoadblockPhase.MOST` stand
## (the orchestrator's reading, open to correction). The task's row is
## `DawnContext.roadblock_row()`, null on every other day, which this leaves exactly as it was.
##
## **The phase places into the day's locations** (`DawnContext.locations()`, laid out off the
## walk's corridor every day), before the dawn draw fills the rest
## (`EventScheduler._draw_the_locations()`).
##
## **What a section is offered, and what close by is, are the day's**: `RuledRoadblockGround`
## stands the roadblock where it fits in the section and asks today's placement rules of it
## (`StreetInvalidation`), never on the main road (inbox #1186 in gentle-owl); close by is the
## walk her paths take from the ground she touches it from without leaving the circle of
## `RuledRoadblockGround.TASK_ROW_CLOSE_BY` round it (`DayReach.paths_over()`), the widest the
## task searches (`ResistanceDirector.ROADBLOCK_WIDER_REACH`).
##
## **What it does not promise.** Close by is measured over the ground as it stands when this
## runs: the scripted rows, the one-shots, the spoilers and the dawn draw after it shut more.
## `EventScheduler._count_what_is_left_uncovered()` writes to the run log how many route tiles
## have none as the day finally stands.
##
## **Outside the bags and on a stream of its own** (`RoadblockPhase.SALT`): the dawn draw after
## it draws the day's other rows, the roadblock holding no marble in it, spaced against these as
## against anything already down, and never over one.
##
## Model: no node.

## Overrides DawnPhase.run.
func run(context: DawnContext) -> void:
	var def := context.roadblock_row()
	if def == null:
		return
	var day := context.day()
	var map := context.map()
	def = def.for_day(day)
	var judged := RuledRoadblockGround.new(def, day, map, context.builder(), context.events(),
			context.ground(), context.corridor(), context.rules())
	var phase := RoadblockPhase.new(context.locations(), judged)
	var placed: Array[String] = []
	for plan in phase.place(context.stream(RoadblockPhase.SALT)):
		placed.append(RunTrace.tile(map.world_to_tile(plan.placed_at())))
	context.note("plan", ("%d %s placed beside the day's routes, at %s; %d route tiles left with " +
			"none close by, the phase done")
			% [placed.size(), def.id, " ".join(placed) if not placed.is_empty() else "none",
			phase.left_uncovered()])
