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
	_test_the_release_hud_drops_the_header(t)
	_test_the_release_hud_drops_the_status_line_but_keeps_announcements(t)
	_test_the_release_optional_goal_keeps_its_title_and_drops_the_progress_dots(t)

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
## is cut with the rest of the debug readout. The goal's own title is kept — it is "the current
## optional goal" the decision names as staying — with no dots beside it.
func _test_the_release_optional_goal_keeps_its_title_and_drops_the_progress_dots(t) -> void:
	var hud := _hud(t)
	hud._debug = false

	hud._contact_step = 0
	hud._refresh_resistance()
	t.check(hud._resistance_label.text == "", "no current goal draws nothing")

	hud._contact_step = 1
	hud._refresh_resistance()
	var step := ResistanceSteps.by_index(1)
	t.check(hud._resistance_label.text == step.title.to_lower(),
			"the release line is the goal's title alone")
	t.check(not "resistance" in hud._resistance_label.text,
			"and carries no 'resistance ***..' progress count")

	hud._debug = true
	hud._refresh_resistance()
	t.check("resistance" in hud._resistance_label.text,
			"a debug build keeps the progress dots the rigs were built against")

	hud.free()
