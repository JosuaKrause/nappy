class_name WalkDraw
extends RefCounted
## **The day's open locations drawn as she walks, each from its view's bag** (inbox #1185 in gentle-owl, the
## placeholders "get filled in with non-blocking events from the bag" "when the player walks",
## gray-dolphin #1173; `docs/EVENTS.md`, "The three views and the placement order"). The dawn fixes
## the fixed parts, the scripted rows, day 13's roadblocks and every row that blocks the way, and
## leaves every other location undrawn; this draws one the first time it comes near her, only among
## the rows that block nothing (`LocationDraw`: the view's bag, the caps spread over the walk, the
## location's own ground and the day's rules but the reach, which nothing it draws can need).
##
## **When a location is drawn** (the orchestrator's reading, open to the player's overturn): the
## nearest out of her view whose ground has come within `BAND_FAR` of her, those ahead of her heading
## first, is drawn a step a tick (`LocationDraw.begin()`, `Asking.step()`: a marble from the bag or
## one tile of a row's offer), so no tick pays for more than one candidate of the band's draws; and
## any out of her view within `MUST_DRAW` is drawn whole on the tick it gets there, however many and
## whatever it costs, so no location reaches the stream radius undrawn, even after a sharp turn
## brings many near together (`forced()` counts those draws). A location part-way drawn holds
## nothing until its draw ends, so nothing of it can stream in. A location in her view is never
## drawn: an event drawn there would appear where she is looking. A sidewalk is drawn after its
## section (`DayLocations.drawn_before()`), since an event that takes the section takes the
## sidewalk too. Model: no node.

## Within this of her a location out of her view is drawn at once: the stream radius
## (`Tuning.EVENT_STREAM_RADIUS`) and a second of walking, so it is drawn before anything in it can
## stream in.
const MUST_DRAW := Tuning.EVENT_STREAM_RADIUS + Tuning.WALK_SPEED
## How far from her a location is drawn, a step a tick: the stream radius, its hysteresis
## (`Tuning.EVENT_STREAM_HYSTERESIS`) and two seconds of walking beyond.
const BAND_FAR := Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS + Tuning.WALK_SPEED * 2.0
## The side of a bucket of the locations' index, in world pixels: one block and its street.
const BUCKET := 448.0
## How far she walks before the locations near her are looked up again, in world pixels.
const RESCAN := 32.0

## Where her walk starts: the doorstep the day is planned from.
var _start := Vector2.ZERO
var _locations: DayLocations
var _draw: LocationDraw
## Bucket -> the locations whose ground touches it.
var _index := {}
## Location -> its ground in world space.
var _rects := {}
## The undrawn locations within `BAND_FAR` and `RESCAN` of where the last scan stood, as
## `[distance, location]`, and that point: a tick asks these rather than the whole index, and scans
## again once she has walked `RESCAN` from it.
var _near: Array = []
var _scanned_at := Vector2.INF
## The band's draw under way, a step a tick, or null.
var _asking: LocationDraw.Asking = null
## How many draws a tick had to make whole (`forced()`).
var _forced := 0

