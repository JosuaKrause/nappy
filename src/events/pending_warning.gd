class_name PendingWarning
extends RefCounted
## A warning that is up before the thing it warns about exists: the screen-edge badge for a row
## that arrives from off screen, pointing at the place it will come from, with nothing in the world
## yet. *(PLAYTEST-145: "the warning appears by itself with a reasonable position and when the time
## is right the object is spawned in at that location just offscreen. that way even if you keep
## moving the object will move with you until it is actually spawned.")*
##
## **The warning is the row's own `telegraph_time`, and nothing about the siting spends it.** The
## thing is created when that time is over, at the place the badge points to, just off screen: the
## view's edge along the way it comes plus the row's own `offscreen_notice` of closing
## (`Tuning.offscreen_lead()`). It is created with its telegraph already spent, because the
## telegraph was the warning — a `hard_fail` row is lethal from its first frame, and a loud one is
## at its own intensity.
##
## **Until then the place follows her** (`follow()`, once a physics frame): walking on neither
## brings the thing sooner nor leaves it behind, and the badge tracks the place. **And it stays on
## ground that makes sense for the thing**, which is what each kind of place below answers
## differently: a cyclist or a loose dog on a sidewalk (`down_her_line()`), the fire engine on the
## road on its way to the fire (`on_its_route()`), the day-13 column in its lane of the main road
## (`in_its_lane()`).
##
## **Where there is no sensible ground this frame the place holds where it last was**, rather than
## leaving its ground, and the thing waits past its time until both are true again: the place is on
## its ground, and it is off screen by the row's own notice. A thing never spawns closer than that,
## so the fairness contract measured from the badge (`EventDef.least_warning()`) holds whatever she
## did while it waited. The owner of the warning (`EventManager`) decides what "arrive" does; this
## class holds the place and the clock.

## The row the badge draws: its silhouette, its colour, and how fast it will close.
var def: EventDef
## Where the badge points, in world px. Moves with her until the thing is created.
var place := Vector2.INF
## Seconds of warning still to run.
var left := 0.0
## How long the warning has been up, in seconds.
var shown := 0.0
## `func(her: Vector2) -> Vector2`: the place on the thing's own ground for her standing at `her`,
## or `Vector2.INF` where there is none this frame.
var _where: Callable
## `func(place: Vector2, her: Vector2) -> bool`: creates the thing at `place`; false when it
## cannot be created there yet, which keeps the warning up for another frame.
var _arrive: Callable

func _init(row: EventDef, where: Callable, arrive: Callable) -> void:
	def = row
	left = row.telegraph_time
	_where = where
	_arrive = arrive

## The closing speed the place is kept off screen against: the row's own speed plus a walk, since
## she is usually walking into it — `Tuning.offscreen_lead()`'s own reading.
func closing_speed() -> float:
	return def.speed + Tuning.WALK_SPEED

## Moves the place with her. False when the warning has nowhere to stand at all yet — only ever
## asked before it is first put up, by `EventManager.warn_first()`.
func follow(her: Vector2) -> bool:
	var at: Vector2 = _where.call(her)
	if at == Vector2.INF:
		return place != Vector2.INF
	place = at
	return true

## Runs the clock, and creates the thing once its time is over and its place is both on its ground
## and off screen by its notice. True once it has been created, when the warning is done.
func tick(delta: float, her: Vector2) -> bool:
	follow(her)
	left -= delta
	shown += delta
	if left > 0.0 or place == Vector2.INF:
		return false
	if not is_off_screen(place - her, closing_speed(), def.offscreen_notice):
		return false
	return bool(_arrive.call(place, her))

# ------------------------------------------------------------------- off screen ---

## Whether a point `offset` from her is outside the view along its own ray by at least `notice`
## seconds of `closing` — the whole of "just off screen". The half pixel keeps a place computed at
## exactly that distance from failing its own test on a rounding.
static func is_off_screen(offset: Vector2, closing: float, notice: float) -> bool:
	if offset.length_squared() < 1.0:
		return false
	return offset.length() + 0.5 >= Tuning.offscreen_lead(offset.normalized(), closing, notice)

# ------------------------------------------------------------ down her line ---

