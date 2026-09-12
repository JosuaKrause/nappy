class_name TouchControls
extends Control
## The one control scheme a pointer drives, in either of two chosen modes, and the pause button
## it draws.
##
## A press — a finger, or a mouse click, on any device — sets a direction that is locked in and
## walked with nothing held down until the next press changes it, or stops her instead if it lands
## close enough to the right ground; a double press sets the direction and holds `run` until the
## next press changes or releases it. See `set_direction()`, `_stop()` and `is_double_tap()` — that
## half of this file used to be `TapControls`, a second node with nothing to draw, and is folded in
## here because it needs something to draw now: the pause button, the one thing left standing once
## the drag stick and the held `RUN` circle are deleted.
##
## **Two things decide different questions here, and only one of them is about the mode.**
## `_touch` (`TouchInput.available()`) is a hardware fact: whether this device has touch hardware
## of its own, read once the same way `hud._debug` is. It answers exactly one question, in
## `_input()` — whether a real `InputEventScreenTouch` is on offer at all, and therefore whether a
## same-instant emulated `InputEventMouseButton` from that same finger has to be ignored rather
## than read as a second, doubling press (`_test_a_touch_devices_own_emulated_click_is_ignored`).
## It decides **nothing** about where a heading is measured from any more.
##
## **`_mode` (`ControlsMode.Mode`) is the player's own choice, set once from outside through
## `set_mode()` — see that function's own doc — and it is what `_on_tap()`, `_on_drag()` and
## `_draw()` actually branch on.** *(2026-09-07, the player: "joystick is the two focal point mode
## and tap is the mouse mode. both modes for in both settings so let's let the player choose
## instead of forcing one ... independent of whether tap is available".)* A touchscreen set to
## `TAP` aims from her own world position exactly as a mouse always has; a mouse set to `JOYSTICK`
## aims from a fixed focal point exactly as a real finger does. See `ControlsMode` for what each
## mode means and why neither is tied to a device.
##
## **`Mode.JOYSTICK` aims from whichever of the two fixed focal points, `FOCUS_LEFT` (240, 480) or
## `FOCUS_RIGHT` (1040, 480) in the 1280x720 design box, is nearer the press** — see `nearer_focus()`
## and `_on_tap()`'s own doc for the coordinate-space trip a focus has to take to become a world
## heading. **Both focal points are drawn**, as a ring at `STOP_RADIUS` with a knob at `_direction`
## — see `_draw_focus_circles()`'s own doc. A press within `STOP_RADIUS` of either focus stops her
## too, and so does one in the stop band down the middle of the screen, or a held pointer dragged
## into either — see `is_on_a_focus()`, `is_in_stop_band()` and `_on_drag()`. **A drag that leaves the
## band re-picks which focus its heading is measured from, for whichever side it left on** — see
## `_drag_origin_focus`'s own doc for why crossing the band is safe to retarget on where a bare
## `nearer_focus()` on every motion event was not.
##
## **`Mode.TAP` aims from her own world position instead, and draws nothing.** A press within
## `TAP_STOP_RADIUS` of her stops her; the band and the focal circles do not exist in this mode at
## all.
## *(Playtest 29 finding 6, on why a real touch in `JOYSTICK` mode no longer stops on a press near
## her own position: the camera sits on her, so her own screen position already is the band's own
## centre line, and covering that ground twice made a drag crossing her by accident stop her by
## surprise — see `_on_tap()`'s own doc.)* Held down and moved, a pointer in either mode keeps
## re-aiming: the heading updates continuously until it lifts, always at one speed, never a partial
## vector — see `_on_drag()`'s own doc for why that is not the deleted drag stick returning.
##
## **A real key on the arrows or WASD resets whatever a click, tap or drag last locked in, so the
## keys steer alone from that frame.** See `_yield_to_the_keyboard()`'s own doc for the mechanism
## and the ordering trap it exists to avoid — a naive release of the same action a key press just
## set would cancel the key rather than the stale click.
##
## **The pause button is not that kind of control.** `main._unhandled_input()` reads
## `event.is_action_pressed("pause")` off the propagated *event*, not off polled state, so
## `Input.action_press(&"pause")` would set the state and be heard by nothing — the same trap
## `AutoScreenshot._tap()` already names in its own comment for exactly this action. See
## `_send_pause_action()`.
##
## **Drawn on every device, and only while a day is actually being walked.** *(2026-09-06: "I
## specifically said that now all controls are treated the same across platforms so the buttons
## should show in *every* environment.")* `get_tree().paused` is the one fact the title screen, the
## pause and the between-days summary all set, and checking it here is what keeps the button off
## every one of those three screens without a wire from `main` telling it so on each. A
## keyboard-and-mouse desktop draws it too, now that a click sets a direction or stops her the same
## way a finger does: pressing the corner presses the button there exactly as it does on a phone,
## so the corner is subtracted from the aiming surface on every device that shows the button rather
## than only a touch one — see `_on_pointer()`'s own doc for that consequence.
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
## without stopping the day. See `_on_pointer()`.
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

## The disc, the rim and the two bars, baked into one asset — see `_draw_pause_button()`.
const _PAUSE_ICON: Texture2D = preload("res://assets/ui/pause.svg")

