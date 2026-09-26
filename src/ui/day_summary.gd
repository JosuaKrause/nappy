extends CanvasLayer
## The screen between days, the one at the end of a run, and the two the escape uses — the brief
## before a lost section starts again, and the last screen of the sequence.
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
## day, from `_DAY_BRIEF` below — its own label, not a line folded into `_body`, because a screen
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

## Whether this device has a touchscreen. Read once from `TouchInput`, the same pattern
## `TitleScreen` and `PauseScreen` each read it once into their own member instead of asking at
## every use site. No longer chooses the hint's own wording (`_hint` is always empty now — see
## its own doc), but still gates `_wants_rotation()` and the mouse branch in
## `_handle_restart_touch()` below.
var _touch := TouchInput.available()

## One or two plain sentences a morning, in American English, under `docs/NARRATIVE.md`'s tone
## rules — nobody explains the politics, the danger is noise, nothing triumphant. Each names the
## thing that day introduces, so this is also where a new obstacle is first heard of; a line is
## not tied to its own day's resistance task or once-only happening, so one that would give a
## task away says something else that is true that morning instead. Read directly off
## `GameState.day` rather than a parameter, since the same table has to answer for both
## `show_day_brief()` (a resumed run's own gate) and `show_day()` (the ordinary transition every
## other day reaches this screen through) — a static fact about the calendar day, never about
## what an attempt touched, so a lost day's own line reads exactly as it did this morning.
const _DAY_BRIEF := {
	1: "She won't settle indoors. It is quiet in the park. Walk until she sleeps, then bring "
			+ "her home.",
	2: "There are bicycles on the sidewalk again.",
	3: "The streets smell of smoke today.",
	4: "It feels like there are more police around now.",
	5: "They put up masts at the intersections overnight.",
	6: "A curfew was announced today. There is not as much time. There are rumors of chalk "
			+ "messages in alleys.",
	7: "There are more posters than yesterday. The same face is on most of them.",
	8: "A van took someone from the next street before it was light.",
	9: "They have closed the districts off from each other. There are huts at the crossings.",
	10: "The stores on the square are boarded up.",
	11: "A door down the hall was sealed in the night. The name is still on the bell.",
	12: "They are fencing off the parks.",
	13: "There are army trucks on the main road.",
	14: "The last night.",
}

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
## still has one; an ending has none, and the button was drawn as *continue* while doing exactly
## what the catch-all underneath it already does — restart the run. `_buttons` itself stays
## visible for `_restart_button` even here: *"the restart button, hold and all"* is the player's
## own answer to whether the hold still earns its keep with no day left to protect.
func _refresh_buttons() -> void:
	_buttons.visible = true
	_continue_column.visible = not _showing_ending

## What a saved game opens on instead of starting the day outright, once the title's own start
## button has been pressed — `main._show_the_resume_gate()`'s own call, made after
## `GameState.finish_day()` has already charged whatever the load itself costs, so `day` and
## `nerves` are already the numbers the retry (or the day exactly as the save left it) actually
## has. Three things, no more: the day, the nerves, and the morning's own line from `_DAY_BRIEF`.
## `lost_note` is `main._RESUMED_DAY_LOST_NOTE` when the load itself spent a nerve, or `""` for a
## save that cost nothing, in which case this is exactly what a fresh day 1 skips by going
## straight from the title into `main._engage_the_day()` instead. Continuing from here reaches
## that same function, through `main._on_summary_continued()`'s own `_resume_gate_open` branch —
## the moment the day actually starts, and the moment the save says so.
func show_day_brief(day: int, nerves: int, lost_note: String = "") -> void:
	_heading.hide()
	_showing_ending = false
	_note.text = lost_note
	_note.visible = lost_note != ""
	_title.text = "Day %d of %d" % [day, Tuning.RUN_LENGTH_DAYS]
	_body.text = "last nerve" if nerves == 1 else "%d nerves left" % nerves
	_brief.text = _DAY_BRIEF.get(day, "")
	_brief.visible = _brief.text != ""
	_hint.text = ""
	_present()

