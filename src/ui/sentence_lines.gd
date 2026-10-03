class_name SentenceLines
extends RefCounted
## One helper that breaks a screen's prose onto more than one line, used by every label the
## `SentenceLines` paragraph in `docs/MECHANICS.md` lists rather than a `\n` typed into each
## string, so a new text gets the same rule automatically.
##
## **Breaks only where the text has to wrap, and only between sentences.** *(2026-09-27, the
## player: "if a text has multiple sentences like \"She started crying after 0:10. There is no
## settling now.\" the newline comes after the period"; asked whether every sentence gets its own
## line or the break falls only where the text must wrap, the second example answered "the latter":
## "same for \"She won't settle indoors. It is quiet in the park. Walk until she sleeps, then bring
## her home.\" the newline goes after park".)* A text that already fits the target width on one
## line is left on one line, with no break at all. A text too wide for one line breaks at whichever
## sentence end splits it most evenly — never inside a sentence — and recurses into each half so a
## text with more than two sentences can still take more than one break. A single sentence too long
## for the width on its own is handed back unbroken, so the label's own `autowrap_mode` wraps it
## further, word by word, exactly as it would have without this helper.
##
## A sentence ends at a `.`, `?` or `!` that is followed by a space or by the end of the string —
## never at one followed directly by another character, which is what keeps a decimal ("1.5") or a
## clock reading's own fraction from splitting: "0:10." ends a sentence because a space follows it,
## "1.5" does not because a digit does.

## Reads the label's own font size (`ThemeDB.fallback_font` is what every label in this project
## actually renders with — none of them overrides the font resource itself, only its size, the same
## way `home_arrow.gd` and `danger_edge.gd` already measure text) and the width prose wraps to at
## `label.custom_minimum_size.x`, so every caller that wants this rule sets that width once on the
## label rather than each call site guessing at one.
static func break_for_label(text: String, label: Label) -> String:
	return _wrap(text, label.get_theme_font_size("font_size"), label.custom_minimum_size.x)

static func _wrap(text: String, font_size: int, max_width: float) -> String:
	var sentences := _split_sentences(text)
	return "\n".join(_lines(sentences, font_size, max_width))

## Splits `text` into its sentences, each keeping its own ending punctuation and none of the space
## that followed it, so `" ".join(_split_sentences(text)) == text` for every text this file's
## callers hand it (a single space between sentences, no trailing space).
static func _split_sentences(text: String) -> Array[String]:
	var sentences: Array[String] = []
	var start := 0
	var length := text.length()
	var i := 0
	while i < length:
		var c := text[i]
		if c == "." or c == "?" or c == "!":
			var at_end := i + 1 >= length
			var followed_by_space := not at_end and text[i + 1] == " "
			if at_end or followed_by_space:
				sentences.append(text.substr(start, i + 1 - start))
				i += 2 if followed_by_space else 1
				start = i
				continue
		i += 1
	if start < length:
		sentences.append(text.substr(start))
	return sentences

## The recursive split: one line if `sentences` already fits (or cannot be split further), or the
## two halves either side of whichever sentence boundary balances the two resulting widths best,
## each recursed into in case it still needs a break of its own.
static func _lines(sentences: Array[String], font_size: int, max_width: float) -> Array[String]:
	var joined := " ".join(sentences)
	if sentences.size() <= 1 or _width(joined, font_size) <= max_width:
		return [joined]
	var best_k := 1
	var best_score := INF
	for k in range(1, sentences.size()):
		var prefix := " ".join(sentences.slice(0, k))
		var suffix := " ".join(sentences.slice(k, sentences.size()))
		var score: float = maxf(_width(prefix, font_size), _width(suffix, font_size))
		if score < best_score:
			best_score = score
			best_k = k
	var lines: Array[String] = []
	lines.append_array(_lines(sentences.slice(0, best_k), font_size, max_width))
	lines.append_array(_lines(sentences.slice(best_k, sentences.size()), font_size, max_width))
	return lines

static func _width(text: String, font_size: int) -> float:
	return ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
