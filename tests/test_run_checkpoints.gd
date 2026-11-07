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
## **Every test plays a run of its own**, a fresh `RunState` it makes: the calendar's
## tests drive that run's own calls, the screens are handed it (`use_run()`), and a test that boots
## the real `scenes/main.tscn` hands the boot a home with a sitting parked in it that holds the run
## (`tests/booted_main.gd`'s `home_playing()`), so the game plays it. Booted games are driven the
## way a player and the engine drive them: the title's and the summary's buttons pressed through
## the viewport, the day's own end signal, a capture's `EventBus.hard_fail_triggered`, the
## building's own `exit_requested`, and real frames; what they built is found by the names `main`
## gives it. Every save goes to a scratch file (`GameSave.new()` at a scratch path), never the
## player's own.

const Boot := preload("res://tests/booted_main.gd")
const UI := preload("res://tests/ui_screens.gd")
## Her street door and the building it stands in front of, read off the city's nodes.
const HomeDoorReads := preload("res://tests/home_door_reads.gd")
## Takes the process id, since `user://` is shared by every checkout on the machine and two runs of
## the suite at once would otherwise read each other's file.
var _scratch_path := "user://test_run_checkpoints_scratch_%d.json" % OS.get_process_id()
const _SEED := 712044
## The height of a phone held landscape, in points (an iPhone 15, 852x393).
const _PHONE_LANDSCAPE_HEIGHT_PT := 393.0
## The catch the Hard Mode box had before every button gained its 5% margin, in design px past
## the box and its label on every side: the floor the margin may not take the catch below (the
## calm-pelican record: "the 5% button reach is a minimum, and no catch shrank").
const _HARD_MODE_FLOOR_REACH := 28.0
const TITLE := preload("res://scenes/ui/title_screen.tscn")
const SUMMARY_SCENE := preload("res://scenes/ui/day_summary.tscn")

## The save under test, at a scratch path.
var _save := GameSave.new(_scratch_path)

func run(t) -> void:

	_test_going_back_restores_every_field_the_save_carries(t)
	_test_a_checkpoint_is_kept_only_the_first_time_its_day_is_begun(t)
	_test_checkpoint_zero_is_day_one_of_the_same_city(t)
	_test_the_play_time_only_grows_across_every_way_back(t)
	await _test_going_back_across_day_11_boots_a_world_with_nothing_after_the_checkpoint(t)
	_test_a_hard_run_keeps_no_checkpoint_and_ends_on_its_last_nerve(t)
	_test_choosing_hard_mode_drops_a_checkpoint_already_kept(t)
	await _test_a_hard_runs_escape_spends_nerves_and_ends_on_the_last(t)
	await _test_leaving_the_building_gives_a_hard_run_no_nerve_back(t)
	_test_the_lost_day_screen_says_where_she_goes_back_to(t)
	_test_the_checkbox_shows_only_for_a_new_game(t)
	await _test_which_titles_show_the_checkbox_today(t)
	await _test_a_press_on_the_checkbox_flips_it_and_never_starts_the_run(t)
	await _test_a_real_tap_on_the_checkbox_reaches_it_on_a_phone_and_a_desktop(t)
	_test_no_control_on_the_title_stops_a_press(t)
	await _test_the_title_sets_a_new_games_mode_and_leaves_a_resumed_ones(t)

	_with_saving(func() -> void: _save.clear())
	_save.free()

## `callable` run as a windowed release run, which saves, against the scratch file `run()` set; the
## configuration is taken back off afterwards, since a booted `main` hands its own.
func _with_saving(callable: Callable) -> void:
	_save.configure(RunConfig.parse(PackedStringArray(), "", false, false, {}, false))
	callable.call()
	_save.configure(null)

## `run` written to the scratch file the way a game writes it, under way. Whether it was kept.
func _write_to_the_scratch_file(run: RunState) -> bool:
	var kept := [false]
	_with_saving(func() -> void: kept[0] = _save.write(run, true) == GameSave.Result.CONFIRMED)
	return kept[0]

## What the scratch file resumes into `run`, `{}` when nothing.
func _read_from_the_scratch_file(run: RunState) -> Dictionary:
	var resumed := [{}]
	_with_saving(func() -> void: resumed[0] = _save.try_resume(run))
	return resumed[0]

## The configuration of a windowed release run, which saves, for a boot that reads a save the test
## laid down (`_with_saving()`'s own).
static func _windowed() -> RunConfig:
	return RunConfig.parse(PackedStringArray(["--no-telemetry"]), "", false, false, {}, false)

# ------------------------------------------------------------------ the checkpoint ---

