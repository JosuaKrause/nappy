# A text broken onto two lines takes two, not three

A sentence-broken text whose first line fits is shown on that one line, never wrapped again so its
last word moves down; the player saw a first line lose its last word, a three-letter one, to the
second line while "there was plenty more room on the first line".

The text is not known. Find it: every caller of `SentenceLines.break_for_label()` and
`break_for_help()` (the title, the day briefs, the finale's body, the endings, the pause screen's
walking instructions, the chalk mark's big message, the help lines), each rendered at its real
label width in both presentations (landscape, and a phone held upright), and every one whose
rendered line count is more than `SentenceLines` returned is a case of this bug. The
[polite-finch](../2026-10-10-polite-finch/README.md) catalogue would make that list one file; this
fix does not wait for it.

What to look at, the player's "maybe the line budget is too tight?" among it, and none of it
settled: `SentenceLines._width()` measures with `ThemeDB.fallback_font` at the label's theme font
size against `custom_minimum_size.x`, so a label that renders narrower than that width (a
container squeezing it, a margin or an outline, a rotated phone view), wider than measured (a
different font, a button symbol wider than the two letters `HelpText.measurable()` counts), or a
line exactly at the width with the space the label keeps at a line's end, would each give this
result. And "plenty more room" says the first line was well short of the screen's own width, so the
label's width may be the budget that is too tight rather than the measurement.

A test renders each caller's texts at the label's real width and asserts the label's own line count
(`Label.get_line_count()`, or `RichTextLabel`'s) equals the number of lines `SentenceLines` returned,
for every text whose sentences each fit; it fails before the fix on the case found. The evidence is
a still of the text before and after, taken at the width it was seen at.
