extends RefCounted
## The HUD's teaching lines, plus the debug/release gate that decides what else it draws.
##
## Most of what the HUD shows is read off `EventBus` values and is either checked by eye or
## covered by whatever produces the value. Two things here are a *rule* rather than a readout:
## when "Double tap to run" is allowed to say anything at all, and which lines the debug build keeps
## or drops. The HUD is configured the way `main` configures it (`configure()`, `use_touch()`,
## `use_run()`), put in the tree, and driven by the signals the game sends it
## (`EventBus.event_telegraphed`, `day_started`, `resistance_contact_available`, ...) and by real
## frames; what is read back is what it draws, found by the names the scene gives its labels. The
## release shape is a HUD configured with `debug` false: a test is itself a debug process, so the
## default would otherwise leave the release shape asserted by nothing.
##
## Each test hands its HUD a run of its own (`RunState.new()`), so none leans on, or leaves behind,
## a run shared with another test.

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const UIScreens := preload("res://tests/ui_screens.gd")

## How fast the long stands run (`Engine.time_scale` for the stretch, put back after it).
const FAST_SCALE := 21.0

func run(t) -> void:
	await _test_the_run_hint_fires_once_on_the_teaching_day(t)
	await _test_the_joystick_scheme_shows_its_run_button_in_the_run_lines(t)
	await _test_the_run_hint_never_fires_off_the_teaching_day(t)
	await _test_the_run_hint_fires_again_on_a_retried_teaching_day(t)
	await _test_the_run_hint_names_a_double_tap_on_a_touch_device(t)
	await _test_the_walk_hint_names_a_tap_on_a_touch_device(t)
	await _test_the_meters_move_to_the_top_on_a_touch_device(t)
	await _test_the_pause_hint_names_the_touch_button_on_a_touch_device(t)
	await _test_the_pause_hint_waits_out_a_detention(t)
	await _test_the_release_hud_drops_the_header(t)
	await _test_the_release_hud_drops_the_status_line_but_keeps_announcements(t)
	await _test_the_first_mark_is_never_named_but_later_ones_are(t)
	await _test_every_task_line_fits_on_one_line(t)
	await _test_a_touched_marks_message_breaks_between_sentences(t)
	await _test_every_perform_steps_header_names_the_instruction_not_the_title(t)
	await _test_a_completed_step_puts_no_text_on_screen(t)
	await _test_the_task_line_clears_when_the_task_is_done(t)
	_test_a_meter_bar_may_not_read_100_before_the_day_actually_ends(t)
	await _test_the_status_line_finds_a_baby_that_appears_after_the_hud_does(t)
	await _test_learned_lessons_say_no_control_lesson(t)
	await _test_unlearned_lessons_are_all_said(t)
	# The page's visit counter remembers the last day the bus announced (`VisitCounter._day`, which
	# reads `0` until one is heard); the suite announced several, so it puts the answer back to the
	# one a page that has heard none gives.
	EventBus.day_started.emit(0)
	_release_actions()

## A HUD configured as `main` configures it, before it enters the tree: `debug` false is the release
## shape, `touch` the device answer, `learned` an authored mid-game scene's `tutorial_complete`.
## It reads `run`, which the test owns.
func _hud(t, run: RunState, debug := true, touch := false, learned := false) -> CanvasLayer:
	var hud: CanvasLayer = HUD_SCENE.instantiate()
	hud.configure(debug, false, learned)
	hud.use_touch(touch)
	hud.use_run(run)
	t.add_child(hud)
	return hud

## A run of the test's own, on `day`.
func _run_on(day: int) -> RunState:
	var run := RunState.new()
	run.header.day = day
	return run

func _teach(hud: CanvasLayer) -> HelpText:
	return hud.find_child("Teach", true, false) as HelpText

func _label(hud: CanvasLayer, node_name: String) -> Label:
	return hud.find_child(node_name, true, false) as Label

func _pursuer() -> EventInstance:
	var def := EventDef.new()
	def.id = "test_pursuer"
	def.pursuit = PursuitSpec.new()
	def.telegraph_time = 2.0
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	return instance

## The director's announcement that step `step` is on offer. The task counter on the bus keeps what
## is open until the step completes or fails, so a test that leaves one open closes it with
## `_close_offers()`.
func _offer(step: int) -> void:
	EventBus.resistance_contact_available.emit(step)

func _close_offers(steps: Array[int]) -> void:
	for step in steps:
		EventBus.resistance_step_failed.emit(step)

