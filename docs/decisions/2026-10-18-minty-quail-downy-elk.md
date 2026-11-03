# minty-quail — The arrow settles through the director's own retarget and tick, and the baby's step goes private (tests through public seams) · 2026-11-03

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the resistance arrow's privates
other files reached, and `Baby.step()`. The item lists what the arrow, pursuit and checkpoint suites
still read.

**Built.**
- `ResistanceDirector._settle_the_arrow()`, which ran every sweep at once for rigs with no frames,
  is gone. Its callers settle the arrow as the game does, `retarget_the_arrow()` then `tick()` at the
  physics tick until `arrow_sweeping()` is false, and read it through the arrow queries.
  `test_day13_guard.gd` (private-read lines 69 to 5, `GameState` lines 60 to 0) builds each city in a
  run of its own, reads the task's guard off the street, and completes the mark and task through
  `contact().complete_now()`. The six probes the item named use runs of their own and the same reads
  (111 lines to 17, `GameState` 101 to 0); three of them never handed the director the player, so
  their arrow chose from the contact, and they hand her in now, which changes what they print.
- `Baby.step()` is folded back into `_physics_process()`. `test_checkpoints.gd`,
  `test_resistance_traps.gd`, `test_invincible.gd` and `test_baby_world.gd` let her own frame take
  real engine ticks; the trap walks run on `physics_frame`, so she steps before the robber every
  tick, at 1/60 s of game time each, sped up by raising the tick rate and time scale together and
  restoring both.
- The fingerprint probe's `LEAK VisitCounter._open_tasks` on main: the probe never declared
  `t.gives_back_observers()`; it does now.
- No public member added; `src/` changes are `resistance_director.gd` and `baby.gd`. Checks kept but
  day 13's follows-her test (29 to 28: two reads of the director's bookkeeping folded into
  behaviour, one check added that a failed search is retried only after 3 s of ticks). Nine mutation
  runs.

**Open to overturn** (the builder's choices where the brief was silent): an arrow choice in the day
13 suite is one 0.5 s director tick; the trap walks rely on `physics_frame` for tick order rather than
pinning one tick per frame; the guard-walk probe classifies the guard by where he stands; the probes
hand the director the player.
