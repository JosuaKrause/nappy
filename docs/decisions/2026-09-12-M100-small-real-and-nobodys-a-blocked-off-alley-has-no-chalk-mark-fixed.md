## M100 — Small, real, and nobody's · a blocked-off alley has no chalk mark, fixed 2026-09-12

*(2026-09-11, playtest 57: "a blocked off alley must not have a chalk mark.")* The mark lay on the
paving of an alley whose mouth a roadblock band closed. One agent commit on
`feature/chalk-and-invincible`, reviewed here. **The cause, exactly**: on seed 2199579682, day 7,
the alley is a crossing alley off the day's route tree, which `RegionPlanner` walls at both mouths
with a `roadblock` band each. All three refusals `ResistanceDirector._pick_reachable()` applied
let it through — `is_closed()` knows only `RoadClosure`s, `is_held_at()` asks
`StreetNetwork.segment_containing()`, which answers null for every tile of an alley because an
alley is carved into a block interior and never sits on a lattice segment, and the home-block check
is unrelated. All eighty tiles of that day's walled alleys passed all three. **What stands**: a
fourth query, `CityMap.is_in_walled_alley(tile, walled_alleys)`, rect membership against the region
plan's `alley_walls`, asked at every point a candidate is offered — the mark's initial roll, the
trap's guard position, and the relocation path that moves an unseen mark to the nearest alley —
never as a repair afterwards. **Rejected**: a `ReachabilityGrid` flood from the doorstep. The
planner's own contract is that a walled crossing alley is walled at both mouths, one tile deep and
full width, so there is no third opening and rect membership is the exact answer a flood would
give, without rebuilding and flooding a grid on every alley tile the relocation path checks per
frame. **What this does not cover**: ground behind a closure or a hard seal on a street is refused
by the existing closed and held checks; a soft seal leaves the far pavement walkable by design. If
a mark is ever seen behind a band that is neither a closure nor a region wall, that is a new gap,
not this one. Two tests in `tests/test_resistance.gd` pin it: the walled alley escaping every other
check, and the real city-to-director pipeline never offering it the mark or the guard over twenty
draws per step; both were red before the fix.
