# minty-quail — The generator, reachability grid and recipe composition suites ask the city what it built (tests through public seams: W21) · 2026-11-04

minty-quail's `tests-public-seams.md`: `tests/test_generator.gd`, `tests/test_reachability_grid.gd`
and `tests/test_recipe_composition.gd`. Tests only.

**Built.** Private-read lines 6 to 1, 5 to 3 and 5 to 0. The generator suite reads what the
subtraction leaves through a generated city's buildings, block layouts and home: a block with no
hole is one building, an alley leaves two slabs, a corner square two pieces and the home's notch
three, with area kept, no overlap and room left round each hole, every kind seen; the alley test
also checks each alley's offset is even and leaves two tiles of building either side. The grid
suite reads its mask table through sixteen one-cell maps and the cells a flood dirties through
`flood()` and `reaches()` alone. The recipe composition suite builds its city on a run of its own
(`GameState` lines 9 to 0), reads the street trees off `city.props()` and a walker's lane through
`LaneMover.lane_key_parts()`.

**Not done:** the generator's even-offset helper on odd bounds and a collapsed range, which no city
asks for, since its one caller passes two to four; the grid's tile-to-cell floor, where a wrongly
dirty cell changes what a query costs and never its answer, so only a reader of the dirty cells,
which no game class calls, would see it.
