extends RefCounted
## The HUD's teaching lines — currently just the run hint, which is the one that has been wrong.
##
## Everything else the HUD draws is read off `EventBus` values and is either checked by eye or
## covered by whatever produces the value. This suite is for the one piece of HUD logic that is a
## *rule* rather than a readout: when "Hold SHIFT to run" is allowed to say anything at all.

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")

func run(t) -> void:
	_test_the_run_hint_fires_once_on_the_teaching_day(t)
	_test_the_run_hint_never_fires_off_the_teaching_day(t)

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
