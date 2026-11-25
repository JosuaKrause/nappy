# The two crowd probes leave three bus connections behind

`tests/probes/minty_quail_crowd_cadence.gd` prints what the crowd's own numbers come to (car
headways, the junction boxes' throughput, the horns, the bumps and the strikes) when its motion is
stepped at frame rates other than the physics tick; `tests/probes/minty_quail_crowd_yields.gd`
counts how the crowd's walkers and cars meet the day's event figures (overlaps, the seconds a car
stands for one, the longest stand in a junction box). Both count horns, bumps and day-ending
strikes by connecting a function to three signals of the global event bus (`EventBus`):
`car_near_miss`, `crowd_bumped` and `hard_fail_triggered`.

**Their first failure:** neither disconnects them, and the runner fails a file that leaves an
autoload's signal connections changed (`tests/shared_state.gd`, which compares every connection on
an autoload's signals before and after), so each prints its numbers and exits 1 (the record
2026-10-18-minty-quail-lilac-chipmunk).

*Proposed, not asked for:* fixed, by disconnecting the three at the end of `run()`; the crowd is
already handed the bus (`Crowd.use_bus()`), so a bus of the probe's own handed to the crowd would
spare the global one altogether. Deleting them loses the crowd's cadence and yield measurements,
which the refactor's end remeasure may want.
