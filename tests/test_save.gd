extends RefCounted
## `GameSave`, and the two functions on `GameState` it reads and writes through
## (`save_snapshot()`/`restore_snapshot()`) — see docs/MECHANICS.md, "Saving and resuming". The
## checks that go through `main` (the title, the resume gate, the focus loss and the day-14
## hand-over) are in `tests/test_save_wiring.gd`.
##
## **Every test here points `GameSave` at a scratch file**, never `user://save.json`: a run whose
## `RunConfig` is headless (the runner's own) never saves (see
## `_test_uses_save_is_false_under_the_headless_runner()`), so the suite hands `GameSave.configure()`
## the configuration of a windowed release run for everything after the policy checks, and
## `set_path_override()` points that run's `write()`, `try_resume()` and `clear()` at the scratch
## file. The file format is exercised through those three, the calls the game itself makes.
##
## `run()` snapshots the live `GameState` first and restores it last, so this suite — which
## mutates nearly every field `GameState` owns — leaves nothing behind for a suite that runs
## after it in the same process.

const _SCRATCH_PATH := "user://test_save_scratch.json"

func run(t) -> void:
	var baseline := GameState.save_snapshot()
	GameSave.set_path_override(_SCRATCH_PATH)

	_test_uses_save_is_false_under_the_headless_runner(t)
	_test_debug_run_uses_save_policy(t)
	_test_no_save_query_parsing(t)
	_test_web_debug_flag_used_query_parsing(t)
	_test_gated_write_and_resume_touch_nothing_under_the_headless_runner(t)

	# From here on the run is a windowed release run, which saves; the scratch path keeps it off the
	# player's own file.
	GameSave.configure(_windowed_run())
	# A finished run leaves no save (`main` connects this at every boot); a suite that ends a run
	# connects it itself, so it holds whichever suite ran before this one.
	GameSave.clear_when_a_run_ends()
	GameSave.clear()

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

	_test_day_under_way_load_costs_one_nerve(t)
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
	_test_a_refused_save_leaves_the_symbol_dark(t)
	_test_a_desktop_save_shows_the_symbol_confirmed_at_once(t)
	_test_a_save_not_kept_swaps_to_the_struck_picture(t)

	GameSave.clear()
	GameSave.set_path_override("")
	GameSave.configure(null)
	GameState.restore_snapshot(baseline)
	# `restore_snapshot()` writes every field the *snapshot* carries, and the escape's own section,
	# the resistance's used alley tiles and the one fenced park are deliberately not among them —
	# see `RunSubState.Slot.RIDER` — so this suite has to put all three back by hand or the next
	# one starts in the middle of an escape with somebody else's used alleys and fenced park still on.
	GameState.facts.escape_section = DaySpec.Section.NONE
	GameState.facts.completed_resistance_alley_tiles.clear()
	GameState.facts.fenced_park = Vector2i(-1, -1)
	GameState.facts.fenced_park_act = 0
	GameState.calendar.hard_mode = false
	GameState.calendar.checkpoint = {}

## The configuration of a windowed run on a release build (or, with `args` and `query`, a debug one
## given those flags): the shape `main` hands `GameSave.configure()` outside a headless runner.
func _windowed_run(args := PackedStringArray(), query := "", debug_build := false) -> RunConfig:
	return RunConfig.parse(args, query, debug_build, false, {}, false)

## A run the headless runner itself would resolve: it never saves.
func _headless_run() -> RunConfig:
	return RunConfig.parse(PackedStringArray(), "", false)

## `GameState` written to the scratch file the way a game writes it. Whether the write was kept.
func _saved(day_under_way: bool) -> bool:
	return GameSave.write(GameState, day_under_way) == GameSave.Result.CONFIRMED

## Operation ids a test hands the bus or a flush table for changes of its own, larger for every
## change begun later, as `GameSave`'s own are.
var _operation := 1000

func _next_operation() -> int:
	_operation += 1
	return _operation

## The scratch file is put away around `callable`, so a test starts and leaves with no save.
func _with_a_scratch_save(callable: Callable) -> void:
	GameSave.clear()
	callable.call()
	GameSave.clear()

## `callable` run as the headless runner's own run would be: saving refused.
func _headless(callable: Callable) -> void:
	GameSave.configure(_headless_run())
	callable.call()
	GameSave.configure(_windowed_run())

# ---------------------------------------------------------------------- policy ---

func _test_uses_save_is_false_under_the_headless_runner(t) -> void:
	GameSave.configure(RunConfig.at_boot())
	t.check(RunConfig.at_boot().headless and not GameSave.uses_save(),
			"the headless test runner never reads or writes the real save")
	GameSave.configure(_headless_run())
	t.check(not GameSave.uses_save(), "nor does a headless release run, flags or no flags")
	GameSave.configure(null)
	t.check(not GameSave.uses_save(), "nor does a run nothing has configured yet")

func _test_debug_run_uses_save_policy(t) -> void:
	GameSave.configure(_windowed_run(PackedStringArray(), "", true))
	t.check(GameSave.uses_save(), "a flagless debug run uses the save")
	GameSave.configure(_windowed_run(PackedStringArray(["--seed", "1"]), "", true))
	t.check(not GameSave.uses_save(), "any dev flag disables it, by being a dev flag at all")
	GameSave.configure(_windowed_run(PackedStringArray(), "?nosave=1", true))
	t.check(not GameSave.uses_save(),
			"--no-save disables it even with nothing else on the command line")
	GameSave.configure(_windowed_run(PackedStringArray(["--seed", "1"]), "?nosave=1", true))
	t.check(not GameSave.uses_save(), "and the two reasons stack rather than fighting")
	GameSave.configure(_windowed_run())
	t.check(GameSave.uses_save(), "a windowed release run uses it")
	GameSave.configure(null)

func _test_no_save_query_parsing(t) -> void:
	t.check(not DevFlags.new(PackedStringArray(), "", true).no_save(),
			"an absent URL parameter changes nothing")
	t.check(not DevFlags.new(PackedStringArray(), "?nosave=0", true).no_save(),
			"nosave=0 leaves the save on")
	t.check(DevFlags.new(PackedStringArray(), "?nosave=1", true).no_save(), "?nosave=1 turns it off")
	t.check(DevFlags.new(PackedStringArray(), "?seed=1&nosave=1&day=2", true).no_save(),
			"the parameter is found among other URL parameters")

func _test_web_debug_flag_used_query_parsing(t) -> void:
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

func _test_gated_write_and_resume_touch_nothing_under_the_headless_runner(t) -> void:
	GameSave.configure(_windowed_run())
	GameSave.clear()
	GameSave.configure(_headless_run())
	t.check(GameSave.write(GameState, true) == GameSave.Result.REFUSED,
			"the gated write refuses under the headless runner")
	t.check(not GameSave.has_save(), "and leaves no file behind")
	GameSave.configure(_windowed_run())
	t.check(_saved(true), "while the run saves, the same write lands")
	GameSave.configure(_headless_run())
	t.check(GameSave.try_resume(GameState).is_empty(),
			"the gated resume also refuses, even with a real file sitting at the scratch path")
	t.check(GameSave.clear() == GameSave.Result.REFUSED,
			"the gated deletion refuses too")
	t.check(GameSave.has_save(), "and leaves the file where it was")
	GameSave.configure(_windowed_run())
	GameSave.clear()

# ------------------------------------------------------------------- round trip ---