## **The exact state at the checkpoint, every field the save carries.** The run is played into
## day 4 (its first checkpoint), on past it with a lost day and a won one, written to the file and
## read back so the checkpoint has been through JSON, then every field the save carries is changed
## and the last nerve is lost: what comes back must be the checkpoint's own dawn, field for field,
## with every nerve.
##
## **The fields are enumerated off the run itself, not listed here.** `RunStateRegistry.run_data()`
## is everything the file holds of the run (the file adds its format, build, the day under way, the
## mode and the checkpoint, and refuses a run that has an ending, which the last change below gives
## it); every top-level key and every field under `"state"` is checked
## twice: once that `_change_everything()` actually changed it — so a field a later build adds to
## the save fails here until it is changed too — and once that going back gave it back. A field the
## restore left out keeps its changed value and fails the second check; a field the save never
## carries at all is `tests/test_save.gd`'s `_test_round_trip_field_list_matches_the_property_list`.
func _test_going_back_restores_every_field_the_save_carries(t) -> void:
	var run := RunState.new()
	run.start_run(_SEED)
	for d in range(1, 4):
		run.calendar.begin_day()
		run.calendar.remember_where_she_settled(Vector2i(d, d))
		run.calendar.finish_day(GameEnums.DayResult.WON)
	t.check(run.header.day == 4, "three won days reach day 4")
	run.header.nerves = 3
	run.calendar.begin_day()
	var expected := run.run_parts.run_data()
	t.check(run.calendar.checkpoint == expected, "beginning day 4 keeps its dawn as the checkpoint")

	# On past it: a lost attempt at day 4, a won one, and into day 5.
	run.add_scar("after_the_checkpoint", Vector2(40.0, 40.0))
	run.calendar.finish_day(GameEnums.DayResult.LOST_CRYING)
	run.calendar.begin_day()
	run.calendar.finish_day(GameEnums.DayResult.WON)
	run.calendar.begin_day()
	t.check(run.header.day == 5 and run.calendar.checkpoint == expected,
			"day 5 is under way and the checkpoint is still day 4's dawn")

	# Through the file, so the checkpoint given back is the one a closed game would come back to.
	t.check(_write_to_the_scratch_file(run), "the run is written with its checkpoint")
	run.start_run(_SEED + 1)
	t.check(not _read_from_the_scratch_file(run).is_empty(), "and read back")
	t.check(run.calendar.checkpoint_day() == 4, "with its checkpoint on day 4")

	var keys := _run_keys(run)
	t.check(keys.size() > 10, "there are fields to check (%d)" % keys.size())
	var before := _flatten(run.run_parts.run_data())
	_change_everything(run)
	var changed := _flatten(run.run_parts.run_data())
	for key in keys:
		t.check(changed[key] != before[key] and changed[key] != _flatten_run(expected)[key],
				"'%s' is changed after the checkpoint — a field this test does not change cannot "
						% key + "show that going back gives it back; change it in _change_everything()")

	run.header.nerves = 1
	t.check(run.calendar.a_loss_goes_back_to_the_checkpoint(), "losing now spends a normal run's last nerve")
	t.check(run.calendar.finish_day(GameEnums.DayResult.LOST_HARD_FAIL), "and the run goes on")
	var after := _flatten(run.run_parts.run_data())
	var wanted := _flatten_run(expected)
	wanted["state.nerves"] = Tuning.STARTING_NERVES
	# The one field going back does not give back: the time played only grows (inbox #920 in plaid-penguin).
	wanted["state.play_seconds"] = changed["state.play_seconds"]
	for key in keys:
		t.check(after[key] == wanted[key],
				"'%s' is the checkpoint's own dawn again (%s, wanted %s)"
						% [key, str(after[key]).left(80), str(wanted[key]).left(80)])
	t.check(run.header.nerves == Tuning.STARTING_NERVES and run.header.day == 4,
			"back at day 4 with every nerve")
	t.check(run.calendar.checkpoint_day() == 4 and not run.calendar.hard_mode,
			"still a normal run, whose checkpoint is still day 4")
	t.check(run.header.ending == GameEnums.Ending.NONE, "and a normal run has no bad ending")

## Every key of the file that is the run's own state — top-level riders by name, and `"state"`'s
## fields as `state.<name>` — read off `RunStateRegistry.run_data()` itself.
func _run_keys(run: RunState) -> Array[String]:
	var keys: Array[String] = []
	for key: String in _flatten(run.run_parts.run_data()):
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

