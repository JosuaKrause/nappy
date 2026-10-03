class_name ContactPoint
extends Node2D
## A place in the city where touching completes a step of the resistance subquest.
##
## Deliberately quiet: no quest marker, no arrow. A pickup is a chalk mark on the ground,
## found by walking past it, which is the only way anything in this game is found. A
## perform's contact rides on the `EventInstance` its task is built around and draws
## nothing of its own — it must look exactly like the ordinary version of the same row, or
## "several candidates to test before finding the correct one" is not actually true.

signal completed(step: int)

## How close the player must be for a touch to complete the step.
const REACH := 36.0

## The `decoration` atlas group the two pictures below are regions of — `_enter_tree()`/
## `_exit_tree()` acquire and release it, the same pairing `ClosureMarker` uses for its own
## `street_kit` group, rather than trusting `City`'s own hold on it: a `ContactPoint` built by a
## test with no `City` around it (`tests/test_resistance.gd`'s bare pickups and rides) still
## needs a region to draw, and `AtlasLibrary` reference-counts, so acquiring a group already
## resident from boot (`main.RESIDENT_GROUPS`) still costs one page load for the whole process.
const ATLAS_GROUP := &"decoration"
## The two prepared pictures a pickup draws from (`docs/GRAPHICS.md`, "M100 — Small, real, and
## nobody's").
const MARK := &"props/chalk_mark"
const MARK_TOUCHED := &"props/chalk_mark_touched"

var step: ResistanceSteps.Step
var is_done := false
## How close she must be for this contact's touch to complete: `REACH` for every contact but day
## 8's, which stands on the burnt building's door and reaches half the sidewalk in front of it
## (`ResistanceDirector.DOOR_REACH`).
var reach := REACH

var _player: Stroller
var _pulse := 0.0
## Set only for a perform step: the instance this contact rides on, and the fixed offset
## from it — drawn once, in a direction the day's own RNG chose, so a contact that has to
## clear an obstruction stands at a learnable spot rather than a re-rolled one. For a rider with a
## solid body (the van, a roadblock) that spot is only where she can stand to touch it: the touch
## itself counts from any side of the body (`touches_the_body()`).
var _rider: EventInstance
var _rider_offset := Vector2.ZERO

func _enter_tree() -> void:
	AtlasLibrary.acquire(ATLAS_GROUP)

func _exit_tree() -> void:
	AtlasLibrary.release(ATLAS_GROUP)

## A pickup: a bare chalk mark at a fixed point.
func setup(which: ResistanceSteps.Step, at: Vector2) -> void:
	step = which
	position = at
	# A mark on the ground belongs under everything that stands on it, including the
	# player who is standing on it to read it.
	z_index = -1

## A perform: the contact follows `instance`, offset so a solid body between them never
## makes it unreachable.
func ride(which: ResistanceSteps.Step, instance: EventInstance, offset: Vector2) -> void:
	step = which
	_rider = instance
	_rider_offset = offset
	position = instance.global_position + offset
	z_index = -1

## Whether the thing this rides on is still there to be touched.
func rider_alive() -> bool:
	return not _rider or (is_instance_valid(_rider) and not _rider.is_finished)

func _physics_process(delta: float) -> void:
	if is_done:
		return
	_pulse += delta
	if _rider:
		if not rider_alive():
			return
		global_position = _rider.global_position + _rider_offset
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as Stroller
		if not _player:
			return
	var distance := global_position.distance_to(_player.global_position)
	# M205, "the note costs, and the ordinary day": day 6's note (the only step with
	# `ResistanceSteps.Step.completes_at_inner_radius` set -- see that field's own doc)
	# completes the instant she is within the rider's own `inner_radius` (45px, his
	# full-strength field) rather than this contact's own `reach` (`REACH`, 36px, on every
	# step but day 8's door). `REACH` sits inside a rider's own `inner_radius`, so the generic check always landed
	# only the last few pixels of an approach; the player, offered a fork that would have
	# made her stand in this wider circle for a while first, rejected it outright: "the
	# player should stand for 2.5s? no way. the moment the player touches the inner circle
	# it counts as delivered."
	if _rider and step and step.completes_at_inner_radius:
		if distance <= _rider.def.inner_radius:
			_complete()
	elif _rider and has_a_body(_rider):
		if touches_the_body(_rider, _player.global_position, reach):
			_complete()
	elif distance <= reach:
		_complete()
	queue_redraw()

