class_name EventFootprints
extends RefCounted
## **Where a row's pictures and body stand, measured off the pictures themselves**: the box its
## picture fills, everything it can put on the screen, its solid footprint and the axis that footprint
## lies along, the posted roadblock guard's feet and his warning picture, and whether a row's own
## hold hides it. Static and stateless (two caches aside), so the spawner and the scheduler ask it of
## a row before any instance exists, and an instance asks it of its own row with the street it stands
## on (`EventInstance.drawn_box()`, `EventInstance.solid_axis()`).
##
## Everything here reads the row's data and `EventPictures`' measurements; nothing reads a look or an
## instance's drawing, so siting and drawing agree because both read this one class.

## The gap between a posted roadblock guard's picture and the barrier's, so the two never touch —
## see `guard_post_offset()`.
const _GUARD_POST_CLEARANCE := 2.0

## How far the loose dog's slack lead trails behind it, in px — `FigureLook._draw_loose_dog()`'s own
## reach.
const LOOSE_LEAD_REACH := 26.0

## The box a row's own picture fills standing on its feet at the origin — `drawn_box_of()` before an
## instance exists, and without the run a spread covers, which only an instance's own street decides.
## Empty for a row that draws nothing of its own.
static func box_of(row: EventDef) -> Rect2:
	var icon := EventPictures.icon_for(row.look)
	if icon.is_empty():
		return Rect2()
	var size := EventPictures.native_size(icon)
	return Rect2(-size.x * 0.5, -size.y, size.x, size.y)

## The box, in an instance's own space, that what a row draws roughly fills: its own picture
## (`EventPictures.icon_for()`) standing on its feet at the origin, stretched along the run a
## spread or a rank standing along its street (`EventDef.stands_along_its_street`) covers on a
## street laid down the screen (`spread_vertical`) or
## across it, and grown by the wheel of a flock. An empty box for a row that draws nothing of its own
## (`Look.NONE`). Not pixel-exact — no halo, no badge, no bob, the view a mover is drawn in this frame
## aside — and it does not need to be: `EncounterWatch` asks only whether most of it is in view.
static func drawn_box_of(row: EventDef, spread_vertical: bool) -> Rect2:
	var box := box_of(row)
	if not box.has_area():
		return Rect2()
	var size := box.size
	box = _with_the_drop(row, box)
	var half := maxf(11.0, row.obstructs_radius)
	if row.has_a_spread and spread_vertical:
		box = box.merge(Rect2(-size.x * 0.5, -half, size.x, half * 2.0))
	elif row.has_a_spread or row.stands_along_its_street:
		box = box.merge(Rect2(-half, -size.y, half * 2.0, size.y))
	if row.flock_size > 0:
		box = box.grow(row.flock_spread)
	return box

## **Everything a row can put on the screen**, standing on its feet at the origin, whichever way it
## faces: the union of every picture its look can draw (`EventPictures.family_sources()` — a cyclist
## coming down the screen draws its front view, not the side view its badge shows) wherever it can
## stand (the picture of a car that drives is lowered over its body, `picture_drop_of()`), its body
## shadow (a disc of its shape's radius at its feet), the loose dog's trailing lead, the bob and the
## excitement halo's rim (`EntityHalo.HALO_MARGIN`). What a thing arriving from off screen is placed
## wholly outside the camera's view by (`PendingWarning.just_out_of_sight()`), so nothing of it
## shows on the frame it exists *(amendment 6 of M226, the player: "I don't want any pop in")*. And
## for a row that can be marked — anything with a field or a lethal reach — the danger caret above
## its feet at its tallest (`EventPictures.largest_mark_rect()`), which stands well above the
## picture. Empty for a row that draws nothing of its own.
static func footprint_of(row: EventDef) -> Rect2:
	var box := Rect2()
	var any := false
	for picture in EventPictures.family_sources(row.look):
		var size := EventPictures.native_size(picture)
		if size.x <= 0.0 or size.y <= 0.0:
			continue
		var one := Rect2(-size.x * 0.5, -size.y, size.x, size.y)
		box = one if not any else box.merge(one)
		any = true
	if not any:
		return box_of(row)
	box = _with_the_drop(row, box)
	if row.draws_body_shadow and row.shape != null:
		var r := row.obstructs_radius if row.obstructs_radius > 0.0 else row.shape.radius
		box = box.merge(Rect2(-r, -r, r * 2.0, r * 2.0))
	if row.trails_a_lead:
		box = box.merge(Rect2(-LOOSE_LEAD_REACH, -8.0, LOOSE_LEAD_REACH * 2.0, 8.0))
	box = box.grow(EventPictures.BOB_HEIGHT + EntityHalo.HALO_MARGIN)
	if row.intensity > 0.0 or row.hard_fail:
		box = box.merge(_with_the_drop(row,
				EventPictures.largest_mark_rect().grow_individual(0.0, EventPictures.BOB_HEIGHT,
						0.0, 0.0)))
	return box

