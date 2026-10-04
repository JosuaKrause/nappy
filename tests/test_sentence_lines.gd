extends RefCounted
## `SentenceLines`, the helper that breaks a screen's prose onto more than one line only where it
## has to, and only between sentences — see `src/ui/sentence_lines.gd`'s own doc for the rule.
##
## Every one of these checks fails against the code before this file's own change: before
## `SentenceLines` existed, `DaySummary.show_day()` wrote `_elapsed_line()`'s two sentences onto
## `_title` unbroken, and `_DAY_BRIEF`'s day-1 entry had no break in it at all — both pinned checks
## below would have read the whole thing as a single line with no `\n` in it.

const SUMMARY_SCENE := preload("res://scenes/ui/day_summary.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause_screen.tscn")

func run(t) -> void:
	_test_a_short_multi_sentence_text_stays_on_one_line(t)
	_test_a_decimal_and_a_clock_reading_never_split(t)
	_test_a_single_long_sentence_is_handed_back_unbroken(t)
	_test_a_too_narrow_multi_sentence_text_breaks_between_every_sentence(t)
	_test_a_day_lost_to_crying_pins_the_players_own_two_lines(t)
	_test_day_ones_brief_breaks_after_the_park_not_after_every_sentence(t)
	_test_every_day_brief_breaks_only_between_sentences(t)
	_test_every_ending_and_finale_body_breaks_only_between_sentences(t)
	_test_the_resumed_day_note_breaks_only_between_sentences(t)
	_test_the_pause_screens_body_breaks_only_between_sentences(t)

# ------------------------------------------------------------- the pure helper ---

func _test_a_short_multi_sentence_text_stays_on_one_line(t) -> void:
	var text := "A. B."
	t.check(SentenceLines._wrap(text, 26, 100000.0) == text,
			"a text that already fits the width keeps no break at all, whatever it is made of")

func _test_a_decimal_and_a_clock_reading_never_split(t) -> void:
	var decimal := "The distance was 1.5 miles today."
	t.check(SentenceLines._split_sentences(decimal) == [decimal],
			"a period followed by a digit, not a space, never ends a sentence — \"1.5\" stays whole")
	var clock := "She started crying after 0:10. There is no settling her now."
	t.check(SentenceLines._split_sentences(clock) == [
				"She started crying after 0:10.", "There is no settling her now."],
			"a period followed by a space still ends a sentence even right after a clock reading")

func _test_a_single_long_sentence_is_handed_back_unbroken(t) -> void:
	var text := "A very long single sentence with no period anywhere inside it at all"
	t.check(SentenceLines._wrap(text, 26, 1.0) == text,
			"one sentence too wide for the width is handed back with no `\\n` of its own, so the " +
			"label's own autowrap is what wraps it, word by word")

func _test_a_too_narrow_multi_sentence_text_breaks_between_every_sentence(t) -> void:
	var wrapped := SentenceLines._wrap("One sentence here. Another one there. And a third.", 26, 1.0)
	t.check(wrapped == "One sentence here.\nAnother one there.\nAnd a third.",
			"a width no sentence can share breaks after every one of them, never inside one")

# -------------------------------------------------------- the two pinned stills ---

## *(2026-09-27, the player: "if a text has multiple sentences like \"She started crying after
## 0:10. There is no settling now.\" the newline comes after the period".)* The exact line quoted
## is `_elapsed_line()`'s own reconstruction of `DayController`'s `"She started crying. There is no
## settling her now."` with the clock worked into the first sentence — see that function's own doc.
func _test_a_day_lost_to_crying_pins_the_players_own_two_lines(t) -> void:
	var summary: CanvasLayer = SUMMARY_SCENE.instantiate()
	t.add_child(summary)
	summary.show_day(GameEnums.DayResult.LOST_CRYING,
			"She started crying. There is no settling her now.", 3, 10.0)
	var title: Label = summary.get_node("Root/Center/Lines/Title")
	t.check(title.text == "She started crying after 0:10.\nThere is no settling her now.",
			"the day summary's title breaks after the first sentence's own period, exactly where " +
			"the player's own example put it")
	summary.queue_free()

