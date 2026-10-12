class_name Texts
extends RefCounted
## Every text the game puts on screen, in one place: read down this file to read the game's
## words, change one here and nothing else has to be found. The callers read `Texts.<NAME>`; none
## of them holds a sentence of its own.
##
## **What is in here** is every player-facing string: the title and the pause screen, the help
## lines (a button's symbol is the token `HelpText` already uses, `{pause}` and `{run}`), the HUD's
## lines, the day briefs, the loss and summary lines, the endings and the finale's body, the chalk
## marks and the task line, and the escape's section lines. A text with a value in it (a day
## number, a clock reading) is a format string here (`%d`, `%s`), filled where it is shown.
##
## **What is not** is a developer readout (the dev overlay, the debug HUD lines, a `?debug=1`
## panel) and a line written to a log or an error message: nobody plays those, so they stay at
## the code that writes them. `tests/test_texts_catalogue.gd` fails on a sentence in a quoted
## string anywhere else under `src/`, and holds the one allow-list of those readouts and logs.
##
## **Names are content, never identifiers** (CLAUDE.md): the mother's and the baby's names, if a
## text ever carries them, appear only inside a string here, never in a constant's name.
##
## Prose is written with one space between sentences and no `\n` of its own, except where a text
## is deliberately two lines: `SentenceLines` breaks a multi-sentence text onto the lines its label
## needs.

# --------------------------------------------------------------------- title ---
# Shown by `TitleScreen`: the name, the one-line premise, the walking lesson, the three control
# buttons' captions, the prompt under them and the Hard Mode checkbox.

const TITLE_NAME := "Nappy"
const TITLE_PREMISE := "Fourteen days. One pram. Get her to sleep and get her home."
## One body for every device — see `Texts.WALKING_LESSON_PAUSE`'s own doc for the same collapse made
## there. *(2026-09-06, the player: "in fact I said to remove the keyboard inputs altogether but
## I'm willing to compromise on letting them stay silently".)* The keyboard still walks and runs;
## nothing on screen names a key for it any more. `TouchInput.available()` used to choose between
## this and a keyboard body — with only one body left, this screen has no more use for that fact
## and keeps no member for it.
##
## **Says two things and nothing else.** *(2026-09-07: "the movement tutorial should just say 'Tap
## to walk' and 'Double tap to run'. no mention of tapping her or 'that way'.")* The struck clauses
## named a stop she can still ask for — a press in the joystick's dead zone, or a mouse
## click on her — the same way nothing here has ever named a key: stopping still works, and the
## game simply stops teaching it, exactly as `HUD._teach_the_day()`'s own day-1 line already reads.
const TITLE_BODY := "Tap to walk, double tap to run.\n" \
		+ "Walk to calm ground and stay moving; standing still settles nothing."
const TITLE_CAPTION_JOYSTICK := "On-screen Controls"
const TITLE_CAPTION_TAP := "Tap to Go"
const TITLE_HINT_BEGIN := "press a button to begin"
const TITLE_HINT_AGAIN := "press a button to walk again"
const TITLE_HARD_MODE := "Hard Mode"

# --------------------------------------------------------------------- pause ---
# Shown by `PauseScreen`: where the run stands, the line that names the screen, the walking
# lesson, and the two buttons' captions (the day summary's buttons carry the same two).