## How soon a second press has to land to read as a double, in seconds.
const DOUBLE_TAP_SECONDS := 0.35
## How close the second press has to land to the first, in screen px, to read as the same
## direction doubled rather than a new one. Generous, because a thumb pressing twice does not land
## on the same pixel either time.
const DOUBLE_TAP_DISTANCE := 60.0
## How close a press has to land to a focus or to the middle band, in **design-space** px, to read
## as *stop* rather than a direction in `Mode.JOYSTICK` — `is_on_a_focus()` and `is_in_stop_band()`
## are the only two places this is compared now, and both are design-space questions:
## `is_on_a_focus()` is also the radius `_draw_focus_circles()` draws each ring at, so the ring's
## own edge **is** the boundary between the two doors a press through it can open, rather than an
## arbitrary aesthetic size. The three milestones that added these two doors never named a separate
## figure for either, so one number does both jobs.
##
## **`Mode.TAP`'s own door used to reuse this same number as a world-space distance — see
## `TAP_STOP_RADIUS` for what it uses now.** *(Playtest 34 finding 5: "the stop circle on the
## player should exactly be the size of the joystick stop circle nothing bigger.")* The camera sits
## on her at zoom 2, so 48 world px covered 96 design px on the glass — twice the ring this constant
## actually draws.
const STOP_RADIUS := 48.0

## How close a press has to land to her, in **world** px, to read as *stop* rather than a direction
## in `Mode.TAP` — `_near_her()` is the only place this is compared, since `Mode.TAP`'s aiming
## origin is her own live position rather than a fixed place on the glass, unlike `STOP_RADIUS`'s
## own design-space doors. Half of `STOP_RADIUS` (48 design px): the camera sits on her at zoom 2
## over a 1280x720 viewport (`Tuning.OUT_OF_SIGHT`'s own doc states the same fact for the sight
## radii), so 24 world px covers exactly the same ground on screen as `STOP_RADIUS`'s own drawn
## ring, rather than the 96 design px a bare `STOP_RADIUS` compared in world space used to cover.
##
## **Deliberately short of `Stroller.PRAM_DISTANCE` (34px), not merely short of it by accident.**
## *(Playtest 34 finding 6: "if I click on the stroller it shouldn't stop only when I click on the
## body of the player.")* An earlier version of this doc argued the opposite — that a wider radius
## catching the pram was correct, because a press on the pram is a press on her. It is not: the
## pram is not her, so widening this back toward `PRAM_DISTANCE` to "fix" a stop that looks
## generous undoes exactly what was asked for. Still generous against `Tuning.PLAYER_BODY_RADIUS`
## (14px) alone, for a pointer that does not land on the same world pixel twice.
const TAP_STOP_RADIUS := STOP_RADIUS / 2.0

## How far above her feet `_near_her()` centres the stop circle — half `Stroller.FIGURE_HEIGHT`
## (46px, her own drawn height from the ground point her sprite is anchored at, over the 24x46
## `mother_front_a.svg`). *(Playtest 35 finding 1: "the stop circle for the player is at her feet --
## should be at the center of the sprite -- right now I can click below her to stop.")* `Sprites`'
## own doc states the anchoring this circle used to ignore: "a node's position is where its feet
## are, and its art rises from there." Measured from her bare `global_position`, `TAP_STOP_RADIUS`
## (24px) covered 24px of pavement *below* her feet while her head, 46px above them, sat entirely
## outside it. Centred here instead, the same radius reaches from her shoes to her shoulders and
## stops one pixel below her feet — no new radius, only a new centre.
const TAP_STOP_CENTRE_LIFT := Stroller.FIGURE_HEIGHT / 2.0

## The two fixed points `Mode.JOYSTICK` aims from — see the class doc's own paragraph on why the two
## modes disagree here. *(2026-09-06, the player: "define two points equally apart
## from the border on each side (same distance from top/bottom/and its own side)".)* M83 put each
## the same distance from the top, the bottom and its own side, which made that distance 360 in the
## 1280x720 design box — `(360, 360)` and `(920, 360)`. *(2026-09-07: "Move the center of the focal
## points 1/3 towards the sides and 1/3 towards the bottom of the screen.")* A third of the
## remaining gap to each edge is 120px, so `(240, 480)` and `(1040, 480)` — each still a full 360°
## dial around its own half of the screen, just no longer centred edge-to-edge in either direction.
## Authored in **design space**, not world space: they are a fixed place on the glass, not a place
## in the city, so they have to make the same design→presented→world trip a raw touch's own
## position does — see `_on_tap()`'s own doc.
const FOCUS_LEFT := Vector2(240.0, 480.0)
const FOCUS_RIGHT := Vector2(1040.0, 480.0)

## The knob `_draw_focus_circles()` offsets from each focus, at rest. Sized off `PAUSE_RADIUS`'s
## own third — small enough that a knob pressed out to `STOP_RADIUS * 0.6` still sits well inside
## its own ring rather than crowding the rim.
const _FOCUS_KNOB_RADIUS := PAUSE_RADIUS / 3.0

## Hardware only — see the class doc's own paragraph on what this decides and what it no longer
## does. Read once into a member the same way `TouchInput.available()` already is everywhere else
## it is asked, since a headless test process is never a touch device.
var _touch := TouchInput.available()

