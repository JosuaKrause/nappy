class_name EventBarrierPost
extends EventBehaviour
## **A barrier its guards stand at, and walk out of** (`PursuitSpec.leaves_its_body`): the roadblock,
## cold or hunting. **Two guards, one on each side of the band** *(2026-09-25: "have one guard on
## each side?")*, and which of them set off: `0` while both hold their posts, then the side of the
## one on her side — the only one who gives chase, "since the other one will be blocked" by his own
## barrier. The event is the chaser from then on; the other stays at his post beside the band until
## his partner starts to walk away, when he leaves too (`RoadblockFarGuard`).
##
## **The barrier he walks out of stays where it was built** (`body_position()`): the man who leaves
## it does not take it with him, so the street he abandoned stays shut behind him, and the body is
## pinned there rather than freed. **The barrier outlives its guard**: once he is gone for good the
## event is only the barrier, solid and silent (`EventInstance.Phase.SPENT`), the post he left
## empty, for as long as the roadblock would have stood had he never set off.
##
## **Streamed out spent, or walking off, it comes back as only the barrier** (`save()`, `restore()`):
## never as a guard who has forgotten and chases again.

## Where the event's body was left standing when its guard walked out of it, in world space, or
## `Vector2.INF` while the two are still the same place.
var _body_left_at := Vector2.INF
## Which side's guard set off; `0` while both stand at their posts.
var _chaser_side := 0
## The guard at the far post.
var far: RoadblockFarGuard

func _init() -> void:
	steps_each_tick = false

func attach(owner: EventInstance) -> void:
	super.attach(owner)
	far = RoadblockFarGuard.new(owner)

## Whether the barrier has been left behind — read by `RoadblockLook._draw_roadblock()` to know
## whether to draw the band under its own feet or back at the post.
func has_left_its_body() -> bool:
	return _body_left_at != Vector2.INF

## Where the body stands, which is where the street is still shut: the event's own position while
## nothing has been left behind.
func body_position() -> Vector2:
	return event.global_position if _body_left_at == Vector2.INF else _body_left_at

## Which side's guard set off; `0` while both stand.
func chaser_side() -> int:
	return _chaser_side

## **Whether its guard is spent, or on his way out from the barrier**: what a stream-out carries
## (`save()`) so that a barrier streamed in again comes back as only the barrier, never as a guard
## who has forgotten and chases again, and what passes over a band that has nothing to warn of
## (`EventManager._warn_about_the_ground_she_is_on()`).
func is_spent() -> bool:
	return event.phase == EventInstance.Phase.SPENT or (event.is_leaving and has_left_its_body())

## Whether a guard still stands at the band's far post: the band's own drawing while both are
## posted, and after his partner has set off, until he leaves too.
func has_its_far_guard_posted() -> bool:
	return not far.has_left() \
			and event.def.guard_sides.any(func(side: int) -> bool: return side != _chaser_side)

## **Pins the body at the place the guard is walking away from**, the frame he stops waiting, and
## keeps it there every frame he moves. **The body is a child node, so it moves with him unless
## something holds it** — `keep_the_body()`, run every frame rather than reparenting, since a
## reparent mid-tick would change the tree under the loop that is walking it, and the body has to
## be freed with the event in any case. **The place is recorded only once**: the branch that calls
## this runs on every frame he is hunting.
##
## **He sets off from his own post**, the one on her side of the band: the event steps from the
## band's centre, where his notice was measured — inside the band's own field, which
## `Tuning.validate_pursuit()` requires — out to that post the frame he notices her, and
## `EventPursuit` walks him from there. Beside the band he is nearer her than the centre is, which
## costs her none of his warning: he charges on its clock (`EventInstance.warns_by_radius()`).
func leave_the_body() -> void:
	if _body_left_at == Vector2.INF:
		_body_left_at = event.global_position
		_set_off_from_the_near_post()
	keep_the_body()

