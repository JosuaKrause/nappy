class_name SpreadLook
extends EventLook
## A row drawn as a run across its street — the roadworks, a stall, a barricade, a collapsed
## frontage, scaffolding, and the three whole-street scenes (a fallen tree, a crash, a burst main) —
## and the slices every long picture is drawn in, so each part sorts against her on its own. The
## ranks (`RankLook`) and the roadblock (`RoadblockLook`) are drawn in slices too.

func _draw_figure(canvas: CanvasItem) -> void:
	match event.def.look:
		EventDef.Look.ROADWORKS:
			_draw_the_spread(canvas)
		EventDef.Look.STALL:
			_draw_the_spread(canvas)
		EventDef.Look.BARRICADE:
			_draw_the_spread(canvas)
		EventDef.Look.FALLEN_TREE:
			_draw_wide_scene(EventPictures.wide_scene_texture(EventDef.Look.FALLEN_TREE, event.runs_vertically()), canvas)
		EventDef.Look.CAR_ACCIDENT:
			if canvas != event or _slices.is_empty():
				_draw_wide_scene(EventPictures.wide_scene_texture(EventDef.Look.CAR_ACCIDENT, event.runs_vertically(),
						_idle_stepping(EventPictures.CAR_ACCIDENT_SMOKE_PERIOD)), canvas)
		EventDef.Look.BURST_MAIN:
			if canvas != event or _slices.is_empty():
				_draw_wide_scene(EventPictures.wide_scene_texture(EventDef.Look.BURST_MAIN, event.runs_vertically(),
						_idle_stepping(EventPictures.BURST_MAIN_SPLASH_PERIOD)), canvas)
		EventDef.Look.COLLAPSED_FRONTAGE:
			_draw_the_spread(canvas)
		EventDef.Look.SCAFFOLDING:
			_draw_the_spread(canvas)

## The scenery behind each slice of a crash or a burst main, index for index with `_slices`.
var _sceneries: Array[EventScenery] = []

## The crash's and the burst main's visible scene: retained painter-order layers behind each of
## its slices (`EventScenery`), shown while the instance is, on the frame its own clock picks. The
## whole A/B sources remain the badge and halo pictures.
func _update_scenery() -> void:
	if _sceneries.is_empty():
		return
	var shown := not (event.skip_draw or event.is_finished or event.is_suppressed_by_its_own_hold())
	var period := EventPictures.CAR_ACCIDENT_SMOKE_PERIOD if event.def.look == EventDef.Look.CAR_ACCIDENT \
			else EventPictures.BURST_MAIN_SPLASH_PERIOD
	var frame_b := _idle_stepping(period)
	for scenery in _sceneries:
		scenery.visible = shown
		scenery.set_frame(frame_b)

## The draw size for one slice of a spread: `along` is its length down the axis it spreads on,
## `thickness` is its extent across that axis, swapped into `(x, y)` for whichever axis that is —
## so a segment stays as tall as the art says on a north-south street and as wide as the art says
## on an east-west one, whichever axis "tall" turns out to be.
func _spread_extent(along: float, thickness: float) -> Vector2:
	return Vector2(thickness, along) if event.runs_vertically() else Vector2(along, thickness)

## A blocking object is drawn at exactly the width it obstructs, by repeating a segment
## across it. Anything else would be a lie about where the player can walk. On either axis the
## segments cover the run its body closes (`_spread_run()`) and no further.
##
## **The end cap is inset by half its own width, for the same reason, on either axis.** A cap
## centred at `±half` hangs half its own width past the obstruction — `barrier_end.svg` is 6px wide,
## so a `construction` barrier that obstructs 64px would draw 70 — which is the picture claiming
## ground the collision does not hold. Insetting so the cap's *outer* edge lands on `±half` makes
## the drawn extent equal the obstructed one, matching the segments rather than overhanging them.
## A cap is an upright post on both axes, so it is drawn at its own size and its width is what it
## covers along the run whichever way the run goes (`_cap_along`). End-on, the far post stands
## behind the board and the near one in front of it (`_cap_sides`).
##
## **On the screen it is drawn in slices** (`_build_the_slices()`), one per segment, each standing
## at its own feet, so a run going away from the camera sorts slice by slice against her: on this
## node's own canvas, or the band's, nothing is drawn here. On any other canvas — a rim tracing the
## whole picture — it is drawn whole, in the order its slices draw it.
## `origin` moves the whole spread, its shadow included, to a local point other than this node's
## own — which is what a body left standing while its owner walks away needs (`_draw_roadblock()`,
## `PursuitSpec.leaves_its_body`). Zero, the default, is every other caller: the spread is drawn
## where the instance is.
func _draw_spread(segment_picture: String, cap: String, canvas: CanvasItem,
		origin := Vector2.ZERO) -> void:
	if _drawn_by_its_slices(canvas):
		return
	_draw_spread_slices(segment_picture, cap, canvas, origin, 0,
			_spread_slice_count(segment_picture) - 1)

