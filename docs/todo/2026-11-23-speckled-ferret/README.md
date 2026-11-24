priority: now

# speckled-ferret — The placement probes plan with the plain roadblock row and never refresh the street trees · filed 2026-11-23

**What is wrong.** `tests/probes/placement_rows.gd` and `tests/probes/placement_view_mix.gd` hand the dawn the day's guarded roadblock row as `EventCatalogue.by_id(guarded)`, while the real planner (`DayPlanner`, `src/events/simulation/day_planner.gd`) hands `EventCatalogue.heated(EventCatalogue.by_id(guarded), progress)`, the row heated by the run's resistance progress. Neither probe calls `refresh_street_trees()` after planning the seals, which the game does once the day's seals are planned (`City.refresh_street_trees()`), so the trees the placements see differ from the game's. The two probes also hold the same planning block (the seals, the doors, the standing bodies, the wall plans, `GameDawn.of(...)...plan().placements()`) by copy. A filing from a review, not from the player's words; the band, `later`, is the filer's proposal.

**Found by** pull request 1683's review.

**Order.** This settles before minty-quail's end remeasure, which reads these probes, so its numbers are measured over the game's own rows; that is why the band is `now` (newest first, so it prints at the head of the band, ahead of minty-quail). There is no `after:` line on minty-quail's side, since the remeasure is a step inside that entry and not an entry.

**What a builder does.** Plan with the heated row as `DayPlanner` does, call `refresh_street_trees()` where the game does, and put the shared planning block in one helper both probes use.

**Shown fixed.** Both probes plan with the same rows and trees as `DayPlanner` for a day on which the roadblock row is heated, and the shared block is in one file.
