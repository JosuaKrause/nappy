extends CanvasLayer
## The clock, the two meter bars and the current optional goal — the whole of the day's HUD.
##
## Meter values arrive over EventBus, so the HUD never holds a reference to the world or
## the event system. The one direct reference is to the Baby, for `stall_reason()` — a
## coaching hint that needs to ask "why", which a value signal cannot answer.
##
## The header (day / act / nerves) and the status line (the baby's state and why sleepiness has
## stalled) are debug output, not the game: between-day summaries already say all of it, and
## during the day it is noise the entity on screen already carries. They draw only in a debug
## build, because the rigs and `tools/shot.sh` read them, and the release build drops them
## silently rather than replacing them with anything.

## Pinned to `ScreenOrientation.DESIGN_SIZE` in `_ready()`, so every child below keeps anchoring
## against the fixed 1280x720 box it is authored for rather than against whatever
## `content_scale_size` currently reports — see `ScreenOrientation.pin_to_design_box()`.
@onready var _root: Control = $Root
@onready var _meters: Control = $Root/Meters
@onready var _sleepiness: MeterBar = $Root/Meters/Sleepiness
@onready var _excitement: MeterBar = $Root/Meters/Excitement
@onready var _state_label: Label = $Root/Meters/State
@onready var _resistance_label: Label = $Root/Meters/Resistance
@onready var _header: Label = $Root/Header
@onready var _clock: Label = $Root/Clock
@onready var _home_arrow: HomeArrow = $Root/HomeArrow
@onready var _teach: Label = $Root/Teach

## Read once per instance rather than at each use site, so a test can flip it and drive both HUD
## shapes without needing an actual debug build — the test process itself always is one, so asking
## `OS.is_debug_build()` from inside `_refresh_header()` et al. would leave the release shape
## covered by nothing.
var _debug := OS.is_debug_build()

## Whether this device has a touchscreen. Read once from `TouchInput`, the same pattern
## `DaySummary` and `PauseScreen` use, so the run lesson names the held `RUN` circle the touch
## layer draws instead of a `SHIFT` key a touch device does not have.
var _touch := TouchInput.available()

## Which of the two control schemes is driving this run, so the walking and running lessons name a
## tap rather than a control tap mode does not draw, and so the pause lesson knows to say nothing
## at all — see `_teach_the_pause()`.
##
## **Not read from `ControlsMode` at `_ready()`.** The title screen may still be asking when day 1
## already starts behind it (see `main._open_the_title()`), so there is no answer to cache yet —
## `main` calls `set_controls_mode()` the moment there is one, whether that is immediately (a flag
## or a URL skipped the question) or once the player has pressed one of the title's own two
## buttons. Defaults to the stick, the same fallback `ControlsMode.from_word("")` itself falls back
## to, so a test that never calls the setter still gets a sensible shape.
var _controls_mode := ControlsMode.Mode.STICK

var _baby: Baby
var _contact_step := 0
var _announcement := ""
var _announcement_for := 0.0
## What is holding a floor under the whole city, or "" for nothing. Debug-only readout (see
## `_refresh_state()`); a city-wide source still holds the meter up in a release build, it is just
## not named on screen any more.
var _city_wide := ""

const _STATE_TEXT := {
	GameEnums.BabyState.AWAKE: "awake",
	GameEnums.BabyState.ASLEEP: "asleep - go home",
	GameEnums.BabyState.CRYING: "crying - day lost",
}

