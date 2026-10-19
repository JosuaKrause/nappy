# coral-alpaca — The escape building's walls are taken out of the city · 2026-10-18 · not from an entry


The player, from the escape's city section on seed 4216201080 (run folder
`run-170256-seed4216201080-v0.28.0-4-g2148e837`, scratch telemetry): an "invisible wall exactly where
I'm standing -- impossible to continue the escape" (minty-lemur #777).

**The cause:** the escape building's own collision (its `Collision` node, 10,755 `StaticBody2D` wall
blockers) stayed in the city's physics space after she walked out, since the building shares the
city's origin. On `main` at `8d76e7e6` the step north from tile 74,27 was stopped by one of them, and
328 of 1,170 open escape tiles overlapped a body outside the city. Every escape run reaching the city
through the building hit it (the tunnel exit was cut off on all 100 seeds of a sweep).

**Built (PR #779).** `main._on_escape_exit_requested()` calls `InteriorScene.take_the_walls_out()`
before it builds the city, freeing the blockers at once; the building's pictures and fade stay.
`Stroller` takes its three atlas pages in `_enter_tree()`, since the walk-out reparents her and
`_exit_tree()` gave them back on every exit. `tests/test_escape_invisible_wall.gd` boots the real
game on the player's seed and requires the step through that spot and no open tile overlapping a
body; it fails on `main` before the fix.

**Not done here:** the building and the city still share no map interface, and the building's event
runner is its own; both are the refactor's (minty-quail, `world-map.md`).
