class_name WalkDraw
extends RefCounted
## **The day's open locations drawn as she walks, each from its view's bag** (inbox #1185, the
## placeholders "get filled in with non-blocking events from the bag" "when the player walks",
## gray-dolphin #1173; `docs/EVENTS.md`, "The three views and the placement order"). The dawn fixes
## the fixed parts, the scripted rows and day 13's roadblocks and leaves every other location
## undrawn; this draws one the first time it comes near her, through the same draw the dawn used
## (`LocationDraw`: the view's bag, the day's caps, the location's own ground and the day's rules).
##
## **When a location is drawn** (the orchestrator's reading, open to the player's overturn): once its
## ground comes within `BAND_FAR` of her ahead of her, out of her view, one location a tick, nearest
## first; and any location within `MUST_DRAW` of her, out of her view, at once, however many, so no
## location reaches the stream radius undrawn, even after a sharp turn brings many near together. A
## location in her view is never drawn: an event drawn there would appear where she is looking.
## Model: no node.

## Within this of her a location out of her view is drawn at once: the stream radius and its
## hysteresis (`Tuning.EVENT_STREAM_RADIUS`, `EVENT_STREAM_HYSTERESIS`), so it is drawn before
## anything in it can stream in.
const MUST_DRAW := Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
## How far ahead of her a location is drawn, one a tick: sixteen seconds of walking beyond `MUST_DRAW`,
## the band the walk's sitings use (`EventDirector._siting_band()`).
const BAND_FAR := MUST_DRAW + Tuning.WALK_SPEED * 16.0
## The side of a bucket of the locations' index, in world pixels: one block and its street.
const BUCKET := 448.0

var _locations: DayLocations
var _draw: LocationDraw
## Bucket -> the locations whose ground touches it.
var _index := {}
## Location -> its ground in world space.
var _rects := {}

## The walk's draw over the day's `locations`, drawing through `draw`.
func _init(locations: DayLocations, draw: LocationDraw) -> void:
	_locations = locations
	_draw = draw
	for location in locations.open_locations():
		var rect := Rect2(Vector2(location.tiles().position) * Tuning.TILE_SIZE,
				Vector2(location.tiles().size) * Tuning.TILE_SIZE)
		_rects[location] = rect
		var low := (rect.position / BUCKET).floor()
		var high := (rect.end / BUCKET).floor()
		for y in range(int(low.y), int(high.y) + 1):
			for x in range(int(low.x), int(high.x) + 1):
				var key := Vector2i(x, y)
				if not _index.has(key):
					_index[key] = []
				(_index[key] as Array).append(location)

## **Draws what a tick of her walk owes**: every undrawn location within `MUST_DRAW` of `at` that
## `in_view` (a world rect -> whether she can see it) says she cannot see, nearest first, and then
## the nearest undrawn one ahead of her `heading` within `BAND_FAR`, out of her view. Answers the
## plans the draws placed, for the walk to stand.
func draw_ahead(at: Vector2, heading: Vector2, in_view: Callable) -> Array[EventScheduler.Planned]:
	var placed: Array[EventScheduler.Planned] = []
	var near := _undrawn_within(at, BAND_FAR)
	var ahead: Location = null
	for entry: Array in near:
		var location: Location = entry[1]
		if in_view.call(_rects[location]):
			continue
		if float(entry[0]) <= MUST_DRAW:
			_draw_one(location, placed)
		elif ahead == null and heading != Vector2.ZERO \
				and (_rects[location] as Rect2).get_center().direction_to(at).dot(heading) < 0.0:
			ahead = location
	if ahead:
		_draw_one(ahead, placed)
	return placed

## **Draws every undrawn location within `radius` of `at`**, nearest first, whether she can see it
## or not: what a walk starting at `at` owes before its first step, drawn while the day is set up.
func draw_within(at: Vector2, radius: float) -> Array[EventScheduler.Planned]:
	var placed: Array[EventScheduler.Planned] = []
	for entry: Array in _undrawn_within(at, radius):
		_draw_one(entry[1], placed)
	return placed

## Hands the draw the walk it now judges against (`LocationDraw.judge_against()`): from the walk's
## start, what stands is the walk's.
func judge_against(walk: WalkEvents) -> void:
	_draw.judge_against(walk)

func _draw_one(location: Location, placed: Array[EventScheduler.Planned]) -> void:
	if location.is_drawn() or location.is_taken():
		return
	var plan := _draw.draw(location)
	if plan:
		placed.append(plan)

## The undrawn, open locations whose ground is within `radius` of `at`, as `[distance, location]`,
## nearest first.
func _undrawn_within(at: Vector2, radius: float) -> Array:
	var found: Array = []
	var seen := {}
	var low := ((at - Vector2.ONE * radius) / BUCKET).floor() if is_finite(radius) else Vector2.ZERO
	var high := ((at + Vector2.ONE * radius) / BUCKET).floor() if is_finite(radius) else Vector2.ZERO
	var keys: Array = _index.keys() if not is_finite(radius) else []
	if is_finite(radius):
		for y in range(int(low.y), int(high.y) + 1):
			for x in range(int(low.x), int(high.x) + 1):
				keys.append(Vector2i(x, y))
	for key: Vector2i in keys:
		for location: Location in _index.get(key, []):
			if seen.has(location) or location.is_drawn() or location.is_taken() \
					or not location.is_available():
				continue
			seen[location] = true
			var rect: Rect2 = _rects[location]
			var distance := at.distance_to(Vector2(clampf(at.x, rect.position.x, rect.end.x),
					clampf(at.y, rect.position.y, rect.end.y)))
			if distance <= radius:
				found.append([distance, location])
	found.sort_custom(func(a: Array, b: Array) -> bool:
		return a[0] < b[0] if a[0] != b[0] else (a[1] as Location).centre() < (b[1] as Location).centre())
	return found
