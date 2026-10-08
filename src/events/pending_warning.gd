class_name PendingWarning
extends RefCounted
## A warning that is up before the thing it warns about exists: the screen-edge badge for a row
## that arrives from off screen, pointing at the place it will come from, with nothing in the world
## yet. *(PLAYTEST-145: "the warning appears by itself with a reasonable position and when the time
## is right the object is spawned in at that location just offscreen.")*
##
## **The badge is up alone for at most a second, then the thing is placed just out of sight where
## it points, and comes into view at once.** *(calm-kestrel, inbox #559: "it should *always* show
## the warning for x seconds (never longer than 2s) without placing anything then place the object
## immediately off screen so it will immediately start coming on the screen turning off the warning.
## the warnings right now are way too long and they jump around wildly"; busy-quail, inbox #569:
## "1s warning should be enough -- there is enough screen space to cross -- let's apply that to the
## others as well".)* How long is the row's own `EventDef.warned_for()`, never more than
## `Tuning.WARNING_ALONE_MAX`. Then the place the row's own ground gives for her where she is now
## (`_where`) is asked once more and the thing is created there (`_arrive`): just off screen, all of
## it outside the camera's whole view (`just_out_of_sight()`), so nothing of it is drawn on the frame
## it exists and it comes into view as soon as it moves, and the screen-edge badge goes off as it
## comes into sight.
##
## **The badge holds still.** Its place is fixed against her when the warning goes up and moves only
## with her own walking (`offset`): it is never re-planned while it is up, so it neither jumps
## between pieces of ground nor slides along a road as she walks.
##
## **Where its ground has no place for it when its time is up, it is withdrawn** (`withdrawn`): the
## badge goes down and nothing comes. A second is the most it may be up alone, so it does not wait
## for ground the way a longer warning could.
##
## Each kind of place below answers "its ground" differently: a cyclist on a sidewalk
## (`down_her_line()`), a pursuer sent down her heading on anything walkable (`along_her_heading()`),
## the fire engine on the road on its way to the fire (`on_its_route()`), the day-13 column in its lane
## of the main road (`in_its_lane()`); the resistance's trap is placed by `ResistanceDirector`'s own.
## The owner of the warning (`EventManager`) decides what "arrive" does; this class holds the place
## and the clock.

## The row the badge draws: its silhouette, its colour, and how fast it will close.
var def: EventDef
## Where the badge points, in world px: her, plus `offset`. Moves only with her.
var place := Vector2.INF
## Where the badge points from her, fixed when the warning goes up (`put_up()`).
var offset := Vector2.INF
## Seconds of the badge alone still to run.
var left := 0.0
## How long the warning has been up, in seconds.
var shown := 0.0
## Whether it came to nothing: when its time was up its ground had no place for the thing, or the
## thing could not be created there, so the badge went down with nothing in the world.
var withdrawn := false
## `func(her: Vector2) -> Vector2`: where the thing would be created for her standing at `her` —
## on its own ground, just out of sight — or `Vector2.INF` where there is none.
var _where: Callable
## `func(place: Vector2, her: Vector2) -> bool`: creates the thing at `place`; false when it
## cannot be created there, which withdraws the warning.
var _arrive: Callable
## Called once if the warning is withdrawn, so the caller that put it up can ask again — the fire
## engine's summons, which would otherwise never come. Empty for a caller with nothing to retry.
var on_withdrawn := Callable()
## Whether the cyclist this warns of is the pelican, rolled as the warning went up
## (`EventManager.rolls_a_pelican()`). Read by the telemetry alone (`logged_name()`): the badge
## draws the row's own silhouette either way.
var is_pelican := false

## What the run log calls the thing this warns of — `EventInstance.logged_name()` before there is
## an instance to ask.
func logged_name() -> String:
	return EventInstance.named_for_the_log(def.id, is_pelican)

func _init(row: EventDef, where: Callable, arrive: Callable) -> void:
	def = row
	left = row.warned_for()
	_where = where
	_arrive = arrive

## Puts the warning up for her standing at `her`: the badge points where the thing would be created
## now, and keeps that offset from her from here on. False, and nothing is up, where its ground has
## no place for it — only ever asked by `EventManager.warn_first()`.
func put_up(her: Vector2) -> bool:
	var at: Vector2 = _where.call(her)
	if at == Vector2.INF:
		return false
	offset = at - her
	place = at
	return true

## Runs the clock with her standing at `her`, the place moving with her, and once its time is up
## creates the thing where its ground now has a place for it, or withdraws the warning. True once it
## is over, either way.
func tick(delta: float, her: Vector2) -> bool:
	place = her + offset
	left -= delta
	shown += delta
	if left > 0.0:
		return false
	var at: Vector2 = _where.call(her)
	if at == Vector2.INF or not bool(_arrive.call(at, her)):
		withdrawn = true
	return true