## Every field the save carries, moved somewhere the checkpoint's dawn could not have had it. The
## dawn's own photographs (the resistance's, the spent one-shots, scars and city, the posters' and the
## pelican's) are moved the way the game moves them, by photographing the changed run
## (`RunStateRegistry.photograph()`, which `RunCalendar.begin_day()` calls), so each holds the
## changed value rather than the checkpoint's.
func _change_everything(run: RunState) -> void:
	run.header.run_seed += 1
	run.header.player_is_male = not run.header.player_is_male
	run.header.day = 10
	run.header.nerves = 2
	run.resistance.progress += 3
	run.header.ending = GameEnums.Ending.NEUTRAL
	run.header.play_ticks += 15000
	run.attempt_spend.consumed_one_shots.append("spent_after_the_checkpoint")
	run.resistance.completed_steps.append(99)
	run.resistance.failed_steps.append(98)
	run.add_scar("scarred_after_the_checkpoint", Vector2(120.0, 80.0))
	run.attempt_spend.city_state.apply_cause({Vector2i(30, 30): _fake_block_plan()}, Vector2i(30, 30),
			GameEnums.BlockCause.FIRE, 10)
	run.resistance.sabotage_done = not run.resistance.sabotage_done
	run.resistance.carrying_package = not run.resistance.carrying_package
	run.settled.settled_in[10] = Vector2i(5, 5)
	run.facts.escape_section = DaySpec.Section.CITY
	run.facts.completed_resistance_alley_tiles.append(Vector2i(77, 77))
	run.facts.fenced_park = Vector2i(3, 3)
	run.facts.fenced_park_act = 3
	run.posters.paste(Vector2i(9, 9), 0, false, 1)
	run.posters.tears += 1
	run.posters.pasted_through += 4
	run.pelican.draws += 5
	run.run_parts.photograph()

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
	var run := RunState.new()
	run.start_run(_SEED)
	t.check(run.calendar.checkpoint_day() == 1, "a fresh run's checkpoint is day 1")
	run.header.day = 4
	run.calendar.begin_day()
	var day_four := run.calendar.checkpoint.duplicate(true)
	t.check(run.calendar.checkpoint_day() == 4, "day 4 is a checkpoint")
	run.header.play_ticks = 2310
	run.calendar.finish_day(GameEnums.DayResult.LOST_TIMEOUT)
	run.calendar.begin_day()
	t.check(run.calendar.checkpoint == day_four, "a retry of day 4 does not replace its dawn")
	for d in range(4, 8):
		run.calendar.finish_day(GameEnums.DayResult.WON)
		run.calendar.begin_day()
		if run.header.day < 8:
			t.check(run.calendar.checkpoint == day_four,
					"day %d is not a checkpoint, so day 4's stands" % run.header.day)
	t.check(run.header.day == 8 and run.calendar.checkpoint_day() == 8, "day 8 replaces it")
	run.header.day = 12
	run.calendar.begin_day()
	t.check(run.calendar.checkpoint_day() == 12, "day 12, the last act's first, replaces it too")

## Before day 4, the last nerve goes back to day 1 of the same city — the same seed, and the same
## parent pushing the pram — rather than a new run.
func _test_checkpoint_zero_is_day_one_of_the_same_city(t) -> void:
	var run := RunState.new()
	run.start_run(_SEED)
	run.header.player_is_male = not run.header.player_is_male
	var parent := run.header.player_is_male
	run.calendar.finish_day(GameEnums.DayResult.WON)
	run.calendar.finish_day(GameEnums.DayResult.WON)
	run.calendar.begin_day()
	run.complete_resistance_step(0)
	run.header.nerves = 1
	var events := []
	var listen := func(day: int, lost_day: int) -> void: events.append([day, lost_day])
	EventBus.went_back_to_a_checkpoint.connect(listen)
	t.check(run.calendar.finish_day(GameEnums.DayResult.LOST_CRYING), "the run goes on")
	EventBus.went_back_to_a_checkpoint.disconnect(listen)
	t.check(run.header.day == 1 and run.header.run_seed == _SEED, "day 1 of the same city")
	t.check(run.header.nerves == Tuning.STARTING_NERVES and run.resistance.progress == 0
			and run.resistance.completed_steps.is_empty(), "with every nerve and nothing done")
	t.check(run.header.player_is_male == parent, "pushed by the same parent")
	t.check(events == [[1, 3]], "and the counter hears checkpoint 1 from day 3 (%s)" % [events])

## **The run's play time only ever grows** (inbox #920 in plaid-penguin): going back to checkpoint zero, going back
## to a later checkpoint, retrying a lost day and a save continued after a go-back each leave the
## time exactly as it was, and a new game from the title is the one thing that starts it at zero.
## The go-back paths to checkpoint zero and to a later checkpoint fail on the code before the fix
## (zero reset it, a later one took the dawn's); the retry and the save passed before and pin it.
func _test_the_play_time_only_grows_across_every_way_back(t) -> void:
	var run := RunState.new()
	# Back to checkpoint zero, from day 3.
	run.start_run(_SEED)
	run.calendar.finish_day(GameEnums.DayResult.WON)
	run.calendar.finish_day(GameEnums.DayResult.WON)
	run.calendar.begin_day()
	run.header.play_ticks = 4321
	run.header.nerves = 1
	run.calendar.finish_day(GameEnums.DayResult.LOST_CRYING)
	t.check(run.header.day == 1 and run.header.play_ticks == 4321,
			"back to checkpoint zero keeps the play time (%d)" % run.header.play_ticks)

	# Back to a later checkpoint: the dawn of day 4 held less time than the loss on day 5.
	run.start_run(_SEED)
	run.header.day = 4
	run.header.play_ticks = 1000
	run.calendar.begin_day()
	run.calendar.finish_day(GameEnums.DayResult.WON)
	run.calendar.begin_day()
	run.header.play_ticks = 7777
	run.header.nerves = 1
	run.calendar.finish_day(GameEnums.DayResult.LOST_CRYING)
	t.check(run.header.day == 4 and run.calendar.checkpoint_day() == 4
			and run.header.play_ticks == 7777,
			"back to a later checkpoint keeps the play time, not the dawn's (%d)" % run.header.play_ticks)

	# A lost day retried with nerves left: no go-back, the header is not given back.
	run.header.nerves = 3
	run.header.play_ticks = 8000
	run.calendar.finish_day(GameEnums.DayResult.LOST_TIMEOUT)
	run.calendar.begin_day()
	t.check(run.header.play_ticks == 8000, "a lost day's retry keeps the play time")

	# A save continued after a go-back holds the time the go-back kept.
	run.header.nerves = 1
	run.calendar.finish_day(GameEnums.DayResult.LOST_CRYING)
	var kept := run.header.play_ticks
	t.check(_write_to_the_scratch_file(run), "the run is written after the go-back")
	run.start_run(_SEED + 1)
	t.check(run.header.play_ticks == 0, "a new game starts at zero")
	_read_from_the_scratch_file(run)
	t.check(kept == 8000 and run.header.play_ticks == 8000,
			"a save continued after a go-back keeps the play time (%d)" % run.header.play_ticks)

