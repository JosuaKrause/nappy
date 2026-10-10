class_name TouchControls
extends Control
## Pointer steering, a hold-to-run half opposite the steering side, and pause.
##
## A tap or drag locks a unit heading until the next steering action. In joystick mode the title
## chooses which half steers and the other half is Run, for the whole sitting: *(2026-10-10, the
## player: "we don't allow switching joystick and run key. the decision is mad on the title screen
## ... selecting the left one will make the left side permanently joystick and the right side
## permanently run button (permanently for the sitting)")*. `set_mode()` is the only way the side
## changes; no press, tap or drag in play moves it, and from the first frame of play one ring steers
## and the other focus is Run. Keys change the heading, never the side.
##
## The steering half reaches two thirds of the way to Run's focus (`STEERING_REACH`), with a stop
## band at its edge; everything beyond that edge is Run's, so a press there holds Run and never
## steers. Each pointer keeps the role its press gave it until release: a steering drag that
## wanders onto Run's half still steers, and a run finger never steers. A double press
## independently latches run. A release re-aims a steering drag at the point it lifted, so a swipe
## through the dead zone that lands outside it walks toward the landing point. Button catches reach
## at least 5% beyond their painted radius (`ButtonGeometry`) and never less than they did before
## that rule (pause keeps its 46px); the dead zone does not. Tap mode instead aims
## from the player's world position.
##
## Raw input is shared by mouse and touch; emulated mouse events are ignored on touch devices.
## ALWAYS processing releases input when paused, hidden or ending a day. Pause restores the
## locked heading, but never resurrects a held finger.

## The pause disc's painted radius, smaller than the joystick-sized Run disc.
const PAUSE_RADIUS := 26.0
## The catch is the larger of the 46px a thumb always had here and 1.05 times the painted radius
## (27.3px), so it is 46px — and it is also the radius a *release* has to land inside to fire, so a
## thumb that lands wrong can slide off and lift without stopping the day. See `_on_pointer()`.
const PAUSE_OLD_CATCH_RADIUS := 46.0
const PAUSE_CATCH_RADIUS := maxf(PAUSE_OLD_CATCH_RADIUS, PAUSE_RADIUS * ButtonGeometry.CATCH_SCALE)
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

## The disc, the rim and the two bars, baked into one asset — see `_draw_pause_button()`. A region
## name on the `ui` atlas group; `_enter_tree()`/`_exit_tree()` acquire and release it.
const _PAUSE_ICON := &"ui/pause"
## The run button's disc, rim and two chevrons (`art/ui/run.svg`), the same kind of region on the same
## group — see `_draw_run_buttons()`.
const _RUN_ICON := &"ui/run"

## How soon a second press has to land to read as a double, in seconds.
const DOUBLE_TAP_SECONDS := 0.35
## How close the second press has to land to the first, in screen px, to read as the same
## direction doubled rather than a new one. Generous, because a thumb pressing twice does not land
## on the same pixel either time.
const DOUBLE_TAP_DISTANCE := 60.0
## The joystick ring's drawn radius, in **design-space** px, and the half-width of the stop band
## at the steering half's edge. The band was asked for at the stop circle's size *(2026-09-07: "a
## narrow band in the middle of the screen (size of the stop circle) that stops the player")*, when
## the stop circle and the ring were both 48px. The stop circle is now the tighter dead zone, and
## keeping the band at the ring's width is the filer's proposal, open to overturn; see
## `is_in_stop_band()`. Run's disc is sized off this ring.
const RING_RADIUS := 48.0

## How close a press has to land to the steering focus, in **design-space** px, to stop her rather
## than steer — the joystick's dead zone, drawn as its own circle inside `RING_RADIUS`.
## *(2026-10-10, the player: "decrease the deadzone of the joystick (which makes the player stop)
## smaller/tighter".)* No number was named; two thirds of the ring keeps a thumb-sized stop target
## while leaving a band of steering inside the ring. `in_dead_zone()` is the only place it is
## compared. It never takes `ButtonGeometry.CATCH_SCALE`: it is steering geometry, not a button.
const DEAD_ZONE_RADIUS := 32.0

