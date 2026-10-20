extends CanvasLayer
## The screen between days, the one at the end of a run, and the escape's last screen. The escape's
## two sections are days, so their briefs and their outcome screens are a day's, with the section's
## own words where "Day N of 14" stands.
##
## **A normal run's last nerve comes here as a lost day, not as an ending**: the same screen any
## lost day reaches, saying the day she goes back to and drawing the nerves she has again, with the
## ordinary continue that carries on into it (`show_day()`'s `back_to_checkpoint`). The ending with
## no continue, `GAME OVER`, is hard mode's alone — see `_refresh_buttons()`.
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
## Empty and hidden except when `show_day_brief()` is given a lost-day note — the one line the day
## brief shows that is not always the same words, see that function's own doc. Its own label, not
## folded into `_body`, since the two hide independently of each other.
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
## still has one — a normal run out of nerves included, whose lost-day screen carries on into its
## checkpoint, so the game over screen is a hard run's alone; an ending has none, and the button
## was drawn as *continue* while doing exactly what the catch-all underneath it already does —
## restart the run. `_buttons` itself stays
## visible for `_restart_button` even here: *"the restart button, hold and all"* is the player's
## own answer to whether the hold still earns its keep with no day left to protect.
func _refresh_buttons() -> void:
	_buttons.visible = true
	_continue_column.visible = not _showing_ending

## What a saved game opens on instead of starting the day outright, once the title's own start
## button has been pressed — `main._show_the_resume_gate()`'s own call, made after
## `GameState.finish_day()` has already charged whatever the load itself costs, so `day` and
## `nerves` are already the numbers the retry (or the day exactly as the save left it) actually
## has. Three things, no more: the day, the nerves, and the morning's own line from `Texts.DAY_BRIEF`.
## `lost_note` is `Texts.RESUMED_DAY_LOST` when the load itself spent a nerve, or `""` for a
## save that cost nothing, in which case this is exactly what a fresh day 1 skips by going
## straight from the title into `main._engage_the_day()` instead. Continuing from here reaches
## that same function, through `main._on_summary_continued()`'s own `_resume_gate_open` branch —
## the moment the day actually starts, and the moment the save says so.
##
## **`title` is a section of the escape's own words** — *"Escape the building"* or *"Escape the
## city"* (`DaySpec.title`) — standing where "Day N of 14" stands, on the brief each section opens
## on (*"each the apartment and escape city are treated as their own 'days' with brief and restart
## checkpoint"*). A section has no morning line of its own, so none shows. No new fiction, and
## nothing triumphant or melodramatic (`docs/NARRATIVE.md`, "No triumphalism").
func show_day_brief(day: int, nerves: int, lost_note: String = "", title := "") -> void:
	_heading.hide()
	_showing_ending = false
	_note.text = SentenceLines.break_for_label(lost_note, _note)
	_note.visible = lost_note != ""
	_title.text = Texts.SUMMARY_DAY % [day, Tuning.RUN_LENGTH_DAYS] if title == "" \
			else SentenceLines.break_for_label(title, _title)
	# Stars, through the same `NerveDisplay.stars()` the HUD, the day summary and the pause screen
	# all read the count through — never a digit.
	_body.text = Texts.SUMMARY_NERVES % NerveDisplay.stars(nerves)
	var brief_text: String = Texts.DAY_BRIEF.get(day, "") if title == "" else ""
	_brief.text = SentenceLines.break_for_label(brief_text, _brief)
	_brief.visible = brief_text != ""
	_hint.text = ""
	_present()

