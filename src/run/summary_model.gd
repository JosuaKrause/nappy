class_name SummaryModel
extends RefCounted
## What one summary screen says: the screen between days, a day brief, the end of a run and the
## escape's last screen. Pure: it reads the run (`RunState`), the day's end (`DayEnd`) and the words
## (`Texts`), holds no node and draws nothing. `DaySummary` renders it; the only thing left to the
## screen is breaking a line between sentences to its label's width (`SentenceLines`), which needs
## the label's font.
##
## Also the one place the run's standing (the day of fourteen and the nerves left) and the
## resistance tally are worded: the pause screen reads `standing_line()`.

## Which screen this is.
enum Kind {
	## A day brief: a resumed day's, or a section's of the escape.
	BRIEF,
	## The summary of a day that ended, or of a lost section.
	DAY,
	## The end of a run.
	ENDING,
	## The escape's last screen, the way out behind her.
	EPILOGUE,
}

var kind := Kind.BRIEF
## The big heading above the title; empty on a screen that has none, which hides it.
var heading := ""
var title := ""
## Whether the title is prose the screen breaks between sentences (the clock line, a section's
## words), rather than a fixed line ("Day 3 of 14", an ending's title).
var title_is_prose := false
## The one line a resumed day's brief adds about what opening the save cost; empty hides it.
var note := ""
## The prose the body opens with — an ending's or the epilogue's paragraph — which the screen breaks
## between sentences to the body's width before `body()` places it; empty when the body has none.
var body_prose := ""
## The morning's own line (`Texts.DAY_BRIEF`); empty on a screen that has none, which hides it.
var brief := ""
## Whether the continue button shows. Not on an ending (Playtest 28 finding 4: "the game over screen
## cannot have a continue button"): the held restart stays, and every other screen carries on.
var shows_continue := true

## The body's format: its first slot is the opening prose as the screen broke it, the rest are
## `_body_fill`. A body with no prose is its text after an empty opening.
var _body_shape := "%s%s"
var _body_fill: Array = [""]

## The body as drawn, with `prose` — `body_prose` as the screen broke it — in its place.
func body(prose: String) -> String:
	var fill: Array = [prose]
	fill.append_array(_body_fill)
	return _body_shape % fill

func _plain_body(text: String) -> void:
	_body_shape = "%s%s"
	_body_fill = [text]

# ------------------------------------------------------------- the screens ---

## The day brief: what a saved game opens on once the title's start is pressed, and the screen each
## section of the escape opens on. Three things, no more: the day (or the section's own words,
## `section_title`, where "Day N of 14" stands), the nerves as the run holds them, and the morning's
## own line, which a section has none of. `note` is what opening the save cost (`Texts.RESUMED_*`),
## or `""` for a save that cost nothing and for a section.
static func brief_for(run: RunState, note_line := "", section_title := "") -> SummaryModel:
	var model := SummaryModel.new()
	model.kind = Kind.BRIEF
	model.note = note_line
	if section_title == "":
		model.title = day_line(run.header.day)
	else:
		model.title = section_title
		model.title_is_prose = true
	model._plain_body(nerves_line(run.header.nerves))
	model.brief = Texts.DAY_BRIEF.get(run.header.day, "") if section_title == "" else ""
	return model

## The summary of a day that just ended, or of a lost section of the escape (`section_title`, its
## own words, standing where "Day N of 14" stands).
##
## **Everything but the one line about the day that ended is the coming day's.** The title is the
## clock the day ended on, worded by `clock_line()`; the day, the nerves and the morning's line read
## the run as it stands now — a win has already moved `run.header.day` on, and a loss leaves it on
## the day being retried, so the screen names the day she is about to walk.
##
## **`end.goes_back` is a normal run's last nerve**: the run is back at its checkpoint's dawn with
## every nerve, so the line that says she tries the day again names the day she goes back to
## instead (gentle-osprey, the player's own example: "Back to day 8"). A lost section reports its
## reason like any lost day (minty-lemur #785), and its words say which is tried again; a section has
## no morning line and no tally of its own.
static func day_over(run: RunState, end: DayEnd, section_title := "") -> SummaryModel:
	var model := SummaryModel.new()
	model.kind = Kind.DAY
	model.title = clock_line(end.result, end.reason, RunState.format_clock_seconds(end.elapsed_seconds))
	model.title_is_prose = true
	var day := run.header.day
	var nerves := run.header.nerves
	var retrying := end.result != GameEnums.DayResult.WON and nerves > 0 and section_title == ""
	var lines: Array[String] = [day_line(day) if section_title == "" else section_title]
	lines.append("")
	# The state she carries into the coming day, on a win as much as a loss, drawn as stars.
	lines.append(nerves_line(nerves))
	# The calendar does not move on a loss, so the screen says so — or, when the last nerve sent a
	# normal run back, which day it went back to, and why every star is there again.
	if end.goes_back:
		lines.append(Texts.SUMMARY_BACK_TO_CHECKPOINT % day)
	elif retrying:
		lines.append(Texts.SUMMARY_TRY_AGAIN % day)
	# The tally is the only place the subquest is ever spelled out. In the world it is chalk on a
	# wall.
	if run.has_joined_resistance() and section_title == "":
		lines.append("")
		lines.append(resistance_tally(run))
	model._plain_body("\n".join(lines))
	model.brief = Texts.DAY_BRIEF.get(day, "") if section_title == "" else ""
	return model

