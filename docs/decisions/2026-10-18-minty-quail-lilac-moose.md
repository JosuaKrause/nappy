# minty-quail — A building's fields read through its methods outside the events · 2026-11-18

**What it is.** Part of minty-quail's `field-reads.md` bullet "The city's own classes": a
building's (`Building`, `src/city/building.gd`, one lot's facade and roof) fields read from outside
its file by the city scene, the city's fronts, the scene recipes' draft and runtime and the three
roof previews, with `Building.power_station`, which the city scene's `assign_roof_extensions()`
read. An Opus builder designed and built it. It changes nothing in play: each hand-over now
rebuilds the building once rather than once per field, and every roll is seeded from the variant
and position, so the result is the same.

**What was built.** Getters `district()`, `height()`, `condition()`, `covered_ground_cols()` (a
copy) and `neighbor_window_col()`; the question `is_power_station()`; the writers
`show_condition()`, `dress_as_power_station()`, `mark_covered_ground_cols()`,
`board_neighbor_window_at()`, `mark_courtyard_seams()` and `lay_roof_furniture()` (public for the
roof network preview, a dev rig); `lot_rect()`, `look_variant()`, `is_on_home_block()`,
`stand_on()` and `draw_as()` reused. Thirteen fields are private, `station_door_col` and
`station_yard_cols` among them, which no suite reads. `tools/field_reads.txt` lost 27 lines and
gained none.

**What is left, and why.** Eight fields keep their direct write in the game: the blackout's
`powered`, the city scene's `day`, `roof_extension_rows` and `tint_variant`, the poster walls'
`poster_art`, and the previews' `atlas`, `footprint` and `roof_object_parent`. Suites read each
of them, and the game's only touch outside the class is that write, so a method for the write would
leave the field public for tests alone, which `tools/check_test_only_members.py` fails. They join
the item's group of fields only a test reads, which go with the tests-one-module item.

**Proposed, not asked for, open to the player:** the method names; one `dress_as_power_station()`
and one `mark_courtyard_seams()` call for facts handed together; `lay_roof_furniture()` public for
a dev rig.
