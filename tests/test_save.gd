extends RefCounted
## `GameSave`, and the functions on `RunState` and its registry it reads and writes through
## (`run_parts.run_data()`/`restore_state()`) — see docs/MECHANICS.md, "Saving and resuming". The
## checks that go through `main` (the title, the resume gate, the focus loss and the day-14
## hand-over) are in `tests/test_save_wiring.gd`.
##
## **Every test here builds its `GameSave` at a scratch file**, never `user://save.json`: a run whose
## `RunConfig` is headless (the runner's own) never saves (see
## `_test_uses_save_is_false_under_the_headless_runner()`), so the suite hands `_save.configure()`
## the configuration of a windowed release run for everything after the policy checks, and
## the scratch path it was built with points that run's `write()`, `try_resume()` and `clear()` at
## the scratch file. The file format is exercised through those three, the calls the game itself makes.
##
## **Every test makes the run it saves and loads** (`_a_run()`, a fresh `RunState` of its own) and
## hands it to the save, as `main` hands the save the run its sitting holds; nothing here
## reads or sets a global run, so nothing is put back for the suite that runs after it.

const MapCache := preload("res://tests/city_map_cache.gd")
const Boot := preload("res://tests/booted_main.gd")
## What a city's state has recorded, read off the snapshot the save writes.
const CityStateReads := preload("res://tests/city_state_reads.gd")

const _SCRATCH_PATH := "user://test_save_scratch.json"

## The save under test, at a scratch path.
var _save := GameSave.new(_SCRATCH_PATH)


func run(t: TestRunner) -> void:

	_test_uses_save_is_false_under_the_headless_runner(t)
	_test_debug_run_uses_save_policy(t)
	_test_no_save_query_parsing(t)
	_test_web_debug_flag_used_query_parsing(t)
	_test_gated_write_and_resume_touch_nothing_under_the_headless_runner(t)

	# From here on the run is a windowed release run, which saves; the scratch path keeps it off the
	# player's own file.
	_save.configure(_windowed_run())
	# A finished run leaves no save (`main` connects this at every boot); a suite that ends a run
	# connects it itself, so it holds whichever suite ran before this one.
	_save.clear_when_a_run_ends()
	_save.clear()

	_test_round_trip_field_list_matches_the_property_list(t)
	_test_round_trip_preserves_every_field(t)
	_test_play_time_is_saved_as_seconds_and_counted_in_ticks(t)
	_test_a_won_days_regained_nerve_survives_a_round_trip(t)
	_test_missing_file_is_dropped(t)
	_test_garbled_text_is_dropped(t)
	_test_wrong_format_version_is_dropped(t)
	_test_incomplete_state_is_dropped(t)
	_test_clear_deletes_the_file(t)
	_test_write_refuses_once_the_run_has_ended(t)
	_test_the_escape_section_survives_a_round_trip(t)
	_test_a_save_from_before_the_escape_still_loads(t)
	_test_completed_resistance_alley_tiles_survive_a_round_trip(t)
	_test_a_save_from_before_the_alley_tiles_still_loads(t)
	_test_the_fenced_park_survives_a_round_trip(t)
	_test_an_expired_fence_survives_a_round_trip(t)
	_test_a_save_from_before_the_fenced_park_still_loads(t)
	_test_a_save_from_before_a_task_was_one_day_still_loads(t)
	_test_the_posters_survive_a_round_trip(t)
	_test_the_pelican_bags_count_survives_a_round_trip_and_an_old_save_loads_at_0(t)

	_test_a_day_under_way_gives_back_the_fire_it_lit(t)
	_test_day_under_way_load_on_the_last_nerve_ends_the_run(t)
	_test_day_under_way_load_on_a_normal_runs_last_nerve_goes_back(t)
	_test_a_save_from_before_checkpoints_still_loads(t)
	_test_the_mode_and_the_checkpoint_survive_a_round_trip(t)
	_test_summary_load_costs_nothing(t)
	_test_double_load_does_not_charge_twice(t)
	_test_either_ending_clears_the_save(t)

	_test_a_save_moment_answers_by_platform_and_storage(t)
	_test_a_desktop_write_is_confirmed_at_once(t)
	_test_a_refused_or_ended_run_is_not_a_failed_save(t)
	_test_a_flush_settles_once_whichever_answer_comes_first(t)
	_test_a_flush_whose_listener_is_gone_settles_quietly(t)
	_test_a_deletion_flush_settles_through_the_bus_and_a_write_flush_does_not(t)
	_test_a_deletion_flush_whose_listener_is_gone_settles_quietly(t)
	_test_one_huge_frame_does_not_time_a_flush_out(t)
	_test_a_flush_still_times_out_after_enough_frames(t)
	_test_a_deletion_raises_and_settles_the_symbol(t)
	_test_a_deletion_not_kept_strikes_the_symbol(t)
	_test_a_run_that_ends_shows_the_symbol_for_the_deletion(t)
	_test_a_resumed_run_ended_by_its_charge_shows_the_symbol(t)
	_test_a_restart_with_no_save_left_shows_nothing(t)
	_test_the_restarts_symbol_survives_the_scene_reload(t)
	_test_a_write_announces_itself_on_the_bus_and_begins_the_symbol_once(t)
	_test_a_write_flush_settles_the_write_signal_and_a_deletion_flush_does_not(t)
	_test_a_pending_write_is_answered_after_the_restart_freed_the_main_that_saved(t)
	_test_an_answer_to_a_change_the_symbol_never_began_is_ignored(t)
	_test_each_change_carries_its_own_operation_id_to_its_answer(t)
	_test_the_symbols_listening_ends_with_the_symbol(t)
	_test_the_symbol_holds_with_no_timer_while_a_save_is_pending(t)
	_test_a_save_answered_at_once_shows_for_a_second_then_fades(t)
	_test_a_save_pending_three_seconds_fades_straight_after_its_answer(t)
	_test_any_unanswered_save_keeps_the_symbol_up(t)
	_test_a_failure_answered_at_once_shows_struck_for_ten_seconds(t)
	_test_a_failure_answered_after_five_seconds_is_struck_until_fifteen(t)
	_test_a_save_beginning_mid_fade_restarts_the_second(t)
	_test_a_save_beginning_while_fully_shown_does_not_restart_the_second(t)
	_test_the_newest_failure_strikes_and_an_older_success_does_not_clear_it(t)
	_test_an_older_failure_never_strikes(t)
	_test_only_the_newest_save_decides_in_either_order_of_arrival(t)
	_test_each_failure_restarts_the_struck_clock(t)
	_test_a_kept_save_after_a_failed_one_clears_the_strike(t)
	_test_begin_does_not_clear_a_strike_while_its_save_is_unanswered(t)
	_test_a_struck_symbol_that_faded_away_is_forgotten(t)
	_test_a_stray_answer_shows_nothing(t)
	_test_a_save_not_kept_swaps_to_the_struck_picture(t)

	_save.clear()
	_save.free()

## The configuration of a windowed run on a release build (or, with `args` and `query`, a debug one
## given those flags): the shape `main` hands `_save.configure()` outside a headless runner.
func _windowed_run(args := PackedStringArray(), query := "", debug_build := false) -> RunConfig:
	return RunConfig.parse(args, query, debug_build, false, {}, false)

## A run the headless runner itself would resolve: it never saves.
func _headless_run() -> RunConfig:
	return RunConfig.parse(PackedStringArray(), "", false)

## A fresh run on `run_seed`, the run a test saves and loads.
func _a_run(run_seed := 2) -> RunState:
	var run := RunState.new()
	run.start_run(run_seed)
	return run

## `run` written to the scratch file the way a game writes it. Whether the write was kept.
func _saved(run: RunState, day_under_way: bool) -> bool:
	return _save.write(run, day_under_way) == GameSave.Result.CONFIRMED

## Operation ids a test hands the bus or a flush table for changes of its own, larger for every
## change begun later, as `GameSave`'s own are.
var _operation := 1000

func _next_operation() -> int:
	_operation += 1
	return _operation

## Whether a write under the current configuration lands: the save answers that it kept the file
## and the file is there. The scratch file is gone before and after, so only this write is read.
func _a_write_lands() -> bool:
	var run := _a_run()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_SCRATCH_PATH))
	var landed := _saved(run, false) and FileAccess.file_exists(_SCRATCH_PATH)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_SCRATCH_PATH))
	return landed

## The scratch file is put away around `callable`, so a test starts and leaves with no save.
func _with_a_scratch_save(callable: Callable) -> void:
	_save.clear()
	callable.call()
	_save.clear()

## `callable` run as the headless runner's own run would be: saving refused.
func _headless(callable: Callable) -> void:
	_save.configure(_headless_run())
	callable.call()
	_save.configure(_windowed_run())

# ---------------------------------------------------------------------- policy ---

## The property that makes every other test in this suite (and every other suite, and
## `tools/check.sh`'s own boot) safe to run at all: nothing here ever reaches the player's real
## `user://save.json`, because the headless display server this runner boots against already
## answers "no" on its own, before a path override is even asked for.
func _test_uses_save_is_false_under_the_headless_runner(t: TestRunner) -> void:
	_save.configure(RunConfig.at_boot())
	t.check(RunConfig.at_boot().headless and not _a_write_lands(),
			"the headless test runner never reads or writes the real save")
	_save.configure(_headless_run())
	t.check(not _a_write_lands(), "nor does a headless release run, flags or no flags")
	_save.configure(null)
	t.check(not _a_write_lands(), "nor does a run nothing has configured yet")

## The debug build's policy on whether a run saves, read off whether a write lands.
func _test_debug_run_uses_save_policy(t: TestRunner) -> void:
	_save.configure(_windowed_run(PackedStringArray(), "", true))
	t.check(_a_write_lands(), "a flagless debug run uses the save")
	_save.configure(_windowed_run(PackedStringArray(["--seed", "1"]), "", true))
	t.check(not _a_write_lands(), "any dev flag disables it, by being a dev flag at all")
	_save.configure(_windowed_run(PackedStringArray(), "?nosave=1", true))
	t.check(not _a_write_lands(),
			"--no-save disables it even with nothing else on the command line")
	_save.configure(_windowed_run(PackedStringArray(["--seed", "1"]), "?nosave=1", true))
	t.check(not _a_write_lands(), "and the two reasons stack rather than fighting")
	_save.configure(_windowed_run())
	t.check(_a_write_lands(), "a windowed release run uses it")
	_save.configure(null)


func _test_no_save_query_parsing(t: TestRunner) -> void:
	t.check(not DevFlags.new(PackedStringArray(), "", true).no_save(),
			"an absent URL parameter changes nothing")
	t.check(not DevFlags.new(PackedStringArray(), "?nosave=0", true).no_save(),
			"nosave=0 leaves the save on")
	t.check(DevFlags.new(PackedStringArray(), "?nosave=1", true).no_save(), "?nosave=1 turns it off")
	t.check(DevFlags.new(PackedStringArray(), "?seed=1&nosave=1&day=2", true).no_save(),
			"the parameter is found among other URL parameters")

