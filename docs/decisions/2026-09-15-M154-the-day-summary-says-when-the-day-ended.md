## M154 — The day summary says when the day ended · built 2026-09-15

*(2026-09-15, [PLAYTEST-77](../playtests/PLAYTEST-77.md): "can you show the time of the day when
dieing/completing a day (not the total like on the game over / win screen). ...fell asleep
after xx:xx or something like that".)* One agent commit on `feature/m154-summary-clock`,
reviewed on the PR.

**The capture point.** `main._on_day_finished()` takes `_day.time_total - _day.time_remaining`
at the top of the handler, before anything else touches `_day`, clamped to the day's length
because a timeout's `time_remaining` can read a frame's delta past zero on the frame `_end()`
fires. It is handed to `DaySummary.show_day()` as a defaulted fifth argument, so the pause and
resume rigs that call `show_day()` without caring about the clock did not change.

**The phrasing is not one suffix.** `DaySummary._elapsed_line()` matches on `DayResult`: a won
day gets *She fell asleep after 1:24.*; a crying loss reads the clock into its reason's first
sentence, *She started crying after 1:24. There is no settling her now.*; a hard fail keeps its
reason whole with the clock as a sentence after it, *After 1:24.*; a timeout shows no clock,
since dusk is the whole day and printing its length back is the total the player said they did
not want. The hard fail's shape is the agent's call, open to overturn: the reasons there are
free sentences, so the clock trails them rather than being spliced into grammar it cannot see.

**One formatter, not two.** `GameState.format_clock_seconds()` is the `m:ss` sibling of the
millisecond `format_clock()`; `hud.gd`'s inline format string was rewritten to call it, so the
HUD clock and the summary's line cannot carry two copies of the same shape. It truncates as
the HUD always did, so a value read a frame apart never disagrees by a second.

**The check.** `tests/test_day_loop.gd`'s `_test_the_summary_shows_when_the_day_ended` drives
`show_day()` with 84 seconds and asserts the exact phrasing for all four results, and that a
timeout's body never contains the day's length. A `--day-length 1` screenshot confirmed the
timeout body on screen in its box; the other three were left to the check.