## The last screen of a run: its heading, its title, its paragraph and the run's length to the
## millisecond — the one place `run.header.play_seconds()` is ever shown. `which` is the run's ending;
## a rig (`--ending`) names one of its own. The day is shown on the `BAD` ending alone, the only one
## that can end mid-day, and it is the last day played, never advanced past the day a run ends on.
static func ending(run: RunState, which: GameEnums.Ending) -> SummaryModel:
	var model := SummaryModel.new()
	model.kind = Kind.ENDING
	model.heading = Texts.ENDING_HEADING.get(which, Texts.ENDING_HEADING_DEFAULT)
	model.title = Texts.ENDING_TITLE.get(which, Texts.ENDING_TITLE_DEFAULT)
	model.body_prose = Texts.ENDING_BODY.get(which, "")
	var day_reached := Texts.ENDING_DAY_REACHED % run.header.day \
			if which == GameEnums.Ending.BAD else ""
	model._body_shape = Texts.ENDING_PLAYED
	model._body_fill = [RunState.format_clock(run.header.play_seconds()), day_reached]
	model.shows_continue = false
	return model

## The escape's own last screen: the tunnel or the bridge behind her (`end.exit_reached`, a
## `CityEdge.Kind`), and the clock she took it on to the millisecond — and nothing triumphant
## (`docs/NARRATIVE.md`, "No triumphalism"). Not a fourth ending: an ending is a run's outcome, and
## this is the last screen of the sequence the run hands over to.
static func epilogue(end: DayEnd) -> SummaryModel:
	var model := SummaryModel.new()
	model.kind = Kind.EPILOGUE
	model.heading = Texts.FINALE_HEADING
	model.title = Texts.FINALE_TITLE
	model.body_prose = Texts.FINALE_BODY.get(end.exit_reached, Texts.FINALE_BODY_DEFAULT)
	model._body_shape = Texts.FINALE_OUT_IN
	model._body_fill = [RunState.format_clock(end.elapsed_seconds)]
	return model

# ---------------------------------------------------------- the lines, once ---

## "Day N of 14": where the run stands in its calendar, on the summary, the brief and the pause.
static func day_line(day: int) -> String:
	return Texts.SUMMARY_DAY % [day, Tuning.RUN_LENGTH_DAYS]

## The nerves left, as stars (`Texts.nerve_stars()`, data below this layer) — never a digit — on every screen that shows
## them.
static func nerves_line(nerves: int) -> String:
	return Texts.SUMMARY_NERVES % Texts.nerve_stars(nerves)

## Where the run stands, on one line: the pause screen's, the day and the nerves it covers in the HUD.
static func standing_line(run: RunState) -> String:
	return Texts.PAUSE_STANDING % [day_line(run.header.day), nerves_line(run.header.nerves)]

## The resistance's tally: the errands run of the goal and the contacts lost, or that the work is
## done enough once the last night's sabotage is on offer. The morning's line is not part of it.
static func resistance_tally(run: RunState) -> String:
	if run.sabotage_available():
		return Texts.SUMMARY_TALLY_DONE
	var done := run.resistance.progress
	var lost := run.resistance.failed_steps.size()
	var line := Texts.SUMMARY_TALLY % [done, Tuning.RESISTANCE_GOAL]
	if lost > 0:
		line += Texts.SUMMARY_TALLY_LOST_ONE if lost == 1 else Texts.SUMMARY_TALLY_LOST % lost
	return line

## The line that says when the day ended — the ask behind M154: *"can you show the time of the day
## when dieing/completing a day ... fell asleep after xx:xx or something like that"*. `clock` is the
## HUD clock's own `m:ss` (`RunState.format_clock_seconds()`), never the ending screen's millisecond
## form, which the player named as what they did not want here.
##
## Phrased per outcome, because `reason` is not a single shape: a crying loss's reason names the
## moment itself ("She started crying. ...") so the clock reads into that first sentence, and every
## other reason keeps its own sentence whole with the clock as a sentence of its own after it. A
## timeout shows no clock at all: dusk is the whole day, and printing the day's own length back is
## the total the player does not want here.
static func clock_line(result: GameEnums.DayResult, reason: String, clock: String) -> String:
	match result:
		GameEnums.DayResult.WON:
			return Texts.SUMMARY_FELL_ASLEEP % clock
		GameEnums.DayResult.LOST_TIMEOUT:
			return reason
		GameEnums.DayResult.LOST_CRYING:
			var cut := reason.find(". ")
			if cut == -1:
				return Texts.SUMMARY_REASON_AFTER % [reason, clock]
			return Texts.SUMMARY_REASON_AFTER_REST % [reason.substr(0, cut), clock, reason.substr(cut + 1)]
		_:
			return Texts.SUMMARY_REASON_THEN_CLOCK % [reason, clock]