## Slices `first` to `last` of the spread on `canvas`, the spread's origin at `origin`: the shadow
## and the far cap with the first slice, before its segment, and the near cap or caps with the last,
## after its segment — the order the whole picture is drawn in.
func _draw_spread_slices(segment_picture: String, cap: String, canvas: CanvasItem, origin: Vector2,
		first: int, last: int) -> void:
	var run := _spread_run()
	var half := run[0].distance_to(run[1]) * 0.5
	var segment := EventPictures.native_size(segment_picture)
	var thickness := segment.x if event.runs_vertically() else segment.y
	var segments := _spread_slice_count(segment_picture)
	var width := half * 2.0 / segments
	var feet := DrawLayer.slice_feet(run[0], run[1], segments)
	var cap_size := EventPictures.native_size(cap) if not cap.is_empty() else Vector2.ZERO
	for i in range(first, last + 1):
		if i == 0:
			_draw_body_shadow(canvas, origin)
			if not cap.is_empty():
				for side: float in _cap_sides(event.runs_vertically(), true):
					_draw_cap(canvas, cap, cap_size, origin, half, side)
		Sprites.draw_standing(canvas, EventPictures.drawn(segment_picture), origin + feet[i],
				_spread_extent(width, thickness))
		if i == segments - 1 and not cap.is_empty():
			for side: float in _cap_sides(event.runs_vertically(), false):
				_draw_cap(canvas, cap, cap_size, origin, half, side)

## How many segments a spread of `segment_picture` is drawn in: as few as cover its run with no
## segment stretched past its own picture's length.
func _spread_slice_count(segment_picture: String) -> int:
	var run := _spread_run()
	var segment := EventPictures.native_size(segment_picture)
	var along_natural := segment.y if event.runs_vertically() else segment.x
	return maxi(1, ceili(run[0].distance_to(run[1]) / along_natural))

## The run a spread covers from its own origin, far end first: its solid footprint end to end
## (`solid_footprint_of()`, `DrawLayer.run_of()`), the ground its body closes. A spread with no body
## covers 11px either side of its origin, as `drawn_box()` reserves.
func _spread_run() -> PackedVector2Array:
	if event.def.obstructs_radius > 0.0 and event.def.shape != null:
		return DrawLayer.run_of(EventInstance.solid_footprint_of(event.def, event.spread_axis(), event.runs_vertically()),
				Vector2.ZERO)
	return PackedVector2Array([event.spread_at(-11.0), event.spread_at(11.0)])

## The segment and the end cap (`""` for none) a spread-drawn look repeats along its run, or an empty
## list for a look that is not drawn as a spread.
func _spread_pictures() -> PackedStringArray:
	match event.def.look:
		EventDef.Look.ROADWORKS:
			return PackedStringArray([EventPictures.roadwork_segment_texture(event.runs_vertically()), EventPictures.BARRIER_END])
		EventDef.Look.STALL:
			return PackedStringArray([EventPictures.STALL, ""])
		EventDef.Look.BARRICADE:
			return PackedStringArray([EventPictures.BARRICADE_PILE, ""])
		EventDef.Look.COLLAPSED_FRONTAGE:
			return PackedStringArray([EventPictures.COLLAPSED_FRONTAGE, ""])
		EventDef.Look.SCAFFOLDING:
			return PackedStringArray([EventPictures.SCAFFOLDING, ""])
		EventDef.Look.ROADBLOCK:
			return PackedStringArray([EventPictures.roadblock_segment_texture(event.runs_vertically()), EventPictures.ROADBLOCK_END])
	return PackedStringArray()

## The whole spread of this instance's look on `canvas` (`_draw_spread()`).
func _draw_the_spread(canvas: CanvasItem, origin := Vector2.ZERO) -> void:
	var pictures := _spread_pictures()
	_draw_spread(pictures[0], pictures[1], canvas, origin)

