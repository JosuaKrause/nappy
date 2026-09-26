## M100 — Four escape and run-log defects · built 2026-09-24

*(Found building the escape's run log, `DECISIONS.md`, M102, the building shows what the city
shows, and M183, the blackout.)*

**The masked man has his own hard-fail line.** `DayController._HARD_FAIL_TEXT` had no
`masked_pursuer` entry, so a catch in the escape fell back to "It went wrong."; it now says "He
caught you on the stairs." — he waits at the foot of a stairwell shaft, and the line keeps the
table's rule that what is lost is named, never dwelt on. The wording is the agent's, open to
overturn.

**A retried section restarts its snapshot schedule.** `TelemetryObserver.start_section()` reset the
section clock with `Telemetry.set_clock(0.0)` but left the last shot's time at the lost attempt's
reading, so the three-second spacing gate held every automatic snapshot back until the retry's
clock climbed past it. `Telemetry.restart_section_clock()` resets the clock, the day's shot count
and the last shot together, as `begin_day()` does; a named method rather than teaching
`set_clock()` a rule about going backwards.

**The readout read nothing, not a different state.** `HUD` looked the baby up once, in `_ready()`,
and in the escape the HUD is built before the building makes the baby, so the lookup came back empty
and the status line kept the scene file's placeholder, "awake", for the whole section while the
pram's picture read the live state. `_refresh_state()` now asks again while it holds no baby. The
root cause is `main._ready_escape()` building the HUD before the world; fixing that order instead is
open to overturn, and was outside the agent's fence.

**The quiet line says what fires it.** The run log's `quiet` line and
`EventBus.city_went_quiet`'s docstring said "the sabotage went through"; both fire at the
blackout, so both now say so.

Tests in `test_day_loop.gd`, `test_telemetry.gd` and `test_hud.gd`, each shown to fail before its
fix.
