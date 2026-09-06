extends RefCounted
## The HUD's teaching lines, plus the debug/release gate that decides what else it draws.
##
## Most of what the HUD shows is read off `EventBus` values and is either checked by eye or
## covered by whatever produces the value. Two things here are a *rule* rather than a readout:
## when "Hold SHIFT to run" is allowed to say anything at all, and which lines `hud._debug`
## keeps or drops. `hud._debug` is read once into a member rather than asked of
## `OS.is_debug_build()` at each use site precisely so a test — itself always a debug process —
## can set it to `false` and see the release shape, which is otherwise asserted by nothing.

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")

func run(t) -> void:
	_test_the_run_hint_fires_once_on_the_teaching_day(t)
	_test_the_run_hint_never_fires_off_the_teaching_day(t)
	_test_the_run_hint_fires_again_on_a_retried_teaching_day(t)
	_test_the_run_hint_names_the_touch_button_on_a_touch_device(t)
	_test_the_walk_hint_names_the_touch_stick_on_a_touch_device(t)
	_test_the_walk_and_run_hints_name_a_tap_in_tap_mode(t)
	_test_the_pause_hint_says_nothing_in_tap_mode(t)
	_test_the_meters_move_to_the_top_on_a_touch_device(t)
	_test_the_pause_hint_names_the_touch_button_on_a_touch_device(t)
	_test_the_pause_hint_waits_out_a_detention(t)
	_test_the_release_hud_drops_the_header(t)
	_test_the_release_hud_drops_the_status_line_but_keeps_announcements(t)
	_test_the_release_optional_goal_keeps_its_title_and_drops_the_progress_dots(t)
	_test_a_meter_bar_may_not_read_100_before_the_day_actually_ends(t)

func _hud(t) -> CanvasLayer:
	var hud: CanvasLayer = HUD_SCENE.instantiate()
	t.add_child(hud)
	hud.set_process(false)
	return hud

func _pursuer() -> EventInstance:
	var def := EventDef.new()
	def.id = "test_pursuer"
	def.pursues = true
	def.telegraph_time = 2.0
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	return instance

## **The run hint belongs to the lesson, not the mechanic.** *("hold SHIFT to run randomly shows up
## sometimes after the running tutorial. it should only show up for the tutorial.")* The first
## pursuit telegraphed on `Tuning.RUN_TAUGHT_DAY` is the lesson, and it is the only telegraph in
## the whole run allowed to say anything: a second pursuit the same day is not a second lesson, and
## `hud._taught_run` is what stops it from reading as one.
func _test_the_run_hint_fires_once_on_the_teaching_day(t) -> void:
	var saved_day := GameState.day
	GameState.day = Tuning.RUN_TAUGHT_DAY
	var hud := _hud(t)

	var first := _pursuer()
	hud._on_event_telegraphed(first)
	t.check(hud._teach.text == "Hold SHIFT to run",
			"the first pursuit of the teaching day shows the hint")
	t.check(hud._taught_run, "and the day is marked taught")

	# A second pursuit the same day — the day the lesson is repeated most, since `charging_dog` can
	# land more than once — must not read as a second lesson.
	hud._teach.text = ""
	var second := _pursuer()
	hud._on_event_telegraphed(second)
	t.check(hud._teach.text == "", "a second pursuit the same day says nothing new")

	first.free()
	second.free()
	hud.free()
	GameState.day = saved_day

## **The lesson names the control that is actually there.** *(Filed from a phone play of the
## deployed build: "the run tutorial says hold 'SHIFT' on mobile.")* `hud._touch` is read once
## from `TouchInput`, the same pattern `DaySummary` and `PauseScreen` use, so a touch device gets
## the held `RUN` circle `TouchControls` draws rather than a key it has not got.
func _test_the_run_hint_names_the_touch_button_on_a_touch_device(t) -> void:
	var saved_day := GameState.day
	GameState.day = Tuning.RUN_TAUGHT_DAY
	var hud := _hud(t)
	hud._touch = true

	var first := _pursuer()
	hud._on_event_telegraphed(first)
	t.check(hud._teach.text == "Hold RUN to run",
			"a touch device is told to hold the on-screen RUN button, not a keyboard key")

	first.free()
	hud.free()
	GameState.day = saved_day

