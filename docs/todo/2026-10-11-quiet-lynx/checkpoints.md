# Checkpoints in normal mode

The checkpoints are **days 4, 8 and 12**, the first days of acts II, III and IV
(`Tuning.ACT_START_DAYS` is `[1, 4, 8, 12]`; statement 3, answer 1). **Day 1 is checkpoint zero**, in the same
city with the same seed (statement 3, answer 2).

After the run is lost in normal mode (see [out-of-nerves-in-normal.md](out-of-nerves-in-normal.md)),
it restarts at the latest checkpoint reached, with 5 nerves.

**The exact state at the checkpoint is stored and restored.** In the player's words (statement 6):
*"store the exact state at the checkpoint -- continuing should not have anything that happened after
the checkpoint"*. The state is the whole run state at the dawn of the checkpoint day's first
attempt, which is the same state `docs/MECHANICS.md` says a retried day gets (*"exact same state at
the beginning of the day. nothing else"*):

- the resistance's progress and steps;
- the scars and the consumed one-shot events;
- the city's block arcs;
- the posters;
- where she settled each day;
- the fenced park;
- the alley tiles already used for a completed mark;
- the run's play time, which is the filer's reading of "exact state".

The snapshot is written into the save when the checkpoint day is first begun, so it exists before
anything of that day can have happened. Day 1's snapshot is the run's own start, which
`start_run(seed)` rebuilds exactly, so nothing extra is stored for it.

A checkpoint is the first time the day is begun, never a later retry of it: losing nerves on day 8
and retrying day 8 does not replace the day 8 checkpoint, and reaching day 9 does not replace it
either. Only reaching day 12 does.

**Proposed, not asked for:**

- The snapshot rides in the save as a top-level key, so `FORMAT_VERSION` does not change.
- A save with no stored checkpoint, such as one written before this exists, falls back to
  checkpoint zero, which `start_run(seed)` rebuilds exactly.

**A checkpoint cannot leave too few tasks to finish** (statements 5 to 8): tasks belong to their days, a
checkpoint restores exactly what the run had, and winning day 14 still gives the neutral ending. No
change is owed there. The player's follow-up, a run that neglected act II's tasks and returns at checkpoint 8, got the same answer (that run still has 6 tasks to reach 5), and *"okay sounds good"* leaves it as it is: nothing on the out-of-nerves screen mentions tasks, the held restart is the fresh start, and offering a start over when the good ending is out of reach was not taken.

`docs/MECHANICS.md` "Saving and resuming" says what a save holds; it gains the checkpoint snapshot
and the mode in the same pull request.
