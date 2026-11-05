# minty-quail — The tests of implementation details go, and the route rig plans its cut onto a painted crosswalk (tests through public seams) · 2026-11-04

minty-quail's `tests-public-seams.md`: `tests/test_generator.gd`, `tests/test_reachability_grid.gd`,
`tests/test_route_tree.gd` and `tests/test_route_rig.gd`, the four the last wave's scoping found
answerable without a source change. Tests only, plus one doc comment in
`src/routes/reachability_grid.gd`.

**Built.** Three tests of members no city asks for and no reader sees are deleted, each after a
check that what it guarded is guarded elsewhere or cannot change an answer:

- the generator's even-offset test: its only caller, the alley rectangle, asks for 2 to 4, and the
  alley-width test fails on every seed when the offset is made odd;
- the grid's cell-flooring test: flooring and truncating differ only at negative tiles, which lie
  outside the map, and there truncating only adds a dirty cell, which changes what a query costs
  and never its answer; with the cell made to truncate, every other grid check and the suites that
  use the grid still pass, and a flood with blocked tiles at -1 agrees with one without them. The
  grid's doc above `_cell_of_tile` says so, and that a cell leaving a blocked tile's own cell out of
  the dirty set would ignore the block;
- the route tree's cached-against-uncached growth test: the memo is invisible from outside, and
  growth's result is checked by the suite's walk, determinism and existing-streets tests, all on
  the cached path; no test pins cached growth equal to uncached any more.

The route rig's zebra rule is checked through `plan()`: the test paints a crosswalk three tiles
wide on an open run of the city's map and asks for the straight cut onto it, and a line of sight
made to refuse a crossing fails it.

**Choices, open to overturn.** The orchestrator chose deletion for the three detail tests, from
the queue item's own description of each as a check of what no city asks for or no reader sees;
the alternative, a public member for each, is the shape records -44 and -47 reject. The painted
crossing has sidewalk beside it rather than road, so the rig's test checks that a crossing is not
refused, the old test's claim, and not that a cut onto a generated zebra is refused for the road
beside it.
