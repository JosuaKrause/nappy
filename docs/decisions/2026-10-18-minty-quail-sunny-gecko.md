# minty-quail — The placement probes plan what the day plans · 2026-11-24

Pull request 1683's review found that the two placement probes, `tests/probes/placement_rows.gd` and
`tests/probes/placement_view_mix.gd`, planned a day differently from `DayPlanner`, and the remeasure of
the placement readings was not to run on them as they were.

**What the probes do now.**

- **The roadblock row.** They hand the dawn `EventCatalogue.heated(EventCatalogue.by_id(guarded), 0)`, where
  they handed the plain row; at level 0 `heated()` returns the row itself, so the path is the game's and
  no count moves.
- **The street trees.** The game refreshes them (`City.refresh_street_trees()`) after the whole dawn
  (`DayDirector` calls it once `EventManager.start_day()` has returned), a `fallen_tree_seal` having
  emptied a pit of its own. The helper calls it after the dawn has placed, on a built `City` (`RunCity`).
  It only shows or hides tree pictures and refreshes the decals' pits, so it cannot move a count by design.
- **One planning block.** Both carried a copy of the closures, holds, region wall, seals and standing.
  `tests/probes/placement_probe_day.gd` (`PlacementProbeDay`) holds it once; each probe passes the tag its
  closure and seal streams are seeded under, so each keeps its own streams.

**Why heat 0.** Every column of the baseline readings in `docs/evidence/minty-quail-baseline-2026-11-09/`
was taken at heat 0 (the `v0.29.0` counterpart passes its default `0`; the probes of the other columns
never call `GameDawn.heat()`), and the end remeasure compares against them with
`tools/compare-placement-rows.py`. A probe planned at the progress of a run that completes every task
moved days 10 to 14 by 5% to 7% (day 11 1466 to 1365), which that comparison would list beside what the
refactor moved. A heated reading is a reading of its own beside the cold one, as
`downy_llama_route_roadblocks.gd` runs heats 0 and 4; it is not the remeasure's default.

**Measured** on main (`1e73db9e0`) and on the branch, the two probes each, 18 cities a day: every printed
line equals main's, on every day, for both probes (the comparison is in the pull request).

**Noted.**

- The probes give the dawn `GameDawn`'s default calm areas, where the game sets aside the day's narrow
  task spot (day 9's door, day 12's swing park, day 14's station door); the baseline's probes do the same,
  so the remeasure is not biased by it.
- Five probes under `tests/probes/` carry their own copy of the block, none on the helper:
  `walk_rows.gd`, `curly_stork_piece_layout.gd`, `downy_llama_route_roadblocks.gd`,
  `minty_quail_blocking_reach.gd` and `placement_cells.gd`. They plan the plain row, which at heat 0 is
  the heated row, and no tree refresh, which moves no count, so their headers' "plans as `placement_rows.gd`
  plans" holds for every count. Moving them onto the helper needs a heat argument and an undrawn option
  (`walk_rows.gd` and `placement_cells.gd` leave the units undrawn; two choose their own heat), a design of
  its own.
