# minty-quail — C1a: a building is told its day, power, poster art, clock and door · 2026-11-23

Building's `day`, `powered`, `poster_art`, `posters`, `scenery_clock` and `door_world_x_range` are private
(`_day`, `_powered`, `_poster_art`, `_posters`, `_scenery_clock`, `_door_span`) behind writers the game calls:
`show_day()`, `switch_power()`, `use_poster_art()`, `use_scenery_clock()`, `mark_door_span()`, and
`hand_over_posters()` for the posters. No reader was added. The suites read what a building draws
(a recording front drawer, a recording poster art) or hand the blackout buildings that record the switch.

Rejected: a field keeping its old name behind a forwarder (no legacy shape); a getter only the suites
call. `test_scenery_residency.gd` reads what survives an eviction: the boarded condition, the neighbor
window's column (`neighbor_window_col()`, untouched) and a sheet drawn through a recording art; no lit
window with the power off; and a lived-in commercial front whose shutters differ between day 1 and the
last day, which must show the last day's after eviction. The fixture buildings are too short to draw the
neighbor window's overlay (row index 3), so the column is read, not the picture. The frames those checks
wait on run with the residency's own per-frame work paused, which otherwise moves the view home.