const PAUSE_TITLE := "Stopped on the pavement."
## `%d` the day, `%d` the run's length in days, `%s` the nerves as stars.
const PAUSE_STANDING := "Day %d of %d     ·     Nerves left: %s"
## One body for every device. *(2026-09-06, the player: "in fact I said to remove the keyboard
## inputs altogether but I'm willing to compromise on letting them stay silently".)* The keyboard
## still walks, runs, pauses and restarts — nothing here stops reading `KEY_R`/`KEY_Q` or the
## `move_*`/`run`/`pause` actions a key presses — but nothing on screen names a key any more, so
## the keyboard and touch bodies collapse to the one shape that was always the touch body: naming
## the tap is naming a control every device actually has, since a mouse click reads as one too.
##
## **Says two things and nothing else.** *(2026-09-07: "the movement tutorial should just say 'Tap
## to walk' and 'Double tap to run'. no mention of tapping her or 'that way'.")* The struck clauses
## named a stop she can still ask for — a press in the joystick's dead zone, or a mouse
## click on her — the same way nothing here has ever named a key: stopping still works, and the
## game simply stops teaching it, exactly as `HUD._teach_the_day()`'s own day-1 line already reads.
##
## Plain prose, not a string with its own `\n`: `PauseScreen._refresh_body()` breaks it onto more than one line
## through `SentenceLines.break_for_help()`, the sentence-boundary rule every other screen's prose
## goes through in `break_for_label()`, with each `{run}` measured as two letters wide, so this reads
## exactly as it would in the source it was written in.
##
## **The run half names the run button in the joystick scheme only.** *(2026-10-04, the player, inbox
## #533: "joystick run should now say hold <run button> or double tap to run where it makes
## sense".)* The joystick scheme draws a run button from the first frame of play, so its line shows
## it — `{run}` stands for the button's own symbol, see `HelpText` — and the tap scheme, which draws
## none, keeps "double tap to run". That is the one place the body varies, and it varies by the
## scheme the player chose, not by the device.
##
## `%s` is the run half, `RUN_TAP` or `RUN_JOYSTICK`.
const WALKING_LESSON_PAUSE := "Tap to walk, %s. " \
		+ "Walk to calm ground and stay moving; standing still settles nothing."
const BUTTON_CONTINUE := "continue"
const BUTTON_HOLD_TO_RESTART := "hold to restart"

# ----------------------------------------------------------------- the lessons ---
# Said by `HUD` on the day it teaches them, and by the pause screen's body.

## The run half of a lesson in the tap scheme, which draws no run button.
const RUN_TAP := "double tap to run"
## In the joystick scheme, whose run button is drawn: `{run}` is that button's symbol.
const RUN_JOYSTICK := "hold " + HelpText.RUN_TOKEN + " or double tap to run"
## `%s` is the run half, `RUN_TAP` or `RUN_JOYSTICK`.
const WALKING_LESSON := "Tap to walk, %s"
## `%s` is the pause button's symbol, `{pause}`.
const PAUSE_LESSON := "Press %s to pause"
## Said over the whole city when the loudspeakers stop.
const CITY_WENT_QUIET := "The loudspeakers cut out mid-sentence."

# ------------------------------------------------------------------------ HUD ---
# The two meter bars' labels and the task line.

const METER_SLEEPINESS := "SLEEPINESS"
const METER_EXCITEMENT := "EXCITEMENT"
## The task line: `%s` is the step's header, lowercased.
const TASK_LINE := "out there: %s"

# ------------------------------------------------------------------ day briefs ---
# Shown by `DaySummary` on the screen between two days, under the day and the nerves. One or two
# plain sentences a morning, under `docs/NARRATIVE.md`'s tone rules: nobody explains the politics,
# the danger is noise, nothing triumphant. Each names what that day introduces, and a line that
# would give a task away says something else that is true that morning instead.

