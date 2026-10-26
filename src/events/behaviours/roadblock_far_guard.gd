class_name RoadblockFarGuard
extends RefCounted
## **The guard at a roadblock's far post, once his partner walks away** (`EventBarrierPost`). He
## sets off the frame his partner starts walking away, at the pace his partner leaves at
## (`EventDef.chase_speed()`, `EventDeparture.speed()`'s for a guard leaving his barrier), standing
## as he walks, over walkable ground by the way his partner walks (`EventDeparture.way_out_from()`,
## planned again from where he is each time it runs out while she could still be watching; away
## from her by `Navigator.step()` only where it finds none), and he is gone once she could not be
## watching: past `Tuning.OUT_OF_SIGHT` from her, or after `EventDeparture.LEAVING_GIVES_UP` with no
## player to be out of sight of — the sight rule his partner's departure keeps. He notices nothing,
## chases nothing and costs nothing: the band is silent from the same frame.
##
## **His own node** (`RoadblockLook.FarGuard`), in the world's entity layer like the band's, so he
## sorts at his own feet as he walks rather than at the band's line. Not carried across a
## stream-out: a band streamed back in after its guard was spent comes back with neither
## (`EventBarrierPost.come_back_as_the_barrier()`).

## The event whose band he guards.
var event: EventInstance
## Where his feet are while he walks away, in world space; `Vector2.INF` while he stands at his
## post, and once he is gone.
var at := Vector2.INF
## Which way he faces as he walks.
var heading := Vector2.ZERO
## How far he has walked, the stride his picture bobs on.
var walked := 0.0
## How long he has been walking.
var walking_for := 0.0
## Whether he is gone for good, or there was never a far post to leave.
var gone := false
## The way he walks, tile centres, each dropped as he reaches it; planned from where he stands
## whenever it is empty.
var way := PackedVector2Array()
## His node while he walks.
var node: RoadblockLook.FarGuard

func _init(owner: EventInstance) -> void:
	event = owner

## Whether he has left his post, walking or gone.
func has_left() -> bool:
	return at != Vector2.INF or gone

## Sends him off from his post on `side`, or marks him gone where there is no far post (`side` 0).
func send_off(side: int) -> void:
	if has_left():
		return
	if side == 0:
		gone = true
		return
	var vertical: bool = event._spread_vertical
	at = event.body_position() + EventInstance.guard_post_offset(vertical, side)
	heading = EventInstance.guard_post_heading(vertical, side)
	var her: Vector2 = event.player_at
	if her != Vector2.INF and not her.is_equal_approx(at):
		heading = (at - her).normalized()
	walked = 0.0
	walking_for = 0.0
	way = PackedVector2Array()
	node = RoadblockLook.FarGuard.new()
	node.instance = event
	node.name = "FarGuard"
	node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if event.is_inside_tree() and event.get_parent() != null:
		event.add_beside_it(node)
	move_node()

## One frame of his walk away, and his end once she could not be watching.
func walk_off(delta: float) -> void:
	if at == Vector2.INF:
		return
	var her: Vector2 = event.player_at
	var step: float = event.def.chase_speed() * delta
	var left := step
	if her != Vector2.INF:
		if way.is_empty():
			way = event.departure.way_out_from(at)
		var walk: Navigator.Walked = event._navigator.walk(at, way, left, event._mover)
		if walk.heading != Vector2.ZERO:
			heading = walk.heading
		at = walk.at
		way = PackedVector2Array() if walk.stopped else walk.points
		left = walk.left
	if left > 0.0:
		var away := heading
		if her != Vector2.INF and not her.is_equal_approx(at):
			away = (at - her).normalized()
		var moved: Vector2 = event._navigator.step(at, away * left, event._mover)
		if event.departure.avoids().has_point(event._map.world_to_tile(at + moved)):
			moved = Vector2.ZERO
		if not moved.is_zero_approx():
			heading = moved.normalized()
			at += moved
	walked += step
	walking_for += delta
	var out_of_sight := her != Vector2.INF and at.distance_to(her) > Tuning.OUT_OF_SIGHT
	if out_of_sight or (her == Vector2.INF and walking_for >= EventDeparture.LEAVING_GIVES_UP):
		at = Vector2.INF
		gone = true
		release()
		return
	move_node()

## Keeps his node at his feet, shown while the event is, and redrawn.
func move_node() -> void:
	if node == null or not node.is_inside_tree():
		return
	node.global_position = at
	node.visible = not (event.skip_draw or event.is_finished
			or event.is_suppressed_by_its_own_hold())
	node.queue_redraw()

## Frees his node.
func release() -> void:
	if node != null and is_instance_valid(node):
		node.queue_free()
	node = null
