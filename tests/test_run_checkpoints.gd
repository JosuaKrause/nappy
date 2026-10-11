extends RefCounted
## A run's checkpoints and its two modes — see docs/MECHANICS.md, "Nerves" and "Saving and
## resuming". A normal run that spends its last nerve goes back to the latest checkpoint it has
## reached (days 4, 8 and 12, or day 1 of the same city before them) with every nerve, **in exactly
## the state the run had at that checkpoint's dawn**; a hard run has none, and its last nerve is
## the bad ending, in the days and in the escape alike. *(gentle-osprey, the player: "store the exact
## state at the checkpoint -- continuing should not have anything that happened after the
## checkpoint".)*
##
## Not `tests/test_checkpoints.gd`, which is the region wall's gatehouses — the same word for a
## different thing, and the reason this suite's name says whose checkpoints these are.
##
## `run()` snapshots the whole save first and puts it back last, and points `GameSave` at a scratch
## file for the round trip, so nothing here leaks into the next suite or reaches the player's save.

const _SCRATCH_PATH := "user://test_run_checkpoints_scratch.json"
const _SEED := 712044
const MAIN_SCRIPT: GDScript = preload("res://src/main.gd")
const TITLE := preload("res://scenes/ui/title_screen.tscn")
const SUMMARY_SCENE := preload("res://scenes/ui/day_summary.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")

func run(t) -> void:
	var baseline := GameSave.file_data(false)
	GameSave.set_path_override(_SCRATCH_PATH)

	_test_going_back_restores_every_field_the_save_carries(t)
	_test_a_checkpoint_is_kept_only_the_first_time_its_day_is_begun(t)
	_test_checkpoint_zero_is_day_one_of_the_same_city(t)
	_test_a_hard_run_keeps_no_checkpoint_and_ends_on_its_last_nerve(t)
	_test_choosing_hard_mode_drops_a_checkpoint_already_kept(t)
	_test_a_hard_runs_escape_spends_nerves_and_ends_on_the_last(t)
	_test_a_hard_run_gets_a_nerve_back_for_leaving_the_building(t)
	_test_the_lost_day_screen_says_where_she_goes_back_to(t)
	_test_the_checkbox_shows_only_for_a_new_game(t)
	_test_a_press_on_the_checkbox_flips_it_and_never_starts_the_run(t)
	_test_the_title_sets_a_new_games_mode_and_leaves_a_resumed_ones(t)

	GameSave._clear_now()
	GameSave.set_path_override("")
	GameSave.restore_run_data(baseline)
	GameState.hard_mode = bool(baseline["hard_mode"])
	GameState.checkpoint = baseline["checkpoint"]

# ------------------------------------------------------------------ the checkpoint ---

