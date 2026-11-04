# minty-quail — The return patrol and pursuit suites read what the director hands out (tests through public seams: W6a) · 2026-11-03

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the return patrol and pursuit
suites, subtask W6a of the scoped plan. No `src/` change and no seam added.

**Built.**
- `test_return_patrols.gd` (private-read lines 13 to 0) drives `EventDirector`'s public calls and
  reads what `due()` hands out as she walks, the patrol's siting off the path it returns; its forty
  samples of `_roll_interval()` became six checks on the gaps between the events `due()` hands out
  (checks 58 to 29).
- `test_pursuer_on_foot.gd` (13 to 2) reads the clear run off the run-trace line the game writes,
  compares two days, one with a torn poster, by what `place_what_is_owed_ahead()` hands her, reads
  the patrol routes off the day 8 `police_patrol` plans `build_day()` places, retires men through
  `EventManager.retire()`, and builds its city on a run of its own.
- `test_events_pursuit.gd` (7 to 5) sets the robber up on the map with its navigator through
  `EventInstance.setup()`.
- About twenty-five mutation runs; the park early return in `_toward_her_on_the_road()` is caught
  by nothing, since `corridor_at()` and the trim refuse the park anyway.

**Not done:** the pursuer suite's tick still calls the manager's `_tell_them_where_she_is()` and
`_check_hard_fails()`, wanting a public manager tick the game calls (real frames would coarsen the
encounter sums); the pursuit suite's blocked lesson wants the director handed to `EventsAhead`, and
its `DangerEdge._measure()` calls want a deterministic frame delta.
