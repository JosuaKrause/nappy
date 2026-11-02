# minty-quail — The reach suites drive public seams, and the rig reads nothing private (tests through public seams) · 2026-11-02


minty-quail's `tests-public-seams.md`: `tests/test_resistance_reach_marks.gd`, `reach_narrow`,
`reach_relocated`, and the rig's last private read. With them all eleven resistance suites build
their cities in runs of their own; the item stays open for the reads other files still make.

**Built.**
- `ResistanceDirector.reaches_from_home(tile)`, `reach_obstruction()` (a copy of the day's
  obstruction as the first placement measured it; a read builds it if nothing has asked yet) and
  `fell_back()`. The rig's `_edge_of_her_circle()` reads `reach_obstruction()`, so the rig reads no
  private member; its `_paths_reach_between()` is a deliberate copy of the director's walk, kept as a
  test oracle.
- `reach_marks` no longer writes `GameState`; `reach_narrow` builds a city per seed and day and gets
  its contact from the real day (`start_day()` and her read of the mark) rather than `place_contact()`;
  `reach_relocated` touches through `contact().complete_now()` and lets `EventManager.start_day()`
  plan the later days from the run's scars. Private reads: reach_marks 0, reach_narrow 7 to 1
  (`EventScheduler._is_spoiled()`), reach_relocated 12 to 1 (`EventScheduler._place_masts()`).
- Checks: reach_marks 33, reach_narrow 84 and reach_contacts 60 unchanged; reach_relocated 17423 to
  17427. The last night still plans the silenced mast from its scar exactly (on the day-11 map through
  `_place_masts()`), the real day-14 plan is checked against whether that day leaves it room, at least
  one seed must leave room, the queued mast is picked by the contact standing on its foot, and
  reaching it checks the mast silenced as well as the scar. Breaking the silencing, the scar-driven
  planning or the contact's link each fails the suite.

**Open to overturn** (the builders' choices where the brief was silent): a city per seed and day; the
real day flow in place of `place_contact()`; `reach_obstruction()` as a snapshot of the first placement's
measure; the rig's copied walk.
