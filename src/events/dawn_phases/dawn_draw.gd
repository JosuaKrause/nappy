class_name DawnDraw
extends DawnPhase
## **The dawn draw**: every open location of the day drawn, a unit at a time (inbox #1185 in
## gentle-owl; `UnitDraw`, `MarbleDraw`): each unit (a street, a junction box, an alley, a park
## or a square; `DayUnits`) draws in one go, on its own stream, from one fresh bag of the fill of
## its view, the most permissive of its locations' (`PlacementUnit.view()`), and its kind of ground
## (`UnitFills`: every recurring row the catalogue places on the map today, the declared table's
## events per hundred draw locations among them by weight, and the empty event for the rest of the
## bag), each marble drawn before it has a place and its rows laid out in the unit (inbox #1466 in silky-lemur),
## at most one of a row in a unit, after every touching unit of lower rank. The day's ground answers which row is valid where and how much each location weighs it
## (`RuledLocationGround`), judged among the dawn's plans and the draws of the units touching the
## one drawing, on the first tile no rule refuses, a route kept on its location's run
## (`Location.run()`). The rows other
## phases place have no marble: the moments she is owed (`DawnMoments`), and on the day of the
## roadblock phase its row (`DawnContext.roadblock_row()`), the phase's alone.
##
## **It prepares the draw, holds it in the context** (`DawnContext.hold_the_draw()`) **and draws
## nothing**, on a day: the draw travels with the walk (`DayPlanner.Plan.unit_draw()`,
## `WalkEvents.unit_draw()`), and each unit draws as she comes near it
## (`EventsAhead.draw_what_comes_near()`), the same whatever order the units are drawn in, and so
## whatever her path: what drawing every unit at dawn in rank order would give. **A walk whose spec
## draws every unit before she sets off** (`DaySpec.draws_before_she_sets_off()`) **is drawn here,
## whole**, in its units' order (`UnitDraw.draw_in_their_order()`), each street judged among
## everything drawn before it, its routes uncut, since every draw sees every draw before it. Which
## bag the units draw from is the spec's too: one for the whole walk where it holds one
## (`DaySpec.walk_bag()`, `WholeWalkBag`), else a day's fresh bag a unit (`UnitFills`).
##
## Model: no node.

## **Whether a drawn row's route stays on its location's run** (`RuledLocationGround`'s
## `keeps_routes_on_the_run`, `Location.run()`): a route that would leave its street's run is cut
## at the far edge of the boxes at its ends (inbox #1460 in silky-lemur), and this is the one setting that holds
## it. The rows a unit draws that move are a pacing beat (the man shouting and the chatting mother,
## 8 tiles from their tile, which from a tile near a street's end runs through the box and on past
## it, and is cut) and the alley mouse; the long routes, the dog walker's, the
## patrol's and the convoy's, are the director's, which sends those rows ahead of her
## (`EventDef.is_sent_ahead()`) and draws none of them by a unit. It holds on a walk whose units
## draw as she comes near them; a walk drawn whole keeps its routes uncut.
const ROUTES_STAY_ON_THE_RUN := true

## Overrides DawnPhase.run.
func run(context: DawnContext) -> void:
	var spec := context.spec()
	var day := context.day()
	var map := context.map()
	var ground := context.ground()
	var whole := spec.draws_before_she_sets_off()
	var rows := _rows_of(context)
	var units := DayUnits.of(context.locations().all(), context.day_seed())
	var events := context.events()
	var judged := RuledLocationGround.new(day, context.day_seed(), map, events.standing(),
			context.corridor(),
			LocationFit.new(day, map, context.builder().without_todays_bodies(), ground,
					context.ground_she_starts_on()),
			context.rules(), ground, false, ROUTES_STAY_ON_THE_RUN and not whole)
	var draw := UnitDraw.new(units,
			MarbleDraw.new(context.locations(), rows, judged, spec.stands_one_event_a_street()),
			_bags_of(context, rows), events.placements())
	context.hold_the_draw(draw)
	if whole:
		var placed := draw.draw_in_their_order()
		events.add_all(placed)
		context.note("plan", "every unit drawn before she sets off: %d units, %d rows"
				% [units.all().size(), placed.size()])

## **The rows the bags' marbles name** (`id -> EventDef`): the walk bag's own where the walk has
## one (`DaySpec.walk_bag_rows()`), else every recurring row the catalogue places on the map today
## that a unit draws (`EventDef.is_drawn_by_units()`), as the day gives it.
static func _rows_of(context: DawnContext) -> Dictionary:
	var spec := context.spec()
	if not spec.walk_bag().is_empty():
		return spec.walk_bag_rows()
	var day := context.day()
	var beside_the_routes := context.roadblock_row()
	var beside_id := beside_the_routes.id if beside_the_routes != null else ""
	var rows := {}
	for def in context.catalogue_rows(GameEnums.EventKind.RECURRING):
		if def.is_drawn_by_units(day, beside_id):
			rows[def.id] = def.for_day(day)
	return rows

## **What answers a unit's bag** (`UnitBags`): one bag for the whole walk where the spec holds one
## (`DaySpec.walk_bag()`), on a stream of its own off the day's seed; else the day's fills, a fresh
## bag a unit (`UnitFills`).
static func _bags_of(context: DawnContext, rows: Dictionary) -> UnitBags:
	var spec := context.spec()
	var bag := spec.walk_bag()
	if not bag.is_empty():
		return WholeWalkBag.new(bag, hash("%d:walk-bag" % context.day_seed()))
	var ground := context.ground()
	return UnitFills.new(rows, context.day(), spec.share_of_walls_drawn(), ground.weights(),
			ground.is_a_wall_by_cost)