# ------------------------------------------------------------------ the slices ---
# **A picture longer than a tile is drawn in slices**, each a node of its own in the world's entity
# layer standing at its own feet, so a run going away from the camera sorts slice by slice against
# her: a spread, one slice per segment; a café, one per table and its sitter; a protest, one per
# protester; a firefight, one per gunman; a wide scene, one per tile of its run, each drawing the
# part of the authored picture over its own band. The instance itself then draws only its caret;
# any other canvas, a rim tracing the whole picture, gets the whole picture.

## **One slice of a long picture on the screen**: a node of its own in the world's entity layer,
## standing at its slice's feet (`DrawLayer.add_slices()`), drawing its own part of the picture
## (`_draw_a_slice()`), and for a crash or a burst main holding that part's scenery. Freed with the
## instance.
class Slice extends Node2D:
	var instance: EventInstance
	var index := 0

	func _draw() -> void:
		if instance != null and is_instance_valid(instance):
			(instance.look as SpreadLook)._draw_a_slice(self)

## The slices this instance's picture is drawn in, far end first, and where each stands from the
## body (`body_position()`), index for index.
var _slices: Array[Slice] = []

var _slice_feet := PackedVector2Array()

## Whether this look is drawn in slices, so they are built again if it re-enters the tree.
var _sliced := false

## Whether a picture drawn on `canvas` is left to the slices: on this node's own canvas, or the
## band's, once its slices stand.
func _drawn_by_its_slices(canvas: CanvasItem) -> bool:
	return not _slices.is_empty() and (canvas == event or canvas == band_node())

## Where each slice of this look's picture stands its feet, from the body, in draw order; empty for
## a look drawn on this node alone.
func _slice_plan() -> PackedVector2Array:
	match event.def.look:
		EventDef.Look.FALLEN_TREE, EventDef.Look.CAR_ACCIDENT, EventDef.Look.BURST_MAIN:
			var run := _wide_scene_run()
			return DrawLayer.slice_feet(run[0], run[1], _wide_scene_slice_count())
	var pictures := _spread_pictures()
	if pictures.is_empty():
		return PackedVector2Array()
	var spread := _spread_run()
	return DrawLayer.slice_feet(spread[0], spread[1], _spread_slice_count(pictures[0]))

## The run a wide scene covers from its own origin, far end first: its shape end to end
## (`DrawLayer.run_of()`), the whole ground the scene is drawn over — for the crash, both cars and
## the debris between them, of which its solid footprint is the cars alone.
func _wide_scene_run() -> PackedVector2Array:
	return DrawLayer.run_of(Footprint.of(event.def.shape, event.spread_axis()), Vector2.ZERO)

## A wide scene is cut into one slice per tile of its run.
func _wide_scene_slice_count() -> int:
	var run := _wide_scene_run()
	return maxi(1, ceili(run[0].distance_to(run[1]) / Tuning.TILE_SIZE))

## The band of a wide scene's picture slice `index` draws, from the instance's origin: its share of
## the run, across the screen on a north-south street, down it on an east-west one, the picture's
## whole height or width the other way.
func _wide_scene_band(index: int) -> Rect2:
	var run := _wide_scene_run()
	var count := _wide_scene_slice_count()
	const FAR := 4096.0
	if event.runs_vertically():
		var share := (run[1].y - run[0].y) / count
		return Rect2(-FAR, run[0].y + share * index, FAR * 2.0, share)
	var width := (run[1].x - run[0].x) / count
	return Rect2(run[0].x + width * index, -FAR, width, FAR * 2.0)

## Builds the slices of a look drawn in slices (`_slice_plan()`), put in beside it once it has
## settled into the world (`_attach_the_slices()`), and the scenery behind each slice of a crash or a
## burst main. None when nothing of it is drawn.
func _build_the_slices() -> void:
	var plan := _slice_plan()
	if plan.is_empty() or event.skip_draw:
		return
	_sliced = true
	_slice_feet = plan
	for i in _slice_feet.size():
		var slice := Slice.new()
		slice.instance = event
		slice.index = i
		slice.name = "Slice%d" % i
		# Moved from `_process()`, so it opts out of physics interpolation like this instance does.
		slice.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		_slices.append(slice)
		_build_the_scenery_of(slice)
	_update_scenery()
	_attach_the_slices.call_deferred()

