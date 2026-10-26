class_name RankLook
extends SpreadLook
## A row drawn as people across its ground, each a slice of his own: the café's tables and sitters,
## the protest's two ranks and the firefight's two gunmen.

func _draw_figure(canvas: CanvasItem) -> void:
	match event.def.look:
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
## its sitter *(inbox #827 in curly-moose: "yes, slice the cafe tables")*; slice `only` draws its
## own sitter and table from `origin`, the first also the shadow. On any other canvas, or with
## `only` below zero, the whole frontage is drawn, every sitter before every table.
func _draw_cafe(canvas: CanvasItem, only := -1, origin := Vector2.ZERO) -> void:
	if only < 0 and _drawn_by_its_slices(canvas):
		return
	var half := maxf(11.0, event.def.obstructs_radius)
	if only <= 0:
		_draw_body_shadow(canvas, origin)
	var segments := _cafe_table_count()
	var width := half * 2.0 / segments
	for i in segments:
		if only < 0 or i == only:
			_draw_cafe_sitter(canvas, origin, half, width, i)
			if only >= 0:
				_draw_cafe_table(canvas, origin, half, width, i)
	if only < 0:
		for i in segments:
			_draw_cafe_table(canvas, origin, half, width, i)

## How many tables the café's frontage holds: as few as cover its run, none stretched past its own
## picture's length.
func _cafe_table_count() -> int:
	var half := maxf(11.0, event.def.obstructs_radius)
	var segment := EventPictures.native_size(EventPictures.CAFE_TABLE)
	var along_natural := segment.y if event.runs_vertically() else segment.x
	return maxi(1, ceili(half * 2.0 / along_natural))

## The sitter of table `i`, at one end of the table sprite, turned to face it. The lean is the whole
## row's and the facing each seat's: `_idle_stepping()` is a property of the event rather than
## of a chair, so every sitter leans together, while the view and the mirror are picked per seat,
## because a party at one table faces the table rather than sharing the frontage's own bearing.
func _draw_cafe_sitter(canvas: CanvasItem, origin: Vector2, half: float, width: float,
		i: int) -> void:
	var by_view := EventPictures.CAFE_SITTER_BY_VIEW_B \
			if _idle_stepping(EventPictures.SITTER_IDLE_PERIOD) \
					else EventPictures.CAFE_SITTER_BY_VIEW
	var along := -half + width * (i + 0.5)
	var alternate := i % 2 == 1
	var chair_along := along + width * (0.26 if alternate else -0.26)
	# Face the table from this chair. The +Vector2(0, -7) below is a screen-depth lift for the
	# sitter's projected feet; it is deliberately not part of the table-facing bearing.
	var sitter_heading := _cafe_seat_heading(event.runs_vertically(), alternate)
	var sitter_sector := EightDirection.nearest(sitter_heading)
	var view: String = EventPictures.EIGHT_VIEW_BY_SECTOR[sitter_sector]
	var sitter: String = by_view[view]
	var mirror := EightDirection.is_mirrored(sitter_sector)
	Sprites.draw_standing(canvas, EventPictures.drawn(sitter),
			origin + event.spread_at(chair_along) + Vector2(0.0, -7.0), Vector2.ZERO, mirror)

