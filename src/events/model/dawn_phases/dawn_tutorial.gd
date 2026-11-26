class_name DawnTutorial
extends DawnPhase
## **Day 1's lessons, stood on the tutorial route at dawn** (`TutorialRoute`, handed in on the day
## whose spec walks it, `DawnContext.tutorial_route()`): the market stall on the sidewalk across from
## the line for (2), a noise she can pass wide; the delivery van shutting the line's sidewalk just
## past the box where the line crosses for (4); the yeller pacing the line's sidewalk for (6), the
## street before the park's, on its half away from (5)'s junction. (3)'s dog walker is sent toward her by the director, never placed
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

## **Where a lesson's row may stand**: the tiles it is offered, in the order they are offered, and
## the ground a route along the street may walk (`within`; no area for the location's whole run).
class Slot:
	var _tiles: Array[Vector2i]
	var _within: Rect2i

	func _init(tiles: Array[Vector2i], within := Rect2i()) -> void:
		_tiles = tiles
		_within = within

	func tiles() -> Array[Vector2i]:
		return _tiles

	func within() -> Rect2i:
		return _within

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
		var plan := _stand(def, slots[row_id] as Slot, map, ground, locations, judged, events)
		context.note("plan", "day %d's tutorial: %s %s" % [day, row_id,
				("at " + RunTrace.tile(map.world_to_tile(plan.placed_at()))) if plan
				else "has no tile of its slot the day's rules allow"])
	var units := {}
	for unit in route.units_past_the_first_block():
		units[unit] = true
	for location in locations.open_locations():
		if units.has(location.part_of()):
			locations.record(location, null)

## **Each lesson's row with its slot** (`Slot`): the market stall along the far sidewalk of (2)'s
## street from its middle out, the van along the far sidewalk of (4)'s street from the box where the
## line crosses it, and the yeller along the line's sidewalk of (6)'s street past
## `YELLER_CLEAR_OF_THE_CROSSING` tiles from the junction she arrives at, from there on toward the
## park, his beat held to that stretch and the far junction's box. A lesson the route is too short
## for has none.
##
## **The yeller's beat never reaches the junction she comes onto his street at**, by construction:
## that is lesson (5)'s, the crossing with cars, and the player made him a lesson of his own after it
## *(gentle-owl #1253)*. His beat leaves her no line along the sidewalk, so the day's rules take it
## only where it reaches a crossing or a side route (`StreetInvalidation`, a pacing beat that walls
## a sidewalk); off (5)'s box that is the far junction's, toward the park's street, where his field
## mostly reaches the park she has not used (`UnusedCalmRule`), so on most seeds he stands nowhere.
## The record grassy-beaver-golden-puffin counts it. *Proposed, not asked for:* the clear stretch's
## length, the builder's, open to the player's correction.
static func _lesson_slots(route: TutorialRoute) -> Dictionary:
	var slots := {}
	var wide := route.lesson_street(TutorialRoute.Lesson.NOISE_PASSED_WIDE)
	if wide:
		var band := route.far_sidewalk(wide)
		slots[NOISE_PASSED_WIDE] = Slot.new(_ordered(band, Vector2(band.get_center())))
	var shut := route.lesson_street(TutorialRoute.Lesson.CROSSING_WITH_NO_CARS)
	if shut:
		slots[SHUTS_HER_SIDEWALK] = Slot.new(_ordered(route.far_sidewalk(shut),
				_box_centre(route.crossing_with_no_cars())))
	var paced := route.lesson_street(TutorialRoute.Lesson.TIMING_THE_YELLER)
	if paced:
		var band := route.line_sidewalk(paced)
		var from := _box_centre(route.arrives_at(paced))
		var clear := YELLER_CLEAR_OF_THE_CROSSING
		slots[PACES_HER_SIDEWALK] = Slot.new(_ordered(_clear_of(band, from, clear), from),
				_clear_of(paced.run_rect(), from, Tuning.STREET_WIDTH + clear))
	return slots

## **How many tiles of his street's sidewalk the yeller's beat keeps clear of the junction box she
## comes onto it at**, lesson (5)'s: half the street.
const YELLER_CLEAR_OF_THE_CROSSING := 4

## `band`, a sidewalk, along its street, less its `clear` tiles at the end nearer `from`.
static func _clear_of(band: Rect2i, from: Vector2, clear: int) -> Rect2i:
	var kept := band
	var middle := _middle_of(band)
	if band.size.x >= band.size.y:
		kept.size.x = band.size.x - clear
		if from.x < middle.x:
			kept.position.x = band.position.x + clear
	else:
		kept.size.y = band.size.y - clear
		if from.y < middle.y:
			kept.position.y = band.position.y + clear
	return kept

## The middle of `band`, in tiles.
static func _middle_of(band: Rect2i) -> Vector2:
	return Vector2(band.position) + Vector2(band.size) * 0.5

## Stands `def` on the first tile of `slot` that is its ground for the day and that the day's
## rules allow, its route held to the slot's ground, assigned to the location holding it; answers
## the plan, or null where none is.
static func _stand(def: EventDef, slot: Slot, map: CityMap, ground: RowGround,
		locations: DayLocations, judged: RuledLocationGround, events: DayEvents) -> EventPlan:
	var own := ground.offers_for(def)
	for tile in slot.tiles():
		if not own.has(tile):
			continue
		var location := locations.holding(tile, map.tile_at(tile))
		if location == null or not location.is_open():
			continue
		var one: Array[Vector2i] = [tile]
		var plan := judged.offer_within(def, location, one, events.placements(), slot.within())
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

