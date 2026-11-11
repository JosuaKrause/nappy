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
## What is here is his walk; he is drawn by the roadblock's look (`RoadblockLook`), on a node of his
## own in the world's entity layer, from what its barrier post asks him (`where_he_walks()`,
## `which_way_he_walks()`, `how_far_he_has_walked()`). Not carried across a stream-out: a band
## streamed back in after its guard was spent comes back with neither
## (`EventBarrierPost.come_back_as_the_barrier()`).

## The figure of the event whose band he guards (`EventInstance.Figure`), asked which way its band
## runs.
var _figure: EventInstance.Figure
## Where she is (`WhereSheIs`), as the event whose band he guards hears it.
var _where: WhereSheIs
## The roadblock's row: the pace his partner leaves at.
var _row: EventDef
## The ground he walks off over, and how he moves over it, as what he walks as.
var _map: WorldMap
var _navigator: Navigator
var _mover: Mover
## Where his feet are while he walks away, in world space; `Vector2.INF` while he stands at his
## post, and once he is gone.
var _at := Vector2.INF
## Which way he faces as he walks.
var _heading := Vector2.ZERO
## How far he has walked, the stride his picture bobs on.
var _walked := 0.0
## How long he has been walking.
var _walking_for := 0.0
## Whether he is gone for good, or there was never a far post to leave.
var _gone := false
## The way he walks, tile centres, each dropped as he reaches it; planned from where he stands
## whenever it is empty.
var _way := PackedVector2Array()

## Handed, as the barrier post he stands at is made, the figure of its event, where she is, its row,
## and the ground and how he moves over it.
func _init(figure: EventInstance.Figure, where: WhereSheIs, row: EventDef, map: WorldMap,
		navigator: Navigator, mover: Mover) -> void:
	_figure = figure
	_where = where
	_row = row
	_map = map
	_navigator = navigator
	_mover = mover

## Whether he has left his post, walking or gone.
func has_left() -> bool:
	return _at != Vector2.INF or _gone

## Where his feet are while he walks away, in world space; `Vector2.INF` while he stands at his
## post, and once he is gone.
func where_he_walks() -> Vector2:
	return _at

## Which way he faces as he walks.
func which_way_he_walks() -> Vector2:
	return _heading

## How far he has walked, the stride his picture bobs on.
func how_far_he_has_walked() -> float:
	return _walked

## Sends him off from his post on `side` of the band standing at `band`, or marks him gone where
## there is no far post (`side` 0).
func send_off(side: int, band: Vector2) -> void:
	if has_left():
		return
	if side == 0:
		_gone = true
		return
	var vertical: bool = _figure.runs_vertically()
	_at = band + EventFootprints.guard_post_offset(vertical, side)
	_heading = EventFootprints.guard_post_heading(vertical, side)
	var her: Vector2 = _where.at()
	if her != Vector2.INF and not her.is_equal_approx(_at):
		_heading = (_at - her).normalized()
	_walked = 0.0
	_walking_for = 0.0
	_way = PackedVector2Array()

## Gone with his partner, never sent off: a band streamed back in after its guard was spent
## (`EventBarrierPost.come_back_as_the_barrier()`).
func went_with_his_partner() -> void:
	_gone = true

## One frame of his walk away, by the way his partner walks off (`departure`), and his end once she
## could not be watching.
func walk_off(delta: float, departure: EventDeparture) -> void:
	if _at == Vector2.INF:
		return
	var her: Vector2 = _where.at()
	var step: float = _row.chase_speed() * delta
	var left := step
	if her != Vector2.INF:
		if _way.is_empty():
			_way = departure.way_out_from(_at)
		var walk: Navigator.Walked = _navigator.walk(_at, _way, left, _mover)
		if walk.heading != Vector2.ZERO:
			_heading = walk.heading
		_at = walk.at
		_way = PackedVector2Array() if walk.stopped else walk.points
		left = walk.left
	if left > 0.0:
		var away := _heading
		if her != Vector2.INF and not her.is_equal_approx(_at):
			away = (_at - her).normalized()
		var moved: Vector2 = _navigator.step(_at, away * left, _mover)
		if departure.avoids().has_point(_map.world_to_tile(_at + moved)):
			moved = Vector2.ZERO
		if not moved.is_zero_approx():
			_heading = moved.normalized()
			_at += moved
	_walked += step
	_walking_for += delta
	var out_of_sight := her != Vector2.INF and _at.distance_to(her) > Tuning.OUT_OF_SIGHT
	if out_of_sight or (her == Vector2.INF and _walking_for >= EventDeparture.LEAVING_GIVES_UP):
		_at = Vector2.INF
		_gone = true
