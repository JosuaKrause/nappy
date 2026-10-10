# Day 9's walk under the boom and a hut's hold

**Medium · from the re-review of PR #570 (grassy-goose, every guarded target sends the robber from
off screen).** Walking under day 9's raised boom completes the task and sends only the door's guard,
no robber (`ResistanceDirector._on_door_crossed()`); stepping into either hut then is a hold, and
under M100 a hold ends the guard's chase (`EventManager._end_the_guard_for_a_hold()`). So the task
costs one inspection and no pursuer, while the honest inspected crossing costs the inspection plus
the robber. #570 made it so: before it, the walk under also sent the robber.

**The player keeps it** (inbox #651 in [lilac-marmot](../../playtests/2026-10-10-lilac-marmot.md)), asked whether the hut should stop
ending that guard's chase or send the robber instead:

> Let's not send the robber in that case and stop the chase. It's a fair cheat getting through the barrier is hard enough. Well earned if the player pulls it off.

So nothing about the behaviour changes. The robber a done task sends stays the one a hut does not
hold (the player's "you shouldn't try to cheat it by going back in the hut -- that should be fatal
by the robber", [plush-bunny](../../playtests/2026-10-05-plush-bunny.md), and `docs/EVENTS.md`'s
"a gatehouse is no hiding place from him"), and the walk under never sends him. What this item
owes: a test that walks under the named boom, steps into a hut, and asserts the door's guard gives
up and nobody else is sent. *Proposed, not asked for:* a sentence in `docs/EVENTS.md`'s hold
paragraph and `docs/NARRATIVE.md`'s day-9 paragraph, both of which already speak only of the robber,
saying the walk under's guard is one a hut ends, with the player's words; it clarifies, and changes
nothing they say.

**Low, same area:** `tests/test_resistance.gd`'s
`_test_day_nine_is_done_by_crossing_the_door_not_by_standing_at_it` cannot fail: an earlier walk
under another door already set a guard on her, only one walk-under guard exists at a time, so the
named crossing spawns nobody and the check passes on the first guard. Finish or clear the first
guard first, or assert a new `door_guard` at the named door's hut. And show the trap in pictures on
the days #570 changed beyond day 8: day 9 both ways through the door, day 11's mast foot, day 12's
swing, day 14's station door, under `docs/evidence/`.