## A mother with her camera in the tree and her own physics running: the rig the HUD looks up by
## group to ask whether she is standing still.
func _stroller(t) -> Stroller:
	var stroller := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	stroller.add_child(camera)
	t.add_child(stroller)
	return stroller

## She walks east with the move key held for a few real physics frames, then lets go and is left to
## settle to a standstill: "she has walked today" and "she has stopped" both happen the way they do
## in play.
func _walk_then_stop(t, stroller: Stroller) -> void:
	Input.action_press(&"move_right")
	for _i in 8:
		await t.get_tree().physics_frame
	Input.action_release(&"move_right")
	var guard := 0
	while not stroller.is_idle() and guard < 600:
		await t.get_tree().physics_frame
		guard += 1

## Counts the seconds the frames hand out, the same delta the HUD's own `_process()` is handed.
class Stopwatch extends Node:
	var seconds := 0.0

	func _process(delta: float) -> void:
		seconds += delta

## Lets frames pass under `Engine.time_scale` until `done` says so or `limit_seconds` of game time
## have gone by; the clock is put back after. Returns the seconds that passed.
func _stand(t, watch: Stopwatch, limit_seconds: float, done: Callable) -> float:
	var clock := Engine.time_scale
	Engine.time_scale = FAST_SCALE
	var start := watch.seconds
	var guard := 0
	while watch.seconds - start < limit_seconds and not done.call() and guard < 20000:
		await t.get_tree().process_frame
		guard += 1
	Engine.time_scale = clock
	await t.get_tree().process_frame
	return watch.seconds - start

## **The run hint belongs to the lesson, not the mechanic.** *("hold SHIFT to run randomly shows up
## sometimes after the running tutorial. it should only show up for the tutorial.")* The first
## pursuit telegraphed on `Tuning.RUN_TAUGHT_DAY` is the lesson, and it is the only telegraph in
## the whole run allowed to say anything: a second pursuit the same day is not a second lesson.
func _test_the_run_hint_fires_once_on_the_teaching_day(t) -> void:
	var run := _run_on(Tuning.RUN_TAUGHT_DAY)
	var hud := _hud(t, run)

	var first := _pursuer()
	EventBus.event_telegraphed.emit(first)
	t.check(_teach(hud).line == "Double tap to run",
			"the first pursuit of the teaching day shows the hint")

	# A second pursuit the same day — the day the lesson is repeated most, since `charging_dog` can
	# land more than once — must not read as a second lesson, so the day is marked taught.
	_teach(hud).show_line("")
	var second := _pursuer()
	EventBus.event_telegraphed.emit(second)
	t.check(_teach(hud).line == "", "a second pursuit the same day says nothing new: the day is marked taught")

	first.free()
	second.free()
	hud.free()

## **The lesson names the control on every device, not only a touch one.** *(Filed from a phone
## play of the deployed build: "the run tutorial says hold 'SHIFT' on mobile", then confirmed by
## playtest 29 finding 4: nothing on screen may name a key at all, on any device.)* The device flag
## used to choose between this wording and "Hold SHIFT to run"; now both values produce the same
## line, since the double-tap wording is the only one left.
func _test_the_run_hint_names_a_double_tap_on_a_touch_device(t) -> void:
	var run := _run_on(Tuning.RUN_TAUGHT_DAY)
	var hud := _hud(t, run, true, false)

	var first := _pursuer()
	EventBus.event_telegraphed.emit(first)
	t.check(_teach(hud).line == "Double tap to run",
			"a keyboard-and-mouse desktop gets the same wording — no key is named for it either")

	first.free()
	hud.free()

## **The day-1 walk lesson has the same defect the run lesson had, and the same fix.** *(Playtest
## 29 finding 4.)* The device flag used to choose between "Tap to walk, double tap to run" and
## "Arrow keys or WASD to walk"; the keyboard wording is gone, so both values now produce the touch
## line.
func _test_the_walk_hint_names_a_tap_on_a_touch_device(t) -> void:
	var run := _run_on(1)
	var hud := _hud(t, run, true, false)

	EventBus.day_started.emit(1)
	t.check(_teach(hud).line == "Tap to walk, double tap to run",
			"day 1 tells every device to tap — no key is named for a keyboard either")

	hud.free()

