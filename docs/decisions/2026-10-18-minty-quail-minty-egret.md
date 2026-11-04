# minty-quail — The shapes, power station and home block suites ask the physics world and the city what they hold (tests through public seams: W9c) · 2026-11-04

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the shapes, power station and
home block suites, subtask W9c of the scoped plan. No `src/` change and no seam added.

**Built.**
- `test_shapes.gd` (private-read lines 2 to 0) asks the physics world, after one real physics tick,
  whether anything solid stands at a point: the hard-seal barricade across and along the street in
  both orientations, a corner of its capsule left clear, and a building at each edge with its north
  inset, each probe within about a pixel and a half. The event gets its atlas the
  way the spawner hands it.
- `test_power_station.gd` (4 to 0, the stand-in through `RunCity.of_the_run` 1 to 0) counts
  `RouteTree.cells()` per cell, one entry per node, so a lost node still fails; the chimney city is on
  a run of its own, and the two day-planning tests plan on maps of their own, since they repainted
  and closed streets on maps the other tests share and failed run in reverse.
- `test_home_block.gd` (5 to 0) counts the roof objects in the city's entities layer by the lot
  their feet stand on, with controls that a building off the home block carries some and that every
  one lands on exactly one lot, and every lot of the home block is bare on either seed. Its copy of
  the city's height stream goes: heights are checked to be deterministic on a rebuilt city, whole
  tiles within the lot's cap, different across seeds with variants, and varied within a block, some
  block holding two heights among its lots of one depth and two colour variants among its lots.
- Checks 875, 497 and 730 to 902, 497 and 1057; fourteen mutation runs.

**Open to overturn:** the exact random stream behind a building's height and variant is no longer
pinned, so a change of stream passes while the roll stays a deterministic function of seed and lot
with the same properties.