## **The day-1 walk lesson has the same defect the run lesson had, and the same fix.** `hud._touch`
## drives both: a touch device gets "Drag the stick to walk", the exact wording `TitleScreen` and
## `PauseScreen` already use for the same control, rather than "Arrow keys or WASD to walk", which
## names two things it does not have.
func _test_the_walk_hint_names_the_touch_stick_on_a_touch_device(t) -> void:
	var hud := _hud(t)
	hud._touch = true

	hud._teach_the_day(1)
	t.check(hud._teach.text == "Drag the stick to walk",
			"day 1 tells a touch device to drag the stick, not press a key it has not got")

	hud.free()

## **Tap mode names a tap, not a control it does not draw.** `hud._controls_mode` is read once
## from `ControlsMode`, the same pattern `_touch` already is, and takes precedence over `_touch`
## for both lessons: there is no stick and no `RUN` circle to point at in tap mode, only the tap
## itself.
func _test_the_walk_and_run_hints_name_a_tap_in_tap_mode(t) -> void:
	var saved_day := GameState.day
	var hud := _hud(t)
	hud._controls_mode = ControlsMode.Mode.TAP
	hud._touch = true

	hud._teach_the_day(1)
	t.check(hud._teach.text == "Tap to walk, double tap to run",
			"day 1 in tap mode names the tap rather than the stick it does not draw")

	GameState.day = Tuning.RUN_TAUGHT_DAY
	var pursuer := _pursuer()
	hud._on_event_telegraphed(pursuer)
	t.check(hud._teach.text == "Double tap to run",
			"the run lesson in tap mode names the double tap rather than a RUN button it does not draw")

	pursuer.free()
	hud.free()
	GameState.day = saved_day

## **The pause hint has nothing to say in tap mode.** There is no pause key on a phone and no
## button to point at — `TapControls` pauses on its own, every stand rather than once per run, so
## the once-per-run keybinding lesson `_teach_the_pause()` teaches does not apply and must not fire.
func _test_the_pause_hint_says_nothing_in_tap_mode(t) -> void:
	var stroller := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	stroller.add_child(camera)
	t.add_child(stroller)
	stroller.set_physics_process(false)

	var hud := _hud(t)
	hud._controls_mode = ControlsMode.Mode.TAP
	hud._rig = stroller
	hud._walked_today = true

	for _i in 40: # 4s of stillness, past TEACH_PAUSE_AFTER
		hud._teach_the_pause(0.1)
	t.check(hud._teach.text == "" and not hud._taught_pause,
			"tap mode never raises the pause keybinding lesson at all")

	stroller.free()
	hud.free()

## **A lost nerve rewinds the day, not the run.** *(Player, of the deployed build: "the run lesson
## doesn't show at all anymore — it should always show for the day 3 lesson", diagnosed as "you
## need to reset the flag when the player dies on day 3.")* `main._start_day()` calls
## `_teach_the_day()` again on the same HUD instance when a nerve is spent, so the first retry of
## `RUN_TAUGHT_DAY` is already marked taught by an attempt the player never got to finish — and
## every attempt after that stays silent. The flag has to belong to the attempt on this one day.
func _test_the_run_hint_fires_again_on_a_retried_teaching_day(t) -> void:
	var saved_day := GameState.day
	GameState.day = Tuning.RUN_TAUGHT_DAY
	var hud := _hud(t)

	var first := _pursuer()
	hud._on_event_telegraphed(first)
	t.check(hud._taught_run, "the first attempt teaches the run")

	# The day restarts on the same HUD, exactly as a spent nerve does.
	hud._teach_the_day(Tuning.RUN_TAUGHT_DAY)
	t.check(not hud._taught_run, "a fresh attempt at the teaching day has not been taught yet")

	var second := _pursuer()
	hud._on_event_telegraphed(second)
	t.check(hud._teach.text == "Hold SHIFT to run",
			"and the lesson fires again on the second attempt")

	# Still only once within that attempt — the gate is the attempt, not "has this run seen it".
	hud._teach.text = ""
	var third := _pursuer()
	hud._on_event_telegraphed(third)
	t.check(hud._teach.text == "", "and still only once within one attempt")

	first.free()
	second.free()
	third.free()
	hud.free()
	GameState.day = saved_day

