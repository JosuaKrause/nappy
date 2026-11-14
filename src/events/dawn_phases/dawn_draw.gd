class_name DawnDraw
extends DawnPhase
## **The dawn draw**: every open location of the day drawn from its view's bag (`LocationDraw`,
## inbox #1185 in gentle-owl): the bags (made from `EventScheduler.view_fills()`) hold every
## recurring row the catalogue places on the map today, each as many times as its weight in the view
## (`EventScheduler.view_weight()`), and the empty event; the day's ground answers which row is
## valid where and how much each location weighs it (`RuledLocationGround`). The rows
## other phases place have no marble: the moments she is owed (`DawnMoments`), and on the day
## of the roadblock phase its row (`DawnContext.roadblock_row()`), the phase's alone. The draw
## places into the context's plan.
##
## Model: no node.

## The phase salt a share of a wall's cap is rounded on (`_caps_of()`).
const CAPS_SALT := 8

## Overrides DawnPhase.run.
func run(context: DawnContext) -> void:
	var day := context.day()
	var spec := context.spec()
	var base := context.day_seed()
	var map := context.map()
	var beside_the_routes := context.roadblock_row()
	var rows := {}
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day, context.heat()):
		if def.spawn_mode_on(day) != EventDef.SpawnMode.MAP:
			continue
		if beside_the_routes != null and def.id == beside_the_routes.id:
			continue
		rows[def.id] = def.for_day(day)
	var fills := EventScheduler.view_fills(rows, day, spec)
	var bags := {}
	for view: int in fills:
		bags[view] = ViewBag.new(fills[view], EventScheduler.view_bag_seed(base, view))
	var events := context.events()
	var judged := RuledLocationGround.new(day, base, map, events.standing(), context.corridor(),
			LocationFit.new(day, map, context.builder(), context.ground()), context.rules(),
			context.ground())
	var caps := _caps_of(rows, day, spec, context.stream(CAPS_SALT)) if spec.caps_per_day else {}
	events.add_all(LocationDraw.new(context.locations(), bags, rows, judged, caps).draw_all(
			context.stream(EventScheduler.LOCATIONS_SALT), events.placements()))

## **How many of each row the day's draw may stand** (`id -> count`): its `EventDef.max_per_day`,
## and a wall-role row's times `DaySpec.wall_row_share`, so the gatehouse day holds that share of a
## wall whose cap binds as well as of one whose weight does (`EventScheduler.view_weight()`
## scales the weight). A
## share of a cap that is not whole is rounded up or down on `rng`, by its fraction, so the day
## holds the share on average.
static func _caps_of(rows: Dictionary, day: int, spec: DaySpec,
		rng: RandomNumberGenerator) -> Dictionary:
	var caps := {}
	var ids := rows.keys()
	ids.sort()
	for id: String in ids:
		var def: EventDef = rows[id]
		var most := float(def.most_in_a_day())
		if EventScheduler.role_for(def, day) == GameEnums.BlockerRole.WALL:
			most *= spec.wall_row_share
		caps[id] = floori(most) + (1 if rng.randf() < most - floorf(most) else 0)
	return caps