## How far the steering half reaches toward Run's focus, as a fraction of the distance between the
## two foci. *(2026-10-10, the player: "we can even increase the influence zone of the joystick
## (instead of splitting the in middle we can move it closer to the run button; although I wouldn't
## go all the way)".)* Two thirds puts the edge at x≈773 with the left side steering, about 216px
## short of Run's painted rim, and at x≈507 with the right side steering. See `boundary_x()`.
const STEERING_REACH := 2.0 / 3.0

## How close a press has to land to her, in **world** px, to read as *stop* rather than a direction
## in `Mode.TAP` — `_near_her()` is the only place this is compared, since `Mode.TAP`'s aiming
## origin is her own live position rather than a fixed place on the glass. Half of
## `DEAD_ZONE_RADIUS`: the camera sits on her at zoom 2 over a 1280x720 viewport
## (`Tuning.OUT_OF_SIGHT`'s own doc states the same fact for the sight radii), so this covers
## exactly the joystick's dead zone on screen. *(Playtest 34 finding 5: "the stop circle on the
## player should exactly be the size of the joystick stop circle nothing bigger.")* So it tightens
## whenever the joystick's dead zone does.
##
## **Deliberately excludes the visible pram's side-view centre.** *(Playtest 34 finding 6: "if I
## click on the stroller it shouldn't stop only when I click on the body of the player.")* The
## stop circle is lifted 23px above her feet while the side-view pram shares her ground line;
## together with its 24px horizontal offset, its centre is about 33px from this circle's centre,
## outside this radius. Still a little wider than `Tuning.PLAYER_BODY_RADIUS` (14px), for a pointer
## that does not land on the same world pixel twice.
const TAP_STOP_RADIUS := DEAD_ZONE_RADIUS / 2.0

## How far above her feet `_near_her()` centres the stop circle — half `Stroller.FIGURE_HEIGHT`
## (46px, her own drawn height from the ground point her sprite is anchored at, over the 24x46
## `mother_front_a.svg`). *(Playtest 35 finding 1: "the stop circle for the player is at her feet --
## should be at the center of the sprite -- right now I can click below her to stop.")* `Sprites`'
## own doc states the anchoring: "a node's position is where its feet are, and its art rises from
## there." Centred on her feet, the circle would cover pavement below her while her head sat
## outside it; centred here, `TAP_STOP_RADIUS` (16px) covers her body from 7px to 39px above her
## feet.
const TAP_STOP_CENTRE_LIFT := Stroller.FIGURE_HEIGHT / 2.0

## The two fixed points `Mode.JOYSTICK` aims from — see the class doc's own paragraph on why the two
## modes disagree here. *(2026-09-06, the player: "define two points equally apart
## from the border on each side (same distance from top/bottom/and its own side)".)* M83 put each
## the same distance from the top, the bottom and its own side, which made that distance 360 in the
## 1280x720 design box — `(360, 360)` and `(920, 360)`. *(2026-09-07: "Move the center of the focal
## points 1/3 towards the sides and 1/3 towards the bottom of the screen.")* A third of the
## remaining gap to each edge is 120px, so `(240, 480)` and `(1040, 480)`. The title draws its two
## joystick buttons on these same points, so the button pressed is where that side's ring appears.
## Authored in **design space**, not world space: they are a fixed place on the glass, not a place
## in the city, so they have to make the same design→presented→world trip a raw touch's own
## position does — see `_on_tap()`'s own doc.
const FOCUS_LEFT := Vector2(240.0, 480.0)
const FOCUS_RIGHT := Vector2(1040.0, 480.0)

## The joystick ring's stroke reaches one pixel beyond `RING_RADIUS`. Run's disc matches that
## visible outer edge, rather than the SVG's transparent texture bounds. Run needs no catch radius
## of its own: its whole half catches a run press (`is_on_run_side()`), which holds the disc and
## 1.05 times its radius on both sides (`tests/test_touch.gd` pins it).
const FOCUS_STROKE_WIDTH := 2.0
const RUN_RADIUS := RING_RADIUS + FOCUS_STROKE_WIDTH * 0.5
## The dead zone's own circle, thinner and fainter than the ring around it so the two read as one
## control with a smaller centre rather than two rings.
const _DEAD_ZONE_STROKE_WIDTH := 1.5
## Both pause.svg and run.svg paint to radius 62.5 on a 128px square.
const _ICON_PAINTED_RADIUS := 62.5
const _ICON_HALF_SIZE := 64.0
## The knob `_draw_focus_circles()` offsets from the steering focus, at rest. Sized off
## `PAUSE_RADIUS`'s own third, so even the larger running knob at `_FOCUS_KNOB_OFFSET` stays
## inside the ring rather than crowding the rim.
const _FOCUS_KNOB_RADIUS := PAUSE_RADIUS / 3.0
## How far the knob sits from the focus while she walks: just past the dead zone's circle, where a
## steering press itself lands, rather than straddling it.
const _FOCUS_KNOB_OFFSET := DEAD_ZONE_RADIUS + (RING_RADIUS - DEAD_ZONE_RADIUS) * 0.25

