priority: now

# striped-lemur — The game over screen shows the day you made it to · filed 2026-09-27

> "Oh bad ending game over screen should show the day that you made it to" · "File that for now
> too"

[round-moose](../../playtests/2026-09-27-round-moose.md), statements 4 and 5. The `BAD` ending is
the one a run reaches when its nerves run out, the only way a run ends before day 14
(`docs/MECHANICS.md`). `DaySummary.show_ending()` in `src/ui/day_summary.gd` fills it from three tables,
`_ENDING_HEADING` ("GAME OVER"), `_ENDING_TITLE` ("You stop going out.") and `_ENDING_BODY` (two
lines of fiction), then adds "Time played: m:ss.mmm" from `GameState.play_seconds`. Nothing on it
says which day the run reached, though `GameState.day` holds it.

Related: [M210](../2026-09-26-M210/README.md), the brief between two days is the coming day's,
where the day number on the brief is one behind. The day this screen names must be read from the
same source the day brief uses once M210 fixes it, so the two cannot disagree.
