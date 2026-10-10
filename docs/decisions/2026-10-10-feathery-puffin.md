# feathery-puffin — A text broken onto two lines takes two, not three · 2026-10-10

[Mossy-beaver](../playtests/2026-10-10-mossy-beaver.md), inbox #650, from playing:

> I saw a text that was supposed to be broken into two lines but got actually broken into three lines with the last (three letter) word of the first line moved to the second line. I can't find the exact text (we need that catalogue) but this is a bug there was plenty more room on the first line -- no need to break it apart. maybe the line budget is too tight?

**The text**, found by rendering every caller of `SentenceLines.break_for_label()` and
`break_for_help()` at its label's real width: the day summary's title for a day lost to the van
guard's chase, "He caught up with the package still on her. They took her in. After 10:00." Its
first sentence measures about 830px at the title's 40px size, the label was 820px wide, so the
label wrapped inside it and "her." went to a line of its own. The pause screen's body had the same
fault: "Walk to calm ground and stay moving; standing still settles nothing." measures 1042px in an
820px label. Every other caller's texts (the day briefs, the ending and finale bodies, the resumed
note, the lost-day title for every hard-fail text, the pause body in both control schemes, every
chalk-mark message) already rendered on the lines `SentenceLines` returned.

**The cause was the label's width, not the measurement**: the player's "maybe the line budget is
too tight?" Font, outline, the space kept at a line's end and the button symbols are not involved.
Every screen is laid out in the 1280x720 design box and a phone held upright only rotates that box,
so the widths are the same in landscape and portrait.

**Built in PR #655**: the day summary's title, note, body and brief are 900px wide
(`scenes/ui/day_summary.tscn`) and the pause body 1120px (`scenes/ui/pause_screen.tscn`).
*Open to overturn:* 900px rather than the screen's width for the summary, because at 1120px the
player's own pinned example ("She started crying after 0:10. / There is no settling her now.")
fits on one line and loses the break they asked for; 900px keeps it and holds the 830px sentence.
The summary's brief takes the same 900px, so a two-sentence brief measuring 820px to 900px now shows
on one line, as the sentence-breaking rule says a text that fits does.
`tests/test_sentence_lines_render.gd` renders every caller's texts at the label's real width and
asserts each sentence fits it and the label's own line count equals the lines `SentenceLines`
returned; at the old widths it fails six checks (the van-guard title and the pause body, in both
control schemes). The stills before and after, and one of the title after in a phone held upright, are in
[two-lines-2026-10-10](../evidence/two-lines-2026-10-10/).
