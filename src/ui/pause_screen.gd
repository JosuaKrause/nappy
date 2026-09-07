class_name PauseScreen
extends CanvasLayer
## The pause, and the only one a player can ask for — the between-days summary stops the tree too,
## but nobody chooses when it appears.
##
## It reuses the machinery `main` already built rather than inventing a second kind of paused: the
## tree's own `paused` flag, and `main._pauses_with_the_game()` deciding what that reaches. That
## matters more than it looks — the six-milestone bug M-something-or-other spent a milestone on
## was `process_mode` being inherited, so a pause that paused nothing ran for six milestones with
## the player still walking behind the screen that said the day was over. Anything added under
## `Main` needs that call, and this screen is deliberately **not** given it: a pause screen that
## pauses with the game cannot unpause it.
##
## Quitting keeps its key, one step further in. A run that is abandoned is still a run worth
## reading, so `Telemetry.end_run()` happens on the way out exactly as it did before.

signal resumed()
signal restart_requested()
signal quit_requested()

@onready var _root: Control = $Root
@onready var _dim: ColorRect = $Root/Dim
@onready var _standing: Label = $Root/Center/Lines/Standing
@onready var _body: Label = $Root/Center/Lines/Body
## Always empty. *(2026-09-06: "never should it be mentioned to the user".)* `space`/`esc`/`r`/`q`
## keep working, and the continue/restart pair already says what a tap does — there is nothing
## left for a sentence here to say that does not name a key, so the label stays only to be looked
## at and found blank rather than for a function to keep writing "" into.
@onready var _hint: Label = $Root/Center/Lines/Hint
@onready var _buttons: HBoxContainer = $Root/Center/Lines/Buttons
@onready var _continue_button: ModeButton = $Root/Center/Lines/Buttons/ContinueColumn/Continue
@onready var _restart_button: ModeButton = $Root/Center/Lines/Buttons/RestartColumn/Restart

## Whether `Q` does anything on this platform. Read once from `QuitOption` rather than asked at
## each use site, so a test — never itself a web export — can set this and drive both shapes.
## Gates only whether the key is **handled** in `_unhandled_input()` below; it names nothing on
## screen any more — see `_BODY`'s own doc.
var _can_quit := QuitOption.available()
## Whether this device has a touchscreen. Read once from `TouchInput`, the same pattern
## `_can_quit` follows: a test process is never a touch device. Still gates real platform
## questions elsewhere in this file (`_wants_rotation()`, the mouse branch in
## `_handle_restart_touch()`) even though it no longer chooses between two bodies or two hints.
var _touch := TouchInput.available()

## One body for every device. *(2026-09-06, the player: "in fact I said to remove the keyboard
## inputs altogether but I'm willing to compromise on letting them stay silently".)* The keyboard
## still walks, runs, pauses and restarts — nothing here stops reading `KEY_R`/`KEY_Q` or the
## `move_*`/`run`/`pause` actions a key presses — but nothing on screen names a key any more, so
## the keyboard and touch bodies collapse to the one shape that was always the touch body: naming
## the tap is naming a control every device actually has, since a mouse click reads as one too.
##
## **Says two things and nothing else.** *(2026-09-07: "the movement tutorial should just say 'Tap
## to walk' and 'Double tap to run'. no mention of tapping her or 'that way'.")* The struck clauses
## named a stop she can still ask for — a press within `STOP_RADIUS` of a focal point, or a mouse
## click on her — the same way nothing here has ever named a key: stopping still works, and the
## game simply stops teaching it, exactly as `HUD._teach_the_day()`'s own day-1 line already reads.
const _BODY := "Tap to walk, double tap to run.\n" \
		+ "Walk to calm ground and stay moving; standing still settles nothing."

