## M134 — A lost day gives the resistance back · built 2026-09-13

*(2026-09-13, [PLAYTEST-69](../playtests/PLAYTEST-69.md): "a lost day shouldn't retain the touch
mark -- a task is only complete if it is done on the day that won. but also it should reset if
lost so the player can try again"; and on the summary: "the words shown on the lost day are the
words that show at the beginning of that day not the nexts. since day doesn't have words it
doesn't make sense to show words on day 4".)* *Asked for as "what the run has spent stays spent"
· overturned for the resistance on 2026-09-13.* Two agent commits on
`feature/m134-lost-day-resets-the-resistance`, reviewed on the PR.

**The attempt owns the resistance's day.** `GameState.begin_day()`, called first thing in
`main._start_day()` before anything is placed, photographs the six run-scoped resistance
fields — completed and failed steps, progress, the package, the sabotage and the queued brief —
and a loss in `finish_day()` restores all six before the last-nerve branch, emitting the
progress signal when the number moves; a win takes the photograph again, which is the commit.
The step list is restored rather than repaired, so the retry's `ResistanceSteps.for_day()`
offers the same mark or contact, and a test drives a real city and director across a loss and
holds the retry meets the same step within a hundredth of a pixel of the same spot. The nerve's
telemetry line gains a clause when a day's resistance work went with it. `finish_day()`'s
docstring lists the resistance as the second thing the attempt owns beside where she settled.

**A lost summary repeats the day's own instruction.** `ResistanceSteps.unlocking_brief(step)`
answers the brief of the pickup that unlocked a perform step, with the pairing checked rather
than assumed; on a loss `GameState` runs the day's table over the dawn photograph to find the
step the day offered and queues those words over the restored brief, so the summary reads what
the retry is for, and a lost day 4 — or any day with no perform step on offer — reads nothing.
The summary's own code did not change; only its comment, which had claimed a lost day 4 still
hands over the mark's words. Pinned by `tests/test_day_loop.gd` end to end: a lost day 5 shows
the day-4 mark's words, a lost day 4 with the mark touched shows none, a won day 4 still reads
the mark it touched.

**Open to overturn.** The package is put down before the photograph, so a day won carrying it
does not hand a heavy pram back on the next loss; the instruction is queued over the restored
brief rather than instead of it, so words owed and never shown are never dropped; no signal
announces a step un-completing, since the HUD rebuilds its line on the retry's day start; a
lost run's last day still gets its instruction. No capture: no dev flag fast-forwards
resistance progress, so a rig cannot stand on a perform step.