## `elapsed_seconds` is the day's own clock at the instant it ended — `main._on_day_finished()`
## takes `DayController.time_total - DayController.time_remaining`, clamped to the day, before
## anything about the next day can touch either field, and hands it here alongside the reason.
## Defaults to `0.0` only so the handful of test call sites that do not care about the clock (the
## pause and resume rig in `tests/test_pause.gd`) do not all need an argument they never read.
##
## **Everything but the one line about the day that ended is the coming day's.** The morning a
## player reads this screen for is the one about to start, not the one just walked, so `_title`
## carries only the one exception — the clock the day ended on, worded by `_elapsed_line()` below
## — while `_body` and `_brief` both read `GameState.day` rather than a `finished_day` argument,
## which this function no longer takes: a win has already moved `GameState.day` on by the time
## this runs (`main._on_day_finished()` calls `GameState.finish_day()` before this), and a loss
## leaves it exactly on the day being retried, so nothing this screen shows still needs the day
## that ended passed in separately from `GameState.day` — `_elapsed_line()` below reads only
## `result` and `reason`, neither of which is a day number.
##
## **`back_to_checkpoint` is a normal run's last nerve**: `GameState.finish_day()` has already put
## the run back at its checkpoint's dawn with every nerve, so `GameState.day` is the day she goes
## back to and `nerves` is five. The line that says she tries the day again says that instead —
## *(gentle-osprey, the player's own example: "Back to day 8")* — and the continue under it carries
## on into that day.
##
## **`title` is a lost section of the escape's own words** (`DaySpec.title`), standing where "Day N
## of 14" stands: a lost section reports its outcome with its reason like any lost day *(minty-lemur
## #785: "losing an escape should still state the reason like the rest of the game")*, and the
## continue under it is the section again, so its words say which is tried again in place of the
## day's try-again line. A section has no morning line and no tally of its own.
func show_day(result: GameEnums.DayResult, reason: String, nerves: int,
		elapsed_seconds: float = 0.0, back_to_checkpoint := false, title := "") -> void:
	_heading.hide()
	_showing_ending = false
	# Never carried from a day brief this same day might have opened on — this is a real day's own
	# result, not the load-time note a brief shows instead of one.
	_note.visible = false
	# The one line about the day that just ended — see this function's own doc for why it moved
	# here rather than staying a line inside `_body`.
	_title.text = SentenceLines.break_for_label(
			_elapsed_line(result, reason, GameState.format_clock_seconds(elapsed_seconds)), _title)
	var retrying := result != GameEnums.DayResult.WON and nerves > 0 and title == ""
	var lines: Array[String] = [Texts.SUMMARY_DAY % [GameState.day, Tuning.RUN_LENGTH_DAYS]
			if title == "" else title]
	lines.append("")
	# The state she carries into the coming day, shown on a win as much as a loss, and drawn as
	# stars — never a digit — the way every other screen that shows the count now does.
	lines.append(Texts.SUMMARY_NERVES % NerveDisplay.stars(nerves))
	# The calendar does not move on a loss, so the screen says so rather than leaving the player
	# to notice tomorrow that it is still today — or, when the last nerve sent a normal run back,
	# which day it went back to, and why every star is there again.
	if back_to_checkpoint:
		lines.append(back_to_line(GameState.day))
	elif retrying:
		lines.append(Texts.SUMMARY_TRY_AGAIN % GameState.day)
	# The tally is the only place the subquest is ever spelled out. In the world it is chalk on
	# a wall.
	if GameState.has_joined_resistance() and title == "":
		lines.append("")
		lines.append(_resistance_tally_line())
	_body.text = "\n".join(lines)
	var brief_text: String = Texts.DAY_BRIEF.get(GameState.day, "") if title == "" else ""
	_brief.text = SentenceLines.break_for_label(brief_text, _brief)
	_brief.visible = brief_text != ""
	# Always empty. *(2026-09-06: "never should it be mentioned to the user".)* `space` still
	# carries on, but the continue/restart pair below already says what a tap does, and nothing
	# left to say here does not name a key — see `PauseScreen._hint`'s own doc for the same call
	# made there.
	_hint.text = ""
	_present()

## The line under the title that says when the day ended — the ask behind M154: *"can you show
## the time of the day when dieing/completing a day ... fell asleep after xx:xx or something like
## that"*. `clock` is `GameState.format_clock_seconds()`'s `m:ss`, never the ending screen's
## millisecond form (`GameState.format_clock()`), because the player asked for the HUD clock's own
## shape and named the millisecond one as what they did not want.
##
## Phrased per outcome rather than one suffix appended everywhere, because `reason` is not a single
## shape: `LOST_CRYING`'s reason names the moment itself ("She started crying. ...") so the clock
## reads into that first sentence rather than trailing the second one, and every other reason keeps
## its own sentence whole with the clock as a sentence of its own after it. `LOST_TIMEOUT` shows no
## clock at all — dusk *is* the whole day, so printing the day's own length back is the total the
## TODO item says the player does not want here, only in a different place.
func _elapsed_line(result: GameEnums.DayResult, reason: String, clock: String) -> String:
	match result:
		GameEnums.DayResult.WON:
			return Texts.SUMMARY_FELL_ASLEEP % clock
		GameEnums.DayResult.LOST_TIMEOUT:
			return reason
		GameEnums.DayResult.LOST_CRYING:
			var cut := reason.find(". ")
			if cut == -1:
				return Texts.SUMMARY_REASON_AFTER % [reason, clock]
			return Texts.SUMMARY_REASON_AFTER_REST % [reason.substr(0, cut), clock, reason.substr(cut + 1)]
		_:
			return Texts.SUMMARY_REASON_THEN_CLOCK % [reason, clock]

