# lilac-marten — The ending screens show the total game time beside their segment's · 2026-11-25

**What it is.** The item `total-time.md` of the entry lilac-marten (band `now`, after minty-quail).
The player: every end screen must show the total game time beside the current day's, and then "I'm
talking about *ending* screens *not* day/scene completion screens (those keep their segment's time)"
(curly-moose #803). A day's or a scene's completion screen keeps its segment's time only.

**What was found.** Two screens end the game. The run's ending (`SummaryModel.ending()`: the
nerves-spent loss `GAME OVER` in hard mode, and the two endings after day 14) showed the total
alone, `Time played`, and nothing of the day it ended on. The escape's last screen (the epilogue,
`SummaryModel.epilogue()`) showed the escape's own time alone, `Out in`. A lost day and a lost
escape section are retried and a normal run's last nerve sends it back to its checkpoint, so none
of those is an ending.

**What was built.**
- **The total is `RunHeader.play_seconds()`**, the physics ticks the world has moved this run. It is
  saved with the run and loaded back, so it spans reloads; a day left mid-walk and reopened restarts
  from its dawn, and the ticks walked since the last save are not counted (the run's save is
  written at each day's dawn and end). It is never reset by a retry or a checkpoint.
- **The epilogue shows both**: `Out in: <the escape's clock>` and `Time played: <the total>`
  (`Texts.FINALE_OUT_IN`); `SummaryModel.epilogue()` takes the run for the total.
- **The ending shows both**: `Time played: <the total>`, then `The last day: <its clock>`
  (`Texts.ENDING_LAST_DAY`), then the day reached on `GAME OVER`. `main` keeps the clock of the day
  that ended last (`_last_day_seconds`, set in `_on_day_finished()`) and hands it to
  `SummaryModel.ending()`. An ending opened again from a saved run (the resume gate) and the
  `--ending` rig have no such day in this boot, so they show the total alone.
- Both lines are plain body text in the screens' existing label; nothing new is drawn.

**What is open.** coral-squirrel (in the queue) marks a resumed run's times as inaccurate; the total
here is the one that exists and is not changed by it.