## The player's own choice of aiming origin — see the class doc and `ControlsMode`. Defaults to
## `TAP`, the same default `ControlsMode.resolve()` falls back to, so a test or a rig that never
## calls `set_mode()` gets the mode every existing screenshot and `--walk` script was taken under.
## In the running game this default is never actually observed: `main._add_touch_controls()` calls
## `set_mode(ControlsMode.resolve())` immediately after building this node, and
## `main._on_title_start()` calls it again the moment a player actually presses one of the title
## screen's two buttons — see those functions' own docs for why this cannot be read once at
## `_ready()` the way `_touch` is: the title screen answers the question at runtime, well after
## this node already exists.
var _mode := ControlsMode.Mode.TAP

## Sets the aiming origin a press and a drag measure their heading from — the one seam `main` uses
## to hand this node the player's own choice, since nothing here can read a title screen's button
## press on its own. `queue_redraw()` because `_draw()` only re-runs on request and the focal
## circles (`_draw_focus_circles()`) exist only in `Mode.JOYSTICK`.
func set_mode(mode: ControlsMode.Mode) -> void:
	_mode = mode
	queue_redraw()

## Whether `main` has decided a portrait touch window is presenting rotated — see
## `ScreenOrientation`. Set from outside rather than asked here, the same way `_touch` is a read
## of a platform fact rather than a query at each use site: `main._apply_orientation()` is the one
## place that knows the window's own shape, and the pause button's own touch handling goes through
## `ScreenOrientation.to_design_space()` with this flag before comparing a raw press to
## `PAUSE_CENTRE`, which stays authored in the unrotated 1280x720 box regardless. A direction press
## needs no such remap — it is turned straight into a world position through the viewport's own
## canvas transform, which already carries the rotation.
var rotated := false

## The touch or pointer index currently down on the pause button, or -1 when nothing is. Going down
## does not press anything — see `_on_pointer()` for why the action only fires on release, and only
## if that release is still over the button.
var _pause_touch := -1

## The rig, found the same way `HUD._rig` is: a state of the player rather than something a
## signal carries.
var _rig: Node2D

## Locked in at the last press; never touched again until the next press releases or replaces it.
var _direction := Vector2.ZERO
var _walking := false
## Whether this node itself currently holds the `run` action pressed — set alongside `_direction`
## in `set_direction()`, cleared wherever `_direction` is. Tracked rather than read back off
## `Input.is_action_pressed(&"run")`, which cannot tell this node's own press from `Tuning`'s Shift
## binding: see `_yield_to_the_keyboard()`'s own doc for why that distinction is the whole fix.
var _run_active := false

## The previous press's own moment and screen position, for the double-tap windows. `-INF` reads as
## "no earlier press this run", which can never fall inside either window.
var _last_tap_at := -INF
var _last_tap_screen_position := Vector2.ZERO

## The pointer index currently re-aiming a held direction with every motion event — a real touch's
## own `InputEventScreenTouch.index`, or `_MOUSE_POINTER_INDEX` for a held left mouse button — or
## -1 when nothing is. Set at every press that reaches `_on_tap()` (a stop as much as a walk — see
## its own doc), and cleared on the matching release, in `_on_pointer()`. *(2026-09-07: "dragging
## the finger doesn't work anymore but should", and "although dragging a mouse should reaim as
## well".)*
var _drag_pointer_index := -1
## Which focus `_drag_pointer_index`'s own heading is measured from, in **design space** — the
## fixed place on the glass `_on_tap()` chose in `Mode.JOYSTICK` (`nearer_focus()`, at the moment
## the press landed), or `Vector2.INF` ("her own position") in `Mode.TAP`, the same sentinel
## `set_direction()`'s own `from` parameter already reads that way.
##
## **Design space, not world, and that is the whole of the fix playtest 34 findings 7 and 9 asked
## for.** *(2026-09-07: "I cannot drag around the joystick circle and it follows the whole way. it
## moves a bit and then moves completely differently from what my movement is.")* A focus is a
## fixed place on the glass, not a place in the city — converting it to world space once, the way
## the very first version of this drag did, leaves that world point behind in the street the moment
## she starts walking and the camera moves with her, so the reference drifts out from under the
## thumb a heading later. Kept in design space here, `_on_drag()` redoes the same design→presented→
## world trip `_on_tap()` makes, every motion event instead of once, so the reference stays under
## the drawn ring for exactly as long as the ring stays under the thumb.
##
## **Sticky for the whole drag, except across the stop band.** *(Playtest 35 finding 4: "dragging
## from one side of the screen to the other side of the screen keeps the reference on the original
## side. this might make sense were it not for the stop gap in the middle... I think we should
## retarget to the other side when that happens.")* M85 made this sticky in the first place because
## `nearer_focus()` on every motion event flipped the instant a press crossed the design box's own
## centre line — a heading measured from `FOCUS_LEFT` swapping for one from `FOCUS_RIGHT`, and back,
## while the thumb barely moved; its own note records hysteresis and a stickier focus as rejected,
## in favour of declaring the middle "not a direction at all." **The band is what makes retargeting
## safe now, where a bare crossing was not**: a pointer cannot reach the far side of the centre line
## without first passing through `STOP_RADIUS` either side of it, and inside that band she is
## stopped — so a crossing is a discrete, already-stopped event with a defined middle, not a
## continuous slide between two references with nothing between them to flip against. `_drag_in_band`
## is what `_on_drag()` reads to fire the re-pick exactly once, on the frame the pointer actually
## leaves the band, rather than on every motion event inside or outside it — see that variable's own
## doc for why a pointer wiggling at the band's own edge cannot oscillate between the two foci.
var _drag_origin_focus := Vector2.INF

