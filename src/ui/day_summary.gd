extends CanvasLayer
## The screen between days, and the one at the end of a run.
##
## Also the pause: the tree is paused while this is up, so the city keeps its state and the
## day can simply be restarted rather than rebuilt.
##
## `restart_requested` is wired in `main._connect_summary_and_pause_signals()` to the same
## `main._restart_run()` `PauseScreen.restart_requested` reaches — see that function's own doc for
## why the wiring is pulled into one place rather than left beside each screen's own instantiation.

signal continued()
signal restart_requested()

@onready var _root: Control = $Root
@onready var _heading: Label = $Root/Center/Lines/Heading
@onready var _title: Label = $Root/Center/Lines/Title
@onready var _body: Label = $Root/Center/Lines/Body
## Always empty — see `PauseScreen._hint`'s own doc for why the label stays but nothing writes to
## it any more: the continue/restart pair already says what a tap does, and nothing left to say
## here does not name a key.
@onready var _hint: Label = $Root/Center/Lines/Hint
@onready var _buttons: HBoxContainer = $Root/Center/Lines/Buttons
@onready var _continue_column: VBoxContainer = $Root/Center/Lines/Buttons/ContinueColumn
@onready var _continue_button: ModeButton = $Root/Center/Lines/Buttons/ContinueColumn/Continue
@onready var _restart_button: ModeButton = $Root/Center/Lines/Buttons/RestartColumn/Restart

## Whether this device has a touchscreen. Read once from `TouchInput`, the same pattern
## `TitleScreen` and `PauseScreen` each read it once into their own member instead of asking at
## every use site. No longer chooses the hint's own wording (`_hint` is always empty now — see
## its own doc), but still gates `_wants_rotation()` and the mouse branch in
## `_handle_restart_touch()` below.
var _touch := TouchInput.available()

const _DAY_TITLE := {
	GameEnums.DayResult.WON: "She's asleep.",
	GameEnums.DayResult.LOST_CRYING: "Not tonight.",
	GameEnums.DayResult.LOST_TIMEOUT: "Too late.",
	GameEnums.DayResult.LOST_HARD_FAIL: "The day ends here.",
}

const _ENDING_TITLE := {
	GameEnums.Ending.BAD: "You stop going out.",
	GameEnums.Ending.NEUTRAL: "The city is quiet now.",
	GameEnums.Ending.GOOD: "Silence.",
}

## The one line on the ending screen that is not writing.
##
## Every ending title in this file is a **sentence out of the fiction** — *"You stop going out."*,
## *"Silence."* — which is right for what they are and is exactly why they do not read as the end
## of anything on their own. A run that has finished has to say so before it says anything else.
##
## **It is not the same word for all three, and that is a decision rather than the request being
## trimmed.** The screen the complaint came off is the `BAD` one, where the nerves ran out, and
## `GAME OVER` is what that is. Stamping it over a run somebody *won* would be telling them they
## lost. `THE END` is the same size, the same weight and the same job on the other two.
const _ENDING_HEADING := {
	GameEnums.Ending.BAD: "GAME OVER",
	GameEnums.Ending.NEUTRAL: "THE END",
	GameEnums.Ending.GOOD: "THE END",
}

const _ENDING_BODY := {
	GameEnums.Ending.BAD:
		"There is nothing left in you for another walk.\n"
		+ "The city goes on without the two of you in it.",
	GameEnums.Ending.NEUTRAL:
		"She sleeps through most nights now.\n"
		+ "The streets you learned to avoid are empty of everything worth avoiding.\n"
		+ "Nobody is out.",
	GameEnums.Ending.GOOD:
		"The loudspeakers cut out mid-sentence.\n"
		+ "For the first time since the masts went up, you walk home in the quiet.",
}

func _ready() -> void:
	# The summary has to keep running while it pauses everything behind it.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Pinned to the fixed design box, not full-rect, so this layer's own rotation (applied in
	# `main._apply_orientation()`) has a stationary 1280x720 footprint to rotate — see
	# `ScreenOrientation.pin_to_design_box()`.
	ScreenOrientation.pin_to_design_box(_root)
	# Coloured here rather than in the scene so `Palette` stays the one place a runtime colour is
	# decided — which is what its own class comment asks for.
	_heading.add_theme_color_override("font_color", Palette.GAME_OVER)
	_refresh_buttons()
	_root.hide()

## Whether the screen currently up is the ending — read by `_refresh_buttons()` to decide whether
## `_continue_column` shows, and set before `_present()` runs rather than passed as an argument to
## it, since `_present()` is also what `_restart_button.cancel_hold()` and `_continuing`'s own reset
## share and neither of those needs to know which screen raised it.
var _showing_ending := false

