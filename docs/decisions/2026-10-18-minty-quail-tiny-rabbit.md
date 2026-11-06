# minty-quail — The last test writes of run and city state go through the game's own paths · 2026-11-06


**Built.** The run and city state tests wrote by hand goes through the game's own writer where
there is a callable one: `test_acts.gd` records its barricade scars with `RunState.add_scar()`;
`test_day6_yeller_met.gd` and `test_day7_van.gd` complete the days behind her with
`RunState.complete_resistance_step()`, passing the step's own `grants_progress`;
`test_resistance_placement_kinds.gd` gives the run back as its dawn left it with
`ResistanceRunState.give_back()` between draws; `test_blackout.gd` does the sabotage by completing
the last night's contact under a director (after completing every errand before it, which is what
puts the finale on offer) and gives it back with `give_back()` for the retry. `Blackout` has no
public `go_dark()`, only `_go_dark()`, so making one would have been a change to `src/` for the
tests; the director's completion is the game's own route to the flag.

`test_event_strides.gd` and `test_event_redraw.gd` send the dog they draw off
(`EventInstance.leave_for_a_completed_task()`) and step it with `step()` the way its manager does,
in place of `walk_on_by_hand()`; their checks pass unchanged, including the exact half-stride bob
arithmetic, since one `step()` of `distance / speed` covers the ground the hand covered.
`test_scene_recipe_runtime.gd` already reads the runtime's own walk over real frames and names
`walk_on_by_hand()` only in a comment.

**Kept, with reasons.** `walk_on_by_hand()` in the crouched cat test: a crouching cat covers no ground
under its manager's step, so only a hand puts its stride on a step, and the test guards a state the
game cannot reach. The fixture writes on `RunState`'s public fields (`consumed_one_shots`, the
escape tests' `sabotage_done`) and on a hand-built building's `powered`, `day` and `condition`: no
game writer reaches one alone, the city and `Blackout` write them for every building at once, and
the suites test what one building does given its state.

**Found stale.** `test_blackout.gd` already started the city's day before the events' day, the order
the day director runs them in; the item's open hand call was that order, so nothing changed.
`RunConfig.rig_quit_seconds()` is called by `RigLock` and `FrameCost` by the frame trace, the frame
watch, the frame recorder and the debug readout, so neither is a member only tests read.

**Rejected.** A public `Blackout.go_dark()` for the blackout suite: a `src/` change that only tests
would call.
