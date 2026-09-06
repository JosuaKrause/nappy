class_name TouchControls
extends Control
## The one control scheme a pointer drives, and the pause button it draws.
##
## A press — a finger, or (on a device with no touch hardware of its own) a mouse click —
## sets a direction, measured from her own world position, that is locked in and walked with
## nothing held down until the next press changes it; a press within `STOP_RADIUS` of her stops
## her instead; a double press sets the direction and holds `run` until the next press changes or
## releases it. See `set_direction()`, `_stop()` and `is_double_tap()` — that half of this file
## used to be `TapControls`, a second node with nothing to draw, and is folded in here because it
## needs something to draw now: the pause button, the one thing left standing once the drag stick
## and the held `RUN` circle are deleted.
##
## **The pause button is not that kind of control.** `main._unhandled_input()` reads
## `event.is_action_pressed("pause")` off the propagated *event*, not off polled state, so
## `Input.action_press(&"pause")` would set the state and be heard by nothing — the same trap
## `AutoScreenshot._tap()` already names in its own comment for exactly this action. See
## `_send_pause_action()`.
##
## **Drawn only on a touch device** (`TouchInput.available()`) **and only while a day is actually
## being walked.** `get_tree().paused` is the one fact the title screen, the pause and the
## between-days summary all set, and checking it here is what keeps the button off every one of
## those three screens without a wire from `main` telling it so on each. A keyboard-and-mouse
## desktop never draws it at all: `Esc` is its pause, exactly as it always was, and pressing
## anywhere else on such a device still sets a direction or stops her — the corner is only ever
## subtracted from the aiming surface where the button is actually there to press. Direction
## presses themselves are read whether or not the button is drawn, since a keyboard device is
## exactly where the mouse half of this file has to keep working.
##
## `process_mode` stays `ALWAYS`, like the three screens it has to disappear under: a `PAUSABLE`
## node stops running the instant the tree pauses, which is one frame too late to let go of
## whatever direction was pressed when the pause landed. Every action this holds is force-released
## the moment the tree pauses, for any reason, so a finger still down when a day ends is never
## still down once the next one begins.

## Smaller than the drag stick and `RUN` button this file used to also draw: it is pressed once a
## day at most, so it does not want either one's old reach into the walking hand's own space.
const PAUSE_RADIUS := 26.0
## As generous as the catch radii this file's own now-deleted stick and `RUN` button used to
## carry, for the same reason a thumb does not land on a button to the pixel — and also the radius
## a *release* has to land inside to fire, so a thumb that lands wrong can slide off and lift
## without stopping the day. See `_on_touch()`.
const PAUSE_CATCH_RADIUS := 46.0
## Top right, in the corner both `DangerEdge` and `HomeArrow` keep clear on purpose rather than in
## front of them: `DangerEdge.MARGIN` (104/116/104/148, left/top/right/bottom) never draws a chevron
## closer to this corner than (1176, 116), and `HomeArrow.MARGIN` (96px, uniform) never draws its
## own arrow closer than (1184, 96) — so nothing else is ever asked to share these pixels.
##
## **It is held 36px clear of both edges rather than pushed right into them.** The rim is what the
## margin is measured to, so the drawn circle stops 36px short of the top and the right. A button
## whose edge touches the screen's reads as clipped, and on a real phone that corner is where the
## rounded glass and the system gesture strip live — a control flush against it is one a thumb
## cannot reach cleanly even when it is drawn in full.
##
## **That margin is what set `HomeArrow.MARGIN`, not the other way round.** This button's rim needs
## `PAUSE_RADIUS` + `HomeArrow.SIZE` (15px, the chevron's reach from its own centre) = 41px of
## clearance from the arrow's closest approach, and coming in off the edge spends exactly that. At
## the arrow's old 74px inset the two overlapped, so the arrow moved to 96 to make room. Widening
## this margin further moves the arrow again; the two numbers are one decision.
const PAUSE_CENTRE := Vector2(1218.0, 62.0)

## How soon a second press has to land to read as a double, in seconds.
const DOUBLE_TAP_SECONDS := 0.35
## How close the second press has to land to the first, in screen px, to read as the same
## direction doubled rather than a new one. Generous, because a thumb pressing twice does not land
## on the same pixel either time.
const DOUBLE_TAP_DISTANCE := 60.0
## How close a press has to land to her, in world px, to read as *stop* rather than a direction.
## Wider than `Tuning.PLAYER_BODY_RADIUS` (14px) alone — the pram rides up to `PRAM_DISTANCE` (34px)
## off to one side of her, and a press that lands on the pram is a press on her — with room to
## spare for a thumb that does not land on the same pixel twice, the way every catch radius in this
## game is generous rather than exact.
const STOP_RADIUS := 48.0

var _touch := TouchInput.available()

## Whether `main` has decided a portrait touch window is presenting rotated — see
## `ScreenOrientation`. Set from outside rather than asked here, the same way `_touch` is a read
## of a platform fact rather than a query at each use site: `main._apply_orientation()` is the one
## place that knows the window's own shape, and the pause button's own touch handling goes through
## `ScreenOrientation.to_design_space()` with this flag before comparing a raw press to
## `PAUSE_CENTRE`, which stays authored in the unrotated 1280x720 box regardless. A direction press
## needs no such remap — it is turned straight into a world position through the viewport's own
## canvas transform, which already carries the rotation.
var rotated := false

