# minty-quail — The crowd closures and turns suites read what the crowd does (tests through public seams: W3a) · 2026-11-03

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the crowd closures and turns
suites, subtask W3a of the scoped plan. No `src/` change.

**Built.**
- `test_crowd_closures.gd` (private-read lines 34 to 6) reads seals through
  `SealPlanner.positions_across()`, a hut's `WalkerDoorHold` off a probe walker's `door_ahead`, a
  held walker through the hut (`inside`, `place_of()`) and its own velocity and visibility, and the
  crowd's own recycles as they happen (a body moving more than 100 px in one frame), with the entry
  tests standing the crowd's box near the map edge; the stride floor is the strategy's
  `stride_length()` over its top speed, looser than the agent's own stride time but still failing
  when the reversal hold is zeroed.
- `test_turns.gd` (19 to 0): a figure on the map's moves holds the blocking car, `crashed_into()`
  brings stub cars to rest, `nudge_back()` makes the barrier overlap, `add_recipe_actor()` places the
  merge queue.
- Each scenario builds its own city on a fresh `RunState` (`GameState` lines 6 to 0). Checks kept;
  turns asks "has a four-way junction" once per scenario (13 more). Twelve mutation runs.

**Not done:** two cooldown checks read the walker's emerging door state, which no game class reads;
`recycle()` stays private, since the mover calls it itself. Removing only `claim()` in
`_claim_the_turn()` fails nothing, because `Crowd._book_the_turns()` claims the same lane every
frame.