## **Going back is a boot, not a repaint.** Day 11 boards the neighbor's window on her own building
## for the rest of the run (`City.board_neighbor_window()`), which nothing in a dawn takes down; a
## run that loses its last nerve on day 11 and goes back to day 8 must not see it boarded, since
## nothing after the checkpoint happened. Played through the real `main.tscn` on a run of the
## test's own: booted on day 8 (`--day 8`, its checkpoint), its title answered through the viewport,
## and days 8 to 10 won through the day's own end signal and the summary's continue, which repaints
## the same world for the next day; the last nerve lost on day 11, and the lost-day screen's
## continue. The world she then plays day 8 in — the next boot if the continue reloaded, this one
## if it did not — has the window unboarded, and the run's checkpoint restart was counted once and
## not followed by a second `run_begun`. Both boots are handed one node of the test's own in place
## of the tree's root (`main.use_sitting_home()`), with the sitting that holds the run parked in
## it: the continue leaves that sitting there, carrying the run and the title's answer, and the
## next boot takes it from there.
func _test_going_back_across_day_11_boots_a_world_with_nothing_after_the_checkpoint(t) -> void:
	var run := RunState.new()
	var home := Boot.home_playing(t, run)
	var reloads := []
	var hand := func(main: Node) -> void:
		main.use_sitting_home(home)
		main.use_reload(func() -> void: reloads.append(1))
	var config := Boot.config(["--day", "8"])
	var booted: Boot.Booted = await Boot.boot(t, _scratch_path, config, hand)
	var main := booted.main
	# A joystick, steered from the right: what the title answered has to hold for the sitting, and
	# the boot going back opens no title to ask again.
	await Boot.press_title(t, main, "Right")
	for d in range(8, 11):
		Boot.day(main).day_finished.emit(GameEnums.DayResult.WON)
		await Boot.press_continue(t, main)
	t.check(run.header.day == 11 and run.calendar.checkpoint_day() == 8,
			"day 11 is under way, with day 8 the checkpoint")
	var boarded := HomeDoorReads.building(Boot.city(main))
	t.check(boarded != null and boarded.neighbor_window_col >= 0,
			"day 11 boarded the neighbor's window")

	var back := []
	var begun := []
	var on_back := func(day: int, lost_day: int) -> void: back.append([day, lost_day])
	var on_begun := func(day: int, resumed: bool) -> void: begun.append([day, resumed])
	EventBus.went_back_to_a_checkpoint.connect(on_back)
	EventBus.run_begun.connect(on_begun)
	run.header.nerves = 1
	# The day's own timeout: its clock runs out and one physics tick ends the day.
	Boot.day(main).time_remaining = 0.0
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	t.check(run.header.day == 8 and Boot.summary(main).is_showing(), "the lost-day screen is up, at day 8")
	await Boot.press_continue(t, main)

	var playing := booted
	if reloads.size() == 1:
		booted.free_all()
		var parked := home.get_node_or_null(NodePath(Sitting.NODE_NAME)) as Sitting
		t.check(parked != null and parked.carry_the_run_over,
				"the continue leaves the sitting in its home, carrying the run over")
		playing = await Boot.boot(t, _scratch_path, config, hand)
	t.check(reloads.size() == 1, "the continue reloads the scene rather than repainting this one")
	t.check(run.header.day == 8 and run.header.nerves == Tuning.STARTING_NERVES,
			"she plays day 8 with every nerve")
	var building := HomeDoorReads.building(Boot.city(playing.main))
	t.check(building != null and building.neighbor_window_col < 0,
			"and the neighbor's window is not boarded on day 8")
	t.check(not Boot.title(playing.main).is_open() and not t.get_tree().paused,
			"straight into the day, with no title in front of it")
	# Run's disc is drawn at the focus opposite the one the joystick steers from.
	var controls := Boot.touch_controls(playing.main)
	t.check(controls.controls_mode() == ControlsMode.Mode.JOYSTICK
			and controls.run_button_center() == TouchControls.FOCUS_LEFT,
			"with the joystick the title chose, steered from the right, as before")
	t.check(run.calendar.hard_mode == false, "in the mode the title chose")
	t.check(back == [[8, 11]], "the checkpoint restart was counted once (%s)" % [back])
	t.check(begun.is_empty(), "and the reload begins no new run (%s)" % [begun])
	EventBus.went_back_to_a_checkpoint.disconnect(on_back)
	EventBus.run_begun.disconnect(on_begun)
	t.get_tree().paused = false
	t.check(home.get_child_count() == 1 and not (home.get_child(0) as Sitting).carry_the_run_over,
			"and the next boot took that sitting and spent the carry")
	playing.free_all()
	home.free()