## The guard the brief asks for: a field declared on `GameState` and saved by nothing fails here
## rather than quietly not being saved. A field is saved when the registered parts write a key of
## its name, or it is a part itself, or it is the calendar, whose mode and checkpoint ride at the
## top of the save beside `"day_under_way"` (`GameSave.file_data()`, held by
## `tests/test_run_checkpoints.gd`). (A part's own field is saved by its part, which
## `tests/test_run_state.gd` holds.)
## `PROPERTY_USAGE_SCRIPT_VARIABLE` is what separates a field this script declares from the base
## `Node` properties `get_property_list()` also reports (`name`, `process_mode`, and the rest).
func _test_round_trip_field_list_matches_the_property_list(t) -> void:
	var declared: Array[String] = []
	for property in GameState.get_property_list():
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			declared.append(property["name"])
	var written := GameState.run_parts.state_keys()
	written.append_array(GameState.run_parts.rider_data().keys())
	for name in declared:
		var value: Variant = GameState.get(name)
		if value is RunSubState or value is RunStateRegistry or value is RunCalendar:
			continue
		t.check(name in written,
				"'%s' is a GameState field the save format does not mention" % name)

## The run's play time is counted in physics ticks (inbox #866 in minty-dolphin) and saved as seconds
## (`to_data()`), so any save's seconds, whatever number they hold, load to the nearest tick, and
## a tick count is written back as its seconds.
func _test_play_time_is_saved_as_seconds_and_counted_in_ticks(t) -> void:
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
func _test_round_trip_preserves_every_field(t) -> void:
	GameState.start_run(778899)
	GameState.header.day = 6
	GameState.header.nerves = 3
	# The dawn the run stands at is photographed first, then the live work moves on from it, so the
	# file has to carry both.
	GameState.resistance.completed_steps = [0]
	GameState.resistance.failed_steps = []
	GameState.resistance.progress = 1
	GameState.resistance.sabotage_done = false
	GameState.resistance.carrying_package = false
	GameState.resistance.photograph()
	GameState.resistance.progress = 2
	GameState.header.ending = GameEnums.Ending.NONE
	GameState.header.play_ticks = 3704
	GameState.attempt_spend.consumed_one_shots = ["a_one_shot", "another_one_shot"]
	GameState.resistance.completed_steps = [0, 2]
	GameState.resistance.failed_steps = [1]
	GameState.attempt_spend.scars = [{"id": "fire", "position": Vector2(140.5, -30.25), "since_day": 4}]
	GameState.attempt_spend.city_state.reset()
	GameState.attempt_spend.city_state.apply_cause(
			{Vector2i(3, 4): _fake_block_plan()}, Vector2i(3, 4), GameEnums.BlockCause.FIRE, 6)
	GameState.resistance.sabotage_done = false
	GameState.resistance.carrying_package = true
	GameState.settled.settled_in = {5: Vector2i(-2, 7), 6: Vector2i(9, 9)}

	var written := GameState.save_snapshot()
	t.check(_saved(true), "the write reports success")
	var resume := GameSave.try_resume(GameState)
	t.check(resume.get("day_under_way", false) == true, "day_under_way round-trips as true")

	t.check(GameState.header.run_seed == 778899, "run_seed survives")
	t.check(GameState.header.day == 6, "day survives")
	t.check(GameState.header.nerves == 3, "nerves survives")
	t.check(GameState.resistance.progress == 2, "resistance_progress survives")
	t.check(GameState.header.play_ticks == 3704, "the play time survives to the tick, saved as seconds")
	t.check(GameState.attempt_spend.consumed_one_shots == ["a_one_shot", "another_one_shot"],
			"consumed_one_shots survives, string array and all")
	t.check(GameState.resistance.completed_steps == [0, 2], "completed_resistance_steps survives")
	t.check(GameState.resistance.failed_steps == [1], "failed_resistance_steps survives")
	t.check(GameState.attempt_spend.scars.size() == 1
			and GameState.attempt_spend.scars[0]["id"] == "fire"
			and (GameState.attempt_spend.scars[0]["position"] as Vector2).distance_to(Vector2(140.5, -30.25)) < 0.01
			and GameState.attempt_spend.scars[0]["since_day"] == 4,
			"a scar survives with its Vector2 position intact")
	t.check(GameState.attempt_spend.city_state.changed_on(Vector2i(3, 4)) == 6,
			"the city's own block-arc history survives — a fire that burned did happen")
	t.check(GameState.resistance.carrying_package == true, "resistance_carrying_package survives")
	t.check(GameState.settled.settled_in.get(5) == Vector2i(-2, 7)
			and GameState.settled.settled_in.get(6) == Vector2i(9, 9),
			"settled_in survives with its Vector2i values and integer day keys intact")
	t.check(GameState.save_snapshot() == written,
			"and the whole snapshot taken before the write matches the one read back after it")
	# The dawn snapshot, read through what it is for: a lost day gives it back.
	GameState.resistance.give_back()
	t.check(GameState.resistance.completed_steps == [0] and GameState.resistance.failed_steps.is_empty(),
			"the dawn snapshot's own steps survive")
	t.check(GameState.resistance.progress == 1, "the dawn's progress survives")
	t.check(not GameState.resistance.sabotage_done and not GameState.resistance.carrying_package,
			"and the dawn's sabotage and package")

## Player, 2026-09-27: *"a won day recovers a nerve up to the max"*. `nerves` was already carried by
## the snapshot's keys, but the count it carries now has to be the one a win just gave back, not the one
## a save taken before the change would have written — this writes the file only after the gain and
## wipes the live count before reading it back, so a save that quietly dropped the regained nerve
## rather than the round trip itself is what would fail this.
func _test_a_won_days_regained_nerve_survives_a_round_trip(t) -> void:
	GameState.start_run(240927)
	GameState.header.nerves = 3
	GameState.calendar.finish_day(GameEnums.DayResult.WON)
	t.check(GameState.header.nerves == 4, "winning regains a nerve before the save is even written")

	t.check(_saved(true), "the write reports success")
	GameState.header.nerves = 0
	GameSave.try_resume(GameState)
	t.check(GameState.header.nerves == 4, "and the regained count is what loading the save gives back")

## The smallest fake `BlockPlan`-shaped dictionary `CityState.apply_cause()` needs to take a
## `FIRE` step — a `Dictionary` because `CityState` reads `plan.steps`, not a real `BlockPlan`
## resource, and this suite has no city to build one from.
func _fake_block_plan() -> BlockPlan:
	var plan := BlockPlan.new()
	plan.steps = [
		BlockPlan.Step.new(GameEnums.BlockPurpose.RESIDENTIAL, 1, GameEnums.BlockCause.SCHEDULED),
		BlockPlan.Step.new(GameEnums.BlockPurpose.BURNT_OUT, 1, GameEnums.BlockCause.FIRE),
	]
	return plan

# ----------------------------------------------------------------- dropped saves ---

func _test_missing_file_is_dropped(t) -> void:
	GameSave.clear()
	t.check(GameSave.try_resume(GameState).is_empty(), "no file at all resumes nothing")

func _test_garbled_text_is_dropped(t) -> void:
	var before := GameState.save_snapshot()
	_write_raw("not valid json at all {{{")
	t.check(GameSave.try_resume(GameState).is_empty(), "text that is not valid JSON resumes nothing")
	t.check(GameState.save_snapshot() == before, "and GameState is left exactly as it was")

func _test_wrong_format_version_is_dropped(t) -> void:
	var before := GameState.save_snapshot()
	_write_raw(JSON.stringify({
		"format_version": GameSave.FORMAT_VERSION + 1,
		"build": "some other build",
		"day_under_way": true,
		"state": GameState.save_snapshot(),
	}))
	t.check(GameSave.try_resume(GameState).is_empty(),
			"a save this build's own format version does not match resumes nothing")
	t.check(GameState.save_snapshot() == before, "and GameState is untouched by trying")

