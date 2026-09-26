## M102 — The finale · it is the run's ending, and its two sections are days, 2026-09-20

*(2026-09-20, [PLAYTEST-113](../playtests/PLAYTEST-113.md): "the escape the building starts when the
player has completed all tasks by the end of day 14"; "each the apartment and escape city are
treated as their own \"days\" with brief and restart checkpoint. we keep the no nerve costs for
now.")* One agent commit on `feature/m102-finale-is-the-ending`, reviewed here.

**The clock was asked back, and the answer overturns 2026-09-09.** *Asked for one clock "the
same length" counting down through both sections · overturned by the player on 2026-09-20 to
"180s per section"*, put to them with two alternatives: one shared clock whose city checkpoint
restores the time left on arrival, and the same with a floor on what it restores. A shared clock
needs a saved remaining time at the city's brief and lets a slow building leave that checkpoint
unwinnable; a clock per section is what a day brief already does. `FinaleController.start_section()`
is the only thing that starts a clock and is reached from the brief's continue, so nothing counts
down behind an undismissed screen and the city's clock is full whatever the stairs cost.

**"Every task complete" is `GameState.earned_good_ending()`** — `Tuning.RESISTANCE_GOAL` errands
run and the day-14 sabotage performed — which is answer 1 of 2026-09-09 ("the sabotage is the
cause of the brutal crackdown"): the runs that reach the escape are exactly the runs that used
to see the good-ending screen. A won day 14 without both keeps the neutral ending.

**The run is not ended on the way in, and that is the load-bearing part.** `GameState.finish_day()`
on a won final day ends the run, sets `ending` and clears the save, and `GameSave` refuses to
write once `ending` is set; recording the win at day 14 would have left the escape's checkpoints
nothing to come back to. The win is recorded in `main._on_finale_escaped()`, when she is out of
the city.

**`escape_section` is a top-level key of the save, not a field of the run snapshot.**
`GameState.snapshot_is_complete()` rejects a snapshot missing any field this build writes, so
adding it there would have made every existing save unreadable for one int. Beside
`day_under_way` it reads as no section when absent, and `GameSave.FORMAT_VERSION` stays 1.

**Chosen where the design was silent, each open to overturn:**

- The handover is a scene reload with `GameState.escape_section` surviving on the autoload,
  the answer `_restart_run()` already gives. Carrying it through the save file alone was tried
  and rejected: `GameSave.uses_save()` refuses dev-flagged and headless runs, so `--day 14` and
  every rig would have lost the run on the reload.
- A resumed escape opens straight on the section's brief with no title screen first.
- The brief's title and the HUD hint line are one string, so "Escape the building" and "Escape
  the city" retire the 2026-09-09 hint wording "Escape the apartment" and "Exit the city". The
  hint line moved to the brief's continue, since the HUD runs through a pause and the line
  would have faded behind the brief.
- After the epilogue a run's escape returns to the title; the good-ending screen does not
  follow it, since the epilogue already ends the story and two endings in a row is one too many.
- Telemetry keeps writing the run's existing log through the handover, and the save indicator
  is built only for a run's escape, since the flag's boot writes nothing.

**Found and left open in `TODO.md`:** the escape's boot has never built a pause screen. It
predates this change and matters more now that a real run ends there. **Not covered by a test:**
the four lines in `_ready()` that branch on `escape_section`, since nothing in the suite drives
a scene reload; the decision, the save round trip and the escape's boot are each covered.
Evidence: `docs/evidence/m102-section-briefs-2026-09-20/`. What only a play can settle is in
`REVIEW.md`.
