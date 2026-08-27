class_name Stroller
extends CharacterBody2D
## The mother-and-pram rig the player drives.
##
## `position` is the mother's feet on the ground plane; everything is drawn upward from
## there so that y-sorting against buildings and props matches where she actually stands.
## The pram is drawn as an offset in the facing direction, foreshortened on Y to sell the
## oblique view (docs/CITY.md, "Rendering").

## How far ahead of the mother the pram sits, on the ground plane.
const PRAM_DISTANCE := 34.0
## Vertical squash applied to ground-plane offsets, i.e. the obliqueness of the view.
const OBLIQUE_Y := 0.7
## Radians per second the rig turns to face a new input direction.
const FACING_TURN_SPEED := 12.0
## How far the camera leads the player, in px.
const CAMERA_LOOK_AHEAD := 46.0

## Two frames per direction: mid-stride, then feet passing.
const MOTHER_FRONT: Array[Texture2D] = [
	preload("res://assets/rig/mother_front_a.svg"),
	preload("res://assets/rig/mother_front_b.svg"),
]
const MOTHER_BACK: Array[Texture2D] = [
	preload("res://assets/rig/mother_back_a.svg"),
	preload("res://assets/rig/mother_back_b.svg"),
]
const MOTHER_SIDE: Array[Texture2D] = [
	preload("res://assets/rig/mother_side_a.svg"),
	preload("res://assets/rig/mother_side_b.svg"),
]
const PRAM_SIDE := preload("res://assets/rig/pram_side.svg")
const PRAM_FRONT := preload("res://assets/rig/pram_front.svg")
const PRAM_BACK := preload("res://assets/rig/pram_back.svg")
const ALERT := preload("res://assets/props/alert.svg")

## How far above her head the warning mark floats, and how fast it flashes. She is 46px tall,
## so this clears her head by a few pixels and no more: at 68 the mark drifted far enough up
## the screen to read as belonging to whatever was standing behind her, which for a cue that
## means "this is about *you*" is the one thing it must not do.
const ALERT_HEIGHT := 54.0
const ALERT_FLASHES_PER_SECOND := 4.0

@onready var _camera: Camera2D = $Camera2D

var facing := Vector2.DOWN
var _walk_phase := 0.0
## Deflection from being walked into, decaying like any other velocity. Kept apart from
## `velocity` so an input frame cannot quietly erase it.
var _shove := Vector2.ZERO
## Set by `Crowd` while something lethal is closing on where she is standing.
var _alert := false
var _alert_phase := 0.0

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var top_speed := Tuning.RUN_SPEED if Input.is_action_pressed("run") else Tuning.WALK_SPEED

	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * top_speed, Tuning.ACCELERATION * delta)
		_turn_toward(input_dir.normalized(), delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, Tuning.FRICTION * delta)

	move_and_slide()

	# The deflection is moved separately rather than added to `velocity`, which stays what she
	# is steering. Folding it in would have made `is_idle()` and `run_excess_ratio()` — the two
	# questions the baby asks the rig — answer for the crowd rather than for the player.
	if _shove != Vector2.ZERO:
		move_and_collide(_shove * delta)
		_shove = _shove.move_toward(Vector2.ZERO, Tuning.FRICTION * delta)

	# Stride cadence is driven by distance covered, so it stays in step at any speed.
	_walk_phase = wrapf(_walk_phase + velocity.length() * delta * 0.09, 0.0, TAU)
	_alert_phase = wrapf(_alert_phase + delta, 0.0, 1.0)
	_update_camera(delta)
	queue_redraw()

## Knocks her off her line. Called by `Crowd` when she walks into somebody: the contact
## displaces them both, which is finding 2 of playtest 02.
func shove(impulse: Vector2) -> void:
	# The strongest contact of the frame wins rather than the sum of them, or being caught
	# between two people would fire her out of the crowd.
	if impulse.length() > _shove.length():
		_shove = impulse

## Whether she is standing somewhere that is about to be dangerous.
func set_alert(on: bool) -> void:
	_alert = on

func _turn_toward(target: Vector2, delta: float) -> void:
	var step := FACING_TURN_SPEED * delta
	var diff := angle_difference(facing.angle(), target.angle())
	facing = facing.rotated(clampf(diff, -step, step)).normalized()

func _update_camera(delta: float) -> void:
	var lead := Vector2(facing.x, facing.y * OBLIQUE_Y) * CAMERA_LOOK_AHEAD
	_camera.offset = _camera.offset.lerp(lead, clampf(delta * 3.0, 0.0, 1.0))

