priority: now

# feathery-puffin — A text broken onto two lines takes two, not three · filed 2026-10-10


[mossy-beaver](../../playtests/2026-10-10-mossy-beaver.md), inbox #650, from playing, filed `now`
as a playtest note is:

> I saw a text that was supposed to be broken into two lines but got actually broken into three lines with the last (three letter) word of the first line moved to the second line. I can't find the exact text (we need that catalogue) but this is a bug there was plenty more room on the first line -- no need to break it apart. maybe the line budget is too tight?

If the text went through `SentenceLines`, the rule it should have followed is that helper's (`src/ui/sentence_lines.gd`, the
paragraph in `docs/MECHANICS.md` that starts "A title, brief or body of more than one sentence"): a
text too wide for one line breaks at the sentence end that splits it most evenly, and the label's
own word wrap then wraps only a sentence too long on its own. A first line that lost its last
three-letter word to the second line is then a line that `SentenceLines` measured as fitting and
the label measured as too wide; a text that does not go through it is a caller the rule misses.