## M193, "the live page's ?debug=1 reaches the debug flags": the save's release branch is
## `not DevFlags.web_debug_flag_used()` rather than an unconditional `true` now, so a visitor who
## tries `?day=12` never touches the save the page might otherwise share with a real player —
## `_web_debug_flag_used_in_query()` is the pure half of that predicate a test can drive without a
## live page. The `?debug=1`-alone and empty-query cases pin that opening the bundle is not the
## same as having used anything in it, which is the property that keeps an ordinary release page's
## own save exactly as it always was.
func _test_web_debug_flag_used_query_parsing(t: TestRunner) -> void:
	t.check(not DevFlags.new(PackedStringArray(), "", false).web_debug_flag_used(),
			"an absent query used nothing")
	t.check(not DevFlags.new(PackedStringArray(), "?debug=1", false).web_debug_flag_used(),
		"?debug=1 alone opens the bundle without having used anything in it")
	t.check(DevFlags.new(PackedStringArray(), "?debug=1&day=12", false).web_debug_flag_used(),
		"?day=12 is a use of the bundle's own day parameter")
	t.check(DevFlags.new(PackedStringArray(), "?debug=1&invincible=1", false).web_debug_flag_used(),
		"and so is ?invincible=1")
	t.check(not DevFlags.new(PackedStringArray(), "?debug=1&seed=1234", false).web_debug_flag_used(),
		"?seed=, the older M133 bundle, is not part of this one")

## The gated entry points `main.gd` actually calls (`write()`, `try_resume()` and `clear()`) refuse
## outright under the headless runner, and touch no file at all in doing so — the property every
## other suite, and `tools/check.sh`'s own boot, are safe *because* of.
func _test_gated_write_and_resume_touch_nothing_under_the_headless_runner(t: TestRunner) -> void:
	var run := _a_run()
	_save.configure(_windowed_run())
	_save.clear()
	_save.configure(_headless_run())
	t.check(_save.write(run, true) == GameSave.Result.REFUSED,
			"the gated write refuses under the headless runner")
	t.check(not FileAccess.file_exists(_SCRATCH_PATH), "and leaves no file behind")
	_save.configure(_windowed_run())
	t.check(_saved(run, true), "while the run saves, the same write lands")
	_save.configure(_headless_run())
	t.check(_save.try_resume(run).is_empty(),
			"the gated resume also refuses, even with a real file sitting at the scratch path")
	t.check(_save.clear() == GameSave.Result.REFUSED,
			"the gated deletion refuses too")
	t.check(FileAccess.file_exists(_SCRATCH_PATH), "and leaves the file where it was")
	_save.configure(_windowed_run())
	_save.clear()

# ------------------------------------------------------------------- round trip ---

## The guard the brief asks for: a field declared on `RunState` and saved by nothing fails here
## rather than quietly not being saved. A field is saved when the registered parts write a key of
## its name, or it is a part itself, or it is the calendar, whose mode and checkpoint ride at the
## top of the save beside `"day_under_way"` (the file `write()` leaves, held by
## `tests/test_run_checkpoints.gd`). (A part's own field is saved by its part, which
## `tests/test_run_state.gd` holds.)
## `PROPERTY_USAGE_SCRIPT_VARIABLE` is what separates a field this script declares from the base
## `Node` properties `get_property_list()` also reports (`name`, `process_mode`, and the rest).
func _test_round_trip_field_list_matches_the_property_list(t: TestRunner) -> void:
	var run := _a_run()
	var declared: Array[String] = []
	for property in run.get_property_list():
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			declared.append(property["name"])
	var written := run.run_parts.state_keys()
	written.append_array(run.run_parts.run_data().keys())
	for name in declared:
		var value: Variant = run.get(name)
		if value is RunSubState or value is RunStateRegistry or value is RunCalendar:
			continue
		t.check(name in written,
				"'%s' is a run field the save format does not mention" % name)

## The run's play time is counted in physics ticks (inbox #866 in minty-dolphin) and saved as seconds
## (`to_data()`), so any save's seconds, whatever number they hold, load to the nearest tick, and
## a tick count is written back as its seconds.
func _test_play_time_is_saved_as_seconds_and_counted_in_ticks(t: TestRunner) -> void:
	var header := RunHeader.new()
	var old := header.to_data()
	old["play_seconds"] = 123.456
	header.restore(old)
	t.check(header.play_ticks == roundi(123.456 * Engine.physics_ticks_per_second),
			"seconds from an older save load to the nearest tick (%d)" % header.play_ticks)
	header.play_ticks = 9645
	var written := header.to_data()
	t.check(written["play_seconds"] is float
			and is_equal_approx(written["play_seconds"], 9645.0 / Engine.physics_ticks_per_second),
			"and ticks are written back as seconds (%s)" % written["play_seconds"])
	header.restore(written)
	t.check(header.play_ticks == 9645, "which load back to the same tick")

## Every field, mutated to a value its default could not be mistaken for, round-tripped through
## the actual file — `write()`/`try_resume()`, not the in-memory dictionaries, so a JSON
## int-becomes-float or a `Vector2i` key that cannot survive `JSON.stringify()` would show up here.
func _test_round_trip_preserves_every_field(t: TestRunner) -> void:
	var run := _a_run(778899)
	run.header.day = 6
	run.header.nerves = 3
	# The dawn the run stands at is photographed first, then the live work moves on from it, so the
	# file has to carry both.
	run.resistance.completed_steps = [0]
	run.resistance.failed_steps = []
	run.resistance.progress = 1
	run.resistance.sabotage_done = false
	run.resistance.carrying_package = false
	run.resistance.photograph()
	run.resistance.progress = 2
	run.header.ending = GameEnums.Ending.NONE
	run.header.play_ticks = 3704
	run.attempt_spend.consumed_one_shots = ["a_one_shot", "another_one_shot"]
	run.resistance.completed_steps = [0, 2]
	run.resistance.failed_steps = [1]
	run.attempt_spend.scars = [{"id": "fire", "position": Vector2(140.5, -30.25), "since_day": 4}]
	run.attempt_spend.city_state.reset()
	run.attempt_spend.city_state.apply_cause(
			{Vector2i(3, 4): _fake_block_plan()}, Vector2i(3, 4), GameEnums.BlockCause.FIRE, 6)
	run.resistance.sabotage_done = false
	run.resistance.carrying_package = true
	run.settled.settled_in = {5: Vector2i(-2, 7), 6: Vector2i(9, 9)}

	var written: Dictionary = run.run_parts.run_data()["state"]
	t.check(_saved(run, true), "the write reports success")
	var resume := _save.try_resume(run)
	t.check(resume.get("day_under_way", false) == true, "day_under_way round-trips as true")

	t.check(run.header.run_seed == 778899, "run_seed survives")
	t.check(run.header.day == 6, "day survives")
	t.check(run.header.nerves == 3, "nerves survives")
	t.check(run.resistance.progress == 2, "resistance_progress survives")
	t.check(run.header.play_ticks == 3704, "the play time survives to the tick, saved as seconds")
	t.check(run.attempt_spend.consumed_one_shots == ["a_one_shot", "another_one_shot"],
			"consumed_one_shots survives, string array and all")
	t.check(run.resistance.completed_steps == [0, 2], "completed_resistance_steps survives")
	t.check(run.resistance.failed_steps == [1], "failed_resistance_steps survives")
	t.check(run.attempt_spend.scars.size() == 1
			and run.attempt_spend.scars[0]["id"] == "fire"
			and (run.attempt_spend.scars[0]["position"] as Vector2).distance_to(Vector2(140.5, -30.25)) < 0.01
			and run.attempt_spend.scars[0]["since_day"] == 4,
			"a scar survives with its Vector2 position intact")
	t.check(CityStateReads.changed_on(run.attempt_spend.city_state, Vector2i(3, 4)) == 6,
			"the city's own block-arc history survives — a fire that burned did happen")
	t.check(run.resistance.carrying_package == true, "resistance_carrying_package survives")
	t.check(run.settled.settled_in.get(5) == Vector2i(-2, 7)
			and run.settled.settled_in.get(6) == Vector2i(9, 9),
			"settled_in survives with its Vector2i values and integer day keys intact")
	t.check(run.run_parts.run_data()["state"] == written,
			"and the whole snapshot taken before the write matches the one read back after it")
	# The dawn snapshot, read through what it is for: a lost day gives it back.
	run.resistance.give_back()
	t.check(run.resistance.completed_steps == [0] and run.resistance.failed_steps.is_empty(),
			"the dawn snapshot's own steps survive")
	t.check(run.resistance.progress == 1, "the dawn's progress survives")
	t.check(not run.resistance.sabotage_done and not run.resistance.carrying_package,
			"and the dawn's sabotage and package")

## Player, 2026-09-27: *"a won day recovers a nerve up to the max"*. `nerves` was already carried by
## the snapshot's keys, but the count it carries now has to be the one a win just gave back, not the one
## a save taken before the change would have written — this writes the file only after the gain and
## wipes the live count before reading it back, so a save that quietly dropped the regained nerve
## rather than the round trip itself is what would fail this.
func _test_a_won_days_regained_nerve_survives_a_round_trip(t: TestRunner) -> void:
	var run := _a_run(240927)
	run.header.nerves = 3
	run.calendar.finish_day(GameEnums.DayResult.WON)
	t.check(run.header.nerves == 4, "winning regains a nerve before the save is even written")

	t.check(_saved(run, true), "the write reports success")
	run.header.nerves = 0
	_save.try_resume(run)
	t.check(run.header.nerves == 4, "and the regained count is what loading the save gives back")

## The smallest arc `CityState.apply_cause()` needs to take a `FIRE` step, built the way the
## generator builds one (`BlockPlan.of()`, `then()`), since this suite has no city to take one from.
func _fake_block_plan() -> BlockPlan:
	var plan := BlockPlan.of(GameEnums.BlockPurpose.RESIDENTIAL).then(GameEnums.BlockPurpose.BURNT_OUT,
			1, GameEnums.BlockCause.FIRE)
	return plan

# ----------------------------------------------------------------- dropped saves ---


func _test_missing_file_is_dropped(t: TestRunner) -> void:
	var run := _a_run()
	_save.clear()
	t.check(_save.try_resume(run).is_empty(), "no file at all resumes nothing")


func _test_garbled_text_is_dropped(t: TestRunner) -> void:
	var run := _a_run()
	var before: Dictionary = run.run_parts.run_data()["state"]
	_write_raw("not valid json at all {{{")
	t.check(_save.try_resume(run).is_empty(), "text that is not valid JSON resumes nothing")
	t.check(run.run_parts.run_data()["state"] == before, "and the run is left exactly as it was")


func _test_wrong_format_version_is_dropped(t: TestRunner) -> void:
	var run := _a_run()
	var before: Dictionary = run.run_parts.run_data()["state"]
	_write_raw(JSON.stringify({
		"format_version": GameSave.FORMAT_VERSION + 1,
		"build": "some other build",
		"day_under_way": true,
		"state": run.run_parts.run_data()["state"],
	}))
	t.check(_save.try_resume(run).is_empty(),
			"a save this build's own format version does not match resumes nothing")
	t.check(run.run_parts.run_data()["state"] == before, "and the run is untouched by trying")