## Puts the rig back on the doorstep at the start of a day, stopped and facing the street.
func reset_at(where: Vector2, look: Vector2 = Vector2.DOWN) -> void:
	global_position = where
	velocity = Vector2.ZERO
	facing = look.normalized()
	_walk_phase = 0.0
	_shove = Vector2.ZERO
	_alert = false
	if _camera:
		_camera.offset = Vector2.ZERO
		_camera.reset_smoothing()
	queue_redraw()

## Stops the camera from panning past the edge of the city.
func set_camera_limits(bounds: Rect2) -> void:
	_camera.limit_left = int(bounds.position.x)
	_camera.limit_top = int(bounds.position.y)
	_camera.limit_right = int(bounds.end.x)
	_camera.limit_bottom = int(bounds.end.y)

# ------------------------------------------------------------------ queries ---
# Consumed by Baby (M2) to decide how the meters move.

func current_speed() -> float:
	return velocity.length()

## True when the rig is close enough to stationary that sleepiness should drain.
func is_idle() -> bool:
	return velocity.length() < Tuning.IDLE_SPEED_THRESHOLD

## 0.0 at walking pace or below, 1.0 at a full sprint. Scales excitement from running.
func run_excess_ratio() -> float:
	var excess := velocity.length() - Tuning.WALK_SPEED
	if excess <= 0.0:
		return 0.0
	return clampf(excess / (Tuning.RUN_SPEED - Tuning.WALK_SPEED), 0.0, 1.0)

# ------------------------------------------------------------------ drawing ---

func _draw() -> void:
	var gait := clampf(velocity.length() / Tuning.WALK_SPEED, 0.0, 1.6)
	var pram_offset := Vector2(facing.x, facing.y * OBLIQUE_Y) * PRAM_DISTANCE

	# Shadows belong to the ground plane, so they always go underneath both figures.
	Sprites.draw_shadow(self, Vector2.ZERO, 9.0)
	Sprites.draw_shadow(self, pram_offset, 12.0)

	# Facing away from the viewer puts the pram further up the screen, i.e. behind her.
	if facing.y < 0.0:
		_draw_pram(pram_offset)
		_draw_mother(gait)
	else:
		_draw_mother(gait)
		_draw_pram(pram_offset)

	_draw_alert()

## *This spot is about to be bad; move.* Drawn over the player rather than over the thing
## that is coming, because "there is a car on this road" is information and "you are standing
## in front of it" is an instruction — and only the second one is a move.
##
## Flashing rather than steady: a mark that is always there stops being read, and the flash is
## also what distinguishes it from the props she walks past. M22 generalises this to events
## and adds the screen-edge half; the cue itself is built here because M19 is what makes a
## street lethal. See docs/EVENTS.md, "The visual vocabulary".
func _draw_alert() -> void:
	if not _alert or _alert_phase * ALERT_FLASHES_PER_SECOND - floorf(
			_alert_phase * ALERT_FLASHES_PER_SECOND) > 0.55:
		return
	Sprites.draw_standing(self, ALERT, Vector2(0.0, -ALERT_HEIGHT))

## The stride is two frames rather than a procedural swing: with the legs drawn into the
## sprite there is nothing left to swing. The frames carry the body's bob too, which is why
## nothing here offsets her vertically any more.
func _draw_mother(gait: float) -> void:
	var stepping := gait > 0.05 and sin(_walk_phase * 2.0) > 0.0
	var frame := 1 if stepping else 0
	var flip := false
	var texture: Texture2D
	if absf(facing.x) > absf(facing.y):
		texture = MOTHER_SIDE[frame]
		flip = facing.x < 0.0
	elif facing.y > 0.0:
		texture = MOTHER_FRONT[frame]
	else:
		texture = MOTHER_BACK[frame]
	Sprites.draw_standing(self, texture, Vector2.ZERO, Vector2.ZERO, flip)

## Three profiles rather than one drawing with the hood nudged sideways. Sliding the hood
## along a fixed basket made it overhang the end of the pram whenever she turned, which is
## what "the canopy is offset going sideways" was: the hood was drawn at the rear, but the
## basket underneath it never changed shape, so the two stopped agreeing.
func _draw_pram(at: Vector2) -> void:
	if absf(facing.x) > absf(facing.y):
		# Authored travelling east, hood at the rear; mirrored to travel west.
		Sprites.draw_standing(self, PRAM_SIDE, at, Vector2.ZERO, facing.x < 0.0)
	elif facing.y > 0.0:
		Sprites.draw_standing(self, PRAM_FRONT, at)
	else:
		Sprites.draw_standing(self, PRAM_BACK, at)
