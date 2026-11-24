# minty-quail — The route rig asks the one stated fact · 2026-11-24

The `--route` dev rig (`RouteRigPlanner`) worked the ground a deadly event shuts out in its own
words: `EventInstance.is_a_standing_lethal_place()` (a live row that ends the day and does not move)
and then `lethal_reach()`, a fifth statement of the fact the record minty-quail-calm-marmot made one.

**Built.** `EventInstance.catch_shuts_within()` forwards `EventDef.catch_shuts_within()` while the
event is in the world and answers 0 once it is gone. The rig keeps off a live event exactly when that
answer is above 0, at that answer plus its margin. `is_a_standing_lethal_place()` is deleted, and so
is the instance's `lethal_reach()`, whose only readers were the rig and tests; those tests read the
row's (`row().lethal_reach()`).

**Measured.** No answer changes: day 9, seed 90303 (`--route mark,task,calm,home --invincible`)
prints the same `route` lines on main twice and on the branch twice. Day 6, seed 4242 is not a
fixed point of the rig: main itself prints two different runs there (a re-plan more or fewer), so it
cannot show an equality; the equality rests on the rows being the same by construction
(`tests/test_event_phase.gd` holds that the live answer is the row's while it stands, 0 once gone, and
above 0 exactly for a row that ends the day and holds its place).
