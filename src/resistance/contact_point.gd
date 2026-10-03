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
## How close she must be for this contact's touch to complete: `REACH` for a bare point with no
## size of its own (a chalk mark), `ResistanceDirector.DOOR_REACH` for a door on a facade (day 8's,
## the last night's), the mast's body reach on day 11 — and how far out the guard's band is worked
## from for all of them (`ResistanceDirector._maybe_set_a_trap()`).
var reach := REACH
## Non-zero for a touch that is an area on the ground rather than a circle: the semi-axes of an
## ellipse centred on this contact, which her body has to overlap — day 12's swing, whose base it
## is (`ResistanceDirector.SWING_BASE`).
var touch_ellipse := Vector2.ZERO
## True for a task completed by doing something rather than by being near a place — day 9's
## crossing, which `ResistanceDirector` completes (`complete_now()`) the moment she is through the
## named district door. No distance completes it, however near she stands.
var by_crossing := false

var _player: Stroller
var _pulse := 0.0
## Set only for a perform step: the instance this contact rides on. The contact stands on it —
## where the task is, and where the red arrow ends — and follows it.
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

## A perform: the contact follows `instance`, standing `offset` from it — zero for every task, so
## it stands on the thing itself.
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
	if would_complete_at(_player.global_position):
		_complete()
	queue_redraw()

## Whether her standing at `her` completes this contact — the one question `_physics_process()`
## asks, pure, so a test or a sweep can ask it of any point:
##
## - **a crossing** (`by_crossing`, day 9) never completes on where she stands;
## - **day 6's note** (`ResistanceSteps.Step.completes_at_inner_radius`) completes within the man's
##   own `inner_radius` (45px) — M205: "the moment the player touches the inner circle it counts as
##   delivered";
## - **a rider with a body** (the van, a roadblock) completes from any side of it
##   (`touches_the_body()`);
## - **an area on the ground** (`touch_ellipse`, the swing's base) completes the moment her body
##   overlaps it (`overlaps_the_ellipse()`);
## - anything else within `reach` of this contact.
func would_complete_at(her: Vector2) -> bool:
	if by_crossing:
		return false
	if _rider and step and step.completes_at_inner_radius:
		return global_position.distance_to(her) <= _rider.def.inner_radius
	if _rider and has_a_body(_rider):
		return touches_the_body(_rider, her, REACH)
	if touch_ellipse != Vector2.ZERO:
		return overlaps_the_ellipse(global_position, touch_ellipse, her)
	return global_position.distance_to(her) <= reach

## Completes a task that is done by an action rather than a place (`by_crossing`) — the director's
## call the moment she has crossed. Nothing once it is done.
func complete_now() -> void:
	if not is_done:
		_complete()

## Whether her body — a disc of `Tuning.PLAYER_BODY_RADIUS` round `her` — overlaps the ground ellipse
## round `centre` with semi-axes `semi`: her centre inside it, or within her body of its outline,
## measured against `ELLIPSE_SAMPLES` points of the outline.
static func overlaps_the_ellipse(centre: Vector2, semi: Vector2, her: Vector2) -> bool:
	var local := her - centre
	if semi.x <= 0.0 or semi.y <= 0.0:
		return false
	if (local.x * local.x) / (semi.x * semi.x) + (local.y * local.y) / (semi.y * semi.y) <= 1.0:
		return true
	for i in ELLIPSE_SAMPLES:
		var angle := TAU * float(i) / float(ELLIPSE_SAMPLES)
		if local.distance_to(Vector2(cos(angle) * semi.x, sin(angle) * semi.y)) \
				<= Tuning.PLAYER_BODY_RADIUS:
			return true
	return false

## How finely `overlaps_the_ellipse()` walks the outline: 96 points round a 22px ellipse are under
## 1.5px apart, so the overlap it answers is the true one to within a pixel.
const ELLIPSE_SAMPLES := 96

## Whether `instance` has a solid body she is stopped by — the van, a roadblock — rather than being
## a figure she walks up to (the man shouting, the neighbor) or a bodiless scar.
static func has_a_body(instance: EventInstance) -> bool:
	return instance != null and instance.def.solid_reach() > 0.0

## How far from `instance`'s own centre a touch of its body counts: its furthest reach
## (`EventDef.solid_reach()`) plus her own body (`Tuning.PLAYER_BODY_RADIUS`) plus `within` — 72px
## for the van (22 + 14 + 36), 110px for a roadblock's band (60 + 14 + 36). One circle round the
## body's centre rather than a band round its outline, so it reaches past the body by at least
## `within` on every side, its ends included, and is the same circle an any-instance task already
## retargeted onto a look-alike from (`ResistanceDirector._reach_distance()`).
static func body_reach(instance: EventInstance, within := REACH) -> float:
	return instance.def.solid_reach() + Tuning.PLAYER_BODY_RADIUS + within

## **Touching a task's body from any side completes it** (feathery-marmot: *"the arrow correctly
## points to the van but touching the van doesn't solve the task"*): her centre within
## `body_reach()` of where the body stands (`EventInstance.body_position()`, which a roadblock's
## guard leaves behind when he sets off), wherever round it she is, rather than within `reach` of
## the one point beside it the day's RNG chose. Pressed against the body she is at most its
## furthest reach plus her own body from its centre, `within` inside the circle, so she completes
## before she can touch it on every side.
static func touches_the_body(instance: EventInstance, at: Vector2, within := REACH) -> bool:
	return at.distance_to(instance.body_position()) <= body_reach(instance, within)

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
