class_name DawnDraw
extends DawnPhase
## **The dawn draw**: every open location of the day drawn, a unit at a time (inbox #1185 in
## gentle-owl; `UnitDraw`, `MarbleDraw`): each unit (a street, a junction box, an alley, a park
## or a square; `DayUnits`) draws in one go, on its own stream, from one fresh bag of the fill of
## its view, the most permissive of its locations' (`PlacementUnit.view()`;
## `EventScheduler.view_fills()`: every recurring row the catalogue places on the map today, each as many times as
## its weight in the view, and the empty event), each marble drawn before it has a place and its rows laid out
## in the unit (inbox #1466), at most one of a row in a unit, after every touching unit of lower
## rank. The day's ground answers which row is valid where and how much each location weighs it
## (`RuledLocationGround`), judged among the dawn's plans and the draws of the units touching the
## one drawing, on the first tile no rule refuses, a route kept on its location's run
## (`Location.run()`). The rows other
## phases place have no marble: the moments she is owed (`DawnMoments`), and on the day of the
## roadblock phase its row (`DawnContext.roadblock_row()`), the phase's alone.
##
## **It prepares the draw, holds it in the context** (`DawnContext.hold_the_draw()`) **and draws
## nothing**: the draw travels with the walk (`DayPlanner.Plan.unit_draw()`,
## `WalkEvents.unit_draw()`), and each unit draws as she comes near it
## (`EventsAhead.draw_what_comes_near()`), the same whatever order the units are drawn in, and so
## whatever her path: what drawing every unit at dawn in rank order would give.
##
## Model: no node.

## **Whether a drawn row's route stays on its location's run** (`RuledLocationGround`'s
## `keeps_routes_on_the_run`, `Location.run()`): a route longer than its street would be cut to
## the street and the boxes at its ends (inbox #1460), and this is the one setting that holds it.
## The rows a unit draws that move are a pacing beat (the man shouting and the chatting mother,
## 8 tiles from a tile mid-street) and the alley mouse; the long routes, the dog walker's, the
## patrol's and the convoy's, are the director's, which sends those rows ahead of her
## (`EventDef.is_sent_ahead()`) and draws none of them by a unit.
const ROUTES_STAY_ON_THE_RUN := true

## Overrides DawnPhase.run.
func run(context: DawnContext) -> void:
	var day := context.day()
	var map := context.map()
	var beside_the_routes := context.roadblock_row()
	var beside_id := beside_the_routes.id if beside_the_routes != null else ""
	var rows := {}
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day, context.heat()):
		if not def.is_drawn_by_units(day, beside_id):
			continue
		rows[def.id] = def.for_day(day)
	var fills := UnitFills.new(rows, day, context.spec())
	var units := DayUnits.of(context.locations().all(), context.day_seed())
	var ground := context.ground()
	var events := context.events()
	var judged := RuledLocationGround.new(day, context.day_seed(), map, events.standing(),
			context.corridor(),
			LocationFit.new(day, map, context.builder().without_todays_bodies(), ground),
			context.rules(), ground, false, ROUTES_STAY_ON_THE_RUN)
	context.hold_the_draw(UnitDraw.new(units,
			MarbleDraw.new(context.locations(), rows, judged), fills, events.placements()))