## **A lost nerve rewinds the day, not the run.** *(Player, of the deployed build: "the run lesson
## doesn't show at all anymore — it should always show for the day 3 lesson", diagnosed as "you
## need to reset the flag when the player dies on day 3.")* `main._start_day()` announces the day
## again on the same HUD instance when a nerve is spent, so the first retry of `RUN_TAUGHT_DAY` is
## already marked taught by an attempt the player never got to finish — and every attempt after
## that stays silent. The flag has to belong to the attempt on this one day.
func _test_the_run_hint_fires_again_on_a_retried_teaching_day(t) -> void:
	var run := _run_on(Tuning.RUN_TAUGHT_DAY)
	var hud := _hud(t, run)

	var first := _pursuer()
	EventBus.event_telegraphed.emit(first)
	t.check(_teach(hud).line == "Double tap to run", "the first attempt teaches the run")

	# The day restarts on the same HUD, exactly as a spent nerve does.
	EventBus.day_started.emit(Tuning.RUN_TAUGHT_DAY)
	var second := _pursuer()
	EventBus.event_telegraphed.emit(second)
	t.check(_teach(hud).line == "Double tap to run",
			"a fresh attempt at the teaching day has not been taught yet, so the lesson fires "
			+ "again on the second attempt")

	# Still only once within that attempt — the gate is the attempt, not "has this run seen it".
	_teach(hud).show_line("")
	var third := _pursuer()
	EventBus.event_telegraphed.emit(third)
	t.check(_teach(hud).line == "", "and still only once within one attempt")

	first.free()
	second.free()
	third.free()
	hud.free()

## **The meters move to the top on a touch build, so a walking thumb never rests on the one
## reading that may never be occluded.** *(2026-09-02: "let's also move the progress bars to the
## top for mobile so they're not hidden by the finger.")* The device answer, handed to the HUD
## before it enters the tree, picks the anchors; desktop keeps the original bottom-left column
## untouched. Two HUDs, one per answer, since the placement is made as the HUD enters the tree.
func _test_the_meters_move_to_the_top_on_a_touch_device(t) -> void:
	var run := _run_on(1)
	var desktop := _hud(t, run, true, false)
	var meters := desktop.find_child("Meters", true, false) as Control
	t.check(meters.anchor_top == 1.0 and meters.anchor_bottom == 1.0,
			"desktop keeps the bottom-anchored column")
	# Measured on the desktop column rather than written down as 280x114: the size the desktop
	# column happens to be is a layout decision, and a test naming it would go red for a resize that
	# broke nothing. What this asserts is that repositioning does not *resize*.
	var was := Vector2(meters.offset_right - meters.offset_left,
			meters.offset_bottom - meters.offset_top)

	var touch := _hud(t, run, true, true)
	var touch_meters := touch.find_child("Meters", true, false) as Control
	t.check(touch_meters.anchor_top == 0.0 and touch_meters.anchor_bottom == 0.0,
			"a touch device anchors the column to the top instead")
	t.check(touch_meters.offset_top > _label(touch, "Header").offset_bottom,
			"and starts below where the day header ends, rather than under it")
	t.check(Vector2(touch_meters.offset_right - touch_meters.offset_left,
			touch_meters.offset_bottom - touch_meters.offset_top) == was,
			"the column keeps its own size — only where it sits changes")

	desktop.free()
	touch.free()

## **The pause lesson names the button on every device, in plain words rather than a label that is
## not there.** Same defect the walk and run lessons had, filed by the same audit, closed the same
## way playtest 29 finding 4 closes it everywhere else: `TouchControls._draw_pause_button()` draws
## an icon (two bars), not a word, so the line describes the control rather than naming a label —
## or a key — that is not there. The device answer used to pick between this and "Esc to pause";
## now both values produce the same line. She walks, stops, and stands past `TEACH_PAUSE_AFTER` on
## real frames.
func _test_the_pause_hint_names_the_touch_button_on_a_touch_device(t) -> void:
	var run := _run_on(1)
	var stroller := _stroller(t)
	var hud := _hud(t, run, true, false)
	var watch := Stopwatch.new()
	t.add_child(watch)

	await _walk_then_stop(t, stroller)
	await _stand(t, watch, 4.0 * 2.0,
			func() -> bool: return _teach(hud).line != "")
	t.check(_teach(hud).line == "Press {pause} to pause",
			"a keyboard-and-mouse desktop is shown the pause button too — Esc is not named")

	# `.free()`, not `queue_free()`: `Stroller._exit_tree()` removes it from the "player" group
	# synchronously, and `Stroller._ready()` puts every instance into that group, and the crowd and
	# the HUD look her up by group later in the same run, so a queued deletion here is a stale
	# Stroller another suite's lookup can pick up instead of its own.
	watch.free()
	stroller.free()
	hud.free()
	_release_actions()