func _test_incomplete_state_is_dropped(t: TestRunner) -> void:
	var run := _a_run()
	var before: Dictionary = run.run_parts.run_data()["state"]
	var state: Dictionary = run.run_parts.run_data()["state"]
	state.erase("nerves")
	_write_raw(JSON.stringify({
		"format_version": GameSave.FORMAT_VERSION,
		"build": "some build",
		"day_under_way": true,
		"state": state,
	}))
	t.check(_save.try_resume(run).is_empty(),
			"a state missing a field this build writes resumes nothing rather than half-loading")
	t.check(run.run_parts.run_data()["state"] == before, "and the run is untouched by trying")


func _write_raw(text: String) -> void:
	var file := FileAccess.open(_SCRATCH_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _test_clear_deletes_the_file(t: TestRunner) -> void:
	var run := _a_run()
	_with_a_scratch_save(func() -> void:
		var answers := _Answers.new()
		t.check(_save.clear(answers.take) == GameSave.Result.REFUSED,
				"with no file there is nothing to delete, which changes nothing")
		t.check(_saved(run, true), "a write lands")
		t.check(FileAccess.file_exists(_SCRATCH_PATH), "and the file exists")
		t.check(_save.clear(answers.take) == GameSave.Result.CONFIRMED,
				"deleting it off the web is confirmed at once")
		t.check(not FileAccess.file_exists(_SCRATCH_PATH), "clear() removes it")
		t.check(_save.clear(answers.take) == GameSave.Result.REFUSED,
				"clearing an already-absent save changes nothing and answers refused")
		t.check(answers.results.is_empty(), "and nothing is left for a later answer to settle")
	)

func _test_write_refuses_once_the_run_has_ended(t: TestRunner) -> void:
	var run := _a_run()
	_save.clear()
	run.header.ending = GameEnums.Ending.BAD
	t.check(not _saved(run, true), "a write refuses once the run has an ending")
	t.check(not FileAccess.file_exists(_SCRATCH_PATH), "and touches no file at all")

## Closing the game inside a section of the escape and opening it again comes back to that
## section's own brief, which is `RunState.facts.escape_section` surviving the file — the same
## mechanism a day under way already rides on, and deliberately the same one rather than a second
## save path beside it.
func _test_the_escape_section_survives_a_round_trip(t: TestRunner) -> void:
	var run := _a_run(313131)
	run.header.day = Tuning.RUN_LENGTH_DAYS
	run.facts.escape_section = DaySpec.Section.CITY
	t.check(_saved(run, false), "a section of the escape writes a save")
	# Wiped the way a fresh process would find it, so what is read back has to come off the file.
	run.start_run(1)
	t.check(run.facts.escape_section == DaySpec.Section.NONE,
			"a fresh run is in no section (the check below would pass vacuously otherwise)")
	t.check(not _save.try_resume(run).is_empty(), "and the file resumes")
	t.check(run.facts.escape_section == DaySpec.Section.CITY,
			"onto the section it was closed in, not the start of the escape")
	t.check(run.header.run_seed == 313131, "with the run it belonged to")
	_save.clear()

## **A save written before the escape was a run's ending still loads.** `"escape_section"` is a
## top-level key rather than a field of the run snapshot exactly so this holds: a file with no
## mention of it at all is a complete save (`RunState.snapshot_is_complete()` asks only about
## `"state"`) and resumes to a run in no section, which is every one of the fourteen days.
##
## The payload is assembled here rather than pasted from a real old file, so it stays a save of
## *this* build's snapshot shape with only the new key missing — which is the thing that has to
## keep working, and the only part of an older file that differs.
func _test_a_save_from_before_the_escape_still_loads(t: TestRunner) -> void:
	var run := _a_run(424242)
	run.header.day = 9
	run.header.nerves = 3
	var old_shape := JSON.stringify({
		"format_version": GameSave.FORMAT_VERSION,
		"build": "a build from before the escape",
		"day_under_way": true,
		"state": run.run_parts.run_data()["state"],
	})
	t.check(not old_shape.contains("escape_section"),
			"the payload really is one with no escape section in it")
	run.start_run(1)
	run.facts.escape_section = DaySpec.Section.BUILDING
	_write_raw(old_shape)
	var resumed := _save.try_resume(run)
	t.check(not resumed.is_empty(), "a save with no escape section still resumes")
	t.check(run.header.run_seed == 424242 and run.header.day == 9 and run.header.nerves == 3,
			"with every field it does carry")
	t.check(bool(resumed.get("day_under_way", false)),
			"and the day-under-way flag beside it, unchanged")
	t.check(run.facts.escape_section == DaySpec.Section.NONE,
			"and the run is in no section, rather than keeping whatever was in memory")
	_save.clear()

## The same mechanism `escape_section` rides on, for the alley tiles the resistance has already
## used this run (M177) — closing the game between days must not hand the next mark back every
## alley to choose from again.
func _test_completed_resistance_alley_tiles_survive_a_round_trip(t: TestRunner) -> void:
	var run := _a_run(515151)
	run.facts.completed_resistance_alley_tiles = [Vector2i(4, 9), Vector2i(-2, 15)]
	t.check(_saved(run, false), "a run with used alley tiles writes a save")
	run.start_run(1)
	t.check(run.facts.completed_resistance_alley_tiles.is_empty(),
			"a fresh run has recorded none (the check below would pass vacuously otherwise)")
	t.check(not _save.try_resume(run).is_empty(), "and the file resumes")
	t.check(run.facts.completed_resistance_alley_tiles == [Vector2i(4, 9), Vector2i(-2, 15)],
			"onto the tiles it was closed with, Vector2i values and all")
	_save.clear()

## Expiring the physical fence cannot reopen the once-per-run choice, including after a reload.
func _test_an_expired_fence_survives_a_round_trip(t: TestRunner) -> void:
	var run := _a_run(14040)
	run.facts.fenced_park = Vector2i(6, 8)
	run.facts.fenced_park_act = 3
	run.header.day = 12
	run.facts.remember_fenced_park(Vector2i(-1, -1), 0)
	t.check(_saved(run, false), "the act-boundary run writes a save")
	run.start_run(1)
	t.check(not _save.try_resume(run).is_empty(), "the act-boundary save resumes")
	t.check(run.facts.fenced_park == Vector2i(6, 8) and run.facts.fenced_park_act == 3,
			"reloading after expiry remembers the original fence")
	var map := MapCache.of(run.header.run_seed)
	var state := CityState.new()
	state.begin_day(map.block_plans, 13)
	map.repaint(state)
	var used: Array[Vector2i] = [map.calm_blocks[0]]
	map.set_spent_calm(used)
	map.set_fenced_park_state(run.facts.fenced_park, run.facts.fenced_park_act, 4)
	map.repaint(state)
	t.check(not map.shut_calm().is_empty(), "the resumed act has an accepted used area")
	t.check(map.fenced_park == Vector2i(-1, -1),
			"the resumed run cannot select a second fence in act IV")
	_save.clear()

## **A save written before this field existed still loads**, the same reasoning
## `_test_a_save_from_before_the_escape_still_loads()` holds for `escape_section`: a file with no
## mention of it is a complete save and resumes with nothing recorded, by absence.
func _test_a_save_from_before_the_alley_tiles_still_loads(t: TestRunner) -> void:
	var run := _a_run(626262)
	var old_shape := JSON.stringify({
		"format_version": GameSave.FORMAT_VERSION,
		"build": "a build from before this field",
		"day_under_way": true,
		"escape_section": run.facts.escape_section,
		"state": run.run_parts.run_data()["state"],
	})
	t.check(not old_shape.contains("completed_resistance_alley_tiles"),
			"the payload really is one with no alley tiles recorded in it")
	run.start_run(1)
	run.facts.completed_resistance_alley_tiles = [Vector2i(7, 7)]
	_write_raw(old_shape)
	var resumed := _save.try_resume(run)
	t.check(not resumed.is_empty(), "a save with no alley tiles still resumes")
	t.check(run.facts.completed_resistance_alley_tiles.is_empty(),
			"and the list is empty, rather than keeping whatever was in memory")
	_save.clear()

## The same mechanism `escape_section` rides on, for the one calm area this run has fenced (M129) —
## closing the game mid-act must not let a second park get fenced on reopening, which is exactly
## what forgetting `fenced_park` on reload would do.
func _test_the_fenced_park_survives_a_round_trip(t: TestRunner) -> void:
	var run := _a_run(535353)
	run.facts.fenced_park = Vector2i(6, 9)
	run.facts.fenced_park_act = 3
	t.check(_saved(run, false), "a run with a fenced park writes a save")
	run.start_run(1)
	t.check(run.facts.fenced_park == Vector2i(-1, -1),
			"a fresh run has fenced none (the check below would pass vacuously otherwise)")
	t.check(not _save.try_resume(run).is_empty(), "and the file resumes")
	t.check(run.facts.fenced_park == Vector2i(6, 9) and run.facts.fenced_park_act == 3,
			"onto the same park and the same act it was closed with")
	_save.clear()

## **A save written before this field existed still loads**, the same reasoning
## `_test_a_save_from_before_the_escape_still_loads()` holds for `escape_section`: a file with no
## mention of it is a complete save and resumes with no park fenced, by absence — the same state a
## run that has not reached act III yet is already in, so nothing forces a second fence later.
func _test_a_save_from_before_the_fenced_park_still_loads(t: TestRunner) -> void:
	var run := _a_run(646464)
	var old_shape := JSON.stringify({
		"format_version": GameSave.FORMAT_VERSION,
		"build": "a build from before this field",
		"day_under_way": true,
		"escape_section": run.facts.escape_section,
		"state": run.run_parts.run_data()["state"],
	})
	t.check(not old_shape.contains("fenced_park"),
			"the payload really is one with no fenced park recorded in it")
	run.start_run(1)
	run.facts.fenced_park = Vector2i(3, 3)
	run.facts.fenced_park_act = 2
	_write_raw(old_shape)
	var resumed := _save.try_resume(run)
	t.check(not resumed.is_empty(), "a save with no fenced park still resumes")
	t.check(run.facts.fenced_park == Vector2i(-1, -1) and run.facts.fenced_park_act == 0,
			"and none is fenced, rather than keeping whatever was in memory")
	_save.clear()

## **The pelican bag's count survives the file, and a save from before it loads at 0.** `pelican`
## rides at the top level beside `posters`, for the same reason.
func _test_the_pelican_bags_count_survives_a_round_trip_and_an_old_save_loads_at_0(t: TestRunner) -> void:
	var run := _a_run(656565)
	run.pelican.draws = 9
	run.pelican.photograph()
	run.pelican.draws = 12
	var data := run.run_parts.run_data()
	run.pelican.reset()
	run.run_parts.restore_run_data(data)
	t.check(run.pelican.draws == 12, "a save keeps the pelican bag's count (%d)"
			% run.pelican.draws)
	run.pelican.give_back()
	t.check(run.pelican.draws == 9, "and the dawn's, so a lost day after a resume goes back")
	run.pelican.draws = 12
	var old: Dictionary = data.duplicate(true)
	old.erase("pelican")
	run.run_parts.restore_run_data(old)
	t.check(run.pelican.draws == 0,
			"a save written before the bag loads at 0 over a run with a count (%d)"
			% run.pelican.draws)

## **The walls survive the file, and a save from before there were posters loads with none up.**
## `posters` rides at the top level for the reason `escape_section` does.
func _test_the_posters_survive_a_round_trip(t: TestRunner) -> void:
	var run := _a_run(646464)
	run.posters.paste(Vector2i(5, 6), PosterArt.Kind.LEADER, false, 1)
	run.posters.photograph()
	run.posters.tear(Vector2i(5, 6), 1)
	run.posters.tears = 1
	run.posters.pasted_through = 4
	var written := run.posters.to_data()
	t.check(_saved(run, false), "a run with posters writes")
	run.posters.reset()
	_save.try_resume(run)
	t.check(run.posters.to_data() == written,
			"the walls, the tear count and the photograph a lost day gives back all survive")
	var old_shape := JSON.stringify({
		"format_version": GameSave.FORMAT_VERSION,
		"build": "a build from before the posters",
		"day_under_way": false,
		"state": run.run_parts.run_data()["state"],
	})
	_write_raw(old_shape)
	_save.try_resume(run)
	t.check(run.posters.cells.is_empty() and run.posters.pasted_through == 0,
			"a save with no posters in it loads with bare walls")
	_save.clear()

## **A save from before a task was one day still loads.** `pending_resistance_brief` and
## `_dawn_brief` are gone from `RunState` (M181, the resistance has a reason, and a task is one
## day: the day brief carries no task and no mark's words, so nothing reads them back any more) —
## removed rather than added, so `snapshot_is_complete()` only ever asks for a field this build
## still names, and an older file naming two more than that still has every one of them.
## `completed_resistance_steps` from an old run names indices out of the old two-beat table, which
## no longer exists in that shape: `ResistanceSteps.by_index()` answers null for anything the new
## one-task-per-day table does not have at that index, which `RunState` and `ResistanceDirector`
## already treat as nothing, so the resumed run simply offers whatever the new table's own
## `for_day()` finds for the day it resumes on.
func _test_a_save_from_before_a_task_was_one_day_still_loads(t: TestRunner) -> void:
	var run := _a_run(636363)
	run.header.day = 7
	run.header.nerves = 4
	run.resistance.completed_steps = [1, 2, 3]
	run.resistance.progress = 1
	var snapshot: Dictionary = run.run_parts.run_data()["state"]
	snapshot["pending_resistance_brief"] = "meet at the fountain"
	snapshot["_dawn_brief"] = "an earlier brief"
	var old_shape := JSON.stringify({
		"format_version": GameSave.FORMAT_VERSION,
		"build": "a build from before a task was one day",
		"day_under_way": true,
		"state": snapshot,
	})
	run.start_run(1)
	_write_raw(old_shape)
	var resumed := _save.try_resume(run)
	t.check(not resumed.is_empty(), "a save naming the old brief fields still resumes")
	t.check(run.header.run_seed == 636363 and run.header.day == 7 and run.header.nerves == 4,
			"with every field the new build still reads")
	t.check(run.resistance.completed_steps == [1, 2, 3],
			"and its old-table step indices, carried over rather than dropped")
	_save.clear()

# ------------------------------------------------------------- the lost-day path ---

## **A run closed mid-day gives back what that day burned, through the same path an ordinary loss
## takes.** `main._ready()` hands a save written with `day_under_way` to `RunState.calendar.finish_day()` as
## a hard fail, so the whole of the give-back has to survive the file: the photograph of what the
## attempt may spend rides in the snapshot beside the resistance's, or a day 3 closed after the
## fire burned would come back with the fire spent, a shell standing and no fire owed on the retry.
##
## The round trip is the point, so the state is written, wiped to something else, and read back
## before the day is lost — a check that never left memory would pass with the three fields missing
## from the save entirely.
func _test_a_day_under_way_gives_back_the_fire_it_lit(t: TestRunner) -> void:
	var run := _a_run(59)
	run.header.day = Tuning.RUN_TAUGHT_DAY
	run.header.nerves = 3
	run.calendar.begin_day()
	run.attempt_spend.consumed_one_shots.append("burning_building")
	run.add_scar("burnt_shell", Vector2(640.0, 640.0))
	t.check(_saved(run, true), "the run is saved with the day under way and the fire lit")

	# Wiped to a different run entirely, so what comes back can only have come out of the file.
	run.start_run(60)
	var resume := _save.try_resume(run)
	t.check(resume.get("day_under_way") == true, "the save says a day was under way")
	t.check("burning_building" in run.attempt_spend.consumed_one_shots and run.attempt_spend.scars.size() == 1,
			"and it comes back with the fire spent and its shell standing, as the attempt left it")

	run.calendar.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)
	t.check(not "burning_building" in run.attempt_spend.consumed_one_shots,
			"losing the resumed day owes the fire again")
	t.check(run.attempt_spend.scars.is_empty(),
			"and takes the shell down with it, the same as any other lost day")

