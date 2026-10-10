extends RefCounted
## What `SentenceLines` returns is what the label shows: every caller's text, rendered at the
## label's real width, takes exactly as many lines as `SentenceLines` broke it into. See
## `src/ui/sentence_lines.gd` for the rule and why a label that wraps a fitting line again is a bug.

const SUMMARY_SCENE := preload("res://scenes/ui/day_summary.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause_screen.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")

const _RESUMED_NOTE := "Left before the day ended. That cost a nerve — it starts over from dawn."

func run(t) -> void:
	var summary: CanvasLayer = SUMMARY_SCENE.instantiate()
	t.add_child(summary)
	var title: Label = summary.get_node("Root/Center/Lines/Title")
	var note: Label = summary.get_node("Root/Center/Lines/Note")
	var body: Label = summary.get_node("Root/Center/Lines/Body")
	var brief: Label = summary.get_node("Root/Center/Lines/Brief")
	for day in summary._DAY_BRIEF.keys():
		_check_label(t, summary._DAY_BRIEF[day], brief, "day %d's brief" % day)
	for ending in summary._ENDING_BODY.keys():
		_check_label(t, summary._ENDING_BODY[ending], body, "ending %d's body" % ending)
	for kind in summary._FINALE_BODY.keys():
		_check_label(t, summary._FINALE_BODY[kind], body, "finale body %d" % kind)
	_check_label(t, _RESUMED_NOTE, note, "the resumed-day note")
	_check_label(t, "She started crying after 0:10. There is no settling her now.", title,
			"the lost-day title")
	var hard_fails: Dictionary = DayController._HARD_FAIL_TEXT
	for reason in hard_fails.keys():
		var line: String = summary._elapsed_line(GameEnums.DayResult.LOST_HARD_FAIL,
				hard_fails[reason], "10:00")
		_check_label(t, line, title, "the day summary title for %s" % reason)
	_check_label(t, "Dusk. You are still out.", title, "the dusk title")
	summary.queue_free()

	var pause: CanvasLayer = PAUSE_SCENE.instantiate()
	t.add_child(pause)
	var pause_body: HelpText = pause.get_node("Root/Center/Lines/Body")
	for joystick in [false, true]:
		_check_help(t, pause.body_for(joystick), pause_body, "the pause body (joystick %s)" % joystick)
	pause.queue_free()

	var hud: CanvasLayer = HUD_SCENE.instantiate()
	t.add_child(hud)
	var teach: HelpText = hud.get_node("Root/Teach")
	for step in ResistanceSteps.all():
		if step.is_pickup and step.brief != "":
			_check_help(t, step.brief, teach, "the chalk mark's message \"%s\"" % step.title)
	hud.queue_free()

## The label as the screen lays it out: the width it asks for, as the box it sits in gives it.
func _check_label(t, source: String, label: Label, what: String) -> void:
	var wrapped := SentenceLines.break_for_label(source, label)
	label.text = wrapped
	label.size.x = maxf(label.custom_minimum_size.x, label.get_combined_minimum_size().x)
	_compare(t, wrapped, label.get_line_count(), source, label.size.x,
			label.get_theme_font_size("font_size"), what)

func _check_help(t, source: String, label: HelpText, what: String) -> void:
	var wrapped := SentenceLines.break_for_help(source, label)
	label.show_line(wrapped)
	label.size.x = label.custom_minimum_size.x
	_compare(t, wrapped, label.get_line_count(), source, label.size.x,
			label.get_theme_font_size("normal_font_size"), what)

## Every sentence has to fit the label's width on its own (a label that wraps one moves its last
## word down, though the screen has room), and then the label's own line count is `SentenceLines`'s.
func _compare(t, wrapped: String, shown: int, source: String, width: float, font_size: int,
		what: String) -> void:
	var broken := wrapped.split("\n").size()
	for sentence in SentenceLines._split_sentences(source):
		t.check(SentenceLines._width(sentence, font_size) <= width,
				"%s: the sentence \"%s\" fits the %d px the label has, so the label never wraps it"
						% [what, sentence, width])
	t.check(shown == broken,
			"%s shows %d lines at %d px where SentenceLines broke it into %d" % [what, shown, width, broken])