## **The exact state at the checkpoint, every field the save carries.** The run is played into
## day 4 (its first checkpoint), on past it with a lost day and a won one, written to the file and
## read back so the checkpoint has been through JSON, then every field the save carries is changed
## and the last nerve is lost: what comes back must be the checkpoint's own dawn, field for field,
## with every nerve.
##
## **The fields are enumerated off the save itself, not listed here.** `GameSave.file_data()` is
## everything the file holds; less `GameSave.FILE_KEYS` (the file's format, build, the day under way,
## the mode and the checkpoint), every top-level key and every field under `"state"` is checked
## twice: once that `_change_everything()` actually changed it — so a field a later build adds to
## the save fails here until it is changed too — and once that going back gave it back. A field the
## restore left out keeps its changed value and fails the second check; a field the save never
## carries at all is `tests/test_save.gd`'s `_test_round_trip_field_list_matches_the_property_list`.
func _test_going_back_restores_every_field_the_save_carries(t) -> void:
	GameState.start_run(_SEED)
	for d in range(1, 4):
		GameState.begin_day()
		GameState.remember_where_she_settled(Vector2i(d, d))
		GameState.finish_day(GameEnums.DayResult.WON)
	t.check(GameState.day == 4, "three won days reach day 4")
	GameState.nerves = 3
	GameState.begin_day()
	var expected := GameSave.run_data()
	t.check(GameState.checkpoint == expected, "beginning day 4 keeps its dawn as the checkpoint")

	# On past it: a lost attempt at day 4, a won one, and into day 5.
	GameState.add_scar("after_the_checkpoint", Vector2(40.0, 40.0))
	GameState.finish_day(GameEnums.DayResult.LOST_CRYING)
	GameState.begin_day()
	GameState.finish_day(GameEnums.DayResult.WON)
	GameState.begin_day()
	t.check(GameState.day == 5 and GameState.checkpoint == expected,
			"day 5 is under way and the checkpoint is still day 4's dawn")

	# Through the file, so the checkpoint given back is the one a closed game would come back to.
	t.check(GameSave._write_now(true), "the run is written with its checkpoint")
	GameState.start_run(_SEED + 1)
	t.check(not GameSave._read_now().is_empty(), "and read back")
	t.check(GameState.checkpoint_day() == 4, "with its checkpoint on day 4")

	var keys := _run_keys()
	t.check(keys.size() > 10, "there are fields to check (%d)" % keys.size())
	var before := _flatten(GameSave.file_data(false))
	_change_everything()
	var changed := _flatten(GameSave.file_data(false))
	for key in keys:
		t.check(changed[key] != before[key] and changed[key] != _flatten_run(expected)[key],
				"'%s' is changed after the checkpoint — a field this test does not change cannot "
						% key + "show that going back gives it back; change it in _change_everything()")

	GameState.nerves = 1
	t.check(GameState.a_loss_goes_back_to_the_checkpoint(), "losing now spends a normal run's last nerve")
	t.check(GameState.finish_day(GameEnums.DayResult.LOST_HARD_FAIL), "and the run goes on")
	var after := _flatten(GameSave.file_data(false))
	var wanted := _flatten_run(expected)
	wanted["state.nerves"] = Tuning.STARTING_NERVES
	for key in keys:
		t.check(after[key] == wanted[key],
				"'%s' is the checkpoint's own dawn again (%s, wanted %s)"
						% [key, str(after[key]).left(80), str(wanted[key]).left(80)])
	t.check(GameState.nerves == Tuning.STARTING_NERVES and GameState.day == 4,
			"back at day 4 with every nerve")
	t.check(GameState.checkpoint_day() == 4 and not GameState.hard_mode,
			"still a normal run, whose checkpoint is still day 4")
	t.check(GameState.ending == GameEnums.Ending.NONE, "and a normal run has no bad ending")

## Every key of the file that is the run's own state — top-level riders by name, and `"state"`'s
## fields as `state.<name>` — read off `GameSave.file_data()` itself.
func _run_keys() -> Array[String]:
	var keys: Array[String] = []
	for key: String in _flatten(GameSave.file_data(false)):
		if key.get_slice(".", 0) in GameSave.FILE_KEYS:
			continue
		keys.append(key)
	return keys

func _flatten(data: Dictionary) -> Dictionary:
	var flat := {}
	for key: String in data:
		if key == "state":
			var state: Dictionary = data[key]
			for field: String in state:
				flat["state." + field] = state[field]
		else:
			flat[key] = data[key]
	return flat

## A checkpoint has no file keys, so it flattens to exactly the run keys.
func _flatten_run(data: Dictionary) -> Dictionary:
	return _flatten(data)