## *(2026-09-27, the player's second example, asked whether every sentence gets its own line or the
## break falls only where the text must wrap: "same for \"She won't settle indoors. It is quiet in
## the park. Walk until she sleeps, then bring her home.\" the newline goes after park" — the
## latter.)* Day 1's own `_DAY_BRIEF` entry is exactly this three-sentence text.
func _test_day_ones_brief_breaks_after_the_park_not_after_every_sentence(t) -> void:
	var summary: CanvasLayer = SUMMARY_SCENE.instantiate()
	t.add_child(summary)
	summary.show_day_brief(1, 5)
	var brief: Label = summary.get_node("Root/Center/Lines/Brief")
	t.check(brief.text == "She won't settle indoors. It is quiet in the park.\n" +
			"Walk until she sleeps, then bring her home.",
			"the break falls after \"the park.\", the sentence end that splits the text most " +
			"evenly, not after every sentence")
	summary.queue_free()

# ---------------------------------------------------- every real screen text ---

## Never inside a sentence, and every word survives — run over every day brief, every ending body,
## every finale body, the resumed-day note and the pause screen's own instructions, so a future
## entry in any of those tables is covered by the same sweep rather than only by the two pinned
## cases above.
func _check_breaks_only_between_sentences(t, source: String, label: Label, description: String) -> void:
	var wrapped := SentenceLines.break_for_label(source, label)
	var lines := wrapped.split("\n")
	for i in range(lines.size() - 1):
		var line: String = lines[i]
		t.check(line.ends_with(".") or line.ends_with("?") or line.ends_with("!"),
				"%s breaks only after a sentence's own end, not \"%s\"" % [description, line])
	t.check(" ".join(lines) == source,
			"%s keeps every word — the break neither drops nor rewrites anything in it" % description)

func _test_every_day_brief_breaks_only_between_sentences(t) -> void:
	var summary: CanvasLayer = SUMMARY_SCENE.instantiate()
	t.add_child(summary)
	var brief: Label = summary.get_node("Root/Center/Lines/Brief")
	for day in summary._DAY_BRIEF.keys():
		var source: String = summary._DAY_BRIEF[day]
		_check_breaks_only_between_sentences(t, source, brief, "day %d's brief" % day)
	summary.queue_free()

func _test_every_ending_and_finale_body_breaks_only_between_sentences(t) -> void:
	var summary: CanvasLayer = SUMMARY_SCENE.instantiate()
	t.add_child(summary)
	var body: Label = summary.get_node("Root/Center/Lines/Body")
	for ending in summary._ENDING_BODY.keys():
		var source: String = summary._ENDING_BODY[ending]
		_check_breaks_only_between_sentences(t, source, body, "the %s ending's body" % ending)
	for kind in summary._FINALE_BODY.keys():
		var source: String = summary._FINALE_BODY[kind]
		_check_breaks_only_between_sentences(t, source, body, "the finale body for exit kind %d" % kind)
	summary.queue_free()

## `main._RESUMED_DAY_LOST_NOTE` (`src/main.gd`) — the day brief's own line for a resumed run whose
## save said a day was under way. Quoted here rather than read off `main.gd`, which this item's own
## fence keeps untouched: the two sentences the note is made of.
func _test_the_resumed_day_note_breaks_only_between_sentences(t) -> void:
	var summary: CanvasLayer = SUMMARY_SCENE.instantiate()
	t.add_child(summary)
	var note: Label = summary.get_node("Root/Center/Lines/Note")
	_check_breaks_only_between_sentences(t,
			"Left before the day ended. That cost a nerve — it starts over from dawn.", note,
			"the resumed-day note")
	summary.queue_free()

func _test_the_pause_screens_body_breaks_only_between_sentences(t) -> void:
	var pause: CanvasLayer = PAUSE_SCENE.instantiate()
	t.add_child(pause)
	var body: HelpText = pause.get_node("Root/Center/Lines/Body")
	for joystick in [false, true]:
		var source: String = pause.body_for(joystick)
		var wrapped := SentenceLines.break_for_help(source, body)
		var lines := wrapped.split("\n")
		for i in range(lines.size() - 1):
			t.check(lines[i].ends_with(".") or lines[i].ends_with("?") or lines[i].ends_with("!"),
					"the pause screen's instructions (joystick %s) break only after a sentence's end"
							% joystick)
		t.check(" ".join(lines) == source,
				"the pause screen's instructions (joystick %s) keep every word" % joystick)
	pause.queue_free()
