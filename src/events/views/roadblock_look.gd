class_name RoadblockLook
extends SpreadLook
## The roadblock: its band of barrier drawn in slices, a guard posted at each end, the one who sets
## off after her, and the far guard who walks off once his partner has left for good.

## The barrier post its guards stand at (`EventBarrierPost`), or null for a row with no post. Handed
## when the look is made, and asked everything that changes about the guards.
var _barrier_post: EventBarrierPost

## Handed, as its event is set up, what every look is handed and the barrier post its guards stand
## at, none for a row with no post (`EventBehaviours.compose()` makes it first).
func _init(owner: EventInstance, row: EventDef, drawer: EventDrawer, skip_draw: bool,
		barrier_post: EventBarrierPost) -> void:
	super(owner, row, drawer, skip_draw)
	_barrier_post = barrier_post

## Overrides SpreadLook._draw_figure.
func _draw_figure(canvas: CanvasItem) -> void:
	match _row.picture():
		EventDef.Look.ROADBLOCK:
			_draw_roadblock(canvas)

## A guard still standing at his band (before he has left its body) is drawn facing out from his
## post; once he has left it, his heading is the base's.
## Overrides EventLook.drawn_heading.
func drawn_heading() -> Vector2:
	if _barrier_post and not _barrier_post.has_left_its_body():
		return EventFootprints.guard_post_heading(event.runs_vertically(), 1)
	return super()

## **A barrier with a guard standing at it, from the moment it is placed** (PLAYTEST-94, the
## roadblock's guard). Nothing here appears and nothing disappears: the band and the man are
## both drawn for the whole of the event's life, cold or hunting, and the only thing that changes
## is which of them is moving.
##
## - **Cold, or hunting but not yet noticed** (`is_waiting()`), one man stands at his post for
##   every side its row's `guard_sides` names (PLAYTEST-135 3), in the
##   `guard_standing_*` family, each clear of the barrier's picture and facing out from it
##   (`guard_post_offset()`). `[-1, 1]` (both sides) is every row's own default — a cold roadblock
##   posts two, drawings with no field, no body and no cost of their own — except the region wall's
##   own road body, which `SealPlanner.place_hard_on()` builds with the array emptied: see
##   `EventDef.guard_sides`.
## - **Once the one on her side sets off** — the only one who does, his own barrier blocking the
##   other — the event's own node *is* him: it steps out to his post and `EventPursuit` walks it at
##   her (`EventBarrierPost.leave_the_body()`). The barrier he left is drawn back at
##   `body_position()`, where its collision body is pinned (`PursuitSpec.leaves_its_body`), and the
##   other guard still stands at his post beside it. `guard_alert_*`, hand raised, while he stands
##   at that post for his notice (`_chaser_pictures()`), and `guard_lunging_*` once he is actually
##   giving chase — each read from his own travel heading through `_draw_eight_view()`, so he turns
##   to face where he is going rather than only mirroring east/west (PLAYTEST-128 1).
##
## So the street he abandoned stays visibly and physically shut behind him, and what she has to get
## away from is a man rather than a band of concrete.
##
## **The man, the band and its slices are nodes of their own, so each sorts at its own point**: the
## instance at the chaser's feet once he has set off, the guards posted beside the band at the
## band's line (`RoadblockBand`), and the band's segments each at its own slice's feet (`Slice`).
func _draw_roadblock(canvas: CanvasItem) -> void:
	# **The barrier never rides the chaser's stride** (azure-koala #601). `draw()` lifts the whole
	# canvas by `current_bob()` for anything that pursues or leaves, and the band and the posted
	# guard are furniture of the street rather than part of the man who walked out of it. On the
	# screen they are nodes of their own (`RoadblockBand`, its `Slice`s), standing at the body; the
	# halo ring's canvas has no such node and draws them back down by the lift.
	if canvas == event and _band != null:
		_draw_the_chaser(canvas)
		return
	# The halo ring (`canvas != self`) traces what is costing her: both guards and the band while
	# the instance stands on the band, only the man once he has set off (his halo would otherwise
	# paint over the band wherever he stands south of it). A departing guard's band has a rim of its
	# own, `_band_halo`.
	if _barrier_post == null or _barrier_post.chaser_side() == 0 \
			or event.is_only_its_barrier() or _band == null:
		draw_the_band(canvas, _roadblock_band_at())
	_draw_the_chaser(canvas)

