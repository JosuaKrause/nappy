class_name TouchControls
extends Control
## The on-screen stick that makes movement playable with a thumb.
##
## It presses the same two actions a keyboard does — `Input.action_press("move_left", strength)`
## and its three siblings — so `Stroller`'s own `Input.get_vector("move_left", "move_right",
## "move_up", "move_down")` never has to learn where the vector came from. It is already analogue
## with a 0.2 deadzone in the input map, so a partial deflection is a slower walk exactly the way a
## half-pressed key never was and a half-tilted stick already is.
##
## Drawn overlaying the city rather than in a letterbox bar, because a letterbox bar is outside the
## drawable viewport — the two meter bars and the optional goal already occupy the bottom-left and
## bottom-centre of the HUD, so the stick sits above the meters rather than beside them, out of the
## way of both.
##
## Shown only on a touch device (`TouchInput.available()`) and only while a day is actually being
## walked. `get_tree().paused` is the one fact the title screen, the pause and the between-days
## summary all set, and checking it here is what keeps the stick off every one of those three
## screens without a wire from `main` telling it so on each — the same fact that already decides
## whether the player is being driven at all.
##
## `process_mode` stays `ALWAYS`, like the three screens it has to disappear under: a `PAUSABLE`
## node stops running the instant the tree pauses, which is one frame too late to let go of
## whatever direction was pressed when the pause landed. Every action this holds is force-released
## the moment it goes invisible for any reason, so a finger still on the stick when a day ends is
## never still on it once the next one begins.

## How far the knob can travel from the stick's centre before the deflection reads as full push —
## the analogue range the 0.2 deadzone in the input map then trims.
const STICK_RADIUS := 60.0
const STICK_KNOB_RADIUS := 24.0
## Well past the visible base: a thumb does not land on a drawn circle to the pixel, and a stick
## that only grabs where it is drawn is a stick that is frequently missed.
const STICK_CATCH_RADIUS := 100.0
## Above the meter bars (`hud.tscn`'s `Meters`, the last 132px of screen height in its own
## 280px-wide column) rather than beside them, and on the same side a left thumb rests on.
const STICK_CENTRE := Vector2(130.0, 500.0)

var _touch := TouchInput.available()

## The touch index currently driving the stick, or -1 when nothing is.
var _stick_touch := -1
## Current deflection, each axis in [-1, 1]. `Vector2.ZERO` is centred.
var _stick_vector := Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false

func _process(_delta: float) -> void:
	var showing := _touch and not get_tree().paused
	if showing != visible:
		visible = showing
		if not showing:
			_release_all()
		queue_redraw()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		_on_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_on_drag(event as InputEventScreenDrag)

func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _stick_touch == -1 and event.position.distance_to(STICK_CENTRE) <= STICK_CATCH_RADIUS:
			_stick_touch = event.index
			_update_stick(event.position)
		return
	if event.index == _stick_touch:
		_stick_touch = -1
		_stick_vector = Vector2.ZERO
		_apply_stick()
		queue_redraw()

func _on_drag(event: InputEventScreenDrag) -> void:
	if event.index == _stick_touch:
		_update_stick(event.position)

func _update_stick(at: Vector2) -> void:
	var offset := at - STICK_CENTRE
	_stick_vector = offset.limit_length(STICK_RADIUS) / STICK_RADIUS
	_apply_stick()
	queue_redraw()

## Presses the two axis actions the way a keyboard would, one direction at a time: only one of
## `move_left`/`move_right` can be true on a keyboard, and the other is explicitly released rather
## than left to decay on its own, or a stick flicked hard the other way would fight its own
## trailing strength for a frame.
func _apply_stick() -> void:
	_set_axis(&"move_left", &"move_right", _stick_vector.x)
	_set_axis(&"move_up", &"move_down", _stick_vector.y)

func _set_axis(negative: StringName, positive: StringName, value: float) -> void:
	if value > 0.0:
		Input.action_press(positive, value)
		Input.action_release(negative)
	elif value < 0.0:
		Input.action_press(negative, -value)
		Input.action_release(positive)
	else:
		Input.action_release(negative)
		Input.action_release(positive)

## Lets go of everything this node might be holding down. Called whenever the stick goes
## invisible, for whatever reason, so a finger caught mid-gesture by a pause or a day ending never
## leaves a direction pressed into the day that follows.
func _release_all() -> void:
	_stick_touch = -1
	_stick_vector = Vector2.ZERO
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")

func _draw() -> void:
	if not visible:
		return
	draw_circle(STICK_CENTRE, STICK_RADIUS, Color(1.0, 1.0, 1.0, 0.16))
	draw_arc(STICK_CENTRE, STICK_RADIUS, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.4), 2.0)
	var knob := STICK_CENTRE + _stick_vector * STICK_RADIUS
	var held := _stick_touch != -1
	draw_circle(knob, STICK_KNOB_RADIUS, Color(1.0, 1.0, 1.0, 0.42 if held else 0.28))
