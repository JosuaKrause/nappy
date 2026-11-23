priority: later

# lilac-bison — Nothing asserts that the event manager's instances() stops listing a retired event · filed 2026-11-23

No player's words name this finding; it is the filer's, and the band `later` is the filer's proposal, not asked for.

**Found** by the review of pull request #1655 (minty-quail row 5, the danger suite).

**What holds today.** `EventManager.instances()` hands out the list `EventWorld` keeps, and `EventStreaming.retire_finished()` takes a gone event out of it by assigning the survivors in place (`world.keep_only(survivors)`), the list being held across frames by the screen-edge badge. No suite asserts, against the real manager, that a retired event is no longer in what `instances()` returns: `tests/test_halo.gd` retires events and reads their rims and their deletion, `tests/test_drawn_view.gd` does not read the list, and `tests/test_event_moves.gd` checks only that a retired event is off the proposed moves and queued for deletion. To show it: delete the `world.keep_only(survivors)` line of `retire_finished()` and run `tools/test.sh test_halo test_drawn_view test_event_moves`; the review of #1655 found nothing fails in them. It was not re-run when this entry was filed.

**What the fix must hold.** A case in the event manager's suite (`tests/test_event_manager.gd`) that retires a streamed-in event through the real manager and asserts that `instances()` no longer lists it while the other events stay listed, and that the array it handed out before is the one that changed (the badge holds it by reference). Removing `keep_only()` from `retire_finished()` then fails that case.

**Proposed, not asked for:** the band `later`, and the manager's suite as the place for the case.
