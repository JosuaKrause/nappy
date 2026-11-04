extends RefCounted
## `SummaryModel`: what each summary screen says, built from a run of the test's own, a day's end
## and `Texts`, with no screen at all — and the run's standing and the resistance tally, worded once
## for the day summary, the brief and the pause.

func run(t) -> void:
	_test_a_won_days_summary_names_the_coming_day(t)
	_test_a_lost_days_summary_says_it_is_tried_again(t)
	_test_a_last_nerve_names_the_checkpoint(t)
	_test_a_lost_sections_summary_carries_its_words(t)
	_test_a_brief_is_the_day_the_nerves_and_the_morning(t)
	_test_an_ending_has_no_continue_and_names_its_day_when_bad(t)
	_test_the_epilogue_names_the_way_out_and_its_clock(t)
	_test_the_tally_counts_errands_and_contacts_lost(t)
	_test_the_standing_line_is_the_pause_screens(t)

func _run_on(day: int, nerves: int) -> RunState:
	var run := RunState.new()
	run.header.day = day
	run.header.nerves = nerves
	return run

func _ended(result: GameEnums.DayResult, reason := "", elapsed := 0.0) -> DayEnd:
	var end := DayEnd.new()
	end.result = result
	end.reason = reason
	end.elapsed_seconds = elapsed
	return end

func _test_a_won_days_summary_names_the_coming_day(t) -> void:
	var run := _run_on(5, 3)
	var model := SummaryModel.day_over(run, _ended(GameEnums.DayResult.WON, "", 84.0))
	t.check(model.kind == SummaryModel.Kind.DAY and model.title == "She fell asleep after 1:24."
			and model.title_is_prose, "a won day's title is the clock it ended on ('%s')" % model.title)
	t.check(model.body("") == "Day 5 of %d\n\nNerves left: ***" % Tuning.RUN_LENGTH_DAYS,
			"its body is the coming day and the nerves carried into it ('%s')" % model.body(""))
	t.check(model.brief == Texts.DAY_BRIEF.get(5, "") and model.heading == "" and model.note == ""
			and model.shows_continue, "with the morning's line, no heading, no note, and a continue")
	run.free()

func _test_a_lost_days_summary_says_it_is_tried_again(t) -> void:
	var run := _run_on(4, 2)
	run.resistance.progress = 2
	var model := SummaryModel.day_over(run, _ended(GameEnums.DayResult.LOST_CRYING,
			"She started crying. There is no settling her now.", 84.0))
	t.check(model.title == "She started crying after 1:24. There is no settling her now.",
			"a crying loss reads the clock into its first sentence ('%s')" % model.title)
	var lines := model.body("").split("\n")
	t.check(lines.has("You try day 4 again.") and lines[lines.size() - 1] == "Errands run: 2 of %d"
			% Tuning.RESISTANCE_GOAL, "it says the day is tried again, then the tally ('%s')"
			% model.body(""))
	var timeout := SummaryModel.day_over(run, _ended(GameEnums.DayResult.LOST_TIMEOUT,
			"Dusk. You are still out.", 180.0))
	t.check(timeout.title == "Dusk. You are still out.", "a timeout shows its reason and no clock")
	run.free()

func _test_a_last_nerve_names_the_checkpoint(t) -> void:
	var run := _run_on(8, Tuning.STARTING_NERVES)
	var end := _ended(GameEnums.DayResult.LOST_TIMEOUT, "Dusk came.")
	end.goes_back = true
	var body := SummaryModel.day_over(run, end).body("")
	t.check(body.contains("Your nerves gave out. Back to day 8.") and not body.contains("again"),
			"a normal run's last nerve names the day she goes back to ('%s')" % body)
	run.free()

func _test_a_lost_sections_summary_carries_its_words(t) -> void:
	var run := _run_on(Tuning.RUN_LENGTH_DAYS, 2)
	run.resistance.progress = 3
	var model := SummaryModel.day_over(run, _ended(GameEnums.DayResult.LOST_HARD_FAIL,
			"It never slowed down.", 30.0), "Escape the city")
	t.check(model.body("") == "Escape the city\n\nNerves left: **",
			"a lost section names itself where the day stands, with no retry line and no tally ('%s')"
			% model.body(""))
	t.check(model.brief == "", "and no morning line")
	run.free()