## How far to either side of her line a place down it may be moved to reach its ground, in tiles —
## a street's width, which reaches from any lane of a corridor to both of its sidewalks.
const LATERAL_TILES := Tuning.STREET_WIDTH
## How much further down her line than just off screen a place may be moved to reach its ground,
## in tiles — two streets' widths, which carries it across the carriageway of a cross street and
## the junction it makes.
const FURTHER_TILES := Tuning.STREET_WIDTH * 2

## The waiting place of a row that comes down her own line (`cyclist`, `loose_dog`): just off
## screen in `direction` from her, on the nearest ground `def.placement` names — a sidewalk or a
## square. Moved sideways first, within `LATERAL_TILES`, and where there is none level with that
## point — the carriageway of a cross street is ahead — further down her line, within
## `FURTHER_TILES`, never nearer. `Vector2.INF` where there is none.
##
## `direction` is fixed when the warning goes up and is not re-read from her heading, so a badge
## that said *from there* keeps saying it: she answers it by crossing the street or turning, and a
## place that swung round with her would take the answer away. The place is never nearer her along
## `direction` than just off screen, which is the part that keeps it off screen and keeps walking on
## from bringing the thing sooner.
##
## `map` null is open ground, where every point is ground — the probe and the tests that measure
## the timing rather than the city.
static func down_her_line(map: CityMap, row: EventDef, her: Vector2,
		direction: Vector2) -> Vector2:
	var closing := row.speed + Tuning.WALK_SPEED
	var ahead := her + direction * Tuning.offscreen_lead(direction, closing, row.offscreen_notice)
	if not map:
		return ahead
	var along := direction * Tuning.TILE_SIZE
	var across := Vector2(-direction.y, direction.x) * Tuning.TILE_SIZE
	for further in FURTHER_TILES + 1:
		var level := ahead + along * float(further)
		for step in LATERAL_TILES + 1:
			for side: float in [1.0, -1.0]:
				var at := level + across * (float(step) * side)
				if _is_its_ground(map, row, at):
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

# -------------------------------------------------------------- on its route ---

## The waiting place of a row that drives a fixed route to a place of its own — the fire engine,
## on the fire's street, coming to the kerb at `stop`: on the road up from `stop`, against the way
## it travels (`travel`, unit), **level with her or further up it**, the nearest such point that is
## off screen from her by its notice. No further up the road than `reach`, which is as far as the
## road runs inside the map.
##
## So the engine is always on its way to the fire and never past it, and never between her and the
## fire unless she is past the fire herself: walking up the street toward where it comes from keeps it
## just off screen ahead of her, and walking away past the fire leaves it on the first stretch of its
## road she cannot see — a tile up from the fire, once the fire itself is out of view, where it
## arrives and parks unseen. `Vector2.INF` when no point of the road up from her is off screen, which
## is only ever her standing at its far end.
static func on_its_route(row: EventDef, her: Vector2, stop: Vector2, travel: Vector2,
		reach: float) -> Vector2:
	var closing := row.speed + Tuning.WALK_SPEED
	var up := maxf(float(Tuning.TILE_SIZE), (stop - her).dot(travel))
	while up <= reach:
		var at := stop - travel * up
		if is_off_screen(at - her, closing, row.offscreen_notice):
			return at
		up += ROUTE_STEP
	return Vector2.INF

## How finely `on_its_route()` walks the road looking for its place, in px. A quarter of a tile: the
## place is then at most that much further off screen than it has to be.
const ROUTE_STEP := Tuning.TILE_SIZE * 0.25

# -------------------------------------------------------------- in its lane ---

## The waiting place of a column in one lane of a road running north-south at `lane_x`, driving
## `going` (+1 south, -1 north): level with her along the road, just off screen up it — the lane's
## own column of the view, whatever street she is on. Held on the map (`top` to `bottom`), since the
## main road leaves the map by a tunnel and a bridge and a lead the map cannot hold starts at its
## edge.
static func in_its_lane(row: EventDef, her: Vector2, lane_x: float, going: float, top: float,
		bottom: float) -> Vector2:
	var toward_her := Vector2(0.0, -going)
	var lead := Tuning.offscreen_lead(toward_her, row.speed + Tuning.WALK_SPEED,
			row.offscreen_notice)
	return Vector2(lane_x, clampf(her.y + toward_her.y * lead, top, bottom))
