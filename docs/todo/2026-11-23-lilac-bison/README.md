priority: later

# lilac-bison — Nothing asserts that the array the event manager's instances() handed out is the one a retirement changes · filed 2026-11-23

No player's words name this finding; it is the filer's, and the band `later` is the filer's proposal, not asked for.

**Found** by the review of pull request #1655 (minty-quail row 5, the danger suite), narrowed by the review of the pull request that filed it.

**What holds today.** `EventManager.instances()` hands out the list `EventWorld` keeps, and `EventStreaming.retire_finished()` takes a gone event out of it by assigning the survivors in place (`world.keep_only(survivors)`), so a caller holding the array across frames, as the screen-edge badge does, sees the retirement. `tests/test_event_manager.gd`'s `_test_finished_instances_are_dropped` holds that a retired event leaves the manager (its count drops by one and the entries left are valid; with the `keep_only()` line replaced by `pass`, the suite stops on a freed instance). No suite holds that the array handed out *before* the retirement is the one that changed: a `retire_finished()` that built a fresh array and handed that out from then on would pass every suite, and the badge, holding the old array, would keep a gone event.

**What the fix must hold.** A case in the event manager's suite that takes the array `instances()` returns, retires a streamed-in event through the real manager, and asserts that same array no longer lists it while the others stay listed. A `retire_finished()` that replaces the array rather than changing it in place then fails that case.

**Proposed, not asked for:** the band `later`, and the manager's suite as the place for the case.
