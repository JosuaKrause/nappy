extends CanvasLayer
## The screen between days, the one at the end of a run, and the escape's last screen. The escape's
## two sections are days, so their briefs and their outcome screens are a day's, with the section's
## own words where "Day N of 14" stands.
##
## **It only renders.** What a screen says is a `SummaryModel` (`show_summary()`), built by `main`
## from the run, the day's end and `Texts`; the screen breaks its prose between sentences to each
## label's width (`SentenceLines`) and draws it. Which screen it is in the run is the mode
## `RunFlow` raised it in, which the screen hands back with its one continue
## (`continued(raised_in)`).
##
## **A normal run's last nerve comes here as a lost day, not as an ending**: the same screen any
## lost day reaches, saying the day she goes back to and drawing the nerves she has again, with the
## ordinary continue that carries on into it (`SummaryModel.day_over()`, `DayEnd.goes_back`). The
## ending with no continue, `GAME OVER`, is hard mode's alone — see `_refresh_buttons()`.
##
## Also the pause: the tree is paused while this is up, so the city keeps its state and the
## day can simply be restarted rather than rebuilt.
##
## `restart_requested` is wired in `main._connect_summary_and_pause_signals()` to the same
## `main._restart_run()` `PauseScreen.restart_requested` reaches — see that function's own doc for
## why the wiring is pulled into one place rather than left beside each screen's own instantiation.

## The screen's continue, carrying the `RunFlow.Mode` the screen was raised in, as an `int` since a
## cross-script enum is not the same type as itself as a parameter (the **godot** skill).
signal continued(raised_in: int)
signal restart_requested()

@onready var _root: Control = $Root
@onready var _heading: Label = $Root/Center/Lines/Heading
@onready var _title: Label = $Root/Center/Lines/Title
## Empty and hidden except on a day brief given a lost-day note (`SummaryModel.note`) — the one line
## the day brief shows that is not always the same words. Its own label, not folded into `_body`,
## since the two hide independently of each other.
@onready var _note: Label = $Root/Center/Lines/Note
@onready var _body: Label = $Root/Center/Lines/Body
## The morning's own line — one or two plain sentences saying what is true of the city by that
## day, from `Texts.DAY_BRIEF` — its own label, not a line folded into `_body`, because a screen
## full of ordinary lines is exactly what playtest 69 missed it in ("the day text needs to be
## bigger to be able to be noticed"). Bigger and its own color (`Palette.CHALK_DONE`) is what
## makes it the thing the screen is telling you rather than one more line.
##
## **Carries no task, no mark's words and no reminder** (`docs/TODO.md`, M181, the resistance has
## a reason, and a task is one day: "since the task will be immediately announced when touching
## the mark there is no need to mention tasks in the day brief at all"). A task is announced at
## the mark and nowhere else — see `Hud._on_resistance_step_completed()`.
@onready var _brief: Label = $Root/Center/Lines/Brief
## Always empty — see `PauseScreen._hint`'s own doc for why the label stays but nothing writes to
## it any more: the continue/restart pair already says what a tap does, and nothing left to say
## here does not name a key.
@onready var _hint: Label = $Root/Center/Lines/Hint
@onready var _buttons: HBoxContainer = $Root/Center/Lines/Buttons
@onready var _continue_column: VBoxContainer = $Root/Center/Lines/Buttons/ContinueColumn
@onready var _continue_button: ModeButton = $Root/Center/Lines/Buttons/ContinueColumn/Continue
@onready var _restart_button: ModeButton = $Root/Center/Lines/Buttons/RestartColumn/Restart
@onready var _continue_caption: Label = $Root/Center/Lines/Buttons/ContinueColumn/ContinueCaption
@onready var _restart_caption: Label = $Root/Center/Lines/Buttons/RestartColumn/RestartCaption

## Whether this device has a touchscreen. Read once from `TouchInput`, the same pattern
## `TitleScreen` and `PauseScreen` each read it once into their own member instead of asking at
## every use site. No longer chooses the hint's own wording (`_hint` is always empty now — see
## its own doc), but still gates `_wants_rotation()` and the mouse branch in
## `_handle_restart_touch()` below.
var _touch := TouchInput.available()

## Hands the screen the run's answer to the touch question (`TouchInput.available(config)`), which
## `--touch` can force. Called by `main` before the screen enters the tree; a screen built anywhere
## else keeps the hardware's own answer.
func use_touch(touch: bool) -> void:
	_touch = touch

