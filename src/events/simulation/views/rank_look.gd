class_name RankLook
extends SpreadLook
## A row drawn as people across its ground, each a slice of his own: the café's tables and sitters,
## the protest's two ranks and the firefight's two gunmen.

## Overrides SpreadLook._draw_figure.
func _draw_figure(canvas: CanvasItem) -> void:
	match _look.picture():
		EventDef.Look.CAFE:
			_draw_cafe(canvas)
		EventDef.Look.PROTEST:
			_draw_protest(canvas)
		EventDef.Look.FIREFIGHT:
			_draw_firefight(canvas)

## **Both halves have to be drawn**: the tables are what obstructs and the conversation is what it
## emits, so a café drawn as furniture alone is the loudest pleasant thing in act I looking like
## something somebody left out. The spread is `_draw_spread`'s, so the width is exactly the width in
## the way; each sitter is drawn before their own table and a little behind it, because the table is
## the part she cannot walk through and the picture has to agree with that.
##
## Alternate tables are mirrored, which turns a rank of clones into pairs facing each other — the
## same reason a spoiled park rolls a different def per cell. The chair's own shift stays *along*
## the spread axis, same as the table it sits beside; the −7 lift is a fixed screen-depth nudge that
## puts a sitter visibly behind their table whichever way the row runs, so it stays a plain Y offset
## rather than turning with the spread.
##
## **On the screen each table and its sitter are a slice of their own** (`_slice_plan()`), standing
## at their share of the run's feet, so each table sorts against her and against the next table and
## its sitter (inbox #827 in curly-moose). The first slice draws the shadow on itself; its sitter
## stands in it as retained layers of their own (`EventScenery`, `_build_the_scenery_of()`), so the
## lean redraws the moving upper body and nothing else, and its table is drawn over the sitter on
## the slice's front (`draw_the_slice_front()`). On any other canvas the whole frontage is drawn,
## every sitter before every table.
func _draw_cafe(canvas: CanvasItem) -> void:
	if _drawn_by_its_slices(canvas):
		return
	var half := _half_run()
	_draw_body_shadow(canvas)
	var segments := _cafe_table_count()
	var width := half * 2.0 / segments
	for i in segments:
		_draw_cafe_sitter(canvas, half, width, i)
	for i in segments:
		_draw_cafe_table(canvas, Vector2.ZERO, half, width, i)

## How many tables the café's frontage holds: as few as cover its run, none stretched past its own
## picture's length.
func _cafe_table_count() -> int:
	var half := _half_run()
	var segment := EventPictures.native_size(EventPictures.CAFE_TABLE)
	var along_natural := segment.y if event.runs_vertically() else segment.x
	return maxi(1, ceili(half * 2.0 / along_natural))

## The sitter of table `i`, at one end of the table sprite, turned to face it. The lean is the whole
## row's and the facing each seat's: `idle_is_stepping()` is a property of the event rather than
## of a chair, so every sitter leans together, while the view and the mirror are picked per seat,
## because a party at one table faces the table rather than sharing the frontage's own bearing.
func _draw_cafe_sitter(canvas: CanvasItem, half: float, width: float, i: int) -> void:
	var by_view := EventPictures.CAFE_SITTER_BY_VIEW_B \
			if idle_is_stepping(EventPictures.SITTER_IDLE_PERIOD) \
					else EventPictures.CAFE_SITTER_BY_VIEW
	var seat := _cafe_seat(half, width, i)
	var view: String = seat[0]
	var mirror: bool = seat[1]
	var feet: Vector2 = seat[2]
	_drawer.stand(canvas, by_view[view], feet, Vector2.ZERO, mirror)