## Hardware only — see the class doc's own paragraph on what this decides and what it no longer
## does. Read once into a member the same way `TouchInput.available()` already is everywhere else
## it is asked, since a headless test process is never a touch device.
var _touch := TouchInput.available()

## The player's own choice of aiming origin — see the class doc and `ControlsMode`. Defaults to
## `TAP`, the same default `ControlsMode.resolve()` falls back to, so a test or a rig that never
## calls `set_mode()` gets the mode every existing screenshot and `--walk` script was taken under.
## In the running game this default is never actually observed: `main._add_touch_controls()` calls
## `set_mode()` with `ControlsMode.resolve()` immediately after building this node, and
## `main._on_title_start()` calls it again the moment a player actually presses one of the title
## screen's buttons — see those functions' own docs for why this cannot be read once at
## `_ready()` the way `_touch` is: the title screen answers the question at runtime, well after
## this node already exists.
var _mode := ControlsMode.Mode.TAP

## The focus `Mode.JOYSTICK` steers from, `FOCUS_LEFT` or `FOCUS_RIGHT`; Run is the other one. Set
## only by `set_mode()`, from the side the title chose, and never by a press.
var _steering_focus := FOCUS_LEFT

## Sets the aiming origin a press and a drag measure their heading from, and in `Mode.JOYSTICK` the
## side that steers — the one seam `main` uses to hand this node the player's own choice, since
## nothing here can read a title screen's button press on its own. A change of either lets go of
## whatever is held, since a finger on Run would otherwise keep running from the wrong half.
## `queue_redraw()` because `_draw()` only re-runs on request and the ring and Run disc exist only
## in `Mode.JOYSTICK`.
func set_mode(mode: ControlsMode.Mode, side := ControlsMode.Side.LEFT) -> void:
	var focus := FOCUS_RIGHT if side == ControlsMode.Side.RIGHT else FOCUS_LEFT
	if mode != _mode or focus != _steering_focus:
		_release_all()
		_direction_before_pause = Vector2.ZERO
		_run_before_pause = false
	_mode = mode
	_steering_focus = focus
	if mode != ControlsMode.Mode.JOYSTICK:
		# The buttons exist only in `JOYSTICK`; a finger still down on one must not keep running on.
		_let_go_of_the_run_button()
	queue_redraw()

## The scheme in force, for the help lines that name a button only one scheme draws — see
## `HelpText.joystick_in_force()`.
func controls_mode() -> ControlsMode.Mode:
	return _mode

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

## Every touch or pointer index currently holding a run button, and whether any hold is what keeps
## `run` pressed. A list rather than one index, so that handing the button from one thumb to the
## other (the second lands before the first lifts) never drops the run. Separate from `_run_active` (a double press's latch): either one
## keeps `run` down, and letting go of one must not release the other. See the class doc.
var _run_touches: Array[int] = []
var _run_held := false

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
## Whether `_drag_pointer_index`'s own press doubled into a run — carried through every motion
## event so re-aiming never itself starts or stops holding `run`; only a fresh press does.
var _drag_run := false

var _was_paused := false

func _enter_tree() -> void:
	AtlasLibrary.acquire(&"ui")

func _exit_tree() -> void:
	AtlasLibrary.release(&"ui")

