extends RefCounted
## `GameSave`, and the two functions on `GameState` it reads and writes through
## (`save_snapshot()`/`restore_snapshot()`) — see docs/MECHANICS.md, "Saving and resuming".
##
## **Every test here points `GameSave` at a scratch file**, never `user://save.json`: the suite
## runs headless, so `GameSave.uses_save()` already answers `false` on its own (see
## `_test_uses_save_is_false_under_the_headless_runner()`), but the *ungated* mechanics
## (`_write_now()`/`_read_now()`) bypass that gate on purpose so the actual file format can be
## exercised, and those go through `set_path_override()` unconditionally here to make sure of it.
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

	_test_round_trip_field_list_matches_the_property_list(t)
	_test_round_trip_preserves_every_field(t)
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

	_test_day_under_way_load_costs_one_nerve(t)
	_test_a_day_under_way_gives_back_the_fire_it_lit(t)
	_test_day_under_way_load_on_the_last_nerve_ends_the_run(t)
	_test_summary_load_costs_nothing(t)
	_test_double_load_does_not_charge_twice(t)
	_test_either_ending_clears_the_save(t)

	_test_focus_loss_never_charges_a_nerve(t)
	_test_focus_loss_and_window_close_write_nothing(t)
	_test_fresh_boot_writes_nothing_until_the_title_is_dismissed(t)
	_test_a_restart_writes_nothing_until_the_next_titles_dismissed(t)
	_test_resumed_boot_with_a_charged_nerve_writes_the_reduced_nerve_count(t)
	_test_dismissing_a_fresh_titles_start_writes_the_save_under_way(t)
	_test_title_leads_to_the_day_brief_with_nothing_charged(t)
	_test_title_leads_to_the_day_brief_with_a_charged_nerve(t)
	_test_title_leads_to_the_ending_on_the_last_nerve(t)

	_test_a_save_moment_answers_by_platform_and_storage(t)
	_test_a_desktop_write_is_confirmed_at_once(t)
	_test_a_refused_or_ended_run_is_not_a_failed_save(t)
	_test_a_flush_settles_once_whichever_answer_comes_first(t)
	_test_a_flush_whose_listener_is_gone_settles_quietly(t)
	_test_the_symbol_holds_with_no_timer_while_a_save_is_pending(t)
	_test_a_save_answered_at_once_shows_for_a_second_then_fades(t)
	_test_a_save_pending_three_seconds_fades_straight_after_its_answer(t)
	_test_a_second_save_keeps_the_symbol_up_until_both_are_answered(t)
	_test_a_failure_answered_at_once_shows_struck_for_ten_seconds(t)
	_test_a_failure_answered_after_five_seconds_is_struck_until_fifteen(t)
	_test_a_save_beginning_mid_fade_restarts_the_second(t)
	_test_a_save_beginning_while_fully_shown_does_not_restart_the_second(t)
	_test_a_failure_while_another_save_is_pending_strikes_at_once(t)
	_test_each_failure_restarts_the_struck_clock(t)
	_test_a_kept_batch_after_a_failed_one_clears_the_strike(t)
	_test_begin_does_not_clear_a_strike_while_its_save_is_unanswered(t)
	_test_a_struck_symbol_that_faded_away_is_forgotten(t)
	_test_a_save_not_kept_is_struck_through_whichever_answers_first(t)
	_test_a_stray_answer_shows_nothing(t)
	_test_main_draws_nothing_for_a_refused_run(t)
	_test_main_shows_a_desktop_save_confirmed_at_once(t)
	_test_a_save_not_kept_swaps_to_the_struck_picture(t)

	GameSave.clear()
	GameSave.set_path_override("")
	GameState.restore_snapshot(baseline)
	# `restore_snapshot()` writes every field the *snapshot* carries, and the escape's own section,
	# the resistance's used alley tiles and the one fenced park are deliberately not among them —
	# see `_SAVED_OUTSIDE_THE_SNAPSHOT` — so this suite has to put all three back by hand or the next
	# one starts in the middle of an escape with somebody else's used alleys and fenced park still on.
	GameState.escape_section = FinaleController.Section.NONE
	GameState.completed_resistance_alley_tiles.clear()
	GameState.fenced_park = Vector2i(-1, -1)
	GameState.fenced_park_act = 0

# ---------------------------------------------------------------------- policy ---

## The property that makes every other test in this suite (and every other suite, and
## `tools/check.sh`'s own boot) safe to run at all: nothing here ever reaches the player's real
## `user://save.json`, because the headless display server this runner boots against already
## answers "no" on its own, before a path override is even asked for.
func _test_uses_save_is_false_under_the_headless_runner(t) -> void:
	t.check(not GameSave.uses_save(),
			"the headless test runner never reads or writes the real save")

## The pure half of `uses_save()`'s policy — see that function's own doc for why it is split out.
func _test_debug_run_uses_save_policy(t) -> void:
	t.check(GameSave._debug_run_uses_save(PackedStringArray(), false),
			"a flagless debug run uses the save")
	t.check(not GameSave._debug_run_uses_save(PackedStringArray(["--seed", "1"]), false),
			"any dev flag disables it, by being a dev flag at all")
	t.check(not GameSave._debug_run_uses_save(PackedStringArray(), true),
			"--no-save disables it even with nothing else on the command line")
	t.check(not GameSave._debug_run_uses_save(PackedStringArray(["--seed", "1"]), true),
			"and the two reasons stack rather than fighting")

func _test_no_save_query_parsing(t) -> void:
	t.check(not DevFlags._no_save_from_query(""), "an absent URL parameter changes nothing")
	t.check(not DevFlags._no_save_from_query("?nosave=0"), "nosave=0 leaves the save on")
	t.check(DevFlags._no_save_from_query("?nosave=1"), "?nosave=1 turns it off")
	t.check(DevFlags._no_save_from_query("?seed=1&nosave=1&day=2"),
			"the parameter is found among other URL parameters")

## M193, "the live page's ?debug=1 reaches the debug flags": `uses_save()`'s release branch is
## `not DevFlags.web_debug_flag_used()` rather than an unconditional `true` now, so a visitor who
## tries `?day=12` never touches the save the page might otherwise share with a real player —
## `_web_debug_flag_used_in_query()` is the pure half of that predicate a test can drive without a
## live page. The `?debug=1`-alone and empty-query cases pin that opening the bundle is not the
## same as having used anything in it, which is the property that keeps an ordinary release page's
## own save exactly as it always was.
func _test_web_debug_flag_used_query_parsing(t) -> void:
	t.check(not DevFlags._web_debug_flag_used_in_query(""), "an absent query used nothing")
	t.check(not DevFlags._web_debug_flag_used_in_query("?debug=1"),
		"?debug=1 alone opens the bundle without having used anything in it")
	t.check(DevFlags._web_debug_flag_used_in_query("?debug=1&day=12"),
		"?day=12 is a use of the bundle's own day parameter")
	t.check(DevFlags._web_debug_flag_used_in_query("?debug=1&invincible=1"),
		"and so is ?invincible=1")
	t.check(not DevFlags._web_debug_flag_used_in_query("?debug=1&seed=1234"),
		"?seed=, the older M133 bundle, is not part of this one")