## **The meters move to the top on a touch build, so a walking thumb never rests on the one
## reading that may never be occluded.** *(2026-09-02: "let's also move the progress bars to the
## top for mobile so they're not hidden by the finger.")* `hud._touch` picks the anchors on
## `_reposition_meters_for_touch()`; desktop keeps the original bottom-left column untouched.
##
## Called directly a second time after flipping `_touch`, the same way `_teach_the_day()` is
## called again elsewhere in this file: `_touch` is read once at `_ready()`, which has already run
## by the time a test can reach it, so the repositioning has to be re-triggered explicitly to see
## the other shape.
func _test_the_meters_move_to_the_top_on_a_touch_device(t) -> void:
	var hud := _hud(t)
	t.check(hud._meters.anchor_top == 1.0 and hud._meters.anchor_bottom == 1.0,
			"desktop keeps the bottom-anchored column")
	# Measured before the flip rather than written down as 280x114: the size the desktop column
	# happens to be is a layout decision, and a test naming it would go red for a resize that
	# broke nothing. What this asserts is that repositioning does not *resize*.
	var was := Vector2(hud._meters.offset_right - hud._meters.offset_left,
			hud._meters.offset_bottom - hud._meters.offset_top)

	hud._touch = true
	hud._reposition_meters_for_touch()
	t.check(hud._meters.anchor_top == 0.0 and hud._meters.anchor_bottom == 0.0,
			"a touch device anchors the column to the top instead")
	t.check(hud._meters.offset_top > hud._header.offset_bottom,
			"and starts below where the day header ends, rather than under it")
	t.check(Vector2(hud._meters.offset_right - hud._meters.offset_left,
			hud._meters.offset_bottom - hud._meters.offset_top) == was,
			"the column keeps its own size — only where it sits changes")

	hud.free()

## **The pause lesson names the button that now exists, in plain words rather than a label that
## is not there.** Same defect the walk and run lessons had, filed by the same audit — `hud._touch`
## picks the wording, and `TouchControls._draw_pause_button()` draws an icon (two bars), not a
## word, so the touch line describes the control rather than naming a label it does not have, the
## same shape "Drag the stick to walk" already uses for the stick.
func _test_the_pause_hint_names_the_touch_button_on_a_touch_device(t) -> void:
	var stroller := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	stroller.add_child(camera)
	t.add_child(stroller)
	stroller.set_physics_process(false)

	var hud := _hud(t)
	hud._touch = true
	hud._rig = stroller
	hud._walked_today = true

	for _i in 40: # 4s of stillness, past TEACH_PAUSE_AFTER
		hud._teach_the_pause(0.1)
	t.check(hud._teach.text == "Tap the pause button to pause",
			"a touch device is told to tap the button, not press a key it has not got")

	# `.free()`, not `queue_free()`: `Stroller._exit_tree()` removes it from the "player" group
	# synchronously, and this suite never yields a frame for a deferred deletion to catch up —
	# `stroller.gd:105` puts every instance into that group, and `ContactPoint` (test_resistance.gd)
	# looks it up by group later in the same run, so a queued deletion here is a stale Stroller
	# another suite's lookup can pick up instead of its own.
	stroller.free()
	hud.free()