func _test_incomplete_state_is_dropped(t) -> void:
	var before := GameState.save_snapshot()
	var state := GameState.save_snapshot()
	state.erase("nerves")
	_write_raw(JSON.stringify({
		"format_version": GameSave.FORMAT_VERSION,
		"build": "some build",
		"day_under_way": true,
		"state": state,
	}))
	t.check(GameSave.try_resume(GameState).is_empty(),
			"a state missing a field this build writes resumes nothing rather than half-loading")
	t.check(GameState.save_snapshot() == before, "and GameState is untouched by trying")

func _write_raw(text: String) -> void:
	var file := FileAccess.open(_SCRATCH_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _test_clear_deletes_the_file(t) -> void:
	_with_a_scratch_save(func() -> void:
		var answers := _Answers.new()
		t.check(GameSave.clear(answers.take) == GameSave.Result.REFUSED,
				"with no file there is nothing to delete, which changes nothing")
		t.check(_saved(true), "a write lands")
		t.check(GameSave.has_save(), "and the file exists")
		t.check(GameSave.clear(answers.take) == GameSave.Result.CONFIRMED,
				"deleting it off the web is confirmed at once")
		t.check(not GameSave.has_save(), "clear() removes it")
		t.check(GameSave.clear(answers.take) == GameSave.Result.REFUSED,
				"clearing an already-absent save changes nothing and answers refused")
		t.check(answers.results.is_empty(), "and nothing is left for a later answer to settle")
	)
	t.check(not GameSave.has_save(), "putting away a file that is not there is already done")

func _test_write_refuses_once_the_run_has_ended(t) -> void:
	GameSave.clear()
	var ending := GameState.header.ending
	GameState.header.ending = GameEnums.Ending.BAD
	t.check(not _saved(true), "a write refuses once the run has an ending")
	t.check(not GameSave.has_save(), "and touches no file at all")
	GameState.header.ending = ending

## Closing the game inside a section of the escape and opening it again comes back to that
## section's own brief, which is `GameState.facts.escape_section` surviving the file — the same
## mechanism a day under way already rides on, and deliberately the same one rather than a second
## save path beside it.
func _test_the_escape_section_survives_a_round_trip(t) -> void:
	GameState.start_run(313131)
	GameState.header.day = Tuning.RUN_LENGTH_DAYS
	GameState.facts.escape_section = DaySpec.Section.CITY
	t.check(_saved(false), "a section of the escape writes a save")
	# Wiped the way a fresh process would find it, so what is read back has to come off the file.
	GameState.start_run(1)
	t.check(GameState.facts.escape_section == DaySpec.Section.NONE,
			"a fresh run is in no section (the check below would pass vacuously otherwise)")
	t.check(not GameSave.try_resume(GameState).is_empty(), "and the file resumes")
	t.check(GameState.facts.escape_section == DaySpec.Section.CITY,
			"onto the section it was closed in, not the start of the escape")
	t.check(GameState.header.run_seed == 313131, "with the run it belonged to")
	GameSave.clear()

## **A save written before the escape was a run's ending still loads.** `"escape_section"` is a
## top-level key rather than a field of the run snapshot exactly so this holds: a file with no
## mention of it at all is a complete save (`GameState.snapshot_is_complete()` asks only about
## `"state"`) and resumes to a run in no section, which is every one of the fourteen days.
##
## The payload is assembled here rather than pasted from a real old file, so it stays a save of
## *this* build's snapshot shape with only the new key missing — which is the thing that has to
## keep working, and the only part of an older file that differs.
func _test_a_save_from_before_the_escape_still_loads(t) -> void:
	GameState.start_run(424242)
	GameState.header.day = 9
	GameState.header.nerves = 3
	var old_shape := JSON.stringify({
		"format_version": GameSave.FORMAT_VERSION,
		"build": "a build from before the escape",
		"day_under_way": true,
		"state": GameState.save_snapshot(),
	})
	t.check(not old_shape.contains("escape_section"),
			"the payload really is one with no escape section in it")
	GameState.start_run(1)
	GameState.facts.escape_section = DaySpec.Section.BUILDING
	_write_raw(old_shape)
	var resumed := GameSave.try_resume(GameState)
	t.check(not resumed.is_empty(), "a save with no escape section still resumes")
	t.check(GameState.header.run_seed == 424242 and GameState.header.day == 9 and GameState.header.nerves == 3,
			"with every field it does carry")
	t.check(bool(resumed.get("day_under_way", false)),
			"and the day-under-way flag beside it, unchanged")
	t.check(GameState.facts.escape_section == DaySpec.Section.NONE,
			"and the run is in no section, rather than keeping whatever was in memory")
	GameSave.clear()

## The same mechanism `escape_section` rides on, for the alley tiles the resistance has already
## used this run (M177) — closing the game between days must not hand the next mark back every
## alley to choose from again.
func _test_completed_resistance_alley_tiles_survive_a_round_trip(t) -> void:
	GameState.start_run(515151)
	GameState.facts.completed_resistance_alley_tiles = [Vector2i(4, 9), Vector2i(-2, 15)]
	t.check(_saved(false), "a run with used alley tiles writes a save")
	GameState.start_run(1)
	t.check(GameState.facts.completed_resistance_alley_tiles.is_empty(),
			"a fresh run has recorded none (the check below would pass vacuously otherwise)")
	t.check(not GameSave.try_resume(GameState).is_empty(), "and the file resumes")
	t.check(GameState.facts.completed_resistance_alley_tiles == [Vector2i(4, 9), Vector2i(-2, 15)],
			"onto the tiles it was closed with, Vector2i values and all")
	GameSave.clear()

## Expiring the physical fence cannot reopen the once-per-run choice, including after a reload.
func _test_an_expired_fence_survives_a_round_trip(t) -> void:
	GameState.start_run(14040)
	GameState.facts.fenced_park = Vector2i(6, 8)
	GameState.facts.fenced_park_act = 3
	GameState.header.day = 12
	GameState.facts.remember_fenced_park(Vector2i(-1, -1), 0)
	t.check(_saved(false), "the act-boundary run writes a save")
	GameState.start_run(1)
	t.check(not GameSave.try_resume(GameState).is_empty(), "the act-boundary save resumes")
	t.check(GameState.facts.fenced_park == Vector2i(6, 8) and GameState.facts.fenced_park_act == 3,
			"reloading after expiry remembers the original fence")
	var map := CityGenerator.generate(GameState.header.run_seed)
	var state := CityState.new()
	state.begin_day(map.block_plans, 13)
	map.repaint(state)
	var used: Array[Vector2i] = [map.calm_blocks[0]]
	map.set_spent_calm(used)
	map.set_fenced_park_state(GameState.facts.fenced_park, GameState.facts.fenced_park_act, 4)
	map.repaint(state)
	t.check(not map.shut_calm.is_empty(), "the resumed act has an accepted used area")
	t.check(map.fenced_park == Vector2i(-1, -1),
			"the resumed run cannot select a second fence in act IV")
	GameSave.clear()

## **A save written before this field existed still loads**, the same reasoning
## `_test_a_save_from_before_the_escape_still_loads()` holds for `escape_section`: a file with no
## mention of it is a complete save and resumes with nothing recorded, by absence.
func _test_a_save_from_before_the_alley_tiles_still_loads(t) -> void:
	GameState.start_run(626262)
	var old_shape := JSON.stringify({
		"format_version": GameSave.FORMAT_VERSION,
		"build": "a build from before this field",
		"day_under_way": true,
		"escape_section": GameState.facts.escape_section,
		"state": GameState.save_snapshot(),
	})
	t.check(not old_shape.contains("completed_resistance_alley_tiles"),
			"the payload really is one with no alley tiles recorded in it")
	GameState.start_run(1)
	GameState.facts.completed_resistance_alley_tiles = [Vector2i(7, 7)]
	_write_raw(old_shape)
	var resumed := GameSave.try_resume(GameState)
	t.check(not resumed.is_empty(), "a save with no alley tiles still resumes")
	t.check(GameState.facts.completed_resistance_alley_tiles.is_empty(),
			"and the list is empty, rather than keeping whatever was in memory")
	GameSave.clear()

## The same mechanism `escape_section` rides on, for the one calm area this run has fenced (M129) —
## closing the game mid-act must not let a second park get fenced on reopening, which is exactly
## what forgetting `fenced_park` on reload would do.
func _test_the_fenced_park_survives_a_round_trip(t) -> void:
	GameState.start_run(535353)
	GameState.facts.fenced_park = Vector2i(6, 9)
	GameState.facts.fenced_park_act = 3
	t.check(_saved(false), "a run with a fenced park writes a save")
	GameState.start_run(1)
	t.check(GameState.facts.fenced_park == Vector2i(-1, -1),
			"a fresh run has fenced none (the check below would pass vacuously otherwise)")
	t.check(not GameSave.try_resume(GameState).is_empty(), "and the file resumes")
	t.check(GameState.facts.fenced_park == Vector2i(6, 9) and GameState.facts.fenced_park_act == 3,
			"onto the same park and the same act it was closed with")
	GameSave.clear()

## **A save written before this field existed still loads**, the same reasoning
## `_test_a_save_from_before_the_escape_still_loads()` holds for `escape_section`: a file with no
## mention of it is a complete save and resumes with no park fenced, by absence — the same state a
## run that has not reached act III yet is already in, so nothing forces a second fence later.
func _test_a_save_from_before_the_fenced_park_still_loads(t) -> void:
	GameState.start_run(646464)
	var old_shape := JSON.stringify({
		"format_version": GameSave.FORMAT_VERSION,
		"build": "a build from before this field",
		"day_under_way": true,
		"escape_section": GameState.facts.escape_section,
		"state": GameState.save_snapshot(),
	})
	t.check(not old_shape.contains("fenced_park"),
			"the payload really is one with no fenced park recorded in it")
	GameState.start_run(1)
	GameState.facts.fenced_park = Vector2i(3, 3)
	GameState.facts.fenced_park_act = 2
	_write_raw(old_shape)
	var resumed := GameSave.try_resume(GameState)
	t.check(not resumed.is_empty(), "a save with no fenced park still resumes")
	t.check(GameState.facts.fenced_park == Vector2i(-1, -1) and GameState.facts.fenced_park_act == 0,
			"and none is fenced, rather than keeping whatever was in memory")
	GameSave.clear()

## **The pelican bag's count survives the file, and a save from before it loads at 0.** `pelican`
## rides at the top level beside `posters`, for the same reason.
func _test_the_pelican_bags_count_survives_a_round_trip_and_an_old_save_loads_at_0(t) -> void:
	GameState.start_run(656565)
	GameState.pelican.draws = 9
	GameState.pelican.photograph()
	GameState.pelican.draws = 12
	var data := GameState.run_parts.run_data()
	GameState.pelican.reset()
	GameState.run_parts.restore_run_data(data)
	t.check(GameState.pelican.draws == 12, "a save keeps the pelican bag's count (%d)"
			% GameState.pelican.draws)
	GameState.pelican.give_back()
	t.check(GameState.pelican.draws == 9, "and the dawn's, so a lost day after a resume goes back")
	GameState.pelican.draws = 12
	var old: Dictionary = data.duplicate(true)
	old.erase("pelican")
	GameState.run_parts.restore_run_data(old)
	t.check(GameState.pelican.draws == 0,
			"a save written before the bag loads at 0 over a run with a count (%d)"
			% GameState.pelican.draws)

## **The walls survive the file, and a save from before there were posters loads with none up.**
## `posters` rides at the top level for the reason `escape_section` does.
func _test_the_posters_survive_a_round_trip(t) -> void:
	GameState.start_run(646464)
	GameState.posters.paste(Vector2i(5, 6), PosterArt.Kind.LEADER, false, 1)
	GameState.posters.photograph()
	GameState.posters.tear(Vector2i(5, 6), 1)
	GameState.posters.tears = 1
	GameState.posters.pasted_through = 4
	var written := GameState.posters.to_data()
	t.check(_saved(false), "a run with posters writes")
	GameState.posters.reset()
	GameSave.try_resume(GameState)
	t.check(GameState.posters.to_data() == written,
			"the walls, the tear count and the photograph a lost day gives back all survive")
	var old_shape := JSON.stringify({
		"format_version": GameSave.FORMAT_VERSION,
		"build": "a build from before the posters",
		"day_under_way": false,
		"state": GameState.save_snapshot(),
	})
	_write_raw(old_shape)
	GameSave.try_resume(GameState)
	t.check(GameState.posters.cells.is_empty() and GameState.posters.pasted_through == 0,
			"a save with no posters in it loads with bare walls")
	GameSave.clear()

## **A save from before a task was one day still loads.** `pending_resistance_brief` and
## `_dawn_brief` are gone from `GameState` (M181, the resistance has a reason, and a task is one
## day: the day brief carries no task and no mark's words, so nothing reads them back any more) —
## removed rather than added, so `snapshot_is_complete()` only ever asks for a field this build
## still names, and an older file naming two more than that still has every one of them.
## `completed_resistance_steps` from an old run names indices out of the old two-beat table, which
## no longer exists in that shape: `ResistanceSteps.by_index()` answers null for anything the new
## one-task-per-day table does not have at that index, which `GameState` and `ResistanceDirector`
## already treat as nothing, so the resumed run simply offers whatever the new table's own
## `for_day()` finds for the day it resumes on.
func _test_a_save_from_before_a_task_was_one_day_still_loads(t) -> void:
	GameState.start_run(636363)
	GameState.header.day = 7
	GameState.header.nerves = 4
	GameState.resistance.completed_steps = [1, 2, 3]
	GameState.resistance.progress = 1
	var snapshot := GameState.save_snapshot()
	snapshot["pending_resistance_brief"] = "meet at the fountain"
	snapshot["_dawn_brief"] = "an earlier brief"
	var old_shape := JSON.stringify({
		"format_version": GameSave.FORMAT_VERSION,
		"build": "a build from before a task was one day",
		"day_under_way": true,
		"state": snapshot,
	})
	GameState.start_run(1)
	_write_raw(old_shape)
	var resumed := GameSave.try_resume(GameState)
	t.check(not resumed.is_empty(), "a save naming the old brief fields still resumes")
	t.check(GameState.header.run_seed == 636363 and GameState.header.day == 7 and GameState.header.nerves == 4,
			"with every field the new build still reads")
	t.check(GameState.resistance.completed_steps == [1, 2, 3],
			"and its old-table step indices, carried over rather than dropped")
	GameSave.clear()

# ------------------------------------------------------------- the lost-day path ---

## What `main._ready()` does with a `day_under_way: true` resume: apply `GameState.calendar.finish_day()`
## with a non-`WON` result, the same call an ordinary lost day makes. One nerve, the day's own
## resistance work undone, the same day again.
func _test_day_under_way_load_costs_one_nerve(t) -> void:
	GameState.start_run(55)
	GameState.header.day = 4
	GameState.header.nerves = 5
	GameState.calendar.begin_day()
	# Progress made during the attempt that is about to be "left" — the dawn snapshot above this
	# does not carry it, so a loss has something real to give back.
	GameState.complete_resistance_step(0)
	t.check(GameState.resistance.progress == 1, "the attempt made progress before being saved")

	var resume := {"day_under_way": true}
	var continues := GameState.calendar.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)

	t.check(continues, "a nerve was spent, not the last one, so the run goes on")
	t.check(GameState.header.nerves == 4, "exactly one nerve is spent")
	t.check(GameState.header.day == 4, "the same day is offered again, not the next one")
	t.check(GameState.resistance.progress == 0,
			"the resistance work the attempt did is given back, the same as any other lost day")
	t.check(resume["day_under_way"], "the resume dict this all hangs off of is the one asserted")