## Every field the save carries, moved somewhere the checkpoint's dawn could not have had it.
func _change_everything() -> void:
	GameState.run_seed += 1
	GameState.player_is_male = not GameState.player_is_male
	GameState.day = 10
	GameState.nerves = 2
	GameState.resistance_progress += 3
	GameState.ending = GameEnums.Ending.NEUTRAL
	GameState.play_seconds += 500.0
	GameState.consumed_one_shots.append("spent_after_the_checkpoint")
	GameState.completed_resistance_steps.append(99)
	GameState.failed_resistance_steps.append(98)
	GameState.add_scar("scarred_after_the_checkpoint", Vector2(120.0, 80.0))
	GameState.city_state.apply_cause({Vector2i(30, 30): _fake_block_plan()}, Vector2i(30, 30),
			GameEnums.BlockCause.FIRE, 10)
	GameState.sabotage_done = not GameState.sabotage_done
	GameState.resistance_carrying_package = not GameState.resistance_carrying_package
	GameState._dawn_completed_steps.append(97)
	GameState._dawn_failed_steps.append(96)
	GameState._dawn_progress += 2
	GameState._dawn_sabotage_done = not GameState._dawn_sabotage_done
	GameState._dawn_carrying_package = not GameState._dawn_carrying_package
	GameState.settled_in[10] = Vector2i(5, 5)
	GameState._dawn_consumed_one_shots.append("photographed_after_the_checkpoint")
	GameState._dawn_scars.append({"id": "dawn_after", "position": Vector2(9.0, 9.0), "since_day": 9})
	GameState._dawn_city_state = {"stage": [{"x": 41, "y": 41, "v": 1}]}
	GameState.escape_section = FinaleController.Section.CITY
	GameState.completed_resistance_alley_tiles.append(Vector2i(77, 77))
	GameState.fenced_park = Vector2i(3, 3)
	GameState.fenced_park_act = 3
	GameState.posters.paste(Vector2i(9, 9), 0, false, 1)
	GameState.posters.tears += 1
	GameState.posters.pasted_through += 4
	GameState.posters.photograph()

func _fake_block_plan() -> BlockPlan:
	var plan := BlockPlan.new()
	plan.steps = [
		BlockPlan.Step.new(GameEnums.BlockPurpose.RESIDENTIAL, 1, GameEnums.BlockCause.SCHEDULED),
		BlockPlan.Step.new(GameEnums.BlockPurpose.BURNT_OUT, 1, GameEnums.BlockCause.FIRE),
	]
	return plan

## The checkpoint is the first dawn of its day and nothing later: a retry of day 4, a run sent back
## to day 4, and days 5 to 7 all keep day 4's; only day 8 replaces it.
func _test_a_checkpoint_is_kept_only_the_first_time_its_day_is_begun(t) -> void:
	GameState.start_run(_SEED)
	t.check(GameState.checkpoint_day() == 1, "a fresh run's checkpoint is day 1")
	GameState.day = 4
	GameState.begin_day()
	var day_four := GameState.checkpoint.duplicate(true)
	t.check(GameState.checkpoint_day() == 4, "day 4 is a checkpoint")
	GameState.play_seconds = 77.0
	GameState.finish_day(GameEnums.DayResult.LOST_TIMEOUT)
	GameState.begin_day()
	t.check(GameState.checkpoint == day_four, "a retry of day 4 does not replace its dawn")
	for d in range(4, 8):
		GameState.finish_day(GameEnums.DayResult.WON)
		GameState.begin_day()
		if GameState.day < 8:
			t.check(GameState.checkpoint == day_four,
					"day %d is not a checkpoint, so day 4's stands" % GameState.day)
	t.check(GameState.day == 8 and GameState.checkpoint_day() == 8, "day 8 replaces it")
	for d in [1, 4, 8, 12]:
		t.check(GameState.is_checkpoint_day(d) == (d > 1),
				"day %d is %s" % [d, "a stored checkpoint" if d > 1 else "checkpoint zero, never stored"])
	for d in Tuning.ACT_START_DAYS:
		t.check(GameState.is_checkpoint_day(d) or d == 1, "every act after the first starts on one")

