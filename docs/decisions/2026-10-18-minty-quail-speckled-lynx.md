# minty-quail — The blackout and scenery residency suites build a city per test (isolated tests) · 2026-11-05


minty-quail's `tests-isolated.md` and `tests-public-seams.md`: the two city suites that shared one
city across their tests, and so failed run in reverse. No `src/` change.

**Built.**
- `test_blackout.gd` builds its city on a run of its own (`RunCity.with_own_run`) before every test
  and frees it after. The two tests that leaned on an earlier test's darkness (it stays dark walking
  back; a retry gives the power back) go dark themselves, and the retry test now also checks the
  power was off before the retry. The escape test builds its own city and run.
- `test_scenery_residency.gd`'s one long per-seed body is seven tests (all mode, all mode's budget,
  one mode, the frame record, the pending chunks, residency following the view, the roof phase),
  each building its own city with the recording roof drawers handed in as before, for both seeds;
  the pending test switches to the stepped ground mode itself, which the old sequence did for it.
- Both suites pass in their normal order, with their tests reversed (shown by reversing the calls
  in each `run()` locally, not committed, since the runner shuffles suites and not the tests in one),
  and under `tools/test.sh --shuffle 7 --repeat 3`.
- A city costs about 1.5 s to build, now paid per test: the blackout suite went from about 9 s to
  about 22 s and the residency suite from about 2 s to about 6 s. Nothing is shared between tests,
  since `start_day()` and the residency both change the map, so a map built from the same seed is
  not safely immutable.

**Open to overturn:** both seeds kept for every residency test (the mode tests could run on the
first seed alone); the blackout suite keeps its fields, reset per test, rather than handing the city
to each helper; the three blackout checks that need no darkness could share one city if the
time matters.

**Not done**, listed for the public-seams scoping: the blackout suite finds its buildings through
the city's `Buildings` node's children; the residency suite reads the scenery ground's `chunks` and
`pending` entries' `layer` and `step`, `scenery.ordinary_guard_preparations`, writes
`city.scenery.view` by hand, and finds nodes through `get_children()`.