## **Being held is not stopping.** *(Player: "the pause tutorial comes up when being detained
## (since you're not moving)".)* `chatting_mother`'s `detain()` locks her input and lets friction
## settle her to idle, which used to read exactly like a stop of her own accord. The lesson has to
## wait for release, and the time spent held must not count toward the stand a released player
## still has to earn.
func _test_the_pause_hint_waits_out_a_detention(t) -> void:
	var stroller := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	stroller.add_child(camera)
	t.add_child(stroller)
	stroller.set_physics_process(false)

	var hud := _hud(t)
	hud._rig = stroller
	hud._walked_today = true

	stroller.detain(10.0)
	for _i in 40: # 4s of held stillness, past TEACH_PAUSE_AFTER
		hud._teach_the_pause(0.1)
	t.check(not hud._taught_pause, "held past the usual wait teaches nothing")
	t.check(hud._stood_for == 0.0, "and none of the held time is banked towards the lesson")

	stroller._detained_for = 0.0
	for _i in 40:
		hud._teach_the_pause(0.1)
	t.check(hud._taught_pause, "released, she still earns the lesson on her own stand")
	t.check(hud._teach.text == "Esc to pause", "and says the actual line")

	stroller.free()
	hud.free()

## Every pursuit after the teaching day is the mechanic working, not the lesson repeating —
## `alley_robbery` from day 8 pursues exactly like `charging_dog` does, and none of it is a
## keybinding reminder.
func _test_the_run_hint_never_fires_off_the_teaching_day(t) -> void:
	var saved_day := GameState.day

	# Before the day the run is taught: nothing has been taught yet, so there is nothing to repeat
	# either — the hint still must not fire, because it belongs to one specific day.
	GameState.day = Tuning.RUN_TAUGHT_DAY - 1
	var hud_before := _hud(t)
	var early := _pursuer()
	hud_before._on_event_telegraphed(early)
	t.check(hud_before._teach.text == "", "a pursuit before the teaching day says nothing")
	early.free()
	hud_before.free()

	# After it: the lesson already happened on an earlier day, and a fresh HUD (a new day started)
	# has never taught this run, but the pursuit is not on the teaching day, so it still says
	# nothing — the gate is the day, not just "has this run seen the hint yet".
	GameState.day = Tuning.RUN_TAUGHT_DAY + 5
	var hud_after := _hud(t)
	var late := _pursuer()
	hud_after._on_event_telegraphed(late)
	t.check(hud_after._teach.text == "", "a pursuit well after the teaching day says nothing")
	late.free()
	hud_after.free()

	GameState.day = saved_day

## Day, act and nerves are all read between days already; during the day the release build says
## none of it. `_debug` starts true in this process (the suite is itself a debug build), so the
## release shape has to be reached by hand.
func _test_the_release_hud_drops_the_header(t) -> void:
	var hud := _hud(t)

	hud._debug = false
	hud._refresh_header()
	t.check(hud._header.text == "", "the release build draws no header at all")

	hud._debug = true
	hud._refresh_header()
	t.check(hud._header.text != "", "a debug build still draws it, for the rigs and tools/shot.sh")

	hud.free()

## The baby's own state, `stall_reason()` and the city-wide note are debug output — the state is
## already on the pram, and the other two are read between days. An announcement is not part of
## that cut: it is the one thing the game says out loud, and it keeps the same label in both
## shapes because nothing else was asked to carry it.
func _test_the_release_hud_drops_the_status_line_but_keeps_announcements(t) -> void:
	var stroller := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	stroller.add_child(camera)
	t.add_child(stroller)
	stroller.set_physics_process(false)
	var baby := Baby.new()
	baby.name = "Baby"
	stroller.add_child(baby)
	baby.set_physics_process(false)

	var hud := _hud(t)
	hud._baby = baby

	hud._debug = false
	hud._refresh_state()
	t.check(hud._state_label.text == "",
			"state, stall reason and the city-wide note stay off screen in release")

	hud._debug = true
	hud._refresh_state()
	t.check(hud._state_label.text.begins_with("awake"), "a debug build still shows the state")
	t.check("not settling" in hud._state_label.text,
			"and the reason it is not settling, since she is standing still")

	# An announcement pre-empts the status line in both shapes.
	hud._debug = false
	hud._announcement = "The loudspeakers cut out mid-sentence."
	hud._announcement_for = 7.0
	hud._refresh_state()
	t.check(hud._state_label.text == hud._announcement,
			"an announcement is not the status line and is never cut")

	hud.free()
	stroller.free()