## The scenery of a crash's or a burst main's slice: the part of every span over the slice's band,
## standing at the instance's origin, the first slice's with the contact shadow whole.
func _build_the_scenery_of(slice: Slice) -> void:
	if event.def.look not in [EventDef.Look.CAR_ACCIDENT, EventDef.Look.BURST_MAIN]:
		return
	var picture := EventPictures.wide_scene_texture(event.def.look, event.runs_vertically())
	var half := maxf(11.0, event.def.obstructs_radius)
	var size := EventPictures.native_size(picture)
	var thickness := size.x if event.runs_vertically() else size.y
	var scenery := EventScenery.new()
	scenery.configure(picture, _spread_extent(half * 2.0, thickness),
			_wide_scene_anchor(event.runs_vertically(), half),
			EventPictures.wide_scene_shadow(picture) if slice.index == 0 else "", _wide_scene_band(slice.index))
	scenery.position = -_slice_feet[slice.index]
	slice.add_child(scenery)
	_sceneries.append(scenery)

## Puts the slices into the world at their feet, each ahead of this instance in the tree, so at a
## tie of feet its caret is drawn over its own picture. Idempotent, so a rig that never reaches the
## idle frame can call it itself (`_attach_the_band()`).
func _attach_the_slices() -> void:
	if _slices.is_empty() or _slices[0].is_inside_tree() or not event.is_inside_tree() \
			or event.get_parent() == null:
		return
	var feet := PackedVector2Array()
	for at in _slice_feet:
		feet.append(event.body_position() + at)
	var nodes: Array[Node2D] = []
	nodes.assign(_slices)
	if event.world_map().has_world():
		DrawLayer.add_slices(event.world_map().world, nodes, feet, DrawLayer.Layer.ENTITIES, event)
	else:
		DrawLayer.add_slices_beside(event, nodes, feet)
	_move_the_slices(true)

## Keeps the slices at the body's feet, shown while the instance is, and redrawn when asked. A
## protest whose pose changes how many protesters its rank holds is sliced again.
func _move_the_slices(redraw := false) -> void:
	if _slices.is_empty() or not _slices[0].is_inside_tree():
		return
	if redraw and event.def.look == EventDef.Look.PROTEST:
		var plan := _slice_plan()
		if plan.size() != _slice_feet.size():
			_release_the_slices()
			_build_the_slices()
			_attach_the_slices()
			return
	var at := event.body_position()
	var shown := not (event.skip_draw or event.is_finished or event.is_suppressed_by_its_own_hold())
	for slice in _slices:
		var feet := at + _slice_feet[slice.index]
		if not slice.global_position.is_equal_approx(feet):
			slice.global_position = feet
		slice.visible = shown
		if redraw:
			slice.queue_redraw()

## One slice of the picture, drawn on its own node from the body's own origin. A crash's or a burst
## main's draws nothing itself: its scenery does.
func _draw_a_slice(slice: Slice) -> void:
	var origin := -_slice_feet[slice.index]
	match event.def.look:
		EventDef.Look.FALLEN_TREE:
			_draw_wide_scene(EventPictures.wide_scene_texture(event.def.look, event.runs_vertically()), slice, slice.index,
					origin)
		EventDef.Look.CAR_ACCIDENT, EventDef.Look.BURST_MAIN:
			pass
		_:
			var pictures := _spread_pictures()
			_draw_spread_slices(pictures[0], pictures[1], slice, origin, slice.index, slice.index)

## Frees the slices with whatever they hold: the scenery, and a rim standing behind the first,
## given back on the spot as a rim always is (`EntityHalo.release()`).
func _release_the_slices() -> void:
	event.release_rims_on_slices()
	for slice in _slices:
		if is_instance_valid(slice):
			slice.hide()
			slice.queue_free()
	_slices.clear()
	_sceneries.clear()

## One end cap of a spread, standing at its end of the run — see `_draw_spread`.
func _draw_cap(canvas: CanvasItem, cap: String, cap_size: Vector2, origin: Vector2, half: float,
		side: float) -> void:
	Sprites.draw_standing(canvas, EventPictures.drawn(cap),
			origin + event.spread_at(_cap_offset(half, _cap_along(cap_size), side)), cap_size)