func _test_a_hard_run_keeps_no_checkpoint_and_ends_on_its_last_nerve(t) -> void:
	var run := RunState.new()
	run.start_run(_SEED)
	run.calendar.choose_mode(true)
	run.header.day = 8
	run.calendar.begin_day()
	t.check(run.calendar.checkpoint.is_empty(), "a hard run keeps no checkpoint on day 8")
	run.header.nerves = 1
	t.check(not run.calendar.a_loss_goes_back_to_the_checkpoint(), "its last nerve does not go back")
	t.check(not run.calendar.finish_day(GameEnums.DayResult.LOST_TIMEOUT), "the run ends")
	t.check(run.header.ending == GameEnums.Ending.BAD and run.header.day == 8,
			"with the bad ending, on the day it was lost")
	run.header.ending = GameEnums.Ending.NONE

## A `--day 8` boot keeps day 8's dawn behind the title before the mode is chosen; choosing hard
## mode on that title drops it.
func _test_choosing_hard_mode_drops_a_checkpoint_already_kept(t) -> void:
	var run := RunState.new()
	run.start_run(_SEED)
	run.header.day = 8
	run.calendar.begin_day()
	t.check(run.calendar.checkpoint_day() == 8, "a normal run keeps day 8")
	run.calendar.choose_mode(true)
	t.check(run.calendar.hard_mode and run.calendar.checkpoint.is_empty(), "hard mode has none")

# ------------------------------------------------------------------- the escape ---

## Hard mode's escape, booted for real on a hard run handed over to the building and lost through
## the signal a real capture fires (`EventBus.hard_fail_triggered`, which the day's own clock turns
## into its end): a lost section costs a nerve and comes up on the day's outcome screen with one
## fewer star and the section's own words, its continue is the section again behind its brief, and
## the last nerve is the bad ending, with no continue, rather than the section again — shown after
## the outcome screen, as a lost day's is.
func _test_a_hard_runs_escape_spends_nerves_and_ends_on_the_last(t) -> void:
	var run := RunState.new()
	run.start_run(_SEED)
	run.calendar.choose_mode(true)
	run.header.day = Tuning.RUN_LENGTH_DAYS
	run.header.nerves = 2
	run.facts.escape_section = DaySpec.Section.BUILDING
	var home := Boot.home_playing(t, run)
	var booted: Boot.Booted = await Boot.boot(t, _scratch_path, Boot.config([]),
			func(main: Node) -> void: main.use_sitting_home(home))
	var main := booted.main
	var summary := Boot.summary(main)
	await Boot.press_continue(t, main)
	EventBus.hard_fail_triggered.emit("abduction")
	var body: Label = summary.get_node("Root/Center/Lines/Body")
	t.check(run.header.nerves == 1 and summary.is_showing()
			and body.text.contains("Escape the building"),
			"a lost section costs a hard run a nerve, and comes up on the day's outcome screen")
	t.check(body.text.contains("Nerves left: %s" % Texts.nerve_stars(1))
			and body.text.contains("Escape the building"),
			"which shows the one star left under the section's own words ('%s')" % body.text)

	# Its continue is the section again, behind its brief, and the brief's continue the walk.
	await Boot.press_continue(t, main)
	await Boot.press_continue(t, main)
	EventBus.hard_fail_triggered.emit("abduction")
	t.check(run.header.nerves == 0 and summary.is_showing(),
			"the last nerve does not start it again")
	await Boot.press_continue(t, main)
	var heading: Label = summary.get_node("Root/Center/Lines/Heading")
	t.check(run.header.ending == GameEnums.Ending.BAD and summary.is_showing(),
			"it is the bad ending")
	t.check(heading.visible and heading.text == "GAME OVER", "on the GAME OVER screen")
	t.check(not UI.control(summary, "ContinueColumn").visible, "which has no continue button")

	booted.free_all()
	home.free()