func _test_a_brief_is_the_day_the_nerves_and_the_morning(t) -> void:
	var run := _run_on(1, 4)
	var model := SummaryModel.brief_for(run, Texts.RESUMED_DAY_LOST)
	t.check(model.kind == SummaryModel.Kind.BRIEF and model.title == "Day 1 of %d"
			% Tuning.RUN_LENGTH_DAYS and not model.title_is_prose, "a brief names the day plainly")
	t.check(model.body("") == "Nerves left: ****" and model.note == Texts.RESUMED_DAY_LOST
			and model.brief == Texts.DAY_BRIEF[1], "with the nerves, its note and the morning's line")
	var section := SummaryModel.brief_for(run, "", "Escape the building")
	t.check(section.title == "Escape the building" and section.title_is_prose
			and section.brief == "" and section.note == "", "a section's brief carries its own words")
	run.free()

func _test_an_ending_has_no_continue_and_names_its_day_when_bad(t) -> void:
	var run := _run_on(9, 0)
	run.header.play_ticks = 22620
	var bad := SummaryModel.ending(run, GameEnums.Ending.BAD)
	t.check(bad.kind == SummaryModel.Kind.ENDING and not bad.shows_continue
			and bad.heading == Texts.ENDING_HEADING[GameEnums.Ending.BAD],
			"an ending has its heading and no continue")
	t.check(bad.body_prose == Texts.ENDING_BODY[GameEnums.Ending.BAD], "its prose is its paragraph")
	t.check(bad.body("PROSE") == Texts.ENDING_PLAYED % ["PROSE",
			RunState.format_clock(run.header.play_seconds()), Texts.ENDING_DAY_REACHED % 9],
			"and its body the paragraph, the time played and the day")
	var good := SummaryModel.ending(run, GameEnums.Ending.GOOD)
	t.check(not good.body("").contains("made it to day"), "the good ending names no day")
	run.free()

func _test_the_epilogue_names_the_way_out_and_its_clock(t) -> void:
	var end := _ended(GameEnums.DayResult.WON, "", 42.5)
	end.exit_reached = CityEdge.Kind.TUNNEL
	var model := SummaryModel.epilogue(end)
	t.check(model.kind == SummaryModel.Kind.EPILOGUE and model.shows_continue
			and model.heading == Texts.FINALE_HEADING and model.title == Texts.FINALE_TITLE,
			"the epilogue has its heading and title, and a continue back to the title")
	t.check(model.body_prose == Texts.FINALE_BODY[CityEdge.Kind.TUNNEL]
			and model.body("P") == Texts.FINALE_OUT_IN % ["P", RunState.format_clock(42.5)],
			"its body is the way she took and the clock she took it on")

func _test_the_tally_counts_errands_and_contacts_lost(t) -> void:
	var run := _run_on(6, 3)
	run.resistance.progress = 1
	t.check(SummaryModel.resistance_tally(run) == "Errands run: 1 of %d" % Tuning.RESISTANCE_GOAL,
			"the errands run of the goal")
	run.resistance.failed_steps.assign([4])
	t.check(SummaryModel.resistance_tally(run).ends_with(Texts.SUMMARY_TALLY_LOST_ONE),
			"one contact lost")
	run.resistance.failed_steps.assign([4, 7])
	t.check(SummaryModel.resistance_tally(run).ends_with(Texts.SUMMARY_TALLY_LOST % 2),
			"several contacts lost")
	run.resistance.progress = Tuning.RESISTANCE_GOAL
	t.check(SummaryModel.resistance_tally(run) == Texts.SUMMARY_TALLY_DONE,
			"and done enough once the last night's work is on offer")
	run.free()

## The pause screen's standing line is the summary's day and nerves lines, joined as it always read.
func _test_the_standing_line_is_the_pause_screens(t) -> void:
	var run := _run_on(7, 3)
	t.check(SummaryModel.standing_line(run) == "Day 7 of %d     ·     Nerves left: ***"
			% Tuning.RUN_LENGTH_DAYS, "the pause reads 'Day 7 of 14 · Nerves left' with stars ('%s')"
			% SummaryModel.standing_line(run))
	run.free()