func _ready() -> void:
	add_to_group(HelpText.CONTROLS_GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Pinned to the fixed design box rather than full-rect, so this node's own ancestor
	# `CanvasLayer` (set up in `main._add_touch_controls()`) has a stationary 1280x720 footprint to
	# rotate rather than one that resizes itself to whatever `content_scale_size` currently is —
	# see `ScreenOrientation.pin_to_design_box()`.
	ScreenOrientation.pin_to_design_box(self)
	visible = false
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_release_all()

## The pause button's own visibility, gated on pause only — every device shows it now, not only a
## touch one. Any pause landing, on any device, force-releases whatever direction and `run` were
## held: the tree pausing is the one signal both halves of this file share, so it is what
## `_release_all()` is hung off rather than the visibility toggle alone.
func _process(_delta: float) -> void:
	var paused := get_tree().paused
	var showing := not paused
	if showing != visible:
		visible = showing
	if paused and not _was_paused:
		_release_all()
	_was_paused = paused
	if showing:
		# Every frame, not only on a change here — see `_draw_focus_circles()`'s own doc.
		# `current_heading()` reads `Input.get_vector()` fresh each time, and a real key can change
		# that between two presses this node itself handles, with no event of its own to redraw on
		# (a key release is not routed to `_yield_to_the_keyboard()` at all). The same reason
		# `DangerEdge` and `HomeArrow` redraw every frame while active: something that is not this
		# node's own state can change what they draw.
		queue_redraw()

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
		if get_tree().paused:
			# A press that lands while a screen has the day paused never reaches the world —
			# `_on_tap()`'s own guard already no-ops it, and this returns *before* the pause
			# button's own corner catch or `_drag_pointer_index` below, rather than after.
			# **This is the fix for M127's "already walking" report.** Without this early
			# return, a press dismissing a screen (the title's own disc, the summary's
			# continue, the pause's own continue) still fell through to `_drag_pointer_index
			# = index` below and armed drag-tracking for this pointer even though `_on_tap()`
			# did nothing with the press itself — so a finger or a mouse button still down a
			# frame or two later, once the screen's own two-frame acknowledge delay has
			# unpaused the tree, generates an ordinary `InputEventScreenDrag`/
			# `InputEventMouseMotion` for the *same* index, `_on_drag()` reads it as a live
			# re-aim (nothing about it said "this pointer's opening press was swallowed"), and
			# she starts the resumed day walking toward wherever that follow-up nudge landed.
			# A single pixel of sensor noise was enough — confirmed against a scratch rig that
			# reproduced it every time a motion event followed the dismiss press by as little
			# as (2, 1)px, which is why the report reads as *always* rather than *sometimes* on
			# a real touchscreen, where a finger held for even a couple of frames essentially
			# never reports the exact same point twice.
			return
		# The one correction a rotated presentation needs on the input side — see
		# `ScreenOrientation`'s own doc for why this is the only file in `src/ui/` that needs it.
		var design := ScreenOrientation.to_design_space(position, rotated)
		if visible and _pause_touch == -1 \
				and design.distance_to(PAUSE_CENTRE) <= PAUSE_CATCH_RADIUS:
			# Only grabs the index here — see `_send_pause_action()`'s doc for why
			# nothing fires until the matching release.
			_pause_touch = index
			queue_redraw()
			return
		if _mode == ControlsMode.Mode.JOYSTICK and is_on_run_side(design, _steering_focus):
			# A press that *begins* on Run's half, and only that, holds `run` — never a direction,
			# whatever the drawn disc covers, so the steering finger's drag and the double-tap
			# clock are left alone. A second finger there joins the first rather than being read as
			# a heading, and `run` lasts while any finger holds it.
			if not _run_touches.has(index):
				_run_touches.append(index)
				_run_held = true
				Input.action_press(&"run")
				queue_redraw()
			return
		_on_tap(position, Time.get_ticks_msec() / 1000.0)
		# Tracked whether this press walked or stopped her — see `_on_tap()`'s own doc for where
		# `_drag_run` was just set for this same press. *(Playtest 34 finding 8: "when I start
		# dragging from the center of the joystick nothing happens it should behave the same as if
		# I move to the center and back stop while I'm in the center and move when I'm back.")* A
		# press in the dead zone is followed like any other, so dragging out of it steers.
		#
		# **Never armed for a press `get_tree().paused` already refused above** — the same press
		# this line's own `_on_tap()` call just turned into a no-op. Arming a drag off a press the
		# world never saw is exactly the M127 leak: see the guard above this call.
		_drag_pointer_index = index
		return
	if index == _drag_pointer_index:
		if _mode == ControlsMode.Mode.JOYSTICK:
			# The release is the drag's last position. *(2026-10-10, the player: "make sure swiping
			# over it but landing outside of it correctly keeps the player moving in the direction
			# of the final position".)* A fast swipe can lift before any motion event reports where
			# it ended, leaving the heading on whatever the dead zone last said; re-aiming at the
			# lift point walks her toward it, or stops her if it lifted inside the dead zone. Not
			# in `Mode.TAP`, whose origin is her moving position: a finger held still while she
			# walked up to it would stop her on lifting.
			_on_drag(position, index)
		_drag_pointer_index = -1
	if _run_touches.has(index):
		# Lifting anywhere lets go, not only over the button: the hold began on it, and a thumb that
		# drifted off while running should not leave `run` stuck down. Run ends with the last finger.
		_run_touches.erase(index)
		if _run_touches.is_empty():
			_let_go_of_the_run_button()
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
## mode has, since its aiming origin already *is* her. `Mode.JOYSTICK` instead aims from the
## steering focus the title chose, and is stopped by a press in its dead zone (`in_dead_zone()`) or
## in the stop band at the steering half's edge (`is_in_stop_band()`) — not by a press near her own
## position, which a drag crossing her by accident would otherwise stop her on by surprise. A press
## on Run's half never reaches this function: `_on_pointer()` gives it to Run.
##
## The joystick's geometry is where the coordinate-space trap in those constants' own doc actually
## has to be walked through, because the two spaces cannot be mixed:
## - "is this press in the dead zone or the band" is asked in **design space**, the 1280x720 box the
##   constants are authored in and where "two thirds of the way to Run" means what it says —
##   `ScreenOrientation.to_design_space(screen_position, rotated)` is what gets there.
## - the heading itself needs the focus in **world space**, the same space `target` (the press) is
##   already in. A design-space subtraction would ignore the camera, the zoom and — on a rotated
##   presentation — literally point the wrong way, since the design box does not carry the
##   rotation. So the steering focus makes the same round trip a raw touch's own position takes, the
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
	# Set before the stop check, not after: a stop is tracked into a drag exactly as a walk is
	# (playtest 34 finding 8), so a drag out of a stop carries the press's own run.
	_drag_run = double
	if _mode == ControlsMode.Mode.TAP:
		if _near_her(world):
			_stop()
			return
		set_direction(world, double)
		return
	# Mode.JOYSTICK, past here — see the class doc and this function's own doc above.
	var design := ScreenOrientation.to_design_space(screen_position, rotated)
	if in_dead_zone(design, _steering_focus) or is_in_stop_band(design, _steering_focus):
		_stop()
		return
	set_direction(world, double, _focus_world(_steering_focus))

## The design→presented→world trip a fixed focus takes to become a heading's own origin — the same
## trip `_on_tap()`'s own doc walks through, pulled out here so `_on_drag()` can redo it every
## motion event instead of once. `focus_design` is a **design-space** point (`FOCUS_LEFT` or
## `FOCUS_RIGHT`); the camera, the zoom and any rotation are applied fresh each call, which is what
## keeps the reference under the drawn ring for as long as the ring stays under the thumb.
## *(Playtest 34: "I cannot drag around the joystick circle and it follows the whole way. it moves
## a bit and then moves completely differently from what my movement is.")* A focus converted to
## world space once is left behind in the street the moment she walks and the camera follows her.
func _focus_world(focus_design: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() \
			* ScreenOrientation.to_presented_space(focus_design, rotated)

## Whether `world` lands within `TAP_STOP_RADIUS` of the centre of her sprite — `TAP_STOP_CENTRE_LIFT`
## above her feet, not her bare `global_position` (see that constant's own doc for why) —
## `Mode.TAP`'s own door into `_stop()`, asked identically by `_on_tap()`'s opening press and by
## `_on_drag()`'s own live boundary crossing (playtest 34 finding 8's "in the centre is stopped, out
## of it is walking that way, and crossing the boundary either way changes it live", read as applying
## to `Mode.TAP`'s one door the same way it applies to `Mode.JOYSTICK`'s dead zone and band).
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
## is, from the steering focus in `Mode.JOYSTICK` (converted to world space fresh, through
## `_focus_world()`) or her own live position in `Mode.TAP`. **Crossing into the dead zone or the
## band mid-drag stops her, and dragging back out resumes steering, live** — playtest 34 finding
## 8's own words, and the reason this checks the same doors `_on_tap()` does. A steering drag that
## wanders past the band onto Run's half keeps steering from the same focus: the pointer's role
## was set by its press, and the sides never swap during play. `_on_pointer()` calls this once
## more with the release position in `Mode.JOYSTICK`, so the heading locks in toward where the
## pointer lifted.
func _on_drag(screen_position: Vector2, index: int) -> void:
	if index != _drag_pointer_index or get_tree().paused:
		return
	if not _rig:
		return
	var world := get_viewport().get_canvas_transform().affine_inverse() * screen_position
	if _mode == ControlsMode.Mode.JOYSTICK:
		var design := ScreenOrientation.to_design_space(screen_position, rotated)
		if in_dead_zone(design, _steering_focus) or is_in_stop_band(design, _steering_focus):
			_stop()
			return
		set_direction(world, _drag_run, _focus_world(_steering_focus))
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
	if run or _run_held:
		Input.action_press(&"run")
	else:
		Input.action_release(&"run")
	# The ring and the Run disc read `_direction` and `run` straight off this node — see
	# `_draw_focus_circles()` — and `_draw()` only re-runs on request.
	queue_redraw()

## Lets go of whatever direction and `run` were held, with nothing pressed in their place — the
## door every one of `_on_tap()`'s own stop conditions goes through.
func _stop() -> void:
	_walking = false
	_direction = Vector2.ZERO
	_run_active = false
	_release_movement()
	if _run_held:
		# A stop is about the heading; the finger on a run button is still down.
		Input.action_press(&"run")
	queue_redraw()

## Where Run's disc is drawn: the focus opposite the steering one in `Mode.JOYSTICK`, from the
## first frame of play, or `Vector2.INF` in `Mode.TAP`, which draws no disc.
func run_button_center() -> Vector2:
	if _mode != ControlsMode.Mode.JOYSTICK:
		return Vector2.INF
	return run_focus_for(_steering_focus)

## Lets go of a run button's hold. `run` itself stays down if a double press's latch still wants it.
func _let_go_of_the_run_button() -> void:
	var was_held := _run_held
	_run_touches.clear()
	_run_held = false
	if was_held and not _run_active:
		Input.action_release(&"run")
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
## and `_walking` matters for this node's own bookkeeping only now — what a later stop or release has
## left to undo — **not** for what the ring draws: `_draw_focus_circles()` reads
## `current_heading()` off `Input.get_vector()` directly, every frame, so the knob already shows
## wherever the keys just pointed her without anything here telling it to. Harmless when nothing
## was ever clicked: both sets are already empty, so pure keyboard play never reaches past the first
## `return` below.
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
		if not _run_held:
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

## Run's focus for a given steering focus: the other of `FOCUS_LEFT`/`FOCUS_RIGHT`. Pure and static,
## like `heading_to()`/`is_double_tap()`, as is the rest of the joystick's geometry below, so it is
## testable with no viewport and no rig; every point is in the 1280x720 design box — see
## `_on_tap()`'s own doc for the coordinate-space trip that takes.
static func run_focus_for(steering: Vector2) -> Vector2:
	return FOCUS_LEFT if steering == FOCUS_RIGHT else FOCUS_RIGHT

## The x of the steering half's edge: `STEERING_REACH` of the way from the steering focus to Run's.
static func boundary_x(steering: Vector2) -> float:
	return lerpf(steering.x, run_focus_for(steering).x, STEERING_REACH)

## Whether `design_position` lies beyond the steering half's edge, on Run's side. Everything there
## is Run's: a press there holds run and never steers *(2026-10-10, the player: "the right side
## permanently run button")*. The edge itself still belongs to steering.
static func is_on_run_side(design_position: Vector2, steering: Vector2) -> bool:
	var beyond := design_position.x - boundary_x(steering)
	return beyond > 0.0 if run_focus_for(steering).x > steering.x else beyond < 0.0

## Whether `design_position` lands in the steering focus's dead zone, `DEAD_ZONE_RADIUS` around
## it — one of the two doors `_on_tap()` and `_on_drag()` stop her through in `Mode.JOYSTICK`,
## beside the stop band. *(2026-09-06, the player: "tapping in their center or on the player should
## stop the player still".)* Run's focus has no dead zone: a press there is Run's.
static func in_dead_zone(design_position: Vector2, steering: Vector2) -> bool:
	return design_position.distance_to(steering) <= DEAD_ZONE_RADIUS

## Whether `design_position` lands in the stop band, `RING_RADIUS` either side of the steering
## half's edge — the other door into `_stop()`. *(2026-09-07: "there should be a narrow band in the
## middle of the screen (size of the stop circle) that stops the player. this is to prevent moving
## the finger over the middle of the screen and quickly flicking back and forth.")* It moved from the
## middle to the edge with the steering half's reach. The player confirmed the band's width as the
## stop circle's **diameter** *(2026-09-07: "the band doesn't get drawn and yes it's the diameter in
## size")* when that circle was the 48px ring. The stop circle is now the 32px dead zone; keeping the
## band at the ring's diameter rather than shrinking it with the dead zone is the filer's proposal,
## open to overturn. **Not drawn**, by the same quote. The half
## of it beyond the edge is on Run's side, so a fresh press there holds Run; only a steering drag
## that wanders in is stopped by it, before it carries on past onto Run's half.
static func is_in_stop_band(design_position: Vector2, steering: Vector2) -> bool:
	return absf(design_position.x - boundary_x(steering)) <= RING_RADIUS

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
	_run_touches.clear()
	_run_held = false
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

## What was locked in the moment `PauseScreen` last called `remember_before_pause()` — read back by
## `resume_after_pause()` once that same screen closes. `Vector2.ZERO`/`false` reads as "she was
## standing," which needs no further distinction from "nothing has been remembered yet": either way
## there is nothing to press back.
var _direction_before_pause := Vector2.ZERO
var _run_before_pause := false

## *"Pause can keep the last direction."* Called by `PauseScreen.open()`, before `_process()`'s own
## pause-transition check reaches `_release_all()` and zeroes `_direction` for the duration of the
## pause exactly as it always has — this stashes what `_release_all()` is about to erase, rather
## than changing what `_release_all()` does, since the day-ending summary and the title screen both
## still want that same zeroing with nothing to restore afterwards. See `resume_after_pause()` for
## the other half.
func remember_before_pause() -> void:
	_direction_before_pause = _direction
	_run_before_pause = _run_active

## The other half of *"Pause can keep the last direction just don't overwrite it from the button
## press."* Called by `PauseScreen.close()`, once the tree is actually running again, so the
## heading that was locked in before the pause is what she walks off with — **not** the press that
## dismissed the screen, which `_on_pointer()`'s own `get_tree().paused` guard already keeps from
## ever being armed for a heading of its own (see that function's own doc). A no-op while standing:
## `_direction_before_pause == Vector2.ZERO` covers both "she was standing" and "nothing was ever
## remembered," and both mean there is nothing to press back.
func resume_after_pause() -> void:
	if _direction_before_pause == Vector2.ZERO:
		return
	_direction = _direction_before_pause
	_walking = true
	_set_axis(&"move_left", &"move_right", _direction.x)
	_set_axis(&"move_up", &"move_down", _direction.y)
	_run_active = _run_before_pause
	if _run_active:
		Input.action_press(&"run")
	else:
		Input.action_release(&"run")
	queue_redraw()

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

## The pause button, and — in `Mode.JOYSTICK` — the steering ring and Run's disc. Not every pixel of
## the city is an undrawn direction any more: see `_draw_focus_circles()`'s own doc for why that
## mode needs something to read the locked-in state off, and why `Mode.TAP` does not.
func _draw() -> void:
	if FrameRecord.on:
		FrameRecord.drew(FrameLedger.DRAWS_OTHER)
	if not visible:
		return
	_draw_pause_button()
	if _mode == ControlsMode.Mode.JOYSTICK:
		_draw_focus_circles()
		_draw_run_button()

## The disc, its rim and the two bars — a region of the baked `ui` atlas page, sourced from
## `art/ui/pause.svg`, not painted in code. *(Playtest 29 finding 3: "neither should the buttons use draw commands -- I explicitly
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
## `_draw_focus_circles()`'s rings.
func _draw_pause_button() -> void:
	var held := _pause_touch != -1
	if held:
		draw_circle(PAUSE_CENTRE, PAUSE_RADIUS, Palette.BUTTON_PRESSED)
	var size := Vector2.ONE * PAUSE_RADIUS * 2.0 * _ICON_HALF_SIZE / _ICON_PAINTED_RADIUS
	draw_texture_rect(AtlasLibrary.region(_PAUSE_ICON), Rect2(PAUSE_CENTRE - size * 0.5, size), false,
			Color(1.0, 1.0, 1.0, 1.0 if held else 0.7))

## Run's disc, on the focus the steering side leaves free, lit while any finger holds Run.
func _draw_run_button() -> void:
	var center := run_button_center()
	if center == Vector2.INF:
		return
	if _run_held:
		draw_circle(center, RUN_RADIUS, Palette.BUTTON_PRESSED)
	var size := Vector2.ONE * RUN_RADIUS * 2.0 * _ICON_HALF_SIZE / _ICON_PAINTED_RADIUS
	draw_texture_rect(AtlasLibrary.region(_RUN_ICON), Rect2(center - size * 0.5, size), false,
			Color(1.0, 1.0, 1.0, 1.0 if _run_held else 0.7))

## The steering ring at `RING_RADIUS`, the dead zone's own fainter circle inside it, and a knob
## at the heading she is actually walking, including keyboard steering and detention — so what she
## is walking can be read off the glass without watching her. Layout rather than a picture, the
## same reading the **cues** rule's exception gives any shape whose position is live state.
func _draw_focus_circles() -> void:
	if not _rig:
		_rig = get_tree().get_first_node_in_group("player") as Node2D
	var running := Input.is_action_pressed(&"run")
	var knob_radius := _FOCUS_KNOB_RADIUS * (1.3 if running else 1.0)
	var knob_colour := Color(1.0, 1.0, 1.0, 1.0 if running else 0.8)
	var offset := current_heading(_rig) * _FOCUS_KNOB_OFFSET
	draw_arc(_steering_focus, RING_RADIUS, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.35),
			FOCUS_STROKE_WIDTH, true)
	draw_arc(_steering_focus, DEAD_ZONE_RADIUS, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.22),
			_DEAD_ZONE_STROKE_WIDTH, true)
	draw_circle(_steering_focus + offset, knob_radius, knob_colour)