## *(dotted-hawk, the player, #718: "No regain in escape either.")* A hard run handed over to the
## escape boots the real `main.tscn` on the building, and the service door's own `exit_requested`
## — the signal the building emits when she walks out of it — brings the city's brief up with the
## nerves it had, none given back.
func _test_leaving_the_building_gives_a_hard_run_no_nerve_back(t) -> void:
	var run := RunState.new()
	run.start_run(_SEED)
	run.calendar.choose_mode(true)
	run.header.day = Tuning.RUN_LENGTH_DAYS
	run.header.nerves = 3
	run.facts.escape_section = DaySpec.Section.BUILDING
	var home := Boot.home_playing(t, run)
	var booted: Boot.Booted = await Boot.boot(t, _scratch_path, Boot.config([]),
			func(main: Node) -> void: main.use_sitting_home(home))
	var main := booted.main
	var interior := Boot.interior(main)
	t.check(interior != null and Boot.summary(main).is_showing(),
			"the boot stands in the building on its brief")
	t.check(interior.exit_requested.is_connected(Boot.day(main).reach_the_exit),
			"the service door is wired to the day's own goal")
	await Boot.press_continue(t, main)
	interior.exit_requested.emit()
	t.check(run.header.nerves == 3, "leaving the building gives the hard run no nerve back")
	var body: Label = Boot.summary(main).get_node("Root/Center/Lines/Body")
	t.check(Boot.summary(main).is_showing() and body.text.contains(Texts.nerve_stars(3)),
			"and the city's brief shows the same count ('%s')" % body.text)
	booted.free_all()
	home.free()

# ---------------------------------------------------------------- the screens ---

## *(gentle-osprey: the lost-day screen says e.g. "Back to day 8" with five stars and keeps the
## ordinary continue button.)*
func _test_the_lost_day_screen_says_where_she_goes_back_to(t) -> void:
	var run := RunState.new()
	run.start_run(_SEED)
	run.header.day = 8
	var summary: CanvasLayer = SUMMARY_SCENE.instantiate()
	t.add_child(summary)
	var end := DayEnd.new()
	end.result = GameEnums.DayResult.LOST_TIMEOUT
	end.reason = "Dusk came."
	end.goes_back = true
	summary.show_summary(SummaryModel.day_over(run, end), RunFlow.Mode.BACK_TO_CHECKPOINT)
	var body: Label = summary.get_node("Root/Center/Lines/Body")
	t.check(body.text.contains("Back to day 8"), "it names the day she goes back to ('%s')" % body.text)
	t.check(body.text.contains(Texts.nerve_stars(Tuning.STARTING_NERVES)), "with five stars")
	t.check(not body.text.contains("again"), "and not that she tries the day again")
	t.check(UI.control(summary, "ContinueColumn").visible, "and the continue button stays")
	summary.free()
	t.get_tree().paused = false

## A title of the real scene, handed `run` and the platform's touch answer the way `main` hands
## them before the screen enters the tree (`use_run()`, `use_platform()`), under `t`.
func _title_for(t, run: RunState, touch := false) -> TitleScreen:
	var title: TitleScreen = TITLE.instantiate()
	title.use_run(run)
	title.use_platform(touch, QuitOption.available())
	t.add_child(title)
	return title

## Whether the title shows its Hard Mode checkbox, read off the box's node.
static func _box_shown(title: TitleScreen) -> bool:
	return UI.control(title, "HardMode").visible

## The catch the box owes a press, in the 1280x720 design box: the box and its label as drawn, grown
## by the 5% every button catches beyond what it draws and by the reach it had before, whichever is
## larger each way. A press inside it flips the box.
static func _the_catch_owed(title: TitleScreen) -> Rect2:
	var box := UI.control(title, "HardMode")
	var drawn := box.get_global_transform() * Rect2(Vector2.ZERO, box.size)
	return ButtonGeometry.margin_rect(drawn).merge(drawn.grow(_HARD_MODE_FLOOR_REACH))