## In hard mode the last nerve ends the run exactly as it does when a day is lost by playing it out —
## and the ending clears the save, since there is nothing left to resume.
func _test_day_under_way_load_on_the_last_nerve_ends_the_run(t: TestRunner) -> void:
	_save.clear_when_a_run_ends()
	var run := _a_run(56)
	run.calendar.choose_mode(true)
	run.header.day = 9
	run.header.nerves = 1
	run.calendar.begin_day()
	_with_a_scratch_save(func() -> void:
		t.check(_saved(run, true), "a save exists before the last nerve is spent")

		var continues := run.calendar.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)

		t.check(not continues, "the run does not go on")
		t.check(run.header.nerves == 0, "the last nerve is gone")
		t.check(run.header.ending == GameEnums.Ending.BAD,
				"the bad ending, the same as any other run out")
		t.check(not FileAccess.file_exists(_SCRATCH_PATH), "and the save that named the run is gone with it")
	)

## The same load in a normal run goes back to its checkpoint instead, through the same call: the run
## goes on, standing at the checkpoint's dawn with every nerve, and the save is still there to be
## written over by the dawn `main._write_dawn_for_a_resumed_run()` writes next.
func _test_day_under_way_load_on_a_normal_runs_last_nerve_goes_back(t: TestRunner) -> void:
	var run := _a_run(57)
	run.header.day = 8
	run.header.nerves = 2
	run.calendar.begin_day()
	t.check(run.calendar.checkpoint_day() == 8, "day 8's dawn is the run's checkpoint")
	run.calendar.finish_day(GameEnums.DayResult.WON)
	run.calendar.begin_day()
	run.header.nerves = 1
	_with_a_scratch_save(func() -> void:
		t.check(_saved(run, true), "the mid-day save on day 9, one nerve left")
		run.start_run(58)
		var resume := _save.try_resume(run)
		t.check(resume.get("day_under_way") == true and run.calendar.checkpoint_day() == 8,
				"the save comes back under way, its checkpoint with it")
		t.check(run.calendar.a_loss_goes_back_to_the_checkpoint(),
				"and losing the day it was left on goes back")
		var continues := run.calendar.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)
		t.check(continues and run.header.ending == GameEnums.Ending.NONE,
				"the run goes on rather than ending")
		t.check(run.header.day == 8 and run.header.nerves == Tuning.STARTING_NERVES,
				"back at day 8 with every nerve")
		t.check(FileAccess.file_exists(_SCRATCH_PATH), "and the save is not deleted")
	)

## A save written before there were two modes or checkpoints — no `hard_mode` key, no `checkpoint`
## key — loads as a normal run whose checkpoint is day 1 of its own city, and `FORMAT_VERSION` is
## what it always was.
func _test_a_save_from_before_checkpoints_still_loads(t: TestRunner) -> void:
	var run := _a_run(59)
	run.header.day = 10
	t.check(_saved(run, false), "a save is written")
	var file := FileAccess.open(_SCRATCH_PATH, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	data.erase("hard_mode")
	data.erase("checkpoint")
	_write_raw(JSON.stringify(data))
	run.calendar.choose_mode(true)
	run.calendar.checkpoint = {"state": {"day": 4}}
	var resume := _save.try_resume(run)
	t.check(not resume.is_empty() and run.header.day == 10, "it still loads, on its own day")
	t.check(not run.calendar.hard_mode, "as a normal run")
	t.check(run.calendar.checkpoint.is_empty() and run.calendar.checkpoint_day() == 1,
			"whose checkpoint is checkpoint zero, day 1")

## The mode and the checkpoint survive a save, and a checkpoint this build could not give back is
## dropped for checkpoint zero rather than half-applied later.
func _test_the_mode_and_the_checkpoint_survive_a_round_trip(t: TestRunner) -> void:
	var run := _a_run(60)
	run.header.day = 4
	run.calendar.begin_day()
	t.check(run.calendar.checkpoint_day() == 4, "day 4's dawn is kept")
	run.calendar.finish_day(GameEnums.DayResult.WON)
	t.check(_saved(run, false), "a save is written")
	var kept := run.calendar.checkpoint.duplicate(true)
	run.start_run(61)
	_save.try_resume(run)
	t.check(run.calendar.checkpoint_day() == 4 and not run.calendar.hard_mode,
			"a normal run comes back with its day 4 checkpoint")
	t.check(int((run.calendar.checkpoint["state"] as Dictionary)["run_seed"])
			== int((kept["state"] as Dictionary)["run_seed"]),
			"the checkpoint read back is the one written")

	run.calendar.choose_mode(true)
	t.check(_saved(run, false), "a hard run's save is written")
	run.start_run(62)
	_save.try_resume(run)
	t.check(run.calendar.hard_mode and run.calendar.checkpoint.is_empty(),
			"a hard run comes back hard, with no checkpoint")

	run.start_run(63)
	run.calendar.checkpoint = {"state": {"day": 8}}
	t.check(_saved(run, false), "a save carrying a checkpoint with a broken snapshot")
	_save.try_resume(run)
	t.check(run.calendar.checkpoint.is_empty(),
			"falls back to checkpoint zero rather than keeping what it could not give back")

## A save written at a day's own summary (`day_under_way: false`) is never handed to
## `RunState.calendar.finish_day()` at all in `main._ready()` — asserted here as the shape of the contract
## the two booleans below make untestable any other way: nerves and day both hold whatever the
## save itself named, because nothing here ever touches them.
func _test_summary_load_costs_nothing(t: TestRunner) -> void:
	var run := _a_run(57)
	run.header.day = 8
	run.header.nerves = 4
	t.check(_saved(run, false), "a save is written at a day's own summary")
	var resume := _save.try_resume(run)
	t.check(resume.get("day_under_way") == false, "it comes back false")

## The ordering the commit message states: after the load-time penalty is applied, the very next
## write (`main._start()`'s own dawn write, made before the resumed pause screen can even be
## looked at) already reflects the spent nerve *and* writes the fresh dawn as not yet under way —
## since nothing has happened in it yet. A second close-and-reopen before ever touching that screen
## therefore finds `day_under_way: false` and costs nothing more.
func _test_double_load_does_not_charge_twice(t: TestRunner) -> void:
	var run := _a_run(58)
	run.header.day = 5
	run.header.nerves = 5
	run.calendar.begin_day()
	t.check(_saved(run, true), "the first save: a day left mid-way")

	var first := _save.try_resume(run)
	t.check(first.get("day_under_way") == true, "the first load finds a day under way")
	run.calendar.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)
	t.check(run.header.nerves == 4, "the first load costs its one nerve")
	# `main._ready()`'s own write for the resumed, unplayed retry — a title, and then a day brief,
	# both stand between this and the player actually taking control, so this is what it writes
	# before either is ever shown.
	t.check(_saved(run, false), "the fresh dawn is saved before the title is shown")

	var second := _save.try_resume(run)
	t.check(second.get("day_under_way") == false,
			"a second close before pressing continue on the day brief finds nothing under way")


