## M166 — The save is written when a day starts, and a saved game opens on the day brief · built 2026-09-19

*(2026-09-19, [PLAYTEST-85](../playtests/PLAYTEST-85.md): "write the save when starting a day; not
when the focus is lost etc. also if there is a saved game the title screen should go to the day
brief screen instead of starting outright" — and, asked whether a day's end also writes: "save as
"played" when the day starts. save as "nothing played yet" for the day brief and end of day
message. nothing else will change the state and doesn't need to be saved".)* *Asked for "saving
should be implicit (on focus loss or game quit)" in [PLAYTEST-80](../playtests/PLAYTEST-80.md) ·
overturned by the player on 2026-09-19 to the two writes below.* Built by an agent on
`feature/m166-save-at-day-start`; it replaces the four write moments and the resumed pause screen
of M162, a game can be resumed, recorded directly below.

**What was built.**

- **Two writes.** `main._engage_the_day()` writes `day_under_way: true` when the title is
  dismissed on a fresh run or the day brief is continued from, and `main._on_summary_continued()`
  writes `true` after starting the next day from an end-of-day message. `main._on_day_finished()`
  writes `false` as the end-of-day message comes up. Focus loss, application pause, the window's
  close request and the pause screen's quit write nothing; focus loss still pauses.
- **The day brief's write is made at boot, before the title.** `main._write_dawn_for_a_resumed_run()`
  writes `false` on a resumed boot only, right after `GameState.finish_day()` has charged whatever
  the load owes, so the charged nerve is on disk before either gate is shown. A kill before the
  day is engaged finds `false` and costs nothing more; a kill after finds `true` and costs the
  day. No instant hands back a free retry or charges one abandoned day twice.
- **A fresh run writes nothing until its title is dismissed.** The first build wrote at every
  dawn, so merely opening the game made a day-1 save, the next launch showed a day brief for a day
  nobody had touched, and the held restart re-created the save it had just cleared. Review caught
  it; the boot write is gated on a resumed run.
- **The title comes up on every boot.** With a save, its start opens `DaySummary.show_day_brief()`
  — "Day N of 14", the nerve count, the resistance's pending brief, and the lost-day line when the
  load charged a nerve — or the ending when the load spent the last one. `PauseScreen.open()`'s
  note and its label, `main._day_engaged`, `_day_under_way_for_save()`, `_on_pause_resumed()` and
  `_show_resume_outcome()` are gone.

**Chosen where the design was silent, open to overturn.** The day brief is its own small
presentation rather than `show_day()` with an invented result. The resumed boot's write happens
before the title rather than as the brief appears, for the kill ordering above, so the save symbol
shows behind the title on a resumed boot. `main._quit()` losing its write is verified by reading,
since calling it ends the test process.

**What only a person can check** is in `REVIEW.md`: no rig reaches the title-to-day-brief flow,
because a dev-flagged run never reads or writes the save.