## How far down her line, past just out of sight, a place may be moved to reach its ground or a
## walkable tile, in tiles — two streets' widths, which carries it across the carriageway of a
## cross street and the junction it makes.
const FURTHER_TILES := Tuning.STREET_WIDTH * 2

## The least distance from her anything arriving from off screen is created at:
## `Tuning.min_offscreen_boundary()`, the view's half height — the worst case `EventDef.validate()`
## checks a row's field against.
static func least_distance() -> float:
	return Tuning.min_offscreen_boundary()

## **Just off screen** along `direction` (unit) from `her`: the nearest point at which everything
## `row` can draw (`EventInstance.footprint_of()`) is wholly outside the camera's view, never nearer
## than `least_distance()`. *(Amendment 6 of M226, the player: "objects don't spawn \"at the edge of
## the screen\" they spawn *offscreen*" · "I don't want any pop in".)* `view` is the camera's whole
## view (`seen_from()`), whatever the input scheme: a corner the joystick's controls cover is out of
## sight for the badge and every "has she seen it", but a thing placed under it is drawn there, so
## placement never counts it.
static func just_out_of_sight(view: VisibleView, row: EventDef, her: Vector2,
		direction: Vector2) -> Vector2:
	return her + direction * view.clear_of_sight(her, direction, EventInstance.footprint_of(row),
			least_distance())

## The camera's whole view placement is measured against: `view`'s own rect with no covered
## corners, or, where there is none or it has never been looked through — a caller that only asks
## whether there is ground at all, such as `EventDirector`'s siting, or a rig with no camera — the
## view about her.
static func seen_from(view: VisibleView, her: Vector2) -> VisibleView:
	if view and view.view.has_area():
		var whole := VisibleView.new()
		whole.look(view.view, false)
		return whole
	return VisibleView.around(her)

## Whether everything `row` can draw, standing at `at`, is wholly outside `view` (the camera's whole
## view, `seen_from()`), and at least `least_distance()` from her.
static func is_out_of_sight(view: VisibleView, row: EventDef, her: Vector2, at: Vector2) -> bool:
	if at.distance_to(her) + 0.5 < least_distance():
		return false
	var box := EventInstance.footprint_of(row)
	var drawn := Rect2(at + box.position, box.size) if box.has_area() \
			else Rect2(at - Vector2.ONE * 0.5, Vector2.ONE)
	return not view.sees_any(drawn)

# ------------------------------------------------------------ down her line ---

## How far to either side of her line a place down it may be moved to reach its ground, in tiles —
## a street's width, which reaches from any lane of a corridor to both of its sidewalks.
const LATERAL_TILES := Tuning.STREET_WIDTH

## Where a row that comes down her own line (`cyclist`, `loose_dog`) is created: just out of sight in
## `direction` from her (`just_out_of_sight()`), on the nearest ground `def.placement` names — a
## sidewalk or a square — and still out of sight there. Moved sideways first, within
## `LATERAL_TILES`, and where there is none level with that point — the carriageway of a cross street
## is ahead — further down her line, within `FURTHER_TILES`, never nearer. `Vector2.INF` where there
## is none.
##
## `direction` is fixed when the warning goes up and is not re-read from her heading, so a badge
## that said *from there* keeps saying it: she answers it by crossing the street or turning, and a
## place that swung round with her would take the answer away.
##
## `map` null is open ground, where every point is ground — the probe and the tests that measure
## the timing rather than the city.
static func down_her_line(map: CityMap, row: EventDef, her: Vector2, direction: Vector2,
		in_view: VisibleView = null) -> Vector2:
	var view := seen_from(in_view, her)
	var ahead := just_out_of_sight(view, row, her, direction)
	if not map:
		return ahead
	var along := direction * Tuning.TILE_SIZE
	var across := Vector2(-direction.y, direction.x) * Tuning.TILE_SIZE
	for further in FURTHER_TILES + 1:
		var level := ahead + along * float(further)
		for step in LATERAL_TILES + 1:
			for side: float in [1.0, -1.0]:
				var at := level + across * (float(step) * side)
				if _is_its_ground(map, row, at) and is_out_of_sight(view, row, her, at):
					return at
				if step == 0:
					break
	return Vector2.INF

