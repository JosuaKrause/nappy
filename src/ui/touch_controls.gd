class_name TouchControls
extends Control
## The on-screen stick and run button that make the game playable with a thumb.
##
## Both press the same actions a keyboard does — `Input.action_press("move_left", strength)` and
## its three siblings for the stick, `"run"` held for the button — so `Stroller`'s own
## `Input.get_vector("move_left", "move_right", "move_up", "move_down")` and
## `Input.is_action_pressed("run")` never have to learn where either came from. The stick is
## already analogue with a 0.2 deadzone in the input map, so a partial deflection is a slower walk
## exactly the way a half-pressed key never was and a half-tilted stick already is.
##
## **Running is never the far end of the stick's own push, on purpose.** `Stroller` moves toward
## `input_dir * top_speed` with the *raw* vector, so a stick threshold would make the one
## deliberate act in the game — the run key, held — into a gradient a thumb could cross by
## accident. It is a separate button instead, exactly as `Shift` already is, planted on the
## opposite side of the screen from the stick: the two are read from independent touch indices, so
## a thumb steering the stick never has to cross the one holding the button down, and vice versa.
##
## Drawn overlaying the city rather than in a letterbox bar, because a letterbox bar is outside the
## drawable viewport — the two meter bars and the optional goal already occupy the bottom-left and
## bottom-centre of the HUD, so the stick sits above the meters and the button sits at the matching
## height on the right, out of the way of both.
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

const RUN_RADIUS := 50.0
## As generous as the stick's own catch radius, for the same reason: a thumb does not land on a
## button to the pixel.
const RUN_CATCH_RADIUS := 76.0
## The mirror of `STICK_CENTRE` — same height, the opposite side of the screen, far enough from the
## HUD's own `Teach` label (centred, 380px to 900px wide in the same space) that neither the
## walking lesson nor the optional-goal line ever falls under it.
const RUN_CENTRE := Vector2(1150.0, 500.0)

var _touch := TouchInput.available()

## The touch index currently driving the stick, or -1 when nothing is.
var _stick_touch := -1
## Current deflection, each axis in [-1, 1]. `Vector2.ZERO` is centred.
var _stick_vector := Vector2.ZERO
## The touch index currently holding the run button, or -1 when nothing is. Tracked independently
## of the stick's own index, since the whole point of a separate button is that both can be down
## together.
var _run_touch := -1

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
		elif _run_touch == -1 and event.position.distance_to(RUN_CENTRE) <= RUN_CATCH_RADIUS:
			_run_touch = event.index
			Input.action_press(&"run", 1.0)
			queue_redraw()
		return
	if event.index == _stick_touch:
		_stick_touch = -1
		_stick_vector = Vector2.ZERO
		_apply_stick()
		queue_redraw()
	elif event.index == _run_touch:
		_run_touch = -1
		Input.action_release(&"run")
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

## Lets go of everything this node might be holding down. Called whenever the controls go
## invisible, for whatever reason, so a finger caught mid-gesture by a pause or a day ending never
## leaves a direction — or the run key — pressed into the day that follows.
func _release_all() -> void:
	_stick_touch = -1
	_stick_vector = Vector2.ZERO
	_run_touch = -1
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")
	Input.action_release(&"run")

func _draw() -> void:
	if not visible:
		return
	_draw_stick()
	_draw_run_button()

func _draw_stick() -> void:
	draw_circle(STICK_CENTRE, STICK_RADIUS, Color(1.0, 1.0, 1.0, 0.16))
	draw_arc(STICK_CENTRE, STICK_RADIUS, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.4), 2.0)
	var knob := STICK_CENTRE + _stick_vector * STICK_RADIUS
	var held := _stick_touch != -1
	draw_circle(knob, STICK_KNOB_RADIUS, Color(1.0, 1.0, 1.0, 0.42 if held else 0.28))

func _draw_run_button() -> void:
	var held := _run_touch != -1
	draw_circle(RUN_CENTRE, RUN_RADIUS, Color(1.0, 1.0, 1.0, 0.32 if held else 0.16))
	draw_arc(RUN_CENTRE, RUN_RADIUS, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.4), 2.0)
	var label := "RUN"
	var font := ThemeDB.fallback_font
	var font_size := 15
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, RUN_CENTRE + Vector2(-width * 0.5, font_size * 0.35), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 1.0, 1.0, 0.8))
