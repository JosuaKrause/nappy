class_name TapControls
extends Node
## The direction reader: a press sets a heading and it is walked with nothing held down until the
## next press changes it, standing in for the on-screen stick in the other of the two control
## schemes `ControlsMode` chooses between.
##
## **This deletes the destination.** A press used to fix a heading *and* a target, walk the
## straight line, and stop at the plane through the target — there is no target now and nothing to
## arrive at. She walks the heading until the next press changes it. *(2026-09-06: "let's do mouse
## mode to behave the same way that she keeps walking in the direction indefinitely".)*
##
## **Nothing here re-aims.** The heading is worked out once, at the press, and pressed the way
## `TouchControls._set_axis()` presses the stick's own deflection — the components of a fixed unit
## vector, not a direction recomputed every frame — so a shove that knocks her off the line does
## not silently correct itself. Walking into a wall and stopping is the player's mistake to make
## here exactly as it is with the stick: nothing routes around what is in the way, and nothing
## times out either.
##
## **A press on her stops her**, *(2026-09-06: "also, to stop her just click on her")* — this
## replaces both arriving, which used to release the movement actions and no longer exists, and
## playtest 27's own stop target, a tap on the drawn joystick's centre, which cannot survive the
## drawing being deleted. `STOP_RADIUS` is compared in world space, since she moves and the camera
## follows, and is generous rather than exact the way every other catch radius in this game is.
##
## A double press is two windows: `DOUBLE_TAP_SECONDS` decides *soon enough*, and
## `DOUBLE_TAP_DISTANCE` decides *close enough* to the first press to read as the same direction
## doubled into a run rather than a new one — without the second window, a press somewhere else a
## moment later would make her run the wrong way. Both are plain constants here, the way
## `TouchControls.RUN_CATCH_RADIUS` (how near the RUN button a thumb must land) is a plain
## constant there rather than a balance number in `Tuning`. Running holds until the next press
## changes the direction or stops her — there is nothing left to arrive at that would release it
## on its own.

## How soon a second press has to land to read as a double, in seconds.
const DOUBLE_TAP_SECONDS := 0.35
## How close the second press has to land to the first, in screen px, to read as the same
## direction doubled rather than a new one. Generous like `TouchControls.RUN_CATCH_RADIUS`, because
## a thumb pressing twice does not land on the same pixel either time.
const DOUBLE_TAP_DISTANCE := 60.0
## How close a press has to land to her, in world px, to read as *stop* rather than a direction.
## Wider than `Tuning.PLAYER_BODY_RADIUS` (14px) alone — the pram rides up to `PRAM_DISTANCE` (34px)
## off to one side of her, and a press that lands on the pram is a press on her — with room to
## spare for a thumb that does not land on the same pixel twice, the way every catch radius in this
## game is generous rather than exact.
const STOP_RADIUS := 48.0

## Whether this device has a touchscreen. Read once from `TouchInput`, the same pattern
## `TouchControls._touch` is — and the reason the mouse stand-in below checks it: Godot emulates a
## mouse click from every real touch by default (`input_devices/pointing/emulate_mouse_from_touch`),
## so without this gate a single tap on an actual touch device would fire `_on_tap()` twice in the
## same instant, through both event types, and read as its own double tap.
var _touch := TouchInput.available()

## The rig, found the same way `HUD._rig` is: a state of the player rather than something a
## signal carries.
var _rig: Node2D

## Locked in at the last press; never touched again until the next press releases or replaces it.
var _direction := Vector2.ZERO
var _walking := false

## The previous press's own moment and screen position, for the double-tap windows. `-INF` reads as
## "no earlier press this run", which can never fall inside either window.
var _last_tap_at := -INF
var _last_tap_screen_position := Vector2.ZERO

var _was_paused := false

func _ready() -> void:
	# Has to keep reading a press through any pause Esc or the day raises, the same reason
	# `TouchControls` stays ALWAYS rather than the inherited PAUSABLE.
	process_mode = Node.PROCESS_MODE_ALWAYS