## The route a row that came down her line is created on: from its place along `direction` back
## toward her and on past her by the same distance, so it is still going somewhere when it reaches
## her — `EventInstance` reads the end of a path as *arrived* and leaves from there. Shortened to
## stay on the map where the far end would leave it.
static func route_down_her_line(map: CityMap, place: Vector2, her: Vector2,
		direction: Vector2) -> PackedVector2Array:
	var ahead := maxf((place - her).dot(direction), 0.0)
	var behind := place - direction * ahead * 2.0
	if map:
		var bounds := Rect2(Vector2.ZERO, map.world_size()).grow(-Tuning.TILE_SIZE * 0.5)
		while not bounds.has_point(behind) and behind.distance_to(place) > Tuning.TILE_SIZE:
			behind += direction * Tuning.TILE_SIZE
	return PackedVector2Array([place, behind])

static func _is_its_ground(map: CityMap, row: EventDef, at: Vector2) -> bool:
	var tile := map.world_to_tile(at)
	return map.in_bounds(tile) and row.placement.has(map.tile_at(tile)) and not map.is_closed(tile)

# ---------------------------------------------------------- along her heading ---

## Where a pursuer the director sends at her down her heading (`charging_dog`, on the day it teaches
## the run) is created: just out of sight along `direction` from her, or further out along it up to
## `FURTHER_TILES` to the first walkable point still out of sight. It comes at her in a straight line
## from there, so nothing about its ground is asked but that it can stand on it. `Vector2.INF` where
## there is none; `map` null is open ground.
static func along_her_heading(map: CityMap, row: EventDef, her: Vector2, direction: Vector2,
		in_view: VisibleView = null) -> Vector2:
	var view := seen_from(in_view, her)
	var ahead := just_out_of_sight(view, row, her, direction)
	if not map:
		return ahead
	var step := direction * (Tuning.TILE_SIZE * 0.5)
	for further in FURTHER_TILES * 2 + 1:
		var at := ahead + step * float(further)
		if map.is_walkable(map.world_to_tile(at)) and is_out_of_sight(view, row, her, at):
			return at
	return Vector2.INF

# -------------------------------------------------------------- on its route ---

## Where a row that drives a fixed route to a place of its own is created — the fire engine, on the
## fire's street, coming to the kerb at `stop`: on the road up from `stop`, against the way it travels
## (`travel`, unit), **level with her or further up it**, the nearest such point that is out of sight
## (`is_out_of_sight()`). No further up the road than `reach`, which is as far as the road runs
## inside the map.
##
## So the engine is always on its way to the fire and never past it, and never between her and the
## fire unless she is past the fire herself: walking up the street toward where it comes from keeps it
## just out of sight ahead of her, and walking away past the fire leaves it on the first stretch of its
## road she cannot see — a tile up from the fire, once the fire itself is out of view, where it
## arrives and parks unseen. `Vector2.INF` when no point of the road up from her is out of sight,
## which is only ever her standing at its far end.
static func on_its_route(row: EventDef, her: Vector2, stop: Vector2, travel: Vector2,
		reach: float, in_view: VisibleView = null) -> Vector2:
	var view := seen_from(in_view, her)
	var up := maxf(float(Tuning.TILE_SIZE), (stop - her).dot(travel))
	while up <= reach:
		var at := stop - travel * up
		if is_out_of_sight(view, row, her, at):
			return at
		up += ROUTE_STEP
	return Vector2.INF

## How finely `on_its_route()` walks the road looking for its place, in px. A quarter of a tile: the
## place is then at most that much further out of sight than it has to be.
const ROUTE_STEP := Tuning.TILE_SIZE * 0.25

# -------------------------------------------------------------- in its lane ---

## Where a column in one lane of a road running north-south at `lane_x`, driving `going` (+1 south,
## -1 north), is created: level with her along the road, just out of sight up it — the lane's own
## column of the view, whatever street she is on. Held on the map (`top` to `bottom`), since the main
## road leaves the map by a tunnel and a bridge and a place the map cannot hold starts at its edge —
## and where holding it there would bring the front truck into view, `Vector2.INF`: she is too near
## the road's end for it to come from there unseen, so the warning has no place (or is withdrawn)
## rather than a truck appearing on screen.
static func in_its_lane(row: EventDef, her: Vector2, lane_x: float, going: float, top: float,
		bottom: float, in_view: VisibleView = null) -> Vector2:
	var view := seen_from(in_view, her)
	var toward_her := Vector2(0.0, -going)
	var level := Vector2(lane_x, her.y)
	var out := view.clear_of_sight(level, toward_her, EventInstance.footprint_of(row), least_distance())
	var at := Vector2(lane_x, clampf(her.y + toward_her.y * out, top, bottom))
	if at.y != her.y + toward_her.y * out and not is_out_of_sight(view, row, her, at):
		return Vector2.INF
	return at
