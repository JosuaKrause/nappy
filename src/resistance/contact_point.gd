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

var step: ResistanceSteps.Step
var is_done := false

var _player: Stroller
var _pulse := 0.0
## Set only for a perform step: the instance this contact rides on, and the fixed offset
## from it — drawn once, in a direction the day's own RNG chose, so a contact that has to
## clear an obstruction sits at a learnable spot rather than a re-rolled one.
var _rider: EventInstance
var _rider_offset := Vector2.ZERO

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
	if global_position.distance_to(_player.global_position) <= REACH:
		_complete()
	queue_redraw()

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
	_draw_chalk(Palette.CHALK_DONE if is_done else Palette.CHALK)

## Three strokes and a circle — the sort of mark you would walk past a hundred times.
func _draw_chalk(colour: Color) -> void:
	var flicker := colour
	flicker.a *= 0.75 + 0.25 * sin(_pulse * 2.0)
	draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 20, flicker, 2.0)
	draw_line(Vector2(-7.0, 4.0), Vector2(7.0, -5.0), flicker, 2.0)
	draw_line(Vector2(-6.0, -5.0), Vector2(2.0, 6.0), flicker, 2.0)