## The touch index currently down on the pause button, or -1 when nothing is. Going down does not
## press anything — see `_on_touch()` for why the action only fires on release, and only if that
## release is still over the button.
var _pause_touch := -1

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
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Pinned to the fixed design box rather than full-rect, so this node's own ancestor
	# `CanvasLayer` (set up in `main._add_touch_controls()`) has a stationary 1280x720 footprint to
	# rotate rather than one that resizes itself to whatever `content_scale_size` currently is —
	# see `ScreenOrientation.pin_to_design_box()`.
	ScreenOrientation.pin_to_design_box(self)
	visible = false

## The pause button's own visibility, gated on device and pause exactly as it always was; a
## direction press is read whether or not this ever turns true, so a keyboard-and-mouse desktop —
## which never shows the button — still walks on a click. Any pause landing, on any device,
## force-releases whatever direction and `run` were held: the tree pausing is the one signal both
## halves of this file share, so it is what `_release_all()` is hung off rather than the
## visibility toggle alone.
func _process(_delta: float) -> void:
	var paused := get_tree().paused
	var showing := _touch and not paused
	if showing != visible:
		visible = showing
		queue_redraw()
	if paused and not _was_paused:
		_release_all()
	_was_paused = paused

## Every real touch, always; a mouse click stands in for one too, on every build including a
## release export — *(2026-09-06, on a laptop: "I still need to press space even in mouse mode",
## and the same session: "let's do mouse mode to behave the same way that she keeps walking in the
## direction indefinitely")* — since a laptop with no touchscreen has no other way to choose this
## scheme at all. **Gated on `not _touch`, and that gate is load-bearing, not a nicety**: Godot
## emulates a mouse click from every real touch by default, so on an actual touch device a single
## tap would otherwise arrive here twice, once as each event type, close enough together in space
## and time to read as its own double tap — see `_test_a_touch_devices_own_emulated_click_is_ignored`
## in `tests/test_touch.gd`. Neither branch is gated on `visible`: the pause button only ever
## matters while it is shown, which `_on_touch()` checks for itself, but a direction press has to
## keep working on a device that never draws anything at all.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event as InputEventScreenTouch)
	elif not _touch and event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			_on_tap(click.position, Time.get_ticks_msec() / 1000.0)

## A touch press or release. **The corner is subtracted from the aiming surface only while the
## button is actually showing** (`visible`, `_touch and not get_tree().paused`) — pressing where it
## would be on a device that never draws it is an ordinary direction press, same as anywhere else.
func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if visible:
			# The one correction a rotated presentation needs on the input side — see
			# `ScreenOrientation`'s own doc for why this is the only file in `src/ui/` that needs it.
			var design := ScreenOrientation.to_design_space(event.position, rotated)
			if _pause_touch == -1 and design.distance_to(PAUSE_CENTRE) <= PAUSE_CATCH_RADIUS:
				# Only grabs the touch index here — see `_send_pause_action()`'s doc for why
				# nothing fires until the matching release.
				_pause_touch = event.index
				queue_redraw()
				return
		_on_tap(event.position, Time.get_ticks_msec() / 1000.0)
		return
	if event.index == _pause_touch:
		_pause_touch = -1
		queue_redraw()
		# Fires on release rather than on touch-down, and only when the release itself is still
		# over the button, so a thumb that lands wrong can slide off and lift without stopping the
		# day.
		var design := ScreenOrientation.to_design_space(event.position, rotated)
		if _pause_fires(design):
			_send_pause_action()

## A press arrived at `screen_position` -- the same canvas-space coordinate the event itself
## carries, whatever the window's own rotation -- at moment `now`.
##
## `get_viewport().get_canvas_transform().affine_inverse()` maps it to a world position: the exact
## reverse of what `DangerEdge` and `HomeArrow` already do every frame to place a screen cue from a
## world one, so this tracks the camera, the zoom and the rotated presentation with nothing of its
## own to keep in step. A press within `STOP_RADIUS` of her stops her; otherwise it locks in the
## heading toward it.
##
## `now` is a parameter rather than read from `Time` in here, so a test can hold the double-tap
## window still instead of racing the engine clock -- `_input()` and `_on_touch()` are the real
## callers and supply it from `Time.get_ticks_msec()`.
##
## **Paused, a press does nothing at all**, the same as this file's controls drawing nothing on the
## title, the pause and the between-days summary. The event is left unhandled either way, so the
## same raw touch also reaches whichever of those screens is actually up — `PauseScreen`,
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

## Locks in the heading toward `target`, computed once here and never again — nothing here
## re-aims, so a shove that knocks her off the line does not silently correct itself, the same way
## walking into a wall and stopping is the player's mistake to make. `run` holds the same `run`
## action Shift does, until the next press changes the direction or stops her — there is nothing
## to arrive at that would let go of it on its own.
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
	_set_axis(&"move_left", &"move_right", direction.x)
	_set_axis(&"move_up", &"move_down", direction.y)
	if run:
		Input.action_press(&"run")
	else:
		Input.action_release(&"run")