## Table `i` of the frontage, standing at the middle of its share of the run, alternate ones
## mirrored.
func _draw_cafe_table(canvas: CanvasItem, origin: Vector2, half: float, width: float,
		i: int) -> void:
	var segment := EventPictures.native_size(EventPictures.CAFE_TABLE)
	var thickness := segment.x if event.runs_vertically() else segment.y
	var along := -half + width * (i + 0.5)
	Sprites.draw_standing(canvas, EventPictures.drawn(EventPictures.CAFE_TABLE),
			origin + event.spread_at(along),
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
## back rank is drawn first and higher up the screen. Nothing here grows with `intensity_ramp` —
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
			Sprites.draw_standing(canvas, EventPictures.drawn(picture), origin + feet[i],
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
		var view := _select_view(event.facing_now())
		var by_view := EventPictures.PROTESTER_BY_VIEW_B if _gait_stepping() \
				else EventPictures.PROTESTER_BY_VIEW
		picture = by_view[view]
		mirror = EightDirection.is_mirrored(_view_sector)
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
	var half := maxf(11.0, event.def.obstructs_radius)
	var across := maxi(2, roundi(half * 2.0 / (EventPictures.native_size(picture).x * 0.8)))
	var step := half * 2.0 / across
	var feet := DrawLayer.slice_feet(Vector2(-half + step * 0.5, -14.0),
			Vector2(half - step * 0.5, -14.0), across - 1)
	feet.append_array(DrawLayer.slice_feet(Vector2(-half, 0.0), Vector2(half, 0.0), across))
	return feet

## People behind cover, shooting at each other. Not a building on fire, which is what it drew for
## fourteen milestones — the same five flames as `burning_building`, on the one event in the
## catalogue whose content is that there are *people* doing this.
##
## The flashes are drawn rather than authored, because a muzzle flash is a light and not an object,
## and they are timed off the pulse envelope so they land on the beat the meter is already moving
## on. Between beats there is nothing but two shapes behind sandbags, which is the point: it is a
## thing to time a run past, and `can_be_timed()` already says so.
##
## **On the screen each half is a slice of its own** (`_slice_plan()`), standing at the middle of
## its share of the run, and slice `only` draws its own gunman and flash from `origin`, the first
## also the shadow. On any other canvas, or with `only` below zero, both are drawn.
func _draw_firefight(canvas: CanvasItem, only := -1, origin := Vector2.ZERO) -> void:
	if only < 0 and _drawn_by_its_slices(canvas):
		return
	var half := maxf(11.0, event.def.obstructs_radius)
	if only <= 0:
		_draw_body_shadow(canvas, origin)
	var strength := 1.0
	if event.def.intensity > 0.0:
		strength = clampf(event.current_intensity() / event.def.intensity, 0.0, 1.0)
	for index in 2:
		if only >= 0 and index != only:
			continue
		var side := -1.0 if index == 0 else 1.0
		var at := origin + Vector2(side * half * 0.62, 0.0)
		Sprites.draw_standing(canvas, EventPictures.drawn(EventPictures.GUNMAN), at, Vector2.ZERO,
				side > 0.0)
		# Sized off the current emission and jittered per side, so the two are never in step.
		var flare := strength * (0.6 + 0.4 * sin(event.age * 17.0 + side * 2.1))
		if flare <= 0.25:
			continue
		var muzzle := at + Vector2(side * 15.0, -12.0)
		canvas.draw_circle(muzzle, 3.0 + 4.0 * flare, MUZZLE_FLASH)
		canvas.draw_circle(muzzle, 1.5 + 2.0 * flare, Color.WHITE)

## A muzzle flash is a *light*, and it must not borrow the amber the danger vocabulary uses for its
## marks. Two things that mean different things must not share a constant, or a rebalance of one
## silently repaints the other.
const MUZZLE_FLASH := Color("e8b64a")

func _slice_plan() -> PackedVector2Array:
	match event.def.look:
		EventDef.Look.PROTEST:
			return _protest_feet(_protest_pose_now()[0])
		EventDef.Look.FIREFIGHT:
			var half := maxf(11.0, event.def.obstructs_radius)
			return DrawLayer.slice_feet(Vector2(-half, 0.0), Vector2(half, 0.0), 2)
		EventDef.Look.CAFE:
			var tables := _spread_run()
			return DrawLayer.slice_feet(tables[0], tables[1], _cafe_table_count())
	return PackedVector2Array()

func _draw_a_slice(slice: Slice) -> void:
	var origin := -_slice_feet[slice.index]
	match event.def.look:
		EventDef.Look.PROTEST:
			_draw_protest(slice, slice.index, origin)
		EventDef.Look.CAFE:
			_draw_cafe(slice, slice.index, origin)
		EventDef.Look.FIREFIGHT:
			_draw_firefight(slice, slice.index, origin)
