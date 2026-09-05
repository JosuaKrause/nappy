class_name TapControls
extends Node
## The tap-to-walk reader: a tap decides a straight line and a double tap runs it, standing in
## for the on-screen stick in the other of the two control schemes `ControlsMode` chooses between.
##
## **Nothing here re-aims.** The heading is worked out once, at the tap, and pressed the way
## `TouchControls._set_axis()` presses the stick's own deflection — the components of a fixed unit
## vector, not a direction recomputed every frame — so a shove that knocks her off the line does
## not silently correct itself. Walking into a wall and stopping is the player's mistake to make
## here exactly as it is with the stick: nothing routes around what is in the way, and nothing
## times out either. She presses until she arrives or until the next tap.
##
## **Arrival is the plane through the target, not a distance.** `has_arrived()` is
## `(target - position).dot(direction) <= 0` — the plane at right angles to the heading fixed at
## the tap. That terminates cleanly even when a shove pushes her sideways off the line, where a
## distance test would have her pressing forever past a target she was knocked around.
##
## A double tap is two windows: `DOUBLE_TAP_SECONDS` decides *soon enough*, and `DOUBLE_TAP_DISTANCE`
## decides *close enough* to the first tap to read as the same destination doubled rather than a
## new one — without the second window, a tap somewhere else a moment later would make her run to
## the wrong place. Both are plain constants here, the way `TouchControls.RUN_CATCH_RADIUS` (how
## near the RUN button a thumb must land) is a plain constant there rather than a balance number in
## `Tuning`.
##
## **Arriving starts a clock, and the clock pauses.** Pausing on arrival itself would stutter the
## ordinary loop — arrive, tap on — so `ARRIVAL_PAUSE_AFTER` only fires the pause if she is still
## standing when it expires, and a tap before then is simply the next leg. It is gated on
## *arriving*, not on standing still: something blocking her never crosses the plane and so never
## starts the clock, consistent with "walking into a wall and stopping is the player's mistake to
## make" above — nothing here detects being stuck, and nothing is meant to. The pause it opens is
## `TouchControls._send_pause_action()`'s own real `InputEventAction`, the same one the stick's
## pause button sends, so `main._unhandled_input()` opens the same `PauseScreen` either way.

## How soon a second tap has to land to read as a double, in seconds.
const DOUBLE_TAP_SECONDS := 0.35
## How close the second tap has to land to the first, in screen px, to read as the same
## destination rather than a new one. Generous like `TouchControls.RUN_CATCH_RADIUS`, because a
## thumb tapping twice does not land on the same pixel either time.
const DOUBLE_TAP_DISTANCE := 60.0
## How long she can stand at a destination before the game pauses on her behalf. Longer than
## `HUD.TEACH_PAUSE_AFTER` (3s) on purpose — this is a feel number, the only way to set it is to
## walk with it, and it moves against a played day.
const ARRIVAL_PAUSE_AFTER := 5.0

## Whether this device has a touchscreen. Read once from `TouchInput`, the same pattern
## `TouchControls._touch` is — and the reason the mouse stand-in below checks it: Godot emulates a
## mouse click from every real touch by default (`input_devices/pointing/emulate_mouse_from_touch`),
## so without this gate a single tap on an actual touch device would fire `_on_tap()` twice in the
## same instant, through both event types, and read as its own double tap.
var _touch := TouchInput.available()

## The rig, found the same way `HUD._rig` is: a state of the player rather than something a
## signal carries.
var _rig: Node2D

## Fixed at the tap that started the current leg; never touched again until the next tap or
## arrival releases them.
var _direction := Vector2.ZERO
var _target := Vector2.ZERO
var _walking := false

## The previous tap's own moment and screen position, for the double-tap windows. `-INF` reads as
## "no earlier tap this run", which can never fall inside either window.
var _last_tap_at := -INF
var _last_tap_screen_position := Vector2.ZERO

## Counts down once she has arrived and is standing; `<= 0.0` while walking or once the pause has
## already fired for this stand.
var _stand_left := 0.0
## Whether the pause currently up is the one `_stand_left` raised, as opposed to Esc, the day
## ending, or a screen with nothing to do with tap mode. Only "our own" pause is a tap's to
## dismiss — see `_on_tap()` — and only an unrelated one needs its own held direction force-released
## the way `TouchControls._release_all()` already forces one on every kind of hiding.
var _own_pause := false
var _was_paused := false

func _ready() -> void:
	# Has to keep reading a tap through the arrival pause it can itself raise, the same reason
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