## A press on her: lets go of whatever direction and `run` were held, with nothing pressed in
## their place.
func _stop() -> void:
	_walking = false
	_direction = Vector2.ZERO
	_release_movement()

## The unit vector from `from` to `target`, or `Vector2.ZERO` for a press with nowhere to go.
static func heading_to(target: Vector2, from: Vector2) -> Vector2:
	var offset := target - from
	return offset.normalized() if offset.length() > 0.001 else Vector2.ZERO

## Whether a second tap `distance` px from the first, `elapsed` seconds after it, reads as the
## same direction doubled into a run rather than a new one.
static func is_double_tap(elapsed: float, distance: float) -> bool:
	return elapsed <= DOUBLE_TAP_SECONDS and distance <= DOUBLE_TAP_DISTANCE

## Presses one signed value onto a pair of opposite actions, one direction at a time: only one of
## `move_left`/`move_right` can be true on a keyboard, and the other is explicitly released rather
## than left to decay on its own. Static, since it is pure — a direction's own components are what
## every caller here presses through it.
static func _set_axis(negative: StringName, positive: StringName, value: float) -> void:
	if value > 0.0:
		Input.action_press(positive, value)
		Input.action_release(negative)
	elif value < 0.0:
		Input.action_press(negative, -value)
		Input.action_release(positive)
	else:
		Input.action_release(negative)
		Input.action_release(positive)

## Lets go of everything this node might be holding down. Called whenever the tree pauses, for
## whatever reason, so a finger caught mid-gesture by a pause or a day ending never leaves a
## direction — or the run key — pressed into the day that follows.
##
## `_pause_touch` only needs resetting here, not releasing: nothing was ever pressed for it, since
## the pause fires once on a clean release rather than holding a state — see
## `_send_pause_action()`. A pause opening is one of the moments this is called for, so a finger
## still down on the button when that happens must not fire it a second time on whatever it lands
## on next.
func _release_all() -> void:
	_pause_touch = -1
	_walking = false
	_release_movement()

## The four `move_*` actions and `run`, released together — the shape needed at the moment a
## direction has to be let go of that is not the player's own doing: the day ending, or a pause
## opening.
static func _release_movement() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")
	Input.action_release(&"run")

## Whether a release at `at` lands the pause, or a slide-off cancels it. Pulled out to a pure,
## static function so a test can ask the geometry question on its own — `Input.parse_input_event()`
## queues the event for the engine's own next flush rather than updating anything a test can poll
## synchronously (`Input.is_action_pressed("pause")` read right after sending one is not reliable;
## a first version of this test asserted it and failed for exactly that reason), so nothing about
## whether this decides to fire is asserted through `Input` at all.
static func _pause_fires(at: Vector2) -> bool:
	return at.distance_to(PAUSE_CENTRE) <= PAUSE_CATCH_RADIUS

## Sends the pause exactly the way a real `Esc` arrives: an `InputEventAction` pushed through
## `Input.parse_input_event()`, which propagates to `main._unhandled_input()` the same way a key
## does, rather than `Input.action_press(&"pause")`, which only sets polled state and is heard by
## nothing — `AutoScreenshot._tap()`'s own comment names this exact trap for `--press`, and the
## fix is the same fix here.
##
## Returns the event it sent, so a test can inspect its shape directly rather than depend on when
## the tree gets around to propagating or polling it.
static func _send_pause_action() -> InputEventAction:
	var event := InputEventAction.new()
	event.action = &"pause"
	event.pressed = true
	Input.parse_input_event(event)
	return event

## The only thing this file draws, and the only thing on screen this scheme ever needs: every
## pixel of the city is a direction, so there is nothing left to draw for that half of it.
func _draw() -> void:
	if not visible:
		return
	_draw_pause_button()

## Two bars, the same shape `hud.gd`'s touch teach line then names in words — drawn rather than
## set in a font glyph, because a vector shape always renders and a Unicode pause glyph is not
## guaranteed to be in `ThemeDB.fallback_font` at all.
func _draw_pause_button() -> void:
	var held := _pause_touch != -1
	draw_circle(PAUSE_CENTRE, PAUSE_RADIUS, Color(1.0, 1.0, 1.0, 0.32 if held else 0.16))
	draw_arc(PAUSE_CENTRE, PAUSE_RADIUS, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.4), 2.0)
	var bar_height := PAUSE_RADIUS * 0.8
	var bar_width := PAUSE_RADIUS * 0.22
	var gap := PAUSE_RADIUS * 0.22
	for side in [-1.0, 1.0]:
		var bar_centre := PAUSE_CENTRE + Vector2(side * (gap * 0.5 + bar_width * 0.5), 0.0)
		draw_rect(Rect2(bar_centre - Vector2(bar_width, bar_height) * 0.5,
				Vector2(bar_width, bar_height)), Color(1.0, 1.0, 1.0, 0.8))
