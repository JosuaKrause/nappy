class_name DawnDraw
extends DawnPhase
## **The dawn draw**: every open location of the day drawn from its view's bag, a unit at a time
## (inbox #1185 in gentle-owl; `UnitDraw`, `LocationDraw`): each unit (a street, a junction box, an
## alley, a park or a square; `DayUnits`) draws its locations in one go, on its own stream, from a
## fresh bag per view of the view's fill (`EventScheduler.view_fills()`: every recurring row the
## catalogue places on the map today, each as many times as its weight in the view, and the empty
## event), at most one of a row in a unit, after every touching unit of lower rank. The day's ground
## answers which row is valid where and how much each location weighs it (`RuledLocationGround`),
## judged among the dawn's plans and the draws of the units touching the one drawing, on the first
## tile no rule refuses, a route kept on its location's run (`Location.run()`). The rows other
## phases place have no marble: the moments she is owed (`DawnMoments`), and on the day of the
## roadblock phase its row (`DawnContext.roadblock_row()`), the phase's alone.
##
## **It prepares the draw and holds it in the context** (`DawnContext.hold_the_draw()`), then draws
## every unit into the day's plan, so the day is whole at dawn: what drawing every unit at dawn in
## rank order gives, whatever order the units are asked for in.
##
## Model: no node.

## **Whether a drawn row's route stays on its location's run** (`RuledLocationGround`'s
## `keeps_routes_on_the_run`, `Location.run()`): a route longer than its street is cut to the
## street and the boxes at its ends, the player's answer (inbox #1460), and this is the one setting
## that answer lives in.
const ROUTES_STAY_ON_THE_RUN := true

## Overrides DawnPhase.run.
func run(context: DawnContext) -> void:
	var day := context.day()
	var map := context.map()
	var beside_the_routes := context.roadblock_row()
	var rows := {}
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day, context.heat()):
		if def.spawn_mode_on(day) != EventDef.SpawnMode.MAP:
			continue
		if beside_the_routes != null and def.id == beside_the_routes.id:
			continue
		rows[def.id] = def.for_day(day)
	var fills := EventScheduler.view_fills(rows, day, context.spec())
	var units := DayUnits.of(context.locations().all(), context.day_seed())
	var ground := context.ground()
	var events := context.events()
	var judged := RuledLocationGround.new(day, context.day_seed(), map, events.standing(),
			context.corridor(),
			LocationFit.new(day, map, context.builder().without_todays_bodies(), ground),
			context.rules(), ground, false, ROUTES_STAY_ON_THE_RUN)
	context.hold_the_draw(UnitDraw.new(units,
			LocationDraw.new(context.locations(), rows, judged), fills, events.placements()))
	var draw := context.unit_draw()
	for unit in draw.units().undrawn_within(Vector2.ZERO, INF):
		events.add_all(draw.draw(unit))
