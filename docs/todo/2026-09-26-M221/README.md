## M221 — A failed day leaves no chalk mark behind · found 2026-09-26

> "chalk marks don't get properly reset on failed days accumulating more and more chalk marks in
> the same alley"

[PLAYTEST-143](../../playtests/PLAYTEST-143.md), statement 7. `ResistanceDirector._begin_step()` adds a
new `ContactPoint` each time a step is placed. `start_day()` calls `_clear()`, which frees the old
contact. The robber (`_guard`) is only set to null there and never retired, and nothing yet shows
which node the extra marks are. This follows M137 (PR #362), M205 and M213, which all change the
resistance director.