func _set_off_from_the_near_post() -> void:
	var her: Vector2 = event.player_at
	var vertical: bool = event._spread_vertical
	var toward: Vector2 = her - event.global_position if her != Vector2.INF else Vector2.ZERO
	_chaser_side = EventInstance._guard_side_toward(vertical, toward)
	# Not a step: he already stands at this post, drawn there while he waits, and the event's own
	# origin moves from the band he guards to his feet so his chase sets off from them.
	event.global_position = event.global_position \
			+ EventInstance.guard_post_offset(vertical, _chaser_side)
	# Drawn from his post at once, not slid there between two ticks.
	event.reset_physics_interpolation()
	if her != Vector2.INF and not her.is_equal_approx(event.global_position):
		event._heading = (her - event.global_position).normalized()

## Holds the body where it was left.
func keep_the_body() -> void:
	if not event._obstruction or _body_left_at == Vector2.INF:
		return
	event._obstruction.global_position = _body_left_at

## **He stops warning and is back at the band he stood at**, with the band's body under him again:
## she went back out of his warning radius (`EventInstance._stop_warning()`).
func back_at_the_band() -> void:
	if _body_left_at == Vector2.INF:
		return
	event.global_position = _body_left_at
	_body_left_at = Vector2.INF
	_chaser_side = 0
	if event._obstruction:
		event._obstruction.position = Vector2.ZERO
	event.reset_physics_interpolation()

## The tiles under the barrier's solid body where it was left, as the smallest rect holding them:
## the ground a guard walking off from it, and the far guard, never walk through.
func tiles_under_the_band() -> Rect2i:
	var def: EventDef = event.def
	if def.shape == null:
		return Rect2i()
	var tiles := def.shape.tiles_under(body_position(), event._solid_axis())
	var low := tiles[0]
	var high := tiles[0]
	for tile in tiles:
		low = Vector2i(mini(low.x, tile.x), mini(low.y, tile.y))
		high = Vector2i(maxi(high.x, tile.x), maxi(high.y, tile.y))
	return Rect2i(low, high - low + Vector2i.ONE)

## Sends the far guard off from his post, the frame his partner starts to walk away.
func send_the_far_guard_off() -> void:
	var far_side := 0
	for side: int in event.def.guard_sides:
		if side != _chaser_side:
			far_side = side
			break
	far.send_off(far_side)

## **The guard is gone for good** *(Playtest: "the guarded barriers disappear after shaking off the
## pursuer. that doesn't make sense.")*: a chase that ended sent him away, and once he is out of
## the picture the event goes back to being the barrier, its body and its picture where they were
## built and the post he left empty. Nothing appears and nothing disappears.
func stand_as_the_barrier() -> void:
	event.transition(EventInstance.Phase.SPENT)
	event.departure.reset()
	event._notice.stop()
	event.global_position = _body_left_at
	keep_the_body()
	event.reset_physics_interpolation()

## **Streamed in after its guard was spent**: only the barrier, at the place the plan stands,
## waiting and solid, with the post `side` left empty and the far guard gone with his partner.
## Nothing is reported again: its charge, and the warning before it, were counted before it streamed
## out and are over, its end at the day's end included.
func come_back_as_the_barrier(side: int) -> void:
	event.transition(EventInstance.Phase.SPENT)
	# The walk off he was on when it streamed out is over with him, as `stand_as_the_barrier()`'s.
	event.departure.reset()
	_chaser_side = side
	far.gone = true
	_body_left_at = event.global_position
	event._notice.stop()
	event._charge.began = true
	event._charge.warned = true
	event._charge.ended = true
	keep_the_body()

## Its guard spent, or on his way out from the barrier, and the side he left: only then is there
## anything to carry.
func save() -> Dictionary:
	if not is_spent():
		return {}
	return {"spent": true, "side": _chaser_side}

func restore(state: Dictionary) -> void:
	if bool(state.get("spent", false)):
		come_back_as_the_barrier(int(state.get("side", 0)))
