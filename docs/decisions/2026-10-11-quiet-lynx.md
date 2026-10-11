# quiet-lynx — Checkpoints, and a Hard Mode that has none · 2026-10-11

The player ([gentle-osprey](../playtests/2026-10-11-gentle-osprey.md), inbox #678): "I want to
introduce a partway continue checkpoints. what are good days for checkpoints that restart after game
over with 5 nerves? also on that note I want a "Hard Mode" checkbox on the title screen (if new game)
that decides whether checkpoints are available. with hard mode the escape also has normal nerve
counts and ends if nerves go to zero (instead of restarting indefinitely; this is only for normal
mode). needs telemetry whether someone chooses hard mode and whether they are restarting from a
checkpoint after losing all nerves". Asked, they chose checkpoints on days 4, 8 and 12 (the first
days of acts II, III and IV), day 1 in the same city as checkpoint zero, a cleared escape section
giving a nerve back, "No game over in normal", and a hard-only copy of the day-start event; and
added "store the exact state at the checkpoint -- continuing should not have anything that happened
after the checkpoint" and, on telemetry, "the event stats (influence/lethal/etc) should not include
hard mode since hard mode doesn't affect gameplay -- only restart pacing".

**Built in PR #681.**

- **The title has one option.** A "Hard Mode" checkbox sits under "press a button to begin" when the
  title begins a new game, and never in front of a resumed save or the escape's title. A tap, a
  click or `H` flips it and none of them starts the run. It is drawn at 1.5x with a 28-design-px reach, about a
  50pt target on a phone held landscape. The mode is `GameState.hard_mode`, set when
  the title is dismissed and carried in the save as a top-level key, so a save without it reads as
  normal.
- **A checkpoint is the whole save at its dawn.** `GameState.begin_day()` keeps `GameSave.run_data()`
  the first time day 4, 8 or 12 (`Tuning.ACT_START_DAYS`) is begun. A normal run's last nerve brings
  it back through `GameSave.restore_run_data()`, the same function a load uses, with nerves set to 5.
  Before day 4 it is `start_run(run_seed)`. `tests/test_run_checkpoints.gd` changes every key the
  save file carries and asserts each comes back as day 4's dawn, so a field added to the save later
  fails it until the checkpoint carries it too.
- **Normal mode never reaches GAME OVER.** Its last lost nerve shows the lost-day summary, "Your
  nerves gave out. Back to day N." with five stars and the ordinary continue; that continue reloads the scene and starts the checkpoint's day
  directly, on the run read back the way a load reads it (`GameSave.load_in_memory()`), so nothing
  a later day put on the world, such as day 11's boarded window over the neighbor's flat, survives
  the trip back (clearing the window at a dawn before day 11 was rejected: it fixes the one fact
  found and not the next); a resumed save that
  spends the last nerve says "Left before the day ended. That was the last nerve — back to day N."
  The held restart still starts from scratch in both modes.
- **Hard mode is the old run, and its escape spends nerves.** A lost section costs one and at zero
  the run ends on GAME OVER; leaving the building gives one back before the city's brief. Normal
  mode's escape is unchanged.
- **GoatCounter:** `nappy-mode-hard` / `nappy-mode-normal` when a fresh run's title is dismissed;
  `nappy-day-N-began-hard` beside the unchanged `nappy-day-N-began`, for hard runs only;
  `nappy-checkpoint-N-from-day-M` when a normal run goes back. Nothing else is split by mode.
- Dev flags `--hard` and `--nerves N` reach both modes' endings.

**What it narrows and what it leaves standing.** PLAYTEST-28 finding 4, "the game over screen cannot
have a continue button", stands as written: only hard mode reaches that screen. The records
[striped-lemur](2026-09-27-striped-lemur.md) and [M206](2026-09-25-M206.md) now describe hard mode's
GAME OVER screen. The escape's "escape doesn't have nerves"
([pebbly-penguin](../playtests/2026-09-27-pebbly-penguin.md)) and M102's lost section at no Nerve
cost now hold for normal mode, at the player's own word. PLAYTEST-143's "restart button restarts the
game from scratch" stands in both modes. Decision 2, "Difficulty is self-selected through the extra
quests … the base game has to be hard on its own", is read as untouched: checkpoints change what
running out of nerves costs, never how hard a day is to walk (the filer's reading, open to
overturn).

**Tasks and checkpoints.** Asked whether a checkpoint can leave too few tasks, the answer was that a
checkpoint holds exactly what the run had: each task belongs to its day (6 to 13), the good ending
needs five and the sabotage, so a run can already be past it before any checkpoint, and winning day
14 still gives the neutral ending. The player's "okay sounds good" left it as it is; offering a start
over when the good ending is out of reach was not taken.

**Not taken.** Checkpoints on days 6, 9 and 12 (tied to the first chalk mark and the first gatehouse
rather than to the acts); a new run in a new city before the first checkpoint; no nerve back in the
hard escape; a continue button on GAME OVER, or GAME OVER followed by the checkpoint; splitting
`nappy-day-N-began` into `-normal`/`-hard`, which would end its series.

**Open to overturn** (the filer's and the builder's choices): play time is part of the checkpoint; a
checkpoint is kept only the first time its day is begun; a stored checkpoint the build cannot read
falls back to checkpoint zero; the box starts unchecked and is not remembered between sittings;
nothing during play shows the mode; the two "back to day N" lines; the key `H`; the regained escape
nerve capped at 5; leaving mid-section costs nothing in either mode; the run log reuses the `nerve`
kind; the band `now`.