func _ready() -> void:
	# Above the world and above the HUD, and it must keep running while everything else stops.
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Pinned to the fixed design box, not full-rect, so this layer's own rotation (applied in
	# `main._apply_orientation()`) has a stationary 1280x720 footprint to rotate — see
	# `ScreenOrientation.pin_to_design_box()`.
	ScreenOrientation.pin_to_design_box(_root)
	visible = false
	_refresh_body()
	_refresh_buttons()

## Its own function for the same reason it always was: so a test can call this again rather than
## reaching for a fresh scene. No longer branches on `_touch` — see `_BODY`'s own doc.
func _refresh_body() -> void:
	_body.text = _BODY

## Shown on every device — there is one control scheme now, and a press sets a direction on a
## keyboard-and-mouse desktop exactly as it does on a phone, so the same pair of buttons is a
## control there too. *(2026-09-06: "I specifically said that now all controls are treated the
## same across platforms so the buttons should show in *every* environment.")* This overturns
## M76's own reason, taken while a device still chose between two control schemes: *"The
## continue/restart pair only replaces a sentence where there is a thumb to press it with — a
## mouse-and-keyboard desktop keeps `space`/`esc`/`r`, which already read as a control there and
## need no picture beside them."* M82 deleted the choice, so that reason no longer holds. Its own
## function still, so a test can call this again after changing what it depends on.
func _refresh_buttons() -> void:
	_buttons.visible = true

func is_open() -> bool:
	return visible

## Whether the tree was *already* paused when this opened — the between-days summary pauses it too.
##
## Putting back what was found rather than setting `false` is what lets the pause open **over** the
## summary. The alternative, and the first version, was refusing to open there at all, which reads
## as the key being broken on the one screen where somebody most wants it.
var _was_paused := false

## Where the run stands, at the top and in the largest type after the title.
##
## Both numbers are in the HUD, which this screen covers — and the pause is exactly when somebody
## stops to ask *how far in am I and how much of this can I still get wrong*.
##
## Read at `open()` rather than kept in step with `EventBus`, because a screen that is only ever
## looked at while the game is stopped cannot go stale, and a listener that has to be kept correct
## across fourteen days is a listener that will not be.
func _show_where_the_run_stands() -> void:
	var nerves := GameState.nerves
	_standing.text = "Day %d of %d     ·     %s" % [GameState.day, Tuning.RUN_LENGTH_DAYS,
			"last nerve" if nerves == 1 else "%d nerves left" % nerves]

func open() -> void:
	visible = true
	_show_where_the_run_stands()
	_restart_button.cancel_hold()
	# A press that closed this screen before can leave the continue button's own forced-pressed
	# look set — see `_acknowledge_and_resume()`'s own doc for why the frame that would clear it may
	# never actually run before this screen hides. Cleared on the way back in rather than left to
	# leak into the next open.
	_continue_button.clear_forced_press()
	_continue_button.set_hovered(false)
	_restart_button.set_hovered(false)
	_was_paused = get_tree().paused
	# Over the stopped city the dim is a scrim and the street behind it is worth seeing. Over
	# another screen — which is what an already-paused tree means — it is two paragraphs of
	# different text in the same place, so it covers instead.
	_dim.color.a = 1.0 if _was_paused else DIM_OVER_THE_CITY
	get_tree().paused = true

const DIM_OVER_THE_CITY := 0.78

func close() -> void:
	visible = false
	get_tree().paused = _was_paused
	_restart_button.cancel_hold()

## Whether the screen's own layer is presenting rotated — computed fresh rather than pushed in from
## `main`, because `TouchControls` is the only file `main._apply_orientation()` reaches with a
## `rotated` property and this screen is not on that list (see `TouchControls.rotated`'s own doc).
## `ScreenOrientation.wants_rotation()` is a pure function of the same two facts `main` itself asks
## it with, so recomputing it here needs no wire of its own.
func _wants_rotation() -> bool:
	return ScreenOrientation.wants_rotation(get_window().size, _touch)