func _test_the_checkbox_shows_only_for_a_new_game(t) -> void:
	var run := RunState.new()
	run.start_run(_SEED)
	var title := _title_for(t, run)
	title.open(false, true)
	t.check(_box_shown(title) and not title.hard_mode_checked(),
			"a new game shows the box, unchecked")
	title.open(false, false)
	t.check(not _box_shown(title) and not title.hard_mode_checked(),
			"a resumed game shows none")
	UI.push(title, _key(KEY_H))
	t.check(not title.hard_mode_checked(), "and H flips nothing that is not there")
	run.calendar.hard_mode = true
	title.open(false, true)
	t.check(title.hard_mode_checked(), "--hard opens it checked")
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
##   whether or not an ending was shown in this scene first (`open()`'s `again`).
## - A boot that resumed a saved run, its day under way or not: none.
## - The escape's resume gate (a boot that resumed a game closed in the building) and the
##   `--start-escape` epilogue (`open(true)`): none.
##
## Each boot is the real `main.tscn`, under a windowed release configuration handed a scratch save
## (`_windowed()`), reading the run the test wrote there or finding none, so what is checked is the
## boot's own decision; the title's own `open()` answers the two openings no boot here reaches (the
## title again after an ending, the epilogue's), on the booted title.
func _test_which_titles_show_the_checkbox_today(t) -> void:
	# [what the save holds: null for nothing, else whether its day was under way, and whether it
	#  was closed in the building; the box shown; the name of the case]
	var cases := [
		[null, false, true, "a boot with nothing to resume"],
		[false, false, false, "a boot that resumed a saved run between days"],
		[true, false, false, "a boot that resumed a run in the middle of a day"],
		[false, true, false, "the escape's resume gate"],
	]
	for case: Array in cases:
		if case[0] != null:
			var saved := RunState.new()
			saved.start_run(_SEED)
			if case[1]:
				saved.header.day = Tuning.RUN_LENGTH_DAYS
				saved.facts.escape_section = DaySpec.Section.BUILDING
			_with_saving(func() -> void: _save.write(saved, bool(case[0])))
		var run := RunState.new()
		var home := Boot.home_playing(t, run)
		var booted: Boot.Booted = await Boot.boot(t, _scratch_path, _windowed(),
				func(main: Node) -> void: main.use_sitting_home(home))
		var title := Boot.title(booted.main)
		t.check(title.is_open() and _box_shown(title) == case[2],
				"%s: the box is %s" % [case[3], "shown" if case[2] else "not shown"])
		# Where the box is not shown a resumed run's mode is decided, so its name stands there.
		t.check(Boot.mode_name_drawn(title) == ("" if case[2] else "Normal"),
				"%s: the mode's name is %s" % [case[3], "not shown" if case[2] else "shown"])
		if case[0] == null:
			title.open(true, true)
			t.check(_box_shown(title), "the same, after an ending in this scene: the box is shown")
			t.check(Boot.mode_name_drawn(title) == "",
					"the same, after an ending in this scene: the mode's name is not shown")
			title.open(true)
			t.check(not _box_shown(title) and Boot.mode_name_drawn(title) == "",
					"nor does the --start-escape epilogue show a box or a name")
		booted.free_all()
		home.free()

## The box answers a touch, a click and `H`, and none of them starts the run; the three buttons
## still do. Each press is pushed through the viewport, the GUI pass and then the title's own
## handler, as a real one arrives.
func _test_a_press_on_the_checkbox_flips_it_and_never_starts_the_run(t) -> void:
	var run := RunState.new()
	run.start_run(_SEED)
	var title := _title_for(t, run, false)
	var started := [0]
	title.start_requested.connect(func(_mode: ControlsMode.Mode, _by_key: bool,
			_side: ControlsMode.Side) -> void: started[0] += 1)
	title.open(false, true)
	var box := title.get_node("Root/HardMode") as Control
	var centre := _the_catch_owed(title).get_center()
	t.check(box.size.x > 0.0, "the box is laid out (%s)" % box.size)
	# A phone held landscape is about 393pt tall and shows the 720-px-tall design box scaled to fit;
	# a finger wants 44pt each way.
	var on_a_phone := _the_catch_owed(title).size * (_PHONE_LANDSCAPE_HEIGHT_PT / 720.0)
	t.check(on_a_phone.x >= 44.0 and on_a_phone.y >= 44.0,
			"the box is a 44pt target on a phone held landscape (%s pt)" % on_a_phone)

	UI.push(title, UI.touch_at(centre, true))
	t.check(title.hard_mode_checked(), "a touch checks it")
	UI.push(title, UI.mouse_at(centre, true))
	t.check(not title.hard_mode_checked(), "a click unchecks it")
	UI.push(title, _key(KEY_H))
	t.check(title.hard_mode_checked(), "and H checks it again")
	await UI.frames(t, 3)
	t.check(started[0] == 0, "none of which started the run")

	UI.push(title, UI.touch_at(UI.centre(UI.button(title, "Tap")), true))
	await UI.frames(t, 3)
	t.check(started[0] == 1 and title.hard_mode_checked(),
			"a button still starts the run, with the box as it was set")
	for button_name: String in ["Left", "Right"]:
		title.open(false, true)
		var was := title.hard_mode_checked()
		UI.push(title, UI.touch_at(UI.centre(UI.button(title, button_name)), true))
		await UI.frames(t, 3)
		t.check(title.hard_mode_checked() == was and started[0] == (2 if button_name == "Left" else 3),
				"the %s button's disc is outside the box's reach: it starts the run and flips nothing"
						% button_name)
	title.free()