## Shown on every device — see `PauseScreen._refresh_buttons()`, the same split on the same
## question, now answered the same way here: one control scheme means the same buttons everywhere.
## Its own function still, for the same reason: a test can call this again after changing what it
## depends on.
##
## **Continue does not show on an ending.** *(Playtest 28 finding 4: "the game over screen cannot
## have a continue button".)* Every other screen this row appears on carries on into a day that
## still has one; an ending has none, and the button was drawn as *continue* while doing exactly
## what the catch-all underneath it already does — restart the run. `_buttons` itself stays
## visible for `_restart_button` even here: *"the restart button, hold and all"* is the player's
## own answer to whether the hold still earns its keep with no day left to protect.
func _refresh_buttons() -> void:
	_buttons.visible = true
	_continue_column.visible = not _showing_ending

func show_day(day: int, result: GameEnums.DayResult, reason: String, nerves: int) -> void:
	# A lost *day* is not the end of a run — there are nerves left, and the screen says so two lines
	# down. The heading belongs to the screen that ends the run and to nothing else.
	_heading.hide()
	_showing_ending = false
	_title.text = _DAY_TITLE.get(result, "The day ends.")
	var lines: Array[String] = ["Day %d of %d" % [day, Tuning.RUN_LENGTH_DAYS]]
	if reason != "":
		lines.append("")
		lines.append(reason)
	lines.append("")
	var retrying := result != GameEnums.DayResult.WON and nerves > 0
	if result == GameEnums.DayResult.WON:
		lines.append("You got her home.")
	else:
		lines.append("Nerves left: %s" % ("*".repeat(nerves) if nerves > 0 else "none"))
	# The calendar does not move on a loss, so the screen says so rather than leaving the player
	# to notice tomorrow that it is still today.
	if retrying:
		lines.append("You try day %d again." % day)
	# The only place the subquest is ever spelled out. In the world it is chalk on a wall.
	if GameState.has_joined_resistance():
		lines.append("")
		lines.append(_resistance_line())
	_body.text = "\n".join(lines)
	# Always empty. *(2026-09-06: "never should it be mentioned to the user".)* `space` still
	# carries on, but the continue/restart pair below already says what a tap does, and nothing
	# left to say here does not name a key — see `PauseScreen._hint`'s own doc for the same call
	# made there.
	_hint.text = ""
	_present()

## The tally, and — the mechanism rather than a courtesy — the chalk mark's own words once a
## pickup has just been touched. Read once and cleared: `GameState.pending_resistance_brief` is
## how she learns what tomorrow wants, since there is no marker anywhere else that would.
func _resistance_line() -> String:
	var lines: Array[String] = []
	if GameState.sabotage_available():
		lines.append("You have done enough. There is one more night.")
	else:
		var done := GameState.resistance_progress
		var lost := GameState.failed_resistance_steps.size()
		var line := "Errands run: %d of %d" % [done, Tuning.RESISTANCE_GOAL]
		if lost > 0:
			line += "   (%d contact%s lost)" % [lost, "" if lost == 1 else "s"]
		lines.append(line)
	if GameState.pending_resistance_brief != "":
		lines.append(GameState.pending_resistance_brief)
		GameState.pending_resistance_brief = ""
	return "\n".join(lines)

## The last screen of a run. `space` — or a tap — goes back to the title, which is where the next
## one begins.
##
## **Not `esc to quit`**, which is not true from here: `Esc` opens the pause, and the pause offers
## `Esc` and `Q`, so a finished run becomes a cycle between two screens with closing the window as
## the only way out. Space dismisses every other screen in the game, so it is the key this one owes
## rather than a new one.
func show_ending(ending: GameEnums.Ending) -> void:
	_heading.text = _ENDING_HEADING.get(ending, "THE END")
	_heading.show()
	_title.text = _ENDING_TITLE.get(ending, "The end.")
	_body.text = _ENDING_BODY.get(ending, "")
	_hint.text = ""
	_showing_ending = true
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
	get_tree().paused = true

func dismiss() -> void:
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
func _acknowledge_and_continue() -> void:
	if _continuing:
		return
	_continuing = true
	_continue_button.force_pressed_look()
	await get_tree().process_frame
	await get_tree().process_frame
	_continue_button.clear_forced_press()
	_continuing = false
	continued.emit()

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
		continued.emit()

## A laptop's own question — there is no hover on a phone. *(Playtest 34 finding 1: "buttons still
## don't light up when pressed or hovered.")* `ModeButton.set_hovered()` is the answer
## `MOUSE_FILTER_IGNORE` already needs for a press, reused here since it silences
## `mouse_entered`/`mouse_exited` exactly as it silences a click.
func _update_hover(position: Vector2) -> void:
	var at := ScreenOrientation.to_design_space(position, _wants_rotation())
	_continue_button.set_hovered(_continue_column.visible \
			and _continue_button.catch_rect().has_point(at))
	_restart_button.set_hovered(_buttons.visible and _restart_button.catch_rect().has_point(at))
