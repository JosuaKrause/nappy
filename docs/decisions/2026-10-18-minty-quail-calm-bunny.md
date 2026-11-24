# minty-quail — The world map's, the mover's and the excitement source's fields go behind methods · 2026-11-23

## What was built

The world map's `size`, `moves`, `separation` and `day_record_version` are underscore-private. Readers ask
`size_in_tiles()` (which already existed), `list_move()` and `unlist_move()` for the figures that join and leave the
list, `course_keepers()` for the separation pass a body that gives way asks, and `day_record_version()`. The two
properties that computed from the blocked record, `obstructed_tiles` and `obstruction_version`, are methods of the
same names, and `has_solid_bodies()` answers the one question the walker asked of the first (whether anything
stands). `Mover`'s `blocked_by` and `radius` are private; its existing `layers_blocked()` and `body_reach()` answer
them. `ExcitementSource.landed_ever` is private behind `landed_ever()`, a number, so it keeps the field's name.

The fields wait for no other pass: the earlier reading, that they go with whatever pass gives the blocked tiles an
owner of their own, named no item.

## Rejected

A getter named for each field was rejected where a reader's question has a name of its own (`has_solid_bodies()`,
`list_move()`). `listed_moves()`, the list itself, is read only by tests (which confirm what a figure put on the
list, since a move is a pose nothing outward shows) and stands as a kept line of `tools/test_only_members.txt` with
that reason.

## The scene recipes' size reads

The scene recipes' reads of the map's size (`src/dev/scene_recipe_draft.gd`, `scene_recipe_runtime.gd`) are converted
to `size_in_tiles()` too, since the field is gone; their untyped files keep the opt-out line for their other reads.

## Verified

The thirty-nine suites touched pass with no failure; the field-read, test-only-member and layer checks and
`./tools/check.sh` pass.