func _test_either_ending_clears_the_save(t: TestRunner) -> void:
	_save.clear_when_a_run_ends()
	var run := _a_run(59)
	run.header.day = 3
	run.header.nerves = 2
	_with_a_scratch_save(func() -> void:
		t.check(_saved(run, true), "a save exists")
		run.calendar.finish_day(GameEnums.DayResult.WON)
		t.check(run.header.ending == GameEnums.Ending.NONE,
				"day 3 of a run this short does not end it")
		t.check(FileAccess.file_exists(_SCRATCH_PATH), "so the save is untouched")

		run.header.day = Tuning.RUN_LENGTH_DAYS
		run.calendar.begin_day()
		t.check(_saved(run, true), "a save exists for the final day")
		run.calendar.finish_day(GameEnums.DayResult.WON)
		t.check(run.header.ending != GameEnums.Ending.NONE, "winning the final day ends the run")
		t.check(not FileAccess.file_exists(_SCRATCH_PATH), "and a won run clears the save exactly as a lost one does")
	)

# ------------------------------------------------------------ confirmation ---

## Records every answer a `settled` callable is given, so a test can count them.
class _Answers extends RefCounted:
	var results: Array[int] = []

	func take(result: int) -> void:
		results.append(result)

## `GameSave.moment_result()`, the pure half of `write()`: every branch of what a save moment comes
## to before any browser has answered, including the web's, which this desktop runner cannot reach
## through `write()` itself. A web page whose storage was refused at boot is a failed save without
## any flush, since a flush there succeeds for a copy no reload finds.
func _test_a_save_moment_answers_by_platform_and_storage(t: TestRunner) -> void:
	t.check(GameSave.moment_result(true, false, true) == GameSave.Result.CONFIRMED,
			"off the web, a closed file is a kept save")
	t.check(GameSave.moment_result(true, true, true) == GameSave.Result.PENDING,
			"on the web, a closed file waits for the browser's answer")
	t.check(GameSave.moment_result(true, true, false) == GameSave.Result.FAILED,
			"on a web page whose storage was refused, the save is not kept, flush or no flush")
	t.check(GameSave.moment_result(false, false, true) == GameSave.Result.FAILED,
			"a file that could not be written is a failed save off the web")
	t.check(GameSave.moment_result(false, true, true) == GameSave.Result.FAILED,
			"and on it")

## Off the web, `write()` itself answers `CONFIRMED` and never calls `settled`: the file closing is
## the confirmation, so a desktop save shows the symbol at once.
func _test_a_desktop_write_is_confirmed_at_once(t: TestRunner) -> void:
	var run := _a_run()
	_with_a_scratch_save(func() -> void:
		var answers := _Answers.new()
		var result: int = _save.write(run, true, answers.take)
		t.check(result == GameSave.Result.CONFIRMED, "a desktop write is confirmed at once")
		t.check(FileAccess.file_exists(_SCRATCH_PATH), "and the file is there")
		t.check(answers.results.is_empty(), "with nothing left for a later answer to settle")
	)

## A run the save refuses (a dev or headless run), and a run that has already ended, answer `REFUSED`, which draws
## nothing — neither is a save that failed, so neither may show the strike.
func _test_a_refused_or_ended_run_is_not_a_failed_save(t: TestRunner) -> void:
	var run := _a_run()
	var answers := _Answers.new()
	_headless(func() -> void:
		t.check(_save.write(run, true, answers.take) == GameSave.Result.REFUSED,
				"the headless runner's refused save is refused, not failed")
	)
	_with_a_scratch_save(func() -> void:
		run.header.ending = GameEnums.Ending.BAD
		t.check(_save.write(run, true, answers.take) == GameSave.Result.REFUSED,
				"a run with an ending is refused, not failed")
		t.check(not FileAccess.file_exists(_SCRATCH_PATH), "and writes nothing")
	)
	t.check(answers.results.is_empty(), "neither ever answers later")

## The race `Flushes`' settling exists for: the page's answer and the timeout both settle the same
## flush, and only the first counts. A flush that answers after timing out stays failed rather than
## taking back the strike already shown, and a timeout after an answer changes nothing.
func _test_a_flush_settles_once_whichever_answer_comes_first(t: TestRunner) -> void:
	var flushes := GameSave.Flushes.new()
	var answered := _Answers.new()
	var token := flushes.register(_next_operation(), answered.take)
	flushes.answer([float(token), ""])
	flushes.fail(token, "timed out")
	t.check(answered.results.size() == 1 and answered.results[0] == GameSave.Result.CONFIRMED,
			"the browser's success settles the flush, and the later timeout does nothing")

	var timed_out := _Answers.new()
	token = flushes.register(_next_operation(), timed_out.take)
	flushes.fail(token, "timed out")
	flushes.answer([float(token), ""])
	t.check(timed_out.results.size() == 1 and timed_out.results[0] == GameSave.Result.FAILED,
			"a timeout settles the flush as failed, and a late success does not reverse it")

	var failed := _Answers.new()
	token = flushes.register(_next_operation(), failed.take)
	flushes.answer([float(token), "Connection to Indexed Database server lost"])
	t.check(failed.results.size() == 1 and failed.results[0] == GameSave.Result.FAILED,
			"the page's failure message settles the flush as failed")
	t.check(flushes.is_empty(), "and nothing is left waiting")

## A held restart reloads `main` while a flush may still be out, so the `settled` callable can name
## an object that no longer exists by the time the browser answers. Settling it does nothing.
func _test_a_flush_whose_listener_is_gone_settles_quietly(t: TestRunner) -> void:
	var flushes := GameSave.Flushes.new()
	var gone := Node.new()
	var token := flushes.register(_next_operation(), Callable(gone, &"set_name"))
	gone.free()
	flushes.answer([float(token), ""])
	t.check(flushes.is_empty(), "the flush is settled without calling anything")

# ---------------------------------------------------------------- deletions ---

## A deletion is settled through the same token table a write is, and a deletion's answer also
## reaches `EventBus.save_deletion_settled`, which is how a symbol that outlived its `main` hears it.
## A write's answer never does.
func _test_a_deletion_flush_settles_through_the_bus_and_a_write_flush_does_not(t: TestRunner) -> void:
	var flushes := GameSave.Flushes.new()
	var heard: Array[bool] = []
	var listen := func(_operation: int, kept: bool) -> void: heard.append(kept)
	EventBus.save_deletion_settled.connect(listen)

	var deleted := _Answers.new()
	var token := flushes.register(_next_operation(), deleted.take, true)
	flushes.answer([float(token), ""])
	t.check(deleted.results == [GameSave.Result.CONFIRMED] and heard == [true],
			"a deletion the browser kept settles its caller and the bus, kept")

	token = flushes.register(_next_operation(), deleted.take, true)
	flushes.answer([float(token), "Connection to Indexed Database server lost"])
	t.check(heard == [true, false], "a deletion the browser did not keep settles the bus, not kept")

	var written := _Answers.new()
	token = flushes.register(_next_operation(), written.take)
	flushes.answer([float(token), ""])
	t.check(written.results == [GameSave.Result.CONFIRMED] and heard == [true, false],
			"a write's answer settles its caller and says nothing on the deletion signal")

	t.check(flushes.is_empty(), "nothing is left waiting")
	EventBus.save_deletion_settled.disconnect(listen)

## The restart frees `main` while its deletion's flush is still out, so the callable a deletion was
## given can name a freed object when the browser answers; nothing is called, and the bus still
## says it.
func _test_a_deletion_flush_whose_listener_is_gone_settles_quietly(t: TestRunner) -> void:
	var flushes := GameSave.Flushes.new()
	var heard: Array[bool] = []
	var listen := func(_operation: int, kept: bool) -> void: heard.append(kept)
	EventBus.save_deletion_settled.connect(listen)
	var gone := Node.new()
	var token := flushes.register(_next_operation(), Callable(gone, &"set_name"), true)
	gone.free()
	flushes.answer([float(token), ""])
	t.check(flushes.is_empty() and heard == [true],
			"the deletion settles the bus without calling the freed object")
	EventBus.save_deletion_settled.disconnect(listen)

## *A tab hidden for an hour reports the whole hour as one frame's time on its return.* One frame
## adds at most `MAX_FLUSH_STEP_SECONDS` to a flush's wait, so a flush the browser was never given
## the chance to run is not timed out by that frame — and is not struck through for a save the
## browser then reports kept. A deletion's flush counts the same way.
func _test_one_huge_frame_does_not_time_a_flush_out(t: TestRunner) -> void:
	var steps := int(GameSave.FLUSH_TIMEOUT_SECONDS / GameSave.MAX_FLUSH_STEP_SECONDS)
	# An hour between two frames counts as one clamped step: it is as far along as `steps - 1` more
	# clamped steps leave it one short of the timeout, and the next one reaches it.
	var hour := GameSave.Flushes.new()
	var hour_answers := _Answers.new()
	hour.register(_next_operation(), hour_answers.take)
	hour.advance(3600.0)
	for i in steps - 2:
		hour.advance(GameSave.MAX_FLUSH_STEP_SECONDS)
	t.check(not hour.is_empty() and hour_answers.results.is_empty(),
			"an hour between two frames counts as one clamped step")
	hour.advance(GameSave.MAX_FLUSH_STEP_SECONDS)
	t.check(hour_answers.results == [GameSave.Result.FAILED], "and not as more than one")
	# An ordinary frame counts as itself: an eighth of a second, forty times, is the timeout.
	var ordinary := GameSave.Flushes.new()
	ordinary.register(_next_operation(), Callable())
	var frame := 0.125
	var frames := int(GameSave.FLUSH_TIMEOUT_SECONDS / frame)
	for i in frames - 1:
		ordinary.advance(frame)
	t.check(not ordinary.is_empty(), "an ordinary frame counts as itself: one short, it waits")
	ordinary.advance(frame)
	t.check(ordinary.is_empty(), "and the last one reaches the timeout")
	# A clock that went backwards counts as nothing.
	var backwards := GameSave.Flushes.new()
	backwards.register(_next_operation(), Callable())
	for i in 100:
		backwards.advance(-1.0)
	for i in steps - 1:
		backwards.advance(GameSave.MAX_FLUSH_STEP_SECONDS)
	t.check(not backwards.is_empty(),
			"a clock that went backwards counts as nothing: it neither adds nor takes back time")
	backwards.advance(GameSave.MAX_FLUSH_STEP_SECONDS)
	t.check(backwards.is_empty(), "so the timeout comes on the step it always did")
	var flushes := GameSave.Flushes.new()
	var write_answers := _Answers.new()
	var delete_answers := _Answers.new()
	var write_token := flushes.register(_next_operation(), write_answers.take)
	var delete_token := flushes.register(_next_operation(), delete_answers.take, true)
	flushes.advance(3600.0)
	t.check(write_answers.results.is_empty() and delete_answers.results.is_empty()
			and not flushes.is_empty(),
			"neither flush has been settled by the huge frame")
	flushes.answer([float(delete_token), ""])
	t.check(delete_answers.results == [GameSave.Result.CONFIRMED] and write_answers.results.is_empty()
			and not flushes.is_empty(),
			"the deletion's flush was still waiting, and answering it leaves the write's waiting")
	flushes.answer([float(write_token), ""])
	t.check(write_answers.results == [GameSave.Result.CONFIRMED] and flushes.is_empty(),
			"and the write's was too: the browser's own answer on that frame is kept, not ignored")