## Whether the drag `_drag_pointer_index` is tracking currently has its pointer standing inside the
## stop band — `Mode.JOYSTICK` only, since `Mode.TAP` has no band. Set the moment a press or a drag
## step lands in the band, cleared the moment one leaves it; `_on_drag()` reads the falling edge —
## band **and now not** — to re-pick `_drag_origin_focus` via `nearer_focus()` for whichever side the
## pointer left on, and nowhere else, so the sticky rule still holds for a drag that never enters the
## band at all.
##
## **Why a pointer cannot oscillate between the two foci by wiggling at the band's own edge.**
## `nearer_focus()` ties only exactly on the design box's own centre line (640, the midpoint of
## `FOCUS_LEFT` and `FOCUS_RIGHT`), which sits 48px inside either edge of the band — so *every* point
## outside the band already lies unambiguously nearer to whichever focus is on its own side. Leaving
## the band can therefore only ever re-pick the focus that matches the side actually left on; picking
## the *other* focus would require the pointer to cross the band's full 96px width in one step, which
## is exactly the deliberate, already-stopped crossing this feature exists to retarget on, not a
## flicker at one edge of it.
var _drag_in_band := false
## Whether `_drag_pointer_index`'s own press doubled into a run — carried through every motion
## event so re-aiming never itself starts or stops holding `run`; only a fresh press does.
var _drag_run := false

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

## The pause button's own visibility, gated on pause only — every device shows it now, not only a
## touch one. Any pause landing, on any device, force-releases whatever direction and `run` were
## held: the tree pausing is the one signal both halves of this file share, so it is what
## `_release_all()` is hung off rather than the visibility toggle alone.
func _process(_delta: float) -> void:
	var paused := get_tree().paused
	var showing := not paused
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
## in `tests/test_touch.gd`. Both branches feed `_on_pointer()`, which is what checks `visible`
## for the pause button: the button is drawn on every device now, so a mouse press has to be
## checked against it exactly as a finger's press is, not only a direction press kept working on a
## device that never draws anything at all.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_on_pointer(touch.position, touch.pressed, touch.index)
	elif event is InputEventScreenDrag:
		# A finger still down, moving — see `_on_drag()`'s own doc. Godot never sends this for a
		# mouse; a held left button's own motion arrives as `InputEventMouseMotion` below instead.
		var drag := event as InputEventScreenDrag
		_on_drag(drag.position, drag.index)
	elif not _touch and event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index == MOUSE_BUTTON_LEFT:
			_on_pointer(click.position, click.pressed, _MOUSE_POINTER_INDEX)
	elif not _touch and event is InputEventMouseMotion:
		# The mouse's own half of the drag — *(2026-09-07: "although dragging a mouse should reaim
		# as well".)* Only while the left button is actually held: `button_mask` is a snapshot of
		# every button down at the moment of this motion, not just the one that started a press.
		var motion := event as InputEventMouseMotion
		if motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_on_drag(motion.position, _MOUSE_POINTER_INDEX)
	elif event is InputEventKey and event.pressed and not (event as InputEventKey).echo:
		_yield_to_the_keyboard(event as InputEventKey)

## Stands in for the touch index a mouse event carries none of — the same role `PauseScreen
## ._MOUSE_HOLD_INDEX` plays for the restart button's own hold. Needed now that the pause button is
## drawn on every device: a mouse press near the corner has to be tracked by `_pause_touch` the same
## way a finger holding it would be, rather than always falling through to `_on_tap()`.
const _MOUSE_POINTER_INDEX := -2

## A press or release, from a real finger or — now that the button is drawn on every device — a
## left click standing in for one. **The corner is subtracted from the aiming surface only while
## the button is actually showing** (`visible`, `not get_tree().paused`) — pressing where it would
## be while the button is not currently drawn is an ordinary direction press, same as anywhere
## else. `index` is `InputEventScreenTouch.index` for a real finger or `_MOUSE_POINTER_INDEX` for a
## click, so both share the one piece of state (`_pause_touch`) that tracks which of them is
## currently holding the button.
func _on_pointer(position: Vector2, pressed: bool, index: int) -> void:
	if pressed:
		if visible:
			# The one correction a rotated presentation needs on the input side — see
			# `ScreenOrientation`'s own doc for why this is the only file in `src/ui/` that needs it.
			var design := ScreenOrientation.to_design_space(position, rotated)
			if _pause_touch == -1 and design.distance_to(PAUSE_CENTRE) <= PAUSE_CATCH_RADIUS:
				# Only grabs the index here — see `_send_pause_action()`'s doc for why
				# nothing fires until the matching release.
				_pause_touch = index
				queue_redraw()
				return
		_on_tap(position, Time.get_ticks_msec() / 1000.0)
		# Tracked whether this press walked or stopped her — see `_on_tap()`'s own doc for where
		# `_drag_origin_focus`/`_drag_run` were just set for this same press. *(Playtest 34 finding
		# 8: "when I start dragging from the center of the joystick nothing happens it should
		# behave the same as if I move to the center and back stop while I'm in the center and move
		# when I'm back.")* A stop used to leave nothing tracked, so a finger landing in a circle
		# was never followed and every motion event after it was discarded — see `_on_drag()`'s own
		# doc for the boundary crossing this now makes live in both directions.
		_drag_pointer_index = index
		return
	if index == _drag_pointer_index:
		_drag_pointer_index = -1
	if index == _pause_touch:
		_pause_touch = -1
		queue_redraw()
		# Fires on release rather than on press, and only when the release itself is still over
		# the button, so a press that lands wrong can slide off and lift without stopping the day.
		var design := ScreenOrientation.to_design_space(position, rotated)
		if _pause_fires(design):
			_send_pause_action()

