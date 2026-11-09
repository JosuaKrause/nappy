@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## `SentenceLines`, the helper that breaks a screen's prose onto more than one line only where it
## has to, and only between sentences — see `src/ui/sentence_lines.gd`'s own doc for the rule.
##
## Every one of these checks fails against the code before this file's own change: before
## `SentenceLines` existed, the day summary wrote its clock line's two sentences onto
## `_title` unbroken, and `Texts.DAY_BRIEF`'s day-1 entry had no break in it at all — both pinned checks
## below would have read the whole thing as a single line with no `\n` in it.

const SUMMARY_SCENE := preload("res://scenes/ui/day_summary.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause_screen.tscn")

func run(t) -> void:
	var was_paused: bool = t.get_tree().paused
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
	t.get_tree().paused = was_paused

# ------------------------------------------------------------- the pure helper ---

## A label at `font_size` whose prose wraps to `width`, the two things `break_for_label()` reads off
## a screen's label. Never in the tree.
static func _label(font_size: int, width: float) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.custom_minimum_size.x = width
	return label

func _test_a_short_multi_sentence_text_stays_on_one_line(t) -> void:
	var text := "A. B."
	var wide := _label(26, 100000.0)
	t.check(SentenceLines.break_for_label(text, wide) == text,
			"a text that already fits the width keeps no break at all, whatever it is made of")
	wide.free()

## Where a sentence ends is read where it shows: at a width no two sentences can share, the text
## breaks after every sentence and nowhere else.
func _test_a_decimal_and_a_clock_reading_never_split(t) -> void:
	var narrow := _label(26, 1.0)
	var decimal := "The distance was 1.5 miles today."
	t.check(SentenceLines.break_for_label(decimal, narrow) == decimal,
			"a period followed by a digit, not a space, never ends a sentence — \"1.5\" stays whole")
	var clock := "She started crying after 0:10. There is no settling her now."
	t.check(SentenceLines.break_for_label(clock, narrow)
				== "She started crying after 0:10.\nThere is no settling her now.",
			"a period followed by a space still ends a sentence even right after a clock reading")
	narrow.free()

func _test_a_single_long_sentence_is_handed_back_unbroken(t) -> void:
	var text := "A very long single sentence with no period anywhere inside it at all"
	var narrow := _label(26, 1.0)
	t.check(SentenceLines.break_for_label(text, narrow) == text,
			"one sentence too wide for the width is handed back with no `\\n` of its own, so the " +
			"label's own autowrap is what wraps it, word by word")
	narrow.free()

func _test_a_too_narrow_multi_sentence_text_breaks_between_every_sentence(t) -> void:
	var narrow := _label(26, 1.0)
	var wrapped := SentenceLines.break_for_label(
			"One sentence here. Another one there. And a third.", narrow)
	t.check(wrapped == "One sentence here.\nAnother one there.\nAnd a third.",
			"a width no sentence can share breaks after every one of them, never inside one")
	narrow.free()

# -------------------------------------------------------- the two pinned stills ---

## *(2026-09-27, the player: "if a text has multiple sentences like \"She started crying after
## 0:10. There is no settling now.\" the newline comes after the period".)* The exact line quoted
## is the title `SummaryModel.day_over()` builds from `DayController`'s `"She started crying.
## There is no settling her now."` with the clock worked into the first sentence — see
## `SummaryModel._clock_line()`'s own doc.
func _test_a_day_lost_to_crying_pins_the_players_own_two_lines(t) -> void:
	var summary: CanvasLayer = SUMMARY_SCENE.instantiate()
	t.add_child(summary)
	var end := DayEnd.new()
	end.result = GameEnums.DayResult.LOST_CRYING
	end.reason = "She started crying. There is no settling her now."
	end.elapsed_seconds = 10.0
	var run := RunState.new()
	summary.show_summary(SummaryModel.day_over(run, end), RunFlow.Mode.DAY_OVER)
	var title: Label = summary.get_node("Root/Center/Lines/Title")
	t.check(title.text == "She started crying after 0:10.\nThere is no settling her now.",
			"the day summary's title breaks after the first sentence's own period, exactly where " +
			"the player's own example put it")
	summary.queue_free()

## *(2026-09-27, the player's second example, asked whether every sentence gets its own line or the
## break falls only where the text must wrap: "same for \"She won't settle indoors. It is quiet in
## the park. Walk until she sleeps, then bring her home.\" the newline goes after park" — the
## latter.)* Day 1's own `Texts.DAY_BRIEF` entry is exactly this three-sentence text.
func _test_day_ones_brief_breaks_after_the_park_not_after_every_sentence(t) -> void:
	var summary: CanvasLayer = SUMMARY_SCENE.instantiate()
	t.add_child(summary)
	var run := RunState.new()
	run.header.day = 1
	summary.show_summary(SummaryModel.brief_for(run), RunFlow.Mode.BRIEF)
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
	for day in Texts.DAY_BRIEF.keys():
		var source: String = Texts.DAY_BRIEF[day]
		_check_breaks_only_between_sentences(t, source, brief, "day %d's brief" % day)
	summary.queue_free()

func _test_every_ending_and_finale_body_breaks_only_between_sentences(t) -> void:
	var summary: CanvasLayer = SUMMARY_SCENE.instantiate()
	t.add_child(summary)
	var body: Label = summary.get_node("Root/Center/Lines/Body")
	for ending in Texts.ENDING_BODY.keys():
		var source: String = Texts.ENDING_BODY[ending]
		_check_breaks_only_between_sentences(t, source, body, "the %s ending's body" % ending)
	for kind in Texts.FINALE_BODY.keys():
		var source: String = Texts.FINALE_BODY[kind]
		_check_breaks_only_between_sentences(t, source, body, "the finale body for exit kind %d" % kind)
	summary.queue_free()

## `Texts.RESUMED_DAY_LOST` (`src/ui/texts.gd`) — the day brief's own line for a resumed run whose
## save said a day was under way: the two sentences the note is made of.
func _test_the_resumed_day_note_breaks_only_between_sentences(t) -> void:
	var summary: CanvasLayer = SUMMARY_SCENE.instantiate()
	t.add_child(summary)
	var note: Label = summary.get_node("Root/Center/Lines/Note")
	_check_breaks_only_between_sentences(t,
			Texts.RESUMED_DAY_LOST, note,
			"the resumed-day note")
	summary.queue_free()

func _test_the_pause_screens_body_breaks_only_between_sentences(t) -> void:
	# The touch layer holds the control scheme, and the screen words its body again on every open.
	var controls: TouchControls = load("res://scenes/ui/touch_controls.tscn").instantiate()
	t.add_child(controls)
	var pause: CanvasLayer = PAUSE_SCENE.instantiate()
	var run := RunState.new()
	pause.use_run(run)
	t.add_child(pause)
	var body: HelpText = pause.get_node("Root/Center/Lines/Body")
	for joystick in [false, true]:
		controls.set_mode(ControlsMode.Mode.JOYSTICK if joystick else ControlsMode.Mode.TAP)
		pause.open()
		var source: String = Texts.WALKING_LESSON_PAUSE % (
				Texts.RUN_JOYSTICK if joystick else Texts.RUN_TAP)
		var lines := body.line.split("\n")
		for i in range(lines.size() - 1):
			t.check(lines[i].ends_with(".") or lines[i].ends_with("?") or lines[i].ends_with("!"),
					"the pause screen's instructions (joystick %s) break only after a sentence's end"
							% joystick)
		t.check(" ".join(lines) == source,
				"the pause screen's instructions (joystick %s) keep every word" % joystick)
		pause.close()
	pause.free()
	controls.free()