func _ready() -> void:
	ScreenOrientation.pin_to_design_box(_root)
	_sleepiness.label = "SLEEPINESS"
	_sleepiness.fill_colour = Color("4a5f9e")
	_sleepiness.full_colour = Color("8fb4d9")

	_excitement.label = "EXCITEMENT"
	_excitement.fill_colour = Color("d9a648")
	_excitement.full_colour = Color("cf4436")
	_excitement.markers = [Tuning.EXCITEMENT_CALM_THRESHOLD, Tuning.EXCITEMENT_WAKE_THRESHOLD]
	_reposition_meters_for_touch()

	EventBus.sleepiness_changed.connect(_on_sleepiness_changed)
	EventBus.excitement_changed.connect(_on_excitement_changed)
	EventBus.baby_state_changed.connect(_on_baby_state_changed)
	EventBus.nerves_changed.connect(func(_n: int) -> void: _refresh_header())
	EventBus.day_started.connect(func(_d: int) -> void: _refresh_header())
	EventBus.day_time_changed.connect(_on_day_time_changed)
	EventBus.resistance_progress_changed.connect(func(_v: int) -> void: _refresh_resistance())
	EventBus.resistance_contact_available.connect(_on_contact_available)
	EventBus.city_went_quiet.connect(_on_city_went_quiet)
	EventBus.city_wide_changed.connect(_on_city_wide_changed)
	EventBus.event_telegraphed.connect(_on_event_telegraphed)
	EventBus.day_started.connect(_teach_the_day)
	EventBus.day_started.connect(func(_d: int) -> void:
		_contact_step = 0
		_refresh_resistance())

	_baby = get_tree().get_first_node_in_group("baby") as Baby
	if _baby:
		_sleepiness.value = _baby.sleepiness
		_excitement.value = _baby.excitement
	_refresh_header()
	_refresh_state()
	_refresh_resistance()

## *("let's also move the progress bars to the top for mobile so they're not hidden by the
## finger.")* The two meter bars, the resistance line and the baby's state sit in `hud.tscn`'s
## `Meters` column, anchored bottom-left ending 18px above the bottom edge — under a walking
## thumb on a phone, where `TouchControls.STICK_CENTRE` (130, 500) sits right above it. **The
## baby's state may never be occluded: it is what the whole route decision is read off.**
##
## Touch only, moving the anchors on the one node rather than keeping a second HUD scene that has
## to be changed twice forever — the same shape every other touch difference in this game takes.
## Top left, under the day header (`$Header`, 20px tall from `offset_top=14` to `34`): same 18px
## left inset and the same 280×114 box the bottom column used, just measured from the top instead
## of the bottom, so nothing about the column's own contents changes, only where it sits.
##
## **This does not clear `DangerEdge`.** Its own `MARGIN` (104/116/104/148,
## left/top/right/bottom) was tuned for a HUD with nothing at the top left — "the clock and the
## run header are along the top" is that file's own reasoning for why the *bottom* margin is
## generous instead. Its chevrons ride the edge of a bounds rect starting at `(104, 116)`, so on a
## touch device this column (x 18–298, y 40–154) crosses both edges that meet at that corner: the
## top one along `y=116` for `x` 104–298, and the left one along `x=104` for `y` 116–154. Real
## overlap, not a near miss. `DangerEdge` is `main`'s own layer and out of this item's scope; left
## as a fork for whoever tunes it next — see the report for the full reasoning.
func _reposition_meters_for_touch() -> void:
	if not _touch:
		return
	_meters.anchor_left = 0.0
	_meters.anchor_top = 0.0
	_meters.anchor_right = 0.0
	_meters.anchor_bottom = 0.0
	_meters.offset_left = 18.0
	_meters.offset_top = 40.0
	_meters.offset_right = 298.0
	_meters.offset_bottom = 154.0
	_meters.grow_vertical = Control.GROW_DIRECTION_END

# ---------------------------------------------------------------- teaching ---
# Day 1 introduces the arrow keys; day 3 introduces running, which is possible before then and
# never required.
#
# Two lines of text and no tutorial, because **teaching a move before it is ever correct teaches a
# move that is never correct again.** Running is available and wrong from the first morning, so the
# game says nothing about it for two days — and then says it on the frame it becomes the answer.

## How long the day-1 line stays up. Long enough to be read while walking off the doorstep.
const TEACH_SECONDS := 7.0
## How long she has to stand still, having already walked today, before the game mentions that a
## pause exists. Long enough that it is a person stopping rather than a person turning round.
const TEACH_PAUSE_AFTER := 3.0
## And how long the run prompt holds once a pursuit has raised it. A little past the chase, so it
## is still there while she is getting her breath back and can connect the key to the outcome.
const TEACH_RUN_SECONDS := 5.0