## One or two plain sentences a morning, in American English, under `docs/NARRATIVE.md`'s tone
## rules — nobody explains the politics, the danger is noise, nothing triumphant. Each names the
## thing that day introduces, so this is also where a new obstacle is first heard of; a line is
## not tied to its own day's resistance task or once-only happening, so one that would give a
## task away says something else that is true that morning instead. Read directly off
## `GameState.day` rather than a parameter, since the same table has to answer for both
## `show_day_brief()` (a resumed run's own gate) and `show_day()` (the ordinary transition every
## other day reaches this screen through) — a static fact about the calendar day, never about
## what an attempt touched, so a lost day's own line reads exactly as it did this morning.
##
## Written as plain prose, one space between sentences and no `\n` of its own: `SentenceLines
## .break_for_label()` breaks a multi-sentence entry onto more than one line only where `_brief`'s
## own width needs it to, at whichever sentence end splits it most evenly.
const DAY_BRIEF := {
	1: "She won't settle indoors. It is quiet in the park. Walk until she sleeps, then bring "
			+ "her home.",
	2: "There are bicycles on the sidewalk again.",
	3: "The streets smell of smoke today.",
	4: "It feels like there are more police around now.",
	5: "They put up masts at the intersections overnight.",
	6: "A curfew was announced today. There is not as much time. There are rumors of chalk "
			+ "messages in alleys.",
	7: "There are more posters than yesterday. The same face is on most of them.",
	8: "A van took someone from the next street before dawn.",
	9: "They have closed the districts off from each other. There are gatehouses at the crossings.",
	10: "The stores on the square are boarded up.",
	11: "A door down the hall was sealed in the night. The name is still on the bell.",
	12: "They are fencing off the parks.",
	13: "There are army trucks on the main road.",
	14: "The last night.",
}

# ------------------------------------------------------- day and run summaries ---
# `DaySummary`'s lines about the day that just ended, and the nerves.

## `%d` the day, `%d` the run's length in days.
const SUMMARY_DAY := "Day %d of %d"
## `%s` the nerves as stars.
const SUMMARY_NERVES := "Nerves left: %s"
## A lost day that is tried again; `%d` is the day.
const SUMMARY_TRY_AGAIN := "You try day %d again."
## A normal run's last nerve, sent back to its checkpoint; `%d` is that day.
const SUMMARY_BACK_TO_CHECKPOINT := "Your nerves gave out. Back to day %d."
## When the day ended, `%s` the clock as `m:ss`. A won day.
const SUMMARY_FELL_ASLEEP := "She fell asleep after %s."
## A lost day whose reason is one sentence: `%s` the reason, `%s` the clock.
const SUMMARY_REASON_AFTER := "%s after %s."
## A lost day whose reason is more than one sentence: the first, the clock, the rest.
const SUMMARY_REASON_AFTER_REST := "%s after %s.%s"
## Any other reason, whole, with the clock a sentence of its own after it.
const SUMMARY_REASON_THEN_CLOCK := "%s After %s."
## The resistance tally once the work is done enough.
const SUMMARY_TALLY_DONE := "You have done enough. There is one more night."
## `%d` errands run, `%d` the goal.
const SUMMARY_TALLY := "Errands run: %d of %d"
## Appended to the tally; `%d` contacts lost and `%s` the plural ending.
const SUMMARY_TALLY_LOST := "   (%d contact%s lost)"