## Decided by the orchestrator, not the design, because the design was silent on this one detail:
## `resistance ***..` is a progress count, the same category as the header's `nerves ***`, so it
## is cut with the rest of the debug readout. The goal itself is kept — it is "the current optional
## goal" the decision names as staying — with no dots beside it, and with the `somewhere out there:`
## that makes a title an instruction rather than a noun.
func _test_the_release_optional_goal_keeps_its_title_and_drops_the_progress_dots(t) -> void:
	var hud := _hud(t)
	hud._debug = false

	hud._contact_step = 0
	hud._refresh_resistance()
	t.check(hud._resistance_label.text == "", "no current goal draws nothing")

	hud._contact_step = 1
	hud._refresh_resistance()
	var step := ResistanceSteps.by_index(1)
	t.check(hud._resistance_label.text == "somewhere out there: %s" % step.title.to_lower(),
			"the release line is the goal, said as an instruction rather than as a noun")
	t.check(not "resistance" in hud._resistance_label.text,
			"and carries no 'resistance ***..' progress count")

	hud._debug = true
	hud._refresh_resistance()
	t.check("resistance" in hud._resistance_label.text,
			"a debug build keeps the progress dots the rigs were built against")

	hud.free()

## *(Playtest 25 finding 1, verified against the engine rather than inferred: `"%3.0f" % value`
## rounds to nearest, so 99.5 and everything above it already printed `100` while the day was
## still live — read by the player on a phone as the crying rule being broken outright: "if
## excitement reaches 100 the game doesn't end! that's a major bug".)* The day ends only at
## exactly `Tuning.METER_MAX`, so the bar may not say so a fraction early. Nothing in this project
## screenshots a meter and reads the number back, which is exactly why this survived every gate —
## `MeterBar.displayed_value()` and `displayed_fraction()` are pulled out to pure functions for
## precisely that reason, so the formatting is a value this suite can hold without a render.
func _test_a_meter_bar_may_not_read_100_before_the_day_actually_ends(t) -> void:
	t.check(MeterBar.displayed_value(99.999) == 99,
			"a value a hair under the max still floors to 99, not a rounded-up 100")
	t.check(MeterBar.displayed_value(99.5) == 99,
			"99.5 is exactly the value that used to round up and cannot any more")
	t.check(MeterBar.displayed_value(100.0) == 100, "the true max still reads 100")
	t.check(MeterBar.displayed_value(0.0) == 0, "and the floor holds at the bottom of the bar too")

	# The fill has the same lie in a quieter shape: at 99.7% full no eye can tell it from solid, so
	# a bare `value / max_value` (0.999, well past the point an eye reads as solid) is not enough
	# of a check on its own — it asserts the cap actually held, not merely that the raw fraction
	# happens to round the same way.
	t.check(MeterBar.displayed_fraction(99.99, Tuning.METER_MAX) == MeterBar._MAX_FILL_BEFORE_FULL,
			"just short of the max is held at the visual ceiling rather than reading as nearly solid")
	t.check(MeterBar.displayed_fraction(Tuning.METER_MAX, Tuning.METER_MAX) == 1.0,
			"and only reaches solid once the value genuinely is the max")
	t.check(MeterBar.displayed_fraction(50.0, Tuning.METER_MAX) == 0.5,
			"and away from the ceiling the fraction is not touched at all")