var _teach_left := 0.0
## The rig, for the one question the pause hint needs: is she standing still. Found the same way
## `_baby` is, and for the same reason — it is a *state* of the player, and no signal carries it.
var _rig: Stroller
## Whether she has moved at all today. The stand on the doorstep at dawn is not a person who has
## stopped, it is a person who has not started, so it does not count.
var _walked_today := false
var _stood_for := 0.0
## Once per **run**, not once per day. See `_teach_the_pause()`.
var _taught_pause := false
## Once per **run**, and only on `Tuning.RUN_TAUGHT_DAY`. See `_on_event_telegraphed()`.
var _taught_run := false

## Day 1 says how to walk, and nothing else. Every later day says nothing at all until something
## on the street asks for a key she has not needed yet.
func _teach_the_day(day: int) -> void:
	_teach_left = 0.0
	_teach.text = ""
	_walked_today = false
	_stood_for = 0.0
	if day == 1:
		var line := "Arrow keys or WASD to walk"
		if _controls_mode == ControlsMode.Mode.TAP:
			line = "Tap to walk, double tap to run"
		elif _touch:
			line = "Drag the stick to walk"
		_say(line, TEACH_SECONDS)
	# A nerve is a rewind, not a resource, and a rewound day has not been taught anything: this
	# flag belongs to the *attempt* at the teaching day rather than to the run, and only on this
	# one day, so a lost nerve on `RUN_TAUGHT_DAY` gets the lesson again instead of a HUD that
	# remembers a lesson the player never actually reached. `_taught_pause` keeps the once-per-run
	# shape the comment above it argues for — it is not tied to a day, so whether a rewind should
	# clear it too is a different question and not this one's to answer.
	if day == Tuning.RUN_TAUGHT_DAY:
		_taught_run = false


## The pause exists, and the moment to say so is the first time she stops **of her own accord**.
##
## Four conditions, and each one is a way this would otherwise be noise:
##
## - **Not before she has walked today.** Standing on the doorstep at dawn is not somebody who has
##   stopped, it is somebody who has not started, and every single day would open with it.
## - **Not while something is holding her still.** A zero velocity is not the same claim as "she
##   has stopped": `chatting_mother`'s `detain()` locks her input and lets friction carry her to a
##   standstill, and `HUD` itself keeps running behind the title, the pause and the between-days
##   summary — all three set `get_tree().paused` — so standing behind any of them for
##   `TEACH_PAUSE_AFTER` looks identical to standing on a calm pavement unless this is asked apart
##   from it. Offering the pause key at the exact moment her controls were taken away, or while she
##   is already looking at a screen that has one, is the worst possible reading of "she stopped".
## - **Not over the walking lesson.** One line at a time; the `Teach` label is one label, and a
##   prompt that replaces the instruction she is still following teaches neither.
## - **Once per run.** It is a keybinding, not a warning. A cue that comes back is a cue that gets
##   read once and then ignored — which is the rings' mistake in the smallest possible shape.
##
## It is also, incidentally, the moment the answer is most useful: standing still settles nothing,
## so somebody who has stopped either wants the game to stop with them, or is about to find out
## that waiting is not a plan.
##
## **Has nothing to say in tap mode**, and does not run there at all: there is no pause key on a
## phone and no button to point at — `TapControls` itself pauses when she stands at a destination
## long enough (`TapControls.ARRIVAL_PAUSE_AFTER`), every time rather than once, because that is
## how the mode works rather than a cue to be taught once and then left alone.
func _teach_the_pause(delta: float) -> void:
	if _taught_pause or _controls_mode == ControlsMode.Mode.TAP:
		return
	if not _rig:
		_rig = get_tree().get_first_node_in_group("player") as Stroller
		if not _rig:
			return
	if not _rig.is_idle():
		_walked_today = true
		_stood_for = 0.0
		return
	# Held rather than stopped: reset, don't merely stop adding, so a conversation does not leave
	# her three-quarters of the way to a lesson she never earned.
	if _rig.is_detained() or get_tree().paused:
		_stood_for = 0.0
		return
	if not _walked_today or _teach_left > 0.0:
		return
	_stood_for += delta
	if _stood_for < TEACH_PAUSE_AFTER:
		return
	_taught_pause = true
	# "the pause button" rather than any drawn label: `TouchControls._draw_pause_button()` draws
	# an icon, two bars, not a word — naming a label that is not there would be the same defect
	# this line exists to fix on the other lessons.
	var line := "Tap the pause button to pause" if _touch else "Esc to pause"
	_say(line, TEACH_SECONDS)