## The gated entry points `main.gd` actually calls (`write()`/`try_resume()`, as opposed to the
## `_write_now()`/`_read_now()` this whole suite otherwise uses to reach past the gate) refuse
## outright under the headless runner, and touch no file at all in doing so — the property every
## other suite, and `tools/check.sh`'s own boot, are safe *because* of.
func _test_gated_write_and_resume_touch_nothing_under_the_headless_runner(t) -> void:
	GameSave.clear()
	t.check(not GameSave.write(true), "the gated write refuses under the headless runner")
	t.check(not GameSave.has_save(), "and leaves no file behind")
	t.check(GameSave._write_now(true), "the ungated mechanics still write, for this suite's own use")
	t.check(GameSave.try_resume().is_empty(),
			"the gated resume also refuses, even with a real file sitting at the scratch path")
	GameSave.clear()

# ------------------------------------------------------------------- round trip ---

## Every field a run holds that the save file does not carry inside its `"state"` object, and why
## each is somewhere else instead. **One entry, and adding a second is a decision rather than a
## convenience**: this list is the only way a field can be added to `GameState` and not be saved
## without the check below going red, which is the whole thing that check exists for.
##
## `escape_section` — which half of the escape a run is in — rides at the *top* level of the save
## beside `"day_under_way"`, because `GameState.snapshot_is_complete()` refuses a `"state"` missing
## any field this build writes: inside the snapshot it would have made every save written before
## the escape existed unreadable, for the sake of one int. `_test_a_save_from_before_the_escape_
## still_loads()` is what holds that. `completed_resistance_alley_tiles` rides the same way, for
## the same reason — `_test_a_save_from_before_the_alley_tiles_still_loads()` holds it — and so do
## `posters`, what is pasted on the walls (`_test_the_posters_survive_a_round_trip()`), and
## `fenced_park`/`fenced_park_act`, the one calm area a run may fence
## (`_test_a_save_from_before_the_fenced_park_still_loads()`).
const _SAVED_OUTSIDE_THE_SNAPSHOT := [
	"escape_section", "completed_resistance_alley_tiles", "posters",
	"fenced_park", "fenced_park_act",
]

## The guard the brief asks for: a field added to `GameState` later and forgotten in
## `GameState._SAVE_FIELDS` fails here rather than quietly not being saved. `PROPERTY_USAGE_
## SCRIPT_VARIABLE` is what separates a field this script actually declares from the base `Node`
## properties `get_property_list()` also reports (`name`, `process_mode`, and the rest).
func _test_round_trip_field_list_matches_the_property_list(t) -> void:
	var declared: Array[String] = []
	for property in GameState.get_property_list():
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			declared.append(property["name"])
	var declared_set := {}
	for name in declared:
		declared_set[name] = true
	var listed_set := {}
	for name in GameState._SAVE_FIELDS:
		listed_set[name] = true
	for name in declared:
		if name in _SAVED_OUTSIDE_THE_SNAPSHOT:
			continue
		t.check(listed_set.has(name),
				"'%s' is a GameState field the save format does not mention" % name)
	for name in GameState._SAVE_FIELDS:
		t.check(declared_set.has(name),
				"'%s' is in the save field list but is not actually a GameState field" % name)

## Every field, mutated to a value its default could not be mistaken for, round-tripped through
## the actual file — `_write_now()`/`_read_now()`, not the in-memory dictionaries, so a JSON
## int-becomes-float or a `Vector2i` key that cannot survive `JSON.stringify()` would show up here.
func _test_round_trip_preserves_every_field(t) -> void:
	GameState.start_run(778899)
	GameState.day = 6
	GameState.nerves = 3
	GameState.resistance_progress = 2
	GameState.ending = GameEnums.Ending.NONE
	GameState.play_seconds = 123.456
	GameState.consumed_one_shots = ["a_one_shot", "another_one_shot"]
	GameState.completed_resistance_steps = [0, 2]
	GameState.failed_resistance_steps = [1]
	GameState.scars = [{"id": "fire", "position": Vector2(140.5, -30.25), "since_day": 4}]
	GameState.city_state.reset()
	GameState.city_state.apply_cause(
			{Vector2i(3, 4): _fake_block_plan()}, Vector2i(3, 4), GameEnums.BlockCause.FIRE, 6)
	GameState.sabotage_done = false
	GameState.resistance_carrying_package = true
	GameState._dawn_completed_steps = [0]
	GameState._dawn_failed_steps = []
	GameState._dawn_progress = 1
	GameState._dawn_sabotage_done = false
	GameState._dawn_carrying_package = false
	GameState.settled_in = {5: Vector2i(-2, 7), 6: Vector2i(9, 9)}

	var written := GameState.save_snapshot()
	t.check(GameSave._write_now(true), "the write reports success")
	var resume := GameSave._read_now()
	t.check(resume.get("day_under_way", false) == true, "day_under_way round-trips as true")

	t.check(GameState.run_seed == 778899, "run_seed survives")
	t.check(GameState.day == 6, "day survives")
	t.check(GameState.nerves == 3, "nerves survives")
	t.check(GameState.resistance_progress == 2, "resistance_progress survives")
	t.close_to(GameState.play_seconds, 123.456, "play_seconds survives to a float")
	t.check(GameState.consumed_one_shots == ["a_one_shot", "another_one_shot"],
			"consumed_one_shots survives, string array and all")
	t.check(GameState.completed_resistance_steps == [0, 2], "completed_resistance_steps survives")
	t.check(GameState.failed_resistance_steps == [1], "failed_resistance_steps survives")
	t.check(GameState.scars.size() == 1
			and GameState.scars[0]["id"] == "fire"
			and (GameState.scars[0]["position"] as Vector2).distance_to(Vector2(140.5, -30.25)) < 0.01
			and GameState.scars[0]["since_day"] == 4,
			"a scar survives with its Vector2 position intact")
	t.check(GameState.city_state.changed_on(Vector2i(3, 4)) == 6,
			"the city's own block-arc history survives — a fire that burned did happen")
	t.check(GameState.resistance_carrying_package == true, "resistance_carrying_package survives")
	t.check(GameState._dawn_completed_steps == [0], "the dawn snapshot's own steps survive")
	t.check(GameState._dawn_progress == 1, "_dawn_progress survives")
	t.check(GameState.settled_in.get(5) == Vector2i(-2, 7)
			and GameState.settled_in.get(6) == Vector2i(9, 9),
			"settled_in survives with its Vector2i values and integer day keys intact")
	t.check(GameState.save_snapshot() == written,
			"and the whole snapshot taken before the write matches the one read back after it")

## Player, 2026-09-27: *"a won day recovers a nerve up to the max"*. `nerves` was already carried by
## `_SAVE_FIELDS`, but the count it carries now has to be the one a win just gave back, not the one
## a save taken before the change would have written — this writes the file only after the gain and
## wipes the live count before reading it back, so a save that quietly dropped the regained nerve
## rather than the round trip itself is what would fail this.
func _test_a_won_days_regained_nerve_survives_a_round_trip(t) -> void:
	GameState.start_run(240927)
	GameState.nerves = 3
	GameState.finish_day(GameEnums.DayResult.WON)
	t.check(GameState.nerves == 4, "winning regains a nerve before the save is even written")

	t.check(GameSave._write_now(true), "the write reports success")
	GameState.nerves = 0
	GameSave._read_now()
	t.check(GameState.nerves == 4, "and the regained count is what loading the save gives back")

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
	t.check(GameSave._read_now().is_empty(), "no file at all resumes nothing")