## The timeout still exists: frames actually drawn add up to `FLUSH_TIMEOUT_SECONDS`.
func _test_a_flush_still_times_out_after_enough_frames(t: TestRunner) -> void:
	var flushes := GameSave.Flushes.new()
	var answers := _Answers.new()
	var token := flushes.register(_next_operation(), answers.take, true)
	var steps := int(GameSave.FLUSH_TIMEOUT_SECONDS / GameSave.MAX_FLUSH_STEP_SECONDS)
	for i in steps - 1:
		flushes.advance(GameSave.MAX_FLUSH_STEP_SECONDS)
	t.check(not flushes.is_empty(), "one frame short of the timeout it still waits")
	flushes.advance(GameSave.MAX_FLUSH_STEP_SECONDS)
	t.check(answers.results == [GameSave.Result.FAILED], "the frame that reaches it fails the flush")
	flushes.answer([float(token), ""])
	t.check(answers.results == [GameSave.Result.FAILED], "and a late success does not reverse it")

## *"show deleting the save file with a save symbol as well. every change in the save state needs
## to show the symbol"* — a deletion that removes a file raises the symbol, answered at once off
## the web, and a pending one holds it fully shown until the browser's answer reaches the bus.
func _test_a_deletion_raises_and_settles_the_symbol(t: TestRunner) -> void:
	var run := _a_run()
	_with_a_scratch_save(func() -> void:
		# Written before the symbol is built: a write raises the symbol too.
		t.check(_saved(run, true), "a save exists")
		var timeline := SaveIndicator.Showing.new()
		var indicator := SaveIndicator.new(timeline)
		t.add_child(indicator)
		t.check(not indicator.is_showing(), "nothing shows before a deletion")
		t.check(_save.clear() == GameSave.Result.CONFIRMED, "the deletion is kept")
		t.check(indicator.is_showing() and timeline.pending == 0,
				"the symbol is up and the deletion is already answered")
		t.check(Boot.save_symbol_plain(indicator), "plain, since it was kept")
		indicator.free()

		var waiting_timeline := SaveIndicator.Showing.new()
		var waiting := SaveIndicator.new(waiting_timeline)
		t.add_child(waiting)
		var deletion := _next_operation()
		EventBus.save_deleted.emit(deletion, int(GameSave.Result.PENDING))
		t.check(waiting_timeline.pending == 1, "a pending deletion begins one change")
		waiting_timeline.advance(SaveIndicator.MIN_SHOWN_SECONDS + SaveIndicator.FADE_SECONDS + 20.0)
		t.check(waiting_timeline.alpha() == 1.0, "and holds the symbol fully shown while unanswered")
		EventBus.save_deletion_settled.emit(deletion, true)
		t.check(waiting_timeline.pending == 0 and not waiting_timeline.struck,
				"the browser's answer settles it, kept")
		waiting.free()
	)

## The same strike as a write that was not kept, for a deletion that was not: answered at once, or
## by the browser later, and for the full ten seconds.
func _test_a_deletion_not_kept_strikes_the_symbol(t: TestRunner) -> void:
	var immediate_timeline := SaveIndicator.Showing.new()
	var immediate := SaveIndicator.new(immediate_timeline)
	t.add_child(immediate)
	EventBus.save_deleted.emit(_next_operation(), int(GameSave.Result.FAILED))
	t.check(Boot.save_symbol_struck(immediate) and immediate_timeline.pending == 0,
			"a deletion that failed at once shows the struck picture")
	immediate_timeline.advance(9.9)
	t.check(immediate_timeline.alpha() == 1.0, "fully for ten seconds")
	immediate.free()

	var later_timeline := SaveIndicator.Showing.new()
	var later := SaveIndicator.new(later_timeline)
	t.add_child(later)
	var deletion := _next_operation()
	EventBus.save_deleted.emit(deletion, int(GameSave.Result.PENDING))
	EventBus.save_deletion_settled.emit(deletion, false)
	t.check(Boot.save_symbol_struck(later) and later_timeline.pending == 0,
			"a deletion the browser did not keep shows the struck picture")
	later.free()

## Statement 8: the run's end deletes the save through `_save.clear_when_a_run_ends()`, which has no
## way to reach `main`, and the symbol shows it anyway. A day that does not end the run deletes
## nothing and shows nothing.
func _test_a_run_that_ends_shows_the_symbol_for_the_deletion(t: TestRunner) -> void:
	_save.clear_when_a_run_ends()
	var run := _a_run(61)
	run.header.day = 3
	_with_a_scratch_save(func() -> void:
		t.check(_saved(run, true), "a save exists")
		# Built after the write, which raises the symbol too: only the deletions are watched.
		var indicator := SaveIndicator.new()
		t.add_child(indicator)
		run.calendar.finish_day(GameEnums.DayResult.WON)
		t.check(not indicator.is_showing(), "a day that does not end the run shows nothing")

		run.header.day = Tuning.RUN_LENGTH_DAYS
		run.calendar.begin_day()
		run.calendar.finish_day(GameEnums.DayResult.WON)
		t.check(run.header.ending != GameEnums.Ending.NONE, "the final day ends the run")
		t.check(not FileAccess.file_exists(_SCRATCH_PATH), "which deletes the save")
		t.check(indicator.is_showing() and Boot.save_symbol_plain(indicator),
				"and the symbol shows the deletion, kept")
		indicator.free()
	)

## The charge a reopened run pays can end it: the lost day was the last nerve. That deletion shows
## the symbol too, provided a symbol is listening when `main._ready()` charges it.
func _test_a_resumed_run_ended_by_its_charge_shows_the_symbol(t: TestRunner) -> void:
	_save.clear_when_a_run_ends()
	var run := _a_run(62)
	run.calendar.choose_mode(true)
	run.header.day = 4
	run.header.nerves = 1
	run.calendar.begin_day()
	_with_a_scratch_save(func() -> void:
		t.check(_saved(run, true), "the mid-day save")
		var indicator := SaveIndicator.new()
		t.add_child(indicator)
		var resume := _save.try_resume(run)
		t.check(resume.get("day_under_way", false), "it resumes with its day under way")
		var kept_going := run.calendar.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)
		t.check(not kept_going and not FileAccess.file_exists(_SCRATCH_PATH), "the charge ends the run and deletes it")
		t.check(indicator.is_showing(), "and the symbol that was already there shows it")
		indicator.free()
	)

## Statement 8: a restart after the run already ended finds no save to delete, changes nothing and
## shows nothing.
func _test_a_restart_with_no_save_left_shows_nothing(t: TestRunner) -> void:
	_with_a_scratch_save(func() -> void:
		var indicator := SaveIndicator.new()
		t.add_child(indicator)
		t.check(not FileAccess.file_exists(_SCRATCH_PATH), "the run's end already deleted the save")
		t.check(_save.clear() == GameSave.Result.REFUSED, "so the restart's deletion is refused")
		t.check(not indicator.is_showing(), "and the symbol stays dark")
		indicator.free()
	)

## The held restart deletes the save and reloads the scene, which frees `main` and everything under
## it. The symbol the deletion raised is handed to the sitting first (`Sitting`, which a real reload
## leaves at the tree's root; a sitting of the test's own here), so it is still there on the title
## the reload builds, still pending, and the browser's answer settles it. An idle symbol is not
## carried: the next boot builds its own.
func _test_the_restarts_symbol_survives_the_scene_reload(t: TestRunner) -> void:
	var sitting := Sitting.new()
	t.add_child(sitting)
	var old_main := Node.new()
	t.add_child(old_main)
	var timeline := SaveIndicator.Showing.new()
	var indicator := SaveIndicator.new(timeline)
	old_main.add_child(indicator)
	t.check(SaveIndicator.carried(sitting) == null, "nothing is carried before a restart")

	indicator.outlive_the_scene(sitting)
	t.check(indicator.get_parent() == old_main, "an idle symbol stays where it is")

	var deletion := _next_operation()
	EventBus.save_deleted.emit(deletion, int(GameSave.Result.PENDING))
	indicator.outlive_the_scene(sitting)
	t.check(indicator.get_parent() == sitting, "a symbol that is up goes to the sitting")
	old_main.free()
	t.check(is_instance_valid(indicator), "so freeing the scene it came from does not free it")
	t.check(SaveIndicator.carried(sitting) == indicator, "and the next boot finds it")
	t.check(timeline.pending == 1 and indicator.is_showing(), "still showing the pending deletion")

	EventBus.save_deletion_settled.emit(deletion, false)
	t.check(Boot.save_symbol_struck(indicator) and timeline.pending == 0,
			"the browser's answer arrives after the reload and settles it, struck")
	indicator.free()
	t.check(SaveIndicator.carried(sitting) == null, "nothing is left on the sitting")
	sitting.free()

## A symbol freed with its scene stops listening: a signal drops a freed object by itself, so a
## later deletion reaches nobody and calls nothing.
func _test_the_symbols_listening_ends_with_the_symbol(t: TestRunner) -> void:
	var before := EventBus.save_deleted.get_connections().size()
	var indicator := SaveIndicator.new()
	t.add_child(indicator)
	t.check(EventBus.save_deleted.get_connections().size() == before + 1,
			"a symbol listens for deletions once it is built")
	indicator.free()
	t.check(EventBus.save_deleted.get_connections().size() == before,
			"and stops when it is freed")
	var before_writes := EventBus.save_written.get_connections().size()
	var writer := SaveIndicator.new()
	t.add_child(writer)
	t.check(EventBus.save_written.get_connections().size() == before_writes + 1,
			"and for writes, which is how a save's answer outlives the main that saved")
	writer.free()
	t.check(EventBus.save_written.get_connections().size() == before_writes,
			"until it is freed")