## What a day's loss says. The key is the id of what ended the day (an event's id, or a
## `ParkCordon` cause); `DAY_LOST_DEFAULT` answers one that has no line of its own.
const DAY_LOST_DUSK := "Dusk. You are still out."
const DAY_LOST_CRYING := "She started crying. There is no settling her now."
const DAY_LOST_DEFAULT := "It went wrong."
const HARD_FAIL_TEXT := {
	"abduction": "The van door opened. Nobody saw where you went.",
	"alley_robbery": "They were waiting in the alley.",
	# The same man, sent after her by a handed-over task rather than met in an alley, so the line
	# is the alley robber's with the alley taken out of it.
	"robber_giving_chase": "They were waiting for you.",
	# The van's own guard, sent after her the same way — but he is the door's own man rather than
	# the alley's, so his line follows `door_guard`'s tone (a detention, not a killing) with the
	# package named as the reason, the same "what is lost is named, never dwelt on" rule.
	"van_guard_giving_chase": "He caught up with the package still on her. They took her in.",
	# The pursuer on foot a torn poster sends, or an investigating car lets out — the robber's line
	# in a uniform: who caught her, then what it means, plainly, with the poster left unnamed, since
	# the same man gets out of a car that never saw one torn.
	"policeman_giving_chase": "The policeman caught up with you. They took you in.",
	"guardsman_giving_chase": "The guard caught up with you. They took you in.",
	"firefight": "You walked into the middle of it.",
	# Not an event, and the only hard fail the player can walk into rather than be caught by.
	"car_strike": "It never slowed down. You were in the road.",
	# The patrol car strikes the way a car does, in front of it on the carriageway, so its line is
	# the car's with the car named.
	"police_patrol": "The patrol car never slowed down. You were in the road.",
	# The fire engine, driving to the fire down a street she stood in: a car's line with the engine named.
	"fire_truck": "The fire engine never slowed down. You were in the road.",
	# Act I's two, and they are deliberately the most ordinary sentences in this table:
	# the danger act I was missing is not sinister, it is a street.
	"cyclist": "The bell, and then the bike. She is screaming.",
	"reversing_lorry": "It never saw you. Nobody was looking behind it.",
	# The escape's own catch, on the stairs rather than the street — the same figure as
	# `roadblock`'s guard (`EventCatalogue`, `masked_pursuer`'s own doc), and the same tone rule
	# the rest of this table already keeps: what is lost is named, never dwelt on.
	"masked_pursuer": "He caught you on the stairs.",
	# The door's own guard, after she walked under a raised boom rather than through a hut: a
	# detention, not a death — *"She gets detained/imprisoned or whatever in that case"* — said as
	# plainly as the rest of the table, with the reason in the first half and the baby left out of
	# it, since the regime never puts her in narrative danger directly (docs/NARRATIVE.md, the
	# tone rules).
	"door_guard": "You went under the barrier. They took you in.",
	# Day 12's park, cordoned off by the police with her still inside (`ParkCordon`): not a catch
	# but a place closed round her, said as plainly as the rest, with what it means left to the
	# reader.
	"park_cordon": "They taped the park shut with you inside.",
}

# ----------------------------------------------------------------- resumed day ---
# The day brief's note for a run opened from a save that said a day was under way.

const RESUMED_DAY_LOST := "Left before the day ended. That cost a nerve — it starts over from dawn."
## `%d` is the checkpoint's day.
const RESUMED_LAST_NERVE := "Left before the day ended. That was the last nerve — back to day %d."

# --------------------------------------------------------------------- endings ---
# `DaySummary.show_ending()`: a big heading, the title under it, and the body (then the run's
# length, and for the hard run's loss the day it ended on).

## The one line on the ending screen that is not writing.
##
## Every ending title in this file is a **sentence out of the fiction** — *"You stop going out."*,
## *"Silence."* — which is right for what they are and is exactly why they do not read as the end
## of anything on their own. A run that has finished has to say so before it says anything else.
##
## **It is not the same word for all three, and that is a decision rather than the request being
## trimmed.** The screen the complaint came off is the `BAD` one, where the nerves ran out, and
## `GAME OVER` is what that is. Stamping it over a run somebody *won* would be telling them they
## lost. `THE END` is the same size, the same weight and the same job on the other two.
const ENDING_HEADING := {
	GameEnums.Ending.BAD: "GAME OVER",
	GameEnums.Ending.NEUTRAL: "THE END",
	GameEnums.Ending.GOOD: "THE END",
}
const ENDING_HEADING_DEFAULT := "THE END"
const ENDING_TITLE := {
	GameEnums.Ending.BAD: "You stop going out.",
	GameEnums.Ending.NEUTRAL: "The city is quiet now.",
	GameEnums.Ending.GOOD: "Silence.",
}
const ENDING_TITLE_DEFAULT := "The end."
## Plain prose, one space between sentences: `show_ending()` breaks it onto more than one line
## through `SentenceLines.break_for_label()`, the same helper `Texts.DAY_BRIEF` and every other screen's
## prose goes through, rather than a `\n` typed into each entry.
const ENDING_BODY := {
	GameEnums.Ending.BAD:
		"There is nothing left in you for another walk. "
		+ "The city goes on without the two of you in it.",
	GameEnums.Ending.NEUTRAL:
		"She sleeps through most nights now. "
		+ "The streets you learned to avoid are empty of everything worth avoiding. "
		+ "Nobody is out.",
	GameEnums.Ending.GOOD:
		"The loudspeakers cut out mid-sentence. "
		+ "For the first time since the masts went up, you walk home in the quiet.",
}
## The bad ending's extra line; `%d` is the last day played.
const ENDING_DAY_REACHED := "\nYou made it to day %d."
## `%s` the body, `%s` the run's length as a clock, `%s` the line above or "".
const ENDING_PLAYED := "%s\n\nTime played: %s%s"