func _test_garbled_text_is_dropped(t) -> void:
	var before := GameState.save_snapshot()
	_write_raw("not valid json at all {{{")
	t.check(GameSave._read_now().is_empty(), "text that is not valid JSON resumes nothing")
	t.check(GameState.save_snapshot() == before, "and GameState is left exactly as it was")

func _test_wrong_format_version_is_dropped(t) -> void:
	var before := GameState.save_snapshot()
	_write_raw(JSON.stringify({
		"format_version": GameSave.FORMAT_VERSION + 1,
		"build": "some other build",
		"day_under_way": true,
		"state": GameState.save_snapshot(),
	}))
	t.check(GameSave._read_now().is_empty(),
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
	t.check(GameSave._read_now().is_empty(),
			"a state missing a field this build writes resumes nothing rather than half-loading")
	t.check(GameState.save_snapshot() == before, "and GameState is untouched by trying")

func _write_raw(text: String) -> void:
	var file := FileAccess.open(_SCRATCH_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _test_clear_deletes_the_file(t) -> void:
	t.check(GameSave._write_now(true), "a write lands")
	t.check(GameSave.has_save(), "and the file exists")
	GameSave.clear()
	t.check(not GameSave.has_save(), "clear() removes it")
	GameSave.clear()
	t.check(not GameSave.has_save(), "clearing an already-absent save is a silent no-op")

func _test_write_refuses_once_the_run_has_ended(t) -> void:
	GameSave.clear()
	var ending := GameState.ending
	GameState.ending = GameEnums.Ending.BAD
	t.check(not GameSave._write_now(true), "a write refuses once the run has an ending")
	t.check(not GameSave.has_save(), "and touches no file at all")
	GameState.ending = ending

## Closing the game inside a section of the escape and opening it again comes back to that
## section's own brief, which is `GameState.escape_section` surviving the file — the same
## mechanism a day under way already rides on, and deliberately the same one rather than a second
## save path beside it.
func _test_the_escape_section_survives_a_round_trip(t) -> void:
	GameState.start_run(313131)
	GameState.day = Tuning.RUN_LENGTH_DAYS
	GameState.escape_section = FinaleController.Section.CITY
	t.check(GameSave._write_now(false), "a section of the escape writes a save")
	# Wiped the way a fresh process would find it, so what is read back has to come off the file.
	GameState.start_run(1)
	t.check(GameState.escape_section == FinaleController.Section.NONE,
			"a fresh run is in no section (the check below would pass vacuously otherwise)")
	t.check(not GameSave._read_now().is_empty(), "and the file resumes")
	t.check(GameState.escape_section == FinaleController.Section.CITY,
			"onto the section it was closed in, not the start of the escape")
	t.check(GameState.run_seed == 313131, "with the run it belonged to")
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
	GameState.day = 9
	GameState.nerves = 3
	var old_shape := JSON.stringify({
		"format_version": GameSave.FORMAT_VERSION,
		"build": "a build from before the escape",
		"day_under_way": true,
		"state": GameState.save_snapshot(),
	})
	t.check(not old_shape.contains("escape_section"),
			"the payload really is one with no escape section in it")
	GameState.start_run(1)
	GameState.escape_section = FinaleController.Section.BUILDING
	_write_raw(old_shape)
	var resumed := GameSave._read_now()
	t.check(not resumed.is_empty(), "a save with no escape section still resumes")
	t.check(GameState.run_seed == 424242 and GameState.day == 9 and GameState.nerves == 3,
			"with every field it does carry")
	t.check(bool(resumed.get("day_under_way", false)),
			"and the day-under-way flag beside it, unchanged")
	t.check(GameState.escape_section == FinaleController.Section.NONE,
			"and the run is in no section, rather than keeping whatever was in memory")
	GameSave.clear()

## The same mechanism `escape_section` rides on, for the alley tiles the resistance has already
## used this run (M177) — closing the game between days must not hand the next mark back every
## alley to choose from again.
func _test_completed_resistance_alley_tiles_survive_a_round_trip(t) -> void:
	GameState.start_run(515151)
	GameState.completed_resistance_alley_tiles = [Vector2i(4, 9), Vector2i(-2, 15)]
	t.check(GameSave._write_now(false), "a run with used alley tiles writes a save")
	GameState.start_run(1)
	t.check(GameState.completed_resistance_alley_tiles.is_empty(),
			"a fresh run has recorded none (the check below would pass vacuously otherwise)")
	t.check(not GameSave._read_now().is_empty(), "and the file resumes")
	t.check(GameState.completed_resistance_alley_tiles == [Vector2i(4, 9), Vector2i(-2, 15)],
			"onto the tiles it was closed with, Vector2i values and all")
	GameSave.clear()

## Expiring the physical fence cannot reopen the once-per-run choice, including after a reload.
func _test_an_expired_fence_survives_a_round_trip(t) -> void:
	GameState.start_run(14040)
	GameState.fenced_park = Vector2i(6, 8)
	GameState.fenced_park_act = 3
	GameState.day = 12
	GameState.remember_fenced_park(Vector2i(-1, -1), 0)
	t.check(GameSave._write_now(false), "the act-boundary run writes a save")
	GameState.start_run(1)
	t.check(not GameSave._read_now().is_empty(), "the act-boundary save resumes")
	t.check(GameState.fenced_park == Vector2i(6, 8) and GameState.fenced_park_act == 3,
			"reloading after expiry remembers the original fence")
	var map := CityGenerator.generate(GameState.run_seed)
	var state := CityState.new()
	state.begin_day(map.block_plans, 13)
	map.repaint(state)
	var used: Array[Vector2i] = [map.calm_blocks[0]]
	map.set_spent_calm(used)
	map.set_fenced_park_state(GameState.fenced_park, GameState.fenced_park_act, 4)
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
		"escape_section": GameState.escape_section,
		"state": GameState.save_snapshot(),
	})
	t.check(not old_shape.contains("completed_resistance_alley_tiles"),
			"the payload really is one with no alley tiles recorded in it")
	GameState.start_run(1)
	GameState.completed_resistance_alley_tiles = [Vector2i(7, 7)]
	_write_raw(old_shape)
	var resumed := GameSave._read_now()
	t.check(not resumed.is_empty(), "a save with no alley tiles still resumes")
	t.check(GameState.completed_resistance_alley_tiles.is_empty(),
			"and the list is empty, rather than keeping whatever was in memory")
	GameSave.clear()