## **A run closed mid-day gives back what that day burned, through the same path an ordinary loss
## takes.** `main._ready()` hands a save written with `day_under_way` to `GameState.calendar.finish_day()` as
## a hard fail, so the whole of the give-back has to survive the file: the photograph of what the
## attempt may spend rides in the snapshot beside the resistance's, or a day 3 closed after the
## fire burned would come back with the fire spent, a shell standing and no fire owed on the retry.
##
## The round trip is the point, so the state is written, wiped to something else, and read back
## before the day is lost — a check that never left memory would pass with the three fields missing
## from the save entirely.
func _test_a_day_under_way_gives_back_the_fire_it_lit(t) -> void:
	GameState.start_run(59)
	GameState.header.day = Tuning.RUN_TAUGHT_DAY
	GameState.header.nerves = 3
	GameState.calendar.begin_day()
	GameState.attempt_spend.consumed_one_shots.append("burning_building")
	GameState.add_scar("burnt_shell", Vector2(640.0, 640.0))
	t.check(_saved(true), "the run is saved with the day under way and the fire lit")

	# Wiped to a different run entirely, so what comes back can only have come out of the file.
	GameState.start_run(60)
	var resume := GameSave.try_resume(GameState)
	t.check(resume.get("day_under_way") == true, "the save says a day was under way")
	t.check("burning_building" in GameState.attempt_spend.consumed_one_shots and GameState.attempt_spend.scars.size() == 1,
			"and it comes back with the fire spent and its shell standing, as the attempt left it")

	GameState.calendar.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)
	t.check(not "burning_building" in GameState.attempt_spend.consumed_one_shots,
			"losing the resumed day owes the fire again")
	t.check(GameState.attempt_spend.scars.is_empty(),
			"and takes the shell down with it, the same as any other lost day")