func _ready() -> void:
	# The summary has to keep running while it pauses everything behind it.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Pinned to the fixed design box, not full-rect, so this layer's own rotation (applied in
	# `main._apply_orientation()`) has a stationary 1280x720 footprint to rotate — see
	# `ScreenOrientation.pin_to_design_box()`.
	ScreenOrientation.pin_to_design_box(_root)
	_continue_caption.text = Texts.BUTTON_CONTINUE
	_restart_caption.text = Texts.BUTTON_HOLD_TO_RESTART
	# Coloured here rather than in the scene so `Palette` stays the one place a runtime colour is
	# decided — which is what its own class comment asks for.
	_heading.add_theme_color_override("font_color", Palette.GAME_OVER)
	_brief.add_theme_color_override("font_color", Palette.CHALK_DONE)
	_refresh_buttons()
	# Fires the instant the disc fills, not on release — see `ModeButton.hold_completed`'s own doc.
	_restart_button.hold_completed.connect(func() -> void: restart_requested.emit())
	_root.hide()

## Whether the screen up shows the continue button (`SummaryModel.shows_continue`, false on an
## ending) — read by `_refresh_buttons()`, and set by `show_summary()` before `_present()` runs
## rather than passed to it, since `_present()` is also what `_restart_button.cancel_hold()` and
## `_continuing`'s own reset share and neither of those needs to know which screen raised it.
var _continue_shown := true

## The `RunFlow.Mode` the screen up was raised in, as an `int`, sent back with its continue.
var _raised_in := 0

## Shown on every device — see `PauseScreen._refresh_buttons()`, the same split on the same
## question, now answered the same way here: one control scheme means the same buttons everywhere.
## Its own function still, for the same reason: a test can call this again after changing what it
## depends on.
##
## **Continue does not show on an ending.** *(Playtest 28 finding 4: "the game over screen cannot
## have a continue button".)* Every other screen this row appears on carries on into a day that
## still has one — a normal run out of nerves included, whose lost-day screen carries on into its
## checkpoint, so the game over screen is a hard run's alone; an ending has none, and the button
## was drawn as *continue* while doing exactly what the catch-all underneath it already does —
## restart the run. `_buttons` itself stays
## visible for `_restart_button` even here: *"the restart button, hold and all"* is the player's
## own answer to whether the hold still earns its keep with no day left to protect.
func _refresh_buttons() -> void:
	_buttons.visible = true
	_continue_column.visible = _continue_shown

## Puts `model` on screen, raised in `raised_in` (a `RunFlow.Mode`, as an `int`), and pauses the
## tree behind it. Every label is set from the model, so nothing one screen showed leaks onto the
## next: a hidden heading, note or morning line is one the model leaves empty. The title, the note,
## the morning line and the body's opening prose are broken between sentences to their labels'
## widths (`SentenceLines.break_for_label()`), the title only when it is prose (`title_is_prose`: the
## clock line, a section's words, rather than "Day N of 14" or an ending's title). `_hint` is always
## empty. *(2026-09-06: "never should it be mentioned to the user".)* `space` still carries on, but
## the continue/restart pair already says what a tap does — see `PauseScreen._hint`'s own doc.
func show_summary(model: SummaryModel, raised_in: int) -> void:
	_raised_in = raised_in
	_heading.text = model.heading
	_heading.visible = model.heading != ""
	_title.text = SentenceLines.break_for_label(model.title, _title) if model.title_is_prose \
			else model.title
	_note.text = SentenceLines.break_for_label(model.note, _note)
	_note.visible = model.note != ""
	_body.text = model.body(SentenceLines.break_for_label(model.body_prose, _body))
	_brief.text = SentenceLines.break_for_label(model.brief, _brief)
	_brief.visible = model.brief != ""
	_hint.text = ""
	_continue_shown = model.shows_continue
	_present()

func _present() -> void:
	_root.show()
	_refresh_buttons()
	_restart_button.cancel_hold()
	# A press that dismissed this screen before can leave the continue button's own forced-pressed
	# look set — see `_acknowledge_and_continue()`'s own doc for why the frames that would clear it
	# may never actually run before this screen hides. Cleared on the way back in rather than left
	# to leak into the next day's own summary.
	_continue_button.clear_forced_press()
	_continue_button.set_hovered(false)
	_restart_button.set_hovered(false)
	_continuing = false
	_screen_changes += 1
	get_tree().paused = true

