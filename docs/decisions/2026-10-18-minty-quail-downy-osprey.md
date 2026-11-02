# minty-quail — The placement-kinds and replacement suites drive public seams: the happenings, the home door and the mark's guard (tests through public seams) · 2026-11-02


minty-quail's `tests-public-seams.md`: `tests/test_resistance_placement_kinds.gd` and
`tests/test_resistance_replacement.gd`, the resistance happenings and the mark's replacement. The
item stays open for the other resistance suites and the private reads these two still make.

**Built.**
- Read-only queries: `City.home_door_is_sealed()`, `City.home_door_building()` (the private
  `_home_door_building()` made public), `ResistanceHappenings.raid_vans()`, `raid_beat()`,
  `frontage_of()` and `spine_x()` (the last two made public), and `ResistanceDirector.mark_guard()`,
  the robber standing over today's mark. `raid_vans()`, `raid_beat()`, `home_door_is_sealed()` and
  `mark_guard()` have no caller in `src/` yet.
- Each test builds its city in a run of its own, reads from the street or a public query, and
  touches through a real physics frame; the market and column tests drive `ResistanceHappenings.tick()`
  with a long delta and a walking velocity in place of writing `_elapsed` and `_walked`. Both suites
  pass with their tests reversed and leave the live `GameState` unchanged. Private-read lines (the
  item's first command): placement_kinds 75 to 7, replacement 29 to 10.
- Checks: placement_kinds 294 to 298, replacement 8239 to 8245. The completed-mark test goes 12 to 16
  (its guard-stays check runs once per robbery standing in the street; "still tracked as the mark's
  own" and "no longer tracked as today's" are read through `mark_guard()`, the second guarding the
  reset in `start_day()`; the door-guard check counts the `task_guard` row). The covered-corner test
  goes 4 to 10 (the mark-seen decision read from what it does in each scheme), the notice-radius
  test 1 to 2, the relocated-mark test 4 to 5. The two "day 10 offers a mark" checks, the setup
  assertion `_director_on_the_neighbor()` repeated on the same seed, are dropped: the same behaviour
  is checked three times in replacement and twice in placement_kinds.

**Open to overturn** (the builders' choices where the brief was silent): the two raid getters,
ticking the happenings with a long delta, and the dropped repeated setup checks.