## The trap this milestone's own design names: `_unhandled_input`'s catch-all below reads **any**
## pressed touch or click as *carry on*, so a held button has to be tested against the press
## position before that branch ever sees the event — the same way `TouchControls._on_pointer()`
## checks a press against its own catch radii before anything else claims it.
##
## **Not a `Button`'s own `pressed`/`button_down` signals.** Godot delivers the screen touch *and*
## an emulated mouse event, and this screen reads the raw touch on purpose. *(Playtest 29 finding
## 2: the comment here used to claim "a `Button` consuming the emulated click would not stop the
## raw touch from reaching the catch-all underneath it" — the raw touch is exactly what a `STOP`
## `mouse_filter` stops, which is what made the buttons unusable until `ModeButton._ready()` set
## `MOUSE_FILTER_IGNORE`.)* With the button no longer claiming anything, this still reads the same
## raw event `_unhandled_input` already does, before the catch-all gets a look at it — the read
## has to happen here regardless of the button's own filter, since a hold spans a press and a
## release and `Button` has no signal for "held for about a second".
##
## **A left click holds it too, on a build with no touch hardware** — the same `not _touch` gate
## `TouchControls._input()` uses for its own mouse branch, and for the same reason: a real touch
## device emulates a mouse click from every finger it reads, so without the gate one hold would be
## granted, released and re-granted through two event types at once. `_MOUSE_HOLD_INDEX` stands in
## for the touch index a mouse event carries none of.
##
## Returns whether `event` belonged to the restart button at all — a press that landed inside its
## `catch_rect()`, or the matching release, whichever way the hold resolves. The caller returns
## without falling through to the catch-all exactly when this is true, so a press that starts a hold
## never also closes the screen underneath it, and a release — met or not — never does either.
func _handle_restart_touch(event: InputEvent) -> bool:
	# `_buttons.visible` rather than `_restart_button.visible`: a `Control`'s own `visible` says
	# nothing about an invisible ancestor, so a button left at its default `true` inside a hidden
	# `_buttons` would still catch a touch meant for the keyboard-only shape underneath it.
	if not _buttons.visible:
		return false
	var position: Vector2
	var pressed: bool
	var index: int
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		position = touch.position
		pressed = touch.pressed
		index = touch.index
	elif not _touch and event is InputEventMouseButton \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var click := event as InputEventMouseButton
		position = click.position
		pressed = click.pressed
		index = _MOUSE_HOLD_INDEX
	else:
		return false
	if pressed:
		var at := ScreenOrientation.to_design_space(position, _wants_rotation())
		if not _restart_button.catch_rect().has_point(at):
			return false
		if not _restart_button.begin_hold(index):
			return false
		get_viewport().set_input_as_handled()
		return true
	if not _restart_button.is_held_by(index):
		return false
	get_viewport().set_input_as_handled()
	if _restart_button.end_hold(index):
		restart_requested.emit()
	return true

## Stands in for the touch index a mouse event carries none of, in `_handle_restart_touch()`'s own
## call to `ModeButton.begin_hold()`/`is_held_by()`/`end_hold()` — distinct from `-1` ("nothing
## held") and from any real touch index, which `InputEventScreenTouch.index` never gives as negative.
const _MOUSE_HOLD_INDEX := -2

## A laptop's own question — there is no hover on a phone, which is why the one call site above is
## gated `not _touch` rather than this. *(Playtest 34 finding 1: "buttons still don't light up when
## pressed or hovered.")* `ModeButton.set_hovered()` is the answer `MOUSE_FILTER_IGNORE` already
## needs for a press, reused here since it silences `mouse_entered`/`mouse_exited` exactly as it
## silences a click.
func _update_hover(position: Vector2) -> void:
	var at := ScreenOrientation.to_design_space(position, _wants_rotation())
	_continue_button.set_hovered(_buttons.visible and _continue_button.catch_rect().has_point(at))
	_restart_button.set_hovered(_buttons.visible and _restart_button.catch_rect().has_point(at))