## A tap arrived at `screen_position` -- the same canvas-space coordinate the event itself carries,
## whatever the window's own rotation -- at moment `now`.
##
## `get_viewport().get_canvas_transform().affine_inverse()` maps it to a world position: the exact
## reverse of what `DangerEdge` and `HomeArrow` already do every frame to place a screen cue from a
## world one, so this tracks the camera, the zoom and the rotated presentation with nothing of its
## own to keep in step -- no separate remap through `ScreenOrientation` the way `TouchControls` has
## to for its own fixed screen constants, because a tap has no fixed constant to compare against.
##
## `now` is a parameter rather than read from `Time` in here, so a test can hold the double-tap
## window still instead of racing the engine clock -- `_input()` is the one real caller and is what
## supplies it from `Time.get_ticks_msec()`.
##
## **While paused for a reason of its own making, a tap both unpauses and sets the next
## destination** -- a tap is the only input this mode has, and two taps to resume-then-walk would
## collide with the double tap that means *run*. The event is left unhandled either way, so the
## same raw touch also reaches `PauseScreen._unhandled_input()`, which already closes on any touch
## press; this does not have to know how to close that screen itself. Paused for any other
## reason -- Esc, the day ending, the title -- a tap here does nothing, the same as the stick's own
## controls drawing nothing on any of those screens.
func _on_tap(screen_position: Vector2, now: float) -> void:
	if get_tree().paused and not _own_pause:
		return
	var world := get_viewport().get_canvas_transform().affine_inverse() * screen_position
	var double := is_double_tap(now - _last_tap_at,
			screen_position.distance_to(_last_tap_screen_position))
	_last_tap_at = now
	_last_tap_screen_position = screen_position
	walk_to(world, double)

func _process(delta: float) -> void:
	var paused := get_tree().paused
	if paused and not _was_paused and not _own_pause:
		# Esc, the day ending, or a screen with nothing to do with tap mode -- not the clock below.
		# A direction left pressed into whatever comes next is the same leak
		# `TouchControls._release_all()` already guards its own controls against.
		_walking = false
		_stand_left = 0.0
		_release()
	elif not paused and _was_paused:
		_own_pause = false
	_was_paused = paused

	if _walking:
		if not _rig:
			_rig = get_tree().get_first_node_in_group("player") as Node2D
		if _rig and has_arrived(_target, _rig.global_position, _direction):
			_walking = false
			_release()
			_stand_left = ARRIVAL_PAUSE_AFTER
		return
	if _stand_left <= 0.0:
		return
	_stand_left = maxf(0.0, _stand_left - delta)
	if _stand_left <= 0.0:
		_own_pause = true
		# The tap that dismisses this pause must read as a fresh single tap, not a double against
		# whatever was tapped minutes ago to get here.
		_last_tap_at = -INF
		TouchControls._send_pause_action()

## Starts a leg toward `target`, computed once here and never again. `run` holds the same `run`
## action the button and Shift do, until she arrives or the next tap lets go of it.
##
## A tap that lands on her own position has no line to walk and is a no-op — there is nothing for
## `_process()` to test an arrival against.
func walk_to(target: Vector2, run: bool) -> void:
	if not _rig:
		_rig = get_tree().get_first_node_in_group("player") as Node2D
	if not _rig:
		return
	var direction := heading_to(target, _rig.global_position)
	if direction == Vector2.ZERO:
		return
	_target = target
	_direction = direction
	_walking = true
	TouchControls._set_axis(&"move_left", &"move_right", direction.x)
	TouchControls._set_axis(&"move_up", &"move_down", direction.y)
	if run:
		Input.action_press(&"run")
	else:
		Input.action_release(&"run")

func _release() -> void:
	TouchControls._release_movement()

## Whether a straight walk toward `target`, heading `direction`, has reached the plane through the
## target at right angles to that heading — see the class doc for why this is a plane and not a
## radius.
static func has_arrived(target: Vector2, position: Vector2, direction: Vector2) -> bool:
	return (target - position).dot(direction) <= 0.0

## The unit vector from `from` to `target`, or `Vector2.ZERO` for a tap with nowhere to go.
static func heading_to(target: Vector2, from: Vector2) -> Vector2:
	var offset := target - from
	return offset.normalized() if offset.length() > 0.001 else Vector2.ZERO

## Whether a second tap `distance` px from the first, `elapsed` seconds after it, reads as the
## same destination doubled rather than a new one.
static func is_double_tap(elapsed: float, distance: float) -> bool:
	return elapsed <= DOUBLE_TAP_SECONDS and distance <= DOUBLE_TAP_DISTANCE