## **Being held is not stopping.** *(Player: "the pause tutorial comes up when being detained
## (since you're not moving)".)* `chatting_mother`'s `detain()` locks her input and lets friction
## settle her to idle, which used to read exactly like a stop of her own accord. The lesson has to
## wait for release, and the time spent held must not count toward the stand a released player
## still has to earn: held for longer than the usual wait it says nothing, and once her detention
## runs out it still takes the full wait of her own stillness.
func _test_the_pause_hint_waits_out_a_detention(t) -> void:
	var run := _run_on(1)
	var stroller := _stroller(t)
	var hud := _hud(t, run)
	var watch := Stopwatch.new()
	t.add_child(watch)

	await _walk_then_stop(t, stroller)
	# Part of the stand is already earned when the detention begins: the lesson must not keep it.
	await _stand(t, watch, 2.0, func() -> bool: return _teach(hud).line != "")
	t.check(_teach(hud).line == "", "two seconds of her own stillness is not yet the lesson")
	var held_for: float = hud.TEACH_PAUSE_AFTER * 2.0
	stroller.detain(held_for)
	await _stand(t, watch, held_for * 0.9, func() -> bool: return _teach(hud).line != "")
	t.check(stroller.is_detained() and _teach(hud).line == "",
			"held past the usual wait teaches nothing")

	await _stand(t, watch, held_for, func() -> bool: return not stroller.is_detained())
	var released_at := watch.seconds
	t.check(_teach(hud).line == "", "the moment she is let go, none of the held time has been banked "
			+ "towards the lesson")
	await _stand(t, watch, hud.TEACH_PAUSE_AFTER * 4.0,
			func() -> bool: return _teach(hud).line != "")
	t.check(_teach(hud).line == "Press {pause} to pause",
			"released, she still earns the lesson on her own stand, and says the actual line, the "
			+ "pause symbol in it — no key named, even on this default (non-touch) device")
	t.check(watch.seconds - released_at >= hud.TEACH_PAUSE_AFTER - 1.0,
			"after her own full wait of stillness, not sooner")

	watch.free()
	stroller.free()
	hud.free()
	_release_actions()

## Every pursuit after the teaching day is the mechanic working, not the lesson repeating —
## `alley_robbery` from day 8 pursues exactly like `charging_dog` does, and none of it is a
## keybinding reminder.
func _test_the_run_hint_never_fires_off_the_teaching_day(t) -> void:
	# Before the day the run is taught: nothing has been taught yet, so there is nothing to repeat
	# either — the hint still must not fire, because it belongs to one specific day.
	var run_before := _run_on(Tuning.RUN_TAUGHT_DAY - 1)
	var hud_before := _hud(t, run_before)
	var early := _pursuer()
	EventBus.event_telegraphed.emit(early)
	t.check(_teach(hud_before).line == "", "a pursuit before the teaching day says nothing")
	early.free()
	hud_before.free()

	# After it: the lesson already happened on an earlier day, and a fresh HUD (a new day started)
	# has never taught this run, but the pursuit is not on the teaching day, so it still says
	# nothing — the gate is the day, not just "has this run seen the hint yet".
	var run_after := _run_on(Tuning.RUN_TAUGHT_DAY + 5)
	var hud_after := _hud(t, run_after)
	var late := _pursuer()
	EventBus.event_telegraphed.emit(late)
	t.check(_teach(hud_after).line == "", "a pursuit well after the teaching day says nothing")
	late.free()
	hud_after.free()

## Day, act and nerves are all read between days already; during the day the release build says
## none of it. A test is itself a debug build, so the release shape is a HUD configured for it.
func _test_the_release_hud_drops_the_header(t) -> void:
	var run := _run_on(1)
	var release := _hud(t, run, false)
	t.check(_label(release, "Header").text == "", "the release build draws no header at all")

	var debug := _hud(t, run, true)
	t.check(_label(debug, "Header").text != "",
			"a debug build still draws it, for the rigs and tools/shot.sh")

	release.free()
	debug.free()