## The same mechanism `escape_section` rides on, for the one calm area this run has fenced (M129) —
## closing the game mid-act must not let a second park get fenced on reopening, which is exactly
## what forgetting `fenced_park` on reload would do.
func _test_the_fenced_park_survives_a_round_trip(t) -> void:
	GameState.start_run(535353)
	GameState.fenced_park = Vector2i(6, 9)
	GameState.fenced_park_act = 3
	t.check(GameSave._write_now(false), "a run with a fenced park writes a save")
	GameState.start_run(1)
	t.check(GameState.fenced_park == Vector2i(-1, -1),
			"a fresh run has fenced none (the check below would pass vacuously otherwise)")
	t.check(not GameSave._read_now().is_empty(), "and the file resumes")
	t.check(GameState.fenced_park == Vector2i(6, 9) and GameState.fenced_park_act == 3,
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
		"escape_section": GameState.escape_section,
		"state": GameState.save_snapshot(),
	})
	t.check(not old_shape.contains("fenced_park"),
			"the payload really is one with no fenced park recorded in it")
	GameState.start_run(1)
	GameState.fenced_park = Vector2i(3, 3)
	GameState.fenced_park_act = 2
	_write_raw(old_shape)
	var resumed := GameSave._read_now()
	t.check(not resumed.is_empty(), "a save with no fenced park still resumes")
	t.check(GameState.fenced_park == Vector2i(-1, -1) and GameState.fenced_park_act == 0,
			"and none is fenced, rather than keeping whatever was in memory")
	GameSave.clear()

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
	t.check(GameSave._write_now(false), "a run with posters writes")
	GameState.posters.reset()
	GameSave._read_now()
	t.check(GameState.posters.to_data() == written,
			"the walls, the tear count and the photograph a lost day gives back all survive")
	var old_shape := JSON.stringify({
		"format_version": GameSave.FORMAT_VERSION,
		"build": "a build from before the posters",
		"day_under_way": false,
		"state": GameState.save_snapshot(),
	})
	_write_raw(old_shape)
	GameSave._read_now()
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
	GameState.day = 7
	GameState.nerves = 4
	GameState.completed_resistance_steps = [1, 2, 3]
	GameState.resistance_progress = 1
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
	var resumed := GameSave._read_now()
	t.check(not resumed.is_empty(), "a save naming the old brief fields still resumes")
	t.check(GameState.run_seed == 636363 and GameState.day == 7 and GameState.nerves == 4,
			"with every field the new build still reads")
	t.check(GameState.completed_resistance_steps == [1, 2, 3],
			"and its old-table step indices, carried over rather than dropped")
	GameSave.clear()

# ------------------------------------------------------------- the lost-day path ---

## What `main._ready()` does with a `day_under_way: true` resume: apply `GameState.finish_day()`
## with a non-`WON` result, the same call an ordinary lost day makes. One nerve, the day's own
## resistance work undone, the same day again.
func _test_day_under_way_load_costs_one_nerve(t) -> void:
	GameState.start_run(55)
	GameState.day = 4
	GameState.nerves = 5
	GameState.begin_day()
	# Progress made during the attempt that is about to be "left" — the dawn snapshot above this
	# does not carry it, so a loss has something real to give back.
	GameState.complete_resistance_step(0)
	t.check(GameState.resistance_progress == 1, "the attempt made progress before being saved")

	var resume := {"day_under_way": true}
	var continues := GameState.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)

	t.check(continues, "a nerve was spent, not the last one, so the run goes on")
	t.check(GameState.nerves == 4, "exactly one nerve is spent")
	t.check(GameState.day == 4, "the same day is offered again, not the next one")
	t.check(GameState.resistance_progress == 0,
			"the resistance work the attempt did is given back, the same as any other lost day")
	t.check(resume["day_under_way"], "the resume dict this all hangs off of is the one asserted")

## **A run closed mid-day gives back what that day burned, through the same path an ordinary loss
## takes.** `main._ready()` hands a save written with `day_under_way` to `GameState.finish_day()` as
## a hard fail, so the whole of the give-back has to survive the file: the photograph of what the
## attempt may spend rides in `_SAVE_FIELDS` beside the resistance's, or a day 3 closed after the
## fire burned would come back with the fire spent, a shell standing and no fire owed on the retry.
##
## The round trip is the point, so the state is written, wiped to something else, and read back
## before the day is lost — a check that never left memory would pass with the three fields missing
## from the save entirely.
func _test_a_day_under_way_gives_back_the_fire_it_lit(t) -> void:
	GameState.start_run(59)
	GameState.day = Tuning.RUN_TAUGHT_DAY
	GameState.nerves = 3
	GameState.begin_day()
	GameState.consumed_one_shots.append("burning_building")
	GameState.add_scar("burnt_shell", Vector2(640.0, 640.0))
	t.check(GameSave._write_now(true), "the run is saved with the day under way and the fire lit")

	# Wiped to a different run entirely, so what comes back can only have come out of the file.
	GameState.start_run(60)
	var resume := GameSave._read_now()
	t.check(resume.get("day_under_way") == true, "the save says a day was under way")
	t.check("burning_building" in GameState.consumed_one_shots and GameState.scars.size() == 1,
			"and it comes back with the fire spent and its shell standing, as the attempt left it")

	GameState.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)
	t.check(not "burning_building" in GameState.consumed_one_shots,
			"losing the resumed day owes the fire again")
	t.check(GameState.scars.is_empty(),
			"and takes the shell down with it, the same as any other lost day")

## The last nerve ends the run exactly as it does when a day is lost by playing it out — and the
## ending clears the save, since there is nothing left to resume.
func _test_day_under_way_load_on_the_last_nerve_ends_the_run(t) -> void:
	GameState.start_run(56)
	GameState.day = 9
	GameState.nerves = 1
	GameState.begin_day()
	t.check(GameSave._write_now(true), "a save exists before the last nerve is spent")

	var continues := GameState.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)

	t.check(not continues, "the run does not go on")
	t.check(GameState.nerves == 0, "the last nerve is gone")
	t.check(GameState.ending == GameEnums.Ending.BAD, "the bad ending, the same as any other run out")
	t.check(not GameSave.has_save(), "and the save that named the run is gone with it")

## A save written at a day's own summary (`day_under_way: false`) is never handed to
## `GameState.finish_day()` at all in `main._ready()` — asserted here as the shape of the contract
## the two booleans below make untestable any other way: nerves and day both hold whatever the
## save itself named, because nothing here ever touches them.
func _test_summary_load_costs_nothing(t) -> void:
	GameState.start_run(57)
	GameState.day = 8
	GameState.nerves = 4
	t.check(GameSave._write_now(false), "a save is written at a day's own summary")
	var resume := GameSave._read_now()
	t.check(resume.get("day_under_way") == false, "it comes back false")
	t.check(GameState.day == 8 and GameState.nerves == 4,
			"nothing about the run changes on a load this function never spends a nerve on")

## The ordering the commit message states: after the load-time penalty is applied, the very next
## write (`main._start_day()`'s own dawn write, made before the resumed pause screen can even be
## looked at) already reflects the spent nerve *and* writes the fresh dawn as not yet under way —
## since nothing has happened in it yet. A second close-and-reopen before ever touching that screen
## therefore finds `day_under_way: false` and costs nothing more.
func _test_double_load_does_not_charge_twice(t) -> void:
	GameState.start_run(58)
	GameState.day = 5
	GameState.nerves = 5
	GameState.begin_day()
	t.check(GameSave._write_now(true), "the first save: a day left mid-way")

	var first := GameSave._read_now()
	t.check(first.get("day_under_way") == true, "the first load finds a day under way")
	GameState.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)
	t.check(GameState.nerves == 4, "the first load costs its one nerve")
	# `main._ready()`'s own write for the resumed, unplayed retry — a title, and then a day brief,
	# both stand between this and the player actually taking control, so this is what it writes
	# before either is ever shown.
	t.check(GameSave._write_now(false), "the fresh dawn is saved before the title is shown")

	var second := GameSave._read_now()
	t.check(second.get("day_under_way") == false,
			"a second close before pressing continue on the day brief finds nothing under way")
	# The caller (`main._ready()`) would not call `finish_day()` at all on this result — nothing
	# here does either, so an unchanged nerve count is the whole of the assertion.
	t.check(GameState.nerves == 4, "and so the second load does not spend a second nerve")