## Before day 4, the last nerve goes back to day 1 of the same city — the same seed, and the same
## parent pushing the pram — rather than a new run.
func _test_checkpoint_zero_is_day_one_of_the_same_city(t) -> void:
	GameState.start_run(_SEED)
	GameState.player_is_male = not GameState.player_is_male
	var parent := GameState.player_is_male
	GameState.finish_day(GameEnums.DayResult.WON)
	GameState.finish_day(GameEnums.DayResult.WON)
	GameState.begin_day()
	GameState.complete_resistance_step(0)
	GameState.nerves = 1
	var events := []
	var listen := func(day: int, lost_day: int) -> void: events.append([day, lost_day])
	EventBus.went_back_to_a_checkpoint.connect(listen)
	t.check(GameState.finish_day(GameEnums.DayResult.LOST_CRYING), "the run goes on")
	EventBus.went_back_to_a_checkpoint.disconnect(listen)
	t.check(GameState.day == 1 and GameState.run_seed == _SEED, "day 1 of the same city")
	t.check(GameState.nerves == Tuning.STARTING_NERVES and GameState.resistance_progress == 0
			and GameState.completed_resistance_steps.is_empty(), "with every nerve and nothing done")
	t.check(GameState.player_is_male == parent, "pushed by the same parent")
	t.check(events == [[1, 3]], "and the counter hears checkpoint 1 from day 3 (%s)" % [events])

func _test_a_hard_run_keeps_no_checkpoint_and_ends_on_its_last_nerve(t) -> void:
	GameState.start_run(_SEED)
	GameState.choose_mode(true)
	GameState.day = 8
	GameState.begin_day()
	t.check(GameState.checkpoint.is_empty(), "a hard run keeps no checkpoint on day 8")
	GameState.nerves = 1
	t.check(not GameState.a_loss_goes_back_to_the_checkpoint(), "its last nerve does not go back")
	t.check(not GameState.finish_day(GameEnums.DayResult.LOST_TIMEOUT), "the run ends")
	t.check(GameState.ending == GameEnums.Ending.BAD and GameState.day == 8,
			"with the bad ending, on the day it was lost")
	GameState.ending = GameEnums.Ending.NONE

## A `--day 8` boot keeps day 8's dawn behind the title before the mode is chosen; choosing hard
## mode on that title drops it.
func _test_choosing_hard_mode_drops_a_checkpoint_already_kept(t) -> void:
	GameState.start_run(_SEED)
	GameState.day = 8
	GameState.begin_day()
	t.check(GameState.checkpoint_day() == 8, "a normal run keeps day 8")
	GameState.choose_mode(true)
	t.check(GameState.hard_mode and GameState.checkpoint.is_empty(), "hard mode has none")

# ------------------------------------------------------------------- the escape ---

## Hard mode's escape, driven through `main`'s own handlers against a real `FinaleController`, a real
## `DaySummary` and a real HUD, the rig `tests/test_finale.gd` uses for the briefs: a lost section
## costs a nerve and comes back on its brief with one fewer star, and the last one is the bad
## ending, with no continue, rather than the section again.
func _test_a_hard_runs_escape_spends_nerves_and_ends_on_the_last(t) -> void:
	DevFlags._invincible_override = false
	GameState.start_run(_SEED)
	GameState.choose_mode(true)
	GameState.day = Tuning.RUN_LENGTH_DAYS
	GameState.nerves = 2
	var main: Node2D = MAIN_SCRIPT.new()
	main._summary = SUMMARY_SCENE.instantiate()
	t.add_child(main._summary)
	main._hud = HUD_SCENE.instantiate()
	t.add_child(main._hud)
	var finale := FinaleController.new()
	t.add_child(finale)
	main._finale = finale
	finale.section_lost.connect(main._on_finale_section_lost)
	main._summary.continued.connect(main._on_finale_summary_continued)
	var briefs := [0]
	finale.section_started.connect(func(which: int, _restarted: bool) -> void:
		briefs[0] += 1
		main._show_the_finale_brief(which))

	finale.begin(FinaleController.Section.BUILDING)
	main._summary.continued.emit()
	EventBus.hard_fail_triggered.emit("abduction")
	t.check(GameState.nerves == 1 and briefs[0] == 2,
			"a lost section costs a hard run a nerve, and comes back on its brief")
	var body: Label = main._summary.get_node("Root/Center/Lines/Body")
	t.check(body.text.contains("Nerves left: %s" % NerveDisplay.stars(1)),
			"which shows the one star left ('%s')" % body.text)

	main._summary.continued.emit()
	EventBus.hard_fail_triggered.emit("abduction")
	t.check(GameState.nerves == 0 and briefs[0] == 2, "the last nerve does not start it again")
	t.check(GameState.ending == GameEnums.Ending.BAD and main._ending_shown,
			"it is the bad ending")
	var heading: Label = main._summary.get_node("Root/Center/Lines/Heading")
	t.check(heading.visible and heading.text == "GAME OVER", "on the GAME OVER screen")
	t.check(not main._summary._continue_column.visible, "which has no continue button")

	main._summary.free()
	main._hud.free()
	finale.free()
	main.free()
	t.get_tree().paused = false
	DevFlags._invincible_override = null
	GameState.ending = GameEnums.Ending.NONE