## A write tells `EventBus` what it came to, so the symbol hears it without `main` relaying it, and
## begins exactly once for one save. A write
## `GameSave` refuses (a headless run, an ended run) announces nothing.
func _test_a_write_announces_itself_on_the_bus_and_begins_the_symbol_once(t: TestRunner) -> void:
	var run := _a_run()
	var heard: Array[int] = []
	var listen := func(_operation: int, result: int) -> void: heard.append(result)
	EventBus.save_written.connect(listen)
	_headless(func() -> void:
		t.check(_save.write(run, true) == GameSave.Result.REFUSED and heard.is_empty(),
				"a headless run's write is refused and announces nothing")
	)
	_with_a_scratch_save(func() -> void:
		var timeline := SaveIndicator.Showing.new()
		var indicator := SaveIndicator.new(timeline)
		t.add_child(indicator)
		_save.write(run, true)
		t.check(heard == [int(GameSave.Result.CONFIRMED)], "a write announces what it came to")
		t.check(timeline.begun == 1, "and the symbol began once for it, with nobody relaying it")
		t.check(indicator.is_showing() and timeline.pending == 0 and Boot.save_symbol_plain(indicator),
				"and that one change is already answered, showing the plain picture")
		indicator.free()
		run.header.ending = GameEnums.Ending.BAD
		heard.clear()
		t.check(_save.write(run, true) == GameSave.Result.REFUSED and heard.is_empty(),
				"a run that has ended refuses the write and announces nothing")
	)
	EventBus.save_written.disconnect(listen)

## A write's web answer reaches `EventBus.save_write_settled`, and only a write's: a deletion's goes
## to `save_deletion_settled`, so one answer settles one change however many are out.
func _test_a_write_flush_settles_the_write_signal_and_a_deletion_flush_does_not(t: TestRunner) -> void:
	var flushes := GameSave.Flushes.new()
	var heard: Array[bool] = []
	var listen := func(_operation: int, kept: bool) -> void: heard.append(kept)
	EventBus.save_write_settled.connect(listen)
	var answers := _Answers.new()
	var token := flushes.register(_next_operation(), answers.take)
	flushes.answer([float(token), ""])
	t.check(heard == [true] and answers.results == [GameSave.Result.CONFIRMED],
			"a write the browser kept settles the bus, kept, and then its caller")
	token = flushes.register(_next_operation(), answers.take)
	flushes.answer([float(token), "Connection to Indexed Database server lost"])
	t.check(heard == [true, false], "a write the browser did not keep settles the bus, not kept")
	token = flushes.register(_next_operation(), answers.take, true)
	flushes.answer([float(token), ""])
	t.check(heard == [true, false], "a deletion's answer says nothing on the write signal")
	t.check(flushes.is_empty(), "nothing is left waiting")
	EventBus.save_write_settled.disconnect(listen)

## **The held restart on a day's summary while its end-of-day save is still being retried.** The web
## save is announced pending, the restart hands the symbol to the sitting and frees `main`, and
## the browser answers a flush whose `settled` callable names the freed `main`. The symbol must
## still be answered; before the answer went through the bus it stayed pending, fully shown, for
## good.
func _test_a_pending_write_is_answered_after_the_restart_freed_the_main_that_saved(t: TestRunner) -> void:
	var flushes := GameSave.Flushes.new()
	var sitting := Sitting.new()
	t.add_child(sitting)
	var old_main_scene := Node.new()
	t.add_child(old_main_scene)
	var timeline := SaveIndicator.Showing.new()
	var indicator := SaveIndicator.new(timeline)
	old_main_scene.add_child(indicator)
	# The object the flush's `settled` callable names, standing for the `main` that saved.
	var saver := Node.new()

	var save := _next_operation()
	EventBus.save_written.emit(save, int(GameSave.Result.PENDING))
	var token := flushes.register(save, Callable(saver, &"set_name"))
	t.check(timeline.pending == 1, "the web save is out and the symbol waits for it")
	indicator.outlive_the_scene(sitting)
	t.check(indicator.get_parent() == sitting, "the restart hands the symbol to the sitting")
	saver.free()
	old_main_scene.free()

	flushes.answer([float(token), ""])
	t.check(timeline.pending == 0 and Boot.save_symbol_plain(indicator),
			"the answer reaches the symbol with the main that saved gone, and it is kept")
	timeline.advance(SaveIndicator.MIN_SHOWN_SECONDS + SaveIndicator.FADE_SECONDS + 0.1)
	t.check(timeline.is_idle(), "so the symbol fades out instead of staying up for good")

	save = _next_operation()
	EventBus.save_written.emit(save, int(GameSave.Result.PENDING))
	token = flushes.register(save, Callable())
	flushes.answer([float(token), "Connection to Indexed Database server lost"])
	t.check(Boot.save_symbol_struck(indicator) and timeline.pending == 0,
			"and a save the browser did not keep strikes it the same way")
	indicator.free()
	sitting.free()

## A symbol that did not live through a reload never began the changes announced before it, and an
## answer to one of those settles nothing on it: its own pending change stays pending, and its own
## failure still strikes.
func _test_an_answer_to_a_change_the_symbol_never_began_is_ignored(t: TestRunner) -> void:
	var timeline := SaveIndicator.Showing.new()
	var indicator := SaveIndicator.new(timeline)
	t.add_child(indicator)
	var before_it := _next_operation()
	var its_own := _next_operation()
	EventBus.save_written.emit(its_own, int(GameSave.Result.PENDING))
	EventBus.save_write_settled.emit(before_it, true)
	EventBus.save_deletion_settled.emit(before_it, false)
	t.check(timeline.pending == 1 and Boot.save_symbol_plain(indicator),
			"an answer to a change announced before it was built neither settles nor strikes it")
	EventBus.save_write_settled.emit(its_own, false)
	t.check(Boot.save_symbol_struck(indicator) and timeline.pending == 0,
			"and its own change's answer still does")
	indicator.free()

## Every announced change carries its own operation id, larger for every change begun later, and its
## web answer carries the same id back — the tie between an answer and its change.
func _test_each_change_carries_its_own_operation_id_to_its_answer(t: TestRunner) -> void:
	var run := _a_run()
	var announced: Array[int] = []
	var announce := func(operation: int, _result: int) -> void: announced.append(operation)
	var answered: Array[int] = []
	var answer := func(operation: int, _kept: bool) -> void: answered.append(operation)
	EventBus.save_written.connect(announce)
	EventBus.save_deleted.connect(announce)
	EventBus.save_write_settled.connect(answer)
	EventBus.save_deletion_settled.connect(answer)
	_save.clear()
	var before := announced.size()
	_save.write(run, true)
	_save.clear()
	_save.write(run, false)
	announced = announced.slice(before)
	t.check(announced.size() == 3 and announced[0] < announced[1] and announced[1] < announced[2],
			"a write, a deletion and a write announce increasing ids from one sequence")
	var flushes := GameSave.Flushes.new()
	var write_flush := flushes.register(announced[0], Callable())
	var delete_flush := flushes.register(announced[1], Callable(), true)
	flushes.answer([float(delete_flush), ""])
	flushes.answer([float(write_flush), "lost"])
	t.check(answered == [delete_flush, write_flush], "each web answer carries its own change's id")
	EventBus.save_written.disconnect(announce)
	EventBus.save_deleted.disconnect(announce)
	EventBus.save_write_settled.disconnect(answer)
	EventBus.save_deletion_settled.disconnect(answer)
	_save.clear()

# ----------------------------------------------------------------- the symbol ---

## *"we should show it until it is fully confirmed saved"* — while a save is unanswered the symbol
## is fully shown and nothing counts down, however long the browser takes.
func _test_the_symbol_holds_with_no_timer_while_a_save_is_pending(t: TestRunner) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin(1)
	showing.advance(SaveIndicator.MIN_SHOWN_SECONDS + SaveIndicator.FADE_SECONDS + 10.0)
	t.check(showing.alpha() == 1.0, "a pending save stays fully shown past every minimum and the fade")
	t.check(not showing.struck, "and plain, since nothing has failed yet")

## *"okay always show it. but show it for at least a second"* — a desktop save is answered in the
## frame it begins, and the symbol still shows, fully, for a second and then fades.
func _test_a_save_answered_at_once_shows_for_a_second_then_fades(t: TestRunner) -> void:
	var showing := SaveIndicator.Showing.new()
	t.check(showing.is_idle() and showing.alpha() == 0.0, "nothing shows before a save")
	showing.begin(1)
	showing.settle(1, true)
	t.check(not showing.is_idle() and showing.alpha() == 1.0,
			"a save answered in the same call is shown from the start")
	showing.advance(0.99)
	t.check(showing.alpha() == 1.0, "fully shown at 0.99s")
	showing.advance(0.11)
	t.check(showing.alpha() > 0.0 and showing.alpha() < 1.0,
			"fading after the second, with no hold after the answer")
	showing.advance(1.41)
	t.check(showing.alpha() == 0.0 and showing.is_idle(), "gone by 2.51s")
	t.check(not showing.struck, "a kept save is never struck through")

## A pending save keeps the symbol up past the minimum, and the fade begins at the answer, not a
## hold later.
func _test_a_save_pending_three_seconds_fades_straight_after_its_answer(t: TestRunner) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin(1)
	showing.advance(1.0)
	t.check(showing.alpha() == 1.0, "fully shown when the minimum has run out but the save has not answered")
	showing.advance(2.0)
	t.check(showing.alpha() == 1.0, "and fully shown at 3s")
	showing.settle(1, true)
	t.check(showing.alpha() == 1.0, "the answer itself does not dim it")
	showing.advance(0.2)
	t.check(showing.alpha() > 0.0 and showing.alpha() < 1.0, "the fade begins straight away")
	showing.advance(SaveIndicator.FADE_SECONDS)
	t.check(showing.is_idle(), "and runs its 1.5s")

## Any change still unanswered keeps the symbol fully shown, an older one as much as the newest, so
## nothing still being written looks finished — even once the newest has answered and decided the
## picture.
func _test_any_unanswered_save_keeps_the_symbol_up(t: TestRunner) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin(1)
	showing.begin(2)
	showing.settle(2, true)
	showing.advance(SaveIndicator.MIN_SHOWN_SECONDS + SaveIndicator.FADE_SECONDS + 1.0)
	t.check(showing.alpha() == 1.0 and not showing.struck,
			"the newest answered and kept, the older still out: up, plain and untimed")
	showing.settle(1, true)
	showing.advance(0.2)
	t.check(showing.alpha() > 0.0 and showing.alpha() < 1.0, "the older answer lets it fade")
	var newest_out := SaveIndicator.Showing.new()
	newest_out.begin(1)
	newest_out.begin(2)
	newest_out.settle(1, true)
	newest_out.advance(SaveIndicator.MIN_SHOWN_SECONDS + SaveIndicator.FADE_SECONDS + 1.0)
	t.check(newest_out.alpha() == 1.0, "and the newest still out keeps it up the same way")
	newest_out.settle(2, true)
	newest_out.advance(0.2)
	t.check(newest_out.alpha() < 1.0, "until it answers")

