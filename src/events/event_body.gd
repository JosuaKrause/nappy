class_name EventBody
extends RefCounted
## **What a live event is on the ground**: its collision body, the tiles that body is recorded on,
## the axis it lies along on the street it landed on, the side a vehicle standing still shows, and
## whether a boom's body follows its arm. A part the live event holds (`EventInstance`) and answers
## its outward questions about its body through (`is_solid()`, `runs_vertically()`,
## `stands_side_on()`, `solid_axis()`, `standing_pieces()`).
##
## **It is handed what never changes under it** (its row, the row's body part, where she is, the
## node its collision body stands under, how it stands where it landed, and the boom state its
## arm is) and **tells nothing upward**: the event asks it, and tells it what happened (it came
## into the world, it started, its arm moved, its guard left it, it landed on other ground),
## handing it what changes with each call (where the event stands, which way it heads). How it
## stands is a `BodyStance` the event derives once and hands it, and hands it again when it
## lands somewhere else (`land_at()`). Until the row is written as its parts it asks the row
## under the row's body part (`BodySpec`) for everything it says about the body.
##
## **The body and the day's blocked record are one solid read twice**: the body is built from
## the row's solid footprint (`EventFootprints.solid_footprint_of()`), and the tiles it is
## recorded on are the record's own (`EventSpawner.footprint_of()`), each laid out by the one
## `BodyStance`, so the body that stops her and the tiles that stop every other mover cannot
## disagree.

## Its row, for the three things that span the body and what else the row is (whether it moves,
## whether it drives, and the day's blocked record).
var _row: EventDef
## What it is on the ground: its pieces, when it is solid, what a walker takes it for, whether it
## parks, how it lies.
var _body: BodySpec
## Where she is (`WhereSheIs`): a body never goes down around her.
var _where: WhereSheIs
## The node its collision body is a child of, so the body travels with a mobile event and
## disappears with it: the live event itself.
var _holder: Node2D
## How it stands on the street it landed on: where, which way it lies, the side a vehicle
## standing still shows, its pieces. Handed in as the event is set up and again when it lands
## elsewhere.
var _stance: BodyStance
## The collision body `go_down()` made, or null before it is down and after it was dropped.
var _obstruction: StaticBody2D
## The tiles of its body for the stance it holds (`tiles()`), worked out the first time they are
## asked for, and again after it lands elsewhere.
var _own_tiles := {}
var _own_tiles_are_worked_out := false
## What `follow_the_arm()` last set a boom's shapes to, so a boom standing still in either position
## costs a comparison rather than a deferred call a frame.
var _arm_was_open := false
## The boom state a boom's arm is, shared with `Crowd` (`GateState`), which only the
## crowd writes; null for every row but a street door's boom, and read as lowered then.
var _gate: GateState

## Handed, as its event is set up, its row, the row's body, where she is, the node its collision
## body stands under, how it stands where it landed (`stance`), and the boom state its arm is
## (`gate`).
func _init(row: EventDef, body: BodySpec, where: WhereSheIs, holder: Node2D, stance: BodyStance,
		gate: GateState = null) -> void:
	_gate = gate
	_row = row
	_body = body
	_where = where
	_holder = holder
	land_at(stance)

# ------------------------------------------------------------------ questions ---

## Whether a crowd walker goes round its figure while it stands still, as round an object or a
## vehicle, rather than through it, as through a person or an animal (`BodySpec.is_walked_round()`).
func is_walked_round() -> bool:
	return _body.is_walked_round()

## Whether its figure parks once it stands (`BodySpec.parks()`): a crowd car behind it turns round.
func parks() -> bool:
	return _body.parks()

## Whether it has parked from the start: a figure that parks and never moves.
func has_parked_from_the_start() -> bool:
	return _body.parks() and not _row.moves()

## Whether its spread runs down the screen rather than across it.
func runs_vertically() -> bool:
	return _stance.lies_vertically()

## Whether a vehicle standing still shows its side rather than its end.
func stands_side_on() -> bool:
	return _stance.stands_side_on()

## How it stands on the street it landed on (`BodyStance`), for what is handed it on: its look,
## its footprint.
func stance() -> BodyStance:
	return _stance

## The ground-plane direction a spread lies along: down the screen on an east-west street, across
## it otherwise.
func spread_axis() -> Vector2:
	return Vector2.DOWN if _stance.lies_vertically() else Vector2.RIGHT

## A point `offset` along the axis it spreads on (`spread_axis()`), from its own centre.
func spread_at(offset: float) -> Vector2:
	return Vector2(0.0, offset) if _stance.lies_vertically() else Vector2(offset, 0.0)