## In hard mode the last nerve ends the run exactly as it does when a day is lost by playing it out —
## and the ending clears the save, since there is nothing left to resume.
func _test_day_under_way_load_on_the_last_nerve_ends_the_run(t) -> void:
	GameSave.clear_when_a_run_ends()
	GameState.start_run(56)
	GameState.calendar.choose_mode(true)
	GameState.header.day = 9
	GameState.header.nerves = 1
	GameState.calendar.begin_day()
	_with_a_scratch_save(func() -> void:
		t.check(_saved(true), "a save exists before the last nerve is spent")

		var continues := GameState.calendar.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)

		t.check(not continues, "the run does not go on")
		t.check(GameState.header.nerves == 0, "the last nerve is gone")
		t.check(GameState.header.ending == GameEnums.Ending.BAD,
				"the bad ending, the same as any other run out")
		t.check(not GameSave.has_save(), "and the save that named the run is gone with it")
	)
	GameState.header.ending = GameEnums.Ending.NONE

## The same load in a normal run goes back to its checkpoint instead, through the same call: the run
## goes on, standing at the checkpoint's dawn with every nerve, and the save is still there to be
## written over by the dawn `main._write_dawn_for_a_resumed_run()` writes next.
func _test_day_under_way_load_on_a_normal_runs_last_nerve_goes_back(t) -> void:
	GameState.start_run(57)
	GameState.header.day = 8
	GameState.header.nerves = 2
	GameState.calendar.begin_day()
	t.check(GameState.calendar.checkpoint_day() == 8, "day 8's dawn is the run's checkpoint")
	GameState.calendar.finish_day(GameEnums.DayResult.WON)
	GameState.calendar.begin_day()
	GameState.header.nerves = 1
	_with_a_scratch_save(func() -> void:
		t.check(_saved(true), "the mid-day save on day 9, one nerve left")
		GameState.start_run(58)
		var resume := GameSave.try_resume(GameState)
		t.check(resume.get("day_under_way") == true and GameState.calendar.checkpoint_day() == 8,
				"the save comes back under way, its checkpoint with it")
		t.check(GameState.calendar.a_loss_goes_back_to_the_checkpoint(),
				"and losing the day it was left on goes back")
		var continues := GameState.calendar.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)
		t.check(continues and GameState.header.ending == GameEnums.Ending.NONE,
				"the run goes on rather than ending")
		t.check(GameState.header.day == 8 and GameState.header.nerves == Tuning.STARTING_NERVES,
				"back at day 8 with every nerve")
		t.check(GameSave.has_save(), "and the save is not deleted")
	)

## A save written before there were two modes or checkpoints — no `hard_mode` key, no `checkpoint`
## key — loads as a normal run whose checkpoint is day 1 of its own city, and `FORMAT_VERSION` is
## what it always was.
func _test_a_save_from_before_checkpoints_still_loads(t) -> void:
	GameState.start_run(59)
	GameState.header.day = 10
	t.check(_saved(false), "a save is written")
	var file := FileAccess.open(_SCRATCH_PATH, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	data.erase("hard_mode")
	data.erase("checkpoint")
	_write_raw(JSON.stringify(data))
	GameState.calendar.choose_mode(true)
	GameState.calendar.checkpoint = {"state": {"day": 4}}
	var resume := GameSave.try_resume(GameState)
	t.check(not resume.is_empty() and GameState.header.day == 10, "it still loads, on its own day")
	t.check(not GameState.calendar.hard_mode, "as a normal run")
	t.check(GameState.calendar.checkpoint.is_empty() and GameState.calendar.checkpoint_day() == 1,
			"whose checkpoint is checkpoint zero, day 1")

## The mode and the checkpoint survive a save, and a checkpoint this build could not give back is
## dropped for checkpoint zero rather than half-applied later.
func _test_the_mode_and_the_checkpoint_survive_a_round_trip(t) -> void:
	GameState.start_run(60)
	GameState.header.day = 4
	GameState.calendar.begin_day()
	t.check(GameState.calendar.checkpoint_day() == 4, "day 4's dawn is kept")
	GameState.calendar.finish_day(GameEnums.DayResult.WON)
	t.check(_saved(false), "a save is written")
	var kept := GameState.calendar.checkpoint.duplicate(true)
	GameState.start_run(61)
	GameSave.try_resume(GameState)
	t.check(GameState.calendar.checkpoint_day() == 4 and not GameState.calendar.hard_mode,
			"a normal run comes back with its day 4 checkpoint")
	t.check(int((GameState.calendar.checkpoint["state"] as Dictionary)["run_seed"])
			== int((kept["state"] as Dictionary)["run_seed"]),
			"the checkpoint read back is the one written")

	GameState.calendar.choose_mode(true)
	t.check(_saved(false), "a hard run's save is written")
	GameState.start_run(62)
	GameSave.try_resume(GameState)
	t.check(GameState.calendar.hard_mode and GameState.calendar.checkpoint.is_empty(),
			"a hard run comes back hard, with no checkpoint")

	GameState.start_run(63)
	GameState.calendar.checkpoint = {"state": {"day": 8}}
	t.check(_saved(false), "a save carrying a checkpoint with a broken snapshot")
	GameSave.try_resume(GameState)
	t.check(GameState.calendar.checkpoint.is_empty(),
			"falls back to checkpoint zero rather than keeping what it could not give back")

## A save written at a day's own summary (`day_under_way: false`) is never handed to
## `GameState.calendar.finish_day()` at all in `main._ready()` — asserted here as the shape of the contract
## the two booleans below make untestable any other way: nerves and day both hold whatever the
## save itself named, because nothing here ever touches them.
func _test_summary_load_costs_nothing(t) -> void:
	GameState.start_run(57)
	GameState.header.day = 8
	GameState.header.nerves = 4
	t.check(_saved(false), "a save is written at a day's own summary")
	var resume := GameSave.try_resume(GameState)
	t.check(resume.get("day_under_way") == false, "it comes back false")
	t.check(GameState.header.day == 8 and GameState.header.nerves == 4,
			"nothing about the run changes on a load this function never spends a nerve on")

## The ordering the commit message states: after the load-time penalty is applied, the very next
## write (`main._start_day()`'s own dawn write, made before the resumed pause screen can even be
## looked at) already reflects the spent nerve *and* writes the fresh dawn as not yet under way —
## since nothing has happened in it yet. A second close-and-reopen before ever touching that screen
## therefore finds `day_under_way: false` and costs nothing more.
func _test_double_load_does_not_charge_twice(t) -> void:
	GameState.start_run(58)
	GameState.header.day = 5
	GameState.header.nerves = 5
	GameState.calendar.begin_day()
	t.check(_saved(true), "the first save: a day left mid-way")

	var first := GameSave.try_resume(GameState)
	t.check(first.get("day_under_way") == true, "the first load finds a day under way")
	GameState.calendar.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)
	t.check(GameState.header.nerves == 4, "the first load costs its one nerve")
	# `main._ready()`'s own write for the resumed, unplayed retry — a title, and then a day brief,
	# both stand between this and the player actually taking control, so this is what it writes
	# before either is ever shown.
	t.check(_saved(false), "the fresh dawn is saved before the title is shown")

	var second := GameSave.try_resume(GameState)
	t.check(second.get("day_under_way") == false,
			"a second close before pressing continue on the day brief finds nothing under way")
	# The caller (`main._ready()`) would not call `finish_day()` at all on this result — nothing
	# here does either, so an unchanged nerve count is the whole of the assertion.
	t.check(GameState.header.nerves == 4, "and so the second load does not spend a second nerve")