## *"if it fails it show for at least 10s"* — however fast the failure came back, the struck
## picture is fully shown for ten seconds from the strike.
func _test_a_failure_answered_at_once_shows_struck_for_ten_seconds(t: TestRunner) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin(1)
	showing.settle(1, false)
	t.check(showing.struck, "a save not kept strikes the symbol at once")
	showing.advance(9.9)
	t.check(showing.struck and showing.alpha() == 1.0, "struck and fully shown at 9.9s")
	showing.advance(0.2)
	t.check(showing.struck and showing.alpha() > 0.0 and showing.alpha() < 1.0,
			"fading, still struck, after 10s")
	showing.advance(SaveIndicator.FADE_SECONDS)
	t.check(showing.is_idle() and not showing.struck, "gone, and the strike with it")

## A web flush that times out answers after 5s: the ten seconds count from the strike, so the
## struck picture itself is up until 15s.
func _test_a_failure_answered_after_five_seconds_is_struck_until_fifteen(t: TestRunner) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin(1)
	showing.advance(5.0)
	t.check(not showing.struck and showing.alpha() == 1.0, "plain and full while the flush is out")
	showing.settle(1, false)
	showing.advance(9.9)
	t.check(showing.struck and showing.alpha() == 1.0, "struck and fully shown at 14.9s")
	showing.advance(0.2)
	t.check(showing.struck and showing.alpha() < 1.0, "fading after 15s")

## A save beginning while the symbol fades brings it back to full with the second restarted; one
## beginning while it is already fully shown does not restart that clock.
func _test_a_save_beginning_mid_fade_restarts_the_second(t: TestRunner) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin(1)
	showing.settle(1, true)
	showing.advance(1.0 + SaveIndicator.FADE_SECONDS * 0.5)
	t.check(showing.alpha() > 0.0 and showing.alpha() < 1.0, "fading")
	showing.begin(2)
	t.check(showing.alpha() == 1.0, "a new save brings it back to full")
	showing.settle(2, true)
	showing.advance(0.99)
	t.check(showing.alpha() == 1.0, "full for a new second from the new save")
	showing.advance(0.02)
	t.check(showing.alpha() < 1.0, "and then fading")


func _test_a_save_beginning_while_fully_shown_does_not_restart_the_second(t: TestRunner) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin(1)
	showing.settle(1, true)
	showing.advance(0.6)
	showing.begin(2)
	showing.settle(2, true)
	showing.advance(0.5)
	t.check(showing.alpha() < 1.0, "1.1s after the symbol appeared it fades, the second save or not")
	var waiting := SaveIndicator.Showing.new()
	waiting.begin(1)
	waiting.settle(1, true)
	waiting.advance(0.6)
	waiting.begin(2)
	waiting.advance(5.0)
	t.check(waiting.alpha() == 1.0, "though the symbol still waits for the second save's answer")
	waiting.settle(2, true)
	waiting.advance(0.2)
	t.check(waiting.alpha() < 1.0, "and fades once it comes")

## *"an older success answered after a newer failure does not clear the strike"* (golden-otter) —
## the newest save failing while an older one is out strikes the picture at once, its ten seconds
## starting then, and the older one's later success leaves the strike where it is.
func _test_the_newest_failure_strikes_and_an_older_success_does_not_clear_it(t: TestRunner) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin(1)
	showing.begin(2)
	showing.advance(4.0)
	showing.settle(2, false)
	t.check(showing.struck and showing.pending == 1, "struck while the older save is unanswered")
	showing.advance(20.0)
	t.check(showing.struck and showing.alpha() == 1.0, "and held while that save is pending")
	showing.settle(1, true)
	t.check(showing.struck, "the older save's success, answered later, leaves it struck")
	showing.advance(0.2)
	t.check(showing.struck and showing.alpha() < 1.0, "fading, the ten seconds having run from the strike")
	var timed := SaveIndicator.Showing.new()
	timed.begin(1)
	timed.begin(2)
	timed.settle(2, false)
	timed.advance(4.0)
	timed.settle(1, true)
	timed.advance(5.9)
	t.check(timed.struck and timed.alpha() == 1.0, "ten seconds count from the strike, not the last answer")
	timed.advance(0.2)
	t.check(timed.alpha() < 1.0, "so it fades 10s after the strike")

## *"an older failure answered after a newer success does not strike the symbol"* (golden-otter) —
## nor does one answered while the newest is still out: an older save's failure decides nothing,
## and the symbol owes only the plain second.
func _test_an_older_failure_never_strikes(t: TestRunner) -> void:
	var after := SaveIndicator.Showing.new()
	after.begin(1)
	after.begin(2)
	after.settle(2, true)
	after.settle(1, false)
	t.check(not after.struck and after.pending == 0,
			"the older failure answered after the newer success leaves the symbol plain")
	after.advance(SaveIndicator.MIN_SHOWN_SECONDS + 0.1)
	t.check(after.alpha() < 1.0, "and it fades after its second, not ten")
	var before := SaveIndicator.Showing.new()
	before.begin(1)
	before.begin(2)
	before.settle(1, false)
	t.check(not before.struck and before.pending == 1 and before.alpha() == 1.0,
			"the older failure answered while the newest is out: plain and fully shown")
	before.settle(2, true)
	t.check(not before.struck, "and the newest kept leaves it plain")
	before.advance(SaveIndicator.MIN_SHOWN_SECONDS + 0.1)
	t.check(before.alpha() < 1.0, "fading after the second")

## Golden-otter statement 1 in all four shapes: whichever of two overlapping saves answers first,
## the picture is what the save started last came to.
func _test_only_the_newest_save_decides_in_either_order_of_arrival(t: TestRunner) -> void:
	for newest_kept: bool in [true, false]:
		for newest_first: bool in [true, false]:
			var showing := SaveIndicator.Showing.new()
			showing.begin(1)
			showing.begin(2)
			if newest_first:
				showing.settle(2, newest_kept)
				showing.settle(1, not newest_kept)
			else:
				showing.settle(1, not newest_kept)
				showing.settle(2, newest_kept)
			t.check(showing.struck == (not newest_kept) and showing.pending == 0,
					"the newest save %s, answered %s: the symbol is %s" % [
						"kept" if newest_kept else "not kept",
						"first" if newest_first else "last",
						"plain" if newest_kept else "struck"])

## Every failure of the newest save restarts the ten seconds.
func _test_each_failure_restarts_the_struck_clock(t: TestRunner) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin(1)
	showing.settle(1, false)
	showing.advance(6.0)
	showing.begin(2)
	showing.settle(2, false)
	showing.advance(9.9)
	t.check(showing.struck and showing.alpha() == 1.0, "the newest failure's ten seconds are running")
	showing.advance(0.2)
	t.check(showing.alpha() < 1.0, "and end ten seconds after it")

## *The strike follows the newest answer*: a newer save that was kept clears an earlier failure's
## strike, even with its ten seconds unspent, and the plain symbol then gets its own second.
func _test_a_kept_save_after_a_failed_one_clears_the_strike(t: TestRunner) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin(1)
	showing.settle(1, false)
	showing.advance(3.0)
	showing.begin(2)
	showing.settle(2, true)
	t.check(not showing.struck, "the strike clears though 7s of its ten were left")
	t.check(showing.alpha() == 1.0, "the symbol is still up for the moment")
	showing.advance(0.2)
	t.check(showing.alpha() < 1.0, "the plain symbol's second ran from when the symbol appeared")
	# Mid-fade, the new save restarts the second, which the plain symbol then owes.
	var fading := SaveIndicator.Showing.new()
	fading.begin(1)
	fading.settle(1, false)
	fading.advance(10.5)
	t.check(fading.struck and fading.alpha() < 1.0, "the struck picture is fading")
	fading.begin(2)
	fading.settle(2, true)
	t.check(not fading.struck and fading.alpha() == 1.0, "a kept save brings it back plain and full")
	fading.advance(0.99)
	t.check(fading.alpha() == 1.0, "for its own second")
	fading.advance(0.02)
	t.check(fading.alpha() < 1.0, "then fades")

## `begin()` does not clear the strike: a save still unanswered does not hide a known failure, and
## only its own answer decides.
func _test_begin_does_not_clear_a_strike_while_its_save_is_unanswered(t: TestRunner) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin(1)
	showing.settle(1, false)
	showing.advance(2.0)
	showing.begin(2)
	t.check(showing.struck and showing.alpha() == 1.0, "struck and full with the new save unanswered")
	showing.advance(30.0)
	t.check(showing.struck and showing.alpha() == 1.0, "and for as long as it stays unanswered")
	showing.settle(2, false)
	t.check(showing.struck, "a failed answer keeps the strike")
	showing.advance(9.9)
	t.check(showing.struck and showing.alpha() == 1.0, "with a fresh ten seconds")

## Once the symbol has faded away the strike is forgotten: the next save comes up plain.
func _test_a_struck_symbol_that_faded_away_is_forgotten(t: TestRunner) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin(1)
	showing.settle(1, false)
	showing.advance(10.0 + SaveIndicator.FADE_SECONDS + 0.1)
	t.check(showing.is_idle() and not showing.struck, "gone")
	showing.begin(2)
	t.check(not showing.struck and showing.alpha() == 1.0, "the next save comes up plain and full")
	showing.settle(2, true)
	t.check(not showing.struck, "and stays plain once kept")

## An answer to a save never begun here, or a second answer to one already settled, is ignored:
## it raises nothing, is not counted against the next save, and does not move the picture.
func _test_a_stray_answer_shows_nothing(t: TestRunner) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.settle(7, false)
	t.check(showing.is_idle() and showing.alpha() == 0.0,
			"an answer with no save begun raises nothing")
	showing.begin(8)
	t.check(showing.pending == 1, "and is not counted against the next save")
	showing.settle(7, true)
	t.check(showing.pending == 1, "nor is a later answer to that same save never begun")
	showing.settle(8, false)
	showing.settle(8, true)
	t.check(showing.struck, "a second answer to a save already answered changes nothing")

## The struck symbol is its own picture on the `ui` atlas (`art/ui/save_unavailable.svg`), swapped
## in for the plain one rather than drawn over it — so the region has to exist and be a different
## picture, and a kept save afterwards has to swap back.
func _test_a_save_not_kept_swaps_to_the_struck_picture(t: TestRunner) -> void:
	var indicator := SaveIndicator.new()
	t.add_child(indicator)
	var icon := indicator.find_child("Icon", true, false) as TextureRect
	var plain := icon.texture
	indicator.begin(1)
	indicator.settle(1, false)
	var struck := icon.texture
	t.check(plain != null and struck != null and struck != plain,
			"the plain and the struck pictures are both on the atlas, and different")
	t.check(Boot.save_symbol_struck(indicator), "a save not kept shows the struck picture")
	indicator.begin(2)
	t.check(Boot.save_symbol_struck(indicator), "a new save still unanswered does not hide the failure")
	indicator.settle(2, true)
	t.check(Boot.save_symbol_plain(indicator) and icon.texture == plain,
			"and a kept answer swaps back to the plain one")
	indicator.free()