## The baby's own state, `stall_reason()` and the city-wide note are debug output — the state is
## already on the pram, and the other two are read between days. An announcement is not part of
## that cut: it is the one thing the game says out loud, and it keeps the same label in both
## shapes because nothing else was asked to carry it.
func _test_the_release_hud_drops_the_status_line_but_keeps_announcements(t) -> void:
	var run := _run_on(1)
	var stroller := _stroller(t)
	stroller.set_physics_process(false)
	var baby := Baby.new()
	baby.name = "Baby"
	stroller.add_child(baby)
	baby.set_physics_process(false)

	var release := _hud(t, run, false)
	var debug := _hud(t, run, true)
	await UIScreens.frames(t)
	t.check(_label(release, "State").text == "",
			"state, stall reason and the city-wide note stay off screen in release")

	t.check(_label(debug, "State").text.begins_with("awake"), "a debug build still shows the state")
	t.check("not settling" in _label(debug, "State").text,
			"and the reason it is not settling, since she is standing still")

	# An announcement pre-empts the status line in both shapes.
	EventBus.city_went_quiet.emit()
	t.check(_label(release, "State").text == Texts.CITY_WENT_QUIET,
			"an announcement is not the status line and is never cut")
	t.check(_label(debug, "State").text == Texts.CITY_WENT_QUIET,
			"and the debug build says it too")

	release.free()
	debug.free()
	stroller.free()

## *"The readout said 'awake' while the baby was drawn asleep,"* found once under
## `--start-escape stairwell:right --invincible`. `main` builds this HUD before the escape's
## building or city — and so before the `Baby` it goes looking for even exists — so the HUD's
## one-time lookup of the baby came back empty and the readout stayed on `hud.tscn`'s own
## placeholder text, "awake", for the whole section, no matter what she actually was. The HUD now
## re-asks the group whenever it has no baby yet, so the first frame the escape's `Baby` exists is
## the first frame the readout can see it too — the same `Baby.state` the pram's own picture
## (`Stroller._draw_baby_cue()`) already reads.
func _test_the_status_line_finds_a_baby_that_appears_after_the_hud_does(t) -> void:
	var run := _run_on(1)
	var hud := _hud(t, run)
	await UIScreens.frames(t)
	t.check(_label(hud, "State").text == "awake",
			"with no Baby to read, the label is stuck on the scene's own placeholder — the defect itself")

	var stroller := _stroller(t)
	stroller.set_physics_process(false)
	var baby := Baby.new()
	baby.name = "Baby"
	stroller.add_child(baby)
	baby.set_physics_process(false)
	baby.state = GameEnums.BabyState.ASLEEP

	await UIScreens.frames(t)
	t.check(_label(hud, "State").text.begins_with("asleep"),
			"the readout picks up the baby the frame it appears and reads the same state the pram "
			+ "is drawn from, not the scene's own placeholder (got '%s')" % _label(hud, "State").text)

	hud.free()
	stroller.free()

## Playtest 19 finding 5, verbatim: *"the first chalk mark is written in the status when it
## should not be"* — seen as `resistance ....   out there: a chalk mark` before
## anything had been found. `CLAUDE.md`'s own rule is that the first encounter comes with no
## hint at all, so the goal title is silent until the run's `resistance.completed_steps` is
## non-empty — which happens the instant the first mark is *touched*, not once its perform
## half is done a day later, because `complete_resistance_step` records a pickup too even
## though a pickup grants no progress. `has_joined_resistance()` (`progress > 0`) would still
## be zero at that point, which is why it is not the test here.
func _test_the_first_mark_is_never_named_but_later_ones_are(t) -> void:
	var run := _run_on(1)
	var release := _hud(t, run, false)
	var debug := _hud(t, run, true)

	_offer(1)
	t.check(_label(release, "Resistance").text == "",
			"the release line names nothing before the first mark is found")
	t.check(_label(debug, "Resistance").text == "resistance %s" % ".".repeat(Tuning.RESISTANCE_GOAL),
			"a debug build keeps its own progress dots, but no title beside them either")

	run.complete_resistance_step(1, false)

	_offer(2)
	var step := ResistanceSteps.by_index(2)
	t.check(_label(release, "Resistance").text == "out there: %s" % step.header.to_lower(),
			"once the first mark is touched, the next one is named by its own instruction")
	t.check(not step.title.to_lower() in _label(release, "Resistance").text,
			"and not by the step's bare title, which is what playtest 69 could not use")
	t.check(not "resistance" in _label(release, "Resistance").text,
			"and the release line still carries no 'resistance ***..' progress count")

	t.check("resistance" in _label(debug, "Resistance").text
			and step.header.to_lower() in _label(debug, "Resistance").text,
			"a debug build keeps the progress dots the rigs were built against, instruction and all")

	_close_offers([2])
	release.free()
	debug.free()

