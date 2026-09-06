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
@onready var _hint: Label = $Root/Center/Lines/Hint
@onready var _buttons: HBoxContainer = $Root/Center/Lines/Buttons
@onready var _continue_button: ModeButton = $Root/Center/Lines/Buttons/ContinueColumn/Continue
@onready var _restart_button: ModeButton = $Root/Center/Lines/Buttons/RestartColumn/Restart

## Whether `Q` does anything on this platform. Read once from `QuitOption` rather than asked at
## each use site, so a test — never itself a web export — can set this and drive both shapes.
var _can_quit := QuitOption.available()
## Whether this device has a touchscreen. Read once from `TouchInput`, for the same reason
## `_can_quit` is: a test process is never a touch device, and the body and the hint both have to
## agree with whatever the game is actually played with.
var _touch := TouchInput.available()

const _BODY_KEYBOARD := "Arrows or WASD to walk.\n" \
		+ "Hold Shift to run — it wakes her, so it is rarely worth it.\n" \
		+ "Walk to calm ground and stay moving; standing still settles nothing."
const _BODY_TOUCH := "Tap to walk that way, tap her to stop, double tap to run.\n" \
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
	_refresh_hint()
	_refresh_buttons()

## The keyboard's own three lines, or the one other shape they can be. Its own function for the
## same reason `_refresh_hint()` is one: so a test can flip `_touch` and call this again rather
## than reaching for a fresh scene.
func _refresh_body() -> void:
	_body.text = _BODY_TOUCH if _touch else _BODY_KEYBOARD

## Baked into the scene is only the part that is always true; the rest depends on `_can_quit` and
## `_touch` rather than on anything the scene file can say. `R` restarts and `Esc` is a second way
## to carry on, and neither exists on a device with no keyboard, so the touch hint drops both
## rather than naming a key that is not there — the same defect class `q to quit` was.
##
## **On touch it says nothing at all**, once said `tap to carry on`. Two buttons — see
## `_refresh_buttons()` — now say that, and *"a screen offers something to press"* is this
## milestone's own name for not saying it twice in two different vocabularies at once. `q to quit`
## survives as the one word a button carries no glyph for.
##
## Its own function, rather than inline in `_ready()`, so a test can flip either flag and call
## this again to check the platform shapes agree with `_unhandled_input`'s own gate.
func _refresh_hint() -> void:
	if _touch:
		_hint.text = "q to quit" if _can_quit else ""
		return
	_hint.text = "space or esc to carry on     ·     r to start again"
	if _can_quit:
		_hint.text += "     ·     q to quit"

## The continue/restart pair only replaces a sentence where there is a thumb to press it with — a
## mouse-and-keyboard desktop keeps `space`/`esc`/`r`, which already read as a control there and
## need no picture beside them. Its own function for the same reason `_refresh_hint()` is one: a
## test can flip `_touch` and call this again.
func _refresh_buttons() -> void:
	_buttons.visible = _touch

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
## position before that branch ever sees the event — the same way `TouchControls._on_touch()`
## checks a touch against its own catch radii before anything else claims it.
##
## **Not a `Button`'s own `pressed`/`button_down` signals.** Godot delivers the screen touch *and*
## an emulated mouse event, and this screen reads the raw touch on purpose — a `Button` consuming
## the emulated click would not stop the raw touch from reaching the catch-all underneath it, which
## is exactly the trap. So this reads the same raw event `_unhandled_input` already does, before the
## catch-all gets a look at it.
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

## `Esc` **or `space`** closes it, `R` starts the whole run again and `Q` leaves the game —
## **except on the web**, where `QuitOption.available()` is false, `_ready()` never put "q to
## quit" in the hint, and the key is not handled either. Handled here rather than in `main` so
## that the screen owns its own keys while it is up, and `main` only owns the one that opens it.
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
	# A tap or a mouse click carries on exactly as space does. *(2026-09-06: "I still need to press
	# space even in mouse mode".)* The pointer scheme reads a click everywhere now, so this screen
	# has to accept one too rather than leaving the keyboard as the only way past it.
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_accept") \
			or TouchInput.is_press(event):
		get_viewport().set_input_as_handled()
		close()
		resumed.emit()
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