## The band and the guard posted at each end of it, drawn at `band_at` in `canvas`; on the band's
## own node only the guards, its segments being its slices (`_draw_spread()`).
##
## Overrides EventLook.draw_the_band.
func draw_the_band(canvas: CanvasItem, band_at: Vector2) -> void:
	_draw_the_spread(canvas, band_at)
	if _barrier_post == null:
		return
	for side: int in _barrier_post.sides_still_posted():
		_draw_posted_guard(canvas, band_at, side)

## The man who set off, drawn on the event's own node, which walks with him.
func _draw_the_chaser(canvas: CanvasItem) -> void:
	if _barrier_post == null or _barrier_post.chaser_side() == 0 \
			or event.is_only_its_barrier():
		return
	# His own small shadow — not the band's — so `_draw_eight_view()` below is asked not to draw
	# one of its own; see that function's own doc comment.
	_draw_shadow(canvas, Vector2.ZERO, EventPictures.GUARD_SHADOW_RADIUS)
	_draw_eight_view(_chaser_pictures(), event.facing_now(), canvas, false, {}, false)

## The hunting roadblock's guard who set off, by stage: his alert, hand raised, while he stands at
## his post for his notice (`is_standing_for_its_notice()`), his lunge once he gives chase, and his
## standing picture as he walks away when the chase is over.
func _chaser_pictures() -> Dictionary:
	if event.is_standing_for_its_notice():
		return EventPictures.GUARD_ALERT_BY_VIEW
	if event.is_telegraphing() or event.is_on_its_way_out():
		return EventPictures.GUARD_STANDING_BY_VIEW
	return EventPictures.GUARD_LUNGING_BY_VIEW

## **The barrier's own node.** A sibling of the event in the world's entity layer standing at
## `body_position()`, drawing the posted guards through the look that made it, so that they sort at
## the band's line however far the man who set off has walked from it; the band's segments are its
## slices (`Slice`), each at its own feet. Freed with the instance. It holds its look by a weak
## reference, as a slice does and for the same reason (`SpreadLook.Slice`).
class RoadblockBand extends Node2D:
	var _look: WeakRef

	## Handed, as the look makes it, the look that draws it.
	func _init(look: RoadblockLook) -> void:
		_look = weakref(look)

	func _draw() -> void:
		var look := _look.get_ref() as RoadblockLook
		if look != null:
			look.draw_the_band(self, Vector2.ZERO)

var _band: RoadblockBand

## **Once the guard on her side has left his post for good, the guard at the far post walks off
## too**, so the band stands unmanned and reads as the barrier it now is (inbox #771 in
## minty-lemur). Every roadblock sends him, on a day as in the escape.
##
## The far guard walking away, drawn standing, facing where he goes, on the stride his partner
## walks on. Freed when he is gone or with the instance. It holds the look that draws it and the
## barrier post it follows by weak references, as a slice holds its look (`SpreadLook.Slice`): with
## its event gone it draws nothing and stays where it is.
class FarGuard extends Node2D:
	var _look: WeakRef
	var _post: WeakRef

	## Handed, as the look makes it, the look that draws it and the barrier post that says where he
	## walks.
	func _init(look: RoadblockLook, post: EventBarrierPost) -> void:
		_look = weakref(look)
		_post = weakref(post)
		# After the events' manager has stepped the walk this tick (`EventManager` runs at the
		# default priority), so he stands where his walk ended it and is drawn interpolated
		# between two ticks, as the event is.
		process_physics_priority = 1

	func _physics_process(_delta: float) -> void:
		var post := _post.get_ref() as EventBarrierPost
		if post == null:
			return
		var at := post.where_the_far_guard_walks()
		if at != Vector2.INF:
			global_position = at

	func _draw() -> void:
		var look := _look.get_ref() as RoadblockLook
		if look != null:
			look.draw_the_far_guard(self)

## The far guard as he walks, at his node's origin: his own small shadow on the ground and his
## standing picture lifted by his own stride, the bob his partner's departure rides on
## (`current_bob()`). The view sector is put back afterwards, as `_draw_posted_guard()` puts it.
## What his node asks of the look that made it each time it is drawn.
func draw_the_far_guard(canvas: CanvasItem) -> void:
	_draw_shadow(canvas, Vector2.ZERO, EventPictures.GUARD_SHADOW_RADIUS)
	var kept := _view_sector
	var bob := -absf(sin(_barrier_post.how_far_the_far_guard_has_walked()
			* EventPictures.BOB_PER_PX)) * EventPictures.BOB_HEIGHT
	_draw_eight_view(EventPictures.GUARD_STANDING_BY_VIEW,
			_barrier_post.which_way_the_far_guard_walks(), canvas, false, {}, false,
			Vector2(0.0, bob))
	_view_sector = kept