## How the sitter of table `i` sits: `[view, mirrored, feet]`, the eight-view name it faces its table
## in, whether that view is drawn mirrored, and where its feet stand from the body's origin. What
## the whole frontage (`_draw_cafe_sitter()`) and the sitter's own layers
## (`_build_the_scenery_of()`) both stand it by, so the two cannot disagree.
func _cafe_seat(half: float, width: float, i: int) -> Array:
	var along := -half + width * (i + 0.5)
	var alternate := i % 2 == 1
	var chair_along := along + width * (0.26 if alternate else -0.26)
	# Face the table from this chair. The +Vector2(0, -7) below is a screen-depth lift for the
	# sitter's projected feet; it is deliberately not part of the table-facing bearing.
	var sitter_sector := EightDirection.nearest(_cafe_seat_heading(event.runs_vertically(),
			alternate))
	return [EventPictures.EIGHT_VIEW_BY_SECTOR[sitter_sector],
			EightDirection.is_mirrored(sitter_sector),
			event.spread_at(chair_along) + Vector2(0.0, -7.0)]

## Table `i` of the frontage, standing at the middle of its share of the run, alternate ones
## mirrored.
func _draw_cafe_table(canvas: CanvasItem, origin: Vector2, half: float, width: float,
		i: int) -> void:
	var segment := EventPictures.native_size(EventPictures.CAFE_TABLE)
	var thickness := segment.x if event.runs_vertically() else segment.y
	var along := -half + width * (i + 0.5)
	_drawer.stand(canvas, EventPictures.CAFE_TABLE, origin + event.spread_at(along),
			_spread_extent(width, thickness), i % 2 == 1)

## The bearing from an alternating café chair to its own table. This follows the chair anchor's
## spread-axis offset, while leaving the sprite's fixed screen-depth lift out of the calculation.
## A horizontal frontage therefore seats its pair facing east and west; a vertical frontage seats
## them facing south and north. The caller resolves the bearing through the shared eight-view table.
static func _cafe_seat_heading(spread_vertical: bool, alternate: bool) -> Vector2:
	var toward_table := Vector2.DOWN if spread_vertical else Vector2.RIGHT
	return -toward_table if alternate else toward_table

## A rank of placards as wide as the ground it takes.
##
## The body follows the picture rather than the other way round: a protest that fills a square is
## the whole content of the event.
##
## Two ranks rather than one, offset, so it reads as a crowd with depth instead of a queue; the
## back rank is drawn first and higher up the screen. Nothing here grows with the field's swell —
## the caret over it already breathes with what it is emitting, and a crowd that visibly recruits
## would be a second cue saying the same thing.
##
## **Every body in the rank shares one pose.** They stand within a few tens of pixels of each
## other and the objective is blocks away, so the bearing from any one of them to it is the same
## bearing to within a sector; asking once for the whole rank is the same picture a per-body ask
## would draw, for a fortieth of the cost.
##
## **On the screen each protester is a slice of his own**, standing at his own feet
## (`_protest_feet()`), so the back rank sorts behind the front one and either sorts against her;
## slice `only` draws its own protester from `origin`, the first also the shadow. On any other
## canvas, or with `only` below zero, the whole rank is drawn.
func _draw_protest(canvas: CanvasItem, only := -1, origin := Vector2.ZERO) -> void:
	if only < 0 and _drawn_by_its_slices(canvas):
		return
	if only <= 0:
		_draw_body_shadow(canvas, origin)
	var pose := _protest_pose_now()
	var picture: String = pose[0]
	var mirror: bool = pose[1]
	var feet := _protest_feet(picture)
	for i in feet.size():
		if only < 0 or i == only:
			_drawer.stand(canvas, picture, origin + feet[i],
					Vector2.ZERO, mirror)

## The protest's picture this frame and whether it is mirrored.
func _protest_pose_now() -> Array:
	var picture := EventPictures.protester_texture(event.global_position, _protest_objective())
	var mirror := false
	# `EventPictures.PROTESTER` is `EventPictures.protester_texture()`'s own sentinel for "nothing
	# to point at" — a mark step or no step at all — which is exactly a stationary actor with no
	# target: the rank's own site facing picks its view instead, the same as `busker` or
	# `poster_crew`. Left as a sentinel check rather than a change to
	# `EventPictures.protester_texture()` itself, so `tests/test_protest.gd`'s own contract (a plain
	# pose is exactly `EventPictures.PROTESTER`) keeps holding: the eight `protester_point_*` poses
	# stay unmirrored, since each is its own authored direction rather than a member of the
	# mirrored five-view family.
	if picture == EventPictures.PROTESTER:
		var view := select_view(event.facing_now())
		var by_view := EventPictures.PROTESTER_BY_VIEW_B if gait_is_stepping() \
				else EventPictures.PROTESTER_BY_VIEW
		picture = by_view[view]
		mirror = is_mirrored()
	return [picture, mirror]