## Every real tap: `InputEventScreenTouch` is what a finger sends. `InputEventMouseButton` stands
## in for one too, in a debug build with no touch hardware of its own — "on non-mobile we can try
## clicking with the mouse instead of tapping" is a way to try the mode out on a desktop, not a
## control an exported build owes a mouse.
##
## **Gated on `not _touch`, and that gate is load-bearing, not a nicety**: Godot emulates a mouse
## click from every real touch by default, so on an actual touch device a single tap would
## otherwise arrive here twice, once as each event type, close enough together in space and time to
## read as its own double tap. `not _touch` is false on any device this matters on — a real
## touchscreen, or a screenshot rig run with `--touch` — so the emulated click is never read there,
## and the mouse-only branch is live only where no touch event could ever collide with it.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_on_tap((event as InputEventScreenTouch).position, Time.get_ticks_msec() / 1000.0)
	elif OS.is_debug_build() and not _touch and event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			_on_tap(click.position, Time.get_ticks_msec() / 1000.0)

## A press arrived at `screen_position` -- the same canvas-space coordinate the event itself
## carries, whatever the window's own rotation -- at moment `now`.
##
## `get_viewport().get_canvas_transform().affine_inverse()` maps it to a world position: the exact
## reverse of what `DangerEdge` and `HomeArrow` already do every frame to place a screen cue from a
## world one, so this tracks the camera, the zoom and the rotated presentation with nothing of its
## own to keep in step -- no separate remap through `ScreenOrientation` the way `TouchControls` has
## to for its own fixed screen constants, because a press has no fixed constant to compare against.
##
## `now` is a parameter rather than read from `Time` in here, so a test can hold the double-tap
## window still instead of racing the engine clock -- `_input()` is the one real caller and is what
## supplies it from `Time.get_ticks_msec()`.
##
## **Paused, a press does nothing at all**, the same as the stick's own controls drawing nothing on
## the title, the pause and the between-days summary. The event is left unhandled either way, so
## the same raw touch also reaches whichever of those screens is actually up — `PauseScreen`,
## `DaySummary` and `TitleScreen` each close or begin on a touch or a click of their own, so this
## does not have to know how to dismiss any of them itself.
func _on_tap(screen_position: Vector2, now: float) -> void:
	if get_tree().paused:
		return
	if not _rig:
		_rig = get_tree().get_first_node_in_group("player") as Node2D
	if not _rig:
		return
	var world := get_viewport().get_canvas_transform().affine_inverse() * screen_position
	var double := is_double_tap(now - _last_tap_at,
			screen_position.distance_to(_last_tap_screen_position))
	_last_tap_at = now
	_last_tap_screen_position = screen_position
	if world.distance_to(_rig.global_position) <= STOP_RADIUS:
		_stop()
		return
	set_direction(world, double)

## A pause landing force-releases whatever direction was held, the same leak
## `TouchControls._release_all()` already guards its own controls against — there is nothing left
## here that raises a pause of its own to tell apart from one that is not.
func _process(_delta: float) -> void:
	var paused := get_tree().paused
	if paused and not _was_paused:
		_walking = false
		_release()
	_was_paused = paused

## Locks in the heading toward `target`, computed once here and never again. `run` holds the same
## `run` action the button and Shift do, until the next press changes the direction or stops her —
## there is nothing to arrive at that would let go of it on its own.
##
## A press exactly on her own position has no heading to compute and stops her instead, the same
## case `_on_tap()`'s own `STOP_RADIUS` check already catches for anything a thumb's-width away —
## this is the fallback for the one caller (a test) that calls straight in with an exact point.
func set_direction(target: Vector2, run: bool) -> void:
	if not _rig:
		_rig = get_tree().get_first_node_in_group("player") as Node2D
	if not _rig:
		return
	var direction := heading_to(target, _rig.global_position)
	if direction == Vector2.ZERO:
		_stop()
		return
	_direction = direction
	_walking = true
	TouchControls._set_axis(&"move_left", &"move_right", direction.x)
	TouchControls._set_axis(&"move_up", &"move_down", direction.y)
	if run:
		Input.action_press(&"run")
	else:
		Input.action_release(&"run")

## A press on her: lets go of whatever direction and `run` were held, with nothing pressed in
## their place.
func _stop() -> void:
	_walking = false
	_direction = Vector2.ZERO
	_release()

func _release() -> void:
	TouchControls._release_movement()

## The unit vector from `from` to `target`, or `Vector2.ZERO` for a press with nowhere to go.
static func heading_to(target: Vector2, from: Vector2) -> Vector2:
	var offset := target - from
	return offset.normalized() if offset.length() > 0.001 else Vector2.ZERO

## Whether a second tap `distance` px from the first, `elapsed` seconds after it, reads as the
## same direction doubled into a run rather than a new one.
static func is_double_tap(elapsed: float, distance: float) -> bool:
	return elapsed <= DOUBLE_TAP_SECONDS and distance <= DOUBLE_TAP_DISTANCE