func _test_either_ending_clears_the_save(t) -> void:
	GameState.start_run(59)
	GameState.day = 3
	GameState.nerves = 2
	t.check(GameSave._write_now(true), "a save exists")
	GameState.finish_day(GameEnums.DayResult.WON)
	t.check(GameState.ending == GameEnums.Ending.NONE, "day 3 of a run this short does not end it")
	t.check(GameSave.has_save(), "so the save is untouched")

	GameState.day = Tuning.RUN_LENGTH_DAYS
	GameState.begin_day()
	t.check(GameSave._write_now(true), "a save exists for the final day")
	GameState.finish_day(GameEnums.DayResult.WON)
	t.check(GameState.ending != GameEnums.Ending.NONE, "winning the final day ends the run")
	t.check(not GameSave.has_save(), "and a won run clears the save exactly as a lost one does")

# ------------------------------------------------------------------- main.gd wiring ---

const _MAIN_SCRIPT: GDScript = preload("res://src/main.gd")
const _PAUSE_SCENE := preload("res://scenes/ui/pause_screen.tscn")
const _SUMMARY_SCENE := preload("res://scenes/ui/day_summary.tscn")
const _TITLE_SCENE := preload("res://scenes/ui/title_screen.tscn")

## A script-only `main`, the same shape `tests/test_main.gd`'s own focus-loss rig builds — a bare
## `DayController` stands in for a live one, since all `_notification()` asks of it is `.phase`.
func _build_bare_main(t) -> Node2D:
	var main: Node2D = _MAIN_SCRIPT.new()
	main._summary = _SUMMARY_SCENE.instantiate()
	t.add_child(main._summary)
	main._pause = _PAUSE_SCENE.instantiate()
	t.add_child(main._pause)
	main._title = _TITLE_SCENE.instantiate()
	t.add_child(main._title)
	main._no_focus_pause = false
	main._day = DayController.new()
	main._day.phase = GameEnums.DayPhase.WALKING
	return main

func _free_bare_main(t, main: Node2D) -> void:
	t.get_tree().paused = false
	main._summary.queue_free()
	main._pause.queue_free()
	main._title.queue_free()
	main._day.free()
	main.free()

## Losing focus opens the pause and, under a real run, may write a save — but never through
## `GameState.finish_day()`. Only *opening a saved game* ever spends a nerve; continuing after a
## focus loss in the same session is free, which this asserts by the coarsest available proof: the
## numbers `finish_day()` would have touched do not move.
func _test_focus_loss_never_charges_a_nerve(t) -> void:
	var main := _build_bare_main(t)
	var day := GameState.day
	var nerves := GameState.nerves
	t.get_tree().paused = false

	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(main._pause.is_open(), "focus loss still opens the pause, exactly as before this milestone")
	t.check(GameState.day == day and GameState.nerves == nerves,
			"and neither the day nor the nerve count moved — a focus loss alone never spends one")
	main._pause.close()

	_free_bare_main(t, main)

## **`main._notification()` stops calling `_save_now()` on either notification.** Losing focus
## still opens the pause (asserted above) and a window close still ends the telemetry log, but
## neither touches the save any more — only a day starting, or its own brief or end-of-day message
## coming up, changes what a save holds (docs/MECHANICS.md, "Saving and resuming"). Forced through
## `_with_forced_save()` so a stray write here would actually land and be caught; without it
## `uses_save()` already answers `false` under the headless runner regardless of what `main` calls,
## and the assertion would pass whether or not the write survived. `main._quit()` makes the same
## change on its one remaining line, but it also calls `get_tree().quit()`, which would end this
## test run rather than this test — there is no way to call it from here at all, so that half is
## read off the diff rather than asserted.
func _test_focus_loss_and_window_close_write_nothing(t) -> void:
	_with_forced_save(func() -> void:
		var main := _build_bare_main(t)
		t.get_tree().paused = false

		main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		t.check(main._pause.is_open(), "focus loss still opens the pause")
		t.check(not GameSave.has_save(), "but writes nothing")
		main._pause.close()

		main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		t.check(not GameSave.has_save(), "and neither does the window-close notification")

		_free_bare_main(t, main)
	)

## The seam that lets a gated write actually land under this headless runner — see
## `GameSave._uses_save_override`'s own doc. Every test below that calls `main._engage_the_day()`
## (directly, or through `_on_title_start()`/`_on_summary_continued()`) needs `main._save_now()`'s
## own call to `GameSave.write()` to really write, which `uses_save()` would otherwise refuse
## unconditionally under `DisplayServer.get_name() == "headless"`.
func _with_forced_save(callable: Callable) -> void:
	GameSave._uses_save_override = true
	GameSave.clear()
	callable.call()
	GameSave.clear()
	GameSave._uses_save_override = null

## The fuller rig `_on_title_start()`/`_show_the_resume_gate()`/`_on_summary_continued()` need to
## run for real: the same touch/camera/city/hud/edge/status scaffolding
## `_test_dismissing_a_fresh_titles_start_writes_the_save_under_way()` needs to drive
## `_engage_the_day()`, plus a real `DaySummary` scene instance so `show_day_brief()`'s own labels
## have something to populate into.
func _bare_gate_main(t) -> Node2D:
	var main: Node2D = _MAIN_SCRIPT.new()
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
	main._title = TitleScreen.new()
	main._summary = _SUMMARY_SCENE.instantiate()
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

## **The review finding this test exists for.** `_start_day()` used to write its own dawn
## unconditionally, so merely opening the game — before the title was ever dismissed — created a
## save for a fresh day 1 nobody had touched, with the symbol flashing behind the title on every
## launch and the *next* launch showing a day brief for a day nobody played. `_resume` is empty for
## a fresh run, so `_write_dawn_for_a_resumed_run()`'s own guard means the call does nothing at
## all — asserted directly, against the function itself, rather than the whole world `_start_day()`
## needs to run for real.
func _test_fresh_boot_writes_nothing_until_the_title_is_dismissed(t) -> void:
	GameState.start_run(345)
	_with_forced_save(func() -> void:
		var main: Node2D = _MAIN_SCRIPT.new()
		t.check(main._resume.is_empty(), "a fresh run's own default — nothing to resume")

		main._write_dawn_for_a_resumed_run()
		t.check(not GameSave.has_save(), "a fresh boot writes nothing at all")

		main.free()
	)

## The held restart reaches the same case as a fresh boot: `main._restart_run()`'s own
## `GameSave.clear()` leaves `GameSave.try_resume()` nothing to find on the reload that follows, so
## the reloaded boot's own `_resume` is empty and its dawn write does nothing either — asserted by
## driving `try_resume()` for real against a save that was just cleared, the same shape the reload
## itself reaches.
func _test_a_restart_writes_nothing_until_the_next_titles_dismissed(t) -> void:
	GameState.start_run(346)
	_with_forced_save(func() -> void:
		t.check(GameSave._write_now(true), "a save exists before the restart")
		GameSave.clear()
		t.check(not GameSave.has_save(), "the held restart clears it")

		var resume := GameSave.try_resume()
		t.check(resume.is_empty(), "the reloaded boot's own try_resume() finds nothing to resume")

		var main: Node2D = _MAIN_SCRIPT.new()
		main._resume = resume
		main._write_dawn_for_a_resumed_run()
		t.check(not GameSave.has_save(), "and its own dawn write does nothing either")

		main.free()
	)

