class_name DawnTutorial
extends DawnPhase
## **Day 1's lessons, stood on the tutorial route at dawn** (`TutorialRoute`, handed in on the day
## whose spec walks it, `DawnContext.tutorial_route()`): the market stall on the sidewalk across from
## the line for (2), a noise she can pass wide; the delivery van shutting the line's sidewalk just
## past the box where the line crosses for (4); the yeller pacing the line's sidewalk for (6), the
## street before the park's. (3)'s dog walker is sent toward her by the director, never placed
## (`EventDirector`), and (5) is the crossing where the cars start, the far end of (4)'s street,
## where the line crosses a carriageway again (`TutorialRoute`).
## Every other location of the route's units past the first block, its lesson streets and their
## junction boxes, is drawn empty, so nothing else stands between the lessons, and every unit off
## the route draws from its view's bag as on any other day. *(gentle-owl #1253: on day 1 the
## obstacles on the way to the park are placed at dawn, authored to teach one lesson after another,
## and placement off the route happens normally.)*
##
## **Placed outside the bags, and that is the exception made honestly**, as `DawnLesson` makes it
## for the run: everywhere else at dawn the density is the bags', and a lesson that comes only when
## the draw agrees is not a lesson. One day of fourteen, and only on its route.
##
## **Each row is offered through the dawn's own path and judged by the day's rules**
## (`RuledLocationGround.offer_on()`, `StreetInvalidation`), on the row's own ground for the day
## (`RowGround.offers_for()`) along its slot, the tiles in the slot's order: a row no tile of its
## slot takes is not placed and the run log says so, which is the right failure direction. Nothing
## is drawn on a stream, so a retried day 1 replays the same lessons. *Proposed, not asked for:* the
## route's other locations left empty is the orchestrator's reading (gentle-owl #1253), open to the
## player's correction. Model: no node.

## The row that teaches (2), a noise source she can pass wide, on the far sidewalk: free on the
## line and a loud wall on its own sidewalk. A row whose cost reaches across the carriageway (the
## leaf blower's, 165px) would take her line, which the day's rules refuse on a route
## (`RouteLineRule`); the stall's reaches 58px. *Proposed, not asked for* (gentle-owl #1253, the
## orchestrator's sketch).
const NOISE_PASSED_WIDE := "market_stall"
## The row that shuts the line's sidewalk for (4), so she crosses with no cars about.
const SHUTS_HER_SIDEWALK := "delivery_van"
## The row whose beat she times for (6).
const PACES_HER_SIDEWALK := "homeless_yeller"

## Overrides DawnPhase.run.
func run(context: DawnContext) -> void:
	var route := context.tutorial_route()
	if route == null:
		return
	var day := context.day()
	var map := context.map()
	var events := context.events()
	var ground := context.ground()
	var locations := context.locations()
	var judged := RuledLocationGround.new(day, context.day_seed(), map, events.standing(),
			context.corridor(), LocationFit.new(day, map, context.builder(), ground),
			context.rules(), ground, true, true)
	var slots := _lesson_slots(route)
	for row_id: String in slots:
		var def := EventCatalogue.heated(EventCatalogue.by_id(row_id), context.heat()).for_day(day)
		var plan := _stand(def, slots[row_id], map, ground, locations, judged, events)
		context.note("plan", "day %d's tutorial: %s %s" % [day, row_id,
				("at " + RunTrace.tile(map.world_to_tile(plan.placed_at()))) if plan
				else "has no tile of its slot the day's rules allow"])
	var units := _route_units(route)
	for location in locations.open_locations():
		if units.has(location.part_of()):
			locations.record(location, null)

## **Each lesson's row with the tiles of its slot, in the order they are offered**: the market stall
## along the far sidewalk of (2)'s street from its middle out, the van along the far sidewalk of
## (4)'s street from the box where the line crosses it, and the yeller along the line's sidewalk of
## (6)'s street from the end she arrives at, away from the park. A lesson the route is too short
## for has none.
static func _lesson_slots(route: TutorialRoute) -> Dictionary:
	var slots := {}
	var wide := route.lesson_street(TutorialRoute.Lesson.NOISE_PASSED_WIDE)
	if wide:
		var band := route.far_sidewalk(wide)
		slots[NOISE_PASSED_WIDE] = _ordered(band, Vector2(band.get_center()))
	var shut := route.lesson_street(TutorialRoute.Lesson.CROSSING_WITH_NO_CARS)
	if shut:
		slots[SHUTS_HER_SIDEWALK] = _ordered(route.far_sidewalk(shut),
				_box_centre(route.crossing_with_no_cars()))
	var paced := route.lesson_street(TutorialRoute.Lesson.TIMING_THE_YELLER)
	if paced:
		slots[PACES_HER_SIDEWALK] = _ordered(route.line_sidewalk(paced),
				_box_centre(route.arrives_at(paced)))
	return slots

## **The rects of the units the route runs through past the first block**, as `Location.part_of()`
## names them, as a set: each lesson street's, and each junction box along the route.
static func _route_units(route: TutorialRoute) -> Dictionary:
	var units := {}
	for segment in route.lesson_streets():
		units[segment.tile_rect()] = true
		for junction: Vector2i in [segment.a, segment.b]:
			units[Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)] = true
	return units

## Stands `def` on the first tile of `tiles` that is its ground for the day and that the day's
## rules allow, assigned to the location holding it; answers the plan, or null where none is.
static func _stand(def: EventDef, tiles: Array[Vector2i], map: CityMap, ground: RowGround,
		locations: DayLocations, judged: RuledLocationGround, events: DayEvents) -> EventPlan:
	var own := ground.offers_for(def)
	for tile in tiles:
		if not own.has(tile):
			continue
		var location := locations.holding(tile, map.tile_at(tile))
		if location == null or not location.is_open():
			continue
		var one: Array[Vector2i] = [tile]
		var plan := judged.offer_on(def, location, one, events.placements())
		if plan:
			locations.assign_to(location, plan)
			events.add(plan)
			return plan
	return null

## The tiles of `band`, nearest `from` first.
static func _ordered(band: Rect2i, from: Vector2) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for y in range(band.position.y, band.end.y):
		for x in range(band.position.x, band.end.x):
			tiles.append(Vector2i(x, y))
	tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := (Vector2(a) - from).length_squared()
		var db := (Vector2(b) - from).length_squared()
		return da < db or (da == db and (a.y < b.y or (a.y == b.y and a.x < b.x))))
	return tiles

## The centre of `junction`'s box, in tiles.
static func _box_centre(junction: Vector2i) -> Vector2:
	return Vector2(junction * CityMap.period()) + Vector2.ONE * (Tuning.STREET_WIDTH * 0.5)