## The run is taught by the thing that requires it, at the moment it requires it — and only for
## that one lesson.
##
## Hung off the telegraph rather than off the day, so the prompt and the dog arrive together: a
## line of text at dawn saying "you can run" is a control list, and a line of text over a dog
## coming at the pram is an instruction. But it is a lesson about the mechanic, not a running
## commentary on it — once `Tuning.RUN_TAUGHT_DAY` has taught the control, a line naming it again
## explains something she has already been made to do, every time something later in the run
## pursues her. So it fires once, for the first pursuit of the day the run is taught, and never
## again this run: the same "once per run" shape as `_teach_the_pause()`, for the same reason —
## it is a keybinding, not a warning, and a cue that keeps coming back is one that gets read once
## and then ignored. The control it names is `_touch`'s: `SHIFT` on a keyboard, the held `RUN`
## circle `TouchControls` draws on a touch device — same pattern `DaySummary` and `PauseScreen`
## read `TouchInput.available()` for.
func _on_event_telegraphed(instance: EventInstance) -> void:
	if _taught_run or not instance.def.pursues or GameState.day != Tuning.RUN_TAUGHT_DAY:
		return
	_taught_run = true
	var line := "Hold SHIFT to run"
	if _controls_mode == ControlsMode.Mode.TAP:
		line = "Double tap to run"
	elif _touch:
		line = "Hold RUN to run"
	_say(line, instance.def.telegraph_time + TEACH_RUN_SECONDS)

func _say(line: String, seconds: float) -> void:
	_teach.text = line
	_teach_left = seconds

func _process(delta: float) -> void:
	_teach_the_pause(delta)
	if _teach_left > 0.0:
		_teach_left = maxf(0.0, _teach_left - delta)
		# Fades out over its last second rather than blinking off, so it leaves the way a
		# subtitle does and not the way an alarm does.
		_teach.modulate.a = clampf(_teach_left, 0.0, 1.0)
		if _teach_left <= 0.0:
			_teach.text = ""
	_refresh_state()
	if _announcement_for > 0.0:
		_announcement_for = maxf(0.0, _announcement_for - delta)

func _on_sleepiness_changed(value: float) -> void:
	_sleepiness.value = value

func _on_excitement_changed(value: float) -> void:
	_excitement.value = value

func _on_baby_state_changed(_state: GameEnums.BabyState) -> void:
	_refresh_state()

## The status line. An announcement always uses it — "The loudspeakers cut out mid-sentence." has
## nowhere else to go — but the baby's state, `stall_reason()` and the city-wide note are debug-only:
## the state is already visible on the pram itself, and the other two are read between days.
func _refresh_state() -> void:
	if not _baby:
		return
	if _announcement_for > 0.0:
		_state_label.text = _announcement
		return
	if not _debug:
		_state_label.text = ""
		return
	var text: String = _STATE_TEXT.get(_baby.state, "?")
	var reason := _baby.stall_reason()
	if reason != "":
		text += "   (not settling: %s)" % reason
	# Last, and phrased as a place rather than as a source: a player cannot walk away from this
	# one, and the useful thing to tell them is that walking away is not the move.
	if _city_wide != "":
		text += "   [%s - nowhere is quiet]" % _city_wide.to_lower()
	_state_label.text = text