## *(gentle-osprey, the player: "Section won gives one back".)* Read from the source, since the
## handler builds the whole finale city on its next line: the regain is hard mode's alone, and it
## comes before `enter_city()`, whose brief shows and saves the count.
func _test_a_hard_run_gets_a_nerve_back_for_leaving_the_building(t) -> void:
	var text := FileAccess.get_file_as_string("res://src/main.gd")
	var handler := text.find("func _on_escape_exit_requested() -> void:")
	var next := text.find("\nfunc ", handler + 1)
	var body := text.substr(handler, next - handler)
	var regain := body.find("if GameState.hard_mode:\n\t\tGameState.regain_a_nerve()")
	var enter := body.find("_finale.enter_city()")
	t.check(handler != -1 and regain != -1 and enter != -1 and regain < enter,
			"leaving the building gives a hard run a nerve back before the city's brief")
	GameState.start_run(_SEED)
	GameState.nerves = Tuning.STARTING_NERVES
	GameState.regain_a_nerve()
	t.check(GameState.nerves == Tuning.STARTING_NERVES, "never past five")

# ---------------------------------------------------------------- the screens ---

## *(gentle-osprey: the lost-day screen says e.g. "Back to day 8" with five stars and keeps the
## ordinary continue button.)*
func _test_the_lost_day_screen_says_where_she_goes_back_to(t) -> void:
	GameState.start_run(_SEED)
	GameState.day = 8
	var summary: CanvasLayer = SUMMARY_SCENE.instantiate()
	t.add_child(summary)
	summary.show_day(GameEnums.DayResult.LOST_TIMEOUT, "Dusk came.", Tuning.STARTING_NERVES, 0.0,
			true)
	var body: Label = summary.get_node("Root/Center/Lines/Body")
	t.check(body.text.contains("Back to day 8"), "it names the day she goes back to ('%s')" % body.text)
	t.check(body.text.contains(NerveDisplay.stars(Tuning.STARTING_NERVES)), "with five stars")
	t.check(not body.text.contains("again"), "and not that she tries the day again")
	t.check(summary._continue_column.visible, "and the continue button stays")
	summary.free()
	t.get_tree().paused = false

func _test_the_checkbox_shows_only_for_a_new_game(t) -> void:
	GameState.start_run(_SEED)
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)
	title.open(false, true)
	t.check(title.hard_mode_shown() and not title.hard_mode_checked(),
			"a new game shows the box, unchecked")
	title.open(false, false)
	t.check(not title.hard_mode_shown() and not title.hard_mode_checked(),
			"a resumed game shows none")
	title._unhandled_input(_key(KEY_H))
	t.check(not title.hard_mode_checked(), "and H flips nothing that is not there")
	GameState.hard_mode = true
	title.open(false, true)
	t.check(title.hard_mode_checked(), "--hard opens it checked")
	GameState.hard_mode = false
	title.free()

