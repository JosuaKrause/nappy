class_name ContactPoint
extends Node2D
## A place in the city where the player can hold `interact` to advance the subquest.
##
## Deliberately quiet: a chalk mark on the ground, no quest marker, no arrow. It is found
## by walking past it, which is the only way anything in this game is found.

signal completed(step: int)

## How close the player must be for the hold to count.
const REACH := 36.0
## How fast held progress unwinds when she steps away or lets go.
const DECAY_RATE := 1.6
## A patrol this close mid-handover resets the hold.
const SEEN_RADIUS := 190.0

var step: ResistanceSteps.Step
var progress := 0.0
var is_done := false
var was_seen := false

var _player: Stroller
var _events: EventManager
var _pulse := 0.0

func setup(which: ResistanceSteps.Step, at: Vector2, events: EventManager) -> void:
	step = which
	position = at
	_events = events
	# A mark on the ground belongs under everything that stands on it, including the
	# player who is standing on it to read it.
	z_index = -1

func _physics_process(delta: float) -> void:
	if is_done:
		return
	_pulse += delta
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as Stroller
		if not _player:
			return

	var within := global_position.distance_to(_player.global_position) <= REACH
	var holding := within and Input.is_action_pressed("interact")

	if holding and _patrol_is_watching():
		# Not a permanent loss — the cost is having to wait for it to pass, standing in an
		# alley, while the meter you care about does the wrong thing.
		if progress > 0.0:
			was_seen = true
			EventBus.resistance_seen.emit()
		progress = 0.0
		holding = false

	if holding:
		progress += delta / step.hold_seconds
	else:
		progress = maxf(0.0, progress - DECAY_RATE * delta / step.hold_seconds)

	EventBus.resistance_hold_changed.emit(clampf(progress, 0.0, 1.0) if within else 0.0)
	if progress >= 1.0:
		_complete()
	queue_redraw()

func _patrol_is_watching() -> bool:
	if not _events:
		return false
	for instance in _events.instances():
		if instance.def.id != "police_patrol" or instance.is_telegraphing():
			continue
		if instance.global_position.distance_to(global_position) <= SEEN_RADIUS:
			return true
	return false

func _complete() -> void:
	is_done = true
	progress = 1.0
	EventBus.resistance_hold_changed.emit(0.0)
	completed.emit(step.index)
	queue_redraw()

# ------------------------------------------------------------------ drawing ---

func _draw() -> void:
	if is_done:
		_draw_chalk(Palette.CHALK_DONE)
		return
	_draw_chalk(Palette.CHALK)
	if progress > 0.0:
		draw_arc(Vector2(0.0, -2.0), REACH * 0.6, -PI * 0.5,
				-PI * 0.5 + TAU * clampf(progress, 0.0, 1.0), 40, Palette.CHALK_DONE, 3.0)

## Three strokes and a circle — the sort of mark you would walk past a hundred times.
func _draw_chalk(colour: Color) -> void:
	var flicker := colour
	flicker.a *= 0.75 + 0.25 * sin(_pulse * 2.0)
	draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 20, flicker, 2.0)
	draw_line(Vector2(-7.0, 4.0), Vector2(7.0, -5.0), flicker, 2.0)
	draw_line(Vector2(-6.0, -5.0), Vector2(2.0, 6.0), flicker, 2.0)
