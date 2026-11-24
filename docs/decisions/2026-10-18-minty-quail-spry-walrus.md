# minty-quail — C1a: a building is told its day, power, poster art, clock and door · 2026-11-23

Building's `day`, `powered`, `poster_art`, `posters`, `scenery_clock` and `door_world_x_range` are private
(`_day`, `_powered`, `_poster_art`, `_posters`, `_scenery_clock`, `_door_span`) behind writers the game calls:
`show_day()`, `switch_power()`, `use_poster_art()`, `use_scenery_clock()`, `mark_door_span()`, and
`hand_over_posters()` for the posters. No reader was added. The suites read what a building draws
(a recording front drawer, a recording poster art) or hand the blackout buildings that record the switch.

Rejected: a field keeping its old name behind a forwarder (no legacy shape); a getter only the suites
call. Not writable any more: `test_scenery_residency.gd`'s fixture buildings have at most three wall rows
and the boarded neighbor window draws on row index 3, so the neighbor-window column is no longer read
there (`test_home_block.gd` holds it on the home building).
