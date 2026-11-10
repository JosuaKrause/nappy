class_name EventBody
extends RefCounted
## **What a live event is on the ground**: its collision body, the tiles that body is recorded on,
## the axis it lies along on the street it landed on, the side a vehicle standing still shows, and
## whether a boom's body follows its arm. A part the live event holds (`EventInstance`) and answers
## its outward questions about its body through (`is_solid()`, `runs_vertically()`,
## `stands_side_on()`, `solid_axis()`, `solid_part_centres()`, `solid_part_shapes()`).
##
## **It is handed what never changes under it** (its row, the map, where she is, the node its
## collision body stands under, and how it lies where it landed) and **tells nothing upward**: the
## event asks it, and tells it what happened (it came into the world, it started, its arm moved, its
## guard left it), handing it what changes with each call (where the event stands, which way it
## heads, whether the arm is up). Until the row is written as its parts it asks the row under the
## body part's names (`EventDef.has_a_body()`, `solid_from()`, `body_pieces()` and the rest).
##
## **The body and the day's blocked record are one solid read twice**: the body is built from the
## row's solid footprint (`EventFootprints.solid_footprint_of()`), and the tiles it is recorded on
## are the record's own (`EventSpawner.obstructed_footprint()`), so the body that stops her and the
## tiles that stop every other mover cannot disagree.

## Its row: its pieces, when it is solid, whether it parks.
var _row: EventDef
## The map it stands on, which the tiles of its body are recorded on.
var _map: WorldMap
## Where she is (`WhereSheIs`): a body never goes down around her.
var _where: WhereSheIs
## The node its collision body is a child of, so the body travels with a mobile event and
## disappears with it: the live event itself.
var _holder: Node2D
## Whether it lies down the screen rather than across it, decided once from the street it landed on
## (`EventInstance._spread_is_vertical()`): never a per-row field, since two rows on the same street
## face the same way for the same reason, and a row that had to say so itself could disagree with
## the street it was actually placed on.
var _spread_vertical := false
## Whether a vehicle standing still shows its side (`EventFootprints.stands_side_on()`): the moving
## van stands along its street while the burnt car lies across it; a junction, off-street ground or
## open ground follows its facing.
var _stationary_vehicle_side := true
## The collision body `go_down()` made, or null before it is down and after it was dropped.
var _obstruction: StaticBody2D
## The tiles of its body, and where the body stood when they were worked out (`tiles_at()`).
var _own_tiles := {}
var _own_tiles_at := Vector2.INF
## What `follow_the_arm()` last set a boom's shapes to, so a boom standing still in either position
## costs a comparison rather than a deferred call a frame.
var _arm_was_open := false

## Handed, as its event is set up, its row, the map, where she is, the node its collision body
## stands under, where it landed (`at`), the way it was sited facing (`face`), and whether the
## street it landed on runs it down the screen (`vertical`).
func _init(row: EventDef, map: WorldMap, where: WhereSheIs, holder: Node2D, at: Vector2,
		face: Vector2, vertical: bool) -> void:
	_row = row
	_map = map
	_where = where
	_holder = holder
	land_at(at, face, vertical)

# ------------------------------------------------------------------ questions ---

## Whether a crowd walker goes round its figure while it stands still, as round an object or a
## vehicle, rather than through it, as through a person or an animal (`EventDef.is_walked_round()`).
func is_walked_round() -> bool:
	return _row.is_walked_round()

## Whether its figure parks once it stands (`EventDef.parks()`): a crowd car behind it turns round.
func parks() -> bool:
	return _row.parks()

## Whether it has parked from the start: a figure that parks and never moves.
func has_parked_from_the_start() -> bool:
	return _row.parks() and not _row.moves()

## Whether its spread runs down the screen rather than across it.
func runs_vertically() -> bool:
	return _spread_vertical

## Whether a vehicle standing still shows its side rather than its end.
func stands_side_on() -> bool:
	return _stationary_vehicle_side

## The ground-plane direction a spread lies along: down the screen on an east-west street, across
## it otherwise.
func spread_axis() -> Vector2:
	return Vector2.DOWN if _spread_vertical else Vector2.RIGHT

## A point `offset` along the axis it spreads on (`spread_axis()`), from its own centre.
func spread_at(offset: float) -> Vector2:
	return Vector2(0.0, offset) if _spread_vertical else Vector2(offset, 0.0)

## The ground-plane direction its body's spine lies along when it heads along `heading`
## (`EventFootprints.solid_axis_of()`): its heading for a car that drives, its street's axis for a
## spread, the side it shows for a vehicle standing still.
func solid_axis(heading: Vector2) -> Vector2:
	return EventFootprints.solid_axis_of(_row, heading, _spread_vertical, _stationary_vehicle_side)

## Whether its collision body is in place: put down and not dropped since, whatever a boom's arm
## is doing.
func is_in_place() -> bool:
	return _obstruction != null

## **Whether it is solid right now**: its body is down, and it is not a boom whose arm is up
## (`arm_is_up`).
func is_solid(arm_is_up: bool) -> bool:
	return _obstruction != null and not (_row.is_a_boom() and arm_is_up)

## Whether its body is still to come down once it starts (`EventDef.SolidWhen.ONCE_IT_STARTS`).
func waits_to_come_down() -> bool:
	return _obstruction == null and _row.solid_from() == EventDef.SolidWhen.ONCE_IT_STARTS

