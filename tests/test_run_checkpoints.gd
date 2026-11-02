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
## The height of a phone held landscape, in points (an iPhone 15, 852x393).
const _PHONE_LANDSCAPE_HEIGHT_PT := 393.0
const MAIN_SCRIPT: GDScript = preload("res://src/main.gd")
const TITLE := preload("res://scenes/ui/title_screen.tscn")
const SUMMARY_SCENE := preload("res://scenes/ui/day_summary.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func run(t) -> void:
	var baseline := GameSave.file_data(GameState, false)
	GameSave.set_path_override(_SCRATCH_PATH)

	_test_going_back_restores_every_field_the_save_carries(t)
	_test_a_checkpoint_is_kept_only_the_first_time_its_day_is_begun(t)
	_test_checkpoint_zero_is_day_one_of_the_same_city(t)
	_test_the_play_time_only_grows_across_every_way_back(t)
	_test_going_back_across_day_11_boots_a_world_with_nothing_after_the_checkpoint(t)
	_test_a_hard_run_keeps_no_checkpoint_and_ends_on_its_last_nerve(t)
	_test_choosing_hard_mode_drops_a_checkpoint_already_kept(t)
	_test_a_hard_runs_escape_spends_nerves_and_ends_on_the_last(t)
	_test_leaving_the_building_gives_a_hard_run_no_nerve_back(t)
	_test_parse_nerves_accepts_one_to_five_and_refuses_the_rest(t)
	_test_the_lost_day_screen_says_where_she_goes_back_to(t)
	_test_the_checkbox_shows_only_for_a_new_game(t)
	_test_which_titles_show_the_checkbox_today(t)
	_test_a_press_on_the_checkbox_flips_it_and_never_starts_the_run(t)
	_test_a_real_tap_on_the_checkbox_reaches_it_on_a_phone_and_a_desktop(t)
	_test_no_control_on_the_title_stops_a_press(t)
	_test_the_title_sets_a_new_games_mode_and_leaves_a_resumed_ones(t)

	GameSave._clear_now()
	GameSave.set_path_override("")
	GameState.run_parts.restore_run_data(baseline)
	GameState.calendar.hard_mode = bool(baseline["hard_mode"])
	GameState.calendar.checkpoint = baseline["checkpoint"]

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
		GameState.calendar.begin_day()
		GameState.calendar.remember_where_she_settled(Vector2i(d, d))
		GameState.calendar.finish_day(GameEnums.DayResult.WON)
	t.check(GameState.header.day == 4, "three won days reach day 4")
	GameState.header.nerves = 3
	GameState.calendar.begin_day()
	var expected := GameState.run_parts.run_data()
	t.check(GameState.calendar.checkpoint == expected, "beginning day 4 keeps its dawn as the checkpoint")

	# On past it: a lost attempt at day 4, a won one, and into day 5.
	GameState.add_scar("after_the_checkpoint", Vector2(40.0, 40.0))
	GameState.calendar.finish_day(GameEnums.DayResult.LOST_CRYING)
	GameState.calendar.begin_day()
	GameState.calendar.finish_day(GameEnums.DayResult.WON)
	GameState.calendar.begin_day()
	t.check(GameState.header.day == 5 and GameState.calendar.checkpoint == expected,
			"day 5 is under way and the checkpoint is still day 4's dawn")

	# Through the file, so the checkpoint given back is the one a closed game would come back to.
	t.check(GameSave._write_now(GameState, true), "the run is written with its checkpoint")
	GameState.start_run(_SEED + 1)
	t.check(not GameSave._read_now(GameState).is_empty(), "and read back")
	t.check(GameState.calendar.checkpoint_day() == 4, "with its checkpoint on day 4")

	var keys := _run_keys()
	t.check(keys.size() > 10, "there are fields to check (%d)" % keys.size())
	var before := _flatten(GameSave.file_data(GameState, false))
	_change_everything()
	var changed := _flatten(GameSave.file_data(GameState, false))
	for key in keys:
		t.check(changed[key] != before[key] and changed[key] != _flatten_run(expected)[key],
				"'%s' is changed after the checkpoint — a field this test does not change cannot "
						% key + "show that going back gives it back; change it in _change_everything()")

	GameState.header.nerves = 1
	t.check(GameState.calendar.a_loss_goes_back_to_the_checkpoint(), "losing now spends a normal run's last nerve")
	t.check(GameState.calendar.finish_day(GameEnums.DayResult.LOST_HARD_FAIL), "and the run goes on")
	var after := _flatten(GameSave.file_data(GameState, false))
	var wanted := _flatten_run(expected)
	wanted["state.nerves"] = Tuning.STARTING_NERVES
	# The one field going back does not give back: the time played only grows (inbox #920 in plaid-penguin).
	wanted["state.play_seconds"] = changed["state.play_seconds"]
	for key in keys:
		t.check(after[key] == wanted[key],
				"'%s' is the checkpoint's own dawn again (%s, wanted %s)"
						% [key, str(after[key]).left(80), str(wanted[key]).left(80)])
	t.check(GameState.header.nerves == Tuning.STARTING_NERVES and GameState.header.day == 4,
			"back at day 4 with every nerve")
	t.check(GameState.calendar.checkpoint_day() == 4 and not GameState.calendar.hard_mode,
			"still a normal run, whose checkpoint is still day 4")
	t.check(GameState.header.ending == GameEnums.Ending.NONE, "and a normal run has no bad ending")

## Every key of the file that is the run's own state — top-level riders by name, and `"state"`'s
## fields as `state.<name>` — read off `GameSave.file_data()` itself.
func _run_keys() -> Array[String]:
	var keys: Array[String] = []
	for key: String in _flatten(GameSave.file_data(GameState, false)):
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
	GameState.header.run_seed += 1
	GameState.header.player_is_male = not GameState.header.player_is_male
	GameState.header.day = 10
	GameState.header.nerves = 2
	GameState.resistance.progress += 3
	GameState.header.ending = GameEnums.Ending.NEUTRAL
	GameState.header.play_ticks += 15000
	GameState.attempt_spend.consumed_one_shots.append("spent_after_the_checkpoint")
	GameState.resistance.completed_steps.append(99)
	GameState.resistance.failed_steps.append(98)
	GameState.add_scar("scarred_after_the_checkpoint", Vector2(120.0, 80.0))
	GameState.attempt_spend.city_state.apply_cause({Vector2i(30, 30): _fake_block_plan()}, Vector2i(30, 30),
			GameEnums.BlockCause.FIRE, 10)
	GameState.resistance.sabotage_done = not GameState.resistance.sabotage_done
	GameState.resistance.carrying_package = not GameState.resistance.carrying_package
	GameState.resistance._dawn_completed_steps.append(97)
	GameState.resistance._dawn_failed_steps.append(96)
	GameState.resistance._dawn_progress += 2
	GameState.resistance._dawn_sabotage_done = not GameState.resistance._dawn_sabotage_done
	GameState.resistance._dawn_carrying_package = not GameState.resistance._dawn_carrying_package
	GameState.settled.settled_in[10] = Vector2i(5, 5)
	GameState.attempt_spend._dawn_consumed_one_shots.append("photographed_after_the_checkpoint")
	GameState.attempt_spend._dawn_scars.append({"id": "dawn_after", "position": Vector2(9.0, 9.0), "since_day": 9})
	GameState.attempt_spend._dawn_city_state = {"stage": [{"x": 41, "y": 41, "v": 1}]}
	GameState.facts.escape_section = DaySpec.Section.CITY
	GameState.facts.completed_resistance_alley_tiles.append(Vector2i(77, 77))
	GameState.facts.fenced_park = Vector2i(3, 3)
	GameState.facts.fenced_park_act = 3
	GameState.posters.paste(Vector2i(9, 9), 0, false, 1)
	GameState.posters.tears += 1
	GameState.posters.pasted_through += 4
	GameState.posters.photograph()
	GameState.pelican.draws += 5
	GameState.pelican.photograph()

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
	t.check(GameState.calendar.checkpoint_day() == 1, "a fresh run's checkpoint is day 1")
	GameState.header.day = 4
	GameState.calendar.begin_day()
	var day_four := GameState.calendar.checkpoint.duplicate(true)
	t.check(GameState.calendar.checkpoint_day() == 4, "day 4 is a checkpoint")
	GameState.header.play_ticks = 2310
	GameState.calendar.finish_day(GameEnums.DayResult.LOST_TIMEOUT)
	GameState.calendar.begin_day()
	t.check(GameState.calendar.checkpoint == day_four, "a retry of day 4 does not replace its dawn")
	for d in range(4, 8):
		GameState.calendar.finish_day(GameEnums.DayResult.WON)
		GameState.calendar.begin_day()
		if GameState.header.day < 8:
			t.check(GameState.calendar.checkpoint == day_four,
					"day %d is not a checkpoint, so day 4's stands" % GameState.header.day)
	t.check(GameState.header.day == 8 and GameState.calendar.checkpoint_day() == 8, "day 8 replaces it")
	for d in [1, 4, 8, 12]:
		t.check(RunCalendar.is_checkpoint_day(d) == (d > 1),
				"day %d is %s" % [d, "a stored checkpoint" if d > 1 else "checkpoint zero, never stored"])
	for d in Tuning.ACT_START_DAYS:
		t.check(RunCalendar.is_checkpoint_day(d) or d == 1, "every act after the first starts on one")

## Before day 4, the last nerve goes back to day 1 of the same city — the same seed, and the same
## parent pushing the pram — rather than a new run.
func _test_checkpoint_zero_is_day_one_of_the_same_city(t) -> void:
	GameState.start_run(_SEED)
	GameState.header.player_is_male = not GameState.header.player_is_male
	var parent := GameState.header.player_is_male
	GameState.calendar.finish_day(GameEnums.DayResult.WON)
	GameState.calendar.finish_day(GameEnums.DayResult.WON)
	GameState.calendar.begin_day()
	GameState.complete_resistance_step(0)
	GameState.header.nerves = 1
	var events := []
	var listen := func(day: int, lost_day: int) -> void: events.append([day, lost_day])
	EventBus.went_back_to_a_checkpoint.connect(listen)
	t.check(GameState.calendar.finish_day(GameEnums.DayResult.LOST_CRYING), "the run goes on")
	EventBus.went_back_to_a_checkpoint.disconnect(listen)
	t.check(GameState.header.day == 1 and GameState.header.run_seed == _SEED, "day 1 of the same city")
	t.check(GameState.header.nerves == Tuning.STARTING_NERVES and GameState.resistance.progress == 0
			and GameState.resistance.completed_steps.is_empty(), "with every nerve and nothing done")
	t.check(GameState.header.player_is_male == parent, "pushed by the same parent")
	t.check(events == [[1, 3]], "and the counter hears checkpoint 1 from day 3 (%s)" % [events])

## **The run's play time only ever grows** (inbox #920 in plaid-penguin): going back to checkpoint zero, going back
## to a later checkpoint, retrying a lost day and a save continued after a go-back each leave the
## time exactly as it was, and a new game from the title is the one thing that starts it at zero.
## The go-back paths to checkpoint zero and to a later checkpoint fail on the code before the fix
## (zero reset it, a later one took the dawn's); the retry and the save passed before and pin it.
func _test_the_play_time_only_grows_across_every_way_back(t) -> void:
	# Back to checkpoint zero, from day 3.
	GameState.start_run(_SEED)
	GameState.calendar.finish_day(GameEnums.DayResult.WON)
	GameState.calendar.finish_day(GameEnums.DayResult.WON)
	GameState.calendar.begin_day()
	GameState.header.play_ticks = 4321
	GameState.header.nerves = 1
	GameState.calendar.finish_day(GameEnums.DayResult.LOST_CRYING)
	t.check(GameState.header.day == 1 and GameState.header.play_ticks == 4321,
			"back to checkpoint zero keeps the play time (%d)" % GameState.header.play_ticks)

	# Back to a later checkpoint: the dawn of day 4 held less time than the loss on day 5.
	GameState.start_run(_SEED)
	GameState.header.day = 4
	GameState.header.play_ticks = 1000
	GameState.calendar.begin_day()
	GameState.calendar.finish_day(GameEnums.DayResult.WON)
	GameState.calendar.begin_day()
	GameState.header.play_ticks = 7777
	GameState.header.nerves = 1
	GameState.calendar.finish_day(GameEnums.DayResult.LOST_CRYING)
	t.check(GameState.header.day == 4 and GameState.calendar.checkpoint_day() == 4
			and GameState.header.play_ticks == 7777,
			"back to a later checkpoint keeps the play time, not the dawn's (%d)" % GameState.header.play_ticks)

	# A lost day retried with nerves left: no go-back, the header is not given back.
	GameState.header.nerves = 3
	GameState.header.play_ticks = 8000
	GameState.calendar.finish_day(GameEnums.DayResult.LOST_TIMEOUT)
	GameState.calendar.begin_day()
	t.check(GameState.header.play_ticks == 8000, "a lost day's retry keeps the play time")

	# A save continued after a go-back holds the time the go-back kept.
	GameState.header.nerves = 1
	GameState.calendar.finish_day(GameEnums.DayResult.LOST_CRYING)
	var kept := GameState.header.play_ticks
	t.check(GameSave._write_now(GameState, true), "the run is written after the go-back")
	GameState.start_run(_SEED + 1)
	t.check(GameState.header.play_ticks == 0, "a new game starts at zero")
	GameSave._read_now(GameState)
	t.check(kept == 8000 and GameState.header.play_ticks == 8000,
			"a save continued after a go-back keeps the play time (%d)" % GameState.header.play_ticks)

## **Going back is a boot, not a repaint.** Day 11 boards the neighbor's window on her own building
## for the rest of the run (`City.board_neighbor_window()`), which nothing in a dawn takes down; a
## run that loses its last nerve on day 11 and goes back to day 8 must not see it boarded, since
## nothing after the checkpoint happened. Played through the real `main.tscn`: into day 8 (its
## checkpoint) and on to day 11 on the same world, the last nerve lost there, and the lost-day
## screen's continue. The world she then plays day 8 in — the next boot if the continue reloaded,
## this one if it did not — has the window unboarded, and the run's checkpoint restart was counted
## once and not followed by a second `run_begun`.
func _test_going_back_across_day_11_boots_a_world_with_nothing_after_the_checkpoint(t) -> void:
	var main: Node2D = MAIN_SCENE.instantiate()
	t.add_child(main)
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	# A joystick, steered from the right: what the title answered has to hold for the sitting, and
	# the boot going back opens no title to ask again.
	main._on_title_start(ControlsMode.Mode.JOYSTICK, false, ControlsMode.Side.RIGHT)
	GameState.header.day = 8
	main._start_day()
	for d in range(8, 11):
		GameState.calendar.finish_day(GameEnums.DayResult.WON)
		main._start_day()
	t.check(GameState.header.day == 11 and GameState.calendar.checkpoint_day() == 8,
			"day 11 is under way, with day 8 the checkpoint")
	var boarded: Building = main._city._home_door_building()
	t.check(boarded != null and boarded.neighbor_window_col >= 0,
			"day 11 boarded the neighbor's window")

	var back := []
	var begun := []
	var on_back := func(day: int, lost_day: int) -> void: back.append([day, lost_day])
	var on_begun := func(day: int, resumed: bool) -> void: begun.append([day, resumed])
	EventBus.went_back_to_a_checkpoint.connect(on_back)
	EventBus.run_begun.connect(on_begun)
	var reloads := []
	main._reload_override = func() -> void: reloads.append(1)
	GameState.header.nerves = 1
	main._on_day_finished(GameEnums.DayResult.LOST_TIMEOUT)
	t.check(GameState.header.day == 8 and main._summary.is_showing(), "the lost-day screen is up, at day 8")
	main._on_summary_continued(main._flow.mode)

	var playing := main
	if reloads.size() == 1:
		t.get_tree().paused = false
		main.free()
		playing = MAIN_SCENE.instantiate()
		t.add_child(playing)
		t.get_tree().process_frame.emit()
		t.get_tree().process_frame.emit()
	t.check(reloads.size() == 1, "the continue reloads the scene rather than repainting this one")
	t.check(GameState.header.day == 8 and GameState.header.nerves == Tuning.STARTING_NERVES,
			"she plays day 8 with every nerve")
	var building: Building = playing._city._home_door_building()
	t.check(building != null and building.neighbor_window_col < 0,
			"and the neighbor's window is not boarded on day 8")
	t.check(not playing._title.is_open() and not t.get_tree().paused,
			"straight into the day, with no title in front of it")
	t.check(playing._touch_controls._mode == ControlsMode.Mode.JOYSTICK
			and playing._touch_controls._steering_focus == TouchControls.FOCUS_RIGHT,
			"with the joystick the title chose, steered from the right, as before")
	t.check(GameState.calendar.hard_mode == false, "in the mode the title chose")
	t.check(back == [[8, 11]], "the checkpoint restart was counted once (%s)" % [back])
	t.check(begun.is_empty(), "and the reload begins no new run (%s)" % [begun])
	EventBus.went_back_to_a_checkpoint.disconnect(on_back)
	EventBus.run_begun.disconnect(on_begun)
	t.get_tree().paused = false
	Telemetry.end_run()
	playing.free()

func _test_a_hard_run_keeps_no_checkpoint_and_ends_on_its_last_nerve(t) -> void:
	GameState.start_run(_SEED)
	GameState.calendar.choose_mode(true)
	GameState.header.day = 8
	GameState.calendar.begin_day()
	t.check(GameState.calendar.checkpoint.is_empty(), "a hard run keeps no checkpoint on day 8")
	GameState.header.nerves = 1
	t.check(not GameState.calendar.a_loss_goes_back_to_the_checkpoint(), "its last nerve does not go back")
	t.check(not GameState.calendar.finish_day(GameEnums.DayResult.LOST_TIMEOUT), "the run ends")
	t.check(GameState.header.ending == GameEnums.Ending.BAD and GameState.header.day == 8,
			"with the bad ending, on the day it was lost")
	GameState.header.ending = GameEnums.Ending.NONE

## A `--day 8` boot keeps day 8's dawn behind the title before the mode is chosen; choosing hard
## mode on that title drops it.
func _test_choosing_hard_mode_drops_a_checkpoint_already_kept(t) -> void:
	GameState.start_run(_SEED)
	GameState.header.day = 8
	GameState.calendar.begin_day()
	t.check(GameState.calendar.checkpoint_day() == 8, "a normal run keeps day 8")
	GameState.calendar.choose_mode(true)
	t.check(GameState.calendar.hard_mode and GameState.calendar.checkpoint.is_empty(), "hard mode has none")

# ------------------------------------------------------------------- the escape ---

## Hard mode's escape, driven through `main`'s own finish path (`_on_day_finished()`, the one every
## day ends through) against a real `DayController`, a real `DaySummary` and a real HUD: a lost
## section costs a nerve and comes up on the day's outcome screen with one fewer star and the
## section's own words, and the last one is the bad ending, with no continue, rather than the
## section again — shown after the outcome screen, as a lost day's is.
func _test_a_hard_runs_escape_spends_nerves_and_ends_on_the_last(t) -> void:
	GameState.start_run(_SEED)
	GameState.calendar.choose_mode(true)
	GameState.header.day = Tuning.RUN_LENGTH_DAYS
	GameState.header.nerves = 2
	var main: Node2D = MAIN_SCRIPT.new()
	main._summary = SUMMARY_SCENE.instantiate()
	t.add_child(main._summary)
	main._hud = HUD_SCENE.instantiate()
	main._hud.use_run(main._run)
	t.add_child(main._hud)
	var day := DayController.new()
	t.add_child(day)
	day.set_process(false)
	main._day = day
	main._flow.opening = RunFlow.Opening.ESCAPE_HANDED_OVER
	main._use_the_day(MAIN_SCRIPT.escape_section_spec(DaySpec.Section.BUILDING, 180.0))
	day.start(180.0)
	EventBus.hard_fail_triggered.emit("abduction")
	main._on_day_finished(GameEnums.DayResult.LOST_HARD_FAIL)
	t.check(GameState.header.nerves == 1 and main._summary.is_showing()
			and main._flow.mode == RunFlow.Mode.SECTION_LOST,
			"a lost section costs a hard run a nerve, and comes up on the day's outcome screen")
	var body: Label = main._summary.get_node("Root/Center/Lines/Body")
	t.check(body.text.contains("Nerves left: %s" % Texts.nerve_stars(1))
			and body.text.contains("Escape the building"),
			"which shows the one star left under the section's own words ('%s')" % body.text)

	day.start(180.0)
	EventBus.hard_fail_triggered.emit("abduction")
	main._on_day_finished(GameEnums.DayResult.LOST_HARD_FAIL)
	t.check(GameState.header.nerves == 0 and main._flow.mode == RunFlow.Mode.RUN_OVER,
			"the last nerve does not start it again")
	main._on_summary_continued(main._flow.mode)
	t.check(GameState.header.ending == GameEnums.Ending.BAD and main._flow.mode == RunFlow.Mode.ENDING,
			"it is the bad ending")
	var heading: Label = main._summary.get_node("Root/Center/Lines/Heading")
	t.check(heading.visible and heading.text == "GAME OVER", "on the GAME OVER screen")
	t.check(not main._summary._continue_column.visible, "which has no continue button")

	main._summary.free()
	main._hud.free()
	day.free()
	main.free()
	t.get_tree().paused = false
	GameState.header.ending = GameEnums.Ending.NONE
	GameState.facts.escape_section = DaySpec.Section.NONE

## *(dotted-hawk, the player, #718: "No regain in escape either.")* A hard run handed over to the
## escape boots the real `main.tscn` on the building, and the service door's own `exit_requested`
## — the signal the building emits when she walks out of it — brings the city's brief up with the
## nerves it had, none given back.
func _test_leaving_the_building_gives_a_hard_run_no_nerve_back(t) -> void:
	GameState.start_run(_SEED)
	GameState.calendar.choose_mode(true)
	GameState.header.day = Tuning.RUN_LENGTH_DAYS
	GameState.header.nerves = 3
	GameState.facts.escape_section = DaySpec.Section.BUILDING
	var main: Node2D = MAIN_SCENE.instantiate()
	t.add_child(main)
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	t.check(main._interior != null and main._summary.is_showing(),
			"the boot stands in the building on its brief")
	t.check(main._interior.exit_requested.is_connected(main._day.reach_the_exit),
			"the service door is wired to the day's own goal")
	main._on_summary_continued(main._flow.mode)
	main._interior.exit_requested.emit()
	t.check(GameState.header.nerves == 3, "leaving the building gives the hard run no nerve back")
	var body: Label = main._summary.get_node("Root/Center/Lines/Body")
	t.check(main._summary.is_showing() and body.text.contains(Texts.nerve_stars(3)),
			"and the city's brief shows the same count ('%s')" % body.text)
	t.get_tree().paused = false
	Telemetry.end_run()
	main.free()
	GameState.facts.escape_section = DaySpec.Section.NONE
	GameState.calendar.hard_mode = false

## `--nerves N`'s own parsing: a whole number from 1 to five, anything else refused as not given.
func _test_parse_nerves_accepts_one_to_five_and_refuses_the_rest(t) -> void:
	t.check(DevFlags.parse_nerves("1") == 1, "'1' is one nerve")
	t.check(DevFlags.parse_nerves("5") == 5, "'5' is five")
	for raw: String in ["0", "6", "x", "", "2.5", "-1"]:
		t.check(DevFlags.parse_nerves(raw) == 0, "'%s' is refused as not given" % raw)

# ---------------------------------------------------------------- the screens ---

## *(gentle-osprey: the lost-day screen says e.g. "Back to day 8" with five stars and keeps the
## ordinary continue button.)*
func _test_the_lost_day_screen_says_where_she_goes_back_to(t) -> void:
	GameState.start_run(_SEED)
	GameState.header.day = 8
	var summary: CanvasLayer = SUMMARY_SCENE.instantiate()
	t.add_child(summary)
	var end := DayEnd.new()
	end.result = GameEnums.DayResult.LOST_TIMEOUT
	end.reason = "Dusk came."
	end.goes_back = true
	summary.show_summary(SummaryModel.day_over(GameState, end), RunFlow.Mode.BACK_TO_CHECKPOINT)
	var body: Label = summary.get_node("Root/Center/Lines/Body")
	t.check(body.text.contains("Back to day 8"), "it names the day she goes back to ('%s')" % body.text)
	t.check(body.text.contains(Texts.nerve_stars(Tuning.STARTING_NERVES)), "with five stars")
	t.check(not body.text.contains("again"), "and not that she tries the day again")
	t.check(summary._continue_column.visible, "and the continue button stays")
	summary.free()
	t.get_tree().paused = false

func _test_the_checkbox_shows_only_for_a_new_game(t) -> void:
	GameState.start_run(_SEED)
	var title: TitleScreen = TITLE.instantiate()
	title.use_run(GameState)
	t.add_child(title)
	title.open(false, true)
	t.check(title.hard_mode_shown() and not title.hard_mode_checked(),
			"a new game shows the box, unchecked")
	title.open(false, false)
	t.check(not title.hard_mode_shown() and not title.hard_mode_checked(),
			"a resumed game shows none")
	title._unhandled_input(_key(KEY_H))
	t.check(not title.hard_mode_checked(), "and H flips nothing that is not there")
	GameState.calendar.hard_mode = true
	title.open(false, true)
	t.check(title.hard_mode_checked(), "--hard opens it checked")
	GameState.calendar.hard_mode = false
	title.free()

## **Which titles a player can meet show the box today, pinned as it stands, not as settled.**
## *(inbox #746 in woolly-penguin, the player: "I don't see the hard mode button at all locally".)* The title opens
## through `main._open_the_title()`, which passes `new_game` as `_resume.is_empty()`: whether the boot
## found a saved run to resume. A run is saved from its first day on, so every boot after a first
## one, until that run ends or the held restart throws it away, opens on a title with no box. Whether
## the box belongs on that title is open (plaid-goose's report); this pins what each title does now,
## so a change to it is a decision someone made rather than a side effect.
##
## - A boot with nothing to resume (a first visit, after an ending, after the held restart): shown,
##   whether or not an ending was shown in this scene first (`RunFlow.Mode.ENDING`, `open()`'s `again`).
## - A boot that resumed a saved run, its day under way or not: none.
## - The escape's resume gate (`open(false)`) and the `--start-escape` epilogue (`open(true)`): none.
func _test_which_titles_show_the_checkbox_today(t) -> void:
	var main := _bare_gate_main(t)
	# `_open_the_title()` turns every layer through `_apply_orientation()`, which reaches
	# `_hud.set_rotated()`: the bare layer the gate rig carries has no such method.
	main._hud.free()
	var hud: CanvasLayer = HUD_SCENE.instantiate()
	hud.use_run(GameState)
	t.add_child(hud)
	hud.set_process(false)
	main._hud = hud
	main._status_layer = CanvasLayer.new()
	GameState.start_run(_SEED)
	var cases := [
		[{}, false, true, "a boot with nothing to resume"],
		[{}, true, true, "the same, after an ending in this scene"],
		[{"day_under_way": false}, false, false, "a boot that resumed a saved run between days"],
		[{"day_under_way": true}, false, false, "a boot that resumed a run in the middle of a day"],
	]
	for case: Array in cases:
		main._resume = case[0]
		main._flow.mode = RunFlow.Mode.ENDING if case[1] else RunFlow.Mode.BOOTING
		main._open_the_title()
		t.check(main._title.hard_mode_shown() == case[2],
				"%s: the box is %s" % [case[3], "shown" if case[2] else "not shown"])
		# Where the box is not shown a resumed run's mode is decided, so its name stands there.
		t.check(main._title.mode_name_shown() == ("" if case[2] else "Normal"),
				"%s: the mode's name is %s" % [case[3], "not shown" if case[2] else "shown"])
		main._title.close()
	main._title.open(false, false, true)
	t.check(not main._title.hard_mode_shown(), "the escape's resume gate shows no box")
	t.check(main._title.mode_name_shown() == "Normal", "but names the mode")
	main._title.open(true)
	t.check(not main._title.hard_mode_shown() and main._title.mode_name_shown() == "",
			"nor does the --start-escape epilogue show a box or a name")
	main._title.close()
	main._resume = {}
	main._status_layer.free()
	_free_gate_main(t, main)

## The box answers a touch, a click and `H`, and none of them starts the run; the three buttons
## still do.
func _test_a_press_on_the_checkbox_flips_it_and_never_starts_the_run(t) -> void:
	GameState.start_run(_SEED)
	var title: TitleScreen = TITLE.instantiate()
	title.use_run(GameState)
	t.add_child(title)
	title.set("_touch", false)
	var started := [0]
	title.start_requested.connect(func(_mode: ControlsMode.Mode, _by_key: bool,
			_side: ControlsMode.Side) -> void: started[0] += 1)
	title.open(false, true)
	var centre := title.hard_mode_target().get_center()
	t.check(title._hard_mode.size.x > 0.0, "the box is laid out (%s)" % title._hard_mode.size)
	# A phone held landscape is about 393pt tall and shows the 720-px-tall design box scaled to fit;
	# a finger wants 44pt each way.
	var on_a_phone := title.hard_mode_target().size * (_PHONE_LANDSCAPE_HEIGHT_PT / 720.0)
	t.check(on_a_phone.x >= 44.0 and on_a_phone.y >= 44.0,
			"the box is a 44pt target on a phone held landscape (%s pt)" % on_a_phone)

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

## **A real tap on the box flips it, through the engine's own input dispatch.** *(fluffy-kestrel,
## the player, #740: "Hard mode should have the same 5% extension over the box and text as other
## buttons", titled "Cannot select hard mode"; inbox #746 in woolly-penguin: "all of this was on phone.")* The test
## above hands its events straight to `_unhandled_input()`, which skips the step that stopped them:
## Godot's GUI pass, which runs first and offers a press to the topmost `Control` under it that does
## not ignore the mouse. Under the box that was the bottom scrim, a `ColorRect` left at Godot's
## default `MOUSE_FILTER_STOP`, so every touch and click on the box was used up there and never
## reached the title's own handler; the three buttons worked because their columns are containers,
## which pass a press on. So this drives `Input.parse_input_event()` + `flush_buffered_events()`, as
## `tests/test_held_restart.gd` does, which runs the GUI pass and the engine's
## emulate-mouse-from-touch pass both: a phone (`_touch`, its finger arriving as a screen touch and
## an emulated click) held landscape, held portrait (the title turned, the touch arriving in the
## 720x1280 box) and a desktop's mouse, each at the drawn box's centre, on its label, in the space
## between the two, at a corner of the drawn rect and just inside two corners of its catch: *"the
## whole bounding box should trigger"* (inbox #746 in woolly-penguin). Each tap must flip the box exactly once. The
## window is sized to the device for the span, since real dispatch maps a window position through
## the stretch.
func _test_a_real_tap_on_the_checkbox_reaches_it_on_a_phone_and_a_desktop(t) -> void:
	GameState.start_run(_SEED)
	var original_window_size: Vector2i = t.get_window().size
	# [the window, whether it is a touch device, the name of the case]
	var devices := [
		[Vector2i(852, 393), true, "a phone held landscape"],
		[Vector2i(393, 852), true, "a phone held portrait"],
		[Vector2i(ScreenOrientation.DESIGN_SIZE), false, "a desktop's mouse"],
	]
	for device: Array in devices:
		var window: Vector2i = device[0]
		var touch: bool = device[1]
		var rotate := ScreenOrientation.wants_rotation(Vector2(window), touch)
		t.get_window().size = window
		t.get_window().content_scale_size = ScreenOrientation.content_scale_size(rotate)
		var title: TitleScreen = TITLE.instantiate()
		title.use_run(GameState)
		t.add_child(title)
		title._touch = touch
		ScreenOrientation.apply_to_layer(title, rotate)
		var started := [0]
		title.start_requested.connect(func(_mode: ControlsMode.Mode, _by_key: bool,
				_side: ControlsMode.Side) -> void: started[0] += 1)
		title.open(false, true)
		var drawn := title._hard_mode.get_global_transform() \
				* Rect2(Vector2.ZERO, title._hard_mode.size)
		var box := title._hard_mode_frame.get_global_transform() \
				* Rect2(Vector2.ZERO, title._hard_mode_frame.size)
		var catch := title.hard_mode_target()
		t.check(catch.encloses(ButtonGeometry.margin_rect(drawn))
				and catch.encloses(drawn.grow(TitleScreen._HARD_MODE_REACH)),
				"%s: the catch %s holds the box and label grown by 5%% and by the old reach"
						% [device[2], catch])
		var inset := Vector2.ONE
		var points := {
			"the box's centre": box.get_center(),
			"its label": Vector2(drawn.end.x - drawn.size.x * 0.25, drawn.get_center().y),
			"the space between the box and its label": Vector2(box.end.x + 1.0, box.get_center().y),
			"the drawn rect's top-right corner": Vector2(drawn.end.x - 1.0, drawn.position.y + 1.0),
			"just inside its catch's top-left": catch.position + inset,
			"just inside its catch's bottom-right": catch.end - inset,
		}
		for where: String in points:
			var was := title.hard_mode_checked()
			var at: Vector2 = points[where]
			_tap_through_the_engine(t, ScreenOrientation.to_presented_space(at, rotate), touch)
			t.check(title.hard_mode_checked() != was,
					"%s: a tap on %s %s flips the box" % [device[2], where, at])
		t.get_tree().process_frame.emit()
		t.get_tree().process_frame.emit()
		t.check(started[0] == 0, "%s: and none of those taps started the run" % device[2])
		# The same scrim covered the strip of each button's catch above its column, the part of the
		# square grown by a third of the radius that lies outside the container.
		title._tap_button.get_parent().notification(Container.NOTIFICATION_SORT_CHILDREN)
		var button := title._tap_button.get_global_rect()
		var above := Vector2(button.get_center().x, button.position.y - ModeButton.RADIUS / 3.0 + 1.0)
		t.check(title._tap_button.contains_design_point(above),
				"%s: %s is inside the tap button's catch" % [device[2], above])
		_tap_through_the_engine(t, ScreenOrientation.to_presented_space(above, rotate), touch)
		t.get_tree().process_frame.emit()
		t.get_tree().process_frame.emit()
		t.check(started[0] == 1,
				"%s: and a tap there, above its column, starts the run" % device[2])
		title.free()
	t.get_window().content_scale_size = Vector2i(ScreenOrientation.DESIGN_SIZE)
	t.get_window().size = original_window_size
	t.get_tree().paused = false

## **Nothing on the title uses a press up before the title's own handler reads it.** Every press on
## this screen is read off its raw position in `TitleScreen._unhandled_input()`, and Godot's GUI pass
## runs before that phase and ends a press at the first `Control` under it set to
## `MOUSE_FILTER_STOP`, Godot's default for a bare `Control` or `ColorRect`. So a node added later
## that keeps the default would silently swallow every press over it, as the bottom scrim once did
## over the Hard Mode box; this names it. A container's default, `MOUSE_FILTER_PASS`, hands the press
## on and is fine.
func _test_no_control_on_the_title_stops_a_press(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	title.use_run(GameState)
	t.add_child(title)
	title.open(false, true)
	var stopping: Array[String] = []
	var pending: Array[Node] = [title]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		pending.append_array(node.get_children())
		if node is Control and (node as Control).mouse_filter == Control.MOUSE_FILTER_STOP:
			stopping.append(str(title.get_path_to(node)))
	t.check(stopping.is_empty(), "no Control on the title stops a press (%s)" % [stopping])
	title.free()

## A tap at `presented`, a point in the viewport's own (stretched, possibly rotated) box, sent as a
## real device sends it: from a phone a screen touch, which the engine also turns into an emulated
## click; from a desktop a left click. Press and release, so no touch is left held for the next.
func _tap_through_the_engine(t, presented: Vector2, touch: bool) -> void:
	var on_the_window: Vector2 = t.get_viewport().get_final_transform() * presented
	for pressed: bool in [true, false]:
		var event: InputEvent
		if touch:
			var finger := InputEventScreenTouch.new()
			finger.index = 0
			finger.position = on_the_window
			finger.pressed = pressed
			event = finger
		else:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.position = on_the_window
			click.global_position = on_the_window
			click.pressed = pressed
			event = click
		Input.parse_input_event(event)
		Input.flush_buffered_events()

## `main._on_title_start()` reads the box for a new game and nothing for a resumed one, and tells
## the counter the mode only for the new game. The rig is `tests/test_save.gd`'s bare gate `main`,
## with the real title scene in place of a bare `TitleScreen`, so the box is there to read.
func _test_the_title_sets_a_new_games_mode_and_leaves_a_resumed_ones(t) -> void:
	var main := _bare_gate_main(t)
	var modes := []
	var listen := func(hard: bool, day: int) -> void: modes.append([hard, day])
	EventBus.run_mode_chosen.connect(listen)

	GameState.start_run(_SEED)
	GameState.calendar.hard_mode = true
	main._resume = {"day_under_way": false}
	main._title.open(false, false)
	main._on_title_start(ControlsMode.Mode.TAP)
	t.check(GameState.calendar.hard_mode and modes.is_empty(),
			"a resumed run keeps the mode its save carries, and reports none")
	main._summary.dismiss()

	GameState.start_run(_SEED)
	main._resume = {}
	main._title.open(false, true)
	main._title._toggle_hard_mode()
	main._on_title_start(ControlsMode.Mode.TAP)
	t.check(GameState.calendar.hard_mode and modes == [[true, 1]],
			"a new game takes the box's answer and reports it with the day behind the title (%s)"
					% [modes])

	EventBus.run_mode_chosen.disconnect(listen)
	_free_gate_main(t, main)
	GameState.calendar.hard_mode = false

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
	main._title.use_run(main._run)
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