## The furthest below its own node a row's picture is ever drawn: a car's body reach, pointed
## straight down the screen, and its look's largest canvas margin (`EventLook._body_anchor()`); zero
## for every other row, whose pictures stand on the node. `footprint_of()` and `drawn_box_of()` add it.
static func picture_drop_of(row: EventDef) -> float:
	if not EventPictures.is_anchored_over_its_body(row.look) or row.shape == null:
		return 0.0
	var margins := EventPictures.canvas_margins(row.look)
	var margin := 0.0
	for view: String in margins:
		margin = maxf(margin, float(margins[view]))
	return row.shape.reach() + margin

## `box` and the same box lowered by `picture_drop_of(row)`, together: every place between the
## two a picture can stand as its heading turns.
static func _with_the_drop(row: EventDef, box: Rect2) -> Rect2:
	var drop := picture_drop_of(row)
	if drop <= 0.0:
		return box
	return box.merge(Rect2(box.position + Vector2(0.0, drop), box.size))

# ------------------------------------------------------------------- the body ---

## **A row's solid footprint**, its origin at the row's own: one piece per `EventDef.parts()`
## entry — one at the origin carrying `shape` for every row that declares none, a car per piece
## for the crash — each offset along the spread axis (`spread_vertical`,
## `EventInstance.spread_at()`) by the piece's own reading of whichever picture is in use, its spine
## along `axis` (`solid_axis_of()`). The physics body (`EventInstance._build_obstruction()`) and the
## blocked record (`EventSpawner.obstructed_footprint()`) both come from here.
static func solid_footprint_of(row: EventDef, axis: Vector2, spread_vertical: bool) -> Footprint:
	var footprint := Footprint.new()
	for piece in row.parts():
		var offset := piece.offset_for(spread_vertical)
		footprint.add(piece.shape,
				Vector2(0.0, offset) if spread_vertical else Vector2(offset, 0.0), axis)
	return footprint

## The ground-plane direction a row's solid body's spine lies along, for whichever of the three
## families ever has a segment shape: a car that drives (`EventDef.vehicle`), along its own
## `heading`; a spread-drawn row, down the screen on a street laid that way (`spread_vertical`) and
## across it otherwise; or the one stationary-vehicle row wide enough to be a segment (`moving_van` —
## see `GroundShape.band()` on that row), which lies along whichever of the street's axes it is drawn
## on (`side_on`, `stands_side_on()`). Never asked of a point shape, where an axis means nothing.
static func solid_axis_of(row: EventDef, heading: Vector2, spread_vertical: bool,
		side_on: bool) -> Vector2:
	# A car's body lies along the way it is driving, and turns with it (`EventCarDriving.turn_the_body()`).
	if row.vehicle != null:
		return heading.normalized() if not heading.is_zero_approx() else Vector2.RIGHT
	if row.has_a_spread or row.stands_along_its_street:
		return Vector2.DOWN if spread_vertical else Vector2.RIGHT
	return Vector2.RIGHT if side_on else Vector2.DOWN

## The ground-plane direction a sited body's spine lies along — `solid_axis_of()` for a body that does
## not exist yet, off the same two statics its instance would read about the street at `placed`.
static func body_axis(map: WorldMap, row: EventDef, placed: Vector2, facing: Vector2) -> Vector2:
	return solid_axis_of(row, facing, EventInstance._spread_is_vertical(map, placed),
			stands_side_on(row, map, placed, facing))

## Whether a stationary vehicle is seen side-on at this point. The moving van faces along the
## street and the burnt car lies across it (`EventDef.lies_across_its_street`). A junction or ground outside the lattice has
## no single street axis, so the vehicle's own facing supplies the coherent default.
static func stands_side_on(row: EventDef, map: WorldMap, at: Vector2, face: Vector2) -> bool:
	var offsets := map.corridor_offsets(map.world_to_tile(at))
	var on_a_north_south_street := offsets.x >= 0
	var on_an_east_west_street := offsets.y >= 0
	if on_a_north_south_street != on_an_east_west_street:
		var parallel_side := on_an_east_west_street
		return not parallel_side if row.lies_across_its_street else parallel_side
	return absf(face.x) >= absf(face.y)

# ------------------------------------------------------------ the guard post ---

## `+1` or `-1`: which side of a band laid along `vertical`'s axis the offset `toward` falls on,
## across it. Level with the band's own line counts as `+1`.
static func guard_side_toward(vertical: bool, toward: Vector2) -> int:
	var across := toward.x if vertical else toward.y
	return -1 if across < 0.0 else 1