## A press arrived at `screen_position` -- the same canvas-space coordinate the event itself
## carries, whatever the window's own rotation -- at moment `now`.
##
## `get_viewport().get_canvas_transform().affine_inverse()` maps it to a world position: the exact
## reverse of what `DangerEdge` and `HomeArrow` already do every frame to place a screen cue from a
## world one, so this tracks the camera, the zoom and the rotated presentation with nothing of its
## own to keep in step. Otherwise it locks in a heading.
##
## **Where that heading is measured from, and what stops her instead, are the two places the two
## modes disagree — and both are the same disagreement seen twice.** *(Playtest 29 finding 6;
## 2026-09-07: "with that we can remove tap the player to stop since it's the same area ... mouse
## click doesn't have the band and will keep the click the player to stop behavior".)* `Mode.TAP`
## aims from her own world position, exactly as a mouse always has, and a press within
## `TAP_STOP_RADIUS` of that same position stops her rather than steering her — the one door this
## mode has, since its aiming origin already *is* her. `Mode.JOYSTICK` instead aims from the nearer of
## `FOCUS_LEFT`/`FOCUS_RIGHT`, and is stopped by a press on either focus (`is_on_a_focus()`) or in
## the stop band down the middle of the screen (`is_in_stop_band()`) — not by a press near her own
## position any more, since the band already covers that ground (the camera sits on her, so her own
## screen position is the band's own centre line) and covering it twice is what made a drag crossing
## her by accident stop her by surprise.
##
## Locating the nearer focus is the one place the coordinate-space trap in those constants' own doc
## actually has to be walked through, because the two spaces cannot be mixed:
## - "which focus is nearer" and "is this press on a focus" are asked in **design space**, the
##   1280x720 box the two constants are authored in and where "half the screen" means half the
##   screen — `ScreenOrientation.to_design_space(screen_position, rotated)` is what gets there.
## - the heading itself needs the focus in **world space**, the same space `target` (the press) is
##   already in. A design-space subtraction would ignore the camera, the zoom and — on a rotated
##   presentation — literally point the wrong way, since the design box does not carry the
##   rotation. So the chosen focus makes the same round trip a raw touch's own position takes, the
##   other direction: design → presented (`ScreenOrientation.to_presented_space()`, the inverse of
##   `to_design_space()`) → world (`_focus_world()`, the same canvas-transform inverse used above).
##
## `now` is a parameter rather than read from `Time` in here, so a test can hold the double-tap
## window still instead of racing the engine clock -- `_input()` and `_on_pointer()` are the real
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
	if _mode == ControlsMode.Mode.TAP:
		# Set before the stop check, not after — see `_drag_origin_focus`'s own doc. A stop is now
		# tracked into a drag exactly as a walk is (playtest 34 finding 8), so both branches leave a
		# correct reference behind for `_on_drag()` to pick up.
		_drag_origin_focus = Vector2.INF
		_drag_run = double
		if _near_her(world):
			_stop()
			return
		set_direction(world, double)
		return
	# Mode.JOYSTICK, past here — see the class doc and this function's own doc above.
	var design := ScreenOrientation.to_design_space(screen_position, rotated)
	var focus := nearer_focus(design)
	_drag_origin_focus = focus
	_drag_in_band = is_in_stop_band(design)
	_drag_run = double
	if is_on_a_focus(design) or is_in_stop_band(design):
		_stop()
		return
	set_direction(world, double, _focus_world(focus))