func _on_day_time_changed(remaining: float, total: float) -> void:
	_clock.text = "%d:%02d" % [int(remaining) / 60, int(remaining) % 60]
	# The last minute is the one worth panicking about.
	var urgent := remaining < 60.0 and total > 0.0
	_clock.modulate = Color("e5765f") if urgent else Color(1, 1, 1)

func _on_contact_available(step: int) -> void:
	_contact_step = step
	_refresh_resistance()

## Deliberately terse. There is no quest log — the subquest is chalk on a wall.
##
## The release line is the current optional goal and no count: the progress dots are how far in you
## are, the same category as the header's `nerves ***` and read between days rather than during one.
## A debug build keeps the `resistance ***..` prefix the rigs and `tools/shot.sh` were built against.
##
## **`somewhere out there:` stays**, because it is what makes a title a goal. Without it the line is
## a bare fragment — `a chalk mark` — which says a noun rather than *go and find this*, and the
## whole of what survives the cut is that one instruction.
func _refresh_resistance() -> void:
	if not _debug:
		var step: ResistanceSteps.Step = null
		if _contact_step > 0:
			step = ResistanceSteps.by_index(_contact_step)
		_resistance_label.text = "somewhere out there: %s" % step.title.to_lower() if step else ""
		return

	if not GameState.has_joined_resistance() and _contact_step == 0:
		_resistance_label.text = ""
		return

	var marks := "*".repeat(GameState.resistance_progress) \
			+ ".".repeat(maxi(0, Tuning.RESISTANCE_GOAL - GameState.resistance_progress))
	var line := "resistance %s" % marks
	if _contact_step > 0:
		var step := ResistanceSteps.by_index(_contact_step)
		if step:
			line += "   somewhere out there: %s" % step.title.to_lower()
	_resistance_label.text = line

## `main`'s own answer to which control scheme is driving this run — see `_controls_mode`'s own
## doc for why this is a setter rather than something read here at `_ready()`.
##
## **Re-announces day 1's opening line if it already went out.** `_teach_the_day(1)` fires from
## `EventBus.day_started` the moment the day is built, which for the very first day is *before* an
## interactively-asked title screen has closed — so that line may have already guessed the stick
## from the still-default `_controls_mode` above. The HUD is hidden behind the title for the whole
## of that wait, so nobody has read the guess yet; redoing it here, now that the real answer
## exists, is free and is what keeps the line honest once the HUD becomes visible again. A day
## already under way when this is called (every day but the first) is left alone — its own opening
## line is long past and nothing here should replay it.
func set_controls_mode(mode: ControlsMode.Mode) -> void:
	_controls_mode = mode
	if GameState.day == 1:
		_teach_the_day(GameState.day)

## Forwarded from `main._apply_orientation()`. `HomeArrow` is the one child here that computes a
## screen position from a world one every frame rather than sitting still under `_root`'s own
## pinned anchors, so it needs to know when to correct for the rotation the same way `DangerEdge`
## does — see `ScreenOrientation`'s class doc.
func set_rotated(rotate: bool) -> void:
	_home_arrow.rotated = rotate

## The one moment the game says something out loud.
## Shown only while she is carrying a sleeping baby home.
func set_home_guidance(showing: bool, home: Vector2) -> void:
	if showing:
		_home_arrow.show_toward(home)
	else:
		_home_arrow.hide_arrow()

func _on_city_wide_changed(what: String) -> void:
	_city_wide = what
	_refresh_state()

func _on_city_went_quiet() -> void:
	_announcement = "The loudspeakers cut out mid-sentence."
	_announcement_for = 7.0
	_refresh_state()

## Debug-only: day, act and nerves are all read between days already, and during the day this is
## the header the rigs and `tools/shot.sh` were built against, not something the release build owes
## the player.
func _refresh_header() -> void:
	if not _debug:
		_header.text = ""
		return
	_header.text = "day %d / %d      act %d      nerves %s" % [
		GameState.day, Tuning.RUN_LENGTH_DAYS, GameState.current_act(),
		"*".repeat(GameState.nerves) if GameState.nerves > 0 else "-",
	]