## The ground-plane direction its body's spine lies along when it heads along `heading`
## (`BodyStance.spine_along()`): its heading for a car that drives, its street's axis for a
## spread, the side it shows for a vehicle standing still.
func solid_axis(heading: Vector2) -> Vector2:
	return _stance.spine_along(heading)

## Whether its collision body is in place: put down and not dropped since, whatever a boom's arm
## is doing.
func is_in_place() -> bool:
	return _obstruction != null

## **Whether it is solid right now**: its body is down, and it is not a boom whose arm is up.
func is_solid() -> bool:
	return _obstruction != null and not (_body.is_a_boom() and _arm_is_up())

## Whether its boom's arm is up: its gate's state, lowered with none.
func _arm_is_up() -> bool:
	return _gate != null and _gate.is_boom_up()

## Whether its body is still to come down once it starts (`BodySpec.SolidWhen.ONCE_IT_STARTS`).
func waits_to_come_down() -> bool:
	return _obstruction == null and _body.solid_from() == BodySpec.SolidWhen.ONCE_IT_STARTS

## **Its solid pieces where they stand**, in world space, for a body whose centre stands at `at` and
## which heads along `heading`: each piece's middle offset along its street's axis, its ground shape
## and the axis its spine lies along (`solid_axis()`, the axis its collision shape and its shadow are
## turned by). The one layout of a body's pieces, `BodyStance.pieces_at()`, which the walk's
## ground, the map's record of standing bodies and the route rig read as well: one piece for every
## row but the crash, which stands a piece under each car and leaves the ground between them open, the
## whole reason the crowd steps round the cars and walks the debris.
func standing_pieces(at: Vector2, heading: Vector2) -> Array[StandingPiece]:
	return _stance.pieces_at(at, heading)

## The tiles its body is recorded on (`EventSpawner.footprint_of()`) where it stands, as a set;
## empty for a row the record leaves out. Worked out once for each stance it holds.
func tiles() -> Dictionary:
	if not _own_tiles_are_worked_out:
		_own_tiles.clear()
		for tile in EventSpawner.footprint_of(_stance):
			_own_tiles[tile] = true
		_own_tiles_are_worked_out = true
	return _own_tiles

# ------------------------------------------------------------- what happened ---

## **It landed standing as `stance` says**: how it lies there (its spread's axis, the side a
## vehicle standing still shows) was decided from that ground when the stance was made, as it is
## set up and again when it is moved to other ground.
func land_at(stance: BodyStance) -> void:
	_stance = stance
	_own_tiles_are_worked_out = false

## It came into the world heading along `heading`: a body solid from its first frame goes down.
## A row solid once it starts (`BodySpec.SolidWhen.ONCE_IT_STARTS`) waits for that
## (`come_down_clear_of_her()`).
func come_into_the_world(heading: Vector2) -> void:
	if _body.has_a_body() and _body.solid_from() != BodySpec.SolidWhen.ONCE_IT_STARTS:
		go_down(heading)

## **Its body goes down now**, lying along `heading`'s axis (`solid_axis()`).
##
## **Built from the row's solid footprint** (`EventFootprints.solid_footprint_of()`), laid out by the
## `BodyStance` layout the day's blocked record is written from too
## (`EventSpawner.footprint_of()`). One
## `StaticBody2D` holds every piece, so nothing downstream (the debug view's bounding-box layer,
## which walks the physics tree, or `is_solid()`) has to learn that a row may have more than one.
func go_down(heading: Vector2) -> void:
	var collision := EventFootprints.solid_footprint_of(_stance, heading).body()
	_holder.add_child(collision)
	_obstruction = collision

## **It started, standing at `at` and heading along `heading`**: a body that waits to come down once
## it starts (`waits_to_come_down()`) goes down now, **unless she is standing in it**, in which case
## it stays passable until she is out of it.
##
## Her centre comes to rest `BodySpec.solid_reach()` + `Tuning.PLAYER_BODY_RADIUS` from the middle
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
	if at.distance_to(_where.at()) <= _body.solid_reach() + Tuning.PLAYER_BODY_RADIUS:
		return
	go_down(heading)

## **A boom's body follows its arm**: solid while it is down, not while it is up. The
## shapes are switched rather than the body freed and rebuilt, so nothing that holds the body (the
## debug view's bounding-box layer) ever sees it vanish; nothing for any other row.
##
## **It never comes down on her, and that is `Crowd`'s half, not this one's.** The arm is the one
## fact both halves read, and `Crowd._stop_for_gates()` does not lower it while she is under it, so
## the body cannot go down around her: following the arm is enough. Deferred, because the switch
## can land while the physics server is mid-query.
func follow_the_arm() -> void:
	if not _body.is_a_boom() or _obstruction == null:
		return
	var arm_is_up := _arm_is_up()
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