## A resumed boot with a charged nerve: `main._ready()` calls `GameState.finish_day()` (driven here
## directly, the same as `_test_day_under_way_load_costs_one_nerve()` above) before `_start_day()`
## and this write ever run, so the reduced nerve count is already the live `GameState`'s own by the
## time this lands — and it is what the write carries to disk, with `day_under_way: false`, before
## the title or the day brief behind it is ever shown.
func _test_resumed_boot_with_a_charged_nerve_writes_the_reduced_nerve_count(t) -> void:
	GameState.start_run(347)
	GameState.day = 4
	GameState.nerves = 5
	GameState.begin_day()
	t.check(GameSave._write_now(true), "the original mid-day save")

	var resume := GameSave._read_now()
	t.check(resume.get("day_under_way") == true, "the load finds a day under way")
	GameState.finish_day(GameEnums.DayResult.LOST_HARD_FAIL)
	t.check(GameState.nerves == 4, "main._ready() charges its one nerve before _start_day() runs")

	_with_forced_save(func() -> void:
		var main: Node2D = _MAIN_SCRIPT.new()
		main._resume = resume
		main._write_dawn_for_a_resumed_run()

		var after := GameSave._read_now()
		t.check(after.get("day_under_way") == false,
				"the boot write says nothing has been played in the retry yet")
		t.check(GameState.nerves == 4,
				"and the reduced nerve count the load already charged is what landed on disk")

		main.free()
	)

## **The regression this whole commit exists for.** A day engaged with no write beside it would
## leave the save on disk saying `day_under_way: false` — correctly written at dawn, for a day
## nobody had touched yet — for the entire time between the title closing and the next moment
## something else happened to write. A crash, a force-kill, or a backgrounded mobile tab whose page
## is simply discarded never sends a notification at all any more (see the two writes above), so a
## day playtested start to finish and killed right after would have resumed for free were
## `_engage_the_day()` not the one place `_on_title_start()` (with no resume) reaches to write
## immediately. Asserted directly: dismissing a fresh day 1's title, with nothing else run at all,
## already leaves the save on disk saying the day is under way.
func _test_dismissing_a_fresh_titles_start_writes_the_save_under_way(t) -> void:
	# A fresh run, since an earlier test in this suite may have left `GameState.ending` set —
	# `GameSave._write_now()` refuses once an ending is set, on purpose, and `start_run()` is the
	# same reset an ordinary day 1 boot itself performs before ever reaching the title.
	GameState.start_run(123)
	_with_forced_save(func() -> void:
		var main := _bare_gate_main(t)
		t.check(main._resume.is_empty(), "a fresh run carries no resume")

		t.check(not GameSave.has_save(), "nothing on disk before the title is dismissed")
		main._on_title_start(ControlsMode.Mode.TAP)
		t.check(not main._resume_gate_open, "no day brief for a fresh run — she is playing already")
		var saved := GameSave._read_now()
		t.check(saved.get("day_under_way") == true,
				"and the save on disk already says so, with nothing else run at all")

		_free_gate_main(t, main)
	)

## The title→day-brief path with nothing charged: `_resume` says the save was written at a day's
## own summary or at an earlier day brief (`day_under_way: false`), so pressing start on the title
## shows the day brief with no lost-day note, and continuing from it — `_on_summary_continued()`'s
## own `_resume_gate_open` branch — is the moment the save actually says the day is under way.
## Also the "second open of a nothing-played-yet save costs nothing" case: nothing here writes
## between the title closing and the day brief's own continue, so a kill anywhere in between finds
## exactly what the screen is already showing — see `_show_the_resume_gate()`'s own doc for why.
func _test_title_leads_to_the_day_brief_with_nothing_charged(t) -> void:
	GameState.start_run(234)
	GameState.day = 7
	GameState.nerves = 5
	_with_forced_save(func() -> void:
		var main := _bare_gate_main(t)
		main._resume = {"day_under_way": false}
		GameSave._write_now(false)

		main._on_title_start(ControlsMode.Mode.TAP)
		t.check(main._summary.is_showing(), "the day brief shows instead of starting the day outright")
		t.check(not main._summary._note.visible, "no lost-day note — the load cost nothing")
		t.check(main._resume_gate_open, "and the day brief's own continue still has to engage the day")
		t.check(GameSave._read_now().get("day_under_way") == false,
				"showing the day brief writes nothing new — the dawn write already said this")

		main._on_summary_continued()
		t.check(not main._summary.is_showing(), "continuing dismisses the brief")
		t.check(not main._resume_gate_open, "and the gate is spent")
		t.check(GameSave._read_now().get("day_under_way") == true,
				"the day is engaged, which the save now says")

		_free_gate_main(t, main)
	)

## The same path with a nerve charged: the day brief carries `main._RESUMED_DAY_LOST_NOTE`.
func _test_title_leads_to_the_day_brief_with_a_charged_nerve(t) -> void:
	GameState.start_run(235)
	_with_forced_save(func() -> void:
		var main := _bare_gate_main(t)
		main._resume = {"day_under_way": true}

		main._on_title_start(ControlsMode.Mode.TAP)
		t.check(main._summary._note.visible
				and main._summary._note.text == _MAIN_SCRIPT._RESUMED_DAY_LOST_NOTE,
				"the day brief carries the lost-day line the load itself charged")

		_free_gate_main(t, main)
	)

## The last-nerve case: the load's own `GameState.finish_day()` call in `_ready()` (not driven here
## — this rig starts past it, with `_run_over` already set the way that call would have left it)
## spent the run's last nerve, so pressing start on the title shows the ending directly — the same
## screen and the same `_on_summary_continued()` path any other run-ending reaches — rather than
## the day brief. `GameState.ending` is already set by the time this is reached, so
## `GameSave._write_now()`'s own refusal (see its doc) means nothing here writes at all, gate or no
## gate.
func _test_title_leads_to_the_ending_on_the_last_nerve(t) -> void:
	_with_forced_save(func() -> void:
		var main := _bare_gate_main(t)
		main._resume = {"day_under_way": true}
		main._run_over = true
		var ending := GameState.ending
		GameState.ending = GameEnums.Ending.BAD

		main._on_title_start(ControlsMode.Mode.TAP)
		t.check(main._ending_shown, "the ending is shown rather than the day brief")
		t.check(not main._resume_gate_open, "so there is no day brief for a later continue to engage")
		t.check(not GameSave.has_save(), "a run that has ended writes nothing, on this path either")

		GameState.ending = ending
		_free_gate_main(t, main)
	)

# ------------------------------------------------------------ confirmation ---

## Records every answer a `settled` callable is given, so a test can count them.
class _Answers extends RefCounted:
	var results: Array[int] = []

	func take(result: int) -> void:
		results.append(result)

## `GameSave._moment_result()`, the pure half of `write()`: every branch of what a save moment comes
## to before any browser has answered, including the web's, which this desktop runner cannot reach
## through `write()` itself. A web page whose storage was refused at boot is a failed save without
## any flush, since a flush there succeeds for a copy no reload finds.
func _test_a_save_moment_answers_by_platform_and_storage(t) -> void:
	t.check(GameSave._moment_result(true, false, true) == GameSave.Result.CONFIRMED,
			"off the web, a closed file is a kept save")
	t.check(GameSave._moment_result(true, true, true) == GameSave.Result.PENDING,
			"on the web, a closed file waits for the browser's answer")
	t.check(GameSave._moment_result(true, true, false) == GameSave.Result.FAILED,
			"on a web page whose storage was refused, the save is not kept, flush or no flush")
	t.check(GameSave._moment_result(false, false, true) == GameSave.Result.FAILED,
			"a file that could not be written is a failed save off the web")
	t.check(GameSave._moment_result(false, true, true) == GameSave.Result.FAILED,
			"and on it")