func _test_either_ending_clears_the_save(t) -> void:
	GameSave.clear_when_a_run_ends()
	GameState.start_run(59)
	GameState.header.day = 3
	GameState.header.nerves = 2
	_with_a_scratch_save(func() -> void:
		t.check(_saved(true), "a save exists")
		GameState.calendar.finish_day(GameEnums.DayResult.WON)
		t.check(GameState.header.ending == GameEnums.Ending.NONE,
				"day 3 of a run this short does not end it")
		t.check(GameSave.has_save(), "so the save is untouched")

		GameState.header.day = Tuning.RUN_LENGTH_DAYS
		GameState.calendar.begin_day()
		t.check(_saved(true), "a save exists for the final day")
		GameState.calendar.finish_day(GameEnums.DayResult.WON)
		t.check(GameState.header.ending != GameEnums.Ending.NONE, "winning the final day ends the run")
		t.check(not GameSave.has_save(), "and a won run clears the save exactly as a lost one does")
	)
	# An ended run refuses every later write, including the next test's.
	GameState.header.ending = GameEnums.Ending.NONE

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
func _test_a_save_moment_answers_by_platform_and_storage(t) -> void:
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
func _test_a_desktop_write_is_confirmed_at_once(t) -> void:
	_with_a_scratch_save(func() -> void:
		var answers := _Answers.new()
		var result: int = GameSave.write(GameState, true, answers.take)
		t.check(result == GameSave.Result.CONFIRMED, "a desktop write is confirmed at once")
		t.check(GameSave.has_save(), "and the file is there")
		t.check(answers.results.is_empty(), "with nothing left for a later answer to settle")
	)

func _test_a_refused_or_ended_run_is_not_a_failed_save(t) -> void:
	var answers := _Answers.new()
	_headless(func() -> void:
		t.check(GameSave.write(GameState, true, answers.take) == GameSave.Result.REFUSED,
				"the headless runner's refused save is refused, not failed")
	)
	_with_a_scratch_save(func() -> void:
		var ending := GameState.header.ending
		GameState.header.ending = GameEnums.Ending.BAD
		t.check(GameSave.write(GameState, true, answers.take) == GameSave.Result.REFUSED,
				"a run with an ending is refused, not failed")
		t.check(not GameSave.has_save(), "and writes nothing")
		GameState.header.ending = ending
	)
	t.check(answers.results.is_empty(), "neither ever answers later")

func _test_a_flush_settles_once_whichever_answer_comes_first(t) -> void:
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

func _test_a_flush_whose_listener_is_gone_settles_quietly(t) -> void:
	var flushes := GameSave.Flushes.new()
	var gone := Node.new()
	var token := flushes.register(_next_operation(), Callable(gone, &"set_name"))
	gone.free()
	flushes.answer([float(token), ""])
	t.check(flushes.is_empty(), "the flush is settled without calling anything")

# ---------------------------------------------------------------- deletions ---

func _test_a_deletion_flush_settles_through_the_bus_and_a_write_flush_does_not(t) -> void:
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

func _test_a_deletion_flush_whose_listener_is_gone_settles_quietly(t) -> void:
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

func _test_one_huge_frame_does_not_time_a_flush_out(t) -> void:
	var steps := int(GameSave.FLUSH_TIMEOUT_SECONDS / GameSave.MAX_FLUSH_STEP_SECONDS)
	# An hour between two frames counts as one clamped step: it is as far along as `steps - 1` more
	# clamped steps leave it one short of the timeout, and the next one reaches it.
	var hour := GameSave.Flushes.new()
	var hour_answers := _Answers.new()
	var hour_token := hour.register(_next_operation(), hour_answers.take)
	hour.advance(3600.0)
	for i in steps - 2:
		hour.advance(GameSave.MAX_FLUSH_STEP_SECONDS)
	t.check(hour.waits_for(hour_token) and hour_answers.results.is_empty(),
			"an hour between two frames counts as one clamped step")
	hour.advance(GameSave.MAX_FLUSH_STEP_SECONDS)
	t.check(hour_answers.results == [GameSave.Result.FAILED], "and not as more than one")
	# An ordinary frame counts as itself: an eighth of a second, forty times, is the timeout.
	var ordinary := GameSave.Flushes.new()
	var ordinary_token := ordinary.register(_next_operation(), Callable())
	var frame := 0.125
	var frames := int(GameSave.FLUSH_TIMEOUT_SECONDS / frame)
	for i in frames - 1:
		ordinary.advance(frame)
	t.check(ordinary.waits_for(ordinary_token), "an ordinary frame counts as itself: one short, it waits")
	ordinary.advance(frame)
	t.check(not ordinary.waits_for(ordinary_token), "and the last one reaches the timeout")
	# A clock that went backwards counts as nothing.
	var backwards := GameSave.Flushes.new()
	var backwards_token := backwards.register(_next_operation(), Callable())
	for i in 100:
		backwards.advance(-1.0)
	for i in steps - 1:
		backwards.advance(GameSave.MAX_FLUSH_STEP_SECONDS)
	t.check(backwards.waits_for(backwards_token),
			"a clock that went backwards counts as nothing: it neither adds nor takes back time")
	backwards.advance(GameSave.MAX_FLUSH_STEP_SECONDS)
	t.check(not backwards.waits_for(backwards_token), "so the timeout comes on the step it always did")
	var flushes := GameSave.Flushes.new()
	var write_answers := _Answers.new()
	var delete_answers := _Answers.new()
	var write_token := flushes.register(_next_operation(), write_answers.take)
	var delete_token := flushes.register(_next_operation(), delete_answers.take, true)
	flushes.advance(3600.0)
	t.check(flushes.waits_for(write_token) and write_answers.results.is_empty(),
			"a write's flush is still waiting after the huge frame")
	t.check(flushes.waits_for(delete_token) and delete_answers.results.is_empty(),
			"and so is a deletion's")
	flushes.answer([float(write_token), ""])
	flushes.answer([float(delete_token), ""])
	t.check(write_answers.results == [GameSave.Result.CONFIRMED]
			and delete_answers.results == [GameSave.Result.CONFIRMED],
			"so the browser's own answer on that frame is kept, not ignored")