## The walk's draw over the day's `locations`, drawing through `draw`, for a walk from `start`.
func _init(locations: DayLocations, draw: LocationDraw, start: Vector2) -> void:
	_locations = locations
	_draw = draw
	_start = start
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
## `in_view` (a world rect -> whether she can see it) says she cannot see, whole; then one step
## of the band's draw under way, or of a new one, the nearest out of her view within `BAND_FAR`, ahead
## of her `heading` before any behind. Answers the plans the draws placed, for the walk to stand.
func draw_ahead(at: Vector2, heading: Vector2, in_view: Callable) -> Array[EventScheduler.Planned]:
	var placed: Array[EventScheduler.Planned] = []
	if _scanned_at == Vector2.INF or at.distance_to(_scanned_at) > RESCAN:
		_near = _undrawn_within(at, BAND_FAR + RESCAN, false)
		_scanned_at = at
	# The must-draws first, so the band's pick after them sees what they drew.
	var band: Array = []
	for entry: Array in _near:
		var location: Location = entry[1]
		if location.is_drawn() or location.is_taken():
			continue
		var rect: Rect2 = _rects[location]
		var distance := at.distance_to(Vector2(clampf(at.x, rect.position.x, rect.end.x),
				clampf(at.y, rect.position.y, rect.end.y)))
		if distance > BAND_FAR or in_view.call(rect):
			continue
		# A sidewalk waits for its section (`DayLocations.drawn_before()`), and so for her to look
		# away from it too.
		var first := _locations.drawn_before(location)
		if first and in_view.call(_rects[first]):
			continue
		if distance <= MUST_DRAW:
			_forced += _draw_whole(location, placed)
		else:
			band.append([location, distance, rect])
	var next: Location = null
	var next_rank := INF
	for entry: Array in band:
		var location: Location = entry[0]
		if location.is_drawn() or location.is_taken():
			continue
		var rect: Rect2 = entry[2]
		var behind := heading == Vector2.ZERO \
				or rect.get_center().direction_to(at).dot(heading) >= 0.0
		var rank: float = entry[1] + (BAND_FAR if behind else 0.0)
		if rank < next_rank:
			next_rank = rank
			var first := _locations.drawn_before(location)
			next = first if first else location
	if _asking == null and next != null:
		_asking = _draw.begin(next)
	if _asking and _asking.location.is_taken():
		_asking = null
	# A draw under way waits while she can see its location: a marble it took there would appear
	# where she is looking.
	if _asking and not in_view.call(_rects[_asking.location]):
		if _asking.step():
			var plan := _draw.finish(_asking)
			_asking = null
			if plan:
				placed.append(plan)
	return placed

## How many locations the walk has had to draw whole on one tick because they came within
## `MUST_DRAW` undrawn: what the band's one step a tick did not reach in time.
func forced() -> int:
	return _forced

## **Draws every undrawn location within `radius` of `at`**, nearest first, whether she can see it
## or not: what a walk starting at `at` owes before its first step, drawn while the day is set up.
func draw_within(at: Vector2, radius: float) -> Array[EventScheduler.Planned]:
	var placed: Array[EventScheduler.Planned] = []
	for entry: Array in _undrawn_within(at, radius, true):
		_draw_whole(entry[1], placed)
	return placed

## **Draws every location still undrawn, nearest her start first**, as a walk that went everywhere
## from where she starts would leave them: what a dev spawn beside a row asks
## (`EventManager.draw_everywhere()`), and a suite that asks the day's rules of every row the day can
## stand (`tests/drawn_day.gd`). Nothing in play calls it.
func draw_everywhere() -> Array[EventScheduler.Planned]:
	return draw_within(_start, INF)

## Hands the draw the walk it now judges against (`LocationDraw.judge_against()`): from the walk's
## start, what stands is the walk's.
func judge_against(walk: WalkEvents) -> void:
	_draw.judge_against(walk)

## Draws `location` whole, after the location drawn before it if that is still open, and answers
## how many locations it drew.
func _draw_whole(location: Location, placed: Array[EventScheduler.Planned]) -> int:
	var drawn := 0
	var first := _locations.drawn_before(location)
	if first:
		drawn += _draw_whole(first, placed)
	if location.is_drawn() or location.is_taken():
		return drawn
	var plan: EventScheduler.Planned = null
	if _asking and _asking.location == location:
		plan = _draw.finish(_asking)
		_asking = null
	else:
		plan = _draw.draw(location)
	if plan:
		placed.append(plan)
	return drawn + (1 if location.is_drawn() else 0)

## The undrawn, open locations whose ground is within `radius` of `at`, as `[distance, location]`,
## nearest first where `sorted`.
func _undrawn_within(at: Vector2, radius: float, sorted: bool) -> Array:
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
	if sorted:
		found.sort_custom(func(a: Array, b: Array) -> bool:
			return a[0] < b[0] if a[0] != b[0] \
					else (a[1] as Location).centre() < (b[1] as Location).centre())
	return found