## Where each protester of the rank drawn in `picture` stands, in draw order: the back rank, 14px up
## the screen and a half step along, then the front rank, each a slice of the run across the
## screen (`DrawLayer.slice_feet()`), drawn across the screen whichever way the street runs.
## Spaced off the body rather than off the sprite, so the rank ends where the ground it takes ends:
## a crowd drawn at its own natural spacing overhangs its own body by most of a person, which is the
## lie `_draw_spread` exists to avoid in the other direction. Off the drawn pose's own width rather
## than the plain one's, because a pointing pose's placard arm doubles it, so the count of slices
## follows the pose (`_move_the_slices()`).
func _protest_feet(picture: String) -> PackedVector2Array:
	var half := _half_run()
	var across := maxi(2, roundi(half * 2.0 / (EventPictures.native_size(picture).x * 0.8)))
	var step := half * 2.0 / across
	var feet := DrawLayer.slice_feet(Vector2(-half + step * 0.5, -14.0),
			Vector2(half - step * 0.5, -14.0), across - 1)
	feet.append_array(DrawLayer.slice_feet(Vector2(-half, 0.0), Vector2(half, 0.0), across))
	return feet

## People behind cover, shooting at each other, and not a building on fire (`burning_building`'s
## flames): it is the one event in the catalogue whose content is that there are *people* doing
## this.
##
## The flashes are drawn rather than authored, because a muzzle flash is a light and not an object,
## and they are timed off the pulse envelope so they land on the beat the meter is already moving
## on. Between beats there is nothing but two shapes behind sandbags, which is the point: it is a
## thing to time a run past, and `can_be_timed()` already says so.
##
## **On the screen each half is a slice of its own** (`_slice_plan()`), standing at the middle of
## its share of the run, and slice `only` draws its own gunman from `origin`, the first also the
## shadow. **The gunmen and the shadow stand still and the flashes do not**, so a slice is redrawn
## only when the picture's key moves, and its flash is drawn on the slice's front
## (`draw_the_slice_front()`), redrawn on every frame the event is drawn (`_update_scenery()`):
## the player's guarantee that a sprite with only partial motion keeps its stationary pixels in a
## static drawing (sunny-lynx). On any other canvas, or with `only` below zero, both gunmen are
## drawn, each with its flash.
func _draw_firefight(canvas: CanvasItem, only := -1, origin := Vector2.ZERO) -> void:
	if only < 0 and _drawn_by_its_slices(canvas):
		return
	if only <= 0:
		_draw_body_shadow(canvas, origin)
	for index in 2:
		if only >= 0 and index != only:
			continue
		_drawer.stand(canvas, EventPictures.GUNMAN, _gunman_feet(index, origin), Vector2.ZERO,
				index == 1)
		if only < 0:
			_draw_muzzle_flash(canvas, index, origin)

## Where gunman `index` stands from `origin`: the first at the west end of the cover, the second,
## mirrored, at the east.
func _gunman_feet(index: int, origin: Vector2) -> Vector2:
	var side := -1.0 if index == 0 else 1.0
	return origin + Vector2(side * _half_run() * 0.62, 0.0)

## Gunman `index`'s muzzle flash, from `origin`, or nothing between its beats.
func _draw_muzzle_flash(canvas: CanvasItem, index: int, origin: Vector2) -> void:
	var side := -1.0 if index == 0 else 1.0
	# Sized off the current emission and jittered per side, so the two are never in step.
	var flare := _share_of_its_peak_now() * (0.6 + 0.4 * sin(event.age() * 17.0 + side * 2.1))
	if flare <= 0.25:
		return
	var muzzle := _gunman_feet(index, origin) + Vector2(side * 15.0, -12.0)
	canvas.draw_circle(muzzle, 3.0 + 4.0 * flare, MUZZLE_FLASH)
	canvas.draw_circle(muzzle, 1.5 + 2.0 * flare, Color.WHITE)