func _build_the_band() -> void:
	_band = RoadblockBand.new(self)
	_band.name = "RoadblockBand"
	# Placed where the body is rather than moved on the physics tick, so it opts out of physics
	# interpolation.
	_band.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_attach_the_band.call_deferred()

## Puts the band into the world beside the event, on the idle frame after it is built. Idempotent.
## The band's slices go in with it.
func _attach_the_band() -> void:
	_attach_the_slices()
	if _band == null or _band.is_inside_tree() or not event.is_inside_tree() \
			or event.get_parent() == null:
		return
	_band.position = event.body_position()
	event.add_beside_it(_band)
	_move_the_band()

## Keeps the band and the slices where the body is, shown while the instance is, and redrawn when
## asked.
func _move_the_band(redraw := false) -> void:
	_move_the_slices(redraw)
	if _band == null or not _band.is_inside_tree():
		return
	var at := event.body_position()
	if not _band.global_position.is_equal_approx(at):
		_band.global_position = at
	_band.visible = _shows_anything()
	if redraw:
		_band.queue_redraw()

## Where the band is drawn in the event's local space when it is drawn on the event's own canvas
## (the halo ring's): back at `body_position()`, and drawn down by the lift `draw()` puts the whole
## canvas through, so on the screen it stands exactly where its body does on every frame.
func _roadblock_band_at() -> Vector2:
	return event.body_position() - event.global_position + Vector2(0.0, -current_bob())

## One guard standing at his post on `side` of the band drawn at `band_at`, facing out from it.
## **The view sector is put back afterwards**: `select_view()` advances `_view_sector` with
## hysteresis for the one heading the event carries — the chaser's, once there is one — and a
## second figure turned another way must not reset it on every draw.
func _draw_posted_guard(canvas: CanvasItem, band_at: Vector2, side: int) -> void:
	var feet := band_at + EventFootprints.guard_post_offset(event.runs_vertically(), side)
	_draw_shadow(canvas, feet, EventPictures.GUARD_SHADOW_RADIUS)
	var kept := _view_sector
	_draw_eight_view(EventPictures.GUARD_STANDING_BY_VIEW,
			EventFootprints.guard_post_heading(event.runs_vertically(), side), canvas,
			false, {}, false, feet)
	_view_sector = kept

## Overrides SpreadLook.build_nodes.
func build_nodes() -> void:
	_build_the_band()
	super()

## Overrides SpreadLook.move_nodes.
func move_nodes(redraw := false) -> void:
	_move_the_band(redraw)
	_move_the_far_guard()

## Overrides SpreadLook.release_nodes.
func release_nodes() -> void:
	if _band != null and is_instance_valid(_band):
		_band.queue_free()
	_band = null
	_release_the_far_guard()
	super()

## Overrides EventLook.band_node.
func band_node() -> Node2D:
	return _band

## A roadblock's rim stays on the event: its slices are the band's, and the rim it lights traces the
## man who sets off from it.
##
## Overrides SpreadLook.rim_holder.
func rim_holder() -> Node2D:
	if _band != null:
		return null
	return super()

## What the band's own rim stands behind: the band's first slice, or the band.
func band_rim_holder() -> Node2D:
	if not _slices.is_empty() and _slices[0].is_inside_tree():
		return _slices[0]
	return _band

## Overrides EventLook._shows_its_nodes.
func _shows_its_nodes(reach: Rect2) -> bool:
	return _band != null and _band.is_inside_tree() and DrawnView.shows(_band, reach)

## The far guard's node while he walks away (`EventBarrierPost.where_the_far_guard_walks()` names a
## place), null while he stands at his post and once he is gone.
var _far_node: FarGuard

## Keeps the far guard's node at his feet while he walks, shown while the event is and redrawn: made
## the first time he is found walking, freed once he is not.
func _move_the_far_guard() -> void:
	var at: Vector2 = _barrier_post.where_the_far_guard_walks() if _barrier_post else Vector2.INF
	if at == Vector2.INF:
		_release_the_far_guard()
		return
	if _far_node == null:
		if not event.is_inside_tree() or event.get_parent() == null:
			return
		_far_node = FarGuard.new(self, _barrier_post)
		_far_node.name = "FarGuard"
		_far_node.position = at
		event.add_beside_it(_far_node)
		_far_node.global_position = at
		_far_node.reset_physics_interpolation()
	if not _far_node.is_inside_tree():
		return
	_far_node.visible = _shows_anything()
	_far_node.queue_redraw()

func _release_the_far_guard() -> void:
	if _far_node != null and is_instance_valid(_far_node):
		_far_node.queue_free()
	_far_node = null