## What the lost-day screen says when a normal run's last nerve sent it back to `day`, its
## checkpoint.
static func back_to_line(day: int) -> String:
	return Texts.SUMMARY_BACK_TO_CHECKPOINT % day

## The tally alone. The morning's own line is `_brief`'s job now — a static fact about the
## calendar day, shown unconditionally in `show_day()` — so this stays about progress and losses
## only, which is why it is still gated on `has_joined_resistance()` at the call site.
func _resistance_tally_line() -> String:
	if GameState.sabotage_available():
		return Texts.SUMMARY_TALLY_DONE
	var done := GameState.resistance_progress
	var lost := GameState.failed_resistance_steps.size()
	var line := Texts.SUMMARY_TALLY % [done, Tuning.RESISTANCE_GOAL]
	if lost > 0:
		line += Texts.SUMMARY_TALLY_LOST_ONE if lost == 1 else Texts.SUMMARY_TALLY_LOST % lost
	return line

## The last screen of a run. `space` — or a tap — goes back to the title, which is where the next
## one begins.
##
## **Not `esc to quit`**, which is not true from here: `Esc` opens the pause, and the pause offers
## `Esc` and `Q`, so a finished run becomes a cycle between two screens with closing the window as
## the only way out. Space dismisses every other screen in the game, so it is the key this one owes
## rather than a new one.
##
## `day` is the last day played, not the last day completed — a hard run that loses its last nerve
## on day 1 names day 1, not 0. It is shown only on the `BAD` ending — a hard run's, and the only one
## that can end mid-day: `NEUTRAL` and `GOOD` are reached by finishing day 14, and every caller already has the
## number this needs, since `GameState.day` is never advanced past the day a run ends on
## (`GameState.finish_day()` ends the run before it would move the calendar) or past the day a
## load spent the last nerve on.
func show_ending(ending: GameEnums.Ending, day: int) -> void:
	_heading.text = Texts.ENDING_HEADING.get(ending, Texts.ENDING_HEADING_DEFAULT)
	_heading.show()
	_title.text = Texts.ENDING_TITLE.get(ending, Texts.ENDING_TITLE_DEFAULT)
	# The one place `GameState.play_seconds` is ever shown — never during play, on every ending
	# alike. `GameState.format_clock()` is the shared formatter so this line and the finale's own
	# clock, once that is built, never carry two copies of the same format string.
	var day_line := Texts.ENDING_DAY_REACHED % day if ending == GameEnums.Ending.BAD else ""
	var ending_body := SentenceLines.break_for_label(Texts.ENDING_BODY.get(ending, ""), _body)
	_body.text = Texts.ENDING_PLAYED \
			% [ending_body, GameState.format_clock(GameState.play_seconds), day_line]
	_hint.text = ""
	# The ending is not a day summary and has no morning line of its own to show.
	_brief.visible = false
	# Never carried from the day brief a resumed run's own last nerve replaces with this screen —
	# see `main._show_the_resume_gate()`.
	_note.visible = false
	_showing_ending = true
	_present()

## The escape's own last screen: the tunnel or the bridge behind her, and **nothing triumphant**
## (`docs/NARRATIVE.md`, "No triumphalism"). Two lines, one for the way she took, and the clock she
## took it on to the millisecond — the only number this screen carries, and the reason the finale's
## clock reads that way at all.
##
## Not a fourth `GameEnums.Ending`: an ending is a *run's* outcome and `GameState.ending` picks one
## of three from the nerves and the sabotage. This is the last screen of a sequence that the run
## hands over to, so it is its own entry point on the same screen — the smallest thing that keeps
## `show_ending()`'s own table saying exactly what it says now.
##
## `exit_kind` is a `CityEdge.Kind`, passed as an `int` because a cross-script enum is not the same
## type as itself as a parameter — see the **godot** skill.
func show_finale(exit_kind: int, seconds: float) -> void:
	_heading.text = Texts.FINALE_HEADING
	_heading.show()
	_title.text = Texts.FINALE_TITLE
	_showing_ending = false
	var finale_body := SentenceLines.break_for_label(
			Texts.FINALE_BODY.get(exit_kind, Texts.FINALE_BODY[CityEdge.Kind.BRIDGE]), _body)
	_body.text = Texts.FINALE_OUT_IN % [finale_body, GameState.format_clock(seconds)]
	_hint.text = ""
	_brief.visible = false
	# Never carried from a brief or a lost section's screen before it.
	_note.visible = false
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
			and _continue_button.contains_design_point(at))
	_restart_button.set_hovered(_buttons.visible and _restart_button.contains_design_point(at))