## Which end caps are drawn before the segments (`behind` true) and which after, as the `side` of
## each (−1 the start of the run, +1 its end): before the first slice's segment and after the last
## one's (`_draw_spread_slices()`). A cap stands inside its end slice's ground, so it sorts with that
## slice and its draw order within the slice is its only depth. Broadside, both posts stand level
## with the board and go over it. End-on, the run goes away from the camera: the start is its far
## end, so that post stands behind the board and is drawn first, and only the near post goes over
## it.
static func _cap_sides(vertical: bool, behind: bool) -> Array[float]:
	var sides: Array[float] = []
	if vertical:
		sides.append(-1.0 if behind else 1.0)
	elif not behind:
		sides.append(-1.0)
		sides.append(1.0)
	return sides

## A whole-scene picture is one body, including on an east-west street. Its vertical asset is
## fitted to the obstruction's diameter, so its standing point moves to the far end of the
## obstruction: `Sprites.draw_standing` anchors the bottom edge, while this scene must span both
## sides of the ground point. Only the three wide scenes use this path; segmented looks keep the
## repeated standing anchors above unchanged.
##
## **On the screen it is cut into slices** along its run (`_wide_scene_band()`): slice `only` draws
## the part of the picture over its own band, the first also the shadow, whole, first. On any
## other canvas, or with `only` below zero, the whole picture is drawn, from `origin`.
func _draw_wide_scene(picture: String, canvas: CanvasItem, only := -1,
		origin := Vector2.ZERO) -> void:
	if only < 0 and _drawn_by_its_slices(canvas):
		return
	var half := maxf(11.0, event.def.obstructs_radius)
	var size := EventPictures.native_size(picture)
	var thickness := size.x if event.runs_vertically() else size.y
	var extent := _spread_extent(half * 2.0, thickness)
	var anchor := origin + _wide_scene_anchor(event.runs_vertically(), half)
	var whole := Rect2(anchor - Vector2(extent.x * 0.5, extent.y), extent)
	if only <= 0:
		var shadow := EventPictures.wide_scene_shadow(picture)
		if not shadow.is_empty() and canvas != event.rim():
			canvas.draw_texture_rect(EventPictures.drawn(shadow), whole, false, Palette.SHADOW)
		else:
			# No authored ground-contact art for this axis (only `car_accident` has one either
			# way) — the shape's own capsule shadow follows the same span as the body, `-half` to
			# `half` along the spread axis.
			_draw_body_shadow(canvas, origin)
	if only < 0:
		Sprites.draw_standing(canvas, EventPictures.drawn(picture), anchor, extent)
		return
	var clip := _wide_scene_band(only)
	clip.position += origin
	var band := whole.intersection(clip)
	if not band.has_area():
		return
	var texture := EventPictures.drawn(picture)
	var texels := texture.get_size() / whole.size
	canvas.draw_texture_rect_region(texture, band,
			Rect2((band.position - whole.position) * texels, band.size * texels))

static func _wide_scene_anchor(vertical: bool, half: float) -> Vector2:
	return Vector2(0.0, half) if vertical else Vector2.ZERO

## The along-axis offset for one end cap, inset from `±half` by half the cap's own extent on that
## axis so its outer edge lands on the obstruction boundary rather than past it — see `_draw_spread`.
## A pure function so a test can assert the arithmetic directly, against the same asset size and
## `obstructs_radius` the drawing itself uses, rather than by parsing what `draw_texture_rect`
## painted.
static func _cap_offset(half: float, cap_along: float, side: float) -> float:
	return side * (half - cap_along * 0.5)

## How much of a spread's run one end cap covers on the ground: the post's own width, on both
## axes. **Never its picture's height on an end-on run**, though that is the extent along the
## spread there: the height is how tall the post stands, not how much of the street it takes up,
## and insetting by it stands each end post half its height in from its end of the barrier, so on
## a 64px column the two 26px posts cover most of it rather than capping it.
static func _cap_along(cap_size: Vector2) -> float:
	return cap_size.x

func build_nodes() -> void:
	_build_the_slices()

func attach_nodes() -> void:
	_attach_the_slices()

func enter_tree() -> void:
	if _sliced and _slices.is_empty():
		_build_the_slices()

func move_nodes(redraw := false) -> void:
	_move_the_slices(redraw)

func release_nodes() -> void:
	_release_the_slices()

func hide_the_scenery() -> void:
	for scenery in _sceneries:
		scenery.hide()

## The first slice, which every other part of a long picture is drawn after, so a rim behind it
## is behind the whole picture.
func rim_holder() -> Node2D:
	if not _slices.is_empty() and _slices[0].is_inside_tree():
		return _slices[0]
	return null

## The slices, in drawing order.
func slices() -> Array[Slice]:
	return _slices
