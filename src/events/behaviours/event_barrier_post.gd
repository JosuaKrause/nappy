class_name EventBarrierPost
extends EventBehaviour
## **A barrier its guards stand at, and walk out of** (`PursuitSpec.leaves_its_body`): the roadblock,
## cold or hunting. **Two guards, one on each side of the band** (PLAYTEST-135 3), and which of them
## set off: `0` while both hold their posts, then the side of the one on her side — the only one who
## gives chase, the other being blocked by his own barrier.
## The event is the chaser from then on; the other stays at his post beside the band until
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
var _far: RoadblockFarGuard
## Its row: the shape of its band and the sides its guards stand on.
var _row: EventDef
## The departure its guard walks off by (`EventDeparture`), which this ends once he is gone and
## clears for a barrier streamed in spent, held by a weak reference: the departure holds this to
## walk him off, so a strong one each way would be a reference cycle that is never freed. Handed once
## the departure is made (`take_its_departure()`).
var _departure: WeakRef = null

## Handed, as its event is set up, the figure it moves, where she is, its row, and the ground and how
## its guards move over it, which it hands on to the guard at the far post.
func _init(figure: EventInstance.Figure, where: WhereSheIs, row: EventDef, map: WorldMap,
		navigator: Navigator, mover: Mover) -> void:
	steps_each_tick = false
	_figure = figure
	_where = where
	_row = row
	_far = RoadblockFarGuard.new(figure, where, row, map, navigator, mover)

## Handed the departure its guard walks off by, as its event is set up: it is made after this, since
## it is handed this too (`EventBehaviours.compose()`).
func take_its_departure(departure: EventDeparture) -> void:
	_departure = weakref(departure)

## The departure its guard walks off by.
func _its_departure() -> EventDeparture:
	return _departure.get_ref()

## Whether the barrier has been left behind — read by `RoadblockLook.drawn_heading()` to know
## whether a guard still stands at his band, facing out from his post.
func has_left_its_body() -> bool:
	return _body_left_at != Vector2.INF

## Where the body stands, which is where the street is still shut: the event's own position while
## nothing has been left behind.
func body_position() -> Vector2:
	return _figure.place() if _body_left_at == Vector2.INF else _body_left_at

## Which side's guard set off; `0` while both stand.
func chaser_side() -> int:
	return _chaser_side

## **Whether its guard is spent, or on his way out from the barrier**: what a stream-out carries
## (`save()`) so that a barrier streamed in again comes back as only the barrier, never as a guard
## who has forgotten and chases again, and what passes over a band that has nothing to warn of
## (`WarningBoard.warn_about_the_ground_she_is_on()`).
func is_spent() -> bool:
	return _figure.is_only_its_barrier() or (_figure.is_on_its_way_out() and has_left_its_body())

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
		_body_left_at = _figure.place()
		_set_off_from_the_near_post()
	keep_the_body()

func _set_off_from_the_near_post() -> void:
	var her: Vector2 = _where.at()
	var vertical: bool = _figure.runs_vertically()
	var toward: Vector2 = her - _figure.place() if her != Vector2.INF else Vector2.ZERO
	_chaser_side = EventFootprints.guard_side_toward(vertical, toward)
	# Not a step: he already stands at this post, drawn there while he waits, and the event's own
	# origin moves from the band he guards to his feet so his chase sets off from them.
	_figure.arrive_at(_figure.place() + EventFootprints.guard_post_offset(vertical, _chaser_side))
	# Drawn from his post at once, not slid there between two ticks.
	_figure.appear_where_it_stands()
	if her != Vector2.INF and not her.is_equal_approx(_figure.place()):
		_figure.turn_to((her - _figure.place()).normalized())

## Holds the body where it was left.
func keep_the_body() -> void:
	if _body_left_at == Vector2.INF:
		return
	_figure.pin_its_body_at(_body_left_at)