## Off the web, `write()` itself answers `CONFIRMED` and never calls `settled`: the file closing is
## the confirmation, so a desktop save shows the symbol at once.
func _test_a_desktop_write_is_confirmed_at_once(t) -> void:
	_with_forced_save(func() -> void:
		var answers := _Answers.new()
		var result: int = GameSave.write(true, answers.take)
		t.check(result == GameSave.Result.CONFIRMED, "a desktop write is confirmed at once")
		t.check(GameSave.has_save(), "and the file is there")
		t.check(answers.results.is_empty(), "with nothing left for a later answer to settle")
	)

## A run `uses_save()` refuses, and a run that has already ended, answer `REFUSED`, which draws
## nothing — neither is a save that failed, so neither may show the strike.
func _test_a_refused_or_ended_run_is_not_a_failed_save(t) -> void:
	var answers := _Answers.new()
	t.check(GameSave.write(true, answers.take) == GameSave.Result.REFUSED,
			"the headless runner's refused save is refused, not failed")
	_with_forced_save(func() -> void:
		var ending := GameState.ending
		GameState.ending = GameEnums.Ending.BAD
		t.check(GameSave.write(true, answers.take) == GameSave.Result.REFUSED,
				"a run with an ending is refused, not failed")
		t.check(not GameSave.has_save(), "and writes nothing")
		GameState.ending = ending
	)
	t.check(answers.results.is_empty(), "neither ever answers later")

## The race `GameSave._settle()` exists for: the page's answer and the timeout both settle the same
## flush, and only the first counts. A flush that answers after timing out stays failed rather than
## taking back the strike already shown, and a timeout after an answer changes nothing.
func _test_a_flush_settles_once_whichever_answer_comes_first(t) -> void:
	var answered := _Answers.new()
	var token := GameSave._register_flush(answered.take)
	GameSave._on_flush_answered([float(token), ""])
	GameSave._settle(token, GameSave.Result.FAILED, "timed out")
	t.check(answered.results.size() == 1 and answered.results[0] == GameSave.Result.CONFIRMED,
			"the browser's success settles the flush, and the later timeout does nothing")

	var timed_out := _Answers.new()
	token = GameSave._register_flush(timed_out.take)
	GameSave._settle(token, GameSave.Result.FAILED, "timed out")
	GameSave._on_flush_answered([float(token), ""])
	t.check(timed_out.results.size() == 1 and timed_out.results[0] == GameSave.Result.FAILED,
			"a timeout settles the flush as failed, and a late success does not reverse it")

	var failed := _Answers.new()
	token = GameSave._register_flush(failed.take)
	GameSave._on_flush_answered([float(token), "Connection to Indexed Database server lost"])
	t.check(failed.results.size() == 1 and failed.results[0] == GameSave.Result.FAILED,
			"the page's failure message settles the flush as failed")
	t.check(GameSave._pending_flushes.is_empty(), "and nothing is left waiting")

## A held restart reloads `main` while a flush may still be out, so the `settled` callable can name
## an object that no longer exists by the time the browser answers. Settling it does nothing.
func _test_a_flush_whose_listener_is_gone_settles_quietly(t) -> void:
	var gone := Node.new()
	var token := GameSave._register_flush(Callable(gone, &"set_name"))
	gone.free()
	GameSave._settle(token, GameSave.Result.CONFIRMED, "")
	t.check(GameSave._pending_flushes.is_empty(), "the flush is settled without calling anything")

# ----------------------------------------------------------------- the symbol ---

## *"we should show it until it is fully confirmed saved"* — while a save is unanswered the symbol
## is fully shown and nothing counts down, however long the browser takes.
func _test_the_symbol_holds_with_no_timer_while_a_save_is_pending(t) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin()
	showing.advance(SaveIndicator.MIN_SHOWN_SECONDS + SaveIndicator.FADE_SECONDS + 10.0)
	t.check(showing.alpha() == 1.0, "a pending save stays fully shown past every minimum and the fade")
	t.check(not showing.struck, "and plain, since nothing has failed yet")

## *"okay always show it. but show it for at least a second"* — a desktop save is answered in the
## frame it begins, and the symbol still shows, fully, for a second and then fades.
func _test_a_save_answered_at_once_shows_for_a_second_then_fades(t) -> void:
	var showing := SaveIndicator.Showing.new()
	t.check(showing.is_idle() and showing.alpha() == 0.0, "nothing shows before a save")
	showing.begin()
	showing.settle(true)
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
	showing.begin()
	showing.advance(1.0)
	t.check(showing.alpha() == 1.0, "fully shown when the minimum has run out but the save has not answered")
	showing.advance(2.0)
	t.check(showing.alpha() == 1.0, "and fully shown at 3s")
	showing.settle(true)
	t.check(showing.alpha() == 1.0, "the answer itself does not dim it")
	showing.advance(0.2)
	t.check(showing.alpha() > 0.0 and showing.alpha() < 1.0, "the fade begins straight away")
	showing.advance(SaveIndicator.FADE_SECONDS)
	t.check(showing.is_idle(), "and runs its 1.5s")

func _test_a_second_save_keeps_the_symbol_up_until_both_are_answered(t) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin()
	showing.begin()
	showing.settle(true)
	showing.advance(SaveIndicator.MIN_SHOWN_SECONDS + SaveIndicator.FADE_SECONDS + 1.0)
	t.check(showing.alpha() == 1.0, "one answered save of two leaves the symbol up, untimed")
	showing.settle(true)
	showing.advance(0.2)
	t.check(showing.alpha() > 0.0 and showing.alpha() < 1.0, "the second answer lets it fade")

## *"if it fails it show for at least 10s"* — however fast the failure came back, the struck
## picture is fully shown for ten seconds from the strike.
func _test_a_failure_answered_at_once_shows_struck_for_ten_seconds(t) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin()
	showing.settle(false)
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
	showing.begin()
	showing.advance(5.0)
	t.check(not showing.struck and showing.alpha() == 1.0, "plain and full while the flush is out")
	showing.settle(false)
	showing.advance(9.9)
	t.check(showing.struck and showing.alpha() == 1.0, "struck and fully shown at 14.9s")
	showing.advance(0.2)
	t.check(showing.struck and showing.alpha() < 1.0, "fading after 15s")

## A save beginning while the symbol fades brings it back to full with the second restarted; one
## beginning while it is already fully shown does not restart that clock.
func _test_a_save_beginning_mid_fade_restarts_the_second(t) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin()
	showing.settle(true)
	showing.advance(1.0 + SaveIndicator.FADE_SECONDS * 0.5)
	t.check(showing.alpha() > 0.0 and showing.alpha() < 1.0, "fading")
	showing.begin()
	t.check(showing.alpha() == 1.0, "a new save brings it back to full")
	showing.settle(true)
	showing.advance(0.99)
	t.check(showing.alpha() == 1.0, "full for a new second from the new save")
	showing.advance(0.02)
	t.check(showing.alpha() < 1.0, "and then fading")