# ---------------------------------------------------------------------- escape ---
# The escape's own last screen, and the line each section of it opens on.

const FINALE_HEADING := "THE END"
const FINALE_TITLE := "You are out."
## The same sentence either way; the two differ in what she stands on. The key is a `CityEdge.Kind`.
## What is behind her, and it is the same sentence either way: she is out, nobody is following,
## and the city is still there. The two differ only in what she is standing on. Plain prose, one
## space between sentences: `show_finale()` breaks it through `SentenceLines.break_for_label()`,
## the same helper the rest of this file's prose goes through, rather than a `\n` of its own.
const FINALE_BODY := {
	CityEdge.Kind.TUNNEL:
		"The mountain closes over the road behind you. "
		+ "She does not wake.",
	CityEdge.Kind.BRIDGE:
		"The water is under you and the city is behind you. "
		+ "She does not wake.",
}
## `%s` the body, `%s` the time the escape took as a clock.
const FINALE_OUT_IN := "%s\n\nOut in: %s"
const ESCAPE_BUILDING := "Escape the building"
const ESCAPE_CITY := "Escape the city"

# ------------------------------------------------------------- the chalk marks ---
# `ResistanceSteps`: for each task day, the chalk mark's own words said as it is touched (the
# `*_BRIEF`), the step's name (the `*_TITLE`), and the short form the task line says (the
# `*_HEADER`) — which names where to go rather than leaking what the task is.

const MARK_TITLE := "A chalk mark"
const MARK_TITLE_MORE := "Another mark"

const NOTE_TITLE := "A note for a stranger"
const NOTE_BRIEF := "Give it to the one who won't stop shouting."
const NOTE_HEADER := "the one who won't stop shouting"

const PACKAGE_TITLE := "The package"
const PACKAGE_BRIEF := "A van is waiting on the sidewalk. Don't come home empty-handed."
const PACKAGE_HEADER := "a van, waiting"

const BURNT_SHELL_TITLE := "The burnt shell"
const BURNT_SHELL_BRIEF := "Take what's in the stroller to the burnt building."
const BURNT_SHELL_HEADER := "the burnt building"

const CROSSING_TITLE := "The crossing"
const CROSSING_BRIEF := "Cross at this district door. See if they let you through."
const CROSSING_HEADER := "the district door"

const NEIGHBOR_TITLE := "Warn the neighbor"
const NEIGHBOR_BRIEF := "They come for your neighbor tonight. Get to them first."
const NEIGHBOR_HEADER := "your neighbor, on the way home"

const MAST_TITLE := "Silence a mast"
const MAST_BRIEF := "Silence the loudspeaker mast. The wire is at its foot."
const MAST_HEADER := "the loudspeaker mast"

const SWING_TITLE := "The swing"
const SWING_BRIEF := "Go to the swing. Get there before they close the gate."
const SWING_HEADER := "the park's own swing"

const ROADBLOCK_TITLE := "Into a roadblock's band"
const ROADBLOCK_BRIEF := "Walk up to the roadblock. See how close they let you come."
const ROADBLOCK_HEADER := "the roadblock"

const LAST_NIGHT_TITLE := "The last night"
const LAST_NIGHT_HEADER := "the power station's front door"