func dismiss() -> void:
	_screen_changes += 1
	_root.hide()
	get_tree().paused = false
	_restart_button.cancel_hold()

func is_showing() -> bool:
	return _root.visible

## Whether the screen's own layer is presenting rotated — computed fresh rather than pushed in
## from `main`, for the same reason `PauseScreen._wants_rotation()` is: `TouchControls` is the only
## file `main._apply_orientation()` reaches with a `rotated` property, and `ScreenOrientation
## .wants_rotation()` is a pure function of the same two facts `main` itself asks it with.
func _wants_rotation() -> bool:
	return ScreenOrientation.wants_rotation(get_window().size, _touch)

## The trap this milestone's own design names, the same one `PauseScreen._handle_restart_touch()`
## guards against: `_unhandled_input`'s catch-all below reads **any** pressed touch or click as
## *carry on*, so a held button has to be tested against the press position before that branch ever
## sees the event. A left click holds it too, gated on `not _touch` for the same reason
## `PauseScreen._handle_restart_touch()`'s own mouse branch is — see that function's own doc,
## including the corrected reasoning for why this reads the raw event rather than a `Button`'s own
## `pressed` signal (Playtest 29 finding 2, `ModeButton._ready()`'s `mouse_filter` fix).
func _handle_restart_touch(event: InputEvent) -> bool:
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
		# **A second touch anywhere while the disc is already held is this button's business too.**
		# *(M212: "sometimes it just doesn't work at all... you have to hold long multiple times".)*
		# The same guard `PauseScreen._handle_restart_touch()` carries — see its own doc. Without
		# this, a stray second finger fails `begin_hold()` below, falls through to the catch-all in
		# `_unhandled_input()`, and reads as *carry on*, continuing past the day out from under a
		# hold already in progress.
		if _restart_button.is_held():
			get_viewport().set_input_as_handled()
			return true
		var at := ScreenOrientation.to_design_space(position, _wants_rotation())
		if not _restart_button.contains_design_point(at):
			return false
		if not _restart_button.begin_hold(index):
			return false
		get_viewport().set_input_as_handled()
		return true
	if not _restart_button.is_held_by(index):
		return false
	get_viewport().set_input_as_handled()
	# The restart itself already fired from `ModeButton.hold_completed` the instant the disc filled,
	# while this same finger or click was still down — see that signal's own doc. This only tears
	# the hold's own state down; calling `restart_requested.emit()` here too would restart twice.
	_restart_button.end_hold(index)
	return true

## Stands in for the touch index a mouse event carries none of — the same role
## `PauseScreen._MOUSE_HOLD_INDEX` plays there, kept as its own constant here rather than shared,
## since each screen already owns a full duplicate of the hold-reading logic rather than one moved
## out to `ModeButton`.
const _MOUSE_HOLD_INDEX := -2

## Whether a `continued` request is already on its way to being acknowledged — the one-frame gap
## `_acknowledge_and_continue()` opens is also one frame in which a second tap can land, and a
## coroutine that has not yet resumed does not stop `_unhandled_input` from reading the next event
## as a fresh press. Without this, a fumbled double-tap starts the day twice.
var _continuing := false

## How many times a screen has been raised or dismissed: what `_acknowledge_and_continue()` compares
## across its two frames to tell whether the screen it acknowledged is still the one up.
var _screen_changes := 0