## **Where a posted roadblock guard's feet stand relative to the band's centre: beside it, never
## over it.** *(2026-09-25: "also the guards are on top of the barrier?")* The whole of his standing
## picture is kept clear of the whole of the barrier's, `_GUARD_POST_CLEARANCE` apart, on `side`:
##
## - **End-on** (`vertical`), the column is as wide as `roadblock_segment_vertical.svg`, so he stands
##   level with the band's centre, half the column's width and half his own out to the east or west.
## - **Broadside**, the barrier stands as tall as `roadblock_segment.svg` on the band's line, so to
##   the north his feet stand that far behind it and to the south his own height in front of it —
##   his head clear of the barrier's foot rather than over it.
##
## Measured off the pictures themselves, so a redrawn barrier or guard moves the post with it.
static func guard_post_offset(vertical: bool, side: int) -> Vector2:
	var guard := EventPictures.native_size(EventPictures.GUARD_STANDING_BY_VIEW["front"])
	if vertical:
		var column := EventPictures.native_size(EventPictures.ROADBLOCK_SEGMENT_VERTICAL)
		return Vector2(signf(side) * (column.x * 0.5 + guard.x * 0.5 + _GUARD_POST_CLEARANCE), 0.0)
	if side < 0:
		return Vector2(0.0,
				-(EventPictures.native_size(EventPictures.ROADBLOCK_SEGMENT).y
				+ _GUARD_POST_CLEARANCE))
	return Vector2(0.0, guard.y + _GUARD_POST_CLEARANCE)

## Which way a posted guard faces: straight out from the barrier on his own side, towards where she
## would come from — so the turn to face her the frame the near one notices her is still a turn.
static func guard_post_heading(vertical: bool, side: int) -> Vector2:
	var outward := Vector2.RIGHT if vertical else Vector2.DOWN
	return outward * (-1.0 if side < 0 else 1.0)

# ---------------------------------------------------------------- the warning ---

## The largest of a row's warning pictures (`EventDef.warning_picture`): the dog's alert, the
## robber's two alert frames, or the guard's raised hand for anyone else drawn standing in a warning.
static func warning_picture_size(row: EventDef) -> Vector2:
	if _warning_sizes.has(row.warning_picture):
		return _warning_sizes[row.warning_picture]
	var families: Array[Dictionary] = [EventPictures.GUARD_ALERT_BY_VIEW]
	match row.warning_picture:
		EventDef.WarningPicture.DOG_ALERT:
			families = [EventPictures.CHARGING_DOG_ALERT_BY_VIEW]
		EventDef.WarningPicture.ROBBER_ALERT:
			families = [EventPictures.ROBBER_ALERT_BY_VIEW, EventPictures.ROBBER_ALERT_BY_VIEW_B]
	var size := Vector2.ZERO
	for family in families:
		for view: String in family:
			size = size.max(EventPictures.native_size(family[view]))
	_warning_sizes[row.warning_picture] = size
	return size

static var _warning_sizes := {}

## The world rect a roadblock's guard fills with his hand raised, standing at the post on `her` side
## of a band at `band_at` laid along `vertical` — what his warning draws
## (`RoadblockLook.chaser_pictures()`), at the widest and tallest of its views, standing on his
## feet.
static func warning_guard_rect(vertical: bool, band_at: Vector2, her: Vector2) -> Rect2:
	var feet := band_at + guard_post_offset(vertical, guard_side_toward(vertical, her - band_at))
	if _warning_guard == Vector2.ZERO:
		for view: String in EventPictures.GUARD_ALERT_BY_VIEW:
			_warning_guard = _warning_guard.max(
					EventPictures.native_size(EventPictures.GUARD_ALERT_BY_VIEW[view]))
	return Rect2(feet - Vector2(_warning_guard.x * 0.5, _warning_guard.y), _warning_guard)

static var _warning_guard := Vector2.ZERO

# ------------------------------------------------------------------- the hold ---

## Whether a checkpoint's own hold suppresses *every* drawing of `event`, halo included.
##
## **True only where the guard is the whole of what this row draws** (`EventDef.hides_in_its_hold`):
## `checkpoint_post` is one
## man at an alley mouth and nothing else, so when he goes in there is nothing left to draw; a hut
## is a building and a gate is a boom across a road, and *(PLAYTEST-57: "the checkpoint house
## disappears ... all this is incorrect".)* A structure that blinks out while she is inside it
## reads as the door having been removed rather than as her having gone through it, which is the
## opposite of what the hold is for.
##
## Read by `EventLook.draw()`, by `EventLook.draw_body()` (the halo's own re-draw entry point — see
## that function's doc for why the halo needs its own guard rather than inheriting
## `EventLook.draw()`'s), and by a test, so the three can never drift apart from each other.
static func hidden_by_its_hold(event: EventInstance) -> bool:
	return event.def.hides_in_its_hold and event.is_its_guard_inside()