func _test_a_save_beginning_while_fully_shown_does_not_restart_the_second(t) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin()
	showing.settle(true)
	showing.advance(0.6)
	showing.begin()
	showing.settle(true)
	showing.advance(0.5)
	t.check(showing.alpha() < 1.0, "1.1s after the symbol appeared it fades, the second save or not")
	var waiting := SaveIndicator.Showing.new()
	waiting.begin()
	waiting.settle(true)
	waiting.advance(0.6)
	waiting.begin()
	waiting.advance(5.0)
	t.check(waiting.alpha() == 1.0, "though the symbol still waits for the second save's answer")
	waiting.settle(true)
	waiting.advance(0.2)
	t.check(waiting.alpha() < 1.0, "and fades once it comes")

## A failure while another save is out strikes the picture at once, with its ten seconds starting
## then rather than at the last answer.
func _test_a_failure_while_another_save_is_pending_strikes_at_once(t) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin()
	showing.begin()
	showing.advance(4.0)
	showing.settle(false)
	t.check(showing.struck and showing.pending == 1, "struck while the other save is unanswered")
	showing.advance(20.0)
	t.check(showing.struck and showing.alpha() == 1.0, "and held while that save is pending")
	showing.settle(true)
	t.check(showing.struck, "a kept answer after a failure in the same batch leaves it struck")
	showing.advance(0.2)
	t.check(showing.struck and showing.alpha() < 1.0, "fading, the ten seconds having run from the strike")
	var timed := SaveIndicator.Showing.new()
	timed.begin()
	timed.begin()
	timed.settle(false)
	timed.advance(4.0)
	timed.settle(true)
	timed.advance(5.9)
	t.check(timed.struck and timed.alpha() == 1.0, "ten seconds count from the strike, not the last answer")
	timed.advance(0.2)
	t.check(timed.alpha() < 1.0, "so it fades 10s after the strike")

## Every failure restarts the ten seconds.
func _test_each_failure_restarts_the_struck_clock(t) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin()
	showing.settle(false)
	showing.advance(6.0)
	showing.begin()
	showing.settle(false)
	showing.advance(9.9)
	t.check(showing.struck and showing.alpha() == 1.0, "the newest failure's ten seconds are running")
	showing.advance(0.2)
	t.check(showing.alpha() < 1.0, "and end ten seconds after it")

## *The strike follows the newest answer*: a batch that was all kept clears an earlier batch's
## strike, even with its ten seconds unspent, and the plain symbol then gets its own second.
func _test_a_kept_batch_after_a_failed_one_clears_the_strike(t) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin()
	showing.settle(false)
	showing.advance(3.0)
	showing.begin()
	showing.settle(true)
	t.check(not showing.struck, "the strike clears though 7s of its ten were left")
	t.check(showing.alpha() == 1.0, "the symbol is still up for the moment")
	showing.advance(0.2)
	t.check(showing.alpha() < 1.0, "the plain symbol's second ran from when the symbol appeared")
	# Mid-fade, the new save restarts the second, which the plain symbol then owes.
	var fading := SaveIndicator.Showing.new()
	fading.begin()
	fading.settle(false)
	fading.advance(10.5)
	t.check(fading.struck and fading.alpha() < 1.0, "the struck picture is fading")
	fading.begin()
	fading.settle(true)
	t.check(not fading.struck and fading.alpha() == 1.0, "a kept save brings it back plain and full")
	fading.advance(0.99)
	t.check(fading.alpha() == 1.0, "for its own second")
	fading.advance(0.02)
	t.check(fading.alpha() < 1.0, "then fades")

## `begin()` no longer clears the strike: a save still unanswered does not hide a known failure.
func _test_begin_does_not_clear_a_strike_while_its_save_is_unanswered(t) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin()
	showing.settle(false)
	showing.advance(2.0)
	showing.begin()
	t.check(showing.struck and showing.alpha() == 1.0, "struck and full with the new save unanswered")
	showing.advance(30.0)
	t.check(showing.struck and showing.alpha() == 1.0, "and for as long as it stays unanswered")
	showing.settle(false)
	t.check(showing.struck, "a failed answer keeps the strike")
	showing.advance(9.9)
	t.check(showing.struck and showing.alpha() == 1.0, "with a fresh ten seconds")

## Once the symbol has faded away the strike is forgotten: the next save comes up plain.
func _test_a_struck_symbol_that_faded_away_is_forgotten(t) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.begin()
	showing.settle(false)
	showing.advance(10.0 + SaveIndicator.FADE_SECONDS + 0.1)
	t.check(showing.is_idle() and not showing.struck, "gone")
	showing.begin()
	t.check(not showing.struck and showing.alpha() == 1.0, "the next save comes up plain and full")
	showing.settle(true)
	t.check(not showing.struck, "and stays plain once kept")

## *"if saving is unavailable it should show up with a strike through"* — struck if either of two
## overlapping saves was not kept, whichever answered first.
func _test_a_save_not_kept_is_struck_through_whichever_answers_first(t) -> void:
	for order: Array in [[false, true], [true, false]]:
		var showing := SaveIndicator.Showing.new()
		showing.begin()
		showing.begin()
		showing.settle(order[0])
		showing.settle(order[1])
		t.check(showing.struck, "a save of the pair that was not kept strikes the symbol")
		showing.advance(9.9)
		t.check(showing.alpha() == 1.0, "held ten seconds")

func _test_a_stray_answer_shows_nothing(t) -> void:
	var showing := SaveIndicator.Showing.new()
	showing.settle(false)
	t.check(showing.is_idle() and showing.alpha() == 0.0,
			"an answer with no save begun raises nothing")
	showing.begin()
	t.check(showing.pending == 1, "and is not counted against the next save")

## The whole path through `main._save_now()`: a run `GameSave.uses_save()` refuses — here the
## headless runner — leaves the symbol dark rather than struck.
func _test_main_draws_nothing_for_a_refused_run(t) -> void:
	var indicator := SaveIndicator.new()
	t.add_child(indicator)
	var main: Node2D = _MAIN_SCRIPT.new()
	main._save_indicator = indicator
	main._save_now(true)
	t.check(indicator._showing.is_idle() and not indicator._showing.struck,
			"a refused save leaves the symbol dark")
	main.free()
	indicator.free()

func _test_main_shows_a_desktop_save_confirmed_at_once(t) -> void:
	_with_forced_save(func() -> void:
		var indicator := SaveIndicator.new()
		t.add_child(indicator)
		var main: Node2D = _MAIN_SCRIPT.new()
		main._save_indicator = indicator
		main._save_now(true)
		t.check(indicator._showing.pending == 0 and not indicator._showing.is_idle(),
				"a desktop save is answered at once and the symbol is already showing")
		t.check(not indicator._showing.struck and not indicator.shows_struck(),
				"showing the plain picture")
		main.free()
		indicator.free()
	)

## The struck symbol is its own picture on the `ui` atlas (`art/ui/save_unavailable.svg`), swapped
## in for the plain one rather than drawn over it — so the region has to exist and be a different
## picture, and a kept save afterwards has to swap back.
func _test_a_save_not_kept_swaps_to_the_struck_picture(t) -> void:
	var indicator := SaveIndicator.new()
	t.add_child(indicator)
	t.check(indicator._struck_texture != null and indicator._plain_texture != null
			and indicator._struck_texture != indicator._plain_texture,
			"the plain and the struck pictures are both on the atlas, and different")
	indicator.begin()
	indicator.settle(false)
	t.check(indicator.shows_struck(), "a save not kept shows the struck picture")
	indicator.begin()
	t.check(indicator.shows_struck(), "a new save still unanswered does not hide the failure")
	indicator.settle(true)
	t.check(not indicator.shows_struck(), "and a kept answer swaps back to the plain one")
	indicator.free()