## A muzzle flash is a *light*, and it must not borrow the amber the danger vocabulary uses for its
## marks. Two things that mean different things must not share a constant, or a rebalance of one
## silently repaints the other.
const MUZZLE_FLASH := Color("e8b64a")

## Overrides SpreadLook._slice_plan.
func _slice_plan() -> PackedVector2Array:
	match _look.picture():
		EventDef.Look.PROTEST:
			return _protest_feet(_protest_pose_now()[0])
		EventDef.Look.FIREFIGHT:
			var half := _half_run()
			return DrawLayer.slice_feet(Vector2(-half, 0.0), Vector2(half, 0.0), 2)
		EventDef.Look.CAFE:
			var tables := _spread_run()
			return DrawLayer.slice_feet(tables[0], tables[1], _cafe_table_count())
	return PackedVector2Array()

## Overrides SpreadLook.draw_the_slice.
func draw_the_slice(canvas: CanvasItem, index: int) -> void:
	var origin := -_slice_feet[index]
	match _look.picture():
		EventDef.Look.PROTEST:
			_draw_protest(canvas, index, origin)
		EventDef.Look.CAFE:
			if index == 0:
				_draw_body_shadow(canvas, origin)
		EventDef.Look.FIREFIGHT:
			_draw_firefight(canvas, index, origin)

## A café table, over the sitter its slice holds (`_draw_cafe()`), or a gunman's muzzle flash over
## him (`_draw_firefight()`).
##
## Overrides SpreadLook.draw_the_slice_front.
func draw_the_slice_front(canvas: CanvasItem, index: int) -> void:
	if _look.picture() == EventDef.Look.FIREFIGHT:
		_draw_muzzle_flash(canvas, index, -_slice_feet[index])
		return
	if _look.picture() != EventDef.Look.CAFE:
		return
	var half := _half_run()
	_draw_cafe_table(canvas, -_slice_feet[index], half, half * 2.0 / _cafe_table_count(), index)

## A café slice's sitter, standing in the slice as retained layers (`EventScenery`): its lap and
## chair-side spans stay drawn while the lean swaps only the upper body's, on the sitter's own
## mirror about its feet. Then the front, so the table goes over the sitter. A firefight's slice
## holds only its front, which draws the gunman's flash. Nothing for any other rank.
##
## Overrides SpreadLook._build_the_scenery_of.
func _build_the_scenery_of(slice: Slice, index: int) -> void:
	if _look.picture() == EventDef.Look.FIREFIGHT:
		slice.add_front()
		return
	if _look.picture() != EventDef.Look.CAFE:
		return
	var half := _half_run()
	var seat := _cafe_seat(half, half * 2.0 / _cafe_table_count(), index)
	var view: String = seat[0]
	var feet: Vector2 = seat[2]
	var sitter: String = EventPictures.CAFE_SITTER_BY_VIEW[view]
	var mirrored: bool = seat[1]
	var parts := _drawer.scenery(sitter, EventPictures.native_size(sitter),
			feet - _slice_feet[index], "", Rect2(), mirrored)
	parts.name = "Sitter"
	slice.add_child(parts)
	slice.add_front()
	_sceneries.append(parts)

## The sitters lean together on the frontage's own timer.
##
## Overrides SpreadLook._scenery_period.
func _scenery_period() -> float:
	if _look.picture() == EventDef.Look.CAFE:
		return EventPictures.SITTER_IDLE_PERIOD
	return super()

## A firefight's muzzle flashes, on its slices' fronts, drawn again on every frame the event is in
## the box: they are a continuous function of its clock (`_draw_muzzle_flash()`), while the gunmen
## under them wait for the picture's key.
##
## Overrides SpreadLook._update_scenery.
func _update_scenery() -> void:
	super()
	if _look.picture() != EventDef.Look.FIREFIGHT:
		return
	for slice in _slices:
		slice.redraw_front()