## The design→presented→world trip a fixed focus takes to become a heading's own origin — the same
## trip `_on_tap()`'s own doc walks through, pulled out here so `_on_drag()` can redo it every
## motion event instead of once. `focus_design` is a **design-space** point (`FOCUS_LEFT`,
## `FOCUS_RIGHT`, or whatever `nearer_focus()` chose); the camera, the zoom and any rotation are
## applied fresh each call, which is what keeps the reference under the drawn ring for as long as
## the ring stays under the thumb — see `_drag_origin_focus`'s own doc for what goes wrong when
## this trip is made once and cached instead.
func _focus_world(focus_design: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() \
			* ScreenOrientation.to_presented_space(focus_design, rotated)

## Whether `world` lands within `TAP_STOP_RADIUS` of the centre of her sprite — `TAP_STOP_CENTRE_LIFT`
## above her feet, not her bare `global_position` (see that constant's own doc for why) —
## `Mode.TAP`'s own door into `_stop()`, asked identically by `_on_tap()`'s opening press and by
## `_on_drag()`'s own live boundary crossing (playtest 34 finding 8's "in the centre is stopped, out
## of it is walking that way, and crossing the boundary either way changes it live", read as applying
## to `Mode.TAP`'s one door the same way it applies to `Mode.JOYSTICK`'s two).
func _near_her(world: Vector2) -> bool:
	var centre := _rig.global_position - Vector2(0.0, TAP_STOP_CENTRE_LIFT)
	return world.distance_to(centre) <= TAP_STOP_RADIUS

## A finger or a held left mouse button, still down and moving, at `screen_position` — the drag
## stick's replacement, and the reason it survives
## `_test_no_input_path_presses_a_vector_shorter_than_one` is the whole of the difference from it:
## this recomputes a heading through `set_direction()`, which always normalises, rather than
## pressing a partial vector for a thumb short of some rim. *(2026-09-07: "dragging the finger
## doesn't work anymore but should", and "although dragging a mouse should reaim as well".)*
##
## Every motion event for `_drag_pointer_index` moves the heading toward wherever the pointer now
## is, from `_drag_origin_focus` — the same focus `_on_tap()` chose in `Mode.JOYSTICK` (converted
## to world space fresh, through `_focus_world()`, rather than once at the press — see that
## variable's own doc), or her own live position in `Mode.TAP`. **Crossing back into the stop door
## mid-drag stops her, and dragging back out resumes steering, live** — playtest 34 finding 8's own
## words, and the reason this checks the same doors `_on_tap()` does rather than only the band.
## The direction otherwise locks in as it stands the moment the pointer lifts, since nothing
## further happens on release beyond forgetting the index in `_on_pointer()`.
##
## **Leaving the band re-picks `_drag_origin_focus`, once, on the falling edge of `_drag_in_band`.**
## *(Playtest 35 finding 4.)* Landing in the band sets `_drag_in_band` and stops her, exactly as
## before; the first motion event that lands outside it again re-picks the focus through
## `nearer_focus()` before steering resumes, and every motion event after that — until the band is
## entered again — leaves `_drag_origin_focus` alone, which is the sticky rule surviving everywhere
## else. See that variable's own doc for why this cannot flip-flap at the band's own edge.
func _on_drag(screen_position: Vector2, index: int) -> void:
	if index != _drag_pointer_index or get_tree().paused:
		return
	if not _rig:
		return
	var world := get_viewport().get_canvas_transform().affine_inverse() * screen_position
	if _mode == ControlsMode.Mode.JOYSTICK:
		var design := ScreenOrientation.to_design_space(screen_position, rotated)
		if is_in_stop_band(design):
			_drag_in_band = true
			_stop()
			return
		if is_on_a_focus(design):
			_stop()
			return
		if _drag_in_band:
			_drag_origin_focus = nearer_focus(design)
			_drag_in_band = false
		set_direction(world, _drag_run, _focus_world(_drag_origin_focus))
		return
	if _near_her(world):
		_stop()
		return
	set_direction(world, _drag_run)

## Locks in the heading toward `target` from `from` — computed once here and never again, so a
## shove that knocks her off the line does not silently correct itself, the same way walking into a
## wall and stopping is the player's mistake to make. `run` holds the same `run` action Shift does,
## until the next press changes the direction or stops her — there is nothing to arrive at that
## would let go of it on its own.
##
## `from` defaults to `Vector2.INF`, read as "her own world position" — `Mode.TAP`'s own aiming
## point, and every caller's that never sets it explicitly, since `Vector2.INF` can never be a
## real focus or a real press. `_on_tap()` and `_on_drag()` are the only two callers that ever pass
## something else: a focus already converted to world space, in `Mode.JOYSTICK`.
##
## A press exactly on `from` has no heading to compute and stops her instead, the same case
## `_near_her()`'s own `TAP_STOP_RADIUS` check already catches for a `Mode.TAP` press a pixel's-width
## away from her — this is the fallback for the one caller (a test) that calls straight in with an
## exact point.
func set_direction(target: Vector2, run: bool, from := Vector2.INF) -> void:
	if not _rig:
		_rig = get_tree().get_first_node_in_group("player") as Node2D
	if not _rig:
		return
	var origin := _rig.global_position if from == Vector2.INF else from
	var direction := heading_to(target, origin)
	if direction == Vector2.ZERO:
		_stop()
		return
	_direction = direction
	_walking = true
	_set_axis(&"move_left", &"move_right", direction.x)
	_set_axis(&"move_up", &"move_down", direction.y)
	_run_active = run
	if run:
		Input.action_press(&"run")
	else:
		Input.action_release(&"run")
	# The two focal circles read `_direction` and `run` straight off this node — see
	# `_draw_focus_circles()` — and `_draw()` only re-runs on request.
	queue_redraw()

## Lets go of whatever direction and `run` were held, with nothing pressed in their place — the
## door every one of `_on_tap()`'s own stop conditions goes through.
func _stop() -> void:
	_walking = false
	_direction = Vector2.ZERO
	_run_active = false
	_release_movement()
	queue_redraw()

## The keyboard resets whatever heading a click, tap or drag last locked in. *(PLAYTEST-57: "arrow
## keys should reset any mouse click position. when pressing awsd or arrow keys right now the last
## pressed mouse position is still active resulting in incorrect / drifting movement.")* A pointer
## press locks a heading in by pressing `move_*` actions synthetically (`_set_axis()`, called from
## `set_direction()`), and `Stroller._physics_process()` reads the same four actions through
## `Input.get_vector()`, which sums over *everybody* currently pressing them — so a real key adds
## to, rather than replaces, whatever a click left behind, and she drifts toward neither heading.
##
## **Releasing this node's own synthetic press is only safe for an action the key itself did not
## just set.** The trap: `Input`'s polled state for an action is updated before any node's
## `_input()` sees the event that changed it, so a naive `Input.action_release()` on the same
## action the key press just set would cancel the key that is now actually held, not the click
## that is stale. `_our_pressed_move_actions()` names exactly what this node itself is holding down
## from the last `set_direction()` call — never derived from a real key's own state, which `Input`
## already tracks correctly and this never has to touch — and every entry that is not `key`'s own
## action is released. An entry that *is* that action is left alone, because the real key is now
## the one holding it, which is already the direction she should walk.
##
## Also drops any drag still in flight, so a finger or a held mouse button left down cannot re-aim
## over the keyboard a frame later, and this node's own `run` press from a double click or tap —
## `_run_active`, never a bare `Input.action_release(&"run")`, for the same reason as the move
## actions: a real Shift held at the same moment is not this node's to release. Zeroing `_direction`
## and `_walking` is what lets the drawn focus knob (`Mode.JOYSTICK`) read as centred — stopped and
## keyboard-driven — rather than still pointing at a heading the keys have already overridden.
## Harmless when nothing was ever clicked: both sets are already empty, so pure keyboard play never
## reaches past the first `return` below.
func _yield_to_the_keyboard(key: InputEventKey) -> void:
	if get_tree().paused:
		return
	var pressed_action: StringName = &""
	for action in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		if key.is_action(action, true):
			pressed_action = action
			break
	if pressed_action == &"":
		return
	for action in _our_pressed_move_actions():
		if action != pressed_action:
			Input.action_release(action)
	if _run_active:
		Input.action_release(&"run")
		_run_active = false
	_drag_pointer_index = -1
	_walking = false
	_direction = Vector2.ZERO
	queue_redraw()

## Exactly the `move_*` actions this node itself currently holds pressed, derived from `_direction`
## rather than kept as a second copy of it — `_set_axis()` is what `set_direction()` presses these
## through, and it presses at most one of each opposing pair, matching `_direction`'s own sign on
## each axis. Empty once `_direction` is `Vector2.ZERO`, which `_stop()` and `_release_all()` both
## already set.
func _our_pressed_move_actions() -> Array[StringName]:
	var found: Array[StringName] = []
	if _direction.x > 0.0:
		found.append(&"move_right")
	elif _direction.x < 0.0:
		found.append(&"move_left")
	if _direction.y > 0.0:
		found.append(&"move_down")
	elif _direction.y < 0.0:
		found.append(&"move_up")
	return found

## The unit vector from `from` to `target`, or `Vector2.ZERO` for a press with nowhere to go.
static func heading_to(target: Vector2, from: Vector2) -> Vector2:
	var offset := target - from
	return offset.normalized() if offset.length() > 0.001 else Vector2.ZERO

## The nearer of `FOCUS_LEFT`/`FOCUS_RIGHT` to `design_position`, which must already be in the
## 1280x720 design box — see `_on_tap()`'s own doc for the coordinate-space trip that takes. Pure
## and static, like `heading_to()`/`is_double_tap()`, so this geometry is testable with no viewport
## and no rig at all. Ties go to `FOCUS_LEFT`; the two are 560px apart and a tie only happens
## exactly on the design box's own centre line, which is not a press either focus would rather own.
static func nearer_focus(design_position: Vector2) -> Vector2:
	return FOCUS_LEFT if design_position.distance_to(FOCUS_LEFT) \
			<= design_position.distance_to(FOCUS_RIGHT) else FOCUS_RIGHT

## Whether `design_position` (already in design space) lands within `STOP_RADIUS` of either focal
## point — one of the two doors `_on_tap()` and `_on_drag()` stop her through in `Mode.JOYSTICK`,
## alongside the stop band (`is_in_stop_band()`). *(2026-09-06, the player: "tapping in their
## center or on the player should stop the player still".)*
static func is_on_a_focus(design_position: Vector2) -> bool:
	return design_position.distance_to(FOCUS_LEFT) <= STOP_RADIUS \
			or design_position.distance_to(FOCUS_RIGHT) <= STOP_RADIUS

## Whether `design_position` (already in design space) lands in the stop band down the middle of
## the screen — the third door into `_stop()`, beside a press on her and a press on either focus.
## *(2026-09-07: "there should be a narrow band in the middle of the screen (size of the stop
## circle) that stops the player. this is to prevent moving the finger over the middle of the
## screen and quickly flicking back and forth.")*
##
## **This is what makes the drag usable, not a decoration on top of it.** `nearer_focus()` flips
## the instant a press crosses the design box's own centre line, so a finger wandering near the
## middle mid-drag would otherwise swap a heading measured from `FOCUS_LEFT` for one measured from
## `FOCUS_RIGHT` — pointing somewhere entirely different — and snap back and forth while barely
## moving. Declaring the middle "not a direction at all" removes the flip rather than damping it.
##
## `STOP_RADIUS` either side of the centre line, reading *"size of the stop circle"* as its
## **diameter** — confirmed by the player rather than inferred — so the band has the same reach
## either side of the line that a stop circle has around its own centre. The centre line is
## `ScreenOrientation.DESIGN_SIZE.x / 2.0` (640 in the 1280x720 design box) rather than a bare
## 640, so this stays correct if the design box's own width ever does not. **Not drawn** —
## *(2026-09-07: "the band doesn't get drawn and yes it's the diameter in size".)* the two focal
## circles are what item 2 asked for by name, and stay the only things this scheme draws besides
## the pause button.
##
## **Asked for the focus sticky for the whole drag · overturned to re-picking it on 2026-09-07,
## because the band this constant governs turns a crossing into a discrete, already-stopped event
## with nothing left in the middle to flip against.** M85 made the focus sticky because a bare
## `nearer_focus()` on every motion event flipped the instant a press crossed the design box's own
## centre line, snapping the heading to the other side while a thumb barely moved, and recorded
## hysteresis and a stickier focus as rejected in favour of this band. Playtest 35 finding 4 asks for
## the crossing back on the strength of the band itself: a pointer cannot reach the far side of the
## centre line without passing through this band first, and inside it she is already stopped, so
## leaving it — not merely touching the centre line — is safe to re-pick a focus on. See
## `_drag_origin_focus`'s own doc for the safety argument and `_on_drag()` for where the re-pick
## fires.
static func is_in_stop_band(design_position: Vector2) -> bool:
	return absf(design_position.x - ScreenOrientation.DESIGN_SIZE.x / 2.0) <= STOP_RADIUS

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
	_drag_pointer_index = -1
	_walking = false
	_direction = Vector2.ZERO
	_run_active = false
	_release_movement()
	queue_redraw()

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

## The pause button, and — in `Mode.JOYSTICK` — the two focal circles. Not every pixel of the city
## is an undrawn direction any more: see `_draw_focus_circles()`'s own doc for why that mode needs
## something to read the locked-in state off, and why `Mode.TAP` does not.
func _draw() -> void:
	if not visible:
		return
	_draw_pause_button()
	if _mode == ControlsMode.Mode.JOYSTICK:
		_draw_focus_circles()

## The disc, its rim and the two bars — a preloaded SVG asset (`assets/ui/pause.svg`), not painted
## in code. *(Playtest 29 finding 3: "neither should the buttons use draw commands -- I explicitly
## said that icons/symbols do not count as graphics".)* This is not a `ModeButton`, so there is no
## `Button` icon or `icon_normal_color` to tint through here; the held/idle contrast the old
## `draw_circle()`/`draw_arc()`/`draw_rect()` calls carried as two different alpha values on the
## disc alone is instead one overall alpha `draw_texture_rect()`'s own modulate colour multiplies
## the whole texture by, which is why `pause.svg`'s own three shapes already carry their relative
## opacities against each other (dim disc, mid rim, bright bars) — see that file's own comment.
##
## **The held alpha step (0.7 idle, 1.0 held) is not what "lights up white" asks for on its own.**
## *(2026-09-07: "buttons should light up white when pressed.")* Going more opaque makes the icon
## solid, not bright — a `ModeButton`'s own pressed answer is a **fill**, `Palette.BUTTON_PRESSED`,
## behind its glyph, and this button has no `StyleBox` to hold one. `draw_circle()` behind the icon
## is that fill's own shape, in the same colour every other pressed button now reaches for, layout
## rather than a picture — the same reading the **cues** rule's own exception gives
## `_draw_focus_circles()`'s ring.
func _draw_pause_button() -> void:
	var held := _pause_touch != -1
	if held:
		draw_circle(PAUSE_CENTRE, PAUSE_RADIUS, Palette.BUTTON_PRESSED)
	var size := Vector2(PAUSE_RADIUS, PAUSE_RADIUS) * 2.0
	draw_texture_rect(TextureResolver.resolve(_PAUSE_ICON), Rect2(PAUSE_CENTRE - size * 0.5, size), false,
			Color(1.0, 1.0, 1.0, 1.0 if held else 0.7))

## Both focal points, always, in `Mode.JOYSTICK` — M83 drew nothing for them and left *whether they
## can be found by feel* as the played question the next report would answer; the answer is no.
## *(2026-09-07: "show the control circles again on both sides so the user can see what is
## currently locked in.")*
##
## **What is drawn is the state, not only the place.** Each ring is `STOP_RADIUS` itself — the same
## radius a press has to land inside to stop her — so the ring's own edge is the boundary between
## the two doors a press through it can open, rather than an arbitrary aesthetic size. The knob
## inside is `_direction`, the one heading this whole scheme ever holds, read identically off
## either circle: there is one direction locked in, not one per focus, so the two always agree.
## Centred (no offset) reads as *stopped*; a knob toward the rim reads as *walking that way*;
## brighter and larger while `run` is held, since a hold on the run action is as much a part of
## "what is locked in" as the heading is.
##
## **Primitives, not an SVG, and that is the cues rule's own exception rather than a violation of
## it.** A knob whose offset is a continuous function of `_direction` cannot be a static asset any
## more than `ModeButton`'s own hold-progress sweep can — see that class's comment for the same call
## made there: "a fill that is not a drawing of anything is not a picture." This ring and its knob
## are that shape, not a glyph's.
func _draw_focus_circles() -> void:
	var running := Input.is_action_pressed(&"run")
	var knob_radius := _FOCUS_KNOB_RADIUS * (1.3 if running else 1.0)
	var knob_colour := Color(1.0, 1.0, 1.0, 1.0 if running else 0.8)
	var offset := _direction * (STOP_RADIUS * 0.6)
	for focus in [FOCUS_LEFT, FOCUS_RIGHT]:
		draw_arc(focus, STOP_RADIUS, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.35), 2.0, true)
		draw_circle(focus + offset, knob_radius, knob_colour)