## Where each of its solid pieces stands, in world space, for a body whose centre stands at `at`:
## paired index for index with `solid_part_shapes()`.
##
## **A per-tile solid record reads the same pieces, index for index.**
## `EventSpawner.obstructed_footprint()` steps the row's pieces on its own rather than calling this
## pair, but it is the same data: one piece for every row but the crash, which records tiles under
## each car and leaves the ground between them open, the whole reason the crowd steps round the
## cars and walks the debris.
func solid_part_centres(at: Vector2) -> PackedVector2Array:
	var centres := PackedVector2Array()
	for piece in _row.body_pieces():
		centres.append(at + spread_at(piece.offset_for(_spread_vertical)))
	return centres

## The `GroundShape` of each solid piece, index for index with `solid_part_centres()`. Each lies
## along `solid_axis()`, the axis its collision shape and its shadow are turned by.
func solid_part_shapes() -> Array[GroundShape]:
	var shapes: Array[GroundShape] = []
	for piece in _row.body_pieces():
		shapes.append(piece.ground_shape())
	return shapes

## The tiles its body is recorded on (`EventSpawner.obstructed_footprint()`) for a body standing at
## `at` and heading along `heading`, as a set; empty for a row with no body. Worked out once for
## each place the body stands.
func tiles_at(at: Vector2, heading: Vector2) -> Dictionary:
	if _own_tiles_at != at:
		_own_tiles_at = at
		_own_tiles.clear()
		for tile in EventSpawner.obstructed_footprint(_map, _row, at, heading):
			_own_tiles[tile] = true
	return _own_tiles

# ------------------------------------------------------------- what happened ---

## **It landed at `at`**, sited facing `face`, on ground whose street runs it down the screen
## (`vertical`) or not: how it lies there (its spread's axis, the side a vehicle standing still
## shows) is decided from that ground, as it is set up and again when it is moved to other ground.
func land_at(at: Vector2, face: Vector2, vertical: bool) -> void:
	_spread_vertical = vertical
	_stationary_vehicle_side = EventFootprints.stands_side_on(_row, _map, at, face)

## It came into the world heading along `heading`: a body solid from its first frame goes down.
## A row solid once it starts (`EventDef.SolidWhen.ONCE_IT_STARTS`) waits for that
## (`come_down_clear_of_her()`).
func come_into_the_world(heading: Vector2) -> void:
	if _row.has_a_body() and _row.solid_from() != EventDef.SolidWhen.ONCE_IT_STARTS:
		go_down(heading)

## **Its body goes down now**, lying along `heading`'s axis (`solid_axis()`).
##
## **Built from the row's solid footprint** (`EventFootprints.solid_footprint_of()`), the one the
## day's blocked record is written from too (`EventSpawner.obstructed_footprint()`). One
## `StaticBody2D` holds every piece, so nothing downstream (the debug view's bounding-box layer,
## which walks the physics tree, or `is_solid()`) has to learn that a row may have more than one.
func go_down(heading: Vector2) -> void:
	var body := EventFootprints.solid_footprint_of(_row, solid_axis(heading), _spread_vertical).body()
	_holder.add_child(body)
	_obstruction = body

## **It started, standing at `at` and heading along `heading`**: a body that waits to come down once
## it starts (`waits_to_come_down()`) goes down now, **unless she is standing in it**, in which case
## it stays passable until she is out of it.
##
## Her centre comes to rest `EventDef.solid_reach()` + `Tuning.PLAYER_BODY_RADIUS` from the middle
## of a body, so that distance is exactly "inside it": closing at any point nearer would put a wall
## around her rather than in front of her, and the only ways out of one are teleporting her or
## deleting the body again, which are a repair and an admission respectively. Deferring costs
## nothing and can only leave ground reachable that would otherwise have been closed.
##
## Where she is (`WhereSheIs.at()`) is `Vector2.INF` until something tells the event, and an
## infinite distance is outside every footprint, so a rig with no player in it gets the body at once
## rather than never.
func come_down_clear_of_her(at: Vector2, heading: Vector2) -> void:
	if not waits_to_come_down():
		return
	if at.distance_to(_where.at()) <= _row.solid_reach() + Tuning.PLAYER_BODY_RADIUS:
		return
	go_down(heading)

## **A boom's body follows its arm** (`arm_is_up`): solid while it is down, not while it is up. The
## shapes are switched rather than the body freed and rebuilt, so nothing that holds the body (the
## debug view's bounding-box layer) ever sees it vanish; nothing for any other row.
##
## **It never comes down on her, and that is `Crowd`'s half, not this one's.** The arm is the one
## fact both halves read, and `Crowd._stop_for_gates()` does not lower it while she is under it, so
## the body cannot go down around her: following the arm is enough. Deferred, because the switch
## can land while the physics server is mid-query.
func follow_the_arm(arm_is_up: bool) -> void:
	if not _row.is_a_boom() or _obstruction == null:
		return
	if arm_is_up == _arm_was_open:
		return
	_arm_was_open = arm_is_up
	for child in _obstruction.get_children():
		var collision := child as CollisionShape2D
		if collision:
			collision.set_deferred("disabled", arm_is_up)

## Its body is taken away: a pursuer that had one stops being a wall once it moves.
func drop() -> void:
	_obstruction.queue_free()
	_obstruction = null

## Its body is held at `at`, in world space, wherever its event moves; nothing before it is down.
func pin_at(at: Vector2) -> void:
	if _obstruction:
		_obstruction.global_position = at

## Its body is under its event's own feet again, and moves with it; nothing before it is down.
func unpin() -> void:
	if _obstruction:
		_obstruction.position = Vector2.ZERO

## Its body's shapes are turned to `angle`, in radians, as a car's spine follows its heading;
## nothing before it is down.
func turn_to(angle: float) -> void:
	if _obstruction == null:
		return
	for child in _obstruction.get_children():
		var collision := child as CollisionShape2D
		if collision and not is_equal_approx(collision.rotation, angle):
			collision.rotation = angle
