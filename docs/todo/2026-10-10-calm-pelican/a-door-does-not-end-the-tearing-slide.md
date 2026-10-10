# A door or fire escape in a papered wall does not end the tearing slide

**Medium · from the re-review of PR #593 (a held push tears every sheet she slides past, inbox
#591).** `PosterWalls._push_to_tear()` (`src/city/poster_walls.gd`) resets the slide on any tile
that is not a poster cell, and `blank_ground_floor_cells()` leaves out the entrance-door column, a
civic portico and every fire-escape column. Crossing a 32px door cell at 92px/s takes under 0.4s,
the 0.4s count starts again, and the next sheet escapes — the player's "every second poster" comes
back at every door, and `docs/MECHANICS.md`'s held-push paragraph is false there. The test
`_test_a_held_push_tears_every_sheet_she_slides_past` slides only along unbroken cells.

Fix: on a tile that is still the building's front (`_is_a_front`) but has no poster cell, keep the
slide going; reset only when she leaves the front row or the push ends. Add a test that slides
across a gap.