func _test_a_flush_still_times_out_after_enough_frames(t) -> void:
	var flushes := GameSave.Flushes.new()
	var answers := _Answers.new()
	var token := flushes.register(_next_operation(), answers.take, true)
	var steps := int(GameSave.FLUSH_TIMEOUT_SECONDS / GameSave.MAX_FLUSH_STEP_SECONDS)
	for i in steps - 1:
		flushes.advance(GameSave.MAX_FLUSH_STEP_SECONDS)
	t.check(flushes.waits_for(token), "one frame short of the timeout it still waits")
	flushes.advance(GameSave.MAX_FLUSH_STEP_SECONDS)
	t.check(answers.results == [GameSave.Result.FAILED], "the frame that reaches it fails the flush")
	flushes.answer([float(token), ""])
	t.check(answers.results == [GameSave.Result.FAILED], "and a late success does not reverse it")

func _test_a_deletion_raises_and_settles_the_symbol(t) -> void:
	_with_a_scratch_save(func() -> void:
		# Written before the symbol is built: a write raises the symbol too.
		t.check(_saved(true), "a save exists")
		var timeline := SaveIndicator.Showing.new()
		var indicator := SaveIndicator.new(timeline)
		t.add_child(indicator)
		t.check(not indicator.is_showing(), "nothing shows before a deletion")
		t.check(GameSave.clear() == GameSave.Result.CONFIRMED, "the deletion is kept")
		t.check(indicator.is_showing() and timeline.pending == 0,
				"the symbol is up and the deletion is already answered")
		t.check(not indicator.shows_struck(), "plain, since it was kept")
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

func _test_a_deletion_not_kept_strikes_the_symbol(t) -> void:
	var immediate_timeline := SaveIndicator.Showing.new()
	var immediate := SaveIndicator.new(immediate_timeline)
	t.add_child(immediate)
	EventBus.save_deleted.emit(_next_operation(), int(GameSave.Result.FAILED))
	t.check(immediate.shows_struck() and immediate_timeline.pending == 0,
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
	t.check(later.shows_struck() and later_timeline.pending == 0,
			"a deletion the browser did not keep shows the struck picture")
	later.free()

## Statement 8: the run's end deletes the save through `GameSave.clear_when_a_run_ends()`, which has no
## way to reach `main`, and the symbol shows it anyway. A day that does not end the run deletes
## nothing and shows nothing.
func _test_a_run_that_ends_shows_the_symbol_for_the_deletion(t) -> void:
	GameSave.clear_when_a_run_ends()
	GameState.start_run(61)
	GameState.header.day = 3
	_with_a_scratch_save(func() -> void:
		t.check(_saved(true), "a save exists")
		# Built after the write, which raises the symbol too: only the deletions are watched.
		var indicator := SaveIndicator.new()
		t.add_child(indicator)
		GameState.calendar.finish_day(GameEnums.DayResult.WON)
		t.check(not indicator.is_showing(), "a day that does not end the run shows nothing")

		GameState.header.day = Tuning.RUN_LENGTH_DAYS
		GameState.calendar.begin_day()
		GameState.calendar.finish_day(GameEnums.DayResult.WON)
		t.check(GameState.header.ending != GameEnums.Ending.NONE, "the final day ends the run")
		t.check(not GameSave.has_save(), "which deletes the save")
		t.check(indicator.is_showing() and not indicator.shows_struck(),
				"and the symbol shows the deletion, kept")
		indicator.free()
	)
	# An ended run refuses every later write, including the next suite's.
	GameState.header.ending = GameEnums.Ending.NONE

## The charge a reopened run pays can end it: the lost day was the last nerve. That deletion shows
## the symbol too, provided a symbol is listening when `main._ready()` charges it.
func _test_a_resumed_run_ended_by_its_charge_shows_the_symbol(t) -> void:
	GameSave.clear_when_a_run_ends()
	GameState.start_run(62)
	GameState.calendar.choose_mode(true)
	GameState.header.day = 4
	GameState.header.nerves = 1
	GameState.calendar.begin_day()
	_with_a_scratch_save(func() -> void:
		t.check(_saved(true), "the mid-day save")
		var indicator := SaveIndicator.new()
		t.add_child(indicator)
		var resume := GameSave.try_resume(GameState)
		t.check(resume.get("day_under_way", false), "it resumes with its day under way")
		var kept_going := GameState.calendar.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)
		t.check(not kept_going and not GameSave.has_save(), "the charge ends the run and deletes it")
		t.check(indicator.is_showing(), "and the symbol that was already there shows it")
		indicator.free()
	)
	GameState.header.ending = GameEnums.Ending.NONE

## Statement 8: a restart after the run already ended finds no save to delete, changes nothing and
## shows nothing.
func _test_a_restart_with_no_save_left_shows_nothing(t) -> void:
	_with_a_scratch_save(func() -> void:
		var indicator := SaveIndicator.new()
		t.add_child(indicator)
		t.check(not GameSave.has_save(), "the run's end already deleted the save")
		t.check(GameSave.clear() == GameSave.Result.REFUSED, "so the restart's deletion is refused")
		t.check(not indicator.is_showing(), "and the symbol stays dark")
		indicator.free()
	)

func _test_the_restarts_symbol_survives_the_scene_reload(t) -> void:
	var tree: SceneTree = t.get_tree()
	# This suite runs inside the runner's own `_ready()`, while the tree's root is still busy
	# adding the runner, so it cannot take a child; a node stands in for the root.
	var home := Node.new()
	t.add_child(home)
	SaveIndicator.use_home(home)
	var old_main := Node.new()
	t.add_child(old_main)
	var timeline := SaveIndicator.Showing.new()
	var indicator := SaveIndicator.new(timeline)
	old_main.add_child(indicator)
	t.check(SaveIndicator.carried(tree) == null, "nothing is carried before a restart")

	indicator.outlive_the_scene()
	t.check(indicator.get_parent() == old_main, "an idle symbol stays where it is")

	var deletion := _next_operation()
	EventBus.save_deleted.emit(deletion, int(GameSave.Result.PENDING))
	indicator.outlive_the_scene()
	t.check(indicator.get_parent() == home, "a symbol that is up goes to the tree's root")
	old_main.free()
	t.check(is_instance_valid(indicator), "so freeing the scene it came from does not free it")
	t.check(SaveIndicator.carried(tree) == indicator, "and the next boot finds it")
	t.check(timeline.pending == 1 and indicator.is_showing(), "still showing the pending deletion")

	EventBus.save_deletion_settled.emit(deletion, false)
	t.check(indicator.shows_struck() and timeline.pending == 0,
			"the browser's answer arrives after the reload and settles it, struck")
	indicator.free()
	t.check(SaveIndicator.carried(tree) == null, "nothing is left on the root")
	SaveIndicator.use_home(null)
	home.free()

## A symbol freed with its scene stops listening: a signal drops a freed object by itself, so a
## later deletion reaches nobody and calls nothing.
func _test_the_symbols_listening_ends_with_the_symbol(t) -> void:
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

func _test_a_write_announces_itself_on_the_bus_and_begins_the_symbol_once(t) -> void:
	var heard: Array[int] = []
	var listen := func(_operation: int, result: int) -> void: heard.append(result)
	EventBus.save_written.connect(listen)
	_headless(func() -> void:
		t.check(GameSave.write(GameState, true) == GameSave.Result.REFUSED and heard.is_empty(),
				"a headless run's write is refused and announces nothing")
	)
	_with_a_scratch_save(func() -> void:
		var timeline := SaveIndicator.Showing.new()
		var indicator := SaveIndicator.new(timeline)
		t.add_child(indicator)
		GameSave.write(GameState, true)
		t.check(heard == [int(GameSave.Result.CONFIRMED)], "a write announces what it came to")
		t.check(timeline.begun == 1, "and the symbol began once for it, with nobody relaying it")
		t.check(indicator.is_showing() and timeline.pending == 0,
				"and that one change is already answered")
		indicator.free()
		GameState.header.ending = GameEnums.Ending.BAD
		heard.clear()
		t.check(GameSave.write(GameState, true) == GameSave.Result.REFUSED and heard.is_empty(),
				"a run that has ended refuses the write and announces nothing")
		GameState.header.ending = GameEnums.Ending.NONE
	)
	EventBus.save_written.disconnect(listen)

func _test_a_write_flush_settles_the_write_signal_and_a_deletion_flush_does_not(t) -> void:
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

func _test_a_pending_write_is_answered_after_the_restart_freed_the_main_that_saved(t) -> void:
	var flushes := GameSave.Flushes.new()
	var home := Node.new()
	t.add_child(home)
	SaveIndicator.use_home(home)
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
	indicator.outlive_the_scene()
	t.check(indicator.get_parent() == home, "the restart hands the symbol to the tree's root")
	saver.free()
	old_main_scene.free()

	flushes.answer([float(token), ""])
	t.check(timeline.pending == 0 and not indicator.shows_struck(),
			"the answer reaches the symbol with the main that saved gone, and it is kept")
	timeline.advance(SaveIndicator.MIN_SHOWN_SECONDS + SaveIndicator.FADE_SECONDS + 0.1)
	t.check(timeline.is_idle(), "so the symbol fades out instead of staying up for good")

	save = _next_operation()
	EventBus.save_written.emit(save, int(GameSave.Result.PENDING))
	token = flushes.register(save, Callable())
	flushes.answer([float(token), "Connection to Indexed Database server lost"])
	t.check(indicator.shows_struck() and timeline.pending == 0,
			"and a save the browser did not keep strikes it the same way")
	indicator.free()
	SaveIndicator.use_home(null)
	home.free()

func _test_an_answer_to_a_change_the_symbol_never_began_is_ignored(t) -> void:
	var timeline := SaveIndicator.Showing.new()
	var indicator := SaveIndicator.new(timeline)
	t.add_child(indicator)
	var before_it := _next_operation()
	var its_own := _next_operation()
	EventBus.save_written.emit(its_own, int(GameSave.Result.PENDING))
	EventBus.save_write_settled.emit(before_it, true)
	EventBus.save_deletion_settled.emit(before_it, false)
	t.check(timeline.pending == 1 and not indicator.shows_struck(),
			"an answer to a change announced before it was built neither settles nor strikes it")
	EventBus.save_write_settled.emit(its_own, false)
	t.check(indicator.shows_struck() and timeline.pending == 0,
			"and its own change's answer still does")
	indicator.free()

func _test_each_change_carries_its_own_operation_id_to_its_answer(t) -> void:
	var announced: Array[int] = []
	var announce := func(operation: int, _result: int) -> void: announced.append(operation)
	var answered: Array[int] = []
	var answer := func(operation: int, _kept: bool) -> void: answered.append(operation)
	EventBus.save_written.connect(announce)
	EventBus.save_deleted.connect(announce)
	EventBus.save_write_settled.connect(answer)
	EventBus.save_deletion_settled.connect(answer)
	GameSave.clear()
	var before := announced.size()
	GameSave.write(GameState, true)
	GameSave.clear()
	GameSave.write(GameState, false)
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
	GameSave.clear()

# ----------------------------------------------------------------- the symbol ---

## *"we should show it until it is fully confirmed saved"* — while a save is unanswered the symbol
## is fully shown and nothing counts down, however long the browser takes.
func _test_the_symbol_holds_with_no_timer_while_a_save_is_pending(t) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin(1)
	showing.advance(SaveIndicator.MIN_SHOWN_SECONDS + SaveIndicator.FADE_SECONDS + 10.0)
	t.check(showing.alpha() == 1.0, "a pending save stays fully shown past every minimum and the fade")
	t.check(not showing.struck, "and plain, since nothing has failed yet")

## *"okay always show it. but show it for at least a second"* — a desktop save is answered in the
## frame it begins, and the symbol still shows, fully, for a second and then fades.
func _test_a_save_answered_at_once_shows_for_a_second_then_fades(t) -> void:
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
func _test_a_save_pending_three_seconds_fades_straight_after_its_answer(t) -> void:
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
func _test_any_unanswered_save_keeps_the_symbol_up(t) -> void:
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
func _test_a_failure_answered_at_once_shows_struck_for_ten_seconds(t) -> void:
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
func _test_a_failure_answered_after_five_seconds_is_struck_until_fifteen(t) -> void:
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
func _test_a_save_beginning_mid_fade_restarts_the_second(t) -> void:
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

func _test_a_save_beginning_while_fully_shown_does_not_restart_the_second(t) -> void:
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
func _test_the_newest_failure_strikes_and_an_older_success_does_not_clear_it(t) -> void:
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
func _test_an_older_failure_never_strikes(t) -> void:
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
func _test_only_the_newest_save_decides_in_either_order_of_arrival(t) -> void:
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
func _test_each_failure_restarts_the_struck_clock(t) -> void:
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
func _test_a_kept_save_after_a_failed_one_clears_the_strike(t) -> void:
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
func _test_begin_does_not_clear_a_strike_while_its_save_is_unanswered(t) -> void:
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
func _test_a_struck_symbol_that_faded_away_is_forgotten(t) -> void:
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
func _test_a_stray_answer_shows_nothing(t) -> void:
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

## The whole path through `GameSave.write()` — the one call `main` makes for a save, which it
## relays nothing of: a run `GameSave.uses_save()` refuses — here the headless runner — leaves the
## symbol dark rather than struck.
func _test_a_refused_save_leaves_the_symbol_dark(t) -> void:
	var timeline := SaveIndicator.Showing.new()
	var indicator := SaveIndicator.new(timeline)
	t.add_child(indicator)
	_headless(func() -> void:
		t.check(GameSave.write(GameState, true) == GameSave.Result.REFUSED, "the write is refused")
	)
	t.check(timeline.is_idle() and not timeline.struck, "a refused save leaves the symbol dark")
	indicator.free()

func _test_a_desktop_save_shows_the_symbol_confirmed_at_once(t) -> void:
	_with_a_scratch_save(func() -> void:
		var timeline := SaveIndicator.Showing.new()
		var indicator := SaveIndicator.new(timeline)
		t.add_child(indicator)
		GameSave.write(GameState, true)
		t.check(timeline.pending == 0 and not timeline.is_idle(),
				"a desktop save is answered at once and the symbol is already showing")
		t.check(not timeline.struck and not indicator.shows_struck(), "showing the plain picture")
		indicator.free()
	)

func _test_a_save_not_kept_swaps_to_the_struck_picture(t) -> void:
	var indicator := SaveIndicator.new()
	t.add_child(indicator)
	var icon := indicator.find_child("Icon", true, false) as TextureRect
	var plain := icon.texture
	indicator.begin(1)
	indicator.settle(1, false)
	var struck := icon.texture
	t.check(plain != null and struck != null and struck != plain,
			"the plain and the struck pictures are both on the atlas, and different")
	t.check(indicator.shows_struck(), "a save not kept shows the struck picture")
	indicator.begin(2)
	t.check(indicator.shows_struck(), "a new save still unanswered does not hide the failure")
	indicator.settle(2, true)
	t.check(not indicator.shows_struck() and icon.texture == plain,
			"and a kept answer swaps back to the plain one")
	indicator.free()