## The box answers a touch, a click and `H`, and none of them starts the run; the three buttons
## still do.
func _test_a_press_on_the_checkbox_flips_it_and_never_starts_the_run(t) -> void:
	GameState.start_run(_SEED)
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)
	title.set("_touch", false)
	var started := [0]
	title.start_requested.connect(func(_mode: ControlsMode.Mode, _by_key: bool,
			_side: ControlsMode.Side) -> void: started[0] += 1)
	title.open(false, true)
	title._hard_mode.get_parent().notification(Container.NOTIFICATION_SORT_CHILDREN)
	var centre := title._hard_mode.get_global_rect().get_center()
	t.check(title._hard_mode.size.x > 0.0, "the box is laid out (%s)" % title._hard_mode.size)

	title._unhandled_input(_touch_at(centre))
	t.check(title.hard_mode_checked(), "a touch checks it")
	title._unhandled_input(_click_at(centre))
	t.check(not title.hard_mode_checked(), "a click unchecks it")
	title._unhandled_input(_key(KEY_H))
	t.check(title.hard_mode_checked(), "and H checks it again")
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	t.check(started[0] == 0, "none of which started the run")

	for button: ModeButton in [title._left_button, title._tap_button, title._right_button]:
		button.get_parent().notification(Container.NOTIFICATION_SORT_CHILDREN)
		t.check(not title.hard_mode_contains_design_point(button.get_global_rect().get_center()),
				"no button's disc is within the box's reach")
	title._unhandled_input(_touch_at(title._tap_button.get_global_rect().get_center()))
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	t.check(started[0] == 1 and title.hard_mode_checked(),
			"a button still starts the run, with the box as it was set")
	title.free()

## `main._on_title_start()` reads the box for a new game and nothing for a resumed one, and tells
## the counter the mode only for the new game. The rig is `tests/test_save.gd`'s bare gate `main`,
## with the real title scene in place of a bare `TitleScreen`, so the box is there to read.
func _test_the_title_sets_a_new_games_mode_and_leaves_a_resumed_ones(t) -> void:
	var main := _bare_gate_main(t)
	var modes := []
	var listen := func(hard: bool, day: int) -> void: modes.append([hard, day])
	EventBus.run_mode_chosen.connect(listen)

	GameState.start_run(_SEED)
	GameState.hard_mode = true
	main._resume = {"day_under_way": false}
	main._title.open(false, false)
	main._on_title_start(ControlsMode.Mode.TAP)
	t.check(GameState.hard_mode and modes.is_empty(),
			"a resumed run keeps the mode its save carries, and reports none")
	main._summary.dismiss()

	GameState.start_run(_SEED)
	main._resume = {}
	main._title.open(false, true)
	main._title._toggle_hard_mode()
	main._on_title_start(ControlsMode.Mode.TAP)
	t.check(GameState.hard_mode and modes == [[true, 1]],
			"a new game takes the box's answer and reports it with the day behind the title (%s)"
					% [modes])

	EventBus.run_mode_chosen.disconnect(listen)
	_free_gate_main(t, main)
	GameState.hard_mode = false

func _bare_gate_main(t) -> Node2D:
	var main: Node2D = MAIN_SCRIPT.new()
	main._add_touch_controls()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	var stroller := Stroller.new()
	stroller.add_child(camera)
	t.add_child(stroller)
	stroller.set_physics_process(false)
	main._player = stroller
	main._city = City.new()
	main._hud = CanvasLayer.new()
	main._edge_layer = CanvasLayer.new()
	main._status = Label.new()
	main._title = TITLE.instantiate()
	t.add_child(main._title)
	main._summary = SUMMARY_SCENE.instantiate()
	t.add_child(main._summary)
	return main

func _free_gate_main(t, main: Node2D) -> void:
	t.get_tree().paused = false
	var stroller: Node = main._player
	main._status.free()
	main._title.free()
	main._edge_layer.free()
	main._hud.free()
	main._city.free()
	main._summary.queue_free()
	main.free()
	stroller.free()

# ------------------------------------------------------------------- helpers ---

func _touch_at(position: Vector2) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = true
	return event

func _click_at(position: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	return event

func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event