## **A real tap on the box flips it, through the engine's own input dispatch.** *(fluffy-kestrel,
## the player, #740: "Hard mode should have the same 5% extension over the box and text as other
## buttons", titled "Cannot select hard mode"; inbox #746 in woolly-penguin: "all of this was on phone.")* What
## stopped the presses was Godot's GUI pass, which runs first and offers a press to the topmost
## `Control` under it that does not ignore the mouse. Under the box that was the bottom scrim, a
## `ColorRect` left at Godot's default `MOUSE_FILTER_STOP`, so every touch and click on the box was
## used up there and never reached the title's own handler; the three buttons worked because their
## columns are containers, which pass a press on. So this drives `Input.parse_input_event()` +
## `flush_buffered_events()`, as `tests/test_held_restart.gd` does, which runs the GUI pass and the
## engine's emulate-mouse-from-touch pass both: a phone (the title handed a touch platform,
## `use_platform()`, its finger arriving as a screen touch and an emulated click) held landscape,
## held portrait (the title turned, the touch arriving in the 720x1280 box) and a desktop's mouse,
## each at the drawn box's centre, on its label, in the space between the two, at a corner of the
## drawn rect and just inside two corners of its catch: *"the whole bounding box should trigger"*
## (inbox #746 in woolly-penguin). Each tap must flip the box exactly once. The window is sized to the device for
## the span, since real dispatch maps a window position through the stretch.
func _test_a_real_tap_on_the_checkbox_reaches_it_on_a_phone_and_a_desktop(t) -> void:
	var run := RunState.new()
	run.start_run(_SEED)
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
		var title := _title_for(t, run, touch)
		ScreenOrientation.apply_to_layer(title, rotate)
		var started := [0]
		title.start_requested.connect(func(_mode: ControlsMode.Mode, _by_key: bool,
				_side: ControlsMode.Side) -> void: started[0] += 1)
		title.open(false, true)
		var box_node := title.get_node("Root/HardMode") as Control
		var frame_node := title.get_node("Root/HardMode/Frame") as Control
		var drawn := box_node.get_global_transform() * Rect2(Vector2.ZERO, box_node.size)
		var box := frame_node.get_global_transform() * Rect2(Vector2.ZERO, frame_node.size)
		var catch := _the_catch_owed(title)
		var inset := Vector2.ONE
		var points := {
			"the box's centre": box.get_center(),
			"its label": Vector2(drawn.end.x - drawn.size.x * 0.25, drawn.get_center().y),
			"the space between the box and its label": Vector2(box.end.x + 1.0, box.get_center().y),
			"the drawn rect's top-right corner": Vector2(drawn.end.x - 1.0, drawn.position.y + 1.0),
			"just inside its owed catch's top-left": catch.position + inset,
			"just inside its owed catch's bottom-right": catch.end - inset,
		}
		for where: String in points:
			var was := title.hard_mode_checked()
			var at: Vector2 = points[where]
			_tap_through_the_engine(t, ScreenOrientation.to_presented_space(at, rotate), touch)
			t.check(title.hard_mode_checked() != was,
					"%s: a tap on %s %s flips the box" % [device[2], where, at])
		await UI.frames(t, 3)
		t.check(started[0] == 0, "%s: and none of those taps started the run" % device[2])
		# The same scrim covered the strip of each button's catch above its column, the part of the
		# square grown by a third of the radius that lies outside the container. The frames above
		# have laid the columns out.
		var tap := UI.button(title, "Tap")
		var button := tap.get_global_rect()
		var above := Vector2(button.get_center().x, button.position.y - ModeButton.RADIUS / 3.0 + 1.0)
		t.check(tap.contains_design_point(above),
				"%s: %s is inside the tap button's catch" % [device[2], above])
		_tap_through_the_engine(t, ScreenOrientation.to_presented_space(above, rotate), touch)
		await UI.frames(t, 3)
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
	var run := RunState.new()
	var title := _title_for(t, run)
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

## The title's start reads the box for a new game and nothing for a resumed one, and tells the
## counter the mode only for the new game. Two real boots of `main.tscn` under a windowed release
## configuration handed a scratch save: one resuming a hard run the test wrote there, between
## days, and one with nothing to resume, whose box is pressed through the viewport before Tap.
func _test_the_title_sets_a_new_games_mode_and_leaves_a_resumed_ones(t) -> void:
	var modes := []
	var listen := func(hard: bool, day: int) -> void: modes.append([hard, day])
	EventBus.run_mode_chosen.connect(listen)

	var saved := RunState.new()
	saved.start_run(_SEED)
	saved.calendar.choose_mode(true)
	_with_saving(func() -> void: _save.write(saved, false))
	var run := RunState.new()
	var home := Boot.home_playing(t, run)
	var booted: Boot.Booted = await Boot.boot(t, _scratch_path, _windowed(),
			func(main: Node) -> void: main.use_sitting_home(home))
	await Boot.press_title(t, booted.main, "Tap")
	t.check(run.calendar.hard_mode and modes.is_empty(),
			"a resumed run keeps the mode its save carries, and reports none")
	booted.free_all()
	home.free()

	run = RunState.new()
	home = Boot.home_playing(t, run)
	booted = await Boot.boot(t, _scratch_path, _windowed(),
			func(main: Node) -> void: main.use_sitting_home(home))
	var title := Boot.title(booted.main)
	await UI.frames(t)
	UI.push(title, UI.touch_at(_the_catch_owed(title).get_center(), true))
	await Boot.press_title(t, booted.main, "Tap")
	t.check(run.calendar.hard_mode and modes == [[true, 1]],
			"a new game takes the box's answer and reports it with the day behind the title (%s)"
					% [modes])

	EventBus.run_mode_chosen.disconnect(listen)
	booted.free_all()
	home.free()

# ------------------------------------------------------------------- helpers ---

func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event
