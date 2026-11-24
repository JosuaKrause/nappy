# minty-quail — The placement probes plan what the day plans · 2026-11-24

Pull request 1683's review found that the two placement probes, `tests/probes/placement_rows.gd` and
`tests/probes/placement_view_mix.gd`, planned a day differently from `DayPlanner`, and the remeasure of
the placement readings was not to run on them as they were.

**What the probes did differently, and now do the same.**

- **The roadblock row.** They handed the dawn the plain `EventCatalogue.by_id(guarded)`; the day hands
  `EventCatalogue.heated(EventCatalogue.by_id(guarded), progress)`. Both ask for the heated row now.
- **The street trees.** The game refreshes them (`City.refresh_street_trees()`) after the day's seals are
  planned, a `fallen_tree_seal` emptying a pit of its own; the probes never did. The probe's city is now a
  built `City` (`RunCity`), so the call has a city to reach.
- **One planning block.** Both carried a copy of the closures, holds, region wall, seals and standing.
  `tests/probes/placement_probe_day.gd` (`PlacementProbeDay`) holds it once; each probe passes the tag its
  closure and seal streams are seeded under, so each keeps its own streams.

**The progress a probe has to choose.** A probe has no run, and `DayPlanner` reads the run's resistance
progress. The helper takes that of a run that completes every task offered before the day
(`PlacementProbeDay.progress_on()`: the steps that grant progress with an index up to `2 * (day - 6)`, the
goal on the finale's day), hands it to the roadblock row's heating and tells the dawn the same progress
(`GameDawn.heat()`), as `DayPlanner` does with one number. Another choice is a run that does none of them
(progress 0 everywhere, where the heated row is the plain row); it is left to a reader who wants the
cold city.

**Measured**, on main (`1e73db9e0`) and on the branch, the two probes each, 18 cities a day:

- `placement_view_mix.gd`: days 1 to 9 print the same lines; days 10, 11, 12 and 14 differ (placed a day
  82.9, 82.0, 97.9 and 103.2 on main; 79.3, 76.7, 93.5 and 96.6 on the branch), nearly all in the off-the-route
  view; day 13 differs by 0.1 (115.4 to 115.3).
- `placement_rows.gd`, `RD` lines (placed summed over the 18 cities): days 1 to 9 equal; day 10 1483 to
  1405, day 11 1466 to 1365, day 12 1782 to 1689, day 14 1835 to 1727, day 13 2105 to 2107; the moments are
  equal on every day.
- **Where the change comes from.** A third run of `placement_rows.gd` with the dawn's heat left at 0 and the
  rest as the branch has (heated row, trees) printed main's lines on every day but day 13 (2107, the heated
  roadblock row's own effect). So the street trees move no placement, the heated roadblock row moves day 13
  by 2, and the dawn's heat from day 10 on is what moves days 10 to 14, as the game's dawn has it.

**Left open.** The other probes under `tests/probes/` that carry their own copy of the block (`walk_rows.gd`,
`curly_stork_piece_layout.gd`, `downy_llama_route_roadblocks.gd`, `minty_quail_blocking_reach.gd`) plan with
the plain row and no trees; their headers say they plan as `placement_rows.gd` plans.