## Acknowledges a touch before the day it starts costs anything to look at. *(Playtest 27 finding
## 3: a press was not acknowledged, and the wait after it was long.)* `main._on_summary_continued()`
## runs `_start_day()` synchronously in response to `continued` — measured at 610-900ms — and
## nothing was ever rendered between the touch landing and that freeze, because both happened
## inside the same frame's input processing.
##
## **Two awaits, not one, and the difference is load-bearing.** `SceneTree.process_frame` fires
## *before* the frame it names is drawn, not after — confirmed directly with
## `RenderingServer.frame_pre_draw`/`frame_post_draw`, both of which fire only once this coroutine's
## first `await` has already resumed. A single `await get_tree().process_frame` therefore resumes
## and would clear the flash before a single pixel of it ever reached the screen — the mistake this
## function's first version made, caught only by a screenshot that showed no flash at all rather than
## by anything the suite could see. The *second* `process_frame` is what actually lands after the
## draw that happened between the two: the button paints pressed, that frame is drawn, and only then
## does the second await let this go on to clear it. Both fire under `get_tree().paused` — this
## screen's own state throughout — checked directly rather than assumed, since a coroutine that
## never resumed would hang the game on the one screen everybody eventually presses.
##
## **Flashes the continue button even for a press that missed it.** The catch-all below is what
## fires for most presses — nothing requires landing on the button itself — so a `Button`'s own
## native pressed state, which only ever answers a press that actually hit it, would leave a tap on
## the bare scrim with nothing to show for it. `force_pressed_look()` says the same thing regardless
## of where the touch landed.
##
## **Touch and mouse, not the keyboard.** *(Playtest 34 finding 1: "buttons still don't light up
## when pressed or hovered.")* A left click used to fire `continued` directly rather than through
## here — see `_unhandled_input()`'s own doc for why that skipped the flash for a laptop player
## specifically, which is exactly who found it missing. A keyboard has no button on screen to
## flash, and `space` needs no frame held open for it — the keyboard branch below stays exactly as
## synchronous as it always was, since adding a wait with nothing new to show for it is latency
## this path does not need.
##
## **A tap continues the screen it was made on, or nothing.** A key inside the two frames
## continues at once, and that continue dismisses this screen or raises the next one — the ending
## after the run over, the retry's brief after a lost section — so a tap's continue emitted after
## it would continue a screen nobody has read. So the emit is dropped once any screen has been
## raised or dismissed since the tap, whatever did it, and a tap and a key reaching one screen are
## one continue.
func _acknowledge_and_continue() -> void:
	if _continuing:
		return
	_continuing = true
	var acknowledged := _screen_changes
	_continue_button.force_pressed_look()
	await get_tree().process_frame
	await get_tree().process_frame
	if _screen_changes != acknowledged:
		return
	_continue_button.clear_forced_press()
	_continuing = false
	continued.emit(_raised_in)

## Space, a tap, or a mouse click moves on. *(2026-09-06, on a laptop: "I still need to press space
## even in mouse mode".)* **This overturns an earlier reason**: the touch event used to be read
## directly rather than turned into a synthetic click *"so a stray mouse press elsewhere on the
## desktop still cannot skip a summary a player has not read"* — a real concern, taken when no
## control scheme invited a player to use the mouse. The pointer scheme now reads a click
## everywhere, so a laptop player is expected to click, and the screen has to accept one.
##
## **The mouse branch is its own, gated on `not _touch`, rather than folded into `TouchInput
## .is_press()`.** A real touch device emulates a mouse click from every finger it reads, and
## `_acknowledge_and_continue()`'s two-frame delay leaves `is_showing()` true for that whole
## window — long enough for the emulated click to arrive while it is still open. Reading it through
## the same `not _touch` gate `TouchControls` and `PauseScreen`'s own restart hold use means the
## emulated click never reaches a branch at all on a device where a real touch already has, so it
## can never fire `continued` a second time underneath the delay `_continuing` exists to guard. It
## calls the same `_acknowledge_and_continue()` the touch branch does rather than emitting directly
## — see that function's own doc for why a laptop player needs the flash exactly as much as a
## finger does, and why routing through the shared `_continuing` guard here is safe: this branch
## can only ever run on a device with no touch hardware to emulate a click from in the first place.
func _unhandled_input(event: InputEvent) -> void:
	if not is_showing():
		return
	if (event is InputEventScreenTouch or event is InputEventMouseButton) \
			and _handle_restart_touch(event):
		return
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		get_viewport().set_input_as_handled()
		_acknowledge_and_continue()
		return
	if not _touch and event is InputEventMouseButton \
			and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_acknowledge_and_continue()
		return
	if not _touch and event is InputEventMouseMotion:
		_update_hover((event as InputEventMouseMotion).position)
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		continued.emit(_raised_in)

## A laptop's own question — there is no hover on a phone. *(Playtest 34 finding 1: "buttons still
## don't light up when pressed or hovered.")* `ModeButton.set_hovered()` is the answer
## `MOUSE_FILTER_IGNORE` already needs for a press, reused here since it silences
## `mouse_entered`/`mouse_exited` exactly as it silences a click.
func _update_hover(position: Vector2) -> void:
	var at := ScreenOrientation.to_design_space(position, _wants_rotation())
	_continue_button.set_hovered(_continue_column.visible \
			and _continue_button.contains_design_point(at))
	_restart_button.set_hovered(_buttons.visible and _restart_button.contains_design_point(at))
