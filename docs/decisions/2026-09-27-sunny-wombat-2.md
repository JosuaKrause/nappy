# sunny-wombat — The HUD's task line breaks at a sentence end · built 2026-10-03

*([sandy-marten](../playtests/2026-09-27-sandy-marten.md): the break falls at a sentence end only
where the text must wrap, "in the above example the first two sentences were on the same line";
the rest of the entry is [sunny-wombat](2026-09-27-sunny-wombat.md), PR #419)*

**Built (PR #469).** The marks' task line at the bottom left was the one screen text #419 left out,
because PR #414 was rewriting the same function. `Hud._refresh_resistance()` (`src/ui/hud.gd`) now
builds both of its lines, the ordinary one and the debug one, through `Hud._task_text()`, which
calls `SentenceLines.break_for_label()`. `Root/Meters/Resistance` in `scenes/ui/hud.tscn` is 280px
wide, the width of the meters above it, with word autowrap, so a single sentence too long for the
line still wraps by word. The `SentenceLines` paragraph in `docs/MECHANICS.md` lists the task line.

**Proposed, not asked for, and open to overturn:** the task line is covered at all (the filer's
reading of "this is the rule for all of them"); its 280px width; and, on the debug line, only the
task text is broken, not the progress marks after it, since those end in a "." the helper would
read as a sentence end.

**Verified.** `tests/test_hud.gd` (`_test_a_long_task_line_breaks_at_a_sentence_end`) checks that a
two-sentence task breaks after its first sentence on both lines and that a task fitting one line
stays on one; without the change the text has no line break, so the first check fails. The still in
`docs/evidence/sunny-wombat-hud-task-line-2026-10-03/` comes from a throwaway scene that gives a
task a two-sentence header, because no task the game ships says more than one sentence and no dev
flag puts one on screen: the rule changes nothing a player sees until a task does.