## Whether `instance` has a solid body she is stopped by — the van, a roadblock — rather than being
## a figure she walks up to (the man shouting, the neighbor) or a bodiless scar.
static func has_a_body(instance: EventInstance) -> bool:
	return instance != null and instance.def.solid_reach() > 0.0

## How far her centre at `at` stands from the nearest edge of `instance`'s own solid body: the
## smallest gap to any of its pieces (`EventInstance.solid_part_centres()`/`solid_part_shapes()`),
## each measured to its own outline along `EventInstance.solid_axis()` the way its collision shape
## and its field are, from where the body stands (`EventInstance.body_position()`, which a
## roadblock's guard leaves behind when he sets off). `PLAYER_BODY_RADIUS` (14px) when she is
## pressed against it; `INF` for an instance with no body.
static func gap_to_the_body(instance: EventInstance, at: Vector2) -> float:
	if not has_a_body(instance):
		return INF
	var axis := instance.solid_axis()
	var moved := instance.body_position() - instance.global_position
	var centres := instance.solid_part_centres()
	var shapes := instance.solid_part_shapes()
	var gap := INF
	for i in centres.size():
		var shape: GroundShape = shapes[i]
		var local := (at - (centres[i] + moved)).rotated(-axis.angle())
		gap = minf(gap, shape.distance_to_spine(local) - shape.radius)
	return gap

## **Touching a task's body from any side completes it** (feathery-marmot: *"the arrow correctly
## points to the van but touching the van doesn't solve the task"*): her own edge within `reach` of
## the body's edge — her centre within `PLAYER_BODY_RADIUS + reach` of its outline — wherever round
## it she stands, rather than within `reach` of the one point beside it the day's RNG chose. The
## same `reach` a chalk mark is touched from (`REACH`, 36px), measured from where she is stopped
## rather than from a point, so she completes the moment before she would press against it, on
## every side she can reach.
static func touches_the_body(instance: EventInstance, at: Vector2, within := REACH) -> bool:
	return gap_to_the_body(instance, at) <= Tuning.PLAYER_BODY_RADIUS + within

func _complete() -> void:
	is_done = true
	completed.emit(step.index)
	queue_redraw()

# ------------------------------------------------------------------ drawing ---

func _draw() -> void:
	# A perform's contact is invisible — it has to look exactly like the ordinary row it
	# rides on, or approaching it would already answer "is this the one".
	if _rider:
		return
	_draw_chalk()

## The chalk mark itself — `chalk_mark.svg` untouched, `chalk_mark_touched.svg` once `is_done`,
## drawn from the `decoration` atlas group exactly as prepared, centre-anchored on this node's
## own position the way the code-drawn circle and cross used to be centred on `Vector2.ZERO`.
## "A picture is an asset, never code": the mark no longer strokes an arc and two lines by
## hand, and the two prepared pictures already carry the same 11px-radius circle and cross at
## the same 32×32 scale, so nothing about its size or its reading on the pavement moves.
func _draw_chalk() -> void:
	var picture := MARK_TOUCHED if is_done else MARK
	var texture := AtlasLibrary.region(picture)
	if not texture:
		return
	var flicker := 0.75 + 0.25 * sin(_pulse * 2.0)
	draw_texture(texture, -texture.get_size() * 0.5, Color(1.0, 1.0, 1.0, flicker))
