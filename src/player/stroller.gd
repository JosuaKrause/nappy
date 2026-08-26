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

@onready var _camera: Camera2D = $Camera2D

var facing := Vector2.DOWN
var _walk_phase := 0.0

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

	# Stride cadence is driven by distance covered, so it stays in step at any speed.
	_walk_phase = wrapf(_walk_phase + velocity.length() * delta * 0.09, 0.0, TAU)
	_update_camera(delta)
	queue_redraw()

func _turn_toward(target: Vector2, delta: float) -> void:
	var step := FACING_TURN_SPEED * delta
	var diff := angle_difference(facing.angle(), target.angle())
	facing = facing.rotated(clampf(diff, -step, step)).normalized()

func _update_camera(delta: float) -> void:
	var lead := Vector2(facing.x, facing.y * OBLIQUE_Y) * CAMERA_LOOK_AHEAD
	_camera.offset = _camera.offset.lerp(lead, clampf(delta * 3.0, 0.0, 1.0))

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
	var bob := sin(_walk_phase * 2.0) * 1.4 * gait
	var pram_offset := Vector2(facing.x, facing.y * OBLIQUE_Y) * PRAM_DISTANCE

	# Shadows belong to the ground plane, so they always go underneath both figures.
	_draw_shadow(Vector2.ZERO, 9.0)
	_draw_shadow(pram_offset, 12.0)

	# Facing away from the viewer puts the pram further up the screen, i.e. behind her.
	if facing.y < 0.0:
		_draw_pram(pram_offset, bob)
		_draw_mother(Vector2.ZERO, bob, gait)
	else:
		_draw_mother(Vector2.ZERO, bob, gait)
		_draw_pram(pram_offset, bob)

func _draw_shadow(at: Vector2, radius: float) -> void:
	draw_set_transform(at, 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, radius, Palette.SHADOW)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_mother(base: Vector2, bob: float, gait: float) -> void:
	var o := base + Vector2(0.0, bob)
	var stride := sin(_walk_phase * 2.0) * 4.0 * gait

	# Legs swing in opposition; the feet stay pinned to the ground plane at base.y.
	draw_line(o + Vector2(-3.0, -14.0), base + Vector2(-3.0 + stride, 0.0), Palette.TROUSERS, 4.5)
	draw_line(o + Vector2(3.0, -14.0), base + Vector2(3.0 - stride, 0.0), Palette.TROUSERS, 4.5)
	draw_circle(base + Vector2(-3.0 + stride, 0.0), 2.4, Palette.SHOE)
	draw_circle(base + Vector2(3.0 - stride, 0.0), 2.4, Palette.SHOE)

	# Coat.
	draw_rect(Rect2(o + Vector2(-7.0, -32.0), Vector2(14.0, 19.0)), Palette.COAT)
	draw_rect(Rect2(o + Vector2(-7.0, -19.0), Vector2(14.0, 6.0)), Palette.COAT_SHADE)

	# Arms reach toward the pram handle.
	var reach := Vector2(facing.x, facing.y * OBLIQUE_Y).normalized() * 9.0
	draw_line(o + Vector2(-6.0, -28.0), o + Vector2(-4.0, -20.0) + reach, Palette.COAT, 3.5)
	draw_line(o + Vector2(6.0, -28.0), o + Vector2(4.0, -20.0) + reach, Palette.COAT, 3.5)

	# Head, then hair from whichever side we are looking at.
	var head := o + Vector2(0.0, -37.0)
	draw_circle(head, 6.5, Palette.SKIN)
	if facing.y < 0.0:
		draw_circle(head, 6.5, Palette.HAIR)
	else:
		draw_arc(head, 5.6, PI, TAU, 12, Palette.HAIR, 4.0)
		var eye := 1.6 * signf(facing.x) if absf(facing.x) > 0.3 else 0.0
		draw_circle(head + Vector2(-2.2 + eye, -0.5), 0.9, Palette.OUTLINE)
		draw_circle(head + Vector2(2.2 + eye, -0.5), 0.9, Palette.OUTLINE)

func _draw_pram(base: Vector2, bob: float) -> void:
	var o := base + Vector2(0.0, bob)

	draw_circle(base + Vector2(-7.0, -3.5), 3.8, Palette.PRAM_WHEEL)
	draw_circle(base + Vector2(7.0, -3.5), 3.8, Palette.PRAM_WHEEL)

	# Basket.
	draw_rect(Rect2(o + Vector2(-11.0, -20.0), Vector2(22.0, 12.0)), Palette.PRAM_BODY)
	draw_rect(Rect2(o + Vector2(-11.0, -11.0), Vector2(22.0, 3.0)), Palette.PRAM_TRIM)

	# The hood sits at the head end, which is the end away from the direction of travel.
	var hood_x := -6.0 * signf(facing.x) if absf(facing.x) > 0.25 else 0.0
	draw_arc(o + Vector2(hood_x, -19.0), 8.0, PI, TAU, 14, Palette.PRAM_HOOD, 5.0)

	# Facing the viewer, you can see into the pram.
	if facing.y > 0.2:
		draw_circle(o + Vector2(hood_x, -18.0), 3.2, Palette.SKIN)