## The small HUD task line is the short version and always one line: every step's own line fits
## the width the HUD gives the label (the Meters column, 280px) at its 12px font, so it never wraps.
func _test_every_task_line_fits_on_one_line(t) -> void:
	var run := _run_on(1)
	var hud := _hud(t, run, false)
	var label := _label(hud, "Resistance")
	var font_size: int = label.get_theme_font_size("font_size")
	var width: float = label.get_parent().get_combined_minimum_size().x
	t.check(width >= 280.0, "the Meters column gives the task line at least 280px")
	# Non-empty so the HUD's own "already touched a mark" gate is open.
	run.resistance.completed_steps = [1]
	for step in ResistanceSteps.all():
		_offer(step.index)
		# A pickup has no header and shows its title, exactly as the HUD names it.
		var line: String = label.text
		var w := ThemeDB.fallback_font.get_string_size(
				line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		t.check(w <= 280.0, "step %d's task line '%s' fits one line (%d px)"
				% [step.index, line, int(w)])
		t.check(line.begins_with("out there: ") and not "\n" in line,
				"step %d's task line starts 'out there:' and has no break" % step.index)
		_close_offers([step.index])
	hud.free()

## The big message shown when a mark is touched breaks between sentences where it must wrap: every
## real mark text comes out with each line inside the Teach label's width, and a sentence is never
## split. A two-sentence message too wide for one line breaks after the first.
func _test_a_touched_marks_message_breaks_between_sentences(t) -> void:
	var run := _run_on(1)
	var hud := _hud(t, run)
	var teach := _teach(hud)
	var font_size: int = teach.get_theme_font_size("normal_font_size")
	var width: float = teach.custom_minimum_size.x
	t.check(width > 0.0, "the Teach label has a width for the helper to wrap to")
	for step in ResistanceSteps.all():
		if step.brief == "":
			continue
		var broken := SentenceLines.break_for_help(step.brief, teach)
		t.check(broken.replace("\n", " ") == step.brief,
				"step %d's message only gains breaks, never loses words" % step.index)
		for line in broken.split("\n"):
			var w := ThemeDB.fallback_font.get_string_size(
					line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			# A line the helper cannot break any further is one sentence.
			var single := SentenceLines.break_for_help(line, teach) == line
			t.check(w <= width or single,
					"step %d's line '%s' fits the width or is one sentence" % [step.index, line])

	var step := ResistanceSteps.by_index(3)
	var saved_brief := step.brief
	step.brief = "A van is waiting on the sidewalk by the old market. Do not come home empty-handed tonight."
	EventBus.resistance_step_completed.emit(3)
	t.check(teach.line == "A van is waiting on the sidewalk by the old market.\n"
			+ "Do not come home empty-handed tonight.",
			"a touched mark's long message breaks after its first sentence, got '%s'" % teach.line)
	step.brief = saved_brief
	hud.free()

## The wording rule holds for every task, not only the first: every perform step
## names `Step.header` — the associated mark's own words, cut to fit — never `Step.title`, which
## stays unused by the header and is reserved for the progress dots.
func _test_every_perform_steps_header_names_the_instruction_not_the_title(t) -> void:
	var run := _run_on(1)
	var hud := _hud(t, run, false)
	var label := _label(hud, "Resistance")
	for step in ResistanceSteps.all():
		if step.is_pickup or step.needs_goal:
			continue
		t.check(step.header != "", "perform step %d has its own header phrase" % step.index)
		# Non-empty so the HUD's own "already touched a mark" gate is open.
		run.resistance.completed_steps = [step.index - 1]
		_offer(step.index)
		t.check(label.text == "out there: %s" % step.header.to_lower(),
				"step %d's header names the instruction ('%s')" % [step.index, label.text])
		t.check(not step.title.to_lower() in label.text,
				"step %d's header never falls back to naming the title" % step.index)
		_close_offers([step.index])

	hud.free()

## *"no onscreen text for acknowledgements like this"* (PLAYTEST-117): a **finished** resistance
## step is shown by the world — the mark's touched picture, the man shouting walking away — and
## the HUD's teaching line stays out of acknowledging that, for a mark and for a perform step
## alike. A **mark**'s own completion is the one exception, and a decided one: *"since the task
## will be immediately announced when touching the mark there is no need to mention tasks in the
## day brief at all"* moved the announcement onto the world's own teaching line instead of
## removing it.
func _test_a_completed_step_puts_no_text_on_screen(t) -> void:
	var run := _run_on(1)
	var hud := _hud(t, run)
	_teach(hud).show_line("")
	EventBus.resistance_step_completed.emit(1)
	t.check(_teach(hud).line == ResistanceSteps.by_index(1).brief,
			"a completed mark announces its own words on the teaching line — the mark and " +
			"nowhere else — rather than staying silent")
	_teach(hud).show_line("")
	EventBus.resistance_step_completed.emit(2)
	t.check(_teach(hud).line == "", "a completed perform step puts no text on screen")

	hud.free()

## fluffy-alpaca, "the bottom left text with the current task should disappear when the task is
## complete" — *"this is not an onscreen text that shows up so it fits the rule still. but it is
## helpful as indication that the task was completed correctly because most tasks right now are
## not clear about whether they have been completed."* Pinned for a mark and for a task, as the
## item asks: a perform step's own completion is the day's last contact, so nothing else ever
## overwrites the "out there:" line on its own, and clearing it on completion is what stops it
## naming an already-finished task for the rest of the day.
func _test_the_task_line_clears_when_the_task_is_done(t) -> void:
	var run := _run_on(7)
	# Day 6 already behind her, so the "first mark is never named" gate — the goal has been
	# joined — is open for day 7's own mark (index 3) and perform (index 4) below.
	run.resistance.completed_steps = [1, 2]
	run.resistance.progress = 1

	var hud := _hud(t, run, false)
	var label := _label(hud, "Resistance")

	# A mark: its own completion clears the line, and the perform it unlocks a moment later
	# overwrites the blank with its own instruction — the same order the director fires them in
	# during play.
	_offer(3)
	t.check(label.text != "", "day 7's mark has its own line on screen")
	run.complete_resistance_step(3, false)
	t.check(label.text == "",
			"touching the mark clears the line before the perform it unlocks is announced")
	_offer(4)
	t.check(label.text != "", "and the perform's own instruction takes its place a moment later")

	# A task: its own completion clears the line, and nothing follows to put it back, since it
	# is the day's last contact.
	run.complete_resistance_step(4, true)
	t.check(label.text == "",
			"completing the task clears the line, with no further contact to overwrite it")

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
	# a bare `value / max_value` is not enough of a check on its own — the cap must actually hold:
	# two values short of the max, whose raw fractions differ, draw the same fill, below the raw one.
	var capped := MeterBar.displayed_fraction(99.99, Tuning.METER_MAX)
	t.check(capped < 99.99 / Tuning.METER_MAX
			and capped == MeterBar.displayed_fraction(99.5, Tuning.METER_MAX) and capped < 1.0,
			"just short of the max is held at the visual ceiling rather than reading as nearly solid")
	t.check(MeterBar.displayed_fraction(Tuning.METER_MAX, Tuning.METER_MAX) == 1.0,
			"and only reaches solid once the value genuinely is the max")
	t.check(MeterBar.displayed_fraction(50.0, Tuning.METER_MAX) == 0.5,
			"and away from the ceiling the fraction is not touched at all")

## **The joystick scheme's run lines show the run button.** *(2026-10-04, the player, inbox #533:
## "joystick run should now say hold <run button> or double tap to run where it makes sense".)* The
## tap scheme draws no run button, so it keeps "double tap to run"; a `TouchControls` in the tree
## set to `JOYSTICK` is what the HUD asks.
func _test_the_joystick_scheme_shows_its_run_button_in_the_run_lines(t) -> void:
	var run := _run_on(Tuning.RUN_TAUGHT_DAY)
	var controls: TouchControls = load("res://scenes/ui/touch_controls.tscn").instantiate()
	t.add_child(controls)
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	var hud := _hud(t, run)
	var teach := _teach(hud)

	EventBus.day_started.emit(1)
	t.check(teach.line == "Tap to walk, hold {run} or double tap to run",
			"joystick, day 1: walking by tap, running by the run button or a double tap")
	var p1 := _pursuer()
	EventBus.event_telegraphed.emit(p1)
	t.check(teach.line == "Hold {run} or double tap to run",
			"joystick, first pursuit: the run button's symbol in the line, got '%s'" % teach.line)
	var with_symbol: int = teach.get_content_width()
	teach.show_line("Hold  or double tap to run")
	t.check(with_symbol >= teach.get_content_width() + 20,
			"and the symbol is really placed in the label (%d px against %d without it)"
			% [with_symbol, teach.get_content_width()])

	controls.set_mode(ControlsMode.Mode.TAP)
	EventBus.day_started.emit(1)
	t.check(teach.line == "Tap to walk, double tap to run",
			"tap, day 1: no run button on screen, so none in the line")

	EventBus.day_started.emit(Tuning.RUN_TAUGHT_DAY)
	var p2 := _pursuer()
	EventBus.event_telegraphed.emit(p2)
	t.check(teach.line == "Double tap to run", "tap, first pursuit: unchanged")

	# The title chooses the scheme after day 1 began, and `main` emits the choice before it sets
	# the scheme on `TouchControls`, which still answers TAP here.
	run.header.day = 1
	EventBus.controls_chosen.emit(true, false)
	t.check(teach.line == "Tap to walk, hold {run} or double tap to run",
			"choosing joystick on the title says day 1's line in the joystick wording")
	EventBus.controls_chosen.emit(false, false)
	t.check(teach.line == "Tap to walk, double tap to run", "and choosing tap says the tap one")

	teach.show_line("a [b]bracket[/b] line")
	t.check(teach.get_parsed_text().contains("[b]"), "a line is shown literally, never parsed as BBCode")

	p1.free()
	p2.free()
	controls.free()
	hud.free()

## `configure(debug, invincible, lessons_learned)` with `lessons_learned` (an authored mid-game
## scene's `tutorial_complete`) silences the three ordinary control lessons and nothing else: the
## walking lesson on day 1 (at dawn and again when the controls are chosen), the pause lesson
## (a stand after walking says nothing) and the run lesson (the teaching day does not reopen it).
## Each assertion fails if its guard is dropped.
func _test_learned_lessons_say_no_control_lesson(t) -> void:
	var run := _run_on(1)
	var stroller := _stroller(t)
	var hud := _hud(t, run, true, false, true)
	var teach := _teach(hud)
	EventBus.day_started.emit(1)
	t.check(teach.line == "", "learned: day 1 says no walking lesson at dawn")
	EventBus.controls_chosen.emit(true, false)
	t.check(teach.line == "", "learned: choosing the controls says no walking lesson")
	EventBus.day_started.emit(Tuning.RUN_TAUGHT_DAY)
	run.header.day = Tuning.RUN_TAUGHT_DAY
	var pursuer := _pursuer()
	EventBus.event_telegraphed.emit(pursuer)
	t.check(teach.line == "",
			"learned: the teaching day does not reset the run lesson, so a pursuit says none")

	var watch := Stopwatch.new()
	t.add_child(watch)
	await _walk_then_stop(t, stroller)
	var stood := await _stand(t, watch, hud.TEACH_PAUSE_AFTER * 3.0,
			func() -> bool: return teach.line != "")
	t.check(stood >= hud.TEACH_PAUSE_AFTER * 3.0 and teach.line == "",
			"learned: the pause lesson starts taught, so a long stand says nothing")

	watch.free()
	pursuer.free()
	stroller.free()
	hud.free()
	_release_actions()

## The same calls with `lessons_learned` false: every lesson comes back, so the test above cannot
## pass for a HUD that says nothing at all.
func _test_unlearned_lessons_are_all_said(t) -> void:
	var run := _run_on(1)
	var stroller := _stroller(t)
	var hud := _hud(t, run, true, false, false)
	var teach := _teach(hud)
	EventBus.day_started.emit(1)
	t.check(teach.line != "", "unlearned: day 1 says the walking lesson at dawn")
	teach.show_line("")
	EventBus.controls_chosen.emit(true, false)
	t.check(teach.line != "", "unlearned: choosing the controls says it again")
	EventBus.day_started.emit(Tuning.RUN_TAUGHT_DAY)
	run.header.day = Tuning.RUN_TAUGHT_DAY
	var pursuer := _pursuer()
	EventBus.event_telegraphed.emit(pursuer)
	t.check(teach.line != "",
			"unlearned: the teaching day opens the run lesson, so a pursuit says it")

	teach.show_line("")
	var watch := Stopwatch.new()
	t.add_child(watch)
	await _walk_then_stop(t, stroller)
	await _stand(t, watch, hud.TEACH_PAUSE_AFTER * 4.0,
			func() -> bool: return teach.line != "")
	t.check(teach.line != "", "unlearned: the pause lesson is still to come, and a stand says it")

	watch.free()
	pursuer.free()
	stroller.free()
	hud.free()
	_release_actions()

func _release_actions() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")
	Input.action_release(&"run")