## Whether an acknowledge-and-resume coroutine is already in flight — guards the same double-fire a
## real touch device's own emulated mouse click could otherwise cause, since `TouchInput.is_press()`
## reads both event types and a device with real touch hardware delivers one of each for a single
## finger.
var _resuming := false

## Flashes the continue button pressed for two frame boundaries before actually resuming — the same
## shape `DaySummary._acknowledge_and_continue()` already uses and for the same reason. *(Playtest
## 34 finding 1: "buttons still don't light up when pressed or hovered.")* `close()` used to run
## synchronously inside the same input-processing pass that set the pressed fill, and Godot never
## draws a frame between one call and the next within a single input dispatch, so the fill was set
## and then hidden again — by `close()`'s own `visible = false` — without a frame ever rendering it.
## Two `process_frame` awaits, not one: `SceneTree.process_frame` fires *before* the frame it names
## is drawn, so the second is what actually lands after the draw that happens between them.
##
## **Fires for a tap or a click anywhere on this screen, not only on the continue button.** The
## catch-all this replaces read any pointer press as *carry on* with nothing tying it to a
## particular button; the flash follows that — landing off the button still shows what a press
## does, the same way `DaySummary`'s own flash already does for its own catch-all.
func _acknowledge_and_resume() -> void:
	if _resuming:
		return
	_resuming = true
	_continue_button.force_pressed_look()
	await get_tree().process_frame
	await get_tree().process_frame
	_continue_button.clear_forced_press()
	_resuming = false
	close()
	resumed.emit()

## `Esc` **or `space`** closes it, `R` starts the whole run again and `Q` leaves the game —
## **except on the web**, where `QuitOption.available()` is false and the key is not handled at
## all. None of the four is named on screen any more — see `_hint`'s own doc — so a keyboard
## player learns them from playing rather than from a sentence, the compromise this milestone
## settled on in place of deleting them outright. Handled here rather than in `main` so that the
## screen owns its own keys while it is up, and `main` only owns the one that opens it.
##
## **`space` continues**, because it is the key the title screen and the between-days summary mean
## *carry on* with: a verb learned on two screens out of three and missing on the third is a verb
## the player has to unlearn. `Esc` keeps working too, because it is the key that opened this and a
## toggle should untoggle.
##
## **`R` restarts the run**, and it is the other half of the dead end the title screen closes. With
## the ending offering `Esc`, `Esc` opening this, and this offering `Esc` and `Q`, there are two
## screens and four keys and no way to play again. A run is also abandonable long before it has
## ended — a day gone wrong on a city you do not want to walk any more is exactly when somebody
## reaches for the pause — so the key belongs here and not only on the ending.
##
## It is deliberately not confirmed. Everything a run holds is a fourteen-day walk with no save in
## it, `R` is not next to `Esc`, and a confirmation on the one key that gets you out of a stuck game
## is a second way to be stuck.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if (event is InputEventScreenTouch or event is InputEventMouseButton) \
			and _handle_restart_touch(event):
		return
	# `Esc` and `space` carry on synchronously, exactly as they always have — a keyboard has no
	# button on screen to flash and no frame needs holding open for it, see
	# `_acknowledge_and_resume()`'s own doc for the one that does.
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		close()
		resumed.emit()
		return
	# A tap or a mouse click carries on exactly as space does. *(2026-09-06: "I still need to press
	# space even in mouse mode".)* The pointer scheme reads a click everywhere now, so this screen
	# has to accept one too rather than leaving the keyboard as the only way past it.
	if TouchInput.is_press(event):
		get_viewport().set_input_as_handled()
		_acknowledge_and_resume()
		return
	if not _touch and event is InputEventMouseMotion:
		_update_hover((event as InputEventMouseMotion).position)
		return
	if not (event is InputEventKey and event.pressed):
		return
	match (event as InputEventKey).keycode:
		KEY_R:
			get_viewport().set_input_as_handled()
			restart_requested.emit()
		KEY_Q:
			if _can_quit:
				get_viewport().set_input_as_handled()
				quit_requested.emit()