## `elapsed_seconds` is the day's own clock at the instant it ended — `main._on_day_finished()`
## takes `DayController.time_total - DayController.time_remaining`, clamped to the day, before
## anything about the next day can touch either field, and hands it here alongside the reason.
## Defaults to `0.0` only so the handful of test call sites that do not care about the clock (the
## pause and resume rig in `tests/test_pause.gd`) do not all need an argument they never read.
func show_day(day: int, result: GameEnums.DayResult, reason: String, nerves: int,
		elapsed_seconds: float = 0.0) -> void:
	# A lost *day* is not the end of a run — there are nerves left, and the screen says so two lines
	# down. The heading belongs to the screen that ends the run and to nothing else.
	_heading.hide()
	_showing_ending = false
	# Never carried from a day brief this same day might have opened on — this is a real day's own
	# result, not the load-time note a brief shows instead of one.
	_note.visible = false
	_title.text = _DAY_TITLE.get(result, "The day ends.")
	var lines: Array[String] = ["Day %d of %d" % [day, Tuning.RUN_LENGTH_DAYS]]
	lines.append("")
	lines.append(_elapsed_line(result, reason, GameState.format_clock_seconds(elapsed_seconds)))
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
	# The tally is the only place the subquest is ever spelled out. In the world it is chalk on
	# a wall.
	if GameState.has_joined_resistance():
		lines.append("")
		lines.append(_resistance_tally_line())
	_body.text = "\n".join(lines)
	# `GameState.day` rather than the `day` parameter (which is `finished_day`, the day that just
	# ended): `GameState.finish_day()` has already run by the time `main._on_day_finished()` calls
	# this, so on a win `day` moves on to the day this screen is the brief for while a loss leaves
	# it exactly where a retry needs it — see `_DAY_BRIEF`'s own doc.
	_brief.text = _DAY_BRIEF.get(GameState.day, "")
	_brief.visible = _brief.text != ""
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
			return "She fell asleep after %s." % clock
		GameEnums.DayResult.LOST_TIMEOUT:
			return reason
		GameEnums.DayResult.LOST_CRYING:
			var cut := reason.find(". ")
			if cut == -1:
				return "%s after %s." % [reason, clock]
			return "%s after %s.%s" % [reason.substr(0, cut), clock, reason.substr(cut + 1)]
		_:
			return "%s After %s." % [reason, clock]

## The tally alone. The morning's own line is `_brief`'s job now — a static fact about the
## calendar day, shown unconditionally in `show_day()` — so this stays about progress and losses
## only, which is why it is still gated on `has_joined_resistance()` at the call site.
func _resistance_tally_line() -> String:
	if GameState.sabotage_available():
		return "You have done enough. There is one more night."
	var done := GameState.resistance_progress
	var lost := GameState.failed_resistance_steps.size()
	var line := "Errands run: %d of %d" % [done, Tuning.RESISTANCE_GOAL]
	if lost > 0:
		line += "   (%d contact%s lost)" % [lost, "" if lost == 1 else "s"]
	return line

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
	# The one place `GameState.play_seconds` is ever shown — never during play, on every ending
	# alike. `GameState.format_clock()` is the shared formatter so this line and the finale's own
	# clock, once that is built, never carry two copies of the same format string.
	_body.text = "%s\n\nTime played: %s" \
			% [_ENDING_BODY.get(ending, ""), GameState.format_clock(GameState.play_seconds)]
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
	_heading.text = "THE END"
	_heading.show()
	_title.text = "You are out."
	_showing_ending = false
	_body.text = "%s\n\nOut in: %s" % [
		_FINALE_BODY.get(exit_kind, _FINALE_BODY[CityEdge.Kind.BRIDGE]),
		GameState.format_clock(seconds)]
	_hint.text = ""
	_brief.visible = false
	_present()

## The screen a section of the escape opens on — a first walk through it and a retry alike. *"Each
## the apartment and escape city are treated as their own 'days' with brief and restart
## checkpoint."*
##
## **The same screen a resumed day opens on** (`show_day_brief()`), with the two lines that are
## about a day replaced by the two that are true here. A section costs no Nerve however it goes, so
## the nerve count is exactly what it was and the line says so, unchanged; and the escape has no
## day number, so what stands where "Day N of 14" stands is **the section's own line** — *"Escape
## the building"* or *"Escape the city"*, the same words `HUD.say_once()` says once she is walking
## it and the same words `main` passes in. No new fiction, and nothing triumphant or melodramatic
## (`docs/NARRATIVE.md`, "No triumphalism"): a retry is not a moment, it is the thing she is doing
## again.
##
## There is no reason line and no lost note. The screen before a section is about what she is about
## to do, not about what just happened — `show_day()` is the screen that reports an outcome, and a
## section has no outcome worth a sentence when nothing was spent on it.
func show_finale_brief(hint: String, nerves: int) -> void:
	_heading.hide()
	_showing_ending = false
	_note.visible = false
	_title.text = hint
	_body.text = "last nerve" if nerves == 1 else "%d nerves left" % nerves
	_brief.visible = false
	_hint.text = ""
	_present()

## What is behind her, and it is the same sentence either way: she is out, nobody is following,
## and the city is still there. The two differ only in what she is standing on.
const _FINALE_BODY := {
	CityEdge.Kind.TUNNEL:
		"The mountain closes over the road behind you.\n"
		+ "She does not wake.",
	CityEdge.Kind.BRIDGE:
		"The water is under you and the city is behind you.\n"
		+ "She does not wake.",
}

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
		if not _restart_button.catch_rect().has_point(at):
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
			and _continue_button.catch_rect().has_point(at))
	_restart_button.set_hovered(_buttons.visible and _restart_button.catch_rect().has_point(at))