## **He stops warning and is back at the band he stood at**, with the band's body under him again:
## she went back out of his warning radius (`EventPursuit`).
func back_at_the_band() -> void:
	if _body_left_at == Vector2.INF:
		return
	_figure.arrive_at(_body_left_at)
	_body_left_at = Vector2.INF
	_chaser_side = 0
	_figure.unpin_its_body()
	_figure.appear_where_it_stands()

## The tiles under the barrier's solid body where it was left, as the smallest rect holding them:
## the ground a guard walking off from it, and the far guard, never walk through.
func tiles_under_the_band() -> Rect2i:
	if _row.shape == null:
		return Rect2i()
	var tiles := _row.shape.tiles_under(body_position(), _figure.solid_axis())
	var low := tiles[0]
	var high := tiles[0]
	for tile in tiles:
		low = Vector2i(mini(low.x, tile.x), mini(low.y, tile.y))
		high = Vector2i(maxi(high.x, tile.x), maxi(high.y, tile.y))
	return Rect2i(low, high - low + Vector2i.ONE)

## Sends the far guard off from his post, the frame his partner starts to walk away.
func send_the_far_guard_off() -> void:
	var far_side := 0
	for side: int in _row.guard_sides:
		if side != _chaser_side:
			far_side = side
			break
	_far.send_off(far_side, body_position())

## One frame of the far guard's walk away (`RoadblockFarGuard.walk_off()`), by the way his partner
## walks off.
func walk_the_far_guard_off(delta: float) -> void:
	_far.walk_off(delta, _its_departure())

## Where the far guard's feet are while he walks away, in world space; `Vector2.INF` while he stands
## at his post, and once he is gone.
func where_the_far_guard_walks() -> Vector2:
	return _far.where_he_walks()

## Which way the far guard faces as he walks.
func which_way_the_far_guard_walks() -> Vector2:
	return _far.which_way_he_walks()

## How far the far guard has walked, the stride his picture bobs on.
func how_far_the_far_guard_has_walked() -> float:
	return _far.how_far_he_has_walked()

## The sides of the band a guard still stands posted at: every side its row names but the side of
## the one who set off, and none once the guard at the far post has left. What its look posts a man
## at each time it draws the band.
func sides_still_posted() -> Array[int]:
	var sides: Array[int] = []
	if _far.has_left():
		return sides
	for side: int in _row.guard_sides:
		if side != _chaser_side:
			sides.append(side)
	return sides

## **The guard is gone for good** (azure-puffin #664): a chase that ended sent him away, and once he
## is out of the picture the event goes back to being the barrier, its body and its picture where
## they were built and the post he left empty. Nothing appears and nothing disappears.
func stand_as_the_barrier() -> void:
	_figure.be_only_its_barrier()
	_its_departure().reset()
	_figure.arrive_at(_body_left_at)
	keep_the_body()
	_figure.appear_where_it_stands()

## **Streamed in after its guard was spent**: only the barrier, at the place the plan stands,
## waiting and solid, with the post `side` left empty and the far guard gone with his partner.
## Nothing is reported again: its charge, and the warning before it, were counted before it streamed
## out and are over, its end at the day's end included.
func come_back_as_the_barrier(side: int) -> void:
	_figure.be_only_its_barrier()
	# The walk off he was on when it streamed out is over with him, as `stand_as_the_barrier()`'s.
	_its_departure().reset()
	_chaser_side = side
	_far.went_with_his_partner()
	_body_left_at = _figure.place()
	_figure.charge_ended()
	keep_the_body()

## Its guard spent, or on his way out from the barrier, and the side he left: only then is there
## anything to carry.
##
## Overrides EventBehaviour.save.
func save() -> Dictionary:
	if not is_spent():
		return {}
	return {"spent": true, "side": _chaser_side}

## Overrides EventBehaviour.restore.
func restore(state: Dictionary) -> void:
	if bool(state.get("spent", false)):
		come_back_as_the_barrier(int(state.get("side", 0)))
