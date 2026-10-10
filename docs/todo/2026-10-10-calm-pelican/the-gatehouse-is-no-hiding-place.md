# Day 9's gatehouse is no hiding place

**Medium · from the re-review of PR #570 (grassy-goose, every guarded target sends the robber from
off screen).** Walking under day 9's raised boom completes the task and sends only the door's guard,
no robber (`ResistanceDirector._on_door_crossed()`); stepping into either hut then is a hold, and
under M100 a hold ends the guard's chase (`EventManager._end_the_guard_for_a_hold()`). So the task
costs one inspection and no pursuer, while the honest inspected crossing costs the inspection plus
the robber — against the player's "you shouldn't try to cheat it by going back in the hut -- that
should be fatal by the robber", and making `docs/NARRATIVE.md`'s "a gatehouse is no hiding place"
false. #570 opened the hole: before it, the walk under also sent the robber. Found by reading.

**Open, for the player, since it meets M100's hold rule:** (a) a hut's hold does not end the guard
a walk under day 9's named door sends, or (b) a hold that ends that guard sends the task's robber
instead. Either way, add a test that walks under the named boom, steps into a hut, and asserts
someone still chases her.

**Low, same area:** `tests/test_resistance.gd`'s
`_test_day_nine_is_done_by_crossing_the_door_not_by_standing_at_it` cannot fail: an earlier walk
under another door already set a guard on her, only one walk-under guard exists at a time, so the
named crossing spawns nobody and the check passes on the first guard. Finish or clear the first
guard first, or assert a new `door_guard` at the named door's hut. And show the trap in pictures on
the days #570 changed beyond day 8: day 9 both ways through the door, day 11's mast foot, day 12's
swing, day 14's station door, under `docs/evidence/`.