## The heading she is actually walking this instant, whichever of the two doors set it: a press or
## drag through `set_direction()` (`_set_axis()` presses these same four actions), or a real key
## through `_yield_to_the_keyboard()` overriding it. `Input.get_vector()` on `move_left`/
## `move_right`/`move_up`/`move_down` is the exact read `Stroller._physics_process()` makes to
## decide her own velocity, so this is not a second, independent notion of "what is pressed" that
## could disagree with it — `.normalized()` on top guarantees a unit vector or exactly
## `Vector2.ZERO`, matching `heading_to()`'s own convention, rather than trusting whatever length a
## diagonal keyboard press or a partial controller strength happens to produce.
##
## **Zero while `rig` is detained, the same door `Stroller._physics_process()` itself reads
## first.** *(Found in review of #412: a key held through a conversation or a capture used to swing
## the knob toward it even though `_detained_for > 0.0` already makes her stand still — the read
## would have disagreed with her own physics, the one thing this function's doc above promises it
## never does.)* `rig` is untyped `Node2D` rather than `Stroller`, matching `_rig`'s own doc: this
## suite's own test rigs are a bare `Node2D` with no `is_detained()` of their own, so `has_method()`
## is the check rather than a cast that would just fail on them, and a rig with nothing to ask
## answers "not detained" — the only sound default for something that cannot be captured at all.
## `null` (a screen with no player in it, or a caller that does not care) answers the same way.
static func current_heading(rig: Node2D = null) -> Vector2:
	if rig != null and rig.has_method(&"is_detained") and bool(rig.call(&"is_detained")):
		return Vector2.ZERO
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down").normalized()
